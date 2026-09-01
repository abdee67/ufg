-- ===========================================================================
-- 20260901000005_grant_private_schema.sql
-- ---------------------------------------------------------------------------
-- The `private` schema is created by the seed migration but USAGE on it is
-- not granted to `authenticated`. As a result, when
-- public.current_user_is_admin() (SECURITY INVOKER) calls
-- private.current_user_is_admin() in its body, the `authenticated` role
-- hits: "permission denied for schema private" (SQLSTATE 42501).
--
-- This migration grants USAGE on the private schema to the `authenticated`
-- role. Functions inside the schema still have their own explicit
-- `grant execute` statements, and SECURITY DEFINER functions continue to
-- run as the function owner — so this does not expose any data; it only
-- fixes the routing permission so the body of the SECURITY INVOKER
-- wrapper can resolve the call.
-- ===========================================================================

grant usage on schema private to authenticated;
