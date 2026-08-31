# Unity Finance - Auth & Membership Implementation Prompt

## Role

Act as a senior Flutter/Dart + Supabase engineer implementing production-quality foundations for a financial/member-management application called **Unity Finance**.

Work directly in the existing Flutter project. Do not introduce NestJS, Node.js, Express, Python, or another backend framework.

The backend architecture is:

- Flutter + Dart client
- Supabase Auth
- Supabase PostgreSQL
- PostgreSQL RLS
- PostgreSQL RPC/database functions for atomic business operations
- Supabase Storage for private documents
- Supabase Edge Functions only when server-side/external integration logic is appropriate
- Supabase scheduled jobs/pg_cron for future recurring workflows

The app already uses Clean Architecture, BLoC/Cubit, GetIt and GoRouter. Preserve these architectural decisions unless a change is necessary for correctness.

---

# 1. Business Context

Unity Finance is a member-based savings/lending group.

The first vertical slice is:

```text
Auth -> Profile -> Membership Application -> Membership Approval -> Active Member
```

Current business rules relevant to this slice:

- Membership is voluntary.
- A person becomes a member after completing registration and making the required first contribution.
- Accurate identification and contact information are required.
- Member information must remain confidential.
- A member can later be suspended/removed for fraud, misuse of funds, or serious rule violations.
- The application must maintain an auditable membership history.
- The app must use the currently approved business rules, not hardcoded client-side values.

Important: For now we dont have memebrship fee payment for new members. so we can skip this step for now.

---

# 2. Identity Document Requirement - Fayda Upload

Do NOT ask members to manually type/store their Fayda/national-ID number in the application database.

Instead, the membership application must require the user to upload their Fayda/national-ID document/image.

Requirements:

- Use Supabase Storage.
- The bucket MUST be private.
- Never create a public URL for the document.
- Store only the secure storage object path and metadata in PostgreSQL.
- Do not store the Fayda number as a plain-text column.
- Do not put the document URL in public profile fields.
- Use a generated UUID filename, not the original filename.
- Restrict allowed MIME types to the supported image/PDF types chosen by the existing project.
- Enforce a reasonable maximum file size.
- The uploaded document must belong to the authenticated user's membership application.
- A member must not be able to read another applicant's Fayda document.
- Admin/authorized staff access must be controlled through Storage RLS and application authorization.
- Prefer short-lived signed URLs when an authorized reviewer needs to view a private document.
- Never store a long-lived signed URL in the database.
- Audit document upload, replacement, deletion, viewing/download authorization, and verification-status changes.

Recommended object path:

```text
membership-documents/{auth_user_id}/{application_id}/{generated_uuid}.pdf
```

or for images:

```text
membership-documents/{auth_user_id}/{application_id}/{generated_uuid}.jpg
```

Do not allow a client to choose arbitrary storage paths.

---

# 3. Authentication Architecture

Use Supabase Auth as the only credential/identity provider.

Do NOT create a custom password table.

Use:

- Email/password sign-up
- Email/password sign-in
- Password reset
- Email verification
- Session persistence
- Auth state listener
- Sign-out

Use Supabase Flutter APIs directly from the auth data source.

Registration should collect only identity/profile data needed for the current flow, such as:

```text
Full name
Email
Phone
Password
Password confirmation
```

Store profile data in `public.profiles`.

Do not use `raw_user_meta_data` / user metadata as an authorization source. Roles/permissions must come from the database/RLS model.

---

# 4. Roles

Initial roles:

```text
NON_MEMBER
MEMBER
ADMIN
SUPER_ADMIN
```

Do not implement authorization as hardcoded UI checks such as:

```dart
if (email == 'admin@example.com') ...
```

or role values stored in editable client-side/user metadata.

Use database-backed roles/permissions.

The user's initial role after registration is NON_MEMBER.

Approval of membership must atomically:

1. Create/activate the member record.
2. Assign MEMBER role.
3. Remove/deactivate NON_MEMBER role as appropriate.
4. Create membership status history.
5. Create audit record.
6. Ensure all operations succeed or all fail.

---

# 5. Membership Application Lifecycle

Implement this lifecycle:

```text
NON_MEMBER
   |
   v
Membership Application Draft
   |
   v
Submitted
   |
   v
Under Review
   |-------------------|
   v                   v
Approved             Rejected
   |
   v
ACTIVE MEMBER
```

Suggested statuses:

```text
DRAFT
SUBMITTED
UNDER_REVIEW
APPROVED
REJECTED
CANCELLED
```

Membership status:

```text
ACTIVE
SUSPENDED
REMOVED
INACTIVE
```

Do not allow duplicate active/pending membership applications for the same profile.

---

# 6. Membership Application Data

The application should contain:

- applicant/profile reference
- unique application number
- status
- submitted timestamp
- reviewed by
- reviewed timestamp
- rejection reason
- Fayda document object path
- document type
- document verification status
- audit timestamps

Do not add a Fayda/national-ID-number field.

Recommended document statuses:

```text
UPLOADED
UNDER_REVIEW
VERIFIED
REJECTED
REPLACEMENT_REQUIRED
```

