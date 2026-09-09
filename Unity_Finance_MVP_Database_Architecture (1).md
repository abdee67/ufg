# Unity Finance Group - MVP Database & Architecture Design

**Document status:** Approved working design for MVP implementation  
**Source of business rules:** Unity Finance Group Savings & Lending Rules playbook  
**Primary goal:** Build a secure, auditable member savings and lending platform that supports the complete MVP cycle: **Register -> Save -> Apply -> Approve -> Lend -> Repay -> Report**.

> The playbook is the business source of truth. Where the playbook does not define a rule, the design marks it as configurable/TBD rather than inventing a financial policy.

---

## 1. MVP Scope

### Included

1. Authentication and user profiles
2. RBAC foundation
3. Membership registration and approval
4. Membership fee / first contribution handling
5. Mandatory monthly savings
6. Savings late penalty
7. Savings withdrawal requests
8. Payments through wallet and bank transfer
9. Payment verification by authorized staff
10. Append-only financial ledger
11. Member loan applications
12. Outsider/non-member loan applications
13. Guarantor workflow
14. Automatic loan eligibility checks
15. Two-person loan approval
16. Liquidity reserve enforcement
17. Loan service charges
18. Three-month repayment schedules
19. Late loan-payment penalties
20. Serious-default handling
21. Loan/security tracking
22. Admin dashboard
23. Monthly financial reporting
24. Audit logs
25. Transaction reversal/correction workflow
26. Configurable financial rules

### Explicitly outside MVP

- Automated payment API verification
- Dividend distribution engine
- Tax engine
- Multi-branch support
- Advanced accounting/ERP
- SMS provider integration
- Complex loan committee workflows
- Advanced analytics
- External integrations beyond wallet/bank-transfer recording

---

# 2. Business Rules Implemented in MVP

| Rule | MVP value |
|---|---:|
| Minimum monthly saving | 2,000 ETB |
| Saving deadline | 12th day of month |
| Saving late penalty | 10%, charged once per missed contribution |
| Maximum loan amount | 20,000 ETB |
| Member loan service charge | 10% one-time |
| Outsider loan service charge | 15% one-time |
| Standard loan term | 3 months |
| Loan late-payment penalty | 5% of overdue installment, charged once |
| Serious overdue threshold | 60 days after due date |
| Minimum liquidity reserve | 30% |
| Member loan eligibility | Active member, at least 2 months saving, no overdue loan, current monthly contribution fulfilled |
| Outsider loan | Requires active member guarantor |
| Guarantor limit | One outstanding outsider loan at a time |
| Loan approval | Minimum 2 authorized approvers |
| Own loan approval | Prohibited |
| Early loan repayment | Allowed with no early-repayment penalty |
| Savings withdrawal | Allowed, subject to loan-security and liquidity restrictions |

The underlying rules are defined in the approved playbook.

---

# 3. Architecture Overview

```text
                     ┌───────────────────────────┐
                     │       Flutter Clients      │
                     ├─────────────┬─────────────┤
                     │ Member App  │ Admin App/UI │
                     └──────┬──────┴──────┬──────┘
                            │              │
                            └──────┬───────┘
                                   │
                         Application Services
                                   │
                ┌──────────────────┼──────────────────┐
                │                  │                  │
             Auth/RBAC        Business Rules       Audit
                │                  │                  │
                └──────────────────┼──────────────────┘
                                   │
                           Supabase/PostgreSQL
                                   │
        ┌──────────────┬───────────┼────────────┬──────────────┐
        │              │           │            │              │
     Profiles       Savings      Loans       Payments       Ledger
        │              │           │            │              │
        └──────────────┴───────────┼────────────┴──────────────┘
                                   │
                              Reports
```

## Recommended technical stack

- **Frontend:** Flutter
- **Backend:** Supabase
- **Database:** PostgreSQL
- **Authentication:** Supabase Auth
- **Authorization:** PostgreSQL RLS + application RBAC
- **Storage:** Supabase Storage for IDs/payment proofs/documents
- **Notifications:** In-app first; external SMS/push integrations later
- **Architecture style:** Feature-based Clean Architecture
- **State management:** BLoC/Cubit
- **Dependency injection:** GetIt
- **Routing:** GoRouter

