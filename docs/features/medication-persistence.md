# Medication Persistence

## Overview

Feature `032-med-persistence` gives the `meds` module its first `domain/` and `data/` layers and introduces the app's local SQLite database. Tapping **Save** in the add-medication modal now validates the form, writes a `Medication` aggregate (with all its time slots) to a drift database in a single transaction, pops the modal, and shows a localized SnackBar — or stays open and shows an error if validation fails.

This is the first full Clean-Architecture vertical slice for medication data: pure-Dart domain, drift-backed data layer, and `@riverpod`-wired composition seam. It mirrors the existing `settings` slice.

## Save Flow (Add — end to end)

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

## Update / Edit Flow (end to end)

Added in feature `036-meds-edit`. Tapping a medication tile pre-fills the same modal in edit mode; saving runs the update path through all three layers.

```
AddMedicationModal(initial: medication)
  └─ ref.read(editMedicationProvider)   ← composition seam
        └─ EditMedication (use case)
              ├─ validate              → Left(ValidationFailure)  on error
              │   (same 4 rules as AddMedication)
              ├─ reconcile slot IDs    → reuse original TimeSlotId where
              │   minuteOfDay matches; mint new TimeSlotId otherwise
              ├─ original.copyWith(...)  preserving id + createdAt
              └─ MedicationRepository.update(updated)
                    └─ MedicationRepositoryImpl
                          └─ MedicationLocalDataSource.upsertMedication(...)
                                └─ AppDatabase.transaction()
                                      ├─ medications.insertOnConflictUpdate(row)
                                      ├─ delete timeSlots where medicationId == id
                                      │     AND id NOT IN incomingSlotIds
                                      └─ timeSlots.insertOnConflictUpdate(slot)
                                            (for each incoming slot)
```

On `Right(medication)` the modal pops and shows `medsEditSaveSuccess` ("Medication updated"). On `Left(failure)` the modal applies the same field-mapped error logic as add mode. The Save button is disabled while the update is in flight.

### Load-bearing decisions

**`insertOnConflictUpdate` not `insertOrReplace`**

The `TimeSlots` table has an `onDelete: cascade` foreign key to `Medications`. A plain `insertOrReplace` (or `InsertMode.insertOrReplace`) works by deleting the conflicting row and inserting a new one. That delete fires the cascade, which **wipes all time-slot rows** for the medication before the new slot rows are written. Using `insertOnConflictUpdate` instead performs an SQL `UPDATE` on the existing row, which does not trigger the cascade. This is the sole reason `upsertMedication` must not use `insertOrReplace`.

**Slot-ID preservation**

The `EditMedication` use case decides which `TimeSlotId`s survive. Before calling the repository it builds a lookup map from the original aggregate's slots (`minuteOfDay → TimeSlot`). For each minute in the edited set:

- If the minute existed in the original, the **entire original `TimeSlot` is reused verbatim** — its `TimeSlotId` and any `doseOverride` are preserved unchanged.
- If the minute is new, a fresh `TimeSlotId` is minted via the injected `IdGenerator`.
- Minutes absent from the edited set are deleted by the data source (`id NOT IN incomingSlotIds`).

The data source receives a fully-assembled companion list and simply persists it; slot-ID decisions never leak into the data layer.

**Empty-slots guard**

`upsertMedication` throws an `ArgumentError` if `slots` is empty, before the transaction opens. This guards against a SQLite footgun: the delete step filters with `id NOT IN (...)`, and an empty id list would compile to `NOT IN ()`, which SQLite treats as matching every row — silently deleting every time slot for the medication. `EditMedication` already rejects an empty `intakeMinutes` list during validation (`field: 'times'`), so in practice the data source never receives an empty list from the app; the guard exists as a defensive boundary check rather than a reachable runtime path.

**Fields that round-trip unchanged**

