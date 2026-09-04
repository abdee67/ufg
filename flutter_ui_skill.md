# Flutter UI Skill — Premium SACCO / Cooperative Finance App

> **Purpose:** This skill is the canonical UI/UX + Flutter implementation standard for building a premium, trustworthy, modern SACCO financial application.
>
> **Primary rule:** The existing project theme and branding are the source of truth. This skill defines *how to design and implement* the UI, not what the brand colors, typeface, logo treatment, or visual identity should be.
>
> **Audience:** Senior Flutter engineers, product designers, UI engineers, and coding agents working inside an existing Flutter codebase.
>
> **Quality bar:** Production fintech quality. Every screen must be polished, adaptive, accessible, performant, consistent, testable, and faithful to the established product identity.

---

## 0. Non-negotiable operating rules

### 0.1 Existing branding always wins

Before changing or creating a UI, inspect the existing project for:

- `ThemeData` / `ColorScheme` / `TextTheme`
- custom theme extensions
- typography and font configuration
- spacing, radius, elevation, component tokens
- icon family
- logo and brand assets
- light/dark themes
- localization / text direction
- shared widgets and design-system primitives
- existing screen patterns that users already recognize

Do **not** create a second color palette, typography system, button language, card style, radius system, or icon language merely because it looks fashionable.

Use the existing theme as the design source of truth. Extend it only when a real semantic token is missing.

Preferred pattern:

```dart
final scheme = Theme.of(context).colorScheme;
final text = Theme.of(context).textTheme;
```

For custom semantic values, prefer a `ThemeExtension` rather than hardcoded values distributed across screens.

Never do this in feature widgets:

```dart
Container(
  color: const Color(0xFF123456),
)
```

unless that exact color is a deliberate asset-specific value and cannot be represented by the existing theme.

Flutter's Material 3 system is driven primarily by `ColorScheme`, `TextTheme`, and component themes. The framework recommends themes for sharing colors and typography consistently across the application. [Flutter Material 3](https://docs.flutter.dev/ui/design/material), [Flutter themes](https://docs.flutter.dev/cookbook/design/themes)

### 0.2 UI is not decoration

Treat UI as a product system.

Every important screen must answer:

1. What is the user's goal?
2. What information matters most?
3. What action is most important?
4. What could go wrong?
5. What happens while data is loading?
6. What happens when there is no data?
7. What happens when the network fails?
8. What happens after the action succeeds?
9. What happens if the user leaves and returns?
10. How does the screen behave with large text, keyboard, tablet, landscape, and accessibility services?

A screen that only looks good with mock data is not production-ready.

### 0.3 Financial UI requires trust

The visual language must communicate:

- clarity
- stability
- transparency
- control
- security
- accountability
- predictable outcomes

Avoid visual tricks that make financial information look ambiguous. A financial amount, payment status, saving contribution, loan balance, fee, or due date must never require the user to guess.

### 0.4 Avoid unnecessary novelty

Premium does not mean decorative.

Do not add:

- excessive gradients
- decorative blobs everywhere
- floating elements with no function
- excessive glassmorphism
- heavy shadows
- excessive motion
- tiny text
- low-contrast secondary text
- oversized hero sections that hide useful financial information
- custom controls where a standard Material component is clearer

A premium financial app should feel intentional, not like a Dribbble concept accidentally connected to a database.

---

# 1. Product UI philosophy

## 1.1 SACCO-specific design priorities

The visual hierarchy should favor financial truth over decoration.

Recommended hierarchy for member-facing screens:

**Primary:**
- available / total financial position
- saving status
- loan status / repayment status
- important pending actions

**Secondary:**
- recent transactions
- upcoming due dates
- contribution history
- membership information
- notices

**Tertiary:**
- educational content
- tips
- secondary shortcuts
- promotional information

Do not make promotional content visually overpower money-related information.

## 1.2 The user's mental model

Users should be able to understand the app as a small number of stable concepts:

- **Membership:** Who I am in the SACCO and whether I am active.
- **Savings:** What I have contributed, what is due, and my history.
- **Loans:** What I owe, what I can apply for, repayment schedule, guarantor requirements, and status.
- **Payments:** Money-related actions and verification states.
- **Transactions:** Immutable-looking financial history, with clear status.
- **Notifications:** Actions, reminders, approvals, and system messages.
- **Profile:** Personal and membership details.

Do not make the user understand internal database concepts.

For example, do not expose technical states like `pending_verification` or `rpc_failed`.

Instead display a human state:

> Payment verification in progress

with useful supporting information:

> Your receipt was submitted and is awaiting review.

---

# 2. Design-system hierarchy

The UI must be built in layers.

## Level 1 — Brand foundation

Owned by the existing project:

- brand colors
- logo
- typography
- iconography
- imagery
- brand personality

## Level 2 — Semantic design tokens

Translate branding into semantic roles:

```text
surface
surfaceContainer
surfaceContainerHigh
onSurface
onSurfaceVariant
primary
onPrimary
secondary
tertiary
outline
error
warning
success
info
```

Do not scatter raw values throughout widgets.

## Level 3 — Layout tokens

Define shared values for:

- page horizontal padding
- section spacing
- component gaps
- compact gaps
- card padding
- dialog padding
- control heights
- corner radii
- divider thickness

Use a coherent 4/8-based rhythm unless the existing branding system intentionally uses another rhythm. Android's current guidance recommends baseline grid increments around 4 and 8 dp and responsive margins. [Android layout grids](https://developer.android.com/design/ui/mobile/guides/layout-and-content/grids-and-units)

## Level 4 — Components

Examples:

```text
AppScaffold
AppPage
AppSection
AppCard
MoneyCard
BalanceCard
StatusChip
AmountText
PrimaryButton
SecondaryButton
DestructiveButton
AppTextField
MoneyInput
SearchField
AppListTile
TransactionTile
EmptyState
ErrorState
LoadingState
ConfirmationSheet
AppDialog
AppBottomSheet
DateSelector
AmountSelector
StatCard
ProgressCard
```

## Level 5 — Screens

Screens compose components. Screens should not reinvent components.

---

# 3. Flutter architecture requirements for UI work

Flutter's current architecture guidance strongly favors clear UI/data separation, repository boundaries, View/ViewModel separation, unidirectional data flow, dependency injection, and testability. Adapt the exact state-management technology to the existing project rather than replacing architecture merely for aesthetic reasons. [Flutter architecture recommendations](https://docs.flutter.dev/app-architecture/recommendations), [Flutter architecture guide](https://docs.flutter.dev/app-architecture/guide)

## 3.1 UI layer responsibilities

UI code should:

- render state
- collect user input
- invoke commands/events
- handle layout decisions
- present animation
- expose accessibility semantics

UI code should not:

- execute raw SQL
- calculate financial business rules
- make arbitrary backend calls
- implement business authorization
- mutate repositories directly
- duplicate server-side financial calculations

## 3.2 Keep widgets small by responsibility

Prefer:

```dart
class SavingsOverviewCard extends StatelessWidget {
  const SavingsOverviewCard({super.key, required this.state});

  final SavingsOverviewState state;

  @override
  Widget build(BuildContext context) {
    // Presentation only.
  }
}
```

over a giant screen containing hundreds of lines of intertwined layout and business logic.

Flutter's performance guidance also recommends breaking down large widget trees, minimizing build work, localizing state changes, and using `const` constructors where appropriate. [Flutter performance best practices](https://docs.flutter.dev/perf/best-practices)

## 3.3 State-driven rendering

Think in explicit UI states.

For every async financial screen, design at minimum:

