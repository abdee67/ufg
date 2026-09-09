# Unity Finance — Savings Feature Implementation Prompt

## Role

Act as a senior Flutter + Supabase engineer implementing the **Savings feature** for Unity Finance Group.

Stack:
- Flutter + Dart
- BLoC/Cubit
- Clean Architecture
- GetIt
- GoRouter
- Supabase Auth
- Supabase PostgreSQL
- PostgreSQL RLS
- PostgreSQL RPC/database functions
- Supabase Storage where required
- Supabase scheduled jobs / pg_cron where available

Do **not** introduce NestJS, Express, Node.js, Python, or another backend framework.

Inspect the existing Unity Finance project first. Preserve established conventions where they are sound, but remove legacy customer/client terminology from the older project where it conflicts with Unity Finance.

---
# One important thing

Before creating the savings SQL, we should inspect the MVP schema we already generated rather than blindly creating another set of tables. The savings implementation needs to integrate with:

accounts
transactions
transaction_entries
payments
payment_verifications
financial_rules
financial_rule_versions
audit_logs


# For the database side, I would implement it in this order:
1. Verify existing schema
2. savings_accounts
3. savings_obligations
4. savings_contributions
5. savings_penalties
6. withdrawal_requests
7. savings-related ledger integration
8. financial-rule lookup
9. RLS policies
10. RPCs
11. monthly obligation scheduled job
12. late-penalty scheduled job
13. audit integration
14. database tests


# And the important RPCs should be narrowly defined business commands:
get_my_savings_summary()
get_my_savings_obligations()

submit_savings_payment()
post_verified_savings_contribution()

request_savings_withdrawal()
approve_savings_withdrawal()
reject_savings_withdrawal()
delay_savings_withdrawal()

generate_monthly_savings_obligations()
process_late_savings_obligations()

# 1. Business Rules — Source of Truth

Use the approved Unity Finance Group playbook as the business source of truth.

Savings rules:

1. Every active member must contribute a minimum of **2,000 ETB per month**.
2. Members may contribute more than 2,000 ETB.
3. There is no maximum monthly savings amount.
4. Monthly contribution deadline is the **12th day of each month**.
5. A member who fails to contribute the required 2,000 ETB by the 12th is considered late.
6. A **10% penalty** is charged on the required monthly contribution.
7. Missing the 2,000 ETB contribution therefore creates a 200 ETB penalty.
8. The penalty is charged **once for that missed monthly contribution**.
9. The penalty is recorded separately from savings.
10. Members may request withdrawal of available savings.
11. Savings being used as security for an outstanding loan cannot be withdrawn.
12. The group may temporarily delay a withdrawal when necessary to protect liquidity.
13. Any withdrawal delay must be communicated to the member.
14. Every withdrawal must be recorded in the member transaction history.
15. Savings are member funds and must remain separate from group income.
16. Savings are not share capital. Unity Finance currently has no share system.

Do not invent additional financial policy.

---

# 2. Feature Goal

Implement:

```text
Active Member
    ↓
Monthly Savings Obligation
    ↓
Contribution / Payment
    ↓
Current MVP: Admin Verification
    ↓
Financial Posting
    ↓
Savings Balance
```

Late flow:

```text
Missed Obligation
    ↓
LATE
    ↓
10% One-Time Penalty
    ↓
Penalty recorded separately
```

Withdrawal flow:

```text
Member
    ↓
Withdrawal Request
    ↓
Available Savings Check
    ↓
Secured Savings Check
    ↓
Liquidity Check
    ↓
Admin Review
    ↓
Approve / Delay / Reject
    ↓
Financial Posting
```

---

# 3. Architecture Rules

## Flutter responsibilities

Flutter handles:
- UI
- forms
- BLoC/Cubit state
- navigation
- user-facing validation
- file/presentation concerns
- displaying authoritative data

