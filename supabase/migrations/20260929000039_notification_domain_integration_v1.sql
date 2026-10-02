/*
===============================================================================
UNITY FINANCE GROUP
Notification Domain Integration V1 (hybrid workflow trigger layer)
===============================================================================

Target:
  Existing Unity Finance schema after:
    20260929000038_notification_infrastructure_v1.sql

Purpose:
  Emit in-app notifications + queued push jobs for member/admin workflow
  events that are NOT posted financial transactions, without re-deploying the
  large, frequently revised financial RPCs.

Design (hybrid, deliberate):
  - Financial posting/reversal events stay where they are: the transaction
    trigger created by migration 38.
  - Workflow state machines (payments, savings withdrawals, loan applications,
    guarantor requests, repayment submissions, expenses, membership, serious
    loan defaults) are observed at their own table boundary via AFTER triggers.
    This avoids CREATE OR REPLACE of 15+ financial RPCs that have been
    re-deployed many times, which would be a ledger regression risk.

Safety rule (non-negotiable):
  Every trigger function below wraps its body in an exception handler and
  downgrades any failure to a WARNING. Notification creation must never roll
  back or fail a financial/workflow command. The in-app inbox is durable, so a
  lost notification can be backfilled; a rolled-back financial command cannot
  be safely retried by the user.

Copy rules:
  - No secrets, tokens, documents or proof URLs in notification bodies.
  - Keep navigation data machine-readable in `data` (target_type + ids).
  - Statuses are compared as text (::text) so this migration is safe whether a
    status column is text or a PostgreSQL enum.

Permission codes (verified against the live schema definitions):
  payment.verify, savings.withdraw.approve, loan.review, expense.view,
  membership.approve
===============================================================================
*/

begin;

-- ============================================================================
-- 0. Dependency guards
-- ============================================================================

do $$
begin
  if to_regprocedure(
       'private.create_notification_v1(uuid,text,text,text,text,text,jsonb,text,uuid,text)'
     ) is null
     or to_regprocedure(
       'private.notify_users_with_permission_v1(text,text,text,text,text,text,jsonb,text,uuid,text,uuid)'
     ) is null
  then
    raise exception
      'Notification infrastructure v1 is missing. Apply 20260929000038_notification_infrastructure_v1.sql first.';
  end if;

  if to_regclass('public.payments') is null
     or to_regclass('public.withdrawal_requests') is null
     or to_regclass('public.loan_applications') is null
     or to_regclass('public.outsider_loan_applications') is null
     or to_regclass('public.member_loan_guarantors') is null
     or to_regclass('public.outsider_loan_guarantors') is null
     or to_regclass('public.loan_repayment_submissions') is null
     or to_regclass('public.expenses') is null
     or to_regclass('public.membership_applications') is null
     or to_regclass('public.loan_default_events') is null
  then
    raise exception
      'Unity Finance workflow schema is missing. Apply the Savings/Loan/Payment/Expense/Membership migrations first.';
  end if;
end;
$$;

-- ============================================================================
-- 1. Shared helpers
-- ============================================================================

-- Resolve the authenticated profile that owns a member row.
create or replace function private.notification_profile_for_member_v1(
  p_member_id uuid
)
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select m.profile_id
  from public.members m
  where m.id = p_member_id;
$$;

revoke all on function private.notification_profile_for_member_v1(uuid)
  from public, anon, authenticated;

-- ============================================================================
-- 2. Payments (savings contributions + member payment submissions)
-- ============================================================================

create or replace function private.notify_payment_workflow_v1()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid;
  v_new_status text;
  v_old_status text;
