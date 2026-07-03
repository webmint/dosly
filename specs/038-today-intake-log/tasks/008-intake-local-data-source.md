# Task 008: Intake local data source

**Agent**: architect
**Files**: `lib/features/meds/data/datasources/intake_local_data_source.dart`, `test/features/meds/data/datasources/intake_local_data_source_test.dart`
**Depends on**: 005
**Blocks**: 009, 012
**Context docs**: specs/038-today-intake-log/data-model.md
**Review checkpoint**: No

**Description**:
Low-level drift data source for intakes, mirroring `MedicationLocalDataSource` (narrow, exception-throwing API; the repository maps to `Either`). Provides the reactive watch, the idempotent upsert keyed on the occurrence unique index, and delete-by-id.

**Change details**:
- `intake_local_data_source.dart` (`class IntakeLocalDataSource { const IntakeLocalDataSource(this._db); final AppDatabase _db; ... }`):
  - `Stream<List<IntakeRow>> watchAllIntakes()` — `_db.select(_db.intakes).watch()`.
  - `Future<void> upsertIntake(IntakesCompanion companion)` — `_db.into(_db.intakes).insert(companion, onConflict: DoUpdate((_) => companion, target: [_db.intakes.medicationId, _db.intakes.slotId, _db.intakes.scheduledAt]))`, so re-marking the same occurrence UPDATEs `status`/`confirmedAt` instead of inserting a duplicate.
  - `Future<void> deleteIntake(String id)` — `(_db.delete(_db.intakes)..where((t) => t.id.equals(id))).go()` (absent id → 0 rows, no error).
  - Throwing API only; dartdoc notes the repository converts throws to `Left`.
- Tests (in-memory DB): upsert then re-upsert same occurrence → exactly one row with updated status (AC-6 idempotency); delete removes the row; delete-absent is a no-op; `watchAllIntakes` emits on change.

**Contracts**:

### Expects
- `database.g.dart` exposes `db.intakes`, `IntakeRow`, `IntakesCompanion` (Task 005).

### Produces
- `intake_local_data_source.dart` declares `class IntakeLocalDataSource` with `watchAllIntakes()`, `upsertIntake(IntakesCompanion)`, `deleteIntake(String)`.
- `upsertIntake` uses `DoUpdate` with `target: [..medicationId, ..slotId, ..scheduledAt]`.

**Done when**:
- [ ] Upsert is idempotent per occurrence (re-mark updates in place — unit-tested).
- [ ] Delete-by-id works and delete-absent is a no-op.
- [ ] `dart analyze` + `flutter test test/features/meds/data/datasources/intake_local_data_source_test.dart` pass.

**Spec criteria addressed**: AC-6

## Completion Notes
**Status**: Complete
**Completed**: 2026-07-02
**Files changed**: `data/datasources/intake_local_data_source.dart`, `test/features/meds/data/datasources/intake_local_data_source_test.dart`
**Contract**: Expects [ok] | Produces [2/2] — `IntakeLocalDataSource` with 3 methods; `upsertIntake` uses `DoUpdate(target: [medicationId, slotId, scheduledAt])`; no fpdart.
**Notes**: Conflict target is the occurrence unique key (NOT the PK) — fresh ids would never collide on PK, so PK-target would duplicate. 5/5 tests pass incl. AC-6 idempotency. Tests seed a parent medication row (FK enforced via beforeOpen pragma); DateTime asserts via `isAtSameMomentAs` (drift reads back local-flag). `dart analyze` clean.
