begin;

-- ============================================================
-- 0. Dependency guard
-- ============================================================

do $$
begin
  if to_regclass('public.loan_products') is null
     or to_regclass('public.loan_applications') is null
     or to_regclass('public.loans') is null
     or to_regclass('public.loan_installments') is null
     or to_regclass('public.transactions') is null
     or to_regclass('public.transaction_entries') is null
     or to_regclass('public.accounts') is null
     or to_regclass('public.account_types') is null
     or to_regclass('public.members') is null
     or to_regclass('public.profiles') is null
  then
    raise exception
      'Unity Finance MVP base schema is missing. Apply the MVP schema before this loan migration.';
  end if;
end;
$$;


-- ============================================================
-- 1. Harden helper functions used by authorization
-- ============================================================

create or replace function private.current_user_has_role(p_role_code text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.user_roles ur
    join public.roles r
      on r.id = ur.role_id
    where ur.user_id = (select auth.uid())
      and r.code = p_role_code
  );
$$;

revoke all on function private.current_user_has_role(text) from public, anon, authenticated;
grant execute on function private.current_user_has_role(text) to authenticated;


create or replace function private.current_user_is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    private.current_user_has_role('admin')
    or private.current_user_has_role('super_admin');
$$;

revoke all on function private.current_user_is_admin() from public, anon, authenticated;
grant execute on function private.current_user_is_admin() to authenticated;


create or replace function private.current_user_has_permission(p_permission_code text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.user_roles ur
    join public.role_permissions rp
      on rp.role_id = ur.role_id
    join public.permissions p
      on p.id = rp.permission_id
    where ur.user_id = (select auth.uid())
      and p.code = p_permission_code
  );
$$;

revoke all on function private.current_user_has_permission(text) from public, anon, authenticated;
grant execute on function private.current_user_has_permission(text) to authenticated;


create or replace function private.current_member_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select m.id
  from public.members m
  where m.profile_id = (select auth.uid())
    and m.status = 'active'
  limit 1;
$$;

revoke all on function private.current_member_id() from public, anon, authenticated;
grant execute on function private.current_member_id() to authenticated;


-- ============================================================
-- 2. Loan application metadata / eligibility snapshots
-- ============================================================

alter table public.loan_applications
  add column if not exists eligibility_snapshot jsonb not null default '{}'::jsonb;

alter table public.loan_applications
  add column if not exists eligibility_evaluated_at timestamptz;

alter table public.loan_applications
  add column if not exists approved_amount numeric(18,2);

alter table public.loan_applications
  add column if not exists approved_at timestamptz;

create index if not exists loan_applications_status_submitted_idx
  on public.loan_applications(status, submitted_at desc);


alter table public.loan_eligibility_checks
  add column if not exists evaluation_run_id uuid not null default gen_random_uuid();

alter table public.loan_eligibility_checks
  add column if not exists checked_by uuid references public.profiles(id) on delete set null;

alter table public.loan_approvals
  add column if not exists manual_checks jsonb not null default '{}'::jsonb;

create index if not exists loan_eligibility_checks_application_run_idx
  on public.loan_eligibility_checks(loan_application_id, evaluation_run_id, checked_at desc);


-- ============================================================
-- 3. Loan installment penalty settlement tracking
-- ============================================================

alter table public.loan_installments
  add column if not exists paid_penalty_amount numeric(18,2) not null default 0;

alter table public.loan_installments
  add constraint loan_installments_paid_penalty_nonnegative
  check (paid_penalty_amount >= 0)
  not valid;

alter table public.loan_installments
  add constraint loan_installments_penalty_not_overpaid
  check (paid_penalty_amount <= late_penalty_amount)
  not valid;


-- ============================================================
-- 4. Explicit repayment allocation table
--
-- A single payment may settle one or more installments.
-- The allocation amounts are explicit because the playbook does
-- not define a hidden payment-allocation priority.
-- ============================================================

create table if not exists public.loan_repayment_allocations (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null
    references public.payments(id) on delete restrict,
  loan_id uuid not null
    references public.loans(id) on delete restrict,
  installment_id uuid not null
    references public.loan_installments(id) on delete restrict,
  allocated_base_amount numeric(18,2) not null default 0,
  allocated_penalty_amount numeric(18,2) not null default 0,
  transaction_id uuid references public.transactions(id) on delete restrict,
  created_at timestamptz not null default now(),
  check (allocated_base_amount >= 0),
  check (allocated_penalty_amount >= 0),
  check (allocated_base_amount + allocated_penalty_amount > 0),
  unique(payment_id, installment_id)
);

create index if not exists loan_repayment_allocations_loan_idx
  on public.loan_repayment_allocations(loan_id, installment_id);

create index if not exists loan_repayment_allocations_payment_idx
  on public.loan_repayment_allocations(payment_id);


-- ============================================================
-- 5. Savings security lock table
--
-- This is intentionally generic. The exact required security
-- ratio is NOT defined in the playbook and is therefore not
-- invented here.
-- ============================================================

create table if not exists public.savings_security_locks (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null
    references public.members(id) on delete restrict,
  loan_id uuid not null
    references public.loans(id) on delete restrict,
  amount numeric(18,2) not null check (amount > 0),
  status text not null default 'active'
    check (status in ('active', 'released')),
  reason text,
  created_at timestamptz not null default now(),
  released_at timestamptz
);

create index if not exists savings_security_locks_member_idx
  on public.savings_security_locks(member_id, status);

create index if not exists savings_security_locks_loan_idx
  on public.savings_security_locks(loan_id, status);


-- ============================================================
-- 6. Loan extension requests
--
-- The playbook permits an extension before serious default, but
-- does not define extension duration/schedule rules. This table
-- stores the request. Automatic schedule rewriting is NOT done.
-- ============================================================

create table if not exists public.loan_extension_requests (
  id uuid primary key default gen_random_uuid(),
  loan_id uuid not null
    references public.loans(id) on delete restrict,
  requested_by uuid not null
    references public.profiles(id) on delete restrict,
  reason text not null,
  requested_new_due_date date,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected', 'cancelled')),
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists loan_extension_requests_loan_idx
  on public.loan_extension_requests(loan_id, created_at desc);


-- ============================================================
-- 7. Loan recovery events
-- ============================================================

create table if not exists public.loan_recovery_events (
  id uuid primary key default gen_random_uuid(),
  loan_id uuid not null
    references public.loans(id) on delete restrict,
  source_type text not null
    check (source_type in ('savings_security', 'guarantor', 'other_approved')),
  source_id uuid,
  amount numeric(18,2) not null check (amount > 0),
  reason text,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'completed', 'rejected', 'cancelled')),
  approved_by uuid references public.profiles(id) on delete set null,
  transaction_id uuid references public.transactions(id) on delete restrict,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create index if not exists loan_recovery_events_loan_idx
  on public.loan_recovery_events(loan_id, created_at desc);


-- ============================================================
-- 8. Updated-at trigger for extension requests
-- ============================================================

drop trigger if exists loan_extension_requests_set_updated_at
  on public.loan_extension_requests;

create trigger loan_extension_requests_set_updated_at
before update on public.loan_extension_requests
for each row
execute procedure private.set_updated_at();


-- ============================================================
-- 9. System account uniqueness + seed
--
-- Accounts with no owner are system accounts.
-- One system account per account type.
-- ============================================================

create unique index if not exists accounts_one_system_account_per_type
  on public.accounts(account_type_id)
  where owner_profile_id is null
    and owner_member_id is null;


insert into public.accounts(account_type_id, currency, status)
select at.id, 'ETB', 'active'
from public.account_types at
where at.code in (
  'cash',
  'bank',
  'wallet',
  'loan_receivable',
  'loan_service_charge_income',
  'penalty_income',
  'group_income',
  'group_expense'
)
and not exists (
  select 1
  from public.accounts a
  where a.account_type_id = at.id
    and a.owner_profile_id is null
    and a.owner_member_id is null
);


-- ============================================================
-- 10. Internal financial helpers
-- ============================================================

create or replace function private.system_account_id(
  p_code public.account_type_code
)
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select a.id
  from public.accounts a
  join public.account_types at
    on at.id = a.account_type_id
  where at.code = p_code
    and a.owner_profile_id is null
    and a.owner_member_id is null
    and a.status = 'active'
  limit 1;
$$;

revoke all on function private.system_account_id(public.account_type_code)
  from public, anon, authenticated;


create or replace function private.account_balance(p_account_id uuid)
returns numeric
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    sum(
      case
        when te.entry_type = 'debit' then te.amount
        else -te.amount
      end
    ),
    0
  )::numeric(18,2)
  from public.transaction_entries te
  join public.transactions t
    on t.id = te.transaction_id
  where te.account_id = p_account_id
    and t.transaction_status = 'posted';
$$;

revoke all on function private.account_balance(uuid)
  from public, anon, authenticated;


create or replace function private.post_balanced_transaction(
  p_transaction_type public.transaction_type,
  p_profile_id uuid,
  p_member_id uuid,
  p_amount numeric,
  p_source_type text,
  p_source_id uuid,
  p_description text,
  p_entries jsonb
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
  if p_amount is null or p_amount <= 0 then
    raise exception 'Transaction amount must be greater than zero';
  end if;

  if p_entries is null or jsonb_typeof(p_entries) <> 'array' then
    raise exception 'Transaction entries must be a JSON array';
  end if;

  select
    count(*),
    coalesce(
      sum(
        case
          when x.entry_type = 'debit' then x.amount
          else 0
        end
      ),
      0
    )::numeric(18,2),
    coalesce(
      sum(
        case
          when x.entry_type = 'credit' then x.amount
          else 0
        end
      ),
      0
    )::numeric(18,2)
  into
    v_entry_count,
    v_debits,
    v_credits
  from jsonb_to_recordset(p_entries)
  as x(
    account_id uuid,
    entry_type public.transaction_entry_type,
    amount numeric
  );

  if v_entry_count < 2 then
    raise exception 'A financial transaction requires at least two entries';
  end if;

  if v_debits <= 0 or v_credits <= 0 then
    raise exception 'Financial transaction must contain debit and credit entries';
  end if;

  if v_debits <> v_credits then
    raise exception
      'Unbalanced transaction: debits %, credits %',
      v_debits,
      v_credits;
  end if;

  if v_debits <> round(p_amount, 2) then
    raise exception
      'Transaction amount % does not equal ledger total %',
      p_amount,
      v_debits;
  end if;

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
    description
  )
  values (
    p_transaction_type,
    p_source_type,
    p_source_id,
    p_profile_id,
    p_member_id,
    round(p_amount, 2),
    'ETB',
    'approved',
    'posted',
    (select auth.uid()),
    null,
    null,
    p_description
  )
  returning id into v_transaction_id;

  insert into public.transaction_entries(
    transaction_id,
    account_id,
    entry_type,
    amount
  )
  select
    v_transaction_id,
    x.account_id,
    x.entry_type,
    round(x.amount, 2)
  from jsonb_to_recordset(p_entries)
  as x(
    account_id uuid,
    entry_type public.transaction_entry_type,
    amount numeric
  );

  return v_transaction_id;
