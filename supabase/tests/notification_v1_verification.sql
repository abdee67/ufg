-- ============================================================================
-- UNITY FINANCE GROUP
-- Notification V1 verification script
-- ============================================================================
--
-- Run this in the Supabase SQL editor after applying:
--   20260929000038_notification_infrastructure_v1.sql
--   20260929000039_notification_domain_integration_v1.sql
--   20260929000040_notification_worker_schedule_v1.sql
--
-- 100% read-only: it inspects catalog state and permission coverage.
-- Every row should report PASS. Anything reported FAIL must be fixed before
-- enabling the worker schedule in production.
-- ============================================================================

with checks as (

  -- ------------------------------------------------------------------ tables
  select
    'table: public.notifications' as check_name,
    case when to_regclass('public.notifications') is not null
         then 'PASS' else 'FAIL' end as status
  union all
  select 'table: public.notification_devices',
    case when to_regclass('public.notification_devices') is not null
         then 'PASS' else 'FAIL' end
  union all
  select 'table: public.notification_deliveries',
    case when to_regclass('public.notification_deliveries') is not null
         then 'PASS' else 'FAIL' end
  union all
  select 'table: public.notification_preferences',
    case when to_regclass('public.notification_preferences') is not null
         then 'PASS' else 'FAIL' end
  union all
  select 'queue: pgmq.q_notification_push',
    case when to_regclass('pgmq.q_notification_push') is not null
         then 'PASS' else 'FAIL' end

  -- -------------------------------------------------------------- functions
  union all
  select 'function: private.create_notification_v1',
    case when to_regprocedure('private.create_notification_v1(uuid,text,text,text,text,text,jsonb,text,uuid,text)') is not null
         then 'PASS' else 'FAIL' end
  union all
  select 'function: private.notify_users_with_permission_v1',
    case when to_regprocedure('private.notify_users_with_permission_v1(text,text,text,text,text,text,jsonb,text,uuid,text,uuid)') is not null
         then 'PASS' else 'FAIL' end
  union all
  select 'function: private.notify_transaction_transition_v1',
    case when to_regprocedure('private.notify_transaction_transition_v1()') is not null
         then 'PASS' else 'FAIL' end
  union all
  select 'function: public.list_my_notifications_v1',
    case when to_regprocedure('public.list_my_notifications_v1(integer,timestamptz,uuid)') is not null
         then 'PASS' else 'FAIL' end
  union all
  select 'function: public.get_my_unread_notification_count_v1',
    case when to_regprocedure('public.get_my_unread_notification_count_v1()') is not null
         then 'PASS' else 'FAIL' end
  union all
  select 'function: public.mark_notification_read_v1',
    case when to_regprocedure('public.mark_notification_read_v1(uuid)') is not null
         then 'PASS' else 'FAIL' end
  union all
  select 'function: public.mark_all_notifications_read_v1',
    case when to_regprocedure('public.mark_all_notifications_read_v1()') is not null
         then 'PASS' else 'FAIL' end
  union all
  select 'function: public.register_notification_device_v1',
    case when to_regprocedure('public.register_notification_device_v1(text,text,text,text,text,text,text,text)') is not null
         then 'PASS' else 'FAIL' end
  union all
  select 'function: public.deactivate_notification_device_v1',
    case when to_regprocedure('public.deactivate_notification_device_v1(text)') is not null
         then 'PASS' else 'FAIL' end
  union all
  select 'function: public.get_my_notification_preferences_v1',
    case when to_regprocedure('public.get_my_notification_preferences_v1()') is not null
         then 'PASS' else 'FAIL' end
  union all
  select 'function: public.update_my_notification_preferences_v1',
    case when to_regprocedure('public.update_my_notification_preferences_v1(boolean,boolean,boolean,boolean,boolean,boolean,boolean)') is not null
         then 'PASS' else 'FAIL' end

  -- ---------------------------------------------------------------- triggers
  union all
  select 'trigger: trg_transaction_notifications_v1',
    case when exists (
           select 1 from pg_trigger t
           join pg_class c on c.oid = t.tgrelid
           where t.tgname = 'trg_transaction_notifications_v1'
             and c.relname = 'transactions' and not t.tgisinternal)
         then 'PASS' else 'FAIL' end
  union all
  select 'trigger: trg_payment_notification_v1',
    case when exists (
           select 1 from pg_trigger t
           join pg_class c on c.oid = t.tgrelid
           where t.tgname = 'trg_payment_notification_v1'
             and c.relname = 'payments' and not t.tgisinternal)
         then 'PASS' else 'FAIL' end
  union all
  select 'trigger: trg_withdrawal_notification_v1',
    case when exists (
           select 1 from pg_trigger t
           join pg_class c on c.oid = t.tgrelid
           where t.tgname = 'trg_withdrawal_notification_v1'
             and c.relname = 'withdrawal_requests' and not t.tgisinternal)
         then 'PASS' else 'FAIL' end
  union all
  select 'trigger: trg_member_loan_application_notification_v1',
    case when exists (
           select 1 from pg_trigger t
           join pg_class c on c.oid = t.tgrelid
           where t.tgname = 'trg_member_loan_application_notification_v1'
             and c.relname = 'loan_applications' and not t.tgisinternal)
         then 'PASS' else 'FAIL' end
  union all
  select 'trigger: trg_outsider_loan_application_notification_v1',
    case when exists (
           select 1 from pg_trigger t
           join pg_class c on c.oid = t.tgrelid
           where t.tgname = 'trg_outsider_loan_application_notification_v1'
             and c.relname = 'outsider_loan_applications' and not t.tgisinternal)
         then 'PASS' else 'FAIL' end
  union all
  select 'trigger: trg_member_guarantor_notification_v1',
    case when exists (
           select 1 from pg_trigger t
           join pg_class c on c.oid = t.tgrelid
           where t.tgname = 'trg_member_guarantor_notification_v1'
             and c.relname = 'member_loan_guarantors' and not t.tgisinternal)
         then 'PASS' else 'FAIL' end
  union all
  select 'trigger: trg_outsider_guarantor_notification_v1',
    case when exists (
           select 1 from pg_trigger t
           join pg_class c on c.oid = t.tgrelid
           where t.tgname = 'trg_outsider_guarantor_notification_v1'
             and c.relname = 'outsider_loan_guarantors' and not t.tgisinternal)
         then 'PASS' else 'FAIL' end
  union all
  select 'trigger: trg_repayment_submission_notification_v1',
    case when exists (
           select 1 from pg_trigger t
           join pg_class c on c.oid = t.tgrelid
           where t.tgname = 'trg_repayment_submission_notification_v1'
             and c.relname = 'loan_repayment_submissions' and not t.tgisinternal)
         then 'PASS' else 'FAIL' end
  union all
  select 'trigger: trg_expense_notification_v1',
    case when exists (
           select 1 from pg_trigger t
           join pg_class c on c.oid = t.tgrelid
           where t.tgname = 'trg_expense_notification_v1'
             and c.relname = 'expenses' and not t.tgisinternal)
         then 'PASS' else 'FAIL' end
  union all
  select 'trigger: trg_membership_application_notification_v1',
    case when exists (
           select 1 from pg_trigger t
           join pg_class c on c.oid = t.tgrelid
           where t.tgname = 'trg_membership_application_notification_v1'
             and c.relname = 'membership_applications' and not t.tgisinternal)
         then 'PASS' else 'FAIL' end
  union all
  select 'trigger: trg_loan_default_event_notification_v1',
    case when exists (
           select 1 from pg_trigger t
           join pg_class c on c.oid = t.tgrelid
           where t.tgname = 'trg_loan_default_event_notification_v1'
             and c.relname = 'loan_default_events' and not t.tgisinternal)
         then 'PASS' else 'FAIL' end

  -- ------------------------------------------------------------------- RLS
  union all
  select 'rls: notifications enabled',
    case when (select relrowsecurity from pg_class where oid = 'public.notifications'::regclass)
         then 'PASS' else 'FAIL' end
  union all
  select 'rls: notification_devices enabled',
    case when (select relrowsecurity from pg_class where oid = 'public.notification_devices'::regclass)
         then 'PASS' else 'FAIL' end
  union all
  select 'rls: notification_deliveries enabled',
    case when (select relrowsecurity from pg_class where oid = 'public.notification_deliveries'::regclass)
         then 'PASS' else 'FAIL' end
  union all
  select 'rls: notification_preferences enabled',
    case when (select relrowsecurity from pg_class where oid = 'public.notification_preferences'::regclass)
         then 'PASS' else 'FAIL' end
  union all
  select 'rls policy: notifications_select_own_v1',
    case when exists (
           select 1 from pg_policies
           where schemaname = 'public' and tablename = 'notifications'
             and policyname = 'notifications_select_own_v1')
         then 'PASS' else 'FAIL' end
  union all
  select 'rls policy: notification_devices_select_own_v1',
    case when exists (
           select 1 from pg_policies
           where schemaname = 'public' and tablename = 'notification_devices'
             and policyname = 'notification_devices_select_own_v1')
         then 'PASS' else 'FAIL' end
  union all
  select 'rls policy: notification_preferences_select_own_v1',
    case when exists (
           select 1 from pg_policies
           where schemaname = 'public' and tablename = 'notification_preferences'
             and policyname = 'notification_preferences_select_own_v1')
         then 'PASS' else 'FAIL' end

  -- ---------------------------------------------------------------- grants
  union all
  select 'grant: authenticated can select notifications',
    case when has_table_privilege('authenticated', 'public.notifications', 'SELECT')
         then 'PASS' else 'FAIL' end
  union all
  select 'grant: authenticated cannot insert notifications',
    case when has_table_privilege('authenticated', 'public.notifications', 'INSERT')
         then 'FAIL' else 'PASS' end
  union all
  select 'grant: authenticated cannot update notifications',
    case when has_table_privilege('authenticated', 'public.notifications', 'UPDATE')
         then 'FAIL' else 'PASS' end
  union all
  select 'grant: authenticated cannot delete notifications',
    case when has_table_privilege('authenticated', 'public.notifications', 'DELETE')
         then 'FAIL' else 'PASS' end
  union all
  select 'grant: authenticated cannot insert devices',
    case when has_table_privilege('authenticated', 'public.notification_devices', 'INSERT')
         then 'FAIL' else 'PASS' end
  union all
  select 'grant: authenticated cannot write preferences',
    case when has_table_privilege('authenticated', 'public.notification_preferences', 'UPDATE')
         then 'FAIL' else 'PASS' end
  union all
  select 'grant: authenticated has no access to deliveries',
    case when has_table_privilege('authenticated', 'public.notification_deliveries', 'SELECT')
           or has_table_privilege('authenticated', 'public.notification_deliveries', 'INSERT')
         then 'FAIL' else 'PASS' end
  union all
  select 'grant: anon cannot execute list_my_notifications_v1',
    case when has_function_privilege('anon', 'public.list_my_notifications_v1(integer,timestamptz,uuid)', 'EXECUTE')
         then 'FAIL' else 'PASS' end
  union all
  select 'grant: anon cannot execute register_notification_device_v1',
    case when has_function_privilege('anon', 'public.register_notification_device_v1(text,text,text,text,text,text,text,text)', 'EXECUTE')
         then 'FAIL' else 'PASS' end

  -- ------------------------------------------------- indexes / realtime
  union all
  select 'index: notifications_recipient_dedupe_uq',
    case when exists (
           select 1 from pg_indexes
           where schemaname = 'public' and tablename = 'notifications'
             and indexname = 'notifications_recipient_dedupe_uq')
         then 'PASS' else 'FAIL' end
  union all
  select 'realtime: notifications in supabase_realtime',
    case when exists (
           select 1 from pg_publication_tables
           where pubname = 'supabase_realtime'
             and schemaname = 'public' and tablename = 'notifications')
         then 'PASS' else 'FAIL' end

  -- ------------------------------------------- permission code coverage
  -- A wrong permission code produces zero recipients with no error, so every
  -- code used by the notification triggers is verified here.
  union all
  select 'permission coverage: payment.verify',
    case when exists (
           select 1
           from public.user_roles ur
           join public.role_permissions rp on rp.role_id = ur.role_id
           join public.permissions p on p.id = rp.permission_id
           join public.profiles pr on pr.id = ur.user_id
           where p.code = 'payment.verify' and pr.status = 'active')
         then 'PASS' else 'FAIL' end
  union all
  select 'permission coverage: savings.withdraw.approve',
    case when exists (
           select 1
           from public.user_roles ur
           join public.role_permissions rp on rp.role_id = ur.role_id
           join public.permissions p on p.id = rp.permission_id
           join public.profiles pr on pr.id = ur.user_id
           where p.code = 'savings.withdraw.approve' and pr.status = 'active')
         then 'PASS' else 'FAIL' end
  union all
  select 'permission coverage: loan.review',
    case when exists (
           select 1
           from public.user_roles ur
           join public.role_permissions rp on rp.role_id = ur.role_id
           join public.permissions p on p.id = rp.permission_id
           join public.profiles pr on pr.id = ur.user_id
           where p.code = 'loan.review' and pr.status = 'active')
         then 'PASS' else 'FAIL' end
  union all
  select 'permission coverage: expense.view',
    case when exists (
           select 1
           from public.user_roles ur
           join public.role_permissions rp on rp.role_id = ur.role_id
           join public.permissions p on p.id = rp.permission_id
           join public.profiles pr on pr.id = ur.user_id
           where p.code = 'expense.view' and pr.status = 'active')
         then 'PASS' else 'FAIL' end
  union all
  select 'permission coverage: membership.approve',
    case when exists (
           select 1
           from public.user_roles ur
           join public.role_permissions rp on rp.role_id = ur.role_id
           join public.permissions p on p.id = rp.permission_id
           join public.profiles pr on pr.id = ur.user_id
           where p.code = 'membership.approve' and pr.status = 'active')
         then 'PASS' else 'FAIL' end

  -- ---------------------------------------------------- infrastructure
  union all
  select 'deps: pg_cron available',
    case when to_regnamespace('cron') is not null then 'PASS' else 'FAIL' end
  union all
  select 'deps: pg_net available',
    case when to_regnamespace('net') is not null then 'PASS' else 'FAIL' end
  union all
  select 'deps: vault available',
    case when to_regnamespace('vault') is not null then 'PASS' else 'FAIL' end
  union all
  select 'deps: invoke_notification_push_worker_v1 exists',
    case when to_regprocedure('private.invoke_notification_push_worker_v1()') is not null
         then 'PASS' else 'FAIL' end
  union all
  select 'deps: notification_delivery_health_v1 exists',
    case when to_regclass('private.notification_delivery_health_v1') is not null
         then 'PASS' else 'FAIL' end
)
select check_name, status
from checks
order by (status = 'FAIL') desc, check_name;

-- ----------------------------------------------------------------------------
-- Optional: confirm the once-per-minute worker job is registered
-- (run after 20260929000040_notification_worker_schedule_v1.sql).
--
--   select jobid, schedule, active, command
--   from cron.job
--   where jobname = 'unity-finance-notification-push-worker-v1';
--
-- Optional: live delivery health snapshot.
--
--   select * from private.notification_delivery_health_v1;
--
-- Optional: unattended dedupe smoke test. This starts a transaction that is
-- rolled back, so it leaves no data behind:
--
--   begin;
--   select private.create_notification_v1(
--            (select id from public.profiles limit 1),
--            'system', 'verification.smoke', 'Verification smoke test',
--            'Dedupe verification', 'low', '{}'::jsonb, 'verification',
--            null, 'verification:smoke:v1');
--   select private.create_notification_v1(
--            (select id from public.profiles limit 1),
--            'system', 'verification.smoke', 'Verification smoke test',
--            'Dedupe verification', 'low', '{}'::jsonb, 'verification',
--            null, 'verification:smoke:v1');
--   select count(*) as inbox_rows_expected_1
--   from public.notifications
--   where dedupe_key = 'verification:smoke:v1';
--   rollback;
-- ----------------------------------------------------------------------------


