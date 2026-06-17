# Task 002: Domain enums + ID value objects

**Agent**: architect
**Files**: `lib/features/meds/domain/entities/medication_form.dart`, `lib/features/meds/domain/entities/dose_unit.dart`, `lib/features/meds/domain/entities/schedule_frequency.dart`, `lib/features/meds/domain/value_objects/medication_id.dart`, `lib/features/meds/domain/value_objects/time_slot_id.dart`
**Depends on**: None
**Blocks**: 003, 004, 005, 011
**Context docs**: `specs/032-med-persistence/data-model.md`
**Review checkpoint**: No

**Description**:
Define the pure-Dart leaf types of the medication domain model: three enums and two typed-string ID value objects. These have no dependencies on other domain types and unblock everything else. Per the [research.md](../research.md) decision, the IDs are plain `freezed` value objects with **no `generate()`** (IDs come from the injected `IdGenerator` in task 006).

**Change details**:
- `medication_form.dart`: `enum MedicationForm { tablet, capsule, syrup, drops, injection, inhaler, cream, sachet }` (order is the storage contract — do not reorder/rename without a migration).
- `dose_unit.dart`: `enum DoseUnit { tablet, capsule, ml, mg, drops, units, puff, application, sachet }`.
- `schedule_frequency.dart`: `enum ScheduleFrequency { daily }` (only `daily` built this spec).
- `value_objects/medication_id.dart`: `@freezed` `MedicationId` wrapping `String value` (single-field factory, value equality). No Flutter/uuid imports.
- `value_objects/time_slot_id.dart`: `@freezed` `TimeSlotId` wrapping `String value`.
- Run `dart run build_runner build --delete-conflicting-outputs` to emit `*.freezed.dart`.
- All files: dartdoc on every public type. NO `package:flutter/*`, `package:drift/*`, or `package:uuid/*` imports (constitution §2.1).

**Done when**:
- [ ] The three enums and two ID classes exist with the exact value names above
- [ ] `MedicationId`/`TimeSlotId` are `freezed` (generated `*.freezed.dart` committed); no hand-rolled `==`
- [ ] No `domain/` file imports `package:flutter`, `package:drift`, or `package:uuid`
- [ ] `dart analyze` passes; generated files committed

## Contracts
### Expects
- `lib/features/meds/domain/` directory may be created (no prior meds domain code)
### Produces
- `medication_form.dart` exports `enum MedicationForm` with values `tablet, capsule, syrup, drops, injection, inhaler, cream, sachet`
- `dose_unit.dart` exports `enum DoseUnit` with values `tablet, capsule, ml, mg, drops, units, puff, application, sachet`
- `schedule_frequency.dart` exports `enum ScheduleFrequency` with value `daily`
- `medication_id.dart` exports `MedicationId` with a `String value` field; `time_slot_id.dart` exports `TimeSlotId` with a `String value` field

**Spec criteria addressed**: AC-6, AC-7

## Completion Notes
**Completed**: 2026-06-17
**Status**: Complete
**Files changed**: medication_form.dart, dose_unit.dart, schedule_frequency.dart, value_objects/medication_id.dart (+.freezed.dart), value_objects/time_slot_id.dart (+.freezed.dart)
**Contract**: Expects 1/1 | Produces 4/4
**Notes**: freezed 3.x → IDs declared `@freezed abstract class`. `--delete-conflicting-outputs` is DEPRECATED in build_runner ≥2.15 (ignored w/ warning) — drop it. build_runner also regenerated `settings_provider.g.dart` + `shared_preferences_provider.g.dart`: the committed copies had STALE dartdoc (source edited earlier without re-running codegen); the diff is 100% dartdoc comments, zero logic — accepted as a correction. Domain purity verified (no flutter/drift/uuid imports).
