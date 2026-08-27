# Unity Finance Group - Full Product Database & Architecture Design

**Document status:** Full-product blueprint extending the MVP  
**Source of business rules:** Unity Finance Group Savings & Lending Rules playbook + approved project decisions  
**Purpose:** Define the architecture for all discussed capabilities, while keeping undocumented financial policies configurable until formally approved.

---

# 1. Product Vision

Unity Finance is a member-based savings and lending platform following:

```text
SAVE -> LEND -> REPAY -> RECYCLE THE FUNDS
```

The platform supports:

- Members
- Non-members / outsiders
- Administrators
- Future specialized staff roles

It maintains strict separation between:

```text
Member Funds
Group Income
Group Expenses
Loans Receivable
Cash / Bank / Wallet
```

The platform is intended to grow from a small internal business application into a controlled financial-management platform.

---

# 2. Full Feature Set

## Identity & Access

- Authentication
- Phone/email login
- Password reset
- Profile management
- MFA-ready architecture
- RBAC
- Permission management
- Session/security controls
- Staff accounts
- Role assignment
- Role history

## Membership

- Membership application
- Membership fee/initial contribution
- Document submission
- KYC-style profile information
- Membership approval
- Suspension
- Removal
- Membership status history
- Member number
- Member statement
- Member notifications
- Member announcements

## Savings

- Mandatory monthly saving
- Additional voluntary saving
- Savings obligations
- Late penalties
- Savings withdrawal
- Withdrawal approval
- Savings security/lock
- Savings statements
- Monthly contribution history
- Contribution reminders

## Loans

- Member loans
- Outsider loans
- Loan products
- Loan eligibility
- Loan limits
- Service charges
- Repayment schedule
- Guarantors
- Guarantor approval
- Two-person approval
- Loan disbursement
- Repayment
- Early repayment
- Late-payment penalties
- Extensions
- Default management
- Recovery
- Security enforcement
- Loan restructuring later if approved

## Payments

- Wallet
- Bank transfer
- Manual verification
- Payment proofs
- Payment reconciliation
- Payment API integrations later
- Webhooks
- Automated confirmation
- Payment retry handling
- Duplicate-payment protection

## Accounting / Finance

- Double-entry-style ledger
- Accounts
- Journal transactions
- Reversals
- Corrections
- Income
- Expenses
- Cash
- Bank
- Wallet
- Receivables
- Financial periods
- Closing periods
- Trial-balance capability
- Financial statements later

## Liquidity Management

- Liquidity reserve
- Loanable funds
- Available cash
- Outstanding loans
- Secured savings
- Withdrawal impact
- Lending restrictions
- Liquidity dashboard

## Reports

- Member statement
- Savings report
- Loan report
- Repayment report
- Overdue report
- Default report
- Payment report
- Service-charge income
- Penalty income
- Expense report
- Monthly financial report
- Liquidity report
- Audit report
- Export PDF/CSV/Excel
- Scheduled reports

## Notifications

- In-app
- Push
- Email
- SMS later
- Membership notifications
- Savings reminders
- Payment notifications
- Loan notifications
- Guarantor notifications
- Default notifications
- Rule-change notifications
- Announcements

## Governance

- Rule management
- Rule versioning
- Effective dates
- Approval workflow
- Conflict-of-interest declarations
- Audit logs
- Transaction reversals
- Staff activity history
- Permission history
- Financial-period controls

---

# 3. Full Architecture

```text
                        ┌───────────────────────────┐
                        │       Client Layer        │
                        ├───────────────────────────┤
                        │ Flutter Mobile             │
                        │ Flutter Web/Admin          │
                        │ Responsive Admin Portal    │
                        └──────────────┬────────────┘
                                       │
                             Application Layer
                                       │
                 ┌─────────────────────┼──────────────────────┐
                 │                     │                      │
            Authentication         API/Services          Notifications
                 │                     │                      │
                 └─────────────────────┼──────────────────────┘
                                       │
                              Domain / Rules Layer
                                       │
       ┌────────────┬────────────┬─────┼─────┬────────────┬────────────┐
       │            │            │           │            │            │
   Membership    Savings       Loans      Payments     Ledger      Reporting
       │            │            │           │            │            │
       └────────────┴────────────┴─────┬─────┴────────────┴────────────┘
                                       │
                              PostgreSQL / Supabase
                                       │
          ┌────────────┬──────────────┼──────────────┬──────────────┐
          │            │              │              │              │
        Auth        Database       Storage        Scheduled Jobs   Realtime
```