begin
  v_actor := (select auth.uid());
  v_new_status := new.status::text;

  if tg_op = 'UPDATE' then
    v_old_status := old.status::text;
  end if;

  begin
    if tg_op = 'INSERT' and v_new_status = 'pending' then
      perform private.notify_users_with_permission_v1(
        'payment.verify',
        'payment',
        'payment.submitted',
        'Payment submitted',
        format(
          'Payment %s of %s ETB is awaiting verification.',
          coalesce(new.reference_number, 'N/A'),
          new.amount::text
        ),
        'normal',
        jsonb_build_object(
          'target_type', 'payment',
          'payment_id', new.id,
          'payment_reference', new.reference_number,
          'purpose_type', new.purpose_type,
          'amount', new.amount,
          'currency', new.currency
        ),
        'payment',
        new.id,
        'payment:submitted:' || new.id::text,
        v_actor
      );
    elsif tg_op = 'UPDATE'
          and v_new_status = 'rejected'
          and v_old_status is distinct from 'rejected'
          and new.payer_profile_id is not null
    then
      perform private.create_notification_v1(
        new.payer_profile_id,
        'payment',
        'payment.rejected',
        'Payment rejected',
        format(
          'Payment %s was rejected. Open Unity Finance to review the reason.',
          coalesce(new.reference_number, 'N/A')
        ),
        'high',
        jsonb_build_object(
          'target_type', 'payment',
          'payment_id', new.id,
          'payment_reference', new.reference_number,
          'purpose_type', new.purpose_type,
          'amount', new.amount,
          'currency', new.currency,
          'reason', new.rejection_reason
        ),
        'payment',
        new.id,
        'payment:rejected:' || new.id::text
      );
    end if;
  exception
    when others then
      raise warning 'notify_payment_workflow_v1 skipped for payment %: %',
        new.id, sqlerrm;
  end;

  return new;
end;
$$;

revoke all on function private.notify_payment_workflow_v1()
  from public, anon, authenticated;

drop trigger if exists trg_payment_notification_v1 on public.payments;
create trigger trg_payment_notification_v1
after insert or update of status
on public.payments
for each row execute function private.notify_payment_workflow_v1();

-- ============================================================================
-- 3. Savings withdrawal requests
-- ============================================================================

create or replace function private.notify_withdrawal_workflow_v1()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid;
  v_new_status text;
  v_old_status text;
  v_profile_id uuid;
  v_type text;
  v_title text;
  v_body text;
begin
  v_actor := (select auth.uid());
  v_new_status := new.status::text;

  if tg_op = 'UPDATE' then
    v_old_status := old.status::text;
  end if;

  begin
    if tg_op = 'INSERT' and v_new_status = 'pending' then
      perform private.notify_users_with_permission_v1(
        'savings.withdraw.approve',
        'savings',
        'savings.withdrawal_requested',
        'Savings withdrawal requested',
        format(
          'A savings withdrawal request of %s ETB is awaiting review.',
          new.amount::text
        ),
        'high',
        jsonb_build_object(
          'target_type', 'withdrawal',
          'withdrawal_id', new.id,
          'member_id', new.member_id,
          'amount', new.amount
        ),
        'savings_withdrawal',
        new.id,
        'withdrawal:requested:' || new.id::text,
        v_actor
      );
    elsif tg_op = 'UPDATE'
          and v_old_status is distinct from v_new_status
          and v_new_status in ('approved', 'rejected', 'delayed')
    then
      v_profile_id := private.notification_profile_for_member_v1(new.member_id);

      if v_profile_id is not null then
        v_type := case v_new_status
          when 'approved' then 'savings.withdrawal_approved'
          when 'delayed' then 'savings.withdrawal_delayed'
          else 'savings.withdrawal_rejected'
        end;

        v_title := case v_new_status
          when 'approved' then 'Savings withdrawal approved'
          when 'delayed' then 'Savings withdrawal delayed'
          else 'Savings withdrawal rejected'
        end;

        v_body := case v_new_status
          when 'approved' then format(
            'Your savings withdrawal request of %s ETB has been approved. The payout will be reflected after posting.',
            new.amount::text
          )
          when 'delayed' then format(
            'Your savings withdrawal request of %s ETB was delayed. Open Unity Finance to review the reason.',
            new.amount::text
          )
          else format(
            'Your savings withdrawal request of %s ETB was rejected. Open Unity Finance to review the reason.',
            new.amount::text
          )
        end;

        perform private.create_notification_v1(
          v_profile_id,
          'savings',
          v_type,
          v_title,
          v_body,
          'high',
          jsonb_build_object(
            'target_type', 'withdrawal',
            'withdrawal_id', new.id,
            'member_id', new.member_id,
            'amount', new.amount,
            'status', v_new_status,
            'reason', new.reason
          ),
          'savings_withdrawal',
          new.id,
          'withdrawal:status:' || new.id::text || ':' || v_new_status
        );
      end if;
    end if;
  exception
    when others then
      raise warning 'notify_withdrawal_workflow_v1 skipped for request %: %',
        new.id, sqlerrm;
  end;

  return new;
