/*
===============================================================================
Unity Finance Group
Admin Payments + Expenses Production SQL/RPC V1
===============================================================================

Purpose
-------
Production admin boundary for:
  - payment verification/rejection queue
  - expense request/approval/payment workflow
  - finance overview/read models
  - financial transaction reversal for expense transactions
  - audit + RBAC hardening

Dependencies
------------
- Unity Finance MVP Supabase schema
- Admin Savings SQL/RPC migration
- Loan V3 RPC migration for loan-repayment payments to remain domain-specific

Important boundary
------------------
Payments are not one generic posting domain. A payment's purpose owns its
posting behavior. Savings payments must continue through
admin_verify_savings_payment(). Loan repayments continue through the Loan V3
repayment verification/posting workflow. This generic admin payment module
therefore never silently posts an unsupported payment purpose.

Expenses are a controlled workflow:
  pending -> approved/rejected
  approved -> paid

Paying an expense is the financial posting event. Approval alone does not move
money and never creates a ledger transaction.

No financial record is hard-deleted.
===============================================================================
*/

begin;

/* -------------------------------------------------------------------------- */
/* 1. RBAC                                                                    */
/* -------------------------------------------------------------------------- */

insert into public.permissions (code, name, description)
values
  ('payment.view', 'View Payments', 'View administrative payment records'),
  ('payment.reject', 'Reject Payment', 'Reject pending administrative payments'),
  ('expense.view', 'View Expenses', 'View expense records'),
  ('expense.create', 'Create Expense', 'Create an expense request'),
  ('expense.approve', 'Approve Expense', 'Approve or reject expense requests'),
  ('expense.pay', 'Pay Expense', 'Release approved expense funds'),
  ('expense.reverse', 'Reverse Expense', 'Reverse a posted expense transaction')
on conflict (code) do nothing;

insert into public.role_permissions (role_id, permission_id)
select r.id, p.id
from public.roles r
cross join public.permissions p
where r.code in ('admin', 'super_admin')
  and p.code in (
    'payment.view',
    'payment.verify',
    'payment.reject',
    'expense.view',
    'expense.create',
    'expense.approve',
    'expense.pay',
    'expense.reverse'
  )
on conflict do nothing;

/* -------------------------------------------------------------------------- */
/* 2. Idempotency support                                                     */
/* -------------------------------------------------------------------------- */

create table if not exists public.finance_command_idempotency (
  id uuid primary key default gen_random_uuid(),
  actor_profile_id uuid not null references public.profiles(id) on delete restrict,
  command_type text not null,
  idempotency_key text not null,
  target_type text,
  target_id uuid,
  status text not null default 'completed'
    check (status in ('in_progress', 'completed', 'failed')),
  response jsonb,
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  unique (actor_profile_id, command_type, idempotency_key)
);

create index if not exists finance_command_idempotency_target_idx
  on public.finance_command_idempotency(target_type, target_id, created_at desc);

alter table public.finance_command_idempotency enable row level security;
revoke all on public.finance_command_idempotency from anon, authenticated;

/* -------------------------------------------------------------------------- */
/* 3. Operational indexes                                                     */
/* -------------------------------------------------------------------------- */

create index if not exists payments_admin_status_submitted_idx
  on public.payments(status, submitted_at desc);

create index if not exists payments_admin_purpose_idx
  on public.payments(purpose_type, purpose_id, status, submitted_at desc);

create index if not exists payments_admin_reference_idx
  on public.payments(reference_number);

create index if not exists payments_admin_external_reference_idx
  on public.payments(external_reference)
  where external_reference is not null;

create index if not exists expenses_admin_status_created_idx
  on public.expenses(status, created_at desc);

create index if not exists expenses_admin_requested_by_idx
  on public.expenses(requested_by, created_at desc);

create index if not exists expenses_admin_reference_idx
  on public.expenses(reference_number);

/* -------------------------------------------------------------------------- */
/* 4. Financial-write hardening                                               */
/* -------------------------------------------------------------------------- */

revoke insert, update, delete on public.expenses from authenticated;
revoke update, delete on public.payments from authenticated;
revoke insert, update, delete on public.payment_verifications from authenticated;
revoke insert, update, delete on public.transactions from authenticated;
revoke insert, update, delete on public.transaction_entries from authenticated;

