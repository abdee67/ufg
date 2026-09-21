-- ===========================================================================
-- Unity Finance Group - Migration: Dedicated Entity Sequences & References
-- Migration: 20260921000018_dedicated_entity_sequences_and_references.sql
--
-- Purpose:
-- 1. Decouple entity references from the single global sequence (private.reference_seq).
-- 2. Give each business entity its own dedicated sequence counter:
--    - Member Numbers: MEM-000001, MEM-000002... (Lifetime strictly consecutive)
--    - Member Applications: MEMAPP-000001...
--    - Loans: LOAN-000001...
--    - Loan Applications: LOANAPP-000001...
--    - Outsider Loan Applications: OUTLOANAPP-000001...
--    - Transactions: TXN-YYYYMMDD-000001 (High-volume audit trail)
--    - Payments: PAY-YYYYMMDD-000001 (High-volume audit trail)
--    - Expenses: EXP-YYYYMMDD-000001 (High-volume audit trail)
-- 3. In test stage: safely cleans up existing data to be clean, sequential, and aligned.
-- 4. Replaces private.generate_reference() in-place with a high-performance,
--    collision-free, SECURITY DEFINER implementation.
-- ===========================================================================

begin;

-- ---------------------------------------------------------------------------
-- 1. Create Dedicated Sequences per Entity Domain
-- ---------------------------------------------------------------------------
create sequence if not exists private.seq_mem;
create sequence if not exists private.seq_memapp;
create sequence if not exists private.seq_loan;
create sequence if not exists private.seq_loanapp;
create sequence if not exists private.seq_outloanapp;
create sequence if not exists private.seq_txn;
create sequence if not exists private.seq_pay;
create sequence if not exists private.seq_exp;
create sequence if not exists private.seq_general;

-- Grant sequence permissions to ensure background workers / RPCs can access them
grant usage, select on all sequences in schema private to authenticated, anon, service_role;

-- ---------------------------------------------------------------------------
-- 2. Test-Stage Data Renumbering & Sequence Alignment
-- ---------------------------------------------------------------------------
-- Note: Uses a 2-step update (UUID temporary values first) to guarantee
-- that UNIQUE constraints are never violated during row-number reassignment.
do $$
declare
  v_max_mem bigint := 0;
  v_max_memapp bigint := 0;
  v_max_loan bigint := 0;
  v_max_loanapp bigint := 0;
  v_max_outloanapp bigint := 0;
  v_max_txn bigint := 0;
  v_max_pay bigint := 0;
  v_max_exp bigint := 0;
