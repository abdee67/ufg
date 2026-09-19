-- ===========================================================================
-- Unity Finance - Fix Savings Late Obligation Status & Penalty Calculation
-- Migration: 20260919000017_fix_savings_late_obligation_and_penalty.sql
-- Description:
--   1. Enhances public.process_late_savings_obligations to support both
--      global batch/cron execution and per-member on-demand lazy processing.
--   2. Updates get_my_savings_summary and get_my_savings_obligations to volatile,
--      triggering lazy late evaluation so the app immediately reflects overdue
--      status and penalty amounts when the member views their savings.
--   3. Updates admin_verify_savings_payment so partial payments after due_date
--      preserve the 'late' status instead of reverting to 'partially_paid'.
--   4. Updates admin_process_late_savings to delegate to the unified processor.
--   5. Backfills any existing overdue savings obligations to 'late' with penalties.
--   6. Configures pg_cron job for automated nightly processing when available.
-- ===========================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Unified Late Obligation & Penalty Processor
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
begin
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
-- 2. Member RPCs (Updated to volatile with on-demand lazy processing)
-- ---------------------------------------------------------------------------

-- 2.1 Get My Savings Summary
create or replace function public.get_my_savings_summary()
returns jsonb
language plpgsql
volatile
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

  -- Trigger lazy on-demand check for overdue obligations for this member
  perform public.process_late_savings_obligations(current_date, v_member_id);

  v_total_savings := private.get_member_savings_balance(v_member_id);
  v_secured_savings := private.get_member_secured_savings(v_member_id);
  v_available_savings := private.get_member_available_savings(v_member_id);

  select status into v_account_status
  from public.savings_accounts
  where member_id = v_member_id;

  v_account_status := coalesce(v_account_status, 'active');

  v_curr_year := extract(year from current_date)::int;
  v_curr_month := extract(month from current_date)::int;

  -- Check for oldest unpaid/late obligation needing attention
  select * into v_obligation
  from public.savings_obligations
  where member_id = v_member_id
    and status in ('pending', 'partially_paid', 'late')
    and paid_amount < required_amount
  order by due_date asc, period_year asc, period_month asc
  limit 1;

  -- Fall back to current period obligation if no unpaid obligations exist
  if v_obligation is null then
    select * into v_obligation
    from public.savings_obligations
    where member_id = v_member_id
      and period_year = v_curr_year
      and period_month = v_curr_month
    limit 1;
  end if;

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

revoke all on function public.get_my_savings_summary() from public, anon;
grant execute on function public.get_my_savings_summary() to authenticated;

-- 2.2 Get My Savings Obligations
create or replace function public.get_my_savings_obligations()
returns jsonb
language plpgsql
volatile
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

  -- Trigger lazy on-demand check for overdue obligations for this member
  perform public.process_late_savings_obligations(current_date, v_member_id);

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

revoke all on function public.get_my_savings_obligations() from public, anon;
grant execute on function public.get_my_savings_obligations() to authenticated;

-- ---------------------------------------------------------------------------
-- 3. Fix admin_verify_savings_payment: Preserve 'late' status on partial payments
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
          when v_obligation.due_date < current_date or v_obligation.status = 'late' then 'late'::public.savings_obligation_status
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
-- 4. Admin RPC: admin_process_late_savings delegates to unified processor
-- ---------------------------------------------------------------------------
create or replace function public.admin_process_late_savings()
returns jsonb
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_actor uuid := (select auth.uid());
  v_res jsonb;
begin
  if v_actor is null then
    raise exception 'Unauthorized';
  end if;

  if not private.current_user_has_permission('savings.withdraw.approve')
     and not private.current_user_has_permission('membership.approve') then
    raise exception 'Unauthorized';
  end if;

  v_res := public.process_late_savings_obligations(current_date, null);
  return v_res;
end;
$$;

revoke all on function public.admin_process_late_savings() from public, anon;
grant execute on function public.admin_process_late_savings() to authenticated;

-- ---------------------------------------------------------------------------
-- 5. Backfill: Process all existing overdue obligations immediately
-- ---------------------------------------------------------------------------
do $$
begin
  perform public.process_late_savings_obligations(current_date, null);
end;
$$;

-- ---------------------------------------------------------------------------
-- 6. Scheduler: pg_cron setup (if installed)
-- ---------------------------------------------------------------------------
do $$
declare
  v_job record;
begin
  if to_regnamespace('cron') is not null then
    for v_job in
      select j.jobid
      from cron.job j
      where j.jobname = 'unity-finance-savings-late-processor'
    loop
      perform cron.unschedule(v_job.jobid);
    end loop;

    perform cron.schedule(
      'unity-finance-savings-late-processor',
      '5 0 * * *',
      $command$select public.process_late_savings_obligations();$command$
    );
  end if;
end;
$$;

commit;