end;
$$;

revoke all on function private.post_balanced_transaction(
  public.transaction_type,
  uuid,
  uuid,
  numeric,
  text,
  uuid,
  text,
  jsonb
) from public, anon, authenticated;


-- ============================================================
-- 11. Private liquidity snapshot
--
-- Current implementation:
--   total member savings = liability balance of savings accounts
--   liquid funds = asset balances of system cash/bank/wallet
--   required reserve = total member savings * 30%
--   loanable funds = max(liquid funds - required reserve, 0)
--
-- This is the conservative interpretation used for the MVP.
-- It is intentionally isolated in one function so the business
-- formula can be changed later without rewriting loan commands.
-- ============================================================

create or replace function private.loan_liquidity_snapshot()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_total_savings numeric(18,2);
  v_liquid_funds numeric(18,2);
  v_required_reserve numeric(18,2);
  v_loanable_funds numeric(18,2);
  v_outstanding_loans numeric(18,2);
  v_overdue_loans bigint;
  v_reserve_rate numeric;
begin
  v_reserve_rate :=
    coalesce(
      public.get_active_rule_numeric('liquidity_reserve_rate'),
      0.30
    );

  select coalesce(sum(
    case
      when te.entry_type = 'credit' then te.amount
      else -te.amount
    end
  ), 0)::numeric(18,2)
  into v_total_savings
  from public.accounts a
  join public.account_types at
    on at.id = a.account_type_id
  join public.transaction_entries te
    on te.account_id = a.id
  join public.transactions t
    on t.id = te.transaction_id
  where at.code = 'member_savings'
    and t.transaction_status = 'posted'
    and a.owner_member_id is not null
    and a.status <> 'closed';

  select coalesce(sum(
    case
      when te.entry_type = 'debit' then te.amount
      else -te.amount
    end
  ), 0)::numeric(18,2)
  into v_liquid_funds
  from public.accounts a
  join public.account_types at
    on at.id = a.account_type_id
  join public.transaction_entries te
    on te.account_id = a.id
  join public.transactions t
    on t.id = te.transaction_id
  where at.code in ('cash', 'bank', 'wallet')
    and t.transaction_status = 'posted'
    and a.owner_profile_id is null
    and a.owner_member_id is null
    and a.status = 'active';

  select coalesce(sum(
    greatest(l.total_repayment - coalesce(sum_alloc.total_base_paid, 0), 0)
  ), 0)::numeric(18,2)
  into v_outstanding_loans
  from public.loans l
  left join (
    select
      loan_id,
      sum(allocated_base_amount)::numeric(18,2) as total_base_paid
    from public.loan_repayment_allocations
    group by loan_id
  ) sum_alloc
    on sum_alloc.loan_id = l.id
  where l.status in ('active', 'overdue', 'defaulted');

  select count(distinct l.id)
  into v_overdue_loans
  from public.loans l
  join public.loan_installments li
    on li.loan_id = l.id
  where l.status in ('active', 'overdue', 'defaulted')
    and li.status in ('overdue', 'defaulted');

  v_required_reserve :=
    round(v_total_savings * v_reserve_rate, 2);

  v_loanable_funds :=
    greatest(v_liquid_funds - v_required_reserve, 0);

  return jsonb_build_object(
    'total_member_savings', v_total_savings,
    'available_cash', v_liquid_funds,
    'outstanding_loans', v_outstanding_loans,
    'required_reserve', v_required_reserve,
    'loanable_funds', v_loanable_funds,
    'liquidity_reserve_rate', v_reserve_rate,
    'overdue_loans', v_overdue_loans,
    'reserve_compliant', v_liquid_funds >= v_required_reserve
  );
end;
$$;

revoke all on function private.loan_liquidity_snapshot()
  from public, anon, authenticated;


-- ============================================================
-- 12. Loan application submission
--
-- Client cannot directly insert loan_applications anymore.
-- ============================================================

