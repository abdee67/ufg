# Unity Finance — Loan Feature Intensive Implementation Plan

## Purpose

Implement the complete Unity Finance **Loan domain** on top of:

- Flutter + Dart
- BLoC/Cubit
- Clean Architecture
- GetIt
- GoRouter
- Supabase Auth
- Supabase PostgreSQL
- PostgreSQL RLS
- PostgreSQL RPC/database functions
- Supabase Edge Functions where external integrations are required
- Supabase scheduled jobs / pg_cron where available

There is **no NestJS / Express / standalone Node backend** in this architecture.

This document covers both:

1. Backend/domain implementation
2. Flutter member + admin implementation

The loan backend must be implemented and tested before building the full Flutter UI.

---

# 1. Source of Truth

Use the approved Unity Finance Group Savings & Lending Rules playbook as the business source of truth.

Loan rules explicitly defined by the playbook:

- Only active members who have saved for at least 2 months may normally apply for a member loan.
- Member must have no overdue loan.
- Member must have fulfilled required monthly contribution.
- Loans are granted only when sufficient funds are available.
- Meeting eligibility does not guarantee approval.
- Member loan has a **10% one-time service charge** calculated from original principal.
- Non-member/outsider loan has a **15% one-time service charge** calculated from original principal.
- Outsider must have an active member guarantor.
- Maximum loan amount is initially **20,000 ETB**.
- Actual approved amount depends on savings, repayment capacity and available group funds.
- Management may lower the practical limit when liquidity is insufficient.
- Loan must not be approved if it would breach required liquidity reserve.
- Standard repayment period is **3 months** with 3 scheduled monthly repayments.
- Early repayment has no additional early-repayment penalty.
- Late installment attracts a **5% penalty on the overdue installment**, charged once.
- Borrower may request extension before serious default; extension requires authorized approval.
- Loan becomes seriously overdue when an installment remains unpaid for **60 days** after due date.
- Serious default triggers formal notice, guarantor notification where applicable, temporary borrowing ineligibility, and possible recovery from eligible savings/security and/or guarantor.
- Outsider guarantor must be an active member.
- Guarantor must have sufficient savings/security according to group requirements.
- A member may guarantee at most one outstanding outsider loan at a time.
- Guarantor must approve electronically.
- At least **two authorized people must approve a loan**.
- No person may approve their own loan.
- Loan approval and disbursement must be electronically recorded.
- The person approving the loan should not be the only person capable of releasing funds.
- Group must maintain a **minimum 30% liquidity reserve**.
- Protecting member savings takes priority over issuing new loans.
- Every financial transaction must be recorded and auditable.
- Financial records must not be hard-deleted; corrections use reversal/correction transactions.

Do not silently invent missing financial policy.

---

# 2. Core Loan Lifecycle

```text
Application
    ↓
Eligibility Evaluation
    ↓
Guarantor (outsider only)
    ↓
Under Review
    ↓
Liquidity Evaluation
    ↓
Approval #1
    ↓
Approval #2
    ↓
Approved
    ↓
Disbursement Authorization
    ↓
Disbursement
    ↓
ACTIVE
    ↓
Scheduled Repayments
    ├── Paid on time
    ├── Early repayment
    ├── Overdue
    └── Serious Default after 60 days
    ↓
PAID / DEFAULTED / RECOVERED
```

Important distinction:

```text
Eligibility ≠ Approval
Approval ≠ Disbursement
Disbursement ≠ Repayment
Repayment ≠ Ledger balance mutation
```

Each stage must have its own controlled transition.

---

# 3. Loan Types

Create two loan products:

```text
MEMBER_LOAN
OUTSIDER_LOAN
```

## Member loan

```text
Service charge = 10%
Maximum principal = 20,000 ETB
Term = 3 months
```

## Outsider loan

```text
Service charge = 15%
Maximum principal = 20,000 ETB
Term = 3 months
Guarantor = required
```

Product values must come from versioned database rules/product configuration, not hardcoded Flutter constants.

---

# 4. Financial Model

For a member loan:

```text
Principal = 6,000
Service charge = 600
Total repayment = 6,600
```

Three repayments:

```text
2,200
2,200
2,200
```

For an outsider loan:

```text
Principal = 6,000
Service charge = 900
Total repayment = 6,900
```

The 10% / 15% charge is:

```text
one-time
calculated from original principal
```

It is not a conventional interest-amortization engine.

Do not implement reducing-balance or compound-interest logic for the current playbook.

---

# 5. Money Representation

Use:

