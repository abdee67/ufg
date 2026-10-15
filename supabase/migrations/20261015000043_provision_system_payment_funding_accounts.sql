-- Ensure every supported incoming payment method has an active group funding
-- account before an administrator verifies payments.  The verification RPC
-- posts bank_transfer payments to the `bank` account, wallet payments to the
-- `wallet` account, and cash payments to the `cash` account.
--
-- Accounts are group-owned when both owner columns are NULL.  This migration
-- is intentionally idempotent and does not change member-owned accounts or
-- existing ledger entries.

begin;

insert into public.accounts (
  account_type_id,
  owner_profile_id,
  owner_member_id,
  currency,
  status
)
select
  account_type.id,
  null,
  null,
  'ETB',
  'active'
from public.account_types as account_type
where account_type.code in ('cash', 'bank', 'wallet')
  and not exists (
    select 1
    from public.accounts as account
    where account.account_type_id = account_type.id
      and account.owner_profile_id is null
      and account.owner_member_id is null
      and account.status = 'active'
  );

do $$
begin
  if (
    select count(*)
    from public.account_types
    where code in ('cash', 'bank', 'wallet')
  ) <> 3 then
    raise exception 'Required system account types are not configured';
  end if;
end;
$$;

commit;
