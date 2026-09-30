/*
===============================================================================
UNITY FINANCE GROUP
Notification Infrastructure V1
===============================================================================

Target:
  Existing Unity Finance MVP schema + Savings/Admin Savings + Loan V2/V3
  hardening migrations.

Purpose:
  - Unified in-app notification inbox for members and administrators.
  - FCM device registration and delivery tracking.
  - Postgres-native durable push queue using Supabase pgmq.
  - Atomic transaction -> notification creation for posted/reversed
    financial transactions.
  - Internal helper for domain RPCs to notify users/admins without exposing
    privileged notification writes to clients.

Important:
  - This migration does NOT require a service-role key in Flutter/Next.js.
  - Notification rows are user-owned data and are protected by RLS.
  - Financial notification creation happens inside the same DB transaction
    as the business operation. Push delivery happens asynchronously.
  - The FCM provider boundary is at-least-once: a worker crash immediately
    after FCM accepts a request can cause a duplicate push. In-app notification
    identity remains deduplicated by notification UUID/dedupe key.

Prerequisites:
  - Existing public.profiles
  - Existing public.user_roles / roles / permissions / role_permissions
  - Existing public.members
  - Existing public.transactions / transaction_entries
  - pgmq extension available on the Supabase project

The migration creates the pgmq queue but does not expose pgmq to clients.
The worker consumes the queue through a server-side Postgres connection.
===============================================================================
*/

begin;

-- ============================================================================
-- 0. Dependency guards
-- ============================================================================

do $$
begin
  if to_regclass('public.profiles') is null
     or to_regclass('public.user_roles') is null
     or to_regclass('public.roles') is null
     or to_regclass('public.permissions') is null
     or to_regclass('public.role_permissions') is null
     or to_regclass('public.members') is null
     or to_regclass('public.transactions') is null
     or to_regclass('public.transaction_entries') is null
  then
    raise exception
      'Unity Finance base financial/RBAC schema is missing. Apply the MVP and domain migrations first.';
  end if;
end;
$$;

create schema if not exists private;

-- pgmq is used as the durable push delivery queue. Basic queues are logged
-- and therefore preferred over unlogged queues for financial-system
-- notifications.
create extension if not exists pgmq;

-- Create the queue only when its backing queue table does not exist.
do $$
begin
  if to_regclass('pgmq.q_notification_push') is null then
    perform pgmq.create('notification_push');
  end if;
end;
$$;

-- ============================================================================
-- 1. Notification preferences
-- ============================================================================

create table if not exists public.notification_preferences (
  profile_id uuid primary key
    references public.profiles(id) on delete cascade,
  push_enabled boolean not null default true,
  transaction_push_enabled boolean not null default true,
  payment_push_enabled boolean not null default true,
  savings_push_enabled boolean not null default true,
  loan_push_enabled boolean not null default true,
  membership_push_enabled boolean not null default true,
  system_push_enabled boolean not null default true,
  updated_at timestamptz not null default now()
);

create index if not exists notification_preferences_push_idx
  on public.notification_preferences(profile_id)
  where push_enabled = true;

-- Existing profiles receive default notification settings lazily or through
-- this backfill. The trigger below handles all future profiles.
insert into public.notification_preferences(profile_id)
select p.id
from public.profiles p
on conflict (profile_id) do nothing;

-- ============================================================================
-- 2. FCM / notification devices
-- ============================================================================

create table if not exists public.notification_devices (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null
    references public.profiles(id) on delete cascade,
  fcm_token text not null
    check (length(trim(fcm_token)) between 20 and 4096),
  platform text not null
    check (platform in ('android', 'ios', 'web')),
  app_type text not null
    check (app_type in ('member', 'admin')),
  device_identifier text,
  app_version text,
  app_build text,
  locale text,
  timezone text,
  is_active boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (fcm_token)
);

create unique index if not exists notification_devices_profile_device_uq
  on public.notification_devices(profile_id, device_identifier)
  where device_identifier is not null;

