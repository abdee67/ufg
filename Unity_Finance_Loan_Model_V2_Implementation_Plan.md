# Unity Finance — Loan Model V2: Database, RPC & UI/UX Implementation Plan

**Version:** 2.0  
**Date:** 2026-09-07  
**Target stack:** Flutter + BLoC/Clean Architecture + GetIt + GoRouter + Supabase Auth + PostgreSQL/RLS/RPC  
**Migration target:** Existing Unity Finance MVP schema + previous Loan SQL/RPC migration

---

## 1. Purpose

This revision replaces the previous loan model with the finalized business model:

- Member and outsider loan applications are separate database entities.
- Both member and outsider applications require an active member guarantor.
- Members authenticate normally and can apply from the member app.
- Outsiders have no Supabase Auth account and start from the public Welcome/Login entry point.
- The guarantor is selected during application and must accept/reject electronically before the application can proceed to normal review.
- Member maximum loan is `MIN(member_total_savings * 2, 20,000 ETB)`.
- Outsider maximum loan is `MIN(guarantor_total_savings * 2, 20,000 ETB)`.
- The previous member rule `borrower savings + guarantor savings >= requested amount` is removed.
- The old outsider 50% guarantor coverage rule is removed/replaced by the 200% guarantor-savings rule.
- The 10% member service charge and 15% outsider service charge remain.
- The 3-month repayment structure remains.
- The 5% late installment penalty remains.
- The 60-day serious-default threshold remains.
- The 30% liquidity reserve remains.
- Two distinct authorized approvals remain required.
- No self-approval remains prohibited.
- Final liquidity must still be checked immediately before disbursement.

This document is the implementation contract for the revised loan slice. The supplied Unity Finance playbook remains the governing business source for rules that were not changed here.

---

# 2. Final Business Rules

## 2.1 Member loan

A member may apply only when the existing member-loan eligibility conditions are satisfied:

1. Member is active.
2. Member has saved for at least two months.
3. Member has no overdue loan.
4. Required monthly contribution is fulfilled according to the current savings rules.
5. An active member guarantor is selected.
6. The guarantor accepts electronically.
7. Requested amount does not exceed the member's calculated maximum.
8. Group liquidity permits the loan at review/disbursement time.
9. Any repayment-capacity assessment remains a management/manual review item until an exact formula is formally approved.

### Member maximum formula

```text
member_max_loan = MIN(member_total_savings * 2, 20,000)
```

Example:

```text
Savings = 7,000
2x savings = 14,000
Maximum loan = 14,000 ETB
```

Example:

```text
Savings = 15,000
2x savings = 30,000
Global cap = 20,000
Maximum loan = 20,000 ETB
```

**Removed rule:**

```text
borrower savings + guarantor savings >= requested amount
```

This must not appear in SQL, RPCs, Flutter validation, or admin UI.

---

## 2.2 Outsider loan

An outsider:

- has no `auth.users` account;
- has no member record;
- cannot log into the member app;
- applies through a public outsider-loan entry point;
- must nominate an active member guarantor;
- must provide the minimum applicant information required by the approved application form;
- waits for the guarantor's electronic decision before the application moves to ordinary review.

### Outsider maximum formula

```text
outsider_max_loan = MIN(guarantor_total_savings * 2, 20,000)
```

Example:

```text
Guarantor savings = 6,000
2x guarantor savings = 12,000
Maximum outsider loan = 12,000 ETB
```

Example:

```text
Guarantor savings = 15,000
2x guarantor savings = 30,000
Global cap = 20,000
Maximum outsider loan = 20,000 ETB
```

The previous `guarantor savings >= 50% of requested amount` condition is not used.

---

## 2.3 Shared guarantor rules

Both loan types use an active member as guarantor.

The guarantor must:

- be an active member;
- not be the borrower for a member loan;
- receive the application details needed to make an informed decision;
- explicitly accept or reject electronically;
- remain responsible according to the approved group rules until the loan is fully repaid or an approved replacement is recorded.

