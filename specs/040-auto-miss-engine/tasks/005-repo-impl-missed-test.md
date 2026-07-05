# Task 005: Test `markMissed` at the repository-impl / DB level

**Agent**: qa-engineer
**Review checkpoint**: No
**Files**: `test/features/meds/data/repositories/intake_repository_impl_test.dart` (modify)
**Depends on**: 003
**Blocks**: None
**Context docs**: None

## Description

Prove the DB-level never-clobber and error-mapping contract of `markMissed` against a **real in-memory drift database** (constitution §3.4 — data-layer tests use a fake or in-memory drift instance, never mocks for the DB itself). This is the airtight proof the domain use-case test (Task 004, mock-based) structurally cannot give: that `insertOrIgnore` preserves an existing `taken`/`skipped` row and that a `missed` row round-trips as UTC / by enum name.

## Change details

- In `test/features/meds/data/repositories/intake_repository_impl_test.dart`, add a `group('markMissed', ...)`:
  - **Happy path**: on an empty occurrence, `markMissed(missedIntake)` returns `Right`, and reading the row back gives `status == IntakeStatus.missed`, `confirmedAt == null`, `scheduledAt` equal (same absolute UTC moment via `isAtSameMomentAs`).
  - **Never-clobber**: pre-insert a `taken` row for occurrence `(medId, slotId, scheduledAt)` (via `markTaken`), then call `markMissed` for the **same** occurrence (fresh id) → returns `Right` but the stored row is still `taken` (insert-or-ignore skipped it). Repeat asserting a `skipped` row is likewise preserved.
  - **Error path**: with a closed/failing database (mirror the existing error-path style in this file), `markMissed` returns `Left(CacheFailure)`.
  - Reuse the file's existing in-memory `AppDatabase` setUp/tearDown and intake fixtures.

## Contracts

### Expects
- `IntakeRepositoryImpl.markMissed(Intake) → Future<Either<Failure, Intake>>` (Task 003).
- The test file already builds an in-memory `AppDatabase` and an `IntakeRepositoryImpl` with intake fixtures (existing — spec 038).

### Produces
- `intake_repository_impl_test.dart` contains `group('markMissed'` with a never-clobber test asserting an existing `taken`/`skipped` row is preserved and an error test asserting `Left(CacheFailure)`.

## Done when
- [x] `markMissed` happy-path, never-clobber (taken + skipped preserved), and error tests pass against the in-memory DB.
- [x] `missed` row round-trips (status by name, UTC `scheduledAt`).
- [x] `flutter test test/features/meds/data/repositories/intake_repository_impl_test.dart` green; `dart analyze` clean on changed files.

**Spec criteria addressed**: AC-7, AC-8, AC-9

## Completion Notes

**Status**: Complete
**Completed**: 2026-07-04
**Files changed**: `test/features/meds/data/repositories/intake_repository_impl_test.dart` (pure additions, 233 lines)
**Contract**: Expects [1/1 verified] | Produces [1/1 verified]
**Notes**: Added `group('IntakeRepositoryImpl.markMissed() — real in-memory DB')` (4 tests) using a real `NativeDatabase.memory()` AppDatabase (the file's other groups mock the data source; this group needed a real DB to exercise SQLite's `INSERT OR IGNORE`). Never-clobber tests READ THE ROW BACK and assert the `taken`/`skipped` row's status + `confirmedAt` survive `markMissed` (airtight proof). Happy path asserts `missed`/`confirmedAt==null`/`isAtSameMomentAs`. Error path closes the DB → `Left(CacheFailure)`. Seeds a parent medication row for the FK. `hide isNull` on the drift import avoids a matcher collision. Full suite 788/788. Code review: APPROVE.
