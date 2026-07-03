# Task 007: Intake repository contract

**Agent**: architect
**Files**: `lib/features/meds/domain/repositories/intake_repository.dart`
**Depends on**: 002
**Blocks**: 009, 010
**Context docs**: None
**Review checkpoint**: No

**Description**:
Define the domain-layer persistence contract for intake events, mirroring `MedicationRepository`. Pure Dart, `Either`-returning. Consumed by the use cases (Task 010) and implemented in the data layer (Task 009).

**Change details**:
- `intake_repository.dart`:
  ```dart
  abstract interface class IntakeRepository {
    Stream<Either<Failure, List<Intake>>> watchAll();
    Future<Either<Failure, Intake>> markTaken(Intake intake);
    Future<Either<Failure, Intake>> skip(Intake intake);
    Future<Either<Failure, void>> undo(IntakeId id);
  }
  ```
  - `markTaken`/`skip` upsert the given occurrence (idempotent per `(medicationId, slotId, scheduledAt)`); `undo` deletes the row (returns to pending). Idempotent-absent `undo` is a `Right` no-op.
  - Full dartdoc on every method (incl. the idempotency + `Either` contract), matching `MedicationRepository`'s style.

**Contracts**:

### Expects
- `Intake`, `IntakeId` exist (Task 002); `Failure` exists in `lib/core/error/failures.dart`.

### Produces
- `intake_repository.dart` exports `abstract interface class IntakeRepository` with `watchAll()`, `markTaken(Intake)`, `skip(Intake)`, and `undo(IntakeId)`, all returning `Either`/`Stream<Either>`.
- No Flutter/drift import.

**Done when**:
- [ ] Contract declared with the four `Either`-returning members.
- [ ] Method dartdoc documents idempotency + both `Either` paths.
- [ ] No Flutter/drift import; `dart analyze` passes.

**Spec criteria addressed**: AC-6, AC-9, AC-12

## Completion Notes
**Status**: Complete
**Completed**: 2026-07-02
**Files changed**: `lib/features/meds/domain/repositories/intake_repository.dart`
**Contract**: Expects [ok] | Produces [2/2] — `IntakeRepository` with `watchAll`/`markTaken`/`skip`/`undo`; 0 forbidden imports.
**Notes**: Mirrors `MedicationRepository` style; idempotency + Either both-paths documented per method. `dart analyze` clean. Non-checkpoint — verification-gated.