The existing one-outstanding-outsider-guarantee rule remains:

```text
A member may guarantee at most one outstanding outsider loan at a time.
```

This rule is enforced in PostgreSQL, not only in Flutter.

The database does not impose an invented one-guaranty limit for member loans unless a future governance decision adds one.

---

# 3. Revised Domain Model

```text
                        UNITY FINANCE LOANS

                    ┌───────────────┐
                    │   Applicant   │
                    └───────┬───────┘
                            │
                ┌───────────┴───────────┐
                │                       │
             MEMBER                  OUTSIDER
                │                       │
       loan_applications      outsider_loan_applications
                │                       │
                └───────────┬───────────┘
                            │
                    Required guarantor
                            │
              ┌─────────────┴─────────────┐
              │                           │
   member_loan_guarantors      outsider_loan_guarantors
              │                           │
              └─────────────┬─────────────┘
                            │
                      GUARANTOR DECISION
                            │
                   Eligibility evaluation
                            │
                       Admin review
                            │
                    Approval #1 + #2
                            │
                       Disbursement
                            │
                         loans
                            │
                       installments
```

The application tables are intentionally separate because their identity, authentication model, applicant data, RLS model, and public/private access model are different.

---

# 4. Database Changes

## 4.1 `loan_applications`

Keep this table for authenticated members only.

Maintain:

- `applicant_profile_id`
- `member_id`
- `loan_product_id`
- `requested_amount`
- `purpose`
- `eligibility_status`
- `eligibility_snapshot`
- `eligibility_evaluated_at`
- `approved_amount`
- timestamps/status fields

New/revised behavior:

- product must be `member`;
- `member_id` must identify the authenticated applicant's active membership;
- guarantor lives in `member_loan_guarantors`;
- the submission RPC receives `p_guarantor_member_id`;
- savings are calculated server-side.

---

## 4.2 `outsider_loan_applications`

Create a dedicated table.

Recommended fields:

```text
id
application_number
loan_product_id
applicant_full_name
applicant_phone
applicant_address
requested_amount
purpose
eligibility_status
eligibility_snapshot
eligibility_evaluated_at
approved_amount
submitted_at
reviewed_at
created_at
updated_at
```

No `profile_id`, `auth.users` reference, or `member_id` is required.

Applicant information is a snapshot of the application. It is not a substitute for a member profile.

---

## 4.3 `member_loan_guarantors`

Create a dedicated member guarantee table.

Recommended fields:

```text
id
loan_application_id
guarantor_member_id
requested_amount_snapshot
service_charge_rate_snapshot
total_repayment_snapshot
term_months_snapshot
status
requested_at
responded_at
rejected_reason
created_at
updated_at
```

The guarantor does not need to expose their savings balance to the borrower. Savings are only evaluated server-side where needed.

---

## 4.4 `outsider_loan_guarantors`

Create a dedicated outsider guarantee table.

Recommended fields:

```text
id
outsider_loan_application_id
guarantor_member_id
requested_amount_snapshot
service_charge_rate_snapshot
total_repayment_snapshot
term_months_snapshot
guaranteed_max_amount_snapshot
status
requested_at
responded_at
rejected_reason
created_at
updated_at
```

`guaranteed_max_amount_snapshot` represents the maximum amount supported by the guarantor at the time of the request:

```text
MIN(guarantor_total_savings * 2, 20,000)
```

The actual loan cannot exceed this snapshot during the current application workflow.

A final server-side recheck occurs before admin approval and again before disbursement.

---

## 4.5 `loan_approvals`

Keep one common approval table for finalized loan applications, but allow either application source:

```text
loan_application_id                 nullable
outsider_loan_application_id        nullable
```

Database constraint:

```text
exactly one of the two references must be populated
```

Use separate partial unique indexes for each application source.

Two distinct approved decisions remain mandatory.

