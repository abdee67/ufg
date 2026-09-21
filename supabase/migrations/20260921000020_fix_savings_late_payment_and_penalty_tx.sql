-- ===========================================================================
-- Unity Finance - Fix Late Payment Contribution Type & Late Penalty Tx Metadata
-- Migration: 20260921000020_fix_savings_late_payment_and_penalty_tx.sql
-- Description:
--   1. Updates check constraint on savings_contributions to support 'late_payment'
--   2. Updates admin_verify_savings_payment to record late penalty payments as
--      'late_payment' contribution_type linked to the obligation
--   3. Updates process_late_savings_obligations to populate initiated_by,
--      approved_by, and approved_at in transactions for savings_late_penalty
--   4. Backfills null audit fields in existing savings_late_penalty transactions
--   5. Updates admin_savings_obligation_queue to include total_savings, last_payment_date, total_outstanding
--   6. Updates admin_savings_overview to accurately count late members across all periods
--      and include all current month contributions
-- ===========================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Support 'late_payment' in savings_contributions check constraint
-- ---------------------------------------------------------------------------
alter table public.savings_contributions
  drop constraint if exists savings_contributions_contribution_type_check;

alter table public.savings_contributions
  add constraint savings_contributions_contribution_type_check
  check (contribution_type in ('mandatory', 'voluntary', 'adjustment', 'late_payment'));

-- ---------------------------------------------------------------------------
-- 2. Update process_late_savings_obligations to populate initiated_by, approved_by, approved_at
-- ---------------------------------------------------------------------------
create or replace function public.process_late_savings_obligations(
  p_as_of_date date default current_date,
  p_member_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_penalty_rate numeric(8,4);
  v_obligation record;
  v_processed_count int := 0;
  v_penalty_amount numeric(18,2);
  v_existing_penalty_id uuid;
  v_txn_id uuid;
  v_txn_ref text;
  v_actor uuid;
begin
  -- Resolve actor: current auth user, or first admin profile, or obligation profile as fallback
  v_actor := auth.uid();
  if v_actor is null then
    select ur.user_id into v_actor
    from public.user_roles ur
    join public.roles r on r.id = ur.role_id
    where r.code in ('super_admin', 'admin')
    order by ur.created_at asc
    limit 1;
  end if;

  -- Retrieve configured penalty rate (default 10%)
  v_penalty_rate := coalesce(public.get_active_rule_numeric('saving_late_penalty_rate'), 0.10);

  for v_obligation in
    select so.*, m.profile_id
    from public.savings_obligations so
    join public.members m on m.id = so.member_id
    where so.due_date < p_as_of_date
      and so.paid_amount < so.required_amount
      and (p_member_id is null or so.member_id = p_member_id)
      and (
        so.status in ('pending', 'partially_paid')
        or so.late_penalty_amount = 0
        or not exists (
          select 1 from public.savings_penalties sp
          where sp.obligation_id = so.id
        )
      )
    for update skip locked
  loop
    v_penalty_amount := round(v_obligation.required_amount * v_penalty_rate, 2);

    -- Check if penalty was already recorded
    select id into v_existing_penalty_id
    from public.savings_penalties
    where obligation_id = v_obligation.id;

    if v_existing_penalty_id is null and v_penalty_amount > 0 then
      -- 1. Create Transaction for Penalty (Financial audit) with actor metadata
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
        'savings_late_penalty',
        'savings_obligation',
        v_obligation.id,
        v_obligation.profile_id,
        v_obligation.member_id,
        v_penalty_amount,
        'ETB',
        'approved',
        'posted',
        coalesce(v_actor, v_obligation.profile_id),
        coalesce(v_actor, v_obligation.profile_id),
        now(),
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
    end if;

    -- 3. Update Obligation Status to LATE and ensure penalty is populated
    update public.savings_obligations
    set
      status = 'late',
      late_penalty_amount = case
        when v_penalty_amount > 0 then v_penalty_amount
        else late_penalty_amount
      end,
      updated_at = now()
    where id = v_obligation.id;

    v_processed_count := v_processed_count + 1;
  end loop;

  if v_processed_count > 0 then
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
        'member_id', p_member_id,
        'processed_count', v_processed_count,
        'penalty_rate', v_penalty_rate
      )
    );
  end if;

  return jsonb_build_object(
    'as_of_date', p_as_of_date,
    'member_id', p_member_id,
    'late_obligations_processed', v_processed_count
  );
end;
$$;

