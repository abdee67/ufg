-- ===========================================================================
-- Unity Finance Group - Savings Feature Incremental Migration
-- Safe to apply on top of Unity_Finance_MVP_Supabase_Schema.sql and Auth Migration
-- ===========================================================================

begin;

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- 0. Ensure private schema exists
-- ---------------------------------------------------------------------------
create schema if not exists private;

-- ---------------------------------------------------------------------------
-- 1. Enums & Types Updates (Idempotent)
-- ---------------------------------------------------------------------------
do $$ begin
  alter type public.withdrawal_status add value if not exists 'delayed';
exception when duplicate_object then null; end $$;

-- ---------------------------------------------------------------------------
-- 2. Savings Security Locks Table (For Loan Collateral)
-- ---------------------------------------------------------------------------
create table if not exists public.savings_security_locks (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id) on delete restrict,
  loan_id uuid references public.loans(id) on delete restrict,
  amount numeric(18,2) not null check (amount > 0),
  status text not null default 'active' check (status in ('active', 'released')),
  created_at timestamptz not null default now(),
  released_at timestamptz
);

create index if not exists idx_savings_security_locks_member
on public.savings_security_locks(member_id, status);

alter table public.savings_security_locks enable row level security;

-- RLS on savings_security_locks
drop policy if exists "savings_security_locks_select_own_or_admin" on public.savings_security_locks;
create policy "savings_security_locks_select_own_or_admin"
on public.savings_security_locks for select
to authenticated
using (
  private.current_user_is_admin()
  or member_id = (select private.current_member_id())
);

drop policy if exists "savings_security_locks_manage_admin" on public.savings_security_locks;
create policy "savings_security_locks_manage_admin"
on public.savings_security_locks for all
to authenticated
using (private.current_user_is_admin())
with check (private.current_user_is_admin());

grant select on public.savings_security_locks to authenticated;

-- ---------------------------------------------------------------------------
-- 3. Ensure System and Member Accounts Exist
-- ---------------------------------------------------------------------------

-- Helper: Ensure group account exists for Cash/Bank and Penalty Income
create or replace function private.get_or_create_group_account(p_account_type_code public.account_type_code)
returns uuid
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_type_id uuid;
  v_account_id uuid;
begin
  select id into v_type_id from public.account_types where code = p_account_type_code;
  if v_type_id is null then
    raise exception 'Account type % does not exist.', p_account_type_code;
  end if;

  select id into v_account_id
  from public.accounts
  where account_type_id = v_type_id
    and owner_profile_id is null
    and owner_member_id is null
  limit 1;

  if v_account_id is null then
    insert into public.accounts (account_type_id, currency, status)
    values (v_type_id, 'ETB', 'active')
    returning id into v_account_id;
  end if;

  return v_account_id;
end;
$$;

