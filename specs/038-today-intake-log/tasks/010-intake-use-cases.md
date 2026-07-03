# Task 010: Intake use cases (MarkIntakeTaken, SkipIntake, UndoIntake)

**Agent**: architect
**Files**: `lib/features/meds/domain/usecases/mark_intake_taken.dart`, `skip_intake.dart`, `undo_intake.dart`, `test/features/meds/domain/usecases/undo_intake_test.dart`
**Depends on**: 002, 007
**Blocks**: 012
**Context docs**: specs/038-today-intake-log/data-model.md
**Review checkpoint**: No

**Description**:
Single-purpose domain use cases mirroring `AddMedication`/`DeleteMedication`. `MarkIntakeTaken`/`SkipIntake` build an `Intake` (fresh `IntakeId` from the injected `IdGenerator`, `confirmedAt` = injected clock now in UTC, correct `status`) and delegate to the repository. `UndoIntake` enforces the grace window (domain owns the business rule) before deleting.

**Change details**:
- `mark_intake_taken.dart`: `class MarkIntakeTaken { MarkIntakeTaken(this._repo, this._ids); Future<Either<Failure, Intake>> call({required MedicationId medicationId, required TimeSlotId slotId, required DateTime scheduledAt, required DateTime now}) }` — builds `Intake(id: IntakeId(_ids.newId()), ..., scheduledAt: scheduledAt.toUtc(), confirmedAt: now.toUtc(), status: IntakeStatus.taken)` and calls `_repo.markTaken(intake)`.
- `skip_intake.dart`: same shape, `status: IntakeStatus.skipped`, calls `_repo.skip(intake)`.
- `undo_intake.dart`: `class UndoIntake { UndoIntake(this._repo); Future<Either<Failure, void>> call({required IntakeId id, required DateTime confirmedAt, required DateTime now}) }` — if `now.difference(confirmedAt) > kIntakeUndoGracePeriod` return `Left(Failure.validation(...))` (grace expired, locked); else `_repo.undo(id)`.
- Unit test `undo_intake_test.dart`: within grace → repo.undo called (Right); beyond grace → `Left`, repo.undo NOT called (mocktail).

**Contracts**:

### Expects
- `IntakeRepository` (Task 007); `Intake`, `IntakeId`, `IntakeStatus`, `kIntakeUndoGracePeriod` (Task 002); `IdGenerator` in `lib/core/id/id_generator.dart`.

### Produces
- `mark_intake_taken.dart` exports `class MarkIntakeTaken` with a `call(...)` returning `Future<Either<Failure, Intake>>` using `IntakeStatus.taken`.
- `skip_intake.dart` exports `class SkipIntake` using `IntakeStatus.skipped`.
- `undo_intake.dart` exports `class UndoIntake` whose `call` returns `Left` when `now - confirmedAt > kIntakeUndoGracePeriod` and otherwise calls `IntakeRepository.undo`.

**Done when**:
- [ ] Three use cases compile; undo enforces the grace window (unit-tested both branches).
- [ ] `confirmedAt`/`scheduledAt` stored as UTC.
- [ ] No Flutter/drift import; `dart analyze` + `flutter test test/features/meds/domain/usecases/` pass.

**Spec criteria addressed**: AC-9, AC-12, AC-13

## Completion Notes
**Status**: Complete
**Completed**: 2026-07-02
**Files changed**: `usecases/mark_intake_taken.dart`, `skip_intake.dart`, `undo_intake.dart`, `test/features/meds/domain/usecases/undo_intake_test.dart`
**Contract**: Expects [ok] | Produces [3/3] — MarkIntakeTaken (taken), SkipIntake (skipped), UndoIntake (grace guard, inclusive boundary); 0 forbidden imports.
**Notes**: `IdGenerator.newId()`; `Failure.validation(field:, message:)` for grace-expired. Grace const at `value_objects/intake_grace.dart`. UTC via `.toUtc()`. 3/3 undo tests pass (within / boundary / beyond → verifyNever). `dart analyze` clean.
