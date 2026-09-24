begin;

-- ============================================================================

-- ============================================================================
-- 4. Exclude members with active loans from guarantor search
--
-- A member who already has an outstanding loan (active, overdue, defaulted)
-- should not be eligible to guarantee another member's loan. This updates
-- search_outsider_loan_guarantors (used by both member and outsider loan forms)
-- to filter them out.
-- ============================================================================

create or replace function public.search_outsider_loan_guarantors(
  p_search text default null
)
returns table (
  member_id uuid,
  member_number text,
  display_name text
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    m.id,
    m.member_number,
    coalesce(nullif(trim(p.full_name), ''), m.member_number)::text
  from public.members m
  join public.profiles p
    on p.id = m.profile_id
  where m.status = 'active'
    and (
      p_search is null
      or trim(p_search) = ''
      or m.member_number ilike '%' || trim(p_search) || '%'
      or p.full_name ilike '%' || trim(p_search) || '%'
    )
    -- Exclude members who have an outstanding active loan
    and not exists (
      select 1
      from public.loans l
      where l.member_id = m.id
        and l.status in ('active', 'overdue', 'defaulted')
    )
  order by p.full_name, m.member_number
  limit 20;
$$;

revoke all on function public.search_outsider_loan_guarantors(text)
  from public, authenticated, anon;
grant execute on function public.search_outsider_loan_guarantors(text)
  to anon, authenticated;

commit;