-- Helper: Ensure active member has a member_savings account & savings_accounts row
create or replace function private.ensure_member_savings_account(p_member_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_member record;
  v_type_id uuid;
  v_account_id uuid;
  v_savings_acc_id uuid;
begin
  select * into v_member from public.members where id = p_member_id;
  if v_member is null then
    raise exception 'Member % does not exist.', p_member_id;
  end if;

  select id into v_type_id from public.account_types where code = 'member_savings';
  if v_type_id is null then
    raise exception 'Account type member_savings does not exist.';
  end if;

  -- Check existing account
  select id into v_account_id
  from public.accounts
  where owner_member_id = p_member_id
    and account_type_id = v_type_id
  limit 1;

  if v_account_id is null then
    insert into public.accounts (account_type_id, owner_profile_id, owner_member_id, currency, status)
    values (v_type_id, v_member.profile_id, p_member_id, 'ETB', 'active')
    returning id into v_account_id;
  end if;

  -- Ensure savings_accounts row
  select id into v_savings_acc_id
  from public.savings_accounts
  where member_id = p_member_id
  limit 1;

  if v_savings_acc_id is null then
    insert into public.savings_accounts (member_id, account_id, status)
    values (p_member_id, v_account_id, 'active')
    returning id into v_savings_acc_id;
  end if;

  return v_account_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- 4. Authoritative Ledger Calculation Functions
-- ---------------------------------------------------------------------------

-- 4.1 Total Posted Savings Balance for a Member (Credits minus Debits)
create or replace function private.get_member_savings_balance(p_member_id uuid)
returns numeric(18,2)
language plpgsql
stable
security definer
set search_path = public, private
as $$
declare
  v_account_id uuid;
  v_balance numeric(18,2);
begin
  select a.id into v_account_id
  from public.accounts a
  join public.account_types at on at.id = a.account_type_id
  where a.owner_member_id = p_member_id
    and at.code = 'member_savings'
  limit 1;

  if v_account_id is null then
    return 0.00;
  end if;

  select coalesce(sum(
    case
      when te.entry_type = 'credit' then te.amount
      when te.entry_type = 'debit' then -te.amount
      else 0
    end
  ), 0)::numeric(18,2)
  into v_balance
  from public.transaction_entries te
  join public.transactions t on t.id = te.transaction_id
  where te.account_id = v_account_id
    and t.transaction_status = 'posted';

  return coalesce(v_balance, 0.00);
end;
$$;

-- 4.2 Total Active Secured Savings for a Member
create or replace function private.get_member_secured_savings(p_member_id uuid)
returns numeric(18,2)
language sql
stable
security definer
set search_path = public, private
as $$
  select coalesce(sum(amount), 0)::numeric(18,2)
  from public.savings_security_locks
  where member_id = p_member_id
    and status = 'active';
$$;

-- 4.3 Total Available Savings for Withdrawal
create or replace function private.get_member_available_savings(p_member_id uuid)
returns numeric(18,2)
language sql
stable
security definer
set search_path = public, private
as $$
  select greatest(
    private.get_member_savings_balance(p_member_id) - private.get_member_secured_savings(p_member_id),
    0.00
  )::numeric(18,2);
$$;

-- ---------------------------------------------------------------------------
-- 5. Member RPCs (Exposed to Flutter)
-- ---------------------------------------------------------------------------

-- 5.1 Get My Savings Summary
create or replace function public.get_my_savings_summary()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, private
as $$
declare
  v_member_id uuid;
  v_total_savings numeric(18,2);
  v_secured_savings numeric(18,2);
  v_available_savings numeric(18,2);
  v_account_status text;
  v_curr_year int;
  v_curr_month int;
  v_obligation record;
  v_curr_obligation jsonb := null;
begin
  v_member_id := private.current_member_id();
  if v_member_id is null then
    raise exception 'No active membership found for current user.';
  end if;

  v_total_savings := private.get_member_savings_balance(v_member_id);
  v_secured_savings := private.get_member_secured_savings(v_member_id);
  v_available_savings := private.get_member_available_savings(v_member_id);

  select status into v_account_status
  from public.savings_accounts
  where member_id = v_member_id;

  v_account_status := coalesce(v_account_status, 'active');

  v_curr_year := extract(year from current_date)::int;
  v_curr_month := extract(month from current_date)::int;

  select * into v_obligation
  from public.savings_obligations
  where member_id = v_member_id
    and period_year = v_curr_year
    and period_month = v_curr_month
  limit 1;

  if v_obligation is not null then
    v_curr_obligation := jsonb_build_object(
      'id', v_obligation.id,
      'period_year', v_obligation.period_year,
      'period_month', v_obligation.period_month,
      'required_amount', v_obligation.required_amount,
      'due_date', v_obligation.due_date,
      'paid_amount', v_obligation.paid_amount,
      'late_penalty_amount', v_obligation.late_penalty_amount,
      'status', v_obligation.status,
      'total_due', (v_obligation.required_amount - v_obligation.paid_amount + v_obligation.late_penalty_amount)
    );
  end if;

  return jsonb_build_object(
    'member_id', v_member_id,
    'total_savings', v_total_savings,
    'secured_savings', v_secured_savings,
    'available_to_withdraw', v_available_savings,
    'savings_account_status', v_account_status,
    'current_obligation', v_curr_obligation
  );
end;
$$;

grant execute on function public.get_my_savings_summary() to authenticated;

-- 5.2 Get My Savings Obligations
create or replace function public.get_my_savings_obligations()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, private
as $$
declare
  v_member_id uuid;
  v_result jsonb;
begin
  v_member_id := private.current_member_id();
  if v_member_id is null then
    raise exception 'No active membership found for current user.';
  end if;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', so.id,
      'period_year', so.period_year,
      'period_month', so.period_month,
      'required_amount', so.required_amount,
      'due_date', so.due_date,
      'paid_amount', so.paid_amount,
      'late_penalty_amount', so.late_penalty_amount,
      'status', so.status,
      'total_due', (so.required_amount - so.paid_amount + so.late_penalty_amount),
      'created_at', so.created_at,
      'updated_at', so.updated_at
    ) order by so.due_date desc
  ), '[]'::jsonb)
  into v_result
  from public.savings_obligations so
  where so.member_id = v_member_id;

  return v_result;