create index if not exists notification_devices_profile_active_idx
  on public.notification_devices(profile_id, is_active, updated_at desc);

create index if not exists notification_devices_last_seen_idx
  on public.notification_devices(last_seen_at desc)
  where is_active = true;

-- ============================================================================
-- 3. Notification inbox
-- ============================================================================

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_profile_id uuid not null
    references public.profiles(id) on delete cascade,

  category text not null
    check (category in (
      'transaction',
      'payment',
      'savings',
      'loan',
      'membership',
      'system'
    )),

  type text not null
    check (length(trim(type)) between 3 and 100),

  title text not null
    check (length(trim(title)) between 1 and 160),

  body text not null
    check (length(trim(body)) between 1 and 1000),

  priority text not null default 'normal'
    check (priority in ('low', 'normal', 'high', 'critical')),

  data jsonb not null default '{}'::jsonb
    check (jsonb_typeof(data) = 'object'),

  source_type text,
  source_id uuid,
  dedupe_key text,

  read_at timestamptz,
  created_at timestamptz not null default now(),
  expires_at timestamptz,

  constraint notifications_dedupe_key_len_ck
    check (dedupe_key is null or length(trim(dedupe_key)) between 1 and 255)
);

create unique index if not exists notifications_recipient_dedupe_uq
  on public.notifications(recipient_profile_id, dedupe_key)
  where dedupe_key is not null;

create index if not exists notifications_recipient_created_idx
  on public.notifications(recipient_profile_id, created_at desc, id desc);

create index if not exists notifications_unread_idx
  on public.notifications(recipient_profile_id, created_at desc)
  where read_at is null;

create index if not exists notifications_source_idx
  on public.notifications(source_type, source_id, created_at desc);

-- ============================================================================
-- 4. Push delivery state
-- ============================================================================

create table if not exists public.notification_deliveries (
  id uuid primary key default gen_random_uuid(),
  notification_id uuid not null
    references public.notifications(id) on delete cascade,
  device_id uuid not null
    references public.notification_devices(id) on delete cascade,
  channel text not null default 'fcm'
    check (channel in ('fcm')),
  status text not null default 'queued'
    check (status in ('queued', 'processing', 'sent', 'invalid', 'failed')),

  attempt_count integer not null default 0
    check (attempt_count >= 0),

  available_at timestamptz not null default now(),
  lease_until timestamptz,

  provider_message_id text,
  last_error_code text,
  last_error_message text,

  created_at timestamptz not null default now(),
  sent_at timestamptz,
  updated_at timestamptz not null default now(),

  unique (notification_id, device_id, channel)
);

create index if not exists notification_deliveries_queue_idx
  on public.notification_deliveries(status, available_at)
  where status in ('queued', 'processing');

create index if not exists notification_deliveries_notification_idx
  on public.notification_deliveries(notification_id, status);

create index if not exists notification_deliveries_device_idx
  on public.notification_deliveries(device_id, created_at desc);

-- ============================================================================
-- 5. Standard updated_at trigger
-- ============================================================================

-- Reuse the project's existing trigger if present. If not, create a local
-- notification-specific helper. This avoids depending on another migration's
-- trigger name/definition.
create or replace function private.notifications_set_updated_at_v1()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

revoke all on function private.notifications_set_updated_at_v1() from public, anon, authenticated;

drop trigger if exists trg_notification_devices_updated_at_v1
  on public.notification_devices;
create trigger trg_notification_devices_updated_at_v1
before update on public.notification_devices
for each row execute function private.notifications_set_updated_at_v1();

drop trigger if exists trg_notification_deliveries_updated_at_v1
  on public.notification_deliveries;
create trigger trg_notification_deliveries_updated_at_v1
before update on public.notification_deliveries
for each row execute function private.notifications_set_updated_at_v1();

drop trigger if exists trg_notification_preferences_updated_at_v1
  on public.notification_preferences;
