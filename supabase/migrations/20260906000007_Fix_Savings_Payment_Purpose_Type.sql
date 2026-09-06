-- ===========================================================================
-- Unity Finance - Fix Savings Payment Purpose Type & Verification
-- Migration: 20260906000007_Fix_Savings_Payment_Purpose_Type.sql
-- Description:
--   The member app RPC (submit_savings_payment in 20260901000002_savings_feature.sql)
--   submits savings payments with purpose_type = 'savings_contribution'.
--   This migration updates admin_savings_payment_queue, admin_savings_overview,
--   admin_verify_savings_payment, and admin_reject_savings_payment to support
--   both 'savings' and 'savings_contribution', maintaining the exact column
--   contract expected by the admin web application.
-- ===========================================================================

-- 1. Index update
drop index if exists public.payments_savings_queue_idx;
create index if not exists payments_savings_queue_idx
on public.payments(status, submitted_at desc)
where purpose_type in ('savings', 'savings_contribution');

-- 2. View: admin_savings_payment_queue
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

grant select on public.admin_savings_payment_queue to authenticated;

-- 3. View: admin_savings_overview
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

grant select on public.admin_savings_overview to authenticated;

-- 4. Helper: Return sa.id from public.savings_accounts (matches foreign key references)
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

-- 5. RPC: admin_verify_savings_payment
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

-- 6. RPC: admin_reject_savings_payment
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
