-- ============================================================================
-- UNITY FINANCE GROUP
-- Loan Model V2 Modification Migration
-- Date: 2026-09-07
--
-- TARGET:
--   Existing Unity Finance MVP schema + previous loan hardening/RPC migration.
--
-- FINAL BUSINESS MODEL:
--   Member maximum = MIN(member_total_savings * 2, 20000 ETB)
--   Outsider maximum = MIN(guarantor_total_savings * 2, 20000 ETB)
--
-- REMOVED:
--   borrower savings + guarantor savings >= requested amount
--   outsider guarantor 50% coverage rule
--
-- IMPORTANT:
--   This migration intentionally separates authenticated member applications
--   from unauthenticated outsider applications.
-- ============================================================================

begin;

-- ============================================================================
-- 0. Dependency guard
-- ============================================================================

do $$
begin
  if to_regclass('public.loan_products') is null
     or to_regclass('public.loan_applications') is null
     or to_regclass('public.loans') is null
     or to_regclass('public.loan_installments') is null
     or to_regclass('public.loan_approvals') is null
     or to_regclass('public.loan_eligibility_checks') is null
     or to_regclass('public.members') is null
     or to_regclass('public.profiles') is null
     or to_regclass('public.savings_accounts') is null
     or to_regclass('public.accounts') is null
     or to_regclass('public.account_types') is null
     or to_regclass('public.transactions') is null
     or to_regclass('public.transaction_entries') is null
  then
    raise exception
      'Required Unity Finance MVP/loan schema is missing. Apply the base and previous loan migrations first.';
  end if;
end;
$$;

-- ============================================================================
-- 1. Loan products: authoritative hard cap remains 20,000 ETB
-- ============================================================================

update public.loan_products
set max_amount = 20000,
    service_charge_rate = case
      when borrower_type = 'member' then 0.10
      when borrower_type = 'outsider' then 0.15
      else service_charge_rate
    end,
    term_months = 3,
    active = true,
    updated_at = now()
where code in ('member_loan', 'outsider_loan');

-- ============================================================================
-- 2. Preserve the previous shared guarantor table
--
-- The previous model used public.loan_guarantors for mixed applications.
-- Keep the table in place so existing historical rows/functions do not break.
-- V2 does not write new records to it. New application paths use the two
-- dedicated guarantor tables below.
-- ============================================================================

-- ============================================================================
-- 3. Separate outsider applications
-- ============================================================================

create table if not exists public.outsider_loan_applications (
  id uuid primary key default gen_random_uuid(),
  application_number text unique not null
    default private.generate_reference('OUTLOANAPP'),
  loan_product_id uuid not null
    references public.loan_products(id) on delete restrict,
  applicant_full_name text not null
    check (length(trim(applicant_full_name)) between 2 and 200),
  applicant_phone text not null
    check (length(trim(applicant_phone)) between 7 and 40),
  applicant_address text not null
    check (length(trim(applicant_address)) between 3 and 500),
  requested_amount numeric(18,2) not null
    check (requested_amount > 0),
  purpose text,
  eligibility_status public.loan_application_status,
  status public.loan_application_status not null default 'submitted',
  eligibility_snapshot jsonb not null default '{}'::jsonb,
  eligibility_evaluated_at timestamptz,
  approved_amount numeric(18,2),
  approved_at timestamptz,
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists outsider_loan_applications_status_submitted_idx
  on public.outsider_loan_applications(status, submitted_at desc);

create index if not exists outsider_loan_applications_phone_idx
  on public.outsider_loan_applications(applicant_phone);

create index if not exists outsider_loan_applications_product_idx
  on public.outsider_loan_applications(loan_product_id, status);


-- Database invariant: outsider applications can only reference OUTSIDER_LOAN.
create or replace function private.validate_outsider_loan_application_v2()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_borrower_type public.loan_borrower_type;
begin
  select lp.borrower_type
    into v_borrower_type
  from public.loan_products lp
  where lp.id = new.loan_product_id;

  if v_borrower_type is distinct from 'outsider' then
    raise exception 'outsider_loan_applications requires an outsider loan product';
  end if;

  return new;
end;
$$;

revoke all on function private.validate_outsider_loan_application_v2()
  from public, anon, authenticated;

drop trigger if exists validate_outsider_loan_application_v2
  on public.outsider_loan_applications;

create trigger validate_outsider_loan_application_v2
before insert or update on public.outsider_loan_applications
for each row execute procedure private.validate_outsider_loan_application_v2();

-- ============================================================================
-- 4. Separate guarantor tables
-- ============================================================================

create table if not exists public.member_loan_guarantors (
  id uuid primary key default gen_random_uuid(),
  loan_application_id uuid not null unique
    references public.loan_applications(id) on delete restrict,
  guarantor_member_id uuid not null
    references public.members(id) on delete restrict,
  requested_amount_snapshot numeric(18,2) not null
    check (requested_amount_snapshot > 0),
  service_charge_rate_snapshot numeric(8,4) not null
    check (service_charge_rate_snapshot >= 0),
  total_repayment_snapshot numeric(18,2) not null
    check (total_repayment_snapshot > 0),
  term_months_snapshot int not null
    check (term_months_snapshot > 0),
  status public.guarantor_status not null default 'requested',
  requested_at timestamptz not null default now(),
  responded_at timestamptz,
  rejected_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (
    (status = 'requested' and responded_at is null)
    or status in ('accepted', 'rejected', 'released')
  )
);

create index if not exists member_loan_guarantors_guarantor_status_idx
  on public.member_loan_guarantors(guarantor_member_id, status);

create index if not exists member_loan_guarantors_status_idx
  on public.member_loan_guarantors(status, requested_at desc);

create table if not exists public.outsider_loan_guarantors (
  id uuid primary key default gen_random_uuid(),
  outsider_loan_application_id uuid not null unique
    references public.outsider_loan_applications(id) on delete restrict,
  guarantor_member_id uuid not null
    references public.members(id) on delete restrict,
  requested_amount_snapshot numeric(18,2) not null
    check (requested_amount_snapshot > 0),
  service_charge_rate_snapshot numeric(8,4) not null
    check (service_charge_rate_snapshot >= 0),
  total_repayment_snapshot numeric(18,2) not null
    check (total_repayment_snapshot > 0),
  term_months_snapshot int not null
    check (term_months_snapshot > 0),
  guaranteed_max_amount_snapshot numeric(18,2) not null
    check (guaranteed_max_amount_snapshot > 0),
  status public.guarantor_status not null default 'requested',
  requested_at timestamptz not null default now(),
  responded_at timestamptz,
  rejected_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (
    (status = 'requested' and responded_at is null)
    or status in ('accepted', 'rejected', 'released')
  )
);

create index if not exists outsider_loan_guarantors_guarantor_status_idx
  on public.outsider_loan_guarantors(guarantor_member_id, status);

create index if not exists outsider_loan_guarantors_status_idx
  on public.outsider_loan_guarantors(status, requested_at desc);

-- One member may guarantee only one outstanding outsider loan.
-- We intentionally scope this to accepted/requested guarantee records whose
-- linked loan application has not been rejected/cancelled and whose final loan
-- is still outstanding.
create unique index if not exists outsider_one_outstanding_guarantee_per_member_idx
  on public.outsider_loan_guarantors(guarantor_member_id)
  where status in ('requested', 'accepted');

-- ============================================================================
-- 5. Update-at triggers for the new tables
-- ============================================================================

drop trigger if exists outsider_loan_applications_set_updated_at
  on public.outsider_loan_applications;

create trigger outsider_loan_applications_set_updated_at
before update on public.outsider_loan_applications
for each row execute procedure private.set_updated_at();

drop trigger if exists member_loan_guarantors_set_updated_at
  on public.member_loan_guarantors;

create trigger member_loan_guarantors_set_updated_at
before update on public.member_loan_guarantors
for each row execute procedure private.set_updated_at();

drop trigger if exists outsider_loan_guarantors_set_updated_at
  on public.outsider_loan_guarantors;

create trigger outsider_loan_guarantors_set_updated_at
before update on public.outsider_loan_guarantors
for each row execute procedure private.set_updated_at();

-- ============================================================================
-- 6. Harden loan_applications to member-only
-- ============================================================================

-- Existing member applications can be retained. The V2 RPC will only insert
-- member products and the trigger below prevents outsiders being written here.

create or replace function private.validate_member_loan_application_v2()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_borrower_type public.loan_borrower_type;
  v_member_profile_id uuid;
begin
  select lp.borrower_type
  into v_borrower_type
  from public.loan_products lp
  where lp.id = new.loan_product_id;

  if v_borrower_type is distinct from 'member' then
    raise exception 'loan_applications is reserved for member loans';
  end if;

  if new.member_id is null then
    raise exception 'member loan applications require member_id';
  end if;

  select m.profile_id
  into v_member_profile_id
  from public.members m
  where m.id = new.member_id;

  if v_member_profile_id is null then
    raise exception 'member_id does not resolve to a valid member profile';
  end if;

  return new;
end;
$$;

revoke all on function private.validate_member_loan_application_v2()
  from public, anon, authenticated;

drop trigger if exists validate_member_loan_application_v2
  on public.loan_applications;

create trigger validate_member_loan_application_v2
before insert or update on public.loan_applications
for each row execute procedure private.validate_member_loan_application_v2();

-- ============================================================================
-- 7. Support both application sources in eligibility checks
-- ============================================================================

alter table public.loan_eligibility_checks
  alter column loan_application_id drop not null;

alter table public.loan_eligibility_checks
  add column if not exists outsider_loan_application_id uuid
    references public.outsider_loan_applications(id) on delete restrict;

alter table public.loan_eligibility_checks
  add constraint loan_eligibility_checks_exactly_one_source_v2
  check (
    (loan_application_id is not null and outsider_loan_application_id is null)
    or (loan_application_id is null and outsider_loan_application_id is not null)
  )
  not valid;

create index if not exists loan_eligibility_checks_outsider_run_idx
  on public.loan_eligibility_checks(
    outsider_loan_application_id,
    evaluation_run_id,
    checked_at desc
  );

-- ============================================================================
-- 8. Support both application sources in approvals
-- ============================================================================

alter table public.loan_approvals
  alter column loan_application_id drop not null;

alter table public.loan_approvals
  add column if not exists outsider_loan_application_id uuid
    references public.outsider_loan_applications(id) on delete restrict;

alter table public.loan_approvals
  add constraint loan_approvals_exactly_one_source_v2
  check (
    (loan_application_id is not null and outsider_loan_application_id is null)
    or (loan_application_id is null and outsider_loan_application_id is not null)
  )
  not valid;

drop index if exists public.loan_approvals_application_approver_uidx;

create unique index if not exists loan_approvals_member_application_approver_uidx_v2
  on public.loan_approvals(loan_application_id, approver_profile_id)
  where loan_application_id is not null;

create unique index if not exists loan_approvals_outsider_application_approver_uidx_v2
  on public.loan_approvals(outsider_loan_application_id, approver_profile_id)
  where outsider_loan_application_id is not null;

create index if not exists loan_approvals_outsider_application_idx_v2
  on public.loan_approvals(outsider_loan_application_id, decided_at desc)
  where outsider_loan_application_id is not null;

-- ============================================================================
-- 9. Support both application sources in final loans
-- ============================================================================

alter table public.loans
  alter column loan_application_id drop not null;

alter table public.loans
  alter column borrower_profile_id drop not null;

alter table public.loans
  add column if not exists outsider_loan_application_id uuid
    references public.outsider_loan_applications(id) on delete restrict;

alter table public.loans
  add constraint loans_exactly_one_application_source_v2
  check (
    (loan_application_id is not null and outsider_loan_application_id is null)
    or (loan_application_id is null and outsider_loan_application_id is not null)
  )
  not valid;

alter table public.loans
  add constraint loans_borrower_identity_matches_source_v2
  check (
    (
      outsider_loan_application_id is null
      and borrower_profile_id is not null
      and member_id is not null
    )
    or
    (
      outsider_loan_application_id is not null
      and borrower_profile_id is null
      and member_id is null
    )
  )
  not valid;

create unique index if not exists loans_one_per_outsider_application_v2
  on public.loans(outsider_loan_application_id)
  where outsider_loan_application_id is not null;

create index if not exists loans_outsider_application_idx_v2
  on public.loans(outsider_loan_application_id)
  where outsider_loan_application_id is not null;

-- ============================================================================
-- 10. Private member savings balance helper
-- ============================================================================

create or replace function private.member_total_savings_v2(p_member_id uuid)
returns numeric
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    sum(
      case
        when te.entry_type = 'credit' then te.amount
        else -te.amount
      end
    ),
    0
  )::numeric(18,2)
  from public.accounts a
  join public.account_types at
    on at.id = a.account_type_id
  join public.transaction_entries te
    on te.account_id = a.id
  join public.transactions t
    on t.id = te.transaction_id
  where at.code = 'member_savings'
    and a.owner_member_id = p_member_id
    and a.status <> 'closed'
    and t.transaction_status = 'posted';
