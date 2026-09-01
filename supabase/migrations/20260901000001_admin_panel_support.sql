-- ===========================================================================
-- 20260901000000_admin_panel_support.sql
-- Admin panel support: app-callable admin check + audit/search indexes.
-- ===========================================================================

-- 1. App-callable admin check (security invoker wrapper around the
--    private.current_user_is_admin() helper). The admin panel calls this
--    from Server Components / Server Actions to defense-in-depth before
--    calling the SECURITY DEFINER RPCs.
create or replace function public.current_user_is_admin()
returns boolean
language sql
stable
security invoker
set search_path = public, private
as $$
  select private.current_user_is_admin()
$$;

grant execute on function public.current_user_is_admin() to authenticated;

-- 2. Audit log indexes for the admin audit page.
create index if not exists audit_logs_entity_idx
  on public.audit_logs (entity_type, entity_id, created_at desc);

create index if not exists audit_logs_action_idx
  on public.audit_logs (action, created_at desc);

-- 3. Application search index (trigram) for the inbox search box.
--    If pg_trgm is not available in the Supabase project, this statement
--    will fail at migration time; the admin panel falls back to ILIKE.
create extension if not exists pg_trgm;

create index if not exists membership_apps_number_trgm_idx
  on public.membership_applications
  using gin (application_number gin_trgm_ops);