```text
PostgreSQL numeric(18,2)
```

for ETB monetary values.

Never use floating-point values as the authoritative money representation.

Core financial calculations should preferably happen inside PostgreSQL.

---

# 6. Existing Database Objects

Reuse:

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

audit_logs

financial_rules
financial_rule_versions
```

Do not create duplicate systems such as `loan_balances` that compete with the ledger.

---

# 7. Loan Tables

## `loan_products`

Conceptual fields:

```text
id
code
name
borrower_type
service_charge_rate
max_amount
term_months
active
created_at
updated_at
```

Initial products:

```text
MEMBER_LOAN
OUTSIDER_LOAN
```

## `loan_applications`

Fields:

```text
id
application_number
applicant_profile_id
member_id nullable
loan_product_id
requested_amount
purpose
eligibility_status
eligibility_snapshot
status
submitted_at
reviewed_at
created_at
updated_at
```

Statuses:

```text
DRAFT
SUBMITTED
ELIGIBLE
INELIGIBLE
UNDER_REVIEW
APPROVED
REJECTED
CANCELLED
EXPIRED
```

Do not allow arbitrary status updates. Implement a state transition function.

---

# 8. Eligibility Snapshot

When eligibility is evaluated, save the result.

Example:

```json
{
  "active_member": true,
  "minimum_saving_history": true,
  "monthly_contribution_current": true,
  "no_overdue_loan": true,
  "maximum_amount_check": true,
  "liquidity_check": true
}
```

This preserves why an application was eligible/ineligible even if future rules change.

---

# 9. Loan Eligibility Engine

Create a controlled database function such as:

```text
evaluate_loan_application_eligibility(application_id)
```

For a member loan, check:

```text
1. Member exists.
2. Member is ACTIVE.
3. Member has saved for at least 2 months.
4. Member has no overdue loan.
5. Current mandatory monthly contribution is fulfilled.
6. Requested amount <= configured maximum.
7. Basic affordability/repayment-capacity policy if configured.
8. Group funds/liquidity are sufficient.
```

For an outsider loan, check at minimum:

```text
1. Applicant exists.
2. Applicant is not already a member if the product is outsider-only.
3. Active guarantor exists.
4. Guarantor is ACTIVE.
5. Guarantor has sufficient eligible savings/security under configured policy.
6. Guarantor is not already guaranteeing another outstanding outsider loan.
7. Requested amount <= configured maximum.
8. Group funds/liquidity are sufficient.
```

Return structured reasons, not only a boolean.

Example:

```json
{
  "eligible": false,
  "reasons": [
    {
      "code": "OVERDUE_LOAN",
      "message": "Applicant has an overdue loan."
    }
  ]
}
```

---

# 10. Eligibility ≠ Approval

Do not encode eligibility as approval.

```text
eligible = may proceed to review
```

The authorized reviewers still decide the loan.

---

# 11. Repayment Capacity

The playbook says actual approved amount depends partly on repayment capacity but does not specify an exact formula.

Therefore:

- Create a configurable extension point.
- Do not invent an income-to-loan formula.
- Do not hardcode a debt-to-income ratio.
- If not configured, return `MANUAL_REVIEW` / `NOT_CONFIGURED` instead of pretending it was calculated.

Suggested future object:

```text
loan_risk_checks
```

with:

```text
check_code
status
value
reason
checked_at
```

---

# 12. Guarantor

## `loan_guarantors`

Fields:

```text
id
loan_application_id
guarantor_member_id
guaranteed_amount
status
requested_at
approved_at
rejected_at
released_at
created_at
updated_at
```

Statuses:

```text
REQUESTED
ACCEPTED
REJECTED
REPLACED
RELEASED
```

MVP constraint:

```text
one guarantor per outsider loan
```

---

# 13. Guarantor Eligibility

Before requesting a guarantee:

```text
guarantor must:
- be ACTIVE
- have sufficient eligible savings/security
- not already guarantee another outstanding outsider loan
- not equal borrower
```

The exact security amount formula is not specified by the playbook. Make it configurable.

---

# 14. Guarantor Approval

The guarantor must see:

```text
Borrower name
Loan amount
Service charge
Total repayment
Repayment period
Monthly installment
Potential responsibility
```

The guarantor then:

```text
Accept
Reject
```

Store:

```text
guarantor_member_id
timestamp
decision
```

The electronic decision is a permanent business record.

---

# 15. Guarantor Responsibility

Do not release guarantor responsibility simply because a loan was approved.

It remains until:

```text
loan fully repaid
OR
approved replacement guarantor
```

Represent this in the database.

---

# 16. One-Outstanding-Guarantee Rule

Enforce:

```text
one active guarantor assignment per member
for outstanding outsider loans
```

Prefer a database-level partial unique index or equivalent transaction-safe constraint.

Do not enforce this only in Flutter.

---

# 17. Loan Approvals

## `loan_approvals`

Fields:

```text
id
loan_application_id
approver_profile_id
decision
comment
decided_at
created_at
```

Constraint:

```text
unique(loan_application_id, approver_profile_id)
```

Decisions:

```text
APPROVED
REJECTED
```

---

# 18. Two-Person Approval

A loan becomes approved only when:

```text
two distinct authorized approvers
```

have approved it.

A person cannot approve their own loan.

Prevent duplicate approval by the same person.

---

# 19. Approval RPC

Create:

```text
approve_loan_application(application_id)
```

Responsibilities:

1. Derive caller from `auth.uid()`.
2. Verify permission.
3. Verify caller is not borrower.
4. Verify no prohibited conflict.
5. Verify application is reviewable.
6. Record approval.
7. Determine whether the two-approval threshold is met.
8. Set application to `APPROVED` only when threshold is met.
9. Create audit event.
10. Return approval state.

Do not trust a caller-supplied approver identity.

---

# 20. Rejection

Create:

```text
reject_loan_application(application_id, reason)
```

Requirements:

```text
reason required
stored
audited
application in reviewable state
```

---

# 21. Loan Record

Create `loans` when an approved application moves into the loan lifecycle.

Fields:

```text
id
loan_number
loan_application_id
borrower_profile_id
member_id nullable
principal
service_charge_rate
service_charge_amount
total_repayment
term_months
status
disbursed_at
maturity_date
created_at
updated_at
```

Statuses:

```text
APPROVED
READY_FOR_DISBURSEMENT
ACTIVE
PAID
OVERDUE
DEFAULTED
CANCELLED
RECOVERED
```

---

# 22. Service Charge Snapshot

Store at origination:

```text
principal
service_charge_rate
service_charge_amount
total_repayment
```

Existing loans must never be recalculated using a newer service-charge rule.

---

# 23. Repayment Schedule

## `loan_installments`

Fields:

```text
id
loan_id
installment_number
due_date
principal_amount
service_charge_amount
total_due
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
OVERDUE
DEFAULTED
```

Current MVP:

```text
3 monthly installments
```

---

# 24. Schedule Generation

For a 6,000 member loan:

```text
Principal = 6,000
Service charge = 600
Total = 6,600

