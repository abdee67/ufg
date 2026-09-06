-- Unity Finance - Admin Savings SQL/RPC Migration
-- Depends on: Unity_Finance_MVP_Supabase_Schema.sql
-- Purpose: Admin-side Savings operations, secure RPCs, admin reporting views,
--          financial write hardening, indexes, and verification queries.
--
-- IMPORTANT:
-- 1) Run against DEVELOPMENT first.
-- 2) This migration assumes the MVP schema already exists.
-- 3) Financial mutations are routed through controlled RPCs.
-- 4) The client must never receive the Supabase secret/service-role key.

begin;

-- ---------------------------------------------------------------------------
-- 0. Preconditions
-- ---------------------------------------------------------------------------

do $$
begin
  if to_regclass('public.savings_accounts') is null
     or to_regclass('public.savings_obligations') is null
     or to_regclass('public.savings_contributions') is null
     or to_regclass('public.savings_penalties') is null
     or to_regclass('public.withdrawal_requests') is null
     or to_regclass('public.payments') is null
     or to_regclass('public.payment_verifications') is null
     or to_regclass('public.transactions') is null
     or to_regclass('public.transaction_entries') is null
     or to_regclass('public.audit_logs') is null
     or to_regclass('public.financial_rules') is null
     or to_regclass('public.financial_rule_versions') is null
     or to_regclass('public.roles') is null
     or to_regclass('public.user_roles') is null
  then
    raise exception 'Unity Finance MVP schema is incomplete. Run the MVP schema first.';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- 1. Savings status / withdrawal status compatibility
-- ---------------------------------------------------------------------------

do $$
begin
  if not exists (
    select 1
    from pg_enum e
    join pg_type t on t.oid = e.enumtypid
    where t.typnamespace = 'public'::regnamespace
      and t.typname = 'withdrawal_status'
      and e.enumlabel = 'delayed'
  ) then
    alter type public.withdrawal_status add value 'delayed';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- 2. Admin permission helper
-- ---------------------------------------------------------------------------

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
    join public.role_permissions rp on rp.role_id = ur.role_id
    join public.permissions p on p.id = rp.permission_id
    where ur.user_id = (select auth.uid())
      and p.code = p_permission_code
  );
$$;

revoke all on function private.current_user_has_permission(text) from public, anon;
grant execute on function private.current_user_has_permission(text) to authenticated;

-- ---------------------------------------------------------------------------
-- 3. System financial accounts
-- ---------------------------------------------------------------------------
-- These are group-owned accounts used by financial posting RPCs.

create unique index if not exists accounts_one_system_account_per_type
on public.accounts(account_type_id)
where owner_member_id is null and owner_profile_id is null;

insert into public.accounts(account_type_id, currency, status)
select at.id, 'ETB', 'active'
from public.account_types at
where at.code in ('cash', 'bank', 'wallet', 'group_income', 'penalty_income')
  and not exists (
    select 1
    from public.accounts a
    where a.account_type_id = at.id
      and a.owner_member_id is null
      and a.owner_profile_id is null
  );

-- ---------------------------------------------------------------------------
-- 4. Indexes used by the admin Savings panel
-- ---------------------------------------------------------------------------

create index if not exists savings_obligations_status_due_idx
on public.savings_obligations(status, due_date, member_id);

create index if not exists savings_contributions_payment_idx
on public.savings_contributions(payment_id)
where payment_id is not null;

create index if not exists savings_penalties_transaction_idx
on public.savings_penalties(transaction_id)
where transaction_id is not null;

create index if not exists withdrawal_requests_status_requested_idx
on public.withdrawal_requests(status, requested_at desc);

create index if not exists payments_savings_queue_idx
on public.payments(status, submitted_at desc)
where purpose_type in ('savings', 'savings_contribution');

create index if not exists payments_purpose_idx
on public.payments(purpose_type, purpose_id);

create index if not exists transactions_type_status_idx
on public.transactions(transaction_type, transaction_status, created_at desc);

create index if not exists transactions_profile_created_idx
on public.transactions(profile_id, created_at desc);

-- ---------------------------------------------------------------------------
-- 5. Harden direct financial writes
-- ---------------------------------------------------------------------------
-- Members should submit payment/withdrawal requests.
-- They should NOT directly mutate authoritative financial posting tables.

revoke insert, update, delete on public.savings_obligations from authenticated;
revoke insert, update, delete on public.savings_contributions from authenticated;
revoke insert, update, delete on public.savings_penalties from authenticated;
revoke update, delete on public.withdrawal_requests from authenticated;
revoke update, delete on public.payments from authenticated;
revoke insert, update, delete on public.payment_verifications from authenticated;
revoke insert, update, delete on public.transactions from authenticated;
revoke insert, update, delete on public.transaction_entries from authenticated;

-- Read grants remain explicit from the MVP. Mutations happen through RPCs.

-- ---------------------------------------------------------------------------
-- 6. Admin Savings reporting views
-- ---------------------------------------------------------------------------