create or replace function public.submit_loan_application(
  p_loan_product_id uuid,
  p_requested_amount numeric,
  p_purpose text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_profile_id uuid := (select auth.uid());
  v_member_id uuid;
  v_product record;
  v_application_id uuid;
  v_eligibility jsonb;
begin
  if v_profile_id is null then
    raise exception 'Not authenticated';
  end if;

  if not private.current_user_has_permission('loan.apply') then
    raise exception 'Unauthorized';
  end if;

  if p_requested_amount is null or p_requested_amount <= 0 then
    raise exception 'Requested loan amount must be greater than zero';
  end if;

  select
    lp.id,
    lp.code,
    lp.name,
    lp.borrower_type,
    lp.service_charge_rate,
    lp.max_amount,
    lp.term_months,
    lp.active
  into v_product
  from public.loan_products lp
  where lp.id = p_loan_product_id
    and lp.active = true;

  if not found then
    raise exception 'Loan product not found or inactive';
  end if;

  if v_product.borrower_type = 'member' then
    select m.id
    into v_member_id
    from public.members m
    where m.profile_id = v_profile_id
      and m.status = 'active'
    limit 1;

    if v_member_id is null then
      raise exception 'Only active members can apply for a member loan';
    end if;
  else
    if exists (
      select 1
      from public.members m
      where m.profile_id = v_profile_id
        and m.status = 'active'
    ) then
      raise exception 'Active members must use the member loan product';
    end if;

    v_member_id := null;
  end if;

  insert into public.loan_applications(
    applicant_profile_id,
    member_id,
    loan_product_id,
    requested_amount,
    purpose,
    status,
    submitted_at
  )
  values (
    v_profile_id,
    v_member_id,
    p_loan_product_id,
    round(p_requested_amount, 2),
    nullif(trim(p_purpose), ''),
    'submitted',
    now()
  )
  returning id into v_application_id;

  if v_product.borrower_type = 'member' then
    v_eligibility := public.evaluate_loan_application(v_application_id);
  else
    v_eligibility := jsonb_build_object(
      'eligible', false,
      'requires_guarantor', true,
      'application_id', v_application_id,
      'message', 'An active member guarantor is required before eligibility can be completed.'
    );
  end if;

  return jsonb_build_object(
    'application_id', v_application_id,
    'application_number', (
      select la.application_number
      from public.loan_applications la
      where la.id = v_application_id
    ),
    'borrower_type', v_product.borrower_type,
    'eligibility', v_eligibility
  );
end;
$$;

revoke all on function public.submit_loan_application(uuid, numeric, text)
  from public, anon;
grant execute on function public.submit_loan_application(uuid, numeric, text)
  to authenticated;


-- ============================================================
-- 13. Loan eligibility evaluator
-- ============================================================

create or replace function public.evaluate_loan_application(
  p_application_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_application record;
  v_product record;
  v_run_id uuid := gen_random_uuid();
  v_member_saving_months integer := 0;
  v_current_obligation_ok boolean := true;
  v_no_overdue boolean := true;
  v_amount_ok boolean := false;
  v_liquidity_ok boolean := false;
  v_guarantor_ok boolean := false;
  v_member_active boolean := false;
  v_is_outsider boolean := false;
  v_liquidity jsonb;
  v_manual_reviews jsonb := '[]'::jsonb;
  v_pass boolean;
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
    la.loan_product_id,
    la.requested_amount,
    la.approved_amount,
    la.status,
    lp.borrower_type,
    lp.max_amount,
    lp.term_months,
    lp.service_charge_rate
  into v_application
  from public.loan_applications la
  join public.loan_products lp
    on lp.id = la.loan_product_id
  where la.id = p_application_id
  for update;

  if not found then
    raise exception 'Loan application not found';
  end if;

  if not (
    v_application.applicant_profile_id = v_actor
    or private.current_user_has_permission('loan.review')
  ) then
    raise exception 'Unauthorized';
  end if;

  if v_application.status in ('approved', 'rejected', 'cancelled') then
    raise exception 'Application is no longer eligible for evaluation';
  end if;

  v_is_outsider := v_application.borrower_type = 'outsider';

  if not v_is_outsider then
    select exists (
      select 1
      from public.members m
      where m.id = v_application.member_id
        and m.status = 'active'
    )
    into v_member_active;

    select count(*)
    into v_member_saving_months
    from public.savings_obligations so
    where so.member_id = v_application.member_id
      and so.status = 'paid';

    v_no_overdue := not exists (
      select 1
      from public.loans l
      join public.loan_installments li
        on li.loan_id = l.id
      where l.member_id = v_application.member_id
        and l.status in ('active', 'overdue', 'defaulted')
        and li.paid_amount < li.total_due
        and li.due_date < current_date
    );

    select case
      when so.id is null then true
      when so.due_date > current_date then true
      else so.paid_amount >= so.required_amount
    end
    into v_current_obligation_ok
    from public.savings_obligations so
    where so.member_id = v_application.member_id
      and so.period_year = extract(year from current_date)::integer
      and so.period_month = extract(month from current_date)::integer
    limit 1;

    if v_current_obligation_ok is null then
      v_current_obligation_ok := true;
    end if;
  else
    v_member_active := false;

    select exists (
      select 1
      from public.loan_guarantors lg
      where lg.loan_application_id = v_application.id
        and lg.status = 'accepted'
    )
    into v_guarantor_ok;

    if not v_guarantor_ok then
      v_manual_reviews := v_manual_reviews || jsonb_build_array('GUARANTOR_REQUIRED');
    end if;
  end if;

  v_amount_ok := v_application.requested_amount <= v_application.max_amount;

  v_liquidity := private.loan_liquidity_snapshot();

  v_liquidity_ok := (
    coalesce((v_liquidity ->> 'loanable_funds')::numeric, 0)
    >= v_application.requested_amount
  );

  -- Repayment capacity is explicitly part of the business decision,
  -- but no formula is defined in the playbook. Keep it as a manual
  -- review until the group approves a formula.
  v_manual_reviews := v_manual_reviews || jsonb_build_array(
    'REPAYMENT_CAPACITY'
  );

  if v_is_outsider then
    -- Guarantor security requirement exists in the playbook, but the
    -- exact ratio/formula is not defined. Keep this as an explicit
    -- manual confirmation instead of inventing a percentage.
    v_manual_reviews := v_manual_reviews || jsonb_build_array(
      'GUARANTOR_SECURITY'
    );
  end if;

  -- Liquidity is an approval/disbursement gate, not a permanent
  -- borrower eligibility failure. Management may approve a lower
  -- amount when the requested amount exceeds currently loanable funds.
  if not v_liquidity_ok then
    v_manual_reviews := v_manual_reviews || jsonb_build_array(
      'LIQUIDITY_AMOUNT_REDUCTION_OR_DELAY'
    );
  end if;

  v_pass :=
    case
      when v_is_outsider then
        v_amount_ok
        and v_guarantor_ok
      else
        v_member_active
        and (v_member_saving_months >= 2)
        and v_no_overdue
        and v_current_obligation_ok
        and v_amount_ok
    end;

  insert into public.loan_eligibility_checks(
    loan_application_id,
    evaluation_run_id,
    check_code,
    result,
    value,
    reason,
    checked_by
  )
  values
    (
      v_application.id,
      v_run_id,
      'ACTIVE_MEMBER',
      case when v_is_outsider then true else v_member_active end,
      v_member_active::text,
      case
        when v_is_outsider then 'Not applicable for outsider loan'
        when v_member_active then 'Active member'
        else 'Applicant is not an active member'
      end,
      v_actor
    ),
    (
      v_application.id,
      v_run_id,
      'MINIMUM_SAVING_HISTORY',
      case when v_is_outsider then true else v_member_saving_months >= 2 end,
      v_member_saving_months::text,
      case
        when v_is_outsider then 'Not applicable for outsider loan'
        when v_member_saving_months >= 2 then 'At least two paid saving months'
        else 'Fewer than two paid saving months'
      end,
      v_actor
    ),
    (
      v_application.id,
      v_run_id,
      'NO_OVERDUE_LOAN',
      case when v_is_outsider then true else v_no_overdue end,
      v_no_overdue::text,
      case
        when v_is_outsider then 'Not applicable for outsider loan'
        when v_no_overdue then 'No overdue loan'
        else 'Applicant has an overdue loan'
      end,
      v_actor
    ),
    (
      v_application.id,
      v_run_id,
      'CURRENT_MONTHLY_CONTRIBUTION',
      case when v_is_outsider then true else v_current_obligation_ok end,
      v_current_obligation_ok::text,
      case
        when v_is_outsider then 'Not applicable for outsider loan'
        when v_current_obligation_ok then 'Current requirement satisfied or not yet due'
        else 'Current required contribution is not fulfilled'
      end,
      v_actor
    ),
    (
      v_application.id,
      v_run_id,
      'MAXIMUM_AMOUNT',
      v_amount_ok,
      v_application.requested_amount::text,
      case
        when v_amount_ok then 'Requested amount is within the product maximum'
        else 'Requested amount exceeds the configured maximum'
      end,
      v_actor
    ),
    (
      v_application.id,
      v_run_id,
      'LIQUIDITY',
      v_liquidity_ok,
      coalesce(v_liquidity ->> 'loanable_funds', '0'),
      case
        when v_liquidity_ok then 'Liquidity is currently sufficient'
        else 'Liquidity reserve would be breached'
      end,
      v_actor
    ),
    (
      v_application.id,
      v_run_id,
      'GUARANTOR',
      case when v_is_outsider then v_guarantor_ok else true end,
      v_guarantor_ok::text,
      case
        when not v_is_outsider then 'Not applicable for member loan'
        when v_guarantor_ok then 'Accepted active-member guarantor exists'
        else 'Outsider loan requires an accepted guarantor'
      end,
      v_actor
    );

  v_snapshot := jsonb_build_object(
    'evaluation_run_id', v_run_id,
    'evaluated_at', now(),
    'borrower_type', v_application.borrower_type,
    'member_saving_months', v_member_saving_months,
    'active_member', v_member_active,
    'no_overdue_loan', v_no_overdue,
    'current_monthly_contribution_ok', v_current_obligation_ok,
    'amount_ok', v_amount_ok,
    'liquidity_ok', v_liquidity_ok,
    'guarantor_ok', v_guarantor_ok,
    'requested_amount', v_application.requested_amount,
    'max_amount', v_application.max_amount,
    'liquidity', v_liquidity,
    'manual_reviews', v_manual_reviews
  );

  update public.loan_applications
  set
    eligibility_status = case
      when v_pass then 'eligible'::public.loan_application_status
      else 'ineligible'::public.loan_application_status
    end,
    eligibility_snapshot = v_snapshot,
    eligibility_evaluated_at = now(),
    status = case
      when v_pass then 'under_review'::public.loan_application_status
      else 'ineligible'::public.loan_application_status
    end,
    updated_at = now()
  where id = v_application.id;

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
    v_actor,
    'LOAN_ELIGIBILITY_EVALUATED',
    'loan_application',
    v_application.id,
    null,
    v_snapshot,
    jsonb_build_object('evaluation_run_id', v_run_id)
  );

  return jsonb_build_object(
    'eligible', v_pass,
    'application_id', v_application.id,
    'application_number', v_application.application_number,
    'evaluation_run_id', v_run_id,
    'manual_reviews', v_manual_reviews,
    'liquidity', v_liquidity
  );
end;
$$;

revoke all on function public.evaluate_loan_application(uuid)
  from public, anon;
grant execute on function public.evaluate_loan_application(uuid)
  to authenticated;


-- ============================================================
-- 14. Create / replace guarantor request
-- ============================================================

create or replace function public.request_loan_guarantor(
  p_loan_application_id uuid,
  p_guarantor_member_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_application record;
  v_guarantor_profile_id uuid;
  v_guaranteed_amount numeric(18,2);
  v_potential_responsibility numeric(18,2);
  v_service_rate numeric(8,4);
  v_existing_id uuid;
begin
  if v_actor is null then
    raise exception 'Not authenticated';
  end if;

  if not private.current_user_has_permission('loan.apply') then
    raise exception 'Unauthorized';
  end if;

  select
    la.id,
    la.applicant_profile_id,
    la.requested_amount,
    la.status,
    lp.borrower_type,
    lp.service_charge_rate
  into v_application
  from public.loan_applications la
  join public.loan_products lp
    on lp.id = la.loan_product_id
  where la.id = p_loan_application_id
  for update;

  if not found then
    raise exception 'Loan application not found';
  end if;

  if v_application.applicant_profile_id <> v_actor then
    raise exception 'Only the applicant can select a guarantor';
  end if;

  if v_application.borrower_type <> 'outsider' then
    raise exception 'Only outsider loans require a guarantor';
  end if;

  if v_application.status in ('approved', 'rejected', 'cancelled') then
    raise exception 'Application is not accepting guarantor requests';
  end if;

  select m.profile_id
  into v_guarantor_profile_id
  from public.members m
  where m.id = p_guarantor_member_id
    and m.status = 'active';

  if v_guarantor_profile_id is null then
    raise exception 'Guarantor must be an active member';
  end if;

  if v_guarantor_profile_id = v_actor then
    raise exception 'Applicant cannot guarantee their own outsider loan';
  end if;

  v_service_rate := v_application.service_charge_rate;
  v_guaranteed_amount := round(v_application.requested_amount, 2);
  v_potential_responsibility :=
    round(v_application.requested_amount * (1 + v_service_rate), 2);

  select lg.id
  into v_existing_id
  from public.loan_guarantors lg
  where lg.loan_application_id = p_loan_application_id
  for update;

  if v_existing_id is not null then
    if exists (
      select 1
      from public.loan_guarantors lg
      where lg.id = v_existing_id
        and lg.status = 'accepted'
    ) then
      raise exception 'An accepted guarantor cannot be replaced without an approved replacement workflow';
    end if;

    update public.loan_guarantors
    set
      guarantor_member_id = p_guarantor_member_id,
      guaranteed_amount = v_guaranteed_amount,
      potential_responsibility = v_potential_responsibility,
      status = 'requested',
      requested_at = now(),
      approved_at = null,
      rejected_at = null,
      released_at = null
    where id = v_existing_id;
  else
    insert into public.loan_guarantors(
      loan_application_id,
      guarantor_member_id,
      guaranteed_amount,
      potential_responsibility,
      status
    )
    values (
      p_loan_application_id,
      p_guarantor_member_id,
      v_guaranteed_amount,
      v_potential_responsibility,
      'requested'
    )
    returning id into v_existing_id;
  end if;

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
    v_actor,
    'GUARANTOR_REQUESTED',
    'loan_application',
    p_loan_application_id,
    null,
    jsonb_build_object(
      'guarantor_member_id', p_guarantor_member_id,
      'guaranteed_amount', v_guaranteed_amount,
      'potential_responsibility', v_potential_responsibility
    ),
    null
  );

  return jsonb_build_object(
    'guarantor_id', v_existing_id,
    'status', 'requested'
  );
end;
$$;

revoke all on function public.request_loan_guarantor(uuid, uuid)
  from public, anon;
grant execute on function public.request_loan_guarantor(uuid, uuid)
  to authenticated;


-- ============================================================
-- 15. Guarantor response
--
-- Concurrency is protected with an advisory transaction lock.
-- The business rule is one outstanding outsider guarantee.
-- ============================================================

create or replace function public.respond_to_loan_guarantor_request(
  p_guarantor_request_id uuid,
  p_accept boolean
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_request record;
  v_conflict boolean;
  v_new_status public.guarantor_status;
begin
  if v_actor is null then
    raise exception 'Not authenticated';
  end if;

  if not private.current_user_has_permission('guarantor.respond') then
    raise exception 'Unauthorized';
  end if;

  select
    lg.id,
    lg.loan_application_id,
    lg.guarantor_member_id,
    lg.status,
    la.applicant_profile_id,
    la.status as application_status
  into v_request
  from public.loan_guarantors lg
  join public.loan_applications la
    on la.id = lg.loan_application_id
  join public.members gm
    on gm.id = lg.guarantor_member_id
  where lg.id = p_guarantor_request_id
    and gm.profile_id = v_actor
  for update;

  if not found then
    raise exception 'Guarantor request not found or unauthorized';
  end if;

  if v_request.status <> 'requested' then
    raise exception 'Guarantor request has already been decided';
  end if;

  if p_accept then
    -- Serialize acceptance for this guarantor.
    perform pg_advisory_xact_lock(
      hashtextextended(
        'loan-guarantor:' || v_request.guarantor_member_id::text,
        0
      )
    );

    select exists (
      select 1
      from public.loan_guarantors lg2
      join public.loan_applications la2
        on la2.id = lg2.loan_application_id
      left join public.loans l2
        on l2.loan_application_id = la2.id
      where lg2.guarantor_member_id = v_request.guarantor_member_id
        and lg2.status = 'accepted'
        and l2.status in ('active', 'overdue', 'defaulted')
        and lg2.id <> v_request.id
    )
    into v_conflict;

    if v_conflict then
      raise exception 'This member already has an outstanding or active guarantee';
    end if;

    update public.loan_guarantors
    set
      status = 'accepted',
      approved_at = now(),
      rejected_at = null
    where id = v_request.id;

    v_new_status := 'accepted';
  else
    update public.loan_guarantors
    set
      status = 'rejected',
      rejected_at = now(),
      approved_at = null
    where id = v_request.id;

    v_new_status := 'rejected';
  end if;

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
    v_actor,
    case when p_accept then 'GUARANTOR_ACCEPTED' else 'GUARANTOR_REJECTED' end,
    'loan_guarantor',
    v_request.id,
    jsonb_build_object('status', v_request.status),
    jsonb_build_object('status', v_new_status),
    null
  );

  if p_accept then
    perform public.evaluate_loan_application(v_request.loan_application_id);
  end if;

  return jsonb_build_object(
    'guarantor_request_id', v_request.id,
    'status', v_new_status
  );
end;
$$;

revoke all on function public.respond_to_loan_guarantor_request(uuid, boolean)
  from public, anon;
grant execute on function public.respond_to_loan_guarantor_request(uuid, boolean)
  to authenticated;


-- ============================================================
-- 16. Loan approval / rejection
--
-- p_manual_checks example:
-- {
--   "repayment_capacity_confirmed": true,
--   "guarantor_security_confirmed": true
-- }
--
-- The repayment-capacity formula is intentionally not invented.
-- Approval requires an explicit human confirmation.
-- ============================================================

create or replace function public.review_loan_application(
  p_loan_application_id uuid,
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
  v_application record;
  v_approved_count integer;
  v_new_status public.loan_application_status;
  v_repayment_capacity_confirmed boolean;
  v_guarantor_security_confirmed boolean;
  v_approved_amount numeric(18,2);
begin
  if v_actor is null then
    raise exception 'Not authenticated';
  end if;

  if not private.current_user_has_permission('loan.approve') then
    raise exception 'Unauthorized';
  end if;

  select
    la.id,
    la.applicant_profile_id,
    la.status,
    la.eligibility_status,
    lp.borrower_type
  into v_application
  from public.loan_applications la
  join public.loan_products lp
    on lp.id = la.loan_product_id
  where la.id = p_loan_application_id
  for update;

  if not found then
    raise exception 'Loan application not found';
  end if;

  if v_application.status <> 'under_review' then
    raise exception 'Application is not in a reviewable state';
  end if;

  if v_application.eligibility_status <> 'eligible' then
    raise exception 'Application is not eligible';
  end if;

  if v_actor = v_application.applicant_profile_id then
    raise exception 'A person cannot approve their own loan';
  end if;

  if p_decision = 'approved' then
    v_approved_amount := coalesce(
      p_approved_amount,
      (
        select approved_amount
        from public.loan_applications
        where id = p_loan_application_id
      ),
      (
        select requested_amount
        from public.loan_applications
        where id = p_loan_application_id
      )
    );

    if v_approved_amount is null or v_approved_amount <= 0 then
      raise exception 'Approved loan amount must be greater than zero';
    end if;

    if v_approved_amount > (
      select requested_amount
      from public.loan_applications
      where id = p_loan_application_id
    ) then
      raise exception 'Approved amount cannot exceed requested amount';
    end if;

    if v_approved_amount > (
      select lp.max_amount
      from public.loan_applications la
      join public.loan_products lp on lp.id = la.loan_product_id
      where la.id = p_loan_application_id
    ) then
      raise exception 'Approved amount exceeds product maximum';
    end if;

    if exists (
      select 1
      from public.loan_applications la
      where la.id = p_loan_application_id
        and la.approved_amount is not null
        and la.approved_amount <> round(v_approved_amount, 2)
    ) then
      raise exception 'Approved amount must match the amount already agreed by the first approver';
    end if;
  end if;

  v_repayment_capacity_confirmed :=
    coalesce(
      (p_manual_checks ->> 'repayment_capacity_confirmed')::boolean,
      false
    );

  v_guarantor_security_confirmed :=
    case
      when v_application.borrower_type = 'outsider' then
        coalesce(
          (p_manual_checks ->> 'guarantor_security_confirmed')::boolean,
          false
        )
      else true
    end;

  if p_decision = 'approved' and not v_repayment_capacity_confirmed then
    raise exception 'Repayment capacity must be explicitly confirmed';
  end if;

  if p_decision = 'approved'
     and v_application.borrower_type = 'outsider'
     and not v_guarantor_security_confirmed then
    raise exception 'Guarantor security must be explicitly confirmed';
  end if;

  insert into public.loan_approvals(
    loan_application_id,
    approver_profile_id,
    decision,
    comment,
    manual_checks,
    decided_at
  )
  values (
    p_loan_application_id,
    v_actor,
    p_decision,
    nullif(trim(p_comment), ''),
    coalesce(p_manual_checks, '{}'::jsonb),
    now()
  );

  if p_decision = 'approved' then
    update public.loan_applications
    set
      approved_amount = round(v_approved_amount, 2),
      updated_at = now()
    where id = p_loan_application_id;
  end if;

  if p_decision = 'rejected' then
    v_new_status := 'rejected';

    update public.loan_applications
    set
      status = 'rejected',
      updated_at = now()
    where id = p_loan_application_id;
  else
    select count(*)
    into v_approved_count
    from public.loan_approvals
    where loan_application_id = p_loan_application_id
      and decision = 'approved';

    if v_approved_count >= 2 then
      v_new_status := 'approved';

      update public.loan_applications
      set
        status = 'approved',
        approved_amount = round(v_approved_amount, 2),
        approved_at = now(),
        updated_at = now()
      where id = p_loan_application_id;
    else
      v_new_status := 'under_review';
    end if;
  end if;

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
    v_actor,
    case when p_decision = 'approved'
      then 'LOAN_APPROVAL_RECORDED'
      else 'LOAN_REJECTION_RECORDED'
    end,
    'loan_application',
    p_loan_application_id,
    jsonb_build_object('status', v_application.status),
    jsonb_build_object(
      'status', v_new_status,
      'decision', p_decision,
      'manual_checks', p_manual_checks
    ),
    null
  );

  return jsonb_build_object(
    'application_id', p_loan_application_id,
    'application_status', v_new_status,
    'approved_amount', (
      select approved_amount
      from public.loan_applications
      where id = p_loan_application_id
    ),
    'approved_count', (
      select count(*)
      from public.loan_approvals
      where loan_application_id = p_loan_application_id
        and decision = 'approved'
    )
  );
exception
  when unique_violation then
    raise exception 'This reviewer has already reviewed this application';
end;
$$;

revoke all on function public.review_loan_application(
  uuid,
  public.loan_approval_decision,
  numeric,
  text,
  jsonb
) from public, anon;
grant execute on function public.review_loan_application(
  uuid,
  public.loan_approval_decision,
  numeric,
  text,
  jsonb
) to authenticated;


-- ============================================================
-- 17. Cancel application
-- ============================================================

create or replace function public.cancel_loan_application(
  p_loan_application_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_status public.loan_application_status;
begin
  if v_actor is null then
    raise exception 'Not authenticated';
  end if;

  select status
  into v_status
  from public.loan_applications
  where id = p_loan_application_id
    and applicant_profile_id = v_actor
  for update;

  if not found then
    raise exception 'Application not found or unauthorized';
  end if;

  if v_status in ('approved', 'rejected', 'cancelled') then
    raise exception 'Application cannot be cancelled in its current state';
  end if;

  update public.loan_applications
  set
    status = 'cancelled',
    updated_at = now()
  where id = p_loan_application_id;

  update public.loan_guarantors
  set
    status = 'released',
    released_at = now()
  where loan_application_id = p_loan_application_id
    and status = 'accepted';

  insert into public.audit_logs(
    actor_user_id,
    action,
    entity_type,
    entity_id,
    new_data
  )
  values (
    v_actor,
    'LOAN_APPLICATION_CANCELLED',
    'loan_application',
    p_loan_application_id,
    jsonb_build_object('status', 'cancelled')
  );

  return jsonb_build_object(
    'application_id', p_loan_application_id,
    'status', 'cancelled'
  );
end;
$$;

revoke all on function public.cancel_loan_application(uuid)
  from public, anon;
grant execute on function public.cancel_loan_application(uuid)
  to authenticated;


-- ============================================================
-- 18. Disbursement
--
-- IMPORTANT:
--   This creates the loans row only after approval.
--   It performs a final liquidity check and locks the application
--   row, so concurrent disbursement attempts cannot both succeed.
--
-- p_source_account_code:
--   cash | bank | wallet
-- ============================================================

create or replace function public.disburse_loan(
  p_loan_application_id uuid,
  p_source_account_code text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_application record;
  v_approved_count integer;
  v_guarantor record;
  v_liquidity jsonb;
  v_source_type public.account_type_code;
  v_source_account_id uuid;
  v_receivable_account_id uuid;
  v_service_income_account_id uuid;
  v_loan_id uuid;
  v_disbursement_transaction_id uuid;
  v_disbursement_id uuid;
  v_service_charge numeric(18,2);
  v_total_repayment numeric(18,2);
  v_approved_principal numeric(18,2);
  v_maturity_date date;
  v_terms int;
  v_principal_per_installment numeric(18,2);
  v_service_per_installment numeric(18,2);
  v_i int;
  v_principal_amount numeric(18,2);
  v_service_amount numeric(18,2);
  v_installment_total numeric(18,2);
  v_disbursed_at timestamptz := now();
begin
  if v_actor is null then
    raise exception 'Not authenticated';
  end if;

  if not private.current_user_has_permission('loan.disburse') then
    raise exception 'Unauthorized';
  end if;

  v_source_type := case lower(trim(p_source_account_code))
    when 'cash' then 'cash'::public.account_type_code
    when 'bank' then 'bank'::public.account_type_code
    when 'wallet' then 'wallet'::public.account_type_code
    else null
  end;

  if v_source_type is null then
    raise exception 'Invalid disbursement source account. Use cash, bank, or wallet';
  end if;

  select
    la.id,
    la.application_number,
    la.applicant_profile_id,
    la.member_id,
    la.loan_product_id,
    la.requested_amount,
    la.approved_amount,
    la.status,
    lp.borrower_type,
    lp.service_charge_rate,
    lp.term_months
  into v_application
  from public.loan_applications la
  join public.loan_products lp
    on lp.id = la.loan_product_id
  where la.id = p_loan_application_id
  for update;

  if not found then
    raise exception 'Loan application not found';
  end if;

  if v_application.status <> 'approved' then
    raise exception 'Loan application must have two approvals before disbursement';
  end if;

  if exists (
    select 1
    from public.loans l
    where l.loan_application_id = p_loan_application_id
  ) then
    raise exception 'Loan has already been disbursed';
  end if;

  select count(*)
  into v_approved_count
  from public.loan_approvals
  where loan_application_id = p_loan_application_id
    and decision = 'approved';

  if v_approved_count < 2 then
    raise exception 'At least two distinct approvals are required';
  end if;

  v_approved_principal :=
    coalesce(v_application.approved_amount, v_application.requested_amount);

  if v_approved_principal <= 0
     or v_approved_principal > v_application.requested_amount then
    raise exception 'Invalid approved loan amount';
  end if;

  if v_approved_principal > (
    select lp.max_amount
    from public.loan_products lp
    where lp.id = v_application.loan_product_id
  ) then
    raise exception 'Approved amount exceeds product maximum';
  end if;

  if exists (
    select 1
    from public.loan_approvals la1
    join public.loan_approvals la2
      on la2.loan_application_id = la1.loan_application_id
     and la2.decision = 'approved'
     and la2.approver_profile_id <> la1.approver_profile_id
    where la1.loan_application_id = p_loan_application_id
      and la1.approver_profile_id = v_application.applicant_profile_id
      and la1.decision = 'approved'
  ) then
    raise exception 'Borrower cannot approve their own loan';
  end if;

  if v_application.borrower_type = 'outsider' then
    select
      lg.id,
      lg.guarantor_member_id,
      lg.status
    into v_guarantor
    from public.loan_guarantors lg
    join public.members gm
      on gm.id = lg.guarantor_member_id
    where lg.loan_application_id = p_loan_application_id
      and lg.status = 'accepted'
      and gm.status = 'active'
    for update;

    if not found then
      raise exception 'Outsider loan requires an accepted active-member guarantor';
    end if;

    perform pg_advisory_xact_lock(
      hashtextextended(
        'loan-guarantor:' || v_guarantor.guarantor_member_id::text,
        0
      )
    );

    if exists (
      select 1
      from public.loan_guarantors lg2
      join public.loan_applications la2
        on la2.id = lg2.loan_application_id
      join public.loans l2
        on l2.loan_application_id = la2.id
      where lg2.guarantor_member_id = v_guarantor.guarantor_member_id
        and lg2.status = 'accepted'
        and l2.status in ('active', 'overdue', 'defaulted')
    ) then
      raise exception 'Guarantor already guarantees an outstanding outsider loan';
    end if;
  end if;

  v_liquidity := private.loan_liquidity_snapshot();

  if coalesce((v_liquidity ->> 'loanable_funds')::numeric, 0)
     < v_approved_principal then
    raise exception
      'Insufficient liquidity for disbursement';
  end if;

  v_source_account_id :=
    private.system_account_id(v_source_type);

  if v_source_account_id is null then
    raise exception 'System disbursement account is not configured';
  end if;

  if private.account_balance(v_source_account_id)
     < v_approved_principal then
    raise exception 'Selected disbursement account does not have sufficient funds';
  end if;

  v_receivable_account_id :=
    private.system_account_id('loan_receivable'::public.account_type_code);

  v_service_income_account_id :=
    private.system_account_id(
      'loan_service_charge_income'::public.account_type_code
    );

  if v_receivable_account_id is null
     or v_service_income_account_id is null then
    raise exception 'Loan accounting accounts are not configured';
  end if;

  v_service_charge :=
    round(
      v_approved_principal * v_application.service_charge_rate,
      2
    );

  v_total_repayment :=
    round(
      v_approved_principal + v_service_charge,
      2
    );

  insert into public.loans(
    loan_application_id,
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
  )
  values (
    p_loan_application_id,
    v_application.applicant_profile_id,
    v_application.member_id,
    v_approved_principal,
    v_application.service_charge_rate,
    v_service_charge,
    v_total_repayment,
    v_application.term_months,
    'active',
    v_disbursed_at,
    ((v_disbursed_at::date)
      + make_interval(months => v_application.term_months))::date
  )
  returning id, maturity_date
  into v_loan_id, v_maturity_date;

  v_disbursement_transaction_id :=
    private.post_balanced_transaction(
      'loan_disbursement'::public.transaction_type,
      v_application.applicant_profile_id,
      v_application.member_id,
      v_total_repayment,
      'loan',
      v_loan_id,
      'Loan disbursement',
      jsonb_build_array(
        jsonb_build_object(
          'account_id', v_receivable_account_id,
          'entry_type', 'debit',
          'amount', v_total_repayment
        ),
        jsonb_build_object(
          'account_id', v_source_account_id,
          'entry_type', 'credit',
          'amount', v_approved_principal
        ),
        jsonb_build_object(
          'account_id', v_service_income_account_id,
          'entry_type', 'credit',
          'amount', v_service_charge
        )
      )
    );

  v_terms := v_application.term_months;

  if v_terms <= 0 then
    raise exception 'Invalid loan term';
  end if;

  v_principal_per_installment :=
    round(v_approved_principal / v_terms, 2);

  v_service_per_installment :=
    round(v_service_charge / v_terms, 2);

  for v_i in 1..v_terms loop

    if v_i < v_terms then
      v_principal_amount := v_principal_per_installment;
      v_service_amount := v_service_per_installment;
    else
      v_principal_amount :=
        round(
          v_approved_principal
          - (v_principal_per_installment * (v_terms - 1)),
          2
        );

      v_service_amount :=
        round(
          v_service_charge
          - (v_service_per_installment * (v_terms - 1)),
          2
        );
    end if;

    v_installment_total :=
      round(v_principal_amount + v_service_amount, 2);

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
    )
    values (
      v_loan_id,
      v_i,
      ((v_disbursed_at::date)
        + make_interval(months => v_i))::date,
      v_principal_amount,
      v_service_amount,
      v_installment_total,
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
  )
  values (
    v_loan_id,
    v_approved_principal,
    v_source_type::text,
    v_disbursement_transaction_id,
    v_actor,
    now(),
    null
  )
  returning id into v_disbursement_id;

  insert into public.audit_logs(
    actor_user_id,
    action,
    entity_type,
    entity_id,
    new_data,
    metadata
  )
  values (
    v_actor,
    'LOAN_DISBURSED',
    'loan',
    v_loan_id,
    jsonb_build_object(
      'loan_application_id', p_loan_application_id,
      'principal', v_approved_principal,
      'service_charge', v_service_charge,
      'total_repayment', v_total_repayment,
      'term_months', v_terms,
      'maturity_date', v_maturity_date
    ),
    jsonb_build_object(
      'transaction_id', v_disbursement_transaction_id,
      'disbursement_id', v_disbursement_id,
      'liquidity_snapshot', v_liquidity
    )
  );

  return jsonb_build_object(
    'loan_id', v_loan_id,
    'loan_number', (
      select l.loan_number
      from public.loans l
      where l.id = v_loan_id
    ),
    'principal', v_approved_principal,
    'service_charge', v_service_charge,
    'total_repayment', v_total_repayment,
    'term_months', v_terms,
    'maturity_date', v_maturity_date,
    'transaction_id', v_disbursement_transaction_id
  );
end;
$$;

revoke all on function public.disburse_loan(uuid, text)
  from public, anon;
grant execute on function public.disburse_loan(uuid, text)
  to authenticated;


-- ============================================================
-- 19. Post verified loan repayment
--
-- p_allocations example:
-- [
--   {
--     "installment_id": "...",
--     "base_amount": 2200,
--     "penalty_amount": 110
--   }
-- ]
--
-- Explicit allocation avoids inventing a hidden payment priority.
-- Base amount updates installment.paid_amount.
-- Penalty amount updates installment.paid_penalty_amount.
-- ============================================================

create or replace function public.post_verified_loan_repayment(
  p_payment_id uuid,
  p_allocations jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_payment record;
  v_loan_id uuid;
  v_loan record;
  v_source_type public.account_type_code;
  v_source_account_id uuid;
  v_receivable_account_id uuid;
  v_penalty_income_account_id uuid;
  v_transaction_id uuid;
  v_total_base numeric(18,2);
  v_total_penalty numeric(18,2);
  v_total numeric(18,2);
  v_payment_amount numeric(18,2);
  v_target_count integer;
  v_unique_target_count integer;
  v_row record;
  v_remaining_base numeric(18,2);
  v_remaining_penalty numeric(18,2);
  v_new_base numeric(18,2);
  v_new_penalty numeric(18,2);
  v_json_allocations jsonb;
begin
  if v_actor is null then
    raise exception 'Not authenticated';
  end if;

  if not private.current_user_has_permission('loan.repay')
     and not private.current_user_has_permission('payment.verify') then
    raise exception 'Unauthorized';
  end if;

  if p_allocations is null
     or jsonb_typeof(p_allocations) <> 'array'
     or jsonb_array_length(p_allocations) = 0 then
    raise exception 'Repayment allocations are required';
  end if;

  select
    p.id,
    p.payer_profile_id,
    p.amount,
    p.status,
    p.purpose_type,
    p.purpose_id,
    pm.code as payment_method_code
  into v_payment
  from public.payments p
  join public.payment_methods pm
    on pm.id = p.payment_method_id
  where p.id = p_payment_id
  for update;

  if not found then
    raise exception 'Payment not found';
  end if;

  if v_payment.status <> 'verified' then
    raise exception 'Payment must be verified before loan repayment posting';
  end if;

  if v_payment.purpose_type <> 'loan_repayment' then
    raise exception 'Payment is not a loan repayment';
  end if;

  v_loan_id := v_payment.purpose_id;

  if v_loan_id is null then
    raise exception 'Loan repayment payment is missing loan reference';
  end if;

  select
    l.id,
    l.loan_number,
    l.borrower_profile_id,
    l.member_id,
    l.status
  into v_loan
  from public.loans l
  where l.id = v_loan_id
  for update;

  if not found then
    raise exception 'Loan not found';
  end if;

  if v_payment.payer_profile_id <> v_loan.borrower_profile_id then
    raise exception 'Payment payer does not match loan borrower';
  end if;

  if exists (
    select 1
    from public.loan_repayment_allocations lra
    where lra.payment_id = p_payment_id
  ) then
    raise exception 'This payment has already been posted to a loan';
  end if;

  v_payment_amount := round(v_payment.amount, 2);

  -- Validate JSON shape and target uniqueness.
  select
    count(*),
    count(distinct (x.installment_id))
  into
    v_target_count,
    v_unique_target_count
  from jsonb_to_recordset(p_allocations)
  as x(
    installment_id uuid,
    base_amount numeric,
    penalty_amount numeric
  );

  if v_target_count <> v_unique_target_count then
    raise exception 'A repayment allocation cannot contain the same installment twice';
  end if;

  select
    coalesce(sum(round(x.base_amount, 2)), 0)::numeric(18,2),
    coalesce(sum(round(x.penalty_amount, 2)), 0)::numeric(18,2)
  into
    v_total_base,
    v_total_penalty
  from jsonb_to_recordset(p_allocations)
  as x(
    installment_id uuid,
    base_amount numeric,
    penalty_amount numeric
  );

  v_total :=
    round(v_total_base + v_total_penalty, 2);

  if v_total <> v_payment_amount then
    raise exception
      'Allocation total % does not equal payment amount %',
      v_total,
      v_payment_amount;
  end if;

  -- Lock all affected installments in a deterministic order.
  perform 1
  from public.loan_installments li
  where li.id in (
    select x.installment_id
    from jsonb_to_recordset(p_allocations)
    as x(installment_id uuid, base_amount numeric, penalty_amount numeric)
  )
  order by li.id
  for update;

  -- Validate each allocation.
  for v_row in
    select
      x.installment_id,
      round(x.base_amount, 2) as base_amount,
      round(x.penalty_amount, 2) as penalty_amount
    from jsonb_to_recordset(p_allocations)
    as x(
      installment_id uuid,
      base_amount numeric,
      penalty_amount numeric
    )
    order by x.installment_id
  loop

    select
      greatest(li.total_due - li.paid_amount, 0)::numeric(18,2),
      greatest(li.late_penalty_amount - li.paid_penalty_amount, 0)::numeric(18,2)
    into
      v_remaining_base,
      v_remaining_penalty
    from public.loan_installments li
    where li.id = v_row.installment_id
      and li.loan_id = v_loan_id;

    if not found then
      raise exception 'Installment does not belong to this loan';
    end if;

    if v_row.base_amount < 0
       or v_row.penalty_amount < 0
       or (v_row.base_amount + v_row.penalty_amount) <= 0 then
      raise exception 'Invalid installment allocation';
    end if;

    if v_row.base_amount > v_remaining_base then
      raise exception 'Base repayment exceeds installment outstanding amount';
    end if;

    if v_row.penalty_amount > v_remaining_penalty then
      raise exception 'Penalty repayment exceeds penalty outstanding amount';
    end if;
  end loop;

  v_source_type := case
    when v_payment.payment_method_code = 'wallet'
      then 'wallet'::public.account_type_code
    when v_payment.payment_method_code = 'bank_transfer'
      then 'bank'::public.account_type_code
    when v_payment.payment_method_code = 'cash'
      then 'cash'::public.account_type_code
    else null
  end;

  if v_source_type is null then
    raise exception 'Unsupported loan repayment payment method';
  end if;

  v_source_account_id :=
    private.system_account_id(v_source_type);

  v_receivable_account_id :=
    private.system_account_id('loan_receivable'::public.account_type_code);

  v_penalty_income_account_id :=
    private.system_account_id('penalty_income'::public.account_type_code);

  if v_source_account_id is null
     or v_receivable_account_id is null
     or v_penalty_income_account_id is null then
    raise exception 'Loan repayment accounting accounts are not configured';
  end if;

  if private.account_balance(v_source_account_id) < v_payment_amount then
    raise exception 'Repayment source account has insufficient balance';
  end if;

  v_transaction_id :=
    private.post_balanced_transaction(
      'loan_repayment'::public.transaction_type,
      v_loan.borrower_profile_id,
      v_loan.member_id,
      v_payment_amount,
      'loan_repayment',
      p_payment_id,
      'Loan repayment',
      case
        when v_total_penalty > 0 then
          jsonb_build_array(
            jsonb_build_object(
              'account_id', v_source_account_id,
              'entry_type', 'debit',
              'amount', v_payment_amount
            ),
            jsonb_build_object(
              'account_id', v_receivable_account_id,
              'entry_type', 'credit',
              'amount', v_total_base
            ),
            jsonb_build_object(
              'account_id', v_penalty_income_account_id,
              'entry_type', 'credit',
              'amount', v_total_penalty
            )
          )
        else
          jsonb_build_array(
            jsonb_build_object(
              'account_id', v_source_account_id,
              'entry_type', 'debit',
              'amount', v_payment_amount
            ),
            jsonb_build_object(
              'account_id', v_receivable_account_id,
              'entry_type', 'credit',
              'amount', v_total_base
            )
          )
      end
    );

  insert into public.loan_repayment_allocations(
    payment_id,
    loan_id,
    installment_id,
    allocated_base_amount,
    allocated_penalty_amount,
    transaction_id
  )
  select
    p_payment_id,
    v_loan_id,
    x.installment_id,
    round(x.base_amount, 2),
    round(x.penalty_amount, 2),
    v_transaction_id
  from jsonb_to_recordset(p_allocations)
  as x(
    installment_id uuid,
    base_amount numeric,
    penalty_amount numeric
  );

  update public.loan_installments li
  set
    paid_amount = round(
      li.paid_amount
      + x.base_amount,
      2
    ),
    paid_penalty_amount = round(
      li.paid_penalty_amount
      + x.penalty_amount,
      2
    ),
    status = case
      when round(li.paid_amount + x.base_amount, 2) >= li.total_due
           and round(
             li.paid_penalty_amount + x.penalty_amount,
             2
           ) >= li.late_penalty_amount
        then 'paid'::public.installment_status
      when li.due_date < current_date
        then 'overdue'::public.installment_status
      else 'pending'::public.installment_status
    end,
    updated_at = now()
  from (
    select
      x.installment_id,
      sum(round(x.base_amount, 2)) as base_amount,
      sum(round(x.penalty_amount, 2)) as penalty_amount
    from jsonb_to_recordset(p_allocations)
    as x(
      installment_id uuid,
      base_amount numeric,
      penalty_amount numeric
    )
    group by x.installment_id
  ) x
  where li.id = x.installment_id;

  if not exists (
    select 1
    from public.loan_installments li
    where li.loan_id = v_loan_id
      and (
        li.paid_amount < li.total_due
        or li.paid_penalty_amount < li.late_penalty_amount
      )
  ) then
    update public.loans
    set
      status = 'paid',
      updated_at = now()
    where id = v_loan_id;

    update public.loan_guarantors
    set
      status = 'released',
      released_at = now()
    where loan_application_id = (
      select l.loan_application_id
      from public.loans l
      where l.id = v_loan_id
    )
      and status = 'accepted';
  elsif exists (
    select 1
    from public.loan_installments li
    where li.loan_id = v_loan_id
      and li.status = 'defaulted'
  ) then
    update public.loans
    set
      status = 'defaulted',
      updated_at = now()
    where id = v_loan_id;
  elsif exists (
    select 1
    from public.loan_installments li
    where li.loan_id = v_loan_id
      and li.status = 'overdue'
  ) then
    update public.loans
    set
      status = 'overdue',
      updated_at = now()
    where id = v_loan_id;
  else
    update public.loans
    set
      status = 'active',
      updated_at = now()
    where id = v_loan_id;
  end if;

  insert into public.audit_logs(
    actor_user_id,
    action,
    entity_type,
    entity_id,
    new_data,
    metadata
  )
  values (
    v_actor,
    'LOAN_REPAYMENT_POSTED',
    'loan',
    v_loan_id,
    jsonb_build_object(
      'payment_id', p_payment_id,
      'base_amount', v_total_base,
      'penalty_amount', v_total_penalty,
      'total_amount', v_payment_amount
    ),
    jsonb_build_object('transaction_id', v_transaction_id)
  );

  return jsonb_build_object(
    'loan_id', v_loan_id,
    'payment_id', p_payment_id,
    'transaction_id', v_transaction_id,
    'base_amount', v_total_base,
    'penalty_amount', v_total_penalty,
    'total_amount', v_payment_amount
  );
end;
$$;

revoke all on function public.post_verified_loan_repayment(uuid, jsonb)
  from public, anon;
grant execute on function public.post_verified_loan_repayment(uuid, jsonb)
  to authenticated;


-- ============================================================
-- 20. Apply late penalties to overdue installments
--
-- The playbook says 5% of the overdue installment, once.
-- This migration interprets "overdue installment" as the
-- installment's stored total_due, not the remaining balance after
-- partial payment. This policy should be confirmed by the group
-- if partial-before-due payments will be common.
-- ============================================================

create or replace function public.process_overdue_loan_installments()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_rate numeric;
  v_count integer := 0;
  v_penalty numeric(18,2);
  v_transaction_id uuid;
  v_penalty_income_account_id uuid;
  v_receivable_account_id uuid;
  v_item record;
begin
  v_rate :=
    coalesce(
      public.get_active_rule_numeric('loan_late_penalty_rate'),
      0.05
    );

  v_penalty_income_account_id :=
    private.system_account_id(
      'penalty_income'::public.account_type_code
    );

  v_receivable_account_id :=
    private.system_account_id(
      'loan_receivable'::public.account_type_code
    );

  if v_penalty_income_account_id is null
     or v_receivable_account_id is null then
    raise exception 'Penalty accounting accounts are not configured';
  end if;

  for v_item in
    select
      li.id as installment_id,
      li.loan_id,
      li.total_due,
      l.borrower_profile_id,
      l.member_id
    from public.loan_installments li
    join public.loans l
      on l.id = li.loan_id
    where li.due_date < current_date
      and li.paid_amount < li.total_due
      and l.status in ('active', 'overdue', 'defaulted')
    for update of li
  loop

    if exists (
      select 1
      from public.loan_penalties lp
      where lp.installment_id = v_item.installment_id
    ) then
      continue;
    end if;

    v_penalty :=
      round(v_item.total_due * v_rate, 2);

    if v_penalty <= 0 then
      continue;
    end if;

    v_transaction_id :=
      private.post_balanced_transaction(
        'loan_late_penalty'::public.transaction_type,
        v_item.borrower_profile_id,
        v_item.member_id,
        v_penalty,
        'loan_installment',
        v_item.installment_id,
        'Late loan-installment penalty',
        jsonb_build_array(
          jsonb_build_object(
            'account_id', v_receivable_account_id,
            'entry_type', 'debit',
            'amount', v_penalty
          ),
          jsonb_build_object(
            'account_id', v_penalty_income_account_id,
            'entry_type', 'credit',
            'amount', v_penalty
          )
        )
      );

    insert into public.loan_penalties(
      installment_id,
      rate,
      amount,
      transaction_id,
      charged_at
    )
    values (
      v_item.installment_id,
      v_rate,
      v_penalty,
      v_transaction_id,
      now()
    );

    update public.loan_installments
    set
      late_penalty_amount = v_penalty,
      status = 'overdue',
      updated_at = now()
    where id = v_item.installment_id;

    update public.loans
    set
      status = 'overdue',
      updated_at = now()
    where id = v_item.loan_id
      and status = 'active';

    insert into public.audit_logs(
      actor_user_id,
      action,
      entity_type,
      entity_id,
      new_data,
      metadata
    )
    values (
      null,
      'LOAN_LATE_PENALTY_APPLIED',
      'loan_installment',
      v_item.installment_id,
      jsonb_build_object(
        'rate', v_rate,
        'amount', v_penalty
      ),
      jsonb_build_object('transaction_id', v_transaction_id)
    );

    v_count := v_count + 1;
  end loop;

  return jsonb_build_object(
    'processed_installments', v_count,
    'penalty_rate', v_rate
  );
end;
$$;

revoke all on function public.process_overdue_loan_installments()
  from public, anon, authenticated;


-- ============================================================
-- 21. Serious-default processor
--
-- Serious default = unpaid base installment 60 days after due date.
-- ============================================================

create or replace function public.process_serious_loan_defaults()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_default_days bigint;
  v_count integer := 0;
  v_item record;
begin
  v_default_days :=
    coalesce(
      public.get_active_rule_numeric('serious_default_days'),
      60
    )::bigint;

  for v_item in
    select
      li.id as installment_id,
      li.loan_id,
      l.borrower_profile_id
    from public.loan_installments li
    join public.loans l
      on l.id = li.loan_id
    where li.due_date <= current_date - v_default_days
      and li.paid_amount < li.total_due
      and l.status in ('active', 'overdue', 'defaulted')
    for update of li
  loop

    update public.loan_installments
    set
      status = 'defaulted',
      updated_at = now()
    where id = v_item.installment_id;

    update public.loans
    set
      status = 'defaulted',
      updated_at = now()
    where id = v_item.loan_id;

    if not exists (
      select 1
      from public.loan_default_events lde
      where lde.loan_id = v_item.loan_id
        and lde.installment_id = v_item.installment_id
        and lde.event_type = 'DEFAULT_NOTICE'
    ) then

      insert into public.loan_default_events(
        loan_id,
        installment_id,
        event_type,
        event_date,
        notes,
        created_by
      )
      values (
        v_item.loan_id,
        v_item.installment_id,
        'DEFAULT_NOTICE',
        now(),
        'Installment reached the serious-default threshold.',
        null
      );

      insert into public.audit_logs(
        actor_user_id,
        action,
        entity_type,
        entity_id,
        new_data
      )
      values (
        null,
        'LOAN_DEFAULTED',
        'loan',
        v_item.loan_id,
        jsonb_build_object(
          'installment_id', v_item.installment_id,
          'default_days', v_default_days
        )
      );

      v_count := v_count + 1;
    end if;

    if not exists (
      select 1
      from public.loan_default_events lde
      where lde.loan_id = v_item.loan_id
        and lde.event_type = 'BORROWING_SUSPENDED'
    ) then

      insert into public.loan_default_events(
        loan_id,
        installment_id,
        event_type,
        event_date,
        notes,
        created_by
      )
      values (
        v_item.loan_id,
        v_item.installment_id,
        'BORROWING_SUSPENDED',
        now(),
        'Borrower is temporarily ineligible for another loan because of serious default.',
        null
      );
    end if;

    if exists (
      select 1
      from public.loan_guarantors lg
      where lg.loan_application_id = (
        select l.loan_application_id
        from public.loans l
        where l.id = v_item.loan_id
      )
        and lg.status = 'accepted'
    )
    and not exists (
      select 1
      from public.loan_default_events lde
      where lde.loan_id = v_item.loan_id
        and lde.event_type = 'GUARANTOR_NOTICE'
    ) then

      insert into public.loan_default_events(
        loan_id,
        installment_id,
        event_type,
        event_date,
        notes,
        created_by
      )
      values (
        v_item.loan_id,
        v_item.installment_id,
        'GUARANTOR_NOTICE',
        now(),
        'Guarantor must be notified of serious default.',
        null
      );
    end if;
  end loop;

  return jsonb_build_object(
    'defaulted_installments', v_count,
    'default_threshold_days', v_default_days
  );
end;
$$;

revoke all on function public.process_serious_loan_defaults()
  from public, anon, authenticated;


-- ============================================================
-- 22. Optional loan extension request
--
-- Request only. Schedule mutation is intentionally not automatic
-- because the playbook does not define extension rescheduling.
-- ============================================================

create or replace function public.request_loan_extension(
  p_loan_id uuid,
  p_reason text,
  p_requested_new_due_date date default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_loan record;
  v_request_id uuid;
begin
  if v_actor is null then
    raise exception 'Not authenticated';
  end if;

  if not private.current_user_has_permission('loan.repay') then
    raise exception 'Unauthorized';
  end if;

  if p_reason is null or length(trim(p_reason)) < 10 then
    raise exception 'Extension reason must be at least 10 characters';
  end if;

  select
    l.id,
    l.borrower_profile_id,
    l.status
  into v_loan
  from public.loans l
  where l.id = p_loan_id
    and l.borrower_profile_id = v_actor
  for update;

  if not found then
    raise exception 'Loan not found or unauthorized';
  end if;

  if v_loan.status in ('paid', 'cancelled', 'defaulted') then
    raise exception 'Extension cannot be requested for this loan';
  end if;

  if exists (
    select 1
    from public.loan_installments li
    where li.loan_id = p_loan_id
      and li.due_date <= current_date - coalesce(
        public.get_active_rule_numeric('serious_default_days'),
        60
      )::integer
      and li.paid_amount < li.total_due
  ) then
    raise exception 'Extension must be requested before serious default';
  end if;

  insert into public.loan_extension_requests(
    loan_id,
    requested_by,
    reason,
    requested_new_due_date,
    status
  )
  values (
    p_loan_id,
    v_actor,
    trim(p_reason),
    p_requested_new_due_date,
    'pending'
  )
  returning id into v_request_id;

  insert into public.audit_logs(
    actor_user_id,
    action,
    entity_type,
    entity_id,
    new_data
  )
  values (
    v_actor,
    'LOAN_EXTENSION_REQUESTED',
    'loan',
    p_loan_id,
    jsonb_build_object(
      'extension_request_id', v_request_id,
      'requested_new_due_date', p_requested_new_due_date
    )
  );

  return jsonb_build_object(
    'extension_request_id', v_request_id,
    'status', 'pending'
  );
end;
$$;

revoke all on function public.request_loan_extension(uuid, text, date)
  from public, anon;
grant execute on function public.request_loan_extension(uuid, text, date)
  to authenticated;


-- ============================================================
-- 23. Read RPCs
-- ============================================================

create or replace function public.get_my_loan_applications()
returns jsonb
language sql
stable
security invoker
as $$
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', la.id,
        'application_number', la.application_number,
        'borrower_type', lp.borrower_type,
        'requested_amount', la.requested_amount,
        'purpose', la.purpose,
        'eligibility_status', la.eligibility_status,
        'status', la.status,
        'submitted_at', la.submitted_at,
        'eligibility_snapshot', la.eligibility_snapshot
      )
      order by la.created_at desc
    ),
    '[]'::jsonb
  )
  from public.loan_applications la
  join public.loan_products lp
    on lp.id = la.loan_product_id
  where la.applicant_profile_id = (select auth.uid());
$$;

revoke all on function public.get_my_loan_applications()
  from public, anon;
grant execute on function public.get_my_loan_applications()
  to authenticated;


create or replace function public.get_my_loans()
returns jsonb
language sql
stable
security invoker
as $$
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', l.id,
        'loan_number', l.loan_number,
        'principal', l.principal,
        'service_charge_rate', l.service_charge_rate,
        'service_charge_amount', l.service_charge_amount,
        'total_repayment', l.total_repayment,
        'status', l.status,
        'disbursed_at', l.disbursed_at,
        'maturity_date', l.maturity_date,
        'total_paid', coalesce((
          select sum(lra.allocated_base_amount)
          from public.loan_repayment_allocations lra
          where lra.loan_id = l.id
        ), 0),
        'total_penalties_paid', coalesce((
          select sum(lra.allocated_penalty_amount)
          from public.loan_repayment_allocations lra
          where lra.loan_id = l.id
        ), 0),
        'outstanding_base', greatest(
          l.total_repayment - coalesce((
            select sum(lra.allocated_base_amount)
            from public.loan_repayment_allocations lra
            where lra.loan_id = l.id
          ), 0),
          0
        )
      )
      order by l.created_at desc
    ),
    '[]'::jsonb
  )
  from public.loans l
  where l.borrower_profile_id = (select auth.uid());