revoke all on function public.process_late_savings_obligations(date, uuid) from public, anon;
grant execute on function public.process_late_savings_obligations(date, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 3. Backfill null audit columns in existing savings_late_penalty transactions
-- ---------------------------------------------------------------------------
update public.transactions
set
  initiated_by = coalesce(initiated_by, (select ur.user_id from public.user_roles ur join public.roles r on r.id = ur.role_id where r.code in ('super_admin', 'admin') limit 1), profile_id),
  approved_by = coalesce(approved_by, (select ur.user_id from public.user_roles ur join public.roles r on r.id = ur.role_id where r.code in ('super_admin', 'admin') limit 1), profile_id),
  approved_at = coalesce(approved_at, created_at, now())
where transaction_type = 'savings_late_penalty'
  and (initiated_by is null or approved_by is null or approved_at is null);

-- ---------------------------------------------------------------------------
-- 4. Update admin_verify_savings_payment to record 'late_payment' contribution_type
-- ---------------------------------------------------------------------------
create or replace function public.admin_verify_savings_payment(
  p_payment_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_actor uuid := auth.uid();
  v_payment public.payments%rowtype;
  v_member_id uuid;
  v_savings_account_id uuid;
  v_obligation public.savings_obligations%rowtype;
  v_remaining numeric(18,2) := 0;
  v_mandatory_amount numeric(18,2) := 0;
  v_late_penalty_due numeric(18,2) := 0;
  v_excess_after_mandatory numeric(18,2) := 0;
  v_late_payment_amount numeric(18,2) := 0;
  v_voluntary_amount numeric(18,2) := 0;
  v_transaction_id uuid;
  v_payment_method_code text;
  v_funding_account_id uuid;
  v_cash_account_id uuid;
  v_bank_account_id uuid;
  v_wallet_account_id uuid;
begin
  if v_actor is null then
    raise exception 'Unauthorized';
  end if;

  if not private.current_user_has_permission('savings.verify')
     and not private.current_user_has_permission('savings.manage') then
    raise exception 'Unauthorized';
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
    perform private.ensure_member_savings_account(v_member_id);
    v_savings_account_id := private.savings_account_for_member(v_member_id);
  end if;

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

  -- Resolve obligation (targeted by purpose_id or oldest pending/partially_paid/late)
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
      and (so.paid_amount < so.required_amount or so.late_penalty_amount > 0)
    order by so.due_date asc, so.created_at asc
    limit 1
    for update;
  end if;

  if v_obligation.id is not null then
    v_remaining := greatest(v_obligation.required_amount - v_obligation.paid_amount, 0);
    v_mandatory_amount := least(v_payment.amount, v_remaining);

    -- Check if obligation is late or has an unpaid late penalty
    v_late_penalty_due := greatest(coalesce(v_obligation.late_penalty_amount, 0), 0);
    v_excess_after_mandatory := greatest(v_payment.amount - v_mandatory_amount, 0);

    v_late_payment_amount := least(v_excess_after_mandatory, v_late_penalty_due);
    v_voluntary_amount := greatest(v_excess_after_mandatory - v_late_payment_amount, 0);
  else
    v_mandatory_amount := 0;
    v_late_payment_amount := 0;
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

  -- 1. Insert mandatory contribution
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
          when v_obligation.due_date < current_date or v_obligation.status = 'late' then 'late'::public.savings_obligation_status
          else 'partially_paid'::public.savings_obligation_status
        end,
        updated_at = now()
    where id = v_obligation.id;
  end if;

  -- 2. Insert late payment contribution (penalty portion)
  if v_late_payment_amount > 0 then
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
      v_late_payment_amount,
      v_payment.id,
      v_transaction_id,
      'late_payment'
    );
  end if;

  -- 3. Insert voluntary contribution (excess beyond mandatory and penalty)
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
      'late_payment_amount', v_late_payment_amount,
      'voluntary_amount', v_voluntary_amount
    ),
    jsonb_build_object(
      'obligation_id', v_obligation.id,
      'payment_id', v_payment.id,
      'payment_method', v_payment_method_code
    )
  );

  return jsonb_build_object(
    'payment_id', v_payment.id,
    'transaction_id', v_transaction_id,
    'status', 'verified',
    'mandatory_amount', v_mandatory_amount,
    'late_payment_amount', v_late_payment_amount,
    'voluntary_amount', v_voluntary_amount
  );
end;
$$;

revoke all on function public.admin_verify_savings_payment(uuid) from public, anon;
grant execute on function public.admin_verify_savings_payment(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 5. Backfill existing voluntary contributions that were late payments
-- ---------------------------------------------------------------------------
update public.savings_contributions sc
set
  contribution_type = 'late_payment',
  obligation_id = p.purpose_id
from public.payments p
join public.savings_obligations so on so.id = p.purpose_id
where sc.payment_id = p.id
  and sc.contribution_type = 'voluntary'
  and sc.obligation_id is null
  and so.late_penalty_amount > 0
  and sc.amount <= so.late_penalty_amount;

-- ---------------------------------------------------------------------------
-- 6. Update View: admin_savings_obligation_queue
-- Preserve exact existing 16 columns in original order, append additions at end
-- ---------------------------------------------------------------------------
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
  so.updated_at,
  (greatest(so.required_amount - so.paid_amount, 0) + coalesce(so.late_penalty_amount, 0))::numeric(18,2) as total_outstanding,
  coalesce(mss.savings_balance, 0)::numeric(18,2) as total_savings,
  (
    select max(c.created_at)
    from public.savings_contributions c
    where c.member_id = m.id
  ) as last_payment_date
from public.savings_obligations so
join public.members m on m.id = so.member_id
join public.profiles p on p.id = m.profile_id
left join public.member_savings_summary mss on mss.member_id = m.id;

grant select on public.admin_savings_obligation_queue to authenticated;

-- ---------------------------------------------------------------------------
-- 7. Update View: admin_savings_overview
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
    select coalesce(sum(sc.amount), 0)
    from public.savings_contributions sc
    where sc.created_at >= date_trunc('month', current_date)
  )::numeric(18,2) as current_month_collected,

  (
    select coalesce(sum(so.required_amount), 0)
    from public.savings_obligations so, current_period cp
    where so.period_year = cp.period_year
      and so.period_month = cp.period_month
  )::numeric(18,2) as current_month_expected,

  (
    select count(distinct so.member_id)
    from public.savings_obligations so
    where so.status = 'late'
  ) as late_members,

  (
    select coalesce(sum(greatest(so.required_amount - so.paid_amount, 0) + coalesce(so.late_penalty_amount, 0)), 0)
    from public.savings_obligations so
    where so.status in ('pending', 'partially_paid', 'late')
      and (so.paid_amount < so.required_amount or so.late_penalty_amount > 0)
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

commit;
