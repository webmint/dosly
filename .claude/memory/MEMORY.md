# Project Memory — dosly

## Project Identity
**dosly** is a personal cross-platform (iOS + Android) medication tracking app. Fully local — no backend, no accounts, no telemetry. Tracks medications, schedules, intake confirmations, and adherence history. Constitution at `constitution.md` is the source of truth.

## Project Structure
Greenfield Flutter app — `flutter create .` has run, scaffolding is in place. `linux/`, `macos/`, `web/`, `windows/` were removed (iOS + Android only). No feature code yet — first scaffolding step is `lib/core/error/failures.dart` per constitution Section 7.1.

## Key File Paths
- `lib/main.dart` — app entry point (currently `flutter create` boilerplate; replace when first feature lands)
- `lib/core/` — cross-feature utilities (does not exist yet — create per Section 7.1):
  - `lib/core/error/failures.dart` — sealed `Failure` freezed union
  - `lib/core/clock/app_clock.dart` — injectable `Clock` for time-sensitive tests
  - `lib/core/database/database.dart` — drift database singleton
  - `lib/core/database/tables/` — drift table definitions
  - `lib/core/database/migrations/` — versioned migration files
  - `lib/core/notifications/notification_service.dart` — `flutter_local_notifications` wrapper
  - `lib/core/permissions/permission_service.dart` — `permission_handler` wrapper
  - `lib/core/routing/app_router.dart` — `go_router` config
  - `lib/core/theme/app_theme.dart` — Material 3 ThemeData
  - `lib/core/logging/logger.dart` — typed logger with PHI sanitize layer
- `lib/features/[feature]/domain/` — pure Dart: entities, value objects, abstract repository contracts, use cases. **No Flutter, drift, or third-party SDK imports allowed here.**
- `lib/features/[feature]/data/` — drift data sources, DTOs, mappers, repository implementations
- `lib/features/[feature]/presentation/` — `@riverpod`-annotated providers, screens, widgets
- `test/` — mirrors `lib/`
- `pubspec.yaml` — dependencies (currently has only `cupertino_icons` and `flutter_lints`; full list in constitution Section 7.3)
- `analysis_options.yaml` — replace default with strict-mode config from constitution Section 7.4
- `constitution.md` — non-negotiable rules (project root)

## Workspace Configuration
- **Mode**: standalone
- **Source Root**: .
- **Platforms**: iOS + Android
- **Backend**: none (fully local-on-device)

## Architecture Decisions
<!-- Why decisions were made, not just what -->

- **Clean Architecture (data/domain/presentation per feature)** — chosen during `/setup-wizard`. Rationale: enforces dependency direction, makes domain logic unit-testable in pure Dart, isolates third-party SDK choices in `data/`.
- **`Either<Failure, T>` via fpdart** — chosen during `/setup-wizard`. Rationale: explicit error flow at repository boundaries; pairs naturally with Riverpod's `AsyncValue` in the UI; eliminates the "did I forget try/catch?" class of bugs.
- **Riverpod 2.x with `riverpod_generator` codegen** — chosen during `/setup-wizard` and `/constitute`. Rationale: less boilerplate than BLoC, autoDispose by default with codegen, built-in DI removes need for `get_it`, `AsyncValue<T>` composes cleanly with `Either<Failure, T>`.
- **`freezed` for entities, DTOs, and sealed unions** — chosen during `/constitute`. Rationale: hand-rolled equality is bug-prone; freezed gives `==`, `hashCode`, `copyWith`, sealed unions, and JSON for free.
- **`drift` for the local SQLite database** (over sqflite/isar) — chosen during `/constitute`. Rationale: typed queries, strong migration tooling, pairs cleanly with strict mode. Isar is in maintenance; sqflite is untyped strings.
- **`go_router` for routing** — chosen during `/constitute`. Rationale: official Flutter routing solution, supports deep links and type-safe routes.
- **`flutter_test + mocktail` for testing** — chosen during `/setup-wizard`. Rationale: no codegen step (unlike mockito), null-safe, official runner.
- **No backend / fully local** — chosen during `/constitute`. Rationale: medication data is sensitive PHI; eliminating cloud sync is the strongest privacy posture and simplest architecture.
- **Maximum strictness lint mode** (`strict-casts`, `strict-inference`, `strict-raw-types`, no `dynamic`, no `!`) — chosen during `/constitute`. Rationale: medication tracking is safety-relevant; type-system bugs can cause real harm.
- **All timestamps in UTC, displayed in local** — Rationale: prevents DST and time-zone bugs in adherence calculations.
- **`Clock` injection over `DateTime.now()`** — Rationale: scheduling and adherence logic is the heart of the app; tests must control time.