```text
initial
loading
loaded
empty
refreshing
submitting
success
failure
partial/offline
```

Do not use one generic spinner for every state.

Example:

```dart
switch (state.status) {
  case SavingsStatus.loading:
    return const SavingsSkeleton();
  case SavingsStatus.loaded:
    return SavingsContent(data: state.data!);
  case SavingsStatus.empty:
    return const SavingsEmptyState();
  case SavingsStatus.failure:
    return SavingsErrorState(onRetry: onRetry);
}
```

---

# 4. Responsive and adaptive design

Responsive means the layout responds to available space. Adaptive means the UI chooses an appropriate presentation and input pattern for the available environment.

Flutter's current guidance recommends measuring the actual app window with `MediaQuery.sizeOf` or local constraints with `LayoutBuilder`, rather than assuming phone/tablet type or relying on orientation checks. [Flutter adaptive design](https://docs.flutter.dev/ui/adaptive-responsive/general), [Flutter adaptive best practices](https://docs.flutter.dev/ui/adaptive-responsive/best-practices)

## 4.1 Never design only for a single phone size

Every important feature must be checked at least against:

```text
Compact: ~320–599 logical px wide
Medium:  ~600–839 logical px wide
Expanded: >=840 logical px wide
```

These are practical engineering tiers, not sacred numbers. Use the available width and actual content constraints to decide whether a layout should change.

## 4.2 Prefer capability/space-based branching

Good:

```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth >= 840) {
      return const ExpandedDashboardLayout();
    }

    if (constraints.maxWidth >= 600) {
      return const MediumDashboardLayout();
    }

    return const CompactDashboardLayout();
  },
)
```

Avoid:

```dart
if (Platform.isAndroid) ...
if (isTablet) ...
if (orientation == Orientation.landscape) ...
```

when the actual decision is simply about available space.