$$;

revoke all on function public.get_my_loans()
  from public, anon;
grant execute on function public.get_my_loans()
  to authenticated;


create or replace function public.get_loan_application_detail(
  p_application_id uuid
)
returns jsonb
language plpgsql
stable
security invoker
as $$
declare
  v_result jsonb;
begin
  select jsonb_build_object(
    'id', la.id,
    'application_number', la.application_number,
    'applicant_profile_id', la.applicant_profile_id,
    'member_id', la.member_id,
    'requested_amount', la.requested_amount,
    'approved_amount', la.approved_amount,
    'purpose', la.purpose,
    'status', la.status,
    'eligibility_status', la.eligibility_status,
    'eligibility_snapshot', la.eligibility_snapshot,
    'submitted_at', la.submitted_at,
    'product', jsonb_build_object(
      'code', lp.code,
      'name', lp.name,
      'borrower_type', lp.borrower_type,
      'service_charge_rate', lp.service_charge_rate,
      'max_amount', lp.max_amount,
      'term_months', lp.term_months
    ),
    'guarantor', (
      select jsonb_build_object(
        'id', lg.id,
        'guarantor_member_id', lg.guarantor_member_id,
        'status', lg.status,
        'guaranteed_amount', lg.guaranteed_amount,
        'potential_responsibility', lg.potential_responsibility,
        'requested_at', lg.requested_at,
        'approved_at', lg.approved_at,
        'rejected_at', lg.rejected_at,
        'released_at', lg.released_at
      )
      from public.loan_guarantors lg
      where lg.loan_application_id = la.id
    ),
    'approvals', (
      select coalesce(
        jsonb_agg(
          jsonb_build_object(
            'approver_profile_id', lapp.approver_profile_id,
            'decision', lapp.decision,
            'comment', lapp.comment,
            'decided_at', lapp.decided_at
          )
          order by lapp.decided_at
        ),
        '[]'::jsonb
      )
      from public.loan_approvals lapp
      where lapp.loan_application_id = la.id
    ),
    'eligibility_checks', (
      select coalesce(
        jsonb_agg(
          jsonb_build_object(
            'check_code', lec.check_code,
            'result', lec.result,
            'value', lec.value,
            'reason', lec.reason,
            'checked_at', lec.checked_at,
            'evaluation_run_id', lec.evaluation_run_id
          )
          order by lec.checked_at desc
        ),
        '[]'::jsonb
      )
      from public.loan_eligibility_checks lec
      where lec.loan_application_id = la.id
    )
  )
  into v_result
  from public.loan_applications la
  join public.loan_products lp
    on lp.id = la.loan_product_id
  where la.id = p_application_id;

  return v_result;