Installment 1 = 2,200
Installment 2 = 2,200
Installment 3 = 2,200
```

Generate from the actual stored values. Do not hardcode the example.

Handle rounding deterministically.

---

# 25. Disbursement

Disbursement is its own controlled operation:

```text
READY_FOR_DISBURSEMENT
    ↓
Final validation
    ↓
Liquidity check
    ↓
Financial posting
    ↓
Loan ACTIVE
```

At disbursement, re-check:

```text
loan approved
required approvals still valid
guarantor still valid where applicable
liquidity still sufficient
not already disbursed
```

---

# 26. Final Liquidity Gate

The 30% liquidity rule must be checked immediately before disbursement.

Example race:

```text
Loan A approved Monday
Loan B disbursed Tuesday
Loan A disbursement Wednesday
```

Wednesday's final validation must use current financial state.

---

# 27. Disbursement Authorization

Keep separate permissions:

```text
loan.approve
loan.disburse
```

Approval must not automatically mean money release.

For stronger separation later, require different staff members for approval and disbursement.

---

# 28. Disbursement Ledger

Conceptually:

```text
Loan Receivable     DEBIT principal
Cash/Bank/Wallet    CREDIT principal
```

Service charge income must be represented separately according to the chart-of-accounts design.

Never use member savings as a fake loan-disbursement balance.

---

# 29. Repayment

Create a controlled RPC such as:

```text
post_loan_repayment(payment_id, installment_id)
```

It must:

1. Validate payment exists.
2. Validate payment status.
3. Validate payer/borrower relationship.
4. Validate loan state.
5. Determine outstanding installment.
6. Apply payment.
7. Post ledger.
8. Update installment.
9. Mark loan `PAID` when all obligations are settled.
10. Audit.
11. Prevent duplicate posting.

Everything must be atomic.

---

# 30. Early Repayment

Early repayment is allowed with **no additional early-repayment penalty**.

Support:

```text
one installment early
multiple installments
full outstanding loan
```

Do not invent an early-payment discount.

The playbook does not specify detailed multi-installment allocation. If the group has not approved a policy, use a documented deterministic policy such as earliest outstanding installment first, or mark allocation as pending policy before production.

---

# 31. Late Installment

An installment is late when it is unpaid by its due date.

Current penalty:

```text
5% × overdue installment
```

Charged once.

Example:

```text
Installment = 2,200
Penalty = 110
```

Keep penalty separate from the installment amount.

---

# 32. Late-Penalty Processing

Create a scheduled function:

```text
process_overdue_loan_installments()
```

It should:

1. Find unpaid installments after due date.
2. Mark them overdue.
3. Create one 5% penalty.
4. Post penalty income.
5. Notify borrower.
6. Be idempotent.

Do not create a new penalty every day.

---

# 33. Serious Default

Use the installment due date:

```text
current date >= installment due date + 60 days
```

Not the loan creation date.

---

# 34. Default Workflow

```text
OVERDUE
   ↓
