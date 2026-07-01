# Task 001: Add `delete` to repo contract + `DeleteMedication` use case

**Agent**: architect
**Status**: Complete
**Files**: `lib/features/meds/domain/repositories/medication_repository.dart`, `lib/features/meds/domain/usecases/delete_medication.dart`
**Depends on**: None
**Blocks**: 002, 003, 006
**Context docs**: None
**Review checkpoint**: No

**Description**:
Establish the domain surface for delete. Add a `delete(MedicationId)` method to the `MedicationRepository` contract and create a pure-Dart `DeleteMedication` use case that forwards to it. The use case is a thin forwarder (no validation — delete needs none), mirroring the settings-layer thin use cases (`SetThemeMode`, `SetManualLanguage`). Return type is `Future<Either<Failure, void>>` to match the codebase's void-op convention (settings repo/use cases), NOT fpdart `Unit`.

**Change details**:
- In `lib/features/meds/domain/repositories/medication_repository.dart`:
  - Add abstract method `Future<Either<Failure, void>> delete(MedicationId id);` with dartdoc. Docs must state: removes the medication and (via the DB's `onDelete: cascade` FK) all of its time slots; deleting an id that does not exist is a successful no-op (idempotent — `Right`); only a storage error surfaces as `Left(Failure)`.
  - Add `import '../value_objects/medication_id.dart';` (the file currently imports only `medication.dart`).
- Create `lib/features/meds/domain/usecases/delete_medication.dart`:
  - Library-level dartdoc explaining it is the single business operation for deleting a medication, pure Dart (no Flutter/drift/uuid imports), constitution §2.1.
  - `class DeleteMedication` with `const DeleteMedication(this._repository);`, `final MedicationRepository _repository;`, and `Future<Either<Failure, void>> call(MedicationId id) => _repository.delete(id);` with dartdoc.
  - Imports: `package:fpdart/fpdart.dart`, `../../../../core/error/failures.dart`, `../repositories/medication_repository.dart`, `../value_objects/medication_id.dart`.

**Done when**:
- [x] `MedicationRepository` declares `Future<Either<Failure, void>> delete(MedicationId id)` with dartdoc.
- [x] `DeleteMedication` exists, is pure Dart, and its `call(MedicationId)` returns `Future<Either<Failure, void>>` forwarding to `_repository.delete(id)`.
- [x] `delete_medication.dart` imports no `package:flutter/*`, `package:drift/*`, or `uuid`.
- [x] `dart analyze` passes on both files.

**Spec criteria addressed**: AC-1, AC-2

## Completion Notes

**Completed**: 2026-07-01
**Files changed**: `lib/features/meds/domain/repositories/medication_repository.dart` (added `delete` + `medication_id.dart` import), `lib/features/meds/domain/usecases/delete_medication.dart` (new)
**Contract**: Expects [3/3 verified] | Produces [3/3 verified]
**Code review**: APPROVE (no issues)
**Notes**: Thin forwarder use case; `Future<Either<Failure, void>>` convention (not fpdart `Unit`), matching settings layer. No deviations from plan.

## Contracts

### Expects
- `lib/features/meds/domain/repositories/medication_repository.dart` exists and declares `abstract interface class MedicationRepository` with `add`, `update`, `watchAll`.
- `lib/features/meds/domain/value_objects/medication_id.dart` exports `MedicationId(String value)`.
- `lib/core/error/failures.dart` exports the sealed `Failure` type.

### Produces
- `medication_repository.dart` declares `Future<Either<Failure, void>> delete(MedicationId id)`.
- `lib/features/meds/domain/usecases/delete_medication.dart` exports `class DeleteMedication` with a `const DeleteMedication(` constructor.
- `DeleteMedication` has `Future<Either<Failure, void>> call(MedicationId id)` returning `_repository.delete(id)`.
