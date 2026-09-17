/*
===============================================================================
Unity Finance Group
Loan Admin Production RPC V3
===============================================================================

Purpose
-------
Production-grade database command/read boundary for the Next.js admin loan
module and the controlled member/outsider loan lifecycle.

This migration is incremental. It expects the Unity Finance MVP schema plus
Loan V2 migration to already exist.

Critical rules preserved:
- member max = MIN(total member savings * 2, product max / 20,000 ETB)
- outsider max = MIN(guarantor total savings * 2, product max / 20,000 ETB)
- member service charge = 10%
- outsider service charge = 15%
- 3 scheduled monthly installments
- 5% late installment penalty, once per installment
- serious default = 60 days after an unpaid installment due date
- minimum liquidity reserve = 30%
- two distinct approvals
- self approval prohibited
- approval does not equal disbursement
- financial history is append-only; corrections use reversals

Production hardening added here:
- immutable approval/economic snapshots
- idempotent admin commands
- aggregate liquidity serialization using advisory locks
- explicit repayment submission workflow for member + outsider payments
- safe repayment allocation invariants
- scheduled overdue/default processors separated from interactive RPC auth
- pre-disbursement cancellation
- extension review boundary without silently rewriting schedules
- recovery event recording without inventing automatic guarantor debit policy
- guarantor replacement with explicit acceptance and audit
- conflict-of-interest declarations and recusal enforcement
- financial reversal records

No service-role key is required by the client. Privileged commands derive the
actor from auth.uid() and enforce permissions in the database.
===============================================================================
*/

begin;

/* -------------------------------------------------------------------------- */
/* 0. Compatibility / support schema                                           */
/* -------------------------------------------------------------------------- */

alter table public.loan_applications
  add column if not exists approved_amount numeric(18,2),
  add column if not exists approved_service_charge_rate numeric(8,4),
  add column if not exists approved_term_months integer,
  add column if not exists approved_rule_snapshot jsonb;

alter table public.outsider_loan_applications
  add column if not exists approved_service_charge_rate numeric(8,4),
  add column if not exists approved_term_months integer,
  add column if not exists approved_rule_snapshot jsonb;

alter table public.loan_repayment_allocations
  add column if not exists repayment_submission_id uuid;

alter table public.loan_repayment_allocations
  alter column payment_id drop not null;

alter table public.loan_repayment_allocations
  drop constraint if exists loan_repayment_allocations_payment_or_submission_ck;

alter table public.loan_repayment_allocations
  add constraint loan_repayment_allocations_payment_or_submission_ck
  check (payment_id is not null or repayment_submission_id is not null) not valid;

create table if not exists public.loan_command_idempotency (
  id uuid primary key default gen_random_uuid(),
  actor_profile_id uuid references public.profiles(id) on delete restrict,
  command_type text not null,
  idempotency_key text not null,
  target_type text,
  target_id uuid,
  status text not null default 'completed'
    check (status in ('in_progress', 'completed', 'failed')),
  response jsonb,
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (actor_profile_id, command_type, idempotency_key)
);

create index if not exists loan_command_idempotency_target_idx
  on public.loan_command_idempotency(target_type, target_id, created_at desc);

create table if not exists public.loan_repayment_submissions (
  id uuid primary key default gen_random_uuid(),
  loan_id uuid not null references public.loans(id) on delete restrict,
  payment_id uuid references public.payments(id) on delete restrict,
  borrower_type public.loan_borrower_type not null,
  payer_profile_id uuid references public.profiles(id) on delete restrict,
  payer_name text,
  payer_phone text,
  amount numeric(18,2) not null check (amount > 0),
  payment_method_code text not null,
  external_reference text,
  payment_proof_path text,
  status text not null default 'pending'
    check (status in ('pending', 'verified', 'rejected', 'posted', 'cancelled')),
  submitted_by uuid references public.profiles(id) on delete set null,
  verified_by uuid references public.profiles(id) on delete set null,
  verified_at timestamptz,
  rejected_reason text,
  posted_transaction_id uuid references public.transactions(id) on delete restrict,
  reversed_at timestamptz,
  reversal_transaction_id uuid references public.transactions(id) on delete restrict,
  submitted_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (
    (borrower_type = 'member' and payer_profile_id is not null)
    or borrower_type = 'outsider'
  )
);

create index if not exists loan_repayment_submissions_loan_idx
  on public.loan_repayment_submissions(loan_id, created_at desc);

create index if not exists loan_repayment_submissions_status_idx
  on public.loan_repayment_submissions(status, submitted_at desc);

create unique index if not exists loan_repayment_submissions_external_reference_uq
  on public.loan_repayment_submissions(external_reference)
  where external_reference is not null;

create unique index if not exists loan_repayment_submissions_payment_uq
  on public.loan_repayment_submissions(payment_id)
  where payment_id is not null;

alter table public.loan_repayment_allocations
  drop constraint if exists loan_repayment_allocations_submission_fk;

alter table public.loan_repayment_allocations
  add constraint loan_repayment_allocations_submission_fk
  foreign key (repayment_submission_id)
  references public.loan_repayment_submissions(id)
  on delete restrict;

create unique index if not exists loan_repayment_allocations_submission_installment_uq
  on public.loan_repayment_allocations(repayment_submission_id, installment_id)
  where repayment_submission_id is not null;

create table if not exists public.loan_guarantor_replacement_requests (
  id uuid primary key default gen_random_uuid(),
  loan_id uuid not null references public.loans(id) on delete restrict,
  old_guarantor_member_id uuid not null references public.members(id) on delete restrict,
  new_guarantor_member_id uuid not null references public.members(id) on delete restrict,
  borrower_type public.loan_borrower_type not null,
  reason text not null,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'rejected', 'cancelled')),
  requested_by uuid references public.profiles(id) on delete restrict,
  responded_by uuid references public.profiles(id) on delete set null,
  responded_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (old_guarantor_member_id <> new_guarantor_member_id)
);

create unique index if not exists loan_guarantor_replacement_pending_uq
  on public.loan_guarantor_replacement_requests(loan_id)
  where status = 'pending';

create index if not exists loan_guarantor_replacement_loan_idx
  on public.loan_guarantor_replacement_requests(loan_id, created_at desc);

create table if not exists public.loan_conflict_declarations (
  id uuid primary key default gen_random_uuid(),
  loan_id uuid references public.loans(id) on delete restrict,
  application_id uuid references public.loan_applications(id) on delete restrict,
  outsider_application_id uuid references public.outsider_loan_applications(id) on delete restrict,
  actor_profile_id uuid not null references public.profiles(id) on delete restrict,
  conflict_type text not null,
  description text not null,
  status text not null default 'declared'
    check (status in ('declared', 'resolved', 'dismissed')),
  resolved_by uuid references public.profiles(id) on delete set null,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  check (
    loan_id is not null
    or application_id is not null
    or outsider_application_id is not null
  )
);

create index if not exists loan_conflict_loan_idx
  on public.loan_conflict_declarations(loan_id, created_at desc);

create table if not exists public.loan_financial_reversals (
  id uuid primary key default gen_random_uuid(),
  loan_id uuid not null references public.loans(id) on delete restrict,
  original_transaction_id uuid not null references public.transactions(id) on delete restrict,
  reversal_transaction_id uuid references public.transactions(id) on delete restrict,
  repayment_submission_id uuid references public.loan_repayment_submissions(id) on delete restrict,
  reason text not null,
  requested_by uuid not null references public.profiles(id) on delete restrict,
  approved_by uuid references public.profiles(id) on delete set null,
  status text not null default 'approved'
    check (status in ('approved', 'posted', 'rejected')),
  created_at timestamptz not null default now(),
  posted_at timestamptz,
  unique (original_transaction_id)
);

create index if not exists loan_financial_reversals_loan_idx
  on public.loan_financial_reversals(loan_id, created_at desc);

/* Existing approved rows need immutable economic snapshots before V3 review /
   disbursement starts depending on them. */

update public.loan_applications la
set
  approved_amount = coalesce(la.approved_amount, la.requested_amount),
  approved_service_charge_rate = coalesce(
    la.approved_service_charge_rate,
    lp.service_charge_rate
  ),
  approved_term_months = coalesce(
    la.approved_term_months,
    lp.term_months
  ),
  approved_rule_snapshot = coalesce(
    la.approved_rule_snapshot,
    jsonb_build_object(
      'loan_product_id', lp.id,
      'loan_product_code', lp.code,
      'service_charge_rate', lp.service_charge_rate,
      'max_amount', lp.max_amount,
      'term_months', lp.term_months,
      'captured_at', now()
    )
  )
from public.loan_products lp
where lp.id = la.loan_product_id
  and la.status = 'approved';

update public.outsider_loan_applications oa
set
  approved_service_charge_rate = coalesce(
    oa.approved_service_charge_rate,
    lp.service_charge_rate
  ),
  approved_term_months = coalesce(
    oa.approved_term_months,
    lp.term_months
  ),
  approved_rule_snapshot = coalesce(
    oa.approved_rule_snapshot,
    jsonb_build_object(
      'loan_product_id', lp.id,
      'loan_product_code', lp.code,
      'service_charge_rate', lp.service_charge_rate,
      'max_amount', lp.max_amount,
      'term_months', lp.term_months,
      'captured_at', now()
    )
  )
from public.loan_products lp
where lp.id = oa.loan_product_id
  and oa.status = 'approved';

create index if not exists loan_applications_approved_amount_idx
  on public.loan_applications(status, approved_amount);

create index if not exists outsider_loan_applications_approved_amount_idx
  on public.outsider_loan_applications(status, approved_amount);

/* No client-facing table access. All authoritative operations use RPCs. */
revoke all on public.loan_command_idempotency from public, anon, authenticated;
revoke all on public.loan_repayment_submissions from public, anon, authenticated;
revoke all on public.loan_guarantor_replacement_requests from public, anon, authenticated;
revoke all on public.loan_conflict_declarations from public, anon, authenticated;
revoke all on public.loan_financial_reversals from public, anon, authenticated;

/* -------------------------------------------------------------------------- */
/* 1. Private helpers                                                          */
/* -------------------------------------------------------------------------- */

create or replace function private.loan_require_permission_v3(p_permission text)
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
begin
  if v_actor is null then
    raise exception using errcode = '28000', message = 'Not authenticated';
  end if;

  if not private.current_user_has_permission(p_permission) then
    raise exception using errcode = '42501', message = 'Unauthorized';
  end if;

  return v_actor;
end;
$$;

revoke all on function private.loan_require_permission_v3(text)
  from public, anon, authenticated;

