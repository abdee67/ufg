begin;

/*
  V3 review already re-runs all authoritative eligibility, guarantor, conflict,
  and liquidity checks before recording an approval. Allowing `submitted` into
  that command lets an authorized reviewer process a newly submitted loan even
  when no separate client-side eligibility evaluation has run yet. Approval
  remains impossible unless those current checks pass.
*/
do $allow_submitted_admin_loan_review$
declare
  v_definition text;
  v_old_guard constant text := $guard$if v_application.status not in ('eligible','under_review') then
    raise exception 'Application is not in a reviewable state';
  end if;$guard$;
  v_new_guard constant text := $guard$if v_application.status not in ('submitted','eligible','under_review') then
    raise exception 'Application is not in a reviewable state';
  end if;$guard$;
begin
  select pg_get_functiondef(
    'public.review_loan_application_v3(public.loan_borrower_type,uuid,public.loan_approval_decision,numeric,text,jsonb,text)'::regprocedure
  ) into v_definition;

  if position(v_old_guard in v_definition) = 0 then
    raise exception 'review_loan_application_v3 has an unexpected state guard; refusing an unsafe rewrite';
  end if;

  execute replace(v_definition, v_old_guard, v_new_guard);
end;
$allow_submitted_admin_loan_review$;

commit;
