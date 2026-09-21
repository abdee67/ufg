-- ===========================================================================
-- Unity Finance - Add Pending Payment Tracking to Savings Obligations
-- Migration: 20260921000019_savings_pending_payment_tracking.sql
-- Description:
--   Updates get_my_savings_summary and get_my_savings_obligations RPCs to
--   include pending payment information (has_pending_payment, pending_payment_amount)
--   so the member app can show "Payment Submitted - Awaiting Verification"
--   status on obligations that have unverified payments.
-- ===========================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Updated get_my_savings_summary with pending payment info
-- ---------------------------------------------------------------------------
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
  v_pending_payment_amount numeric(18,2) := 0;
  v_has_pending_payment boolean := false;
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
    -- Check if there are any pending (unverified) payments for this obligation
    select
      coalesce(sum(p.amount), 0),
      count(*) > 0
    into v_pending_payment_amount, v_has_pending_payment
    from public.payments p
    where p.purpose_id = v_obligation.id
      and p.purpose_type in ('savings', 'savings_contribution')
      and p.status = 'pending';

    v_curr_obligation := jsonb_build_object(
      'id', v_obligation.id,
      'period_year', v_obligation.period_year,
      'period_month', v_obligation.period_month,
      'required_amount', v_obligation.required_amount,
      'due_date', v_obligation.due_date,
      'paid_amount', v_obligation.paid_amount,
      'late_penalty_amount', v_obligation.late_penalty_amount,
      'status', v_obligation.status,
      'total_due', (v_obligation.required_amount - v_obligation.paid_amount + v_obligation.late_penalty_amount),
      'has_pending_payment', v_has_pending_payment,
      'pending_payment_amount', v_pending_payment_amount
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

-- ---------------------------------------------------------------------------
-- 2. Updated get_my_savings_obligations with pending payment info
-- ---------------------------------------------------------------------------
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
      'has_pending_payment', coalesce(pp.has_pending, false),
      'pending_payment_amount', coalesce(pp.pending_amount, 0),
      'created_at', so.created_at,
      'updated_at', so.updated_at
    ) order by so.due_date desc
  ), '[]'::jsonb)
  into v_result
  from public.savings_obligations so
  left join lateral (
    select
      count(*) > 0 as has_pending,
      coalesce(sum(p.amount), 0) as pending_amount
    from public.payments p
    where p.purpose_id = so.id
      and p.purpose_type in ('savings', 'savings_contribution')
      and p.status = 'pending'
  ) pp on true
  where so.member_id = v_member_id;

  return v_result;
end;
$$;

revoke all on function public.get_my_savings_obligations() from public, anon;
grant execute on function public.get_my_savings_obligations() to authenticated;

commit;
