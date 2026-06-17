# Medication Persistence

## Overview

Feature `032-med-persistence` gives the `meds` module its first `domain/` and `data/` layers and introduces the app's local SQLite database. Tapping **Save** in the add-medication modal now validates the form, writes a `Medication` aggregate (with all its time slots) to a drift database in a single transaction, pops the modal, and shows a localized SnackBar — or stays open and shows an error if validation fails.

This is the first full Clean-Architecture vertical slice for medication data: pure-Dart domain, drift-backed data layer, and `@riverpod`-wired composition seam. It mirrors the existing `settings` slice.

## Save Flow (end to end)

```
AddMedicationModal (ConsumerStatefulWidget)
  └─ ref.read(addMedicationProvider)   ← composition seam
        └─ AddMedication (use case)
              ├─ validate              → Left(ValidationFailure)  on error
              ├─ mint IDs via IdGenerator
              ├─ assemble Medication aggregate
              └─ MedicationRepository.add(medication)
                    └─ MedicationRepositoryImpl
                          └─ MedicationLocalDataSource.insertMedication(...)
                                └─ AppDatabase.transaction()
                                      ├─ medications.insert(row)
                                      └─ batch.insertAll(timeSlots, slots)
```

On `Right(medication)` the modal pops and shows a success SnackBar. On `Left(failure)` the modal stays open; validation failures show a field-specific message, all other failures show a generic "couldn't save" message. The Save button is disabled for the duration of the in-flight call to prevent double-submit.

```dart
// AddMedicationModal — Save handler (simplified)
Future<void> _save() async {
  setState(() => _isSaving = true);
  final result = await ref.read(addMedicationProvider).call(
    name: _nameController.text,
    form: _selectedForm,
    intakeMinutes: _intakeTimes.map((t) => t.hour * 60 + t.minute).toList(),
    type: _buildMedicationType(),
    dosePerIntake: _buildDosage(),
    stock: _buildPackStock(),
  );
  if (!mounted) return;
  result.fold(
    (failure) {
      setState(() => _isSaving = false);
      _showErrorSnackBar(failure);
    },
    (_) => Navigator.of(context).pop(),  // success SnackBar shown from MedsScreen
  );
}
```

## Domain Model

All entities live under `lib/features/meds/domain/` and are pure Dart — no Flutter, drift, or uuid imports.

### Medication (aggregate root)

```dart
@freezed
abstract class Medication with _$Medication {
  const factory Medication({
    required MedicationId id,
    required String name,
    required MedicationForm form,
    required MedicationType type,
    required Schedule schedule,
    Dosage? dosePerIntake,   // null for inhaler/cream/sachet
    PackStock? stock,        // null when stock is not tracked
    String? notes,
    required DateTime createdAt,  // UTC instant
  }) = _Medication;
}
```

### MedicationType (sealed union)

```dart
@freezed
sealed class MedicationType with _$MedicationType {
  const factory MedicationType.continuous({
    required DateTime startDate,  // UTC calendar date
  }) = ContinuousType;

  const factory MedicationType.course({
    required DateTime startDate,   // UTC calendar date
    required int durationDays,     // ≥ 1
    required int pauseDays,        // 0 = single course, > 0 = cyclic
  }) = CourseType;
}
```

The course end date is **derived** as `startDate + durationDays − 1`. It is not stored.

### Schedule and TimeSlot

```dart
@freezed
abstract class Schedule with _$Schedule {
  const factory Schedule({
    @Default(ScheduleFrequency.daily) ScheduleFrequency frequency,
    required List<TimeSlot> slots,
  }) = _Schedule;
}

@freezed
abstract class TimeSlot with _$TimeSlot {
  const factory TimeSlot({
    required TimeSlotId id,
    required int minuteOfDay,  // 0..1439 (wall-clock local minute)
    Dosage? doseOverride,      // reserved; always null from this spec's form
  }) = _TimeSlot;
}
```

### Dosage and PackStock