end;
$$;

grant execute on function public.get_my_savings_obligations() to authenticated;

-- 5.3 Get My Savings History (Combined Contributions & Withdrawals)
create or replace function public.get_my_savings_history()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, private
as $$
declare
  v_member_id uuid;
  v_result jsonb;
begin
  v_member_id := private.current_member_id();
  if v_member_id is null then
    raise exception 'No active membership found for current user.';
  end if;

  with history_items as (
    -- Contributions
    select
      sc.id as id,
      t.reference_number as reference,
      'contribution' as item_type,
      sc.contribution_type as sub_type,
      sc.amount as amount,
      true as is_credit,
      'posted' as status,
      'Monthly savings contribution' as description,
      sc.created_at as timestamp
    from public.savings_contributions sc
    left join public.transactions t on t.id = sc.transaction_id
    where sc.member_id = v_member_id

    union all

    -- Withdrawals
    select
      wr.id as id,
      coalesce(t.reference_number, 'WDR-' || substr(wr.id::text, 1, 8)) as reference,
      'withdrawal' as item_type,
      'withdrawal' as sub_type,
      wr.amount as amount,
      false as is_credit,
      wr.status::text as status,
      coalesce(wr.reason, 'Savings withdrawal') as description,
      wr.requested_at as timestamp
    from public.withdrawal_requests wr
    left join public.transactions t on t.source_id = wr.id and t.source_type = 'withdrawal_request'
    where wr.member_id = v_member_id
  )
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', h.id,
      'reference', h.reference,
      'item_type', h.item_type,
      'sub_type', h.sub_type,
      'amount', h.amount,
      'is_credit', h.is_credit,
      'status', h.status,
      'description', h.description,
      'timestamp', h.timestamp
    ) order by h.timestamp desc
  ), '[]'::jsonb)
  into v_result
  from history_items h;

  return v_result;
end;
$$;

grant execute on function public.get_my_savings_history() to authenticated;

-- 5.4 Submit Savings Payment (Member Action)
create or replace function public.submit_savings_payment(
  p_amount numeric,
  p_payment_method_code text,
  p_external_reference text,
  p_payment_proof_path text default null,
  p_obligation_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_user_id uuid;
  v_member_id uuid;
  v_method_id uuid;
  v_payment_id uuid;
  v_ref_number text;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'User is not authenticated.';
  end if;

  v_member_id := private.current_member_id();
  if v_member_id is null then
    raise exception 'Active membership required to make savings payments.';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'Payment amount must be greater than zero.';
  end if;

  select id into v_method_id
  from public.payment_methods
  where code = p_payment_method_code and active = true;

  if v_method_id is null then
    raise exception 'Invalid or inactive payment method: %', p_payment_method_code;
  end if;

  v_ref_number := private.generate_reference('PAY');

  insert into public.payments (
    payer_profile_id,
    payment_method_id,
    reference_number,
    purpose_type,
    purpose_id,
    amount,
    currency,
    status,
    payment_proof_path,
    external_reference,
    submitted_at
  )
  values (
    v_user_id,
    v_method_id,
    v_ref_number,
    'savings_contribution',
    p_obligation_id,
    p_amount,
    'ETB',
    'pending',
    p_payment_proof_path,
    trim(p_external_reference),
    now()
  )
  returning id into v_payment_id;

  -- Audit
  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    new_data
  )
  values (
    v_user_id,
    'SAVINGS_PAYMENT_SUBMITTED',
    'payments',
    v_payment_id,
    jsonb_build_object(
      'reference_number', v_ref_number,
      'amount', p_amount,
      'obligation_id', p_obligation_id,
      'payment_method', p_payment_method_code
    )
  );

  return jsonb_build_object(
    'payment_id', v_payment_id,
    'reference_number', v_ref_number,
    'amount', p_amount,
    'status', 'pending',
    'submitted_at', now()
  );
end;
$$;

grant execute on function public.submit_savings_payment(numeric, text, text, text, uuid) to authenticated;