end;
$$;

revoke all on function private.notify_withdrawal_workflow_v1()
  from public, anon, authenticated;

drop trigger if exists trg_withdrawal_notification_v1
  on public.withdrawal_requests;
create trigger trg_withdrawal_notification_v1
after insert or update of status
on public.withdrawal_requests
for each row execute function private.notify_withdrawal_workflow_v1();

-- ============================================================================
-- 4. Loan applications (member)
-- ============================================================================

create or replace function private.notify_member_loan_application_v1()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid;
  v_new_status text;
  v_old_status text;
  v_decision text;
begin
  v_actor := (select auth.uid());
  v_new_status := new.status::text;

  if tg_op = 'UPDATE' then
    v_old_status := old.status::text;
  end if;

  begin
    if tg_op = 'INSERT' and v_new_status = 'submitted' then
      perform private.notify_users_with_permission_v1(
        'loan.review',
        'loan',
        'loan.application_submitted',
        'New loan application',
        format(
          'Loan application %s (%s ETB) is awaiting review.',
          coalesce(new.application_number, 'N/A'),
          new.requested_amount::text
        ),
        'high',
        jsonb_build_object(
          'target_type', 'loan_application',
          'application_id', new.id,
          'application_number', new.application_number,
          'borrower_type', 'member',
          'member_id', new.member_id,
          'requested_amount', new.requested_amount
        ),
        'loan_application',
        new.id,
        'loan_application:submitted:' || new.id::text,
        v_actor
      );
    elsif tg_op = 'UPDATE'
          and v_old_status is distinct from v_new_status
          and v_new_status in ('approved', 'rejected')
          and new.applicant_profile_id is not null
    then
      v_decision := case when v_new_status = 'approved' then 'approved' else 'rejected' end;

      perform private.create_notification_v1(
        new.applicant_profile_id,
        'loan',
        case v_decision when 'approved' then 'loan.approved' else 'loan.rejected' end,
        case v_decision when 'approved' then 'Loan approved' else 'Loan not approved' end,
        case v_decision
          when 'approved' then format(
            'Loan application %s has been approved. Open Unity Finance to review the details.',
            coalesce(new.application_number, 'N/A')
          )
          else format(
            'Loan application %s was not approved. Open Unity Finance to review the details.',
            coalesce(new.application_number, 'N/A')
          )
        end,
        'high',
        jsonb_build_object(
          'target_type', 'loan_application',
          'application_id', new.id,
          'application_number', new.application_number,
          'borrower_type', 'member',
          'decision', v_decision
        ),
        'loan_application',
        new.id,
        'loan:decision:' || new.id::text || ':' || v_decision
      );
    end if;
  exception
    when others then
      raise warning 'notify_member_loan_application_v1 skipped for application %: %',
        new.id, sqlerrm;
  end;

  return new;
end;
$$;

revoke all on function private.notify_member_loan_application_v1()
  from public, anon, authenticated;

drop trigger if exists trg_member_loan_application_notification_v1
  on public.loan_applications;
create trigger trg_member_loan_application_notification_v1
after insert or update of status
on public.loan_applications
for each row execute function private.notify_member_loan_application_v1();

-- ============================================================================
-- 5. Loan applications (outsider)
--    Outsider applications have no borrower profile, so only the loan-review
--    administrators are notified.
-- ============================================================================

create or replace function private.notify_outsider_loan_application_v1()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid;
  v_new_status text;
  v_old_status text;