---

# 4. Application Architecture

## Flutter structure

```text
lib/
├── main.dart
├── injection_container.dart
├── core/
│   ├── constants/
│   ├── errors/
│   ├── extensions/
│   ├── network/
│   ├── permissions/
│   ├── security/
│   ├── utils/
│   └── widgets/
├── shared/
│   ├── models/
│   ├── enums/
│   ├── repositories/
│   └── services/
├── routes/
├── features/
│   ├── auth/
│   ├── profile/
│   ├── membership/
│   ├── savings/
│   ├── payments/
│   ├── loans/
│   ├── guarantors/
│   ├── transactions/
│   ├── dashboard/
│   ├── reports/
│   ├── notifications/
│   └── settings/
└── app.dart
```

Each feature follows:

```text
feature/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── bloc/
    ├── pages/
    └── widgets/
```

---

# 5. Core Architectural Principles

## 5.1 Ledger-first financial architecture

UI actions must never directly update a balance.

Bad:

```text
member.balance += 2000
```

Correct:

```text
Payment
   -> Verification
   -> Financial Transaction
   -> Ledger Entries
   -> Derived Account Balance
```

Balances can be cached/materialized for performance, but the ledger remains the authoritative financial history.

## 5.2 Append-only financial history

Financial transactions are never deleted.

Corrections use:

```text
Original transaction
        ↓
Reversal transaction
        ↓
Corrected transaction
```

## 5.3 Server-side business rules

Eligibility, penalties, service charges, liquidity checks and approval requirements must be enforced server-side.

The client can display the result, but cannot be trusted to enforce financial rules.

## 5.4 Configurable rules

Do not hardcode money/rate rules into Flutter.

Store active rules in the database and version them.

## 5.5 Separation of concerns

```text
Payment ≠ Transaction ≠ Ledger Entry ≠ Account Balance
```

---

# 6. Database Schema

The following schema is the recommended MVP baseline.

---

## 6.1 Users & Profiles

### `profiles`

```sql
id uuid primary key references auth.users(id)
full_name text not null
phone text
email text
national_id text
address text
date_of_birth date
profile_status text not null
created_at timestamptz not null
updated_at timestamptz not null
```

Suggested `profile_status`:

```text
ACTIVE
SUSPENDED
INACTIVE
```

### `roles`

```sql
id uuid primary key
code text unique not null
name text not null
description text
created_at timestamptz not null
```

Initial roles:

```text
MEMBER
ADMIN
```

### `permissions`

```sql
id uuid primary key
code text unique not null
name text
description text
created_at timestamptz not null
```

### `role_permissions`

```sql
role_id uuid references roles(id)
permission_id uuid references permissions(id)
primary key(role_id, permission_id)
```

### `user_roles`

```sql
user_id uuid references profiles(id)
role_id uuid references roles(id)
assigned_by uuid references profiles(id)
created_at timestamptz not null
primary key(user_id, role_id)
```

---

# 7. Membership

## `membership_applications`

```sql
id uuid primary key
applicant_id uuid references profiles(id) not null
application_number text unique not null
status text not null
submitted_at timestamptz not null
reviewed_by uuid references profiles(id)
reviewed_at timestamptz
rejection_reason text
created_at timestamptz not null
updated_at timestamptz not null
```

Statuses:

```text
PENDING
UNDER_REVIEW
APPROVED
REJECTED
CANCELLED
```

## `members`

```sql
id uuid primary key
profile_id uuid unique references profiles(id) not null
member_number text unique not null
membership_date date not null
status text not null
created_at timestamptz not null
updated_at timestamptz not null
```

Statuses:

```text
ACTIVE
SUSPENDED
REMOVED
INACTIVE
```

## `membership_status_history`

```sql
id uuid primary key
member_id uuid references members(id) not null
old_status text
new_status text not null
reason text
changed_by uuid references profiles(id)
created_at timestamptz not null
```

---

# 8. Financial Accounts

## `account_types`

Examples:

```text
MEMBER_SAVINGS
GROUP_INCOME
GROUP_EXPENSE
CASH
BANK
WALLET
LOAN_RECEIVABLE
LOAN_SERVICE_CHARGE_INCOME
PENALTY_INCOME
```