Document verification is an admin process for this phase. Do NOT invent an external Fayda verification API or claim automated identity verification exists.

---


# 7. Supabase Database Design

Use PostgreSQL tables such as:

```text
profiles
roles
permissions
role_permissions
user_roles

membership_applications
members
membership_status_history

membership_documents

financial_rules
financial_rule_versions

audit_logs
```

Do not create unnecessary duplicate concepts such as both `customer` and `profile` for the same person.

---

# 8. RLS Requirements

Enable RLS on every exposed application table.

Member/non-member users should only access their own records.

Examples:

- A user can read their own profile.
- A user can create/read their own membership application.
- A user cannot read another user's membership application.
- A user cannot modify an approved/rejected application arbitrarily.
- A user cannot assign themselves MEMBER/ADMIN/SUPER_ADMIN.
- A user cannot modify roles/permissions.
- A user cannot create members directly.
- A user cannot directly insert audit logs.
- A user cannot directly post financial ledger entries.

Admin access must be permission-based.

Avoid policies that only say `TO authenticated`; authentication is not authorization.

Use ownership predicates and role/permission checks.

Be careful with UPDATE policies: define both `USING` and `WITH CHECK` where needed.

---

# 9. Storage RLS

Create a private bucket:

```text
membership-documents
```

Storage object policies must enforce:

### User upload

The authenticated user may upload only into a path belonging to their own auth UID and their own membership application.

### User read

Normally, a user may see their own uploaded application document if the business flow requires it.

### Admin read

Only authorized membership-review staff may access applicant documents.

### Delete/update

Do not let ordinary users freely delete or replace verified documents.

Any replacement should be an explicit business action and audited.

---

# 10. RPC / Database Function Architecture

Use PostgreSQL functions for atomic business operations.

Do not split approval into multiple independent client calls.

Example:

```text
approve_membership_application(application_id)
```

The function should validate:

- caller authorization
- application exists
- application is in an approvable state
- required Fayda document exists
- required payment state is satisfied, when payment verification is enabled
- applicant is not already an active member

Then atomically:

```text
membership_application -> APPROVED
members                -> INSERT/ACTIVATE
membership status      -> history record
roles                  -> MEMBER assigned
NON_MEMBER role        -> removed/deactivated as appropriate
audit log              -> created
```

If any operation fails, the entire approval transaction must roll back.

Likewise create a controlled rejection function.

Do not expose unsafe generic SQL RPC functions to the client.

Prefer `SECURITY INVOKER` by default. If `SECURITY DEFINER` is genuinely necessary, lock down `search_path`, explicit grants, and authorization checks.

---

# 11. Flutter Architecture Changes

Keep Clean Architecture.

Each feature should follow:

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

Do not put Supabase calls directly inside widgets.

Do not put business rules inside BLoCs.

Do not put SQL/RLS authorization logic in Flutter.

---


### Rename generic/client terminology

Prefer:

```text
profile
user
member
non_member
applicant
staff
admin
```

over:

```text
customer
client
```

### Authentication use cases

Keep:

```text
check_startup_session.dart
forgot_password.dart
reset_password.dart
sign_in.dart
sign_out.dart
sign_up.dart
```

Keep OTP use cases only if OTP is actually part of the approved auth flow. Do not retain dead OTP flows just because they already exist.

Remove or archive unrelated address/location auth use cases unless required by Unity Finance.

---

# 12. Recommended Updated Feature Structure

```text
lib/
├── main.dart
├── injection_container.dart
│
├── core/
│   ├── config/
│   │   ├── app_config.dart
│   │   └── supabase_config.dart
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── routes/
│   ├── security/
│   ├── theme/
│   ├── utils/
│   └── widgets/
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── auth_remote_data_source.dart
│   │   │   │   └── auth_remote_data_source_impl.dart
│   │   │   ├── models/
│   │   │   │   └── profile_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── profile_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── check_startup_session.dart
│   │   │       ├── forgot_password.dart
│   │   │       ├── get_current_profile.dart
│   │   │       ├── reset_password.dart
│   │   │       ├── sign_in.dart
│   │   │       ├── sign_out.dart
│   │   │       └── sign_up.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       ├── screens/
│   │       └── widgets/
│   │
│   ├── membership/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── membership_remote_data_source.dart
│   │   │   ├── models/
│   │   │   │   ├── membership_application_model.dart
│   │   │   │   ├── member_model.dart
│   │   │   │   └── membership_document_model.dart
│   │   │   └── repositories/
│   │   │       └── membership_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── membership_application_entity.dart
│   │   │   │   ├── member_entity.dart
│   │   │   │   └── membership_document_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── membership_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_membership_status.dart
│   │   │       ├── get_my_membership_application.dart
│   │   │       ├── submit_membership_application.dart
│   │   │       ├── cancel_membership_application.dart
│   │   │       └── upload_fayda_document.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       ├── pages/
│   │       └── widgets/
│   │
│   ├── dashboard/
│   └── home/
│
└── shared/
    └── widgets/
```

Do not create `api/` and `network/` abstractions that duplicate each other without a clear purpose. If `api_client.dart` is a generic HTTP client, keep it only for future external APIs. Supabase database access belongs in feature data sources.

