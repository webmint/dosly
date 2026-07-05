# Task 003: Add `markMissed` to `IntakeRepository` (contract + impl + fakes)

**Agent**: architect
**Review checkpoint**: No
**Files**: `lib/features/meds/domain/repositories/intake_repository.dart` (modify), `lib/features/meds/data/repositories/intake_repository_impl.dart` (modify), `test/features/meds/presentation/screens/today_screen_test.dart` (modify — fakes)
**Depends on**: 002
**Blocks**: 004, 005
**Context docs**: None

## Description

Extend the `IntakeRepository` contract with a single operation to persist an auto-generated `missed` occurrence, and implement it over the Task 002 data-source write. This is an **interface change** — per the MEMORY blast-radius lesson, the same atomic task must keep every implementer compiling: the concrete `IntakeRepositoryImpl` gains the method, and the **2 hand-written `implements IntakeRepository` fakes** in `today_screen_test.dart` (`_LoadingIntakeRepository`, `_ErrorIntakeRepository`) get a no-op override. (The 3 `extends Mock implements IntakeRepository` mocks auto-satisfy — no change.)

## Change details

- In `lib/features/meds/domain/repositories/intake_repository.dart`:
  - Declare `Future<Either<Failure, Intake>> markMissed(Intake intake);` with dartdoc: persists an auto-generated `missed` occurrence via an insert-that-never-overwrites; `Right(intake)` on success (incl. the ignore case), `Left(Failure)` on storage error; NOT user-initiated (auto-miss engine only).
- In `lib/features/meds/data/repositories/intake_repository_impl.dart`:
  - Add `@override Future<Either<Failure, Intake>> markMissed(Intake intake)` that `try { await _dataSource.insertMissedIntake(intakeToCompanion(intake)); return Right(intake); } catch (e) { return Left(Failure.cache('Failed to record missed intake: $e')); }` — mirroring `markTaken`/`skip`.
- In `test/features/meds/presentation/screens/today_screen_test.dart`:
  - Add `@override Future<Either<Failure, Intake>> markMissed(Intake intake) async => ...` no-op to `_LoadingIntakeRepository` and `_ErrorIntakeRepository` (match their existing style: loading fake can return a never-completing/`Right`, error fake can return `Left(...)` — consistent with their other overrides).

## Contracts

### Expects
- `intake_local_data_source.dart` has `insertMissedIntake(IntakesCompanion companion)` (Task 002).
- `intake_mapper.dart` exports `intakeToCompanion(Intake)` (existing).
- `today_screen_test.dart` declares `_LoadingIntakeRepository` and `_ErrorIntakeRepository` that `implements IntakeRepository`.

### Produces
- `intake_repository.dart` declares `Future<Either<Failure, Intake>> markMissed(Intake intake)`.
- `intake_repository_impl.dart` has `@override` `markMissed` calling `_dataSource.insertMissedIntake(intakeToCompanion(intake))` and mapping errors to `Left(Failure.cache(...))`.
- `today_screen_test.dart` `_LoadingIntakeRepository` and `_ErrorIntakeRepository` each declare `markMissed`.

## Done when
- [x] `IntakeRepository` declares `markMissed`; `IntakeRepositoryImpl` implements it via `insertMissedIntake`.
- [x] Both hand-written fakes override `markMissed`.
- [x] **Project-wide** `dart analyze` is clean (no "missing concrete implementation" errors anywhere).
- [x] The existing suite still compiles.

**Spec criteria addressed**: AC-8, AC-7, AC-9, AC-15 (fakes)

## Completion Notes

**Status**: Complete
**Completed**: 2026-07-04
**Files changed**: `lib/features/meds/domain/repositories/intake_repository.dart`, `lib/features/meds/data/repositories/intake_repository_impl.dart`, `test/features/meds/presentation/screens/today_screen_test.dart`
**Contract**: Expects [3/3 verified] | Produces [3/3 verified]
**Notes**: `markMissed(Intake) → Either<Failure, Intake>` added between `skip` and `undo`. Impl mirrors `markTaken`/`skip` but calls `insertMissedIntake` (insert-or-ignore) instead of `upsertIntake` (DoUpdate) — the never-clobber distinction. Both hand-written fakes (`_LoadingIntakeRepository` L140, `_ErrorIntakeRepository` L168) got `async => Right(intake)` no-ops copied from their `markTaken`/`skip`; their loading/error semantics live in `watchAll()` so unaffected. The 3 `extends Mock` doubles auto-satisfy (untouched). Project-wide `dart analyze` clean; `flutter test test/features/meds/` 380/380. Code review: APPROVE (no issues).