$$;

revoke all on function private.member_total_savings_v2(uuid)
  from public, anon, authenticated;

-- ============================================================================
-- 11. Private maximum helpers
-- ============================================================================

create or replace function private.member_max_loan_v2(p_member_id uuid)
returns numeric
language sql
stable
security definer
set search_path = ''
as $$
  select least(
    coalesce(private.member_total_savings_v2(p_member_id), 0) * 2,
    20000::numeric
  )::numeric(18,2);
$$;

revoke all on function private.member_max_loan_v2(uuid)
  from public, anon, authenticated;

create or replace function private.outsider_guarantor_max_loan_v2(p_guarantor_member_id uuid)
returns numeric
language sql
stable
security definer
set search_path = ''
as $$
  select least(
    coalesce(private.member_total_savings_v2(p_guarantor_member_id), 0) * 2,
    20000::numeric
  )::numeric(18,2);
$$;

revoke all on function private.outsider_guarantor_max_loan_v2(uuid)
  from public, anon, authenticated;

-- ============================================================================
-- 12. Public helper for minimal outsider guarantor search
--
-- This is deliberately narrow. It does NOT expose savings or private contact
-- data. It exists because outsider applicants are not authenticated members.
-- ============================================================================

create or replace function public.search_outsider_loan_guarantors(
  p_search text default null
)
returns table (
  member_id uuid,
  member_number text,
  display_name text
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    m.id,
    m.member_number,
    coalesce(nullif(trim(p.full_name), ''), m.member_number)::text
  from public.members m
  join public.profiles p
    on p.id = m.profile_id
  where m.status = 'active'
    and (
      p_search is null
      or trim(p_search) = ''
      or m.member_number ilike '%' || trim(p_search) || '%'
      or p.full_name ilike '%' || trim(p_search) || '%'
    )
  order by p.full_name, m.member_number
  limit 20;
$$;

revoke all on function public.search_outsider_loan_guarantors(text)
  from public, authenticated, anon;
grant execute on function public.search_outsider_loan_guarantors(text)
  to anon;

-- ============================================================================
-- 13. Member loan submission RPC
-- ============================================================================

create or replace function public.submit_member_loan_application_v2(
  p_loan_product_id uuid,
  p_requested_amount numeric,
  p_purpose text,
  p_guarantor_member_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_member_id uuid;
  v_product record;
  v_guarantor record;
  v_total_savings numeric(18,2);
  v_max_loan numeric(18,2);
  v_service_charge numeric(18,2);
  v_total_repayment numeric(18,2);
  v_application_id uuid;
  v_guarantor_id uuid;
begin
  if v_actor is null then
    raise exception 'Not authenticated';
  end if;

  if not private.current_user_has_permission('loan.apply') then
    raise exception 'Unauthorized';
  end if;

  if p_requested_amount is null or p_requested_amount <= 0 then
    raise exception 'Requested loan amount must be greater than zero';
  end if;

  if p_guarantor_member_id is null then
    raise exception 'An active member guarantor is required';
  end if;

  select m.id
  into v_member_id
  from public.members m
  where m.profile_id = v_actor
    and m.status = 'active'
  limit 1;

  if v_member_id is null then
    raise exception 'Only active members can apply for a member loan';
  end if;

  if p_guarantor_member_id = v_member_id then
    raise exception 'A member cannot guarantee their own loan';
  end if;

  select
    lp.id,
    lp.code,
    lp.borrower_type,
    lp.service_charge_rate,
    least(lp.max_amount, 20000::numeric) as hard_cap,
    lp.term_months,
    lp.active
  into v_product
  from public.loan_products lp
  where lp.id = p_loan_product_id
    and lp.active = true;

  if not found or v_product.borrower_type <> 'member' then
    raise exception 'Invalid or inactive member loan product';
  end if;

  select
    m.id,
    m.status
  into v_guarantor
  from public.members m
  where m.id = p_guarantor_member_id
    and m.status = 'active';

  if not found then
    raise exception 'Selected guarantor is not an active member';
  end if;

  select private.member_total_savings_v2(v_member_id)
  into v_total_savings;

  v_max_loan := least(v_total_savings * 2, v_product.hard_cap, 20000::numeric);

  if p_requested_amount > v_max_loan then
    raise exception
      'Requested amount % exceeds member maximum loan % based on current savings %',
      round(p_requested_amount, 2),
      v_max_loan,
      v_total_savings;
  end if;

  v_service_charge := round(p_requested_amount * v_product.service_charge_rate, 2);
  v_total_repayment := round(p_requested_amount + v_service_charge, 2);

  insert into public.loan_applications(
    applicant_profile_id,
    member_id,
    loan_product_id,
    requested_amount,
    purpose,
    status,
    submitted_at,
    eligibility_snapshot
  )
  values(
    v_actor,
    v_member_id,
    v_product.id,
    round(p_requested_amount, 2),
    nullif(trim(p_purpose), ''),
    'submitted',
    now(),
    jsonb_build_object(
      'loan_model_version', 'v2',
      'borrower_type', 'member',
      'member_total_savings_at_submission', v_total_savings,
      'member_max_loan_at_submission', v_max_loan,
      'requested_amount', round(p_requested_amount, 2),
      'service_charge_rate', v_product.service_charge_rate,
      'service_charge_amount', v_service_charge,
      'total_repayment', v_total_repayment,
      'term_months', v_product.term_months,
      'guarantor_member_id', p_guarantor_member_id
    )
  )
  returning id into v_application_id;

  insert into public.member_loan_guarantors(
    loan_application_id,
    guarantor_member_id,
    requested_amount_snapshot,
    service_charge_rate_snapshot,
    total_repayment_snapshot,
    term_months_snapshot,
    status,
    requested_at
  )
  values(
    v_application_id,
    p_guarantor_member_id,
    round(p_requested_amount, 2),
    v_product.service_charge_rate,
    v_total_repayment,
    v_product.term_months,
    'requested',
    now()
  )
  returning id into v_guarantor_id;

  return jsonb_build_object(
    'application_id', v_application_id,
    'application_number', (
      select la.application_number
      from public.loan_applications la
      where la.id = v_application_id
    ),
    'borrower_type', 'member',
    'requested_amount', round(p_requested_amount, 2),
    'member_total_savings', v_total_savings,
    'maximum_loan_amount', v_max_loan,
    'service_charge_amount', v_service_charge,
    'total_repayment', v_total_repayment,
    'term_months', v_product.term_months,
    'guarantor_request_id', v_guarantor_id,
    'guarantor_status', 'requested'
  );
end;
$$;

revoke all on function public.submit_member_loan_application_v2(uuid, numeric, text, uuid)
  from public, anon, authenticated;
grant execute on function public.submit_member_loan_application_v2(uuid, numeric, text, uuid)
  to authenticated;

-- ============================================================================
-- 14. Outsider loan submission RPC
--
-- Anonymous endpoint. It creates the application and guarantee request in one
-- transaction. No auth.users row is created.
-- ============================================================================

create or replace function public.submit_outsider_loan_application_v2(
  p_loan_product_id uuid,
  p_full_name text,
  p_phone text,
  p_address text,
  p_requested_amount numeric,
  p_purpose text,
  p_guarantor_member_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_product record;
  v_guarantor record;
  v_guarantor_savings numeric(18,2);
  v_guarantor_max numeric(18,2);
  v_service_charge numeric(18,2);
  v_total_repayment numeric(18,2);
  v_application_id uuid;
  v_guarantor_id uuid;
  v_existing_guarantee boolean;
begin
  if p_full_name is null
     or length(trim(p_full_name)) < 2
     or length(trim(p_full_name)) > 200 then
    raise exception 'Invalid applicant name';
  end if;

  if p_phone is null
     or length(trim(p_phone)) < 7
     or length(trim(p_phone)) > 40 then
    raise exception 'Invalid applicant phone';
  end if;

  if p_address is null
     or length(trim(p_address)) < 3
     or length(trim(p_address)) > 500 then
    raise exception 'Invalid applicant address';
  end if;

  if p_requested_amount is null or p_requested_amount <= 0 then
    raise exception 'Requested loan amount must be greater than zero';
  end if;

  if p_guarantor_member_id is null then
    raise exception 'An active member guarantor is required';
  end if;

  select
    lp.id,
    lp.code,
    lp.borrower_type,
    lp.service_charge_rate,
    least(lp.max_amount, 20000::numeric) as hard_cap,
    lp.term_months,
    lp.active
  into v_product
  from public.loan_products lp
  where lp.id = p_loan_product_id
    and lp.active = true;

  if not found or v_product.borrower_type <> 'outsider' then
    raise exception 'Invalid or inactive outsider loan product';
  end if;

  select m.id, m.status
  into v_guarantor
  from public.members m
  where m.id = p_guarantor_member_id
    and m.status = 'active'
  for update;

  if not found then
    raise exception 'Selected guarantor is not an active member';
  end if;

  select exists(
    select 1
    from public.outsider_loan_guarantors og
    join public.outsider_loan_applications oa
      on oa.id = og.outsider_loan_application_id
    left join public.loans l
      on l.outsider_loan_application_id = oa.id
    where og.guarantor_member_id = p_guarantor_member_id
      and og.status in ('requested', 'accepted')
      and oa.status not in ('rejected', 'cancelled')
      and l.id is null
  )
  into v_existing_guarantee;

  if v_existing_guarantee then
    raise exception 'Selected guarantor already has an outstanding outsider guarantee';
  end if;

  v_guarantor_savings := private.member_total_savings_v2(p_guarantor_member_id);
  v_guarantor_max := least(v_guarantor_savings * 2, v_product.hard_cap, 20000::numeric);

  if p_requested_amount > v_guarantor_max then
    raise exception
      'Requested amount % exceeds guarantor-supported maximum % based on guarantor savings %',
      round(p_requested_amount, 2),
      v_guarantor_max,
      v_guarantor_savings;
  end if;

  v_service_charge := round(p_requested_amount * v_product.service_charge_rate, 2);
  v_total_repayment := round(p_requested_amount + v_service_charge, 2);

  insert into public.outsider_loan_applications(
    loan_product_id,
    applicant_full_name,
    applicant_phone,
    applicant_address,
    requested_amount,
    purpose,
    eligibility_status,
    status,
    eligibility_snapshot,
    submitted_at
  )
  values(
    v_product.id,
    trim(p_full_name),
    trim(p_phone),
    trim(p_address),
    round(p_requested_amount, 2),
    nullif(trim(p_purpose), ''),
    null,
    'submitted',
    jsonb_build_object(
      'loan_model_version', 'v2',
      'borrower_type', 'outsider',
      'guarantor_member_id', p_guarantor_member_id,
      'guarantor_total_savings_at_submission', v_guarantor_savings,
      'guarantor_max_loan_at_submission', v_guarantor_max,
      'requested_amount', round(p_requested_amount, 2),
      'service_charge_rate', v_product.service_charge_rate,
      'service_charge_amount', v_service_charge,
      'total_repayment', v_total_repayment,
      'term_months', v_product.term_months
    ),
    now()
  )
  returning id into v_application_id;

  insert into public.outsider_loan_guarantors(
    outsider_loan_application_id,
    guarantor_member_id,
    requested_amount_snapshot,
    service_charge_rate_snapshot,
    total_repayment_snapshot,
    term_months_snapshot,
    guaranteed_max_amount_snapshot,
    status,
    requested_at
  )
  values(
    v_application_id,
    p_guarantor_member_id,
    round(p_requested_amount, 2),
    v_product.service_charge_rate,
    v_total_repayment,
    v_product.term_months,
    v_guarantor_max,
    'requested',
    now()
  )
  returning id into v_guarantor_id;

  return jsonb_build_object(
    'application_id', v_application_id,
    'application_number', (
      select oa.application_number
      from public.outsider_loan_applications oa
      where oa.id = v_application_id
    ),
    'borrower_type', 'outsider',
    'requested_amount', round(p_requested_amount, 2),
    'guarantor_supported_maximum', v_guarantor_max,
    'service_charge_amount', v_service_charge,
    'total_repayment', v_total_repayment,
    'term_months', v_product.term_months,
    'guarantor_request_id', v_guarantor_id,
    'guarantor_status', 'requested'
  );
end;
$$;

revoke all on function public.submit_outsider_loan_application_v2(uuid, text, text, text, numeric, text, uuid)
  from public, authenticated, anon;
grant execute on function public.submit_outsider_loan_application_v2(uuid, text, text, text, numeric, text, uuid)
  to anon;

-- ============================================================================
-- 15. Member guarantor response RPC
-- ============================================================================

-- ELSE branch. Replace the function with a simpler implementation below to keep
create or replace function public.respond_to_member_loan_guarantor_request_v2(
  p_guarantor_id uuid,
  p_decision public.loan_approval_decision,
  p_rejection_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_member_id uuid;
  v_row public.member_loan_guarantors%rowtype;
  v_new_status public.guarantor_status;
begin
  if v_actor is null then
    raise exception 'Not authenticated';
  end if;

  if not private.current_user_has_permission('guarantor.respond') then
    raise exception 'Unauthorized';
  end if;

  select m.id
  into v_member_id
  from public.members m
  where m.profile_id = v_actor
    and m.status = 'active'
  limit 1;

  if v_member_id is null then
    raise exception 'Only active members can respond as guarantors';
  end if;

  select *
  into v_row
  from public.member_loan_guarantors g
  where g.id = p_guarantor_id
    and g.guarantor_member_id = v_member_id
  for update;

  if not found then
    raise exception 'Guarantee request not found';
  end if;

  if v_row.status <> 'requested' then
    raise exception 'Guarantee request has already been decided';
  end if;

  if p_decision = 'approved' then
    v_new_status := 'accepted';
  elsif p_decision = 'rejected' then
    v_new_status := 'rejected';
  else
    raise exception 'Unsupported guarantor decision';
  end if;

  update public.member_loan_guarantors
  set status = v_new_status,
      responded_at = now(),
      rejected_reason = case
        when v_new_status = 'rejected' then nullif(trim(p_rejection_reason), '')
        else null
      end,
      updated_at = now()
  where id = v_row.id;

  return jsonb_build_object(
    'guarantor_id', v_row.id,
    'status', v_new_status,
    'application_id', v_row.loan_application_id
  );
end;
$$;

revoke all on function public.respond_to_member_loan_guarantor_request_v2(uuid, public.loan_approval_decision, text)
  from public, anon, authenticated;
grant execute on function public.respond_to_member_loan_guarantor_request_v2(uuid, public.loan_approval_decision, text)
  to authenticated;

-- ============================================================================
-- 16. Outsider guarantor response RPC
-- ============================================================================

create or replace function public.respond_to_outsider_loan_guarantor_request_v2(
  p_guarantor_id uuid,
  p_decision public.loan_approval_decision,
  p_rejection_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_member_id uuid;
  v_row public.outsider_loan_guarantors%rowtype;
  v_new_status public.guarantor_status;
begin
  if v_actor is null then
    raise exception 'Not authenticated';
  end if;

  if not private.current_user_has_permission('guarantor.respond') then
    raise exception 'Unauthorized';
  end if;

  select m.id
  into v_member_id
  from public.members m
  where m.profile_id = v_actor
    and m.status = 'active'
  limit 1;

  if v_member_id is null then
    raise exception 'Only active members can respond as guarantors';
  end if;

  select *
  into v_row
  from public.outsider_loan_guarantors g
  where g.id = p_guarantor_id
    and g.guarantor_member_id = v_member_id
  for update;

  if not found then
    raise exception 'Guarantee request not found';
  end if;

  if v_row.status <> 'requested' then
    raise exception 'Guarantee request has already been decided';
  end if;

  if p_decision = 'approved' then
    v_new_status := 'accepted';
  elsif p_decision = 'rejected' then
    v_new_status := 'rejected';
  else
    raise exception 'Unsupported guarantor decision';
  end if;

  -- Final current-savings check when the guarantor accepts.
  if v_new_status = 'accepted'
     and private.outsider_guarantor_max_loan_v2(v_member_id)
           < v_row.requested_amount_snapshot then
    raise exception
      'Current guarantor savings no longer support the requested loan amount';
  end if;

  update public.outsider_loan_guarantors
  set status = v_new_status,
      responded_at = now(),
      rejected_reason = case
        when v_new_status = 'rejected' then nullif(trim(p_rejection_reason), '')
        else null
      end,
      updated_at = now()
  where id = v_row.id;

  return jsonb_build_object(
    'guarantor_id', v_row.id,
    'status', v_new_status,
    'application_id', v_row.outsider_loan_application_id
  );
end;
$$;

revoke all on function public.respond_to_outsider_loan_guarantor_request_v2(uuid, public.loan_approval_decision, text)
  from public, anon, authenticated;
grant execute on function public.respond_to_outsider_loan_guarantor_request_v2(uuid, public.loan_approval_decision, text)
  to authenticated;

-- ============================================================================
-- 17. Member eligibility evaluation V2
-- ============================================================================

create or replace function public.evaluate_member_loan_application_v2(
  p_application_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_app record;
  v_member_active boolean := false;
  v_saving_months integer := 0;
  v_current_obligation_ok boolean := true;
  v_no_overdue boolean := true;
  v_guarantor_ok boolean := false;
  v_savings numeric(18,2) := 0;
  v_max_loan numeric(18,2) := 0;
  v_amount_ok boolean := false;
  v_liquidity jsonb;
  v_liquidity_ok boolean := false;
  v_run_id uuid := gen_random_uuid();
  v_pass boolean;
  v_reasons jsonb := '[]'::jsonb;
  v_manual jsonb := '[]'::jsonb;
  v_snapshot jsonb;
begin
  if v_actor is null then
    raise exception 'Not authenticated';
  end if;

  select
    la.id,
    la.application_number,
    la.applicant_profile_id,
    la.member_id,
    la.requested_amount,
    la.status,
    lp.id as product_id,
    lp.borrower_type,
    lp.service_charge_rate,
    lp.term_months,
    least(lp.max_amount, 20000::numeric) as hard_cap
  into v_app
  from public.loan_applications la
  join public.loan_products lp
    on lp.id = la.loan_product_id
  where la.id = p_application_id
    and lp.borrower_type = 'member'
  for update;

  if not found then
    raise exception 'Member loan application not found';
  end if;

  if not (
    v_app.applicant_profile_id = v_actor
    or private.current_user_has_permission('loan.review')
  ) then
    raise exception 'Unauthorized';
  end if;

  if v_app.status in ('approved', 'rejected', 'cancelled') then
    raise exception 'Application is no longer eligible for evaluation';
  end if;

  select exists(
    select 1
    from public.members m
    where m.id = v_app.member_id
      and m.status = 'active'
  )
  into v_member_active;

  v_savings := private.member_total_savings_v2(v_app.member_id);
  v_max_loan := least(v_savings * 2, v_app.hard_cap, 20000::numeric);
  v_amount_ok := v_app.requested_amount <= v_max_loan;

  select count(*)
  into v_saving_months
  from public.savings_obligations so
  where so.member_id = v_app.member_id
    and so.status = 'paid';

  v_no_overdue := not exists(
    select 1
    from public.loans l
    join public.loan_installments li
      on li.loan_id = l.id
    where l.member_id = v_app.member_id
      and l.status in ('active', 'overdue', 'defaulted')
      and li.paid_amount < li.total_due
      and li.due_date < current_date
  );

  select coalesce(
    case
      when so.id is null then true
      when so.due_date > current_date then true
      else so.paid_amount >= so.required_amount
    end,
    true
  )
  into v_current_obligation_ok
  from public.savings_obligations so
  where so.member_id = v_app.member_id
    and so.period_year = extract(year from current_date)::integer
    and so.period_month = extract(month from current_date)::integer
  limit 1;

  select exists(
    select 1
    from public.member_loan_guarantors g
    where g.loan_application_id = v_app.id
      and g.status = 'accepted'
      and exists(
        select 1
        from public.members gm
        where gm.id = g.guarantor_member_id
          and gm.status = 'active'
      )
  )
  into v_guarantor_ok;

  v_liquidity := private.loan_liquidity_snapshot();
  v_liquidity_ok := coalesce((v_liquidity ->> 'loanable_funds')::numeric, 0)
                     >= v_app.requested_amount;

  -- Repayment capacity has no approved formula, so retain manual review.
  v_manual := jsonb_build_array(
    jsonb_build_object(
      'code', 'REPAYMENT_CAPACITY',
      'status', 'MANUAL_REVIEW',
      'reason', 'No approved repayment-capacity formula is currently configured.'
    )
  );

  v_pass := v_member_active
    and v_saving_months >= 2
    and v_no_overdue
    and v_current_obligation_ok
    and v_amount_ok
    and v_guarantor_ok;

  if not v_member_active then
    v_reasons := v_reasons || jsonb_build_array('ACTIVE_MEMBER_REQUIRED');
  end if;
  if v_saving_months < 2 then
    v_reasons := v_reasons || jsonb_build_array('MINIMUM_SAVING_HISTORY');
  end if;
  if not v_no_overdue then
    v_reasons := v_reasons || jsonb_build_array('OVERDUE_LOAN');
  end if;
  if not v_current_obligation_ok then
    v_reasons := v_reasons || jsonb_build_array('MONTHLY_CONTRIBUTION_NOT_FULFILLED');
  end if;
  if not v_amount_ok then
    v_reasons := v_reasons || jsonb_build_array('AMOUNT_EXCEEDS_MAXIMUM');
  end if;
  if not v_guarantor_ok then
    v_reasons := v_reasons || jsonb_build_array('GUARANTOR_NOT_ACCEPTED');
  end if;
  if not v_liquidity_ok then
    v_manual := v_manual || jsonb_build_array(
      jsonb_build_object(
        'code', 'LIQUIDITY',
        'status', 'MANUAL_REVIEW',
        'reason', 'Current loanable funds are below the requested amount.'
      )
    );
  end if;

  insert into public.loan_eligibility_checks(
    loan_application_id,
    outsider_loan_application_id,
    evaluation_run_id,
    check_code,
    result,
    value,
    reason,
    checked_by
  )
  values
  (
    v_app.id,
    null,
    v_run_id,
    'ACTIVE_MEMBER',
    v_member_active,
    v_member_active::text,
    case when v_member_active then 'Active member' else 'Member is not active' end,
    v_actor
  ),
  (
    v_app.id,
    null,
    v_run_id,
    'MINIMUM_SAVING_HISTORY',
    v_saving_months >= 2,
    v_saving_months::text,
    case when v_saving_months >= 2 then 'At least two paid saving months' else 'Fewer than two paid saving months' end,
    v_actor
  ),
  (
    v_app.id,
    null,
    v_run_id,
    'NO_OVERDUE_LOAN',
    v_no_overdue,
    v_no_overdue::text,
    case when v_no_overdue then 'No overdue loan' else 'Applicant has an overdue loan' end,
    v_actor
  ),
  (
    v_app.id,
    null,
    v_run_id,
    'MONTHLY_CONTRIBUTION',
    v_current_obligation_ok,
    v_current_obligation_ok::text,
    case when v_current_obligation_ok then 'Current mandatory contribution condition satisfied' else 'Current mandatory contribution not fulfilled' end,
    v_actor
  ),
  (
    v_app.id,
    null,
    v_run_id,
    'MAX_LOAN_AMOUNT',
    v_amount_ok,
    jsonb_build_object(
      'total_savings', v_savings,
      'calculated_maximum', v_max_loan,
      'requested_amount', v_app.requested_amount,
      'formula', 'MIN(total_savings * 2, 20000)'
    )::text,
    case when v_amount_ok then 'Requested amount is within member maximum' else 'Requested amount exceeds member maximum' end,
    v_actor
  ),
  (
    v_app.id,
    null,
    v_run_id,
    'GUARANTOR',
    v_guarantor_ok,
    v_guarantor_ok::text,
    case when v_guarantor_ok then 'Guarantor accepted' else 'Active accepted guarantor required' end,
    v_actor
  ),
  (
    v_app.id,
    null,
    v_run_id,
    'LIQUIDITY',
    v_liquidity_ok,
    v_liquidity::text,
    case when v_liquidity_ok then 'Current loanable funds are sufficient' else 'Loanable funds are below requested amount' end,
    v_actor
  );

  v_snapshot := jsonb_build_object(
    'loan_model_version', 'v2',
    'borrower_type', 'member',
    'active_member', v_member_active,
    'saving_months', v_saving_months,
    'member_total_savings', v_savings,
    'member_max_loan', v_max_loan,
    'requested_amount', v_app.requested_amount,
    'amount_ok', v_amount_ok,
    'no_overdue_loan', v_no_overdue,
    'monthly_contribution_ok', v_current_obligation_ok,
    'guarantor_ok', v_guarantor_ok,
    'liquidity_ok', v_liquidity_ok,
    'liquidity_snapshot', v_liquidity,
    'manual_reviews', v_manual,
    'reasons', v_reasons,
    'evaluated_at', now()
  );

  update public.loan_applications
  set eligibility_status = case when v_pass then 'eligible' else 'ineligible' end,
      eligibility_snapshot = v_snapshot,
      eligibility_evaluated_at = now(),
      updated_at = now()
  where id = v_app.id;

  return jsonb_build_object(
    'application_id', v_app.id,
    'eligible', v_pass,
    'reasons', v_reasons,
    'member_total_savings', v_savings,
    'maximum_loan_amount', v_max_loan,
    'requested_amount', v_app.requested_amount,
    'guarantor_accepted', v_guarantor_ok,
    'liquidity_ok', v_liquidity_ok,
    'manual_reviews', v_manual
  );
end;
$$;

revoke all on function public.evaluate_member_loan_application_v2(uuid)
  from public, anon;
grant execute on function public.evaluate_member_loan_application_v2(uuid)
  to authenticated;

-- ============================================================================
-- 18. Outsider eligibility evaluation V2
-- ============================================================================

create or replace function public.evaluate_outsider_loan_application_v2(
  p_application_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_is_admin boolean := false;
  v_app record;
  v_guarantee record;
  v_guarantor_active boolean := false;
  v_guarantor_savings numeric(18,2) := 0;
  v_guarantor_max numeric(18,2) := 0;
  v_amount_ok boolean := false;
  v_liquidity jsonb;
  v_liquidity_ok boolean := false;
  v_one_outstanding_ok boolean := false;
  v_run_id uuid := gen_random_uuid();
  v_pass boolean;
  v_reasons jsonb := '[]'::jsonb;
  v_snapshot jsonb;
begin
  if v_actor is null then
    raise exception 'Not authenticated';
  end if;

  v_is_admin := private.current_user_has_permission('loan.review');

  select
    oa.id,
    oa.application_number,
    oa.requested_amount,
    oa.status,
    oa.loan_product_id,
    lp.borrower_type,
    lp.service_charge_rate,
    lp.term_months,
    least(lp.max_amount, 20000::numeric) as hard_cap
  into v_app
  from public.outsider_loan_applications oa
  join public.loan_products lp
    on lp.id = oa.loan_product_id
  where oa.id = p_application_id
    and lp.borrower_type = 'outsider'
  for update;

  if not found then
    raise exception 'Outsider loan application not found';
  end if;

  if not v_is_admin then
    raise exception 'Only authorized reviewers can evaluate outsider applications';
  end if;

  if v_app.status in ('approved', 'rejected', 'cancelled') then
    raise exception 'Application is no longer eligible for evaluation';
  end if;

  select *
  into v_guarantee
  from public.outsider_loan_guarantors og
  where og.outsider_loan_application_id = v_app.id
  for update;

  if not found then
    raise exception 'Outsider loan requires a guarantor request';
  end if;

  select exists(
    select 1
    from public.members m
    where m.id = v_guarantee.guarantor_member_id
      and m.status = 'active'
  )
  into v_guarantor_active;

  v_guarantor_savings := private.member_total_savings_v2(v_guarantee.guarantor_member_id);
  v_guarantor_max := least(v_guarantor_savings * 2, v_app.hard_cap, 20000::numeric);
  v_amount_ok := v_app.requested_amount <= v_guarantor_max;

  v_one_outstanding_ok := not exists(
    select 1
    from public.outsider_loan_guarantors og
    join public.outsider_loan_applications oa
      on oa.id = og.outsider_loan_application_id
    left join public.loans l
      on l.outsider_loan_application_id = oa.id
    where og.guarantor_member_id = v_guarantee.guarantor_member_id
      and og.id <> v_guarantee.id
      and og.status in ('requested', 'accepted')
      and oa.status not in ('rejected', 'cancelled')
      and l.id is null
  );

  v_liquidity := private.loan_liquidity_snapshot();
  v_liquidity_ok := coalesce((v_liquidity ->> 'loanable_funds')::numeric, 0)
                     >= v_app.requested_amount;

  if v_guarantee.status <> 'accepted' then
    v_reasons := v_reasons || jsonb_build_array('GUARANTOR_NOT_ACCEPTED');
  end if;
  if not v_guarantor_active then
    v_reasons := v_reasons || jsonb_build_array('GUARANTOR_NOT_ACTIVE');
  end if;
  if not v_one_outstanding_ok then
    v_reasons := v_reasons || jsonb_build_array('GUARANTOR_ALREADY_HAS_OUTSTANDING_OUTSIDER_GUARANTEE');
  end if;
  if not v_amount_ok then
    v_reasons := v_reasons || jsonb_build_array('AMOUNT_EXCEEDS_GUARANTOR_SUPPORTED_MAXIMUM');
  end if;
  if not v_liquidity_ok then
    v_reasons := v_reasons || jsonb_build_array('LIQUIDITY_INSUFFICIENT');
  end if;

  v_pass := v_guarantee.status = 'accepted'
    and v_guarantor_active
    and v_one_outstanding_ok
    and v_amount_ok;

  insert into public.loan_eligibility_checks(
    loan_application_id,
    outsider_loan_application_id,
    evaluation_run_id,
    check_code,
    result,
    value,
    reason,
    checked_by
  )
  values
  (
    null,
    v_app.id,
    v_run_id,
    'GUARANTOR_ACCEPTED',
    v_guarantee.status = 'accepted',
    v_guarantee.status::text,
    case when v_guarantee.status = 'accepted' then 'Guarantor accepted' else 'Guarantor has not accepted' end,
    v_actor
  ),
  (
    null,
    v_app.id,
    v_run_id,
    'GUARANTOR_ACTIVE',
    v_guarantor_active,
    v_guarantor_active::text,
    case when v_guarantor_active then 'Guarantor is active' else 'Guarantor is inactive' end,
    v_actor
  ),
  (
    null,
    v_app.id,
    v_run_id,
    'GUARANTOR_OUTSTANDING_LIMIT',
    v_one_outstanding_ok,
    v_one_outstanding_ok::text,
    case when v_one_outstanding_ok then 'Guarantor is not already responsible for another outstanding outsider loan' else 'Guarantor already has an outstanding outsider guarantee' end,
    v_actor
  ),
  (
    null,
    v_app.id,
    v_run_id,
    'GUARANTOR_MAX_LOAN_AMOUNT',
    v_amount_ok,
    jsonb_build_object(
      'guarantor_total_savings', v_guarantor_savings,
      'calculated_maximum', v_guarantor_max,
      'requested_amount', v_app.requested_amount,
      'formula', 'MIN(guarantor_total_savings * 2, 20000)'
    )::text,
    case when v_amount_ok then 'Requested amount is within guarantor-supported maximum' else 'Requested amount exceeds guarantor-supported maximum' end,
    v_actor
  ),
  (
    null,
    v_app.id,
    v_run_id,
    'LIQUIDITY',
    v_liquidity_ok,
    v_liquidity::text,
    case when v_liquidity_ok then 'Current loanable funds are sufficient' else 'Loanable funds are below requested amount' end,
    v_actor
  );

  v_snapshot := jsonb_build_object(
    'loan_model_version', 'v2',
    'borrower_type', 'outsider',
    'guarantor_member_id', v_guarantee.guarantor_member_id,
    'guarantor_active', v_guarantor_active,
    'guarantor_status', v_guarantee.status,
    'guarantor_total_savings', v_guarantor_savings,
    'guarantor_max_loan', v_guarantor_max,
    'requested_amount', v_app.requested_amount,
    'amount_ok', v_amount_ok,
    'one_outstanding_guarantee_ok', v_one_outstanding_ok,
    'liquidity_ok', v_liquidity_ok,
    'liquidity_snapshot', v_liquidity,
    'reasons', v_reasons,
    'evaluated_at', now()
  );

  update public.outsider_loan_applications
  set eligibility_status = case when v_pass then 'eligible' else 'ineligible' end,
      eligibility_snapshot = v_snapshot,
      eligibility_evaluated_at = now(),
      updated_at = now()
  where id = v_app.id;

  return jsonb_build_object(
    'application_id', v_app.id,
    'eligible', v_pass,
    'reasons', v_reasons,
    'guarantor_total_savings', v_guarantor_savings,
    'maximum_loan_amount', v_guarantor_max,
    'requested_amount', v_app.requested_amount,
    'guarantor_status', v_guarantee.status,
    'liquidity_ok', v_liquidity_ok
  );
end;
$$;

revoke all on function public.evaluate_outsider_loan_application_v2(uuid)
  from public, anon;
grant execute on function public.evaluate_outsider_loan_application_v2(uuid)
  to authenticated;

-- ============================================================================
-- 19. Convenience RPC: member maximum loan preview
-- ============================================================================

create or replace function public.get_my_member_loan_limit_v2()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_member_id uuid;
  v_savings numeric(18,2);
  v_max numeric(18,2);
begin
  if v_actor is null then
    raise exception 'Not authenticated';
  end if;

  select m.id
  into v_member_id
  from public.members m
  where m.profile_id = v_actor
    and m.status = 'active'
  limit 1;

  if v_member_id is null then
    raise exception 'Only active members have a member loan limit';
  end if;

  v_savings := private.member_total_savings_v2(v_member_id);
  v_max := least(v_savings * 2, 20000::numeric);

  return jsonb_build_object(
    'member_id', v_member_id,
    'total_savings', v_savings,
    'maximum_loan_amount', v_max,
    'global_cap', 20000,
    'formula', 'MIN(total_savings * 2, 20000)'
  );
end;
$$;

revoke all on function public.get_my_member_loan_limit_v2()
  from public, anon;
grant execute on function public.get_my_member_loan_limit_v2()
  to authenticated;


-- ============================================================================
-- 20. Release accepted guarantees when pre-disbursement applications end.
-- ============================================================================

create or replace function private.release_loan_guarantor_on_application_end_v2()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.status in ('rejected', 'cancelled')
     and old.status is distinct from new.status then
    update public.member_loan_guarantors
    set status = 'released',
        responded_at = coalesce(responded_at, now()),
        updated_at = now()
    where loan_application_id = new.id
      and status in ('requested', 'accepted');
  end if;
  return new;
end;
$$;

revoke all on function private.release_loan_guarantor_on_application_end_v2()
  from public, anon, authenticated;

drop trigger if exists release_member_loan_guarantor_on_application_end_v2
  on public.loan_applications;

create trigger release_member_loan_guarantor_on_application_end_v2
after update of status on public.loan_applications
for each row execute procedure private.release_loan_guarantor_on_application_end_v2();

create or replace function private.release_outsider_guarantor_on_application_end_v2()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.status in ('rejected', 'cancelled')
     and old.status is distinct from new.status then
    update public.outsider_loan_guarantors
    set status = 'released',
        responded_at = coalesce(responded_at, now()),
        updated_at = now()
    where outsider_loan_application_id = new.id
      and status in ('requested', 'accepted');
  end if;
  return new;
end;
$$;

revoke all on function private.release_outsider_guarantor_on_application_end_v2()
  from public, anon, authenticated;

drop trigger if exists release_outsider_guarantor_on_application_end_v2
  on public.outsider_loan_applications;

create trigger release_outsider_guarantor_on_application_end_v2
after update of status on public.outsider_loan_applications
for each row execute procedure private.release_outsider_guarantor_on_application_end_v2();

create or replace function private.release_v2_guarantee_on_loan_paid()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.status in ('paid', 'cancelled')
     and old.status is distinct from new.status then
    update public.member_loan_guarantors
    set status = 'released',
        responded_at = coalesce(responded_at, now()),
        updated_at = now()
    where loan_application_id = new.loan_application_id
      and status = 'accepted';

    update public.outsider_loan_guarantors
    set status = 'released',
        responded_at = coalesce(responded_at, now()),
        updated_at = now()
    where outsider_loan_application_id = new.outsider_loan_application_id
      and status = 'accepted';
  end if;
  return new;
end;
$$;

revoke all on function private.release_v2_guarantee_on_loan_paid()
  from public, anon, authenticated;

drop trigger if exists release_v2_guarantee_on_loan_paid
  on public.loans;

create trigger release_v2_guarantee_on_loan_paid
after update of status on public.loans
for each row execute procedure private.release_v2_guarantee_on_loan_paid();

-- ============================================================================
-- 21. Approve/reject an application from either source.
--
-- Approval threshold is two DISTINCT authorized profiles. Approval amount is
-- fixed after the first approval and may only be equal or lower than the
-- requested amount. It may not exceed the authoritative V2 maximum.
-- ============================================================================

create or replace function public.review_loan_application_v2(
  p_borrower_type public.loan_borrower_type,
  p_application_id uuid,
  p_decision public.loan_approval_decision,
  p_approved_amount numeric default null,
  p_comment text default null,
  p_manual_checks jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_member_application record;
  v_outsider_application record;
  v_existing_approved_amount numeric(18,2);
  v_requested numeric(18,2);
  v_max numeric(18,2);
  v_approved numeric(18,2);
  v_approved_count integer;
  v_new_status public.loan_application_status;
  v_eval jsonb;
begin
  if v_actor is null then
    raise exception 'Not authenticated';
  end if;
  if not private.current_user_has_permission('loan.review') then
    raise exception 'Unauthorized';
  end if;
  if p_decision not in ('approved', 'rejected') then
    raise exception 'Unsupported loan decision';
  end if;

  if p_borrower_type = 'member' then
    select la.*, lp.service_charge_rate, lp.term_months
      into v_member_application
    from public.loan_applications la
    join public.loan_products lp on lp.id = la.loan_product_id
    where la.id = p_application_id
      and lp.borrower_type = 'member'
    for update;

    if not found then
      raise exception 'Member loan application not found';
    end if;

    if v_member_application.status not in ('under_review', 'eligible', 'submitted') then
      raise exception 'Member loan application is not reviewable in its current state';
    end if;

    if v_member_application.applicant_profile_id = v_actor then
      raise exception 'Borrower cannot approve their own loan';
    end if;

    v_eval := public.evaluate_member_loan_application_v2(p_application_id);
    if p_decision = 'approved' and coalesce((v_eval->>'eligible')::boolean, false) is not true then
      raise exception 'Application is not currently eligible for approval';
    end if;

    v_requested := v_member_application.requested_amount;
    v_max := private.member_max_loan_v2(v_member_application.member_id);
    v_existing_approved_amount := v_member_application.approved_amount;

  else
    select oa.*, lp.service_charge_rate, lp.term_months
      into v_outsider_application
    from public.outsider_loan_applications oa
    join public.loan_products lp on lp.id = oa.loan_product_id
    where oa.id = p_application_id
      and lp.borrower_type = 'outsider'
    for update;

    if not found then
      raise exception 'Outsider loan application not found';
    end if;

    if v_outsider_application.status not in ('under_review', 'eligible', 'submitted') then
      raise exception 'Outsider loan application is not reviewable in its current state';
    end if;

    v_eval := public.evaluate_outsider_loan_application_v2(p_application_id);
    if p_decision = 'approved' and coalesce((v_eval->>'eligible')::boolean, false) is not true then
      raise exception 'Application is not currently eligible for approval';
    end if;

    v_requested := v_outsider_application.requested_amount;
    v_max := private.outsider_guarantor_max_loan_v2(
      (select guarantor_member_id
       from public.outsider_loan_guarantors
       where outsider_loan_application_id = p_application_id)
    );
    v_existing_approved_amount := v_outsider_application.approved_amount;
  end if;

  if p_decision = 'approved' then
    v_approved := round(coalesce(p_approved_amount, v_existing_approved_amount, v_requested), 2);
    if v_approved <= 0 then
      raise exception 'Approved amount must be greater than zero';
    end if;
    if v_approved > v_requested then
      raise exception 'Approved amount cannot exceed requested amount';
    end if;
    if v_approved > v_max then
      raise exception 'Approved amount exceeds the current authoritative maximum of % ETB', v_max;
    end if;
    if v_existing_approved_amount is not null
       and v_existing_approved_amount <> v_approved then
      raise exception 'Approved amount must match the amount already set by the first approver';
    end if;
  else
    v_approved := null;
  end if;

  if p_borrower_type = 'member' then
    insert into public.loan_approvals(
      loan_application_id,
      outsider_loan_application_id,
      approver_profile_id,
      decision,
      comment,
      manual_checks,
      decided_at
    ) values (
      p_application_id,
      null,
      v_actor,
      p_decision,
      nullif(trim(p_comment), ''),
      coalesce(p_manual_checks, '{}'::jsonb),
      now()
    );
  else
    insert into public.loan_approvals(
      loan_application_id,
      outsider_loan_application_id,
      approver_profile_id,
      decision,
      comment,
      manual_checks,
      decided_at
    ) values (
      null,
      p_application_id,
      v_actor,
      p_decision,
      nullif(trim(p_comment), ''),
      coalesce(p_manual_checks, '{}'::jsonb),
      now()
    );
  end if;

  if p_decision = 'rejected' then
    v_new_status := 'rejected';
  else
    if p_borrower_type = 'member' then
      update public.loan_applications
      set approved_amount = v_approved,
          updated_at = now()
      where id = p_application_id;
      select count(*) into v_approved_count
      from public.loan_approvals
      where loan_application_id = p_application_id
        and decision = 'approved';
      if v_approved_count >= 2 then
        v_new_status := 'approved';
        update public.loan_applications
        set status = 'approved', approved_amount = v_approved, approved_at = now(), updated_at = now()
        where id = p_application_id;
      else
        v_new_status := 'under_review';
        update public.loan_applications
        set status = 'under_review', approved_amount = v_approved, updated_at = now()
        where id = p_application_id;
      end if;
    else
      update public.outsider_loan_applications
      set approved_amount = v_approved,
          updated_at = now()
      where id = p_application_id;
      select count(*) into v_approved_count
      from public.loan_approvals
      where outsider_loan_application_id = p_application_id
        and decision = 'approved';
      if v_approved_count >= 2 then
        v_new_status := 'approved';
        update public.outsider_loan_applications
        set status = 'approved', approved_amount = v_approved, approved_at = now(), updated_at = now()
        where id = p_application_id;
      else
        v_new_status := 'under_review';
        update public.outsider_loan_applications
        set status = 'under_review', approved_amount = v_approved, updated_at = now()
        where id = p_application_id;
      end if;
    end if;
  end if;

  if p_decision = 'rejected' then
    if p_borrower_type = 'member' then
      update public.loan_applications
      set status = 'rejected', updated_at = now()
      where id = p_application_id;
    else
      update public.outsider_loan_applications
      set status = 'rejected', updated_at = now()
      where id = p_application_id;
    end if;
    select 0 into v_approved_count;
  end if;

  insert into public.audit_logs(
    actor_user_id, action, entity_type, entity_id, new_data, metadata
  ) values (
    v_actor,
    case when p_decision = 'approved' then 'LOAN_APPROVAL_RECORDED' else 'LOAN_REJECTION_RECORDED' end,
    case when p_borrower_type = 'member' then 'loan_application' else 'outsider_loan_application' end,
    p_application_id,
    jsonb_build_object('decision', p_decision, 'status', v_new_status, 'approved_amount', v_approved),
    jsonb_build_object('manual_checks', coalesce(p_manual_checks, '{}'::jsonb))
  );

  return jsonb_build_object(
    'borrower_type', p_borrower_type,
    'application_id', p_application_id,
    'application_status', v_new_status,
    'approved_amount', v_approved,
    'approved_count', coalesce(v_approved_count, 0)
  );
exception
  when unique_violation then
    raise exception 'This reviewer has already reviewed this application';
end;
$$;

revoke all on function public.review_loan_application_v2(public.loan_borrower_type, uuid, public.loan_approval_decision, numeric, text, jsonb)
  from public, anon;
grant execute on function public.review_loan_application_v2(public.loan_borrower_type, uuid, public.loan_approval_decision, numeric, text, jsonb)
  to authenticated;

-- ============================================================================
-- 22. Unified V2 disbursement for member and outsider applications.
-- ============================================================================

create or replace function public.disburse_loan_v2(
  p_borrower_type public.loan_borrower_type,
  p_application_id uuid,
  p_source_account_code text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_source_type public.account_type_code;
  v_source_account_id uuid;
  v_receivable_account_id uuid;
  v_service_income_account_id uuid;
  v_application record;
  v_guarantee record;
  v_approved_count integer;
  v_approved_principal numeric(18,2);
  v_service_charge numeric(18,2);
  v_total_repayment numeric(18,2);
  v_loan_id uuid;
  v_disbursement_transaction_id uuid;
  v_disbursement_id uuid;
  v_maturity_date date;
  v_disbursed_at timestamptz := now();
  v_i integer;
  v_terms integer;
  v_principal_per numeric(18,2);
  v_service_per numeric(18,2);
  v_p numeric(18,2);
  v_s numeric(18,2);
  v_total numeric(18,2);
  v_liquidity jsonb;
begin
  if v_actor is null then raise exception 'Not authenticated'; end if;
  if not private.current_user_has_permission('loan.disburse') then raise exception 'Unauthorized'; end if;

  v_source_type := case lower(trim(p_source_account_code))
    when 'cash' then 'cash'::public.account_type_code
    when 'bank' then 'bank'::public.account_type_code
    when 'wallet' then 'wallet'::public.account_type_code
    else null
  end;
  if v_source_type is null then raise exception 'Invalid disbursement source account'; end if;

  if p_borrower_type = 'member' then
    select la.*, lp.service_charge_rate, lp.term_months, lp.borrower_type
      into v_application
    from public.loan_applications la
    join public.loan_products lp on lp.id = la.loan_product_id
    where la.id = p_application_id and lp.borrower_type = 'member'
    for update;
    if not found then raise exception 'Member loan application not found'; end if;
    if v_application.status <> 'approved' then raise exception 'Member application is not approved'; end if;
    select count(*) into v_approved_count
    from public.loan_approvals
    where loan_application_id = p_application_id and decision = 'approved';
    if v_approved_count < 2 then raise exception 'At least two distinct approvals are required'; end if;
    if private.member_max_loan_v2(v_application.member_id) < coalesce(v_application.approved_amount, v_application.requested_amount) then
      raise exception 'Current member savings no longer support the approved amount';
    end if;
    select * into v_guarantee from public.member_loan_guarantors
    where loan_application_id = p_application_id and status = 'accepted' for update;
    if not found then raise exception 'Member loan requires an accepted guarantor'; end if;
  else
    select oa.*, lp.service_charge_rate, lp.term_months, lp.borrower_type
      into v_application
    from public.outsider_loan_applications oa
    join public.loan_products lp on lp.id = oa.loan_product_id
    where oa.id = p_application_id and lp.borrower_type = 'outsider'
    for update;
    if not found then raise exception 'Outsider loan application not found'; end if;
    if v_application.status <> 'approved' then raise exception 'Outsider application is not approved'; end if;
    select count(*) into v_approved_count
    from public.loan_approvals
    where outsider_loan_application_id = p_application_id and decision = 'approved';
    if v_approved_count < 2 then raise exception 'At least two distinct approvals are required'; end if;
    select * into v_guarantee from public.outsider_loan_guarantors
    where outsider_loan_application_id = p_application_id and status = 'accepted' for update;
    if not found then raise exception 'Outsider loan requires an accepted guarantor'; end if;
    if not exists (select 1 from public.members where id = v_guarantee.guarantor_member_id and status = 'active') then
      raise exception 'Guarantor is no longer active';
    end if;
    if private.outsider_guarantor_max_loan_v2(v_guarantee.guarantor_member_id) < coalesce(v_application.approved_amount, v_application.requested_amount) then
      raise exception 'Current guarantor savings no longer support the approved amount';
    end if;
  end if;

  if exists (
    select 1 from public.loans l
    where (p_borrower_type = 'member' and l.loan_application_id = p_application_id)
       or (p_borrower_type = 'outsider' and l.outsider_loan_application_id = p_application_id)
  ) then
    raise exception 'Loan has already been disbursed';
  end if;

  v_approved_principal := round(coalesce(v_application.approved_amount, v_application.requested_amount), 2);
  if v_approved_principal <= 0 or v_approved_principal > v_application.requested_amount then
    raise exception 'Invalid approved loan amount';
  end if;

  v_liquidity := private.loan_liquidity_snapshot();
  if not coalesce((v_liquidity->>'reserve_compliant')::boolean, false)
     or coalesce((v_liquidity->>'loanable_funds')::numeric,0) < v_approved_principal then
    raise exception 'Insufficient liquidity for disbursement';
  end if;

  v_source_account_id := private.system_account_id(v_source_type);
  v_receivable_account_id := private.system_account_id('loan_receivable'::public.account_type_code);
  v_service_income_account_id := private.system_account_id('loan_service_charge_income'::public.account_type_code);
  if v_source_account_id is null or v_receivable_account_id is null or v_service_income_account_id is null then
    raise exception 'Loan accounting accounts are not configured';
  end if;
  if private.account_balance(v_source_account_id) < v_approved_principal then
    raise exception 'Selected disbursement account does not have sufficient funds';
  end if;

  v_service_charge := round(v_approved_principal * v_application.service_charge_rate, 2);
  v_total_repayment := round(v_approved_principal + v_service_charge, 2);

  if p_borrower_type = 'member' then
    insert into public.loans(
      loan_application_id, outsider_loan_application_id, borrower_profile_id, member_id,
      principal, service_charge_rate, service_charge_amount, total_repayment,
      term_months, status, disbursed_at, maturity_date
    ) values(
      p_application_id, null, v_application.applicant_profile_id, v_application.member_id,
      v_approved_principal, v_application.service_charge_rate, v_service_charge, v_total_repayment,
      v_application.term_months, 'active', v_disbursed_at,
      (v_disbursed_at::date + make_interval(months => v_application.term_months))::date
    ) returning id, maturity_date into v_loan_id, v_maturity_date;
  else
    insert into public.loans(
      loan_application_id, outsider_loan_application_id, borrower_profile_id, member_id,
      principal, service_charge_rate, service_charge_amount, total_repayment,
      term_months, status, disbursed_at, maturity_date
    ) values(
      null, p_application_id, null, null,
      v_approved_principal, v_application.service_charge_rate, v_service_charge, v_total_repayment,
      v_application.term_months, 'active', v_disbursed_at,
      (v_disbursed_at::date + make_interval(months => v_application.term_months))::date
    ) returning id, maturity_date into v_loan_id, v_maturity_date;
  end if;

  v_disbursement_transaction_id := private.post_balanced_transaction(
    'loan_disbursement'::public.transaction_type,
    case when p_borrower_type = 'member' then v_application.applicant_profile_id else null end,
    case when p_borrower_type = 'member' then v_application.member_id else null end,
    v_total_repayment,
    'loan',
    v_loan_id,
    case when p_borrower_type = 'member' then 'Member loan disbursement' else 'Outsider loan disbursement' end,
    jsonb_build_array(
      jsonb_build_object('account_id', v_receivable_account_id, 'entry_type', 'debit', 'amount', v_total_repayment),
      jsonb_build_object('account_id', v_source_account_id, 'entry_type', 'credit', 'amount', v_approved_principal),
      jsonb_build_object('account_id', v_service_income_account_id, 'entry_type', 'credit', 'amount', v_service_charge)
    )
  );

  v_terms := v_application.term_months;
  if v_terms <= 0 then raise exception 'Invalid loan term'; end if;
  v_principal_per := round(v_approved_principal / v_terms, 2);
  v_service_per := round(v_service_charge / v_terms, 2);
  for v_i in 1..v_terms loop
    if v_i < v_terms then
      v_p := v_principal_per; v_s := v_service_per;
    else
      v_p := round(v_approved_principal - v_principal_per * (v_terms - 1), 2);
      v_s := round(v_service_charge - v_service_per * (v_terms - 1), 2);
    end if;
    v_total := round(v_p + v_s, 2);
    insert into public.loan_installments(
      loan_id, installment_number, due_date, principal_amount,
      service_charge_amount, total_due, paid_amount, late_penalty_amount, paid_penalty_amount, status
    ) values(
      v_loan_id, v_i,
      (v_disbursed_at::date + make_interval(months => v_i))::date,
      v_p, v_s, v_total, 0, 0, 0, 'pending'
    );
  end loop;

  insert into public.loan_disbursements(
    loan_id, amount, payment_method_code, transaction_id, released_by, released_at, notes
  ) values(
    v_loan_id, v_approved_principal, v_source_type::text, v_disbursement_transaction_id, v_actor, now(),
    case when p_borrower_type = 'outsider' then 'Outsider loan disbursement' else 'Member loan disbursement' end
  ) returning id into v_disbursement_id;

  insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, new_data, metadata)
  values(
    v_actor, 'LOAN_DISBURSED', 'loan', v_loan_id,
    jsonb_build_object('borrower_type', p_borrower_type, 'principal', v_approved_principal,
      'service_charge', v_service_charge, 'total_repayment', v_total_repayment, 'term_months', v_terms),
    jsonb_build_object('application_id', p_application_id, 'transaction_id', v_disbursement_transaction_id,
      'disbursement_id', v_disbursement_id, 'liquidity_snapshot', v_liquidity)
  );

  return jsonb_build_object(
    'loan_id', v_loan_id,
    'principal', v_approved_principal,
    'service_charge', v_service_charge,
    'total_repayment', v_total_repayment,
    'term_months', v_terms,
    'maturity_date', v_maturity_date,
    'transaction_id', v_disbursement_transaction_id
  );
end;
$$;

revoke all on function public.disburse_loan_v2(public.loan_borrower_type, uuid, text) from public, anon;
grant execute on function public.disburse_loan_v2(public.loan_borrower_type, uuid, text) to authenticated;

-- ============================================================================
-- 23. Member-facing guarantor inbox combines both application sources.
-- ============================================================================

create or replace function public.get_my_guarantor_requests_v2()
returns jsonb
language sql
stable
security invoker
as $$
  select jsonb_build_object(
    'member_requests', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', g.id,
        'borrower_type', 'member',
        'application_id', g.loan_application_id,
        'status', g.status,
        'requested_amount', g.requested_amount_snapshot,
        'service_charge_rate', g.service_charge_rate_snapshot,
        'total_repayment', g.total_repayment_snapshot,
        'term_months', g.term_months_snapshot,
        'requested_at', g.requested_at,
        'applicant_name', coalesce(p.full_name, m.member_number)
      ) order by g.requested_at desc)
      from public.member_loan_guarantors g
      join public.loan_applications la on la.id = g.loan_application_id
      join public.members m on m.id = la.member_id
      join public.profiles p on p.id = m.profile_id
      join public.members gm on gm.id = g.guarantor_member_id
      where gm.profile_id = (select auth.uid())
    ), '[]'::jsonb),
    'outsider_requests', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', g.id,
        'borrower_type', 'outsider',
        'application_id', g.outsider_loan_application_id,
        'status', g.status,
        'requested_amount', g.requested_amount_snapshot,
        'service_charge_rate', g.service_charge_rate_snapshot,
        'total_repayment', g.total_repayment_snapshot,
        'term_months', g.term_months_snapshot,
        'requested_at', g.requested_at,
        'applicant_name', oa.applicant_full_name,
        'applicant_phone', oa.applicant_phone
      ) order by g.requested_at desc)
      from public.outsider_loan_guarantors g
      join public.outsider_loan_applications oa on oa.id = g.outsider_loan_application_id
      join public.members gm on gm.id = g.guarantor_member_id
      where gm.profile_id = (select auth.uid())
    ), '[]'::jsonb)
  );