create trigger trg_notification_preferences_updated_at_v1
before update on public.notification_preferences
for each row execute function private.notifications_set_updated_at_v1();

-- Ensure every future profile gets a preference row.
create or replace function private.ensure_notification_preferences_v1()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.notification_preferences(profile_id)
  values (new.id)
  on conflict (profile_id) do nothing;
  return new;
end;
$$;

revoke all on function private.ensure_notification_preferences_v1() from public, anon, authenticated;

drop trigger if exists trg_profile_notification_preferences_v1
  on public.profiles;
create trigger trg_profile_notification_preferences_v1
after insert on public.profiles
for each row execute function private.ensure_notification_preferences_v1();

-- ============================================================================
-- 6. Internal notification creation primitive
-- ============================================================================

/*
  Creates the durable in-app notification and queues one FCM delivery job per
  eligible active device. This function is PRIVATE by design. Domain RPCs run
  under their own privileged boundary and can call it; clients cannot.
*/
create or replace function private.create_notification_v1(
  p_recipient_profile_id uuid,
  p_category text,
  p_type text,
  p_title text,
  p_body text,
  p_priority text default 'normal',
  p_data jsonb default '{}'::jsonb,
  p_source_type text default null,
  p_source_id uuid default null,
  p_dedupe_key text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_notification_id uuid;
  v_delivery_id uuid;
  v_push_allowed boolean;
  v_category_push_allowed boolean;
begin
  if p_recipient_profile_id is null then
    raise exception 'Notification recipient is required';
  end if;

  if p_category not in (
    'transaction', 'payment', 'savings', 'loan', 'membership', 'system'
  ) then
    raise exception 'Invalid notification category: %', p_category;
  end if;

  if p_priority not in ('low', 'normal', 'high', 'critical') then
    raise exception 'Invalid notification priority: %', p_priority;
  end if;

  if jsonb_typeof(coalesce(p_data, '{}'::jsonb)) <> 'object' then
    raise exception 'Notification data must be a JSON object';
  end if;

  if p_dedupe_key is not null then
    select id
    into v_notification_id
    from public.notifications
    where recipient_profile_id = p_recipient_profile_id
      and dedupe_key = p_dedupe_key
    limit 1;

    if v_notification_id is not null then
      return v_notification_id;
    end if;
  end if;

  insert into public.notifications (
    recipient_profile_id,
    category,
    type,
    title,
    body,
    priority,
    data,
    source_type,
    source_id,
    dedupe_key
  )
  values (
    p_recipient_profile_id,
    p_category,
    p_type,
    trim(p_title),
    trim(p_body),
    p_priority,
    coalesce(p_data, '{}'::jsonb),
    p_source_type,
    p_source_id,
    nullif(trim(p_dedupe_key), '')
  )
  on conflict do nothing
  returning id into v_notification_id;

  if v_notification_id is null and p_dedupe_key is not null then
    select id
    into v_notification_id
    from public.notifications
    where recipient_profile_id = p_recipient_profile_id
      and dedupe_key = p_dedupe_key
    limit 1;
  end if;

  select
    coalesce(np.push_enabled, true),
    case p_category
      when 'transaction' then coalesce(np.transaction_push_enabled, true)
      when 'payment' then coalesce(np.payment_push_enabled, true)
      when 'savings' then coalesce(np.savings_push_enabled, true)
      when 'loan' then coalesce(np.loan_push_enabled, true)
      when 'membership' then coalesce(np.membership_push_enabled, true)
      when 'system' then coalesce(np.system_push_enabled, true)
      else true
    end
  into v_push_allowed, v_category_push_allowed
  from public.notification_preferences np
  where np.profile_id = p_recipient_profile_id;

  v_push_allowed := coalesce(v_push_allowed, true);
  v_category_push_allowed := coalesce(v_category_push_allowed, true);

  update public.notifications
  set data = data || jsonb_build_object('notification_id', v_notification_id)
  where id = v_notification_id
    and not (data ? 'notification_id');

  if v_push_allowed and v_category_push_allowed then
    for v_delivery_id in
      select nd.id
      from public.notification_devices nd
      where nd.profile_id = p_recipient_profile_id
        and nd.is_active = true
    loop
      insert into public.notification_deliveries(
        notification_id,
        device_id,
        channel,
        status,
        available_at
      )
      values (
        v_notification_id,
        v_delivery_id,
        'fcm',
        'queued',
        now()
      )
      on conflict (notification_id, device_id, channel) do nothing;
    end loop;

    for v_delivery_id in
      select ndel.id
      from public.notification_deliveries ndel
      where ndel.notification_id = v_notification_id
        and ndel.status = 'queued'
        and ndel.channel = 'fcm'
    loop
      perform pgmq.send(
        'notification_push',
        jsonb_build_object('delivery_id', v_delivery_id::text, 'version', 1)
      );
    end loop;
  end if;

  return v_notification_id;
end;
$$;

revoke all on function private.create_notification_v1(
  uuid, text, text, text, text, text, jsonb, text, uuid, text
) from public, anon, authenticated;

-- ============================================================================
-- 7. Internal helper: notify users that have a given permission
-- ============================================================================

create or replace function private.notify_users_with_permission_v1(
  p_permission_code text,
  p_category text,
  p_type text,
  p_title text,
  p_body text,
  p_priority text default 'normal',
  p_data jsonb default '{}'::jsonb,
  p_source_type text default null,
  p_source_id uuid default null,
  p_dedupe_key text default null,
  p_exclude_profile_id uuid default null
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_profile_id uuid;
  v_count integer := 0;
  v_notification_dedupe text;
begin
  for v_profile_id in
    select distinct ur.user_id
    from public.user_roles ur
    join public.role_permissions rp
      on rp.role_id = ur.role_id
    join public.permissions p
      on p.id = rp.permission_id
    join public.profiles pr
      on pr.id = ur.user_id
    where p.code = p_permission_code
      and pr.status = 'active'
      and ur.user_id <> coalesce(p_exclude_profile_id, '00000000-0000-0000-0000-000000000000'::uuid)
  loop
    v_notification_dedupe := case
      when p_dedupe_key is null then null
      else p_dedupe_key
    end;

    perform private.create_notification_v1(
      v_profile_id,
      p_category,
      p_type,
      p_title,
      p_body,
      p_priority,
      p_data,
      p_source_type,
      p_source_id,
      v_notification_dedupe
    );

    v_count := v_count + 1;
  end loop;

  return v_count;
end;
$$;

revoke all on function private.notify_users_with_permission_v1(
  text, text, text, text, text, text, jsonb, text, uuid, text, uuid
) from public, anon, authenticated;

-- ============================================================================
-- 8. Public RPC: notification list
-- ============================================================================

create or replace function public.list_my_notifications_v1(
  p_limit integer default 30,
  p_before_created_at timestamptz default null,
  p_before_id uuid default null
)
returns setof public.notifications
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := (select auth.uid());
  v_limit integer := least(greatest(coalesce(p_limit, 30), 1), 100);
begin
  if v_user is null then
    raise exception 'Not authenticated';
  end if;

  return query
  select n.*
  from public.notifications n
  where n.recipient_profile_id = v_user
    and (
      p_before_created_at is null
      or (n.created_at, n.id) < (p_before_created_at, coalesce(p_before_id, 'ffffffff-ffff-ffff-ffff-ffffffffffff'::uuid))
    )
    and (
      n.expires_at is null
      or n.expires_at > now()
    )
  order by n.created_at desc, n.id desc
  limit v_limit;
end;
$$;

revoke all on function public.list_my_notifications_v1(integer, timestamptz, uuid)
  from public, anon;
grant execute on function public.list_my_notifications_v1(integer, timestamptz, uuid)
  to authenticated;

-- ============================================================================
-- 9. Public RPC: unread count
-- ============================================================================

create or replace function public.get_my_unread_notification_count_v1()
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select count(*)::integer
  from public.notifications n
  where n.recipient_profile_id = (select auth.uid())
    and n.read_at is null
    and (n.expires_at is null or n.expires_at > now());
$$;

revoke all on function public.get_my_unread_notification_count_v1()
  from public, anon;
grant execute on function public.get_my_unread_notification_count_v1()
  to authenticated;

-- ============================================================================
-- 10. Public RPC: mark read
-- ============================================================================

create or replace function public.mark_notification_read_v1(
  p_notification_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := (select auth.uid());
  v_updated integer;
begin
  if v_user is null then
    raise exception 'Not authenticated';
  end if;

  update public.notifications
  set read_at = coalesce(read_at, now())
  where id = p_notification_id
    and recipient_profile_id = v_user
    and read_at is null;

  get diagnostics v_updated = row_count;
  return v_updated > 0;
end;
$$;

revoke all on function public.mark_notification_read_v1(uuid)
  from public, anon;
grant execute on function public.mark_notification_read_v1(uuid)
  to authenticated;

-- ============================================================================
-- 11. Public RPC: mark all read
-- ============================================================================

create or replace function public.mark_all_notifications_read_v1()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := (select auth.uid());
  v_updated integer;
begin
  if v_user is null then
    raise exception 'Not authenticated';
  end if;

  update public.notifications
  set read_at = now()
  where recipient_profile_id = v_user
    and read_at is null;

  get diagnostics v_updated = row_count;
  return v_updated;
end;
$$;

revoke all on function public.mark_all_notifications_read_v1()
  from public, anon;
grant execute on function public.mark_all_notifications_read_v1()
  to authenticated;

-- ============================================================================
-- 12. Public RPC: register / refresh FCM device
-- ============================================================================

create or replace function public.register_notification_device_v1(
  p_fcm_token text,
  p_platform text,
  p_app_type text default 'member',
  p_device_identifier text default null,
  p_app_version text default null,
  p_app_build text default null,
  p_locale text default null,
  p_timezone text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := (select auth.uid());
  v_device_id uuid;
  v_is_admin boolean;
begin
  if v_user is null then
    raise exception 'Not authenticated';
  end if;

  if p_platform not in ('android', 'ios', 'web') then
    raise exception 'Invalid platform';
  end if;

  if p_app_type not in ('member', 'admin') then
    raise exception 'Invalid app type';
  end if;

  if p_app_type = 'admin' then
    select exists (
      select 1
      from public.user_roles ur
      join public.roles r on r.id = ur.role_id
      where ur.user_id = v_user
        and r.code in ('admin', 'super_admin')
    ) into v_is_admin;

    if not v_is_admin then
      raise exception 'Only administrators may register an admin application device';
    end if;
  end if;

  if length(trim(coalesce(p_fcm_token, ''))) < 20 then
    raise exception 'Invalid FCM token';
  end if;

  insert into public.notification_devices (
    profile_id,
    fcm_token,
    platform,
    app_type,
    device_identifier,
    app_version,
    app_build,
    locale,
    timezone,
    is_active,
    last_seen_at
  )
  values (
    v_user,
    trim(p_fcm_token),
    p_platform,
    p_app_type,
    nullif(trim(p_device_identifier), ''),
    nullif(trim(p_app_version), ''),
    nullif(trim(p_app_build), ''),
    nullif(trim(p_locale), ''),
    nullif(trim(p_timezone), ''),
    true,
    now()
  )
  on conflict (fcm_token)
  do update set
    profile_id = excluded.profile_id,
    platform = excluded.platform,
    app_type = excluded.app_type,
    device_identifier = excluded.device_identifier,
    app_version = excluded.app_version,
    app_build = excluded.app_build,
    locale = excluded.locale,
    timezone = excluded.timezone,
    is_active = true,
    last_seen_at = now(),
    updated_at = now()
  returning id into v_device_id;

  return v_device_id;
end;
$$;

revoke all on function public.register_notification_device_v1(
  text, text, text, text, text, text, text, text
) from public, anon;
grant execute on function public.register_notification_device_v1(
  text, text, text, text, text, text, text, text
) to authenticated;

-- ============================================================================
-- 13. Public RPC: deactivate device
-- ============================================================================

create or replace function public.deactivate_notification_device_v1(
  p_fcm_token text
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := (select auth.uid());
  v_updated integer;
begin
  if v_user is null then
    raise exception 'Not authenticated';
  end if;

  update public.notification_devices
  set is_active = false,
      updated_at = now()
  where profile_id = v_user
    and fcm_token = trim(p_fcm_token)
    and is_active = true;

  get diagnostics v_updated = row_count;
  return v_updated > 0;
end;
$$;

revoke all on function public.deactivate_notification_device_v1(text)
  from public, anon;
grant execute on function public.deactivate_notification_device_v1(text)
  to authenticated;

-- ============================================================================
-- 14. Notification preferences RPCs
-- ============================================================================

create or replace function public.get_my_notification_preferences_v1()
returns public.notification_preferences
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user uuid := (select auth.uid());
  v_row public.notification_preferences%rowtype;
begin
  if v_user is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_row
  from public.notification_preferences
  where profile_id = v_user;

  if v_row.profile_id is null then
    insert into public.notification_preferences(profile_id)
    values (v_user)
    on conflict (profile_id) do nothing;

    select * into v_row
    from public.notification_preferences
    where profile_id = v_user;
  end if;

  return v_row;
end;
$$;

revoke all on function public.get_my_notification_preferences_v1()
  from public, anon;
grant execute on function public.get_my_notification_preferences_v1()
  to authenticated;

create or replace function public.update_my_notification_preferences_v1(
  p_push_enabled boolean default null,
  p_transaction_push_enabled boolean default null,
  p_payment_push_enabled boolean default null,
  p_savings_push_enabled boolean default null,
  p_loan_push_enabled boolean default null,
  p_membership_push_enabled boolean default null,
  p_system_push_enabled boolean default null
)
returns public.notification_preferences
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := (select auth.uid());
  v_row public.notification_preferences%rowtype;
begin
  if v_user is null then
    raise exception 'Not authenticated';
  end if;

  insert into public.notification_preferences(profile_id)
  values (v_user)
  on conflict (profile_id) do nothing;

  update public.notification_preferences
  set
    push_enabled = coalesce(p_push_enabled, push_enabled),
    transaction_push_enabled = coalesce(p_transaction_push_enabled, transaction_push_enabled),
    payment_push_enabled = coalesce(p_payment_push_enabled, payment_push_enabled),
    savings_push_enabled = coalesce(p_savings_push_enabled, savings_push_enabled),
    loan_push_enabled = coalesce(p_loan_push_enabled, loan_push_enabled),
    membership_push_enabled = coalesce(p_membership_push_enabled, membership_push_enabled),
    system_push_enabled = coalesce(p_system_push_enabled, system_push_enabled),
    updated_at = now()
  where profile_id = v_user
  returning * into v_row;

  return v_row;
end;
$$;

revoke all on function public.update_my_notification_preferences_v1(
  boolean, boolean, boolean, boolean, boolean, boolean, boolean
) from public, anon;
grant execute on function public.update_my_notification_preferences_v1(
  boolean, boolean, boolean, boolean, boolean, boolean, boolean
) to authenticated;

-- ============================================================================
-- 15. Financial transaction -> member notification trigger
-- ============================================================================

/*
  Meaningful event boundary:
    - insert a transaction already in POSTED state, OR
    - transition an existing transaction into POSTED, OR
    - transition an existing non-reversed transaction into REVERSED, OR
    - insert a reversal transaction.

  The notification is emitted to the transaction's member/profile. For a
  reversal row, the original transaction is used as a fallback recipient/source
  context so the member still receives the event when the reversal row does not
  repeat profile_id/member_id.
*/
create or replace function private.notify_transaction_transition_v1()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_profile_id uuid;
  v_member_id uuid;
  v_amount numeric(18,2);
  v_transaction_id uuid;
  v_reference text;
  v_type text;
  v_title text;
  v_body text;
  v_notification_type text;
  v_priority text := 'normal';
  v_dedupe_key text;
  v_data jsonb;
  v_original public.transactions%rowtype;
  v_should_post boolean := false;
  v_should_reverse boolean := false;
begin
  if tg_op = 'INSERT' then
    v_should_post := new.transaction_status = 'posted';
    v_should_reverse := new.transaction_type = 'reversal'
                        and new.transaction_status = 'posted';
  elsif tg_op = 'UPDATE' then
    v_should_post := old.transaction_status <> 'posted'
                     and new.transaction_status = 'posted';
    v_should_reverse := old.transaction_status <> 'reversed'
                        and new.transaction_status = 'reversed';
  end if;

  if not v_should_post and not v_should_reverse then
    return new;
  end if;

  v_profile_id := new.profile_id;
  v_member_id := new.member_id;
  v_amount := new.amount;
  v_transaction_id := new.id;
  v_reference := new.reference_number;
  v_type := new.transaction_type::text;

  if new.transaction_type = 'reversal'
     and new.reversal_of_transaction_id is not null then
    select * into v_original
    from public.transactions
    where id = new.reversal_of_transaction_id;

    v_profile_id := coalesce(v_profile_id, v_original.profile_id);
    v_member_id := coalesce(v_member_id, v_original.member_id);

    if v_should_reverse then
      v_transaction_id := coalesce(new.reversal_of_transaction_id, new.id);
      v_reference := coalesce(v_original.reference_number, new.reference_number);
      v_amount := coalesce(v_original.amount, new.amount);
      v_type := 'reversal';
    end if;
  end if;

  if v_profile_id is null and v_member_id is not null then
    select m.profile_id into v_profile_id
    from public.members m
    where m.id = v_member_id;
  end if;

  if v_profile_id is null then
    return new;
  end if;

  if v_should_reverse then
    v_notification_type := 'transaction.reversed';
    v_title := 'Financial transaction reversed';
    v_body := format(
      'Your transaction %s has been reversed. Open Unity Finance to review the details.',
      v_reference
    );
    v_priority := 'high';
    v_dedupe_key := 'transaction:reversed:' || v_transaction_id::text;
  else
    v_notification_type := 'transaction.posted';
    v_dedupe_key := 'transaction:posted:' || v_transaction_id::text;

    v_title := case v_type
      when 'savings_contribution' then 'Savings contribution posted'
      when 'savings_withdrawal' then 'Savings withdrawal posted'
      when 'savings_late_penalty' then 'Savings penalty posted'
      when 'loan_disbursement' then 'Loan disbursement posted'
      when 'loan_repayment' then 'Loan repayment posted'
      when 'loan_late_penalty' then 'Loan late penalty posted'
      when 'membership_fee' then 'Membership payment posted'
      when 'first_contribution' then 'First contribution posted'
      else 'Transaction posted'
    end;

    v_body := format(
      'Transaction %s has been posted to your Unity Finance account. Open the app to review the details.',
      v_reference
    );
  end if;

  v_data := jsonb_build_object(
    'target_type', 'transaction',
    'transaction_id', v_transaction_id,
    'transaction_reference', v_reference,
    'transaction_type', v_type,
    'amount', v_amount,
    'currency', new.currency,
    'member_id', v_member_id,
    'profile_id', v_profile_id
  );

  perform private.create_notification_v1(
    v_profile_id,
    'transaction',
    v_notification_type,
    v_title,
    v_body,
    v_priority,
    v_data,
    'transaction',
    v_transaction_id,
    v_dedupe_key
  );

  return new;
end;
$$;

revoke all on function private.notify_transaction_transition_v1()
  from public, anon, authenticated;

drop trigger if exists trg_transaction_notifications_v1
  on public.transactions;
create trigger trg_transaction_notifications_v1
after insert or update of transaction_status, transaction_type, reversal_of_transaction_id,
    profile_id, member_id
on public.transactions
for each row execute function private.notify_transaction_transition_v1();

-- ============================================================================
-- 16. RLS
-- ============================================================================

alter table public.notifications enable row level security;
alter table public.notification_devices enable row level security;
alter table public.notification_deliveries enable row level security;
alter table public.notification_preferences enable row level security;

-- Notifications: members/admins can see only their own inbox.
drop policy if exists notifications_select_own_v1 on public.notifications;
create policy notifications_select_own_v1
on public.notifications
for select
to authenticated
using ((select auth.uid()) = recipient_profile_id);

-- Device metadata is private to its owner. Tokens are not granted for general
-- admin browsing; the app only needs its own registration state if it queries it.
drop policy if exists notification_devices_select_own_v1 on public.notification_devices;
create policy notification_devices_select_own_v1
on public.notification_devices
for select
to authenticated
using ((select auth.uid()) = profile_id);

-- Preferences are private to their owner.
drop policy if exists notification_preferences_select_own_v1 on public.notification_preferences;
create policy notification_preferences_select_own_v1
on public.notification_preferences
for select
to authenticated
using ((select auth.uid()) = profile_id);

-- No client policy for notification_deliveries. This is internal delivery state.

-- ============================================================================
-- 17. Direct grants: least privilege
-- ============================================================================

-- Read-only inbox access for Realtime + optional direct SELECT.
grant select on public.notifications to authenticated;
revoke insert, update, delete on public.notifications from authenticated, anon;

-- Device and preferences writes happen only through RPCs.
grant select on public.notification_devices to authenticated;
revoke insert, update, delete on public.notification_devices from authenticated, anon;

grant select on public.notification_preferences to authenticated;
revoke insert, update, delete on public.notification_preferences from authenticated, anon;

revoke all on public.notification_deliveries from authenticated, anon;

-- ============================================================================
-- 18. Realtime publication
-- ============================================================================

-- Add notifications to Supabase Realtime Postgres Changes publication if it
-- exists and the table is not already a member. This is needed for real-time
-- unread count/inbox updates in the apps.
do $$
begin
  if exists (
    select 1
    from pg_publication
    where pubname = 'supabase_realtime'
  ) and not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    execute 'alter publication supabase_realtime add table public.notifications';
  end if;
end;
$$;

-- ============================================================================
-- 19. Internal cleanup helper
-- ============================================================================

create or replace function private.cleanup_notifications_v1(
  p_retention_days integer default 180
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_deleted integer;
begin
  if p_retention_days < 30 or p_retention_days > 730 then
    raise exception 'Notification retention must be between 30 and 730 days';
  end if;

  delete from public.notifications
  where created_at < now() - make_interval(days => p_retention_days);

  get diagnostics v_deleted = row_count;
  return v_deleted;
end;
$$;

revoke all on function private.cleanup_notifications_v1(integer)
  from public, anon, authenticated;

-- ============================================================================
-- 20. Optional scheduled cleanup
-- ============================================================================

-- Requires pg_cron to be available. The notification worker schedule is
-- configured separately because its Edge Function URL and secret key must be
-- provisioned in Vault first.
do $$
begin
  if to_regnamespace('cron') is not null
     and not exists (
       select 1 from cron.job where jobname = 'unity-finance-notification-cleanup-v1'
     ) then
    perform cron.schedule(
      'unity-finance-notification-cleanup-v1',
      '15 3 * * *',
      'select private.cleanup_notifications_v1(180);'
    );
  end if;
exception
  when undefined_table then
    null;
  when undefined_function then
    null;
end;
$$;

commit;
