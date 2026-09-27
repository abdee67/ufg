-- This is the only schema addition needed for the manual temporary-password
-- process. It does not migrate existing identities or create recovery tables.
alter table public.profiles
  add column if not exists must_change_password boolean not null default false;

create or replace function private.current_member_id()
returns uuid
language sql
stable
security definer
set search_path = public, private
as $$
  select id
  from public.members
  where profile_id = auth.uid()
    and status = 'active'
    and not exists (
      select 1
      from public.profiles
      where id = auth.uid()
        and must_change_password = true
    )
  limit 1;
$$;

revoke all on function private.current_member_id() from public;
grant execute on function private.current_member_id() to authenticated;

create or replace function private.clear_password_change_requirement()
returns trigger
language plpgsql
security definer
set search_path = public, private
as $$
begin
  perform set_config('private.password_change_clear', 'true', true);
  update public.profiles
  set must_change_password = false
  where id = new.id
    and must_change_password = true;
  return new;
end;
$$;

drop trigger if exists on_auth_user_password_changed on auth.users;

create trigger on_auth_user_password_changed
after update of encrypted_password on auth.users
for each row
when (old.encrypted_password is distinct from new.encrypted_password)
execute procedure private.clear_password_change_requirement();

create or replace function private.protect_password_change_requirement()
returns trigger
language plpgsql
as $$
begin
  if new.must_change_password is distinct from old.must_change_password
     and auth.role() = 'authenticated'
     and current_setting('private.password_change_clear', true) is distinct from 'true' then
    raise exception 'Password-change status is managed by the authentication workflow';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_protect_password_change_requirement on public.profiles;

create trigger profiles_protect_password_change_requirement
before update of must_change_password on public.profiles
for each row execute procedure private.protect_password_change_requirement();