---

# 4. Recommended Technology

## Client

- Flutter
- Dart
- BLoC/Cubit
- GoRouter
- GetIt
- Dio or Supabase client
- Freezed/json_serializable if desired

## Backend

- Supabase
- PostgreSQL
- Supabase Auth
- Supabase Storage
- Edge Functions where server-side orchestration is needed
- Scheduled jobs / pg_cron-compatible scheduling

## Security

- PostgreSQL Row Level Security
- RBAC
- Least privilege
- Server-side authorization
- Audit logging
- Secrets stored outside source code

---

# 5. Full Domain Modules

```text
auth
identity
membership
members
savings
payments
wallet
banking
loans
guarantors
approvals
ledger
accounting
liquidity
expenses
reports
dividends
tax
notifications
announcements
audit
governance
settings
documents
integrations
```

---

# 6. Full Database Model

The MVP tables remain the foundation. The full design extends them.

---

# 7. Identity

## `profiles`

Core person record.

## `profile_contacts`

```sql
id
profile_id
contact_type
value
is_primary
verified_at
created_at
```

## `identity_documents`

```sql
id
profile_id
document_type
document_number
document_name
storage_path
verification_status
verified_by
verified_at
created_at
```

## `profile_status_history`

Tracks changes to profile status.

---

# 8. Membership

Existing MVP:

```text
membership_applications
members
membership_status_history
```

Add:

## `membership_fees`

```sql
id
membership_application_id
fee_type
amount
currency
payment_id
status
created_at
```

## `membership_documents`

Links required documents to applications/members.

---

# 9. Savings

Existing:

```text
savings_accounts
savings_obligations
savings_penalties
withdrawal_requests
```

Add:

## `savings_contributions`

```sql
id
member_id
savings_account_id
amount
payment_id
transaction_id
period_year
period_month
contribution_type
created_at
```

Types:

```text
MANDATORY
VOLUNTARY
ADJUSTMENT
```

## `savings_security_locks`

```sql
id
member_id
loan_id
amount
reason
status
created_at
released_at
```

This makes secured savings explicit.

---

# 10. Loans

Existing:

```text
loan_products
loan_applications
loans
loan_guarantors
loan_approvals
loan_installments
loan_penalties
loan_default_events
```

Add:

## `loan_eligibility_checks`

```sql
id
loan_application_id
check_code
result
value
reason
checked_at
```

Example:

```text
MINIMUM_SAVING_HISTORY     PASS
NO_OVERDUE_LOAN            PASS
MONTHLY_CONTRIBUTION       PASS
MAX_LOAN_AMOUNT            PASS
LIQUIDITY                   PASS
GUARANTOR                   PASS
```

This gives an audit trail explaining why an application was or was not eligible.

## `loan_extensions`

```sql
id
loan_id
requested_by
reason
old_due_date
new_due_date
approved_by
status
created_at
```

The playbook allows a borrower to request an extension before serious default and requires authorized approval.

## `loan_restructurings`

For future use only.

Do not enable until formally approved by business governance.

---

# 11. Payment Infrastructure

Existing:

```text
payments
payment_methods
```

Add:

## `payment_verifications`

```sql
id
payment_id
verification_type
status
verified_by
external_reference
evidence
verified_at
created_at
```

## `payment_integrations`

```sql
id
provider_code
provider_name
configuration
status
created_at
```

Never store API secrets in this table.

## `payment_webhooks`

```sql
id
provider
event_id
event_type
payload
signature_valid
processed_at
status
created_at
```

Use unique provider event IDs to prevent duplicate posting.

## Future automatic payment flow

```text
Payment Provider
      ↓
Webhook
      ↓
Signature verification
      ↓
Idempotency check
      ↓
Payment confirmation
      ↓
Transaction
      ↓
Ledger
```

---

# 12. Wallet

## `wallet_accounts`

```sql
id
profile_id
currency
status
created_at
```

## `wallet_transactions`