$$;
revoke all on function public.get_my_guarantor_requests_v2() from public, anon;
grant execute on function public.get_my_guarantor_requests_v2() to authenticated;

-- ============================================================================
-- 24. Disable old RPCs that assume a single mixed borrower table.
-- ============================================================================

do $$
declare
  r record;
begin
  for r in
    select n.nspname, p.proname, pg_get_function_identity_arguments(p.oid) as args
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in (
        'submit_loan_application',
        'evaluate_loan_application',
        'request_loan_guarantor',
        'respond_to_loan_guarantor_request',
        'review_loan_application',
        'cancel_loan_application',
        'disburse_loan'
      )
  loop
    execute format('revoke all on function %I.%I(%s) from public, anon, authenticated', r.nspname, r.proname, r.args);
  end loop;
end;
$$;

-- ============================================================================
-- 25. V2 verification helpers.
-- ============================================================================

-- ============================================================================
-- 20. RLS and explicit grants
--
-- New tables are exposed only through explicit grants + RLS.
-- Anonymous users can execute the two narrowly-scoped public functions but may
-- not select from authoritative outsider/member/guarantor tables.
-- ============================================================================

alter table public.outsider_loan_applications enable row level security;
alter table public.member_loan_guarantors enable row level security;
alter table public.outsider_loan_guarantors enable row level security;

