# Task 004: Domain aggregate — MedicationType, Schedule, Medication

**Agent**: architect
**Files**: `lib/features/meds/domain/entities/medication_type.dart`, `lib/features/meds/domain/entities/schedule.dart`, `lib/features/meds/domain/entities/medication.dart`
**Depends on**: 002, 003
**Blocks**: 007, 008
**Context docs**: `specs/032-med-persistence/data-model.md`
**Review checkpoint**: No

**Description**:
Define the sealed `MedicationType`, the `Schedule`, and the `Medication` aggregate root that ties the whole domain model together. Pure Dart only.

**Change details**:
- `medication_type.dart`: `@freezed sealed class MedicationType` with two factories: `MedicationType.continuous({ required DateTime startDate })` and `MedicationType.course({ required DateTime startDate, required int durationDays, required int pauseDays })`. Document that the end date is derived and `pauseDays > 0` means cyclic.
- `schedule.dart`: `@freezed Schedule` with `@Default(ScheduleFrequency.daily) ScheduleFrequency frequency` and `required List<TimeSlot> slots` (import `schedule_frequency.dart`, `time_slot.dart`).
- `medication.dart`: `@freezed Medication` with `MedicationId id`, `String name`, `MedicationForm form`, `MedicationType type`, `Schedule schedule`, `Dosage? dosePerIntake`, `PackStock? stock`, `String? notes`, `DateTime createdAt`.
- Run `build_runner`. Dartdoc each public type; no Flutter/drift/uuid imports.

**Done when**:
- [ ] `MedicationType` is a sealed freezed union with `continuous` and `course` factories carrying the fields above
- [ ] `Schedule` defaults `frequency` to `ScheduleFrequency.daily` and holds `List<TimeSlot> slots`
- [ ] `Medication` exposes all nine fields with the exact types above; `dosePerIntake` and `stock` are nullable
- [ ] No Flutter/drift/uuid imports; `dart analyze` passes; generated files committed

## Contracts
### Expects
- `MedicationForm`, `ScheduleFrequency`, `MedicationId` (task 002); `Dosage`, `PackStock`, `TimeSlot` (task 003)
### Produces
- `medication_type.dart` exports sealed `MedicationType` with `continuous({startDate})` and `course({startDate, durationDays, pauseDays})`
- `schedule.dart` exports `Schedule` with `frequency` (default `ScheduleFrequency.daily`) and `List<TimeSlot> slots`
- `medication.dart` exports `Medication` with fields `id, name, form, type, schedule, dosePerIntake, stock, notes, createdAt`

**Spec criteria addressed**: AC-6

## Completion Notes
**Completed**: 2026-06-17
**Status**: Complete
**Files changed**: medication_type.dart, schedule.dart, medication.dart (+ 3 .freezed.dart)
**Contract**: Expects 2/2 | Produces 3/3
**Notes**: MedicationType = `@freezed sealed class` (no abstract, matches Failure idiom); Schedule/Medication = `@freezed abstract class`. Course end date derived (startDate+durationDays−1), not stored. Domain model now complete & pure. analyze clean.