end;
$$;

revoke all on function public.get_loan_application_detail(uuid)
  from public, anon;
grant execute on function public.get_loan_application_detail(uuid)
  to authenticated;


create or replace function public.get_admin_liquidity_snapshot()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not private.current_user_has_permission('loan.review')
     and not private.current_user_has_permission('reports.read') then
    raise exception 'Unauthorized';
  end if;

  return private.loan_liquidity_snapshot();
end;
$$;

revoke all on function public.get_admin_liquidity_snapshot()
  from public, anon;
grant execute on function public.get_admin_liquidity_snapshot()
  to authenticated;


-- ============================================================
-- 24. RLS for new tables
-- ============================================================

alter table public.loan_repayment_allocations enable row level security;
alter table public.savings_security_locks enable row level security;
alter table public.loan_extension_requests enable row level security;
alter table public.loan_recovery_events enable row level security;


create policy "loan_repayment_allocations_select_borrower_or_admin"
on public.loan_repayment_allocations
for select
to authenticated
using (
  private.current_user_is_admin()
  or exists (
    select 1
    from public.loans l
    where l.id = loan_id
      and l.borrower_profile_id = (select auth.uid())
  )
);


create policy "savings_security_locks_select_member_or_admin"
on public.savings_security_locks
for select
to authenticated
using (
  private.current_user_is_admin()
  or exists (
    select 1
    from public.members m
    where m.id = member_id
      and m.profile_id = (select auth.uid())
  )
);