Links wallet operations to the central ledger.

The wallet is a payment mechanism, not a separate source of truth for member financial balances.

---

# 13. Bank Transfers

## `bank_accounts`

For the group's known bank accounts.

## `bank_transfer_records`

```sql
id
payment_id
bank_name
account_reference
sender_name
transfer_reference
amount
transfer_date
proof_path
verification_status
verified_by
created_at
```

Future bank API reconciliation can populate this table automatically.

---

# 14. Accounting

The full system should use a proper account hierarchy.

## `chart_of_accounts`

```sql
id
code
name
category
parent_id
normal_balance
active
created_at
```

Categories:

```text
ASSET
LIABILITY
EQUITY
INCOME
EXPENSE
```

Possible accounts:

```text
1000 Cash
1010 Bank
1020 Wallet
1100 Member Savings Receivable/Control
1200 Loans Receivable
1300 Secured Savings
4000 Member Loan Service Charge Income
4010 Outsider Service Charge Income
4020 Penalty Income
5000 Operating Expenses
```

The exact chart of accounts should be approved by the group's finance authority before production accounting is relied upon.

---

# 15. Financial Periods

## `financial_periods`

```sql
id
period_type
start_date
end_date
status
closed_by
closed_at
```

Statuses:

```text
OPEN
CLOSING
CLOSED
```

Once a financial period is closed:

- No direct modification of posted financial entries.
- Corrections use reversal/correction transactions.
- Re-opening requires authorized action and audit logging.

---

# 16. Dividends

The playbook provided does not define the final dividend mechanism. Therefore this module should be prepared but **not activated** until the business formally approves the policy.

## `dividend_periods`

```sql
id
financial_year
declared_rate
distributable_profit
dividend_pool
status
declared_by
declared_at
```

## `dividend_eligibility`

```sql
id
dividend_period_id
member_id
time_weighted_balance
eligible_amount
calculated_dividend
created_at
```

## `dividend_payments`

```sql
id
dividend_period_id
member_id
amount
transaction_id
status
paid_at
```

The calculation should support pro-rata time-weighting, but the exact formula, profit-allocation rules and tax treatment must be approved before implementation.

---

# 17. Tax

The playbook does not define tax rates or exact tax treatment.

Prepare:

## `tax_rules`

```sql
id
code
name
rate
applies_to
effective_from
effective_to
status
```

## `tax_calculations`

```sql
id
tax_rule_id
source_type
source_id
base_amount
tax_amount
transaction_id
created_at
```

Do not assume a tax rate in code.

---

# 18. Expenses

Existing:

```text
expenses
```

Add:

## `expense_categories`

```sql
id
code
name
description
active
```

## `expense_approvals`

Supports one or multiple approvals depending on the governance policy.

---

# 19. Notifications

## `notifications`

```sql
id
recipient_profile_id
type
title
body
data
read_at
created_at
```

## `notification_preferences`

```sql
id
profile_id
notification_type
in_app_enabled
push_enabled
email_enabled
sms_enabled
updated_at
```

## `notification_templates`

Allows controlled notification content without hardcoding messages.

---

# 20. Announcements

## `announcements`

```sql
id
title
body
audience_type
published_at
expires_at
created_by
status
```

Audiences:

```text
ALL
MEMBERS
NON_MEMBERS
STAFF
SPECIFIC_ROLE
```

---

# 21. Governance & Rule Changes

The playbook explicitly requires approved rule changes to be recorded with effective dates and members notified of important changes.

## `rule_change_requests`

```sql
id
requested_by
rule_id
proposed_value
reason
status
created_at
```

## `rule_change_approvals`

```sql
id
request_id
approver_id
decision
comment
created_at
```

## Rule lifecycle

```text
Draft
  ↓
Proposed
  ↓
Reviewed
  ↓
Approved
  ↓
Effective
```

---

# 22. Conflict of Interest

## `conflict_declarations`

```sql
id
actor_profile_id
related_entity_type
related_entity_id
description
status
declared_at
resolved_by
resolved_at
```

Examples:

```text
PERSONAL_RELATIONSHIP
FINANCIAL_INTEREST
BORROWER_RELATIONSHIP
OTHER
```

A person with a conflict should be prevented from acting where the policy requires recusal.