begin
  v_actor := (select auth.uid());
  v_new_status := new.status::text;

  if tg_op = 'UPDATE' then
    v_old_status := old.status::text;
  end if;

  begin
    if tg_op = 'INSERT' and v_new_status = 'submitted' then
      perform private.notify_users_with_permission_v1(
        'loan.review',
        'loan',
        'loan.application_submitted',
        'New outsider loan application',
        format(
          'Outsider loan application %s (%s ETB) is awaiting review.',
          coalesce(new.application_number, 'N/A'),
          new.requested_amount::text
        ),
        'high',
        jsonb_build_object(
          'target_type', 'loan_application',
          'application_id', new.id,
          'application_number', new.application_number,
          'borrower_type', 'outsider',
          'applicant_name', new.applicant_full_name,
          'requested_amount', new.requested_amount
        ),
        'loan_application',
        new.id,
        'outsider_loan_application:submitted:' || new.id::text,
        v_actor
      );
    elsif tg_op = 'UPDATE'
          and v_old_status is distinct from v_new_status
          and v_new_status in ('approved', 'rejected')
    then
      perform private.notify_users_with_permission_v1(
        'loan.review',
        'loan',
        'loan.outsider_application_decided',
        case when v_new_status = 'approved'
             then 'Outsider loan approved'
             else 'Outsider loan not approved' end,
        format(
          'Outsider loan application %s is now %s.',
          coalesce(new.application_number, 'N/A'),
          v_new_status
        ),
        'normal',
        jsonb_build_object(
          'target_type', 'loan_application',
          'application_id', new.id,
          'application_number', new.application_number,
          'borrower_type', 'outsider',
          'decision', v_new_status
        ),
        'loan_application',
        new.id,
        'outsider_loan_application:decision:' || new.id::text || ':' || v_new_status,
        v_actor
      );
    end if;
  exception
    when others then
      raise warning 'notify_outsider_loan_application_v1 skipped for application %: %',
        new.id, sqlerrm;
  end;

  return new;
end;
$$;

revoke all on function private.notify_outsider_loan_application_v1()
  from public, anon, authenticated;

drop trigger if exists trg_outsider_loan_application_notification_v1
  on public.outsider_loan_applications;
create trigger trg_outsider_loan_application_notification_v1
after insert or update of status
on public.outsider_loan_applications
for each row execute function private.notify_outsider_loan_application_v1();

-- ============================================================================
-- 6. Loan guarantors (member loans)
-- ============================================================================

create or replace function private.notify_member_guarantor_workflow_v1()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid;
  v_new_status text;
  v_old_status text;
  v_guarantor_profile_id uuid;
  v_borrower_profile_id uuid;
  v_application_number text;
begin
  v_actor := (select auth.uid());
  v_new_status := new.status::text;

  if tg_op = 'UPDATE' then
    v_old_status := old.status::text;
  end if;

  begin
    if tg_op = 'INSERT' and v_new_status = 'requested' then
      v_guarantor_profile_id :=
        private.notification_profile_for_member_v1(new.guarantor_member_id);

      select la.application_number
        into v_application_number
      from public.loan_applications la
      where la.id = new.loan_application_id;

      if v_guarantor_profile_id is not null then
        perform private.create_notification_v1(
          v_guarantor_profile_id,
          'loan',
          'loan.guarantor_required',
          'Guarantor approval required',
          format(
            'You have been requested as guarantor for loan application %s. Open Unity Finance to respond.',
            coalesce(v_application_number, 'N/A')
          ),
          'critical',
          jsonb_build_object(
            'target_type', 'loan_application',
            'application_id', new.loan_application_id,
            'application_number', v_application_number,
            'guarantor_request_id', new.id
          ),
          'loan_application',
          new.loan_application_id,
          'guarantor:requested:' || new.id::text
        );
      end if;
    elsif tg_op = 'UPDATE'
          and v_old_status is distinct from v_new_status
          and v_new_status in ('accepted', 'rejected')
    then
      select
        la.applicant_profile_id,
        la.application_number
      into
        v_borrower_profile_id,
        v_application_number
      from public.loan_applications la
      where la.id = new.loan_application_id;

      if v_borrower_profile_id is not null then
        perform private.create_notification_v1(
          v_borrower_profile_id,
          'loan',
          case v_new_status
            when 'accepted' then 'loan.guarantor_accepted'
            else 'loan.guarantor_rejected'
          end,
          case v_new_status
            when 'accepted' then 'Guarantor accepted'
            else 'Guarantor rejected'
          end,
          case v_new_status
            when 'accepted' then format(
              'Your guarantor has accepted loan application %s.',
              coalesce(v_application_number, 'N/A')
            )
            else format(
              'Your guarantor has rejected loan application %s. Open Unity Finance to review your options.',
              coalesce(v_application_number, 'N/A')
            )
          end,
          'high',
          jsonb_build_object(
            'target_type', 'loan_application',
            'application_id', new.loan_application_id,
            'application_number', v_application_number,
            'guarantor_request_id', new.id,
            'decision', v_new_status
          ),
          'loan_application',
          new.loan_application_id,
          'guarantor:decision:' || new.id::text || ':' || v_new_status
        );
      end if;
    end if;
  exception
    when others then
      raise warning 'notify_member_guarantor_workflow_v1 skipped for request %: %',
        new.id, sqlerrm;
  end;

  return new;