create or replace view public.admin_savings_overview
with (security_invoker = true)
as
with current_period as (
  select
    extract(year from current_date)::int as period_year,
    extract(month from current_date)::int as period_month
)
select
  (
    select count(*)
    from public.members m
    where m.status = 'active'
  ) as active_members,

  (
    select coalesce(sum(mss.savings_balance), 0)
    from public.member_savings_summary mss
  )::numeric(18,2) as total_member_savings,

  (
    select coalesce(sum(so.paid_amount), 0)
    from public.savings_obligations so, current_period cp
    where so.period_year = cp.period_year
      and so.period_month = cp.period_month
  )::numeric(18,2) as current_month_collected,

  (
    select coalesce(sum(so.required_amount), 0)
    from public.savings_obligations so, current_period cp
    where so.period_year = cp.period_year
      and so.period_month = cp.period_month
  )::numeric(18,2) as current_month_expected,

  (
    select count(*)
    from public.savings_obligations so, current_period cp
    where so.period_year = cp.period_year
      and so.period_month = cp.period_month
      and so.status = 'late'
  ) as late_members,

  (
    select coalesce(sum(so.required_amount - so.paid_amount), 0)
    from public.savings_obligations so, current_period cp
    where so.period_year = cp.period_year
      and so.period_month = cp.period_month
      and so.status in ('pending', 'partially_paid', 'late')
  )::numeric(18,2) as outstanding_current_obligations,

  (
    select count(*)
    from public.payments p
    where p.purpose_type in ('savings', 'savings_contribution')
      and p.status = 'pending'
  ) as pending_payment_verifications,

  (
    select count(*)
    from public.withdrawal_requests wr
    where wr.status = 'pending'
  ) as pending_withdrawals,

  (
    select coalesce(sum(sl.amount), 0)
    from public.savings_security_locks sl
    where sl.status = 'active'
  )::numeric(18,2) as secured_savings;

create or replace view public.admin_savings_member_overview
with (security_invoker = true)
as
with current_period as (
  select
    extract(year from current_date)::int as period_year,
    extract(month from current_date)::int as period_month
)
select
  m.id as member_id,
  m.member_number,
  p.full_name,
  p.email,
  p.phone,
  m.status as member_status,
  m.membership_date,
  coalesce(mss.savings_balance, 0)::numeric(18,2) as total_savings,
  coalesce(so.required_amount, 0)::numeric(18,2) as current_required,
  coalesce(so.paid_amount, 0)::numeric(18,2) as current_paid,
  coalesce(so.late_penalty_amount, 0)::numeric(18,2) as current_penalty,
  coalesce(so.status::text, 'pending') as current_obligation_status,
  so.due_date as current_due_date,
  coalesce(sec.secured_amount, 0)::numeric(18,2) as secured_savings,
  greatest(
    coalesce(mss.savings_balance, 0) - coalesce(sec.secured_amount, 0),
    0
  )::numeric(18,2) as available_withdrawal
from public.members m
join public.profiles p on p.id = m.profile_id
left join public.member_savings_summary mss on mss.member_id = m.id
left join lateral (
  select so.*
  from public.savings_obligations so, current_period cp
  where so.member_id = m.id
    and so.period_year = cp.period_year
    and so.period_month = cp.period_month
  limit 1
) so on true
left join lateral (
  select coalesce(sum(sl.amount), 0) as secured_amount
  from public.savings_security_locks sl
  where sl.member_id = m.id
    and sl.status = 'active'
) sec on true
where m.status in ('active', 'suspended', 'inactive', 'removed');

create or replace view public.admin_savings_obligation_queue
with (security_invoker = true)
as
select
  so.id,
  m.id as member_id,
  m.member_number,
  p.full_name,
  p.email,
  p.phone,
  so.period_year,
  so.period_month,
  so.required_amount,
  so.paid_amount,
  greatest(so.required_amount - so.paid_amount, 0)::numeric(18,2) as remaining_amount,
  so.late_penalty_amount,
  so.due_date,
  so.status,
  so.created_at,
  so.updated_at
from public.savings_obligations so
join public.members m on m.id = so.member_id
join public.profiles p on p.id = m.profile_id;

create or replace view public.admin_savings_payment_queue
with (security_invoker = true)
as
select
  p.id,
  p.reference_number,
  p.payer_profile_id,
  pr.full_name as payer_name,
  pr.email,
  pr.phone,
  p.amount,
  p.currency,
  pm.code as payment_method_code,
  pm.name as payment_method_name,
  p.purpose_type,
  p.purpose_id,
  p.status,
  p.payment_proof_path,
  p.external_reference,
  p.submitted_at,
  p.verified_by,
  p.verified_at,
  p.rejection_reason
from public.payments p
join public.profiles pr on pr.id = p.payer_profile_id
left join public.payment_methods pm on pm.id = p.payment_method_id
where p.purpose_type in ('savings', 'savings_contribution');

create or replace view public.admin_savings_withdrawal_queue
with (security_invoker = true)
as
select
  wr.id,
  wr.member_id,
  m.member_number,
  p.full_name,
  p.email,
  p.phone,
  wr.amount,
  wr.status,
  wr.requested_at,
  wr.reviewed_by,
  wr.reviewed_at,
  wr.paid_at,
  wr.reason,
  coalesce(mss.savings_balance, 0)::numeric(18,2) as total_savings,
  coalesce(sec.secured_amount, 0)::numeric(18,2) as secured_savings,
  greatest(
    coalesce(mss.savings_balance, 0) - coalesce(sec.secured_amount, 0),
    0
  )::numeric(18,2) as available_savings
