/*
===============================================================================
UNITY FINANCE GROUP
Notification Push Worker Schedule V1
===============================================================================

Target:
  20260929000038_notification_infrastructure_v1.sql
  20260929000039_notification_domain_integration_v1.sql
  Deployed Edge Function: notification-push-worker

Purpose:
  Invoke the FCM push worker once per minute using pg_cron + pg_net, reading
  the project URL and the dedicated worker secret key from Supabase Vault.

Operator prerequisites (one-time, do this BEFORE applying this migration):
  1. Enable the pg_net extension (Database > Extensions > pg_net).
  2. Create the function secrets:
       supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$(cat <service-account>.json)"
       (FCM_PROJECT_ID is optional when project_id is present in the JSON)
  3. Create a SECRET API key named exactly: notification_worker
     (Project Settings > API Keys > New secret key)
  4. Store the Vault secrets:

       select vault.create_secret(
         'https://<project-ref>.supabase.co',
         'project_url',
         'Unity Finance project URL for the notification worker'
       );

       select vault.create_secret(
         '<sb_secret_...notification_worker key...>',
         'notification_worker_key',
         'Notification push worker invocation key'
       );

  5. Deploy the worker with JWT verification disabled:
       supabase functions deploy notification-push-worker

Notes:
  - No secret value is hard-coded in SQL.
  - If the Vault secrets are missing, the scheduled function raises a WARNING
    and does nothing; the in-app inbox keeps working regardless.
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
  then
    raise exception
      'Notification infrastructure v1 is missing. Apply 20260929000038_notification_infrastructure_v1.sql first.';
  end if;

  if to_regnamespace('net') is null then
    raise exception
      'pg_net is not enabled. Enable it in Database > Extensions > net, then re-run this migration.';
  end if;

  if to_regnamespace('cron') is null then
    raise exception
      'pg_cron is not enabled. Enable it in Database > Extensions > pg_cron, then re-run this migration.';
  end if;

  if to_regnamespace('vault') is null then
    raise exception
      'Supabase Vault is not available in this project. Store the worker URL/key another way before applying this migration.';
  end if;
end;
$$;

-- ============================================================================
-- 1. Worker invocation helper
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
$$;

revoke all on function private.invoke_notification_push_worker_v1()
  from public, anon, authenticated;

-- ============================================================================
-- 2. Once-per-minute schedule
-- ============================================================================

do $$
begin
  if exists (
    select 1 from cron.job
    where jobname = 'unity-finance-notification-push-worker-v1'
  ) then
    perform cron.unschedule('unity-finance-notification-push-worker-v1');
  end if;

  perform cron.schedule(
    'unity-finance-notification-push-worker-v1',
    '* * * * *',
    'select private.invoke_notification_push_worker_v1();'
  );
end;
$$;

-- ============================================================================
-- 3. Delivery health view (private - monitoring only)
-- ============================================================================

create or replace view private.notification_delivery_health_v1 as
select
  (select count(*)::bigint
     from public.notification_deliveries d
    where d.status = 'queued') as queued_count,
  (select count(*)::bigint
     from public.notification_deliveries d
    where d.status = 'processing') as processing_count,
  (select count(*)::bigint
     from public.notification_deliveries d
    where d.status = 'sent'
      and d.sent_at > now() - interval '24 hours') as sent_24h,
  (select count(*)::bigint
     from public.notification_deliveries d
    where d.status = 'invalid'
      and d.updated_at > now() - interval '24 hours') as invalid_24h,
  (select count(*)::bigint
     from public.notification_deliveries d
    where d.status = 'failed'
      and d.updated_at > now() - interval '24 hours') as failed_24h,
  (select count(*)::bigint
     from public.notifications n
    where n.created_at > now() - interval '24 hours') as notifications_24h,
  (select count(*)::bigint
     from public.notifications n
    where n.created_at > now() - interval '24 hours'
      and n.read_at is null) as unread_24h,
  (select min(d.available_at)
     from public.notification_deliveries d
    where d.status = 'queued') as oldest_queued_available_at,
  (select count(*)::bigint
     from public.notification_devices nd
    where nd.is_active = true) as active_devices;

comment on view private.notification_delivery_health_v1 is
  'Unity Finance notification delivery health. Query from the SQL editor or an ops dashboard: select * from private.notification_delivery_health_v1;';

-- ============================================================================
-- 4. Retention note
-- ============================================================================
-- In-app notification cleanup is already scheduled by migration 38
-- (private.cleanup_notifications_v1, daily 03:15). FCM device freshness is
-- handled by deactivating invalid registrations in the worker.

commit;