create policy "loan_extension_requests_select_borrower_or_admin"
on public.loan_extension_requests
for select
to authenticated
using (
  private.current_user_is_admin()
  or exists (
    select 1
    from public.loans l
    where l.id = loan_id
      and l.borrower_profile_id = (select auth.uid())
  )
);


create policy "loan_recovery_events_select_borrower_or_admin"
on public.loan_recovery_events
for select
to authenticated
using (
  private.current_user_is_admin()
  or exists (
    select 1
    from public.loans l
    where l.id = loan_id
      and l.borrower_profile_id = (select auth.uid())
  )
);


-- ============================================================
-- 25. Tighten direct table grants
--
-- Clients may read loan data according to RLS.
-- Sensitive mutations go through RPCs.
-- ============================================================

revoke insert, update, delete
on public.loan_applications
from authenticated;

revoke insert, update, delete
on public.loan_eligibility_checks
from authenticated;

revoke insert, update, delete
on public.loans
from authenticated;

revoke insert, update, delete
on public.loan_guarantors
from authenticated;

revoke insert, update, delete
on public.loan_approvals
from authenticated;

revoke insert, update, delete
on public.loan_installments
from authenticated;

revoke insert, update, delete
on public.loan_penalties
from authenticated;

revoke insert, update, delete
on public.loan_default_events
from authenticated;

