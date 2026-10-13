SET local check_function_bodies = off;

SELECT cron.unschedule('unity-finance-notification-push-worker-v1');

COMMENT ON EXTENSION "pg_net" IS NULL;

DROP FUNCTION "private"."backfill_notification_deliveries_v1"(integer, integer);

DROP FUNCTION "private"."notification_push_self_heal_v1"(integer, integer);

DROP FUNCTION "private"."notification_push_tick_v1"();

DROP EXTENSION "pg_net";

CREATE EXTENSION "pg_net" SCHEMA "extensions";

ALTER TABLE "public"."loan_applications"
  ADD COLUMN "reviewed_at" timestamp WITH time zone;

CREATE OR REPLACE FUNCTION private.backfill_notification_deliveries_v1 (
  p_limit integer DEFAULT 200
)
  RETURNS jsonb
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO ''
  AS $function$
declare
  v_limit integer := greatest(1, least(coalesce(p_limit, 200), 2000));
  v_rec record;
  v_device record;
  v_delivery_id uuid;
  v_inserted integer := 0;
  v_enqueued integer := 0;
  v_notifications integer := 0;
begin
  for v_rec in
    select n.id as notification_id, n.recipient_profile_id
    from public.notifications n
    where n.created_at > now() - interval '30 days'
      and not exists (
        select 1 from public.notification_deliveries d
        where d.notification_id = n.id
      )
      and exists (
        select 1 from public.notification_devices nd
        where nd.profile_id = n.recipient_profile_id
          and nd.is_active
      )
    order by n.created_at desc
    limit v_limit
  loop
    v_notifications := v_notifications + 1;

    for v_device in
      select nd.id
      from public.notification_devices nd
      where nd.profile_id = v_rec.recipient_profile_id
        and nd.is_active
    loop
      v_delivery_id := null;

      insert into public.notification_deliveries(
        notification_id,
        device_id,
        channel,
        status,
        available_at
      )
      values (
        v_rec.notification_id,
        v_device.id,
        'fcm',
        'queued',
        now()
      )
      on conflict (notification_id, device_id, channel) do nothing
      returning id into v_delivery_id;

      if v_delivery_id is not null then
        v_inserted := v_inserted + 1;

        perform pgmq.send(
          'notification_push',
          jsonb_build_object('delivery_id', v_delivery_id::text, 'version', 1)
        );

        v_enqueued := v_enqueued + 1;
      end if;
    end loop;
  end loop;

  return jsonb_build_object(
    'notifications_processed', v_notifications,
    'deliveries_inserted', v_inserted,
    'queue_messages_sent', v_enqueued
  );
end;
$function$;

CREATE OR REPLACE FUNCTION private.get_member_available_savings (
  p_member_id uuid
)
  RETURNS numeric
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path TO 'public', 'private'
  AS $function$
  select greatest(
    private.get_member_savings_balance(p_member_id) - private.get_member_secured_savings(p_member_id),
    0.00
  )::numeric(18,2);
$function$;

CREATE OR REPLACE FUNCTION private.get_member_savings_balance (
  p_member_id uuid
)
  RETURNS numeric
  LANGUAGE plpgsql
  STABLE
  SECURITY DEFINER
  SET search_path TO 'public', 'private'
  AS $function$
declare
  v_account_id uuid;
  v_balance numeric(18,2);
begin
  select a.id into v_account_id
  from public.accounts a
  join public.account_types at on at.id = a.account_type_id
  where a.owner_member_id = p_member_id
    and at.code = 'member_savings'
  limit 1;

  if v_account_id is null then
    return 0.00;
  end if;

  select coalesce(sum(
    case
      when te.entry_type = 'credit' then te.amount
      when te.entry_type = 'debit' then -te.amount
      else 0
    end
  ), 0)::numeric(18,2)
  into v_balance
  from public.transaction_entries te
  join public.transactions t on t.id = te.transaction_id
  where te.account_id = v_account_id
    and t.transaction_status = 'posted';

  return coalesce(v_balance, 0.00);
end;
$function$;

CREATE OR REPLACE FUNCTION private.get_member_secured_savings (
  p_member_id uuid
)
  RETURNS numeric
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path TO 'public', 'private'
  AS $function$
  select coalesce(sum(amount), 0)::numeric(18,2)
  from public.savings_security_locks
  where member_id = p_member_id
    and status = 'active';
$function$;

CREATE OR REPLACE FUNCTION private.get_or_create_group_account (
  p_account_type_code public.account_type_code
)
  RETURNS uuid
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public', 'private'
  AS $function$
declare
  v_type_id uuid;
  v_account_id uuid;
begin
  select id into v_type_id from public.account_types where code = p_account_type_code;
  if v_type_id is null then
    raise exception 'Account type % does not exist.', p_account_type_code;
  end if;

  select id into v_account_id
  from public.accounts
  where account_type_id = v_type_id
    and owner_profile_id is null
    and owner_member_id is null
  limit 1;

  if v_account_id is null then
    insert into public.accounts (account_type_id, currency, status)
    values (v_type_id, 'ETB', 'active')
    returning id into v_account_id;
  end if;

  return v_account_id;
end;
$function$;

CREATE OR REPLACE FUNCTION private.handle_new_auth_user()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public', 'private'
  AS $function$
declare
  v_non_member_role uuid;
begin
  insert into public.profiles (
    id,
    full_name,
    phone,
    email
  )
  values (
    new.id,
    coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
      split_part(coalesce(new.email, ''), '@', 1),
      'New User'
    ),
    nullif(trim(new.raw_user_meta_data ->> 'phone'), ''),
    new.email
  )
  on conflict (id) do nothing;

  select id
  into v_non_member_role
  from public.roles
  where code = 'non_member';

  if v_non_member_role is not null then
    insert into public.user_roles(user_id, role_id)
    values (new.id, v_non_member_role)
    on conflict do nothing;
  end if;

  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION private.invoke_notification_push_worker_v1()
  RETURNS bigint
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO ''
  AS $function$
