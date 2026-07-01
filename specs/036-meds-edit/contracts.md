# Contracts: Tap-to-Edit Medication

dosly has no remote backend — these are the internal domain/data contracts (constitution §5.3). Only NEW or CHANGED contracts are listed; everything else is reused unchanged.

## Domain — `MedicationRepository.update` (NEW method on existing interface)

`lib/features/meds/domain/repositories/medication_repository.dart`

```dart
/// Persists an UPDATE of an already-stored [medication], returning the stored
/// aggregate on success or a [Failure] on error. The medication's `id` must
/// already exist; its row is updated in place and its time slots are
/// reconciled (callers assign which TimeSlotIds survive — see EditMedication).
Future<Either<Failure, Medication>> update(Medication medication);
```

- **Input**: a fully-assembled `Medication` whose `id`/`createdAt` are the originals and whose `schedule.slots` already carry the intended (preserved or freshly-minted) `TimeSlotId`s.
- **Output**: `Right(medication)` (the same aggregate) on success.
- **Errors**: `Left(Failure.unknown(e, st))` — any data-source exception, caught in the impl. Never throws.
- **Breaking note**: adding this to the interface forces every `implements MedicationRepository` (impl + hand-written test fakes) to define it in the same change (mocktail mocks are unaffected).

## Domain — `EditMedication` use case (NEW)

`lib/features/meds/domain/usecases/edit_medication.dart`

```dart
class EditMedication {
  const EditMedication(this._repository, this._idGenerator);

  Future<Either<Failure, Medication>> call({
    required Medication original,        // the medication being edited (source of id, createdAt, existing slot IDs)
    required String name,
    required MedicationForm form,
    required List<int> intakeMinutes,    // edited set of minute-of-day values
    required MedicationType type,
    Dosage? dosePerIntake,
    PackStock? stock,
    String? notes,
  });
}
```

- **Validation** (identical to `AddMedication`, repository not called on failure):
  | Rule | Returns |
  |------|---------|
  | `name.trim().isEmpty` | `Left(ValidationFailure(field:'name'))` |
  | `intakeMinutes.isEmpty` | `Left(ValidationFailure(field:'times'))` |
  | `type is CourseType && durationDays < 1` | `Left(ValidationFailure(field:'durationDays'))` |
  | `dosePerIntake != null && amount <= 0` | `Left(ValidationFailure(field:'dose'))` |
- **Slot reconciliation**: build `Map<int minuteOfDay, TimeSlotId>` from `original.schedule.slots`; for each `m` in `intakeMinutes`, reuse the original ID when `m` is a key, otherwise mint a new `TimeSlotId(_idGenerator.newId())`. Slots are built in `intakeMinutes` order.
- **Aggregate assembly**: `original.copyWith(name: name.trim(), form: form, type: type, schedule: Schedule(slots: reconciledSlots), dosePerIntake: dosePerIntake, stock: stock, notes: notes)` — `id` and `createdAt` are NOT changed.
- **Output**: forwards to `MedicationRepository.update(updated)` and returns its result unchanged.

## Data — `MedicationLocalDataSource.upsertMedication` (NEW)

`lib/features/meds/data/datasources/medication_local_data_source.dart`

```dart
/// Upserts [medication] and reconciles its [slots] in a single transaction.
/// Updates the medication row IN PLACE (no cascade delete), removes time-slot
/// rows for this medication that are absent from [slots], and upserts the rest.
Future<void> upsertMedication(
  MedicationsCompanion medication,
  List<TimeSlotsCompanion> slots,
);
```

Transaction body:
1. `into(medications).insertOnConflictUpdate(medication)` — **NOT** `insertOrReplace` (a REPLACE deletes+reinserts the parent, cascade-deleting its slots via the `onDelete: cascade` FK).
2. `delete(timeSlots)..where((t) => t.medicationId.equals(medId) & t.id.isNotIn(incomingSlotIds))` — drop removed slots. (`incomingSlotIds` is never empty: `EditMedication` rejects empty `intakeMinutes` upstream.)
3. `into(timeSlots).insertOnConflictUpdate(slot)` for each incoming slot — preserved IDs update in place, new IDs insert.

`medId` is read from `medication.id.value` (the mapper always populates the companion PK via `MedicationsCompanion.insert`). Companions are produced by the existing `medicationToCompanion` / `timeSlotsToCompanions` mappers — no mapper change needed.

## Presentation — `editMedicationProvider` (NEW, codegen)

`lib/features/meds/presentation/providers/medication_providers.dart`

```dart
@riverpod
EditMedication editMedication(Ref ref) => EditMedication(
  ref.watch(medicationRepositoryProvider),
  ref.watch(idGeneratorProvider),
);
```

Plain `@riverpod` (autoDispose) function provider, mirroring `addMedicationProvider`. Consumed imperatively from the modal via `ref.read(editMedicationProvider).call(...)`.
