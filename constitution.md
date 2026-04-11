# Project Constitution — dosly

Generated: 2026-04-11
Last updated: 2026-04-11
Mode: Greenfield

> Sections marked `[universal]` are copied verbatim from the AIDevTeamForge template and apply to all projects.
> Sections marked `[project-specific]` were chosen during `/constitute` based on framework best practices and user preferences.

---

## 1. Project Identity

**Name**: dosly
**Type**: Personal mobile health application
**Domain**: Medication tracking and adherence
**Platforms**: iOS + Android (cross-platform from day one)
**Distribution**: Personal use (no app store distribution required)
**Stack**:
- Flutter (stable channel) + Dart (sound null safety, SDK ^3.11.1)
- Riverpod 2.x with `riverpod_generator` (code generation)
- `fpdart` for `Either<Failure, T>` error handling
- `freezed` for immutable data classes and sealed unions
- `drift` for the local SQLite database
- `flutter_local_notifications` for reminders
- `permission_handler` for runtime permissions
- `clock` for injectable time (testable schedules)
- `flutter_test` + `mocktail` for testing

**Backend**: None. dosly is fully local-on-device. All medication, schedule, intake, and adherence data lives in a local drift database. No accounts, no telemetry, no network calls. This is a deliberate architectural decision rooted in privacy: medication data is sensitive personal health information.

---

## 2. Architecture Rules (NON-NEGOTIABLE)

These rules MUST be followed in every code change. Violating them requires explicit user approval.

### 2.1 Layer Boundaries

dosly follows **Clean Architecture**. Each feature folder under `lib/features/[feature]/` contains exactly three layers:

#### `domain/` — pure Dart, no Flutter, no third-party SDKs
Contents:
- `entities/` — immutable business objects (built with `freezed`). Never serialize-aware. Never mention DB columns.
- `value_objects/` — domain types like `MedicationId`, `Dosage`, `IntakeWindow`. Wrap primitives so the type system catches "wrong ID passed to wrong API" bugs.
- `repositories/` — **abstract interfaces only** (`abstract interface class MedicationRepository { ... }`)
- `usecases/` — single-purpose callable classes; one operation per class. Always return `Future<Either<Failure, T>>`.

**Allowed imports in `domain/`**: `package:fpdart/fpdart.dart`, `package:freezed_annotation/freezed_annotation.dart`, `dart:core`, `dart:async`, `package:meta/meta.dart`, `package:clock/clock.dart`, and other `domain/` files within the same project.

**FORBIDDEN imports in `domain/`**: anything from `package:flutter/*`, `package:drift/*`, `package:flutter_local_notifications/*`, `package:flutter_riverpod/*`, `dart:io`, `dart:ui`, or any `data/` / `presentation/` files.

#### `data/` — implements the contracts declared in `domain/`
Contents:
- `datasources/` — local data sources (drift queries, notification scheduler, system services). One class per source. Throws domain-agnostic exceptions internally.
- `models/` — DTOs that mirror DB / external schemas. NEVER leak out of `data/`.
- `mappers/` — pure functions converting `Model ↔ Entity`. Live next to the model.
- `repositories/` — concrete implementations of `domain/repositories/` interfaces. Catch every data-source exception, return `Left(Failure.x(...))`. Exceptions never escape `data/`.

**FORBIDDEN in `data/`**: importing from any `presentation/` directory.

#### `presentation/` — UI and Riverpod state
Contents:
- `providers/` — `@riverpod`-annotated functions and classes (codegen). Wires use cases and exposes `AsyncValue<T>` to widgets.
- `screens/` — top-level routed widgets. One file per screen.
- `widgets/` — feature-scoped reusable widgets.
- `view_models/` — optional, for screens with complex state shaping.

**FORBIDDEN in `presentation/`**: importing directly from any `data/` directory. Always go through a `domain/` use case via a Riverpod provider.

#### Cross-feature rules
- A widget in `features/A/presentation/` may NOT import from `features/B/`. If feature A needs feature B's data, expose it through a `domain/` interface in `lib/core/` or via the public domain API of B.
- Shared utilities live in `lib/core/`. Anything in `core/` must be feature-agnostic.

### 2.2 File Organization

```
lib/
├── main.dart                                # entry point — wraps app in ProviderScope
├── app.dart                                 # MaterialApp + theme + router setup
├── core/                                    # cross-feature, no domain knowledge
│   ├── clock/app_clock.dart                 # injectable Clock for tests
│   ├── database/
│   │   ├── database.dart                    # drift Database singleton
│   │   ├── tables/                          # drift table definitions
│   │   └── migrations/                      # versioned migration files
│   ├── error/failures.dart                  # sealed Failure union
│   ├── logging/logger.dart                  # typed logger (no print/debugPrint anywhere else)
│   ├── notifications/notification_service.dart  # wraps flutter_local_notifications
│   ├── permissions/permission_service.dart  # wraps permission_handler
│   ├── routing/app_router.dart              # go_router config
│   ├── theme/app_theme.dart                 # ThemeData + ColorScheme tokens
│   └── utils/                               # truly generic helpers (date math, formatting)
├── features/
│   └── [feature_name]/
│       ├── data/
│       │   ├── datasources/
│       │   ├── models/
│       │   ├── mappers/
│       │   └── repositories/
│       ├── domain/
│       │   ├── entities/
│       │   ├── value_objects/
│       │   ├── repositories/
│       │   └── usecases/
│       └── presentation/
│           ├── providers/
│           ├── screens/
│           ├── widgets/
│           └── view_models/                 # optional
test/
├── features/                                # mirrors lib/features/
└── core/                                    # mirrors lib/core/
```