begin

  -- A. Renumber Members (MEM-000001, MEM-000002, ...)
  if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'members') then
    update public.members
    set member_number = 'TMP-MEM-' || gen_random_uuid()::text;

    with ordered_members as (
      select id, row_number() over (order by created_at asc, id asc) as seq_num
      from public.members
    )
    update public.members m
    set member_number = 'MEM-' || lpad(ordered_members.seq_num::text, 6, '0')
    from ordered_members
    where m.id = ordered_members.id;

    select coalesce(count(*), 0) into v_max_mem from public.members;
    perform setval('private.seq_mem', greatest(v_max_mem, 1), v_max_mem > 0);
  end if;

  -- B. Renumber Membership Applications (MEMAPP-000001, ...)
  if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'membership_applications') then
    update public.membership_applications
    set application_number = 'TMP-MEMAPP-' || gen_random_uuid()::text;

    with ordered_apps as (
      select id, row_number() over (order by created_at asc, id asc) as seq_num
      from public.membership_applications
    )
    update public.membership_applications ma
    set application_number = 'MEMAPP-' || lpad(ordered_apps.seq_num::text, 6, '0')
    from ordered_apps
    where ma.id = ordered_apps.id;

    select coalesce(count(*), 0) into v_max_memapp from public.membership_applications;
    perform setval('private.seq_memapp', greatest(v_max_memapp, 1), v_max_memapp > 0);
  end if;

  -- C. Renumber Loans (LOAN-000001, ...)
  if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'loans') then
    update public.loans
    set loan_number = 'TMP-LOAN-' || gen_random_uuid()::text;

    with ordered_loans as (
      select id, row_number() over (order by created_at asc, id asc) as seq_num
      from public.loans
    )
    update public.loans l
    set loan_number = 'LOAN-' || lpad(ordered_loans.seq_num::text, 6, '0')
    from ordered_loans
    where l.id = ordered_loans.id;

    select coalesce(count(*), 0) into v_max_loan from public.loans;
    perform setval('private.seq_loan', greatest(v_max_loan, 1), v_max_loan > 0);
  end if;

  -- D. Renumber Loan Applications (LOANAPP-000001, ...)
  if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'loan_applications') then
    update public.loan_applications
    set application_number = 'TMP-LOANAPP-' || gen_random_uuid()::text;

    with ordered_loan_apps as (
      select id, row_number() over (order by created_at asc, id asc) as seq_num
      from public.loan_applications
    )
    update public.loan_applications la
    set application_number = 'LOANAPP-' || lpad(ordered_loan_apps.seq_num::text, 6, '0')
    from ordered_loan_apps
    where la.id = ordered_loan_apps.id;

    select coalesce(count(*), 0) into v_max_loanapp from public.loan_applications;
    perform setval('private.seq_loanapp', greatest(v_max_loanapp, 1), v_max_loanapp > 0);
  end if;

  -- E. Renumber Outsider Loan Applications (OUTLOANAPP-000001, ...)
  if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'outsider_loan_applications') then
    update public.outsider_loan_applications
    set application_number = 'TMP-OUTLOANAPP-' || gen_random_uuid()::text;

    with ordered_out_apps as (
      select id, row_number() over (order by created_at asc, id asc) as seq_num
      from public.outsider_loan_applications
    )
    update public.outsider_loan_applications oa
    set application_number = 'OUTLOANAPP-' || lpad(ordered_out_apps.seq_num::text, 6, '0')
    from ordered_out_apps
    where oa.id = ordered_out_apps.id;

    select coalesce(count(*), 0) into v_max_outloanapp from public.outsider_loan_applications;
    perform setval('private.seq_outloanapp', greatest(v_max_outloanapp, 1), v_max_outloanapp > 0);
  end if;

  -- F. Renumber Transactions (TXN-YYYYMMDD-000001, ...)
  if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'transactions') then
    update public.transactions
    set reference_number = 'TMP-TXN-' || gen_random_uuid()::text;

    with ordered_txns as (
      select id, created_at, row_number() over (order by created_at asc, id asc) as seq_num
      from public.transactions
    )
    update public.transactions t
    set reference_number = 'TXN-' || to_char(coalesce(t.created_at, now()) at time zone 'utc', 'YYYYMMDD') || '-' || lpad(ordered_txns.seq_num::text, 6, '0')
    from ordered_txns
    where t.id = ordered_txns.id;

    select coalesce(count(*), 0) into v_max_txn from public.transactions;
    perform setval('private.seq_txn', greatest(v_max_txn, 1), v_max_txn > 0);
  end if;

  -- G. Renumber Payments (PAY-YYYYMMDD-000001, ...)
  if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'payments') then
    update public.payments
    set reference_number = 'TMP-PAY-' || gen_random_uuid()::text;

    with ordered_payments as (
      select id, created_at, row_number() over (order by created_at asc, id asc) as seq_num
      from public.payments
    )
    update public.payments p
    set reference_number = 'PAY-' || to_char(coalesce(p.created_at, now()) at time zone 'utc', 'YYYYMMDD') || '-' || lpad(ordered_payments.seq_num::text, 6, '0')
    from ordered_payments
    where p.id = ordered_payments.id;

    select coalesce(count(*), 0) into v_max_pay from public.payments;
    perform setval('private.seq_pay', greatest(v_max_pay, 1), v_max_pay > 0);
  end if;

  -- H. Renumber Expenses (EXP-YYYYMMDD-000001, ...)
  if exists (select 1 from information_schema.tables where table_schema = 'public' and table_name = 'expenses') then
    update public.expenses
    set reference_number = 'TMP-EXP-' || gen_random_uuid()::text;

    with ordered_expenses as (
      select id, created_at, row_number() over (order by created_at asc, id asc) as seq_num
      from public.expenses
    )
    update public.expenses e
    set reference_number = 'EXP-' || to_char(coalesce(e.created_at, now()) at time zone 'utc', 'YYYYMMDD') || '-' || lpad(ordered_expenses.seq_num::text, 6, '0')
    from ordered_expenses
    where e.id = ordered_expenses.id;

    select coalesce(count(*), 0) into v_max_exp from public.expenses;
    perform setval('private.seq_exp', greatest(v_max_exp, 1), v_max_exp > 0);
  end if;