## `accounts`

```sql
id uuid primary key
account_type_id uuid references account_types(id) not null
owner_profile_id uuid references profiles(id)
owner_member_id uuid references members(id)
currency text not null default 'ETB'
status text not null
created_at timestamptz not null
updated_at timestamptz not null
```

Important:

- Member savings are separate from group income.
- Group income is never treated as a member's savings balance.
- Account balance should be derived from ledger entries or maintained as a controlled materialized value.

---

# 9. Ledger

## `transactions`

```sql
id uuid primary key
reference_number text unique not null
transaction_type text not null
source_type text
source_id uuid
initiated_by uuid references profiles(id)
approved_by uuid references profiles(id)
approval_status text not null
transaction_status text not null
amount numeric(18,2) not null
currency text not null default 'ETB'
description text
created_at timestamptz not null
approved_at timestamptz
```

Suggested transaction types:

```text
MEMBERSHIP_FEE
SAVINGS_CONTRIBUTION
SAVINGS_LATE_PENALTY
SAVINGS_WITHDRAWAL
LOAN_SERVICE_CHARGE
OUTSIDER_SERVICE_CHARGE
LOAN_DISBURSEMENT
LOAN_REPAYMENT
LOAN_LATE_PENALTY
EXPENSE
REVERSAL
CORRECTION
OTHER_INCOME
```

Approval statuses:

```text
PENDING
APPROVED
REJECTED
```

Transaction statuses:

```text
PENDING
POSTED
REVERSED
VOIDED_BY_REVERSAL
```

## `transaction_entries`

```sql
id uuid primary key
transaction_id uuid references transactions(id) not null
account_id uuid references accounts(id) not null
entry_type text not null
amount numeric(18,2) not null
created_at timestamptz not null
```

Entry types:

```text
DEBIT
CREDIT
```

A financial transaction must produce balanced entries.

Example savings contribution:

```text
Bank/Cash          DEBIT  2000
Member Savings     CREDIT 2000
```

---

# 10. Payments

## `payment_methods`

```sql
id uuid primary key
code text unique not null
name text not null
active boolean not null default true
created_at timestamptz not null
```

Initial methods:

```text
WALLET
BANK_TRANSFER
```

## `payments`

```sql
id uuid primary key
payer_profile_id uuid references profiles(id) not null
amount numeric(18,2) not null
payment_method_id uuid references payment_methods(id) not null
reference_number text unique not null
purpose_type text not null
purpose_id uuid
status text not null
submitted_at timestamptz not null
verified_by uuid references profiles(id)
verified_at timestamptz
rejection_reason text
payment_proof_path text
created_at timestamptz not null
updated_at timestamptz not null
```

Statuses:

```text
PENDING
VERIFIED
REJECTED
CANCELLED
```

---

# 11. Savings

## `savings_accounts`

```sql
id uuid primary key
member_id uuid unique references members(id) not null
account_id uuid unique references accounts(id) not null
status text not null
created_at timestamptz not null
```

## `savings_obligations`

```sql
id uuid primary key
member_id uuid references members(id) not null
period_year int not null
period_month int not null
required_amount numeric(18,2) not null
due_date date not null
paid_amount numeric(18,2) not null default 0
late_penalty_amount numeric(18,2) not null default 0
status text not null
created_at timestamptz not null
updated_at timestamptz not null
unique(member_id, period_year, period_month)
```

Statuses:

```text
PENDING
PARTIALLY_PAID
PAID
LATE
WAIVED
```

## `savings_penalties`

```sql
id uuid primary key
obligation_id uuid unique references savings_obligations(id) not null
rate numeric(8,4) not null
amount numeric(18,2) not null
charged_at timestamptz not null
transaction_id uuid references transactions(id)
```

The penalty is generated once for a missed 2,000 ETB contribution.

## `withdrawal_requests`

```sql
id uuid primary key
member_id uuid references members(id) not null
amount numeric(18,2) not null
status text not null
requested_at timestamptz not null
reviewed_by uuid references profiles(id)
reviewed_at timestamptz
reason text
created_at timestamptz not null
```

Statuses:

```text
PENDING
APPROVED
REJECTED
PAID
CANCELLED
```