-- 5.5 Request Savings Withdrawal (Member Action)
create or replace function public.request_savings_withdrawal(
  p_amount numeric,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_user_id uuid;
  v_member_id uuid;
  v_available numeric(18,2);
  v_req_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'User is not authenticated.';
  end if;

  v_member_id := private.current_member_id();
  if v_member_id is null then
    raise exception 'Active membership required to request withdrawals.';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'Withdrawal amount must be greater than zero.';
  end if;

  v_available := private.get_member_available_savings(v_member_id);
  if p_amount > v_available then
    raise exception 'Requested amount (ETB %) exceeds your available savings (ETB %).', p_amount, v_available;
  end if;

  -- Check for existing pending withdrawal request
  if exists (
    select 1 from public.withdrawal_requests
    where member_id = v_member_id
      and status in ('pending', 'approved', 'delayed')
  ) then
    raise exception 'You already have an active withdrawal request in progress.';
  end if;

  insert into public.withdrawal_requests (
    member_id,
    amount,
    status,
    reason,
    requested_at
  )
  values (
    v_member_id,
    p_amount,
    'pending',
    nullif(trim(p_reason), ''),
    now()
  )
  returning id into v_req_id;

  -- Audit
  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    new_data
  )
  values (
    v_user_id,
    'SAVINGS_WITHDRAWAL_REQUESTED',
    'withdrawal_requests',
    v_req_id,
    jsonb_build_object(
      'member_id', v_member_id,
      'amount', p_amount,
      'reason', p_reason
    )
  );

  return jsonb_build_object(
    'id', v_req_id,
    'member_id', v_member_id,
    'amount', p_amount,
    'status', 'pending',
    'requested_at', now()
  );
end;
$$;

grant execute on function public.request_savings_withdrawal(numeric, text) to authenticated;

-- 5.6 Cancel Withdrawal Request (Member Action)
create or replace function public.cancel_withdrawal_request(p_withdrawal_request_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_user_id uuid;
  v_member_id uuid;
  v_req record;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'User is not authenticated.';
  end if;

  v_member_id := private.current_member_id();
  if v_member_id is null then
    raise exception 'Active membership required.';
  end if;

  select * into v_req
  from public.withdrawal_requests
  where id = p_withdrawal_request_id and member_id = v_member_id
  for update;

  if v_req is null then
    raise exception 'Withdrawal request % not found.', p_withdrawal_request_id;
  end if;

  if v_req.status not in ('pending', 'delayed') then
    raise exception 'Cannot cancel withdrawal in % status.', v_req.status;
  end if;

  update public.withdrawal_requests
  set status = 'cancelled', updated_at = now()
  where id = p_withdrawal_request_id;

  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    new_data
  )
  values (
    v_user_id,
    'SAVINGS_WITHDRAWAL_CANCELLED',
    'withdrawal_requests',
    p_withdrawal_request_id,
    jsonb_build_object('member_id', v_member_id)
  );

  return jsonb_build_object(
    'id', p_withdrawal_request_id,
    'status', 'cancelled'
  );
end;
$$;

grant execute on function public.cancel_withdrawal_request(uuid) to authenticated;

-- 5.7 Get My Withdrawal Requests
create or replace function public.get_my_withdrawal_requests()
returns jsonb
language plpgsql
stable
security definer
set search_path = public, private
as $$
declare
  v_member_id uuid;
  v_result jsonb;
begin
  v_member_id := private.current_member_id();
  if v_member_id is null then
    raise exception 'Active membership required.';
  end if;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', wr.id,
      'member_id', wr.member_id,
      'amount', wr.amount,
      'status', wr.status,
      'reason', wr.reason,
      'requested_at', wr.requested_at,
      'reviewed_at', wr.reviewed_at,
      'paid_at', wr.paid_at,
      'created_at', wr.created_at,
      'updated_at', wr.updated_at
    ) order by wr.requested_at desc
  ), '[]'::jsonb)
  into v_result
  from public.withdrawal_requests wr
  where wr.member_id = v_member_id;

  return v_result;
end;
$$;

grant execute on function public.get_my_withdrawal_requests() to authenticated;

-- ---------------------------------------------------------------------------
-- 6. Admin / System Financial Posting Operations
-- ---------------------------------------------------------------------------

-- 6.1 Post Verified Savings Contribution (Admin / System RPC)
create or replace function public.post_verified_savings_contribution(
  p_payment_id uuid,
  p_reviewer_id uuid default auth.uid()
)
returns jsonb
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_payment record;
  v_member record;
  v_member_acc_id uuid;
  v_savings_acc_id uuid;
  v_bank_acc_id uuid;
  v_txn_id uuid;
  v_txn_ref text;
  v_contrib_id uuid;
  v_obligation record;
  v_min_saving numeric;
  v_contrib_type text := 'mandatory';
