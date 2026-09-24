begin;

-- ============================================================================
-- 1. Drop legacy public.loan_guarantors table & cleanup
--
-- In Migration V2/V3, guarantor management was partitioned into:
--   - public.member_loan_guarantors (for member loan applications)
--   - public.outsider_loan_guarantors (for outsider loan applications)
-- The legacy public.loan_guarantors table from the initial MVP is no longer
-- referenced or needed by the Flutter app, Admin panel, or production RPCs.
-- ============================================================================

drop trigger if exists trg_sync_member_loan_guarantors on public.member_loan_guarantors;
drop function if exists private.sync_member_loan_guarantors_to_legacy();
drop table if exists public.loan_guarantors cascade;


-- ============================================================================
-- 2. Update get_my_member_loan_limit_v2()
-- Expose whether the member has an active loan or a pending application,
-- and whether they can currently apply.
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
  v_paid_saving_months integer := 0;
  v_has_active_loan boolean := false;
  v_has_pending_application boolean := false;
  v_active_loan_id uuid;
  v_pending_application_id uuid;
  v_block_reason text := null;
  v_can_apply boolean := false;
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

  select count(*)
  into v_paid_saving_months
  from public.savings_obligations so
  where so.member_id=v_member_id
    and so.status='paid';

  -- Check if member has an active loan (not fully repaid)
  select l.id
  into v_active_loan_id
  from public.loans l
  where l.member_id = v_member_id
    and l.status in ('active', 'overdue', 'defaulted')
  limit 1;

  v_has_active_loan := (v_active_loan_id is not null);

  -- Check if member has an active application in progress
  select la.id
  into v_pending_application_id
  from public.loan_applications la
  where la.member_id = v_member_id
    and la.status in ('submitted', 'eligible', 'under_review', 'approved')
  order by la.created_at desc
  limit 1;

  v_has_pending_application := (v_pending_application_id is not null);

  if v_has_active_loan then
    v_block_reason := 'ACTIVE_LOAN';
  elsif v_has_pending_application then
    v_block_reason := 'PENDING_APPLICATION';
  elsif v_paid_saving_months < 2 then
    v_block_reason := 'MINIMUM_SAVINGS_NOT_MET';
  end if;

  v_can_apply := (v_paid_saving_months >= 2 and not v_has_active_loan and not v_has_pending_application);

  return jsonb_build_object(
    'member_id', v_member_id,
    'total_savings', v_savings,
    'maximum_loan_amount', v_max,
    'global_cap', 20000,
    'paid_saving_months', v_paid_saving_months,
    'required_saving_months', 2,
    'meets_minimum_saving_history', v_paid_saving_months >= 2,
    'has_active_loan', v_has_active_loan,
    'has_pending_application', v_has_pending_application,
    'active_loan_id', v_active_loan_id,
    'pending_application_id', v_pending_application_id,
    'can_apply', v_can_apply,
    'block_reason', v_block_reason,
    'formula', 'MIN(total_savings * 2, 20000)'
  );
end;
$$;

revoke all on function public.get_my_member_loan_limit_v2() from public, anon;
grant execute on function public.get_my_member_loan_limit_v2() to authenticated;


-- ============================================================================
-- 3. Enforce single active loan / single application rule on submission
-- ============================================================================

do $enforce_single_active_member_loan$
declare
  v_definition text;
  v_old_anchor constant text := $anchor$  if p_guarantor_member_id = v_member_id then
    raise exception 'A member cannot guarantee their own loan';
  end if;$anchor$;
  v_new_anchor constant text := $anchor$  -- Member cannot apply if they have an active loan in progress
  if exists (
    select 1
    from public.loans l
    where l.member_id = v_member_id
      and l.status in ('active', 'overdue', 'defaulted')
  ) then
    raise exception 'You have an active loan. You must fully repay your current loan before applying for a new one.';
  end if;

  -- Member cannot apply if they already have a pending application
  if exists (
    select 1
    from public.loan_applications la
    where la.member_id = v_member_id
      and la.status in ('submitted', 'eligible', 'under_review', 'approved')
  ) then
    raise exception 'You already have a loan application in progress. You cannot apply again until it is completed or cancelled.';
  end if;

  if p_guarantor_member_id = v_member_id then
    raise exception 'A member cannot guarantee their own loan';
  end if;$anchor$;
begin
  select pg_get_functiondef(
    'public.submit_member_loan_application_v2(uuid,numeric,text,uuid)'::regprocedure
  ) into v_definition;

  if position(v_old_anchor in v_definition) = 0 then
    raise exception 'submit_member_loan_application_v2 has an unexpected guarantor guard; refusing an unsafe rewrite';
  end if;

  execute replace(v_definition, v_old_anchor, v_new_anchor);
end;
$enforce_single_active_member_loan$;

commit;
