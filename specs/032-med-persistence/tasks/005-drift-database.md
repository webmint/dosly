# Task 005: drift database — tables, AppDatabase, provider

**Agent**: architect
**Files**: `lib/core/database/tables/medications_table.dart`, `lib/core/database/tables/time_slots_table.dart`, `lib/core/database/database.dart`, `lib/core/database/database_provider.dart`
**Depends on**: 001, 002
**Blocks**: 008, 009, 013
**Context docs**: `specs/032-med-persistence/data-model.md`, `specs/032-med-persistence/research.md`
**Review checkpoint**: Yes — first database in the codebase; combined drift codegen; `textEnum` values become a stored contract

**Description**:
Create the app's first local drift database: two tables, the `AppDatabase` class (with an optional-executor constructor so tests can inject an in-memory DB), and a kept-alive Riverpod provider. Tables use `textEnum` over the domain enums from task 002 and `@DataClassName` to avoid colliding with the domain `Medication` entity.

**Change details**:
- `tables/medications_table.dart`: `class Medications extends Table` annotated `@DataClassName('MedicationRow')`. Columns per data-model.md: `id` text PK; `name` text; `form` `textEnum<MedicationForm>()`; `doseAmount` real nullable; `doseUnit` `textEnum<DoseUnit>()` nullable; `typeKind` `textEnum<MedicationTypeKind>()`; `frequency` `textEnum<ScheduleFrequency>()` with `.withDefault(...)` or handled in mapper; `startDate` dateTime; `durationDays`/`pauseDays` int nullable; `stockRemaining`/`stockTotal`/`stockWarnAt` int nullable; `notes` text nullable; `createdAt` dateTime; `primaryKey => {id}`. Define `enum MedicationTypeKind { continuous, course }` here (storage discriminator).
- `tables/time_slots_table.dart`: `class TimeSlots extends Table` annotated `@DataClassName('TimeSlotRow')`. Columns: `id` text PK; `medicationId` `text().references(Medications, #id, onDelete: KeyAction.cascade)`; `minuteOfDay` int; `doseAmount` real nullable; `doseUnit` `textEnum<DoseUnit>()` nullable; `primaryKey => {id}`.
- `database.dart`: `@DriftDatabase(tables: [Medications, TimeSlots]) class AppDatabase extends _$AppDatabase`. Constructor `AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection())`; `_openConnection()` uses `drift_flutter`'s `driftDatabase(name: 'dosly')`. `int get schemaVersion => 1`. `MigrationStrategy` with `onCreate: (m) => m.createAll()` and `beforeOpen: (d) async { await customStatement('pragma foreign_keys = ON;'); }`.
- `database_provider.dart`: `@Riverpod(keepAlive: true) AppDatabase appDatabase(Ref ref) { final db = AppDatabase(); ref.onDispose(db.close); return db; }`. Mirror `lib/core/providers/shared_preferences_provider.dart` style; `part 'database_provider.g.dart'`.
- Run `dart run build_runner build --delete-conflicting-outputs` (drift + riverpod codegen).

**Done when**:
- [ ] `Medications`/`TimeSlots` tables exist with the columns above and `@DataClassName('MedicationRow')`/`@DataClassName('TimeSlotRow')`
- [ ] `AppDatabase` has `schemaVersion == 1`, an optional-`QueryExecutor` constructor, and a `MigrationStrategy` enabling `pragma foreign_keys = ON` in `beforeOpen`
- [ ] `appDatabaseProvider` is `@Riverpod(keepAlive: true)` and disposes via `ref.onDispose`
- [ ] generated drift/riverpod files committed; `dart analyze` passes

## Contracts
### Expects
- `drift`, `drift_flutter`, `sqlite3_flutter_libs` present (task 001)
- `MedicationForm`, `DoseUnit`, `ScheduleFrequency` enums exist (task 002)
### Produces
- `database.dart` exports `AppDatabase` (`@DriftDatabase`), `schemaVersion` getter returning `1`, constructor accepting optional `QueryExecutor`
- `tables/medications_table.dart` exports `class Medications` (`@DataClassName('MedicationRow')`) and `enum MedicationTypeKind { continuous, course }`
- `tables/time_slots_table.dart` exports `class TimeSlots` (`@DataClassName('TimeSlotRow')`) with `medicationId` referencing `Medications` `onDelete: KeyAction.cascade`
- `database_provider.dart` exports `appDatabaseProvider` (`@Riverpod(keepAlive: true)`)

**Spec criteria addressed**: AC-2, AC-3, AC-4, AC-5

## Completion Notes
**Completed**: 2026-06-17
**Status**: Complete
**Files changed**: tables/medications_table.dart, tables/time_slots_table.dart, database.dart, database_provider.dart (+ database.g.dart, database_provider.g.dart)
**Contract**: Expects 2/2 | Produces 4/4
**Code review**: APPROVE (no Critical/Warning; schema matches data-model.md column-for-column; `EnumNameConverter` confirms textEnum stores by name; FK emits `ON DELETE CASCADE`; provider `isAutoDispose:false`)
**Notes**: Generated row classes `MedicationRow`/`TimeSlotRow`. `frequency` is non-nullable (mapper supplies it; no DB default). Test seam = optional-`QueryExecutor` ctor; tests override with `AppDatabase(NativeDatabase.memory())`. `pragma foreign_keys=ON` in beforeOpen (per-connection).
