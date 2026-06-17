# Task 007: MedicationRepository contract + AddMedication use case

**Agent**: architect
**Files**: `lib/features/meds/domain/repositories/medication_repository.dart`, `lib/features/meds/domain/usecases/add_medication.dart`
**Depends on**: 004, 006
**Blocks**: 008, 009, 012
**Context docs**: `specs/032-med-persistence/data-model.md` (Validation Rules), `constitution.md` §3.2
**Review checkpoint**: No

**Description**:
Declare the abstract repository contract and implement the `AddMedication` use case — the single place medication-creation validation lives. The use case assembles the `Medication` aggregate (generating IDs via the injected `IdGenerator`, stamping `createdAt` from the ambient `clock`), then delegates to the repository.

**Change details**:
- `medication_repository.dart`: `abstract interface class MedicationRepository { Future<Either<Failure, Medication>> add(Medication medication); }` (imports fpdart, `core/error/failures.dart`, `entities/medication.dart`).
- `add_medication.dart`: `class AddMedication { const AddMedication(this._repository, this._idGenerator); ... }`. A `call({ required String name, required MedicationForm form, required List<int> intakeMinutes, required MedicationType type, Dosage? dosePerIntake, PackStock? stock, String? notes })` returning `Future<Either<Failure, Medication>>` that:
  - returns `Left(Failure.validation(field: 'name', ...))` when `name.trim()` is empty;
  - returns `Left(Failure.validation(field: 'times', ...))` when `intakeMinutes` is empty;
  - when `type` is `course` with `durationDays < 1`, returns `Left(Failure.validation(field: 'durationDays', ...))` (use a `switch`/pattern match on the sealed `MedicationType`, no `default:`);
  - otherwise builds `TimeSlot`s (`TimeSlotId(_idGenerator.newId())`, `minuteOfDay`), a `Schedule(slots: ...)`, and a `Medication` (`MedicationId(_idGenerator.newId())`, `createdAt: clock.now().toUtc()`), then returns `_repository.add(medication)` unchanged.
- Imports `package:clock/clock.dart` (allowed in domain). NO Flutter/drift/uuid imports.

**Done when**:
- [ ] `MedicationRepository.add` returns `Future<Either<Failure, Medication>>`
- [ ] `AddMedication` takes `(MedicationRepository, IdGenerator)` and validates name / times / course-duration as above
- [ ] valid input forwards to `repository.add` exactly once and returns its result unchanged
- [ ] `createdAt` uses `clock.now().toUtc()`; IDs come from `IdGenerator`; no `DateTime.now()`, no `default:` clause
- [ ] `dart analyze` passes

## Contracts
### Expects
- `Medication`, `MedicationType`, `Schedule`, `MedicationForm`, `Dosage`, `PackStock`, `TimeSlot`, `MedicationId`, `TimeSlotId` (tasks 002–004)
- `IdGenerator` exposes `newId()` (task 006); `Failure.validation({field, message})` exists (`core/error/failures.dart`)
### Produces
- `medication_repository.dart` exports `abstract interface class MedicationRepository` with `add(Medication)`
- `add_medication.dart` exports `class AddMedication` with constructor `(MedicationRepository, IdGenerator)` and a `call(...)` returning `Future<Either<Failure, Medication>>`

**Spec criteria addressed**: AC-8, AC-9, AC-10, AC-11, AC-12, AC-13, AC-16

## Completion Notes
**Completed**: 2026-06-17
**Status**: Complete
**Files changed**: domain/repositories/medication_repository.dart, domain/usecases/add_medication.dart
**Contract**: Expects 4/4 | Produces 2/2
**Notes**: Course-duration validation via `if (type case CourseType(:final durationDays) when durationDays < 1)` — no `default:`. `call(...)` takes `intakeMinutes: List<int>` (presentation maps TimeOfDay→minute). createdAt = `clock.now().toUtc()`; IDs from injected IdGenerator. Behavioral coverage in task 012. Domain pure.