revoke all on public.outsider_loan_applications from anon, authenticated;
revoke all on public.member_loan_guarantors from anon, authenticated;
revoke all on public.outsider_loan_guarantors from anon, authenticated;

-- Read access is explicit and policy controlled. No INSERT/UPDATE/DELETE grants.
grant select on public.outsider_loan_applications to authenticated;
grant select on public.member_loan_guarantors to authenticated;
grant select on public.outsider_loan_guarantors to authenticated;

-- Member applications/loans/approvals/eligibility: remove direct mutation grants.
revoke insert, update, delete on public.loan_applications from anon, authenticated;
revoke insert, update, delete on public.loans from anon, authenticated;
revoke insert, update, delete on public.loan_approvals from anon, authenticated;
revoke insert, update, delete on public.loan_eligibility_checks from anon, authenticated;

-- Ensure authenticated users can read their own records where policies allow it.
grant select on public.loan_applications to authenticated;
grant select on public.loans to authenticated;
grant select on public.loan_approvals to authenticated;
grant select on public.loan_eligibility_checks to authenticated;

-- Existing policy names are installation-dependent, so remove only V2 names here.
drop policy if exists outsider_loan_applications_admin_select_v2
  on public.outsider_loan_applications;
drop policy if exists member_loan_guarantors_self_select_v2
  on public.member_loan_guarantors;
