# Unity Finance Group (UFG)

A mobile-first financial services application built with Flutter, designed to empower cooperative members and external users with transparent, accessible, and cooperative-driven finance tools. UFG enables members to manage savings, request loans, track obligations, and apply for membership — all from a single Android client.

## Project Overview

UFG is a Unity Finance Group cooperative finance application that provides a seamless mobile experience for managing personal savings, applying for loans, and tracking cooperative membership status. The app serves both registered members and non-members (outsiders) who can apply for limited loan products without full membership.

## Core Features

### Authentication
- Email and password sign-in / sign-up
- OTP-based email verification
- Password reset flow with OTP confirmation
- Persistent session handling with secure storage
- Automatic session refresh and startup session check

### Membership
- Membership application submission
- Real-time membership status tracking
- Status-aware UI (pending, active, rejected)
- Post-login membership check and redirect

### Savings
- Personal savings account balance and summary
- Monthly savings obligation tracking with deadlines
- Contribution history with searchable transactions
- Savings payment submission with proof upload
- Withdrawal request creation and cancellation
- Withdrawal request history and status tracking

### Loans
- Browse active loan products
- Loan eligibility evaluation
- Submit loan applications with guarantor support
- Search and select guarantors from members
- Respond to guarantor requests (accept / decline)
- Track active loans and installment schedules
- Loan extension requests
- Loan repayment submission with payment proof
- Cancel pending loan applications
- **Outsider loan application** — non-members can apply for limited loan products

### Home & Dashboard
- Personalized greeting and quick stats
- Search and category-based navigation
- Trending services shortcuts
- Pull-to-refresh data sync

## Architecture

The project follows a **Clean Architecture** pattern with feature-based modularization:

```
lib/
├── core/           # Shared constants, widgets, utils, routing, error handling
├── features/       # Feature modules (auth, savings, loans, membership, home, dashboard)
│   └── [feature]/
│       ├── data/       # Data sources, models, repository implementations
│       ├── domain/     # Entities, repository contracts, use cases
│       └── presentation/  # BLoC, pages, widgets
├── injection_container.dart  # Dependency injection (get_it)
└── main.dart
```

### State Management
- **flutter_bloc** for predictable, testable state management
- Separate BLoC per feature (auth, savings, loans, membership, home)
- Event-driven architecture with explicit state classes

### Dependency Injection
- **get_it** service locator for lazy singleton registration
- Factory pattern for BLoC instances

### Navigation
- **go_router** for declarative, type-safe routing
- Route constants centralized in `AppRoutes`
- Stateful shell route for bottom navigation

### Backend Integration
- **Supabase** for authentication, database, and RPC functions
- **dio** for additional HTTP requests
- **flutter_secure_storage** for token persistence
- **shared_preferences** for non-sensitive local data

## Tech Stack

| Category | Tools |
|----------|-------|
| Framework | Flutter 3.x / Dart 3.12+ |
| State Management | flutter_bloc, equatable |
| DI | get_it |
| Routing | go_router |
| Backend | Supabase (Postgres, Auth, RPC) |
| HTTP | dio, http |
| Storage | flutter_secure_storage, shared_preferences |
| UI | google_fonts, iconsax_flutter, flutter_animate, animated_text_kit |
| File Picker | file_picker, otp_text_field |
| Form | dartz (Either) |

## Getting Started

### Prerequisites
- Flutter SDK `^3.12.2`
- Android Studio / VS Code with Flutter plugin
- A configured Supabase project (set credentials in `assets/env/.env`)

### Install dependencies
```bash
flutter pub get
```

### Run
```bash
flutter run
```

### Build release APK
```bash
flutter build apk --release
```

## Environment Configuration

Create `.env` and `.env.local` files under `assets/env/`:

```
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
```

These are loaded at runtime via `flutter_dotenv`.

## Project Structure Highlights

- `lib/core/constants/` — app-wide design tokens (colors, sizes, icons, routes, text styles, images)
- `lib/core/widgets/` — reusable UI components (app bar, text field, cards, chips, error / empty states)
- `lib/core/routes/app_router.dart` — central `GoRouter` configuration
- `lib/features/<feature>/presentation/bloc/` — BLoC layer per feature
- `supabase/migrations/` — versioned SQL migrations for the Postgres schema and RPCs

## Database Migrations

SQL migrations live in `supabase/migrations/` and are applied in chronological order. The project uses a date-prefixed naming convention (`YYYYMMDDhhmmss_description.sql`).

Notable migrations include:
- Loan model v2 (loans, installments, guarantors, extensions)
- Savings RPCs and account auto-creation
- RLS hardening and policy fixes

## Code Conventions

- Conventional commits (`feat:`, `fix:`, `chore:`, `refactor:`, `docs:`, `db:`)
- Feature-first directory layout
- Clean Architecture: data → domain → presentation
- Use cases as single-purpose classes injected into BLoC
- Models extend entities via `fromEntity` / `toEntity` for clean separation

## License

Private — Unity Finance Group. All rights reserved.