revoke insert, update, delete
on public.loan_disbursements
from authenticated;

revoke insert, update, delete
on public.loan_repayment_allocations
from authenticated;

revoke insert, update, delete
on public.savings_security_locks
from authenticated;

revoke insert, update, delete
on public.loan_extension_requests
from authenticated;

revoke insert, update, delete
on public.loan_recovery_events
from authenticated;


-- Keep reads.
grant select on public.loan_applications to authenticated;
grant select on public.loan_eligibility_checks to authenticated;
grant select on public.loans to authenticated;
grant select on public.loan_guarantors to authenticated;
grant select on public.loan_approvals to authenticated;
grant select on public.loan_installments to authenticated;
grant select on public.loan_penalties to authenticated;
grant select on public.loan_default_events to authenticated;
grant select on public.loan_disbursements to authenticated;
grant select on public.loan_repayment_allocations to authenticated;
grant select on public.savings_security_locks to authenticated;
grant select on public.loan_extension_requests to authenticated;
grant select on public.loan_recovery_events to authenticated;


-- ============================================================
-- 26. Existing loan RLS hardening
--
-- Existing policies can remain for SELECT.
-- Do not create direct-write policies because grants have been
-- revoked for authenticated.
-- ============================================================

-- Remove unsafe direct mutation policies if they exist.
drop policy if exists "loan_applications_insert_own"
  on public.loan_applications;