---

# 12. Loans

## `loan_products`

```sql
id uuid primary key
code text unique not null
name text not null
borrower_type text not null
service_charge_rate numeric(8,4) not null
max_amount numeric(18,2) not null
term_months int not null
active boolean not null default true
created_at timestamptz not null
updated_at timestamptz not null
```

MVP products:

```text
MEMBER_LOAN
OUTSIDER_LOAN
```

Values:

```text
MEMBER_LOAN    -> 10% service charge
OUTSIDER_LOAN  -> 15% service charge
```

## `loan_applications`

```sql
id uuid primary key
application_number text unique not null
applicant_profile_id uuid references profiles(id) not null
member_id uuid references members(id)
loan_product_id uuid references loan_products(id) not null
requested_amount numeric(18,2) not null
purpose text
eligibility_status text
status text not null
submitted_at timestamptz not null
created_at timestamptz not null
updated_at timestamptz not null
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
```

## `loans`

```sql
id uuid primary key
loan_number text unique not null
loan_application_id uuid unique references loan_applications(id) not null
borrower_profile_id uuid references profiles(id) not null
member_id uuid references members(id)
principal numeric(18,2) not null
service_charge_rate numeric(8,4) not null
service_charge_amount numeric(18,2) not null
total_repayment numeric(18,2) not null
term_months int not null
status text not null
disbursed_at timestamptz
maturity_date date
created_at timestamptz not null
updated_at timestamptz not null
```

Statuses:

```text
ACTIVE
PAID
OVERDUE
DEFAULTED
RESTRUCTURED
CANCELLED
```

---

# 13. Guarantors

## `loan_guarantors`

```sql
id uuid primary key
loan_application_id uuid references loan_applications(id) not null
guarantor_member_id uuid references members(id) not null
guaranteed_amount numeric(18,2) not null
status text not null
requested_at timestamptz not null
approved_at timestamptz
rejected_at timestamptz
created_at timestamptz not null
```

Statuses:

```text
REQUESTED
ACCEPTED
REJECTED
RELEASED
```

Constraints:

- Guarantor must be active.
- A member may guarantee a maximum of one outstanding outsider loan.
- Guarantor must electronically approve.
- Guarantor cannot be the borrower.
- Guaranteed amount must satisfy the configured security rules.

---

# 14. Loan Approvals

## `loan_approvals`

```sql
id uuid primary key
loan_application_id uuid references loan_applications(id) not null
approver_profile_id uuid references profiles(id) not null
decision text not null
comment text
decided_at timestamptz
created_at timestamptz not null
unique(loan_application_id, approver_profile_id)
```

Decisions:

```text
APPROVED
REJECTED
```

Business constraint:

```text
A loan cannot reach APPROVED until at least
2 distinct authorized approvers have approved it.
```

No approver may approve their own loan.

---

# 15. Loan Installments

## `loan_installments`

```sql
id uuid primary key
loan_id uuid references loans(id) not null
installment_number int not null
due_date date not null
principal_amount numeric(18,2) not null
service_charge_amount numeric(18,2) not null
total_due numeric(18,2) not null
paid_amount numeric(18,2) not null default 0
late_penalty_amount numeric(18,2) not null default 0
status text not null
created_at timestamptz not null
updated_at timestamptz not null
unique(loan_id, installment_number)
```

Statuses:

```text
PENDING
PARTIALLY_PAID
PAID
OVERDUE
DEFAULTED
```

For MVP, service charge is calculated once on original principal and represented in the repayment schedule according to the agreed product behavior.

---

# 16. Loan Late Penalties

## `loan_penalties`

```sql
id uuid primary key
installment_id uuid unique references loan_installments(id) not null
rate numeric(8,4) not null
amount numeric(18,2) not null
charged_at timestamptz not null
transaction_id uuid references transactions(id)
```

The penalty is 5% of the overdue installment and is charged once.

---

# 17. Default & Recovery

## `loan_default_events`

```sql
id uuid primary key
loan_id uuid references loans(id) not null
installment_id uuid references loan_installments(id)
event_type text not null
event_date timestamptz not null
notes text
created_by uuid references profiles(id)
created_at timestamptz not null
```