Flutter must **not** be the authority for:
- savings balance
- late penalty calculation
- withdrawal authorization
- liquidity decisions
- ledger posting
- financial transaction creation

## Supabase responsibilities

Use:
- Supabase Auth for identity/session
- PostgreSQL for persistence/integrity
- RLS for row authorization
- RPC for atomic business commands
- Storage for sensitive documents when needed
- scheduled jobs for monthly obligations/late processing
- Edge Functions for external integrations only

## Critical principle

Never implement:

```dart
balance += amount;
```

as the authoritative financial operation.

Use:

```text
Command
  ↓
RPC
  ↓
Validate
  ↓
Authorize
  ↓
Create financial transaction
  ↓
Ledger entries
  ↓
Audit
  ↓
Return result
```

---

# 4. Existing Tables to Reuse

Use the existing MVP schema where available:

```text
profiles
members
accounts
transactions
transaction_entries
payments
payment_methods
payment_verifications
savings_accounts
savings_obligations
savings_contributions
savings_penalties
withdrawal_requests
financial_rules
financial_rule_versions
audit_logs
```

Do not create duplicate concepts such as:
- customer_savings
- client_balance
- member_balance as a second source of truth

---

# 5. Savings Account

`savings_accounts` represents the member savings account.

Conceptual fields:

```text
id
member_id
account_id
status
created_at
updated_at
```

Constraint:

```text
one savings account per member
```

Statuses:

```text
ACTIVE
SUSPENDED
CLOSED
```

Do not expose an independently editable balance field as the authoritative source.

---

# 6. Monthly Savings Obligations

Create/maintain:

```text
savings_obligations
```

Fields:

```text
id
member_id
period_year
period_month
required_amount
due_date
paid_amount
late_penalty_amount
status
created_at
updated_at
```

Statuses:

```text
PENDING
PARTIALLY_PAID
PAID
LATE
WAIVED
```

Constraint:

```sql
UNIQUE(member_id, period_year, period_month)
```

When creating an obligation, copy the current approved rule values into the obligation.

For example:

```text
September 2026
required_amount = 2000
due_date = 2026-09-12
```

If the minimum saving later changes to 2,500, the old obligation remains 2,000.

---

# 7. Financial Rule Configuration

Use the existing versioned financial-rule system.

Required rule codes:

```text
MONTHLY_MIN_SAVING
SAVING_DUE_DAY
SAVING_LATE_PENALTY_RATE
```

Seed:

```text
MONTHLY_MIN_SAVING = 2000
SAVING_DUE_DAY = 12
SAVING_LATE_PENALTY_RATE = 0.10
```

Do not duplicate these values in multiple functions or Dart files.

Old records use the historical effective rule.

---

# 8. Monthly Obligation Job

Create:

```text
generate_monthly_savings_obligations()
```

It must:

1. Find all active members.
2. Read the active approved minimum-saving rule.
3. Create the current monthly obligation.
4. Calculate the due date from the configured day.
5. Avoid duplicates.
6. Be safe to execute multiple times.

Idempotency requirement:

```text
Run #1 → 1 obligation
Run #2 → 0 duplicates
```

Enforce uniqueness in the database as well as in function logic.

Do not rely on Flutter opening the app.

---

# 9. Late Obligation Processing

Create:

```text
process_late_savings_obligations()
```

Behavior:

1. Find unpaid obligations whose due date has passed.
2. Mark them `LATE`.
3. Create exactly one late penalty.
4. Calculate:

```text
required_amount × 10%
```

5. Record the penalty separately from savings.
6. Post the corresponding financial transaction through the controlled financial workflow.
7. Create an audit record.
8. Be idempotent.

For the current rule:

```text
2,000 × 10% = 200 ETB
```

Never create two penalties for the same obligation.

Use a uniqueness rule such as:

```text
one savings_penalty per savings_obligation
```

---

# 10. Penalty Separation

Do NOT model:

```text
savings = 2200
```

for a missed contribution.

Model:

```text
Savings obligation = 2000
Penalty = 200
```

Financial meaning:

```text
2000 → member savings
200  → group penalty income
```

The total amount owed may be 2,200, but the accounts remain separate.

---

# 11. Contributions

Members can contribute:
- the required 2,000
- less than 2,000 before the deadline if the project explicitly supports partial payments
- more than 2,000

Contribution types:

```text
MANDATORY
VOLUNTARY
ADJUSTMENT
```

The normal contribution flow:

```text
Payment
  ↓
Verification
  ↓
Savings Contribution
  ↓
Financial Transaction
  ↓
Ledger
```

A contribution must link to its payment and transaction.

---

# 12. Contribution Posting RPC

Implement a controlled RPC such as:

```sql
post_verified_savings_contribution(
    p_payment_id uuid
)
```

Responsibilities:

1. Validate payment exists.
2. Validate payment is verified.
3. Validate payment purpose is savings.
4. Validate member is active.
5. Validate payment has not already been posted.
6. Create contribution record.
7. Apply amount toward relevant obligation where applicable.
8. Treat amount above required savings as voluntary savings.
9. Create the financial transaction.
10. Create balanced ledger entries.
11. Record audit information.
12. Commit atomically.

A failure anywhere must roll back the entire operation.

---

# 13. Payment Allocation Ambiguity

The playbook does not define the exact allocation priority when a member owes:
- a missed savings contribution
- a savings late penalty

Do not silently invent a policy.

Keep separate fields/records so the system can represent both.

If an allocation rule is later approved, implement it centrally in the RPC/function layer.

---

# 14. Savings Balance

Authoritative savings balance:

```text
posted member savings contributions
-
posted savings withdrawals
-
valid reversals
```

Do not include:

```text
late penalties
loan service charges
group income
operating expenses
```

Savings and group income must remain separate.

A balance cache/materialized view may be introduced for performance, but it must be derived from posted ledger data.

---

# 15. Secured Savings

The loan system will need to lock savings used as security.

Support a structure such as:

```text
savings_security_locks

id
member_id
loan_id
amount
status
created_at
released_at
```

Possible status:

```text
ACTIVE
RELEASED
```

Savings withdrawal availability:

```text
total savings
-
active secured amount
=
available savings
```

Do not invent a required security percentage unless the loan policy explicitly defines it.

---

# 16. Withdrawals

Members may request withdrawal of available savings.

Create/maintain:

```text
withdrawal_requests
```

Fields:

```text
id
member_id
amount
status
requested_at
reviewed_by
reviewed_at
reason
created_at
updated_at
```

Statuses:

```text
PENDING
APPROVED
REJECTED
PAID
CANCELLED
DELAYED
```

A withdrawal request itself must not immediately reduce savings.

Only the approved and posted financial transaction reduces savings.

---

# 17. Withdrawal Validation RPC

Create:

```text
request_savings_withdrawal()
```

Validate server-side:

```text
member is active
amount > 0
amount <= available savings
secured savings are not being withdrawn
request is still valid
```

Also evaluate the current liquidity policy.

The UI validation is only a convenience. The RPC is authoritative.

---

# 18. Withdrawal Approval

Current MVP:

```text
Member
  ↓
Withdrawal request
  ↓
Admin review
  ↓
Approve / Reject / Delay
```

If delayed:

```text
status = DELAYED
delay reason stored
member notified
```

The playbook permits withdrawal delays when required to protect liquidity.

Do not assume a specific approval count for withdrawals unless separately approved.

---

# 19. Withdrawal Posting

Create controlled operation(s) such as:

```text
approve_savings_withdrawal()
reject_savings_withdrawal()
delay_savings_withdrawal()
post_savings_withdrawal()
```

Recommended MVP path:

```text
PENDING
   ↓
APPROVED
   ↓
POST
   ↓
PAID
```

Posting should:
- validate again
- create balanced ledger entries
- link the transaction to the withdrawal
- write audit data
- be atomic
- prevent duplicate posting

