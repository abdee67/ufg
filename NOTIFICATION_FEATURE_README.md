# Unity Finance Transaction Notifications V1

Production-oriented notification infrastructure for the existing Unity Finance Supabase architecture.

## Included

Database migrations
- `supabase/migrations/20260929000038_notification_infrastructure_v1.sql` (applied)
- `supabase/migrations/20260929000039_notification_domain_integration_v1.sql` (workflow triggers: payments, withdrawals, loan applications, guarantors, repayment submissions, expenses, membership, serious defaults)
- `supabase/migrations/20260929000040_notification_worker_schedule_v1.sql` (Vault + pg_net + pg_cron once-per-minute worker invocation, delivery health view)
- `supabase/migrations/20260930000041_notification_push_diagnostics_v1.sql` (pipeline diagnostics snapshot + backfill/requeue recovery helpers)
- `supabase/migrations/20260930000042_notification_push_pipeline_hardening_v1.sql` (loud configuration failures, scheduled self-heal for late device registration, single scheduled tick)

Edge Function
- `supabase/functions/notification-push-worker/index.ts`
- `supabase/functions/notification-push-worker/deno.json`
- `supabase/config.toml` -> `[functions.notification-push-worker] verify_jwt = false`

Verification
- `supabase/tests/notification_v1_verification.sql` (read-only PASS/FAIL checks, including permission-code coverage and RLS/grants assertions)

Reference
- `Unity_Finance_Transaction_Notifications_Production_Implementation_Plan.md`
- `Unity_Finance_Notification_Domain_Integration_Snippets.md` (corrected permission codes + schema corrections)

## What this package does

- creates the notification inbox;
- creates device/token registration storage;
- creates push delivery state;
- creates notification preferences;
- enables strict RLS/grants;
- creates a durable `pgmq` push queue;
- emits member notifications from posted/reversed financial transactions;
- exposes controlled read/device/preference RPCs;
- supplies an FCM HTTP v1 Edge Function worker with retry/backoff and invalid-token cleanup.

## Important

The migration expects the Unity Finance MVP/domain schema to already exist. It was designed against the currently retrieved MVP, Savings and Loan production SQL sources.

Status (2026-09-29): `...038` has been applied by the project owner. `...039`,
`...040` and the verification script are new and must be applied in order.

Production fixes already applied to the worker after the code review:

- `prepare: false` on the Postgres connection: `SUPABASE_DB_URL` runs through the
  Supavisor pooler in transaction mode, which does not support prepared
  statements.
- `[functions.notification-push-worker] verify_jwt = false` in
  `supabase/config.toml`: the worker authenticates the caller itself with a named
  secret key, so the platform JWT check must be off for this function only.
- Workflow notification permission codes were corrected against the live RBAC
  definitions (`payment.verify`, `savings.withdraw.approve`, `loan.review`,
  `expense.view`, `membership.approve`). A wrong code silently targets nobody, so
  the verification script asserts coverage for each one.

The Edge Function expects these secrets/config values:

- `FCM_SERVICE_ACCOUNT_JSON`
- `FCM_PROJECT_ID` (optional if present in service-account JSON)
- Supabase runtime configuration, including `SUPABASE_DB_URL`
- a dedicated named Supabase secret key `notification_worker` for function authentication

Never commit Firebase service-account JSON or Supabase secret keys.

## Deployment runbook

### Phase 0 — already done
- `20260929000038_notification_infrastructure_v1.sql` applied.
- `pgmq` extension enabled in the project.
- Firebase Android config present (`android/app/google-services.json`, plugin applied).
- Worker hardened (`prepare: false`) and `verify_jwt = false` configured.

### Phase 1 — enable infrastructure extensions
1. Database > Extensions: ensure `pg_net` is enabled (pg_cron is already used by
   the loan scheduler; Vault is built in).