SERIOUS DEFAULT
   ↓
Formal borrower notification
   ↓
Guarantor notification
   ↓
New borrowing blocked
   ↓
Recovery assessment
```

Record every action.

---

# 35. Default Events

## `loan_default_events`

Fields:

```text
id
loan_id
installment_id nullable
event_type
event_date
notes
created_by
created_at
```

Events:

```text
DEFAULT_NOTICE
GUARANTOR_NOTICE
BORROWING_SUSPENDED
SECURITY_RECOVERY_STARTED
GUARANTOR_RECOVERY_STARTED
RECOVERY_COMPLETED
```

---

# 36. Recovery

Possible recovery sources:

```text
eligible savings/security
guarantor
```

The playbook does not define exact enforcement priority or legal mechanics.

Create:

## `loan_recovery_events`

```text
id
loan_id
source_type
source_id
amount
reason
status
approved_by
transaction_id
created_at
```

Potential source types:

```text
SAVINGS_SECURITY
GUARANTOR
OTHER_APPROVED
```

Do not automatically debit a guarantor without an approved business/legal policy.

---

# 37. Savings Security Integration

The savings module should expose security locks to the loan module.

Expected relationship:

```text
loan
  ↓
security lock
  ↓
member savings
```

Possible functions:

```text
lock_savings_as_security()
release_savings_security()
```

Exact security ratio remains configurable until formally approved.

---

# 38. Extensions

The playbook allows an extension request before serious default and requires authorized committee approval.

Create:

## `loan_extension_requests`

```text
id
loan_id
requested_by
reason
requested_due_date
status
reviewed_by
reviewed_at
created_at
```

Statuses:

```text
PENDING
APPROVED
REJECTED
CANCELLED
```

Keep the feature disabled until the business approves the exact extension policy.

---

# 39. Borrowing Restriction

Seriously overdue/defaulted borrowers become temporarily ineligible for new borrowing.

The eligibility RPC must check current default status.

Do not represent this only as a Flutter boolean.

---

# 40. Loan State Machine

Enforce valid transitions:

```text
DRAFT
  ↓
SUBMITTED
  ↓
ELIGIBLE / INELIGIBLE
  ↓
UNDER_REVIEW
  ├── REJECTED
  └── APPROVED
          ↓
     READY_FOR_DISBURSEMENT
          ↓
       ACTIVE
          ├── PAID
          ├── OVERDUE
          └── DEFAULTED
                   ↓
                RECOVERED
