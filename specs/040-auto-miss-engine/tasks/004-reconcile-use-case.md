# Task 004: Add the `ReconcileMissedIntakes` use case

**Agent**: architect
**Review checkpoint**: Yes (convergence — depends on 001 + 003; high-risk never-clobber orchestration)
**Files**: `lib/features/meds/domain/usecases/reconcile_missed_intakes.dart` (new), `test/features/meds/domain/usecases/reconcile_missed_intakes_test.dart` (new)
**Depends on**: 001, 003
**Blocks**: 006
**Context docs**: None

## Description

Create the orchestrating use case. It reads the intake window from the settings domain, takes point-in-time snapshots of medications and stored intakes, runs the pure `findAutoMissDoses` derivation, mints a fresh `IntakeId` per eligible occurrence, and persists each as a `missed` `Intake` via `IntakeRepository.markMissed`. It is idempotent (a second run over the same state writes nothing) and never clobbers user intent (eligibility excludes any occurrence that already has a row). Pure Dart — no Flutter/drift imports; the settings dependency is the abstract `SettingsRepository` (its public domain API).

## Change details

- In `lib/features/meds/domain/usecases/reconcile_missed_intakes.dart` (new):
  - Imports: `package:fpdart`, `core/error/failures.dart`, `core/id/id_generator.dart`, `../entities/intake.dart`, `../entities/intake_status.dart`, `../repositories/intake_repository.dart`, `../repositories/medication_repository.dart`, `../value_objects/intake_id.dart`, `../value_objects/missed_intake_reconciliation.dart`, and `../../../settings/domain/repositories/settings_repository.dart` + `../../../settings/domain/value_objects/intake_window.dart`.
  - `class ReconcileMissedIntakes` with `const` constructor taking `(MedicationRepository, IntakeRepository, SettingsRepository, IdGenerator)` as private final fields.
  - `Future<Either<Failure, int>> call({required DateTime now})`:
    - `final window = _settingsRepository.load().fold((_) => IntakeWindow.defaultValue, (s) => s.intakeWindow);` (resilient — default on Left).
    - `final medsEither = await _medicationRepository.watchAll().first;` → on `Left` return it.
    - `final intakesEither = await _intakeRepository.watchAll().first;` → on `Left` return it.
    - `final eligible = findAutoMissDoses(meds: meds, intakes: intakes, window: window, now: now);`
    - For each eligible `DueDose`, build `Intake(id: IntakeId(_idGenerator.newId()), medicationId: d.medication.id, slotId: d.slot.id, scheduledAt: d.scheduledAt, confirmedAt: null, status: IntakeStatus.missed, notes: null)` and `await _intakeRepository.markMissed(intake)`; on the first `Left`, return it (fail-fast); else increment a counter.
    - Return `Right(count)`.
  - dartdoc: idempotent, never-clobbers, resilient window read, single-day scope.
- In the test file (new): use mocktail mocks for `MedicationRepository`/`IntakeRepository`/`SettingsRepository` + a fake `IdGenerator`, fixed `now`. Cover: writes one `missed` per eligible occurrence (verify `markMissed` called with `status == missed`, `confirmedAt == null`); idempotency (occurrences already having rows → `markMissed` never called); never-clobber (a `taken` occurrence past window is not passed to `markMissed`); meds snapshot `Left` → returns `Left` (no writes); intakes snapshot `Left` → returns `Left`; settings `load()` `Left` → falls back to `IntakeWindow.defaultValue` and still reconciles; a `markMissed` `Left` → returns `Left`; returns `Right(count)` on success.

## Contracts

### Expects
- `findAutoMissDoses({meds, intakes, window, now}) → List<DueDose>` (Task 001).
- `IntakeRepository.markMissed(Intake) → Future<Either<Failure, Intake>>` (Task 003) and `IntakeRepository.watchAll()`.
- `MedicationRepository.watchAll()` returns `Stream<Either<Failure, List<Medication>>>` (existing).
- `SettingsRepository.load()` returns `Either<Failure, AppSettings>` synchronously; `AppSettings.intakeWindow` is an `IntakeWindow`; `IntakeWindow.defaultValue` exists (existing — spec 039).
- `IdGenerator.newId()` and `IntakeId` (existing).

### Produces
- `reconcile_missed_intakes.dart` exports `ReconcileMissedIntakes` with `const` constructor `(MedicationRepository, IntakeRepository, SettingsRepository, IdGenerator)`.
- `ReconcileMissedIntakes.call({required DateTime now})` returns `Future<Either<Failure, int>>`.
- The use case constructs `Intake` with `status: IntakeStatus.missed` and `confirmedAt: null` and calls `findAutoMissDoses` + `markMissed`.

## Done when
- [x] Use case reads window (settings, default on Left), snapshots meds/intakes via `watchAll().first`, derives, and writes `missed` rows.
- [x] Idempotent + never-clobber proven by tests (mock verifies `markMissed` not called for occurrences with existing rows).
- [x] Every path returns `Either<Failure, int>`; no `DateTime.now()`; no Flutter/drift import.
- [x] `flutter test test/features/meds/domain/usecases/reconcile_missed_intakes_test.dart` green; `dart analyze` clean on changed files.

**Spec criteria addressed**: AC-5, AC-6, AC-7, AC-8

## Completion Notes

**Status**: Complete
**Completed**: 2026-07-04
**Files changed**: `lib/features/meds/domain/usecases/reconcile_missed_intakes.dart` (new), `test/features/meds/domain/usecases/reconcile_missed_intakes_test.dart` (new)
**Contract**: Expects [5/5 verified] | Produces [3/3 verified]
**Notes**: `ReconcileMissedIntakes(MedicationRepository, IntakeRepository, SettingsRepository, IdGenerator)`, `call({required DateTime now}) → Either<Failure, int>`. Window read resilient (default on Left); meds/intakes snapshots via `watchAll().first` (Left short-circuits, zero writes); fail-fast on first `markMissed` Left. Never-clobber enforced by eligibility (derivation excludes existing-row occurrences) — proven by `verifyNever(markMissed)` across taken/skipped/missed. 8 mocktail tests, no real DB, clock-injected. Nested-async-fold idiom unifies the return type (reviewer confirmed correct). Code review: APPROVE. **Follow-up (deferred to Task 007)**: `intake_status.dart`'s "missed reserved / not produced yet" dartdoc is now stale — `missed` IS produced by this use case; update that comment in Task 007.
