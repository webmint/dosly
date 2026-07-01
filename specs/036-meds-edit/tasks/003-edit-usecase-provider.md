# Task 003: Create the `EditMedication` use case + `editMedicationProvider`

**Agent**: architect
**Files**: `lib/features/meds/domain/usecases/edit_medication.dart` (new), `lib/features/meds/presentation/providers/medication_providers.dart`
**Depends on**: 002
**Blocks**: 004, 007
**Context docs**: `specs/036-meds-edit/contracts.md`
**Review checkpoint**: No

**Description**:
Create the `EditMedication` use case — the single place edit validation + slot-ID reconciliation lives — and wire it through the composition seam as `editMedicationProvider`. It validates with the same rules as `AddMedication`, preserves the original medication's `id` and `createdAt`, reconciles `TimeSlotId`s (reuse the original id where the `minuteOfDay` is unchanged, mint a new id otherwise), assembles the updated aggregate via `copyWith`, and forwards to `MedicationRepository.update`.

**Change details**:
- Create `lib/features/meds/domain/usecases/edit_medication.dart` (pure Dart — no Flutter/drift), modeled on `add_medication.dart`:
  - `class EditMedication { const EditMedication(this._repository, this._idGenerator); final MedicationRepository _repository; final IdGenerator _idGenerator; ... }`
  - `Future<Either<Failure, Medication>> call({ required Medication original, required String name, required MedicationForm form, required List<int> intakeMinutes, required MedicationType type, Dosage? dosePerIntake, PackStock? stock, String? notes })`
  - Validation (identical to `AddMedication`, repository NOT called on failure): empty trimmed `name` → `Failure.validation(field:'name')`; `intakeMinutes.isEmpty` → `field:'times'`; `type case CourseType(:final durationDays) when durationDays < 1` → `field:'durationDays'`; non-null `dosePerIntake` with `amount <= 0` → `field:'dose'`.
  - Slot reconciliation: build `final existing = {for (final s in original.schedule.slots) s.minuteOfDay: s.id};` then `final slots = [for (final m in intakeMinutes) TimeSlot(id: existing[m] ?? TimeSlotId(_idGenerator.newId()), minuteOfDay: m)];` (preserve unchanged-minute ids; new minutes get fresh ids). No `!`.
  - Assemble: `final updated = original.copyWith(name: name.trim(), form: form, type: type, schedule: Schedule(slots: slots), dosePerIntake: dosePerIntake, stock: stock, notes: notes);` — `id` and `createdAt` are intentionally left untouched.
  - `return _repository.update(updated);`
  - Full dartdoc; named params; declared return types.
- In `lib/features/meds/presentation/providers/medication_providers.dart`:
  - Import `edit_medication.dart`; add:
    ```dart
    @riverpod
    EditMedication editMedication(Ref ref) => EditMedication(
      ref.watch(medicationRepositoryProvider),
      ref.watch(idGeneratorProvider),
    );
    ```
  - Regenerate `medication_providers.g.dart` (`dart run build_runner build`).

**Status**: Complete

**Done when**:
- [x] `edit_medication.dart` exports `class EditMedication` with the `call({required Medication original, ...})` signature above.
- [x] The use case preserves `original.id`/`original.createdAt` and reuses original `TimeSlotId`s for unchanged `minuteOfDay`s, minting new ids otherwise.
- [x] No `package:flutter`/`package:drift` import in the use case; no `!`/unchecked `as`.
- [x] `editMedicationProvider` is generated and exposed from `medication_providers.dart`.
- [x] `dart analyze` passes; `dart run build_runner build` regenerates cleanly.

## Completion Notes
**Completed**: 2026-06-19
**Files changed**: `lib/features/meds/domain/usecases/edit_medication.dart` (new), `medication_providers.dart`, `medication_providers.g.dart` (regen)
**Contract**: Expects [3/3 verified] | Produces [3/3 verified]
**Notes**: Validation messages copied verbatim from `add_medication.dart`; `copyWith` preserves id/createdAt; `original.schedule.copyWith(slots:)` preserves frequency. Code review = APPROVE WITH WARNINGS → fixed: reconciliation now keys `minuteOfDay → TimeSlot` (whole slot) and passes unchanged slots through **verbatim** (preserves `doseOverride`, not just the id) — closes a latent data-loss path (form currently always writes null override, but this is strictly safer). Pure Dart; 235 meds tests pass; analyze clean.

## Contracts

### Expects
- `MedicationRepository` declares `update(Medication)` (Task 002).
- `IdGenerator`, `Medication` (with `copyWith`), `Schedule`, `TimeSlot`, `TimeSlotId`, `MedicationType`/`CourseType`, `Dosage`, `PackStock`, `Failure.validation` all exist.
- `medication_providers.dart` declares `medicationRepositoryProvider`, `addMedicationProvider`, `idGeneratorProvider`.

### Produces
- `edit_medication.dart` declares `class EditMedication` and a `call(` with a `required Medication original` parameter.
- `EditMedication.call` returns `Future<Either<Failure, Medication>>` and calls `_repository.update(`.
- `medication_providers.dart` declares `EditMedication editMedication(Ref ref)` annotated `@riverpod`, exposing `editMedicationProvider`.

**Spec criteria addressed**: AC-9, AC-10, AC-11