end $$;

-- ---------------------------------------------------------------------------
-- 3. Stored Function: private.generate_reference
-- ---------------------------------------------------------------------------
-- High performance generator with dedicated sequences:
-- - High-volume audit trails (TXN, PAY, EXP) format: PREFIX-YYYYMMDD-000001
-- - Business entities (MEM, LOAN, MEMAPP, LOANAPP) format: PREFIX-000001
-- - SECURITY DEFINER ensures caller does not encounter sequence permission errors.
-- - search_path locked down to prevent search_path manipulation.
-- ---------------------------------------------------------------------------
create or replace function private.generate_reference(p_prefix text)
returns text
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_prefix text := upper(trim(coalesce(p_prefix, 'REF')));
  v_seq_name text;
  v_val bigint;
  v_date_str text;
begin
  case v_prefix
    -- Members (Permanent, strictly consecutive lifetime member counter)
    when 'MEM' then
      v_seq_name := 'private.seq_mem';
      v_val := nextval(v_seq_name);
      return 'MEM-' || lpad(v_val::text, 6, '0');

    -- Member Applications
    when 'MEMAPP' then
      v_seq_name := 'private.seq_memapp';
      v_val := nextval(v_seq_name);
      return 'MEMAPP-' || lpad(v_val::text, 6, '0');

    -- Loans
    when 'LOAN' then
      v_seq_name := 'private.seq_loan';
      v_val := nextval(v_seq_name);
      return 'LOAN-' || lpad(v_val::text, 6, '0');

    -- Member Loan Applications
    when 'LOANAPP' then
      v_seq_name := 'private.seq_loanapp';
      v_val := nextval(v_seq_name);
      return 'LOANAPP-' || lpad(v_val::text, 6, '0');

    -- Outsider Loan Applications
    when 'OUTLOANAPP' then
      v_seq_name := 'private.seq_outloanapp';
      v_val := nextval(v_seq_name);
      return 'OUTLOANAPP-' || lpad(v_val::text, 6, '0');

    -- High-Volume Financial Audit Entities (Date-partitioned YYYYMMDD + sequence)
    when 'TXN' then
      v_seq_name := 'private.seq_txn';
      v_val := nextval(v_seq_name);
      v_date_str := to_char(now() at time zone 'utc', 'YYYYMMDD');
      return 'TXN-' || v_date_str || '-' || lpad(v_val::text, 6, '0');

    when 'PAY' then
      v_seq_name := 'private.seq_pay';
      v_val := nextval(v_seq_name);
      v_date_str := to_char(now() at time zone 'utc', 'YYYYMMDD');
      return 'PAY-' || v_date_str || '-' || lpad(v_val::text, 6, '0');

    when 'EXP' then
      v_seq_name := 'private.seq_exp';
      v_val := nextval(v_seq_name);
      v_date_str := to_char(now() at time zone 'utc', 'YYYYMMDD');
      return 'EXP-' || v_date_str || '-' || lpad(v_val::text, 6, '0');

    -- Fallback for any other prefix
    else
      v_seq_name := 'private.seq_general';
      v_val := nextval(v_seq_name);
      return v_prefix || '-' || lpad(v_val::text, 6, '0');
  end case;
end;
$$;

-- ---------------------------------------------------------------------------
-- 4. Permissions & Grants
-- ---------------------------------------------------------------------------
grant usage on schema private to authenticated, anon, service_role;
grant execute on function private.generate_reference(text) to authenticated, anon, service_role;

commit;