---

## 4.6 `loan_eligibility_checks`

Extend the existing audit table so an eligibility check may belong to either:

```text
loan_application_id
outsider_loan_application_id
```

Exactly one must be set.

This preserves an auditable explanation of why an application passed or failed.

---

## 4.7 `loans`

The final loan entity remains common to both products.

Use:

```text
loan_application_id              nullable
outsider_loan_application_id     nullable
borrower_profile_id              nullable
member_id                        nullable
```

Constraint:

```text
MEMBER LOAN:
  loan_application_id IS NOT NULL
  outsider_loan_application_id IS NULL
  borrower_profile_id IS NOT NULL
  member_id IS NOT NULL

OUTSIDER LOAN:
  loan_application_id IS NULL
  outsider_loan_application_id IS NOT NULL
  borrower_profile_id IS NULL
  member_id IS NULL
```

This avoids a polymorphic `borrower_id` while keeping one common `loans` table for repayment and accounting.

---

# 5. Authoritative Calculation Rules

All authoritative money and eligibility calculations happen in PostgreSQL.

Flutter may display previews, but it must never submit:

```text
member_total_savings
member_max_loan
outsider_max_loan
guarantor_total_savings
liquidity_amount
loanable_funds
```

as authoritative inputs.

The backend calculates them again.

## Member calculation

```text
member_total_savings = posted balance of member savings account
member_max_loan = MIN(member_total_savings * 2, 20,000)
```

## Outsider calculation

```text
guarantor_total_savings = posted balance of guarantor savings account
guarantor_supported_amount = MIN(guarantor_total_savings * 2, 20,000)
```

## Application amount

```text
requested_amount <= calculated maximum
```

If it fails, the RPC rejects the transition instead of relying on a UI error.

---

# 6. RPC Design

## 6.1 Member submission

```text
submit_member_loan_application(
  p_loan_product_id,
  p_requested_amount,
  p_purpose,
  p_guarantor_member_id
)
```

Server actions:

1. Verify authenticated user.
2. Verify `loan.apply` permission.
3. Resolve current member from `auth.uid()`.
4. Verify active membership.
5. Verify product is `member`.
6. Calculate member total savings.
7. Calculate `MIN(savings * 2, 20,000)`.
8. Reject if requested amount exceeds that maximum.
9. Verify guarantor is an active member and is not the borrower.
10. Create member application.
11. Create pending member-guarantor request.
12. Return application summary and guarantor status.

The RPC must not trust a client-supplied member ID or savings balance.

---

## 6.2 Outsider guarantor lookup

```text
search_outsider_loan_guarantors(p_search)
```

Callable anonymously.

Return only minimal fields such as:

```text
member_id
member_number
display_name
```

Do not return:

- savings balance;
- phone number;
- address;
- loan history;
- financial transactions;
- private profile information.

The search RPC must not be a generic `SELECT` endpoint.

---

## 6.3 Outsider submission

```text
submit_outsider_loan_application(
  p_full_name,
  p_phone,
  p_address,
  p_requested_amount,
  p_purpose,
  p_guarantor_member_id
)
```

Server actions:

1. Validate public input.
2. Verify outsider product is active.
3. Verify guarantor is active.
4. Verify guarantor is not already responsible for another outstanding outsider loan.
5. Calculate guarantor total savings.
6. Calculate `MIN(guarantor savings * 2, 20,000)`.
7. Reject requests over that amount.
8. Create outsider application.
9. Create pending outsider-guarantor request.
10. Return an application reference and safe status information.

No Supabase Auth user is created.

Because this is an anonymous financial endpoint, production deployment should also add edge/API-level abuse controls such as rate limiting, request throttling, and duplicate-submission protection.

---

## 6.4 Member guarantor response

```text
respond_to_member_loan_guarantor_request(
  p_guarantor_id,
  p_decision,
  p_rejection_reason
)
```