```

Block arbitrary transitions such as:

```text
REJECTED → APPROVED
PAID → ACTIVE
DEFAULTED → DRAFT
```

unless an explicitly approved restructuring workflow exists.

---

# 41. Loan Cancellation

Cancellation is only for pre-disbursement applications/loans.

Once funds are disbursed, do not use cancellation as a financial undo mechanism. Use repayment/reversal/recovery workflows.

---

# 42. Liquidity Model

Expose:

```text
Total Member Savings
Available Cash
Outstanding Loans
Loanable Funds
Liquidity Reserve
Overdue Loans
```

The system must protect the minimum 30% reserve.

Protecting member savings takes priority over new lending.

---

# 43. Liquidity Snapshot Function

Create:

```text
get_liquidity_snapshot()
```

Return conceptually:

```json
{
  "total_member_savings": 0,
  "available_cash": 0,
  "outstanding_loans": 0,
  "required_reserve": 0,
  "loanable_funds": 0,
  "overdue_loans": 0,
  "reserve_compliant": true
}
```

The exact formula must follow the approved financial/liquidity policy. Do not invent a misleading formula merely to fill dashboard cards.

---

# 44. Atomic Loan Approval

Loan approval may touch:

```text
application
approval records
status
audit log
```

Use one database transaction.

Do not spread this across independent browser mutations.

---

# 45. Atomic Disbursement

Disbursement should atomically:

```text
validate approval
validate liquidity
create/retrieve loan
create disbursement transaction
post ledger
mark loan active
generate installments
create audit event
```

Any failure rolls back the whole operation.

---

# 46. Idempotency

These commands must be safe against duplicate requests:

```text
approve_loan_application()
reject_loan_application()
accept_guarantee()
post_loan_disbursement()
post_loan_repayment()
apply_loan_late_penalty()
```

Use unique references, state checks, constraints and transactions.

Two taps must not create two disbursements.

---

# 47. Concurrency

Explicitly handle:

```text
Two admins approving simultaneously
Two admins disbursing simultaneously
Two applications using the same guarantor simultaneously
Two payments posting against the same installment
Withdrawal and disbursement happening at once
```

Use:

- database constraints
- transactional locking where appropriate
- unique keys
- state conditions inside the transaction

UI disabling is not a concurrency control mechanism.

---

# 48. Audit Events

At minimum:

```text
LOAN_APPLICATION_SUBMITTED
LOAN_ELIGIBILITY_EVALUATED
GUARANTOR_REQUESTED
GUARANTOR_ACCEPTED
GUARANTOR_REJECTED

LOAN_APPROVAL_GRANTED
LOAN_APPROVAL_REJECTED
LOAN_APPROVED
LOAN_REJECTED

LOAN_DISBURSED

INSTALLMENT_CREATED
INSTALLMENT_PAID
INSTALLMENT_OVERDUE
LOAN_LATE_PENALTY_APPLIED

LOAN_EXTENSION_REQUESTED
LOAN_EXTENSION_APPROVED
LOAN_EXTENSION_REJECTED

LOAN_DEFAULTED

LOAN_SECURITY_LOCKED
LOAN_SECURITY_RELEASED

LOAN_RECOVERY_STARTED
LOAN_RECOVERY_COMPLETED

LOAN_PAYMENT_REVERSED
```

---

# 49. Admin Loan Navigation

```text
Loans
├── Overview
├── Applications
├── Pending Approvals
├── Ready for Disbursement
├── Active Loans
├── Repayments
├── Overdue
├── Defaults
├── Guarantors
├── Recovery
└── Transactions
```

---

# 50. Admin Loan Overview

Show:

```text
Active Loans
Total Outstanding
Loans This Month
Repayments This Month
Overdue Loans
Defaulted Loans
Pending Applications
Pending Approvals
Ready for Disbursement
```

Liquidity summary:

```text
Available Cash
Total Member Savings
Required Reserve
Loanable Funds
```

---

# 51. Applications Inbox

Columns:

```text
Application #
Applicant
Type
Requested Amount
Guarantor
Eligibility
Submitted
Status
```

Filters:

```text
Member / Outsider
Status
Eligibility
Amount range
Date
Search
```

Use server-side filtering and pagination.

---

# 52. Application Detail

Show:

```text
Applicant identity
Member status
Loan type
Requested amount
Service charge rate
Service charge amount
Total repayment
Term
Monthly installment
Eligibility results
Savings summary
Existing loan status
Guarantor
Approval history
```

For outsider:

```text
Guarantor details
Guarantor security summary
Guarantee status
```

---

# 53. Approval UI

Show two explicit approval slots:

```text
Approval 1
Approved by:
Date:
Decision:

