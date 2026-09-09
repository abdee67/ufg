
-- Unity Finance Group - MVP Supabase schema
-- Source of truth: Unity Finance Group Savings & Lending Rules
-- Intended for a NEW / EMPTY Supabase project or dedicated development database.
--
-- This migration creates:
--   - profiles / roles / permissions / user_roles
--   - membership
--   - accounts / ledger / transactions
--   - payments
--   - savings
--   - loans / guarantors / approvals / installments
--   - expenses
--   - audit logs
--   - financial rule versioning
--   - liquidity/reporting views
--   - core RLS policies
--
-- Important:
--   1. Do NOT run this against an existing production schema without a backup
--      and a migration plan.
--   2. Financial rules are stored in the database, not hard-coded in Flutter.
--   3. Financial records are append-only from the application's point of view.
--      Corrections happen through reversal/correction transactions.

begin;

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- 0. Private helper schema
-- ---------------------------------------------------------------------------

create schema if not exists private;

-- ---------------------------------------------------------------------------
-- 1. Enum types
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
    'pending',
    'under_review',
    'approved',
    'rejected',
    'cancelled'
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

do $$ begin
  create type public.payment_status as enum (
    'pending',
    'verified',
    'rejected',
    'cancelled'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.approval_status as enum (
    'pending',
    'approved',
    'rejected'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.transaction_status as enum (
    'pending',
    'posted',
    'reversed'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.transaction_entry_type as enum (
    'debit',
    'credit'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.transaction_type as enum (
    'membership_fee',
    'first_contribution',
    'savings_contribution',
    'savings_late_penalty',
    'savings_withdrawal',
    'loan_service_charge',
    'outsider_service_charge',
    'loan_disbursement',
    'loan_repayment',
    'loan_late_penalty',
    'expense',
    'other_income',
    'reversal',
    'correction'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.savings_obligation_status as enum (
    'pending',
    'partially_paid',
    'paid',
    'late',
    'waived'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.withdrawal_status as enum (
    'pending',
    'approved',
    'rejected',
    'paid',
    'cancelled'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.loan_borrower_type as enum (
    'member',
    'outsider'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.loan_application_status as enum (
    'draft',
    'submitted',
    'eligible',
    'ineligible',
    'under_review',
    'approved',
    'rejected',
    'cancelled'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.loan_status as enum (
    'active',
    'paid',
    'overdue',
    'defaulted',
    'cancelled'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.guarantor_status as enum (
    'requested',
    'accepted',
    'rejected',
    'released'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.loan_approval_decision as enum (
    'approved',
    'rejected'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.installment_status as enum (
    'pending',
    'partially_paid',
    'paid',
    'overdue',
    'defaulted'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.expense_status as enum (
    'pending',
    'approved',
    'rejected',
    'paid'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.account_type_code as enum (
    'member_savings',
    'group_income',
    'group_expense',
    'cash',
    'bank',
    'wallet',
    'loan_receivable',
    'loan_service_charge_income',
    'penalty_income'
  );
exception when duplicate_object then null; end $$;

-- ---------------------------------------------------------------------------
-- 2. Utility functions
-- ---------------------------------------------------------------------------

create sequence if not exists private.reference_seq;

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
  return upper(p_prefix) || '-' || lpad(nextval('private.reference_seq')::text, 6, '0');
end;
$$;

-- ---------------------------------------------------------------------------
-- 3. Profiles / RBAC
-- ---------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users(id) on delete restrict,
  full_name text not null check (length(trim(full_name)) >= 2),
  phone text,
  email text,
  national_id text,
  address text,
  date_of_birth date,
  status public.profile_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index profiles_phone_unique_ci
on public.profiles (lower(phone))
where phone is not null;

create unique index profiles_national_id_unique_ci
on public.profiles (lower(national_id))
where national_id is not null;

create table public.roles (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  description text,
  created_at timestamptz not null default now()
);

create table public.permissions (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  description text,
  created_at timestamptz not null default now()
);

create table public.role_permissions (
  role_id uuid not null references public.roles(id) on delete cascade,
  permission_id uuid not null references public.permissions(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (role_id, permission_id)
);

create table public.user_roles (
  user_id uuid not null references public.profiles(id) on delete cascade,
  role_id uuid not null references public.roles(id) on delete cascade,
  assigned_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  primary key (user_id, role_id)
);

-- Default a newly-created application profile to non_member.
-- ---------------------------------------------------------------------------
-- 4. Membership
-- ---------------------------------------------------------------------------

create table public.membership_applications (
  id uuid primary key default gen_random_uuid(),
  application_number text unique not null default private.generate_reference('MEMAPP'),
  applicant_id uuid not null references public.profiles(id) on delete restrict,
  status public.membership_application_status not null default 'pending',
  submitted_at timestamptz not null default now(),
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  rejection_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.members (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid unique not null references public.profiles(id) on delete restrict,
  member_number text unique not null default private.generate_reference('MEM'),
  membership_date date not null default current_date,
  status public.member_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

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
  limit 1;
$$;

revoke all on function private.current_member_id() from public;
grant execute on function private.current_member_id() to authenticated;

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
  on conflict (id) do nothing;

  select id
  into v_non_member_role
  from public.roles
  where code = 'non_member';

  if v_non_member_role is not null then
    insert into public.user_roles(user_id, role_id)
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

create table public.membership_status_history (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id) on delete restrict,
  old_status public.member_status,
  new_status public.member_status not null,
  reason text,
  changed_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 5. Financial accounts
-- ---------------------------------------------------------------------------

create table public.account_types (
  id uuid primary key default gen_random_uuid(),
  code public.account_type_code unique not null,
  name text not null,
  description text,
  created_at timestamptz not null default now()
);

create table public.accounts (
  id uuid primary key default gen_random_uuid(),
  account_type_id uuid not null references public.account_types(id) on delete restrict,
  owner_profile_id uuid references public.profiles(id) on delete restrict,
  owner_member_id uuid references public.members(id) on delete restrict,
  currency text not null default 'ETB' check (currency = 'ETB'),
  status text not null default 'active' check (status in ('active', 'inactive', 'locked')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index accounts_one_type_per_member
on public.accounts (owner_member_id, account_type_id)
where owner_member_id is not null;

create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  reference_number text unique not null default private.generate_reference('TXN'),
  transaction_type public.transaction_type not null,
  source_type text,
  source_id uuid,
  profile_id uuid references public.profiles(id) on delete restrict,
  member_id uuid references public.members(id) on delete restrict,
  amount numeric(18,2) not null check (amount > 0),
  currency text not null default 'ETB' check (currency = 'ETB'),
  approval_status public.approval_status not null default 'pending',
  transaction_status public.transaction_status not null default 'pending',
  initiated_by uuid references public.profiles(id) on delete set null,
  approved_by uuid references public.profiles(id) on delete set null,
  approved_at timestamptz,
  description text,
  reversal_of_transaction_id uuid references public.transactions(id) on delete restrict,
  created_at timestamptz not null default now()
);

create table public.transaction_entries (
  id uuid primary key default gen_random_uuid(),
  transaction_id uuid not null references public.transactions(id) on delete restrict,
  account_id uuid not null references public.accounts(id) on delete restrict,
  entry_type public.transaction_entry_type not null,
  amount numeric(18,2) not null check (amount > 0),
  created_at timestamptz not null default now()
);

create index transactions_member_idx on public.transactions(member_id, created_at desc);
create index transaction_entries_transaction_idx on public.transaction_entries(transaction_id);

-- ---------------------------------------------------------------------------
-- 6. Payments
-- ---------------------------------------------------------------------------

create table public.payment_methods (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  payer_profile_id uuid not null references public.profiles(id) on delete restrict,
  payment_method_id uuid not null references public.payment_methods(id) on delete restrict,
  reference_number text unique not null default private.generate_reference('PAY'),
  purpose_type text not null,
  purpose_id uuid,
  amount numeric(18,2) not null check (amount > 0),
  currency text not null default 'ETB' check (currency = 'ETB'),
  status public.payment_status not null default 'pending',
  payment_proof_path text,
  external_reference text,
  submitted_at timestamptz not null default now(),
  verified_by uuid references public.profiles(id) on delete set null,
  verified_at timestamptz,
  rejection_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.payment_verifications (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references public.payments(id) on delete restrict,
  verification_type text not null default 'manual',
  status public.payment_status not null,
  verified_by uuid references public.profiles(id) on delete set null,
  external_reference text,
  evidence jsonb,
  verified_at timestamptz,
  created_at timestamptz not null default now()
);

create index payments_payer_idx on public.payments(payer_profile_id, created_at desc);

-- ---------------------------------------------------------------------------
-- 7. Savings
-- ---------------------------------------------------------------------------

create table public.savings_accounts (
  id uuid primary key default gen_random_uuid(),
  member_id uuid unique not null references public.members(id) on delete restrict,
  account_id uuid unique not null references public.accounts(id) on delete restrict,
  status text not null default 'active' check (status in ('active', 'locked', 'closed')),
  created_at timestamptz not null default now()
);

create table public.savings_obligations (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id) on delete restrict,
  period_year int not null check (period_year between 2020 and 2100),
  period_month int not null check (period_month between 1 and 12),
  required_amount numeric(18,2) not null check (required_amount > 0),
  due_date date not null,
  paid_amount numeric(18,2) not null default 0 check (paid_amount >= 0),
  late_penalty_amount numeric(18,2) not null default 0 check (late_penalty_amount >= 0),
  status public.savings_obligation_status not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(member_id, period_year, period_month)
);

create table public.savings_contributions (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id) on delete restrict,
  savings_account_id uuid not null references public.savings_accounts(id) on delete restrict,
  obligation_id uuid references public.savings_obligations(id) on delete restrict,
  amount numeric(18,2) not null check (amount > 0),
  payment_id uuid references public.payments(id) on delete restrict,
  transaction_id uuid references public.transactions(id) on delete restrict,
  contribution_type text not null default 'mandatory'
    check (contribution_type in ('mandatory', 'voluntary', 'adjustment')),
  created_at timestamptz not null default now()
);

create table public.savings_penalties (
  id uuid primary key default gen_random_uuid(),
  obligation_id uuid unique not null references public.savings_obligations(id) on delete restrict,
  rate numeric(8,4) not null check (rate >= 0),
  amount numeric(18,2) not null check (amount > 0),
  transaction_id uuid references public.transactions(id) on delete restrict,
  charged_at timestamptz not null default now()
);

create table public.withdrawal_requests (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id) on delete restrict,
  amount numeric(18,2) not null check (amount > 0),
  status public.withdrawal_status not null default 'pending',
  requested_at timestamptz not null default now(),
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  paid_at timestamptz,
  reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 8. Loan products
-- ---------------------------------------------------------------------------

create table public.loan_products (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  borrower_type public.loan_borrower_type not null,
  service_charge_rate numeric(8,4) not null check (service_charge_rate >= 0),
  max_amount numeric(18,2) not null check (max_amount > 0),
  term_months int not null check (term_months > 0),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.loan_applications (
  id uuid primary key default gen_random_uuid(),
  application_number text unique not null default private.generate_reference('LOANAPP'),
  applicant_profile_id uuid not null references public.profiles(id) on delete restrict,
  member_id uuid references public.members(id) on delete restrict,
  loan_product_id uuid not null references public.loan_products(id) on delete restrict,
  requested_amount numeric(18,2) not null check (requested_amount > 0),
  purpose text,
  eligibility_status public.loan_application_status,
  status public.loan_application_status not null default 'draft',
  submitted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (requested_amount > 0)
);


create or replace function private.validate_loan_application_borrower_type()
returns trigger
language plpgsql
as $$
declare
  v_borrower_type public.loan_borrower_type;
begin
  select borrower_type
  into v_borrower_type
  from public.loan_products
  where id = new.loan_product_id;

  if v_borrower_type is null then
    raise exception 'invalid loan product';
  end if;

  if v_borrower_type = 'member' and new.member_id is null then
    raise exception 'member loans require member_id';
  end if;

  if v_borrower_type = 'outsider' and new.member_id is not null then
    raise exception 'outsider loans cannot have member_id';
  end if;

  return new;
end;
$$;

drop trigger if exists loan_applications_validate_borrower_type on public.loan_applications;

create trigger loan_applications_validate_borrower_type
before insert or update on public.loan_applications
for each row execute procedure private.validate_loan_application_borrower_type();

create table public.loan_eligibility_checks (
  id uuid primary key default gen_random_uuid(),
  loan_application_id uuid not null references public.loan_applications(id) on delete restrict,
  check_code text not null,
  result boolean not null,
  value text,
  reason text,
  checked_at timestamptz not null default now()
);

create table public.loans (
  id uuid primary key default gen_random_uuid(),
  loan_number text unique not null default private.generate_reference('LOAN'),
  loan_application_id uuid unique not null references public.loan_applications(id) on delete restrict,
  borrower_profile_id uuid not null references public.profiles(id) on delete restrict,
  member_id uuid references public.members(id) on delete restrict,
  principal numeric(18,2) not null check (principal > 0),
  service_charge_rate numeric(8,4) not null check (service_charge_rate >= 0),
  service_charge_amount numeric(18,2) not null check (service_charge_amount >= 0),
  total_repayment numeric(18,2) not null check (total_repayment > 0),
  term_months int not null check (term_months > 0),
  status public.loan_status not null default 'active',
  disbursed_at timestamptz,
  maturity_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index loans_borrower_idx on public.loans(borrower_profile_id, created_at desc);
create index loans_member_idx on public.loans(member_id, created_at desc);

-- ---------------------------------------------------------------------------
-- 9. Guarantors / approvals
-- ---------------------------------------------------------------------------

create table public.loan_guarantors (
  id uuid primary key default gen_random_uuid(),
  loan_application_id uuid unique not null references public.loan_applications(id) on delete restrict,
  guarantor_member_id uuid not null references public.members(id) on delete restrict,
  guaranteed_amount numeric(18,2) not null check (guaranteed_amount > 0),
  potential_responsibility numeric(18,2) not null check (potential_responsibility >= 0),
  status public.guarantor_status not null default 'requested',
  requested_at timestamptz not null default now(),
  approved_at timestamptz,
  rejected_at timestamptz,
  released_at timestamptz,
  created_at timestamptz not null default now(),
  check (
    potential_responsibility >= guaranteed_amount
  )
);

create table public.loan_approvals (
  id uuid primary key default gen_random_uuid(),
  loan_application_id uuid not null references public.loan_applications(id) on delete restrict,
  approver_profile_id uuid not null references public.profiles(id) on delete restrict,
  decision public.loan_approval_decision not null,
  comment text,
  decided_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique(loan_application_id, approver_profile_id)
);

-- ---------------------------------------------------------------------------
-- 10. Loan installments / penalties / defaults
-- ---------------------------------------------------------------------------

create table public.loan_installments (
  id uuid primary key default gen_random_uuid(),
  loan_id uuid not null references public.loans(id) on delete restrict,
  installment_number int not null check (installment_number > 0),
  due_date date not null,
  principal_amount numeric(18,2) not null check (principal_amount >= 0),
  service_charge_amount numeric(18,2) not null check (service_charge_amount >= 0),
  total_due numeric(18,2) not null check (total_due > 0),
  paid_amount numeric(18,2) not null default 0 check (paid_amount >= 0),
  late_penalty_amount numeric(18,2) not null default 0 check (late_penalty_amount >= 0),
  status public.installment_status not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(loan_id, installment_number)
);

create table public.loan_penalties (
  id uuid primary key default gen_random_uuid(),
  installment_id uuid unique not null references public.loan_installments(id) on delete restrict,
  rate numeric(8,4) not null check (rate >= 0),
  amount numeric(18,2) not null check (amount > 0),
  transaction_id uuid references public.transactions(id) on delete restrict,
  charged_at timestamptz not null default now()
);

create table public.loan_default_events (
  id uuid primary key default gen_random_uuid(),
  loan_id uuid not null references public.loans(id) on delete restrict,
  installment_id uuid references public.loan_installments(id) on delete restrict,
  event_type text not null,
  event_date timestamptz not null default now(),
  notes text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.loan_disbursements (
  id uuid primary key default gen_random_uuid(),
  loan_id uuid unique not null references public.loans(id) on delete restrict,
  amount numeric(18,2) not null check (amount > 0),
  payment_method_code text not null,
  transaction_id uuid references public.transactions(id) on delete restrict,
  released_by uuid references public.profiles(id) on delete restrict,
  released_at timestamptz not null default now(),
  notes text
);

-- ---------------------------------------------------------------------------
-- 11. Expenses
-- ---------------------------------------------------------------------------

create table public.expenses (
  id uuid primary key default gen_random_uuid(),
  reference_number text unique not null default private.generate_reference('EXP'),
  category text not null,
  amount numeric(18,2) not null check (amount > 0),
  description text,
  supporting_document_path text,
  status public.expense_status not null default 'pending',
  requested_by uuid references public.profiles(id) on delete restrict,
  approved_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  approved_at timestamptz,
  paid_at timestamptz
);

-- ---------------------------------------------------------------------------
-- 12. Audit logs
-- ---------------------------------------------------------------------------

create table public.audit_logs (
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

-- ---------------------------------------------------------------------------
-- 13. Financial rules
-- ---------------------------------------------------------------------------

create table public.financial_rules (
  id uuid primary key default gen_random_uuid(),
  rule_code text unique not null,
  description text,
  data_type text not null check (data_type in ('numeric', 'integer', 'boolean', 'text')),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.financial_rule_versions (
  id uuid primary key default gen_random_uuid(),
  rule_id uuid not null references public.financial_rules(id) on delete restrict,
  value_numeric numeric(18,6),
  value_text text,
  value_boolean boolean,
  value_integer bigint,
  effective_from timestamptz not null,
  effective_to timestamptz,
  status text not null default 'draft'
    check (status in ('draft', 'proposed', 'approved', 'active', 'expired', 'rejected')),
  approved_by uuid references public.profiles(id) on delete set null,
  approved_at timestamptz,
  change_reason text,
  created_at timestamptz not null default now(),
  check (
    num_nonnulls(value_numeric, value_text, value_boolean, value_integer) = 1
  )
);

create index financial_rule_versions_lookup_idx
on public.financial_rule_versions(rule_id, effective_from desc);

-- ---------------------------------------------------------------------------
-- 14. Rule lookup helper
-- ---------------------------------------------------------------------------

create or replace function public.get_active_rule_numeric(p_rule_code text)
returns numeric
language sql
stable
as $$
  select
    case
      when frv.value_numeric is not null then frv.value_numeric
      when frv.value_integer is not null then frv.value_integer::numeric
      else null
    end
  from public.financial_rules fr
  join public.financial_rule_versions frv
    on frv.rule_id = fr.id
  where fr.rule_code = p_rule_code
    and fr.active = true
    and frv.status = 'active'
    and frv.effective_from <= now()
    and (frv.effective_to is null or frv.effective_to > now())
  order by frv.effective_from desc
  limit 1;
$$;

revoke all on function public.get_active_rule_numeric(text) from public;
grant execute on function public.get_active_rule_numeric(text) to authenticated;

-- ---------------------------------------------------------------------------
-- 15. Trigger: updated_at
-- ---------------------------------------------------------------------------

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute procedure private.set_updated_at();

drop trigger if exists membership_applications_set_updated_at on public.membership_applications;
create trigger membership_applications_set_updated_at
before update on public.membership_applications
for each row execute procedure private.set_updated_at();

drop trigger if exists members_set_updated_at on public.members;
create trigger members_set_updated_at
before update on public.members
for each row execute procedure private.set_updated_at();

drop trigger if exists accounts_set_updated_at on public.accounts;
create trigger accounts_set_updated_at
before update on public.accounts
for each row execute procedure private.set_updated_at();

drop trigger if exists payments_set_updated_at on public.payments;
create trigger payments_set_updated_at
before update on public.payments
for each row execute procedure private.set_updated_at();

drop trigger if exists savings_obligations_set_updated_at on public.savings_obligations;
create trigger savings_obligations_set_updated_at
before update on public.savings_obligations
for each row execute procedure private.set_updated_at();

drop trigger if exists withdrawal_requests_set_updated_at on public.withdrawal_requests;
create trigger withdrawal_requests_set_updated_at
before update on public.withdrawal_requests
for each row execute procedure private.set_updated_at();

drop trigger if exists loan_products_set_updated_at on public.loan_products;
create trigger loan_products_set_updated_at
before update on public.loan_products
for each row execute procedure private.set_updated_at();

drop trigger if exists loan_applications_set_updated_at on public.loan_applications;
create trigger loan_applications_set_updated_at
before update on public.loan_applications
for each row execute procedure private.set_updated_at();

drop trigger if exists loans_set_updated_at on public.loans;
create trigger loans_set_updated_at
before update on public.loans
for each row execute procedure private.set_updated_at();

drop trigger if exists loan_installments_set_updated_at on public.loan_installments;
create trigger loan_installments_set_updated_at
before update on public.loan_installments
for each row execute procedure private.set_updated_at();

-- ---------------------------------------------------------------------------
-- 16. Seeds: roles
-- ---------------------------------------------------------------------------

insert into public.roles (code, name, description)
values
  ('non_member', 'Non Member', 'Registered user who is not a member'),
  ('member', 'Member', 'Active Unity Finance member'),
  ('admin', 'Admin', 'Administrative operator'),
  ('super_admin', 'Super Admin', 'Full system administrator')
on conflict (code) do nothing;

insert into public.permissions (code, name, description)
values
  ('profile.read_own', 'Read own profile', 'Read own profile'),
  ('profile.update_own', 'Update own profile', 'Update own profile'),

  ('membership.apply', 'Apply for membership', 'Submit membership application'),
  ('membership.read', 'Read membership', 'Read membership records'),
  ('membership.approve', 'Approve membership', 'Approve or reject membership applications'),

  ('savings.read_own', 'Read own savings', 'Read own savings data'),
  ('savings.contribute', 'Contribute savings', 'Submit savings payment'),
  ('savings.withdraw.request', 'Request withdrawal', 'Request savings withdrawal'),
  ('savings.withdraw.approve', 'Approve withdrawal', 'Approve savings withdrawal'),

  ('payment.create', 'Create payment', 'Create payment request'),
  ('payment.verify', 'Verify payment', 'Verify manual payments'),

  ('loan.apply', 'Apply for loan', 'Create loan application'),
  ('loan.read', 'Read loans', 'Read permitted loan data'),
  ('loan.review', 'Review loan', 'Review loan application'),
  ('loan.approve', 'Approve loan', 'Approve loan application'),
  ('loan.disburse', 'Disburse loan', 'Release approved loan'),
  ('loan.repay', 'Repay loan', 'Record loan repayment'),

  ('guarantor.respond', 'Respond as guarantor', 'Accept or reject guarantee request'),

  ('ledger.read', 'Read ledger', 'Read ledger/transaction data'),
  ('ledger.reverse', 'Reverse transaction', 'Create reversal/correction'),
  ('expense.create', 'Create expense', 'Create expense request'),
  ('expense.approve', 'Approve expense', 'Approve expense'),

  ('reports.read', 'Read reports', 'Read management reports'),
  ('audit.read', 'Read audit logs', 'Read audit history'),
  ('rules.read', 'Read financial rules', 'Read active business rules'),
  ('rules.change', 'Change financial rules', 'Approve/activate rule changes'),
  ('rbac.manage', 'Manage RBAC', 'Assign roles and permissions')
on conflict (code) do nothing;

-- Admin gets all current permissions.
insert into public.role_permissions(role_id, permission_id)
select r.id, p.id
from public.roles r
cross join public.permissions p
where r.code in ('admin', 'super_admin')
on conflict do nothing;

-- Members / non-members get their base permissions.
insert into public.role_permissions(role_id, permission_id)
select r.id, p.id
from public.roles r
join public.permissions p on p.code in (
  'profile.read_own',
  'profile.update_own',
  'membership.apply',
  'savings.read_own',
  'savings.contribute',
  'savings.withdraw.request',
  'payment.create',
  'loan.apply',
  'loan.read',
  'loan.repay',
  'guarantor.respond',
  'rules.read'
)
where r.code in ('member', 'non_member')
on conflict do nothing;

-- ---------------------------------------------------------------------------
-- 17. Seeds: account types
-- ---------------------------------------------------------------------------

insert into public.account_types(code, name, description)
values
  ('member_savings', 'Member Savings', 'Member savings funds'),
  ('group_income', 'Group Income', 'Income belonging to the group'),
  ('group_expense', 'Group Expense', 'Operating expenses'),
  ('cash', 'Cash', 'Physical cash'),
  ('bank', 'Bank', 'Group bank account'),
  ('wallet', 'Wallet', 'Group wallet'),
  ('loan_receivable', 'Loan Receivable', 'Outstanding loan principal'),
  ('loan_service_charge_income', 'Loan Service Charge Income', 'Income from loan service charges'),
  ('penalty_income', 'Penalty Income', 'Income from late penalties')
on conflict (code) do nothing;

-- ---------------------------------------------------------------------------
-- 18. Seeds: payment methods
-- ---------------------------------------------------------------------------

insert into public.payment_methods(code, name, active)
values
  ('wallet', 'Wallet', true),
  ('bank_transfer', 'Bank Transfer', true)
on conflict (code) do nothing;

-- ---------------------------------------------------------------------------
-- 19. Seeds: loan products
-- ---------------------------------------------------------------------------

insert into public.loan_products (
  code,
  name,
  borrower_type,
  service_charge_rate,
  max_amount,
  term_months,
  active
)
values
  ('member_loan', 'Member Loan', 'member', 0.10, 20000, 3, true),
  ('outsider_loan', 'Outsider Loan', 'outsider', 0.15, 20000, 3, true)
on conflict (code) do nothing;

-- ---------------------------------------------------------------------------
-- 20. Seeds: business rules
-- ---------------------------------------------------------------------------

insert into public.financial_rules(rule_code, description, data_type)
values
  ('membership_fee', 'Initial membership fee / first required contribution. Confirm exact treatment before production.', 'numeric'),
  ('monthly_min_saving', 'Minimum monthly saving contribution.', 'numeric'),
  ('saving_due_day', 'Day of month by which the minimum saving is due.', 'integer'),
  ('saving_late_penalty_rate', 'Penalty rate for missing the minimum monthly contribution.', 'numeric'),
  ('member_service_charge_rate', 'One-time member loan service charge.', 'numeric'),
  ('outsider_service_charge_rate', 'One-time outsider loan service charge.', 'numeric'),
  ('max_loan_amount', 'Maximum initial loan amount.', 'numeric'),
  ('default_loan_term_months', 'Standard loan term.', 'integer'),
  ('loan_late_penalty_rate', 'Penalty rate for an overdue loan installment.', 'numeric'),
  ('serious_default_days', 'Days after due date before serious default.', 'integer'),
  ('liquidity_reserve_rate', 'Minimum liquidity reserve.', 'numeric')
on conflict (rule_code) do nothing;

-- Current defaults.
-- The playbook does not state the membership fee amount. Earlier project
-- decisions set it to 500 ETB, so the MVP seeds that agreed project value.
-- Change it through the rule-versioning workflow if the business approves a
-- different amount.
with rule_values(rule_code, value_numeric, value_integer) as (
  values
    ('membership_fee', 500::numeric, null::bigint),
    ('monthly_min_saving', 2000::numeric, null::bigint),
    ('saving_due_day', null::numeric, 12::bigint),
    ('saving_late_penalty_rate', 0.10::numeric, null::bigint),
    ('member_service_charge_rate', 0.10::numeric, null::bigint),
    ('outsider_service_charge_rate', 0.15::numeric, null::bigint),
    ('max_loan_amount', 20000::numeric, null::bigint),
    ('default_loan_term_months', null::numeric, 3::bigint),
    ('loan_late_penalty_rate', 0.05::numeric, null::bigint),
    ('serious_default_days', null::numeric, 60::bigint),
    ('liquidity_reserve_rate', 0.30::numeric, null::bigint)
)
insert into public.financial_rule_versions (
  rule_id,
  value_numeric,
  value_integer,
  effective_from,
  status,
  approved_at,
  change_reason
)
select
  fr.id,
  rv.value_numeric,
  rv.value_integer,
  now(),
  'active',
  now(),
  'Initial MVP seed from approved Unity Finance rules'
from rule_values rv
join public.financial_rules fr
  on fr.rule_code = rv.rule_code
where not exists (
  select 1
  from public.financial_rule_versions existing
  where existing.rule_id = fr.id
    and existing.status = 'active'
);

-- ---------------------------------------------------------------------------
-- 21. Useful read views
-- ---------------------------------------------------------------------------

create or replace view public.member_savings_summary
with (security_invoker = true)
as
select
  m.id as member_id,
  m.member_number,
  p.full_name,
  coalesce(sum(
    case
      when te.entry_type = 'credit' then te.amount
      when te.entry_type = 'debit' then -te.amount
    end
  ), 0)::numeric(18,2) as savings_balance
from public.members m
join public.profiles p on p.id = m.profile_id
left join public.savings_accounts sa on sa.member_id = m.id
left join public.transaction_entries te on te.account_id = sa.account_id
left join public.transactions t on t.id = te.transaction_id
  and t.transaction_status = 'posted'
group by m.id, m.member_number, p.full_name;

create or replace view public.loan_portfolio_summary
with (security_invoker = true)
as
select
  l.id,
  l.loan_number,
  l.borrower_profile_id,
  p.full_name as borrower_name,
  l.member_id,
  l.principal,
  l.service_charge_amount,
  l.total_repayment,
  l.status,
  l.disbursed_at,
  l.maturity_date,
  coalesce(sum(li.paid_amount), 0)::numeric(18,2) as total_paid,
  greatest(l.total_repayment - coalesce(sum(li.paid_amount), 0), 0)::numeric(18,2) as outstanding_amount
from public.loans l
join public.profiles p on p.id = l.borrower_profile_id
left join public.loan_installments li on li.loan_id = l.id
group by
  l.id, l.loan_number, l.borrower_profile_id, p.full_name,
  l.member_id, l.principal, l.service_charge_amount,
  l.total_repayment, l.status, l.disbursed_at, l.maturity_date;

create or replace view public.management_dashboard
with (security_invoker = true)
as
select
  (select count(*) from public.members where status = 'active') as active_members,
  (
    select coalesce(sum(savings_balance), 0)
    from public.member_savings_summary
  )::numeric(18,2) as total_member_savings,
  (
    select coalesce(sum(outstanding_amount), 0)
    from public.loan_portfolio_summary
    where status in ('active', 'overdue', 'defaulted')
  )::numeric(18,2) as outstanding_loans,
  (
    select coalesce(sum(amount), 0)
    from public.transactions
    where transaction_type in ('loan_service_charge', 'outsider_service_charge', 'loan_late_penalty', 'savings_late_penalty', 'other_income')
      and transaction_status = 'posted'
  )::numeric(18,2) as income_recorded,
  (
    select count(*)
    from public.loan_installments
    where status in ('overdue', 'defaulted')
  ) as overdue_installments;

-- ---------------------------------------------------------------------------
-- 22. RLS
-- ---------------------------------------------------------------------------

-- Supabase recommends RLS on all exposed public tables.
alter table public.profiles enable row level security;
alter table public.roles enable row level security;
alter table public.permissions enable row level security;
alter table public.role_permissions enable row level security;
alter table public.user_roles enable row level security;
alter table public.membership_applications enable row level security;
alter table public.members enable row level security;
alter table public.membership_status_history enable row level security;
alter table public.account_types enable row level security;
alter table public.accounts enable row level security;
alter table public.transactions enable row level security;
alter table public.transaction_entries enable row level security;
alter table public.payment_methods enable row level security;
alter table public.payments enable row level security;
alter table public.payment_verifications enable row level security;
alter table public.savings_accounts enable row level security;
alter table public.savings_obligations enable row level security;
alter table public.savings_contributions enable row level security;
alter table public.savings_penalties enable row level security;
alter table public.withdrawal_requests enable row level security;
alter table public.loan_products enable row level security;
alter table public.loan_applications enable row level security;
alter table public.loan_eligibility_checks enable row level security;
alter table public.loans enable row level security;
alter table public.loan_guarantors enable row level security;
alter table public.loan_approvals enable row level security;
alter table public.loan_installments enable row level security;
alter table public.loan_penalties enable row level security;
alter table public.loan_default_events enable row level security;
alter table public.loan_disbursements enable row level security;
alter table public.expenses enable row level security;
alter table public.audit_logs enable row level security;
alter table public.financial_rules enable row level security;
alter table public.financial_rule_versions enable row level security;

-- ---------------------------------------------------------------------------
-- 23. Grants
-- ---------------------------------------------------------------------------

revoke all on all tables in schema public from anon;
grant usage on schema public to authenticated;
revoke all on all tables in schema public from authenticated;

grant select, insert, update on public.profiles to authenticated;
grant select on public.roles, public.permissions, public.role_permissions to authenticated;
grant select, insert, delete on public.user_roles to authenticated;

grant select, insert, update on public.membership_applications to authenticated;
grant select on public.members, public.membership_status_history to authenticated;

grant select on public.account_types, public.accounts to authenticated;
grant select, insert on public.transactions to authenticated;
grant select, insert on public.transaction_entries to authenticated;

grant select on public.payment_methods to authenticated;
grant select, insert, update on public.payments to authenticated;
grant select, insert on public.payment_verifications to authenticated;

grant select on public.savings_accounts, public.savings_obligations, public.savings_contributions, public.savings_penalties to authenticated;
grant insert on public.savings_contributions to authenticated;
grant insert, select on public.withdrawal_requests to authenticated;
grant update on public.withdrawal_requests to authenticated;

grant select on public.loan_products to authenticated;
grant select, insert, update on public.loan_applications to authenticated;
grant select on public.loan_eligibility_checks to authenticated;
grant select on public.loans to authenticated;
grant select, insert, update on public.loan_guarantors to authenticated;
grant select, insert on public.loan_approvals to authenticated;
grant select on public.loan_installments, public.loan_penalties to authenticated;
grant select on public.loan_default_events to authenticated;
grant select on public.loan_disbursements to authenticated;

grant select, insert, update on public.expenses to authenticated;
grant select on public.audit_logs to authenticated;
grant select on public.financial_rules, public.financial_rule_versions to authenticated;

grant select on public.member_savings_summary, public.loan_portfolio_summary, public.management_dashboard to authenticated;

-- ---------------------------------------------------------------------------
-- 24. RLS policies - profiles
-- ---------------------------------------------------------------------------

create policy "profiles_select_own_or_admin"
on public.profiles
for select
to authenticated
using (
  id = (select auth.uid())
  or private.current_user_is_admin()
);

create policy "profiles_insert_own"
on public.profiles
for insert
to authenticated
with check (id = (select auth.uid()));

create policy "profiles_update_own_or_admin"
on public.profiles
for update
to authenticated
using (
  id = (select auth.uid())
  or private.current_user_is_admin()
)
with check (
  id = (select auth.uid())
  or private.current_user_is_admin()
);

-- ---------------------------------------------------------------------------
-- 25. RLS policies - roles / permissions / assignments
-- ---------------------------------------------------------------------------

create policy "roles_select_authenticated"
on public.roles
for select
to authenticated
using (true);

create policy "permissions_select_authenticated"
on public.permissions
for select
to authenticated
using (true);

create policy "role_permissions_select_authenticated"
on public.role_permissions
for select
to authenticated
using (true);

create policy "user_roles_select_own_or_admin"
on public.user_roles
for select
to authenticated
using (
  user_id = (select auth.uid())
  or private.current_user_is_admin()
);

create policy "user_roles_manage_admin_only"
on public.user_roles
for all
to authenticated
using (private.current_user_is_admin())
with check (private.current_user_is_admin());

-- ---------------------------------------------------------------------------
-- 26. Membership RLS
-- ---------------------------------------------------------------------------

create policy "membership_applications_select_own_or_admin"
on public.membership_applications
for select
to authenticated
using (
  applicant_id = (select auth.uid())
  or private.current_user_is_admin()
);

create policy "membership_applications_insert_own"
on public.membership_applications
for insert
to authenticated
with check (applicant_id = (select auth.uid()));

create policy "membership_applications_update_admin"
on public.membership_applications
for update
to authenticated
using (private.current_user_is_admin())
with check (private.current_user_is_admin());

create policy "members_select_own_or_admin"
on public.members
for select
to authenticated
using (
  profile_id = (select auth.uid())
  or private.current_user_is_admin()
);

create policy "members_manage_admin"
on public.members
for all
to authenticated
using (private.current_user_is_admin())
with check (private.current_user_is_admin());

create policy "membership_status_history_select_own_or_admin"
on public.membership_status_history
for select
to authenticated
using (
  exists (
    select 1 from public.members m
    where m.id = member_id
      and (m.profile_id = (select auth.uid()) or private.current_user_is_admin())
  )
);

create policy "membership_status_history_insert_admin"
on public.membership_status_history
for insert
to authenticated
with check (private.current_user_is_admin());

-- ---------------------------------------------------------------------------
-- 27. Account / ledger RLS
-- ---------------------------------------------------------------------------

create policy "account_types_select_authenticated"
on public.account_types
for select
to authenticated
using (true);

create policy "accounts_select_own_or_admin"
on public.accounts
for select
to authenticated
using (
  owner_profile_id = (select auth.uid())
  or owner_member_id = (select private.current_member_id())
  or private.current_user_is_admin()
);

create policy "transactions_select_own_or_admin"
on public.transactions
for select
to authenticated
using (
  profile_id = (select auth.uid())
  or member_id = (select private.current_member_id())
  or private.current_user_is_admin()
);

create policy "transactions_insert_admin_only"
on public.transactions
for insert
to authenticated
with check (
  private.current_user_is_admin()
  and initiated_by = (select auth.uid())
);

create policy "transaction_entries_select_own_or_admin"
on public.transaction_entries
for select
to authenticated
using (
  private.current_user_is_admin()
  or exists (
    select 1
    from public.transactions t
    join public.accounts a
      on a.id = account_id
    where t.id = transaction_id
      and (
        t.profile_id = (select auth.uid())
        or t.member_id = (select private.current_member_id())
        or a.owner_profile_id = (select auth.uid())
        or a.owner_member_id = (select private.current_member_id())
      )
  )
);

create policy "transaction_entries_insert_admin"
on public.transaction_entries
for insert
to authenticated
with check (private.current_user_is_admin());

-- ---------------------------------------------------------------------------
-- 28. Payments RLS
-- ---------------------------------------------------------------------------

create policy "payment_methods_select_authenticated"
on public.payment_methods
for select
to authenticated
using (active = true or private.current_user_is_admin());

create policy "payments_select_own_or_admin"
on public.payments
for select
to authenticated
using (
  payer_profile_id = (select auth.uid())
  or private.current_user_is_admin()
);

create policy "payments_insert_own"
on public.payments
for insert
to authenticated
with check (payer_profile_id = (select auth.uid()));

create policy "payments_update_admin"
on public.payments
for update
to authenticated
using (private.current_user_is_admin())
with check (private.current_user_is_admin());

create policy "payment_verifications_select_own_or_admin"
on public.payment_verifications
for select
to authenticated
using (
  private.current_user_is_admin()
  or exists (
    select 1 from public.payments p
    where p.id = payment_id
      and p.payer_profile_id = (select auth.uid())
  )
);

create policy "payment_verifications_insert_admin"
on public.payment_verifications
for insert
to authenticated
with check (private.current_user_is_admin());

-- ---------------------------------------------------------------------------
-- 29. Savings RLS
-- ---------------------------------------------------------------------------

create policy "savings_accounts_select_own_or_admin"
on public.savings_accounts
for select
to authenticated
using (
  private.current_user_is_admin()
  or exists (
    select 1 from public.members m
    where m.id = member_id
      and m.profile_id = (select auth.uid())
  )
);

create policy "savings_obligations_select_own_or_admin"
on public.savings_obligations
for select
to authenticated
using (
  private.current_user_is_admin()
  or member_id = (select private.current_member_id())
);

create policy "savings_obligations_manage_admin"
on public.savings_obligations
for all
to authenticated
using (private.current_user_is_admin())
with check (private.current_user_is_admin());

create policy "savings_contributions_select_own_or_admin"
on public.savings_contributions
for select
to authenticated
using (
  private.current_user_is_admin()
  or member_id = (select private.current_member_id())
);

create policy "savings_contributions_insert_own"
on public.savings_contributions
for insert
to authenticated
with check (
  member_id = (select private.current_member_id())
);

create policy "savings_penalties_select_own_or_admin"
on public.savings_penalties
for select
to authenticated
using (
  private.current_user_is_admin()
  or exists (
    select 1
    from public.savings_obligations so
    where so.id = obligation_id
      and so.member_id = (select private.current_member_id())
  )
);

create policy "savings_penalties_manage_admin"
on public.savings_penalties
for all
to authenticated
using (private.current_user_is_admin())
with check (private.current_user_is_admin());

create policy "withdrawal_requests_select_own_or_admin"
on public.withdrawal_requests
for select
to authenticated
using (
  private.current_user_is_admin()
  or member_id = (select private.current_member_id())
);

create policy "withdrawal_requests_insert_own"
on public.withdrawal_requests
for insert
to authenticated
with check (
  member_id = (select private.current_member_id())
);

create policy "withdrawal_requests_update_admin"
on public.withdrawal_requests
for update
to authenticated
using (private.current_user_is_admin())
with check (private.current_user_is_admin());

-- ---------------------------------------------------------------------------
-- 30. Loan RLS
-- ---------------------------------------------------------------------------

create policy "loan_products_select_authenticated"
on public.loan_products
for select
to authenticated
using (active = true or private.current_user_is_admin());

create policy "loan_applications_select_own_or_admin"
on public.loan_applications
for select
to authenticated
using (
  applicant_profile_id = (select auth.uid())
  or private.current_user_is_admin()
  or exists (
    select 1 from public.loan_guarantors lg
    join public.members gm on gm.id = lg.guarantor_member_id
    where lg.loan_application_id = id
      and gm.profile_id = (select auth.uid())
  )
);

create policy "loan_applications_insert_own"
on public.loan_applications
for insert
to authenticated
with check (
  applicant_profile_id = (select auth.uid())
);

create policy "loan_applications_update_own_draft_or_admin"
on public.loan_applications
for update
to authenticated
using (
  private.current_user_is_admin()
  or (
    applicant_profile_id = (select auth.uid())
    and status = 'draft'
  )
)
with check (
  private.current_user_is_admin()
  or (
    applicant_profile_id = (select auth.uid())
    and status = 'draft'
  )
);

create policy "loan_eligibility_checks_select_application_owner_or_admin"
on public.loan_eligibility_checks
for select
to authenticated
using (
  private.current_user_is_admin()
  or exists (
    select 1
    from public.loan_applications la
    where la.id = loan_application_id
      and la.applicant_profile_id = (select auth.uid())
  )
);

create policy "loan_eligibility_checks_insert_admin"
on public.loan_eligibility_checks
for insert
to authenticated
with check (private.current_user_is_admin());

create policy "loans_select_own_or_admin"
on public.loans
for select
to authenticated
using (
  borrower_profile_id = (select auth.uid())
  or private.current_user_is_admin()
);

create policy "loan_guarantors_select_borrower_guarantor_or_admin"
on public.loan_guarantors
for select
to authenticated
using (
  private.current_user_is_admin()
  or exists (
    select 1
    from public.loan_applications la
    where la.id = loan_application_id
      and la.applicant_profile_id = (select auth.uid())
  )
  or exists (
    select 1
    from public.members m
    where m.id = guarantor_member_id
      and m.profile_id = (select auth.uid())
  )
);

create policy "loan_guarantors_insert_borrower_or_admin"
on public.loan_guarantors
for insert
to authenticated
with check (
  private.current_user_is_admin()
  or exists (
    select 1 from public.loan_applications la
    where la.id = loan_application_id
      and la.applicant_profile_id = (select auth.uid())
  )
);

create policy "loan_guarantors_update_guarantor_or_admin"
on public.loan_guarantors
for update
to authenticated
using (
  private.current_user_is_admin()
  or exists (
    select 1
    from public.members m
    where m.id = guarantor_member_id
      and m.profile_id = (select auth.uid())
  )
)
with check (
  private.current_user_is_admin()
  or exists (
    select 1
    from public.members m
    where m.id = guarantor_member_id
      and m.profile_id = (select auth.uid())
  )
);

create policy "loan_approvals_select_approver_or_admin"
on public.loan_approvals
for select
to authenticated
using (
  private.current_user_is_admin()
  or approver_profile_id = (select auth.uid())
  or exists (
    select 1
    from public.loan_applications la
    where la.id = loan_application_id
      and la.applicant_profile_id = (select auth.uid())
  )
);

create policy "loan_approvals_insert_admin"
on public.loan_approvals
for insert
to authenticated
with check (
  private.current_user_is_admin()
  and approver_profile_id = (select auth.uid())
);

create policy "loan_installments_select_borrower_or_admin"
on public.loan_installments
for select
to authenticated
using (
  private.current_user_is_admin()
  or exists (
    select 1
    from public.loans l
    where l.id = loan_id
      and l.borrower_profile_id = (select auth.uid())
  )
);

create policy "loan_penalties_select_borrower_or_admin"
on public.loan_penalties
for select
to authenticated
using (
  private.current_user_is_admin()
  or exists (
    select 1
    from public.loan_installments li
    join public.loans l on l.id = li.loan_id
    where li.id = installment_id
      and l.borrower_profile_id = (select auth.uid())
  )
);

create policy "loan_default_events_select_borrower_or_admin"
on public.loan_default_events
for select
to authenticated
using (
  private.current_user_is_admin()
  or exists (
    select 1
    from public.loans l
    where l.id = loan_id
      and l.borrower_profile_id = (select auth.uid())
  )
);

create policy "loan_disbursements_select_borrower_or_admin"
on public.loan_disbursements
for select
to authenticated
using (
  private.current_user_is_admin()
  or exists (
    select 1
    from public.loans l
    where l.id = loan_id
      and l.borrower_profile_id = (select auth.uid())
  )
);

-- ---------------------------------------------------------------------------
-- 31. Expense / audit / rules RLS
-- ---------------------------------------------------------------------------

create policy "expenses_select_admin"
on public.expenses
for select
to authenticated
using (private.current_user_is_admin());

create policy "expenses_insert_admin"
on public.expenses
for insert
to authenticated
with check (private.current_user_is_admin());

create policy "expenses_update_admin"
on public.expenses
for update
to authenticated
using (private.current_user_is_admin())
with check (private.current_user_is_admin());

create policy "audit_logs_select_admin"
on public.audit_logs
for select
to authenticated
using (private.current_user_is_admin());

create policy "audit_logs_insert_authenticated"
on public.audit_logs
for insert
to authenticated
with check (actor_user_id = (select auth.uid()));

create policy "financial_rules_select_authenticated"
on public.financial_rules
for select
to authenticated
using (true);

create policy "financial_rule_versions_select_authenticated"
on public.financial_rule_versions
for select
to authenticated
using (true);

-- Management views: members can inspect only their own row through the
-- underlying security-invoker view/RLS. Admins can see all.
create policy "loan_product_read_active"
on public.loan_products
for select
to authenticated
using (active = true or private.current_user_is_admin());

-- ---------------------------------------------------------------------------
-- 32. Default role bootstrap helper for an existing profile
-- ---------------------------------------------------------------------------

create or replace function public.bootstrap_non_member_role()
returns void
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_role_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  select id into v_role_id
  from public.roles
  where code = 'non_member';

  insert into public.user_roles(user_id, role_id)
  values (auth.uid(), v_role_id)
  on conflict do nothing;
end;
$$;

revoke all on function public.bootstrap_non_member_role() from public;
grant execute on function public.bootstrap_non_member_role() to authenticated;

-- ---------------------------------------------------------------------------
-- 33. Basic integrity helper functions
-- ---------------------------------------------------------------------------

create or replace function public.is_member_eligible_for_loan(p_member_id uuid)
returns boolean
language sql
stable
as $$
  select
    exists (
      select 1
      from public.members m
      where m.id = p_member_id
        and m.status = 'active'
    )
    and (
      select count(*)
      from public.savings_obligations so
      where so.member_id = p_member_id
        and so.status = 'paid'
    ) >= 2
    and not exists (
      select 1
      from public.loan_installments li
      join public.loans l on l.id = li.loan_id
      where l.member_id = p_member_id
        and li.status in ('overdue', 'defaulted')
    );
$$;

revoke all on function public.is_member_eligible_for_loan(uuid) from public;
grant execute on function public.is_member_eligible_for_loan(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 34. Indexes
-- ---------------------------------------------------------------------------

create index membership_applications_applicant_idx
on public.membership_applications(applicant_id, created_at desc);

create index members_profile_idx
on public.members(profile_id);

create index savings_obligations_due_idx
on public.savings_obligations(due_date, status);

create index savings_contributions_member_idx
on public.savings_contributions(member_id, created_at desc);

create index withdrawal_requests_member_idx
on public.withdrawal_requests(member_id, created_at desc);

create index loan_applications_applicant_idx
on public.loan_applications(applicant_profile_id, created_at desc);

create index loan_guarantors_guarantor_idx
on public.loan_guarantors(guarantor_member_id, status);

create index loan_installments_due_idx
on public.loan_installments(due_date, status);

create index audit_logs_entity_idx
on public.audit_logs(entity_type, entity_id, created_at desc);

create index audit_logs_actor_idx
on public.audit_logs(actor_user_id, created_at desc);

-- ---------------------------------------------------------------------------
-- 35. Post-install verification queries
-- ---------------------------------------------------------------------------

-- These do not change data. They are here so you can run them after the
-- migration if you want to verify the seed values.

-- select rule_code, status, effective_from,
--        coalesce(value_numeric, value_integer::numeric) as value
-- from public.financial_rules fr
-- join public.financial_rule_versions frv on frv.rule_id = fr.id
-- where frv.status = 'active'
-- order by rule_code;

-- select code, name from public.roles order by code;

-- select code, name, borrower_type, service_charge_rate, max_amount, term_months
-- from public.loan_products
-- order by code;

commit;
