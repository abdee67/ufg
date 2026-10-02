begin;

-- ============================================================================
-- Migration 36: Restore and update cancel_loan_application RPC
--
-- 1. In migration 20260907000010_loan_model_v2_modification.sql,
--    cancel_loan_application was revoked from authenticated users.
-- 2. In migration 20260924000025_enforce_single_active_member_loan_and_guarantor_sync.sql,
--    the legacy public.loan_guarantors table was dropped in favor of
--    public.member_loan_guarantors.
--
-- This migration restores public.cancel_loan_application(uuid):
-- - Verifies caller authentication and application ownership
-- - Ensures the loan is not already disbursed or in a terminal state
-- - Cancels the application (status = 'cancelled')
-- - Releases any member loan guarantor requests in public.member_loan_guarantors
-- - Records an audit log entry
-- - Explicitly grants EXECUTE to authenticated users
-- ============================================================================

create or replace function public.cancel_loan_application(
  p_loan_application_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_status public.loan_application_status;
  v_member_id uuid;
begin
  if v_actor is null then
    raise exception 'Not authenticated';
  end if;

  if p_loan_application_id is null then
    raise exception 'Loan application ID is required';
  end if;

  -- Lock and retrieve application ensuring it belongs to current authenticated user
  select la.status, la.member_id
  into v_status, v_member_id
  from public.loan_applications la
  where la.id = p_loan_application_id
    and (
      la.applicant_profile_id = v_actor
      or la.member_id in (select m.id from public.members m where m.profile_id = v_actor)
    )
  for update;

  if not found then
    raise exception 'Application not found or unauthorized';
  end if;

  -- Prevent cancellation if loan has already been disbursed
  if exists (
    select 1
    from public.loans l
    where l.loan_application_id = p_loan_application_id
  ) then
    raise exception 'A disbursed loan cannot be cancelled. Use repayment or reversal workflows';
  end if;

  -- Only pre-disbursement, non-terminal applications can be cancelled
  if v_status in ('approved', 'rejected', 'cancelled') then
    raise exception 'Application cannot be cancelled in its current state';
  end if;

  -- Update application status
  update public.loan_applications
  set
    status = 'cancelled',
    updated_at = now()
  where id = p_loan_application_id;

  -- Release any active guarantor requests in member_loan_guarantors
  update public.member_loan_guarantors
  set
    status = 'released',
    responded_at = coalesce(responded_at, now()),
    updated_at = now()
  where loan_application_id = p_loan_application_id
    and status in ('requested', 'accepted');

  -- Record audit log
  insert into public.audit_logs(
    actor_user_id,
    action,
    entity_type,
    entity_id,
    new_data
  )
  values (
    v_actor,
    'LOAN_APPLICATION_CANCELLED',
    'loan_application',
    p_loan_application_id,
    jsonb_build_object(
      'application_id', p_loan_application_id,
      'status', 'cancelled',
      'cancelled_by', 'applicant'
    )
  );

  return jsonb_build_object(
    'application_id', p_loan_application_id,
    'status', 'cancelled'
  );
end;
$$;

revoke all on function public.cancel_loan_application(uuid) from public, anon;
grant execute on function public.cancel_loan_application(uuid) to authenticated;

commit;