end;
$$;

revoke all on function private.notify_member_guarantor_workflow_v1()
  from public, anon, authenticated;

drop trigger if exists trg_member_guarantor_notification_v1
  on public.member_loan_guarantors;
create trigger trg_member_guarantor_notification_v1
after insert or update of status
on public.member_loan_guarantors
for each row execute function private.notify_member_guarantor_workflow_v1();

-- ============================================================================
-- 7. Loan guarantors (outsider loans)
--    The guarantor is always a member, so they can be notified directly. The
--    outsider applicant has no profile, so decisions go to loan reviewers.
-- ============================================================================

create or replace function private.notify_outsider_guarantor_workflow_v1()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid;
  v_new_status text;
  v_old_status text;
  v_guarantor_profile_id uuid;
  v_application_number text;
begin
  v_actor := (select auth.uid());
  v_new_status := new.status::text;

  if tg_op = 'UPDATE' then
    v_old_status := old.status::text;
  end if;

  begin
    select ola.application_number
      into v_application_number
    from public.outsider_loan_applications ola
    where ola.id = new.outsider_loan_application_id;

    if tg_op = 'INSERT' and v_new_status = 'requested' then
      v_guarantor_profile_id :=
        private.notification_profile_for_member_v1(new.guarantor_member_id);

      if v_guarantor_profile_id is not null then
        perform private.create_notification_v1(
          v_guarantor_profile_id,
          'loan',
          'loan.guarantor_required',
          'Guarantor approval required',
          format(
            'You have been requested as guarantor for outsider loan application %s. Open Unity Finance to respond.',
            coalesce(v_application_number, 'N/A')
          ),
          'critical',
          jsonb_build_object(
            'target_type', 'loan_application',
            'application_id', new.outsider_loan_application_id,
            'application_number', v_application_number,
            'borrower_type', 'outsider',
            'guarantor_request_id', new.id
          ),
          'loan_application',
          new.outsider_loan_application_id,
          'outsider_guarantor:requested:' || new.id::text
        );
      end if;
    elsif tg_op = 'UPDATE'
          and v_old_status is distinct from v_new_status
          and v_new_status in ('accepted', 'rejected')
    then
      perform private.notify_users_with_permission_v1(
        'loan.review',
        'loan',
        case v_new_status
          when 'accepted' then 'loan.guarantor_accepted'
          else 'loan.guarantor_rejected'
        end,
        case v_new_status
          when 'accepted' then 'Outsider guarantor accepted'
          else 'Outsider guarantor rejected'
        end,
        format(
          'The guarantor for outsider loan application %s has %s.',
          coalesce(v_application_number, 'N/A'),
          v_new_status
        ),
        'high',
        jsonb_build_object(
          'target_type', 'loan_application',
          'application_id', new.outsider_loan_application_id,
          'application_number', v_application_number,
          'borrower_type', 'outsider',
          'guarantor_request_id', new.id,
          'decision', v_new_status
        ),
        'loan_application',
        new.outsider_loan_application_id,
        'outsider_guarantor:decision:' || new.id::text || ':' || v_new_status,
        v_actor
      );
    end if;
  exception
    when others then
      raise warning 'notify_outsider_guarantor_workflow_v1 skipped for request %: %',
        new.id, sqlerrm;
  end;

  return new;
end;
$$;

revoke all on function private.notify_outsider_guarantor_workflow_v1()
  from public, anon, authenticated;

drop trigger if exists trg_outsider_guarantor_notification_v1
  on public.outsider_loan_guarantors;
create trigger trg_outsider_guarantor_notification_v1
after insert or update of status
on public.outsider_loan_guarantors
for each row execute function private.notify_outsider_guarantor_workflow_v1();

-- ============================================================================
-- 8. Loan repayment submissions
-- ============================================================================

create or replace function private.notify_repayment_submission_v1()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid;
  v_new_status text;
  v_old_status text;