Event types:

```text
DEFAULT_NOTICE
GUARANTOR_NOTICE
BORROWING_SUSPENDED
SECURITY_RECOVERY_STARTED
GUARANTOR_RECOVERY_STARTED
RECOVERY_COMPLETED
```

---

# 18. Expenses

## `expenses`

```sql
id uuid primary key
reference_number text unique not null
category text not null
amount numeric(18,2) not null
description text
supporting_document_path text
status text not null
requested_by uuid references profiles(id)
approved_by uuid references profiles(id)
created_at timestamptz not null
approved_at timestamptz
```

Statuses:

```text
PENDING
APPROVED
REJECTED
PAID
```

---

# 19. Audit Logs

## `audit_logs`

```sql
id uuid primary key
actor_user_id uuid references profiles(id)
action text not null
entity_type text not null
entity_id uuid
old_data jsonb
new_data jsonb
metadata jsonb
created_at timestamptz not null
```

Examples:

```text
MEMBER_APPROVED
PAYMENT_VERIFIED
LOAN_APPROVED
LOAN_REJECTED
LOAN_DISBURSED
TRANSACTION_REVERSED
RULE_CHANGED
ROLE_ASSIGNED
```

Audit logs must be append-only.

---

# 20. Business Rule Versioning

## `financial_rules`

```sql
id uuid primary key
rule_code text unique not null
description text
data_type text not null
active boolean not null default true
created_at timestamptz not null
```

## `financial_rule_versions`

```sql
id uuid primary key
rule_id uuid references financial_rules(id) not null
value_numeric numeric(18,6)
value_text text
effective_from timestamptz not null
effective_to timestamptz
status text not null
approved_by uuid references profiles(id)
approved_at timestamptz
change_reason text
created_at timestamptz not null
```

Rules to seed:

```text
MONTHLY_MIN_SAVING = 2000
SAVING_DUE_DAY = 12
SAVING_LATE_PENALTY_RATE = 0.10

MEMBER_SERVICE_CHARGE_RATE = 0.10
OUTSIDER_SERVICE_CHARGE_RATE = 0.15

MAX_LOAN_AMOUNT = 20000
DEFAULT_LOAN_TERM_MONTHS = 3
LOAN_LATE_PENALTY_RATE = 0.05
SERIOUS_DEFAULT_DAYS = 60

LIQUIDITY_RESERVE_RATE = 0.30
```

---

# 21. Liquidity Service

The system needs a dedicated business service for lending capacity.

Conceptual calculation:

```text
member_savings
available_cash
outstanding_loans
required_reserve
loanable_funds
```

The service should answer:

```text
canApproveLoan(requestedAmount)
```

and return:

```json
{
  "eligible": true,
  "requested_amount": 10000,
  "max_policy_amount": 20000,
  "available_liquidity": 18000,
  "required_reserve": 60000,
  "reasons": []
}
```

The exact accounting formula for liquidity must be finalized against the group's financial policy before production. The 30% reserve rule itself is fixed by the playbook.

---

# 22. RLS / Security Design

## Member

A member can:

- Read/update permitted parts of own profile
- Read own savings
- Read own payments
- Create own payment requests
- Read own transactions
- Create own withdrawal request
- Create own loan application
- Read own loan
- Approve/reject guarantor requests assigned to them
- Read own notifications

A member cannot:

- Read another member's financial data
- Approve loans
- Modify ledger records
- Modify payment verification
- Modify financial rules
- Modify audit logs

## Admin

Admins get only the permissions explicitly assigned by RBAC.

Do not make all backend operations accessible simply because the user has role `ADMIN`.

---

# 23. Critical Database Constraints

Enforce these at database/service level:

1. Amounts must be positive unless the transaction is a deliberate reversal.
2. Currency is `ETB` for MVP.
3. One monthly savings obligation per member per month.
4. One active savings account per member.
5. One guarantor per outsider loan in MVP.
6. One outstanding outsider-loan guarantee per member.
7. At least two distinct approvals required.
8. Approver cannot approve own loan.
9. Financial transactions cannot be hard-deleted.
10. Service-charge and penalty amounts are preserved in transaction history.
11. A secured portion of savings cannot be withdrawn.
12. A loan cannot be approved if the liquidity rule fails.
13. Loan amount cannot exceed configured maximum.
14. Member loan requires minimum saving history.
15. Borrower with overdue loan cannot create an eligible member-loan application.
16. Outsider loan requires active guarantor.
17. All financial mutations create audit entries.