Flutter explicitly advises against making layout decisions from hardware type or orientation alone. [Flutter adaptive best practices](https://docs.flutter.dev/ui/adaptive-responsive/best-practices)

## 4.3 Compact layouts

Phone layouts should prioritize:

- one clear content column
- strong visual hierarchy
- thumb-friendly primary actions
- short navigation paths
- predictable vertical scrolling
- bottom navigation for primary destinations when appropriate

A common member shell might be:

```text
┌──────────────────────────────┐
│ Header / contextual controls │
├──────────────────────────────┤
│                              │
│ Main content                 │
│                              │
│                              │
├──────────────────────────────┤
│ Home  Save  Loan  More       │
└──────────────────────────────┘
```

Keep the number of primary destinations controlled. Android's current navigation guidance recommends three to five destinations in a navigation bar at the same hierarchy level. [Android navigation patterns](https://developer.android.com/design/ui/mobile/guides/layout-and-content/layout-and-nav-patterns)

## 4.4 Medium layouts

Use the extra width to improve information density, not to enlarge every card.

Possible pattern:

```text
┌─────────────────────────────────────┐
│ Header                              │
├─────────────────────────────────────┤
│ Main content   │ Secondary content │
│                 │                   │
└─────────────────────────────────────┘
```

Examples:

- savings summary + contribution chart
- loan overview + upcoming payment
- transaction list + transaction detail

## 4.5 Expanded layouts

On tablets and desktop-sized windows:

- use navigation rail/drawer patterns where appropriate
- use constrained content widths
- prefer two-pane or three-pane layouts for data-heavy workflows
- keep primary reading columns comfortably narrow
- use extra space for additional information, not giant controls

Android's large-screen guidance explicitly recommends list-detail/pane layouts and warns against stretching buttons, fields, cards, dialogs, and other UI elements across the full width. [Android adaptive layouts](https://developer.android.com/design/ui/mobile/guides/layout-and-content/adapt-layout), [Android large screens](https://developer.android.com/guide/topics/large-screens/user-interface)

## 4.6 Constrained content

Never allow a form like this to become absurdly wide on a tablet:

```text
|--------------------------------------------------------------|
|                 FULL WIDTH TEXT FIELD                       |
|--------------------------------------------------------------|
```

Instead:

```text
|--------------------------------------------------------------|
|      |------------------------------|                       |
|      |       Form / content         |                       |
|      |------------------------------|                       |
|--------------------------------------------------------------|
```

Set meaningful `maxWidth` values for:

- forms
- dialogs
- reading columns
- authentication panels
- payment confirmation content
- detail panels

---

# 5. Safe areas, system UI, keyboard, and edge-to-edge

Respect display cutouts, system bars, rounded displays, foldables, and the keyboard.

Flutter's `SafeArea` and `MediaQuery` APIs are designed for this. Flutter recommends using `SafeArea` around content that must not be obscured and using `MediaQuery` for adaptive information such as window size, accessibility settings, and display features. [Flutter SafeArea and MediaQuery](https://docs.flutter.dev/ui/adaptive-responsive/safearea-mediaquery)

## 5.1 Standard screen scaffold

Preferred conceptual structure:

```dart
Scaffold(
  body: SafeArea(
    child: pageContent,
  ),
)
```

Do not blindly wrap the entire `Scaffold` in `SafeArea`; the correct boundary depends on intentional edge-to-edge behavior.

## 5.2 Keyboard-aware forms

Forms must:

- remain scrollable when the keyboard is visible
- keep the focused field visible
- keep the primary action reachable
- not depend on fixed-height columns
- avoid overflow when text scale increases

Use `SingleChildScrollView`, `CustomScrollView`, appropriate insets, and focus handling where needed.

Never ship a production financial form with:

```dart
Column(
  children: lotsOfFields,
)
```

inside a fixed-height viewport if keyboard appearance can make it overflow.

---

# 6. Spacing and visual rhythm

The best interface often feels expensive because of rhythm, alignment, and restraint rather than because it has complicated graphics.

## 6.1 Establish a spacing ladder

Use the existing design system first. If no spacing tokens exist, establish one centralized scale, for example:

```text
4   micro
8   tight
12  compact
16  standard
20  comfortable
24  section
32  major
40  large
48  hero
64  exceptional
```

Do not invent `17`, `19`, `23`, `27`, `31` pixel values casually throughout the project.

Exceptions are allowed when required for typography, asset alignment, or platform behavior, but should be intentional.

## 6.2 Alignment is a quality signal

Prefer consistent shared edges:

```text
Page margin
│
├── Section title
├── Supporting text
├── Card
│   ├── Icon
│   ├── Title
│   └── Content
└── Card
```

Avoid screens where every component has its own random left margin.

## 6.3 Whitespace is functional

Use whitespace to separate:

- concepts
- actions
- ownership boundaries
- primary vs secondary information
- dangerous vs safe operations

Do not fill every empty area simply because it exists.

---

# 7. Typography

## 7.1 Use semantic text styles

Prefer:

```dart
Theme.of(context).textTheme.titleLarge
Theme.of(context).textTheme.bodyMedium
```

over random local font sizes.

If a custom amount style is needed, define it as a shared semantic style.

## 7.2 Financial amounts need hierarchy

Money is often the most important information on a screen.

Example:

```text
Total savings

12,450.00 ETB

+500 ETB this month
```

The amount should be visually stronger than the label, while the delta remains subordinate but clear.

## 7.3 Avoid typographic ambiguity

Never make:

- ETB symbols too small
- decimal values unreadably tiny
- negative amounts hard to distinguish
- due dates visually weaker than irrelevant metadata

Use explicit, consistent formatting.

## 7.4 Text must survive scaling

Flutter respects operating-system text scaling. Design every screen to remain usable under large font settings. [Flutter accessibility styling](https://docs.flutter.dev/ui/accessibility/ui-design-and-styling)

Never rely on:

```dart
Text(
  'Some long text',
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
)
```

for critical financial information merely to protect a design.

A user's accessible text size outranks your card's aesthetic proportions.

---

# 8. Color system and semantic status

The actual colors must come from the existing brand theme.

## 8.1 Semantic meaning

Map states to semantic roles, not arbitrary decoration:

| State | Meaning |
|---|---|
| Success | Completed, approved, paid, active |
| Warning | Due soon, attention required, incomplete |
| Error | Failed, rejected, blocked |
| Info | Neutral information, pending guidance |
| Neutral | Historical / inactive / unknown |

A green color should not simultaneously mean "approved", "money", and "selected" unless the design system intentionally establishes that meaning.

## 8.2 Never communicate meaning by color alone

For example:

```text
✓ Approved
⏳ Pending review
! Payment failed
```

The icon + text carries meaning independently of color.

Flutter's accessibility guidance explicitly recommends ensuring controls remain usable in colorblind and grayscale conditions. [Flutter accessibility](https://docs.flutter.dev/ui/accessibility)

---

# 9. Elevation, surfaces, borders, and cards

Cards are useful for containment, not as decoration factories.

## 9.1 Use cards for related information

A card should answer:

> What belongs together?

Good:

```text
┌─────────────────────────────────┐
│ Savings                         │
│                                 │
│ 12,450 ETB                     │
│ +500 this month                │
│                                 │
│ View savings history →         │
└─────────────────────────────────┘
```

Bad:

```text
┌──────────────┐
│ icon          │
│ text          │
└──────────────┘
┌──────────────┐
│ another card │
└──────────────┘
┌──────────────┐
│ another card │
└──────────────┘
```

when all three are actually one conceptual group.

## 9.2 Prefer subtle separation

Use the existing theme's:

- surface roles
- outline colors
- elevation
- tonal contrast

Avoid strong shadows on every component.

## 9.3 Radius consistency

Use the project's radius tokens consistently.

A screen should not simultaneously contain:

```text
4 px cards
8 px buttons
18 px fields
32 px sheets
48 px random containers
```

unless those differences are intentional semantic levels in the system.

---

# 10. Dashboard design

The dashboard is the user's financial home.

## 10.1 Dashboard structure

A strong default hierarchy:

```text
Greeting / identity

Primary financial summary

Key actions

Savings status

Loan status

Recent transactions

Important notices
```

Do not put ten unrelated cards above the fold.

## 10.2 Primary financial summary

The first major visual should answer:

> What is my current position?

Examples:

```text
Total savings
12,450 ETB
```

or, depending on the business model:

```text
Savings balance      12,450 ETB
Outstanding loan      8,000 ETB
Next payment           800 ETB
```

Do not invent financial totals that the backend does not provide.

## 10.3 Quick actions

Use only the most important actions, such as:

```text
Save money    Apply for loan    Pay dues
```

or the actual actions supported by the product.

Each action must have:

- clear label
- recognizable icon
- large target
- disabled state when unavailable
- loading state when submitted
- feedback after completion

## 10.4 Avoid dashboard overload

A dashboard is not a database dump with rounded corners.

The user should understand the screen in seconds.

---

# 11. Savings UI

Savings is a core SACCO workflow and should feel especially trustworthy.

## 11.1 Savings overview

Recommended information hierarchy:

```text
Savings

Current balance

This month's contribution
Monthly requirement
Current month status

Contribution history
```

Where applicable, surface:

- contribution amount
- required amount
- paid amount
- remaining amount
- due date
- late status
- late fee / interest information
- verification status

## 11.2 Contribution progress

Progress can be represented visually:

```text
Monthly saving

500 / 500 ETB
██████████████████ 100%

Complete
```

The numeric values remain visible. Never require a user to infer a financial value from a progress bar.

## 11.3 Late payment

Late contributions are sensitive financial states.

Do not shame users.

Bad:

> You failed to save again.

Good:

> Monthly saving overdue
> Your contribution is due. The applicable late charge is shown below.

## 11.4 Savings history

Use a clean transaction/list model:

```text
Aug 30       +500 ETB
Monthly saving
Completed

Jul 30       +500 ETB
Monthly saving
Completed

Jun 30       +550 ETB
Monthly saving + late charge
Completed
```

Avoid excessive visual noise for every row.

---

# 12. Loan UI

Loan flows require the strongest information hierarchy because they combine money, eligibility, dates, obligations, approvals, and risk.

## 12.1 Loan overview

Recommended hierarchy:

```text
Loan status
Outstanding balance
Next payment
Due date
Repayment progress
Schedule
```

## 12.2 Eligibility

Eligibility should be understandable before the user begins an application.

Example:

```text
Loan eligibility

Eligible amount
Up to 2,000 ETB

Requirement
Active membership

Guarantor
1 eligible member
```

Do not hide material requirements until after the user spends time filling a form.

## 12.3 Application flow

Use a guided step flow when multiple decisions are involved:

```text
1. Amount
2. Purpose
3. Guarantor
4. Review
5. Submit
```

Each step should:

- display only relevant information
- preserve entered values
- validate before advancing
- show what remains
- support back navigation safely

## 12.4 Loan status vocabulary

Use stable user-facing statuses:

```text
Draft
Submitted
Under review
Awaiting guarantor
Approved
Disbursed
Active
Partially paid
Paid
Rejected
Cancelled
```

Exact vocabulary should match the backend/domain model, but UI labels must be human-readable.

---

# 13. Payments and receipt-upload UI

Where the SACCO uses manual payment verification, the payment UX must make the workflow explicit.

## 13.1 Payment instructions

Show:

1. amount
2. destination/account information
3. reference requirement
4. receipt/screenshot requirement
5. next verification step

Use a strong review layout:

```text
Payment amount
500 ETB

Send payment to
[ destination details ]

Reference
[ payment reference ]

Receipt
[ Upload receipt ]

[ I have completed the payment ]
```

## 13.2 Receipt upload

The upload control must show:

- empty state
- selected state
- uploading state
- uploaded state
- failed state
- remove/replace action

Do not merely display a tiny paperclip icon and assume the user understands what happened.

## 13.3 Verification states

After submission:

```text
Payment submitted

Your payment is awaiting verification.

Submitted: Sep 2, 10:42 AM
Amount: 500 ETB
Reference: ABC123

Status: Pending review
```

The screen should prevent accidental duplicate submissions while verification is pending.

---

# 14. National ID / Fayda upload UI

If the product requires a national ID document upload rather than entering an ID number, design the flow around document quality, privacy, and clear progress.

## 14.1 Upload flow

```text
National ID

Upload a clear image of your ID.

[ Front side ]
[ Upload image ]

[ Back side ]
[ Upload image ]

[ Continue ]
```

If only one document image is required by the business rule, do not add unnecessary second-side requirements.

## 14.2 Privacy copy

Use plain, calm copy describing why the document is requested and who handles it. Avoid unnecessary legal walls of text in the primary UI.

## 14.3 Document preview

After selection:

- show thumbnail/preview
- allow replace
- allow remove before submission
- show upload progress
- show failed upload recovery
- avoid exposing sensitive document previews in notifications or logs

---

# 15. Forms

Flutter provides `Form`, `TextFormField`, validation, focus behavior, and other form primitives. Use standard platform-aware form behavior unless the design system requires a custom component. [Flutter forms](https://docs.flutter.dev/cookbook/forms), [Flutter form validation](https://docs.flutter.dev/cookbook/forms/validation)

## 15.1 Form principles

Every financial form should have:

- clear labels
- meaningful input examples
- correct input keyboard
- field-level validation
- sensible error placement
- focus traversal
- disabled states
- submission loading
- success feedback
- retry behavior

## 15.2 Validate progressively

Avoid showing ten red errors the moment a screen opens.

Preferred:

- validate on interaction / field completion when appropriate
- validate all fields on submit
- preserve valid input
- focus the first failing field
- explain the fix

## 15.3 Error messages

Bad:

> Invalid input.

Better:

> Enter an amount between 100 ETB and 2,000 ETB.

Best error messages are:

- specific
- actionable
- close to the field
- non-technical

---

# 16. Buttons and actions

## 16.1 Primary action hierarchy

One screen should generally have one visually dominant primary action.

Examples:

```text
[ Submit application ]
```

not:

```text
[ Save ] [ Continue ] [ Submit ] [ Confirm ] [ Done ]
```

all visually equal.

## 16.2 Button states

Every actionable button must support, where relevant:

```text
Default
Pressed
Focused
Hovered
Disabled
Loading
Success / completed feedback
```

Material state-aware styling should be used through current Flutter APIs such as `WidgetStateProperty`; `MaterialStateProperty` is now a compatibility typedef and is deprecated in favor of the widgets-layer API. [Flutter API: MaterialStateProperty](https://api.flutter.dev/flutter/material/MaterialStateProperty.html)

## 16.3 Loading buttons

When an action is in progress:

- prevent duplicate submission
- keep layout stable when possible
- show a progress indicator or equivalent state
- do not make the user wonder whether the tap registered

---

# 17. Navigation

## 17.1 Navigation should express product hierarchy

Use primary navigation for stable top-level destinations only.

A sensible member navigation might include some variation of:

```text
Home
Savings
Loans
More
```

The exact destinations must match the real product structure.

## 17.2 Adaptive navigation

On larger windows, transition from bottom navigation to a rail or drawer where it improves ergonomics and hierarchy. Android guidance explicitly recommends adapting navigation to the window size instead of keeping a bottom bar on large screens. [Android navigation patterns](https://developer.android.com/design/ui/mobile/guides/layout-and-content/layout-and-nav-patterns)

## 17.3 Preserve navigation state

Switching between top-level destinations should not unexpectedly reset meaningful scroll position or form state.

Flutter's adaptive best practices also call out preserving/restoring application state during responsive layouts. [Flutter adaptive best practices](https://docs.flutter.dev/ui/adaptive-responsive/best-practices)

---

# 18. Lists and transaction history

## 18.1 Use lazy lists for unbounded/dynamic data

Prefer:

```dart
ListView.builder(...)
```

or sliver-based lists over constructing a huge list of every row at once.

Flutter's rendering performance guidance specifically warns against building large lists directly and recommends lazy list construction. [Flutter rendering performance](https://docs.flutter.dev/perf/rendering-performance)

## 18.2 Financial list row anatomy

A transaction row should make the following scannable:

```text
[icon]  Monthly saving              +500 ETB
        Aug 30, 2026 • Completed
```

For a more complex transaction:

```text
[icon]  Loan repayment              -800 ETB
        Installment 4 of 10
        Aug 30, 2026 • Completed
```

Do not rely on color alone to distinguish money in vs money out.

## 18.3 Use separators deliberately

Use dividers when they improve scanability. Do not put a divider after every tiny nested element.

---

# 19. Loading states and skeletons

A premium app does not flash an empty layout, spinner, then content when a skeleton can preserve structure.

## 19.1 Skeleton requirements

Skeletons should resemble the eventual content shape:

```text
██████████████
████████
████████████████████
```

Avoid skeletons that animate aggressively or create distracting shimmer across the whole screen.

## 19.2 Avoid layout jumps

The loaded layout should occupy approximately the same structural space as the skeleton.

Bad:

```text
Spinner
```

then suddenly:

```text
Large dashboard
```

Better:

```text
Dashboard-shaped skeleton
```

## 19.3 Pull-to-refresh

Use when the user can reasonably refresh the content.

The refresh interaction must not destroy already-visible data unnecessarily.

---

# 20. Empty states

Empty does not mean error.

Examples:

### No savings history

```text
No savings yet

Your contribution history will appear here once a saving is recorded.
```

### No loans

```text
No active loans

You don't currently have an active loan.

[ View eligibility ]
```

### No notifications

```text
You're all caught up

New updates and reminders will appear here.
```

Never display:

> No data.

That is technically correct and spiritually useless.

---

# 21. Error states and recovery

## 21.1 Errors should explain recovery

A production error state should answer:

- what happened
- whether the user's data is safe
- what can be done next

Example:

```text
Couldn't load your savings

Your saved information has not been changed.

[ Try again ]
```

## 21.2 Network failures

Distinguish:

```text
No internet connection
Server temporarily unavailable
Request timed out
Permission denied
Validation failed
Session expired
```

Do not expose raw backend messages unless they are safe and intentionally user-facing.

## 21.3 Preserve user input

When a network request fails after a form submission, do not silently erase the form.

---

# 22. Confirmation dialogs and bottom sheets

Use dialogs for decisions that need immediate confirmation.

Use bottom sheets for contextual actions that can be understood within the current task.

Typical confirmation:

```text
Submit loan application?

Amount        2,000 ETB
Guarantor     John Doe

You can no longer edit the application after submission.

[ Cancel ] [ Submit ]
```

For destructive or irreversible actions, describe the consequence precisely.

Avoid:

> Are you sure?

That sentence has survived decades of UI design without ever becoming more informative.

---

# 23. Toasts, snackbars, banners, and inline feedback

Use feedback based on importance.

### Inline

Use for field-level or context-specific information.

### Snackbar

Use for lightweight, transient confirmation or recoverable information.

### Banner / persistent callout

Use for important state that persists until addressed.

### Full-screen state

Use when the entire screen cannot function correctly.

Do not use snackbars for critical financial information that a user may miss.

For example, a completed payment reference should remain visible in the success state rather than appearing only for three seconds.

---

# 24. Motion and animation

Motion should explain change, preserve spatial relationships, and reinforce feedback.

Flutter provides implicit and explicit animation mechanisms, route transitions, and physics-based animation APIs. Use the least complex mechanism that creates the required behavior. [Flutter animation cookbook](https://docs.flutter.dev/cookbook/animation), [Flutter implicit animations](https://docs.flutter.dev/ui/animations/implicit-animations)

## 24.1 Good motion

Use subtle motion for:

- expanding/collapsing sections
- selection state
- progress changes
- page transitions
- loading completion
- newly available content
- bottom sheets
- status changes

## 24.2 Avoid ornamental animation

Do not animate:

- every card on first load
- every icon independently
- financial numbers unnecessarily every time the screen rebuilds
- large parallax effects on data-heavy screens

## 24.3 Motion duration

Use the existing design-system motion tokens when available.

If absent, use a small coherent set rather than dozens of timings:

```text
fast       ~120ms
standard   ~200ms
emphasis   ~300ms
```

These are implementation defaults, not immutable requirements.

## 24.4 Animation performance

Do not rebuild a large subtree on every animation tick when only a small child changes.

When using `AnimatedBuilder`, move static subtrees into `child` where appropriate.

Avoid expensive clipping, opacity layers, image filters, and `saveLayer` operations inside frequent animations. Flutter's performance documentation calls these out as common rendering costs. [Flutter performance best practices](https://docs.flutter.dev/perf/best-practices), [Flutter rendering performance](https://docs.flutter.dev/perf/rendering-performance)

## 24.5 Reduced-motion/accessibility

Do not make essential functionality dependent on animation.

Where platform accessibility settings indicate animation reduction or where motion would create usability problems, minimize nonessential transitions.

---

# 25. Performance-first UI engineering

Performance is part of visual polish. A beautiful interface that drops frames during scrolling is not polished.

## 25.1 Build performance

Rules:

- use `const` where appropriate
- split large widgets
- localize state updates
- avoid expensive computation in `build()`
- avoid repeated formatting/parsing work on every rebuild
- avoid rebuilding entire screens for tiny state changes
- prefer stable, focused widget boundaries

Flutter specifically recommends minimizing build cost, splitting complex widgets, localizing state changes, and using `const` constructors. [Flutter performance best practices](https://docs.flutter.dev/perf/best-practices)

## 25.2 Avoid unnecessary rebuilds

Do not subscribe a large dashboard widget to a state source if it only needs one field.

Prefer narrowly scoped listeners/selectors where the chosen state-management framework supports them.

## 25.3 Avoid intrinsic layout where possible

Be cautious with:

```dart
IntrinsicHeight
IntrinsicWidth
```

especially inside large, dynamic lists.

Prefer explicit constraints, flexible layouts, and predictable sizing.

## 25.4 Lists

For dynamic lists:

```dart
ListView.builder
SliverList
SliverGrid
```

Prefer lazy construction.

## 25.5 Images

Rules:

- avoid loading huge source images when a smaller rendition is sufficient
- specify meaningful cache dimensions where supported by the image layer
- use placeholders for remote images
- handle failures gracefully
- avoid decoding many massive images simultaneously

Flutter supports network image loading and placeholder/fade-in patterns. [Flutter network images](https://docs.flutter.dev/cookbook/images/network-image), [Flutter images cookbook](https://docs.flutter.dev/cookbook/images)

## 25.6 Opacity and clipping

Avoid `Opacity` and complex clipping where a cheaper rendering method is available.

For example, use a semitransparent color directly when appropriate rather than wrapping a whole subtree in `Opacity`.

Flutter identifies opacity, certain clipping operations, image filters, and `saveLayer` as potential performance costs. [Flutter performance FAQ](https://docs.flutter.dev/perf/faq)

## 25.7 Don't optimize by superstition

Do not add:

- `RepaintBoundary` everywhere
- caching everywhere
- obscure micro-optimizations
- custom render objects

without measurement.

Profile first, optimize the actual bottleneck, then verify the improvement.

## 25.8 Measure in profile mode

Do not judge release performance from debug mode.

Use Flutter DevTools Performance View and profile builds to investigate frame timing and rendering behavior. Flutter's current performance guidance explicitly recommends profile mode when analyzing frame performance. [Flutter Performance View](https://docs.flutter.dev/tools/devtools/performance), [Flutter rendering performance](https://docs.flutter.dev/perf/rendering-performance)

---

# 26. Frame-budget discipline

Flutter targets smooth rendering at typical 60 Hz and can render at higher refresh rates on capable devices. At 60 Hz, one frame is roughly 16 ms.

Treat expensive work inside a frame as a defect to investigate.

Watch for:

- janky list scrolling
- animation stutters
- expensive first-frame work
- heavy image decoding during gestures
- synchronous processing during button taps
- rebuild cascades

A UI should feel instant even when backend work is not instant.

Flutter's architecture guidance also highlights optimistic UI as a way to improve perceived responsiveness when an operation can safely reflect a result before background work fully completes. [Flutter optimistic state](https://docs.flutter.dev/app-architecture/design-patterns/optimistic-state)

For financial transactions, never use optimistic UI to claim money movement is complete unless the domain/backend contract actually supports that state. It is appropriate for low-risk presentation state, but financial truth must follow the authoritative backend result.

---

# 27. Accessibility

Accessibility is a baseline product requirement.

Flutter's accessibility guidance recommends at least 48×48 logical-pixel tappable targets, sufficient contrast, support for large text scaling, and semantics for assistive technologies. [Flutter accessibility](https://docs.flutter.dev/ui/accessibility), [Flutter UI design and styling](https://docs.flutter.dev/ui/accessibility/ui-design-and-styling)

## 27.1 Touch target

All interactive targets should normally provide at least:

```text
48 × 48 logical pixels
```

The visible icon may be smaller, but the interactive target must remain usable.

Android similarly recommends 48×48 dp minimum touch targets for touch interfaces. [Android accessibility](https://developer.android.com/guide/topics/ui/accessibility/apps.html)

## 27.2 Contrast

Target at least:

```text
4.5:1 normal/small text
3:1 large text
```

Use the existing brand colors, but modify semantic pairings where necessary to maintain readable contrast.

Do not solve insufficient contrast by making text smaller.

## 27.3 Screen readers

Use standard Flutter controls wherever possible because they provide semantics automatically.

For custom components, provide explicit `Semantics` where needed. Flutter's accessibility widgets documentation describes `Semantics`, `MergeSemantics`, and `ExcludeSemantics` for controlling the accessibility tree. [Flutter accessibility widgets](https://docs.flutter.dev/ui/widgets/accessibility)

## 27.4 Semantic labels for financial data

For example, a compact amount display should still be announced meaningfully.

Instead of forcing a screen reader to infer:

```text
+500
```

provide semantics equivalent to:

> Savings contribution, plus 500 Ethiopian birr, completed.

Do not duplicate announcements excessively when standard widgets already provide correct semantics.

## 27.5 Color blindness

A status must not be encoded solely as:

```text
red = rejected
amber = pending
green = approved
```

Use:

- icon
- text
- shape/style when helpful
- color as reinforcement

## 27.6 Keyboard / desktop

For larger windows and desktop targets:

- support focus states
- sensible keyboard traversal
- mouse hover where meaningful
- contextual menus where appropriate
- avoid hover-only information on critical controls

Android's current large-screen quality guidance includes keyboard, mouse, trackpad, and hover behavior for optimized experiences. [Android adaptive optimized](https://developer.android.com/guide/topics/large-screens/tier-2-overview)

---

# 28. Localization and Ethiopia-aware financial UI

Design for localization from the beginning even if the first release is one language.

## 28.1 Never assume text length

Do not design around exact English strings.

Labels can become longer because of:

- Amharic translations
- other local languages
- accessibility text
- future terminology changes

## 28.2 Currency display

The application should use a centralized money-formatting layer.

Do not format financial values manually throughout widgets.

Conceptually:

```dart
moneyFormatter.format(amount)
```

The formatter should own:

- currency code/symbol
- decimal precision
- grouping
- negative presentation
- localization

Do not scatter:

```dart
'ETB ${amount.toStringAsFixed(2)}'
```

across screens.

## 28.3 Dates

Use a centralized localized date/time formatter.

Do not manually concatenate date strings in feature widgets.

## 28.4 Text direction

Avoid hardcoded left/right assumptions where logical directional APIs are appropriate.

Prefer:

```dart
EdgeInsetsDirectional
AlignmentDirectional
BorderRadiusDirectional
```

when the design supports bidirectional layouts.

---

# 29. Iconography

Use one coherent icon family.

## 29.1 Icon rules

- icons support labels, they do not replace clear labels for unfamiliar actions
- icon sizes should follow shared tokens
- use filled/outlined variants consistently
- do not mix unrelated icon styles
- provide semantic labels for meaningful icon-only controls

## 29.2 Icon-only controls

An icon button such as:

```text
⋮
```

must have an accessibility label such as:

> More options

and an accessible hit target.

---

# 30. Charts and financial visualization

Charts are useful only when they reveal a pattern.

## 30.1 Never use charts as decoration

Good:

> Savings increased 18% over the last 6 months.

with a supporting chart.

Bad:

> random blue line chart

with no useful interpretation.

## 30.2 Charts must have a textual fallback

Critical information from a chart should also be available as text/list data.

For example:

```text
August savings: 500 ETB
July savings: 500 ETB
June savings: 550 ETB
```

## 30.3 Avoid misleading financial axes

Do not manipulate axes to exaggerate tiny changes.

Clearly label:

- date range
- values
- unit/currency
- positive/negative movement

---

# 31. Security-conscious UI

Financial UI should minimize accidental exposure.

## 31.1 Sensitive values

Support a hide/show pattern for highly sensitive balances where product requirements justify it.

Example:

```text
Total savings
••••••••
                 [ Show ]
```

When revealed, maintain clear accessibility semantics.

## 31.2 Clipboard

Do not automatically copy sensitive financial data without explicit user action.

## 31.3 Screenshots and previews

Avoid unintentionally exposing sensitive information in app previews where platform policies allow control.

The UI should not rely on obscurity as security, but it should practice sensible privacy by default.

## 31.4 Session-expiration UI

When a session expires:

- explain what happened
- avoid destroying unsaved input
- provide a clear re-authentication path
- never display raw authentication/backend errors

---

# 32. Permission UX

Permission requests should happen in context.

Do not request:

```text
camera
photos
notifications
location
contacts
```

all at once during launch merely because the app can.

Explain why the permission is needed before requesting it when the platform flow permits.

For example:

> We need access to your camera to capture your national ID clearly.

Then show the permission request.

---

# 33. Offline and poor-network design

A financial app should assume users can have unreliable connectivity.

## 33.1 Never fake financial certainty offline

If the current balance is stale, indicate that it is cached/stale where necessary.

Example:

```text
Savings balance
12,450 ETB

Last updated 10:41 AM
```

Do not display stale values as though they are live authoritative values when the distinction matters.

## 33.2 Preserve user intent

For forms and uploads:

- retain entered values where safe
- retry intelligently
- show progress
- avoid duplicate submissions
- clearly distinguish queued vs completed

---

# 34. Micro-interactions and polish

Premium polish comes from hundreds of small consistencies.

Check:

- button press feedback
- focus states
- list row hover on desktop
- sheet drag handle where appropriate
- keyboard behavior
- scroll physics
- loading transitions
- empty states
- disabled states
- status icon alignment
- baseline alignment
- truncation behavior
- divider alignment
- safe-area handling
- error recovery
- success confirmation
- back navigation

## 34.1 Avoid layout shifts

Do not let content jump because:

- a progress indicator appears
- a button changes width when loading
- an error line suddenly appears
- an icon loads asynchronously

Reserve structure where appropriate.

## 34.2 Press feedback

Users should immediately know a tappable control registered their interaction.

Use theme-consistent Material interaction states rather than custom animations everywhere.

---

# 35. Screen-specific UI standards

Every feature should implement these patterns consistently.

## Authentication

Required states:

```text
idle
validating
submitting
verification pending
success
error
```

Auth screens should be calm, focused, and low density.

## Home/dashboard

Required:

- clear financial summary
- key actions
- important status
- recent activity
- responsive layout

## Savings

Required:

- balance
- contribution status
- history
- due/late state when applicable
- add/save flow

## Loans

Required:

- eligibility
- loan status
- outstanding amount
- next payment
- schedule
- application flow
- guarantor state where applicable

## Payments

Required:

- amount
- instructions
- receipt/reference
- submission state
- verification state
- final result

## Notifications

Required:

- unread state
- category/status
- timestamp
- meaningful deep link/action where applicable
- read state persistence

## Profile

Required:

- identity
- membership state
- verification state
- account/security settings
- sign out

---

# 36. Design for every state, not just the happy path

Before marking any feature UI complete, explicitly design these variants:

```text
Loading
Loaded
Empty
Error
Disabled
Pending
Success
Failed
Partial data
Offline / stale
Large text
Compact width
Medium width
Expanded width
Keyboard visible
Accessibility service enabled
Dark theme, if supported
```

For financial actions also consider:

```text
already submitted
already paid
already approved
already rejected
expired
permission missing
session expired
duplicate submission
server timeout
```

---

# 37. Component API design

Shared components should encode behavior, not just appearance.

Bad:

```dart
AppButton(
  color: Colors.blue,
  radius: 18,
  height: 54,
)
```

Better:

```dart
PrimaryButton(
  label: 'Submit application',
  onPressed: onSubmit,
  loading: state.isSubmitting,
)
```

The shared component owns:

- typography
- spacing
- state visuals
- interaction feedback
- minimum target size
- loading behavior
- accessibility defaults

Feature code owns business meaning.

---

# 38. UI constants and theme extensions

Centralize reusable values.

Example conceptual extension:

```dart
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.pagePadding,
    required this.cardRadius,
    required this.sectionGap,
  });

  final double pagePadding;
  final double cardRadius;
  final double sectionGap;

  @override
  AppTokens copyWith({
    double? pagePadding,
    double? cardRadius,
    double? sectionGap,
  }) {
    return AppTokens(
      pagePadding: pagePadding ?? this.pagePadding,
      cardRadius: cardRadius ?? this.cardRadius,
      sectionGap: sectionGap ?? this.sectionGap,
    );
  }

  @override
  AppTokens lerp(covariant AppTokens? other, double t) {
    if (other == null) return this;

    return AppTokens(
      pagePadding: lerpDouble(pagePadding, other.pagePadding, t)!,
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t)!,
      sectionGap: lerpDouble(sectionGap, other.sectionGap, t)!,
    );
  }
}
```

Actual implementation must match the project's theme architecture.

Do not create tokens simply to make architecture look sophisticated. Tokens must solve repeated design decisions.

---

# 39. Suggested shared UI primitives

A mature SACCO codebase should converge toward a small, coherent set of primitives.

```text
core/ui/
  app_scaffold.dart
  app_page.dart
  app_section.dart
  app_card.dart
  app_button.dart
  app_text_field.dart
  app_dialog.dart
  app_bottom_sheet.dart
  app_status_chip.dart
  app_empty_state.dart
  app_error_state.dart
  app_skeleton.dart
  app_loading.dart
  app_divider.dart
  app_icon_button.dart
  app_avatar.dart
  app_list_tile.dart
  app_amount_text.dart
  app_money_formatter.dart
  responsive_layout.dart
  adaptive_navigation.dart
```

The real project structure may differ. Preserve the existing architecture and conventions.

---

# 40. Example responsive shell

Conceptual pattern:

```dart
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width >= 840) {
          return ExpandedShell(child: child);
        }

        if (width >= 600) {
          return MediumShell(child: child);
        }

        return CompactShell(child: child);
      },
    );
  }
}
```

The important architectural point is not the exact breakpoint. It is that the layout responds to actual constraints and that shared content remains reusable.

Flutter recommends this measure → branch approach for adaptive applications. [Flutter adaptive general approach](https://docs.flutter.dev/ui/adaptive-responsive/general)

---

# 41. Avoid common Flutter UI anti-patterns

## Anti-pattern: giant build method

Problem:

- hard to test
- hard to reason about
- expensive rebuilds become difficult to diagnose

Use focused widgets.

## Anti-pattern: hardcoded theme values

Problem:

- breaks branding consistency
- dark mode becomes painful
- future rebranding becomes expensive

Use theme tokens.

## Anti-pattern: screen-specific responsive hacks

Problem:

- inconsistent behavior
- unpredictable breakpoints
- duplicated layout logic

Create reusable responsive primitives.

## Anti-pattern: fixed dimensions everywhere

Problem:

- text overflow
- keyboard problems
- small device failures
- tablet whitespace problems

Prefer constraints and flexible layout.

## Anti-pattern: `Expanded` everywhere

`Expanded` is useful, but it does not mean every child should consume every pixel.

Use `ConstrainedBox`, `Flexible`, `SizedBox`, max-width containers, and proper composition where appropriate.

## Anti-pattern: `MediaQuery.of(context).size.width` everywhere

Prefer `MediaQuery.sizeOf(context)` for app-window size or `LayoutBuilder` when the layout depends on local constraints. [Flutter adaptive design](https://docs.flutter.dev/ui/adaptive-responsive/general)

## Anti-pattern: nested scrolling chaos

Avoid unnecessary combinations of:

```text
ListView
  inside SingleChildScrollView
    inside another ListView
```

Prefer a single intentional scrollable surface, commonly a `CustomScrollView` with slivers for complex screens.

## Anti-pattern: giant cards

Cards should contain related information. Do not wrap the entire page in one giant rounded rectangle merely because it is currently popular.

## Anti-pattern: spinner for everything

Use skeletons for content loading, inline indicators for local operations, button loading for submissions, and full-page progress only when necessary.

## Anti-pattern: generic error strings

Never ship:

```text
Something went wrong.
```

without a recovery path when the UI knows what happened.

---

# 42. Testing strategy for UI quality

Flutter's testing model includes unit, widget, and integration tests. Widget tests should verify rendering/interaction behavior, while integration tests cover complete flows and can also be used for performance verification. [Flutter testing overview](https://docs.flutter.dev/testing/overview)

## 42.1 Widget tests

Test:

- primary labels
- button enabled/disabled states
- loading state
- error state
- empty state
- form validation
- accessibility semantics where practical
- responsive branches

## 42.2 Golden tests

Use golden tests for high-value reusable components and critical screens where visual regression matters.

Examples:

```text
MoneyCard
StatusChip
LoanSummaryCard
SavingsOverviewCard
PaymentReviewCard
Dashboard compact
Dashboard expanded
```

Flutter's widget-testing tooling includes golden-file comparison through `matchesGoldenFile`. [Flutter widget testing](https://docs.flutter.dev/cookbook/testing/widget/introduction)

## 42.3 Integration tests

Critical journeys should be covered:

```text
Login
Membership onboarding
National ID upload
Savings contribution
Payment submission
Loan application
Loan repayment
Profile/security changes
```

The official `integration_test` package can execute flows on real devices/emulators. [Flutter integration testing](https://docs.flutter.dev/testing/integration-tests)

## 42.4 Responsive test matrix

Every major screen should be checked at least at:

```text
320 width
360 width
390 width
430 width
600 width
840 width
1024+ width
```

Also test:

```text
short height
large height
landscape
keyboard visible
large text
```

---

# 43. Visual QA checklist

Before accepting a screen, inspect it visually at 100% and real-device scale.

### Composition

- Is the primary action obvious?
- Is the most important financial information first?
- Are sections grouped logically?
- Is there unnecessary visual noise?

### Alignment

- Do major edges align?
- Are icons centered to their text correctly?
- Are card paddings consistent?
- Are section gaps consistent?

### Typography

- Correct semantic text styles?
- No accidental font weight mismatch?
- No truncation of critical financial information?
- Large text remains usable?

### Interaction

- Correct press states?
- Disabled state clear?
- Loading state clear?
- No duplicate submission?
- Keyboard works?
- Back navigation safe?

### Financial clarity

- Currency explicit?
- Positive/negative values distinguishable without color alone?
- Pending vs completed unmistakable?
- Due dates visible?
- Fees explicit?
- No misleading totals?

### Responsive

- Compact works?
- Medium works?
- Expanded works?
- No stretched forms/buttons?
- Navigation changes appropriately?

### Accessibility

- 48×48 targets?
- Contrast sufficient?
- Labels available to screen readers?
- Custom controls have semantics?
- Works in grayscale/color-vision scenarios?

### Performance

- Smooth scrolling?
- No obvious rebuild storms?
- Lists lazy?
- Images appropriately sized?
- No unnecessary opacity/filter/clipping?

---

# 44. Definition of Done for a UI screen

A UI screen is **not done** until all of the following are true:

```text
[ ] Existing theme/branding inspected and respected
[ ] No hardcoded brand colors in feature code
[ ] Typography uses semantic theme styles
[ ] Shared spacing/radius tokens used
[ ] Correct responsive behavior implemented
[ ] Safe area handled
[ ] Keyboard behavior verified where relevant
[ ] Loading state designed
[ ] Empty state designed
[ ] Error state designed
[ ] Disabled state designed
[ ] Submission state designed
[ ] Success state designed
[ ] Network failure path designed
[ ] Critical financial information clearly prioritized
[ ] Accessibility semantics checked
[ ] Touch targets meet minimums
[ ] Large text tested
[ ] Compact width tested
[ ] Medium width tested
[ ] Expanded width tested
[ ] Dark/light mode verified when supported
[ ] Widget tests added/updated
[ ] Golden coverage added for high-value reusable visuals
[ ] Integration flow updated for critical journeys
[ ] Profile-mode performance checked for heavy screens
[ ] No unnecessary rebuilds or expensive work in build()
[ ] No obvious layout jumps
[ ] Copy is human-readable and localized through project conventions
[ ] No raw backend/database errors shown to users
[ ] No duplicate-submit path
[ ] Code follows existing project architecture and naming conventions
```

---

# 45. Implementation workflow for a coding agent

When asked to implement or redesign a screen, follow this sequence.

## Step 1 — Inspect before coding

Read:

- existing theme
- routing
- shared widgets
- feature state classes
- existing responsive utilities
- localization
- current screen implementation

Do not immediately create new components.

## Step 2 — Identify the product job

State internally:

```text
User goal:
Primary information:
Primary action:
Secondary actions:
Risk / irreversible actions:
Loading state:
Failure state:
Empty state:
```

## Step 3 — Build the content hierarchy

Write the content structure before styling.

Example:

```text
Screen title
Primary financial summary
Key action
Status
History
Supporting information
```

## Step 4 — Build responsive composition

Start with structure:

```text
Page
 ├── header
 ├── primary content
 ├── supporting pane
 └── actions
```

Then define compact/medium/expanded behavior.

## Step 5 — Apply the existing theme

Use:

```dart
Theme.of(context).colorScheme
Theme.of(context).textTheme
```

and project-specific extensions/tokens.

## Step 6 — Add interaction states

Do not postpone:

- loading
- disabled
- error
- empty
- success

These are part of the component design.

## Step 7 — Optimize

Check:

- rebuild scope
- list construction
- image cost
- layout complexity
- animations

## Step 8 — Accessibility pass

Test:

- screen-reader semantics
- touch targets
- text scale
- contrast
- keyboard/focus where applicable

## Step 9 — Visual QA

Compare against the existing product language.

Ask:

> Does this look like the same product?

not:

> Does this look cool?

## Step 10 — Test

Add/update widget tests and critical integration coverage.

---

# 46. Senior implementation rules for coding agents

When modifying the existing codebase:

### Rule A — Do not rewrite architecture for UI work

A UI redesign is not permission to replace Bloc, Riverpod, Provider, GetX, clean architecture, repositories, or routing unless the task specifically requires it.

### Rule B — Prefer existing abstractions

Before creating:

```text
NewButton
NewCard
NewDialog
NewResponsiveHelper
NewSpacingConstants
```

search the project first.

Duplication is not premium engineering.

### Rule C — Do not couple UI to Supabase

A screen should consume feature state/repository interfaces rather than embedding database logic.

### Rule D — Do not move financial authority into the client

The Flutter UI may display calculated values, but authoritative financial rules must remain with the backend/domain source of truth.

### Rule E — Don't hide behavior inside visual widgets

A `MoneyCard` should display money. It should not secretly call the database.

### Rule F — Keep rebuild boundaries small

Subscribe only to the state required by a widget.

### Rule G — Prefer composable widgets to massive conditional trees

Instead of one `DashboardScreen` with hundreds of conditions, extract stable conceptual sections.

### Rule H — Don't use magic numbers as a layout system

Use centralized tokens.

### Rule I — Do not sacrifice accessibility for visual fidelity

If a design reference uses a 36×36 control but the action needs 48×48 minimum interactive size, preserve the visual size and expand the hit area rather than shrinking usability.

### Rule J — Don't invent product rules

The UI must reflect actual business rules from the domain/backend specification.

---

# 47. Recommended premium visual behavior

Without changing the project's branding, premium quality can be achieved through:

- strong typographic hierarchy
- precise spacing
- consistent alignment
- restrained elevation
- clear semantic surfaces
- carefully controlled motion
- high-quality loading states
- deliberate empty/error states
- excellent icon alignment
- responsive multi-pane layouts
- meaningful data visualization
- accessibility support
- fast interactions
- stable layouts

The goal is:

> **Calm, confident, precise, and trustworthy.**

not:

> **Look at all the widgets we can animate.**

---

# 48. Reference implementation patterns

## Page container

```dart
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.child,
    this.maxWidth = 1200,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppTokens>();

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens?.pagePadding ?? 16,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
```

This is conceptual. Match the project's actual theme/token implementation.

## Responsive two-pane

```dart
class ResponsiveTwoPane extends StatelessWidget {
  const ResponsiveTwoPane({
    super.key,
    required this.primary,
    required this.secondary,
  });

  final Widget primary;
  final Widget secondary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 840) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: primary),
              const SizedBox(width: 24),
              SizedBox(width: 360, child: secondary),
            ],
          );
        }

        return Column(
          children: [
            primary,
            const SizedBox(height: 24),
            secondary,
          ],
        );
      },
    );
  }
}
```

The exact dimensions should come from the product's component tokens and content requirements.

---

# 49. Review questions for senior-level UI code review

Before approving a UI pull request, ask:

### Product

- Does the hierarchy make the user's main goal obvious?
- Does the UI correctly represent the domain state?
- Could a member misunderstand a financial amount or obligation?

### Design system

- Does it reuse the existing theme?
- Does it look like the same app?
- Did the feature invent unnecessary visual primitives?

### Flutter engineering

- Are constraints understood correctly?
- Are lists lazy?
- Is rebuild scope reasonable?
- Is expensive work absent from `build()`?
- Are animations isolated?
- Are images handled responsibly?

### Responsive

- Does it adapt to available width?
- Does the layout make better use of large screens?
- Are controls constrained instead of stretched?
- Does navigation adapt?

### Accessibility

- Are touch targets usable?
- Does large text work?
- Are statuses understandable without color?
- Do custom controls expose semantics?

### Reliability

- What happens on timeout?
- What happens on duplicate submission?
- What happens if the user leaves the screen?
- What happens after process restart?

### Visual quality

- Are spacing and alignment precise?
- Are there visible layout jumps?
- Are disabled/loading states polished?
- Does the screen still look intentional with real long data?

---

# 50. Final standard

A premium SACCO Flutter UI is successful when a member can:

- understand their financial position quickly
- know what requires attention
- complete important actions confidently
- understand pending/approved/rejected states
- recover from errors without panic
- use the app comfortably on different screen sizes
- increase text size without breaking the layout
- navigate without guessing
- trust that the UI is reflecting authoritative financial information

The engineering standard is equally important:

```text
Theme-driven
Componentized
State-driven
Responsive
Adaptive
Accessible
Performant
Testable
Localized
Secure-by-design
Domain-correct
```

Do not optimize only for screenshots.

Optimize for the user's actual day-to-day interaction with their money.

---

# Sources and living references

This skill is intentionally grounded primarily in current official Flutter and Android guidance. The project should periodically review these sources because Flutter and platform APIs evolve.

1. Flutter Material 3: https://docs.flutter.dev/ui/design/material
2. Flutter themes: https://docs.flutter.dev/cookbook/design/themes
3. Flutter adaptive design overview: https://docs.flutter.dev/ui/adaptive-responsive
4. Flutter adaptive general approach: https://docs.flutter.dev/ui/adaptive-responsive/general
5. Flutter adaptive best practices: https://docs.flutter.dev/ui/adaptive-responsive/best-practices
6. Flutter SafeArea and MediaQuery: https://docs.flutter.dev/ui/adaptive-responsive/safearea-mediaquery
7. Flutter accessibility: https://docs.flutter.dev/ui/accessibility
8. Flutter UI accessibility/design and styling: https://docs.flutter.dev/ui/accessibility/ui-design-and-styling
9. Flutter accessibility widgets and semantics: https://docs.flutter.dev/ui/widgets/accessibility
10. Flutter performance best practices: https://docs.flutter.dev/perf/best-practices
11. Flutter rendering performance: https://docs.flutter.dev/perf/rendering-performance
12. Flutter DevTools Performance View: https://docs.flutter.dev/tools/devtools/performance
13. Flutter performance FAQ: https://docs.flutter.dev/perf/faq
14. Flutter animations cookbook: https://docs.flutter.dev/cookbook/animation
15. Flutter implicit animations: https://docs.flutter.dev/ui/animations/implicit-animations
16. Flutter image cookbook: https://docs.flutter.dev/cookbook/images
17. Flutter network images: https://docs.flutter.dev/cookbook/images/network-image
18. Flutter forms: https://docs.flutter.dev/cookbook/forms
19. Flutter form validation: https://docs.flutter.dev/cookbook/forms/validation
20. Flutter architecture: https://docs.flutter.dev/app-architecture
21. Flutter architecture recommendations: https://docs.flutter.dev/app-architecture/recommendations
22. Flutter architecture guide: https://docs.flutter.dev/app-architecture/guide
23. Flutter architecture design patterns: https://docs.flutter.dev/app-architecture/design-patterns
24. Flutter optimistic state: https://docs.flutter.dev/app-architecture/design-patterns/optimistic-state
25. Flutter testing overview: https://docs.flutter.dev/testing/overview
26. Flutter widget testing: https://docs.flutter.dev/cookbook/testing/widget/introduction
27. Flutter integration testing: https://docs.flutter.dev/testing/integration-tests
28. Flutter `MaterialStateProperty` / `WidgetStateProperty`: https://api.flutter.dev/flutter/material/MaterialStateProperty.html
29. Android adaptive layouts: https://developer.android.com/design/ui/mobile/guides/layout-and-content/adapt-layout
30. Android navigation patterns: https://developer.android.com/design/ui/mobile/guides/layout-and-content/layout-and-nav-patterns
31. Android layout grids and units: https://developer.android.com/design/ui/mobile/guides/layout-and-content/grids-and-units
32. Android content composition: https://developer.android.com/design/ui/mobile/guides/layout-and-content/content-structure
33. Android accessibility: https://developer.android.com/guide/topics/ui/accessibility/apps.html
34. Android large-screen UI: https://developer.android.com/guide/topics/large-screens/user-interface
35. Android adaptive optimized quality: https://developer.android.com/guide/topics/large-screens/tier-2-overview

**Review cadence:** Revalidate platform-specific details when upgrading Flutter or materially changing supported platforms/form factors.
