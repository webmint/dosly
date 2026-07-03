# Task 004: Intakes drift table

**Agent**: architect
**Files**: `lib/core/database/tables/intakes_table.dart`
**Depends on**: 002
**Blocks**: 005
**Context docs**: specs/038-today-intake-log/data-model.md
**Review checkpoint**: No

**Description**:
Define the new `Intakes` drift table storing user-confirmed intake events, mirroring the style/contract docs of `medications_table.dart` and `time_slots_table.dart`. Add the occurrence-uniqueness index so a dose can have at most one row. Do NOT register it in `AppDatabase` yet (Task 005).

**Change details**:
- `intakes_table.dart` (`@DataClassName('IntakeRow')`):
  - `TextColumn get id => text()();` primary key.
  - `TextColumn get medicationId => text().references(Medications, #id, onDelete: KeyAction.cascade)();`
  - `TextColumn get slotId => text()();` (plain text — NO foreign key, so slot reconciliation on edit never cascade-deletes intake history; document this).
  - `DateTimeColumn get scheduledAt => dateTime()();` (UTC).
  - `DateTimeColumn get confirmedAt => dateTime().nullable()();` (UTC).
  - `TextColumn get status => textEnum<IntakeStatus>()();`
  - `TextColumn get notes => text().nullable()();`
  - `Set<Column> get primaryKey => {id};`
  - Add `List<Set<Column>> get uniqueKeys => [ {medicationId, slotId, scheduledAt} ];` (drift emits a UNIQUE constraint for the occurrence key).
  - Include the health-data COLUMN CONTRACT + textEnum STORAGE CONTRACT library dartdoc (copy the pattern from the sibling tables).
- Import `IntakeStatus` from the domain (pure enum — importing it into a table def does not pull Flutter/drift into the domain, same as `MedicationForm`).

**Contracts**:

### Expects
- `IntakeStatus` enum exists (Task 002).
- `Medications` table exists in `lib/core/database/tables/medications_table.dart`.

### Produces
- `intakes_table.dart` declares `class Intakes extends Table` with `@DataClassName('IntakeRow')` and columns `id, medicationId, slotId, scheduledAt, confirmedAt, status, notes`.
- `intakes_table.dart` declares `uniqueKeys` containing `{medicationId, slotId, scheduledAt}`.
- `medicationId` uses `.references(Medications, #id, onDelete: KeyAction.cascade)`.

**Done when**:
- [ ] `Intakes` table + `uniqueKeys` declared per data-model.md.
- [ ] Contract dartdoc present.
- [ ] `dart analyze` passes (note: `IntakeRow` is not generated until Task 005 registers the table — analyzer may warn only where consumed, not here).

**Spec criteria addressed**: AC-5, AC-6

## Completion Notes
**Status**: Complete
**Completed**: 2026-07-02
**Files changed**: `lib/core/database/tables/intakes_table.dart`
**Contract**: Expects [2/2] | Produces [3/3] — `Intakes`/`IntakeRow`, `uniqueKeys {medicationId, slotId, scheduledAt}`, `medicationId` FK cascade; `slotId` intentionally plain text.
**Notes**: Table NOT yet registered (Task 005 registers + regenerates `IntakeRow`); build_runner not run here. `dart analyze` clean on the file. Sibling tables + `database.dart` untouched.