declare
  v_project_url text;
  v_worker_key text;
  v_request_id bigint;
begin
  select ds.decrypted_secret
    into v_project_url
  from vault.decrypted_secrets ds
  where ds.name = 'project_url'
  order by ds.created_at desc
  limit 1;

  select ds.decrypted_secret
    into v_worker_key
  from vault.decrypted_secrets ds
  where ds.name = 'notification_worker_key'
  order by ds.created_at desc
  limit 1;

  if coalesce(trim(v_project_url), '') = ''
     or coalesce(trim(v_worker_key), '') = ''
  then
    raise warning
      'notification worker invocation skipped: Vault secrets project_url / notification_worker_key are not configured';
    return null;
  end if;

  select net.http_post(
    url := rtrim(v_project_url, '/') || '/functions/v1/notification-push-worker',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'apikey', v_worker_key
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 20000
  )
  into v_request_id;

  return v_request_id;
end;
$function$;

CREATE OR REPLACE FUNCTION private.set_updated_at()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $function$
begin
  new.updated_at = now();
  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION private.validate_loan_application_borrower_type()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $function$
declare
  v_borrower_type public.loan_borrower_type;
begin
  select borrower_type
  into v_borrower_type
  from public.loan_products
  where id = new.loan_product_id;

  if v_borrower_type is null then
    raise exception 'invalid loan product';
  end if;

  if v_borrower_type = 'member' and new.member_id is null then
    raise exception 'member loans require member_id';
  end if;

  if v_borrower_type = 'outsider' and new.member_id is not null then
    raise exception 'outsider loans cannot have member_id';
  end if;

  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.approve_membership_application (
  p_application_id   uuid,
  p_decision         text,
  p_reviewer_id      uuid,
  p_rejection_reason text DEFAULT NULL::text
)
  RETURNS jsonb
  LANGUAGE plpgsql
  SET search_path TO 'public', 'private'
  AS $function$
declare
  v_application public.membership_applications%rowtype;
  v_member public.members%rowtype;
  v_old_member_status public.member_status;
  v_member_role uuid;
  v_non_member_role uuid;
begin
  if p_decision not in ('approved', 'rejected') then
    raise exception 'Decision must be approved or rejected';
  end if;

  if not exists (
    select 1
    from public.user_roles ur
    join public.roles r on r.id = ur.role_id
    where ur.user_id = p_reviewer_id
      and r.code in ('admin', 'super_admin')
  ) then
    raise exception 'Reviewer is not authorized';
  end if;

  select *
    into v_application
  from public.membership_applications
  where id = p_application_id
  for update;

  if not found then
    raise exception 'Membership application not found';
  end if;

  if v_application.status not in ('pending', 'under_review') then
    raise exception 'Membership application is already finalized';
  end if;

  if p_decision = 'rejected' then
    update public.membership_applications
    set status = 'rejected',
        reviewed_by = p_reviewer_id,
        reviewed_at = now(),
        rejection_reason = nullif(trim(coalesce(p_rejection_reason, '')), '')
    where id = v_application.id;

    insert into public.audit_logs (
      actor_user_id,
      action,
      entity_type,
      entity_id,
      old_data,
      new_data,
      metadata
    )
    values (
      p_reviewer_id,
      'MEMBERSHIP_APPLICATION_REJECTED',
      'membership_application',
      v_application.id,
      jsonb_build_object('status', v_application.status),
      jsonb_build_object('status', 'rejected'),
      jsonb_build_object('reason', p_rejection_reason)
    );

    return jsonb_build_object(
      'status', 'rejected',
      'application_id', v_application.id,
      'reviewed_by', p_reviewer_id
    );
  end if;

  select *
    into v_member
  from public.members
  where profile_id = v_application.applicant_id
  for update;

  if found then
    v_old_member_status := v_member.status;
    update public.members
    set status = 'active',
        membership_date = coalesce(membership_date, current_date),
        updated_at = now()
    where id = v_member.id
    returning * into v_member;
  else
    v_old_member_status := null;
    insert into public.members(profile_id, membership_date, status)
    values (v_application.applicant_id, current_date, 'active')
    returning * into v_member;
  end if;

  select id into v_member_role from public.roles where code = 'member';
  select id into v_non_member_role from public.roles where code = 'non_member';

  if v_member_role is null then
    raise exception 'Member role is missing';
  end if;

  insert into public.user_roles(user_id, role_id, assigned_by)
  values (v_application.applicant_id, v_member_role, p_reviewer_id)
  on conflict do nothing;

  if v_non_member_role is not null then
    delete from public.user_roles
    where user_id = v_application.applicant_id
      and role_id = v_non_member_role;
  end if;

  update public.membership_applications
  set status = 'approved',
      reviewed_by = p_reviewer_id,
      reviewed_at = now(),
      rejection_reason = null
  where id = v_application.id;

  insert into public.membership_status_history(
    member_id,
    old_status,
    new_status,
    reason,
    changed_by
  )
  values (
    v_member.id,
    v_old_member_status,
    'active'::public.member_status,
    'Membership application approved',
    p_reviewer_id
  );

  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    old_data,
    new_data,
    metadata
  )
  values (
    p_reviewer_id,
    'MEMBERSHIP_APPLICATION_APPROVED',
    'membership_application',
    v_application.id,
    jsonb_build_object('status', v_application.status),
    jsonb_build_object(
      'status', 'approved',
      'member_id', v_member.id,
      'member_number', v_member.member_number
    ),
    jsonb_build_object('reviewer_id', p_reviewer_id)
  );

  return jsonb_build_object(
    'status', 'approved',
    'application_id', v_application.id,
    'member_id', v_member.id,
    'member_number', v_member.member_number,
    'reviewed_by', p_reviewer_id
  );