### Phase 2 — apply the new migrations
2. `supabase db push` (applies `...039` and `...040` in order).
3. Run `supabase/tests/notification_v1_verification.sql` in the SQL editor.
   Every row must be `PASS` before continuing. This includes the permission-code
   coverage assertions.

### Phase 3 — deploy the worker
4. `supabase functions deploy notification-push-worker`
   (`verify_jwt = false` comes from `supabase/config.toml`; add
   `--no-verify-jwt` if your CLI version ignores the config entry).
5. Set the Firebase service-account secret. Preferred path on Windows: paste the
   JSON content into Dashboard > Edge Functions > Secrets as
   `FCM_SERVICE_ACCOUNT_JSON`. CLI alternative:
   `supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$(Get-Content -Raw 'C:\secrets\FCM_CREDENTIALS.json')"`
   (`FCM_PROJECT_ID` is optional when `project_id` is present in the JSON).
6. Create a **secret** API key named exactly `notification_worker`
   (Project Settings > API Keys). Copy the `sb_secret_...` value once.

### Phase 4 — store scheduler secrets and smoke test
7. In the SQL editor:
   ```sql
   select vault.create_secret(
     'https://<project-ref>.supabase.co',
     'project_url',
     'Unity Finance project URL for the notification worker'
   );

   select vault.create_secret(
     '<sb_secret_...notification_worker...>',
     'notification_worker_key',
     'Notification push worker invocation key'
   );
   ```
8. Smoke test the worker and the queue:
   ```sql
   select private.invoke_notification_push_worker_v1();  -- returns a pg_net request id
   select * from private.notification_delivery_health_v1;
   select jobid, schedule, active from cron.job
    where jobname = 'unity-finance-notification-push-worker-v1';
   ```
   Expect `queued_count` to drop and `sent_24h` to rise once a device is
   registered.

### Phase 5 — Flutter member app (implemented)
9. Delivered files:
   - `lib/core/notifications/fcm_notification_service.dart` — Firebase init,
     permission, token registration/refresh, foreground display, tap routing,
     logout deactivation, top-level background handler.
   - `lib/core/notifications/notification_local_display_service.dart` — Android
     channel `financial_notifications` (matches the worker payload) + foreground
     display.
   - `lib/core/notifications/notification_navigation_service.dart` — payload →
     route mapping with a pending buffer for cold-start taps (the router is built
     asynchronously in `main.dart`).
   - `lib/features/notifications/**` — entity/model, RPC datasource, repository,
     6 use cases, `NotificationBloc` (shared singleton, Realtime + debounce +
     refetch-on-reconnect), inbox page, tile, header badge.
   - Wiring: `injection_container.dart`, `app_router.dart` (`/notification`
     route), `home_screen.dart` (real bell + unread badge), `main.dart`
     (FCM init, device sync on session start, badge refresh on resume),
     `auth_bloc.dart` (`onBeforeSignOut` deactivates the device while the JWT is
     still valid).
   - Test: `test/notification_navigation_service_test.dart`.
   Dependencies added: `firebase_core 4.15.0`, `firebase_messaging 16.7.0`,
   `flutter_local_notifications 22.3.1`.
   iOS remains out of scope (no `GoogleService-Info.plist`, APNs key, or Mac).
   Notification preferences RPCs exist server-side but have no UI yet.

### Phase 6 — Next.js admin panel (not yet implemented)
10. Add `lib/admin/notifications/queries.ts`,
    `app/(admin)/notifications/page.tsx` and a bell with unread badge in
    `components/shell/topbar.tsx`, using the same RPCs and Realtime.

### Phase 7 — observe before announcing
11. Watch `private.notification_delivery_health_v1`, FCM `invalid`/`failed`
    counts and worker errors for at least 48 hours of normal operations.
12. Browser push (FCM Web + VAPID) is intentionally deferred until in-app admin
    notifications are stable.

## Troubleshooting: "the badge shows a notification but no push arrives"

The in-app inbox is written in the same transaction as the business event, so it
keeps working even when the push chain is broken. Start with the diagnostics
snapshot:

```sql
select jsonb_pretty(private.notification_push_diagnostics_v1());
```

Read the result in this order:

| Observation | Meaning | Action |
|---|---|---|
| `devices.active` = 0 | No device ever registered | Open the app while signed in (registration runs on session start); check `adb logcat` for `Firebase init skipped` or `register_notification_device_v1 failed`; a phone/emulator without Google Play services cannot receive FCM at all |
| `recent_notifications[].delivery_rows` = 0 while `recipient_has_active_device` = true | The notification was created **before** the device registered, so no delivery job was ever queued | `select private.backfill_notification_deliveries_v1(200);` |
| `last_pg_net_responses[].status_code` = 404 | The Edge Function is not deployed | `supabase functions deploy notification-push-worker` |
| `last_pg_net_responses[].status_code` = 401/403 | Worker rejected the caller | A secret key must exist with the exact name `notification_worker`, and the function must run with `verify_jwt = false` |
| `last_pg_net_responses[].error_msg` not null / `timed_out` = true | pg_net could not reach the function | Ensure pg_net is enabled and Vault `project_url` is the project root (`https://<ref>.supabase.co`) |
| `vault_secret_names` missing `project_url` or `notification_worker_key` | From migration 042 the scheduled job **fails loudly** (`cron_recent_runs[].status` = `failed` with the reason); before 042 it only raised a WARNING and looked healthy | Recreate the Vault secrets |
| `cron_recent_runs[].status` <> `succeeded` | The scheduled command itself failed | Inspect `return_message` |
| `deliveries_by_status.queued` grows, nothing `sent` | The worker never completed a send | Check Edge Function logs + `recent_delivery_errors` |
| `recent_delivery_errors` = `SENDER_ID_MISMATCH` | The service account belongs to a different Firebase project | Use a service account from `unity-finance-group-ufg` |
| `recent_delivery_errors` = `UNREGISTERED` | The token is dead and the worker deactivated the device | Reopen the app so a fresh token is registered |
| `deliveries_by_status.sent` > 0, phone still silent | Client-side problem | Android 13+ notification permission, device notification settings, or the app being in the foreground (foreground messages are rendered by the app's local display) |
| Deliveries stuck in `failed` after fixing config | Retry them | `select private.requeue_notification_deliveries_v1();` (never revives `invalid` devices) |

Manual end-to-end check without waiting for the schedule:

```sql
select private.invoke_notification_push_worker_v1();   -- returns a pg_net request id
select status_code, error_msg, created, left(content, 300)
  from net._http_response order by created desc limit 3;
select * from private.notification_delivery_health_v1;
```

Note: `cron job N starting: select private.notification_push_tick_v1();` in the
Postgres logs only proves the schedule fired. The job's own result lives in
`cron.job_run_details`, and the HTTP outcome in `net._http_response` — both are
surfaced by the diagnostics function above. (Before migration 042 the scheduled
command was `select private.invoke_notification_push_worker_v1();`.)

### Automatic recovery (migration 042 and later)

Every tick (once a minute) runs `private.notification_push_tick_v1()`:

1. **self-heal** — inserts missing delivery rows (and queue messages) for
   notifications created in the last 7 days whose recipient now has an active
   device, capped at 50 per run. A device that registers *after* a notification
   was created therefore still receives that push on the next tick.
2. **invoke** the worker through pg_net.

Deliberately *not* automatic: deliveries in `failed` state (they usually mean bad
FCM credentials or a wrong Firebase project — fix the cause, then run
`select private.requeue_notification_deliveries_v1();`) and `invalid` devices
(the token is dead; the app must register a fresh one).

## Provider references

The implementation follows current Firebase FCM HTTP v1 authorization/sending guidance and current Firebase Flutter message-handling guidance. The plan also follows current Supabase guidance for Edge Function authentication, Postgres-native Queues and server-side secrets.
