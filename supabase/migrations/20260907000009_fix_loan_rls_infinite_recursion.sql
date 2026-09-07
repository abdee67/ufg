-- ===========================================================================
-- Unity Finance - Fix Loan RLS Infinite Recursion & Harden Loan Read RPCs
-- Migration: 20260907000009_fix_loan_rls_infinite_recursion.sql
-- Description:
--   1. Breaks mutual RLS policy recursion between loan_applications and
--      loan_guarantors (and related loan_approvals / loan_eligibility_checks)
--      by introducing SECURITY DEFINER helper predicates in schema private.
--   2. Hardens public.get_my_loan_applications(), public.get_my_loans(), and
--      public.get_loan_application_detail() to SECURITY DEFINER to eliminate
--      RLS overhead and recursive evaluation.
--   3. Enriches public.get_my_loan_applications() with full product metadata.
--   4. Creates public.get_my_guarantor_requests() RPC for fast, single-trip
--      retrieval of guarantor obligations with borrower details.
-- ===========================================================================

-- ===========================================================================
-- 1. Security Definer Helper Predicates
-- ===========================================================================

create or replace function private.is_guarantor_for_loan_application(
  p_application_id uuid,
  p_user_id uuid
)
returns boolean
language sql
security definer
set search_path = ''
stable
as $$
  select exists (
    select 1
    from public.loan_guarantors lg
    join public.members gm
      on gm.id = lg.guarantor_member_id
    where lg.loan_application_id = p_application_id
      and gm.profile_id = p_user_id
  );
$$;

revoke all on function private.is_guarantor_for_loan_application(uuid, uuid)
  from public, anon, authenticated;
grant execute on function private.is_guarantor_for_loan_application(uuid, uuid)
  to authenticated;


create or replace function private.is_applicant_for_loan_application(
  p_application_id uuid,
  p_user_id uuid
)
returns boolean
language sql
security definer
set search_path = ''
stable
as $$
  select exists (
    select 1
    from public.loan_applications la
    where la.id = p_application_id
      and la.applicant_profile_id = p_user_id
  );
$$;

revoke all on function private.is_applicant_for_loan_application(uuid, uuid)
  from public, anon, authenticated;
grant execute on function private.is_applicant_for_loan_application(uuid, uuid)
  to authenticated;


-- ===========================================================================
-- 2. Recreate RLS Policies to Break Cyclic Dependencies
-- ===========================================================================

-- Table: public.loan_applications
drop policy if exists "loan_applications_select_own_or_admin"
  on public.loan_applications;

create policy "loan_applications_select_own_or_admin"
on public.loan_applications
for select
to authenticated
using (
  applicant_profile_id = (select auth.uid())
  or private.current_user_is_admin()
  or private.is_guarantor_for_loan_application(id, (select auth.uid()))
);


-- Table: public.loan_guarantors
drop policy if exists "loan_guarantors_select_borrower_guarantor_or_admin"
  on public.loan_guarantors;

create policy "loan_guarantors_select_borrower_guarantor_or_admin"
on public.loan_guarantors
for select
to authenticated
using (
  private.current_user_is_admin()
  or private.is_applicant_for_loan_application(loan_application_id, (select auth.uid()))
  or exists (
    select 1
    from public.members m
    where m.id = guarantor_member_id
      and m.profile_id = (select auth.uid())
  )
);


-- Table: public.loan_approvals
drop policy if exists "loan_approvals_select_approver_or_admin"
  on public.loan_approvals;

create policy "loan_approvals_select_approver_or_admin"
on public.loan_approvals
for select
to authenticated
using (
  private.current_user_is_admin()
  or approver_profile_id = (select auth.uid())
  or private.is_applicant_for_loan_application(loan_application_id, (select auth.uid()))
);


-- Table: public.loan_eligibility_checks
drop policy if exists "loan_eligibility_checks_select_application_owner_or_admin"
  on public.loan_eligibility_checks;