---

# 13. Data Source Responsibilities

`AuthRemoteDataSource`:

- Supabase Auth sign-up
- Sign-in
- Sign-out
- Password reset
- Session state
- Current auth user

`MembershipRemoteDataSource`:

- Read own membership application
- Submit application
- Upload document
- Read membership status
- Call membership approval/rejection RPC only through authorized admin flows if this same client supports admin UI

Do not make one giant `SupabaseDataSource` for every module.

---

# 14. Upload Flow

Implement document upload safely:

```text
Pick file
   ↓
Validate MIME type
   ↓
Validate size
   ↓
Create/get draft application
   ↓
Generate UUID filename/path
   ↓
Upload to private bucket
   ↓
Save object path + metadata
   ↓
Audit event
   ↓
Submit application
```

If database metadata insertion fails after upload, clean up the orphaned object through a controlled cleanup process.

Do not expose the raw bucket URL to the app as a permanent access mechanism.

---

# 15. Membership UI

### Register

Collect:

```text
Full name
Email
Phone
Password
Confirm password
```

After successful registration:

```text
Email verification -> authenticated/session state according to Supabase configuration
```

Do not assume a session exists immediately after sign-up when email confirmation is enabled.

### Membership application page

Collect/display:

```text
Application information
Fayda document upload
Terms/rules acknowledgement
Submit
```

### Status page

Display:

```text
Not applied
Draft
Submitted
Under review
Approved
Rejected
```

For rejection, show the reason provided by authorized staff.

### Admin review

Show:

```text
Applicant details
Fayda document viewer
Application date
Review status
Approve
Reject
```

Do not show sensitive documents to unauthorized roles.

---

# 16. BLoC Requirements

Use explicit states such as:

```text
Initial
Loading
Authenticated
Unauthenticated
EmailVerificationRequired
Error
```

Membership:

```text
Initial
Loading
Draft
Submitted
UnderReview
Approved
Rejected
Error
```

Do not let widgets infer business states from null checks alone.

---

# 17. Error Handling

Map Supabase/Auth/storage/database errors to domain failures.

Use clear user-facing messages:

```text
Invalid credentials
Email verification required
Membership application already exists
Fayda document is required
Unsupported document type
Document too large
Application already reviewed
Unauthorized action
```

Do not display raw PostgreSQL/Supabase error payloads to users.

Log technical details through the project logger only in safe form.

---

# 18. Testing

Add tests for:

### Auth

- sign-up success
- duplicate account handling
- sign-in success/failure
- sign-out
- session restore
- email-confirmation state

### Membership

- create application
- duplicate application prevented
- upload validation
- own-record access
- status transitions
- rejection reason
- approval result

### Security

- non-member cannot become member by client-side update
- user cannot assign themselves admin
- user cannot read another applicant
- storage path traversal is impossible
- unauthorized document access is rejected
- membership approval requires authorized permission

### Database

- RLS policies
- membership approval atomicity
- duplicate membership prevention
- role assignment consistency
- audit logging

---

# 19. Do Not Do These Things

Do not:

- add NestJS
- add Express
- add a custom backend server
- store passwords in PostgreSQL
- store Fayda numbers as plain text
- make the Fayda bucket public
- trust user metadata for authorization
- let Flutter write directly to ledger tables
- let clients assign themselves roles
- hardcode 500 ETB throughout the Flutter app
- hardcode admin email addresses
- directly mutate membership status from an ordinary client
- delete financial/audit history
- create permanent public URLs for sensitive documents
- put Supabase secret/service-role keys in Flutter

---

# 20. Definition of Done

The implementation is complete only when:

1. A new user can register with Supabase Auth.
2. Profile creation is automatic and consistent.
3. New users are NON_MEMBER by default.
4. User can log in and restore session.
5. User can submit one membership application.
6. User must provide a private Fayda document before submission.
7. The Fayda number is not stored in the application database.
8. Document storage path is scoped to the user's identity/application.
9. RLS protects profiles and membership records.
10. Storage RLS protects documents.
11. Admin can review authorized applications.
12. Admin can approve/reject through atomic RPC/database logic.
13. Approval creates member + role + status history + audit record atomically.
14. Rejection stores a reason and audit record.
15. Users cannot manipulate their own role or membership state from Flutter.
16. Architecture remains Clean Architecture + BLoC + GetIt + GoRouter.
17. No legacy customer/client/address terminology remains in the Unity Finance domain unless specifically justified.
18. Automated tests cover the critical auth/membership/security paths.

---

# 21. Implementation Discipline

Before changing code:

1. Inspect the existing project files and dependencies.
2. Reuse working infrastructure where it is compatible.
3. Remove legacy concepts only after tracing references.
4. Do not create duplicate abstractions.
5. Make the smallest coherent architectural refactor.
6. Implement database/RLS/storage changes first where needed.
7. Then implement data/domain/presentation layers.
8. Run formatter, analyzer and tests.
9. Verify the complete happy path manually.
10. Report exactly what changed, what was verified, and any remaining manual Supabase Dashboard configuration.

Do not stop after writing code. Verify the implementation end-to-end.
