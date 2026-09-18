begin;

/* The member review branch locked an accepted guarantor but did not fail when
   none existed. Enforce the same accepted-and-active guarantor requirement
   during the authoritative V3 approval recheck. */
do $enforce_member_guarantor_on_admin_loan_review$
declare
  v_definition text;
  v_old_block constant text := $block$    select * into v_guarantee
    from public.member_loan_guarantors g
    where g.loan_application_id=p_application_id
      and g.status='accepted'
    for update;

  else$block$;
  v_new_block constant text := $block$    select * into v_guarantee
    from public.member_loan_guarantors g
    where g.loan_application_id=p_application_id
      and g.status='accepted'
    for update;

    if not found then
      v_eligible := false;
      v_reasons := v_reasons || jsonb_build_array('GUARANTOR_NOT_ACCEPTED');
    elsif not exists (
      select 1 from public.members m
      where m.id=v_guarantee.guarantor_member_id and m.status='active'
    ) then
      v_eligible := false;
      v_reasons := v_reasons || jsonb_build_array('GUARANTOR_NOT_ACTIVE');
    end if;

  else$block$;
begin
  select pg_get_functiondef(
    'public.review_loan_application_v3(public.loan_borrower_type,uuid,public.loan_approval_decision,numeric,text,jsonb,text)'::regprocedure
  ) into v_definition;

  if position(v_old_block in v_definition) = 0 then
    raise exception 'review_loan_application_v3 has an unexpected member-guarantor block; refusing an unsafe rewrite';
  end if;

  execute replace(v_definition, v_old_block, v_new_block);
end;
$enforce_member_guarantor_on_admin_loan_review$;

commit;
