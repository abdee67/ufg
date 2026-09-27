-- Supabase Auth may persist phone credentials without a leading `+`, while
-- application input and profile mirrors use canonical E.164 with `+`.
-- Compare the same number independent of that storage representation.

create or replace function public.bootstrap_admin(
  -- Name retained because PostgreSQL cannot rename existing input parameters
  -- through CREATE OR REPLACE FUNCTION. The value is a phone number.
  p_email text,
  p_super boolean default false
)
returns table (user_id uuid, role text, created boolean)
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_phone        text;
  v_user_id      uuid;
  v_user_meta    jsonb;
  v_email        text;
  v_full_name    text;
  v_role_id      uuid;
  v_role_code    text;
  v_non_member   uuid;
  v_was_new      boolean := false;
begin
  v_phone := regexp_replace(trim(coalesce(p_email, '')), '[[:space:]()\-]', '', 'g');
  if left(v_phone, 2) = '00' then
    v_phone := '+' || substring(v_phone from 3);
  elsif left(v_phone, 1) = '0' then
    v_phone := '+251' || substring(v_phone from 2);
  elsif left(v_phone, 3) = '251' then
    v_phone := '+' || v_phone;
  end if;

  if v_phone !~ '^\+[1-9][0-9]{7,14}$' then
    raise exception 'Use a valid E.164 phone number.';
  end if;

  select id, raw_user_meta_data, email
    into v_user_id, v_user_meta, v_email
  from auth.users
  where ltrim(phone, '+') = ltrim(v_phone, '+')
  limit 1;

  if v_user_id is null then
    raise exception
      'No auth.users row found for phone %. Create the phone/password Auth user first.',
      v_phone;
  end if;

  v_role_code := case when p_super then 'super_admin' else 'admin' end;
  select id into v_role_id from public.roles where code = v_role_code;
  if v_role_id is null then
    raise exception 'Role % is missing; apply the role seed migration first.', v_role_code;
  end if;

  v_full_name := coalesce(
    nullif(trim(coalesce(v_user_meta ->> 'full_name', '')), ''),
    nullif(trim(coalesce(v_user_meta ->> 'name', '')), ''),
    'Admin User'
  );

  insert into public.profiles (id, full_name, phone, email)
  values (v_user_id, v_full_name, v_phone, v_email)
  on conflict (id) do update
    set full_name = case
          when profiles.full_name is null or btrim(profiles.full_name) = ''
          then excluded.full_name
          else profiles.full_name
        end,
        phone = excluded.phone,
        email = coalesce(profiles.email, excluded.email);

  if not exists (
    select 1 from public.user_roles
    where user_id = v_user_id and role_id = v_role_id
  ) then
    insert into public.user_roles (user_id, role_id, assigned_by)
    values (v_user_id, v_role_id, v_user_id);
    v_was_new := true;
  end if;

  select id into v_non_member from public.roles where code = 'non_member';
  if v_non_member is not null then
    delete from public.user_roles
    where user_id = v_user_id and role_id = v_non_member;
  end if;

  insert into public.audit_logs (
    actor_user_id, action, entity_type, entity_id, new_data
  )
  values (
    v_user_id,
    'ADMIN_BOOTSTRAP',
    'user_roles',
    v_user_id,
    jsonb_build_object('phone', v_phone, 'role', v_role_code)
  );

  return query select v_user_id, v_role_code, v_was_new;
end;
$$;