Only the authenticated guarantor can execute it for their assigned guarantee.

Accept/reject is atomic and auditable.

---

## 6.5 Outsider guarantor response

```text
respond_to_outsider_loan_guarantor_request(
  p_guarantor_id,
  p_decision,
  p_rejection_reason
)
```

Same authorization model, but reads/writes the outsider guarantee table.

---

## 6.6 Member eligibility evaluation

```text
evaluate_member_loan_application(p_application_id)
```

Checks:

```text
active member
minimum two months savings history
no overdue loan
current mandatory saving condition
member amount <= MIN(savings * 2, 20,000)
guarantee accepted
liquidity snapshot
repayment capacity = manual review unless formula configured
```

No combined borrower + guarantor savings test exists.

---

## 6.7 Outsider eligibility evaluation

```text
evaluate_outsider_loan_application(p_application_id)
```

Checks:

```text
active guarantor exists
guarantor accepted
guarantor still active
guarantor still eligible to guarantee another outsider loan
guarantor-supported max = MIN(guarantor savings * 2, 20,000)
requested amount <= supported max
liquidity snapshot
```

The outsider applicant does not need a Supabase session.

---

## 6.8 Admin review

Use separate commands:

```text
review_member_loan_application(...)
review_outsider_loan_application(...)
```

The function must:

- verify the reviewer permission;
- reload the authoritative application row;
- re-evaluate the relevant eligibility/security rules;
- reject self-approval;
- record the decision;
- require two distinct approved reviewers before moving the application to approved.

---

## 6.9 Disbursement

Disbursement is still a separate command.

Before inserting the final `loans` row / posting financial transactions, re-check:

```text
application approval state
guarantee state
member/guarantor eligibility where applicable
approved amount
current liquidity
30% reserve
no duplicate disbursement
```

This protects against a situation where savings or available cash changed after approval.

---

# 7. UI/UX Flow — Member Applicant

## Entry

Member Dashboard → Loans → Apply for Loan

### Screen 1 — Loan product / introduction

Show:

- Member Loan
- Service charge: 10%
- Repayment period: 3 months
- Maximum allowed: calculated from savings, capped at 20,000 ETB
- Current maximum amount
- Clear eligibility status

Do not present `20,000` as though every member automatically qualifies for it.

Example:

```text
Your current savings
12,000 ETB

Your maximum loan
20,000 ETB

Maximum reached because the group cap is 20,000 ETB.
```

Or:

```text
Your current savings
6,000 ETB

Your maximum loan
12,000 ETB
```

---

## Screen 2 — Amount

Use a premium amount editor rather than a generic form field.

Show dynamically:

```text
Requested        10,000 ETB
Service charge    1,000 ETB
Total repayment  11,000 ETB
Monthly payment   3,666.67 ETB
```

The values are displayed from server/product rules.

Use server response as the authority after submission.

---

## Screen 3 — Purpose

Purpose is a simple, accessible input.

Keep the UI intentionally lightweight.

---

## Screen 4 — Choose guarantor

Searchable member picker.

Show:

```text
Member number
Display name
```

Do not show the guarantor's savings balance to the borrower.

When selected:

```text
Guarantor selected
Awaiting their approval
```

---

## Screen 5 — Review & submit

Summarize:

```text
Loan amount
Service charge
Total repayment
3 monthly installments
Purpose
Guarantor
```

Primary CTA:

```text
Submit loan request
```

After submission, the status should become:

```text
Waiting for guarantor
```

---

## Screen 6 — Application status

Use a timeline/state indicator:

```text
Application submitted       ✓
Guarantor approval          ●
Eligibility check           ○
Admin review               ○
Approval 1                 ○
Approval 2                 ○
Disbursement               ○
```

Do not show a fake progress percentage. Financial workflows are not loading bars wearing business clothes.

---

# 8. UI/UX Flow — Member as Guarantor

Dashboard → Notifications / Guarantees

## Guarantee request card

