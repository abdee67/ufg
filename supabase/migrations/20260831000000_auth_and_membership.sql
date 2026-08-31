-- ===========================================================================
-- Unity Finance Group - Auth & Membership Migration
-- Source of truth: Unity Finance Group Savings & Lending Rules
-- ===========================================================================

begin;

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- 0. Private helper schema
-- ---------------------------------------------------------------------------
create schema if not exists private;

-- ---------------------------------------------------------------------------
-- 1. Enum Types
-- ---------------------------------------------------------------------------
do $$ begin
  create type public.profile_status as enum (
    'active',
    'suspended',
    'inactive'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.membership_application_status as enum (
    'draft',
    'submitted',
    'under_review',
    'approved',
    'rejected',
    'cancelled'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.document_verification_status as enum (
    'uploaded',
    'under_review',
    'verified',
    'rejected',
    'replacement_required'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.member_status as enum (
    'active',
    'suspended',
    'removed',
    'inactive'
  );
exception when duplicate_object then null; end $$;

-- ---------------------------------------------------------------------------
-- 2. Utility Functions
-- ---------------------------------------------------------------------------
create or replace function private.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function private.generate_reference(p_prefix text)
returns text
language plpgsql
as $$
begin
  return upper(p_prefix) || '-' ||
         to_char(clock_timestamp(), 'YYYYMMDDHH24MISSMS') || '-' ||
         upper(substr(encode(gen_random_bytes(4), 'hex'), 1, 8));
end;
$$;

-- ---------------------------------------------------------------------------
-- 3. Profiles & RBAC
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete restrict,
  full_name text not null check (length(trim(full_name)) >= 2),
  phone text,
  email text,
  address text,
  date_of_birth date,
  status public.profile_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_profiles_phone on public.profiles(phone);
create index if not exists idx_profiles_email on public.profiles(email);

create table if not exists public.roles (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  description text,
  created_at timestamptz not null default now()
);

create table if not exists public.permissions (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  description text,
  created_at timestamptz not null default now()
);

create table if not exists public.role_permissions (
  role_id uuid not null references public.roles(id) on delete cascade,
  permission_id uuid not null references public.permissions(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (role_id, permission_id)
);

create table if not exists public.user_roles (
  user_id uuid not null references public.profiles(id) on delete cascade,
  role_id uuid not null references public.roles(id) on delete cascade,
  assigned_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  primary key (user_id, role_id)
);

-- Seed Initial Roles
insert into public.roles (code, name, description)
values
  ('non_member', 'Non Member', 'Default role for newly registered users'),
  ('member', 'Active Member', 'Approved member with full savings and lending capabilities'),
  ('admin', 'Administrator', 'Authorized staff managing membership, loans, and approvals'),
  ('super_admin', 'Super Administrator', 'Full system management and configuration access')
on conflict (code) do update set
  name = excluded.name,
  description = excluded.description;

-- Helper role checking functions
create or replace function private.current_user_has_role(p_role_code text)
returns boolean
language sql
stable
security definer
set search_path = public, private
as $$
  select exists (
    select 1
    from public.user_roles ur
    join public.roles r on r.id = ur.role_id
    where ur.user_id = auth.uid()
      and r.code = p_role_code
  );
$$;

revoke all on function private.current_user_has_role(text) from public;
grant execute on function private.current_user_has_role(text) to authenticated;

create or replace function private.current_user_is_admin()
returns boolean
language sql
stable
security definer
set search_path = public, private
as $$
  select private.current_user_has_role('admin')
      or private.current_user_has_role('super_admin');
$$;

revoke all on function private.current_user_is_admin() from public;
grant execute on function private.current_user_is_admin() to authenticated;

-- Automatic Profile and Non-Member Role Creation on Auth Signup
create or replace function private.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public, private
as $$
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
  on conflict (id) do update set
    email = coalesce(excluded.email, public.profiles.email),
    phone = coalesce(excluded.phone, public.profiles.phone);

  select id into v_non_member_role
  from public.roles
  where code = 'non_member';

  if v_non_member_role is not null then
    insert into public.user_roles (user_id, role_id)
    values (new.id, v_non_member_role)
    on conflict do nothing;
  end if;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure private.handle_new_auth_user();

-- ---------------------------------------------------------------------------
-- 4. Membership Applications & Documents
-- ---------------------------------------------------------------------------
create table if not exists public.membership_applications (
  id uuid primary key default gen_random_uuid(),
  application_number text unique not null default private.generate_reference('MEMAPP'),
  applicant_id uuid not null references public.profiles(id) on delete restrict,
  status public.membership_application_status not null default 'submitted',
  submitted_at timestamptz not null default now(),
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  rejection_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_membership_apps_applicant on public.membership_applications(applicant_id);
create index if not exists idx_membership_apps_status on public.membership_applications(status);

create table if not exists public.membership_documents (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null references public.membership_applications(id) on delete cascade,
  applicant_id uuid not null references public.profiles(id) on delete restrict,
  storage_path text not null,
  file_name text not null,
  mime_type text not null,
  file_size_bytes bigint not null,
  verification_status public.document_verification_status not null default 'uploaded',
  verified_by uuid references public.profiles(id) on delete set null,
  verified_at timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_membership_docs_app on public.membership_documents(application_id);
create index if not exists idx_membership_docs_applicant on public.membership_documents(applicant_id);

-- ---------------------------------------------------------------------------
-- 5. Members & Membership History
-- ---------------------------------------------------------------------------
create table if not exists public.members (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid unique not null references public.profiles(id) on delete restrict,
  member_number text unique not null default private.generate_reference('MEM'),
  membership_date date not null default current_date,
  status public.member_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_members_profile on public.members(profile_id);
create index if not exists idx_members_status on public.members(status);

create table if not exists public.membership_status_history (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id) on delete restrict,
  old_status public.member_status,
  new_status public.member_status not null,
  reason text,
  changed_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 6. Audit Logs
-- ---------------------------------------------------------------------------
create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references public.profiles(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  old_data jsonb,
  new_data jsonb,
  metadata jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_audit_logs_actor on public.audit_logs(actor_user_id);
create index if not exists idx_audit_logs_action on public.audit_logs(action);
create index if not exists idx_audit_logs_created_at on public.audit_logs(created_at desc);

-- ---------------------------------------------------------------------------
-- 7. Atomic Database RPC Functions
-- ---------------------------------------------------------------------------

-- 7.1 Submit Membership Application (Applicant RPC)
create or replace function public.submit_membership_application(
  p_address text,
  p_date_of_birth date,
  p_phone text,
  p_storage_path text,
  p_file_name text,
  p_mime_type text,
  p_file_size_bytes bigint
)
returns jsonb
language plpgsql
security definer
set search_path = public, private
as $$
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

  -- 1. Validate caller state
  if exists (
    select 1 from public.members
    where profile_id = v_user_id and status = 'active'
  ) then
    raise exception 'You are already an active member.';
  end if;

  if exists (
    select 1 from public.membership_applications
    where applicant_id = v_user_id
      and status in ('submitted', 'under_review')
  ) then
    raise exception 'You already have an active membership application pending review.';
  end if;

  -- 2. Validate Fayda document parameters
  if coalesce(trim(p_storage_path), '') = '' then
    raise exception 'Fayda identity document is required.';
  end if;

  -- 3. Update profile KYC details
  update public.profiles
  set
    address = trim(p_address),
    date_of_birth = p_date_of_birth,
    phone = coalesce(nullif(trim(p_phone), ''), phone),
    updated_at = now()
  where id = v_user_id;

  -- 4. Create membership application
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
    'submitted',
    now()
  )
  returning id into v_app_id;

  -- 5. Insert document record
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

  -- 6. Audit log
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
$$;

grant execute on function public.submit_membership_application(text, date, text, text, text, text, bigint) to authenticated;

-- 7.2 Approve Membership Application (Admin RPC)
create or replace function public.approve_membership_application(
  p_application_id uuid,
  p_reviewer_id uuid default auth.uid()
)
returns jsonb
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_app record;
  v_member_id uuid;
  v_member_number text;
  v_member_role_id uuid;
  v_non_member_role_id uuid;
  v_result jsonb;
begin
  -- 1. Check admin permission
  if not private.current_user_is_admin() then
    raise exception 'Unauthorized: Administrator privileges required.';
  end if;

  -- 2. Fetch and lock application
  select * into v_app
  from public.membership_applications
  where id = p_application_id
  for update;

  if v_app is null then
    raise exception 'Membership application % not found.', p_application_id;
  end if;

  if v_app.status not in ('submitted', 'under_review') then
    raise exception 'Application is in % state and cannot be approved.', v_app.status;
  end if;

  -- 3. Ensure applicant is not already a member
  if exists (
    select 1 from public.members where profile_id = v_app.applicant_id and status = 'active'
  ) then
    raise exception 'Applicant is already an active member.';
  end if;

  -- 4. Mark application approved
  update public.membership_applications
  set
    status = 'approved',
    reviewed_by = p_reviewer_id,
    reviewed_at = now(),
    updated_at = now()
  where id = p_application_id;

  -- 5. Mark Fayda document verified
  update public.membership_documents
  set
    verification_status = 'verified',
    verified_by = p_reviewer_id,
    verified_at = now(),
    updated_at = now()
  where application_id = p_application_id;

  -- 6. Insert Member record
  v_member_number := private.generate_reference('MEM');

  insert into public.members (
    profile_id,
    member_number,
    membership_date,
    status
  )
  values (
    v_app.applicant_id,
    v_member_number,
    current_date,
    'active'
  )
  returning id into v_member_id;

  -- 7. Add membership status history
  insert into public.membership_status_history (
    member_id,
    old_status,
    new_status,
    reason,
    changed_by
  )
  values (
    v_member_id,
    null,
    'active',
    'Membership application approved',
    p_reviewer_id
  );

  -- 8. Assign MEMBER role, remove NON_MEMBER role
  select id into v_member_role_id from public.roles where code = 'member';
  select id into v_non_member_role_id from public.roles where code = 'non_member';

  if v_member_role_id is not null then
    insert into public.user_roles (user_id, role_id, assigned_by)
    values (v_app.applicant_id, v_member_role_id, p_reviewer_id)
    on conflict do nothing;
  end if;

  if v_non_member_role_id is not null then
    delete from public.user_roles
    where user_id = v_app.applicant_id and role_id = v_non_member_role_id;
  end if;

  -- 9. Audit log
  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    new_data
  )
  values (
    p_reviewer_id,
    'MEMBERSHIP_APPLICATION_APPROVED',
    'members',
    v_member_id,
    jsonb_build_object(
      'application_id', p_application_id,
      'member_number', v_member_number,
      'profile_id', v_app.applicant_id
    )
  );

  select jsonb_build_object(
    'member_id', id,
    'member_number', member_number,
    'profile_id', profile_id,
    'membership_date', membership_date,
    'status', status
  )
  into v_result
  from public.members
  where id = v_member_id;

  return v_result;
end;
$$;

grant execute on function public.approve_membership_application(uuid, uuid) to authenticated;

-- 7.3 Reject Membership Application (Admin RPC)
create or replace function public.reject_membership_application(
  p_application_id uuid,
  p_reason text,
  p_reviewer_id uuid default auth.uid()
)
returns jsonb
language plpgsql
security definer
set search_path = public, private
as $$
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

  if v_app.status not in ('submitted', 'under_review') then
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
$$;

grant execute on function public.reject_membership_application(uuid, text, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 8. Row Level Security (RLS) Policies
-- ---------------------------------------------------------------------------

-- Enable RLS
alter table public.profiles enable row level security;
alter table public.roles enable row level security;
alter table public.permissions enable row level security;
alter table public.role_permissions enable row level security;
alter table public.user_roles enable row level security;
alter table public.membership_applications enable row level security;
alter table public.membership_documents enable row level security;
alter table public.members enable row level security;
alter table public.membership_status_history enable row level security;
alter table public.audit_logs enable row level security;

-- 8.1 profiles
create policy "profiles_read_own_or_admin"
on public.profiles for select
to authenticated
using (id = auth.uid() or private.current_user_is_admin());

create policy "profiles_update_own"
on public.profiles for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

-- 8.2 roles & user_roles
create policy "roles_read_authenticated"
on public.roles for select
to authenticated
using (true);

create policy "user_roles_read_own_or_admin"
on public.user_roles for select
to authenticated
using (user_id = auth.uid() or private.current_user_is_admin());

-- 8.3 membership_applications
create policy "membership_apps_read_own_or_admin"
on public.membership_applications for select
to authenticated
using (applicant_id = auth.uid() or private.current_user_is_admin());

create policy "membership_apps_insert_own"
on public.membership_applications for insert
to authenticated
with check (applicant_id = auth.uid());

create policy "membership_apps_cancel_own"
on public.membership_applications for update
to authenticated
using (applicant_id = auth.uid() and status in ('draft', 'submitted'))
with check (applicant_id = auth.uid() and status = 'cancelled');

-- 8.4 membership_documents
create policy "membership_docs_read_own_or_admin"
on public.membership_documents for select
to authenticated
using (applicant_id = auth.uid() or private.current_user_is_admin());

create policy "membership_docs_insert_own"
on public.membership_documents for insert
to authenticated
with check (applicant_id = auth.uid());

-- 8.5 members
create policy "members_read_own_or_admin"
on public.members for select
to authenticated
using (profile_id = auth.uid() or private.current_user_is_admin());

-- 8.6 membership_status_history
create policy "membership_history_read_own_or_admin"
on public.membership_status_history for select
to authenticated
using (
  exists (
    select 1 from public.members m
    where m.id = membership_status_history.member_id
      and (m.profile_id = auth.uid() or private.current_user_is_admin())
  )
);

-- 8.7 audit_logs (Admin read only)
create policy "audit_logs_read_admin"
on public.audit_logs for select
to authenticated
using (private.current_user_is_admin());

-- ---------------------------------------------------------------------------
-- 9. Storage Bucket & Policies for Fayda Documents
-- ---------------------------------------------------------------------------

-- Create bucket if not exists
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'membership-documents',
  'membership-documents',
  false,
  10485760, -- 10MB limit
  array['image/jpeg', 'image/png', 'image/jpg', 'image/webp', 'application/pdf']
)
on conflict (id) do update set
  public = false,
  file_size_limit = 10485760,
  allowed_mime_types = array['image/jpeg', 'image/png', 'image/jpg', 'image/webp', 'application/pdf'];

-- Storage RLS: Applicant upload policy
create policy "membership_documents_upload_own"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'membership-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- Storage RLS: Applicant read own, Admin read all
create policy "membership_documents_select_own_or_admin"
on storage.objects for select
to authenticated
using (
  bucket_id = 'membership-documents'
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or private.current_user_is_admin()
  )
);

commit;
