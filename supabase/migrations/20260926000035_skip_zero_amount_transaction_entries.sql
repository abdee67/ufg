begin;

/* A balanced transaction may legitimately have no penalty leg.  Zero-value
   legs must not be persisted because transaction_entries enforces amount > 0. */
create or replace function private.post_balanced_transaction_v3(
  p_transaction_type public.transaction_type,
  p_profile_id uuid,
  p_member_id uuid,
  p_amount numeric,
  p_source_type text,
  p_source_id uuid,
  p_description text,
  p_entries jsonb,
  p_actor uuid
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_transaction_id uuid;
  v_debits numeric(18,2);
  v_credits numeric(18,2);
  v_entry_count integer;
begin
  if p_amount is null or p_amount <= 0 then raise exception 'Transaction amount must be greater than zero'; end if;
  if p_entries is null or jsonb_typeof(p_entries) <> 'array' then raise exception 'Transaction entries must be a JSON array'; end if;

  select
    count(*),
    coalesce(sum(case when x.entry_type = 'debit' then x.amount else 0 end), 0)::numeric(18,2),
    coalesce(sum(case when x.entry_type = 'credit' then x.amount else 0 end), 0)::numeric(18,2)
  into v_entry_count, v_debits, v_credits
  from jsonb_to_recordset(p_entries) as x(account_id uuid, entry_type public.transaction_entry_type, amount numeric)
  where round(coalesce(x.amount, 0), 2) > 0;

  if v_entry_count < 2 then raise exception 'A financial transaction requires at least two non-zero entries'; end if;
  if v_debits <= 0 or v_credits <= 0 then raise exception 'Financial transaction must contain debit and credit entries'; end if;
  if v_debits <> v_credits then raise exception 'Unbalanced transaction: debits %, credits %', v_debits, v_credits; end if;
  if v_debits <> round(p_amount, 2) then raise exception 'Transaction amount % does not equal ledger total %', p_amount, v_debits; end if;

  insert into public.transactions(
    transaction_type, source_type, source_id, profile_id, member_id, amount, currency,
    approval_status, transaction_status, initiated_by, approved_by, approved_at, description
  ) values (
    p_transaction_type, p_source_type, p_source_id, p_profile_id, p_member_id, round(p_amount, 2), 'ETB',
    'approved', 'posted', p_actor, p_actor, case when p_actor is null then null else now() end, p_description
  ) returning id into v_transaction_id;

  insert into public.transaction_entries(transaction_id, account_id, entry_type, amount)
  select v_transaction_id, x.account_id, x.entry_type, round(x.amount, 2)
  from jsonb_to_recordset(p_entries) as x(account_id uuid, entry_type public.transaction_entry_type, amount numeric)
  where round(coalesce(x.amount, 0), 2) > 0;

  return v_transaction_id;
end;
$$;

revoke all on function private.post_balanced_transaction_v3(public.transaction_type,uuid,uuid,numeric,text,uuid,text,jsonb,uuid) from public, anon, authenticated;

commit;