end;
$function$;

REVOKE ALL ON FUNCTION "public"."approve_membership_application"(uuid, text, uuid, text) FROM PUBLIC, "anon", "authenticated";

CREATE OR REPLACE FUNCTION public.approve_savings_withdrawal (
  p_withdrawal_request_id uuid,
  p_reviewer_id           uuid DEFAULT auth.uid()
)
  RETURNS jsonb
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public', 'private'
  AS $function$
declare
  v_req record;
  v_available numeric(18,2);
begin
  if not private.current_user_is_admin() then
    raise exception 'Unauthorized: Admin privileges required.';
  end if;

  select * into v_req
  from public.withdrawal_requests
  where id = p_withdrawal_request_id
  for update;

  if v_req is null then
    raise exception 'Withdrawal request % not found.', p_withdrawal_request_id;
  end if;

  if v_req.status not in ('pending', 'delayed') then
    raise exception 'Cannot approve withdrawal in % status.', v_req.status;
  end if;

  v_available := private.get_member_available_savings(v_req.member_id);
  if v_req.amount > v_available then
    raise exception 'Cannot approve: Requested amount (ETB %) exceeds available savings (ETB %).', v_req.amount, v_available;
  end if;

  update public.withdrawal_requests
  set
    status = 'approved',
    reviewed_by = p_reviewer_id,
    reviewed_at = now(),
    updated_at = now()
  where id = p_withdrawal_request_id;

  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    new_data
  )
  values (
    p_reviewer_id,
    'SAVINGS_WITHDRAWAL_APPROVED',
    'withdrawal_requests',
    p_withdrawal_request_id,
    jsonb_build_object('amount', v_req.amount, 'member_id', v_req.member_id)
  );

  return jsonb_build_object(
    'id', p_withdrawal_request_id,
    'status', 'approved'
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.bootstrap_non_member_role()
  RETURNS void
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public', 'private'
  AS $function$
declare
  v_role_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  select id into v_role_id
  from public.roles
  where code = 'non_member';

  insert into public.user_roles(user_id, role_id)
  values (auth.uid(), v_role_id)
  on conflict do nothing;
end;
$function$;

CREATE OR REPLACE FUNCTION public.cancel_withdrawal_request (
  p_withdrawal_request_id uuid
)
  RETURNS jsonb
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public', 'private'
  AS $function$
declare
  v_user_id uuid;
  v_member_id uuid;
  v_req record;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'User is not authenticated.';
  end if;

  v_member_id := private.current_member_id();
  if v_member_id is null then
    raise exception 'Active membership required.';
  end if;

  select * into v_req
  from public.withdrawal_requests
  where id = p_withdrawal_request_id and member_id = v_member_id
  for update;

  if v_req is null then
    raise exception 'Withdrawal request % not found.', p_withdrawal_request_id;
  end if;

  if v_req.status not in ('pending', 'delayed') then
    raise exception 'Cannot cancel withdrawal in % status.', v_req.status;
  end if;

  update public.withdrawal_requests
  set status = 'cancelled', updated_at = now()
  where id = p_withdrawal_request_id;

  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    new_data
  )
  values (
    v_user_id,
    'SAVINGS_WITHDRAWAL_CANCELLED',
    'withdrawal_requests',
    p_withdrawal_request_id,
    jsonb_build_object('member_id', v_member_id)
  );

  return jsonb_build_object(
    'id', p_withdrawal_request_id,
    'status', 'cancelled'
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.current_user_is_admin()
  RETURNS boolean
  LANGUAGE sql
  STABLE
  SET search_path TO 'public', 'private'
  AS $function$
  select private.current_user_is_admin()
$function$;

CREATE OR REPLACE FUNCTION public.delay_savings_withdrawal (
  p_withdrawal_request_id uuid,
  p_reason                text,
  p_reviewer_id           uuid DEFAULT auth.uid()
)
  RETURNS jsonb
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public', 'private'
  AS $function$
declare
  v_req record;
begin
  if not private.current_user_is_admin() then
    raise exception 'Unauthorized: Admin privileges required.';
  end if;

  if coalesce(trim(p_reason), '') = '' then
    raise exception 'Delay reason is required for communication to member.';
  end if;

  select * into v_req
  from public.withdrawal_requests
  where id = p_withdrawal_request_id
  for update;

  if v_req is null then
    raise exception 'Withdrawal request % not found.', p_withdrawal_request_id;
  end if;

  if v_req.status != 'pending' then
    raise exception 'Cannot delay withdrawal in % status.', v_req.status;
  end if;

  update public.withdrawal_requests
  set
    status = 'delayed',
    reason = trim(p_reason),
    reviewed_by = p_reviewer_id,
    reviewed_at = now(),
    updated_at = now()
  where id = p_withdrawal_request_id;

  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    new_data
  )
  values (
    p_reviewer_id,
    'SAVINGS_WITHDRAWAL_DELAYED',
    'withdrawal_requests',
    p_withdrawal_request_id,
    jsonb_build_object('reason', trim(p_reason))
  );

  return jsonb_build_object(
    'id', p_withdrawal_request_id,
    'status', 'delayed',
    'reason', trim(p_reason)
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.generate_monthly_savings_obligations (
  p_year  integer DEFAULT NULL::integer,
  p_month integer DEFAULT NULL::integer
)
  RETURNS jsonb
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public', 'private'
  AS $function$
declare
  v_year int;
  v_month int;
  v_due_day int;
  v_min_saving numeric(18,2);
  v_due_date date;
  v_created_count int := 0;
  v_member record;
begin
  v_year := coalesce(p_year, extract(year from current_date)::int);
  v_month := coalesce(p_month, extract(month from current_date)::int);

  v_min_saving := coalesce(public.get_active_rule_numeric('monthly_min_saving'), 2000.00);
  v_due_day := coalesce(public.get_active_rule_numeric('saving_due_day')::int, 12);

  v_due_date := make_date(v_year, v_month, v_due_day);

  for v_member in
    select m.id
    from public.members m
    where m.status = 'active'
      and not exists (
        select 1 from public.savings_obligations so
        where so.member_id = m.id
          and so.period_year = v_year
          and so.period_month = v_month
      )
  loop
    insert into public.savings_obligations (
      member_id,
      period_year,
      period_month,
      required_amount,
      due_date,
      paid_amount,
      late_penalty_amount,
      status
    )
    values (
      v_member.id,
      v_year,
      v_month,
      v_min_saving,
      v_due_date,
      0,
      0,
      'pending'
    )
    on conflict (member_id, period_year, period_month) do nothing;

    v_created_count := v_created_count + 1;
  end loop;

  insert into public.audit_logs (
    action,
    entity_type,
    new_data
  )
  values (
    'SAVINGS_MONTHLY_OBLIGATIONS_GENERATED',
    'savings_obligations',
    jsonb_build_object(
      'year', v_year,
      'month', v_month,
      'created_count', v_created_count,
      'due_date', v_due_date,
      'required_amount', v_min_saving
    )
  );

  return jsonb_build_object(
    'year', v_year,
    'month', v_month,
    'obligations_created', v_created_count,
    'due_date', v_due_date
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.get_active_rule_numeric (
  p_rule_code text
)
  RETURNS numeric
  LANGUAGE sql
  STABLE
  AS $function$
  select
    case
      when frv.value_numeric is not null then frv.value_numeric
      when frv.value_integer is not null then frv.value_integer::numeric
      else null
    end
  from public.financial_rules fr
  join public.financial_rule_versions frv
    on frv.rule_id = fr.id
  where fr.rule_code = p_rule_code
    and fr.active = true
    and frv.status = 'active'
    and frv.effective_from <= now()
    and (frv.effective_to is null or frv.effective_to > now())
  order by frv.effective_from desc
  limit 1;
$function$;

CREATE OR REPLACE FUNCTION public.get_member_loan_application_detail_v2 (
  p_application_id uuid
)
  RETURNS jsonb
  LANGUAGE plpgsql
  STABLE
  SECURITY DEFINER
  SET search_path TO ''
  AS $function$
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
$function$;

CREATE OR REPLACE FUNCTION public.get_my_member_loan_applications_v2()
  RETURNS jsonb
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path TO ''
  AS $function$
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
$function$;

CREATE OR REPLACE FUNCTION public.get_my_savings_history()
  RETURNS jsonb
  LANGUAGE plpgsql
  STABLE
  SECURITY DEFINER
  SET search_path TO 'public', 'private'
  AS $function$
declare
  v_member_id uuid;
  v_result jsonb;
begin
  v_member_id := private.current_member_id();
  if v_member_id is null then
    raise exception 'No active membership found for current user.';
  end if;

  with history_items as (
    -- Contributions
    select
      sc.id as id,
      t.reference_number as reference,
      'contribution' as item_type,
      sc.contribution_type as sub_type,
      sc.amount as amount,
      true as is_credit,
      'posted' as status,
      'Monthly savings contribution' as description,
      sc.created_at as timestamp
    from public.savings_contributions sc
    left join public.transactions t on t.id = sc.transaction_id
    where sc.member_id = v_member_id

    union all

    -- Withdrawals
    select
      wr.id as id,
      coalesce(t.reference_number, 'WDR-' || substr(wr.id::text, 1, 8)) as reference,
      'withdrawal' as item_type,
      'withdrawal' as sub_type,
      wr.amount as amount,
      false as is_credit,
      wr.status::text as status,
      coalesce(wr.reason, 'Savings withdrawal') as description,
      wr.requested_at as timestamp
    from public.withdrawal_requests wr
    left join public.transactions t on t.source_id = wr.id and t.source_type = 'withdrawal_request'
    where wr.member_id = v_member_id
  )
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', h.id,
      'reference', h.reference,
      'item_type', h.item_type,
      'sub_type', h.sub_type,
      'amount', h.amount,
      'is_credit', h.is_credit,
      'status', h.status,
      'description', h.description,
      'timestamp', h.timestamp
    ) order by h.timestamp desc
  ), '[]'::jsonb)
  into v_result
  from history_items h;

  return v_result;