Show:

- Applicant name
- Loan amount
- Service charge
- Total repayment
- Period
- Monthly installment
- Responsibility warning
- Request date

Actions:

```text
Reject
Accept
```

Require a confirmation step for Accept.

For Reject, allow a short reason.

After accepting:

```text
Guarantee accepted
```

The request becomes immutable except through approved replacement/release workflows.

---

# 9. UI/UX Flow — Outsider Applicant

## Public entry

Welcome/Login → `Need a loan?` / `Apply as outsider`

Do not expose member dashboard navigation.

---

## Screen 1 — Public introduction

Clearly explain:

- outsider loan is available without membership;
- an active Unity Finance member must guarantee the application;
- maximum loan depends on guarantor savings and the 20,000 ETB cap;
- the guarantor must approve electronically.

---

## Screen 2 — Applicant details

Collect only approved fields:

```text
Full name
Phone number
Address
Purpose
```

Keep the form privacy-conscious.

---

## Screen 3 — Requested amount

Once a guarantor is selected, the public flow can show a server-calculated supported maximum.

Do not calculate it from a client-entered savings value.

The UI should say:

```text
Maximum supported by this guarantor
12,000 ETB
```

The server must return this value from the RPC.

---

## Screen 4 — Choose guarantor

Search member number/name.

Only minimal member identity is displayed.

Upon selection:

```text
Guarantor: Mohamed A.
Status: Request will be sent for approval
```

Do not expose savings details.

---

## Screen 5 — Submit

Show:

```text
Requested amount
15% service charge
Total repayment
3-month schedule
Guarantor
```

Primary CTA:

```text
Submit application
```

---

## Screen 6 — Reference/status receipt

Because the outsider has no account, return a non-guessable application reference.

Do not make the reference itself a public read credential.

The initial MVP can show:

```text
Application submitted
Reference: UFG-OUT-XXXXXX

Your guarantor must approve the request.
```

For future outsider self-service status, introduce a separate verified mechanism rather than allowing anyone who knows the reference to view financial data.

---

# 10. UI/UX Flow — Admin

The admin loan area should separate the queue visually by applicant type:

```text
Loans
├── Member Applications
├── Outsider Applications
├── Guarantor Requests
├── Approval Queue
├── Disbursement Queue
├── Active Loans
├── Repayments
├── Overdue / Defaults
└── Audit
```

## Application inbox

Recommended columns:

```text
Application
Applicant
Type
Amount
Guarantor
Eligibility
Status
Submitted
Action
```

Use clear type labels:

```text
MEMBER
OUTSIDER
```

Do not hide the distinction behind an icon alone.

---

## Admin application detail

### Summary header

```text
Applicant
Loan type
Requested amount
Calculated maximum
Service charge
Total repayment
Term
Guarantor
Current status
```

### Eligibility section

Show each backend check:

```text
Active member              PASS
Saving history             PASS
No overdue loan            PASS
Monthly saving             PASS
Maximum amount             PASS
Guarantor                  PASS
Liquidity                  PASS
Repayment capacity         MANUAL REVIEW
```

For outsider:

```text
Guarantor active            PASS
Guarantor accepted          PASS
Guarantor supported max     PASS
Requested amount            PASS
Outstanding outsider guarantee  PASS
Liquidity                   PASS
```

### Approval section

Display:

```text
Approval 1     Approved by ...
Approval 2     Pending
```

Do not allow the same user to fill both approval slots.

---

# 11. Member vs Outsider UI Differences

| Area | Member | Outsider |
|---|---|---|
| Authentication | Supabase Auth | None |
| Application table | `loan_applications` | `outsider_loan_applications` |
| Applicant identity | profile/member | application snapshot |
| Guarantor | required | required |
| Maximum | `MIN(savings × 2, 20k)` | `MIN(guarantor savings × 2, 20k)` |
| Service charge | 10% | 15% |
| Loan cap | 20,000 ETB | 20,000 ETB |
| Member saving history | Required | Not applicable |
| Overdue member loan check | Required | Not applicable to outsider |
| Public submission | No | Yes, controlled RPC |
| Status login | Member session | No public financial status lookup by reference alone |

