-- ===========================================================================
-- Unity Finance Group - Auth & Membership Incremental Migration
-- Safe to apply on top of Unity_Finance_MVP_Supabase_Schema.sql
-- ===========================================================================

begin;

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- 0. Ensure private helper schema exists
-- ---------------------------------------------------------------------------
create schema if not exists private;

-- ---------------------------------------------------------------------------
-- 1. Update Enums (Idempotent)
-- ---------------------------------------------------------------------------
do $$ begin
  alter type public.membership_application_status add value if not exists 'draft';
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

-- ---------------------------------------------------------------------------
-- 2. Update Profiles Table (Remove plain-text national_id)
-- ---------------------------------------------------------------------------
drop index if exists public.profiles_national_id_unique_ci;
alter table public.profiles drop column if exists national_id;

-- ---------------------------------------------------------------------------
-- 3. Create Membership Documents Table
-- ---------------------------------------------------------------------------
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

alter table public.membership_documents enable row level security;

-- ---------------------------------------------------------------------------
-- 4. Storage Bucket Configuration & Storage Policies
-- ---------------------------------------------------------------------------
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

-- Storage Policies
drop policy if exists "membership_documents_upload_own" on storage.objects;
create policy "membership_documents_upload_own"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'membership-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "membership_documents_select_own_or_admin" on storage.objects;
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

-- Membership Documents RLS Policies
drop policy if exists "membership_docs_read_own_or_admin" on public.membership_documents;
create policy "membership_docs_read_own_or_admin"
on public.membership_documents for select
to authenticated
using (applicant_id = auth.uid() or private.current_user_is_admin());

drop policy if exists "membership_docs_insert_own" on public.membership_documents;
create policy "membership_docs_insert_own"
on public.membership_documents for insert
to authenticated
with check (applicant_id = auth.uid());

-- ---------------------------------------------------------------------------
-- 5. Atomic RPC Functions
-- ---------------------------------------------------------------------------

-- 5.1 Submit Membership Application (Applicant RPC)
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

  -- Validate caller is not already a member
  if exists (
    select 1 from public.members
    where profile_id = v_user_id and status = 'active'
  ) then
    raise exception 'You are already an active member.';
  end if;

  -- Validate no pending or under-review applications exist
  if exists (
    select 1 from public.membership_applications
    where applicant_id = v_user_id
      and status in ('pending', 'under_review')
  ) then
    raise exception 'You already have an active membership application pending review.';
  end if;

  -- Validate document path
  if coalesce(trim(p_storage_path), '') = '' then
    raise exception 'Fayda identity document is required.';
  end if;

  -- Update profile KYC details
  update public.profiles
  set
    address = trim(p_address),
    date_of_birth = p_date_of_birth,
    phone = coalesce(nullif(trim(p_phone), ''), phone),
    updated_at = now()
  where id = v_user_id;

  -- Create membership application
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
    'pending',
    now()
  )
  returning id into v_app_id;

  -- Insert document record
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

  -- Log audit event
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

-- 5.2 Approve Membership Application (Admin RPC)
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
  -- Check admin permission
  if not private.current_user_is_admin() then
    raise exception 'Unauthorized: Administrator privileges required.';
  end if;

  -- Lock application
  select * into v_app
  from public.membership_applications
  where id = p_application_id
  for update;

  if v_app is null then
    raise exception 'Membership application % not found.', p_application_id;
  end if;

  if v_app.status not in ('pending', 'under_review') then
    raise exception 'Application is in % state and cannot be approved.', v_app.status;
  end if;

  if exists (
    select 1 from public.members where profile_id = v_app.applicant_id and status = 'active'
  ) then
    raise exception 'Applicant is already an active member.';
  end if;

  -- Mark application approved
  update public.membership_applications
  set
    status = 'approved',
    reviewed_by = p_reviewer_id,
    reviewed_at = now(),
    updated_at = now()
  where id = p_application_id;

  -- Mark Fayda document verified
  update public.membership_documents
  set
    verification_status = 'verified',
    verified_by = p_reviewer_id,
    verified_at = now(),
    updated_at = now()
  where application_id = p_application_id;

  -- Insert Member record
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

  -- Add membership status history
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

  -- Assign MEMBER role, remove NON_MEMBER role
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

  -- Audit log
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

-- 5.3 Reject Membership Application (Admin RPC)
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

  if v_app.status not in ('pending', 'under_review') then
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

commit;