begin
  if not private.current_user_is_admin() then
    raise exception 'Unauthorized: Admin privileges required.';
  end if;

  select * into v_payment
  from public.payments
  where id = p_payment_id
  for update;

  if v_payment is null then
    raise exception 'Payment % not found.', p_payment_id;
  end if;

  if v_payment.status != 'verified' then
    raise exception 'Payment % is in % status; only verified payments can be posted.', p_payment_id, v_payment.status;
  end if;

  if v_payment.purpose_type != 'savings_contribution' then
    raise exception 'Payment purpose is %, expected savings_contribution.', v_payment.purpose_type;
  end if;

  -- Check if already posted
  if exists (
    select 1 from public.savings_contributions where payment_id = p_payment_id
  ) then
    raise exception 'Payment % has already been posted to savings.', p_payment_id;
  end if;

  -- Find active member for payer
  select * into v_member
  from public.members
  where profile_id = v_payment.payer_profile_id and status = 'active'
  limit 1;

  if v_member is null then
    raise exception 'Payer is not an active member.';
  end if;

  -- Ensure member financial account & savings account
  v_member_acc_id := private.ensure_member_savings_account(v_member.id);
  select id into v_savings_acc_id from public.savings_accounts where member_id = v_member.id;
  v_bank_acc_id := private.get_or_create_group_account('bank');

  -- Find target obligation
  if v_payment.purpose_id is not null then
    select * into v_obligation
    from public.savings_obligations
    where id = v_payment.purpose_id and member_id = v_member.id
    for update;
  else
    -- Match oldest pending/late obligation
    select * into v_obligation
    from public.savings_obligations
    where member_id = v_member.id
      and status in ('pending', 'late', 'partially_paid')
    order by due_date asc
    limit 1
    for update;
  end if;

  -- Update obligation if matched
  if v_obligation is not null then
    declare
      v_new_paid numeric(18,2) := v_obligation.paid_amount + v_payment.amount;
      v_new_status public.savings_obligation_status;
    begin
      if v_new_paid >= v_obligation.required_amount then
        v_new_status := 'paid';
      else
        v_new_status := 'partially_paid';
      end if;

      update public.savings_obligations
      set
        paid_amount = v_new_paid,
        status = v_new_status,
        updated_at = now()
      where id = v_obligation.id;
    end;
  end if;

  v_min_saving := coalesce(public.get_active_rule_numeric('monthly_min_saving'), 2000.00);
  if v_payment.amount > v_min_saving then
    v_contrib_type := 'voluntary';
  end if;

  -- 1. Create Financial Transaction (Double-entry)
  v_txn_ref := private.generate_reference('TXN');

  insert into public.transactions (
    reference_number,
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
    v_txn_ref,
    'savings_contribution',
    'payment',
    p_payment_id,
    v_member.profile_id,
    v_member.id,
    v_payment.amount,
    'ETB',
    'approved',
    'posted',
    p_reviewer_id,
    p_reviewer_id,
    now(),
    'Member monthly savings contribution'
  )
  returning id into v_txn_id;

  -- 2. Balanced Ledger Entries
  -- Debit Bank Account (Asset increase)
  insert into public.transaction_entries (
    transaction_id,
    account_id,
    entry_type,
    amount
  )
  values (
    v_txn_id,
    v_bank_acc_id,
    'debit',
    v_payment.amount
  );

  -- Credit Member Savings Account (Liability to member increase)
  insert into public.transaction_entries (
    transaction_id,
    account_id,
    entry_type,
    amount
  )
  values (
    v_txn_id,
    v_member_acc_id,
    'credit',
    v_payment.amount
  );

  -- 3. Create Savings Contribution Record
  insert into public.savings_contributions (
    member_id,
    savings_account_id,
    obligation_id,
    amount,
    payment_id,
    transaction_id,
    contribution_type
  )
  values (
    v_member.id,
    v_savings_acc_id,
    case when v_obligation is not null then v_obligation.id else null end,
    v_payment.amount,
    p_payment_id,
    v_txn_id,
    v_contrib_type
  )
  returning id into v_contrib_id;

  -- 4. Audit Log
  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    new_data
  )
  values (
    p_reviewer_id,
    'SAVINGS_CONTRIBUTION_POSTED',
    'savings_contributions',
    v_contrib_id,
    jsonb_build_object(
      'payment_id', p_payment_id,
      'member_id', v_member.id,
      'amount', v_payment.amount,
      'transaction_id', v_txn_id,
      'obligation_id', case when v_obligation is not null then v_obligation.id else null end
    )
  );

  return jsonb_build_object(
    'contribution_id', v_contrib_id,
    'transaction_id', v_txn_id,
    'reference_number', v_txn_ref,
    'amount', v_payment.amount,
    'status', 'posted'
  );
end;
$$;