end;
$function$;

CREATE OR REPLACE FUNCTION public.get_my_withdrawal_requests()
  RETURNS jsonb
  LANGUAGE plpgsql
  STABLE
  SECURITY DEFINER
  SET search_path TO 'public', 'private'
  AS $function$
declare
  v_member_id uuid;
  v_result jsonb;
begin
  v_member_id := private.current_member_id();
  if v_member_id is null then
    raise exception 'Active membership required.';
  end if;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', wr.id,
      'member_id', wr.member_id,
      'amount', wr.amount,
      'status', wr.status,
      'reason', wr.reason,
      'requested_at', wr.requested_at,
      'reviewed_at', wr.reviewed_at,
      'paid_at', wr.paid_at,
      'created_at', wr.created_at,
      'updated_at', wr.updated_at
    ) order by wr.requested_at desc
  ), '[]'::jsonb)
  into v_result
  from public.withdrawal_requests wr
  where wr.member_id = v_member_id;

  return v_result;
end;
$function$;

CREATE OR REPLACE FUNCTION public.post_savings_withdrawal (
  p_withdrawal_request_id uuid,
  p_payment_method_code   text DEFAULT 'bank_transfer'::text,
  p_reviewer_id           uuid DEFAULT auth.uid()
)
  RETURNS jsonb
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public', 'private'
  AS $function$
declare
  v_req record;
  v_member record;
  v_member_acc_id uuid;
  v_bank_acc_id uuid;
  v_txn_id uuid;
  v_txn_ref text;
  v_available numeric(18,2);
