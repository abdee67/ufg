-- ============================================================================
-- Unity Finance Group — Loan V2 client contract and RLS hardening
--
-- This migration is intentionally additive to Loan Model V2.  It removes the
-- residual V1 policy graph from loan_applications and exposes V2-specific read
-- contracts for the Flutter member and guarantor experiences.
-- ============================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Break all historical loan_applications policy cycles.
--
-- Earlier installations used policy predicates which joined loan_guarantors
-- back to loan_applications.  Policy names differ between environments, so
-- dropping a single known name is not sufficient.  V2 mutations are RPC-only;
-- the sole direct read policy needed here is owner-or-authorized-reviewer.
-- Guarantors use the narrowly scoped V2 inbox/detail RPCs below.
-- ---------------------------------------------------------------------------
do $$
declare
  v_policy record;
begin
  for v_policy in
    select policyname
    from pg_policies
    where schemaname = 'public'
      and tablename = 'loan_applications'
  loop
    execute format(
      'drop policy if exists %I on public.loan_applications',
      v_policy.policyname
    );
  end loop;
end;
$$;

create policy loan_applications_select_owner_or_reviewer_v2
on public.loan_applications
for select
to authenticated
using (
  applicant_profile_id = (select auth.uid())
  or (select private.current_user_has_permission('loan.review'))
);

-- Member guarantor search intentionally exposes only the same minimal identity
-- fields already available to an outsider.  It never exposes savings or contact
-- data, and lets the member flow use the authoritative picker rather than UUID
-- text entry.
grant execute on function public.search_outsider_loan_guarantors(text)
  to authenticated;

-- The public outsider flow needs a server-owned product identifier to submit a
-- request.  Return the single active outsider product without granting table
-- access to anonymous clients.
create or replace function public.get_active_outsider_loan_product_v2()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'id', lp.id,
    'code', lp.code,
    'name', lp.name,
    'borrower_type', lp.borrower_type,
    'service_charge_rate', lp.service_charge_rate,
    'max_amount', least(lp.max_amount, 20000::numeric),
    'term_months', lp.term_months,
    'active', lp.active
  )
  from public.loan_products lp
  where lp.active = true
    and lp.borrower_type = 'outsider'
  order by lp.id
  limit 1;
$$;

revoke all on function public.get_active_outsider_loan_product_v2() from public, authenticated, anon;
grant execute on function public.get_active_outsider_loan_product_v2() to anon;

-- ---------------------------------------------------------------------------
-- 2. V2 member read contracts.
--
-- SECURITY DEFINER is appropriate here because each function performs its own
-- auth.uid()/permission check, uses a pinned search_path, and returns only the
-- fields needed by the caller.  This avoids re-entering RLS while composing
-- aggregate JSON responses.
-- ---------------------------------------------------------------------------
create or replace function public.get_my_member_loan_applications_v2()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', la.id,
        'application_number', la.application_number,
        'applicant_profile_id', la.applicant_profile_id,
        'member_id', la.member_id,
        'loan_product_id', la.loan_product_id,
        'requested_amount', la.requested_amount,
        'approved_amount', la.approved_amount,
        'purpose', la.purpose,
        'eligibility_status', la.eligibility_status,
        'eligibility_snapshot', la.eligibility_snapshot,
        'status', la.status,
        'submitted_at', la.submitted_at,
        'reviewed_at', la.reviewed_at,
        'approved_at', la.approved_at,
        'created_at', la.created_at,
        'product', jsonb_build_object(
          'id', lp.id,
          'code', lp.code,
          'name', lp.name,
          'borrower_type', lp.borrower_type,
          'service_charge_rate', lp.service_charge_rate,
          'max_amount', lp.max_amount,
          'term_months', lp.term_months,
          'active', lp.active
        ),
        'guarantor', (
          select jsonb_build_object(
            'id', g.id,
            'loan_application_id', g.loan_application_id,
            'guarantor_member_id', g.guarantor_member_id,
            'status', g.status,
            'requested_at', g.requested_at,
            'responded_at', g.responded_at,
            'requested_amount', g.requested_amount_snapshot,
            'service_charge_rate', g.service_charge_rate_snapshot,
            'total_repayment', g.total_repayment_snapshot,
            'term_months', g.term_months_snapshot
          )
          from public.member_loan_guarantors g
          where g.loan_application_id = la.id
          order by g.created_at desc
          limit 1
        )
      )
      order by la.created_at desc
    ),
    '[]'::jsonb
  )
  from public.loan_applications la
  join public.loan_products lp on lp.id = la.loan_product_id
  where la.applicant_profile_id = (select auth.uid());
$$;

revoke all on function public.get_my_member_loan_applications_v2() from public, anon;
grant execute on function public.get_my_member_loan_applications_v2() to authenticated;