---

# 23. Audit Architecture

Every important mutation should produce an audit event.

### Audit categories

```text
AUTH
MEMBERSHIP
SAVINGS
PAYMENTS
LOANS
GUARANTORS
APPROVALS
LEDGER
EXPENSES
REPORTS
RULES
RBAC
SECURITY
```

Audit records should contain:

```text
actor
action
entity
entity ID
timestamp
old state
new state
request metadata
reason
```

Audit history is immutable.

---

# 24. RBAC Model

Future roles:

```text
SUPER_ADMIN
ADMIN
MEMBER_OFFICER
FINANCE_OFFICER
LOAN_OFFICER
APPROVER
AUDITOR
```

Permissions are more important than role names.

Examples:

```text
member.view
member.approve
member.suspend

savings.view
savings.verify
savings.withdraw.approve

loan.view
loan.review
loan.approve
loan.disburse

payment.view
payment.verify

ledger.view
ledger.reverse

report.view
report.export

rule.view
rule.propose
rule.approve

audit.view
```

A user may have multiple roles.

---

# 25. Multi-Level Approval Engine

Rather than hardcoding "two approvals" forever, build an approval engine.

## `approval_policies`

```sql
id
entity_type
action
required_approvals
allow_self_approval
active
created_at
```

Current configuration:

```text
LOAN / APPROVE
required_approvals = 2
allow_self_approval = false
```

Future policies could support:

```text
Expense approval
Rule-change approval
Withdrawal approval
Large loan approval
```

---

# 26. Loan Security / Collateral Model

The current playbook specifically describes guarantors and secured savings.

Future design:

## `security_records`

```sql
id
loan_id
security_type
owner_profile_id
reference_id
secured_amount
status
created_at
released_at
```

Security types:

```text
SAVINGS
GUARANTOR
OTHER
```

Only enable additional security types after formal approval.

---

# 27. Reporting Architecture

Build reports from controlled views/services rather than UI-specific queries.

Examples:

```text
member_savings_summary
loan_portfolio_summary
loan_overdue_summary
liquidity_summary
income_summary
expense_summary
monthly_financial_summary
member_statement
```

Useful materialized views can be introduced later for performance.

---

# 28. Dashboard Metrics

## Management dashboard

```text
Active Members
Pending Applications

Total Member Savings
Available Cash
Outstanding Loans
Loanable Funds
30% Reserve
Secured Savings

Active Loans
Overdue Loans
Defaults

Member Service Charge Income
Outsider Service Charge Income
Penalty Income
Operating Expenses
Net Income
```

## Member dashboard

```text
Savings Balance
Available Savings
Locked Savings

Current Monthly Obligation
Current Payment Status

Active Loan
Outstanding Loan
Next Installment
Due Date

Recent Transactions
Notifications
```

---

# 29. Advanced Notifications

Events:

```text
MEMBERSHIP_APPROVED
MEMBERSHIP_REJECTED

SAVING_DUE_SOON
SAVING_OVERDUE
SAVING_PAYMENT_CONFIRMED
SAVING_WITHDRAWAL_APPROVED

LOAN_SUBMITTED
GUARANTOR_REQUIRED
GUARANTOR_APPROVED
GUARANTOR_REJECTED

LOAN_APPROVED
LOAN_REJECTED
LOAN_DISBURSED
INSTALLMENT_DUE_SOON
INSTALLMENT_OVERDUE
LOAN_DEFAULT

PAYMENT_RECEIVED
PAYMENT_VERIFIED
PAYMENT_REJECTED

RULE_CHANGED
ANNOUNCEMENT_PUBLISHED
```

---

# 30. Scheduled Processing

Create centralized jobs for:

```text
monthly savings generation
late savings detection
savings penalty generation
loan installment generation
loan overdue detection
loan penalty generation
60-day default detection
notification dispatch
monthly report creation
payment reconciliation
financial-period processing
```

All scheduled jobs must be idempotent.

---

# 31. Offline / Reliability Strategy

For financial operations:

- Prefer online confirmation.
- Do not treat local success as financial posting.
- Queue non-financial UI actions only when safe.
- Financial writes require server confirmation.
- Use idempotency keys for payments and financial mutations.