Approval 2
Approved by:
Date:
Decision:
```

Until two distinct approvals exist:

```text
UNDER_REVIEW
```

After two approvals:

```text
APPROVED
```

Never present a misleading final-approved state after approval #1.

---

# 54. Ready-for-Disbursement Queue

Show:

```text
Loan
Borrower
Approved amount
Approvers
Approval date
Guarantor state
Current liquidity
```

Before disbursement run:

```text
FINAL LIQUIDITY CHECK
```

Then:

```text
[ Disburse Loan ]
```

Require explicit confirmation.

---

# 55. Disbursement Confirmation

Show:

```text
Borrower
Principal
Service charge
Total repayment
Term
Installments
Current liquidity
Liquidity after disbursement
```

Example UI values must be calculated from actual loan data, not hardcoded.

---

# 56. Active Loans

Table:

```text
Loan #
Borrower
Type
Principal
Outstanding
Next Due Date
Status
Days Overdue
```

---

# 57. Loan Detail

Canonical operational page sections:

```text
Loan Summary
Borrower / Guarantor
Financial Breakdown
Repayment Schedule
Payment History
Approval History
Security
Default / Recovery History
Audit Timeline
```

---

# 58. Repayment Schedule UI

Example:

```text
#   Due Date    Amount    Paid    Penalty    Status
1   Sep 12      2200      2200       0       PAID
2   Oct 12      2200         0     110       OVERDUE
3   Nov 12      2200         0       0       PENDING
```

Do not hide penalty amounts.

---

# 59. Overdue Queue

Route:

```text
/loans/overdue
```

Show:

```text
Borrower
Loan
Installment
Due date
Days overdue
Outstanding
Penalty
Guarantor
Default threshold date
```

Example:

```text
13 days overdue
Default in 47 days
```

---

# 60. Defaults

Route:

```text
/loans/defaults
```

Show:

```text
Borrower
Loan
Installment
Days since due
Outstanding
Guarantor
Recovery status
```

Actions must be controlled workflow actions, not balance editing.

---

# 61. Guarantor Admin Area

Route:

```text
/loans/guarantors
```

Show:

```text
Guarantor
Borrower
Loan
Guaranteed amount
Status
Start date
Potential responsibility
```

Useful filters:

```text
Active
Released
At-risk
Defaulted loan
```

---

# 62. Recovery Admin Area

Route:

```text
/loans/recovery
```

Show:

```text
Loan
Borrower
Outstanding amount
Security available
Guarantor
Recovery stage
Amount recovered
Remaining
```

All recovery actions must be explicitly approved and audited.

---

# 63. Flutter Loan Structure

Use:

```text
features/
└── loans/
    ├── data/
    │   ├── datasources/
    │   │   └── loans_remote_data_source.dart
    │   ├── models/
    │   │   ├── loan_product_model.dart
    │   │   ├── loan_application_model.dart
    │   │   ├── loan_model.dart
    │   │   ├── loan_installment_model.dart
    │   │   ├── loan_penalty_model.dart
    │   │   ├── loan_approval_model.dart
    │   │   ├── loan_default_event_model.dart
    │   │   └── loan_recovery_model.dart
    │   └── repositories/
    │       └── loan_repository_impl.dart
    │
    ├── domain/
    │   ├── entities/
    │   │   ├── loan_product_entity.dart
    │   │   ├── loan_application_entity.dart
    │   │   ├── loan_entity.dart
    │   │   ├── loan_installment_entity.dart
    │   │   ├── loan_penalty_entity.dart
    │   │   └── guarantor_entity.dart
    │   ├── repositories/
    │   │   └── loan_repository.dart
    │   └── usecases/
    │       ├── get_loan_products.dart
    │       ├── check_loan_eligibility.dart
    │       ├── submit_loan_application.dart
    │       ├── get_my_loan_applications.dart
    │       ├── get_my_loans.dart
    │       ├── get_loan_details.dart
    │       ├── get_repayment_schedule.dart
    │       ├── accept_guarantor_request.dart
    │       ├── reject_guarantor_request.dart
    │       ├── request_loan_extension.dart
    │       └── get_loan_history.dart
    │
    └── presentation/
        ├── bloc/
        │   ├── loan_bloc.dart
        │   ├── loan_event.dart
        │   └── loan_state.dart
        ├── pages/
        │   ├── loans_page.dart
        │   ├── loan_application_page.dart
        │   ├── loan_application_status_page.dart
        │   ├── loan_detail_page.dart
        │   ├── repayment_schedule_page.dart
        │   ├── guarantor_requests_page.dart
        │   └── loan_extension_page.dart
        └── widgets/
            ├── loan_summary_card.dart
            ├── loan_status_chip.dart
            ├── eligibility_checklist.dart
            ├── repayment_schedule_card.dart
            ├── installment_tile.dart
            ├── guarantor_request_card.dart
            └── loan_financial_breakdown.dart
```

Use existing equivalents rather than creating duplicate models/files.

---

# 64. Flutter Member Loan Experience

The member should see:

```text
Loans

Active Loan
Outstanding
Next Payment
Due Date

Available to Apply
Maximum Eligible
```

Application:

```text
Loan Type
Amount
Purpose
Estimated service charge
Estimated total repayment
Estimated monthly repayment
```

The service charge must be visible before the user submits/accepts the application.

---

# 65. Eligibility UI

Use a transparent checklist:

```text
✓ Active member
✓ 2+ months savings history
✓ No overdue loan
✓ Monthly saving fulfilled
✓ Amount within policy
✓ Group liquidity available
```

If not eligible, show a precise reason.

The UI is informational; the database remains authoritative.

---

# 66. Outsider Loan Experience

```text
Loan application
    ↓