begin
  v_actor := (select auth.uid());
  v_new_status := new.status::text;

  if tg_op = 'UPDATE' then
    v_old_status := old.status::text;
  end if;

  begin
    if tg_op = 'INSERT' and v_new_status = 'pending' then
      perform private.notify_users_with_permission_v1(
        'payment.verify',
        'payment',
        'loan.repayment_submitted',
        'Loan repayment submitted',
        format(
          'A loan repayment submission of %s ETB is awaiting verification.',
          new.amount::text
        ),
        'normal',
        jsonb_build_object(
          'target_type', 'loan_repayment_submission',
          'submission_id', new.id,
          'loan_id', new.loan_id,
          'borrower_type', new.borrower_type::text,
          'amount', new.amount
        ),
        'loan_repayment_submission',
        new.id,
        'loan_repayment:submitted:' || new.id::text,
        v_actor
      );
    elsif tg_op = 'UPDATE'
          and v_new_status = 'rejected'
          and v_old_status is distinct from 'rejected'
          and new.payer_profile_id is not null
    then
      perform private.create_notification_v1(
        new.payer_profile_id,
        'payment',
        'loan.repayment_rejected',
        'Repayment submission rejected',
        format(
          'Your loan repayment submission of %s ETB was rejected. Open Unity Finance to review the reason.',
          new.amount::text
        ),
        'high',
        jsonb_build_object(
          'target_type', 'loan_repayment_submission',
          'submission_id', new.id,
          'loan_id', new.loan_id,
          'amount', new.amount,
          'reason', new.rejected_reason
        ),
        'loan_repayment_submission',
        new.id,
        'loan_repayment:rejected:' || new.id::text
      );
    end if;
  exception
    when others then
      raise warning 'notify_repayment_submission_v1 skipped for submission %: %',
        new.id, sqlerrm;
  end;

  return new;
end;
$$;

revoke all on function private.notify_repayment_submission_v1()
  from public, anon, authenticated;

drop trigger if exists trg_repayment_submission_notification_v1
  on public.loan_repayment_submissions;
create trigger trg_repayment_submission_notification_v1
after insert or update of status
on public.loan_repayment_submissions
for each row execute function private.notify_repayment_submission_v1();

-- ============================================================================
-- 9. Expenses (group expenses - admin workflow only, never member ledgers)
-- ============================================================================

create or replace function private.notify_expense_workflow_v1()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid;
  v_new_status text;
  v_old_status text;
begin
  v_actor := (select auth.uid());
  v_new_status := new.status::text;

  if tg_op = 'UPDATE' then
    v_old_status := old.status::text;
  end if;

  begin
    if tg_op = 'INSERT' and v_new_status = 'pending' then
      perform private.notify_users_with_permission_v1(
        'expense.view',
        'system',
        'expense.submitted',
        'Expense submitted',
        format(
          'Expense %s (%s ETB, %s) is awaiting review.',
          coalesce(new.reference_number, 'N/A'),
          new.amount::text,
          new.category
        ),
        'normal',
        jsonb_build_object(
          'target_type', 'expense',
          'expense_id', new.id,
          'expense_reference', new.reference_number,
          'amount', new.amount,
          'category', new.category
        ),
        'expense',
        new.id,
        'expense:submitted:' || new.id::text,
        v_actor
      );
    elsif tg_op = 'UPDATE'
          and v_old_status is distinct from v_new_status
          and v_new_status in ('approved', 'rejected')
          and new.requested_by is not null
    then
      perform private.create_notification_v1(
        new.requested_by,
        'system',
        case v_new_status
          when 'approved' then 'expense.approved'
          else 'expense.rejected'
        end,
        case v_new_status
          when 'approved' then 'Expense approved'
          else 'Expense rejected'
        end,
        case v_new_status
          when 'approved' then format(
            'Expense %s (%s ETB) was approved.',
            coalesce(new.reference_number, 'N/A'),
            new.amount::text
          )
          else format(
            'Expense %s (%s ETB) was rejected. Open the admin panel to review the reason.',
            coalesce(new.reference_number, 'N/A'),
            new.amount::text
          )
        end,
        'normal',
        jsonb_build_object(
          'target_type', 'expense',
          'expense_id', new.id,
          'expense_reference', new.reference_number,
          'amount', new.amount,
          'status', v_new_status
        ),
        'expense',
        new.id,
        'expense:decision:' || new.id::text || ':' || v_new_status
      );
    end if;
  exception
    when others then
      raise warning 'notify_expense_workflow_v1 skipped for expense %: %',
        new.id, sqlerrm;
  end;

  return new;