create policy "loan_eligibility_checks_select_application_owner_or_admin"
on public.loan_eligibility_checks
for select
to authenticated
using (
  private.current_user_is_admin()
  or private.is_applicant_for_loan_application(loan_application_id, (select auth.uid()))
);


-- ===========================================================================
-- 3. Harden and Enrich Read RPCs to SECURITY DEFINER
-- ===========================================================================

-- 3.1 get_my_loan_applications
create or replace function public.get_my_loan_applications()
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
        'borrower_type', lp.borrower_type,
        'requested_amount', la.requested_amount,
        'approved_amount', la.approved_amount,
        'purpose', la.purpose,
        'eligibility_status', la.eligibility_status,
        'status', la.status,
        'submitted_at', la.submitted_at,
        'created_at', la.created_at,
        'reviewed_at', la.reviewed_at,
        'approved_at', la.approved_at,
        'eligibility_evaluated_at', la.eligibility_evaluated_at,
        'eligibility_snapshot', la.eligibility_snapshot,
        'product', jsonb_build_object(
          'id', lp.id,
          'code', lp.code,
          'name', lp.name,
          'borrower_type', lp.borrower_type,
          'service_charge_rate', lp.service_charge_rate,
          'max_amount', lp.max_amount,
          'term_months', lp.term_months
        )
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


-- 3.2 get_my_loans
create or replace function public.get_my_loans()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', l.id,
        'loan_number', l.loan_number,
        'loan_application_id', l.loan_application_id,
        'borrower_profile_id', l.borrower_profile_id,
        'member_id', l.member_id,
        'principal', l.principal,
        'service_charge_rate', l.service_charge_rate,
        'service_charge_amount', l.service_charge_amount,
        'total_repayment', l.total_repayment,
        'term_months', coalesce(l.term_months, 3),
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


-- 3.3 get_loan_application_detail
create or replace function public.get_loan_application_detail(
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
  v_applicant_profile_id uuid;
begin
  if v_actor is null then
    raise exception 'Not authenticated';
  end if;

  select la.applicant_profile_id
  into v_applicant_profile_id
  from public.loan_applications la
  where la.id = p_application_id;

  if not found then
    raise exception 'Loan application not found';
  end if;

  if not (
    v_applicant_profile_id = v_actor
    or private.current_user_is_admin()
    or private.is_guarantor_for_loan_application(p_application_id, v_actor)
  ) then
    raise exception 'Unauthorized';
  end if;

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
      'id', lp.id,
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


-- ===========================================================================
-- 4. Dedicated RPC for Guarantor Requests
-- ===========================================================================

create or replace function public.get_my_guarantor_requests()
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

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', lg.id,
        'loan_application_id', lg.loan_application_id,
        'guarantor_member_id', lg.guarantor_member_id,
        'guaranteed_amount', lg.guaranteed_amount,
        'potential_responsibility', lg.potential_responsibility,
        'status', lg.status,
        'requested_at', lg.requested_at,
        'approved_at', lg.approved_at,
        'rejected_at', lg.rejected_at,
        'released_at', lg.released_at,
        'borrower_name', pr.full_name,
        'borrower_phone', pr.phone,
        'requested_loan_amount', la.requested_amount,
        'service_charge_amount', round(la.requested_amount * lp.service_charge_rate, 2),
        'total_repayment', round(la.requested_amount * (1 + lp.service_charge_rate), 2),
        'term_months', lp.term_months
      )
      order by lg.requested_at desc
    ),
    '[]'::jsonb
  )
  into v_result
  from public.loan_guarantors lg
  join public.members gm
    on gm.id = lg.guarantor_member_id
  join public.loan_applications la
    on la.id = lg.loan_application_id
  join public.loan_products lp
    on lp.id = la.loan_product_id
  left join public.profiles pr
    on pr.id = la.applicant_profile_id
  where gm.profile_id = v_actor;

  return v_result;
end;
$$;

revoke all on function public.get_my_guarantor_requests()
  from public, anon;
grant execute on function public.get_my_guarantor_requests()
  to authenticated;