/* -------------------------------------------------------------------------- */
/* 5. Admin read models                                                       */
/* -------------------------------------------------------------------------- */

create or replace view public.admin_finance_overview_v1
with (security_invoker = true)
as
select
  (
    select count(*)
    from public.payments p
    where p.status = 'pending'
  ) as pending_payments,
  (
    select coalesce(sum(p.amount), 0)
    from public.payments p
    where p.status = 'pending'
  )::numeric(18,2) as pending_payment_amount,
  (
    select count(*)
    from public.payments p
    where p.status = 'verified'
      and p.verified_at::date = current_date
  ) as verified_payments_today,
  (
    select coalesce(sum(p.amount), 0)
    from public.payments p
    where p.status = 'verified'
      and p.verified_at::date = current_date
  )::numeric(18,2) as verified_payment_amount_today,
  (
    select count(*)
    from public.expenses e
    where e.status = 'pending'
  ) as pending_expenses,
  (
    select coalesce(sum(e.amount), 0)
    from public.expenses e
    where e.status = 'pending'
  )::numeric(18,2) as pending_expense_amount,
  (
    select count(*)
    from public.expenses e
    where e.status = 'approved'
  ) as approved_expenses,
  (
    select coalesce(sum(e.amount), 0)
    from public.expenses e
    where e.status = 'approved'
  )::numeric(18,2) as approved_expense_amount,
  (
    select coalesce(sum(e.amount), 0)
    from public.expenses e
    where e.status = 'paid'
      and e.paid_at::date = current_date
  )::numeric(18,2) as paid_expense_amount_today,
  (
    select coalesce(sum(e.amount), 0)
    from public.expenses e
    where e.status = 'paid'
      and date_trunc('month', e.paid_at) = date_trunc('month', now())
  )::numeric(18,2) as paid_expense_amount_month;

create or replace view public.admin_payment_queue_v1
with (security_invoker = true)
as
select
  p.id,
  p.reference_number,
  p.payer_profile_id,
  pr.full_name as payer_name,
  pr.phone as payer_phone,
  m.id as member_id,
  m.member_number,
  pm.code as payment_method_code,
  pm.name as payment_method_name,
  p.purpose_type,
  p.purpose_id,
  p.amount,
  p.currency,
  p.status,
  p.payment_proof_path,
  p.external_reference,
  p.submitted_at,
  p.verified_by,
  verifier.full_name as verified_by_name,
  p.verified_at,
  p.rejection_reason,
  p.created_at,
  p.updated_at,
  case
    when p.purpose_type = 'savings' then 'savings'
    when p.purpose_type = 'loan_repayment' then 'loan_repayment'
    when p.purpose_type in ('membership_fee', 'first_contribution') then 'membership'
    else 'other'
  end as domain_handler,
  case
    when p.purpose_type in ('savings', 'loan_repayment') and p.status = 'pending'
      then true
    else false
  end as can_verify_here
from public.payments p
join public.profiles pr on pr.id = p.payer_profile_id
left join public.members m on m.profile_id = p.payer_profile_id
join public.payment_methods pm on pm.id = p.payment_method_id
left join public.profiles verifier on verifier.id = p.verified_by;

create or replace view public.admin_expense_queue_v1
with (security_invoker = true)
as
select
  e.id,
  e.reference_number,
  e.category,
  e.amount,
  e.description,
  e.supporting_document_path,
  e.status,
  e.requested_by,
  requester.full_name as requested_by_name,
  requester.phone as requested_by_phone,
  e.approved_by,
  approver.full_name as approved_by_name,
  e.created_at,
  e.approved_at,
  e.paid_at,
  tx.id as transaction_id
from public.expenses e
left join public.profiles requester on requester.id = e.requested_by
left join public.profiles approver on approver.id = e.approved_by
left join public.transactions tx
  on tx.source_type = 'expense'
 and tx.source_id = e.id
 and tx.transaction_status = 'posted';

grant select on public.admin_finance_overview_v1,
               public.admin_payment_queue_v1,
               public.admin_expense_queue_v1
  to authenticated;

/* -------------------------------------------------------------------------- */
/* 6. Internal finance helpers                                                */
/* -------------------------------------------------------------------------- */