end;
$$;

revoke all on function private.notify_expense_workflow_v1()
  from public, anon, authenticated;

drop trigger if exists trg_expense_notification_v1 on public.expenses;
create trigger trg_expense_notification_v1
after insert or update of status
on public.expenses
for each row execute function private.notify_expense_workflow_v1();

-- ============================================================================
-- 10. Membership applications
-- ============================================================================

create or replace function private.notify_membership_application_v1()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid;
  v_new_status text;
  v_old_status text;
begin
  v_actor := (select auth.uid());
  v_new_status := new.status::text;

  if tg_op = 'UPDATE' then
    v_old_status := old.status::text;
  end if;

  begin
    if tg_op = 'INSERT' and v_new_status = 'pending' then
      perform private.notify_users_with_permission_v1(
        'membership.approve',
        'membership',
        'membership.application_submitted',
        'Membership application submitted',
        'A membership application is awaiting review in the admin panel.',
        'normal',
        jsonb_build_object(
          'target_type', 'membership_application',
          'application_id', new.id
        ),
        'membership_application',
        new.id,
        'membership:submitted:' || new.id::text,
        v_actor
      );
    elsif tg_op = 'UPDATE'
          and v_old_status is distinct from v_new_status
          and v_new_status in ('approved', 'rejected')
          and new.applicant_id is not null
    then
      perform private.create_notification_v1(
        new.applicant_id,
        'membership',
        case v_new_status
          when 'approved' then 'membership.approved'
          else 'membership.rejected'
        end,
        case v_new_status
          when 'approved' then 'Membership approved'
          else 'Membership not approved'
        end,
        case v_new_status
          when 'approved' then
            'Your membership application has been approved. Welcome to Unity Finance Group.'
          else
            'Your membership application was not approved. Open Unity Finance to review the details.'
        end,
        'high',
        jsonb_build_object(
          'target_type', 'membership_application',
          'application_id', new.id,
          'decision', v_new_status
        ),
        'membership_application',
        new.id,
        'membership:decision:' || new.id::text || ':' || v_new_status
      );
    end if;
  exception
    when others then
      raise warning 'notify_membership_application_v1 skipped for application %: %',
        new.id, sqlerrm;
  end;

  return new;
end;
$$;

revoke all on function private.notify_membership_application_v1()
  from public, anon, authenticated;

drop trigger if exists trg_membership_application_notification_v1
  on public.membership_applications;
create trigger trg_membership_application_notification_v1
after insert or update of status
on public.membership_applications
for each row execute function private.notify_membership_application_v1();

-- ============================================================================
-- 11. Serious loan defaults (event table boundary, no RPC rewrite needed)
--     process_serious_loan_defaults_v3() writes DEFAULT_NOTICE /
--     BORROWING_SUSPENDED / GUARANTOR_NOTICE rows into public.loan_default_events,
--     so the notification boundary is that table instead of the RPC.
-- ============================================================================

create or replace function private.notify_loan_default_event_v1()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid;
  v_event_type text;
  v_key_suffix text;
  v_borrower_profile_id uuid;
  v_application_number text;
  v_member_application_id uuid;
  v_outsider_application_id uuid;
  v_guarantor_member_id uuid;
  v_guarantor_profile_id uuid;