drop policy if exists member_loan_guarantors_admin_select_v2
  on public.member_loan_guarantors;
drop policy if exists outsider_loan_guarantors_self_select_v2
  on public.outsider_loan_guarantors;
drop policy if exists outsider_loan_guarantors_admin_select_v2
  on public.outsider_loan_guarantors;

create policy outsider_loan_applications_admin_select_v2
on public.outsider_loan_applications
for select
 to authenticated
using ((select private.current_user_has_permission('loan.review')));

create policy member_loan_guarantors_self_select_v2
on public.member_loan_guarantors
for select
 to authenticated
using (
  exists (
    select 1
    from public.members m
    where m.id = member_loan_guarantors.guarantor_member_id
      and m.profile_id = (select auth.uid())
  )
  or exists (
    select 1
    from public.loan_applications la
    where la.id = member_loan_guarantors.loan_application_id
      and la.applicant_profile_id = (select auth.uid())
  )
);

create policy member_loan_guarantors_admin_select_v2
on public.member_loan_guarantors
for select
 to authenticated
using ((select private.current_user_has_permission('loan.review')));

create policy outsider_loan_guarantors_self_select_v2
on public.outsider_loan_guarantors
for select
 to authenticated
using (
  exists (
    select 1
    from public.members m
    where m.id = outsider_loan_guarantors.guarantor_member_id
      and m.profile_id = (select auth.uid())
  )
);

