-- ===========================================================================
-- Unity Finance - Auto-Create Member Savings Account on Membership Approval
-- Migration: 20260906000008_auto_create_member_savings_account.sql
-- Description:
--   1. Ensures private.ensure_member_savings_account(p_member_id) creates both
--      the ledger account (public.accounts) and savings account (public.savings_accounts).
--   2. Updates public.approve_membership_application to automatically create the
--      member savings account and initial obligation when an application is approved.
--   3. Adds a trigger on public.members to guarantee savings account creation
--      whenever a member is created or activated.
--   4. Backfills savings accounts for all existing active members.
--   5. Enhances admin_verify_savings_payment with self-healing fallback.
-- ===========================================================================

-- 1. Helper: Ensure member savings account exists
create or replace function private.ensure_member_savings_account(p_member_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_member record;
  v_type_id uuid;
  v_account_id uuid;
  v_savings_acc_id uuid;
begin
  select * into v_member from public.members where id = p_member_id;
  if v_member is null then
    raise exception 'Member % does not exist.', p_member_id;
  end if;

  select id into v_type_id from public.account_types where code = 'member_savings';
  if v_type_id is null then
    raise exception 'Account type member_savings does not exist.';
  end if;

  -- Check existing ledger account in public.accounts
  select id into v_account_id
  from public.accounts
  where owner_member_id = p_member_id
    and account_type_id = v_type_id
  limit 1;

  if v_account_id is null then
    insert into public.accounts (account_type_id, owner_profile_id, owner_member_id, currency, status)
    values (v_type_id, v_member.profile_id, p_member_id, 'ETB', 'active')
    returning id into v_account_id;
  end if;

  -- Check existing public.savings_accounts row
  select id into v_savings_acc_id
  from public.savings_accounts
  where member_id = p_member_id
  limit 1;

  if v_savings_acc_id is null then
    insert into public.savings_accounts (member_id, account_id, status)
    values (p_member_id, v_account_id, 'active')
    returning id into v_savings_acc_id;
  else
    -- Ensure status is active and account_id is properly linked
    update public.savings_accounts
    set account_id = coalesce(account_id, v_account_id),
        status = case when status in ('locked', 'closed') then status else 'active' end
    where id = v_savings_acc_id;
  end if;

  return v_account_id;
end;
$$;

-- 2. Trigger on public.members to guarantee savings account creation upon activation
create or replace function public.trg_members_ensure_savings_account()
returns trigger
language plpgsql
security definer
set search_path = public, private
as $$
begin
  if NEW.status = 'active' and (TG_OP = 'INSERT' or OLD.status is distinct from 'active') then
    perform private.ensure_member_savings_account(NEW.id);
  end if;
  return NEW;
end;
$$;

drop trigger if exists trg_members_ensure_savings_account on public.members;
create trigger trg_members_ensure_savings_account
after insert or update of status on public.members
for each row
execute function public.trg_members_ensure_savings_account();

-- 3. Update public.approve_membership_application to explicitly create savings account & obligation
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
  v_required numeric(18,2);
  v_due_day numeric(18,2);
  v_due_date date;
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

  -- Ensure savings account exists for the newly approved member
  perform private.ensure_member_savings_account(v_member_id);

  -- Create current month savings obligation if financial rules are configured
  begin
    select public.get_active_rule_numeric('monthly_min_saving') into v_required;
    select public.get_active_rule_numeric('saving_due_day') into v_due_day;

    if v_required is not null and v_required > 0 and v_due_day is not null and v_due_day between 1 and 28 then
      v_due_date := make_date(
        extract(year from current_date)::integer,
        extract(month from current_date)::integer,
        v_due_day::integer
      );

      insert into public.savings_obligations (
        member_id,
        period_year,
        period_month,
        required_amount,
        due_date,
        status
      ) values (
        v_member_id,
        extract(year from current_date)::integer,
        extract(month from current_date)::integer,
        v_required,
        v_due_date,
        'pending'
      )
      on conflict (member_id, period_year, period_month) do nothing;
    end if;
  exception when others then
    -- Do not block application approval if rules table is not populated yet
    null;
  end;

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

revoke all on function public.approve_membership_application(uuid, uuid) from public, anon;
grant execute on function public.approve_membership_application(uuid, uuid) to authenticated;

-- 4. Self-healing fallback in admin_verify_savings_payment
create or replace function public.admin_verify_savings_payment(p_payment_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_payment public.payments%rowtype;
  v_member_id uuid;
  v_savings_account_id uuid;
  v_obligation public.savings_obligations%rowtype;
  v_remaining numeric(18,2);
  v_mandatory_amount numeric(18,2) := 0;
  v_voluntary_amount numeric(18,2) := 0;
  v_transaction_id uuid;
  v_cash_account_id uuid;
  v_bank_account_id uuid;
  v_wallet_account_id uuid;
  v_funding_account_id uuid;
  v_payment_method_code text;
  v_result jsonb;
begin
  if v_actor is null then
    raise exception 'Unauthorized';
  end if;

  if not private.current_user_has_permission('payment.verify') then
    raise exception 'Unauthorized: payment verification permission required';
  end if;

  select * into v_payment
  from public.payments
  where id = p_payment_id
  for update;

  if not found then
    raise exception 'Savings payment not found';
  end if;

  if v_payment.purpose_type not in ('savings', 'savings_contribution') then
    raise exception 'Payment is not a savings payment';
  end if;

  if v_payment.status = 'verified' then
    raise exception 'Payment already verified';
  end if;

  if v_payment.status <> 'pending' then
    raise exception 'Payment is not in a verifiable state';
  end if;

  select m.id into v_member_id
  from public.members m
  where m.profile_id = v_payment.payer_profile_id
    and m.status = 'active';

  if v_member_id is null then
    raise exception 'Payment payer is not an active member';
  end if;

  v_savings_account_id := private.savings_account_for_member(v_member_id);
  if v_savings_account_id is null then
    perform private.ensure_member_savings_account(v_member_id);
    v_savings_account_id := private.savings_account_for_member(v_member_id);
  end if;

  if v_savings_account_id is null then
    raise exception 'Member savings account not found';
  end if;

  select code into v_payment_method_code
  from public.payment_methods
  where id = v_payment.payment_method_id;

  if v_payment_method_code is null then
    raise exception 'Payment method not found';
  end if;

  select a.id into v_cash_account_id
  from public.accounts a
  join public.account_types at on at.id = a.account_type_id
  where at.code = 'cash'
    and a.owner_member_id is null
    and a.owner_profile_id is null
    and a.status = 'active'
  limit 1;

  select a.id into v_bank_account_id
  from public.accounts a
  join public.account_types at on at.id = a.account_type_id
  where at.code = 'bank'
    and a.owner_member_id is null
    and a.owner_profile_id is null
    and a.status = 'active'
  limit 1;

  select a.id into v_wallet_account_id
  from public.accounts a
  join public.account_types at on at.id = a.account_type_id
  where at.code = 'wallet'
    and a.owner_member_id is null
    and a.owner_profile_id is null
    and a.status = 'active'
  limit 1;

  if v_payment_method_code = 'bank_transfer' then
    v_funding_account_id := v_bank_account_id;
  elsif v_payment_method_code = 'wallet' then
    v_funding_account_id := v_wallet_account_id;
  else
    v_funding_account_id := v_cash_account_id;
  end if;

  if v_funding_account_id is null then
    raise exception 'System funding account for payment method is not configured';
  end if;

  -- A payment may optionally target an obligation through purpose_id.
  -- If no obligation is provided, apply the mandatory portion to the earliest
  -- open obligation and the excess to voluntary savings.
  if v_payment.purpose_id is not null then
    select * into v_obligation
    from public.savings_obligations so
    where so.id = v_payment.purpose_id
      and so.member_id = v_member_id
    for update;

    if not found then
      raise exception 'Referenced savings obligation not found for member';
    end if;
  else
    select * into v_obligation
    from public.savings_obligations so
    where so.member_id = v_member_id
      and so.status in ('pending', 'partially_paid', 'late')
      and so.paid_amount < so.required_amount
    order by so.due_date asc, so.created_at asc
    limit 1
    for update;
  end if;

  if v_obligation.id is not null then
    v_remaining := greatest(v_obligation.required_amount - v_obligation.paid_amount, 0);
    v_mandatory_amount := least(v_payment.amount, v_remaining);
    v_voluntary_amount := greatest(v_payment.amount - v_mandatory_amount, 0);
  else
    v_voluntary_amount := v_payment.amount;
  end if;

  update public.payments
  set status = 'verified',
      verified_by = v_actor,
      verified_at = now(),
      updated_at = now()
  where id = v_payment.id;

  insert into public.payment_verifications (
    payment_id,
    verification_type,
    status,
    verified_by,
    external_reference,
    evidence,
    verified_at
  ) values (
    v_payment.id,
    'manual',
    'verified',
    v_actor,
    v_payment.external_reference,
    jsonb_build_object('admin_action', 'admin_verify_savings_payment'),
    now()
  );

  insert into public.transactions (
    transaction_type,
    source_type,
    source_id,
    profile_id,
    member_id,
    amount,
    approval_status,
    transaction_status,
    initiated_by,
    approved_by,
    approved_at,
    description
  ) values (
    'savings_contribution',
    'payment',
    v_payment.id,
    v_payment.payer_profile_id,
    v_member_id,
    v_payment.amount,
    'approved',
    'posted',
    v_actor,
    v_actor,
    now(),
    'Verified savings payment'
  ) returning id into v_transaction_id;

  if v_mandatory_amount > 0 then
    insert into public.savings_contributions (
      member_id,
      savings_account_id,
      obligation_id,
      amount,
      payment_id,
      transaction_id,
      contribution_type
    ) values (
      v_member_id,
      v_savings_account_id,
      v_obligation.id,
      v_mandatory_amount,
      v_payment.id,
      v_transaction_id,
      'mandatory'
    );

    update public.savings_obligations
    set paid_amount = paid_amount + v_mandatory_amount,
        status = case
          when paid_amount + v_mandatory_amount >= required_amount then 'paid'::public.savings_obligation_status
          else 'partially_paid'::public.savings_obligation_status
        end,
        updated_at = now()
    where id = v_obligation.id;
  end if;

  if v_voluntary_amount > 0 then
    insert into public.savings_contributions (
      member_id,
      savings_account_id,
      obligation_id,
      amount,
      payment_id,
      transaction_id,
      contribution_type
    ) values (
      v_member_id,
      v_savings_account_id,
      null,
      v_voluntary_amount,
      v_payment.id,
      v_transaction_id,
      'voluntary'
    );
  end if;

  insert into public.transaction_entries (
    transaction_id,
    account_id,
    entry_type,
    amount
  ) values
    (v_transaction_id, v_funding_account_id, 'debit', v_payment.amount),
    ((v_transaction_id), (select sa.account_id from public.savings_accounts sa where sa.id = v_savings_account_id), 'credit', v_payment.amount);

  insert into public.audit_logs (
    actor_user_id,
    action,
    entity_type,
    entity_id,
    old_data,
    new_data,
    metadata
  ) values (
    v_actor,
    'SAVINGS_PAYMENT_VERIFIED',
    'payment',
    v_payment.id,
    jsonb_build_object('status', 'pending'),
    jsonb_build_object(
      'status', 'verified',
      'transaction_id', v_transaction_id,
      'mandatory_amount', v_mandatory_amount,
      'voluntary_amount', v_voluntary_amount
    ),
    jsonb_build_object('member_id', v_member_id)
  );

  v_result := jsonb_build_object(
    'payment_id', v_payment.id,
    'member_id', v_member_id,
    'transaction_id', v_transaction_id,
    'amount', v_payment.amount,
    'mandatory_amount', v_mandatory_amount,
    'voluntary_amount', v_voluntary_amount,
    'status', 'verified'
  );

  return v_result;
end;
$$;

revoke all on function public.admin_verify_savings_payment(uuid) from public, anon;
grant execute on function public.admin_verify_savings_payment(uuid) to authenticated;

-- 5. Backfill: Ensure all existing active members have a savings account
do $$
declare
  r record;
begin
  for r in
    select m.id
    from public.members m
    where m.status = 'active'
      and not exists (
        select 1 from public.savings_accounts sa where sa.member_id = m.id and sa.status = 'active'
      )
  loop
    perform private.ensure_member_savings_account(r.id);
  end loop;
end;
$$;