Never let offline mode create an unverifiable money movement.

---

# 32. Integration Strategy

## Current

```text
Manual payment verification
Wallet
Bank transfer
```

## Later

```text
Payment Provider API
Bank API
Webhook
Automatic reconciliation
SMS provider
Push notification provider
Email provider
```

Integrations should sit behind interfaces:

```text
PaymentGateway
NotificationGateway
BankGateway
IdentityVerificationGateway
```

so a provider can be replaced without changing domain logic.

---

# 33. API / Service Boundary

Recommended service layer:

```text
AuthService
MembershipService
SavingsService
PaymentService
LoanService
GuarantorService
ApprovalService
LedgerService
LiquidityService
NotificationService
ReportService
GovernanceService
AuditService
RuleService
```

Financial examples:

```text
SavingsService.recordContribution()

LoanService.evaluateEligibility()

LoanService.calculateServiceCharge()

LiquidityService.checkLoanCapacity()

ApprovalService.approveLoan()

PaymentService.verifyPayment()

LedgerService.postTransaction()

LedgerService.reverseTransaction()
```

---

# 34. Domain Events

Use events where they reduce coupling.

Examples:

```text
MemberApproved
SavingsObligationCreated
PaymentVerified
SavingsContributionPosted

LoanApplicationSubmitted
GuarantorAccepted
LoanApproved
LoanDisbursed

InstallmentBecameOverdue
LoanDefaulted

RuleVersionActivated
```

Events can trigger notifications, audit records and reports.

---

# 35. Security Architecture

Required:

```text
Supabase Auth
RLS
RBAC
Least privilege
Server-side validation
Encrypted transport
Secrets management
Audit logs
Idempotency
Rate limiting where needed
File access policies
```

Payment proofs and identity documents must not be publicly readable.

Storage access should use authorized policies and signed URLs where appropriate.

---

# 36. Data Integrity

Use database constraints wherever possible.

Examples:

```text
unique member number
unique application number
unique transaction reference
unique monthly savings obligation
unique provider webhook event
unique role/permission relationship
unique guarantor assignment
unique installment number per loan
```

Use database transactions for multi-record financial operations.

---

# 37. Testing Strategy

## Unit tests

- Savings penalty
- Loan service charge
- Installment calculation
- Late penalty
- Eligibility
- Liquidity check
- Default calculation
- Rule lookup

## Integration tests

- Payment -> ledger
- Loan approval -> disbursement
- Repayment -> installment -> ledger
- Withdrawal -> liquidity
- Guarantor -> loan application
- Reversal -> corrected balance

## Security tests

- RLS
- Role permissions
- Self-approval prevention
- Unauthorized data access
- Storage access

## Financial invariants

```text
Every posted transaction is balanced.
No financial record is hard deleted.
A reversal references an original.
A loan cannot be approved without required approvals.
A duplicate webhook cannot post twice.
A duplicate scheduled job cannot duplicate a penalty.
```

---

# 38. Release Plan Beyond MVP

## Phase A - MVP

```text
Auth
Membership
Savings
Payments
Ledger
Loans
Guarantors
Approvals
Repayment
Defaults
Dashboard
Reports
Audit
```

## Phase B - Operational maturity

```text
Advanced RBAC
Loan officer role
Finance officer role
Notifications
Push/email
Better reporting
Expense management
Period closing
Reconciliation
Document management
```

## Phase C - Automation

```text
Payment API
Bank API
Automatic verification
Webhooks
Automated reconciliation
SMS
Scheduled report delivery
```

## Phase D - Financial intelligence

```text
Advanced liquidity analytics
Portfolio analytics
Delinquency analytics
Forecasting
Management dashboards
Export automation
```

## Phase E - Governance / Advanced finance

```text
Rule approval workflow
Dividend engine
Tax engine
Advanced accounting
Financial statements
Audit workflows
Potential restructuring workflows
```

---

# 39. Dividend Design Decision

The previous conversation considered a 15% dividend rate and pro-rata time basis.

The current playbook, however, does not define a final dividend rule.

Therefore:

```text
DO NOT activate a production dividend calculation
until the business formally approves:
```