create policy outsider_loan_guarantors_admin_select_v2
on public.outsider_loan_guarantors
for select
 to authenticated
using ((select private.current_user_has_permission('loan.review')));

-- ============================================================================
-- 21. Read-only access to outsider application detail for admins only
-- ============================================================================

revoke all on public.outsider_loan_applications from anon;

-- ============================================================================
-- 27. Verification queries
-- ============================================================================

-- Tables
-- select to_regclass('public.outsider_loan_applications');
-- select to_regclass('public.member_loan_guarantors');
-- select to_regclass('public.outsider_loan_guarantors');
-- select to_regclass('public.loan_guarantors');

-- Formulas
-- select private.member_max_loan_v2('<member-uuid>');
-- select private.outsider_guarantor_max_loan_v2('<member-uuid>');

-- Product configuration
-- select code, borrower_type, service_charge_rate, max_amount, term_months, active
-- from public.loan_products
-- where code in ('member_loan', 'outsider_loan')
-- order by code;

-- Source constraints
-- select conname, pg_get_constraintdef(oid)
-- from pg_constraint
-- where conrelid in (
--   'public.loan_eligibility_checks'::regclass,
--   'public.loan_approvals'::regclass,
--   'public.loans'::regclass
-- )
-- and conname like '%v2%';

-- Expected authoritative formulas:
-- MEMBER   = MIN(member_total_savings * 2, 20000)
-- OUTSIDER = MIN(guarantor_total_savings * 2, 20000)
-- No borrower_savings + guarantor_savings >= requested rule remains.

commit;