---

# 20. RLS

Enable RLS on all exposed tables.

## Member can read

Only their own:

```text
savings account
savings obligations
savings contributions
savings penalties
withdrawal requests
related payments
financial transaction history
```

## Member may create

```text
payment request
withdrawal request
```

## Member cannot directly

```text
insert ledger entries
update ledger entries
create penalties
change savings balances
approve withdrawals
change financial rules
delete financial transactions
```

## Admin

Access according to explicit RBAC permissions.

Do not use:

```text
authenticated = authorized
```

Do not use editable user metadata as authorization.

---

# 21. Storage

Savings itself does not require a file.

Payment proofs may use the application's private payment-proof bucket.

Any sensitive financial document must:
- be stored in a private bucket
- use RLS/storage policies
- use signed URLs for access where appropriate
- never expose secret/service-role keys

---

# 22. Audit

Create audit records for:

```text
SAVINGS_OBLIGATION_CREATED
SAVINGS_PAYMENT_SUBMITTED
SAVINGS_PAYMENT_VERIFIED
SAVINGS_CONTRIBUTION_POSTED
SAVINGS_LATE_PENALTY_APPLIED
SAVINGS_WITHDRAWAL_REQUESTED
SAVINGS_WITHDRAWAL_APPROVED
SAVINGS_WITHDRAWAL_REJECTED
SAVINGS_WITHDRAWAL_DELAYED
SAVINGS_WITHDRAWAL_POSTED
```

Audit fields should include:

```text
actor
action
entity_type
entity_id
old_data
new_data
timestamp
metadata
```

Audit records must be append-only.

---

# 23. Reversal and Correction

If a contribution or withdrawal is wrong:

Never delete the original transaction.

Use:

```text
Original transaction
      ↓
Reversal
      ↓
Correct transaction
```

The original remains part of the audit history.

---

# 24. Flutter Feature Structure

Implement:

```text
features/
└── savings/
    ├── data/
    │   ├── datasources/
    │   │   └── savings_remote_data_source.dart
    │   ├── models/
    │   │   ├── savings_account_model.dart
    │   │   ├── savings_obligation_model.dart
    │   │   ├── savings_contribution_model.dart
    │   │   ├── savings_penalty_model.dart
    │   │   └── withdrawal_request_model.dart
    │   └── repositories/
    │       └── savings_repository_impl.dart
    │
    ├── domain/
    │   ├── entities/
    │   │   ├── savings_account_entity.dart
    │   │   ├── savings_obligation_entity.dart
    │   │   ├── savings_contribution_entity.dart
    │   │   ├── savings_penalty_entity.dart
    │   │   └── withdrawal_request_entity.dart
    │   ├── repositories/
    │   │   └── savings_repository.dart
    │   └── usecases/
    │       ├── get_savings_summary.dart
    │       ├── get_savings_obligations.dart
    │       ├── get_savings_history.dart
    │       ├── submit_savings_payment.dart
    │       ├── request_savings_withdrawal.dart
    │       ├── cancel_withdrawal_request.dart
    │       └── get_withdrawal_requests.dart
    │
    └── presentation/
        ├── bloc/
        │   ├── savings_bloc.dart
        │   ├── savings_event.dart
        │   └── savings_state.dart
        ├── pages/
        │   ├── savings_page.dart
        │   ├── savings_history_page.dart
        │   ├── savings_obligation_page.dart
        │   ├── withdrawal_page.dart
        │   └── withdrawal_history_page.dart
        └── widgets/
            ├── savings_summary_card.dart
            ├── monthly_obligation_card.dart
            ├── savings_balance_card.dart
            ├── savings_transaction_tile.dart
            ├── withdrawal_request_card.dart
            └── savings_status_chip.dart
```

Use existing equivalent files instead of creating duplicates.

---

# 25. Main Savings Screen

Display:

