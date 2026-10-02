# Unity Finance — Notification Domain Integration Snippets

These snippets show where the existing Savings, Loans, Payments, Expenses and Membership RPCs should call the notification primitives from `20260929000038_notification_infrastructure_v1.sql`.

Do not call these from Flutter.

> **Delivery note (2026-09-29):** this integration is delivered by
> `20260929000039_notification_domain_integration_v1.sql` using AFTER triggers on
> the workflow tables (`payments`, `withdrawal_requests`, `loan_applications`,
> `outsider_loan_applications`, `member_loan_guarantors`,
> `outsider_loan_guarantors`, `loan_repayment_submissions`, `expenses`,
> `membership_applications`, `loan_default_events`) instead of rewriting the
> large financial RPCs. The snippets below remain the reference for how each
> notification is shaped, and the permission codes have been corrected against
> the live RBAC definitions. Every trigger function degrades to a WARNING so a
> notification failure can never roll back a financial command.

---

## 1. Savings payment rejected

Place after the payment status has been changed to `rejected`, rejection reason recorded and audit event written, but before the RPC returns.

```sql
perform private.create_notification_v1(
  v_payment.payer_profile_id,
  'payment',
  'payment.rejected',
  'Payment rejected',
  format(
    'Payment %s was rejected. Open Unity Finance to review the reason.',
    v_payment.reference_number
  ),
  'high',
  jsonb_build_object(
    'target_type', 'payment',
    'payment_id', v_payment.id,
    'payment_reference', v_payment.reference_number,
    'reason', v_payment.rejection_reason
  ),
  'payment',
  v_payment.id,
  'payment:rejected:' || v_payment.id::text
);
```

Do not put a public Storage URL into the push payload for a payment proof.

---

## 2. Savings withdrawal requested

After the withdrawal request is successfully persisted:

```sql
perform private.notify_users_with_permission_v1(
  'savings.withdraw.approve',  -- verified live permission code (NOT 'savings.withdrawal.view')
  'savings',
  'savings.withdrawal_requested',
  'Savings withdrawal requested',
  format(
    'A savings withdrawal request %s is awaiting review.',
    v_withdrawal.reference_number
  ),
  'high',
  jsonb_build_object(
    'target_type', 'withdrawal',
    'withdrawal_id', v_withdrawal.id,
    'withdrawal_reference', v_withdrawal.reference_number,
    'member_id', v_withdrawal.member_id
  ),
  'savings_withdrawal',
  v_withdrawal.id,
  'withdrawal:requested:' || v_withdrawal.id::text,
  v_actor
);
```

The existing migration's exact withdrawal permission names should be used. If your final RBAC migration uses a different code, substitute that code rather than inventing a second permission.

---

## 3. Loan application submitted

After the loan application commits its domain state:

```sql
perform private.notify_users_with_permission_v1(
  'loan.review',
  'loan',
  'loan.application_submitted',
  'New loan application',
  format(
    'Loan application %s is awaiting review.',
    v_application.application_number
  ),
  'high',
  jsonb_build_object(
    'target_type', 'loan_application',
    'application_id', v_application.id,
    'application_number', v_application.application_number,
    'borrower_type', v_application.borrower_type,
    'member_id', v_application.member_id
  ),
  'loan_application',
  v_application.id,
  'loan_application:submitted:' || v_application.id::text,
  v_actor
);
```

The actor exclusion prevents the submitting admin from receiving their own administrative alert.

---

## 4. Guarantor request

For an outsider or member loan that requires an active member guarantor, notify the guarantor directly after the request is successfully created:

```sql
perform private.create_notification_v1(
  v_guarantor_profile_id,
  'loan',
  'loan.guarantor_required',
  'Guarantor approval required',
  format(
    'You have been requested as guarantor for loan application %s.',
    v_application.application_number
  ),
  'critical',
  jsonb_build_object(
    'target_type', 'loan_application',
    'application_id', v_application.id,
    'application_number', v_application.application_number,
    'guarantor_request_id', v_guarantor_request.id
  ),
  'loan_application',
  v_application.id,
  'guarantor:requested:' || v_guarantor_request.id::text
);
```

---

## 5. Guarantor response

When the guarantor accepts or rejects:

```sql
perform private.create_notification_v1(
  v_borrower_profile_id,
  'loan',
  case
    when p_decision = 'accepted' then 'loan.guarantor_accepted'
    else 'loan.guarantor_rejected'
  end,
  case
    when p_decision = 'accepted' then 'Guarantor accepted'
    else 'Guarantor rejected'
  end,
  case
    when p_decision = 'accepted'
      then format('Your guarantor has accepted loan application %s.', v_application.application_number)
    else
      format('Your guarantor has rejected loan application %s.', v_application.application_number)
  end,
  'high',
  jsonb_build_object(
    'target_type', 'loan_application',
    'application_id', v_application.id,
    'application_number', v_application.application_number
  ),
  'loan_application',
  v_application.id,
  'guarantor:decision:' || v_guarantor_request.id::text
);
```