## Naming Conventions

- **Filenames**: `snake_case.dart` (Effective Dart)
- **Types / classes / widgets / enums**: `UpperCamelCase`
- **Variables / parameters / methods**: `lowerCamelCase`
- **Constants**: `lowerCamelCase` (Dart style, NOT `SCREAMING_SNAKE_CASE`)
- **Private members**: leading underscore `_thing`
- **Use cases**: imperative verb phrase, one operation per class — `AddMedication`, `MarkIntake`, `GetTodaySchedule`
- **Repositories (abstract)**: noun + `Repository` — `MedicationRepository`
- **Repository implementations**: `<Name>RepositoryImpl` in `data/repositories/`
- **Failures**: noun + `Failure` suffix
- **Entities**: domain noun, no suffix — `Medication`, `Schedule`, `Intake`
- **DTOs**: entity name + `Model` suffix — `MedicationModel`
- **Drift tables**: plural PascalCase — `Medications`, `Intakes`
- **Riverpod providers (codegen)**: `xxxProvider` auto-generated from `@riverpod` annotated function

## Domain Cheat Sheet

- **Entities**: `Medication`, `MedicationForm` (enum: tablet, capsule, injection, syrup, drops, inhaler, cream, sachet), `MedicationType` (sealed: `Course` | `Permanent`), `Dosage`, `Schedule`, `TimeSlot`, `Intake`, `IntakeStatus` (pending, taken, missed, skipped), `AdherenceRecord`, `Settings`
- **Intake state machine**: `pending → taken/skipped/missed`. `taken → pending` allowed within `gracePeriodMinutes` (undo).
- **Adherence formula**: weekly = `sum(taken across week) / sum(scheduled across week)`. Skipped intakes do NOT count toward scheduled. Future intakes don't dilute the ratio.
- **Default settings**: `gracePeriodMinutes = 5`, `intakeWindowMinutes = 120`, `notificationLeadMinutes = 0`
- **Privacy rule**: notification text must NOT contain medication names — generic "Time for your medication" + tap to view details

## Known Pitfalls
<!-- Populated during work as mistakes are discovered -->

- **`package:flutter/*` in `domain/`** — strictly forbidden. Domain must run in pure Dart tests.
- **`package:drift/*` or `package:flutter_local_notifications/*` in `domain/`** — also forbidden. Wrap in repositories / services.
- **`!` null assertion** — every use is a latent runtime crash. Use explicit null checks or pattern matching.
- **`SharedPreferences` for medication/intake data** — never. That's the system of record; it goes in drift.
- **`ref.read` inside provider `build`** — breaks reactivity. Use `ref.watch`.
- **`DateTime.now()` in domain code** — never. Inject `Clock` and use `Clock.now()` so tests can fake time.
- **Direct `flutter_local_notifications` calls from features** — never. Always go through `core/notifications/notification_service.dart`.
- **Logging medication names** — forbidden. PHI even for personal use.
- **Drift schema changes without bumped `schemaVersion` and migration** — never drop or alter columns blindly; this is health data, do not lose it.
- **`BuildContext` after `await` without `mounted` check** — `use_build_context_synchronously` lint catches this; keep it on.

## What Worked
<!-- Patterns and approaches that solved problems well -->

- **Hand-coded `const ColorScheme` literals + per-hex assertion tests** _(Feature 001)_: 70 per-field `expect(scheme.x, const Color(0x...))` tests catch any design drift instantly. Matched spec §9 drift-protection intent. Total cost: ~120 lines of test file, huge ROI.
- **SHA-256 hashing for bundled font assets** _(Task 001)_: `SOURCE.md` records hashes of all four Roboto TTFs. Security-reviewer independently verified them — excellent supply-chain hygiene for a personal app. Consider promoting to a CI check later.
- **`ValueNotifier<ThemeMode>` + `ListenableBuilder` for app-wide theme state** _(Task 004+008)_: zero dependencies, built into Flutter, trivially testable, pairs cleanly with `MaterialApp.themeMode`. Appropriate choice when you don't need Riverpod yet.
- **Task bundling for mechanical glue work** _(spec 001 breakdown)_: bundling "create data structure + write data-assertion tests" into one task (Task 002, Task 004) kept the breakdown to 8 tasks instead of 11 without losing rigor. Matched `_multi-task-continuation.md` bundling rule.
- **Deferring manual cross-platform run to user** _(Task 008 + AC-13)_: sandbox can't drive simulators. Widget smoke test exercises the compile pipeline so AC-13 is the ONLY gap at verify time, and it's clearly scoped as "user runs `flutter run -d ios/android` after merge."

