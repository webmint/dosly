## Feature Summary: 032 — Medication Persistence (drift)

### What was built
The add-medication form now saves. Tapping **Save** writes the medication — its form, dose/quantity, pack stock, intake times, and continuous-or-course schedule — to a local on-device **drift** (SQLite) database, then closes the modal with a confirmation (or shows a localized error and stays open if input is invalid). This is the app's first real persistence layer and gives the `meds` feature its full Clean-Architecture stack (domain + data), mirroring the existing `settings` slice.

### Changes
- **Task 1**: Added `drift`, `drift_flutter`, `sqlite3_flutter_libs`, `uuid` (+ `drift_dev`) dependencies.
- **Task 2–4**: Built the pure-Dart domain model — `Medication` aggregate, `MedicationType` (continuous | course{duration, pause}), `Dosage`, `PackStock`, `Schedule`, `TimeSlot`, enums, and typed value-object IDs.
- **Task 5**: Created the first drift database — `Medications` + `TimeSlots` tables, `AppDatabase` (schemaVersion 1, cascade FK, `foreign_keys` pragma), and a kept-alive provider.
- **Task 6**: Added an injectable `IdGenerator` (uuid-backed) so the domain mints IDs without importing uuid.
- **Task 7**: Added the `MedicationRepository` contract and the `AddMedication` use case (validates name / ≥1 time / course duration ≥ 1).
- **Task 8**: Implemented the data layer — a null-safe domain↔drift mapper, a transactional insert data source, and an `Either`-returning repository.
- **Task 9**: Wired the dependency graph via `@riverpod` providers (the sanctioned composition seam).
- **Task 10**: Added success + validation/error strings in English, German, and Ukrainian.
- **Task 11**: Converted the modal to a `ConsumerStatefulWidget` and wired Save → use case → pop + SnackBar, with an in-flight disable.
- **Task 12–14**: Tests — use-case unit tests (5), in-memory drift data-layer round-trip tests (45), and rewritten modal widget tests for the wired Save (no-op assertions removed).

### Files changed
- `lib/features/meds/domain/` — full domain layer added (entities, value objects, repository contract, use case)
- `lib/features/meds/data/` — mapper, local data source, repository impl added
- `lib/features/meds/presentation/` — providers added; add-medication modal wired
- `lib/core/database/` — drift database, tables, provider added
- `lib/core/id/` — `IdGenerator` abstraction + uuid impl + provider added
- `lib/l10n/` — 5 new strings × 3 locales (+ regenerated localizations)
- `test/features/meds/` — 4 test files (3 added, 1 rewritten); 54 new tests
- `pubspec.yaml` / `pubspec.lock` — 5 dependencies added
- Total (incl. specs + generated): **76 files changed, ~9,174 insertions, 174 deletions** across 31 WIP commits (squashed by `/finalize`).

### Key decisions
- **Injected `IdGenerator` instead of `MedicationId.generate()`** — keeps `domain/` free of `package:uuid` (§2.1) and gives deterministic test IDs; mirrors the project's `Clock` injection.
- **`@DataClassName('MedicationRow'/'TimeSlotRow')`** — avoids the drift-generated row class colliding with the domain `Medication` entity.
- **`startDate` stored as a UTC calendar date** (`DateTime.utc(y,m,d)`) and the aggregate persisted in a single `transaction` — no tz day-shift, all-or-nothing write.
- **Imperative one-shot Save** (`ref.read` + local in-flight flag) rather than a notifier — no shared observed state (KISS).

### Deviations from plan
- **Tasks 6–9 (IdGenerator)**: `lib/core/id/` was added beyond the original spec's Affected Areas to resolve the §2.1 domain-purity conflict; refines AC-7/AC-9 (documented in plan/research). Approved.
- **Task 1**: drift stack resolved to **2.31.x** (not latest) due to the SDK's `analyzer 9.0.0` ceiling; whole stack added in one `flutter pub add` solve.
- **Task 13**: a 3-import fix was applied to `database.dart` (necessary for compilation — its `.g.dart` part references the `textEnum` enums; `dart analyze` passed without them but `flutter test` did not).

### Acceptance criteria
All 25 verified (PASS) — `dart analyze` clean, `flutter test` 384/384, `flutter build apk` ✓.
- [x] AC-1: drift/uuid dependencies added
- [x] AC-2/3: AppDatabase (schemaVersion 1, migration, FK pragma) + kept-alive provider
- [x] AC-4/5: `Medications` + `TimeSlots` schema (DataClassName, cascade FK)
- [x] AC-6/7: pure-Dart domain entities + typed value-object IDs
- [x] AC-8/9: `MedicationRepository` contract + `AddMedication` use case (IdGenerator + UTC clock)
- [x] AC-10/11/12/13: name / times / course-duration validation + valid-input forwarding
- [x] AC-14/15/16: transactional insert + exceptions caught + null-safe round-trip mapper + UTC
- [x] AC-17/18/19/20: modal `ConsumerStatefulWidget`, Save → pop/SnackBar, in-flight disable, per-form dose/stock mapping
- [x] AC-21: success + error strings in en/de/uk
- [x] AC-22/23/24: use-case + data-layer + rewritten modal tests
- [x] AC-25: build_runner + analyze + test all green