```text
Savings

Total Savings
ETB 12,000.00

Available to Withdraw
ETB 7,000.00

Secured for Loans
ETB 5,000.00
```

Then the current obligation:

```text
September 2026

Required      2,000 ETB
Paid          2,000 ETB
Status        PAID
```

Late example:

```text
Required      2,000 ETB
Paid              0 ETB
Penalty         200 ETB
Total Due      2,200 ETB
Status           LATE
```

Actions:

```text
Make Contribution
Request Withdrawal
View History
```

Never present secured savings as available for withdrawal.

---

# 26. Withdrawal Screen

Display:

```text
Total Savings
Secured Savings
Available Savings
Requested Amount
```

Validate locally for good UX.

Then always validate again through RPC.

Show clear statuses:

```text
PENDING
APPROVED
DELAYED
REJECTED
PAID
```

If delayed, show the recorded delay reason when permitted.

---

# 27. Repository Rules

Repository methods should express domain commands:

```dart
getSavingsSummary()
getSavingsObligations()
getSavingsHistory()
submitSavingsPayment()
requestWithdrawal()
getWithdrawalRequests()
cancelWithdrawal()
```

Do not make repository code the authoritative calculator for financial policy.

Avoid hardcoding:

```text
2000
10%
12
```

in Dart.

---

# 28. BLoC Rules

BLoC controls UI state only.

Example states:

```text
SavingsInitial
SavingsLoading
SavingsLoaded
SavingsActionInProgress
SavingsActionSuccess
SavingsError
```

After a successful financial mutation:

```text
RPC success
   ↓
refresh authoritative savings data
   ↓
update BLoC
```

Do not mutate an assumed local balance and treat that as final.

---

# 29. Dependency Injection

Register:

```text
Supabase client
Savings remote datasource
Savings repository
Savings use cases
Savings BLoC
```

inside the existing `injection_container.dart`.

Do not bypass the existing DI architecture by creating repositories directly inside widgets.

---

# 30. Routing

Add savings routes using the existing `app_router.dart` and `route_names.dart`.

Recommended:

```text
/savings
/savings/history
/savings/obligation
/savings/withdraw
/savings/withdrawals
```

Protect routes using authentication/member state as appropriate.

---

# 31. Scheduled Processing

Create database/scheduled jobs for:

```text
generate_monthly_savings_obligations
process_late_savings_obligations
```

Later notification jobs may support:

```text
saving_due_reminder
saving_late_notification
withdrawal_status_notification
```

All scheduled jobs must be idempotent.

---

# 32. Errors

Map backend errors to domain failures.

Examples:

```text
MemberNotActive
SavingsAccountNotFound
PaymentNotVerified
PaymentAlreadyPosted
ObligationAlreadyPaid
InvalidContributionAmount
WithdrawalExceedsAvailableSavings
SavingsSecuredForLoan
LiquidityInsufficient
WithdrawalAlreadyProcessed
UnauthorizedAction
```

Do not expose raw PostgreSQL errors directly to users.

---

# 33. Testing Requirements

## Database tests

Test:

```text
one obligation per member/month
monthly obligation generation is idempotent
late penalty is 10%
late penalty is created once
penalty is separate from savings
verified contribution posts once
duplicate payment cannot post twice
withdrawal cannot exceed available savings
secured savings cannot be withdrawn
withdrawal cannot be approved twice
posted financial transaction balances
reversal preserves original
```

## RLS tests

Verify:

```text
Member A cannot read Member B savings.
Member cannot modify savings balance.
Member cannot insert ledger entries.
Member cannot create penalties.
Member cannot approve another member's withdrawal without permission.
Anonymous user cannot access savings.
```

## Flutter tests

Test:

```text
Savings loaded state
Late obligation rendering
Penalty rendering
Withdrawal form validation
RPC failure handling
Successful mutation refresh
```

---

# 34. Acceptance Criteria

The implementation is complete when:

### Member