## What Failed
<!-- Approaches that were tried and didn't work — avoid repeating these -->

- **Over-trusting task-spec license claims** _(Task 001)_: the task spec said Roboto is Apache 2.0; implementer correctly discovered it's actually OFL 1.1 in v3 and shipped the right license. Lesson: when specifying licenses in future tasks, VERIFY the current license of the specific version being shipped, don't rely on historical knowledge.
- **Test coverage gaps for getter-based code** _(Feature 001, AC-4)_: `AppTheme.lightTheme`/`darkTheme` are getters with no dedicated test. Review caught it. Lesson: for any new `lib/core/` file, plan a corresponding test file during `/plan`, not as an afterthought. Dedicated test files for `app_theme.dart`, `app.dart`, and `theme_preview_screen.dart` would close the gap at ~35 total lines.
- **`pubspec.yaml` `weight: N` comments in task specs can desync** _(Task 001)_: task spec said Bold/Light are important but the actual type scale only uses w400/w500. Those weights are dead code until someone uses them. Lesson: when declaring font weights, cross-check against the actual `TextStyle` usages in the type scale, not just "what a design spec lists."

## External API Quirks
<!-- Unexpected behavior from APIs, libraries, or services this project uses -->

- **`flutter_local_notifications` + DST**: must use `matchDateTimeComponents: DateTimeComponents.time` so a 09:00 reminder fires at 09:00 local both before and after a DST shift. Combined with the `timezone` package for IANA zones.
- **Android 12+ exact alarms**: `SCHEDULE_EXACT_ALARM` (or `USE_EXACT_ALARM` for Android 13+ apps that qualify) must be granted at runtime; check via `permission_handler`.
- **Android 13+ notifications**: `POST_NOTIFICATIONS` is a runtime permission, not just a manifest declaration.
- **Roboto font licensing** _(spec 001 / Task 001)_: Roboto v3 (the modern Google Fonts release) is **SIL OFL 1.1**, NOT Apache 2.0. Only the original 2011 Roboto was Apache 2.0. Always ship `OFL.txt` (not `LICENSE.txt`/Apache) with bundled Roboto assets.
- **Roboto static weight source** _(spec 001 / Task 001)_: `github.com/google/fonts/apache/roboto/static/` no longer exists; the canonical source for static Roboto weights is the `googlefonts/roboto-3-classic` GitHub release (e.g. `Roboto_v3.015.zip` → `android/static/`). The `google/fonts` repo only ships the variable font now.
- **Flutter `ColorScheme` field rename** _(spec 001 / Task 002)_: `inverseOnSurface` was renamed to `onInverseSurface` in modern Flutter. The HTML Theme Builder output uses `--md-inverse-on-surface` (which matches the new name semantically, not the old one). Modern code MUST use `onInverseSurface`.
- **Deprecated `surfaceVariant` field** _(spec 001 / Task 002)_: removed from `ColorScheme`. Material Theme Builder still emits `--md-surface-variant` in HTML output, but it must be DROPPED — replaced by `surfaceContainerHighest` per Flutter migration guidance.
- **`Color.toARGB32()` vs `Color.value`** _(spec 001 / Task 007)_: `Color.value` is deprecated in modern Flutter (3.27+). Use `c.toARGB32()` to get the 32-bit ARGB int. Works on Flutter SDK ^3.11.1.
- **`unnecessary_import` lint trap** _(spec 001 / Task 004)_: `package:flutter/foundation.dart` is REDUNDANT when `package:flutter/material.dart` is already imported (material re-exports `ValueNotifier`, `ChangeNotifier`, etc.). Importing both fails strict-mode `dart analyze`. Pick one — usually `material.dart` for widget code.

## Performance Notes

- **Profile in profile mode**, never debug. Debug mode disables many optimizations and gives misleading numbers.
- **`const` constructors are free wins** — every widget that takes only compile-time constants should be `const`. The `prefer_const_constructors` lint enforces this.
- **`ListView.builder` over `ListView(children: [...])`** for any list that might exceed ~10 items.
- **Today's schedule resolution** runs on every app foreground; keep it pure and synchronous so the UI stays responsive.

## Pending Removals
<!-- Track APIs marked @Deprecated and the version they should be removed in -->