from public.withdrawal_requests wr
join public.members m on m.id = wr.member_id
join public.profiles p on p.id = m.profile_id
left join public.member_savings_summary mss on mss.member_id = m.id
left join lateral (
  select coalesce(sum(sl.amount), 0) as secured_amount
  from public.savings_security_locks sl
  where sl.member_id = m.id
    and sl.status = 'active'
) sec on true;

create or replace view public.admin_savings_transaction_queue
with (security_invoker = true)
as
select
  t.id,
  t.reference_number,
  t.transaction_type,
  t.profile_id,
  pr.full_name,
  t.member_id,
  m.member_number,
  t.amount,
  t.currency,
  t.approval_status,
  t.transaction_status,
  t.initiated_by,
  initiator.full_name as initiated_by_name,
  t.approved_by,
  approver.full_name as approved_by_name,
  t.approved_at,
  t.description,
  t.source_type,
  t.source_id,
  t.reversal_of_transaction_id,
  t.created_at
from public.transactions t
left join public.profiles pr on pr.id = t.profile_id
left join public.members m on m.id = t.member_id
left join public.profiles initiator on initiator.id = t.initiated_by
left join public.profiles approver on approver.id = t.approved_by
where t.transaction_type in (
  'savings_contribution',
  'savings_withdrawal',
  'savings_late_penalty',
  'reversal',
  'correction'
);

grant select on public.admin_savings_overview,
               public.admin_savings_member_overview,
               public.admin_savings_obligation_queue,
               public.admin_savings_payment_queue,
               public.admin_savings_withdrawal_queue,
               public.admin_savings_transaction_queue
  to authenticated;

-- ---------------------------------------------------------------------------
-- 7. Helper: find current member savings account
-- ---------------------------------------------------------------------------

create or replace function private.savings_account_for_member(p_member_id uuid)
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select sa.id
  from public.savings_accounts sa
  where sa.member_id = p_member_id
    and sa.status = 'active'
  limit 1;
$$;