The edit form does not collect `notes` or a continuous `startDate`; these are forwarded from `original` via `copyWith` and are not altered. A continuous medication's `startDate` round-trips byte-for-byte. The `original.id` and `original.createdAt` are never regenerated — they survive every edit.

## Delete Flow (end to end)

Added in feature `037-meds-delete`. Tapping the trash icon in edit mode (see [meds.md](meds.md#delete-feature-037)) removes the medication and, via the database's cascade FK, its time slots.

```
AddMedicationModal(initial: medication)
  └─ _confirmDelete()                      ← showDialog<bool> AlertDialog
  └─ ref.read(deleteMedicationProvider)    ← composition seam
        └─ DeleteMedication (use case)
              └─ MedicationRepository.delete(medication.id)
                    └─ MedicationRepositoryImpl
                          └─ MedicationLocalDataSource.deleteMedication(id)
                                └─ (delete(medications)..where((m) => m.id.equals(id))).go()
                                      — time_slots cascade-removed via the
                                        onDelete: cascade FK, no manual delete
```

On `Right(null)` the modal pops and shows `medsDeleteSuccess` ("Medication deleted"). On `Left(failure)` an error SnackBar (`medsDeleteError`) is shown and the modal stays open. Cancelling the confirmation dialog (or dismissing it) is a no-op — no provider call is made.

### Load-bearing decisions

**`Either<Failure, void>`, not `Unit`**

Unlike `add`/`update` (which return the stored `Medication`), delete has nothing meaningful to return. The contract is `Future<Either<Failure, void>> delete(MedicationId id)`, returning `const Right(null)` on success — matching the settings-layer convention (`SettingsRepository.save*`) rather than introducing fpdart's `Unit`.

**Idempotent success**

Deleting an id that does not exist affects 0 rows and is **not** an error — `deleteMedication` returns normally, and the repository returns `Right(null)`. The end state (row absent) matches intent; only a thrown data-source exception (a real DB error) becomes `Left(Failure.unknown(e, st))`.

**No manual slot cleanup**

Unlike `upsertMedication` (the edit path), which must reconcile surviving/removed slot ids and guard against the `NOT IN ()` empty-list footgun (see above), `deleteMedication` issues a single statement — `(delete(medications)..where((m) => m.id.equals(id))).go()` — and relies entirely on the existing `onDelete: cascade` foreign key (enforced by `pragma foreign_keys = ON`, set in `beforeOpen`) to remove the medication's `time_slots` rows. No transaction wrapper is needed for a single statement.

**`DeleteMedication` performs no validation**

Unlike `AddMedication`/`EditMedication`, `DeleteMedication` is a thin pass-through with no validation rules — there is nothing to validate before removing a row by id:

```dart
class DeleteMedication {
  const DeleteMedication(this._repository);

  final MedicationRepository _repository;

  Future<Either<Failure, void>> call(MedicationId id) =>
      _repository.delete(id);
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

Validation lives in the use cases — `AddMedication` for the add path and `EditMedication` for the edit path. The repository is never called on invalid input. Both use cases enforce identical rules:

| Rule | Returns |
|------|---------|
| `name.trim().isEmpty` | `Left(Failure.validation(field: 'name', ...))` |
| `intakeMinutes.isEmpty` | `Left(Failure.validation(field: 'times', ...))` |
| `type is CourseType && durationDays < 1` | `Left(Failure.validation(field: 'durationDays', ...))` |
| `dosePerIntake != null && amount <= 0` | `Left(Failure.validation(field: 'dose', ...))` |
| all valid | delegates to `MedicationRepository.add` and returns its result unchanged |

## Database Schema

### AppDatabase

`lib/core/database/database.dart` — `@DriftDatabase(tables: [Medications, TimeSlots, Intakes])`. The `Intakes` table (feature 038) was added by the project's first migration; see [Intakes table](#intakes-table-feature-038) and [Schema migration: v1 → v2](#schema-migration-v1--v2-feature-038) below.

- `schemaVersion = 2`
- `MigrationStrategy.onCreate` → `createAll()` (fresh installs get all three tables)
- `MigrationStrategy.onUpgrade` → add-only `if (from < 2) { await m.createTable(intakes); }`
- `beforeOpen` → `pragma foreign_keys = ON;` (enforces the cascade delete on TimeSlots and on Intakes)

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

### Intakes table (feature 038)

`@DataClassName('IntakeRow')`. Added in feature `038-today-intake-log`, one row per **user-confirmed** dose occurrence (see [`meds.md`](meds.md#today-screen--intake-logging-feature-038) for the lazy-materialization model this table backs).

| Column | Drift type | Nullable | Notes |
|--------|-----------|----------|-------|
| `id` | `text()` | no | PK; domain `IntakeId` value |
| `medicationId` | `text().references(Medications, #id, onDelete: KeyAction.cascade)` | no | FK → `Medications.id`, cascades on delete — intakes never outlive their medication |
| `slotId` | `text()` | no | **No FK** — plain text. An FK cascade here would wipe intake history the moment a slot is reconciled away by an edit (see [Slot-ID preservation](#update--edit-flow-end-to-end) above); keeping it a plain column decouples intake history from slot reconciliation |
| `scheduledAt` | `dateTime()` | no | UTC instant of the scheduled dose |
| `confirmedAt` | `dateTime().nullable()` | yes | UTC; set when the user marks taken/skipped, `null` until then |
| `status` | `textEnum<IntakeStatus>()` | no | stored by enum name; this slice only ever writes `taken` or `skipped` — `pending` is derived, `missed` is reserved and unused |
| `notes` | `text().nullable()` | yes | unused this slice, always `null` |

**Uniqueness / upsert**: a `UNIQUE` index on `(medicationId, slotId, scheduledAt)` identifies one dose occurrence. `IntakeLocalDataSource.upsertIntake` targets this index (not the primary key) in its `onConflict: DoUpdate(...)` — each confirmation mints a fresh `id`, so a PK-targeted upsert would never collide and would insert a duplicate row per re-mark. Targeting the occurrence index means re-marking the same occurrence (e.g. taken → skipped) resolves to an SQL `UPDATE` in place. This is the AC-6 idempotency guarantee: one occurrence is ever represented by at most one row.

### Schema migration: v1 → v2 (feature 038)

This is the project's **first drift schema migration** — every table before it was created fresh via `onCreate`. The migration is deliberately **add-only**:

```dart
// lib/core/database/database.dart
@override
int get schemaVersion => 2;

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) => m.createAll(),
  onUpgrade: (Migrator m, int from, int to) async {
    // v1→v2: add-only. Create the new intakes table; alter nothing else.
    if (from < 2) {
      await m.createTable(intakes);
    }
  },
  beforeOpen: (details) async {
    await customStatement('pragma foreign_keys = ON;');
  },
);
```

It creates the new `intakes` table and touches **no** existing column, table, or enum on `medications`/`time_slots`. `onCreate` (fresh installs) is unchanged — it now includes `Intakes` because the table is registered in `@DriftDatabase(tables: [...])`.

**Migration test convention** (`test/core/database/migration_test.dart`): uses drift's `SchemaVerifier`, fed by a generated schema snapshot (`dart run drift_dev schema dump` → `drift_schemas/drift_schema_v1.json`, then `dart run drift_dev schema generate` → the `test/core/database/schema/` helper). Three tests establish the pattern future migrations should follow:

1. **`upgrade v1 to v2 validates`** — boots a v1-shaped database, opens it as `AppDatabase` (triggering the real `onUpgrade`), and calls `db.validateDatabaseSchema()` to prove the migrated result is structurally identical to a fresh `createAll()` of the currently-declared (v2) tables.
2. **`v1 data survives the upgrade`** — seeds a v1-shaped database directly through the generated v1 companion classes, reopens it as `AppDatabase` on an independent connection to the same underlying database (triggering the upgrade), and reads the medication/time-slot rows back through the real v2 schema to prove no existing column or row was altered.
3. **`fresh install has all three tables`** — a brand-new `AppDatabase(NativeDatabase.memory())` takes the `onCreate` path (not `onUpgrade`) and must expose `medications`, `time_slots`, and `intakes`.

Any future schema change should add an equivalent snapshot + `SchemaVerifier` test pair rather than hand-writing migration assertions.

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

@riverpod
EditMedication editMedication(Ref ref) => EditMedication(
  ref.watch(medicationRepositoryProvider),
  ref.watch(idGeneratorProvider),
);

@riverpod
DeleteMedication deleteMedication(Ref ref) =>
    DeleteMedication(ref.watch(medicationRepositoryProvider));
```

All five providers are plain `@riverpod` (autoDispose) function providers. Save/Delete are one-shot imperative calls from the modal (`ref.read(addMedicationProvider)`, `ref.read(editMedicationProvider)`, or `ref.read(deleteMedicationProvider)`), not a notifier — there is no shared observed state to hold between calls.

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

## Localization Keys (feature 036)

Two new keys added to `app_en.arb`, `app_de.arb`, and `app_uk.arb` for the edit flow:

| Key | English |
|-----|---------|
| `medsEditTitle` | Edit medication |
| `medsEditSaveSuccess` | Medication updated |

Both keys have `@`-description metadata in `app_en.arb`.

## Localization Keys (feature 037)

Seven new keys added to `app_en.arb`, `app_de.arb`, and `app_uk.arb` for the delete flow:

| Key | English |
|-----|---------|
| `medsDeleteButtonTooltip` | Delete medication |
| `medsDeleteDialogTitle` | Delete medication? |
| `medsDeleteDialogBody` | Delete "{name}"? This can't be undone. |
| `medsDeleteDialogConfirm` | Delete |
| `medsDeleteDialogCancel` | Cancel |
| `medsDeleteSuccess` | Medication deleted |
| `medsDeleteError` | Couldn't delete medication. Please try again. |

All seven keys have `@`-description metadata in `app_en.arb`.

## Tests

- `test/features/meds/domain/usecases/add_medication_test.dart` — 5 unit tests: happy path, name-empty, no-times, course-duration-zero, repository-failure passthrough. Uses a `mocktail` mock for `MedicationRepository` and a fixed `Clock`.
- `test/features/meds/domain/usecases/edit_medication_test.dart` — (feature 036) id/createdAt preservation on update, slot-ID reconciliation (unchanged minutes keep their id, new minutes mint one), each of the 4 validation branches, and repository-failure passthrough.
- `test/features/meds/domain/usecases/delete_medication_test.dart` — (feature 037) `DeleteMedication` forwards `id` to `MedicationRepository.delete` unchanged and propagates both the `Right` and `Left` results verbatim.
- `test/features/meds/data/datasources/medication_local_data_source_delete_test.dart` — (feature 037) in-memory drift test: inserts a medication with ≥1 time slot, deletes it, and asserts both the medication row and its slot rows are gone (cascade proof); deleting an absent id is a no-throw no-op.
- `test/features/meds/data/repositories/medication_repository_impl_test.dart` — in-memory drift round-trip and failure path for `add()` and `watchAll()`; a `MedicationRepositoryImpl.update()` group (feature 036) covers in-place row update, preserved/added/removed slot IDs, and the failure path; a `MedicationRepositoryImpl.delete()` group (feature 037) covers success → `Right(null)` and data-source throw → `Left(Failure.unknown)`.
- `test/features/meds/data/mappers/medication_mapper_test.dart` — 45 tests covering every nullable field combination and the full domain→companion→row→domain round-trip.
- `test/features/meds/presentation/widgets/add_medication_modal_test.dart` — rewritten: valid input invokes the use case and pops; invalid input shows the error SnackBar and does not pop. The earlier "Save is a no-op" assertions are removed. An `AddMedicationModal edit mode (spec 036)` group covers pre-fill and update-routing. An `AddMedicationModal delete (spec 037)` group covers: trash shown in edit mode / absent in add mode; tap opens the confirmation dialog naming the medication; Cancel is a no-op; Delete invokes `deleteMedicationProvider` and, on `Right`, pops with a success SnackBar, or on `Left`, shows an error SnackBar and stays open.
- `test/features/meds/presentation/widgets/medication_tile_test.dart` — a `MedicationTile onTap (spec 036)` group covers tap-triggers-callback and the unchanged non-interactive default when `onTap` is `null`.

## What This Feature Does NOT Include

- Reading / listing saved medications (`getAll` / `watch`) — body of `MedsScreen` remains `SizedBox.shrink()`. A future "meds list" spec adds the reactive query, empty state, and the FK index on `TimeSlots.medicationId`.
- Editing a medication beyond `add` — see [feature 036](#update--edit-flow-end-to-end) which added the full edit path.
- Deleting a medication — see [feature 037](#delete-flow-end-to-end) which added the full delete path.
- Notifications or reminder scheduling.
- Adherence calculation / the History screen. (`Intakes` records and the taken/skipped intake state machine were added in feature 038 — see [Intakes table](#intakes-table-feature-038) above and [`meds.md`](meds.md#today-screen--intake-logging-feature-038); adherence aggregation is still deferred.)
- Schedule frequencies other than `daily`.
- Pack-stock decrement on intake or low-stock warnings.
- Schema migrations beyond v2. (v1→v2, adding `Intakes`, shipped in feature 038 — see [Schema migration: v1 → v2](#schema-migration-v1--v2-feature-038) above.)
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

**Adding an update path (already implemented — see feature 036)**

The update path now exists as `MedicationRepository.update`, `EditMedication`, `editMedicationProvider`, and `MedicationLocalDataSource.upsertMedication`. See the [Update / Edit Flow](#update--edit-flow-end-to-end) section above for the full walkthrough.

**Adding a delete path (already implemented — see feature 037)**

The delete path now exists as `MedicationRepository.delete`, `DeleteMedication`, `deleteMedicationProvider`, and `MedicationLocalDataSource.deleteMedication`. See the [Delete Flow](#delete-flow-end-to-end) section above for the full walkthrough.

**Schema changes**

Always bump `AppDatabase.schemaVersion` and add a migration to `MigrationStrategy.onUpgrade`. Never rename a stored enum value without a migration.

## Related

- [`meds.md`](meds.md) — the add/edit modal's visual history (features 026–031, 036), screen structure, tile tap wiring, and localization keys
- [`../architecture.md`](../architecture.md) — Clean Architecture layering, Riverpod patterns, `Either<Failure,T>`, and the new database section
- [`../../specs/032-med-persistence/spec.md`](../../specs/032-med-persistence/spec.md) — the full add spec with all acceptance criteria
- [`../../specs/032-med-persistence/data-model.md`](../../specs/032-med-persistence/data-model.md) — entity/table reference
- [`../../specs/036-meds-edit/spec.md`](../../specs/036-meds-edit/spec.md) — the edit spec: tap-to-edit, slot reconciliation, upsert constraints
- [`../../specs/037-meds-delete/spec.md`](../../specs/037-meds-delete/spec.md) — the delete spec: confirmation dialog, single-statement delete, cascade FK reliance, idempotent-success semantics
- [`../../specs/038-today-intake-log/spec.md`](../../specs/038-today-intake-log/spec.md) — the Today-screen spec: `Intakes` table, the first schema migration, and the lazy intake model
- [`../../constitution.md`](../../constitution.md) — §2.1 (domain purity), §4.2.1 (drift as system of record)