Guarantor request
    ↓
Guarantor acceptance
    ↓
Application review
```

Show the 15% service charge and exact repayment values.

Do not convert the outsider into a member.

---

# 67. Guarantor Mobile Experience

Show:

```text
Guarantee Request

Borrower
Loan amount
Service charge
Total repayment
Term
Monthly installment
Potential responsibility
```

Actions:

```text
Accept
Reject
```

The decision must go through a secure RPC.

---

# 68. Loan Extension UI

Only before serious default.

Form:

```text
Current due date
Requested new date
Reason
```

Submit as a pending approval request.

---

# 69. Notifications

Current MVP can use in-app notifications.

Events:

```text
LOAN_APPLICATION_RECEIVED
LOAN_APPROVAL_RECEIVED
LOAN_REJECTED
LOAN_APPROVED
LOAN_DISBURSED

INSTALLMENT_DUE_SOON
INSTALLMENT_OVERDUE
LATE_PENALTY_APPLIED

GUARANTOR_REQUEST
GUARANTOR_ACCEPTED
GUARANTOR_REJECTED

DEFAULT_NOTICE
GUARANTOR_DEFAULT_NOTICE
RECOVERY_NOTICE
```

---

# 70. RLS

Members may read only their own:

```text
loan applications
loans
installments
payments
loan history
```

A guarantor may read only guarantee requests/loan information necessary for their own guarantee decision.

Members must not:

```text
insert loan approvals
update loan status
create penalties
modify installment amounts
modify service charges
create disbursements
insert ledger entries
```

Admin/staff access must come from explicit RBAC permissions.

---

# 71. RPC Security

Privileged RPCs must:

- derive actor from `auth.uid()`
- validate role/permission
- validate current state
- validate ownership/relationship
- execute atomically
- write audit records
- prevent replay/duplicate actions

Do not trust arbitrary actor IDs supplied by clients.

---

# 72. Scheduled Jobs

Create scheduled processing for:

```text
generate_loan_installments
process_overdue_loan_installments
process_serious_defaults
send_loan_due_notifications
```

Generate a schedule once per loan activation and make processing jobs idempotent.

---

# 73. Payment Integration

Current MVP:

```text
Wallet
Bank transfer
Manual verification
```

Future:

```text
Payment Provider API
Webhook
Automatic verification
Reconciliation
```

Payment remains separate from loan posting:

```text
Payment
  ↓
Verification
  ↓
Loan repayment posting
  ↓