revoke all on function private.savings_account_for_member(uuid) from public, anon;
grant execute on function private.savings_account_for_member(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 8. Admin: verify a savings payment and post the contribution atomically
-- ---------------------------------------------------------------------------

create or replace function public.admin_verify_savings_payment(p_payment_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_payment public.payments%rowtype;
  v_member_id uuid;
  v_savings_account_id uuid;
  v_obligation public.savings_obligations%rowtype;
  v_remaining numeric(18,2);
  v_mandatory_amount numeric(18,2) := 0;
  v_voluntary_amount numeric(18,2) := 0;
  v_transaction_id uuid;
  v_cash_account_id uuid;
  v_bank_account_id uuid;
  v_wallet_account_id uuid;
  v_funding_account_id uuid;
  v_payment_method_code text;
  v_result jsonb;
begin
  if v_actor is null then
    raise exception 'Unauthorized';
  end if;

  if not private.current_user_has_permission('payment.verify') then
    raise exception 'Unauthorized: payment verification permission required';
  end if;

  select * into v_payment
  from public.payments
  where id = p_payment_id
  for update;

  if not found then
    raise exception 'Savings payment not found';
  end if;

  if v_payment.purpose_type not in ('savings', 'savings_contribution') then
    raise exception 'Payment is not a savings payment';
  end if;

  if v_payment.status = 'verified' then
    raise exception 'Payment already verified';
  end if;

  if v_payment.status <> 'pending' then
    raise exception 'Payment is not in a verifiable state';
  end if;

  select m.id into v_member_id
  from public.members m
  where m.profile_id = v_payment.payer_profile_id
    and m.status = 'active';

  if v_member_id is null then
    raise exception 'Payment payer is not an active member';
  end if;

  v_savings_account_id := private.savings_account_for_member(v_member_id);
  if v_savings_account_id is null then
    raise exception 'Member savings account not found';
  end if;

  select code into v_payment_method_code
  from public.payment_methods
  where id = v_payment.payment_method_id;

  if v_payment_method_code is null then
    raise exception 'Payment method not found';
  end if;

  select a.id into v_cash_account_id
  from public.accounts a
  join public.account_types at on at.id = a.account_type_id
  where at.code = 'cash'
    and a.owner_member_id is null
    and a.owner_profile_id is null
    and a.status = 'active'
  limit 1;

  select a.id into v_bank_account_id
  from public.accounts a
  join public.account_types at on at.id = a.account_type_id
  where at.code = 'bank'
    and a.owner_member_id is null
    and a.owner_profile_id is null
    and a.status = 'active'
  limit 1;

  select a.id into v_wallet_account_id
  from public.accounts a
  join public.account_types at on at.id = a.account_type_id
  where at.code = 'wallet'
    and a.owner_member_id is null
    and a.owner_profile_id is null
    and a.status = 'active'
  limit 1;

  if v_payment_method_code = 'bank_transfer' then
    v_funding_account_id := v_bank_account_id;
  elsif v_payment_method_code = 'wallet' then
    v_funding_account_id := v_wallet_account_id;
  else
    v_funding_account_id := v_cash_account_id;
  end if;

  if v_funding_account_id is null then
    raise exception 'System funding account for payment method is not configured';
  end if;

  -- A payment may optionally target an obligation through purpose_id.
  -- If no obligation is provided, apply the mandatory portion to the earliest
  -- open obligation and the excess to voluntary savings.
  if v_payment.purpose_id is not null then
    select * into v_obligation
    from public.savings_obligations so
    where so.id = v_payment.purpose_id
      and so.member_id = v_member_id
    for update;

    if not found then
      raise exception 'Referenced savings obligation not found for member';
    end if;
  else
    select * into v_obligation
    from public.savings_obligations so
    where so.member_id = v_member_id
      and so.status in ('pending', 'partially_paid', 'late')
      and so.paid_amount < so.required_amount
    order by so.due_date asc, so.created_at asc
    limit 1
    for update;
  end if;

  if v_obligation.id is not null then
    v_remaining := greatest(v_obligation.required_amount - v_obligation.paid_amount, 0);
    v_mandatory_amount := least(v_payment.amount, v_remaining);
    v_voluntary_amount := greatest(v_payment.amount - v_mandatory_amount, 0);
  else
    v_voluntary_amount := v_payment.amount;
  end if;

  update public.payments
  set status = 'verified',
      verified_by = v_actor,
      verified_at = now(),
      updated_at = now()
  where id = v_payment.id;

  insert into public.payment_verifications (
    payment_id,
    verification_type,
    status,
    verified_by,
    external_reference,
    evidence,
    verified_at
  ) values (
    v_payment.id,
    'manual',
    'verified',
    v_actor,
    v_payment.external_reference,
    jsonb_build_object('admin_action', 'admin_verify_savings_payment'),
    now()
  );

  insert into public.transactions (
    transaction_type,
    source_type,
    source_id,
    profile_id,
    member_id,
    amount,
    approval_status,
    transaction_status,
    initiated_by,
    approved_by,
    approved_at,
    description
  ) values (
    'savings_contribution',
    'payment',
    v_payment.id,
    v_payment.payer_profile_id,
    v_member_id,
    v_payment.amount,
    'approved',
    'posted',
    v_actor,
    v_actor,
    now(),
    'Verified savings payment'
  ) returning id into v_transaction_id;

  if v_mandatory_amount > 0 then
    insert into public.savings_contributions (
      member_id,
      savings_account_id,
      obligation_id,
      amount,
      payment_id,
      transaction_id,
      contribution_type
    ) values (
      v_member_id,
      v_savings_account_id,
      v_obligation.id,
      v_mandatory_amount,
      v_payment.id,
      v_transaction_id,
      'mandatory'
    );

    update public.savings_obligations
    set paid_amount = paid_amount + v_mandatory_amount,
        status = case
          when paid_amount + v_mandatory_amount >= required_amount then 'paid'::public.savings_obligation_status
          else 'partially_paid'::public.savings_obligation_status
        end,
        updated_at = now()
    where id = v_obligation.id;
  end if;

  if v_voluntary_amount > 0 then
    insert into public.savings_contributions (
      member_id,
      savings_account_id,
      obligation_id,
      amount,
      payment_id,
      transaction_id,
      contribution_type
    ) values (
      v_member_id,
      v_savings_account_id,
      null,
      v_voluntary_amount,
      v_payment.id,
      v_transaction_id,
      'voluntary'
    );
  end if;

  insert into public.transaction_entries (
    transaction_id,
    account_id,
    entry_type,
    amount
  ) values
    (v_transaction_id, v_funding_account_id, 'debit', v_payment.amount),
    ((v_transaction_id), (select sa.account_id from public.savings_accounts sa where sa.id = v_savings_account_id), 'credit', v_payment.amount);

  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    old_data,
    new_data,
    metadata
  ) values (
    v_actor,
    'SAVINGS_PAYMENT_VERIFIED',
    'payment',
    v_payment.id,
    jsonb_build_object('status', 'pending'),
    jsonb_build_object(
      'status', 'verified',
      'transaction_id', v_transaction_id,
      'mandatory_amount', v_mandatory_amount,
      'voluntary_amount', v_voluntary_amount
    ),
    jsonb_build_object('member_id', v_member_id)
  );

  v_result := jsonb_build_object(
    'payment_id', v_payment.id,
    'member_id', v_member_id,
    'transaction_id', v_transaction_id,
    'amount', v_payment.amount,
    'mandatory_amount', v_mandatory_amount,
    'voluntary_amount', v_voluntary_amount,
    'status', 'verified'
  );

  return v_result;
end;
$$;

revoke all on function public.admin_verify_savings_payment(uuid) from public, anon;
grant execute on function public.admin_verify_savings_payment(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 9. Admin: reject savings payment
-- ---------------------------------------------------------------------------

create or replace function public.admin_reject_savings_payment(
  p_payment_id uuid,
  p_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_payment public.payments%rowtype;
  v_reason text := trim(coalesce(p_reason, ''));
begin
  if v_actor is null then
    raise exception 'Unauthorized';
  end if;

  if not private.current_user_has_permission('payment.verify') then
    raise exception 'Unauthorized: payment verification permission required';
  end if;

  if length(v_reason) < 10 then
    raise exception 'Rejection reason must be at least 10 characters';
  end if;

  if length(v_reason) > 500 then
    raise exception 'Rejection reason must not exceed 500 characters';
  end if;

  select * into v_payment
  from public.payments
  where id = p_payment_id
  for update;

  if not found then
    raise exception 'Savings payment not found';
  end if;

  if v_payment.purpose_type not in ('savings', 'savings_contribution') then
    raise exception 'Payment is not a savings payment';
  end if;

  if v_payment.status <> 'pending' then
    raise exception 'Payment is not in a reviewable state';
  end if;

  update public.payments
  set status = 'rejected',
      verified_by = v_actor,
      verified_at = now(),
      rejection_reason = v_reason,
      updated_at = now()
  where id = p_payment_id;

  insert into public.payment_verifications (
    payment_id,
    verification_type,
    status,
    verified_by,
    evidence,
    verified_at
  ) values (
    p_payment_id,
    'manual',
    'rejected',
    v_actor,
    jsonb_build_object('reason', v_reason),
    now()
  );

  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    old_data,
    new_data,
    metadata
  ) values (
    v_actor,
    'SAVINGS_PAYMENT_REJECTED',
    'payment',
    p_payment_id,
    jsonb_build_object('status', 'pending'),
    jsonb_build_object('status', 'rejected', 'reason', v_reason),
    '{}'::jsonb
  );

  return jsonb_build_object(
    'payment_id', p_payment_id,
    'status', 'rejected',
    'reason', v_reason
  );
end;
$$;

revoke all on function public.admin_reject_savings_payment(uuid, text) from public, anon;
grant execute on function public.admin_reject_savings_payment(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- 10. Admin: approve savings withdrawal
-- ---------------------------------------------------------------------------
-- NOTE: This MVP function enforces available savings. The exact group
-- liquidity calculation remains a business-policy dependency and must be
-- wired to the finalized liquidity formula before production use.

create or replace function public.admin_approve_savings_withdrawal(p_request_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_request public.withdrawal_requests%rowtype;
  v_member_id uuid;
  v_savings_account_id uuid;
  v_savings_ledger_account_id uuid;
  v_payout_account_id uuid;
  v_total_savings numeric(18,2);
  v_secured numeric(18,2);
  v_available numeric(18,2);
  v_transaction_id uuid;
  v_result jsonb;
begin
  if v_actor is null then
    raise exception 'Unauthorized';
  end if;

  if not private.current_user_has_permission('savings.withdraw.approve') then
    raise exception 'Unauthorized: withdrawal approval permission required';
  end if;

  select * into v_request
  from public.withdrawal_requests
  where id = p_request_id
  for update;

  if not found then
    raise exception 'Withdrawal request not found';
  end if;

  if v_request.status <> 'pending' then
    raise exception 'Withdrawal request is not pending';
  end if;

  select m.id into v_member_id
  from public.members m
  where m.id = v_request.member_id
    and m.status = 'active';

  if v_member_id is null then
    raise exception 'Member is not active';
  end if;

  v_savings_account_id := private.savings_account_for_member(v_member_id);
  if v_savings_account_id is null then
    raise exception 'Savings account not found';
  end if;

  select sa.account_id into v_savings_ledger_account_id
  from public.savings_accounts sa
  where sa.id = v_savings_account_id;

  select coalesce(mss.savings_balance, 0)
  into v_total_savings
  from public.member_savings_summary mss
  where mss.member_id = v_member_id;

  if v_total_savings is null then
    v_total_savings := 0;
  end if;

  select coalesce(sum(sl.amount), 0)
  into v_secured
  from public.savings_security_locks sl
  where sl.member_id = v_member_id
    and sl.status = 'active';

  v_available := greatest(v_total_savings - v_secured, 0);

  if v_request.amount > v_available then
    raise exception 'Withdrawal exceeds available savings. Available: %', v_available;
  end if;

  -- Choose the group's wallet account for the MVP payout mechanism.
  select a.id into v_payout_account_id
  from public.accounts a
  join public.account_types at on at.id = a.account_type_id
  where at.code = 'wallet'
    and a.owner_member_id is null
    and a.owner_profile_id is null
    and a.status = 'active'
  limit 1;

  if v_payout_account_id is null then
    raise exception 'Group wallet payout account is not configured';
  end if;

  insert into public.transactions (
    transaction_type,
    source_type,
    source_id,
    profile_id,
    member_id,
    amount,
    approval_status,
    transaction_status,
    initiated_by,
    approved_by,
    approved_at,
    description
  ) values (
    'savings_withdrawal',
    'withdrawal_request',
    v_request.id,
    (select m.profile_id from public.members m where m.id = v_member_id),
    v_member_id,
    v_request.amount,
    'approved',
    'posted',
    v_actor,
    v_actor,
    now(),
    'Approved savings withdrawal'
  ) returning id into v_transaction_id;

  insert into public.transaction_entries (
    transaction_id,
    account_id,
    entry_type,
    amount
  ) values
    (v_transaction_id, v_savings_ledger_account_id, 'debit', v_request.amount),
    (v_transaction_id, v_payout_account_id, 'credit', v_request.amount);

  update public.withdrawal_requests
  set status = 'paid',
      reviewed_by = v_actor,
      reviewed_at = now(),
      paid_at = now(),
      updated_at = now()
  where id = v_request.id;

  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    old_data,
    new_data,
    metadata
  ) values (
    v_actor,
    'SAVINGS_WITHDRAWAL_POSTED',
    'withdrawal_request',
    v_request.id,
    jsonb_build_object('status', 'pending', 'amount', v_request.amount),
    jsonb_build_object('status', 'paid', 'transaction_id', v_transaction_id),
    jsonb_build_object(
      'member_id', v_member_id,
      'available_before', v_available,
      'secured_before', v_secured
    )
  );

  v_result := jsonb_build_object(
    'withdrawal_request_id', v_request.id,
    'transaction_id', v_transaction_id,
    'status', 'paid',
    'amount', v_request.amount
  );

  return v_result;
end;
$$;

revoke all on function public.admin_approve_savings_withdrawal(uuid) from public, anon;
grant execute on function public.admin_approve_savings_withdrawal(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 11. Admin: delay savings withdrawal
-- ---------------------------------------------------------------------------

create or replace function public.admin_delay_savings_withdrawal(
  p_request_id uuid,
  p_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_reason text := trim(coalesce(p_reason, ''));
  v_request public.withdrawal_requests%rowtype;
begin
  if v_actor is null then
    raise exception 'Unauthorized';
  end if;

  if not private.current_user_has_permission('savings.withdraw.approve') then
    raise exception 'Unauthorized: withdrawal approval permission required';
  end if;

  if length(v_reason) < 10 then
    raise exception 'Delay reason must be at least 10 characters';
  end if;

  if length(v_reason) > 500 then
    raise exception 'Delay reason must not exceed 500 characters';
  end if;

  select * into v_request
  from public.withdrawal_requests
  where id = p_request_id
  for update;

  if not found then
    raise exception 'Withdrawal request not found';
  end if;

  if v_request.status <> 'pending' then
    raise exception 'Withdrawal request is not pending';
  end if;

  update public.withdrawal_requests
  set status = 'delayed',
      reviewed_by = v_actor,
      reviewed_at = now(),
      reason = v_reason,
      updated_at = now()
  where id = p_request_id;

  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    old_data,
    new_data,
    metadata
  ) values (
    v_actor,
    'SAVINGS_WITHDRAWAL_DELAYED',
    'withdrawal_request',
    p_request_id,
    jsonb_build_object('status', 'pending'),
    jsonb_build_object('status', 'delayed', 'reason', v_reason),
    '{}'::jsonb
  );

  return jsonb_build_object(
    'withdrawal_request_id', p_request_id,
    'status', 'delayed',
    'reason', v_reason
  );
end;
$$;

revoke all on function public.admin_delay_savings_withdrawal(uuid, text) from public, anon;
grant execute on function public.admin_delay_savings_withdrawal(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- 12. Admin: reject savings withdrawal
-- ---------------------------------------------------------------------------

create or replace function public.admin_reject_savings_withdrawal(
  p_request_id uuid,
  p_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_reason text := trim(coalesce(p_reason, ''));
  v_request public.withdrawal_requests%rowtype;
begin
  if v_actor is null then
    raise exception 'Unauthorized';
  end if;

  if not private.current_user_has_permission('savings.withdraw.approve') then
    raise exception 'Unauthorized: withdrawal approval permission required';
  end if;

  if length(v_reason) < 10 then
    raise exception 'Rejection reason must be at least 10 characters';
  end if;

  if length(v_reason) > 500 then
    raise exception 'Rejection reason must not exceed 500 characters';
  end if;

  select * into v_request
  from public.withdrawal_requests
  where id = p_request_id
  for update;

  if not found then
    raise exception 'Withdrawal request not found';
  end if;

  if v_request.status <> 'pending' then
    raise exception 'Withdrawal request is not pending';
  end if;

  update public.withdrawal_requests
  set status = 'rejected',
      reviewed_by = v_actor,
      reviewed_at = now(),
      reason = v_reason,
      updated_at = now()
  where id = p_request_id;

  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    old_data,
    new_data,
    metadata
  ) values (
    v_actor,
    'SAVINGS_WITHDRAWAL_REJECTED',
    'withdrawal_request',
    p_request_id,
    jsonb_build_object('status', 'pending'),
    jsonb_build_object('status', 'rejected', 'reason', v_reason),
    '{}'::jsonb
  );

  return jsonb_build_object(
    'withdrawal_request_id', p_request_id,
    'status', 'rejected',
    'reason', v_reason
  );
end;
$$;

revoke all on function public.admin_reject_savings_withdrawal(uuid, text) from public, anon;
grant execute on function public.admin_reject_savings_withdrawal(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- 13. Admin: generate monthly savings obligations
-- ---------------------------------------------------------------------------

create or replace function public.admin_generate_monthly_savings_obligations(
  p_period_year integer default extract(year from current_date)::integer,
  p_period_month integer default extract(month from current_date)::integer
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_required numeric(18,2);
  v_due_day numeric;
  v_created integer := 0;
  v_member record;
  v_due_date date;
begin
  if v_actor is null then
    raise exception 'Unauthorized';
  end if;

  if not private.current_user_has_permission('savings.withdraw.approve')
     and not private.current_user_has_permission('membership.approve') then
    raise exception 'Unauthorized';
  end if;

  if p_period_month not between 1 and 12 then
    raise exception 'Invalid period month';
  end if;

  select public.get_active_rule_numeric('monthly_min_saving')
  into v_required;

  select public.get_active_rule_numeric('saving_due_day')
  into v_due_day;

  if v_required is null or v_required <= 0 then
    raise exception 'monthly_min_saving rule is not configured';
  end if;

  if v_due_day is null or v_due_day < 1 or v_due_day > 28 then
    raise exception 'saving_due_day must be between 1 and 28';
  end if;

  v_due_date := make_date(p_period_year, p_period_month, v_due_day::integer);

  for v_member in
    select m.id
    from public.members m
    where m.status = 'active'
  loop
    insert into public.savings_obligations (
      member_id,
      period_year,
      period_month,
      required_amount,
      due_date,
      status
    ) values (
      v_member.id,
      p_period_year,
      p_period_month,
      v_required,
      v_due_date,
      'pending'
    )
    on conflict (member_id, period_year, period_month) do nothing;

    if found then
      v_created := v_created + 1;
    end if;
  end loop;

  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    old_data,
    new_data,
    metadata
  ) values (
    v_actor,
    'SAVINGS_OBLIGATIONS_GENERATED',
    'savings_obligation_batch',
    null,
    null,
    null,
    jsonb_build_object(
      'period_year', p_period_year,
      'period_month', p_period_month,
      'required_amount', v_required,
      'due_date', v_due_date,
      'created_count', v_created
    )
  );

  return jsonb_build_object(
    'period_year', p_period_year,
    'period_month', p_period_month,
    'created_count', v_created,
    'required_amount', v_required,
    'due_date', v_due_date
  );
end;
$$;

revoke all on function public.admin_generate_monthly_savings_obligations(integer, integer) from public, anon;
grant execute on function public.admin_generate_monthly_savings_obligations(integer, integer) to authenticated;

-- ---------------------------------------------------------------------------
-- 14. Admin: process late monthly savings penalties
-- ---------------------------------------------------------------------------

create or replace function public.admin_process_late_savings()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_rate numeric(18,6);
  v_created integer := 0;
  v_obligation record;
  v_penalty numeric(18,2);
  v_transaction_id uuid;
  v_funding_account_id uuid;
  v_penalty_income_account_id uuid;
begin
  if v_actor is null then
    raise exception 'Unauthorized';
  end if;

  if not private.current_user_has_permission('savings.withdraw.approve')
     and not private.current_user_has_permission('membership.approve') then
    raise exception 'Unauthorized';
  end if;

  select public.get_active_rule_numeric('saving_late_penalty_rate')
  into v_rate;

  if v_rate is null or v_rate < 0 then
    raise exception 'saving_late_penalty_rate is not configured';
  end if;

  select a.id into v_funding_account_id
  from public.accounts a
  join public.account_types at on at.id = a.account_type_id
  where at.code = 'bank'
    and a.owner_member_id is null
    and a.owner_profile_id is null
    and a.status = 'active'
  limit 1;

  if v_funding_account_id is null then
    select a.id into v_funding_account_id
    from public.accounts a
    join public.account_types at on at.id = a.account_type_id
    where at.code = 'wallet'
      and a.owner_member_id is null
      and a.owner_profile_id is null
      and a.status = 'active'
    limit 1;
  end if;

  select a.id into v_penalty_income_account_id
  from public.accounts a
  join public.account_types at on at.id = a.account_type_id
  where at.code = 'penalty_income'
    and a.owner_member_id is null
    and a.owner_profile_id is null
    and a.status = 'active'
  limit 1;

  if v_funding_account_id is null or v_penalty_income_account_id is null then
    raise exception 'Penalty financial accounts are not configured';
  end if;

  for v_obligation in
    select so.*
    from public.savings_obligations so
    where so.due_date < current_date
      and so.paid_amount < so.required_amount
      and so.status in ('pending', 'partially_paid')
      and not exists (
        select 1 from public.savings_penalties sp
        where sp.obligation_id = so.id
      )
    for update
  loop
    v_penalty := round(v_obligation.required_amount * v_rate, 2);

    if v_penalty <= 0 then
      update public.savings_obligations
      set status = 'late', updated_at = now()
      where id = v_obligation.id;
      continue;
    end if;

    insert into public.transactions (
      transaction_type,
      source_type,
      source_id,
      member_id,
      amount,
      approval_status,
      transaction_status,
      initiated_by,
      approved_by,
      approved_at,
      description
    ) values (
      'savings_late_penalty',
      'savings_obligation',
      v_obligation.id,
      v_obligation.member_id,
      v_penalty,
      'approved',
      'posted',
      v_actor,
      v_actor,
      now(),
      'Monthly savings late penalty'
    ) returning id into v_transaction_id;

    insert into public.savings_penalties (
      obligation_id,
      rate,
      amount,
      transaction_id,
      charged_at
    ) values (
      v_obligation.id,
      v_rate,
      v_penalty,
      v_transaction_id,
      now()
    );

    update public.savings_obligations
    set late_penalty_amount = v_penalty,
        status = 'late',
        updated_at = now()
    where id = v_obligation.id;

    insert into public.transaction_entries (
      transaction_id,
      account_id,
      entry_type,
      amount
    ) values
      (v_transaction_id, v_funding_account_id, 'debit', v_penalty),
      (v_transaction_id, v_penalty_income_account_id, 'credit', v_penalty);

    insert into public.audit_logs (
      actor_user_id,
      action,
      entity_type,
      entity_id,
      old_data,
      new_data,
      metadata
    ) values (
      v_actor,
      'SAVINGS_LATE_PENALTY_APPLIED',
      'savings_obligation',
      v_obligation.id,
      jsonb_build_object('status', v_obligation.status),
      jsonb_build_object('status', 'late', 'penalty_amount', v_penalty),
      jsonb_build_object('transaction_id', v_transaction_id)
    );

    v_created := v_created + 1;
  end loop;

  return jsonb_build_object(
    'processed_count', v_created,
    'penalty_rate', v_rate
  );
end;
$$;

revoke all on function public.admin_process_late_savings() from public, anon;
grant execute on function public.admin_process_late_savings() to authenticated;

-- ---------------------------------------------------------------------------
-- 15. Admin: reverse a savings financial transaction
-- ---------------------------------------------------------------------------
-- Creates a reversal transaction rather than deleting the original.

create or replace function public.admin_reverse_savings_transaction(
  p_transaction_id uuid,
  p_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_reason text := trim(coalesce(p_reason, ''));
  v_original public.transactions%rowtype;
  v_reversal_id uuid;
  v_entry record;
begin
  if v_actor is null then
    raise exception 'Unauthorized';
  end if;

  if not private.current_user_has_permission('ledger.reverse') then
    raise exception 'Unauthorized: ledger reversal permission required';
  end if;

  if length(v_reason) < 10 then
    raise exception 'Reversal reason must be at least 10 characters';
  end if;

  if length(v_reason) > 500 then
    raise exception 'Reversal reason must not exceed 500 characters';
  end if;

  select * into v_original
  from public.transactions
  where id = p_transaction_id
    and transaction_type in (
      'savings_contribution',
      'savings_withdrawal',
      'savings_late_penalty'
    )
  for update;

  if not found then
    raise exception 'Savings transaction not found';
  end if;

  if v_original.transaction_status <> 'posted' then
    raise exception 'Only posted transactions can be reversed';
  end if;

  if exists (
    select 1 from public.transactions t
    where t.reversal_of_transaction_id = p_transaction_id
      and t.transaction_status = 'posted'
  ) then
    raise exception 'Transaction already has a posted reversal';
  end if;

  insert into public.transactions (
    transaction_type,
    source_type,
    source_id,
    profile_id,
    member_id,
    amount,
    approval_status,
    transaction_status,
    initiated_by,
    approved_by,
    approved_at,
    description,
    reversal_of_transaction_id
  ) values (
    'reversal',
    'reversal_of_transaction',
    p_transaction_id,
    v_original.profile_id,
    v_original.member_id,
    v_original.amount,
    'approved',
    'posted',
    v_actor,
    v_actor,
    now(),
    v_reason,
    p_transaction_id
  ) returning id into v_reversal_id;

  for v_entry in
    select transaction_id, account_id, entry_type, amount
    from public.transaction_entries
    where transaction_id = p_transaction_id
  loop
    insert into public.transaction_entries (
      transaction_id,
      account_id,
      entry_type,
      amount
    ) values (
      v_reversal_id,
      v_entry.account_id,
      case
        when v_entry.entry_type = 'debit' then 'credit'::public.transaction_entry_type
        else 'debit'::public.transaction_entry_type
      end,
      v_entry.amount
    );
  end loop;

  update public.transactions
  set transaction_status = 'reversed'
  where id = p_transaction_id;

  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    old_data,
    new_data,
    metadata
  ) values (
    v_actor,
    'SAVINGS_TRANSACTION_REVERSED',
    'transaction',
    p_transaction_id,
    jsonb_build_object('status', 'posted'),
    jsonb_build_object('status', 'reversed', 'reversal_transaction_id', v_reversal_id),
    jsonb_build_object('reason', v_reason)
  );

  return jsonb_build_object(
    'original_transaction_id', p_transaction_id,
    'reversal_transaction_id', v_reversal_id,
    'status', 'reversed'
  );
end;
$$;

revoke all on function public.admin_reverse_savings_transaction(uuid, text) from public, anon;
grant execute on function public.admin_reverse_savings_transaction(uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- 16. Validation / verification queries
-- ---------------------------------------------------------------------------
-- Run these after applying the migration.

-- A. Admin views exist:
-- select table_schema, table_name
-- from information_schema.views
-- where table_schema = 'public'
--   and table_name like 'admin_savings_%'
-- order by table_name;

-- B. Financial mutation grants:
-- select grantee, table_name, privilege_type
-- from information_schema.role_table_grants
-- where grantee = 'authenticated'
--   and table_name in (
--     'savings_obligations', 'savings_contributions', 'savings_penalties',
--     'withdrawal_requests', 'payments', 'payment_verifications',
--     'transactions', 'transaction_entries'
--   )
-- order by table_name, privilege_type;

-- C. RPC grants:
-- select routine_schema, routine_name, privilege_type
-- from information_schema.routine_privileges
-- where specific_schema = 'public'
--   and routine_name like 'admin_%savings%'
-- order by routine_name;

commit;