**Filename rules** [enforced via `dart analyze`]:
- All Dart files: `snake_case.dart`
- Test files mirror source 1:1: `lib/features/x/domain/usecases/foo.dart` → `test/features/x/domain/usecases/foo_test.dart`
- One public type per file when the type is non-trivial (entities, repositories, use cases, widgets that are screens). Small private helpers may share a file.
- Generated files (`*.g.dart`, `*.freezed.dart`) sit next to their source AND are committed to the repo.

### 2.3 Dependency Rules

**Adding packages**:
- Always use `flutter pub add <package>` — NEVER edit `pubspec.yaml` manually
- Pin minor versions with caret syntax: `^1.2.3`
- Run `flutter pub outdated` before any release-prep task
- New packages require justification in the spec or PR description

**Package allowlist criteria** [recommended]:
- pub.dev score ≥ 70
- Updated within the last 12 months
- Verified publisher OR widely used (>500 likes)
- License compatible with personal use (MIT, BSD, Apache-2.0)

**Forbidden package categories**:
- Anything that ships ads
- Anything that phones home with telemetry by default
- Anything that requires `INTERNET` permission for our local-only app (without strong justification)
- Abandoned packages (no commits in >18 months)

**Import ordering** [enforced by `dart format` + `directives_ordering` lint]:
1. `dart:` imports
2. `package:` imports (sorted alphabetically)
3. Relative imports (sorted alphabetically)
4. Each group separated by a blank line

---

## 3. Code Quality Standards

### 3.1 Type Safety [project-specific]

Maximum strictness. The Dart analyzer is configured with `strict-casts: true`, `strict-inference: true`, `strict-raw-types: true`.

- [enforced] **No `dynamic` types** — period. If you must accept untyped data (a JSON map from a deserializer), capture it as `Map<String, Object?>` and immediately convert to a typed model.
- [enforced] **No `!` (null assertion operator)** — every use is a latent runtime crash. Use explicit null checks, pattern matching (`switch`/`if-case`), or restructure so the value is provably non-null.
- [enforced] **No unchecked `as` casts** — only cast after an `is` check or in a pattern match. Drift-generated and freezed-generated casts are exempt.
- [enforced] **No `late` fields without an initializer** unless the constructor or `initState` provably writes the field before any read.
- [convention] **All entities, DTOs, and state classes use `freezed`** — never hand-roll `==`, `hashCode`, or `copyWith`.
- [convention] **Domain IDs are typed value objects** (`class MedicationId { final String value; }`), never raw `String`. This prevents passing the wrong ID to the wrong API.
- [convention] **Exhaustive `switch` over enums and sealed types** — never use `default:` as a fallback. The compiler must enforce that all cases are handled.

### 3.2 Error Handling [project-specific]

**Pattern**: `Either<Failure, T>` from `fpdart` at every repository boundary and every use case return.

#### The `Failure` hierarchy
A single sealed `freezed` union in `lib/core/error/failures.dart`:

```dart
@freezed
sealed class Failure with _$Failure {
  const factory Failure.notFound({String? id}) = NotFoundFailure;
  const factory Failure.cache(String message) = CacheFailure;
  const factory Failure.permissionDenied(String permission) = PermissionDeniedFailure;
  const factory Failure.notificationSchedule(String reason) = NotificationScheduleFailure;
  const factory Failure.validation({required String field, required String message}) = ValidationFailure;
  const factory Failure.unknown(Object error, StackTrace stack) = UnknownFailure;
}
```

#### Rules
- [enforced] Every repository implementation catches its data-source exceptions and returns `Left(Failure.x(...))`. Exceptions NEVER escape the data layer.
- [enforced] Every use case returns `Future<Either<Failure, T>>`, even when the operation has no current error path (future-proof against added validations).
- [enforced] Every `Either.fold` call handles BOTH branches. Forbidden: `.toIterable().first`, `.getRight()`, `.swap().toIterable().first`, or any other partial extractor.
- [convention] Riverpod providers convert `Either` to `AsyncValue`:
  - `Right(t)` → `AsyncValue.data(t)`
  - `Left(failure)` → `AsyncValue.error(failure, stackTrace)`
- [convention] Widgets read `AsyncValue` via `.when(data:, error:, loading:)` — all three branches always handled.

### 3.3 Naming Conventions [project-specific]

