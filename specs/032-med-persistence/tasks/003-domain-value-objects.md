# Task 003: Domain value objects — Dosage, PackStock, TimeSlot

**Agent**: architect
**Files**: `lib/features/meds/domain/entities/dosage.dart`, `lib/features/meds/domain/entities/pack_stock.dart`, `lib/features/meds/domain/entities/time_slot.dart`
**Depends on**: 002
**Blocks**: 004
**Context docs**: `specs/032-med-persistence/data-model.md`
**Review checkpoint**: No

**Description**:
Define the freezed value objects that the `Medication` aggregate composes: `Dosage` (amount + unit), `PackStock` (pack inventory), and `TimeSlot` (an intended intake within a day). Pure Dart only.

**Change details**:
- `dosage.dart`: `@freezed Dosage` with `double amount`, `DoseUnit unit` (import `dose_unit.dart`).
- `pack_stock.dart`: `@freezed PackStock` with `int remaining`, `int total`, `int warnAt`.
- `time_slot.dart`: `@freezed TimeSlot` with `TimeSlotId id`, `int minuteOfDay`, `Dosage? doseOverride` (import `value_objects/time_slot_id.dart`, `dosage.dart`).
- Run `build_runner` to emit `*.freezed.dart`.
- Dartdoc each public type; no Flutter/drift/uuid imports.

**Done when**:
- [ ] `Dosage`, `PackStock`, `TimeSlot` exist as freezed classes with the fields above
- [ ] `TimeSlot.minuteOfDay` is an `int`; `TimeSlot.doseOverride` is nullable `Dosage`
- [ ] No Flutter/drift/uuid imports in any file
- [ ] `dart analyze` passes; generated files committed

## Contracts
### Expects
- `dose_unit.dart` exports `enum DoseUnit`; `value_objects/time_slot_id.dart` exports `TimeSlotId` (from task 002)
### Produces
- `dosage.dart` exports `Dosage` with `double amount` and `DoseUnit unit` fields
- `pack_stock.dart` exports `PackStock` with `int remaining`, `int total`, `int warnAt`
- `time_slot.dart` exports `TimeSlot` with `TimeSlotId id`, `int minuteOfDay`, `Dosage? doseOverride`

**Spec criteria addressed**: AC-6

## Completion Notes
**Completed**: 2026-06-17
**Status**: Complete
**Files changed**: dosage.dart, pack_stock.dart, time_slot.dart (+ 3 .freezed.dart)
**Contract**: Expects 2/2 | Produces 3/3
**Notes**: Straightforward freezed value objects. Domain purity verified. No other generated files drifted (the stale .g.dart correction landed in task 2).