create or replace function private.finance_begin_idempotency_v1(
  p_actor uuid,
  p_command_type text,
  p_key text,
  p_target_type text,
  p_target_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row public.finance_command_idempotency%rowtype;
begin
  insert into public.finance_command_idempotency (
    actor_profile_id,
    command_type,
    idempotency_key,
    target_type,
    target_id,
    status
  ) values (
    p_actor,
    p_command_type,
    p_key,
    p_target_type,
    p_target_id,
    'in_progress'
  )
  on conflict (actor_profile_id, command_type, idempotency_key) do nothing
  returning * into v_row;

  if found then
    return jsonb_build_object('replayed', false, 'id', v_row.id);
  end if;

  select * into v_row
  from public.finance_command_idempotency
  where actor_profile_id = p_actor
    and command_type = p_command_type
    and idempotency_key = p_key
  for update;

  if v_row.status = 'completed' and v_row.response is not null then
    return jsonb_build_object('replayed', true, 'response', v_row.response);
  end if;

  raise exception 'The same financial command is already in progress';
end;
$$;

revoke all on function private.finance_begin_idempotency_v1(uuid,text,text,text,uuid)
  from public, anon, authenticated;

create or replace function private.finance_finish_idempotency_v1(
  p_actor uuid,
  p_command_type text,
  p_key text,
  p_response jsonb
)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.finance_command_idempotency
  set status = 'completed',
      response = p_response,
      completed_at = now()
  where actor_profile_id = p_actor
    and command_type = p_command_type
    and idempotency_key = p_key;
$$;

revoke all on function private.finance_finish_idempotency_v1(uuid,text,text,jsonb)
  from public, anon, authenticated;

create or replace function private.finance_source_account_balance_v1(p_account_id uuid)
returns numeric
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(sum(
    case
      when te.entry_type = 'debit' then te.amount
      else -te.amount
    end
  ), 0)::numeric(18,2)
  from public.transaction_entries te
  join public.transactions t on t.id = te.transaction_id
  where te.account_id = p_account_id
    and t.transaction_status = 'posted';
$$;

revoke all on function private.finance_source_account_balance_v1(uuid)
  from public, anon, authenticated;

create or replace function public.get_admin_finance_capabilities_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null then raise exception 'Unauthorized'; end if;
  return jsonb_build_object(
    'payment_view', private.current_user_has_permission('payment.view'),
    'payment_reject', private.current_user_has_permission('payment.reject'),
    'expense_view', private.current_user_has_permission('expense.view'),
    'expense_create', private.current_user_has_permission('expense.create'),
    'expense_approve', private.current_user_has_permission('expense.approve'),
    'expense_pay', private.current_user_has_permission('expense.pay'),
    'expense_reverse', private.current_user_has_permission('expense.reverse')
  );
end;
$$;

revoke all on function public.get_admin_finance_capabilities_v1() from public, anon;
grant execute on function public.get_admin_finance_capabilities_v1() to authenticated;

create or replace function public.list_admin_finance_funding_accounts_v1()
returns table(id uuid, account_type text, currency text, balance numeric)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null then raise exception 'Unauthorized'; end if;
  if not private.current_user_has_permission('expense.pay') then
    raise exception 'Unauthorized: expense payment permission required';
  end if;

  return query
  select a.id, at.code::text, a.currency, private.finance_source_account_balance_v1(a.id)
  from public.accounts a
  join public.account_types at on at.id = a.account_type_id
  where a.owner_member_id is null
    and a.owner_profile_id is null
    and a.status = 'active'
    and at.code in ('cash', 'bank', 'wallet')
  order by at.code, a.id;
end;
$$;

revoke all on function public.list_admin_finance_funding_accounts_v1() from public, anon;
grant execute on function public.list_admin_finance_funding_accounts_v1() to authenticated;

/* -------------------------------------------------------------------------- */
/* 7. Generic admin payment verification                                      */
/* -------------------------------------------------------------------------- */

create or replace function public.admin_verify_payment_v1(
  p_payment_id uuid,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_payment public.payments%rowtype;
  v_idem jsonb;
  v_result jsonb;
begin
  if v_actor is null then
    raise exception 'Unauthorized';
  end if;

  if not private.current_user_has_permission('payment.verify') then
    raise exception 'Unauthorized: payment verification permission required';
  end if;

  if p_idempotency_key is null or length(trim(p_idempotency_key)) < 8 then
    raise exception 'Idempotency key is required';
  end if;

  v_idem := private.finance_begin_idempotency_v1(
    v_actor,
    'ADMIN_VERIFY_PAYMENT',
    trim(p_idempotency_key),
    'payment',
    p_payment_id
  );

  if coalesce((v_idem->>'replayed')::boolean, false) then
    return v_idem->'response';
  end if;

  select * into v_payment
  from public.payments
  where id = p_payment_id
  for update;

  if not found then
    raise exception 'Payment not found';
  end if;

  if v_payment.status <> 'pending' then
    raise exception 'Only pending payments can be verified';
  end if;

  if v_payment.purpose_type = 'savings' then
    v_result := public.admin_verify_savings_payment(p_payment_id);
  elsif v_payment.purpose_type = 'loan_repayment' then
    raise exception 'Loan repayments must be verified from the Loan Repayment workflow';
  else
    raise exception 'Payment purpose is not currently supported by the generic verification workflow';
  end if;

  perform private.finance_finish_idempotency_v1(
    v_actor,
    'ADMIN_VERIFY_PAYMENT',
    trim(p_idempotency_key),
    v_result
  );

  return v_result;
end;
$$;

revoke all on function public.admin_verify_payment_v1(uuid,text)
  from public, anon;

grant execute on function public.admin_verify_payment_v1(uuid,text)
  to authenticated;

/* -------------------------------------------------------------------------- */
/* 8. Generic payment rejection                                                */
/* -------------------------------------------------------------------------- */

create or replace function public.admin_reject_payment_v1(
  p_payment_id uuid,
  p_reason text,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_payment public.payments%rowtype;
  v_reason text := trim(coalesce(p_reason, ''));
  v_idem jsonb;
  v_old jsonb;
  v_result jsonb;
begin
  if v_actor is null then raise exception 'Unauthorized'; end if;
  if not private.current_user_has_permission('payment.reject') then
    raise exception 'Unauthorized: payment rejection permission required';
  end if;
  if length(v_reason) < 10 or length(v_reason) > 500 then
    raise exception 'Rejection reason must be between 10 and 500 characters';
  end if;
  if p_idempotency_key is null or length(trim(p_idempotency_key)) < 8 then
    raise exception 'Idempotency key is required';
  end if;

  v_idem := private.finance_begin_idempotency_v1(
    v_actor,
    'ADMIN_REJECT_PAYMENT',
    trim(p_idempotency_key),
    'payment',
    p_payment_id
  );
  if coalesce((v_idem->>'replayed')::boolean, false) then
    return v_idem->'response';
  end if;

  select * into v_payment
  from public.payments
  where id = p_payment_id
  for update;

  if not found then raise exception 'Payment not found'; end if;
  if v_payment.status <> 'pending' then raise exception 'Only pending payments can be rejected'; end if;
  if v_payment.purpose_type = 'loan_repayment' then
    raise exception 'Loan repayments must be rejected from the Loan Repayment workflow';
  end if;

  v_old := to_jsonb(v_payment);

  update public.payments
  set status = 'rejected',
      rejection_reason = v_reason,
      verified_by = v_actor,
      verified_at = now(),
      updated_at = now()
  where id = p_payment_id;

  insert into public.payment_verifications (
    payment_id,
    verification_type,
    status,
    verified_by,
    external_reference,
    evidence,
    verified_at
  ) values (
    p_payment_id,
    'manual_admin_rejection',
    'rejected',
    v_actor,
    v_payment.external_reference,
    jsonb_build_object('reason', v_reason),
    now()
  );

  insert into public.audit_logs (
    actor_user_id, action, entity_type, entity_id, old_data, new_data, metadata
  ) values (
    v_actor,
    'PAYMENT_REJECTED',
    'payment',
    p_payment_id,
    v_old,
    jsonb_build_object('status', 'rejected'),
    jsonb_build_object('reason', v_reason, 'purpose_type', v_payment.purpose_type)
  );

  v_result := jsonb_build_object(
    'payment_id', p_payment_id,
    'status', 'rejected',
    'reason', v_reason
  );

  perform private.finance_finish_idempotency_v1(
    v_actor,
    'ADMIN_REJECT_PAYMENT',
    trim(p_idempotency_key),
    v_result
  );

  return v_result;
end;
$$;

revoke all on function public.admin_reject_payment_v1(uuid,text,text)
  from public, anon;

grant execute on function public.admin_reject_payment_v1(uuid,text,text)
  to authenticated;

/* -------------------------------------------------------------------------- */
/* 9. Expense creation                                                        */
/* -------------------------------------------------------------------------- */

create or replace function public.admin_create_expense_v1(
  p_category text,
  p_amount numeric,
  p_description text,
  p_supporting_document_path text default null,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_category text := trim(coalesce(p_category, ''));
  v_description text := trim(coalesce(p_description, ''));
  v_idem jsonb;
  v_expense_id uuid;
  v_reference text;
  v_result jsonb;
begin
  if v_actor is null then raise exception 'Unauthorized'; end if;
  if not private.current_user_has_permission('expense.create') then
    raise exception 'Unauthorized: expense creation permission required';
  end if;
  if p_amount is null or round(p_amount,2) <= 0 then
    raise exception 'Expense amount must be greater than zero';
  end if;
  if length(v_category) < 2 or length(v_category) > 100 then
    raise exception 'Expense category must be between 2 and 100 characters';
  end if;
  if length(v_description) < 5 or length(v_description) > 1000 then
    raise exception 'Expense description must be between 5 and 1000 characters';
  end if;
  if p_idempotency_key is null or length(trim(p_idempotency_key)) < 8 then
    raise exception 'Idempotency key is required';
  end if;

  v_idem := private.finance_begin_idempotency_v1(
    v_actor,
    'ADMIN_CREATE_EXPENSE',
    trim(p_idempotency_key),
    'expense',
    null
  );
  if coalesce((v_idem->>'replayed')::boolean, false) then
    return v_idem->'response';
  end if;

  insert into public.expenses (
    category,
    amount,
    description,
    supporting_document_path,
    status,
    requested_by
  ) values (
    v_category,
    round(p_amount,2),
    v_description,
    nullif(trim(coalesce(p_supporting_document_path,'')), ''),
    'pending',
    v_actor
  ) returning id, reference_number into v_expense_id, v_reference;

  insert into public.audit_logs (
    actor_user_id, action, entity_type, entity_id, old_data, new_data, metadata
  ) values (
    v_actor,
    'EXPENSE_CREATED',
    'expense',
    v_expense_id,
    null,
    jsonb_build_object(
      'status', 'pending',
      'category', v_category,
      'amount', round(p_amount,2),
      'reference_number', v_reference
    ),
    '{}'::jsonb
  );

  v_result := jsonb_build_object(
    'expense_id', v_expense_id,
    'reference_number', v_reference,
    'status', 'pending'
  );

  perform private.finance_finish_idempotency_v1(
    v_actor,
    'ADMIN_CREATE_EXPENSE',
    trim(p_idempotency_key),
    v_result
  );

  return v_result;
end;
$$;

revoke all on function public.admin_create_expense_v1(text,numeric,text,text,text)
  from public, anon;

grant execute on function public.admin_create_expense_v1(text,numeric,text,text,text)
  to authenticated;

/* -------------------------------------------------------------------------- */
/* 10. Expense approval                                                       */
/* -------------------------------------------------------------------------- */

create or replace function public.admin_approve_expense_v1(
  p_expense_id uuid,
  p_comment text default null,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_expense public.expenses%rowtype;
  v_idem jsonb;
  v_result jsonb;
begin
  if v_actor is null then raise exception 'Unauthorized'; end if;
  if not private.current_user_has_permission('expense.approve') then
    raise exception 'Unauthorized: expense approval permission required';
  end if;
  if p_idempotency_key is null or length(trim(p_idempotency_key)) < 8 then
    raise exception 'Idempotency key is required';
  end if;

  v_idem := private.finance_begin_idempotency_v1(
    v_actor, 'ADMIN_APPROVE_EXPENSE', trim(p_idempotency_key), 'expense', p_expense_id
  );
  if coalesce((v_idem->>'replayed')::boolean, false) then return v_idem->'response'; end if;

  select * into v_expense
  from public.expenses
  where id = p_expense_id
  for update;

  if not found then raise exception 'Expense not found'; end if;
  if v_expense.status <> 'pending' then raise exception 'Only pending expenses can be approved'; end if;
  if v_expense.requested_by = v_actor then
    raise exception 'Expense requester cannot approve their own expense';
  end if;

  update public.expenses
  set status = 'approved',
      approved_by = v_actor,
      approved_at = now()
  where id = p_expense_id;

  insert into public.audit_logs (
    actor_user_id, action, entity_type, entity_id, old_data, new_data, metadata
  ) values (
    v_actor,
    'EXPENSE_APPROVED',
    'expense',
    p_expense_id,
    jsonb_build_object('status','pending'),
    jsonb_build_object('status','approved','approved_by',v_actor),
    jsonb_build_object('comment', nullif(trim(coalesce(p_comment,'')), ''))
  );

  v_result := jsonb_build_object('expense_id', p_expense_id, 'status', 'approved');
  perform private.finance_finish_idempotency_v1(v_actor,'ADMIN_APPROVE_EXPENSE',trim(p_idempotency_key),v_result);
  return v_result;
end;
$$;

revoke all on function public.admin_approve_expense_v1(uuid,text,text) from public, anon;
grant execute on function public.admin_approve_expense_v1(uuid,text,text) to authenticated;

/* -------------------------------------------------------------------------- */
/* 11. Expense rejection                                                      */
/* -------------------------------------------------------------------------- */

create or replace function public.admin_reject_expense_v1(
  p_expense_id uuid,
  p_reason text,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_expense public.expenses%rowtype;
  v_reason text := trim(coalesce(p_reason,''));
  v_idem jsonb;
  v_result jsonb;
begin
  if v_actor is null then raise exception 'Unauthorized'; end if;
  if not private.current_user_has_permission('expense.approve') then
    raise exception 'Unauthorized: expense approval permission required';
  end if;
  if length(v_reason) < 10 or length(v_reason) > 500 then
    raise exception 'Rejection reason must be between 10 and 500 characters';
  end if;
  if p_idempotency_key is null or length(trim(p_idempotency_key)) < 8 then
    raise exception 'Idempotency key is required';
  end if;

  v_idem := private.finance_begin_idempotency_v1(
    v_actor, 'ADMIN_REJECT_EXPENSE', trim(p_idempotency_key), 'expense', p_expense_id
  );
  if coalesce((v_idem->>'replayed')::boolean, false) then return v_idem->'response'; end if;

  select * into v_expense
  from public.expenses
  where id = p_expense_id
  for update;

  if not found then raise exception 'Expense not found'; end if;
  if v_expense.status <> 'pending' then raise exception 'Only pending expenses can be rejected'; end if;

  update public.expenses
  set status = 'rejected',
      approved_by = v_actor,
      approved_at = now()
  where id = p_expense_id;

  insert into public.audit_logs (
    actor_user_id, action, entity_type, entity_id, old_data, new_data, metadata
  ) values (
    v_actor,
    'EXPENSE_REJECTED',
    'expense',
    p_expense_id,
    jsonb_build_object('status','pending'),
    jsonb_build_object('status','rejected'),
    jsonb_build_object('reason',v_reason)
  );

  v_result := jsonb_build_object('expense_id', p_expense_id, 'status', 'rejected', 'reason', v_reason);
  perform private.finance_finish_idempotency_v1(v_actor,'ADMIN_REJECT_EXPENSE',trim(p_idempotency_key),v_result);
  return v_result;
end;
$$;

revoke all on function public.admin_reject_expense_v1(uuid,text,text) from public, anon;
grant execute on function public.admin_reject_expense_v1(uuid,text,text) to authenticated;

/* -------------------------------------------------------------------------- */
/* 12. Expense payment / ledger posting                                       */
/* -------------------------------------------------------------------------- */

create or replace function public.admin_pay_expense_v1(
  p_expense_id uuid,
  p_source_account_id uuid,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_expense public.expenses%rowtype;
  v_source public.accounts%rowtype;
  v_source_type public.account_type_code;
  v_expense_account_id uuid;
  v_balance numeric(18,2);
  v_tx_id uuid;
  v_idem jsonb;
  v_result jsonb;
begin
  if v_actor is null then raise exception 'Unauthorized'; end if;
  if not private.current_user_has_permission('expense.pay') then
    raise exception 'Unauthorized: expense payment permission required';
  end if;
  if p_source_account_id is null then raise exception 'Source account is required'; end if;
  if p_idempotency_key is null or length(trim(p_idempotency_key)) < 8 then
    raise exception 'Idempotency key is required';
  end if;

  v_idem := private.finance_begin_idempotency_v1(
    v_actor, 'ADMIN_PAY_EXPENSE', trim(p_idempotency_key), 'expense', p_expense_id
  );
  if coalesce((v_idem->>'replayed')::boolean, false) then return v_idem->'response'; end if;

  select * into v_expense
  from public.expenses
  where id = p_expense_id
  for update;

  if not found then raise exception 'Expense not found'; end if;
  if v_expense.status <> 'approved' then raise exception 'Only approved expenses can be paid'; end if;

  select a.*
  into v_source
  from public.accounts a
  join public.account_types at on at.id = a.account_type_id
  where a.id = p_source_account_id
    and a.owner_member_id is null
    and a.owner_profile_id is null
    and a.status = 'active'
    and at.code in ('cash','bank','wallet')
  for update;

  if not found then raise exception 'Invalid or inactive group source account'; end if;

  select at.code into v_source_type
  from public.account_types at
  where at.id = v_source.account_type_id;

  perform pg_advisory_xact_lock(hashtextextended('UNITY_FINANCE_EXPENSE_PAYMENTS', 0));
  v_balance := private.finance_source_account_balance_v1(v_source.id);

  if v_balance < v_expense.amount then
    raise exception 'Insufficient funds in source account. Available: %, required: %', v_balance, v_expense.amount;
  end if;

  select a.id into v_expense_account_id
  from public.accounts a
  join public.account_types at on at.id = a.account_type_id
  where at.code = 'group_expense'
    and a.owner_member_id is null
    and a.owner_profile_id is null
    and a.status = 'active'
  limit 1
  for update;

  if v_expense_account_id is null then
    raise exception 'Group expense account is not configured';
  end if;

  insert into public.transactions (
    transaction_type,
    source_type,
    source_id,
    profile_id,
    amount,
    approval_status,
    transaction_status,
    initiated_by,
    approved_by,
    approved_at,
    description
  ) values (
    'expense',
    'expense',
    v_expense.id,
    v_expense.requested_by,
    v_expense.amount,
    'approved',
    'posted',
    v_actor,
    v_actor,
    now(),
    coalesce(v_expense.description, v_expense.category)
  ) returning id into v_tx_id;

  insert into public.transaction_entries (
    transaction_id, account_id, entry_type, amount
  ) values
    (v_tx_id, v_expense_account_id, 'debit', v_expense.amount),
    (v_tx_id, v_source.id, 'credit', v_expense.amount);

  update public.expenses
  set status = 'paid',
      paid_at = now()
  where id = p_expense_id;

  insert into public.audit_logs (
    actor_user_id, action, entity_type, entity_id, old_data, new_data, metadata
  ) values (
    v_actor,
    'EXPENSE_PAID',
    'expense',
    p_expense_id,
    jsonb_build_object('status','approved'),
    jsonb_build_object('status','paid','transaction_id',v_tx_id),
    jsonb_build_object(
      'source_account_id',v_source.id,
      'source_account_type',v_source_type,
      'source_balance_before',v_balance,
      'amount',v_expense.amount
    )
  );

  v_result := jsonb_build_object(
    'expense_id', p_expense_id,
    'status', 'paid',
    'transaction_id', v_tx_id,
    'source_account_id', v_source.id,
    'amount', v_expense.amount
  );

  perform private.finance_finish_idempotency_v1(v_actor,'ADMIN_PAY_EXPENSE',trim(p_idempotency_key),v_result);
  return v_result;
end;
$$;

revoke all on function public.admin_pay_expense_v1(uuid,uuid,text) from public, anon;
grant execute on function public.admin_pay_expense_v1(uuid,uuid,text) to authenticated;

/* -------------------------------------------------------------------------- */
/* 13. Expense transaction reversal                                            */
/* -------------------------------------------------------------------------- */

create or replace function public.admin_reverse_expense_transaction_v1(
  p_transaction_id uuid,
  p_reason text,
  p_idempotency_key text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_original public.transactions%rowtype;
  v_reversal_id uuid;
  v_entry record;
  v_reason text := trim(coalesce(p_reason,''));
  v_idem jsonb;
  v_result jsonb;
begin
  if v_actor is null then raise exception 'Unauthorized'; end if;
  if not private.current_user_has_permission('expense.reverse') then
    raise exception 'Unauthorized: expense reversal permission required';
  end if;
  if length(v_reason) < 10 or length(v_reason) > 500 then
    raise exception 'Reversal reason must be between 10 and 500 characters';
  end if;
  if p_idempotency_key is null or length(trim(p_idempotency_key)) < 8 then
    raise exception 'Idempotency key is required';
  end if;

  v_idem := private.finance_begin_idempotency_v1(
    v_actor, 'ADMIN_REVERSE_EXPENSE', trim(p_idempotency_key), 'transaction', p_transaction_id
  );
  if coalesce((v_idem->>'replayed')::boolean, false) then return v_idem->'response'; end if;

  select * into v_original
  from public.transactions
  where id = p_transaction_id
    and transaction_type = 'expense'
  for update;

  if not found then raise exception 'Expense transaction not found'; end if;
  if v_original.transaction_status <> 'posted' then raise exception 'Only posted expense transactions can be reversed'; end if;

  if exists (
    select 1
    from public.transactions t
    where t.reversal_of_transaction_id = p_transaction_id
      and t.transaction_status = 'posted'
  ) then
    raise exception 'Expense transaction already has a posted reversal';
  end if;

  insert into public.transactions (
    transaction_type,
    source_type,
    source_id,
    profile_id,
    amount,
    approval_status,
    transaction_status,
    initiated_by,
    approved_by,
    approved_at,
    description,
    reversal_of_transaction_id
  ) values (
    'reversal',
    'expense_reversal',
    p_transaction_id,
    v_original.profile_id,
    v_original.amount,
    'approved',
    'posted',
    v_actor,
    v_actor,
    now(),
    v_reason,
    p_transaction_id
  ) returning id into v_reversal_id;

  for v_entry in
    select account_id, entry_type, amount
    from public.transaction_entries
    where transaction_id = p_transaction_id
  loop
    insert into public.transaction_entries (
      transaction_id, account_id, entry_type, amount
    ) values (
      v_reversal_id,
      v_entry.account_id,
      case when v_entry.entry_type = 'debit'
        then 'credit'::public.transaction_entry_type
        else 'debit'::public.transaction_entry_type
      end,
      v_entry.amount
    );
  end loop;

  update public.transactions
  set transaction_status = 'reversed'
  where id = p_transaction_id;

  update public.expenses
  set status = 'approved',
      paid_at = null
  where id = v_original.source_id
    and v_original.source_type = 'expense'
    and status = 'paid';

  insert into public.audit_logs (
    actor_user_id, action, entity_type, entity_id, old_data, new_data, metadata
  ) values (
    v_actor,
    'EXPENSE_TRANSACTION_REVERSED',
    'transaction',
    p_transaction_id,
    jsonb_build_object('status','posted'),
    jsonb_build_object('status','reversed','reversal_transaction_id',v_reversal_id),
    jsonb_build_object('reason',v_reason)
  );

  v_result := jsonb_build_object(
    'transaction_id',p_transaction_id,
    'reversal_transaction_id',v_reversal_id,
    'status','reversed'
  );

  perform private.finance_finish_idempotency_v1(v_actor,'ADMIN_REVERSE_EXPENSE',trim(p_idempotency_key),v_result);
  return v_result;
end;
$$;

revoke all on function public.admin_reverse_expense_transaction_v1(uuid,text,text) from public, anon;
grant execute on function public.admin_reverse_expense_transaction_v1(uuid,text,text) to authenticated;

/* -------------------------------------------------------------------------- */
/* 14. Final grants                                                          */
/* -------------------------------------------------------------------------- */

grant select on public.expenses to authenticated;
grant select on public.payments to authenticated;
grant select on public.payment_verifications to authenticated;

commit;

/* -------------------------------------------------------------------------- */
/* 15. Verification queries                                                   */
/* -------------------------------------------------------------------------- */
-- select * from public.admin_finance_overview_v1;
-- select * from public.admin_payment_queue_v1 order by submitted_at desc limit 50;
-- select * from public.admin_expense_queue_v1 order by created_at desc limit 50;
-- select proname from pg_proc where proname in (
--   'admin_verify_payment_v1', 'admin_reject_payment_v1',
--   'admin_create_expense_v1', 'admin_approve_expense_v1',
--   'admin_reject_expense_v1', 'admin_pay_expense_v1',
--   'admin_reverse_expense_transaction_v1'
-- );

