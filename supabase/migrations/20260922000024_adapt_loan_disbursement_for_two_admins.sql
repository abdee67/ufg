begin;

/*
  Adapt Loan Disbursement for 2-Administrator Organizations:
  
  Previously, disburse_loan_v3 strictly prohibited any administrator who approved
  the loan from disbursing it. In a system requiring 2 distinct approvals, this
  demanded at least 3 administrators (Approver 1, Approver 2, Disburser 3).

  For a 2-administrator setup:
  - Dual control is preserved: two distinct administrators must still independently
    review and approve the application before disbursement is unlocked.
  - Either authorized administrator can execute the disbursement once the 2 approvals
    are in place.
  - An administrator is still prohibited from disbursing their own loan.
*/
do $adapt_loan_disbursement_for_two_admins$
declare
  v_definition text;
  v_old_block constant text := $old$  /* A reviewer may not release funds for a loan they approved, even when the
     same profile has both permissions. This preserves approval/disbursement
     separation of duties at the command boundary. */
  if exists (
    select 1
    from public.loan_approvals a
    where a.decision='approved'
      and a.approver_profile_id=v_actor
      and (
        (p_borrower_type='member' and a.loan_application_id=p_application_id)
        or (p_borrower_type='outsider' and a.outsider_loan_application_id=p_application_id)
      )
  ) then
    raise exception 'An approver cannot disburse the same loan';
  end if;$old$;

  v_new_block constant text := $new$  /* 2-Admin Workflow: Dual-control is satisfied by two distinct approvals.
     Either authorized administrator can disburse funds, provided they are not the borrower. */
  if p_borrower_type = 'member' and v_application.applicant_profile_id = v_actor then
    raise exception 'A person cannot disburse their own loan';
  end if;$new$;
begin
  select pg_get_functiondef(
    'public.disburse_loan_v3(public.loan_borrower_type,uuid,text,text,text)'::regprocedure
  ) into v_definition;

  if position(v_old_block in v_definition) = 0 then
    raise exception 'disburse_loan_v3 has an unexpected approval-check block; refusing an unsafe rewrite';
  end if;

  execute replace(v_definition, v_old_block, v_new_block);
end;
$adapt_loan_disbursement_for_two_admins$;

commit;