---

## 6. Loan approval/rejection

Loan approval/rejection is a business-state event, not necessarily a new financial transaction.

Notify the borrower directly from `review_loan_application_v3(...)` after the decision is committed:

```sql
perform private.create_notification_v1(
  v_borrower_profile_id,
  'loan',
  case when p_decision = 'approved' then 'loan.approved' else 'loan.rejected' end,
  case when p_decision = 'approved' then 'Loan approved' else 'Loan not approved' end,
  case
    when p_decision = 'approved'
      then format('Loan application %s has been approved.', v_application.application_number)
    else
      format('Loan application %s was not approved. Open Unity Finance to review the details.', v_application.application_number)
  end,
  'high',
  jsonb_build_object(
    'target_type', 'loan_application',
    'application_id', v_application.id,
    'application_number', v_application.application_number,
    'decision', p_decision
  ),
  'loan_application',
  v_application.id,
  'loan:decision:' || v_application.id::text
);
```

Do not use the notification payload as the authoritative approved amount. The loan detail screen must reload authoritative values from Supabase.

---

## 7. Serious loan default

When `process_serious_loan_defaults_v3()` records a serious default event, notify:

- borrower;
- guarantor where applicable;
- relevant loan-review administrators.

Use separate recipient notifications with separate dedupe keys.

> **Schema correction:** `public.loans` has no `loan_reference` column. The
> delivered implementation (migration 39) emits this from the
> `public.loan_default_events` trigger and identifies the loan by `loan_id` plus
> the `application_number` resolved from `loan_applications` /
> `outsider_loan_applications`. Never reference a column that is not in the live
> schema.

```sql
perform private.create_notification_v1(
  v_borrower_profile_id,
  'loan',
  'loan.serious_default',
  'Loan requires urgent attention',
  format(
    'Loan %s has reached the serious-default threshold. Open Unity Finance to review the required action.',
    v_application_number
  ),
  'critical',
  jsonb_build_object(
    'target_type', 'loan',
    'loan_id', v_loan.id,
    'loan_reference', v_loan.loan_reference
  ),
  'loan',
  v_loan.id,
  'loan:serious-default:borrower:' || v_loan.id::text
);
```

For guarantor/admin notifications, use their own profile IDs and dedupe keys.

---

## 8. Expense submitted

After `admin_create_expense_v1(...)` creates the pending expense:

```sql
perform private.notify_users_with_permission_v1(
  'expense.view',
  'system',
  'expense.submitted',
  'Expense submitted',
  format(
    'Expense %s is awaiting review.',
    v_expense.reference_number
  ),
  'normal',
  jsonb_build_object(
    'target_type', 'expense',
    'expense_id', v_expense.id,
    'expense_reference', v_expense.reference_number
  ),
  'expense',
  v_expense.id,
  'expense:submitted:' || v_expense.id::text,
  v_actor
);
```

---

## 9. Expense approval/rejection

Notify the requester directly.

```sql
perform private.create_notification_v1(
  v_expense.requested_by,
  'system',
  case when p_decision = 'approved' then 'expense.approved' else 'expense.rejected' end,
  case when p_decision = 'approved' then 'Expense approved' else 'Expense rejected' end,
  case
    when p_decision = 'approved'
      then format('Expense %s was approved.', v_expense.reference_number)
    else
      format('Expense %s was rejected. Open the admin panel to review the reason.', v_expense.reference_number)
  end,
  'normal',
  jsonb_build_object(
    'target_type', 'expense',
    'expense_id', v_expense.id,
    'expense_reference', v_expense.reference_number
  ),
  'expense',
  v_expense.id,
  'expense:decision:' || v_expense.id::text
);
```

---

## 10. Transaction-posted notification is automatic

Do **not** add another member notification call inside every financial posting RPC unless there is a special copy/routing requirement.

The infrastructure migration already adds:

```text
public.transactions
       |
       +--> AFTER INSERT / meaningful UPDATE
               |
               +--> private.notify_transaction_transition_v1()
                       |
                       +--> private.create_notification_v1()
```

This covers the current transaction-based notification family:

```text
savings contribution
savings withdrawal
savings late penalty
loan disbursement
loan repayment
loan late penalty
membership fee
first contribution
reversal
```

This is deliberate. One central transaction boundary prevents different financial modules from slowly developing five incompatible notification systems.