grant execute on function public.post_verified_savings_contribution(uuid, uuid) to authenticated;

-- 6.2 Approve Savings Withdrawal (Admin RPC)
create or replace function public.approve_savings_withdrawal(
  p_withdrawal_request_id uuid,
  p_reviewer_id uuid default auth.uid()
)
returns jsonb
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_req record;
  v_available numeric(18,2);
begin
  if not private.current_user_is_admin() then
    raise exception 'Unauthorized: Admin privileges required.';
  end if;

  select * into v_req
  from public.withdrawal_requests
  where id = p_withdrawal_request_id
  for update;

  if v_req is null then
    raise exception 'Withdrawal request % not found.', p_withdrawal_request_id;
  end if;

  if v_req.status not in ('pending', 'delayed') then
    raise exception 'Cannot approve withdrawal in % status.', v_req.status;
  end if;

  v_available := private.get_member_available_savings(v_req.member_id);
  if v_req.amount > v_available then
    raise exception 'Cannot approve: Requested amount (ETB %) exceeds available savings (ETB %).', v_req.amount, v_available;
  end if;

  update public.withdrawal_requests
  set
    status = 'approved',
    reviewed_by = p_reviewer_id,
    reviewed_at = now(),
    updated_at = now()
  where id = p_withdrawal_request_id;

  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    new_data
  )
  values (
    p_reviewer_id,
    'SAVINGS_WITHDRAWAL_APPROVED',
    'withdrawal_requests',
    p_withdrawal_request_id,
    jsonb_build_object('amount', v_req.amount, 'member_id', v_req.member_id)
  );

  return jsonb_build_object(
    'id', p_withdrawal_request_id,
    'status', 'approved'
  );
end;
$$;

grant execute on function public.approve_savings_withdrawal(uuid, uuid) to authenticated;

-- 6.3 Reject Savings Withdrawal (Admin RPC)
create or replace function public.reject_savings_withdrawal(
  p_withdrawal_request_id uuid,
  p_reason text,
  p_reviewer_id uuid default auth.uid()
)
returns jsonb
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_req record;
begin
  if not private.current_user_is_admin() then
    raise exception 'Unauthorized: Admin privileges required.';
  end if;

  if coalesce(trim(p_reason), '') = '' then
    raise exception 'Rejection reason is required.';
  end if;

  select * into v_req
  from public.withdrawal_requests
  where id = p_withdrawal_request_id
  for update;

  if v_req is null then
    raise exception 'Withdrawal request % not found.', p_withdrawal_request_id;
  end if;

  if v_req.status not in ('pending', 'delayed') then
    raise exception 'Cannot reject withdrawal in % status.', v_req.status;
  end if;

  update public.withdrawal_requests
  set
    status = 'rejected',
    reason = trim(p_reason),
    reviewed_by = p_reviewer_id,
    reviewed_at = now(),
    updated_at = now()
  where id = p_withdrawal_request_id;

  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    new_data
  )
  values (
    p_reviewer_id,
    'SAVINGS_WITHDRAWAL_REJECTED',
    'withdrawal_requests',
    p_withdrawal_request_id,
    jsonb_build_object('reason', trim(p_reason))
  );

  return jsonb_build_object(
    'id', p_withdrawal_request_id,
    'status', 'rejected',
    'reason', trim(p_reason)
  );
end;
$$;

grant execute on function public.reject_savings_withdrawal(uuid, text, uuid) to authenticated;

-- 6.4 Delay Savings Withdrawal (Admin RPC for liquidity protection)
create or replace function public.delay_savings_withdrawal(
  p_withdrawal_request_id uuid,
  p_reason text,
  p_reviewer_id uuid default auth.uid()
)
returns jsonb
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_req record;
begin
  if not private.current_user_is_admin() then
    raise exception 'Unauthorized: Admin privileges required.';
  end if;

  if coalesce(trim(p_reason), '') = '' then
    raise exception 'Delay reason is required for communication to member.';
  end if;

  select * into v_req
  from public.withdrawal_requests
  where id = p_withdrawal_request_id
  for update;

  if v_req is null then
    raise exception 'Withdrawal request % not found.', p_withdrawal_request_id;
  end if;

  if v_req.status != 'pending' then
    raise exception 'Cannot delay withdrawal in % status.', v_req.status;
  end if;

  update public.withdrawal_requests
  set
    status = 'delayed',
    reason = trim(p_reason),
    reviewed_by = p_reviewer_id,
    reviewed_at = now(),
    updated_at = now()
  where id = p_withdrawal_request_id;

  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    new_data
  )
  values (
    p_reviewer_id,
    'SAVINGS_WITHDRAWAL_DELAYED',
    'withdrawal_requests',
    p_withdrawal_request_id,
    jsonb_build_object('reason', trim(p_reason))
  );

  return jsonb_build_object(
    'id', p_withdrawal_request_id,
    'status', 'delayed',
    'reason', trim(p_reason)
  );