---

# 12. Flutter Architecture Changes

Recommended module structure:

```text
features/
  loans/
    data/
      datasources/
        member_loan_remote_data_source.dart
        outsider_loan_remote_data_source.dart
        guarantor_remote_data_source.dart
        loan_remote_data_source.dart
      models/
        member_loan_application_model.dart
        outsider_loan_application_model.dart
        member_loan_guarantor_model.dart
        outsider_loan_guarantor_model.dart
        loan_eligibility_model.dart
        loan_installment_model.dart
        loan_model.dart
      repositories/
        loan_repository_impl.dart
    domain/
      entities/
        member_loan_application.dart
        outsider_loan_application.dart
        member_loan_guarantor.dart
        outsider_loan_guarantor.dart
        loan_eligibility.dart
        loan.dart
      repositories/
        loan_repository.dart
      usecases/
        submit_member_loan.dart
        submit_outsider_loan.dart
        search_guarantors.dart
        respond_to_member_guarantee.dart
        respond_to_outsider_guarantee.dart
        get_my_loan_applications.dart
        get_my_loans.dart
        get_guarantee_requests.dart
    presentation/
      bloc/
      pages/
        member/
        outsider/
        guarantor/
      widgets/
```

The outsider flow may be placed behind a public route in GoRouter and must not depend on an authenticated session.

---

# 13. RPC / Data Source Contract

Do not expose raw inserts for authoritative loan state.

Flutter calls commands such as:

```text
submit_member_loan_application
submit_outsider_loan_application
respond_to_member_loan_guarantor_request
respond_to_outsider_loan_guarantor_request
evaluate_member_loan_application
evaluate_outsider_loan_application
review_member_loan_application
review_outsider_loan_application
disburse_loan
```

Read operations may use RLS-protected views/tables where appropriate, but mutations of authoritative loan state stay inside controlled RPCs.

---

# 14. Security Model

Follow this boundary:

```text
Flutter / Admin Browser
        ↓
Supabase Auth where applicable
        ↓
Controlled RPC
        ↓
Permission / ownership validation
        ↓
Row locks + state validation
        ↓
Authoritative calculation
        ↓
Atomic mutation
        ↓
Ledger
        ↓
Audit log
```

For anonymous outsider submission:

```text
Public Flutter screen
        ↓
Controlled anonymous RPC
        ↓
Strict input validation
        ↓
Minimal member lookup
        ↓
Server-side savings calculation
        ↓
Atomic outsider application + guarantor request
```

Security-definer functions must use a pinned empty `search_path` with fully-qualified object names, and their `EXECUTE` privilege must be explicitly restricted. Supabase's current documentation recommends this pattern. citeturn101219search0turn101219search2

New public tables should not be assumed to be reachable through the Supabase Data API. Current Supabase behavior requires explicit grants for newly created public-schema tables as the platform rollout progresses, so the migration explicitly manages grants/RLS rather than relying on historical defaults. citeturn101219search6

---

# 15. State Machine

## Member application

```text
SUBMITTED
   ↓
WAITING_FOR_GUARANTOR  [represented by application + guarantee state]
   ↓
ELIGIBLE / INELIGIBLE
   ↓
UNDER_REVIEW
   ↓
APPROVED / REJECTED
   ↓
READY_FOR_DISBURSEMENT
   ↓
ACTIVE LOAN
```

Because the existing database enum does not contain a dedicated `waiting_for_guarantor` value, use guarantor state as the source for the waiting sub-state rather than expanding enums casually.

## Outsider application