```text
1. Member can open Savings.
2. Member sees total savings.
3. Member sees available savings.
4. Member sees secured savings.
5. Member sees current monthly obligation.
6. Member sees contribution history.
7. Member can submit a savings payment.
8. Verified savings payment posts correctly.
9. Member may contribute more than 2,000 ETB.
10. Missed obligation gets one 10% penalty.
11. Penalty is displayed separately.
12. Member can request available savings withdrawal.
13. Withdrawal cannot exceed available savings.
14. Secured savings cannot be withdrawn.
15. Member sees withdrawal status.
```

### Admin

```text
16. Admin can view authorized savings information.
17. Admin can verify savings payments.
18. Admin can review withdrawals.
19. Admin can approve/reject/delay withdrawals.
20. Approved withdrawal posts financially.
21. Delayed withdrawal stores a reason.
```

### System

```text
22. Monthly obligations are generated automatically.
23. Obligation job is idempotent.
24. Penalty job is idempotent.
25. Financial operations create transaction/reference records.
26. Posted financial records cannot be hard deleted.
27. Corrections use reversal/correction transactions.
28. Savings remain separate from group income.
29. RLS prevents cross-member access.
30. Critical actions are audited.
```

---

# 35. Do Not Invent These Policies

The playbook does not explicitly define:

1. Payment allocation priority between missed savings and the penalty.
2. Exact treatment of multiple missed months beyond one penalty per missed obligation.
3. Exact liquidity formula for approving withdrawals.
4. Number of approvals required for savings withdrawals.
5. Exact partial-payment policy before/after the deadline.
6. Exact relationship between the 500 ETB membership fee/first contribution and the savings account.

Do not fill these gaps with arbitrary assumptions.

Implement clean extension points and document the ambiguity.

---

# 36. Implementation Sequence

Implement in this order:

```text
1. Inspect current Unity Finance codebase.
2. Review existing MVP SQL/schema before changing anything.
3. Add/fix savings tables and constraints.
4. Add/version savings rules.
5. Implement RLS.
6. Implement savings read queries/views.
7. Implement monthly obligation RPC/job.
8. Implement late penalty RPC/job.
9. Implement contribution posting RPC.
10. Implement withdrawal request RPC.
11. Implement withdrawal approval/rejection/delay/posting RPCs.
12. Implement audit logging.
13. Register scheduled jobs.
14. Implement Flutter entities/models.
15. Implement remote datasource.
16. Implement repository.
17. Implement use cases.
18. Implement BLoC.
19. Implement screens/widgets.
20. Register dependencies.
21. Register routes.
22. Add automated tests.
23. Perform end-to-end testing.
24. Report all changed files, SQL objects, policies, functions, jobs and tests.
```

---

# 37. Definition of Done

Do not stop at code generation.

Before declaring the feature complete:

- [ ] SQL migration applied successfully
- [ ] RLS policies verified
- [ ] RPCs tested
- [ ] Scheduled jobs tested
- [ ] Idempotency tested
- [ ] Savings contribution flow tested
- [ ] Late penalty tested
- [ ] Withdrawal flow tested
- [ ] Secured savings restriction tested
- [ ] Financial transaction integrity tested
- [ ] Audit logging tested
- [ ] Flutter screens integrated
- [ ] BLoC tests pass
- [ ] Cross-member RLS tests pass
- [ ] No secrets exposed to Flutter
- [ ] Existing authentication/membership functionality still works
- [ ] No duplicate legacy customer/client savings models were introduced

Provide a final implementation report with:

```text
Files changed
Database tables changed
RPCs created/changed
RLS policies created/changed
Scheduled jobs created
Tests executed
Known unresolved business-policy decisions
```

The final implementation must preserve the principle:

```text
Flutter requests an operation.
Supabase validates and authorizes it.
PostgreSQL performs the atomic financial operation.
Ledger records the financial effect.
Audit records the action.
Flutter displays the authoritative result.
```