1. Whether the rate is a declared target or guaranteed rate.
2. How distributable profit is determined.
3. What portion of profit can be distributed.
4. Time-weighting method.
5. Minimum eligibility period.
6. Treatment of withdrawals.
7. Tax treatment.
8. Approval authority.
9. Payment timing.
10. Reversal/correction rules.

The database should be prepared now, but the calculation remains disabled until approved.

---

# 40. Tax Design Decision

Likewise, no tax rate should be hardcoded until the business confirms applicable rules.

Create configurable tax rules and effective dates.

---

# 41. Full System Folder Structure

```text
lib/
├── core/
│   ├── config/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── security/
│   ├── routing/
│   ├── storage/
│   ├── utils/
│   └── widgets/
│
├── shared/
│   ├── entities/
│   ├── enums/
│   ├── models/
│   ├── repositories/
│   └── services/
│
├── features/
│   ├── auth/
│   ├── profile/
│   ├── membership/
│   ├── members/
│   ├── savings/
│   ├── payments/
│   ├── wallet/
│   ├── banking/
│   ├── loans/
│   ├── guarantors/
│   ├── approvals/
│   ├── transactions/
│   ├── ledger/
│   ├── liquidity/
│   ├── expenses/
│   ├── reports/
│   ├── dividends/
│   ├── tax/
│   ├── notifications/
│   ├── announcements/
│   ├── governance/
│   ├── audit/
│   ├── documents/
│   └── settings/
│
└── main.dart
```

---

# 42. Core Product Invariants

These should remain true throughout the life of the application:

### Financial

```text
Member savings != group income
Group income != group expense
Ledger is authoritative
Posted transactions cannot be deleted
```

### Loan

```text
Loan <= configured maximum
Member loan eligibility is enforced
Outsider requires guarantor
Two-person approval is enforced
Liquidity reserve is enforced
```

### Guarantor

```text
Active member only
Maximum one outstanding outsider guarantee
Electronic consent required
```

### Governance

```text
No self-approval
Rule changes are versioned
Audit records are immutable
Conflicts are recorded
```

---

# 43. Production Readiness Checklist

Before handling real money:

- [ ] RLS fully audited
- [ ] RBAC fully audited
- [ ] Production secrets separated
- [ ] Database backups configured
- [ ] Restore procedure tested
- [ ] Ledger invariants tested
- [ ] Payment idempotency implemented
- [ ] Financial transaction reversal tested
- [ ] Approval workflow tested
- [ ] Liquidity calculation independently verified
- [ ] Default process tested
- [ ] Storage policies tested
- [ ] Audit logs immutable
- [ ] Monitoring enabled
- [ ] Error reporting enabled
- [ ] Financial reports reconciled manually
- [ ] Business owner signs off on financial rules
- [ ] Legal/compliance review completed where applicable

---

# 44. Final Product Architecture

```text
                         UNITY FINANCE
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
      MEMBER               OUTSIDER               STAFF
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
                     AUTH + RBAC + RLS
                              │
        ┌─────────────────────┼─────────────────────────┐
        │                     │                         │
   MEMBERSHIP              SAVINGS                   LOANS
        │                     │                         │
        │               ┌─────┴─────┐          ┌───────┴────────┐
        │               │           │          │                │
        │          Contributions Withdrawals Guarantor       Approval
        │                                      │                │
        └──────────────────────┬───────────────┴────────────────┘
                               │
                            PAYMENTS
                               │
                         TRANSACTION
                               │
                            LEDGER
                               │
            ┌──────────────────┼──────────────────┐
            │                  │                  │
        LIQUIDITY          REPORTING          GOVERNANCE
            │                  │                  │
            │              DASHBOARDS        RULES/AUDIT
            │                  │                  │
            └──────────────────┼──────────────────┘
                               │
                    INTEGRATIONS (FUTURE)
                               │
              Payment APIs / Banks / SMS / Email
```

---

# 45. Final Design Principle

The system should be built as a **financial domain application**, not as a collection of CRUD screens.

Every financial action follows:

```text
Validate
   ↓
Authorize
   ↓
Record
   ↓
Post
   ↓
Audit
   ↓
Notify
```

And when something goes wrong:

```text
Never delete money history.

Reverse it.
Correct it.
Audit it.
```

That principle should remain unchanged as the product grows.
