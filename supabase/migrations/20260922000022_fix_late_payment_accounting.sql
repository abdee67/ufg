-- ===========================================================================
-- Unity Finance - Fix Late Payment Accounting Entries
-- Migration: 20260922000022_fix_late_payment_accounting.sql
-- Description:
--   The admin_verify_savings_payment function currently credits the FULL
--   payment amount to the member's savings account, even when part of the
--   payment is a late-payment penalty. This migration fixes the accounting
--   so that:
--     - Mandatory + voluntary amounts  →  credit member's savings account
--     - Late-payment penalty amount    →  credit penalty_income system account
--   It also reduces the late_penalty_amount on the obligation when the
--   penalty is paid.
-- ===========================================================================

begin;

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
  v_savings_credit_amount numeric(18,2) := 0;
  v_transaction_id uuid;
  v_payment_method_code text;
  v_funding_account_id uuid;
  v_cash_account_id uuid;
  v_bank_account_id uuid;
  v_wallet_account_id uuid;
  v_penalty_income_account_id uuid;
  v_member_savings_account_id uuid;
begin
  -- -----------------------------------------------------------------------
  -- Authorization
  -- -----------------------------------------------------------------------
  if v_actor is null then
    raise exception 'Unauthorized';
  end if;

  if not private.current_user_is_admin()
     and not private.current_user_has_permission('payment.verify')
     and not private.current_user_has_permission('savings.verify')
     and not private.current_user_has_permission('savings.manage') then
    raise exception 'Unauthorized';
  end if;

  -- -----------------------------------------------------------------------
  -- Load and validate payment
  -- -----------------------------------------------------------------------
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

  -- -----------------------------------------------------------------------
  -- Resolve member and savings account
  -- -----------------------------------------------------------------------
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

  -- -----------------------------------------------------------------------
  -- Resolve funding (source) and penalty_income accounts
  -- -----------------------------------------------------------------------
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

  -- Look up the penalty_income system account
  v_penalty_income_account_id := private.system_account_id('penalty_income'::public.account_type_code);

  -- -----------------------------------------------------------------------
  -- Resolve obligation
  -- -----------------------------------------------------------------------
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

  -- -----------------------------------------------------------------------
  -- Compute amount allocation
  -- -----------------------------------------------------------------------
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

  -- Amount that goes to the member's savings account (mandatory + voluntary)
  v_savings_credit_amount := v_mandatory_amount + v_voluntary_amount;

  -- -----------------------------------------------------------------------
  -- Update payment status
  -- -----------------------------------------------------------------------
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

  -- -----------------------------------------------------------------------
  -- Create transaction
  -- -----------------------------------------------------------------------
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

  -- -----------------------------------------------------------------------
  -- Insert contributions
  -- -----------------------------------------------------------------------

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

    -- Reduce the outstanding penalty on the obligation
    update public.savings_obligations
    set late_penalty_amount = greatest(late_penalty_amount - v_late_payment_amount, 0),
        updated_at = now()
    where id = v_obligation.id;
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

  -- -----------------------------------------------------------------------
  -- Insert transaction entries (double-entry accounting)
  --   Debit:  funding account (cash/bank/wallet)  — full payment amount
  --   Credit: member savings account               — mandatory + voluntary
  --   Credit: penalty_income system account         — late payment penalty
  -- -----------------------------------------------------------------------

  -- Always debit the funding source for the full payment
  insert into public.transaction_entries (
    transaction_id,
    account_id,
    entry_type,
    amount
  ) values (
    v_transaction_id,
    v_funding_account_id,
    'debit',
    v_payment.amount
  );

  -- Get the member's savings account (ledger account, not savings_accounts row)
  select sa.account_id into v_member_savings_account_id
  from public.savings_accounts sa
  where sa.id = v_savings_account_id;

  -- Credit member's savings account for mandatory + voluntary only
  if v_savings_credit_amount > 0 then
    insert into public.transaction_entries (
      transaction_id,
      account_id,
      entry_type,
      amount
    ) values (
      v_transaction_id,
      v_member_savings_account_id,
      'credit',
      v_savings_credit_amount
    );
  end if;

  -- Credit penalty_income account for the late payment portion
  if v_late_payment_amount > 0 and v_penalty_income_account_id is not null then
    insert into public.transaction_entries (
      transaction_id,
      account_id,
      entry_type,
      amount
    ) values (
      v_transaction_id,
      v_penalty_income_account_id,
      'credit',
      v_late_payment_amount
    );
  end if;

  -- -----------------------------------------------------------------------
  -- Audit log
  -- -----------------------------------------------------------------------
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
      'voluntary_amount', v_voluntary_amount,
      'savings_credit_amount', v_savings_credit_amount
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
    'voluntary_amount', v_voluntary_amount,
    'savings_credit_amount', v_savings_credit_amount
  );
end;
$$;

revoke all on function public.admin_verify_savings_payment(uuid) from public, anon;
grant execute on function public.admin_verify_savings_payment(uuid) to authenticated;

-- ===========================================================================
-- Backfill: Fix existing late-payment transaction entries
-- For any existing late_payment contributions whose transaction_entries
-- credited the member's savings account, move that portion to penalty_income.
-- ===========================================================================
do $$
declare
  v_penalty_account_id uuid;
  v_rec record;
begin
  -- Get the penalty_income system account
  select a.id into v_penalty_account_id
  from public.accounts a
  join public.account_types at on at.id = a.account_type_id
  where at.code = 'penalty_income'
    and a.owner_member_id is null
    and a.owner_profile_id is null
    and a.status = 'active'
  limit 1;

  if v_penalty_account_id is null then
    raise notice 'penalty_income account not found, skipping backfill';
    return;
  end if;

  -- For each late_payment contribution, check if the transaction only
  -- has a single credit entry to the member's savings account (old pattern)
  for v_rec in
    select
      sc.transaction_id,
      sc.amount as late_amount,
      sa.account_id as member_account_id
    from public.savings_contributions sc
    join public.savings_accounts sa on sa.id = sc.savings_account_id
    where sc.contribution_type = 'late_payment'
      and sc.transaction_id is not null
      -- Only fix if no penalty_income entry exists yet for this transaction
      and not exists (
        select 1
        from public.transaction_entries te
        where te.transaction_id = sc.transaction_id
          and te.account_id = v_penalty_account_id
      )
  loop
    -- Reduce the credit on the member's savings account
    update public.transaction_entries
    set amount = amount - v_rec.late_amount
    where transaction_id = v_rec.transaction_id
      and account_id = v_rec.member_account_id
      and entry_type = 'credit';

    -- Add a new credit entry to penalty_income
    insert into public.transaction_entries (
      transaction_id,
      account_id,
      entry_type,
      amount
    ) values (
      v_rec.transaction_id,
      v_penalty_account_id,
      'credit',
      v_rec.late_amount
    );

    -- Also reduce late_penalty_amount on the obligation
    update public.savings_obligations so
    set late_penalty_amount = greatest(late_penalty_amount - v_rec.late_amount, 0),
        updated_at = now()
    from public.savings_contributions sc2
    where sc2.transaction_id = v_rec.transaction_id
      and sc2.contribution_type = 'late_payment'
      and sc2.obligation_id = so.id
      and so.late_penalty_amount > 0;
  end loop;

  -- Clean up: delete any credit entries that now have amount <= 0
  delete from public.transaction_entries
  where amount <= 0;
end;
$$;

commit;
