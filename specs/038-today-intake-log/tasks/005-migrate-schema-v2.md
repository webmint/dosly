# Task 005: Migrate schema to v2 (register Intakes + onUpgrade)

**Agent**: architect
**Files**: `lib/core/database/database.dart` (+ regenerated `database.g.dart`)
**Depends on**: 001, 004
**Blocks**: 006, 008, 009
**Context docs**: specs/038-today-intake-log/data-model.md, docs/architecture.md
**Review checkpoint**: Yes

**Description**:
Wire the new `Intakes` table into `AppDatabase` and add the project's FIRST schema migration (1 → 2). This is the highest-risk task: it touches the health-data system of record. The migration is **add-only** — it must never alter or drop `medications`/`time_slots`. Regenerate drift code.

**Change details**:
- In `lib/core/database/database.dart`:
  - Add `import 'tables/intakes_table.dart';`.
  - Change `@DriftDatabase(tables: [Medications, TimeSlots])` → `@DriftDatabase(tables: [Medications, TimeSlots, Intakes])`.
  - Change `int get schemaVersion => 1;` → `=> 2;`.
  - In `MigrationStrategy`, keep `onCreate: (m) => m.createAll()` and the `beforeOpen` FK pragma unchanged; add:
    ```dart
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(intakes);
      }
    },
    ```
  - Update the class/library dartdoc to mention the `Intakes` table and `schemaVersion=2`.
- Run build_runner to regenerate `database.g.dart` (produces `IntakeRow`, `IntakesCompanion`, `db.intakes`).

**Contracts**:

### Expects
- `drift_schemas/drift_schema_v1.json` exists (Task 001).
- `Intakes` table declared (Task 004).

### Produces
- `database.dart` declares `int get schemaVersion => 2` and `@DriftDatabase(tables: [Medications, TimeSlots, Intakes])`.
- `database.dart` `MigrationStrategy` contains `onUpgrade` calling `m.createTable(intakes)` guarded by `if (from < 2)`, and still sets `pragma foreign_keys = ON` in `beforeOpen` and `m.createAll()` in `onCreate`.
- `database.g.dart` generates `IntakeRow`, `IntakesCompanion`, and a `$IntakesTable intakes` accessor.
- No change to the `medications`/`time_slots` column definitions.

**Done when**:
- [ ] `schemaVersion == 2`, `Intakes` registered, `onUpgrade` add-only.
- [ ] build_runner regenerates without errors; `IntakeRow`/`IntakesCompanion` exist.
- [ ] `onCreate`/`beforeOpen` behavior preserved.
- [ ] `dart analyze` passes on changed files.

**Spec criteria addressed**: AC-5

## Completion Notes
**Status**: Complete
**Completed**: 2026-07-02
**Files changed**: `lib/core/database/database.dart`, `lib/core/database/database.g.dart` (regenerated). Side-effect: `lib/features/meds/domain/entities/intake.freezed.dart` re-emitted by build_runner (harmless — IntakeId now resolves in-graph; no public API change, analyze clean).
**Contract**: Expects [2/2] | Produces [4/4] — `schemaVersion => 2`, `Intakes` registered, add-only `onUpgrade` (`if (from < 2) createTable(intakes)`), `IntakeRow`/`IntakesCompanion`/`intakes` generated; `onCreate`/`beforeOpen` byte-identical.
**Notes**: Added a required `intake_status.dart` import into `database.dart` (mirrors existing `DoseUnit`/`MedicationForm` textEnum import pattern — not scope creep). **Code review: APPROVE WITH WARNINGS** (no Critical). Warnings: (1) `intake.freezed.dart` regen side-effect [harmless]; (2) constitution §6.6 names a `migrations/` dir convention never followed here — inline `MigrationStrategy` is idiomatic drift + satisfies §4.2.1 → reconcile §6.6 at /finalize. Migration safety (v1 data survival) proven in Task 006.