- **Files**: `snake_case.dart` (Effective Dart)
- **Classes / types / widgets / enums**: `UpperCamelCase`
- **Variables / parameters / methods**: `lowerCamelCase`
- **Constants** (`const` and `final` top-level): `lowerCamelCase` — Dart style, NOT `SCREAMING_SNAKE_CASE`
- **Private members**: leading underscore `_thing`
- **Use cases**: imperative verb phrase, one operation per class — `AddMedication`, `MarkIntake`, `GetTodaySchedule`, `RecalculateAdherence`
- **Repositories (abstract)**: noun + `Repository` — `MedicationRepository`, `IntakeRepository`
- **Repository implementations**: same name + `Impl`, in `data/repositories/` — `MedicationRepositoryImpl`
- **Failures**: noun + `Failure` suffix — `NotFoundFailure`, `ValidationFailure`
- **Riverpod providers (codegen)**: `xxxProvider` is auto-generated from the `@riverpod` annotated function name. Function uses `lowerCamelCase`, the generated provider keeps that name + `Provider` suffix.
- **Entities**: domain noun, no suffix — `Medication`, `Schedule`, `Intake`
- **DTOs / data models**: entity name + `Model` suffix — `MedicationModel`
- **Drift tables**: `Medications`, `Intakes` (plural noun, PascalCase) — drift convention
- **Test files**: `<source>_test.dart`
- **Test groups**: describe the unit and the scenario — `group('AddMedication', () { test('returns ValidationFailure when name is empty', ...); })`

### 3.4 Testing Requirements [project-specific]

**Framework**: `flutter_test` (built-in) + `mocktail` (mocks, no codegen).

#### Coverage targets
- **Domain layer** (use cases, value objects, business rules): **mandatory**. Every use case has unit tests covering happy path, validation failure, and at least one repository failure.
- **Data layer** (repositories, mappers): **mandatory**. Every repository implementation tested with a fake or in-memory drift database.
- **Presentation layer**:
  - Screens with logic: widget test using `ProviderScope` with overridden providers
  - Pure-display widgets: skipped
- **Integration tests**: golden flows only — `add medication`, `mark intake taken`, `view weekly adherence`

#### Test layout
`test/` mirrors `lib/` exactly. `lib/features/medications/domain/usecases/add_medication.dart` → `test/features/medications/domain/usecases/add_medication_test.dart`.

#### Mocktail rules
- Register fallback values for any custom type passed to a `when()` matcher: `registerFallbackValue<MedicationId>(MedicationId('fallback'))`
- Use a fresh `Mock` per test in `setUp` — never share mock state across tests
- Verify side effects with `verify(() => ...).called(1)` — never trust the test passed without an assertion
- For domain tests, NEVER touch the real drift database — use `MockMedicationRepository` or an in-memory drift instance

#### Forbidden in tests
- Hitting the real local DB in unit tests
- Sleeping (`await Future.delayed`) — use `pumpAndSettle`, `fake_async`, or controlled `Clock`
- Inter-test dependencies — every test must work in isolation
- Disabling tests with `skip:` without a `// TODO(...)` explaining why and when it will be re-enabled
- Real `DateTime.now()` in tests — inject `Clock` and use a fixed instant

### 3.5 Universal Code Quality [universal]

**No dead code.** Delete unused functions, variables, imports, and files. Do not comment them out "for later." Version control preserves history.

**No debug artifacts in committed code.** Remove all `console.log`, `print()`, `debugger`, `binding.pry`, `dd()`, and similar statements before marking a task complete. Logging that is part of the application's intentional logging system is fine.

**No magic values.** Use named constants for numbers and strings that carry meaning. `if (status === 3)` is wrong. `if (status === ORDER_COMPLETE)` is right.

**One function, one job.** If a function does two unrelated things, split it. If a function name has "and" in it, it probably does too much.

**Early returns over deep nesting.** Check error conditions first and return early. Do not nest happy-path logic inside multiple `if` blocks.

```
// Bad
function process(input) {
  if (input) {
    if (input.isValid) {
      // 20 lines of logic
    }
  }
}

// Good
function process(input) {
  if (!input) return;
  if (!input.isValid) return;
  // 20 lines of logic
}
```

**Keep functions short.** If a function exceeds ~40 lines, look for extraction opportunities. This is a guideline, not a hard rule — sometimes a long function is clearer than several small ones.

**Consistent style within a file.** If a file uses one pattern (arrow functions, single quotes, specific import style), follow that pattern. Do not introduce a different style.

### 3.6 Design Principles [universal]

**SOLID:**
- **Single Responsibility** — a class/module/function has one reason to change. If you can't describe what it does without "and," split it.
- **Open/Closed** — extend behavior through composition or new implementations, not by modifying existing working code.
- **Liskov Substitution** — subtypes must be usable wherever their parent type is expected without breaking behavior.
- **Interface Segregation** — don't force consumers to depend on methods they don't use. Prefer small, focused interfaces over large ones.
- **Dependency Inversion** — depend on abstractions (interfaces, types), not concrete implementations. High-level modules should not import from low-level modules directly.