```text
SUBMITTED
   ↓
WAITING_FOR_GUARANTOR
   ↓
ELIGIBLE / INELIGIBLE
   ↓
UNDER_REVIEW
   ↓
APPROVED / REJECTED
   ↓
READY_FOR_DISBURSEMENT
   ↓
ACTIVE LOAN
```

---

# 16. Migration Safety

The supplied SQL migration is designed as a V2 modification of the previous loan migration.

Before applying:

1. Back up the development database.
2. Confirm whether any existing `loan_guarantors` rows represent real test data.
3. Review whether previous loan functions have already been used in production/dev data.
4. Apply the migration in development first.
5. Run the verification SQL at the end of the migration.
6. Run cross-user RLS tests.

The migration uses a legacy rename for the old polymorphic guarantor table instead of silently deleting it. If the old table is unused, it can later be removed in a separate cleanup migration after verification.

---

# 17. Required Tests

## Member maximum

```text
Savings 5,000 -> max 10,000
Savings 10,000 -> max 20,000
Savings 15,000 -> max 20,000
```

## Outsider maximum

```text
Guarantor savings 5,000 -> max 10,000
Guarantor savings 10,000 -> max 20,000
Guarantor savings 15,000 -> max 20,000
```

## Removed rule regression

Verify that:

```text
borrower savings + guarantor savings
```

has no effect on member eligibility.

## Member restrictions

- inactive member rejected;
- less than two saving months rejected;
- overdue loan rejected;
- unmet current saving requirement rejected;
- no guarantor rejected;
- requester cannot select self as guarantor;
- amount above calculated max rejected.

## Outsider restrictions

- cannot access member application RPC;
- no `auth.users` required;
- inactive guarantor rejected;
- guarantor already guaranteeing an outstanding outsider loan rejected;
- amount above `MIN(guarantor savings * 2, 20k)` rejected;
- no direct table insert permitted to anonymous clients.

## Guarantor

- only assigned guarantor can respond;
- duplicate response rejected/idempotently handled;
- rejected guarantee blocks normal eligibility until replaced through an approved replacement flow.

## Approval

- one approver cannot count twice;
- applicant cannot self-approve;
- two distinct approvals required;
- approval does not automatically disburse.

## Security

- anonymous cannot read outsider applications;
- authenticated non-guarantor cannot read another member's guarantee request;
- member A cannot read member B's loan;
- client cannot directly update authoritative statuses;
- service-role/secret keys are never used in Flutter.

---

# 18. Definition of Done

```text
[ ] Separate member and outsider application tables are active.
[ ] Both applicant types require a guarantor.
[ ] Member max = MIN(savings * 2, 20,000).
[ ] Outsider max = MIN(guarantor savings * 2, 20,000).
[ ] Old borrower + guarantor combined-savings test is removed.
[ ] Old outsider 50% guarantee rule is removed.
[ ] Member and outsider guarantor tables are separate.
[ ] Outsider can submit without Supabase Auth.
[ ] Outsider cannot read internal loan data anonymously.
[ ] Guarantor decisions are server-authorized and audited.
[ ] One-outstanding-outsider-guarantee rule is database-enforced.
[ ] Two distinct approvals remain enforced.
[ ] Self-approval remains blocked.
[ ] 30% liquidity reserve remains enforced.
[ ] Final liquidity check remains mandatory before disbursement.
[ ] Ledger remains authoritative for financial balances.
[ ] Existing repayment/default functionality remains compatible.
[ ] Flutter member flow matches the revised state machine.
[ ] Flutter outsider flow is public and session-independent.
[ ] Guarantor flow clearly communicates responsibility.
[ ] Admin UI distinguishes member vs outsider applications.
[ ] RLS and RPC authorization tests pass.
[ ] Anonymous outsider abuse controls are planned before production.
[ ] Migration verification SQL passes.
```

---

# 19. Implementation Order

