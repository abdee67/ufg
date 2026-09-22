begin;

/*
  Enforce dual-control and separation of duties in review_loan_application_v3:
  1. An administrator who has already recorded a review for an application
     cannot submit another review for that same application.
  2. The database will raise a descriptive exception before attempting
     to insert into public.loan_approvals, avoiding unique constraint violations.
*/
do $prevent_duplicate_admin_loan_review$
declare
  v_definition text;
  v_old_anchor constant text := $anchor$  if v_conflict then
    raise exception 'Reviewer has a declared or relationship-based conflict of interest for this application';
  end if;$anchor$;
  v_new_anchor constant text := $anchor$  if v_conflict then
    raise exception 'Reviewer has a declared or relationship-based conflict of interest for this application';
  end if;

  /* Separation of duties / dual control: a reviewer cannot review the same application more than once. */
  if exists (
    select 1
    from public.loan_approvals a
    where a.approver_profile_id = v_actor
      and (
        (p_borrower_type = 'member' and a.loan_application_id = p_application_id)
        or (p_borrower_type = 'outsider' and a.outsider_loan_application_id = p_application_id)
      )
  ) then
    raise exception 'You have already recorded a review for this loan application';
  end if;

  /* Ensure an application does not accept more than the required two approvals. */
  if p_decision = 'approved' and (
    select count(*)
    from public.loan_approvals a
    where a.decision = 'approved'
      and (
        (p_borrower_type = 'member' and a.loan_application_id = p_application_id)
        or (p_borrower_type = 'outsider' and a.outsider_loan_application_id = p_application_id)
      )
  ) >= 2 then
    raise exception 'This loan application already has the required number of approvals';
  end if;$anchor$;
begin
  select pg_get_functiondef(
    'public.review_loan_application_v3(public.loan_borrower_type,uuid,public.loan_approval_decision,numeric,text,jsonb,text)'::regprocedure
  ) into v_definition;

  if position(v_old_anchor in v_definition) = 0 then
    raise exception 'review_loan_application_v3 has an unexpected conflict guard; refusing an unsafe rewrite';
  end if;

  execute replace(v_definition, v_old_anchor, v_new_anchor);
end;
$prevent_duplicate_admin_loan_review$;

commit;