**DRY (Don't Repeat Yourself):**
- If the same logic appears in 3+ places, extract it into a shared function or utility.
- 2 occurrences are fine — don't abstract prematurely. Wait for the third.
- DRY applies to logic, not to code that looks similar but serves different purposes. Two functions that happen to look alike but handle different domain concepts should stay separate.

**KISS (Keep It Simple, Stupid):**
- Choose the simplest solution that works correctly.
- Don't add abstractions, patterns, or layers "in case we need them later."
- If a junior developer can't understand the code in 30 seconds, it's too complex.

### 3.7 Check Before You Build [universal]

**Before writing anything generic or reusable, search first.** The codebase may already have:
- A utility function that does what you need
- A helper, composable, or hook that covers your use case
- A shared component that handles this UI pattern
- A type or interface that models this data

Search for it using Grep and Glob before creating a new one. Duplicating existing functionality is worse than not having it — it creates confusion about which version to use and doubles the maintenance burden.

---

## 4. Patterns & Anti-Patterns

### 4.1 ALWAYS Do [universal]

- **Read before write.** Always read a file before modifying it. Understand what exists before changing it.
- **Handle both paths.** Every operation that can fail must handle the success case AND the error case. No unhandled promise rejections. No ignored return values from fallible operations.
- **Validate at boundaries.** Validate all external input: user input, API responses, file content, environment variables. Trust internal code. Do not validate data that your own code just created.
- **Name what things ARE, not what they DO temporarily.** Variable names describe the data. Function names describe the action. `userData` not `tempVar`. `calculateTotal` not `doStuff`.
- **Test your assumptions.** If a change depends on "X should already be Y," verify it. Read the code. Don't assume.

### 4.1.1 ALWAYS Do [project-specific]

- [convention] **Always use `@riverpod` codegen** for new providers. No manual `Provider`/`StateNotifierProvider` declarations.
- [convention] **Always use `freezed`** for entities, DTOs, and state/union types. Never hand-roll equality, hashCode, or copyWith.
- [convention] **Always wrap medication intake events in a use case.** Screens never call repositories directly.
- [convention] **Always store timestamps in UTC**; convert to local time only at the display layer.
- [convention] **Always go through `core/notifications/`** to schedule a reminder. Never call `flutter_local_notifications` directly from feature code.
- [convention] **Always use `const` constructors** when possible — `dart analyze` flags missed ones with `prefer_const_constructors`.
- [convention] **Always inject `Clock`** for time-sensitive logic. Never call `DateTime.now()` directly inside a use case or schedule resolver.
- [convention] **Always check `mounted`** after `await` in a `State`/`StatefulWidget` callback before using `BuildContext`.
- [convention] **Always exhaust** `switch` over enums and `freezed` sealed unions — no `default:` clauses.
- [convention] **Always use named parameters** for any constructor or function with more than one parameter.
- [convention] **Always declare return types** on public functions and methods.

### 4.2 NEVER Do [universal]

- **Never swallow errors silently.** Empty `catch` blocks are forbidden. If you catch an error, you must either: (a) handle it meaningfully, (b) re-throw it, or (c) log it and explain why you're suppressing it.

```
// Forbidden
try { doThing(); } catch (e) {}

// Forbidden
try { doThing(); } catch (e) { /* ignore */ }

// Acceptable
try { doThing(); } catch (e) {
  logger.warn('Non-critical: doThing failed, using fallback', e);
  return fallbackValue;
}
```

- **Never commit secrets.** No API keys, passwords, tokens, private keys, or credentials in code. Not in variables, not in comments, not in test files, not "temporarily." Use environment variables or secret management.
- **Never leave a TODO without context.** `// TODO` alone is useless. Always include: what needs to be done, why it can't be done now, and a reference (ticket number, feature name). Example: `// TODO(FEAT-123): Add pagination after backend supports cursor-based queries`
- **Never modify code outside your task scope.** Do not "fix" unrelated code you happen to see. Do not refactor surrounding code. Do not add type annotations to functions you didn't change. If you see a real problem, note it — don't fix it unless asked.
- **Never guess at behavior.** If you are unsure how existing code works, read it. If you are unsure what the user wants, ask. Guessing leads to wrong implementations that waste time.

### 4.2.1 NEVER Do [project-specific]

- [enforced] **Never put `package:flutter/*` (or any UI/SDK package) imports in `lib/features/*/domain/`.** Domain must run in pure Dart tests with no Flutter binding.
- [enforced] **Never use `print()` or `debugPrint()`** in committed code. Use the typed logger from `core/logging/`. The `avoid_print` lint must remain enabled.
- [enforced] **Never use `SharedPreferences` for medication, schedule, intake, or adherence data.** That's the system of record — it goes in drift. SharedPreferences is for non-essential UI flags only (e.g., "user has seen onboarding").
- [enforced] **Never block `main()` on async work.** Show a splash, run async setup, then `runApp`.
- [enforced] **Never call `setState` in async callbacks** without a `mounted` check.
- [enforced] **Never use `BuildContext` across an `await`** without a `mounted` check (the `use_build_context_synchronously` lint catches this).
- [enforced] **Never persist health data with cloud sync** without explicit, opt-in user consent. Privacy is the architectural default.
- [enforced] **Never log medication names, dosages, or intake history.** These are sensitive PHI even for personal use. The logger must have a sanitize layer.
- [enforced] **Never bypass the adherence calculation** by reading raw intake records in the UI. Always go through the use case so the rules stay centralized.
- [enforced] **Never use `as` to widen `Object?`** to a real type without a preceding `is` check or pattern match.
- [enforced] **Never modify drift schema** without bumping `schemaVersion` and writing a migration.
- [enforced] **Never call `DateTime.now()`** inside a use case, schedule resolver, or business-rule function — always go through injected `Clock.now()`.
- [enforced] **Never schedule a notification directly** with `flutter_local_notifications` from a feature; go through `core/notifications/notification_service.dart`.

### 4.3 PREFER [universal]

- **Explicit over implicit.** Named parameters over positional. Explicit types over inferred when the inference is non-obvious. Explicit imports over wildcards.
- **Composition over inheritance.** Build behavior by combining small pieces, not by extending base classes. Deep inheritance hierarchies are fragile.
- **Flat over nested.** Flat directory structures over deeply nested ones. Flat conditionals (early returns) over nested if/else chains. Flat data over deeply nested objects when possible.
- **Boring over clever.** Readable, obvious code over clever one-liners. The person reading your code (including future you and other AI agents) should understand it without pausing.
- **Existing patterns over new ones.** When the codebase already has a pattern for something, use it. Do not introduce a second way to do the same thing unless the existing way is clearly broken.
- **Small PRs over large ones.** One concern per change. If a task touches more than 5-7 files, consider whether it can be split.

### 4.3.1 PREFER [project-specific]

- [recommended] Prefer `@riverpod` codegen over hand-written providers (less boilerplate, autoDispose by default, better type safety)
- [recommended] Prefer `Notifier` / `AsyncNotifier` over the older `StateNotifier`
- [recommended] Prefer `ref.watch` in `build`, `ref.read` only in callbacks (`onPressed`, etc.)
- [recommended] Prefer `AsyncValue.when(data:, error:, loading:)` over `if/else` against `.isLoading`
- [recommended] Prefer `freezed` sealed unions for screen state over multiple boolean flags (`isLoading`, `hasError`, `data`)
- [recommended] Prefer `drift` typed queries over raw SQL strings
- [recommended] Prefer `IconButton` / `InkWell` (with explicit `constraints`) for tap targets ≥ 48dp — never raw `GestureDetector` for primary actions
- [recommended] Prefer `final` over `var`; prefer `const` over `final` when possible
- [recommended] Prefer `freezed` `@With([...])` mixins over inheritance for shared behavior
- [recommended] Prefer one screen per file, one widget per file when the widget is reused
- [recommended] Prefer `ListView.builder` over `ListView(children: [...])` for any list with > 10 items

---

## 5. Domain Rules [project-specific]

### 5.1 Key Entities

| Entity | Description |
|---|---|
| `Medication` | A single tracked medication. Fields: `id`, `name`, `form`, `defaultDosage`, `type` (course/permanent), `schedule`, optional `notes`, optional `endDate` (course only) |
| `MedicationForm` | Enum: `tablet`, `capsule`, `injection`, `syrup`, `drops`, `inhaler`, `cream`, `sachet` |
| `MedicationType` | Sealed union (freezed): `Course({DateTime startDate, DateTime endDate})` \| `Permanent({DateTime startDate})` |
| `Dosage` | Value object: `value` (double) + `unit` (`pill`, `ml`, `mg`, `puff`, `drop`, `application`, `sachet`) |
| `Schedule` | When the medication is due. Composed of `frequency` (`daily`, `everyNDays(int n)`, `specificWeekdays(Set<Weekday>)`) and a list of `TimeSlot` |
| `TimeSlot` | An intended intake within a day: `id`, `time` (HH:mm local), optional `dosage` override (if different from medication default) |
| `Intake` | A record of an intake event: `id`, `medicationId`, `slotId`, `scheduledAt` (UTC), `confirmedAt` (nullable UTC), `status` (`pending`, `taken`, `missed`, `skipped`), optional `notes` |
| `IntakeStatus` | Enum: `pending`, `taken`, `missed`, `skipped` |
| `AdherenceRecord` | A daily/weekly aggregation: `date`, `scheduledCount`, `takenCount`, `missedCount`, `skippedCount`, `adherenceRatio` (double, 0..1) |
| `Settings` | User preferences: `gracePeriodMinutes` (default 5), `intakeWindowMinutes` (default 120), `notificationLeadMinutes` (default 0), `quietHoursStart`, `quietHoursEnd` |

Each entity is a `freezed` immutable class. Each `*Id` field is a typed value object.

### 5.2 Business Rules

#### Schedule resolution
- A medication's daily intakes are derived from its `Schedule` (which weekdays + which time slots)
- "Today's schedule" is the union of all intakes due today across all active medications, sorted by time
- A `Course` medication's intakes are NOT generated past `endDate` (inclusive cutoff at end-of-day local time)
- A `Permanent` medication's intakes are generated indefinitely until the medication is deleted
- Past intakes (before today) are NOT regenerated — what's persisted is the source of truth

#### Intake state machine
```
            ┌──────── confirm ────────────┐
            │                             ▼
        pending ─── skip ────────────► skipped
            │
            │ scheduledAt + intakeWindow exceeded
            ▼
         missed
            
        taken ─── undo within graceWindow ───► pending
```

- `pending → taken` via the `MarkIntakeTaken` use case
- `pending → skipped` via the `SkipIntake` use case
- `pending → missed` automatically when `now > scheduledAt + intakeWindowMinutes` (background job + on next app open)
- `taken → pending` only allowed within `gracePeriodMinutes` of confirmation (undo)
- After grace period: a `taken` or `missed` intake can ONLY be edited via the explicit "Manual Correction" flow, which is audit-logged separately

#### Grace period
- Default: 5 minutes
- After marking an intake `taken`, the user has `gracePeriodMinutes` to undo
- Adjustable in Settings (range: 0–30 minutes)

#### Intake window
- Default: 120 minutes
- An intake remains `pending` from `scheduledAt - notificationLeadMinutes` until `scheduledAt + intakeWindowMinutes`
- After the window closes, the intake auto-transitions to `missed`
- Adjustable in Settings (range: 15–240 minutes)

#### Adherence calculation
- **Daily adherence**: `takenCount / scheduledCount` for that day, where `scheduledCount` excludes future intakes (whose scheduled time hasn't passed yet)
- **Weekly adherence**: `sum(taken across week) / sum(scheduled across week)` — NOT the average of daily ratios
- `skipped` intakes do NOT count toward `scheduledCount` (the user explicitly opted out — adherence is not punished)
- An intake is "scheduled" only after its scheduled time has passed; future intakes don't dilute the ratio
- If `scheduledCount == 0`, adherence is reported as `null` (display as "—"), not `0` or `1`

#### Notifications
- Reminders fire at `scheduledAt - notificationLeadMinutes` local time
- Quiet hours (`quietHoursStart..quietHoursEnd`) suppress sound but still post the notification silently
- Notification actions allow marking `taken` or `skipped` directly without opening the app
- On device reboot, all pending notifications must be re-scheduled
  - Android: handled by `flutter_local_notifications` + `RECEIVE_BOOT_COMPLETED` permission + boot receiver
  - iOS: native local notifications survive reboot automatically
- Notification text must NOT contain medication names — privacy. Format: "Time for your medication" + tap to see details.

#### Time zones and DST
- All `Intake.scheduledAt` and `Intake.confirmedAt` are stored in UTC
- All display, scheduling, and adherence calculations convert to the user's local time zone
- DST transitions: a 09:00 reminder fires at 09:00 local both before and after the DST shift. Use `flutter_local_notifications` with `matchDateTimeComponents: DateTimeComponents.time` and the `timezone` package.

### 5.3 External Contracts

dosly has **no remote backend**. All data is local. The only "external" boundaries are platform services:

| Boundary | Implementation |
|---|---|
| Local database | `drift` (typed SQLite). Schema versioned with migration files in `lib/core/database/migrations/`. |
| Notifications | `flutter_local_notifications` (cross-platform). Wrapped by `core/notifications/notification_service.dart`. |
| Background re-arming | Android: `flutter_local_notifications` with exact alarms permission. iOS: notifications survive reboot natively. |
| Permissions | `permission_handler`. Wrapped by `core/permissions/permission_service.dart`. |
| File export (optional, future) | `share_plus` + JSON serialization. Not in MVP scope. |

#### Permissions inventory
- **iOS**:
  - Notification authorization (requested at first use, not on app launch) — `NSUserNotificationsUsageDescription` not strictly required, but provide a clear in-app explainer first
- **Android**:
  - `POST_NOTIFICATIONS` (Android 13+) — runtime permission
  - `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` (Android 12+) — required for precise reminder timing
  - `RECEIVE_BOOT_COMPLETED` — to re-arm alarms after device restart

#### Permission flow rules
- ALWAYS show an in-app rationale screen BEFORE the system prompt
- ALWAYS handle the "denied permanently" case by linking the user to system settings
- NEVER prompt for a permission before the user has expressed intent (e.g., adding their first medication)

---

## 6. Workflow Rules

### 6.1 Minimal Changes [universal]
Every code change MUST impact as little code as possible. Do not refactor, improve, or "clean up" code outside the scope of the current task. A bug fix changes the bug. A feature adds the feature. Nothing more.

### 6.2 Semantic Understanding [universal]
Before renaming or replacing any identifier, VERIFY:
1. What the identifier semantically means
2. All callers and consumers of the identifier
3. That the new name correctly represents the concept
4. That no external contracts (APIs, database columns, config keys) depend on the old name

### 6.3 Read-First Principle [universal]
Before writing ANY code:
1. Read the files you plan to modify
2. Read the files that import/use the code you plan to modify
3. Check the constitution for relevant rules
4. Check memory for past lessons about this area

Skipping this step is the #1 cause of wrong implementations.

### 6.4 Documentation [universal]
- **Read docs before starting**: Before any task, read relevant docs in `docs/` for context about the area you're changing
- **Write docs after completing**: After every task, the tech-writer agent updates `docs/` with changes. This is mandatory — not optional
- All new public functions must have a brief inline description (JSDoc/docstring)
- All new types/interfaces must have a brief inline description
- Do NOT add documentation to code you didn't write or change
- Update existing documentation when you change the behavior it describes
- `docs/` is the source of truth for project documentation — organized by topic, not by task

### 6.5 Deprecation Handling [project-specific]

- When deprecating a public API (use case, repository method, widget, value object), mark it with `@Deprecated('Use X instead. Will be removed in v<N.M>.')`
- Keep the deprecated API working for at least one feature cycle
- Track pending removals in `.claude/memory/MEMORY.md` under a "Pending removals" section with the target version
- For drift schema deprecation: NEVER drop a column without a migration that backfills, archives, or explicitly migrates the data — this is health data, do not lose it

### 6.6 Project-Specific Workflow [project-specific]

- **Code generation step**: After any change to a `@riverpod`-annotated function, a `freezed` class, or a drift table, run:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
  Or keep `dart run build_runner watch -d` running during active development. **Generated files (`*.g.dart`, `*.freezed.dart`) ARE committed.**
- **Drift schema changes**: Bump `schemaVersion` and add a migration in `lib/core/database/migrations/migration_<from>_to_<to>.dart`. Test the migration with a fixture from the previous schema version.
- **Permission checks**: Any code path that uses notifications or exact alarms must check the permission first via `PermissionService` and gracefully handle denial.
- **Time-sensitive logic**: Use `Clock.now()` (from `package:clock`) instead of `DateTime.now()` so tests can fake time with `withClock(Clock.fixed(...))`.
- **Manual testing checklist** for any task that touches schedules, intakes, or notifications:
  1. Add a medication with a near-future time slot
  2. Verify the reminder fires
  3. Mark `taken` from the notification
  4. Verify the intake history reflects the change
  5. Toggle device into airplane mode and reboot — verify the reminder still fires
  6. Cross DST boundary using a time-traveled emulator if applicable

---

## 7. Scaffolding Guide [greenfield-only]

This section applies while dosly is being built. Once the codebase has 20+ source files and stable patterns, run `/constitute` again to replace `[convention]` rules with `[extracted]` rules grounded in the actual code.

### 7.1 First Files to Create (in order)

1. `lib/core/error/failures.dart` — sealed `Failure` freezed union
2. `lib/core/clock/app_clock.dart` — `Clock` provider for time injection
3. `lib/core/logging/logger.dart` — typed logger (consider `package:logging` + a sanitize layer)
4. `lib/core/database/database.dart` — drift `Database` singleton + initial schema
5. `lib/core/database/tables/medications_table.dart`, `time_slots_table.dart`, `intakes_table.dart`, `settings_table.dart`
6. `lib/core/notifications/notification_service.dart` — `flutter_local_notifications` wrapper with iOS + Android setup
7. `lib/core/permissions/permission_service.dart` — `permission_handler` wrapper
8. `lib/core/theme/app_theme.dart` — Material 3 `ThemeData` + `ColorScheme` (light + dark)
9. `lib/core/routing/app_router.dart` — `go_router` with the first route
10. `lib/features/medications/domain/value_objects/medication_id.dart`
11. `lib/features/medications/domain/value_objects/dosage.dart`
12. `lib/features/medications/domain/entities/medication.dart`
13. `lib/features/medications/domain/repositories/medication_repository.dart` — abstract
14. `lib/features/medications/data/repositories/medication_repository_impl.dart`
15. `lib/features/medications/domain/usecases/add_medication.dart` (+ unit tests)
16. `lib/features/medications/presentation/providers/medication_providers.dart`
17. `lib/features/medications/presentation/screens/medications_screen.dart`
18. `lib/main.dart` — wrap `runApp(ProviderScope(child: DoslyApp()))`

### 7.2 Pattern Reference

#### Domain entity (freezed)
```dart
// lib/features/medications/domain/entities/medication.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../value_objects/medication_id.dart';
import '../value_objects/dosage.dart';
import 'medication_form.dart';
import 'medication_type.dart';
import 'schedule.dart';

part 'medication.freezed.dart';

@freezed
sealed class Medication with _$Medication {
  const factory Medication({
    required MedicationId id,
    required String name,
    required MedicationForm form,
    required Dosage defaultDosage,
    required Schedule schedule,
    required MedicationType type,
    String? notes,
  }) = _Medication;
}
```

#### Repository contract (abstract)
```dart
// lib/features/medications/domain/repositories/medication_repository.dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/medication.dart';
import '../value_objects/medication_id.dart';

abstract interface class MedicationRepository {
  Future<Either<Failure, List<Medication>>> getAll();
  Future<Either<Failure, Medication>> getById(MedicationId id);
  Future<Either<Failure, Medication>> add(Medication medication);
  Future<Either<Failure, Unit>> delete(MedicationId id);
}
```

#### Use case
```dart
// lib/features/medications/domain/usecases/add_medication.dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/medication.dart';
import '../entities/medication_form.dart';
import '../entities/medication_type.dart';
import '../entities/schedule.dart';
import '../repositories/medication_repository.dart';
import '../value_objects/dosage.dart';
import '../value_objects/medication_id.dart';

class AddMedication {
  const AddMedication(this._repository);
  final MedicationRepository _repository;

  Future<Either<Failure, Medication>> call({
    required String name,
    required MedicationForm form,
    required Dosage defaultDosage,
    required Schedule schedule,
    required MedicationType type,
    String? notes,
  }) async {
    if (name.trim().isEmpty) {
      return const Left(
        Failure.validation(field: 'name', message: 'Name is required'),
      );
    }
    final medication = Medication(
      id: MedicationId.generate(),
      name: name.trim(),
      form: form,
      defaultDosage: defaultDosage,
      schedule: schedule,
      type: type,
      notes: notes,
    );
    return _repository.add(medication);
  }
}
```

#### Riverpod provider (codegen)
```dart
// lib/features/medications/presentation/providers/medication_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/database/database_provider.dart';
import '../../data/repositories/medication_repository_impl.dart';
import '../../domain/entities/medication.dart';
import '../../domain/repositories/medication_repository.dart';
import '../../domain/usecases/add_medication.dart';

part 'medication_providers.g.dart';

@riverpod
MedicationRepository medicationRepository(MedicationRepositoryRef ref) {
  return MedicationRepositoryImpl(ref.watch(databaseProvider));
}

@riverpod
AddMedication addMedication(AddMedicationRef ref) {
  return AddMedication(ref.watch(medicationRepositoryProvider));
}

@riverpod
class MedicationsList extends _$MedicationsList {
  @override
  Future<List<Medication>> build() async {
    final result = await ref.watch(medicationRepositoryProvider).getAll();
    return result.fold(
      (failure) => throw failure,
      (medications) => medications,
    );
  }
}
```

#### Widget consuming a provider
```dart
// lib/features/medications/presentation/screens/medications_screen.dart
class MedicationsScreen extends ConsumerWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(medicationsListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Medications')),
      body: state.when(
        data: (meds) => MedicationListView(medications: meds),
        error: (e, _) => ErrorView(error: e),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
```

#### Unit test for a use case
```dart
// test/features/medications/domain/usecases/add_medication_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements MedicationRepository {}

void main() {
  late _MockRepo repo;
  late AddMedication useCase;

  setUpAll(() {
    registerFallbackValue(_aMedication());
  });

  setUp(() {
    repo = _MockRepo();
    useCase = AddMedication(repo);
  });

  group('AddMedication', () {
    test('returns ValidationFailure when name is empty', () async {
      final result = await useCase(
        name: '   ',
        form: MedicationForm.tablet,
        defaultDosage: const Dosage(value: 1, unit: DoseUnit.pill),
        schedule: _aSchedule(),
        type: MedicationType.permanent(startDate: DateTime.utc(2026, 4, 11)),
      );

      expect(result.isLeft(), isTrue);
      verifyNever(() => repo.add(any()));
    });

    test('forwards to repository when input is valid', () async {
      when(() => repo.add(any())).thenAnswer((_) async => Right(_aMedication()));

      final result = await useCase(
        name: 'Aspirin',
        form: MedicationForm.tablet,
        defaultDosage: const Dosage(value: 1, unit: DoseUnit.pill),
        schedule: _aSchedule(),
        type: MedicationType.permanent(startDate: DateTime.utc(2026, 4, 11)),
      );

      expect(result.isRight(), isTrue);
      verify(() => repo.add(any())).called(1);
    });
  });
}
```

### 7.3 Initial Dependencies

Add with `flutter pub add`:

```bash
# runtime
flutter pub add flutter_riverpod riverpod_annotation \
  fpdart freezed_annotation \
  drift drift_flutter sqlite3_flutter_libs path path_provider \
  flutter_local_notifications timezone \
  permission_handler \
  go_router \
  clock \
  logging

# dev
flutter pub add --dev build_runner riverpod_generator freezed drift_dev mocktail
```

### 7.4 `analysis_options.yaml` (replace the default)

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    invalid_annotation_target: ignore  # required for freezed
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"

linter:
  rules:
    - always_declare_return_types
    - avoid_dynamic_calls
    - avoid_print
    - avoid_unused_constructor_parameters
    - cancel_subscriptions
    - close_sinks
    - directives_ordering
    - prefer_const_constructors
    - prefer_const_constructors_in_immutables
    - prefer_const_declarations
    - prefer_const_literals_to_create_immutables
    - prefer_final_in_for_each
    - prefer_final_locals
    - require_trailing_commas
    - sort_pub_dependencies
    - unnecessary_lambdas
    - unnecessary_late
    - unnecessary_null_aware_assignments
    - use_build_context_synchronously
    - use_super_parameters
```

### 7.5 When to Re-Constitute

Run `/constitute` again when:
- The project reaches 20+ source files (replace `[convention]` rules with `[extracted]` rules grounded in real code)
- A major architectural decision is made (e.g., adding cloud sync would be a major shift)
- Drift schema versioning patterns stabilize and you want to formalize them
- 3+ months pass since this constitution was generated
- You decide to add a backend (Section 5.3 will need a major rewrite)

---

## Rule Tags

Rules use these tags to indicate their origin:
- `[universal]` — Applies to all projects. Pre-populated in template.
- `[convention]` — Team convention discovered or decided during `/constitute`.
- `[extracted]` — Pattern extracted from existing codebase during `/constitute`.
- `[enforced]` — Hard rule with automated checking (linting, type checking, hooks).
- `[recommended]` — Best practice suggestion. Can be overridden with good reason.
- `[greenfield-only]` — Only applies during initial project scaffolding.
- `[project-specific]` — Populated by `/constitute` based on your project.