drop policy if exists "loan_applications_update_own_draft_or_admin"
  on public.loan_applications;

drop policy if exists "loan_eligibility_checks_insert_admin"
  on public.loan_eligibility_checks;

drop policy if exists "loan_guarantors_insert_borrower_or_admin"
  on public.loan_guarantors;

drop policy if exists "loan_guarantors_update_guarantor_or_admin"
  on public.loan_guarantors;

drop policy if exists "loan_approvals_insert_admin"
  on public.loan_approvals;


-- ============================================================
-- 27. Add useful indexes
-- ============================================================

create index if not exists loan_approvals_application_decision_idx
  on public.loan_approvals(loan_application_id, decision, decided_at desc);

create index if not exists loan_default_events_lookup_idx
  on public.loan_default_events(loan_id, installment_id, event_type);

create index if not exists loan_disbursements_released_idx
  on public.loan_disbursements(released_at desc);

create index if not exists loan_installments_loan_status_due_idx
  on public.loan_installments(loan_id, status, due_date);

create index if not exists loan_installments_unpaid_due_idx
  on public.loan_installments(due_date, loan_id)
  where paid_amount < total_due;


-- ============================================================
-- 28. Improve basic loan eligibility helper
-- ============================================================

create or replace function public.is_member_eligible_for_loan(p_member_id uuid)
returns boolean
language sql
stable
as $$
  select
    exists (
      select 1
      from public.members m
      where m.id = p_member_id
        and m.status = 'active'
    )
    and (
      select count(*)
      from public.savings_obligations so
      where so.member_id = p_member_id
        and so.status = 'paid'
    ) >= 2
    and not exists (
      select 1
      from public.loan_installments li
      join public.loans l
        on l.id = li.loan_id
      where l.member_id = p_member_id
        and li.paid_amount < li.total_due
        and li.due_date < current_date
        and l.status in ('active', 'overdue', 'defaulted')
    )
    and not exists (
      select 1
      from public.savings_obligations so
      where so.member_id = p_member_id
        and so.period_year = extract(year from current_date)::integer
        and so.period_month = extract(month from current_date)::integer
        and so.due_date <= current_date
        and so.paid_amount < so.required_amount
    );
$$;

revoke all on function public.is_member_eligible_for_loan(uuid)
  from public, anon;
grant execute on function public.is_member_eligible_for_loan(uuid)
  to authenticated;


-- ============================================================
-- 29. Scheduled jobs
--
-- Supabase Cron / pg_cron.
--
-- These are intentionally daily and idempotent.
-- The functions themselves are authoritative.
-- ============================================================

do $cron$
begin
  if to_regnamespace('cron') is not null then

    perform cron.schedule(
      'unity-finance-loan-overdue-processor',
      '15 0 * * *',
      $$select public.process_overdue_loan_installments();$$
    );

    perform cron.schedule(
      'unity-finance-loan-default-processor',
      '30 0 * * *',
      $$select public.process_serious_loan_defaults();$$
    );

  end if;
end;
$cron$;


commit;