create or replace function private.loan_lock_financial_domain_v3(p_scope text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  /* Transaction-scoped lock. Every V3 command that can change liquidity or
     ledger-backed loan state uses the same lock scope. This only serializes
     callers that opt into the V3 protocol, therefore all liquidity-changing
     V3 commands must take it before checking balances. */
  perform pg_advisory_xact_lock(
    hashtextextended(coalesce(p_scope, 'UNITY_FINANCE_LOANS'), 0)
  );
end;
$$;

revoke all on function private.loan_lock_financial_domain_v3(text)
  from public, anon, authenticated;

create or replace function private.loan_source_account_v3(p_code text)
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select private.system_account_id(
    case lower(trim(p_code))
      when 'cash' then 'cash'::public.account_type_code
      when 'bank' then 'bank'::public.account_type_code
      when 'bank_transfer' then 'bank'::public.account_type_code
      when 'wallet' then 'wallet'::public.account_type_code
      else null
    end
  );
$$;

revoke all on function private.loan_source_account_v3(text)
  from public, anon, authenticated;

create or replace function private.loan_snapshot_json_v3(
  p_borrower_type public.loan_borrower_type,
  p_application_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_member_id uuid;
  v_requested numeric(18,2);
  v_max numeric(18,2);
  v_savings numeric(18,2);
  v_guarantor_member_id uuid;
  v_rate numeric(8,4);
  v_term integer;
begin
  if p_borrower_type = 'member' then
    select la.member_id, la.requested_amount, lp.service_charge_rate, lp.term_months
      into v_member_id, v_requested, v_rate, v_term
    from public.loan_applications la
    join public.loan_products lp on lp.id = la.loan_product_id
    where la.id = p_application_id;

    v_savings := private.member_total_savings_v2(v_member_id);
    v_max := private.member_max_loan_v2(v_member_id);

    return jsonb_build_object(
      'borrower_type', 'member',
      'requested_amount', v_requested,
      'total_savings', v_savings,
      'calculated_maximum', v_max,
      'service_charge_rate', v_rate,
      'term_months', v_term
    );
  end if;

  select oa.requested_amount, lp.service_charge_rate, lp.term_months,
         g.guarantor_member_id
    into v_requested, v_rate, v_term, v_guarantor_member_id
  from public.outsider_loan_applications oa
  join public.loan_products lp on lp.id = oa.loan_product_id
  left join public.outsider_loan_guarantors g
    on g.outsider_loan_application_id = oa.id
  where oa.id = p_application_id;

  v_savings := private.member_total_savings_v2(v_guarantor_member_id);
  v_max := private.outsider_guarantor_max_loan_v2(v_guarantor_member_id);

  return jsonb_build_object(
    'borrower_type', 'outsider',
    'requested_amount', v_requested,
    'guarantor_member_id', v_guarantor_member_id,
    'guarantor_total_savings', v_savings,
    'guarantor_calculated_maximum', v_max,
    'service_charge_rate', v_rate,
    'term_months', v_term
  );
end;
$$;

revoke all on function private.loan_snapshot_json_v3(public.loan_borrower_type, uuid)
  from public, anon, authenticated;

create or replace function private.loan_begin_idempotency_v3(
  p_actor uuid,
  p_command text,
  p_key text,
  p_target_type text,
  p_target_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row public.loan_command_idempotency%rowtype;
begin
  if p_key is null or length(trim(p_key)) < 8 then
    raise exception 'Idempotency key must contain at least 8 characters';
  end if;

  select * into v_row
  from public.loan_command_idempotency
  where actor_profile_id = p_actor
    and command_type = p_command
    and idempotency_key = trim(p_key)
  for update;

  if found then
    if v_row.status = 'completed' and v_row.response is not null then
      return jsonb_build_object(
        'replayed', true,
        'response', v_row.response
      );
    end if;

    if v_row.status = 'in_progress' then
      raise exception 'This command is already being processed';
    end if;
  end if;

  insert into public.loan_command_idempotency(
    actor_profile_id,
    command_type,
    idempotency_key,
    target_type,
    target_id,
    status
  )
  values (
    p_actor,
    p_command,
    trim(p_key),
    p_target_type,
    p_target_id,
    'in_progress'
  );

  return jsonb_build_object('replayed', false);
exception
  when unique_violation then
    select * into v_row
    from public.loan_command_idempotency
    where actor_profile_id = p_actor
      and command_type = p_command
      and idempotency_key = trim(p_key)
    for update;

    if v_row.status = 'completed' and v_row.response is not null then
      return jsonb_build_object('replayed', true, 'response', v_row.response);
    end if;

    raise exception 'This command is already being processed';
end;
$$;

revoke all on function private.loan_begin_idempotency_v3(uuid, text, text, text, uuid)
  from public, anon, authenticated;

create or replace function private.loan_finish_idempotency_v3(
  p_actor uuid,
  p_command text,
  p_key text,
  p_response jsonb
)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.loan_command_idempotency
  set status = 'completed',
      response = p_response,
      completed_at = now()
  where actor_profile_id = p_actor
    and command_type = p_command
    and idempotency_key = trim(p_key);
$$;

revoke all on function private.loan_finish_idempotency_v3(uuid, text, text, jsonb)
  from public, anon, authenticated;

create or replace function private.loan_audit_v3(
  p_actor uuid,
  p_action text,
  p_entity_type text,
  p_entity_id uuid,
  p_old jsonb default null,
  p_new jsonb default null,
  p_metadata jsonb default '{}'::jsonb
)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.audit_logs(
    actor_user_id,
    action,
    entity_type,
    entity_id,
    old_data,
    new_data,
    metadata
  )
  values (
    p_actor,
    p_action,
    p_entity_type,
    p_entity_id,
    p_old,
    p_new,
    coalesce(p_metadata, '{}'::jsonb)
  );
$$;

revoke all on function private.loan_audit_v3(uuid, text, text, uuid, jsonb, jsonb, jsonb)
  from public, anon, authenticated;

/* -------------------------------------------------------------------------- */
/* Transaction helper with explicit actor/approver                             */
/* -------------------------------------------------------------------------- */

create or replace function private.post_balanced_transaction_v3(
  p_transaction_type public.transaction_type,
  p_profile_id uuid,
  p_member_id uuid,
  p_amount numeric,
  p_source_type text,
  p_source_id uuid,
  p_description text,
  p_entries jsonb,
  p_actor uuid
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_transaction_id uuid;
  v_debits numeric(18,2);
  v_credits numeric(18,2);
  v_entry_count integer;
begin
  if p_amount is null or p_amount <= 0 then raise exception 'Transaction amount must be greater than zero'; end if;
  if p_entries is null or jsonb_typeof(p_entries) <> 'array' then raise exception 'Transaction entries must be a JSON array'; end if;

  select
    count(*),
    coalesce(sum(case when x.entry_type='debit' then x.amount else 0 end),0)::numeric(18,2),
    coalesce(sum(case when x.entry_type='credit' then x.amount else 0 end),0)::numeric(18,2)
  into v_entry_count,v_debits,v_credits
  from jsonb_to_recordset(p_entries) as x(
    account_id uuid,
    entry_type public.transaction_entry_type,
    amount numeric
  );

  if v_entry_count < 2 then raise exception 'A financial transaction requires at least two entries'; end if;
  if v_debits <= 0 or v_credits <= 0 then raise exception 'Financial transaction must contain debit and credit entries'; end if;
  if v_debits <> v_credits then raise exception 'Unbalanced transaction: debits %, credits %',v_debits,v_credits; end if;
  if v_debits <> round(p_amount,2) then raise exception 'Transaction amount % does not equal ledger total %',p_amount,v_debits; end if;

  insert into public.transactions(
    transaction_type,source_type,source_id,profile_id,member_id,amount,currency,
    approval_status,transaction_status,initiated_by,approved_by,approved_at,description
  ) values (
    p_transaction_type,p_source_type,p_source_id,p_profile_id,p_member_id,round(p_amount,2),'ETB',
    'approved','posted',p_actor,p_actor,case when p_actor is null then null else now() end,p_description
  ) returning id into v_transaction_id;

  insert into public.transaction_entries(transaction_id,account_id,entry_type,amount)
  select v_transaction_id,x.account_id,x.entry_type,round(x.amount,2)
  from jsonb_to_recordset(p_entries) as x(
    account_id uuid,
    entry_type public.transaction_entry_type,
    amount numeric
  );

  return v_transaction_id;
end;
$$;

revoke all on function private.post_balanced_transaction_v3(public.transaction_type,uuid,uuid,numeric,text,uuid,text,jsonb,uuid) from public, anon, authenticated;

/* -------------------------------------------------------------------------- */
/* 2. Admin read RPCs                                                          */
/* -------------------------------------------------------------------------- */

create or replace function public.get_admin_loan_overview_v3()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('loan.read');
  v_liquidity jsonb;
  v_pending_member bigint;
  v_pending_outsider bigint;
  v_pending_guarantors bigint;
  v_pending_approvals bigint;
  v_ready_disbursement bigint;
  v_active_loans bigint;
  v_overdue_loans bigint;
  v_defaulted_loans bigint;
  v_outstanding numeric(18,2);
  v_service_income numeric(18,2);
  v_penalty_income numeric(18,2);
begin
  v_liquidity := private.loan_liquidity_snapshot();

  select count(*) into v_pending_member
  from public.loan_applications
  where status in ('submitted', 'eligible', 'under_review');

  select count(*) into v_pending_outsider
  from public.outsider_loan_applications
  where status in ('submitted', 'eligible', 'under_review');

  select count(*)
  into v_pending_guarantors
  from (
    select id from public.member_loan_guarantors where status = 'requested'
    union all
    select id from public.outsider_loan_guarantors where status = 'requested'
  ) q;

  select count(*) into v_pending_approvals
  from (
    select la.id
    from public.loan_applications la
    where la.status = 'under_review'
      and (
        select count(*) from public.loan_approvals a
        where a.loan_application_id = la.id and a.decision = 'approved'
      ) < 2
    union all
    select oa.id
    from public.outsider_loan_applications oa
    where oa.status = 'under_review'
      and (
        select count(*) from public.loan_approvals a
        where a.outsider_loan_application_id = oa.id and a.decision = 'approved'
      ) < 2
  ) q;

  select count(*) into v_ready_disbursement
  from (
    select la.id
    from public.loan_applications la
    where la.status = 'approved'
      and not exists (select 1 from public.loans l where l.loan_application_id = la.id)
    union all
    select oa.id
    from public.outsider_loan_applications oa
    where oa.status = 'approved'
      and not exists (select 1 from public.loans l where l.outsider_loan_application_id = oa.id)
  ) q;

  select count(*) into v_active_loans
  from public.loans
  where status = 'active';

  select count(*) into v_overdue_loans
  from public.loans
  where status = 'overdue';

  select count(*) into v_defaulted_loans
  from public.loans
  where status = 'defaulted';

  select coalesce(sum(
    greatest(l.total_repayment - coalesce(a.total_base, 0), 0)
  ), 0)::numeric(18,2)
  into v_outstanding
  from public.loans l
  left join (
    select loan_id, sum(allocated_base_amount)::numeric(18,2) total_base
    from public.loan_repayment_allocations
    group by loan_id
  ) a on a.loan_id = l.id
  where l.status in ('active', 'overdue', 'defaulted');

  select coalesce(sum(t.amount),0)::numeric(18,2)
  into v_service_income
  from public.transactions t
  where t.transaction_type in ('loan_service_charge','outsider_service_charge')
    and t.transaction_status = 'posted';

  select coalesce(sum(t.amount),0)::numeric(18,2)
  into v_penalty_income
  from public.transactions t
  where t.transaction_type = 'loan_late_penalty'
    and t.transaction_status = 'posted';

  return jsonb_build_object(
    'pending_member_applications', v_pending_member,
    'pending_outsider_applications', v_pending_outsider,
    'pending_guarantor_requests', v_pending_guarantors,
    'pending_approvals', v_pending_approvals,
    'ready_for_disbursement', v_ready_disbursement,
    'active_loans', v_active_loans,
    'overdue_loans', v_overdue_loans,
    'defaulted_loans', v_defaulted_loans,
    'outstanding_amount', v_outstanding,
    'service_charge_income', v_service_income,
    'penalty_income', v_penalty_income,
    'liquidity', v_liquidity,
    'generated_at', now()
  );
end;
$$;

revoke all on function public.get_admin_loan_overview_v3() from public, anon;
grant execute on function public.get_admin_loan_overview_v3() to authenticated;

create or replace function public.get_admin_loan_application_detail_v3(
  p_borrower_type public.loan_borrower_type,
  p_application_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('loan.read');
  v_app jsonb;
  v_guarantor jsonb;
  v_approvals jsonb;
  v_checks jsonb;
  v_audit jsonb;
begin
  if p_borrower_type = 'member' then
    select jsonb_build_object(
      'id', la.id,
      'application_number', la.application_number,
      'borrower_type', 'member',
      'applicant_profile_id', la.applicant_profile_id,
      'member_id', la.member_id,
      'requested_amount', la.requested_amount,
      'approved_amount', la.approved_amount,
      'purpose', la.purpose,
      'status', la.status,
      'eligibility_status', la.eligibility_status,
      'submitted_at', la.submitted_at,
      'created_at', la.created_at,
      'updated_at', la.updated_at,
      'loan_product', jsonb_build_object(
        'id', lp.id,
        'code', lp.code,
        'name', lp.name,
        'service_charge_rate', lp.service_charge_rate,
        'max_amount', lp.max_amount,
        'term_months', lp.term_months
      ),
      'applicant', (
        select jsonb_build_object(
          'profile_id', p.id,
          'full_name', p.full_name,
          'email', p.email,
          'phone', p.phone
        ) from public.profiles p where p.id = la.applicant_profile_id
      ),
      'economic_snapshot', jsonb_build_object(
        'approved_service_charge_rate', la.approved_service_charge_rate,
        'approved_term_months', la.approved_term_months,
        'approved_rule_snapshot', la.approved_rule_snapshot
      )
    ) into v_app
    from public.loan_applications la
    join public.loan_products lp on lp.id = la.loan_product_id
    where la.id = p_application_id;
  else
    select jsonb_build_object(
      'id', oa.id,
      'application_number', oa.application_number,
      'borrower_type', 'outsider',
      'requested_amount', oa.requested_amount,
      'approved_amount', oa.approved_amount,
      'purpose', oa.purpose,
      'status', oa.status,
      'eligibility_status', oa.eligibility_status,
      'applicant', jsonb_build_object(
        'full_name', oa.applicant_full_name,
        'phone', oa.applicant_phone,
        'address', oa.applicant_address
      ),
      'submitted_at', oa.submitted_at,
      'created_at', oa.created_at,
      'updated_at', oa.updated_at,
      'loan_product', jsonb_build_object(
        'id', lp.id,
        'code', lp.code,
        'name', lp.name,
        'service_charge_rate', lp.service_charge_rate,
        'max_amount', lp.max_amount,
        'term_months', lp.term_months
      ),
      'economic_snapshot', jsonb_build_object(
        'approved_service_charge_rate', oa.approved_service_charge_rate,
        'approved_term_months', oa.approved_term_months,
        'approved_rule_snapshot', oa.approved_rule_snapshot
      )
    ) into v_app
    from public.outsider_loan_applications oa
    join public.loan_products lp on lp.id = oa.loan_product_id
    where oa.id = p_application_id;
  end if;

  if v_app is null then
    raise exception 'Loan application not found';
  end if;

  if p_borrower_type = 'member' then
    select to_jsonb(g) into v_guarantor
    from public.member_loan_guarantors g
    where g.loan_application_id = p_application_id;
  else
    select to_jsonb(g) into v_guarantor
    from public.outsider_loan_guarantors g
    where g.outsider_loan_application_id = p_application_id;
  end if;

  select coalesce(jsonb_agg(to_jsonb(a) order by a.created_at), '[]'::jsonb)
  into v_approvals
  from public.loan_approvals a
  where (p_borrower_type = 'member' and a.loan_application_id = p_application_id)
     or (p_borrower_type = 'outsider' and a.outsider_loan_application_id = p_application_id);

  select coalesce(jsonb_agg(to_jsonb(c) order by c.checked_at desc), '[]'::jsonb)
  into v_checks
  from public.loan_eligibility_checks c
  where (p_borrower_type = 'member' and c.loan_application_id = p_application_id)
     or (p_borrower_type = 'outsider' and c.outsider_loan_application_id = p_application_id);

  select coalesce(jsonb_agg(to_jsonb(al) order by al.created_at desc), '[]'::jsonb)
  into v_audit
  from public.audit_logs al
  where al.entity_id = p_application_id
    and al.entity_type in ('loan_application','outsider_loan_application');

  return jsonb_build_object(
    'application', v_app,
    'guarantor', coalesce(v_guarantor, '{}'::jsonb),
    'approvals', v_approvals,
    'eligibility_checks', v_checks,
    'audit', v_audit,
    'current_limits', private.loan_snapshot_json_v3(p_borrower_type, p_application_id),
    'actor', v_actor
  );
end;
$$;

revoke all on function public.get_admin_loan_application_detail_v3(public.loan_borrower_type, uuid)
  from public, anon;
grant execute on function public.get_admin_loan_application_detail_v3(public.loan_borrower_type, uuid)
  to authenticated;

create or replace function public.list_admin_loan_applications_v3(
  p_borrower_type public.loan_borrower_type default null,
  p_status public.loan_application_status default null,
  p_search text default null,
  p_limit integer default 25,
  p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('loan.read');
  v_limit integer := least(greatest(coalesce(p_limit,25),1),100);
  v_offset integer := greatest(coalesce(p_offset,0),0);
  v_total bigint;
  v_rows jsonb;
begin
  with combined as (
    select
      la.id,
      la.application_number,
      'member'::public.loan_borrower_type borrower_type,
      la.requested_amount,
      la.approved_amount,
      la.status,
      la.eligibility_status,
      la.submitted_at,
      la.created_at,
      la.updated_at,
      p.full_name applicant_name,
      p.phone applicant_phone,
      p.email applicant_email,
      m.member_number,
      g.guarantor_member_id,
      (select count(*) from public.loan_approvals a where a.loan_application_id = la.id and a.decision = 'approved') approved_count
    from public.loan_applications la
    join public.profiles p on p.id = la.applicant_profile_id
    left join public.members m on m.id = la.member_id
    left join public.member_loan_guarantors g on g.loan_application_id = la.id
    where (p_borrower_type is null or p_borrower_type = 'member')
      and (p_status is null or la.status = p_status)
      and (
        p_search is null or trim(p_search) = ''
        or la.application_number ilike '%'||trim(p_search)||'%'
        or p.full_name ilike '%'||trim(p_search)||'%'
        or p.phone ilike '%'||trim(p_search)||'%'
        or p.email ilike '%'||trim(p_search)||'%'
        or m.member_number ilike '%'||trim(p_search)||'%'
      )
    union all
    select
      oa.id,
      oa.application_number,
      'outsider'::public.loan_borrower_type borrower_type,
      oa.requested_amount,
      oa.approved_amount,
      oa.status,
      oa.eligibility_status,
      oa.submitted_at,
      oa.created_at,
      oa.updated_at,
      oa.applicant_full_name applicant_name,
      oa.applicant_phone applicant_phone,
      null::text applicant_email,
      null::text member_number,
      g.guarantor_member_id,
      (select count(*) from public.loan_approvals a where a.outsider_loan_application_id = oa.id and a.decision = 'approved') approved_count
    from public.outsider_loan_applications oa
    left join public.outsider_loan_guarantors g on g.outsider_loan_application_id = oa.id
    where (p_borrower_type is null or p_borrower_type = 'outsider')
      and (p_status is null or oa.status = p_status)
      and (
        p_search is null or trim(p_search) = ''
        or oa.application_number ilike '%'||trim(p_search)||'%'
        or oa.applicant_full_name ilike '%'||trim(p_search)||'%'
        or oa.applicant_phone ilike '%'||trim(p_search)||'%'
      )
  )
  select count(*) into v_total from combined;

  with combined as (
    select
      la.id,
      la.application_number,
      'member'::public.loan_borrower_type borrower_type,
      la.requested_amount,
      la.approved_amount,
      la.status,
      la.eligibility_status,
      la.submitted_at,
      la.created_at,
      la.updated_at,
      p.full_name applicant_name,
      p.phone applicant_phone,
      p.email applicant_email,
      m.member_number,
      g.guarantor_member_id,
      (select count(*) from public.loan_approvals a where a.loan_application_id = la.id and a.decision = 'approved') approved_count
    from public.loan_applications la
    join public.profiles p on p.id = la.applicant_profile_id
    left join public.members m on m.id = la.member_id
    left join public.member_loan_guarantors g on g.loan_application_id = la.id
    where (p_borrower_type is null or p_borrower_type = 'member')
      and (p_status is null or la.status = p_status)
      and (p_search is null or trim(p_search) = '' or la.application_number ilike '%'||trim(p_search)||'%' or p.full_name ilike '%'||trim(p_search)||'%' or p.phone ilike '%'||trim(p_search)||'%' or p.email ilike '%'||trim(p_search)||'%' or m.member_number ilike '%'||trim(p_search)||'%')
    union all
    select
      oa.id,
      oa.application_number,
      'outsider'::public.loan_borrower_type,
      oa.requested_amount,
      oa.approved_amount,
      oa.status,
      oa.eligibility_status,
      oa.submitted_at,
      oa.created_at,
      oa.updated_at,
      oa.applicant_full_name,
      oa.applicant_phone,
      null::text,
      null::text,
      g.guarantor_member_id,
      (select count(*) from public.loan_approvals a where a.outsider_loan_application_id = oa.id and a.decision = 'approved')
    from public.outsider_loan_applications oa
    left join public.outsider_loan_guarantors g on g.outsider_loan_application_id = oa.id
    where (p_borrower_type is null or p_borrower_type = 'outsider')
      and (p_status is null or oa.status = p_status)
      and (p_search is null or trim(p_search) = '' or oa.application_number ilike '%'||trim(p_search)||'%' or oa.applicant_full_name ilike '%'||trim(p_search)||'%' or oa.applicant_phone ilike '%'||trim(p_search)||'%')
  )
  select coalesce(jsonb_agg(to_jsonb(q) order by q.submitted_at desc nulls last), '[]'::jsonb)
  into v_rows
  from (
    select * from combined
    order by submitted_at desc nulls last
    limit v_limit offset v_offset
  ) q;

  return jsonb_build_object(
    'rows', v_rows,
    'total', v_total,
    'limit', v_limit,
    'offset', v_offset,
    'actor', v_actor
  );
end;
$$;

revoke all on function public.list_admin_loan_applications_v3(public.loan_borrower_type, public.loan_application_status, text, integer, integer) from public, anon;
grant execute on function public.list_admin_loan_applications_v3(public.loan_borrower_type, public.loan_application_status, text, integer, integer) to authenticated;

create or replace function public.list_admin_guarantor_requests_v3(
  p_status public.guarantor_status default 'requested',
  p_borrower_type public.loan_borrower_type default null,
  p_search text default null,
  p_limit integer default 25,
  p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('loan.read');
  v_limit integer := least(greatest(coalesce(p_limit,25),1),100);
  v_offset integer := greatest(coalesce(p_offset,0),0);
  v_rows jsonb;
  v_total bigint;
begin
  with q as (
    select
      g.id,
      'member'::public.loan_borrower_type borrower_type,
      g.loan_application_id application_id,
      la.application_number,
      g.guarantor_member_id,
      gm.member_number guarantor_member_number,
      gp.full_name guarantor_name,
      p.full_name borrower_name,
      la.requested_amount,
      g.status,
      g.requested_at,
      g.responded_at
    from public.member_loan_guarantors g
    join public.loan_applications la on la.id = g.loan_application_id
    join public.profiles p on p.id = la.applicant_profile_id
    join public.members gm on gm.id = g.guarantor_member_id
    join public.profiles gp on gp.id = gm.profile_id
    where (p_borrower_type is null or p_borrower_type = 'member')
      and (p_status is null or g.status = p_status)
      and (p_search is null or trim(p_search) = '' or la.application_number ilike '%'||trim(p_search)||'%' or p.full_name ilike '%'||trim(p_search)||'%' or gp.full_name ilike '%'||trim(p_search)||'%' or gm.member_number ilike '%'||trim(p_search)||'%')
    union all
    select
      g.id,
      'outsider'::public.loan_borrower_type,
      g.outsider_loan_application_id,
      oa.application_number,
      g.guarantor_member_id,
      gm.member_number,
      gp.full_name,
      oa.applicant_full_name,
      oa.requested_amount,
      g.status,
      g.requested_at,
      g.responded_at
    from public.outsider_loan_guarantors g
    join public.outsider_loan_applications oa on oa.id = g.outsider_loan_application_id
    join public.members gm on gm.id = g.guarantor_member_id
    join public.profiles gp on gp.id = gm.profile_id
    where (p_borrower_type is null or p_borrower_type = 'outsider')
      and (p_status is null or g.status = p_status)
      and (p_search is null or trim(p_search) = '' or oa.application_number ilike '%'||trim(p_search)||'%' or oa.applicant_full_name ilike '%'||trim(p_search)||'%' or oa.applicant_phone ilike '%'||trim(p_search)||'%' or gp.full_name ilike '%'||trim(p_search)||'%' or gm.member_number ilike '%'||trim(p_search)||'%')
  )
  select count(*) into v_total from q;

  select coalesce(jsonb_agg(to_jsonb(x) order by x.requested_at desc), '[]'::jsonb)
  into v_rows
  from (
    select * from q order by requested_at desc limit v_limit offset v_offset
  ) x;

  return jsonb_build_object('rows',v_rows,'total',v_total,'limit',v_limit,'offset',v_offset,'actor',v_actor);
end;
$$;

revoke all on function public.list_admin_guarantor_requests_v3(public.guarantor_status, public.loan_borrower_type, text, integer, integer) from public, anon;
grant execute on function public.list_admin_guarantor_requests_v3(public.guarantor_status, public.loan_borrower_type, text, integer, integer) to authenticated;

create or replace function public.list_admin_approval_queue_v3(
  p_limit integer default 25,
  p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('loan.review');
  v_limit integer := least(greatest(coalesce(p_limit,25),1),100);
  v_offset integer := greatest(coalesce(p_offset,0),0);
  v_rows jsonb;
  v_total bigint;
begin
  with q as (
    select
      la.id application_id,
      'member'::public.loan_borrower_type borrower_type,
      la.application_number,
      p.full_name applicant_name,
      la.requested_amount,
      la.approved_amount,
      (select count(*) from public.loan_approvals a where a.loan_application_id = la.id and a.decision = 'approved') approved_count,
      la.status,
      la.updated_at
    from public.loan_applications la
    join public.profiles p on p.id = la.applicant_profile_id
    where la.status = 'under_review'
    union all
    select
      oa.id,
      'outsider'::public.loan_borrower_type,
      oa.application_number,
      oa.applicant_full_name,
      oa.requested_amount,
      oa.approved_amount,
      (select count(*) from public.loan_approvals a where a.outsider_loan_application_id = oa.id and a.decision = 'approved'),
      oa.status,
      oa.updated_at
    from public.outsider_loan_applications oa
    where oa.status = 'under_review'
  )
  select count(*) into v_total from q;

  select coalesce(jsonb_agg(to_jsonb(x) order by x.updated_at desc), '[]'::jsonb)
  into v_rows
  from (
    select * from q order by updated_at desc limit v_limit offset v_offset
  ) x;

  return jsonb_build_object('rows',v_rows,'total',v_total,'limit',v_limit,'offset',v_offset,'actor',v_actor);
end;
$$;

revoke all on function public.list_admin_approval_queue_v3(integer, integer) from public, anon;
grant execute on function public.list_admin_approval_queue_v3(integer, integer) to authenticated;

create or replace function public.list_admin_disbursement_queue_v3(
  p_limit integer default 25,
  p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('loan.disburse');
  v_limit integer := least(greatest(coalesce(p_limit,25),1),100);
  v_offset integer := greatest(coalesce(p_offset,0),0);
  v_rows jsonb;
  v_liquidity jsonb;
  v_total bigint;
begin
  v_liquidity := private.loan_liquidity_snapshot();

  with q as (
    select
      la.id application_id,
      'member'::public.loan_borrower_type borrower_type,
      la.application_number,
      p.full_name applicant_name,
      la.requested_amount,
      la.approved_amount,
      la.approved_service_charge_rate,
      la.approved_term_months,
      la.updated_at,
      private.member_max_loan_v2(la.member_id) current_maximum,
      exists (select 1 from public.member_loan_guarantors g where g.loan_application_id = la.id and g.status = 'accepted') guarantor_accepted
    from public.loan_applications la
    join public.profiles p on p.id = la.applicant_profile_id
    where la.status = 'approved'
      and not exists (select 1 from public.loans l where l.loan_application_id = la.id)
    union all
    select
      oa.id,
      'outsider'::public.loan_borrower_type,
      oa.application_number,
      oa.applicant_full_name,
      oa.requested_amount,
      oa.approved_amount,
      oa.approved_service_charge_rate,
      oa.approved_term_months,
      oa.updated_at,
      private.outsider_guarantor_max_loan_v2(g.guarantor_member_id),
      (g.status = 'accepted')
    from public.outsider_loan_applications oa
    left join public.outsider_loan_guarantors g on g.outsider_loan_application_id = oa.id
    where oa.status = 'approved'
      and not exists (select 1 from public.loans l where l.outsider_loan_application_id = oa.id)
  )
  select count(*) into v_total from q;

  select coalesce(jsonb_agg(to_jsonb(x) order by x.updated_at desc), '[]'::jsonb)
  into v_rows
  from (
    select * from q order by updated_at desc limit v_limit offset v_offset
  ) x;

  return jsonb_build_object('rows',v_rows,'total',v_total,'limit',v_limit,'offset',v_offset,'liquidity',v_liquidity,'actor',v_actor);
end;
$$;

revoke all on function public.list_admin_disbursement_queue_v3(integer, integer) from public, anon;
grant execute on function public.list_admin_disbursement_queue_v3(integer, integer) to authenticated;

create or replace function public.list_admin_active_loans_v3(
  p_status public.loan_status default null,
  p_search text default null,
  p_limit integer default 25,
  p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('loan.read');
  v_limit integer := least(greatest(coalesce(p_limit,25),1),100);
  v_offset integer := greatest(coalesce(p_offset,0),0);
  v_total bigint;
  v_rows jsonb;
begin
  with q as (
    select
      l.id,
      l.loan_number,
      case when l.outsider_loan_application_id is null then 'member' else 'outsider' end::public.loan_borrower_type borrower_type,
      l.principal,
      l.service_charge_amount,
      l.total_repayment,
      l.status,
      l.disbursed_at,
      l.maturity_date,
      coalesce(p.full_name, oa.applicant_full_name) borrower_name,
      p.phone borrower_phone,
      m.member_number,
      greatest(l.total_repayment - coalesce((select sum(allocated_base_amount) from public.loan_repayment_allocations a where a.loan_id=l.id),0),0)::numeric(18,2) outstanding_base,
      coalesce((select count(*) from public.loan_installments li where li.loan_id=l.id and li.status in ('overdue','defaulted')),0) overdue_installments
    from public.loans l
    left join public.profiles p on p.id = l.borrower_profile_id
    left join public.members m on m.id = l.member_id
    left join public.outsider_loan_applications oa on oa.id = l.outsider_loan_application_id
    where (p_status is null or l.status = p_status)
      and (p_search is null or trim(p_search)='' or l.loan_number ilike '%'||trim(p_search)||'%' or p.full_name ilike '%'||trim(p_search)||'%' or oa.applicant_full_name ilike '%'||trim(p_search)||'%' or m.member_number ilike '%'||trim(p_search)||'%')
  )
  select count(*) into v_total from q;

  select coalesce(jsonb_agg(to_jsonb(x) order by x.disbursed_at desc), '[]'::jsonb)
  into v_rows
  from (select * from q order by disbursed_at desc limit v_limit offset v_offset) x;

  return jsonb_build_object('rows',v_rows,'total',v_total,'limit',v_limit,'offset',v_offset,'actor',v_actor);
end;
$$;

revoke all on function public.list_admin_active_loans_v3(public.loan_status, text, integer, integer) from public, anon;
grant execute on function public.list_admin_active_loans_v3(public.loan_status, text, integer, integer) to authenticated;

create or replace function public.get_admin_loan_detail_v3(p_loan_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('loan.read');
  v_loan jsonb;
  v_installments jsonb;
  v_allocations jsonb;
  v_guarantee jsonb;
  v_extensions jsonb;
  v_recoveries jsonb;
  v_audit jsonb;
begin
  select jsonb_build_object(
    'loan', to_jsonb(l),
    'borrower', case
      when l.outsider_loan_application_id is not null then jsonb_build_object(
        'type','outsider',
        'name',oa.applicant_full_name,
        'phone',oa.applicant_phone,
        'address',oa.applicant_address
      )
      else jsonb_build_object(
        'type','member',
        'profile_id',p.id,
        'name',p.full_name,
        'phone',p.phone,
        'email',p.email,
        'member_number',m.member_number
      )
    end
  ) into v_loan
  from public.loans l
  left join public.profiles p on p.id=l.borrower_profile_id
  left join public.members m on m.id=l.member_id
  left join public.outsider_loan_applications oa on oa.id=l.outsider_loan_application_id
  where l.id=p_loan_id;

  if v_loan is null then raise exception 'Loan not found'; end if;

  select coalesce(jsonb_agg(to_jsonb(li) order by li.installment_number), '[]'::jsonb)
  into v_installments
  from public.loan_installments li where li.loan_id=p_loan_id;

  select coalesce(jsonb_agg(to_jsonb(a) order by a.created_at desc), '[]'::jsonb)
  into v_allocations
  from public.loan_repayment_allocations a where a.loan_id=p_loan_id;

  select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb)
  into v_extensions
  from public.loan_extension_requests x where x.loan_id=p_loan_id;

  select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb)
  into v_recoveries
  from public.loan_recovery_events x where x.loan_id=p_loan_id;

  if (v_loan->'borrower'->>'type') = 'member' then
    select coalesce(to_jsonb(g), '{}'::jsonb) into v_guarantee
    from public.member_loan_guarantors g
    join public.loans l on l.loan_application_id=g.loan_application_id
    where l.id=p_loan_id;
  else
    select coalesce(to_jsonb(g), '{}'::jsonb) into v_guarantee
    from public.outsider_loan_guarantors g
    join public.loans l on l.outsider_loan_application_id=g.outsider_loan_application_id
    where l.id=p_loan_id;
  end if;

  select coalesce(jsonb_agg(to_jsonb(a) order by a.created_at desc), '[]'::jsonb)
  into v_audit
  from public.audit_logs a
  where a.entity_id=p_loan_id or a.entity_type='loan_repayment_submission' and a.entity_id in (select id from public.loan_repayment_submissions where loan_id=p_loan_id);

  return jsonb_build_object('loan',v_loan,'installments',v_installments,'allocations',v_allocations,'guarantor',coalesce(v_guarantee,'{}'::jsonb),'extensions',v_extensions,'recoveries',v_recoveries,'audit',v_audit,'actor',v_actor);
end;
$$;

revoke all on function public.get_admin_loan_detail_v3(uuid) from public, anon;
grant execute on function public.get_admin_loan_detail_v3(uuid) to authenticated;

/* -------------------------------------------------------------------------- */
/* 3. Approval command                                                         */
/* -------------------------------------------------------------------------- */

create or replace function public.review_loan_application_v3(
  p_borrower_type public.loan_borrower_type,
  p_application_id uuid,
  p_decision public.loan_approval_decision,
  p_approved_amount numeric default null,
  p_comment text default null,
  p_manual_checks jsonb default '{}'::jsonb,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('loan.approve');
  v_idem jsonb;
  v_application record;
  v_guarantee record;
  v_existing_approval record;
  v_approved_count integer := 0;
  v_amount numeric(18,2);
  v_maximum numeric(18,2);
  v_requested numeric(18,2);
  v_rate numeric(8,4);
  v_term integer;
  v_liquidity jsonb;
  v_eligible boolean := true;
  v_reasons jsonb := '[]'::jsonb;
  v_conflict boolean := false;
  v_old jsonb;
  v_new jsonb;
  v_response jsonb;
begin
  if p_idempotency_key is null then
    raise exception 'Idempotency key is required for approval commands';
  end if;

  v_idem := private.loan_begin_idempotency_v3(
    v_actor,
    'REVIEW_LOAN_APPLICATION',
    p_idempotency_key,
    'loan_application',
    p_application_id
  );

  if coalesce((v_idem->>'replayed')::boolean, false) then
    return v_idem->'response';
  end if;

  perform private.loan_lock_financial_domain_v3('UNITY_FINANCE_LOAN_LIQUIDITY');

  if p_borrower_type = 'member' then
    select
      la.*,
      lp.service_charge_rate,
      lp.term_months,
      least(lp.max_amount, 20000::numeric) hard_cap
    into v_application
    from public.loan_applications la
    join public.loan_products lp on lp.id=la.loan_product_id
    where la.id=p_application_id
      and lp.borrower_type='member'
    for update;
  else
    select
      oa.*,
      lp.service_charge_rate,
      lp.term_months,
      least(lp.max_amount, 20000::numeric) hard_cap
    into v_application
    from public.outsider_loan_applications oa
    join public.loan_products lp on lp.id=oa.loan_product_id
    where oa.id=p_application_id
      and lp.borrower_type='outsider'
    for update;
  end if;

  if not found then
    raise exception 'Loan application not found';
  end if;

  if v_application.status not in ('eligible','under_review') then
    raise exception 'Application is not in a reviewable state';
  end if;

  if p_decision='rejected' then
    if p_comment is null or length(trim(p_comment)) < 10 or length(trim(p_comment)) > 500 then
      raise exception 'A rejection reason is required and must contain 10 to 500 characters';
    end if;
  end if;

  /* Conflict-of-interest: explicit declaration OR direct guarantor relationship. */
  if p_borrower_type='member' then
    select exists(
      select 1 from public.member_loan_guarantors g
      join public.members gm on gm.id=g.guarantor_member_id
      where g.loan_application_id=p_application_id
        and g.status='accepted'
        and gm.profile_id=v_actor
    ) into v_conflict;
  else
    select exists(
      select 1 from public.outsider_loan_guarantors g
      join public.members gm on gm.id=g.guarantor_member_id
      where g.outsider_loan_application_id=p_application_id
        and g.status='accepted'
        and gm.profile_id=v_actor
    ) into v_conflict;
  end if;

  v_conflict := v_conflict or exists(
    select 1
    from public.loan_conflict_declarations c
    where c.actor_profile_id=v_actor
      and c.status='declared'
      and (
        (p_borrower_type='member' and c.application_id=p_application_id)
        or (p_borrower_type='outsider' and c.outsider_application_id=p_application_id)
      )
  );

  if v_conflict then
    raise exception 'Reviewer has a declared or relationship-based conflict of interest for this application';
  end if;

  if p_borrower_type='member' then
    if v_application.applicant_profile_id=v_actor then
      raise exception 'A person cannot approve their own loan';
    end if;

    if not exists (
      select 1 from public.members m
      where m.id=v_application.member_id and m.status='active'
    ) then
      v_eligible := false;
      v_reasons := v_reasons || jsonb_build_array('ACTIVE_MEMBER_REQUIRED');
    end if;

    if (
      select count(*) from public.savings_obligations so
      where so.member_id=v_application.member_id and so.status='paid'
    ) < 2 then
      v_eligible := false;
      v_reasons := v_reasons || jsonb_build_array('MINIMUM_SAVING_HISTORY');
    end if;

    if exists (
      select 1
      from public.loans l
      join public.loan_installments li on li.loan_id=l.id
      where l.member_id=v_application.member_id
        and l.status in ('active','overdue','defaulted')
        and li.paid_amount < li.total_due
        and li.due_date < current_date
    ) then
      v_eligible := false;
      v_reasons := v_reasons || jsonb_build_array('OVERDUE_LOAN');
    end if;

    if exists (
      select 1 from public.savings_obligations so
      where so.member_id=v_application.member_id
        and so.period_year=extract(year from current_date)::integer
        and so.period_month=extract(month from current_date)::integer
        and so.due_date <= current_date
        and so.paid_amount < so.required_amount
    ) then
      v_eligible := false;
      v_reasons := v_reasons || jsonb_build_array('MONTHLY_CONTRIBUTION_NOT_FULFILLED');
    end if;

    v_maximum := least(private.member_total_savings_v2(v_application.member_id) * 2, v_application.hard_cap, 20000::numeric);

    if v_application.requested_amount > v_maximum then
      v_eligible := false;
      v_reasons := v_reasons || jsonb_build_array('AMOUNT_EXCEEDS_MAXIMUM');
    end if;

    select * into v_guarantee
    from public.member_loan_guarantors g
    where g.loan_application_id=p_application_id
      and g.status='accepted'
    for update;

  else
    select * into v_guarantee
    from public.outsider_loan_guarantors g
    where g.outsider_loan_application_id=p_application_id
      and g.status='accepted'
    for update;

    if not found then
      v_eligible := false;
      v_reasons := v_reasons || jsonb_build_array('GUARANTOR_NOT_ACCEPTED');
    end if;

    if found and not exists (
      select 1 from public.members m
      where m.id=v_guarantee.guarantor_member_id and m.status='active'
    ) then
      v_eligible := false;
      v_reasons := v_reasons || jsonb_build_array('GUARANTOR_NOT_ACTIVE');
    end if;

    if found then
      v_maximum := least(private.member_total_savings_v2(v_guarantee.guarantor_member_id) * 2, v_application.hard_cap, 20000::numeric);
      if v_application.requested_amount > v_maximum then
        v_eligible := false;
        v_reasons := v_reasons || jsonb_build_array('AMOUNT_EXCEEDS_GUARANTOR_SUPPORTED_MAXIMUM');
      end if;
    else
      v_maximum := 0;
    end if;
  end if;

  if p_decision='rejected' then
    v_old := to_jsonb(v_application);

    if p_borrower_type='member' then
      update public.loan_applications
      set status='rejected',
          updated_at=now()
      where id=p_application_id;
    else
      update public.outsider_loan_applications
      set status='rejected',
          reviewed_at=now(),
          updated_at=now()
      where id=p_application_id;
    end if;

    insert into public.loan_approvals(
      loan_application_id,
      outsider_loan_application_id,
      approver_profile_id,
      decision,
      comment,
      manual_checks,
      decided_at
    ) values (
      case when p_borrower_type='member' then p_application_id end,
      case when p_borrower_type='outsider' then p_application_id end,
      v_actor,
      'rejected',
      trim(p_comment),
      coalesce(p_manual_checks,'{}'::jsonb),
      now()
    );

    v_new := jsonb_build_object('status','rejected','reason',trim(p_comment));
    perform private.loan_audit_v3(v_actor,'LOAN_APPLICATION_REJECTED',case when p_borrower_type='member' then 'loan_application' else 'outsider_loan_application' end,p_application_id,v_old,v_new,'{}'::jsonb);

    v_response := jsonb_build_object(
      'application_id',p_application_id,
      'borrower_type',p_borrower_type,
      'decision','rejected',
      'status','rejected'
    );
    perform private.loan_finish_idempotency_v3(v_actor,'REVIEW_LOAN_APPLICATION',p_idempotency_key,v_response);
    return v_response;
  end if;

  /* Approval requires a management acknowledgement because the playbook does
     not define an objective repayment-capacity formula yet. */
  if coalesce((p_manual_checks->>'repayment_capacity_confirmed')::boolean,false) is not true then
    raise exception 'Repayment capacity must be explicitly confirmed before approval';
  end if;
  if p_manual_checks->>'repayment_capacity_note' is null
     or length(trim(p_manual_checks->>'repayment_capacity_note')) < 10
     or length(trim(p_manual_checks->>'repayment_capacity_note')) > 1000 then
    raise exception 'Repayment capacity review note must contain 10 to 1000 characters';
  end if;

  if not v_eligible then
    raise exception 'Application failed current eligibility checks: %', v_reasons::text;
  end if;

  v_requested := v_application.requested_amount;

  select count(*)
  into v_approved_count
  from public.loan_approvals a
  where a.decision='approved'
    and ((p_borrower_type='member' and a.loan_application_id=p_application_id)
      or (p_borrower_type='outsider' and a.outsider_loan_application_id=p_application_id));

  /* Determine whether another reviewer has already fixed the amount. */
  select a.* into v_existing_approval
  from public.loan_approvals a
  where a.decision='approved'
    and (
      (p_borrower_type='member' and a.loan_application_id=p_application_id)
      or (p_borrower_type='outsider' and a.outsider_loan_application_id=p_application_id)
    )
  order by a.decided_at asc
  limit 1;

  if v_existing_approval.id is not null then
    if v_existing_approval.manual_checks->>'approved_amount' is null then
      raise exception 'Existing approval is missing the approved amount snapshot';
    end if;
    v_amount := (v_existing_approval.manual_checks->>'approved_amount')::numeric(18,2);
    if p_approved_amount is not null and round(p_approved_amount,2) <> v_amount then
      raise exception 'Second approval must use the exact approved amount fixed by the first approval';
    end if;
  else
    v_amount := round(coalesce(p_approved_amount, v_requested),2);
  end if;

  if v_amount <= 0 or v_amount > v_requested or v_amount > v_maximum then
    raise exception 'Approved amount is outside the allowed range';
  end if;

  v_liquidity := private.loan_liquidity_snapshot();
  if not coalesce((v_liquidity->>'reserve_compliant')::boolean,false) then
    raise exception 'Liquidity reserve would be breached';
  end if;
  if coalesce((v_liquidity->>'loanable_funds')::numeric,0) < v_amount then
    raise exception 'Current loanable funds are below the approved amount';
  end if;

  insert into public.loan_approvals(
    loan_application_id,
    outsider_loan_application_id,
    approver_profile_id,
    decision,
    comment,
    manual_checks,
    decided_at
  ) values (
    case when p_borrower_type='member' then p_application_id end,
    case when p_borrower_type='outsider' then p_application_id end,
    v_actor,
    'approved',
    nullif(trim(p_comment),''),
    coalesce(p_manual_checks,'{}'::jsonb) || jsonb_build_object(
      'approved_amount',v_amount,
      'reviewed_at',now()
    ),
    now()
  );

  select count(*) into v_approved_count
  from public.loan_approvals a
  where a.decision='approved'
    and (
      (p_borrower_type='member' and a.loan_application_id=p_application_id)
      or (p_borrower_type='outsider' and a.outsider_loan_application_id=p_application_id)
    );

  if v_approved_count = 1 then
    if p_borrower_type='member' then
      update public.loan_applications
      set
        status='under_review',
        approved_amount=v_amount,
        approved_service_charge_rate=v_application.service_charge_rate,
        approved_term_months=v_application.term_months,
        approved_rule_snapshot=jsonb_build_object(
          'product_id',v_application.loan_product_id,
          'service_charge_rate',v_application.service_charge_rate,
          'term_months',v_application.term_months,
          'hard_cap',v_application.hard_cap,
          'approved_amount',v_amount,
          'captured_at',now()
        ),
        updated_at=now()
      where id=p_application_id;
    else
      update public.outsider_loan_applications
      set
        status='under_review',
        approved_amount=v_amount,
        approved_at=null,
        approved_service_charge_rate=v_application.service_charge_rate,
        approved_term_months=v_application.term_months,
        approved_rule_snapshot=jsonb_build_object(
          'product_id',v_application.loan_product_id,
          'service_charge_rate',v_application.service_charge_rate,
          'term_months',v_application.term_months,
          'hard_cap',v_application.hard_cap,
          'approved_amount',v_amount,
          'captured_at',now()
        ),
        updated_at=now()
      where id=p_application_id;
    end if;
  else
    if v_approved_count < 2 then
      raise exception 'Unexpected approval count';
    end if;

    if p_borrower_type='member' then
      update public.loan_applications
      set status='approved', updated_at=now()
      where id=p_application_id;
    else
      update public.outsider_loan_applications
      set status='approved', approved_at=now(), reviewed_at=now(), updated_at=now()
      where id=p_application_id;
    end if;
  end if;

  v_new := jsonb_build_object(
    'decision','approved',
    'approval_count',v_approved_count,
    'approved_amount',v_amount,
    'application_status',case when v_approved_count >= 2 then 'approved' else 'under_review' end
  );

  perform private.loan_audit_v3(
    v_actor,
    'LOAN_APPLICATION_APPROVAL_RECORDED',
    case when p_borrower_type='member' then 'loan_application' else 'outsider_loan_application' end,
    p_application_id,
    v_old,
    v_new,
    jsonb_build_object('liquidity_snapshot',v_liquidity)
  );

  v_response := jsonb_build_object(
    'application_id',p_application_id,
    'borrower_type',p_borrower_type,
    'decision','approved',
    'approval_count',v_approved_count,
    'approved_amount',v_amount,
    'status',case when v_approved_count >= 2 then 'approved' else 'under_review' end
  );

  perform private.loan_finish_idempotency_v3(v_actor,'REVIEW_LOAN_APPLICATION',p_idempotency_key,v_response);
  return v_response;
end;
$$;

revoke all on function public.review_loan_application_v3(public.loan_borrower_type, uuid, public.loan_approval_decision, numeric, text, jsonb, text) from public, anon;
grant execute on function public.review_loan_application_v3(public.loan_borrower_type, uuid, public.loan_approval_decision, numeric, text, jsonb, text) to authenticated;

/* -------------------------------------------------------------------------- */
/* 4. Atomic final disbursement                                                */
/* -------------------------------------------------------------------------- */

create or replace function public.disburse_loan_v3(
  p_borrower_type public.loan_borrower_type,
  p_application_id uuid,
  p_source_account_code text,
  p_idempotency_key text,
  p_notes text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('loan.disburse');
  v_idem jsonb;
  v_application record;
  v_guarantee record;
  v_loan record;
  v_source_account_id uuid;
  v_receivable_account_id uuid;
  v_service_income_account_id uuid;
  v_principal numeric(18,2);
  v_service_rate numeric(8,4);
  v_service_charge numeric(18,2);
  v_total_repayment numeric(18,2);
  v_term integer;
  v_source_balance numeric(18,2);
  v_liquidity jsonb;
  v_approval_count integer;
  v_approved_amount_snapshot numeric(18,2);
  v_loan_id uuid;
  v_maturity_date date;
  v_disbursement_tx uuid;
  v_disbursement_id uuid;
  v_disbursed_at timestamptz := now();
  v_principal_per numeric(18,2);
  v_service_per numeric(18,2);
  v_p numeric(18,2);
  v_s numeric(18,2);
  v_i integer;
  v_t numeric(18,2);
  v_member_saving_months integer;
  v_source_code text := lower(trim(p_source_account_code));
  v_old jsonb;
  v_response jsonb;
begin
  if p_idempotency_key is null then
    raise exception 'Idempotency key is required for disbursement commands';
  end if;

  v_idem := private.loan_begin_idempotency_v3(
    v_actor,
    'DISBURSE_LOAN',
    p_idempotency_key,
    'loan_application',
    p_application_id
  );

  if coalesce((v_idem->>'replayed')::boolean,false) then
    return v_idem->'response';
  end if;

  /* Every V3 cash-changing loan command uses this same transaction lock. */
  perform private.loan_lock_financial_domain_v3('UNITY_FINANCE_LOAN_LIQUIDITY');

  v_source_account_id := private.loan_source_account_v3(v_source_code);
  if v_source_account_id is null then
    raise exception 'Invalid disbursement source account. Expected cash, bank, or wallet';
  end if;

  /* Lock the actual source account row in addition to the aggregate lock. */
  perform 1 from public.accounts where id=v_source_account_id and status='active' for update;
  if not found then
    raise exception 'Disbursement source account is not active';
  end if;

  v_receivable_account_id := private.system_account_id('loan_receivable'::public.account_type_code);
  v_service_income_account_id := private.system_account_id('loan_service_charge_income'::public.account_type_code);
  if v_receivable_account_id is null or v_service_income_account_id is null then
    raise exception 'Loan accounting accounts are not configured';
  end if;

  if p_borrower_type='member' then
    select la.*, lp.id product_id
    into v_application
    from public.loan_applications la
    join public.loan_products lp on lp.id=la.loan_product_id
    where la.id=p_application_id
      and lp.borrower_type='member'
    for update;
  else
    select oa.*, lp.id product_id
    into v_application
    from public.outsider_loan_applications oa
    join public.loan_products lp on lp.id=oa.loan_product_id
    where oa.id=p_application_id
      and lp.borrower_type='outsider'
    for update;
  end if;

  if not found then
    raise exception 'Approved loan application not found';
  end if;

  if v_application.status <> 'approved' then
    raise exception 'Loan application is not approved for disbursement';
  end if;

  select count(*)
  into v_approval_count
  from public.loan_approvals a
  where a.decision='approved'
    and (
      (p_borrower_type='member' and a.loan_application_id=p_application_id)
      or (p_borrower_type='outsider' and a.outsider_loan_application_id=p_application_id)
    );

  if v_approval_count < 2 then
    raise exception 'Two distinct approvals are required before disbursement';
  end if;

  /* A reviewer may not release funds for a loan they approved, even when the
     same profile has both permissions. This preserves approval/disbursement
     separation of duties at the command boundary. */
  if exists (
    select 1
    from public.loan_approvals a
    where a.decision='approved'
      and a.approver_profile_id=v_actor
      and (
        (p_borrower_type='member' and a.loan_application_id=p_application_id)
        or (p_borrower_type='outsider' and a.outsider_loan_application_id=p_application_id)
      )
  ) then
    raise exception 'An approver cannot disburse the same loan';
  end if;

  select (a.manual_checks->>'approved_amount')::numeric(18,2)
  into v_approved_amount_snapshot
  from public.loan_approvals a
  where a.decision='approved'
    and (
      (p_borrower_type='member' and a.loan_application_id=p_application_id)
      or (p_borrower_type='outsider' and a.outsider_loan_application_id=p_application_id)
    )
  order by a.decided_at asc
  limit 1;

  if v_approved_amount_snapshot is null then
    raise exception 'Approved amount snapshot is missing';
  end if;

  v_principal := round(v_approved_amount_snapshot,2);

  if exists (
    select 1 from public.loans l
    where (p_borrower_type='member' and l.loan_application_id=p_application_id)
       or (p_borrower_type='outsider' and l.outsider_loan_application_id=p_application_id)
  ) then
    raise exception 'Loan has already been disbursed';
  end if;

  /* Final member eligibility gate. Approval can become stale before cash is
     released, so all critical borrower conditions are checked again here. */
  if p_borrower_type='member' then
    if not exists (
      select 1 from public.members m
      where m.id=v_application.member_id and m.status='active'
    ) then
      raise exception 'Member is no longer active';
    end if;

    select count(*) into v_member_saving_months
    from public.savings_obligations so
    where so.member_id=v_application.member_id and so.status='paid';
    if v_member_saving_months < 2 then
      raise exception 'Member no longer satisfies the minimum saving history';
    end if;

    if exists (
      select 1
      from public.loans l
      join public.loan_installments li on li.loan_id=l.id
      where l.member_id=v_application.member_id
        and l.status in ('active','overdue','defaulted')
        and li.paid_amount < li.total_due
        and li.due_date < current_date
    ) then
      raise exception 'Member has an overdue loan';
    end if;

    if exists (
      select 1 from public.savings_obligations so
      where so.member_id=v_application.member_id
        and so.period_year=extract(year from current_date)::integer
        and so.period_month=extract(month from current_date)::integer
        and so.due_date <= current_date
        and so.paid_amount < so.required_amount
    ) then
      raise exception 'Current mandatory savings contribution is not fulfilled';
    end if;

    select * into v_guarantee
    from public.member_loan_guarantors g
    where g.loan_application_id=p_application_id
      and g.status='accepted'
    for update;

    if not found then
      raise exception 'Accepted guarantor is missing';
    end if;

    if not exists (
      select 1 from public.members m
      where m.id=v_guarantee.guarantor_member_id and m.status='active'
    ) then
      raise exception 'Guarantor is no longer active';
    end if;

    if private.member_max_loan_v2(v_application.member_id) < v_principal then
      raise exception 'Current member savings no longer support the approved amount';
    end if;

    v_service_rate := v_application.approved_service_charge_rate;
    v_term := v_application.approved_term_months;
  else
    select * into v_guarantee
    from public.outsider_loan_guarantors g
    where g.outsider_loan_application_id=p_application_id
      and g.status='accepted'
    for update;

    if not found then
      raise exception 'Accepted guarantor is missing';
    end if;

    if not exists (
      select 1 from public.members m
      where m.id=v_guarantee.guarantor_member_id and m.status='active'
    ) then
      raise exception 'Guarantor is no longer active';
    end if;

    if private.outsider_guarantor_max_loan_v2(v_guarantee.guarantor_member_id) < v_principal then
      raise exception 'Current guarantor savings no longer support the approved amount';
    end if;

    v_service_rate := v_application.approved_service_charge_rate;
    v_term := v_application.approved_term_months;
  end if;

  if v_service_rate is null or v_term is null or v_term <= 0 then
    raise exception 'Approved economic snapshot is incomplete';
  end if;

  if v_principal <= 0 or v_principal > v_application.requested_amount then
    raise exception 'Approved principal is invalid';
  end if;

  v_liquidity := private.loan_liquidity_snapshot();
  if not coalesce((v_liquidity->>'reserve_compliant')::boolean,false) then
    raise exception 'Current liquidity reserve is below the required minimum';
  end if;

  if coalesce((v_liquidity->>'loanable_funds')::numeric,0) < v_principal then
    raise exception 'Current loanable funds are below the approved amount';
  end if;

  v_source_balance := private.account_balance(v_source_account_id);
  if v_source_balance < v_principal then
    raise exception 'Selected disbursement account does not have sufficient funds';
  end if;

  v_service_charge := round(v_principal * v_service_rate,2);
  v_total_repayment := round(v_principal + v_service_charge,2);

  if p_borrower_type='member' then
    insert into public.loans(
      loan_application_id,
      outsider_loan_application_id,
      borrower_profile_id,
      member_id,
      principal,
      service_charge_rate,
      service_charge_amount,
      total_repayment,
      term_months,
      status,
      disbursed_at,
      maturity_date
    ) values (
      p_application_id,
      null,
      v_application.applicant_profile_id,
      v_application.member_id,
      v_principal,
      v_service_rate,
      v_service_charge,
      v_total_repayment,
      v_term,
      'active',
      v_disbursed_at,
      (v_disbursed_at::date + make_interval(months=>v_term))::date
    ) returning * into v_loan;
  else
    insert into public.loans(
      loan_application_id,
      outsider_loan_application_id,
      borrower_profile_id,
      member_id,
      principal,
      service_charge_rate,
      service_charge_amount,
      total_repayment,
      term_months,
      status,
      disbursed_at,
      maturity_date
    ) values (
      null,
      p_application_id,
      null,
      null,
      v_principal,
      v_service_rate,
      v_service_charge,
      v_total_repayment,
      v_term,
      'active',
      v_disbursed_at,
      (v_disbursed_at::date + make_interval(months=>v_term))::date
    ) returning * into v_loan;
  end if;

  /* The loan receivable contains principal + service charge. Cash/bank/wallet
     leaves only the principal. The difference is group service-charge income. */
  v_disbursement_tx := private.post_balanced_transaction_v3(
    'loan_disbursement'::public.transaction_type,
    case when p_borrower_type='member' then v_application.applicant_profile_id else null end,
    case when p_borrower_type='member' then v_application.member_id else null end,
    v_total_repayment,
    'loan',
    v_loan.id,
    coalesce(nullif(trim(p_notes),''), case when p_borrower_type='member' then 'Member loan disbursement' else 'Outsider loan disbursement' end),
    jsonb_build_array(
      jsonb_build_object('account_id',v_receivable_account_id,'entry_type','debit','amount',v_total_repayment),
      jsonb_build_object('account_id',v_source_account_id,'entry_type','credit','amount',v_principal),
      jsonb_build_object('account_id',v_service_income_account_id,'entry_type','credit','amount',v_service_charge)
    ),
    v_actor
  );

  v_principal_per := round(v_principal / v_term,2);
  v_service_per := round(v_service_charge / v_term,2);

  for v_i in 1..v_term loop
    if v_i < v_term then
      v_p := v_principal_per;
      v_s := v_service_per;
    else
      v_p := round(v_principal - (v_principal_per*(v_term-1)),2);
      v_s := round(v_service_charge - (v_service_per*(v_term-1)),2);
    end if;
    v_t := round(v_p+v_s,2);

    insert into public.loan_installments(
      loan_id,
      installment_number,
      due_date,
      principal_amount,
      service_charge_amount,
      total_due,
      paid_amount,
      late_penalty_amount,
      paid_penalty_amount,
      status
    ) values (
      v_loan.id,
      v_i,
      (v_disbursed_at::date + make_interval(months=>v_i))::date,
      v_p,
      v_s,
      v_t,
      0,
      0,
      0,
      'pending'
    );
  end loop;

  insert into public.loan_disbursements(
    loan_id,
    amount,
    payment_method_code,
    transaction_id,
    released_by,
    released_at,
    notes
  ) values (
    v_loan.id,
    v_principal,
    v_source_code,
    v_disbursement_tx,
    v_actor,
    v_disbursed_at,
    nullif(trim(p_notes),'')
  ) returning id into v_disbursement_id;

  if p_borrower_type='member' then
    update public.loan_applications
    set updated_at=now()
    where id=p_application_id;
  else
    update public.outsider_loan_applications
    set reviewed_at=coalesce(reviewed_at,now()), updated_at=now()
    where id=p_application_id;
  end if;

  perform private.loan_audit_v3(
    v_actor,
    'LOAN_DISBURSED',
    'loan',
    v_loan.id,
    null,
    jsonb_build_object(
      'loan_id',v_loan.id,
      'application_id',p_application_id,
      'borrower_type',p_borrower_type,
      'principal',v_principal,
      'service_charge_rate',v_service_rate,
      'service_charge_amount',v_service_charge,
      'total_repayment',v_total_repayment,
      'term_months',v_term,
      'source_account',v_source_code
    ),
    jsonb_build_object(
      'transaction_id',v_disbursement_tx,
      'disbursement_id',v_disbursement_id,
      'liquidity_snapshot',v_liquidity
    )
  );

  v_response := jsonb_build_object(
    'loan_id',v_loan.id,
    'loan_number',v_loan.loan_number,
    'principal',v_principal,
    'service_charge_rate',v_service_rate,
    'service_charge_amount',v_service_charge,
    'total_repayment',v_total_repayment,
    'term_months',v_term,
    'maturity_date',v_loan.maturity_date,
    'transaction_id',v_disbursement_tx,
    'disbursement_id',v_disbursement_id,
    'status','active'
  );

  perform private.loan_finish_idempotency_v3(v_actor,'DISBURSE_LOAN',p_idempotency_key,v_response);
  return v_response;
end;
$$;

revoke all on function public.disburse_loan_v3(public.loan_borrower_type, uuid, text, text, text) from public, anon;
grant execute on function public.disburse_loan_v3(public.loan_borrower_type, uuid, text, text, text) to authenticated;

/* -------------------------------------------------------------------------- */
/* 5. Repayment submission, verification and posting                           */
/* -------------------------------------------------------------------------- */

create or replace function public.create_loan_repayment_submission_v3(
  p_loan_id uuid,
  p_amount numeric,
  p_payment_method_code text,
  p_external_reference text default null,
  p_payment_proof_path text default null,
  p_payer_name text default null,
  p_payer_phone text default null,
  p_payment_id uuid default null,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_idem jsonb;
  v_loan record;
  v_borrower_type public.loan_borrower_type;
  v_submission_id uuid;
  v_response jsonb;
  v_payment record;
begin
  if v_actor is null then
    raise exception 'Not authenticated';
  end if;

  if p_idempotency_key is null then
    raise exception 'Idempotency key is required';
  end if;

  v_idem := private.loan_begin_idempotency_v3(v_actor,'CREATE_LOAN_REPAYMENT_SUBMISSION',p_idempotency_key,'loan',p_loan_id);
  if coalesce((v_idem->>'replayed')::boolean,false) then return v_idem->'response'; end if;

  select l.* into v_loan from public.loans l where l.id=p_loan_id for update;
  if not found then raise exception 'Loan not found'; end if;
  if v_loan.status in ('paid','cancelled') then raise exception 'Loan cannot receive repayments in its current state'; end if;

  v_borrower_type := case when v_loan.outsider_loan_application_id is null then 'member'::public.loan_borrower_type else 'outsider'::public.loan_borrower_type end;

  if v_borrower_type='outsider'
     and not private.current_user_has_permission('loan.review') then
    raise exception 'Unauthorized to create an outsider repayment submission';
  end if;

  if p_amount is null or round(p_amount,2) <= 0 then raise exception 'Repayment amount must be greater than zero'; end if;
  if p_payment_method_code is null or lower(trim(p_payment_method_code)) not in ('cash','bank','wallet') then raise exception 'Invalid repayment payment method'; end if;

  if v_borrower_type='member' then
    if v_loan.borrower_profile_id <> v_actor then
      raise exception 'Only the borrower may create a member repayment submission';
    end if;
  else
    if p_payer_name is null or length(trim(p_payer_name)) < 2 then raise exception 'Outsider payer name is required'; end if;
    if p_payer_phone is null or length(trim(p_payer_phone)) < 7 then raise exception 'Outsider payer phone is required'; end if;
  end if;

  if p_payment_id is not null then
    select * into v_payment from public.payments p where p.id=p_payment_id for update;
    if not found then raise exception 'Payment record not found'; end if;
    if v_payment.status not in ('pending','verified') then raise exception 'Linked payment is not in a verifiable state'; end if;
    if v_payment.amount <> round(p_amount,2) then raise exception 'Payment amount does not match repayment submission'; end if;
    if v_payment.purpose_id is distinct from p_loan_id then raise exception 'Payment is not linked to this loan'; end if;
    if v_payment.purpose_type <> 'loan_repayment' then raise exception 'Linked payment is not a loan repayment'; end if;
    if v_borrower_type='member' and v_payment.payer_profile_id is distinct from v_loan.borrower_profile_id then raise exception 'Payment payer does not match member borrower'; end if;
  end if;

  insert into public.loan_repayment_submissions(
    loan_id,
    payment_id,
    borrower_type,
    payer_profile_id,
    payer_name,
    payer_phone,
    amount,
    payment_method_code,
    external_reference,
    payment_proof_path,
    status,
    submitted_by
  ) values (
    p_loan_id,
    p_payment_id,
    v_borrower_type,
    case when v_borrower_type='member' then v_actor end,
    case when v_borrower_type='member' then (select p.full_name from public.profiles p where p.id=v_actor) else trim(p_payer_name) end,
    case when v_borrower_type='member' then (select p.phone from public.profiles p where p.id=v_actor) else trim(p_payer_phone) end,
    round(p_amount,2),
    lower(trim(p_payment_method_code)),
    nullif(trim(p_external_reference),''),
    nullif(trim(p_payment_proof_path),''),
    case when p_payment_id is not null and v_payment.status='verified' then 'verified' else 'pending' end,
    v_actor
  ) returning id into v_submission_id;

  perform private.loan_audit_v3(v_actor,'LOAN_REPAYMENT_SUBMITTED','loan_repayment_submission',v_submission_id,null,jsonb_build_object('loan_id',p_loan_id,'amount',round(p_amount,2),'borrower_type',v_borrower_type),'{}'::jsonb);

  v_response := jsonb_build_object('submission_id',v_submission_id,'loan_id',p_loan_id,'amount',round(p_amount,2),'status',case when p_payment_id is not null and v_payment.status='verified' then 'verified' else 'pending' end);
  perform private.loan_finish_idempotency_v3(v_actor,'CREATE_LOAN_REPAYMENT_SUBMISSION',p_idempotency_key,v_response);
  return v_response;
end;
$$;

revoke all on function public.create_loan_repayment_submission_v3(uuid,numeric,text,text,text,text,text,uuid,text) from public, anon;
grant execute on function public.create_loan_repayment_submission_v3(uuid,numeric,text,text,text,text,text,uuid,text) to authenticated;

create or replace function public.admin_verify_loan_repayment_v3(
  p_submission_id uuid,
  p_decision public.payment_status,
  p_external_reference text default null,
  p_reason text default null,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('payment.verify');
  v_idem jsonb;
  v_sub record;
  v_old jsonb;
  v_response jsonb;
begin
  if p_idempotency_key is null then raise exception 'Idempotency key is required'; end if;
  if p_decision not in ('verified','rejected') then raise exception 'Verification decision must be verified or rejected'; end if;

  v_idem := private.loan_begin_idempotency_v3(v_actor,'VERIFY_LOAN_REPAYMENT',p_idempotency_key,'loan_repayment_submission',p_submission_id);
  if coalesce((v_idem->>'replayed')::boolean,false) then return v_idem->'response'; end if;

  select * into v_sub from public.loan_repayment_submissions where id=p_submission_id for update;
  if not found then raise exception 'Repayment submission not found'; end if;
  if v_sub.status <> 'pending' then raise exception 'Only pending repayment submissions can be verified'; end if;
  if p_decision='rejected' and (p_reason is null or length(trim(p_reason))<10 or length(trim(p_reason))>500) then raise exception 'A rejection reason of 10 to 500 characters is required'; end if;

  v_old := to_jsonb(v_sub);

  if p_decision='verified' then
    update public.loan_repayment_submissions
    set status='verified', verified_by=v_actor, verified_at=now(), rejected_reason=null, updated_at=now()
    where id=p_submission_id;
  else
    update public.loan_repayment_submissions
    set status='rejected', verified_by=v_actor, verified_at=now(), rejected_reason=trim(p_reason), updated_at=now()
    where id=p_submission_id;
  end if;

  if v_sub.payment_id is not null then
    update public.payments
    set status=p_decision,
        verified_by=case when p_decision='verified' then v_actor else verified_by end,
        verified_at=case when p_decision='verified' then now() else verified_at end,
        rejection_reason=case when p_decision='rejected' then trim(p_reason) else null end,
        external_reference=coalesce(nullif(trim(p_external_reference),''), external_reference),
        updated_at=now()
    where id=v_sub.payment_id;

    insert into public.payment_verifications(
      payment_id, verification_type, status, verified_by, external_reference, evidence, verified_at
    ) values (
      v_sub.payment_id, 'manual_loan_repayment', p_decision, v_actor,
      nullif(trim(p_external_reference),''), jsonb_build_object('loan_repayment_submission_id',p_submission_id), now()
    );
  end if;

  v_response := jsonb_build_object('submission_id',p_submission_id,'status',p_decision::text);
  perform private.loan_audit_v3(v_actor,'LOAN_REPAYMENT_VERIFIED','loan_repayment_submission',p_submission_id,v_old,v_response,jsonb_build_object('external_reference',p_external_reference));
  perform private.loan_finish_idempotency_v3(v_actor,'VERIFY_LOAN_REPAYMENT',p_idempotency_key,v_response);
  return v_response;
end;
$$;

revoke all on function public.admin_verify_loan_repayment_v3(uuid,public.payment_status,text,text,text) from public, anon;
grant execute on function public.admin_verify_loan_repayment_v3(uuid,public.payment_status,text,text,text) to authenticated;

create or replace function public.post_loan_repayment_v3(
  p_submission_id uuid,
  p_allocations jsonb,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('payment.verify');
  v_idem jsonb;
  v_sub record;
  v_loan record;
  v_installment record;
  v_item record;
  v_source_account_id uuid;
  v_receivable_account_id uuid;
  v_penalty_income_account_id uuid;
  v_tx uuid;
  v_total numeric(18,2);
  v_base numeric(18,2) := 0;
  v_penalty numeric(18,2) := 0;
  v_alloc_count integer;
  v_old jsonb;
  v_response jsonb;
begin
  if p_idempotency_key is null then raise exception 'Idempotency key is required'; end if;
  if p_allocations is null or jsonb_typeof(p_allocations)<>'array' or jsonb_array_length(p_allocations)=0 then
    raise exception 'Repayment allocations are required';
  end if;

  v_idem := private.loan_begin_idempotency_v3(v_actor,'POST_LOAN_REPAYMENT',p_idempotency_key,'loan_repayment_submission',p_submission_id);
  if coalesce((v_idem->>'replayed')::boolean,false) then return v_idem->'response'; end if;

  perform private.loan_lock_financial_domain_v3('UNITY_FINANCE_LOAN_LIQUIDITY');

  select * into v_sub
  from public.loan_repayment_submissions
  where id=p_submission_id
  for update;
  if not found then raise exception 'Repayment submission not found'; end if;
  if v_sub.status <> 'verified' then raise exception 'Repayment submission must be verified before posting'; end if;
  if v_sub.reversed_at is not null then raise exception 'Reversed repayment cannot be posted'; end if;

  select * into v_loan
  from public.loans
  where id=v_sub.loan_id
  for update;
  if not found then raise exception 'Loan not found'; end if;
  if v_loan.status='cancelled' then raise exception 'Cancelled loan cannot receive repayment'; end if;

  if v_sub.borrower_type='member' and v_sub.payer_profile_id is distinct from v_loan.borrower_profile_id then
    raise exception 'Repayment payer does not match the loan borrower';
  end if;
  if v_sub.borrower_type='outsider' and v_loan.outsider_loan_application_id is null then
    raise exception 'Outsider repayment is not linked to an outsider loan';
  end if;

  v_source_account_id := private.loan_source_account_v3(v_sub.payment_method_code);
  v_receivable_account_id := private.system_account_id('loan_receivable'::public.account_type_code);
  v_penalty_income_account_id := private.system_account_id('penalty_income'::public.account_type_code);

  if v_source_account_id is null or v_receivable_account_id is null or v_penalty_income_account_id is null then
    raise exception 'Repayment accounting accounts are not configured';
  end if;

  perform 1 from public.accounts where id=v_source_account_id and status='active' for update;
  if not found then raise exception 'Repayment source account is not active'; end if;

  /* Lock every referenced installment before validating allocation sums. */
  for v_item in
    select (x->>'installment_id')::uuid as installment_id
    from jsonb_array_elements(p_allocations) x
  loop
    if v_item.installment_id is null then raise exception 'Every repayment allocation requires an installment_id'; end if;
    select * into v_installment
    from public.loan_installments li
    where li.id=v_item.installment_id and li.loan_id=v_loan.id
    for update;
    if not found then raise exception 'Repayment allocation references an installment outside this loan'; end if;
  end loop;

  select count(*),
         coalesce(sum(round(coalesce((x->>'base_amount')::numeric,0),2)),0),
         coalesce(sum(round(coalesce((x->>'penalty_amount')::numeric,0),2)),0)
  into v_alloc_count, v_base, v_penalty
  from jsonb_array_elements(p_allocations) x;

  if v_alloc_count=0 then raise exception 'At least one repayment allocation is required'; end if;
  if v_base < 0 or v_penalty < 0 then raise exception 'Repayment allocation amounts cannot be negative'; end if;
  v_total := round(v_base+v_penalty,2);
  if v_total <= 0 then raise exception 'Repayment allocation total must be greater than zero'; end if;
  if v_total <> round(v_sub.amount,2) then
    raise exception 'Allocation total % does not equal verified payment amount %',v_total,v_sub.amount;
  end if;

  /* Validate and apply allocations aggregated per installment. This prevents
     duplicate installment objects in one request from bypassing remaining-balance
     checks. */
  for v_item in
    select
      (x->>'installment_id')::uuid installment_id,
      round(sum(coalesce((x->>'base_amount')::numeric,0)),2) base_amount,
      round(sum(coalesce((x->>'penalty_amount')::numeric,0)),2) penalty_amount
    from jsonb_array_elements(p_allocations) x
    group by (x->>'installment_id')::uuid
  loop
    if v_item.base_amount < 0 or v_item.penalty_amount < 0 then
      raise exception 'Negative repayment allocation';
    end if;

    select * into v_installment
    from public.loan_installments li
    where li.id=v_item.installment_id and li.loan_id=v_loan.id
    for update;

    if not found then
      raise exception 'Repayment allocation references an installment outside this loan';
    end if;

    if v_item.base_amount > round(v_installment.total_due-v_installment.paid_amount,2) then
      raise exception 'Base allocation exceeds remaining installment amount';
    end if;
    if v_item.penalty_amount > round(v_installment.late_penalty_amount-v_installment.paid_penalty_amount,2) then
      raise exception 'Penalty allocation exceeds remaining installment penalty';
    end if;
    if v_item.base_amount+v_item.penalty_amount <= 0 then
      raise exception 'Each allocation must contain a positive amount';
    end if;

    if exists (
      select 1 from public.loan_repayment_allocations a
      where a.repayment_submission_id=p_submission_id
        and a.installment_id=v_item.installment_id
    ) then
      raise exception 'Repayment allocation already exists for this submission and installment';
    end if;
  end loop;

  v_tx := private.post_balanced_transaction_v3(
    'loan_repayment'::public.transaction_type,
    v_loan.borrower_profile_id,
    v_loan.member_id,
    v_total,
    'loan_repayment_submission',
    p_submission_id,
    'Loan repayment posting',
    jsonb_build_array(
      jsonb_build_object('account_id',v_source_account_id,'entry_type','debit','amount',v_total),
      jsonb_build_object('account_id',v_receivable_account_id,'entry_type','credit','amount',v_base),
      jsonb_build_object('account_id',v_penalty_income_account_id,'entry_type','credit','amount',v_penalty)
    ),
    v_actor
  );

  for v_item in
    select
      (x->>'installment_id')::uuid installment_id,
      round(sum(coalesce((x->>'base_amount')::numeric,0)),2) base_amount,
      round(sum(coalesce((x->>'penalty_amount')::numeric,0)),2) penalty_amount
    from jsonb_array_elements(p_allocations) x
    group by (x->>'installment_id')::uuid
  loop
    insert into public.loan_repayment_allocations(
      payment_id,
      repayment_submission_id,
      loan_id,
      installment_id,
      allocated_base_amount,
      allocated_penalty_amount,
      transaction_id
    ) values (
      v_sub.payment_id,
      p_submission_id,
      v_loan.id,
      v_item.installment_id,
      v_item.base_amount,
      v_item.penalty_amount,
      v_tx
    );

    update public.loan_installments li
    set
      paid_amount=round(li.paid_amount+v_item.base_amount,2),
      paid_penalty_amount=round(li.paid_penalty_amount+v_item.penalty_amount,2),
      status=case
        when round(li.paid_amount+v_item.base_amount,2) >= li.total_due
         and round(li.paid_penalty_amount+v_item.penalty_amount,2) >= li.late_penalty_amount
          then 'paid'::public.installment_status
        when li.due_date < current_date
          then 'overdue'::public.installment_status
        else 'pending'::public.installment_status
      end,
      updated_at=now()
    where li.id=v_item.installment_id;
  end loop;

  update public.loan_repayment_submissions
  set status='posted', posted_transaction_id=v_tx, updated_at=now()
  where id=p_submission_id;

  if not exists (
    select 1
    from public.loan_installments li
    where li.loan_id=v_loan.id
      and (
        li.paid_amount < li.total_due
        or li.paid_penalty_amount < li.late_penalty_amount
      )
  ) then
    update public.loans set status='paid', updated_at=now() where id=v_loan.id;

    update public.member_loan_guarantors g
    set status='released', responded_at=now(), updated_at=now()
    where g.loan_application_id=v_loan.loan_application_id and g.status='accepted';

    update public.outsider_loan_guarantors g
    set status='released', responded_at=now(), updated_at=now()
    where g.outsider_loan_application_id=v_loan.outsider_loan_application_id and g.status='accepted';
  elsif exists (
    select 1 from public.loan_installments li
    where li.loan_id=v_loan.id and li.status='defaulted'
  ) then
    update public.loans set status='defaulted', updated_at=now() where id=v_loan.id;
  elsif exists (
    select 1 from public.loan_installments li
    where li.loan_id=v_loan.id and li.status='overdue'
  ) then
    update public.loans set status='overdue', updated_at=now() where id=v_loan.id;
  else
    update public.loans set status='active', updated_at=now() where id=v_loan.id;
  end if;

  perform private.loan_audit_v3(
    v_actor,
    'LOAN_REPAYMENT_POSTED',
    'loan',
    v_loan.id,
    null,
    jsonb_build_object('submission_id',p_submission_id,'base_amount',v_base,'penalty_amount',v_penalty,'total_amount',v_total),
    jsonb_build_object('transaction_id',v_tx)
  );

  v_response := jsonb_build_object(
    'loan_id',v_loan.id,
    'submission_id',p_submission_id,
    'transaction_id',v_tx,
    'base_amount',v_base,
    'penalty_amount',v_penalty,
    'total_amount',v_total
  );

  perform private.loan_finish_idempotency_v3(v_actor,'POST_LOAN_REPAYMENT',p_idempotency_key,v_response);
  return v_response;
end;
$$;

revoke all on function public.post_loan_repayment_v3(uuid,jsonb,text) from public, anon;
grant execute on function public.post_loan_repayment_v3(uuid,jsonb,text) to authenticated;

/* -------------------------------------------------------------------------- */
/* 6. Overdue penalty processing                                               */
/* -------------------------------------------------------------------------- */

alter table public.loan_penalties
  add column if not exists reversed_at timestamptz,
  add column if not exists reversal_transaction_id uuid references public.transactions(id) on delete restrict;

alter table public.loan_penalties
  drop constraint if exists loan_penalties_installment_id_key;

create unique index if not exists loan_penalties_active_installment_uq
  on public.loan_penalties(installment_id)
  where reversed_at is null;

alter table public.loan_repayment_allocations
  add column if not exists reversed_at timestamptz,
  add column if not exists reversal_transaction_id uuid references public.transactions(id) on delete restrict;

create or replace function private.process_one_overdue_installment_v3(
  p_installment_id uuid,
  p_actor uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_li record;
  v_loan record;
  v_rate numeric(8,4);
  v_penalty numeric(18,2);
  v_receivable_account uuid;
  v_penalty_income_account uuid;
  v_tx uuid;
begin
  select li.* into v_li
  from public.loan_installments li
  where li.id=p_installment_id
  for update;
  if not found then raise exception 'Installment not found'; end if;

  select * into v_loan from public.loans l where l.id=v_li.loan_id for update;
  if not found then raise exception 'Loan not found'; end if;

  if v_li.due_date >= current_date then
    return jsonb_build_object('processed',false,'reason','NOT_OVERDUE');
  end if;
  if v_li.paid_amount >= v_li.total_due then
    return jsonb_build_object('processed',false,'reason','ALREADY_PAID');
  end if;
  if exists (
    select 1 from public.loan_penalties lp
    where lp.installment_id=v_li.id and lp.reversed_at is null
  ) then
    update public.loan_installments
    set status='overdue', updated_at=now()
    where id=v_li.id and status='pending';
    update public.loans set status='overdue', updated_at=now() where id=v_loan.id and status='active';
    return jsonb_build_object('processed',false,'reason','PENALTY_ALREADY_APPLIED');
  end if;

  v_rate := coalesce(public.get_active_rule_numeric('loan_late_penalty_rate'),0.05);
  v_penalty := round(v_li.total_due * v_rate,2);
  if v_penalty <= 0 then raise exception 'Configured late penalty is not positive'; end if;

  v_receivable_account := private.system_account_id('loan_receivable'::public.account_type_code);
  v_penalty_income_account := private.system_account_id('penalty_income'::public.account_type_code);
  if v_receivable_account is null or v_penalty_income_account is null then
    raise exception 'Penalty accounting accounts are not configured';
  end if;

  v_tx := private.post_balanced_transaction_v3(
    'loan_late_penalty'::public.transaction_type,
    v_loan.borrower_profile_id,
    v_loan.member_id,
    v_penalty,
    'loan_installment',
    v_li.id,
    'Late loan-installment penalty',
    jsonb_build_array(
      jsonb_build_object('account_id',v_receivable_account,'entry_type','debit','amount',v_penalty),
      jsonb_build_object('account_id',v_penalty_income_account,'entry_type','credit','amount',v_penalty)
    ),
    p_actor
  );

  insert into public.loan_penalties(
    installment_id, rate, amount, transaction_id, charged_at
  ) values (
    v_li.id, v_rate, v_penalty, v_tx, now()
  );

  update public.loan_installments
  set late_penalty_amount=v_penalty,
      status='overdue',
      updated_at=now()
  where id=v_li.id;

  update public.loans set status='overdue', updated_at=now() where id=v_loan.id and status='active';

  perform private.loan_audit_v3(
    p_actor,
    'LOAN_LATE_PENALTY_APPLIED',
    'loan_installment',
    v_li.id,
    null,
    jsonb_build_object('penalty_rate',v_rate,'penalty_amount',v_penalty),
    jsonb_build_object('transaction_id',v_tx,'loan_id',v_loan.id)
  );

  return jsonb_build_object('processed',true,'installment_id',v_li.id,'loan_id',v_loan.id,'penalty_amount',v_penalty,'transaction_id',v_tx);
end;
$$;

revoke all on function private.process_one_overdue_installment_v3(uuid,uuid) from public, anon, authenticated;

create or replace function public.process_overdue_loan_installment_v3(
  p_installment_id uuid,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('loan.review');
  v_idem jsonb;
  v_response jsonb;
begin
  if p_idempotency_key is not null then
    v_idem := private.loan_begin_idempotency_v3(v_actor,'PROCESS_OVERDUE_INSTALLMENT',p_idempotency_key,'loan_installment',p_installment_id);
    if coalesce((v_idem->>'replayed')::boolean,false) then return v_idem->'response'; end if;
  end if;

  perform private.loan_lock_financial_domain_v3('UNITY_FINANCE_LOAN_LIQUIDITY');
  v_response := private.process_one_overdue_installment_v3(p_installment_id,v_actor);

  if p_idempotency_key is not null then
    perform private.loan_finish_idempotency_v3(v_actor,'PROCESS_OVERDUE_INSTALLMENT',p_idempotency_key,v_response);
  end if;

  return v_response;
end;
$$;

revoke all on function public.process_overdue_loan_installment_v3(uuid,text) from public, anon;
grant execute on function public.process_overdue_loan_installment_v3(uuid,text) to authenticated;

/* pg_cron / scheduler entry point. EXECUTE is revoked from application roles. */
create or replace function public.process_overdue_loan_installments_v3()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer := 0;
  v_item record;
begin
  perform private.loan_lock_financial_domain_v3('UNITY_FINANCE_LOAN_LIQUIDITY');

  for v_item in
    select li.id
    from public.loan_installments li
    join public.loans l on l.id=li.loan_id
    where li.due_date < current_date
      and li.paid_amount < li.total_due
      and l.status in ('active','overdue','defaulted')
      and not exists (
        select 1 from public.loan_penalties lp
        where lp.installment_id=li.id and lp.reversed_at is null
      )
    order by li.due_date asc
    limit 500
    for update of li skip locked
  loop
    perform private.process_one_overdue_installment_v3(v_item.id,null);
    v_count := v_count + 1;
  end loop;

  return jsonb_build_object('processed_installments',v_count,'processed_at',now());
end;
$$;

revoke all on function public.process_overdue_loan_installments_v3() from public, anon, authenticated;

/* -------------------------------------------------------------------------- */
/* 7. Serious default processing                                               */
/* -------------------------------------------------------------------------- */

create or replace function private.process_one_serious_default_v3(
  p_installment_id uuid,
  p_actor uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_li record;
  v_loan record;
  v_days integer;
  v_event_type text;
  v_created integer := 0;
begin
  select li.* into v_li
  from public.loan_installments li
  where li.id=p_installment_id
  for update;
  if not found then raise exception 'Installment not found'; end if;

  select * into v_loan from public.loans l where l.id=v_li.loan_id for update;
  if not found then raise exception 'Loan not found'; end if;

  if v_li.paid_amount >= v_li.total_due then
    return jsonb_build_object('processed',false,'reason','INSTALLMENT_PAID');
  end if;

  v_days := current_date - v_li.due_date;
  if v_days < coalesce(public.get_active_rule_numeric('serious_default_days'),60)::integer then
    return jsonb_build_object('processed',false,'reason','NOT_SERIOUS_DEFAULT','days_overdue',v_days);
  end if;

  if not exists (
    select 1 from public.loan_default_events e
    where e.loan_id=v_loan.id
      and e.installment_id=v_li.id
      and e.event_type='DEFAULT_NOTICE'
  ) then
    insert into public.loan_default_events(
      loan_id, installment_id, event_type, event_date, notes, created_by
    ) values (
      v_loan.id, v_li.id, 'DEFAULT_NOTICE', now(), 'Installment reached the serious-default threshold', p_actor
    );
    v_created := v_created + 1;
  end if;

  if v_li.status <> 'defaulted' then
    update public.loan_installments set status='defaulted', updated_at=now() where id=v_li.id;
  end if;

  update public.loans
  set status='defaulted', updated_at=now()
  where id=v_loan.id and status<>'paid';

  if not exists (
    select 1 from public.loan_default_events e
    where e.loan_id=v_loan.id and e.event_type='BORROWING_SUSPENDED'
  ) then
    insert into public.loan_default_events(
      loan_id, installment_id, event_type, event_date, notes, created_by
    ) values (
      v_loan.id, v_li.id, 'BORROWING_SUSPENDED', now(), 'Borrowing suspended because of serious default', p_actor
    );
    v_created := v_created + 1;
  end if;

  if v_loan.outsider_loan_application_id is not null then
    if not exists (
      select 1 from public.loan_default_events e
      where e.loan_id=v_loan.id and e.event_type='GUARANTOR_NOTICE'
    ) then
      insert into public.loan_default_events(
        loan_id, installment_id, event_type, event_date, notes, created_by
      ) values (
        v_loan.id, v_li.id, 'GUARANTOR_NOTICE', now(), 'Guarantor notification required for serious default', p_actor
      );
      v_created := v_created + 1;
    end if;
  elsif v_loan.loan_application_id is not null then
    if not exists (
      select 1 from public.loan_default_events e
      where e.loan_id=v_loan.id and e.event_type='GUARANTOR_NOTICE'
    ) then
      insert into public.loan_default_events(
        loan_id, installment_id, event_type, event_date, notes, created_by
      ) values (
        v_loan.id, v_li.id, 'GUARANTOR_NOTICE', now(), 'Guarantor notification required for serious default', p_actor
      );
      v_created := v_created + 1;
    end if;
  end if;

  perform private.loan_audit_v3(
    p_actor,
    'LOAN_SERIOUS_DEFAULT_DETECTED',
    'loan',
    v_loan.id,
    null,
    jsonb_build_object('installment_id',v_li.id,'days_overdue',v_days,'loan_status','defaulted'),
    '{}'::jsonb
  );

  return jsonb_build_object('processed',true,'loan_id',v_loan.id,'installment_id',v_li.id,'days_overdue',v_days,'events_created',v_created);
end;
$$;

revoke all on function private.process_one_serious_default_v3(uuid,uuid) from public, anon, authenticated;

create or replace function public.process_serious_default_v3(
  p_installment_id uuid,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('loan.review');
  v_idem jsonb;
  v_response jsonb;
begin
  if p_idempotency_key is not null then
    v_idem := private.loan_begin_idempotency_v3(v_actor,'PROCESS_SERIOUS_DEFAULT',p_idempotency_key,'loan_installment',p_installment_id);
    if coalesce((v_idem->>'replayed')::boolean,false) then return v_idem->'response'; end if;
  end if;

  perform private.loan_lock_financial_domain_v3('UNITY_FINANCE_LOAN_LIQUIDITY');
  v_response := private.process_one_serious_default_v3(p_installment_id,v_actor);

  if p_idempotency_key is not null then
    perform private.loan_finish_idempotency_v3(v_actor,'PROCESS_SERIOUS_DEFAULT',p_idempotency_key,v_response);
  end if;

  return v_response;
end;
$$;

revoke all on function public.process_serious_default_v3(uuid,text) from public, anon;
grant execute on function public.process_serious_default_v3(uuid,text) to authenticated;

create or replace function public.process_serious_loan_defaults_v3()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer := 0;
  v_item record;
begin
  perform private.loan_lock_financial_domain_v3('UNITY_FINANCE_LOAN_LIQUIDITY');

  for v_item in
    select li.id
    from public.loan_installments li
    join public.loans l on l.id=li.loan_id
    where li.paid_amount < li.total_due
      and l.status in ('active','overdue','defaulted')
      and current_date >= li.due_date + coalesce(public.get_active_rule_numeric('serious_default_days'),60)::integer
      and not exists (
        select 1 from public.loan_default_events e
        where e.loan_id=l.id and e.installment_id=li.id and e.event_type='DEFAULT_NOTICE'
      )
    order by li.due_date asc
    limit 500
    for update of li skip locked
  loop
    perform private.process_one_serious_default_v3(v_item.id,null);
    v_count := v_count + 1;
  end loop;

  return jsonb_build_object('processed_installments',v_count,'processed_at',now());
end;
$$;

revoke all on function public.process_serious_loan_defaults_v3() from public, anon, authenticated;

/* -------------------------------------------------------------------------- */
/* 8. Pre-disbursement cancellation                                            */
/* -------------------------------------------------------------------------- */

create or replace function public.cancel_loan_application_v3(
  p_borrower_type public.loan_borrower_type,
  p_application_id uuid,
  p_reason text,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('loan.review');
  v_idem jsonb;
  v_old jsonb;
  v_response jsonb;
  v_exists boolean;
begin
  if p_reason is null or length(trim(p_reason))<10 or length(trim(p_reason))>500 then
    raise exception 'Cancellation reason must contain 10 to 500 characters';
  end if;

  v_idem := private.loan_begin_idempotency_v3(v_actor,'CANCEL_LOAN_APPLICATION',p_idempotency_key,'loan_application',p_application_id);
  if coalesce((v_idem->>'replayed')::boolean,false) then return v_idem->'response'; end if;

  if p_borrower_type='member' then
    select exists(select 1 from public.loans l where l.loan_application_id=p_application_id) into v_exists;
    if v_exists then raise exception 'A disbursed loan cannot be cancelled. Use repayment or reversal workflows'; end if;

    select to_jsonb(la) into v_old from public.loan_applications la where la.id=p_application_id for update;
    if v_old is null then raise exception 'Loan application not found'; end if;
    if (v_old->>'status') not in ('submitted','eligible','ineligible','under_review','approved') then
      raise exception 'Application cannot be cancelled from its current state';
    end if;

    update public.loan_applications set status='cancelled', updated_at=now() where id=p_application_id;
    update public.member_loan_guarantors set status='released', responded_at=now(), updated_at=now() where loan_application_id=p_application_id and status in ('requested','accepted');
  else
    select exists(select 1 from public.loans l where l.outsider_loan_application_id=p_application_id) into v_exists;
    if v_exists then raise exception 'A disbursed loan cannot be cancelled. Use repayment or reversal workflows'; end if;

    select to_jsonb(oa) into v_old from public.outsider_loan_applications oa where oa.id=p_application_id for update;
    if v_old is null then raise exception 'Outsider loan application not found'; end if;
    if (v_old->>'status') not in ('submitted','eligible','ineligible','under_review','approved') then
      raise exception 'Application cannot be cancelled from its current state';
    end if;

    update public.outsider_loan_applications set status='cancelled', updated_at=now() where id=p_application_id;
    update public.outsider_loan_guarantors set status='released', responded_at=now(), updated_at=now() where outsider_loan_application_id=p_application_id and status in ('requested','accepted');
  end if;

  perform private.loan_audit_v3(v_actor,'LOAN_APPLICATION_CANCELLED',case when p_borrower_type='member' then 'loan_application' else 'outsider_loan_application' end,p_application_id,v_old,jsonb_build_object('status','cancelled'),jsonb_build_object('reason',trim(p_reason)));

  v_response := jsonb_build_object('application_id',p_application_id,'borrower_type',p_borrower_type,'status','cancelled');
  perform private.loan_finish_idempotency_v3(v_actor,'CANCEL_LOAN_APPLICATION',p_idempotency_key,v_response);
  return v_response;
end;
$$;

revoke all on function public.cancel_loan_application_v3(public.loan_borrower_type,uuid,text,text) from public, anon;
grant execute on function public.cancel_loan_application_v3(public.loan_borrower_type,uuid,text,text) to authenticated;

/* -------------------------------------------------------------------------- */
/* 9. Loan extension review                                                    */
/* -------------------------------------------------------------------------- */

create or replace function public.review_loan_extension_v3(
  p_extension_request_id uuid,
  p_decision public.approval_status,
  p_comment text,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('loan.review');
  v_idem jsonb;
  v_req record;
  v_response jsonb;
begin
  v_idem := private.loan_begin_idempotency_v3(v_actor,'REVIEW_LOAN_EXTENSION',p_idempotency_key,'loan_extension_request',p_extension_request_id);
  if coalesce((v_idem->>'replayed')::boolean,false) then return v_idem->'response'; end if;

  select x.*, l.status loan_status
  into v_req
  from public.loan_extension_requests x
  join public.loans l on l.id=x.loan_id
  where x.id=p_extension_request_id
  for update;

  if not found then raise exception 'Extension request not found'; end if;
  if v_req.status <> 'pending' then raise exception 'Extension request is no longer pending'; end if;
  if v_req.loan_status in ('paid','cancelled','defaulted') then raise exception 'Extension cannot be approved after loan termination or serious default'; end if;

  if exists (
    select 1
    from public.loan_installments li
    where li.loan_id=v_req.loan_id
      and li.paid_amount<li.total_due
      and current_date >= li.due_date + coalesce(public.get_active_rule_numeric('serious_default_days'),60)::integer
  ) then
    raise exception 'Extension cannot be approved after serious default';
  end if;

  if p_decision='approved' then
    update public.loan_extension_requests
    set status='approved', reviewed_by=v_actor, reviewed_at=now(), updated_at=now()
    where id=p_extension_request_id;
  elsif p_decision='rejected' then
    if p_comment is null or length(trim(p_comment))<10 then raise exception 'Rejection reason must contain at least 10 characters'; end if;
    update public.loan_extension_requests
    set status='rejected', reviewed_by=v_actor, reviewed_at=now(), updated_at=now()
    where id=p_extension_request_id;
  else
    raise exception 'Extension decision must be approved or rejected';
  end if;

  perform private.loan_audit_v3(v_actor,'LOAN_EXTENSION_REVIEWED','loan_extension_request',p_extension_request_id,null,jsonb_build_object('decision',p_decision::text,'comment',nullif(trim(p_comment),'')),jsonb_build_object('loan_id',v_req.loan_id));

  v_response := jsonb_build_object('extension_request_id',p_extension_request_id,'loan_id',v_req.loan_id,'status',case when p_decision='approved' then 'approved' else 'rejected' end,'schedule_changed',false);
  perform private.loan_finish_idempotency_v3(v_actor,'REVIEW_LOAN_EXTENSION',p_idempotency_key,v_response);
  return v_response;
end;
$$;

revoke all on function public.review_loan_extension_v3(uuid,public.approval_status,text,text) from public, anon;
grant execute on function public.review_loan_extension_v3(uuid,public.approval_status,text,text) to authenticated;

/* -------------------------------------------------------------------------- */
/* 10. Recovery operations                                                     */
/* -------------------------------------------------------------------------- */

create or replace function public.create_loan_recovery_event_v3(
  p_loan_id uuid,
  p_source_type text,
  p_source_id uuid,
  p_amount numeric,
  p_reason text,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('loan.review');
  v_idem jsonb;
  v_loan record;
  v_event_id uuid;
  v_response jsonb;
begin
  v_idem := private.loan_begin_idempotency_v3(v_actor,'CREATE_LOAN_RECOVERY_EVENT',p_idempotency_key,'loan',p_loan_id);
  if coalesce((v_idem->>'replayed')::boolean,false) then return v_idem->'response'; end if;

  select * into v_loan from public.loans where id=p_loan_id for update;
  if not found then raise exception 'Loan not found'; end if;
  if p_source_type not in ('savings_security','guarantor','other_approved') then raise exception 'Invalid recovery source type'; end if;
  if p_amount is null or p_amount<=0 then raise exception 'Recovery amount must be greater than zero'; end if;
  if p_reason is null or length(trim(p_reason))<10 then raise exception 'Recovery reason must contain at least 10 characters'; end if;

  insert into public.loan_recovery_events(
    loan_id, source_type, source_id, amount, reason, status, approved_by
  ) values (
    p_loan_id, lower(trim(p_source_type)), p_source_id, round(p_amount,2), trim(p_reason), 'approved', v_actor
  ) returning id into v_event_id;

  insert into public.loan_default_events(loan_id,event_type,event_date,notes,created_by)
  values (v_loan.id, case when lower(trim(p_source_type))='savings_security' then 'SECURITY_RECOVERY_STARTED' when lower(trim(p_source_type))='guarantor' then 'GUARANTOR_RECOVERY_STARTED' else 'SECURITY_RECOVERY_STARTED' end, now(), trim(p_reason), v_actor);

  perform private.loan_audit_v3(v_actor,'LOAN_RECOVERY_ACTION_APPROVED','loan',p_loan_id,null,jsonb_build_object('recovery_event_id',v_event_id,'source_type',p_source_type,'amount',round(p_amount,2)),jsonb_build_object('reason',trim(p_reason)));

  v_response := jsonb_build_object('recovery_event_id',v_event_id,'loan_id',p_loan_id,'status','approved');
  perform private.loan_finish_idempotency_v3(v_actor,'CREATE_LOAN_RECOVERY_EVENT',p_idempotency_key,v_response);
  return v_response;
end;
$$;

revoke all on function public.create_loan_recovery_event_v3(uuid,text,uuid,numeric,text,text) from public, anon;
grant execute on function public.create_loan_recovery_event_v3(uuid,text,uuid,numeric,text,text) to authenticated;

create or replace function public.complete_loan_recovery_event_v3(
  p_recovery_event_id uuid,
  p_transaction_id uuid,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('loan.review');
  v_idem jsonb;
  v_event record;
  v_tx record;
  v_response jsonb;
begin
  v_idem := private.loan_begin_idempotency_v3(v_actor,'COMPLETE_LOAN_RECOVERY',p_idempotency_key,'loan_recovery_event',p_recovery_event_id);
  if coalesce((v_idem->>'replayed')::boolean,false) then return v_idem->'response'; end if;

  select * into v_event from public.loan_recovery_events where id=p_recovery_event_id for update;
  if not found then raise exception 'Recovery event not found'; end if;
  if v_event.status <> 'approved' then raise exception 'Only approved recovery events can be completed'; end if;

  select * into v_tx from public.transactions where id=p_transaction_id;
  if not found then raise exception 'Recovery transaction not found'; end if;
  if v_tx.transaction_status <> 'posted' then raise exception 'Recovery transaction must be posted'; end if;
  if v_tx.amount <> v_event.amount then raise exception 'Recovery transaction amount does not match approved recovery amount'; end if;
  if v_tx.source_type is distinct from 'loan_recovery_event'
     or v_tx.source_id is distinct from p_recovery_event_id then
    raise exception 'Recovery transaction is not bound to this recovery event';
  end if;

  update public.loan_recovery_events
  set status='completed', transaction_id=p_transaction_id, completed_at=now()
  where id=p_recovery_event_id;

  insert into public.loan_default_events(
    loan_id, event_type, event_date, notes, created_by
  ) values (
    v_event.loan_id, 'RECOVERY_COMPLETED', now(), 'Approved recovery event completed', v_actor
  );

  perform private.loan_audit_v3(v_actor,'LOAN_RECOVERY_COMPLETED','loan',v_event.loan_id,null,jsonb_build_object('recovery_event_id',p_recovery_event_id,'transaction_id',p_transaction_id,'amount',v_event.amount),'{}'::jsonb);

  v_response := jsonb_build_object('recovery_event_id',p_recovery_event_id,'loan_id',v_event.loan_id,'status','completed');
  perform private.loan_finish_idempotency_v3(v_actor,'COMPLETE_LOAN_RECOVERY',p_idempotency_key,v_response);
  return v_response;
end;
$$;

revoke all on function public.complete_loan_recovery_event_v3(uuid,uuid,text) from public, anon;
grant execute on function public.complete_loan_recovery_event_v3(uuid,uuid,text) to authenticated;

/* -------------------------------------------------------------------------- */
/* 11. Guarantor replacement                                                   */
/* -------------------------------------------------------------------------- */

create or replace function public.request_loan_guarantor_replacement_v3(
  p_loan_id uuid,
  p_new_guarantor_member_id uuid,
  p_reason text,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('loan.review');
  v_idem jsonb;
  v_loan record;
  v_old_guarantor uuid;
  v_borrower_type public.loan_borrower_type;
  v_new_guarantor_active boolean;
  v_request_id uuid;
  v_response jsonb;
begin
  v_idem := private.loan_begin_idempotency_v3(v_actor,'REQUEST_GUARANTOR_REPLACEMENT',p_idempotency_key,'loan',p_loan_id);
  if coalesce((v_idem->>'replayed')::boolean,false) then return v_idem->'response'; end if;

  select * into v_loan from public.loans where id=p_loan_id for update;
  if not found then raise exception 'Loan not found'; end if;
  if v_loan.status in ('paid','cancelled') then raise exception 'Guarantor replacement is not available for this loan'; end if;
  if p_reason is null or length(trim(p_reason))<10 then raise exception 'Replacement reason must contain at least 10 characters'; end if;

  select exists(select 1 from public.members m where m.id=p_new_guarantor_member_id and m.status='active') into v_new_guarantor_active;
  if not v_new_guarantor_active then raise exception 'Replacement guarantor must be an active member'; end if;

  if v_loan.outsider_loan_application_id is not null then
    v_borrower_type := 'outsider';
    select guarantor_member_id into v_old_guarantor from public.outsider_loan_guarantors where outsider_loan_application_id=v_loan.outsider_loan_application_id and status='accepted' for update;
  else
    v_borrower_type := 'member';
    select guarantor_member_id into v_old_guarantor from public.member_loan_guarantors where loan_application_id=v_loan.loan_application_id and status='accepted' for update;
  end if;

  if v_old_guarantor is null then raise exception 'Current accepted guarantor not found'; end if;
  if v_old_guarantor=p_new_guarantor_member_id then raise exception 'Replacement guarantor must be different from current guarantor'; end if;

  if v_borrower_type='outsider' and private.outsider_guarantor_max_loan_v2(p_new_guarantor_member_id) < v_loan.principal then
    raise exception 'Replacement guarantor savings no longer support the outstanding loan principal';
  end if;

  if v_borrower_type='outsider' and exists (
    select 1 from public.outsider_loan_guarantors g
    join public.outsider_loan_applications oa on oa.id=g.outsider_loan_application_id
    left join public.loans l on l.outsider_loan_application_id=oa.id
    where g.guarantor_member_id=p_new_guarantor_member_id
      and g.status in ('requested','accepted')
      and l.id is null
  ) then
    raise exception 'Replacement guarantor already has an outstanding outsider guarantee';
  end if;

  insert into public.loan_guarantor_replacement_requests(
    loan_id, old_guarantor_member_id, new_guarantor_member_id, borrower_type, reason, requested_by
  ) values (
    p_loan_id, v_old_guarantor, p_new_guarantor_member_id, v_borrower_type, trim(p_reason), v_actor
  ) returning id into v_request_id;

  perform private.loan_audit_v3(v_actor,'LOAN_GUARANTOR_REPLACEMENT_REQUESTED','loan',p_loan_id,null,jsonb_build_object('replacement_request_id',v_request_id,'old_guarantor_member_id',v_old_guarantor,'new_guarantor_member_id',p_new_guarantor_member_id),jsonb_build_object('reason',trim(p_reason)));

  v_response := jsonb_build_object('replacement_request_id',v_request_id,'loan_id',p_loan_id,'status','pending');
  perform private.loan_finish_idempotency_v3(v_actor,'REQUEST_GUARANTOR_REPLACEMENT',p_idempotency_key,v_response);
  return v_response;
end;
$$;

revoke all on function public.request_loan_guarantor_replacement_v3(uuid,uuid,text,text) from public, anon;
grant execute on function public.request_loan_guarantor_replacement_v3(uuid,uuid,text,text) to authenticated;

create or replace function public.respond_to_loan_guarantor_replacement_v3(
  p_replacement_request_id uuid,
  p_accept boolean,
  p_reason text default null,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('guarantor.respond');
  v_idem jsonb;
  v_req record;
  v_new_profile uuid;
  v_response jsonb;
begin
  if p_idempotency_key is null then raise exception 'Idempotency key is required'; end if;
  v_idem := private.loan_begin_idempotency_v3(v_actor,'RESPOND_GUARANTOR_REPLACEMENT',p_idempotency_key,'loan_guarantor_replacement_request',p_replacement_request_id);
  if coalesce((v_idem->>'replayed')::boolean,false) then return v_idem->'response'; end if;

  select r.*, m.profile_id new_guarantor_profile_id
  into v_req
  from public.loan_guarantor_replacement_requests r
  join public.members m on m.id=r.new_guarantor_member_id
  where r.id=p_replacement_request_id
  for update;
  if not found then raise exception 'Guarantor replacement request not found'; end if;
  if v_req.status <> 'pending' then raise exception 'Replacement request is no longer pending'; end if;
  v_new_profile := v_req.new_guarantor_profile_id;
  if v_new_profile <> v_actor then raise exception 'Only the proposed replacement guarantor may respond'; end if;

  if not p_accept then
    if p_reason is null or length(trim(p_reason))<5 then raise exception 'Rejection reason is required'; end if;
    update public.loan_guarantor_replacement_requests
    set status='rejected', responded_by=v_actor, responded_at=now(), updated_at=now()
    where id=p_replacement_request_id;

    perform private.loan_audit_v3(v_actor,'LOAN_GUARANTOR_REPLACEMENT_REJECTED','loan',v_req.loan_id,null,jsonb_build_object('replacement_request_id',p_replacement_request_id,'reason',trim(p_reason)),'{}'::jsonb);
    v_response := jsonb_build_object('replacement_request_id',p_replacement_request_id,'status','rejected');
    perform private.loan_finish_idempotency_v3(v_actor,'RESPOND_GUARANTOR_REPLACEMENT',p_idempotency_key,v_response);
    return v_response;
  end if;

  if not exists(select 1 from public.members m where m.id=v_req.new_guarantor_member_id and m.status='active') then
    raise exception 'Replacement guarantor is no longer active';
  end if;

  update public.loan_guarantor_replacement_requests
  set status='accepted', responded_by=v_actor, responded_at=now(), updated_at=now()
  where id=p_replacement_request_id;

  if v_req.borrower_type='outsider' then
    update public.outsider_loan_guarantors g
    set guarantor_member_id=v_req.new_guarantor_member_id, updated_at=now()
    where g.outsider_loan_application_id=(select l.outsider_loan_application_id from public.loans l where l.id=v_req.loan_id)
      and g.status='accepted';
  else
    update public.member_loan_guarantors g
    set guarantor_member_id=v_req.new_guarantor_member_id, updated_at=now()
    where g.loan_application_id=(select l.loan_application_id from public.loans l where l.id=v_req.loan_id)
      and g.status='accepted';
  end if;

  perform private.loan_audit_v3(v_actor,'LOAN_GUARANTOR_REPLACED','loan',v_req.loan_id,null,jsonb_build_object('replacement_request_id',p_replacement_request_id,'new_guarantor_member_id',v_req.new_guarantor_member_id),'{}'::jsonb);

  v_response := jsonb_build_object('replacement_request_id',p_replacement_request_id,'status','accepted','loan_id',v_req.loan_id,'new_guarantor_member_id',v_req.new_guarantor_member_id);
  perform private.loan_finish_idempotency_v3(v_actor,'RESPOND_GUARANTOR_REPLACEMENT',p_idempotency_key,v_response);
  return v_response;
end;
$$;

revoke all on function public.respond_to_loan_guarantor_replacement_v3(uuid,boolean,text,text) from public, anon;
grant execute on function public.respond_to_loan_guarantor_replacement_v3(uuid,boolean,text,text) to authenticated;

/* -------------------------------------------------------------------------- */
/* 12. Conflict-of-interest controls                                           */
/* -------------------------------------------------------------------------- */

create or replace function public.declare_loan_conflict_v3(
  p_loan_id uuid default null,
  p_application_id uuid default null,
  p_outsider_application_id uuid default null,
  p_conflict_type text default null,
  p_description text default null,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_idem jsonb;
  v_id uuid;
  v_response jsonb;
begin
  if v_actor is null then raise exception 'Not authenticated'; end if;
  if p_conflict_type is null or length(trim(p_conflict_type))<3 then raise exception 'Conflict type is required'; end if;
  if p_description is null or length(trim(p_description))<10 then raise exception 'Conflict description must contain at least 10 characters'; end if;
  if p_loan_id is null and p_application_id is null and p_outsider_application_id is null then raise exception 'A loan or application target is required'; end if;

  if p_idempotency_key is not null then
    v_idem := private.loan_begin_idempotency_v3(v_actor,'DECLARE_LOAN_CONFLICT',p_idempotency_key,'loan',p_loan_id);
    if coalesce((v_idem->>'replayed')::boolean,false) then return v_idem->'response'; end if;
  end if;

  insert into public.loan_conflict_declarations(
    loan_id, application_id, outsider_application_id, actor_profile_id, conflict_type, description
  ) values (
    p_loan_id, p_application_id, p_outsider_application_id, v_actor, upper(trim(p_conflict_type)), trim(p_description)
  ) returning id into v_id;

  perform private.loan_audit_v3(v_actor,'LOAN_CONFLICT_DECLARED','loan',p_loan_id,null,jsonb_build_object('conflict_id',v_id,'conflict_type',upper(trim(p_conflict_type)),'description',trim(p_description)),jsonb_build_object('application_id',p_application_id,'outsider_application_id',p_outsider_application_id));

  v_response := jsonb_build_object('conflict_id',v_id,'status','declared');
  if p_idempotency_key is not null then perform private.loan_finish_idempotency_v3(v_actor,'DECLARE_LOAN_CONFLICT',p_idempotency_key,v_response); end if;
  return v_response;
end;
$$;

revoke all on function public.declare_loan_conflict_v3(uuid,uuid,uuid,text,text,text) from public, anon;
grant execute on function public.declare_loan_conflict_v3(uuid,uuid,uuid,text,text,text) to authenticated;

create or replace function public.resolve_loan_conflict_v3(
  p_conflict_id uuid,
  p_resolution text,
  p_dismiss boolean,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('loan.review');
  v_idem jsonb;
  v_conflict record;
  v_status text;
  v_response jsonb;
begin
  v_idem := private.loan_begin_idempotency_v3(v_actor,'RESOLVE_LOAN_CONFLICT',p_idempotency_key,'loan_conflict_declaration',p_conflict_id);
  if coalesce((v_idem->>'replayed')::boolean,false) then return v_idem->'response'; end if;

  select * into v_conflict from public.loan_conflict_declarations where id=p_conflict_id for update;
  if not found then raise exception 'Conflict declaration not found'; end if;
  if v_conflict.status <> 'declared' then raise exception 'Conflict declaration is already resolved'; end if;
  if v_conflict.actor_profile_id = v_actor then raise exception 'A person cannot resolve their own conflict declaration'; end if;
  if p_resolution is null or length(trim(p_resolution))<10 then raise exception 'Resolution note must contain at least 10 characters'; end if;

  v_status := case when p_dismiss then 'dismissed' else 'resolved' end;

  update public.loan_conflict_declarations
  set status=v_status, resolved_by=v_actor, resolved_at=now()
  where id=p_conflict_id;

  perform private.loan_audit_v3(v_actor,'LOAN_CONFLICT_RESOLVED','loan',v_conflict.loan_id,null,jsonb_build_object('conflict_id',p_conflict_id,'status',v_status,'resolution',trim(p_resolution)),'{}'::jsonb);

  v_response := jsonb_build_object('conflict_id',p_conflict_id,'status',v_status);
  perform private.loan_finish_idempotency_v3(v_actor,'RESOLVE_LOAN_CONFLICT',p_idempotency_key,v_response);
  return v_response;
end;
$$;

revoke all on function public.resolve_loan_conflict_v3(uuid,text,boolean,text) from public, anon;
grant execute on function public.resolve_loan_conflict_v3(uuid,text,boolean,text) to authenticated;

/* -------------------------------------------------------------------------- */
/* 13. Financial reversal                                                      */
/* -------------------------------------------------------------------------- */

create or replace function public.reverse_loan_financial_transaction_v3(
  p_original_transaction_id uuid,
  p_reason text,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('ledger.reverse');
  v_idem jsonb;
  v_original record;
  v_loan record;
  v_installment record;
  v_entry record;
  v_reversal_id uuid;
  v_reversal_tx uuid;
  v_total numeric(18,2);
  v_base numeric(18,2) := 0;
  v_penalty numeric(18,2) := 0;
  v_was_paid boolean := false;
  v_response jsonb;
begin
  if p_reason is null or length(trim(p_reason))<10 or length(trim(p_reason))>1000 then
    raise exception 'Reversal reason must contain 10 to 1000 characters';
  end if;

  v_idem := private.loan_begin_idempotency_v3(v_actor,'REVERSE_LOAN_TRANSACTION',p_idempotency_key,'transaction',p_original_transaction_id);
  if coalesce((v_idem->>'replayed')::boolean,false) then return v_idem->'response'; end if;

  perform private.loan_lock_financial_domain_v3('UNITY_FINANCE_LOAN_LIQUIDITY');

  select * into v_original
  from public.transactions
  where id=p_original_transaction_id
  for update;
  if not found then raise exception 'Original transaction not found'; end if;
  if v_original.transaction_status <> 'posted' then raise exception 'Only posted transactions can be reversed'; end if;
  if v_original.reversal_of_transaction_id is not null then raise exception 'A reversal transaction cannot itself be reversed'; end if;
  if exists(select 1 from public.loan_financial_reversals r where r.original_transaction_id=p_original_transaction_id) then
    raise exception 'This transaction already has a financial reversal';
  end if;
  if v_original.transaction_type not in ('loan_repayment','loan_late_penalty') then
    raise exception 'This RPC only reverses posted loan repayment or late-penalty transactions. Loan disbursement reversal requires a separate approved financial workflow';
  end if;

  if v_original.transaction_type='loan_repayment' then
    select l.* into v_loan
    from public.loans l
    left join public.loan_repayment_submissions rs on rs.loan_id=l.id and rs.posted_transaction_id=v_original.id
    where l.id=v_original.source_id or rs.id is not null
    limit 1
    for update;

    if v_loan.id is null then raise exception 'Loan for repayment transaction could not be resolved'; end if;
  else
    select l.* into v_loan
    from public.loan_installments li
    join public.loans l on l.id=li.loan_id
    where li.id=v_original.source_id
    for update;
    if not found then raise exception 'Loan for penalty transaction could not be resolved'; end if;
  end if;

  v_was_paid := v_loan.status='paid';

  insert into public.loan_financial_reversals(
    loan_id,
    original_transaction_id,
    requested_by,
    approved_by,
    reason,
    status
  ) values (
    v_loan.id,
    p_original_transaction_id,
    v_actor,
    v_actor,
    trim(p_reason),
    'approved'
  ) returning id into v_reversal_id;

  insert into public.transactions(
    transaction_type,
    source_type,
    source_id,
    profile_id,
    member_id,
    amount,
    currency,
    approval_status,
    transaction_status,
    initiated_by,
    approved_by,
    approved_at,
    description,
    reversal_of_transaction_id
  ) values (
    'reversal',
    'loan_financial_reversal',
    v_reversal_id,
    v_loan.borrower_profile_id,
    v_loan.member_id,
    v_original.amount,
    'ETB',
    'approved',
    'posted',
    v_actor,
    v_actor,
    now(),
    'Reversal of transaction '||v_original.reference_number||': '||trim(p_reason),
    v_original.id
  ) returning id into v_reversal_tx;

  insert into public.transaction_entries(transaction_id,account_id,entry_type,amount)
  select
    v_reversal_tx,
    te.account_id,
    case when te.entry_type='debit' then 'credit'::public.transaction_entry_type else 'debit'::public.transaction_entry_type end,
    te.amount
  from public.transaction_entries te
  where te.transaction_id=v_original.id;

  if not exists(select 1 from public.transaction_entries where transaction_id=v_reversal_tx) then
    raise exception 'Original transaction has no ledger entries';
  end if;

  update public.transactions
  set transaction_status='reversed'
  where id=v_original.id;

  if v_original.transaction_type='loan_repayment' then
    for v_entry in
      select a.*
      from public.loan_repayment_allocations a
      where a.transaction_id=v_original.id and a.reversed_at is null
      for update
    loop
      select * into v_installment from public.loan_installments li where li.id=v_entry.installment_id for update;

      v_base := v_base + v_entry.allocated_base_amount;
      v_penalty := v_penalty + v_entry.allocated_penalty_amount;

      update public.loan_installments
      set
        paid_amount=greatest(round(paid_amount-v_entry.allocated_base_amount,2),0),
        paid_penalty_amount=greatest(round(paid_penalty_amount-v_entry.allocated_penalty_amount,2),0),
        status=case
          when greatest(round(paid_amount-v_entry.allocated_base_amount,2),0) >= total_due
           and greatest(round(paid_penalty_amount-v_entry.allocated_penalty_amount,2),0) >= late_penalty_amount
            then 'paid'::public.installment_status
          when due_date < current_date then 'overdue'::public.installment_status
          else 'pending'::public.installment_status
        end,
        updated_at=now()
      where id=v_entry.installment_id;

      update public.loan_repayment_allocations
      set reversed_at=now(), reversal_transaction_id=v_reversal_tx
      where id=v_entry.id;
    end loop;

    update public.loan_repayment_submissions
    set reversed_at=now(), reversal_transaction_id=v_reversal_tx, updated_at=now()
    where posted_transaction_id=v_original.id;
  else
    select * into v_installment from public.loan_installments li where li.id=v_original.source_id for update;
    if not found then raise exception 'Penalty installment not found'; end if;
    if v_installment.paid_penalty_amount > 0 then
      raise exception 'A late penalty that has already been paid cannot be reversed by this command';
    end if;

    update public.loan_penalties
    set reversed_at=now(), reversal_transaction_id=v_reversal_tx
    where installment_id=v_installment.id
      and transaction_id=v_original.id
      and reversed_at is null;

    if not found then raise exception 'Active late penalty record not found'; end if;

    update public.loan_installments
    set late_penalty_amount=0,
        status=case when paid_amount>=total_due then 'paid'::public.installment_status when due_date<current_date then 'overdue'::public.installment_status else 'pending'::public.installment_status end,
        updated_at=now()
    where id=v_installment.id;
  end if;

  /* Reversal may reopen a previously paid loan. Reinstate the existing
     guarantor only when the original guarantor still satisfies current safety
     rules. Otherwise the financial correction is blocked before posting. */
  if v_was_paid then
    if v_loan.outsider_loan_application_id is not null then
      if not exists (
        select 1
        from public.outsider_loan_guarantors g
        join public.members m on m.id=g.guarantor_member_id
        where g.outsider_loan_application_id=v_loan.outsider_loan_application_id
          and g.status='released'
          and m.status='active'
          and not exists (
            select 1 from public.outsider_loan_guarantors other
            where other.guarantor_member_id=g.guarantor_member_id
              and other.status in ('requested','accepted')
              and other.outsider_loan_application_id<>g.outsider_loan_application_id
          )
      ) then
        raise exception 'Paid loan reversal would reopen guarantor responsibility, but the original outsider guarantor is no longer safely restorable';
      end if;

      update public.outsider_loan_guarantors
      set status='accepted', responded_at=coalesce(responded_at,now()), updated_at=now()
      where outsider_loan_application_id=v_loan.outsider_loan_application_id and status='released';
    elsif v_loan.loan_application_id is not null then
      update public.member_loan_guarantors
      set status='accepted', updated_at=now()
      where loan_application_id=v_loan.loan_application_id and status='released';
    end if;
  end if;

  if exists(select 1 from public.loan_installments li where li.loan_id=v_loan.id and li.status='defaulted') then
    update public.loans set status='defaulted',updated_at=now() where id=v_loan.id;
  elsif not exists(select 1 from public.loan_installments li where li.loan_id=v_loan.id and (li.paid_amount<li.total_due or li.paid_penalty_amount<li.late_penalty_amount)) then
    update public.loans set status='paid',updated_at=now() where id=v_loan.id;
  elsif exists(select 1 from public.loan_installments li where li.loan_id=v_loan.id and li.due_date<current_date and li.paid_amount<li.total_due) then
    update public.loans set status='overdue',updated_at=now() where id=v_loan.id;
  else
    update public.loans set status='active',updated_at=now() where id=v_loan.id;
  end if;

  update public.loan_financial_reversals
  set status='posted', reversal_transaction_id=v_reversal_tx, posted_at=now()
  where id=v_reversal_id;

  perform private.loan_audit_v3(v_actor,'LOAN_FINANCIAL_REVERSAL_POSTED','loan',v_loan.id,null,jsonb_build_object('reversal_id',v_reversal_id,'original_transaction_id',p_original_transaction_id,'reversal_transaction_id',v_reversal_tx,'amount',v_original.amount),jsonb_build_object('reason',trim(p_reason)));

  v_response := jsonb_build_object('reversal_id',v_reversal_id,'loan_id',v_loan.id,'original_transaction_id',p_original_transaction_id,'reversal_transaction_id',v_reversal_tx,'status','posted');
  perform private.loan_finish_idempotency_v3(v_actor,'REVERSE_LOAN_TRANSACTION',p_idempotency_key,v_response);
  return v_response;
end;
$$;

revoke all on function public.reverse_loan_financial_transaction_v3(uuid,text,text) from public, anon;
grant execute on function public.reverse_loan_financial_transaction_v3(uuid,text,text) to authenticated;

/* -------------------------------------------------------------------------- */
/* 14. Operational read RPCs                                                   */
/* -------------------------------------------------------------------------- */

create or replace function public.list_admin_loan_repayments_v3(
  p_status text default null,
  p_search text default null,
  p_limit integer default 25,
  p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('loan.read');
  v_limit integer := least(greatest(coalesce(p_limit,25),1),100);
  v_offset integer := greatest(coalesce(p_offset,0),0);
  v_rows jsonb;
  v_total bigint;
begin
  with q as (
    select
      rs.id submission_id,
      rs.loan_id,
      l.loan_number,
      rs.amount,
      rs.payment_method_code,
      rs.external_reference,
      rs.status,
      rs.borrower_type,
      coalesce(p.full_name, oa.applicant_full_name) payer_name,
      rs.payer_phone,
      rs.submitted_at,
      rs.verified_at,
      rs.posted_transaction_id,
      rs.reversed_at
    from public.loan_repayment_submissions rs
    join public.loans l on l.id=rs.loan_id
    left join public.profiles p on p.id=rs.payer_profile_id
    left join public.outsider_loan_applications oa on oa.id=l.outsider_loan_application_id
    where (p_status is null or rs.status=p_status)
      and (p_search is null or trim(p_search)='' or l.loan_number ilike '%'||trim(p_search)||'%' or rs.external_reference ilike '%'||trim(p_search)||'%' or p.full_name ilike '%'||trim(p_search)||'%' or oa.applicant_full_name ilike '%'||trim(p_search)||'%')
  )
  select count(*) into v_total from q;
  select coalesce(jsonb_agg(to_jsonb(x) order by x.submitted_at desc), '[]'::jsonb)
  into v_rows from (select * from q order by submitted_at desc limit v_limit offset v_offset) x;
  return jsonb_build_object('rows',v_rows,'total',v_total,'limit',v_limit,'offset',v_offset,'actor',v_actor);
end;
$$;

revoke all on function public.list_admin_loan_repayments_v3(text,text,integer,integer) from public, anon;
grant execute on function public.list_admin_loan_repayments_v3(text,text,integer,integer) to authenticated;

create or replace function public.list_admin_overdue_loans_v3(
  p_min_days integer default null,
  p_limit integer default 25,
  p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('loan.read');
  v_limit integer := least(greatest(coalesce(p_limit,25),1),100);
  v_offset integer := greatest(coalesce(p_offset,0),0);
  v_rows jsonb;
  v_total bigint;
begin
  with q as (
    select
      l.id loan_id,
      l.loan_number,
      case when l.outsider_loan_application_id is null then 'member' else 'outsider' end borrower_type,
      coalesce(p.full_name,oa.applicant_full_name) borrower_name,
      li.id installment_id,
      li.installment_number,
      li.due_date,
      greatest(current_date-li.due_date,0) days_overdue,
      li.total_due,
      li.paid_amount,
      li.late_penalty_amount,
      li.paid_penalty_amount,
      li.status
    from public.loan_installments li
    join public.loans l on l.id=li.loan_id
    left join public.profiles p on p.id=l.borrower_profile_id
    left join public.outsider_loan_applications oa on oa.id=l.outsider_loan_application_id
    where li.paid_amount < li.total_due
      and li.due_date < current_date
      and (p_min_days is null or current_date-li.due_date >= p_min_days)
      and l.status in ('active','overdue','defaulted')
  )
  select count(*) into v_total from q;
  select coalesce(jsonb_agg(to_jsonb(x) order by x.due_date asc), '[]'::jsonb)
  into v_rows from (select * from q order by due_date asc limit v_limit offset v_offset) x;
  return jsonb_build_object('rows',v_rows,'total',v_total,'limit',v_limit,'offset',v_offset,'actor',v_actor);
end;
$$;

revoke all on function public.list_admin_overdue_loans_v3(integer,integer,integer) from public, anon;
grant execute on function public.list_admin_overdue_loans_v3(integer,integer,integer) to authenticated;

create or replace function public.list_admin_default_cases_v3(
  p_limit integer default 25,
  p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('loan.read');
  v_limit integer := least(greatest(coalesce(p_limit,25),1),100);
  v_offset integer := greatest(coalesce(p_offset,0),0);
  v_rows jsonb;
  v_total bigint;
begin
  with q as (
    select
      l.id loan_id,
      l.loan_number,
      case when l.outsider_loan_application_id is null then 'member' else 'outsider' end borrower_type,
      coalesce(p.full_name,oa.applicant_full_name) borrower_name,
      l.status,
      min(li.due_date) filter (where li.paid_amount<li.total_due and current_date-li.due_date>=coalesce(public.get_active_rule_numeric('serious_default_days'),60)::integer) first_serious_due_date,
      max(current_date-li.due_date) filter (where li.paid_amount<li.total_due) max_days_overdue,
      count(li.id) filter (where li.status='defaulted') defaulted_installments,
      coalesce((select sum(e.amount) from public.loan_recovery_events e where e.loan_id=l.id and e.status='completed'),0)::numeric(18,2) recovered_amount
    from public.loans l
    left join public.profiles p on p.id=l.borrower_profile_id
    left join public.outsider_loan_applications oa on oa.id=l.outsider_loan_application_id
    left join public.loan_installments li on li.loan_id=l.id
    where l.status='defaulted'
    group by l.id,l.loan_number,l.status,p.full_name,oa.applicant_full_name,l.outsider_loan_application_id
  )
  select count(*) into v_total from q;
  select coalesce(jsonb_agg(to_jsonb(x) order by x.max_days_overdue desc nulls last), '[]'::jsonb)
  into v_rows from (select * from q order by max_days_overdue desc nulls last limit v_limit offset v_offset) x;
  return jsonb_build_object('rows',v_rows,'total',v_total,'limit',v_limit,'offset',v_offset,'actor',v_actor);
end;
$$;

revoke all on function public.list_admin_default_cases_v3(integer,integer) from public, anon;
grant execute on function public.list_admin_default_cases_v3(integer,integer) to authenticated;

create or replace function public.list_admin_recovery_events_v3(
  p_status text default null,
  p_limit integer default 25,
  p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('loan.read');
  v_limit integer := least(greatest(coalesce(p_limit,25),1),100);
  v_offset integer := greatest(coalesce(p_offset,0),0);
  v_rows jsonb;
  v_total bigint;
begin
  with q as (
    select e.*, l.loan_number,
           coalesce(p.full_name,oa.applicant_full_name) borrower_name
    from public.loan_recovery_events e
    join public.loans l on l.id=e.loan_id
    left join public.profiles p on p.id=l.borrower_profile_id
    left join public.outsider_loan_applications oa on oa.id=l.outsider_loan_application_id
    where p_status is null or e.status=p_status
  )
  select count(*) into v_total from q;
  select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb)
  into v_rows from (select * from q order by created_at desc limit v_limit offset v_offset) x;
  return jsonb_build_object('rows',v_rows,'total',v_total,'limit',v_limit,'offset',v_offset,'actor',v_actor);
end;
$$;

revoke all on function public.list_admin_recovery_events_v3(text,integer,integer) from public, anon;
grant execute on function public.list_admin_recovery_events_v3(text,integer,integer) to authenticated;

create or replace function public.list_admin_loan_extensions_v3(
  p_status text default null,
  p_limit integer default 25,
  p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('loan.read');
  v_limit integer := least(greatest(coalesce(p_limit,25),1),100);
  v_offset integer := greatest(coalesce(p_offset,0),0);
  v_rows jsonb;
  v_total bigint;
begin
  with q as (
    select x.*,l.loan_number,l.status loan_status,p.full_name requester_name
    from public.loan_extension_requests x
    join public.loans l on l.id=x.loan_id
    left join public.profiles p on p.id=x.requested_by
    where p_status is null or x.status=p_status
  )
  select count(*) into v_total from q;
  select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb)
  into v_rows from (select * from q order by created_at desc limit v_limit offset v_offset) x;
  return jsonb_build_object('rows',v_rows,'total',v_total,'limit',v_limit,'offset',v_offset,'actor',v_actor);
end;
$$;

revoke all on function public.list_admin_loan_extensions_v3(text,integer,integer) from public, anon;
grant execute on function public.list_admin_loan_extensions_v3(text,integer,integer) to authenticated;

create or replace function public.list_admin_guarantor_replacements_v3(
  p_status text default 'pending',
  p_limit integer default 25,
  p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('loan.read');
  v_limit integer := least(greatest(coalesce(p_limit,25),1),100);
  v_offset integer := greatest(coalesce(p_offset,0),0);
  v_rows jsonb;
  v_total bigint;
begin
  with q as (
    select r.*,l.loan_number,
           old_m.member_number old_guarantor_member_number,
           old_p.full_name old_guarantor_name,
           new_m.member_number new_guarantor_member_number,
           new_p.full_name new_guarantor_name
    from public.loan_guarantor_replacement_requests r
    join public.loans l on l.id=r.loan_id
    join public.members old_m on old_m.id=r.old_guarantor_member_id
    join public.profiles old_p on old_p.id=old_m.profile_id
    join public.members new_m on new_m.id=r.new_guarantor_member_id
    join public.profiles new_p on new_p.id=new_m.profile_id
    where p_status is null or r.status=p_status
  )
  select count(*) into v_total from q;
  select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb)
  into v_rows from (select * from q order by created_at desc limit v_limit offset v_offset) x;
  return jsonb_build_object('rows',v_rows,'total',v_total,'limit',v_limit,'offset',v_offset,'actor',v_actor);
end;
$$;

revoke all on function public.list_admin_guarantor_replacements_v3(text,integer,integer) from public, anon;
grant execute on function public.list_admin_guarantor_replacements_v3(text,integer,integer) to authenticated;

create or replace function public.list_admin_loan_transactions_v3(
  p_transaction_type public.transaction_type default null,
  p_status public.transaction_status default null,
  p_search text default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('ledger.read');
  v_limit integer := least(greatest(coalesce(p_limit,50),1),100);
  v_offset integer := greatest(coalesce(p_offset,0),0);
  v_rows jsonb;
  v_total bigint;
begin
  with q as (
    select
      t.id,
      t.reference_number,
      t.transaction_type,
      t.amount,
      t.transaction_status,
      t.approval_status,
      t.source_type,
      t.source_id,
      t.profile_id,
      t.member_id,
      t.initiated_by,
      t.approved_by,
      t.created_at,
      l.loan_number
    from public.transactions t
    left join public.loans l on l.id=t.source_id and t.source_type='loan'
    where (p_transaction_type is null or t.transaction_type=p_transaction_type)
      and (p_status is null or t.transaction_status=p_status)
      and (
        p_search is null or trim(p_search)=''
        or t.reference_number ilike '%'||trim(p_search)||'%'
        or l.loan_number ilike '%'||trim(p_search)||'%'
      )
      and t.transaction_type in ('loan_disbursement','loan_repayment','loan_late_penalty','reversal','correction','loan_service_charge','outsider_service_charge')
  )
  select count(*) into v_total from q;
  select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb)
  into v_rows from (select * from q order by created_at desc limit v_limit offset v_offset) x;
  return jsonb_build_object('rows',v_rows,'total',v_total,'limit',v_limit,'offset',v_offset,'actor',v_actor);
end;
$$;

revoke all on function public.list_admin_loan_transactions_v3(public.transaction_type,public.transaction_status,text,integer,integer) from public, anon;
grant execute on function public.list_admin_loan_transactions_v3(public.transaction_type,public.transaction_status,text,integer,integer) to authenticated;

create or replace function public.list_admin_loan_audit_v3(
  p_loan_id uuid default null,
  p_application_id uuid default null,
  p_limit integer default 100,
  p_offset integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor uuid := private.loan_require_permission_v3('audit.read');
  v_limit integer := least(greatest(coalesce(p_limit,100),1),200);
  v_offset integer := greatest(coalesce(p_offset,0),0);
  v_rows jsonb;
  v_total bigint;
begin
  with ids as (
    select p_loan_id loan_id,
           p_application_id application_id,
           (select outsider_loan_application_id from public.loans where id=p_loan_id) outsider_application_id
  ), q as (
    select al.*
    from public.audit_logs al, ids
    where al.entity_type in (
      'loan','loan_application','outsider_loan_application','loan_repayment_submission',
      'loan_installment','loan_recovery_event','loan_extension_request',
      'loan_conflict_declaration','loan_guarantor_replacement_request'
    )
      and (
        (p_loan_id is null and p_application_id is null)
        or al.entity_id=ids.loan_id
        or al.entity_id=ids.application_id
        or al.entity_id=ids.outsider_application_id
        or al.entity_id in (select rs.id from public.loan_repayment_submissions rs where rs.loan_id=ids.loan_id)
      )
  )
  select count(*) into v_total from q;
  select coalesce(jsonb_agg(to_jsonb(x) order by x.created_at desc), '[]'::jsonb)
  into v_rows from (select * from q order by created_at desc limit v_limit offset v_offset) x;
  return jsonb_build_object('rows',v_rows,'total',v_total,'limit',v_limit,'offset',v_offset,'actor',v_actor);
end;
$$;

revoke all on function public.list_admin_loan_audit_v3(uuid,uuid,integer,integer) from public, anon;
grant execute on function public.list_admin_loan_audit_v3(uuid,uuid,integer,integer) to authenticated;

/* -------------------------------------------------------------------------- */
/* 15. Security hardening / direct-table access                                */
/* -------------------------------------------------------------------------- */

alter table public.loan_command_idempotency enable row level security;
alter table public.loan_repayment_submissions enable row level security;
alter table public.loan_guarantor_replacement_requests enable row level security;
alter table public.loan_conflict_declarations enable row level security;
alter table public.loan_financial_reversals enable row level security;

/* Updated-at triggers on V3 workflow tables. */
drop trigger if exists loan_repayment_submissions_set_updated_at on public.loan_repayment_submissions;
create trigger loan_repayment_submissions_set_updated_at
before update on public.loan_repayment_submissions
for each row execute procedure private.set_updated_at();

drop trigger if exists loan_guarantor_replacement_requests_set_updated_at on public.loan_guarantor_replacement_requests;
create trigger loan_guarantor_replacement_requests_set_updated_at
before update on public.loan_guarantor_replacement_requests
for each row execute procedure private.set_updated_at();

/* -------------------------------------------------------------------------- */
/* 15.1 V2 compatibility repair and legacy command retirement                 */
/* -------------------------------------------------------------------------- */

/* Loan V2 created both evaluator bodies with a CASE expression inferred as
   text for an enum column. Rebuild those existing member-facing RPCs from
   their installed definitions with explicit enum casts, and make a successful
   evaluation transition the application into V3's reviewable `eligible`
   state. Keeping the established RPC signatures avoids a mobile-app cutover. */
do $loan_v2_evaluator_repair$
declare
  v_member_definition text;
  v_outsider_definition text;
  v_old_assignment constant text := $assignment$set eligibility_status = case when v_pass then 'eligible' else 'ineligible' end,$assignment$;
  v_new_assignment constant text := $assignment$set eligibility_status = case when v_pass then 'eligible'::public.loan_application_status else 'ineligible'::public.loan_application_status end,
      status = case when v_pass then 'eligible'::public.loan_application_status else 'submitted'::public.loan_application_status end,$assignment$;
begin
  select pg_get_functiondef('public.evaluate_member_loan_application_v2(uuid)'::regprocedure)
    into v_member_definition;
  if position(v_old_assignment in v_member_definition) = 0 then
    raise exception 'Loan V2 member evaluator has an unexpected definition; refusing an unsafe compatibility rewrite';
  end if;
  execute replace(v_member_definition, v_old_assignment, v_new_assignment);

  select pg_get_functiondef('public.evaluate_outsider_loan_application_v2(uuid)'::regprocedure)
    into v_outsider_definition;
  if position(v_old_assignment in v_outsider_definition) = 0 then
    raise exception 'Loan V2 outsider evaluator has an unexpected definition; refusing an unsafe compatibility rewrite';
  end if;
  execute replace(v_outsider_definition, v_old_assignment, v_new_assignment);
end;
$loan_v2_evaluator_repair$;

/* Bring forward any applications successfully evaluated before this cutover.
   Approval still re-runs the authoritative V3 eligibility checks. */
update public.loan_applications
set status='eligible'::public.loan_application_status,
    updated_at=now()
where status='submitted'::public.loan_application_status
  and eligibility_status='eligible'::public.loan_application_status;

update public.outsider_loan_applications
set status='eligible'::public.loan_application_status,
    updated_at=now()
where status='submitted'::public.loan_application_status
  and eligibility_status='eligible'::public.loan_application_status;

/* Retire stale V2 mutation bodies as well as their grants. This eliminates
   known runtime-invalid legacy code from the database and makes V3 the only
   supported admin write path. */
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
begin
  raise exception 'disburse_loan_v2 is retired; use disburse_loan_v3';
end;
$$;

create or replace function public.process_overdue_loan_installments()
returns jsonb
language sql
security definer
set search_path = ''
as $$
  select public.process_overdue_loan_installments_v3();
$$;

create or replace function public.process_serious_loan_defaults()
returns jsonb
language sql
security definer
set search_path = ''
as $$
  select public.process_serious_loan_defaults_v3();
$$;

/* -------------------------------------------------------------------------- */
/* 16. Cut over old privileged admin mutations                                 */
/* -------------------------------------------------------------------------- */

/* These commands prevent the old admin approval/disbursement paths from being
   used to bypass the V3 controls. Member-facing submit/respond/evaluate RPCs
   remain available. Repoint the admin panel to V3 before production cutover. */
revoke all on function public.review_loan_application_v2(public.loan_borrower_type,uuid,public.loan_approval_decision,numeric,text,jsonb) from public, anon, authenticated;
revoke all on function public.disburse_loan_v2(public.loan_borrower_type,uuid,text) from public, anon, authenticated;
revoke all on function public.post_verified_loan_repayment(uuid,jsonb) from public, anon, authenticated;
revoke all on function public.process_overdue_loan_installments() from public, anon, authenticated;
revoke all on function public.process_serious_loan_defaults() from public, anon, authenticated;
revoke all on function public.review_loan_application(uuid,public.loan_approval_decision,numeric,text,jsonb) from public, anon, authenticated;
revoke all on function public.disburse_loan(uuid,text) from public, anon, authenticated;

/* Legacy generic review/disbursement APIs from the first loan migration are
   also disabled. The new V3 commands are the single admin write boundary. */

/* -------------------------------------------------------------------------- */
/* 17. Verification / invariants                                               */
/* -------------------------------------------------------------------------- */

/* New allocation invariant can now be validated because historical rows from
   the existing repayment migration always carry payment_id. */
alter table public.loan_repayment_allocations
  validate constraint loan_repayment_allocations_payment_or_submission_ck;

/* V2 added these cross-source integrity rules as NOT VALID. A production V3
   cutover must either prove the historical data satisfies them or stop before
   exposing the new admin mutation surface. */
alter table public.loan_eligibility_checks
  validate constraint loan_eligibility_checks_exactly_one_source_v2;

alter table public.loan_approvals
  validate constraint loan_approvals_exactly_one_source_v2;

alter table public.loans
  validate constraint loans_exactly_one_application_source_v2;

alter table public.loans
  validate constraint loans_borrower_identity_matches_source_v2;

/* Verify every authoritative V3 transaction is balanced. */
do $$
begin
  if exists (
    select 1
    from public.transactions t
    where t.transaction_status='posted'
      and t.transaction_type in (
        'loan_disbursement',
        'loan_service_charge',
        'outsider_service_charge',
        'loan_repayment',
        'loan_late_penalty',
        'reversal',
        'correction'
      )
      and round(coalesce((
        select sum(case when te.entry_type='debit' then te.amount else 0 end)
        from public.transaction_entries te where te.transaction_id=t.id
      ),0),2)
      <> round(coalesce((
        select sum(case when te.entry_type='credit' then te.amount else 0 end)
        from public.transaction_entries te where te.transaction_id=t.id
      ),0),2)
  ) then
    raise exception 'Loan financial invariant failed: an authoritative posted transaction is unbalanced';
  end if;
end;
$$;

/* Verify there is no duplicated active outsider guarantee. */
do $$
begin
  if exists (
    select 1
    from public.outsider_loan_guarantors g
    where g.status in ('requested','accepted')
    group by g.guarantor_member_id
    having count(*) > 1
  ) then
    raise exception 'Loan financial invariant failed: member has more than one outstanding outsider guarantee';
  end if;
end;
$$;

/* Validate final-source constraints when the historical data is clean. */
do $$
begin
  if exists (
    select 1 from public.loan_approvals a
    where (a.loan_application_id is null and a.outsider_loan_application_id is null)
       or (a.loan_application_id is not null and a.outsider_loan_application_id is not null)
  ) then
    raise exception 'Loan approval source invariant failed';
  end if;

  if exists (
    select 1 from public.loans l
    where (l.loan_application_id is null and l.outsider_loan_application_id is null)
       or (l.loan_application_id is not null and l.outsider_loan_application_id is not null)
  ) then
    raise exception 'Loan source invariant failed';
  end if;
end;
$$;

/* Helpful indexes for admin-scale queues. */
create index if not exists loan_installments_overdue_queue_idx
  on public.loan_installments(due_date, status, loan_id)
  where paid_amount < total_due;

create index if not exists loan_default_events_loan_event_idx
  on public.loan_default_events(loan_id, event_type, event_date desc);

create index if not exists audit_logs_loan_entity_created_idx
  on public.audit_logs(entity_type, entity_id, created_at desc);

create index if not exists transactions_loan_created_idx
  on public.transactions(source_type, source_id, created_at desc);

/* Replace legacy pg_cron commands atomically when the extension is available.
   Some Supabase projects use an external scheduler instead, so its absence
   must not block the database cutover. The V3 processor entry points remain
   the required commands in either deployment model. */
do $loan_scheduler_cutover$
declare
  v_job record;
begin
  if to_regnamespace('cron') is null then
    raise warning 'pg_cron is not installed; schedule process_overdue_loan_installments_v3() and process_serious_loan_defaults_v3() through the approved external scheduler';
  else
    for v_job in
      select j.jobid
      from cron.job j
      where j.jobname in (
        'unity-finance-loan-overdue-processor',
        'unity-finance-loan-default-processor',
        'unity-finance-loan-overdue-processor-v3',
        'unity-finance-loan-default-processor-v3'
      )
    loop
      perform cron.unschedule(v_job.jobid);
    end loop;

    perform cron.schedule(
      'unity-finance-loan-overdue-processor',
      '15 0 * * *',
      $command$select public.process_overdue_loan_installments_v3();$command$
    );

    perform cron.schedule(
      'unity-finance-loan-default-processor',
      '30 0 * * *',
      $command$select public.process_serious_loan_defaults_v3();$command$
    );
  end if;
end;
$loan_scheduler_cutover$;

commit;

/*
===============================================================================
POST-MIGRATION OPERATIONS CHECKLIST
===============================================================================

1. Apply this migration only after Loan V2 exists.
2. Repoint the Next.js admin panel to V3 commands.
3. If pg_cron is installed, confirm the two V3 jobs created by this migration
   are present and running. Otherwise, configure the approved external
   scheduler to call `process_overdue_loan_installments_v3()` daily at 00:15
   and `process_serious_loan_defaults_v3()` daily at 00:30.
4. Ensure ALL other liquidity-changing commands (savings withdrawal,
   disbursement, recovery, and any future cash movement) participate in the
   same advisory-lock protocol before production concurrency testing.
5. The extension review RPC intentionally records committee approval but does
   not rewrite installment dates because the business playbook has not defined
   the exact schedule-rewrite policy. Do not add an invented formula.
6. Recovery events record approved recovery intent. Automatic guarantor debit
   or savings seizure is intentionally not implemented without an approved
   legal/business policy and matching ledger workflow.
7. Do not expose V3 support tables directly through the Data API. RLS is enabled
   and direct grants are revoked.
===============================================================================
*/