begin
  v_actor := (select auth.uid());
  v_event_type := new.event_type::text;
  v_key_suffix := coalesce(new.installment_id::text, new.id::text);

  begin
    select
      l.borrower_profile_id,
      l.loan_application_id,
      l.outsider_loan_application_id,
      coalesce(la.application_number, ola.application_number)
    into
      v_borrower_profile_id,
      v_member_application_id,
      v_outsider_application_id,
      v_application_number
    from public.loans l
    left join public.loan_applications la
      on la.id = l.loan_application_id
    left join public.outsider_loan_applications ola
      on ola.id = l.outsider_loan_application_id
    where l.id = new.loan_id;

    if v_event_type = 'DEFAULT_NOTICE' then
      if v_borrower_profile_id is not null then
        perform private.create_notification_v1(
          v_borrower_profile_id,
          'loan',
          'loan.serious_default',
          'Loan requires urgent attention',
          format(
            'Loan %s has reached the serious-default threshold. Open Unity Finance to review the required action.',
            coalesce(v_application_number, 'N/A')
          ),
          'critical',
          jsonb_build_object(
            'target_type', 'loan',
            'loan_id', new.loan_id,
            'application_number', v_application_number,
            'installment_id', new.installment_id
          ),
          'loan',
          new.loan_id,
          'loan:serious-default:borrower:' || new.loan_id::text || ':' || v_key_suffix
        );
      end if;

      perform private.notify_users_with_permission_v1(
        'loan.review',
        'loan',
        'loan.serious_default',
        'Loan default requires review',
        format(
          'Loan %s has reached the serious-default threshold and requires administrative review.',
          coalesce(v_application_number, 'N/A')
        ),
        'critical',
        jsonb_build_object(
          'target_type', 'loan',
          'loan_id', new.loan_id,
          'application_number', v_application_number,
          'installment_id', new.installment_id
        ),
        'loan',
        new.loan_id,
        'loan:serious-default:admin:' || new.loan_id::text || ':' || v_key_suffix,
        v_actor
      );
    elsif v_event_type = 'GUARANTOR_NOTICE' then
      if v_member_application_id is not null then
        select g.guarantor_member_id
          into v_guarantor_member_id
        from public.member_loan_guarantors g
        where g.loan_application_id = v_member_application_id
          and g.status = 'accepted'
        order by g.responded_at desc nulls last
        limit 1;
      elsif v_outsider_application_id is not null then
        select g.guarantor_member_id
          into v_guarantor_member_id
        from public.outsider_loan_guarantors g
        where g.outsider_loan_application_id = v_outsider_application_id
          and g.status = 'accepted'
        order by g.responded_at desc nulls last
        limit 1;
      end if;

      if v_guarantor_member_id is not null then
        v_guarantor_profile_id :=
          private.notification_profile_for_member_v1(v_guarantor_member_id);
      end if;

      if v_guarantor_profile_id is not null then
        perform private.create_notification_v1(
          v_guarantor_profile_id,
          'loan',
          'loan.serious_default',
          'Guaranteed loan requires urgent attention',
          format(
            'A loan you guaranteed (%s) has reached the serious-default threshold. Open Unity Finance to review the required action.',
            coalesce(v_application_number, 'N/A')
          ),
          'critical',
          jsonb_build_object(
            'target_type', 'loan',
            'loan_id', new.loan_id,
            'application_number', v_application_number,
            'installment_id', new.installment_id
          ),
          'loan',
          new.loan_id,
          'loan:serious-default:guarantor:' || new.loan_id::text || ':' || v_key_suffix
        );
      end if;
    end if;
  exception
    when others then
      raise warning 'notify_loan_default_event_v1 skipped for event %: %',
        new.id, sqlerrm;
  end;

  return new;
end;
$$;

revoke all on function private.notify_loan_default_event_v1()
  from public, anon, authenticated;

drop trigger if exists trg_loan_default_event_notification_v1
  on public.loan_default_events;
create trigger trg_loan_default_event_notification_v1
after insert
on public.loan_default_events
for each row execute function private.notify_loan_default_event_v1();

-- ============================================================================
-- 12. Integration summary
-- ============================================================================
-- Workflow events now covered by this migration (all additive, no RPC changes):
--   payments                     -> payment.submitted / payment.rejected
--   withdrawal_requests          -> savings.withdrawal_requested / _approved /
--                                   _rejected / _delayed
--   loan_applications            -> loan.application_submitted / loan.approved /
--                                   loan.rejected
--   outsider_loan_applications   -> loan.application_submitted /
--                                   loan.outsider_application_decided
--   member_loan_guarantors       -> loan.guarantor_required /
--                                   loan.guarantor_accepted / _rejected
--   outsider_loan_guarantors     -> loan.guarantor_required /
--                                   loan.guarantor_accepted / _rejected
--   loan_repayment_submissions   -> loan.repayment_submitted /
--                                   loan.repayment_rejected
--   expenses                     -> expense.submitted / expense.approved /
--                                   expense.rejected
--   membership_applications      -> membership.application_submitted /
--                                   membership.approved / membership.rejected
--   loan_default_events          -> loan.serious_default (borrower, guarantor,
--                                   loan reviewers)
--
-- Transaction posted/reversed notifications remain owned by migration 38.
-- Every trigger above degrades to a WARNING on failure, so a notification
-- problem can never roll back a financial or workflow command.
-- ============================================================================

commit;










