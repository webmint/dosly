# Task 002: Define Intake domain types

**Agent**: architect
**Files**: `lib/features/meds/domain/entities/intake_status.dart`, `lib/features/meds/domain/entities/intake.dart` (+ `intake.freezed.dart`), `lib/features/meds/domain/value_objects/intake_id.dart` (+ `intake_id.freezed.dart`), `lib/features/meds/domain/value_objects/intake_grace.dart`
**Depends on**: None
**Blocks**: 004, 007, 009, 010, 013
**Context docs**: specs/038-today-intake-log/data-model.md
**Review checkpoint**: No

**Description**:
Create the pure-Dart intake vocabulary that the whole slice builds on: the `IntakeStatus` enum, the typed `IntakeId`, the `Intake` entity, and the grace-period policy constant. One cohesive logical unit — all leaf/aggregate type declarations, no logic, no Flutter/drift/uuid imports (constitution §2.1). Mirrors `medication_id.dart` / `medication.dart` exactly.

**Change details**:
- `intake_status.dart`: `enum IntakeStatus { pending, taken, missed, skipped }` with a library dartdoc documenting the drift `textEnum` storage-by-name contract (do not reorder/rename without a migration). Only `taken`/`skipped` are persisted this slice.
- `intake_id.dart`: `@freezed abstract class IntakeId with _$IntakeId { const factory IntakeId(String value) = _IntakeId; }` — mirror `MedicationId`; no `generate()`.
- `intake.dart`: `@freezed abstract class Intake` with fields `IntakeId id`, `MedicationId medicationId`, `TimeSlotId slotId`, `DateTime scheduledAt`, `DateTime? confirmedAt`, `IntakeStatus status`, `String? notes` (per data-model.md).
- `intake_grace.dart`: `const Duration kIntakeUndoGracePeriod = Duration(minutes: 5);` with dartdoc citing constitution §5.2 (Settings-configurable later).
- Run build_runner to generate freezed parts.

**Contracts**:

### Expects
- `lib/features/meds/domain/value_objects/medication_id.dart` and `time_slot_id.dart` export `MedicationId` / `TimeSlotId`.

### Produces
- `intake_status.dart` declares `enum IntakeStatus` with values `pending, taken, missed, skipped` (in that order).
- `intake_id.dart` exports `IntakeId` with `const factory IntakeId(String value)`.
- `intake.dart` exports `Intake` (freezed) with fields `id, medicationId, slotId, scheduledAt, confirmedAt, status, notes`.
- `intake_grace.dart` declares `const Duration kIntakeUndoGracePeriod`.
- None of these files import `package:flutter`, `package:drift`, or `package:uuid`.

**Done when**:
- [ ] All four types compile with generated freezed parts.
- [ ] No Flutter/drift/uuid import in any of the files.
- [ ] Public APIs carry dartdoc.
- [ ] `dart analyze` passes on changed files.

**Spec criteria addressed**: AC-6, AC-13 (types), AC-15

## Completion Notes
**Status**: Complete
**Completed**: 2026-07-02
**Files changed**: `intake_status.dart`, `intake.dart` (+`.freezed.dart`), `intake_id.dart` (+`.freezed.dart`), `intake_grace.dart`
**Contract**: Expects [1/1] | Produces [5/5] — enum values in order; `IntakeId`/`Intake`/`kIntakeUndoGracePeriod` declared; 0 forbidden imports.
**Notes**: build_runner ignores `--delete-conflicting-outputs` in build_runner ^2.15 (ran fine regardless). Agent self-fixed a missing `intake_id.dart` import mid-task. `dart analyze`: no issues. Non-checkpoint task — verification-gated, no formal code review.