```dart
@freezed
abstract class Dosage with _$Dosage {
  const factory Dosage({
    required double amount,
    required DoseUnit unit,
  }) = _Dosage;
}

@freezed
abstract class PackStock with _$PackStock {
  const factory PackStock({
    required int remaining,
    required int total,
    required int warnAt,  // defaults to 0 when the form field is blank
  }) = _PackStock;
}
```

### Enums

| Enum | Values |
|------|--------|
| `MedicationForm` | `tablet, capsule, syrup, drops, injection, inhaler, cream, sachet` |
| `DoseUnit` | `tablet, capsule, ml, mg, drops, units, puff, application, sachet` |
| `ScheduleFrequency` | `daily` (only value built; others are domain-modeled for future specs) |

### Value-object IDs

`MedicationId(String value)` and `TimeSlotId(String value)` are single-field `@freezed` value objects. They carry no `generate()` factory — IDs are minted by the injected `IdGenerator` (see [Key Architecture Decisions](#key-architecture-decisions)).

## Validation

Validation lives exclusively in `AddMedication` (the use case). The repository is never called on invalid input.

| Rule | Returns |
|------|---------|
| `name.trim().isEmpty` | `Left(Failure.validation(field: 'name', ...))` |
| `intakeMinutes.isEmpty` | `Left(Failure.validation(field: 'times', ...))` |
| `type is CourseType && durationDays < 1` | `Left(Failure.validation(field: 'durationDays', ...))` |
| `dosePerIntake != null && amount <= 0` | `Left(Failure.validation(field: 'dose', ...))` |
| all valid | delegates to `MedicationRepository.add` and returns its result unchanged |

## Database Schema

### AppDatabase

`lib/core/database/database.dart` — `@DriftDatabase(tables: [Medications, TimeSlots])`.

- `schemaVersion = 1`
- `MigrationStrategy.onCreate` → `createAll()`
- `beforeOpen` → `pragma foreign_keys = ON;` (enforces the cascade delete on TimeSlots)

The database file is named `dosly`. Pass a `QueryExecutor` to the constructor to inject an in-memory database in tests.

### Medications table (`@DataClassName('MedicationRow')`)

| Column | Drift type | Nullable | Notes |
|--------|-----------|----------|-------|
| `id` | `text()` | no | PK; domain `MedicationId` value |
| `name` | `text()` | no | |
| `form` | `textEnum<MedicationForm>()` | no | stored by enum name |
| `doseAmount` | `real()` | yes | null ↔ `dosePerIntake == null` |
| `doseUnit` | `textEnum<DoseUnit>()` | yes | null ↔ `dosePerIntake == null` |
| `typeKind` | `textEnum<MedicationTypeKind>()` | no | `continuous` or `course` |
| `frequency` | `textEnum<ScheduleFrequency>()` | no | always `daily` (MVP) |
| `startDate` | `dateTime()` | no | UTC calendar date |
| `durationDays` | `integer()` | yes | course only |
| `pauseDays` | `integer()` | yes | course only |
| `stockRemaining` | `integer()` | yes | null ↔ `stock == null` |
| `stockTotal` | `integer()` | yes | null ↔ `stock == null` |
| `stockWarnAt` | `integer()` | yes | null ↔ `stock == null` |
| `notes` | `text()` | yes | |
| `createdAt` | `dateTime()` | no | UTC instant |

`MedicationTypeKind` is a storage discriminator enum defined in the data layer (not the domain). It maps to the domain's sealed `MedicationType` union in the mapper.

### TimeSlots table (`@DataClassName('TimeSlotRow')`)

| Column | Drift type | Nullable | Notes |
|--------|-----------|----------|-------|
| `id` | `text()` | no | PK |
| `medicationId` | `text()` | no | FK → `Medications.id`, `onDelete: cascade` |
| `minuteOfDay` | `integer()` | no | 0–1439 |
| `doseAmount` | `real()` | yes | `doseOverride.amount`; always null this spec |
| `doseUnit` | `textEnum<DoseUnit>()` | yes | `doseOverride.unit`; always null this spec |

The cascade FK is dormant this spec (no delete path yet) but is correct from v1 and is enforced via the `pragma foreign_keys = ON` pragma.

### Schema contract

Enum columns use `textEnum`, which persists **enum value names** (not indices). Reordering enum values is harmless; **renaming or removing** a stored value silently breaks reads of existing rows. Any such change requires bumping `schemaVersion` and writing a migration.

Never drop or alter a column without bumping `schemaVersion`. This is health data — silently defaulting a missing column corrupts a user's medication record.

## Mapping: Domain ↔ Drift

`lib/features/meds/data/mappers/medication_mapper.dart` translates between the domain aggregate and drift companions/rows. The mapper is pure functions (no state, no I/O).

| Domain | Storage |
|--------|---------|
| `dosePerIntake: Dosage(a, u)` | `doseAmount=a, doseUnit=u` |
| `dosePerIntake: null` | both dose columns null |
| `stock: PackStock(r, t, w)` | `stockRemaining=r, stockTotal=t, stockWarnAt=w` |
| `stock: null` | all three stock columns null |
| `type: ContinuousType(s)` | `typeKind=continuous, startDate=s, durationDays=null, pauseDays=null` |
| `type: CourseType(s, d, p)` | `typeKind=course, startDate=s, durationDays=d, pauseDays=p` |
| `schedule.slots[i]` | one `TimeSlots` row (FK = medication id) |

`PackStock` is only built when both `remaining` and `total` parse to non-negative integers. When stock fields are blank or unparseable, `stock` is null and all three stock columns are null.

## Riverpod Provider Wiring

`lib/features/meds/presentation/providers/medication_providers.dart` is the composition seam — the single file in `presentation/` permitted to import `data/` (constitution §2.1 amendment).

```dart
@riverpod
MedicationLocalDataSource medicationLocalDataSource(Ref ref) =>
    MedicationLocalDataSource(ref.watch(appDatabaseProvider));

@riverpod
MedicationRepository medicationRepository(Ref ref) =>
    MedicationRepositoryImpl(ref.watch(medicationLocalDataSourceProvider));

@riverpod
AddMedication addMedication(Ref ref) => AddMedication(
  ref.watch(medicationRepositoryProvider),
  ref.watch(idGeneratorProvider),
);
```

All three providers are plain `@riverpod` (autoDispose) function providers. Save is a one-shot imperative call from the modal (`ref.read(addMedicationProvider)`), not a notifier — there is no shared observed state to hold between calls.

The `appDatabaseProvider` and `idGeneratorProvider` are `@Riverpod(keepAlive: true)` singletons defined in `lib/core/`.

## Key Architecture Decisions

### Injected IdGenerator instead of `MedicationId.generate()`

`package:uuid` is confined to `lib/core/id/uuid_id_generator.dart`. The domain sees only an `IdGenerator` interface and `MedicationId(String value)` / `TimeSlotId(String value)` value objects. This mirrors the project's `Clock` injection pattern and keeps `domain/` free of third-party SDKs (constitution §2.1). In tests, inject a stub `IdGenerator` that returns deterministic IDs.

```dart
abstract interface class IdGenerator {
  String newId();
}
```

### `@DataClassName` to avoid drift row-class collision

Drift generates a data class from each table class. Without the annotation, the `Medications` table would emit a class named `Medication` — colliding with the domain entity. `@DataClassName('MedicationRow')` and `@DataClassName('TimeSlotRow')` resolve this cleanly without any additional wiring.

### UTC calendar date for `startDate`

`startDate` is stored as `DateTime.utc(year, month, day)` — a pure calendar date with no time component. Using `localDate.toUtc()` would shift the date across timezone boundaries (e.g. local midnight in UTC+3 is the prior day in UTC). The UTC-calendar-date approach is the only reliable choice for a date that must not shift when the user travels or the device timezone changes.

`createdAt` is stored as `clock.now().toUtc()` — a true UTC instant.

### Transactional write

The medication row and all time-slot rows are written in a single `AppDatabase.transaction()`. If any insert fails, the entire transaction is rolled back. The database never holds a medication row without its scheduled slots.

### Imperative one-shot Save

Save is wired as `ref.read(addMedicationProvider)` inside the button callback, with a local `_isSaving` boolean for in-flight state. A `AsyncNotifier` was explicitly rejected (KISS — there is no shared observed state for this one-shot action).

## Localization Keys (feature 032)

Five new keys added to `app_en.arb`, `app_de.arb`, and `app_uk.arb`:

| Key | English |
|-----|---------|
| `medsAddSaveSuccess` | Medication saved |
| `medsAddErrorGeneric` | Couldn't save the medication. Please try again. |
| `medsAddErrorName` | Please enter a medication name. |
| `medsAddErrorTimes` | Please add at least one intake time. |
| `medsAddErrorDuration` | Course duration must be at least 1 day. |

## Tests

- `test/features/meds/domain/usecases/add_medication_test.dart` — 5 unit tests: happy path, name-empty, no-times, course-duration-zero, repository-failure passthrough. Uses a `mocktail` mock for `MedicationRepository` and a fixed `Clock`.
- `test/features/meds/data/repositories/medication_repository_impl_test.dart` — in-memory drift round-trip and failure path.
- `test/features/meds/data/mappers/medication_mapper_test.dart` — 45 tests covering every nullable field combination and the full domain→companion→row→domain round-trip.
- `test/features/meds/presentation/widgets/add_medication_modal_test.dart` — rewritten: valid input invokes the use case and pops; invalid input shows the error SnackBar and does not pop. The earlier "Save is a no-op" assertions are removed.

## What This Feature Does NOT Include

- Reading / listing saved medications (`getAll` / `watch`) — body of `MedsScreen` remains `SizedBox.shrink()`. A future "meds list" spec adds the reactive query, empty state, and the FK index on `TimeSlots.medicationId`.
- Editing, deleting, or querying a medication beyond `add`.
- Notifications or reminder scheduling.
- `Intakes` records, intake state machine, or adherence calculation.
- Schedule frequencies other than `daily`.
- Pack-stock decrement on intake or low-stock warnings.
- Schema migrations beyond v1.
- Encryption-at-rest. Drift writes an unencrypted SQLite file. This is a deliberate MVP trade-off: the app is local-only with no sync surface, and the added complexity of SQLCipher was judged disproportionate at this stage. This decision should be revisited before any cloud sync or backup feature lands.

## Extending This Feature (guide for future specs)

**Reading medications (meds-list spec)**

1. Add a `getAll()` or `watchAll()` method to `MedicationRepository` (domain) and `MedicationRepositoryImpl` (data).
2. Add the corresponding drift query in `MedicationLocalDataSource`:
   ```dart
   Stream<List<MedicationRow>> watchAll() => select(medications).watch();
   ```
3. Reconstruct the `Medication` aggregate from the row + its `TimeSlotRow`s using the existing mapper.
4. Consider adding a database index on `TimeSlots.medicationId` for performance once the list query is introduced.

**Adding a new use case (e.g. `DeleteMedication`)**

1. Add `Future<Either<Failure, Unit>> delete(MedicationId id)` to `MedicationRepository`.
2. Implement in `MedicationRepositoryImpl` — the cascade FK means deleting the medication row automatically removes its time slots.
3. Add the use case class under `domain/usecases/`.
4. Wire a new provider in `medication_providers.dart`.

**Schema changes**

Always bump `AppDatabase.schemaVersion` and add a migration to `MigrationStrategy.onUpgrade`. Never rename a stored enum value without a migration.

## Related

- [`meds.md`](meds.md) — the add-medication modal's visual history (features 026–031), screen structure, and localization keys
- [`../architecture.md`](../architecture.md) — Clean Architecture layering, Riverpod patterns, `Either<Failure,T>`, and the new database section
- [`../../specs/032-med-persistence/spec.md`](../../specs/032-med-persistence/spec.md) — the full spec with all acceptance criteria
- [`../../specs/032-med-persistence/data-model.md`](../../specs/032-med-persistence/data-model.md) — entity/table reference
- [`../../constitution.md`](../../constitution.md) — §2.1 (domain purity), §4.2.1 (drift as system of record)