begin
  if not private.current_user_is_admin() then
    raise exception 'Unauthorized: Admin privileges required.';
  end if;

  select * into v_req
  from public.withdrawal_requests
  where id = p_withdrawal_request_id
  for update;

  if v_req is null then
    raise exception 'Withdrawal request % not found.', p_withdrawal_request_id;
  end if;

  if v_req.status != 'approved' then
    raise exception 'Withdrawal request is in % status; only approved requests can be posted.', v_req.status;
  end if;

  select * into v_member from public.members where id = v_req.member_id;
  if v_member is null then
    raise exception 'Member not found.';
  end if;

  v_available := private.get_member_available_savings(v_req.member_id);
  if v_req.amount > v_available then
    raise exception 'Cannot post withdrawal: Amount (ETB %) exceeds current available balance (ETB %).', v_req.amount, v_available;
  end if;

  v_member_acc_id := private.ensure_member_savings_account(v_member.id);
  v_bank_acc_id := private.get_or_create_group_account('bank');

  -- 1. Create Financial Transaction
  v_txn_ref := private.generate_reference('TXN');

  insert into public.transactions (
    reference_number,
    transaction_type,
    source_type,
    source_id,
    profile_id,
    member_id,
    amount,
    currency,
    approval_status,
    transaction_status,
    initiated_by,
    approved_by,
    approved_at,
    description
  )
  values (
    v_txn_ref,
    'savings_withdrawal',
    'withdrawal_request',
    p_withdrawal_request_id,
    v_member.profile_id,
    v_member.id,
    v_req.amount,
    'ETB',
    'approved',
    'posted',
    p_reviewer_id,
    p_reviewer_id,
    now(),
    'Member savings withdrawal payout'
  )
  returning id into v_txn_id;

  -- 2. Balanced Ledger Entries
  -- Debit Member Savings Account (Liability to member decreases)
  insert into public.transaction_entries (
    transaction_id,
    account_id,
    entry_type,
    amount
  )
  values (
    v_txn_id,
    v_member_acc_id,
    'debit',
    v_req.amount
  );

  -- Credit Bank Account (Asset decreases)
  insert into public.transaction_entries (
    transaction_id,
    account_id,
    entry_type,
    amount
  )
  values (
    v_txn_id,
    v_bank_acc_id,
    'credit',
    v_req.amount
  );

  -- 3. Update Withdrawal Request
  update public.withdrawal_requests
  set
    status = 'paid',
    paid_at = now(),
    updated_at = now()
  where id = p_withdrawal_request_id;

  -- 4. Audit Log
  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    new_data
  )
  values (
    p_reviewer_id,
    'SAVINGS_WITHDRAWAL_POSTED',
    'withdrawal_requests',
    p_withdrawal_request_id,
    jsonb_build_object(
      'amount', v_req.amount,
      'member_id', v_member.id,
      'transaction_id', v_txn_id
    )
  );

  return jsonb_build_object(
    'id', p_withdrawal_request_id,
    'transaction_id', v_txn_id,
    'reference_number', v_txn_ref,
    'amount', v_req.amount,
    'status', 'paid'
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.post_verified_savings_contribution (
  p_payment_id  uuid,
  p_reviewer_id uuid DEFAULT auth.uid()
)
  RETURNS jsonb
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public', 'private'
  AS $function$
declare
  v_payment record;
  v_member record;
  v_member_acc_id uuid;
  v_savings_acc_id uuid;
  v_bank_acc_id uuid;
  v_txn_id uuid;
  v_txn_ref text;
  v_contrib_id uuid;
  v_obligation record;
  v_min_saving numeric;
  v_contrib_type text := 'mandatory';
begin
  if not private.current_user_is_admin() then
    raise exception 'Unauthorized: Admin privileges required.';
  end if;

  select * into v_payment
  from public.payments
  where id = p_payment_id
  for update;

  if v_payment is null then
    raise exception 'Payment % not found.', p_payment_id;
  end if;

  if v_payment.status != 'verified' then
    raise exception 'Payment % is in % status; only verified payments can be posted.', p_payment_id, v_payment.status;
  end if;

  if v_payment.purpose_type != 'savings_contribution' then
    raise exception 'Payment purpose is %, expected savings_contribution.', v_payment.purpose_type;
  end if;

  -- Check if already posted
  if exists (
    select 1 from public.savings_contributions where payment_id = p_payment_id
  ) then
    raise exception 'Payment % has already been posted to savings.', p_payment_id;
  end if;

  -- Find active member for payer
  select * into v_member
  from public.members
  where profile_id = v_payment.payer_profile_id and status = 'active'
  limit 1;

  if v_member is null then
    raise exception 'Payer is not an active member.';
  end if;

  -- Ensure member financial account & savings account
  v_member_acc_id := private.ensure_member_savings_account(v_member.id);
  select id into v_savings_acc_id from public.savings_accounts where member_id = v_member.id;
  v_bank_acc_id := private.get_or_create_group_account('bank');

  -- Find target obligation
  if v_payment.purpose_id is not null then
    select * into v_obligation
    from public.savings_obligations
    where id = v_payment.purpose_id and member_id = v_member.id
    for update;
  else
    -- Match oldest pending/late obligation
    select * into v_obligation
    from public.savings_obligations
    where member_id = v_member.id
      and status in ('pending', 'late', 'partially_paid')
    order by due_date asc
    limit 1
    for update;
  end if;

  -- Update obligation if matched
  if v_obligation is not null then
    declare
      v_new_paid numeric(18,2) := v_obligation.paid_amount + v_payment.amount;
      v_new_status public.savings_obligation_status;
    begin
      if v_new_paid >= v_obligation.required_amount then
        v_new_status := 'paid';
      else
        v_new_status := 'partially_paid';
      end if;

      update public.savings_obligations
      set
        paid_amount = v_new_paid,
        status = v_new_status,
        updated_at = now()
      where id = v_obligation.id;
    end;
  end if;

  v_min_saving := coalesce(public.get_active_rule_numeric('monthly_min_saving'), 2000.00);
  if v_payment.amount > v_min_saving then
    v_contrib_type := 'voluntary';
  end if;

  -- 1. Create Financial Transaction (Double-entry)
  v_txn_ref := private.generate_reference('TXN');

  insert into public.transactions (
    reference_number,
    transaction_type,
    source_type,
    source_id,
    profile_id,
    member_id,
    amount,
    currency,
    approval_status,
    transaction_status,
    initiated_by,
    approved_by,
    approved_at,
    description
  )
  values (
    v_txn_ref,
    'savings_contribution',
    'payment',
    p_payment_id,
    v_member.profile_id,
    v_member.id,
    v_payment.amount,
    'ETB',
    'approved',
    'posted',
    p_reviewer_id,
    p_reviewer_id,
    now(),
    'Member monthly savings contribution'
  )
  returning id into v_txn_id;

  -- 2. Balanced Ledger Entries
  -- Debit Bank Account (Asset increase)
  insert into public.transaction_entries (
    transaction_id,
    account_id,
    entry_type,
    amount
  )
  values (
    v_txn_id,
    v_bank_acc_id,
    'debit',
    v_payment.amount
  );

  -- Credit Member Savings Account (Liability to member increase)
  insert into public.transaction_entries (
    transaction_id,
    account_id,
    entry_type,
    amount
  )
  values (
    v_txn_id,
    v_member_acc_id,
    'credit',
    v_payment.amount
  );

  -- 3. Create Savings Contribution Record
  insert into public.savings_contributions (
    member_id,
    savings_account_id,
    obligation_id,
    amount,
    payment_id,
    transaction_id,
    contribution_type
  )
  values (
    v_member.id,
    v_savings_acc_id,
    case when v_obligation is not null then v_obligation.id else null end,
    v_payment.amount,
    p_payment_id,
    v_txn_id,
    v_contrib_type
  )
  returning id into v_contrib_id;

  -- 4. Audit Log
  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    new_data
  )
  values (
    p_reviewer_id,
    'SAVINGS_CONTRIBUTION_POSTED',
    'savings_contributions',
    v_contrib_id,
    jsonb_build_object(
      'payment_id', p_payment_id,
      'member_id', v_member.id,
      'amount', v_payment.amount,
      'transaction_id', v_txn_id,
      'obligation_id', case when v_obligation is not null then v_obligation.id else null end
    )
  );

  return jsonb_build_object(
    'contribution_id', v_contrib_id,
    'transaction_id', v_txn_id,
    'reference_number', v_txn_ref,
    'amount', v_payment.amount,
    'status', 'posted'
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.process_late_savings_obligations (
  p_as_of_date date DEFAULT CURRENT_DATE
)
  RETURNS jsonb
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public', 'private'
  AS $function$
declare
  v_penalty_rate numeric(8,4);
  v_penalty_acc_id uuid;
  v_obligation record;
  v_processed_count int := 0;
  v_penalty_amount numeric(18,2);
  v_txn_id uuid;
  v_txn_ref text;
begin
  v_penalty_rate := coalesce(public.get_active_rule_numeric('saving_late_penalty_rate'), 0.10);
  v_penalty_acc_id := private.get_or_create_group_account('penalty_income');

  for v_obligation in
    select so.*, m.profile_id
    from public.savings_obligations so
    join public.members m on m.id = so.member_id
    where so.due_date < p_as_of_date
      and so.status in ('pending', 'partially_paid')
      and so.paid_amount < so.required_amount
      and not exists (
        select 1 from public.savings_penalties sp
        where sp.obligation_id = so.id
      )
  loop
    v_penalty_amount := round(v_obligation.required_amount * v_penalty_rate, 2);

    -- 1. Create Transaction for Penalty (Financial audit)
    v_txn_ref := private.generate_reference('TXN');

    insert into public.transactions (
      reference_number,
      transaction_type,
      source_type,
      source_id,
      profile_id,
      member_id,
      amount,
      currency,
      approval_status,
      transaction_status,
      description
    )
    values (
      v_txn_ref,
      'savings_late_penalty',
      'savings_obligation',
      v_obligation.id,
      v_obligation.profile_id,
      v_obligation.member_id,
      v_penalty_amount,
      'ETB',
      'approved',
      'posted',
      'Late monthly savings contribution penalty (10%)'
    )
    returning id into v_txn_id;

    -- 2. Insert Penalty Record
    insert into public.savings_penalties (
      obligation_id,
      rate,
      amount,
      transaction_id,
      charged_at
    )
    values (
      v_obligation.id,
      v_penalty_rate,
      v_penalty_amount,
      v_txn_id,
      now()
    )
    on conflict (obligation_id) do nothing;

    -- 3. Update Obligation Status to LATE
    update public.savings_obligations
    set
      status = 'late',
      late_penalty_amount = v_penalty_amount,
      updated_at = now()
    where id = v_obligation.id;

    v_processed_count := v_processed_count + 1;
  end loop;

  insert into public.audit_logs (
    action,
    entity_type,
    new_data
  )
  values (
    'SAVINGS_LATE_OBLIGATIONS_PROCESSED',
    'savings_obligations',
    jsonb_build_object(
      'as_of_date', p_as_of_date,
      'processed_count', v_processed_count,
      'penalty_rate', v_penalty_rate
    )
  );

  return jsonb_build_object(
    'as_of_date', p_as_of_date,
    'late_obligations_processed', v_processed_count
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.reject_membership_application (
  p_application_id uuid,
  p_reason         text,
  p_reviewer_id    uuid DEFAULT auth.uid()
)
  RETURNS jsonb
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public', 'private'
  AS $function$
declare
  v_app record;
begin
  if not private.current_user_is_admin() then
    raise exception 'Unauthorized: Administrator privileges required.';
  end if;

  if coalesce(trim(p_reason), '') = '' then
    raise exception 'A rejection reason is required.';
  end if;

  select * into v_app
  from public.membership_applications
  where id = p_application_id
  for update;

  if v_app is null then
    raise exception 'Membership application % not found.', p_application_id;
  end if;

  if v_app.status not in ('pending', 'under_review') then
    raise exception 'Application is in % state and cannot be rejected.', v_app.status;
  end if;

  update public.membership_applications
  set
    status = 'rejected',
    reviewed_by = p_reviewer_id,
    reviewed_at = now(),
    rejection_reason = trim(p_reason),
    updated_at = now()
  where id = p_application_id;

  update public.membership_documents
  set
    verification_status = 'rejected',
    verified_by = p_reviewer_id,
    verified_at = now(),
    notes = trim(p_reason),
    updated_at = now()
  where application_id = p_application_id;

  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    new_data
  )
  values (
    p_reviewer_id,
    'MEMBERSHIP_APPLICATION_REJECTED',
    'membership_application',
    p_application_id,
    jsonb_build_object(
      'rejection_reason', trim(p_reason),
      'applicant_id', v_app.applicant_id
    )
  );

  return jsonb_build_object(
    'application_id', p_application_id,
    'status', 'rejected',
    'rejection_reason', trim(p_reason)
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.reject_savings_withdrawal (
  p_withdrawal_request_id uuid,
  p_reason                text,
  p_reviewer_id           uuid DEFAULT auth.uid()
)
  RETURNS jsonb
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public', 'private'
  AS $function$
declare
  v_req record;
begin
  if not private.current_user_is_admin() then
    raise exception 'Unauthorized: Admin privileges required.';
  end if;

  if coalesce(trim(p_reason), '') = '' then
    raise exception 'Rejection reason is required.';
  end if;

  select * into v_req
  from public.withdrawal_requests
  where id = p_withdrawal_request_id
  for update;

  if v_req is null then
    raise exception 'Withdrawal request % not found.', p_withdrawal_request_id;
  end if;

  if v_req.status not in ('pending', 'delayed') then
    raise exception 'Cannot reject withdrawal in % status.', v_req.status;
  end if;

  update public.withdrawal_requests
  set
    status = 'rejected',
    reason = trim(p_reason),
    reviewed_by = p_reviewer_id,
    reviewed_at = now(),
    updated_at = now()
  where id = p_withdrawal_request_id;

  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    new_data
  )
  values (
    p_reviewer_id,
    'SAVINGS_WITHDRAWAL_REJECTED',
    'withdrawal_requests',
    p_withdrawal_request_id,
    jsonb_build_object('reason', trim(p_reason))
  );

  return jsonb_build_object(
    'id', p_withdrawal_request_id,
    'status', 'rejected',
    'reason', trim(p_reason)
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.request_savings_withdrawal (
  p_amount numeric,
  p_reason text    DEFAULT NULL::text
)
  RETURNS jsonb
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public', 'private'
  AS $function$
declare
  v_user_id uuid;
  v_member_id uuid;
  v_available numeric(18,2);
  v_req_id uuid;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'User is not authenticated.';
  end if;

  v_member_id := private.current_member_id();
  if v_member_id is null then
    raise exception 'Active membership required to request withdrawals.';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'Withdrawal amount must be greater than zero.';
  end if;

  v_available := private.get_member_available_savings(v_member_id);
  if p_amount > v_available then
    raise exception 'Requested amount (ETB %) exceeds your available savings (ETB %).', p_amount, v_available;
  end if;

  -- Check for existing pending withdrawal request
  if exists (
    select 1 from public.withdrawal_requests
    where member_id = v_member_id
      and status in ('pending', 'approved', 'delayed')
  ) then
    raise exception 'You already have an active withdrawal request in progress.';
  end if;

  insert into public.withdrawal_requests (
    member_id,
    amount,
    status,
    reason,
    requested_at
  )
  values (
    v_member_id,
    p_amount,
    'pending',
    nullif(trim(p_reason), ''),
    now()
  )
  returning id into v_req_id;

  -- Audit
  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    new_data
  )
  values (
    v_user_id,
    'SAVINGS_WITHDRAWAL_REQUESTED',
    'withdrawal_requests',
    v_req_id,
    jsonb_build_object(
      'member_id', v_member_id,
      'amount', p_amount,
      'reason', p_reason
    )
  );

  return jsonb_build_object(
    'id', v_req_id,
    'member_id', v_member_id,
    'amount', p_amount,
    'status', 'pending',
    'requested_at', now()
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.rls_auto_enable()
  RETURNS event_trigger
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'pg_catalog'
  AS $function$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$function$;

CREATE OR REPLACE FUNCTION public.submit_membership_application (
  p_address         text,
  p_date_of_birth   date,
  p_phone           text,
  p_storage_path    text,
  p_file_name       text,
  p_mime_type       text,
  p_file_size_bytes bigint
)
  RETURNS jsonb
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public', 'private'
  AS $function$
declare
  v_user_id uuid;
  v_app_id uuid;
  v_app_number text;
  v_result jsonb;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'User is not authenticated.';
  end if;

  -- Validate caller is not already a member
  if exists (
    select 1 from public.members
    where profile_id = v_user_id and status = 'active'
  ) then
    raise exception 'You are already an active member.';
  end if;

  -- Validate no pending or under-review applications exist
  if exists (
    select 1 from public.membership_applications
    where applicant_id = v_user_id
      and status in ('pending', 'under_review')
  ) then
    raise exception 'You already have an active membership application pending review.';
  end if;

  -- Validate document path
  if coalesce(trim(p_storage_path), '') = '' then
    raise exception 'Fayda identity document is required.';
  end if;

  -- Update profile KYC details
  update public.profiles
  set
    address = trim(p_address),
    date_of_birth = p_date_of_birth,
    phone = coalesce(nullif(trim(p_phone), ''), phone),
    updated_at = now()
  where id = v_user_id;

  -- Create membership application
  v_app_number := private.generate_reference('MEMAPP');

  insert into public.membership_applications (
    application_number,
    applicant_id,
    status,
    submitted_at
  )
  values (
    v_app_number,
    v_user_id,
    'pending',
    now()
  )
  returning id into v_app_id;

  -- Insert document record
  insert into public.membership_documents (
    application_id,
    applicant_id,
    storage_path,
    file_name,
    mime_type,
    file_size_bytes,
    verification_status
  )
  values (
    v_app_id,
    v_user_id,
    p_storage_path,
    p_file_name,
    p_mime_type,
    p_file_size_bytes,
    'uploaded'
  );

  -- Log audit event
  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    new_data
  )
  values (
    v_user_id,
    'MEMBERSHIP_APPLICATION_SUBMITTED',
    'membership_application',
    v_app_id,
    jsonb_build_object(
      'application_number', v_app_number,
      'applicant_id', v_user_id,
      'storage_path', p_storage_path
    )
  );

  select jsonb_build_object(
    'id', id,
    'application_number', application_number,
    'applicant_id', applicant_id,
    'status', status,
    'submitted_at', submitted_at,
    'created_at', created_at
  )
  into v_result
  from public.membership_applications
  where id = v_app_id;

  return v_result;
end;
$function$;

CREATE OR REPLACE FUNCTION public.submit_savings_payment (
  p_amount              numeric,
  p_payment_method_code text,
  p_external_reference  text,
  p_payment_proof_path  text    DEFAULT NULL::text,
  p_obligation_id       uuid    DEFAULT NULL::uuid
)
  RETURNS jsonb
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public', 'private'
  AS $function$
declare
  v_user_id uuid;
  v_member_id uuid;
  v_method_id uuid;
  v_payment_id uuid;
  v_ref_number text;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'User is not authenticated.';
  end if;

  v_member_id := private.current_member_id();
  if v_member_id is null then
    raise exception 'Active membership required to make savings payments.';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'Payment amount must be greater than zero.';
  end if;

  select id into v_method_id
  from public.payment_methods
  where code = p_payment_method_code and active = true;

  if v_method_id is null then
    raise exception 'Invalid or inactive payment method: %', p_payment_method_code;
  end if;

  v_ref_number := private.generate_reference('PAY');

  insert into public.payments (
    payer_profile_id,
    payment_method_id,
    reference_number,
    purpose_type,
    purpose_id,
    amount,
    currency,
    status,
    payment_proof_path,
    external_reference,
    submitted_at
  )
  values (
    v_user_id,
    v_method_id,
    v_ref_number,
    'savings_contribution',
    p_obligation_id,
    p_amount,
    'ETB',
    'pending',
    p_payment_proof_path,
    trim(p_external_reference),
    now()
  )
  returning id into v_payment_id;

  -- Audit
  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    new_data
  )
  values (
    v_user_id,
    'SAVINGS_PAYMENT_SUBMITTED',
    'payments',
    v_payment_id,
    jsonb_build_object(
      'reference_number', v_ref_number,
      'amount', p_amount,
      'obligation_id', p_obligation_id,
      'payment_method', p_payment_method_code
    )
  );

  return jsonb_build_object(
    'payment_id', v_payment_id,
    'reference_number', v_ref_number,
    'amount', p_amount,
    'status', 'pending',
    'submitted_at', now()
  );