Ledger
```

---

# 74. Reports

Required:

```text
Loan portfolio
Outstanding loans
Active loans
Overdue loans
Defaults
Repayments
Service-charge income
Penalty income
Disbursements
Recovery
```

Member statement:

```text
Loan principal
Service charge
Payments
Penalties
Outstanding
```

Management reporting should combine loan, savings and liquidity data.

---

# 75. Testing Strategy

## Unit tests

Test:

```text
member service charge = principal × 10%
outsider service charge = principal × 15%
total repayment
three-installment schedule
5% late penalty
60-day default threshold
eligibility decisions
```

## Database tests

Test:

```text
inactive member cannot qualify
member with <2 months saving cannot qualify
member with overdue loan cannot qualify
member with unmet monthly contribution cannot qualify
outsider without guarantor cannot qualify
inactive guarantor cannot qualify
guarantor already guaranteeing another outsider loan cannot qualify
loan > 20,000 blocked
liquidity breach blocks approval/disbursement
one-person approval does not approve
two distinct approvals approve
self-approval blocked
duplicate disbursement blocked
duplicate repayment blocked
duplicate late penalty blocked
```

## RLS tests

Test:

```text
member A cannot read member B loan
member cannot update loan status
member cannot approve/disburse
member cannot create penalty
guarantor cannot read unrelated guarantee
unauthorized staff cannot execute restricted operations
```

---

# 76. Financial Invariants

These must always remain true:

```text
Every posted transaction balances.
Original service-charge values are immutable.
A late penalty is created once per overdue installment.
Installment numbers are unique within a loan.
A loan cannot be disbursed twice.
A rejected application cannot be casually approved.
Approval identifies the actual approver.
Two distinct approvals are required.
Self-approval is blocked.
A member cannot guarantee two outstanding outsider loans.
Secured savings cannot be freely withdrawn.
Financial history is never hard-deleted.
```

---

# 77. Concurrency Tests

Explicitly test:

```text
Two admins approve simultaneously.
Two admins disburse simultaneously.
Two applications attempt the same guarantor simultaneously.
Two payments post against one installment simultaneously.
Withdrawal and disbursement occur concurrently.
```

Expected result: database constraints/transactions ensure a correct single outcome without violating financial policy.

---

# 78. Implementation Order

## Backend first

```text
1. Audit existing schema.
2. Create/adjust loan tables.
3. Add product/rule configuration.
4. Add indexes and constraints.
5. Implement eligibility functions.
6. Implement guarantor workflow.
7. Implement two-person approval.
8. Implement liquidity evaluation.
9. Implement loan creation.
10. Implement disbursement.
11. Implement repayment schedule.
12. Implement repayment posting.
13. Implement late penalty processing.
14. Implement serious-default processing.
15. Implement security lock/release hooks.
16. Implement extension structure.
17. Implement recovery structure.
18. Implement RLS.
19. Restrict RPC EXECUTE permissions.
20. Implement audit integration.
21. Implement scheduled jobs.
22. Write database tests.
23. Run concurrency tests.
```

## Flutter second

```text
24. Domain entities.
25. DTO/model mapping.
26. Remote datasource.
27. Repository.
28. Use cases.
29. BLoC.
30. Member loan list.
31. Eligibility screen.
32. Application flow.
33. Loan detail.
34. Repayment schedule.
35. Guarantor requests.
36. Extension request.
37. Notifications.
38. Error/loading/empty states.
39. Responsive polish.
40. Accessibility.
41. Integration tests.
```

## Admin third

```text
42. Loan overview.
43. Applications inbox.
44. Application detail.
45. Approval interface.
46. Disbursement queue.
47. Active loans.
48. Repayment queue.
49. Overdue.
50. Defaults.
51. Guarantors.
52. Recovery.
53. Transactions.
54. Audit detail.
55. Responsive/premium UI pass.
```

---

# 79. Definition of Done

The feature is complete only when:

```text
[ ] Eligibility is server-enforced.
[ ] Member service charge = 10%.
[ ] Outsider service charge = 15%.
[ ] Maximum amount = 20,000 ETB.
[ ] Three-month schedule is generated.
[ ] Guarantor workflow works.
[ ] One-outstanding-guarantee rule is enforced.
[ ] Two distinct approvals are enforced.
[ ] Self-approval is blocked.
[ ] Liquidity reserve is enforced.
[ ] Final liquidity is checked before disbursement.
[ ] Disbursement cannot duplicate.
[ ] Repayments cannot duplicate.
[ ] Early repayment has no additional penalty.
[ ] Late installment receives one 5% penalty.
[ ] Serious default is detected after 60 days.
[ ] Default actions are recorded.
[ ] Financial records cannot be hard-deleted.
[ ] Reversal path exists.
[ ] Audit trail exists.
[ ] RLS passes cross-user tests.
[ ] RPC authorization passes.
[ ] Scheduled jobs are idempotent.
[ ] Concurrency tests pass.
[ ] Flutter member experience works.
[ ] Guarantor experience works.
[ ] Admin workflow works.
[ ] Loading/empty/error states are polished.
[ ] Accessibility checks pass.
```

---

# 80. Final Loan Architecture

```text
                    UNITY FINANCE LOANS

                         Applicant
                             │
                  ┌──────────┴──────────┐
                  │                     │
                Member               Outsider
                  │                     │
             Eligibility          Guarantor
                  │                     │
                  └──────────┬──────────┘
                             │
                     Liquidity Check
                             │
                     Eligibility Result
                             │
                        Admin Review
                             │
                    Approval #1 + #2
                             │
                        Approved
                             │
                   Final Liquidity Gate
                             │
                         Disbursement
                             │
                          ACTIVE
                             │
                  ┌──────────┼──────────┐
                  │          │          │
               On-time     Late       Early
                  │          │       repayment
                  │          ↓
                  │       5% penalty
                  │          │
                  └──────────┼──────────┘
                             │
                         Repayments
                             │
                    ┌────────┴────────┐
                    │                 │
                  PAID          60-day default
                                      │
                               Recovery workflow
                                      │
                               Guarantor/security
```

Core implementation principle:

```text
Flutter requests.
PostgreSQL validates.
RPC performs the state transition atomically.
Ledger records the money.
Audit records the action.
The UI refreshes from authoritative state.
```
