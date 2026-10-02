/*
===============================================================================
UNITY FINANCE GROUP
Notification Push Pipeline Hardening V1
===============================================================================

Target:
  20260929000038_notification_infrastructure_v1.sql
  20260929000040_notification_worker_schedule_v1.sql
  (20260930000041_notification_push_diagnostics_v1.sql if already applied)

Problems fixed here
-------------------
1. SILENT MISCONFIGURATION
   The scheduled invocation returned a WARNING when the Vault secrets were
   missing, so the cron run looked healthy while no HTTP request was ever made.
   It now RAISES, which pg_cron records as a failed run with the exact message
   in cron.job_run_details.return_message.

2. LATE DEVICE REGISTRATION
   create_notification_v1 queues push jobs only for devices that were ACTIVE at
   creation time. A device that registers later never received those pushes.
   The scheduled tick now self-heals missing delivery rows for recent
   notifications before invoking the worker, so late registrations recover
   automatically (idempotent: it only inserts where no delivery row exists).

Single scheduled command (replaces the 040 command):
  select private.notification_push_tick_v1();

Operator notes:
  - A failing cron job is now a real signal. Check
    `select jsonb_pretty(private.notification_push_diagnostics_v1());`
    and the run history:
      select status, return_message, start_time
        from cron.job_run_details d
        join cron.job j on j.jobid = d.jobid
       where j.jobname = 'unity-finance-notification-push-worker-v1'
       order by d.start_time desc limit 5;
===============================================================================
*/

begin;

-- ============================================================================
-- 0. Dependency guard
-- ============================================================================

do $$
begin
  if to_regprocedure('private.invoke_notification_push_worker_v1()') is null then
    raise exception
      'Worker schedule v1 is missing. Apply 20260929000040_notification_worker_schedule_v1.sql first.';
  end if;
end;
$$;

-- ============================================================================
-- 1. Make a missing configuration loud instead of silent
-- ============================================================================

create or replace function private.invoke_notification_push_worker_v1()
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
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
    raise exception
      'notification worker cannot run: Vault secrets project_url / notification_worker_key are not configured (see NOTIFICATION_FEATURE_README.md Phase 4)';
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
$$;

revoke all on function private.invoke_notification_push_worker_v1()
  from public, anon, authenticated;

-- ============================================================================
-- 2. Backfill helper (now day-bounded) + self-heal wrapper
--    Replaces the single-argument version from migration 041 so the scheduled
--    tick can keep its window small. Called with one argument it still behaves
--    exactly like before.
-- ============================================================================

drop function if exists private.backfill_notification_deliveries_v1(integer);

create or replace function private.backfill_notification_deliveries_v1(
  p_limit integer default 200,
  p_days integer default 30
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_limit integer := greatest(1, least(coalesce(p_limit, 200), 2000));
  v_days integer := greatest(1, least(coalesce(p_days, 30), 365));
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
    where n.created_at > now() - make_interval(days => v_days)
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
    'queue_messages_sent', v_enqueued,
    'window_days', v_days
  );
end;
$$;

revoke all on function private.backfill_notification_deliveries_v1(integer, integer)
  from public, anon, authenticated;

-- Scheduled self-heal: small, bounded, idempotent.
create or replace function private.notification_push_self_heal_v1(
  p_limit integer default 50,
  p_days integer default 7
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  return private.backfill_notification_deliveries_v1(p_limit, p_days);
end;
$$;

revoke all on function private.notification_push_self_heal_v1(integer, integer)
  from public, anon, authenticated;

-- ============================================================================
-- 3. Scheduled tick: self-heal first, then invoke the worker
-- ============================================================================

create or replace function private.notification_push_tick_v1()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_self_heal jsonb;
  v_request_id bigint;
begin
  v_self_heal := private.notification_push_self_heal_v1(50, 7);

  v_request_id := private.invoke_notification_push_worker_v1();

  return jsonb_build_object(
    'ran_at', now(),
    'self_heal', v_self_heal,
    'worker_request_id', v_request_id
  );
end;
$$;

revoke all on function private.notification_push_tick_v1()
  from public, anon, authenticated;

-- ============================================================================
-- 4. Point the schedule at the tick
-- ============================================================================

do $$
begin
  if to_regnamespace('cron') is null then
    raise exception
      'pg_cron is not enabled; cannot schedule the notification push worker.';
  end if;

  if exists (
    select 1 from cron.job
    where jobname = 'unity-finance-notification-push-worker-v1'
  ) then
    perform cron.unschedule('unity-finance-notification-push-worker-v1');
  end if;

  perform cron.schedule(
    'unity-finance-notification-push-worker-v1',
    '* * * * *',
    'select private.notification_push_tick_v1();'
  );
end;
$$;


commit;
