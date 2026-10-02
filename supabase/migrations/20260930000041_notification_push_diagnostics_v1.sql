/*
===============================================================================
UNITY FINANCE GROUP
Notification Push Diagnostics + Recovery V1
===============================================================================

Target:
  20260929000038_notification_infrastructure_v1.sql
  20260929000039_notification_domain_integration_v1.sql
  20260929000040_notification_worker_schedule_v1.sql

Purpose:
  Answer "why did no push arrive?" with database evidence instead of guesses,
  and provide safe recovery helpers.

  pipeline:
    business event -> notifications row
                   -> notification_deliveries row(s)   (only for devices that
                                                        were ACTIVE at that time)
                   -> pgmq message
                   -> pg_cron -> pg_net -> Edge Function -> FCM

  Any break in that chain leaves the in-app inbox working, which is exactly the
  symptom "badge has a notification but no push came".

Functions (all private, not exposed to clients):
  private.notification_push_diagnostics_v1()          -> jsonb snapshot
  private.backfill_notification_deliveries_v1(limit)  -> queues pushes for
      notifications created before the device was registered
  private.requeue_notification_deliveries_v1(limit)   -> retries terminally
      failed deliveries after a configuration fix

Run from the SQL editor:
  select jsonb_pretty(private.notification_push_diagnostics_v1());
===============================================================================
*/

begin;

-- ============================================================================
-- 0. Dependency guard
-- ============================================================================

do $$
begin
  if to_regprocedure(
       'private.create_notification_v1(uuid,text,text,text,text,text,jsonb,text,uuid,text)'
     ) is null
  then
    raise exception
      'Notification infrastructure v1 is missing. Apply 20260929000038_notification_infrastructure_v1.sql first.';
  end if;
end;
$$;

-- ============================================================================
-- 1. Diagnostics snapshot
-- ============================================================================

create or replace function private.notification_push_diagnostics_v1()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_result jsonb;
  v_net jsonb := '[]'::jsonb;
  v_jobs jsonb := '[]'::jsonb;
  v_runs jsonb := '[]'::jsonb;
  v_secrets jsonb := '[]'::jsonb;
begin
  if to_regclass('net._http_response') is not null then
    execute $q$
      select coalesce(jsonb_agg(t order by t.created desc), '[]'::jsonb)
      from (
        select id,
               status_code,
               timed_out,
               error_msg,
               created,
               left(coalesce(content, ''), 400) as content
        from net._http_response
        order by created desc
        limit 5
      ) t
    $q$ into v_net;
  end if;

  if to_regclass('cron.job') is not null then
    execute $q$
      select coalesce(jsonb_agg(t), '[]'::jsonb)
      from (
        select jobid, jobname, schedule, active
        from cron.job
        where jobname = 'unity-finance-notification-push-worker-v1'
      ) t
    $q$ into v_jobs;

    if to_regclass('cron.job_run_details') is not null then
      execute $q$
        select coalesce(jsonb_agg(t order by t.start_time desc), '[]'::jsonb)
        from (
          select d.jobid,
                 d.runid,
                 d.status,
                 d.return_message,
                 d.start_time,
                 d.end_time
          from cron.job_run_details d
          join cron.job j on j.jobid = d.jobid
          where j.jobname = 'unity-finance-notification-push-worker-v1'
          order by d.start_time desc
          limit 5
        ) t
      $q$ into v_runs;
    end if;
  end if;

  if to_regclass('vault.secrets') is not null then
    execute $q$
      select coalesce(jsonb_agg(name), '[]'::jsonb)
      from vault.secrets
      where name in ('project_url', 'notification_worker_key')
    $q$ into v_secrets;
  end if;

  select jsonb_build_object(
    'generated_at', now(),
    'devices', jsonb_build_object(
      'total', (select count(*) from public.notification_devices),
      'active', (select count(*) from public.notification_devices where is_active),
      'active_android', (select count(*) from public.notification_devices
                          where is_active and platform = 'android'),
      'last_seen_max', (select max(last_seen_at) from public.notification_devices)
    ),
    'deliveries_by_status', (
      select coalesce(jsonb_object_agg(s.status, s.cnt), '{}'::jsonb)
      from (
        select status, count(*)::int as cnt
        from public.notification_deliveries
        group by status
      ) s
    ),
    'queue', jsonb_build_object(
      'queued_ready_now', (
        select count(*) from public.notification_deliveries
        where status = 'queued' and available_at <= now()
      ),
      'oldest_queued_available_at', (
        select min(available_at) from public.notification_deliveries
        where status = 'queued'
      )
    ),
    'recent_notifications', (
      select coalesce(jsonb_agg(t order by t.created_at desc), '[]'::jsonb)
      from (
        select n.id,
               n.type,
               n.category,
               n.created_at,
               n.recipient_profile_id,
               (select count(*) from public.notification_deliveries d
                 where d.notification_id = n.id) as delivery_rows,
               (select jsonb_agg(distinct d.status)
                  from public.notification_deliveries d
                 where d.notification_id = n.id) as delivery_statuses,
               exists (
                 select 1 from public.notification_devices nd
                 where nd.profile_id = n.recipient_profile_id
                   and nd.is_active
               ) as recipient_has_active_device
        from public.notifications n
        order by n.created_at desc
        limit 10
      ) t
    ),
    'recent_delivery_errors', (
      select coalesce(jsonb_agg(t order by t.updated_at desc), '[]'::jsonb)
      from (
        select d.id,
               d.status,
               d.attempt_count,
               d.last_error_code,
               left(coalesce(d.last_error_message, ''), 300) as last_error_message,
               d.updated_at
        from public.notification_deliveries d
        where d.last_error_code is not null
        order by d.updated_at desc
        limit 5
      ) t
    ),
    'cron_jobs', v_jobs,
    'cron_recent_runs', v_runs,
    'vault_secret_names', v_secrets,
    'last_pg_net_responses', v_net
  ) into v_result;

  return v_result;