end;
$$;

grant execute on function public.delay_savings_withdrawal(uuid, text, uuid) to authenticated;

-- 6.5 Post Savings Withdrawal (Financial Ledger Posting)
create or replace function public.post_savings_withdrawal(
  p_withdrawal_request_id uuid,
  p_payment_method_code text default 'bank_transfer',
  p_reviewer_id uuid default auth.uid()
)
returns jsonb
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_req record;
  v_member record;
  v_member_acc_id uuid;
  v_bank_acc_id uuid;
  v_txn_id uuid;
  v_txn_ref text;
  v_available numeric(18,2);
begin
  if not private.current_user_is_admin() then
    raise exception 'Unauthorized: Admin privileges required.';
  end if;

  select * into v_req
  from public.withdrawal_requests
  where id = p_withdrawal_request_id
  for update;

  if v_req is null then
    raise exception 'Withdrawal request % not found.', p_withdrawal_request_id;
  end if;

  if v_req.status != 'approved' then
    raise exception 'Withdrawal request is in % status; only approved requests can be posted.', v_req.status;
  end if;

  select * into v_member from public.members where id = v_req.member_id;
  if v_member is null then
    raise exception 'Member not found.';
  end if;

  v_available := private.get_member_available_savings(v_req.member_id);
  if v_req.amount > v_available then
    raise exception 'Cannot post withdrawal: Amount (ETB %) exceeds current available balance (ETB %).', v_req.amount, v_available;
  end if;

  v_member_acc_id := private.ensure_member_savings_account(v_member.id);
  v_bank_acc_id := private.get_or_create_group_account('bank');

  -- 1. Create Financial Transaction
  v_txn_ref := private.generate_reference('TXN');

  insert into public.transactions (
    reference_number,
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
    v_txn_ref,
    'savings_withdrawal',
    'withdrawal_request',
    p_withdrawal_request_id,
    v_member.profile_id,
    v_member.id,
    v_req.amount,
    'ETB',
    'approved',
    'posted',
    p_reviewer_id,
    p_reviewer_id,
    now(),
    'Member savings withdrawal payout'
  )
  returning id into v_txn_id;

  -- 2. Balanced Ledger Entries
  -- Debit Member Savings Account (Liability to member decreases)
  insert into public.transaction_entries (
    transaction_id,
    account_id,
    entry_type,
    amount
  )
  values (
    v_txn_id,
    v_member_acc_id,
    'debit',
    v_req.amount
  );

  -- Credit Bank Account (Asset decreases)
  insert into public.transaction_entries (
    transaction_id,
    account_id,
    entry_type,
    amount
  )
  values (
    v_txn_id,
    v_bank_acc_id,
    'credit',
    v_req.amount
  );

  -- 3. Update Withdrawal Request
  update public.withdrawal_requests
  set
    status = 'paid',
    paid_at = now(),
    updated_at = now()
  where id = p_withdrawal_request_id;

  -- 4. Audit Log
  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    new_data
  )
  values (
    p_reviewer_id,
    'SAVINGS_WITHDRAWAL_POSTED',
    'withdrawal_requests',
    p_withdrawal_request_id,
    jsonb_build_object(
      'amount', v_req.amount,
      'member_id', v_member.id,
      'transaction_id', v_txn_id
    )
  );

  return jsonb_build_object(
    'id', p_withdrawal_request_id,
    'transaction_id', v_txn_id,
    'reference_number', v_txn_ref,
    'amount', v_req.amount,
    'status', 'paid'
  );
end;
$$;