end;
$function$;

CREATE UNIQUE INDEX membership_applications_one_active_per_applicant ON public.membership_applications USING btree (applicant_id)
  WHERE (status = ANY (ARRAY['pending'::public.membership_application_status, 'under_review'::public.membership_application_status]));

CREATE EVENT TRIGGER "ensure_rls"
  ON ddl_command_end
  WHEN TAG IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
  EXECUTE FUNCTION "public"."rls_auto_enable"();

COMMENT ON EXTENSION "pg_net" IS 'Async HTTP';

REVOKE ALL ON FUNCTION "private"."backfill_notification_deliveries_v1"(integer) FROM PUBLIC;

REVOKE ALL ON FUNCTION "public"."approve_membership_application"(uuid, text, uuid, text) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."approve_membership_application"(uuid, text, uuid, text) TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."approve_membership_application"(uuid, text, uuid, text) TO "service_role";

GRANT EXECUTE ON FUNCTION "public"."rls_auto_enable"() TO PUBLIC, "anon", "authenticated";

REVOKE ALL ON FUNCTION "public"."rls_auto_enable"() FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."rls_auto_enable"() TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."rls_auto_enable"() TO "service_role";

SELECT cron.schedule_in_database('unity-finance-loan-default-processor', '30 0 * * *', 'select public.process_serious_loan_defaults_v3();', 'postgres', NULL, true);

SELECT cron.schedule_in_database('unity-finance-loan-overdue-processor', '15 0 * * *', 'select public.process_overdue_loan_installments_v3();', 'postgres', NULL, true);

SELECT cron.schedule_in_database('unity-finance-notification-cleanup-v1', '15 3 * * *', 'select private.cleanup_notifications_v1(180);', 'postgres', NULL, true);

SELECT cron.schedule_in_database('unity-finance-notification-push-worker-v1', '* * * * *', 'select private.invoke_notification_push_worker_v1();', 'postgres', NULL, true);

SELECT cron.schedule_in_database('unity-finance-savings-late-processor', '5 0 * * *', 'select public.process_late_savings_obligations();', 'postgres', NULL, true);