create or replace function public.get_member_loan_application_detail_v2(
  p_application_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_result jsonb;
begin
  if v_actor is null then
    raise exception 'Not authenticated';
  end if;

  if not exists (
    select 1
    from public.loan_applications la
    where la.id = p_application_id
      and (
        la.applicant_profile_id = v_actor
        or private.current_user_has_permission('loan.review')
      )
  ) then
    raise exception 'Loan application not found or unauthorized';
  end if;

  select jsonb_build_object(
    'id', la.id,
    'application_number', la.application_number,
    'applicant_profile_id', la.applicant_profile_id,
    'member_id', la.member_id,
    'loan_product_id', la.loan_product_id,
    'requested_amount', la.requested_amount,
    'approved_amount', la.approved_amount,
    'purpose', la.purpose,
    'status', la.status,
    'eligibility_status', la.eligibility_status,
    'eligibility_snapshot', la.eligibility_snapshot,
    'submitted_at', la.submitted_at,
    'reviewed_at', la.reviewed_at,
    'approved_at', la.approved_at,
    'created_at', la.created_at,
    'product', jsonb_build_object(
      'id', lp.id,
      'code', lp.code,
      'name', lp.name,
      'borrower_type', lp.borrower_type,
      'service_charge_rate', lp.service_charge_rate,
      'max_amount', lp.max_amount,
      'term_months', lp.term_months,
      'active', lp.active
    ),
    'guarantor', (
      select jsonb_build_object(
        'id', g.id,
        'loan_application_id', g.loan_application_id,
        'guarantor_member_id', g.guarantor_member_id,
        'status', g.status,
        'requested_at', g.requested_at,
        'responded_at', g.responded_at,
        'rejected_reason', g.rejected_reason,
        'requested_amount', g.requested_amount_snapshot,
        'service_charge_rate', g.service_charge_rate_snapshot,
        'total_repayment', g.total_repayment_snapshot,
        'term_months', g.term_months_snapshot
      )
      from public.member_loan_guarantors g
      where g.loan_application_id = la.id
      order by g.created_at desc
      limit 1
    ),
    'approvals', coalesce((
      select jsonb_agg(jsonb_build_object(
        'approver_profile_id', a.approver_profile_id,
        'decision', a.decision,
        'comment', a.comment,
        'decided_at', a.decided_at
      ) order by a.decided_at)
      from public.loan_approvals a
      where a.loan_application_id = la.id
    ), '[]'::jsonb),
    'eligibility_checks', coalesce((
      select jsonb_agg(jsonb_build_object(
        'check_code', ec.check_code,
        'result', ec.result,
        'value', ec.value,
        'reason', ec.reason,
        'checked_at', ec.checked_at,
        'evaluation_run_id', ec.evaluation_run_id
      ) order by ec.checked_at desc)
      from public.loan_eligibility_checks ec
      where ec.loan_application_id = la.id
    ), '[]'::jsonb)
  )
  into v_result
  from public.loan_applications la
  join public.loan_products lp on lp.id = la.loan_product_id
  where la.id = p_application_id;

  return v_result;
end;
$$;

revoke all on function public.get_member_loan_application_detail_v2(uuid) from public, anon;
grant execute on function public.get_member_loan_application_detail_v2(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 3. V2 guarantor inbox.
-- ---------------------------------------------------------------------------
create or replace function public.get_my_guarantor_requests_v2()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  with current_member as (
    select m.id
    from public.members m
    where m.profile_id = (select auth.uid())
      and m.status = 'active'
    limit 1
  ), requests as (
    select
      g.id,
      'member'::text as borrower_type,
      g.loan_application_id as application_id,
      g.guarantor_member_id,
      g.status,
      g.requested_amount_snapshot as requested_amount,
      g.service_charge_rate_snapshot as service_charge_rate,
      g.total_repayment_snapshot as total_repayment,
      g.term_months_snapshot as term_months,
      g.requested_at,
      g.responded_at,
      coalesce(p.full_name, bm.member_number) as applicant_name,
      null::text as applicant_phone
    from public.member_loan_guarantors g
    join current_member cm on cm.id = g.guarantor_member_id
    join public.loan_applications la on la.id = g.loan_application_id
    join public.members bm on bm.id = la.member_id
    left join public.profiles p on p.id = bm.profile_id

    union all

    select
      g.id,
      'outsider'::text as borrower_type,
      g.outsider_loan_application_id as application_id,
      g.guarantor_member_id,
      g.status,
      g.requested_amount_snapshot as requested_amount,
      g.service_charge_rate_snapshot as service_charge_rate,
      g.total_repayment_snapshot as total_repayment,
      g.term_months_snapshot as term_months,
      g.requested_at,
      g.responded_at,
      oa.applicant_full_name as applicant_name,
      oa.applicant_phone as applicant_phone
    from public.outsider_loan_guarantors g
    join current_member cm on cm.id = g.guarantor_member_id
    join public.outsider_loan_applications oa on oa.id = g.outsider_loan_application_id
  )
  select coalesce(
    jsonb_agg(jsonb_build_object(
      'id', id,
      'borrower_type', borrower_type,
      'application_id', application_id,
      'guarantor_member_id', guarantor_member_id,
      'status', status,
      'requested_amount', requested_amount,
      'service_charge_rate', service_charge_rate,
      'total_repayment', total_repayment,
      'term_months', term_months,
      'requested_at', requested_at,
      'responded_at', responded_at,
      'applicant_name', applicant_name,
      'applicant_phone', applicant_phone
    ) order by requested_at desc),
    '[]'::jsonb
  )
  from requests;
$$;

revoke all on function public.get_my_guarantor_requests_v2() from public, anon;
grant execute on function public.get_my_guarantor_requests_v2() to authenticated;

commit;
