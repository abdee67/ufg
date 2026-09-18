begin;

/* Make the server-calculated preview expose the same paid-history prerequisite
   used by final V3 review, so clients can present a clear pre-submission gate. */
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

  return jsonb_build_object(
    'member_id', v_member_id,
    'total_savings', v_savings,
    'maximum_loan_amount', v_max,
    'global_cap', 20000,
    'paid_saving_months', v_paid_saving_months,
    'required_saving_months', 2,
    'meets_minimum_saving_history', v_paid_saving_months >= 2,
    'formula', 'MIN(total_savings * 2, 20000)'
  );
end;
$$;

revoke all on function public.get_my_member_loan_limit_v2() from public, anon;
grant execute on function public.get_my_member_loan_limit_v2() to authenticated;

/* The preview is only user experience. Enforce the prerequisite in the member
   submission RPC as well, before it creates an application or guarantee. */
do $enforce_member_loan_saving_history$
declare
  v_definition text;
  v_old_anchor constant text := $anchor$  if p_guarantor_member_id = v_member_id then
    raise exception 'A member cannot guarantee their own loan';
  end if;$anchor$;
  v_new_anchor constant text := $anchor$  if (
    select count(*)
    from public.savings_obligations so
    where so.member_id=v_member_id
      and so.status='paid'
  ) < 2 then
    raise exception 'At least two paid savings months are required before applying for a member loan';
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
$enforce_member_loan_saving_history$;

commit;