grant execute on function public.post_savings_withdrawal(uuid, text, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 7. Scheduled Jobs / Background RPCs (Idempotent)
-- ---------------------------------------------------------------------------

-- 7.1 Monthly Obligation Generator
create or replace function public.generate_monthly_savings_obligations(
  p_year int default null,
  p_month int default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_year int;
  v_month int;
  v_due_day int;
  v_min_saving numeric(18,2);
  v_due_date date;
  v_created_count int := 0;
  v_member record;
begin
  v_year := coalesce(p_year, extract(year from current_date)::int);
  v_month := coalesce(p_month, extract(month from current_date)::int);

  v_min_saving := coalesce(public.get_active_rule_numeric('monthly_min_saving'), 2000.00);
  v_due_day := coalesce(public.get_active_rule_numeric('saving_due_day')::int, 12);

  v_due_date := make_date(v_year, v_month, v_due_day);

  for v_member in
    select m.id
    from public.members m
    where m.status = 'active'
      and not exists (
        select 1 from public.savings_obligations so
        where so.member_id = m.id
          and so.period_year = v_year
          and so.period_month = v_month
      )
  loop
    insert into public.savings_obligations (
      member_id,
      period_year,
      period_month,
      required_amount,
      due_date,
      paid_amount,
      late_penalty_amount,
      status
    )
    values (
      v_member.id,
      v_year,
      v_month,
      v_min_saving,
      v_due_date,
      0,
      0,
      'pending'
    )
    on conflict (member_id, period_year, period_month) do nothing;

    v_created_count := v_created_count + 1;
  end loop;

  insert into public.audit_logs (
    action,
    entity_type,
    new_data
  )
  values (
    'SAVINGS_MONTHLY_OBLIGATIONS_GENERATED',
    'savings_obligations',
    jsonb_build_object(
      'year', v_year,
      'month', v_month,
      'created_count', v_created_count,
      'due_date', v_due_date,
      'required_amount', v_min_saving
    )
  );

  return jsonb_build_object(
    'year', v_year,
    'month', v_month,
    'obligations_created', v_created_count,
    'due_date', v_due_date
  );
end;
$$;

grant execute on function public.generate_monthly_savings_obligations(int, int) to authenticated;

-- 7.2 Late Obligation & Penalty Processor
create or replace function public.process_late_savings_obligations(
  p_as_of_date date default current_date
)
returns jsonb
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_penalty_rate numeric(8,4);
  v_penalty_acc_id uuid;
  v_obligation record;
  v_processed_count int := 0;
  v_penalty_amount numeric(18,2);
  v_txn_id uuid;
  v_txn_ref text;
begin
  v_penalty_rate := coalesce(public.get_active_rule_numeric('saving_late_penalty_rate'), 0.10);
  v_penalty_acc_id := private.get_or_create_group_account('penalty_income');

  for v_obligation in
    select so.*, m.profile_id
    from public.savings_obligations so
    join public.members m on m.id = so.member_id
    where so.due_date < p_as_of_date
      and so.status in ('pending', 'partially_paid')
      and so.paid_amount < so.required_amount
      and not exists (
        select 1 from public.savings_penalties sp
        where sp.obligation_id = so.id
      )
  loop
    v_penalty_amount := round(v_obligation.required_amount * v_penalty_rate, 2);

    -- 1. Create Transaction for Penalty (Financial audit)
    v_txn_ref := private.generate_reference('TXN');

    insert into public.transactions (
      reference_number,
      transaction_type,
      source_type,
      source_id,
      profile_id,
      member_id,
      amount,
      currency,
      approval_status,
      transaction_status,
      description
    )
    values (
      v_txn_ref,
      'savings_late_penalty',
      'savings_obligation',
      v_obligation.id,
      v_obligation.profile_id,
      v_obligation.member_id,
      v_penalty_amount,
      'ETB',
      'approved',
      'posted',
      'Late monthly savings contribution penalty (10%)'
    )
    returning id into v_txn_id;

    -- 2. Insert Penalty Record
    insert into public.savings_penalties (
      obligation_id,
      rate,
      amount,
      transaction_id,
      charged_at
    )
    values (
      v_obligation.id,
      v_penalty_rate,
      v_penalty_amount,
      v_txn_id,
      now()
    )
    on conflict (obligation_id) do nothing;

    -- 3. Update Obligation Status to LATE
    update public.savings_obligations
    set
      status = 'late',
      late_penalty_amount = v_penalty_amount,
      updated_at = now()
    where id = v_obligation.id;

    v_processed_count := v_processed_count + 1;
  end loop;

  insert into public.audit_logs (
    action,
    entity_type,
    new_data
  )
  values (
    'SAVINGS_LATE_OBLIGATIONS_PROCESSED',
    'savings_obligations',
    jsonb_build_object(
      'as_of_date', p_as_of_date,
      'processed_count', v_processed_count,
      'penalty_rate', v_penalty_rate
    )
  );

  return jsonb_build_object(
    'as_of_date', p_as_of_date,
    'late_obligations_processed', v_processed_count
  );
end;
$$;

grant execute on function public.process_late_savings_obligations(date) to authenticated;

commit;
