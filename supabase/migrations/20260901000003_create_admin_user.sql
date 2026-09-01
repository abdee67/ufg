-- ===========================================================================
-- 20260901000003_create_admin_user.sql
-- ---------------------------------------------------------------------------
-- Promotes an existing Supabase auth user to the admin (or super_admin)
-- role so they can sign in to the Unity Finance admin panel.
--
-- The 20260831000000 migration defined an on_auth_user_created trigger
-- that auto-creates a profiles row from raw_user_meta_data. That trigger
-- may not be present (or may not have run for users created directly in
-- the Dashboard), and profiles.full_name is NOT NULL — so the bootstrap
-- function has to derive a full_name itself.
--
-- USAGE
-- -----
-- 1. Create the auth user first: Dashboard → Authentication → Users →
--    Add user → Create user (email + password).
--
-- 2. Open Dashboard → SQL Editor and run:
--
--      -- promote by exact email
--      select * from public.bootstrap_admin('mcnan6@gmail.com', false);
--
--      -- or, if you don't remember the exact email, look it up first:
--      select email from auth.users order by created_at desc;
--
-- 3. The function is idempotent — re-running it for the same email is
--    safe (it only writes a new audit row).
--
-- 4. Sign in at /login with the email + password you used in step 1.
--
-- For dev, there's also a "promote the first user" helper:
--      select * from public.bootstrap_first_admin(true);   -- super_admin
--      select * from public.bootstrap_first_admin(false);  -- admin
-- ===========================================================================

create or replace function public.bootstrap_admin(
  p_email text,
  p_super boolean default false
)
returns table (user_id uuid, role text, created boolean)
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_user_id      uuid;
  v_user_meta    jsonb;
  v_full_name    text;
  v_role_id      uuid;
  v_role_code    text;
  v_non_member   uuid;
  v_was_new      boolean := false;
begin
  -- 1. Resolve the auth user by email (case-insensitive).
  select id, raw_user_meta_data
    into v_user_id, v_user_meta
  from auth.users
  where lower(email) = lower(p_email)
  limit 1;

  if v_user_id is null then
    raise exception
      'No auth.users row found for email % (case-insensitive). '
      'Create the user first via Dashboard → Authentication → Users.',
      p_email;
  end if;

  -- 2. Resolve the target role id.
  v_role_code := case when p_super then 'super_admin' else 'admin' end;
  select id into v_role_id from public.roles where code = v_role_code;
  if v_role_id is null then
    raise exception
      'Role % is missing — apply the seed migration first.', v_role_code;
  end if;

  -- 3. Derive a NOT-NULL full_name for the profile row. Priority:
  --      a) raw_user_meta_data ->> 'full_name'  (set by Flutter sign-up)
  --      b) raw_user_meta_data ->> 'name'
  --      c) the email local-part (before '@'), title-cased
  --      d) a generic fallback
  v_full_name := coalesce(
    nullif(trim(coalesce(v_user_meta ->> 'full_name', '')), ''),
    nullif(trim(coalesce(v_user_meta ->> 'name',      '')), ''),
    initcap(split_part(p_email, '@', 1)),
    'Admin User'
  );

  -- 4. Ensure the profile row exists and has a non-null full_name.
  --    The Supabase auth hook (on_auth_user_created) normally creates
  --    the profile at user-creation time. In some configurations it
  --    inserts a row with full_name = NULL, which then trips the
  --    NOT NULL constraint on the column. The upsert below backfills
  --    full_name only when the existing value is missing/blank, so a
  --    profile created with a real name is preserved.
  insert into public.profiles (id, full_name, email)
  values (v_user_id, v_full_name, p_email)
  on conflict (id) do update
    set full_name = case
      when profiles.full_name is null
        or btrim(profiles.full_name) = ''
      then excluded.full_name
      else profiles.full_name
    end,
    email     = excluded.email;

  -- 5. Assign the admin role (idempotent).
  if not exists (
    select 1 from public.user_roles
    where user_id = v_user_id and role_id = v_role_id
  ) then
    insert into public.user_roles (user_id, role_id, assigned_by)
    values (v_user_id, v_role_id, v_user_id);
    v_was_new := true;
  end if;

  -- 6. Remove the non_member role if it was assigned by the trigger.
  select id into v_non_member from public.roles where code = 'non_member';
  if v_non_member is not null then
    delete from public.user_roles
    where user_id = v_user_id
      and role_id = v_non_member;
  end if;

  -- 7. Audit the bootstrap.
  insert into public.audit_logs (
    actor_user_id, action, entity_type, entity_id, new_data
  )
  values (
    v_user_id,
    'ADMIN_BOOTSTRAP',
    'user_roles',
    v_user_id,
    jsonb_build_object('email', p_email, 'role', v_role_code)
  );

  return query select v_user_id, v_role_code, v_was_new;
end;
$$;

grant execute on function public.bootstrap_admin(text, boolean)
  to postgres, service_role;

-- Convenience: promote the oldest user in auth.users.
create or replace function public.bootstrap_first_admin(
  p_super boolean default false
)
returns table (user_id uuid, role text, created boolean)
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_email text;
begin
  select email into v_email
  from auth.users
  order by created_at asc
  limit 1;

  if v_email is null then
    raise exception 'auth.users is empty — register a user first.';
  end if;

  return query select * from public.bootstrap_admin(v_email, p_super);
end;
$$;

grant execute on function public.bootstrap_first_admin(boolean)
  to postgres, service_role;