```text
1. Apply loan V2 SQL migration in development.
2. Verify tables, constraints, indexes, functions, grants and RLS.
3. Seed/update loan product configuration.
4. Test member maximum calculation.
5. Test outsider maximum calculation.
6. Test member guarantor workflow.
7. Test outsider guarantor workflow.
8. Test two-person approval.
9. Test disbursement and ledger behavior.
10. Update Flutter models/entities/repositories.
11. Implement member applicant screens.
12. Implement guarantor screens.
13. Implement outsider public flow.
14. Implement admin member/outsider queues.
15. Add polished loading/error/empty/confirmation states.
16. Run end-to-end security and concurrency tests.
```


---

# 15. Final V2 Change Log

This V2 plan supersedes the previous mixed borrower model.

## 15.1 Member loan formula

```text
member maximum = MIN(total member savings × 2, 20,000 ETB)
```

The previous condition:

```text
borrower savings + guarantor savings >= requested amount
```

is removed.

A guarantor is still mandatory because the approved group rule requires both member and outsider applicants to have an active member guarantor who electronically accepts or rejects the guarantee.

## 15.2 Outsider loan formula

```text
outsider maximum = MIN(guarantor total savings × 2, 20,000 ETB)
```

The previous `50% guarantor coverage` interpretation is removed. The guarantor does not need to cover the requested amount with a 50% threshold. Instead, the guarantor's total savings determine the supported maximum through the 200% formula.

## 15.3 Application separation

```text
Authenticated member
    → loan_applications
    → member_loan_guarantors

Unauthenticated outsider
    → outsider_loan_applications
    → outsider_loan_guarantors
```

An outsider does not receive a Supabase Auth account, profile, member row, or member savings account merely by submitting a loan application.

## 15.4 Approval model

Both application sources use the same operational approval rule:

```text
eligible / reviewable
    → approval #1
    → approval #2
    → APPROVED
    → disbursement
```

Two distinct authorized reviewers are required. A reviewer cannot approve the member's own application.

Approval amount is fixed after the first approval. The second reviewer cannot silently approve a different amount.

## 15.5 Final disbursement rule

Before money is released, PostgreSQL must re-check:

```text
application approved
+ two approved reviewers
+ accepted active guarantor
+ current savings-based maximum still supports approved amount
+ current liquidity reserve is compliant
+ current loanable funds >= approved amount
+ source account has enough funds
+ loan does not already exist
```

This protects against the very human habit of changing financial state between clicking "Approve" and clicking "Disburse".

## 15.6 Existing shared `loan_guarantors`

The migration deliberately leaves the old `public.loan_guarantors` table in place for historical compatibility. V2 does not create new records there.

Do not remove that table in the same migration unless the existing legacy functions, scheduled processors, policies, and historical data have been separately migrated and verified.

## 15.7 Outsider repayment boundary

Because outsiders do not have Auth accounts or member profiles, the previous generic authenticated repayment path is not sufficient for outsider repayments.

The UI/backend implementation must therefore keep outsider repayment as a distinct public workflow, normally using the outsider loan/application reference plus a second verifier such as the original applicant phone number, with payment proof and admin verification before ledger posting.

That identity/reconciliation mechanism is an implementation decision, not a new financial rule from the playbook. Do not invent an alternate borrower account model merely to reuse the member repayment screen.

---

# 16. Definition of Done for V2

The loan feature is not considered complete when the screens merely submit rows.

It is complete when:

```text
Database invariants enforced
RPC authorization enforced
Member application flow works
Member guarantor flow works
Outsider public application works
Outsider guarantor flow works
Eligibility snapshots persist
Member 200% + 20k formula is enforced server-side
Outsider guarantor 200% + 20k formula is enforced server-side
Two-person approval is atomic
Final liquidity gate is atomic
Disbursement is idempotent
Repayment schedule is generated from stored principal/service values
Late-penalty/default processors remain functional
Audit events exist for material state changes
RLS prevents cross-member/cross-application access
Flutter displays server truth rather than duplicating business calculations
Admin UI can operate both application sources without mixing their identities
```