---

# 24. Main MVP Workflows

## Membership

```text
Register
 -> Apply
 -> Pay first contribution/fee
 -> Admin review
 -> Approve
 -> Member activated
 -> Savings account created
```

## Monthly Savings

```text
Monthly job
 -> Create obligation
 -> Due on 12th
 -> Payment
 -> Verification
 -> Ledger posting
 -> Mark paid

If missed:
 -> Mark late
 -> Create 10% penalty once
```

## Member Loan

```text
Application
 -> Eligibility check
 -> Liquidity check
 -> Review
 -> Approver 1
 -> Approver 2
 -> Approval
 -> Disbursement
 -> Generate 3 installments
 -> Active
```

## Outsider Loan

```text
Application
 -> Select active member guarantor
 -> Guarantor approval
 -> Eligibility/risk checks
 -> Two-person approval
 -> Liquidity check
 -> Disbursement
 -> Generate schedule
```

## Repayment

```text
Payment
 -> Verify
 -> Match installment
 -> Ledger posting
 -> Update installment
 -> If all paid => Loan PAID
```

## Default

```text
Installment overdue
 -> 5% penalty once
 -> Continue overdue tracking
 -> 60 days
 -> Serious default
 -> Notify borrower
 -> Notify guarantor
 -> Suspend new borrowing
 -> Recovery workflow if required
```

---

# 25. Scheduled Jobs

Use scheduled backend jobs for:

```text
1. Generate monthly savings obligations
2. Detect late savings after the 12th
3. Generate savings penalties
4. Detect overdue loan installments
5. Generate loan late penalties
6. Detect 60-day serious defaults
7. Generate notifications
8. Generate monthly reports
```

All scheduled actions must be idempotent.

Running a job twice must not create duplicate penalties or duplicate obligations.

---

# 26. MVP Screens

## Member app

```text
Splash
Login
Register
Forgot Password
Home
Membership
Profile
Savings
Savings History
Monthly Obligation
Withdrawal
Payments
Payment History
Loans
Loan Application
Loan Details
Repayment Schedule
Guarantor Requests
Transactions
Notifications
```

## Admin app

```text
Login
Dashboard
Members
Membership Applications
Member Details
Savings
Withdrawals
Payments
Payment Verification
Loans
Loan Applications
Loan Review
Loan Approvals
Guarantors
Disbursements
Repayments
Overdue Loans
Defaults
Expenses
Transactions
Reports
Audit Logs
Roles & Permissions
Financial Rules
Settings
```

---

# 27. MVP Acceptance Criteria

The MVP is considered functionally complete when a test user can:

```text
1. Register.
2. Become a member.
3. Pay/record required first contribution.
4. Receive a savings account.
5. Receive monthly savings obligation.
6. Pay 2,000 ETB.
7. Be charged 200 ETB if the contribution becomes late.
8. Request a savings withdrawal.
9. Apply for a member loan after satisfying eligibility.
10. Apply for an outsider loan with an active member guarantor.
11. Have guarantor approve electronically.
12. Pass liquidity validation.
13. Receive two independent loan approvals.
14. Receive a three-month repayment schedule.
15. Make repayments.
16. Be charged 5% once when an installment is late.
17. Enter serious-default workflow after 60 days.
18. Have all financial actions recorded in the ledger.
19. Have every financial action traceable in audit logs.
20. Produce the required monthly financial report.
```

---

# 28. MVP Definition of Done

Before production:

- RLS policies tested
- RBAC tests passed
- Financial calculations covered by automated tests
- Ledger balancing tests passed
- Duplicate job execution tested
- Transaction reversal tested
- Two-approval rule tested
- Own-loan-approval prevention tested
- Guarantor limit tested
- Liquidity reserve tested
- Late penalty idempotency tested
- 60-day default detection tested
- Audit log coverage verified
- Database backups enabled
- Error monitoring enabled
- Production environment separated from development