end;
$$;

revoke all on function private.notification_push_diagnostics_v1()
  from public, anon, authenticated;

-- ============================================================================
-- 2. Backfill: notifications created before the device was registered
--    (create_notification_v1 only queues pushes for devices that were ACTIVE
--     at creation time, so older rows have no delivery rows at all)
-- ============================================================================

create or replace function private.backfill_notification_deliveries_v1(
  p_limit integer default 200
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
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
$$;

revoke all on function private.backfill_notification_deliveries_v1(integer)
  from public, anon, authenticated;

-- ============================================================================
-- 3. Requeue: retry deliveries after a configuration fix (FCM credentials,
--    function deployment, secret key). Invalid devices are never revived.
--    Duplicate queue messages are safe: the worker claims a delivery only while
--    it is queued and available, and deletes messages for terminal states.
-- ============================================================================

create or replace function private.requeue_notification_deliveries_v1(
  p_include_failed boolean default true,
  p_limit integer default 500
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_limit integer := greatest(1, least(coalesce(p_limit, 500), 5000));
  v_rec record;
  v_requeued integer := 0;
  v_enqueued integer := 0;
begin
  for v_rec in
    select d.id
    from public.notification_deliveries d
    join public.notification_devices nd on nd.id = d.device_id
    where nd.is_active = true
      and (
        d.status = 'queued'
        or (p_include_failed and d.status = 'failed')
      )
    order by d.available_at asc
    limit v_limit
  loop
    update public.notification_deliveries
    set status = 'queued',
        attempt_count = 0,
        available_at = now(),
        lease_until = null,
        last_error_code = null,
        last_error_message = null,
        updated_at = now()
    where id = v_rec.id;

    v_requeued := v_requeued + 1;

    perform pgmq.send(
      'notification_push',
      jsonb_build_object('delivery_id', v_rec.id::text, 'version', 1)
    );

    v_enqueued := v_enqueued + 1;
  end loop;

  return jsonb_build_object(
    'deliveries_requeued', v_requeued,
    'queue_messages_sent', v_enqueued
  );
end;
$$;

revoke all on function private.requeue_notification_deliveries_v1(boolean, integer)
  from public, anon, authenticated;



commit;
