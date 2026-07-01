# Task 001: Add transactional upsert to the medication data source

**Agent**: architect
**Files**: `lib/features/meds/data/datasources/medication_local_data_source.dart`
**Depends on**: None
**Blocks**: 002
**Context docs**: `docs/features/medication-persistence.md`
**Review checkpoint**: Yes

**Description**:
Add `upsertMedication` to `MedicationLocalDataSource` — the in-place update + slot-reconciliation write path, the data-layer half of the new medication-edit feature. It must update the medication row **in place** (never delete+reinsert) so the `onDelete: cascade` FK does not wipe the medication's time slots, and it must reconcile slots: delete the rows whose ids are absent from the incoming set, then upsert the rest (preserving unchanged-id rows in place, inserting new ids). This is the highest-risk task in the feature — the `insertOnConflictUpdate` vs `insertOrReplace` choice is load-bearing.

**Change details**:
- In `lib/features/meds/data/datasources/medication_local_data_source.dart`:
  - Add `Future<void> upsertMedication(MedicationsCompanion medication, List<TimeSlotsCompanion> slots)`.
  - Body wraps everything in a single `_db.transaction(() async { ... })`:
    1. `await _db.into(_db.medications).insertOnConflictUpdate(medication);` — **MUST be `insertOnConflictUpdate`, NOT `insertOrReplace`/`InsertMode.insertOrReplace`** (a REPLACE deletes+reinserts the parent row, cascade-deleting all of its time slots via the FK; an upsert performs an UPDATE and does not trigger the cascade — see `plan.md` Key Design Decisions and `medication-persistence.md` cascade note).
    2. Compute `final ids = <String>[for (final s in slots) s.id.value];` and `final medId = medication.id.value;` (the mapper always populates these companion PKs via `.insert`, so `.value` is safe — no `!`).
    3. `await (_db.delete(_db.timeSlots)..where((t) => t.medicationId.equals(medId) & t.id.isNotIn(ids))).go();` — drop removed slots only.
    4. `for (final slot in slots) { await _db.into(_db.timeSlots).insertOnConflictUpdate(slot); }` — preserved ids update in place, new ids insert.
  - Add a dartdoc `///` block describing the in-place semantics and why `insertOnConflictUpdate` is required (cascade safety). Note that callers (the repository) guarantee `slots` is non-empty, so `isNotIn(ids)` never receives an empty list.

**Status**: Complete

**Done when**:
- [x] `upsertMedication(MedicationsCompanion, List<TimeSlotsCompanion>)` exists on `MedicationLocalDataSource`.
- [x] The method uses `insertOnConflictUpdate` for both tables and does NOT contain the strings `insertOrReplace` or `InsertMode.insertOrReplace`.
- [x] Removed slots are deleted via a `delete(_db.timeSlots)` constrained by `medicationId` AND `id.isNotIn(...)`.
- [x] No `!`, no unchecked `as`; dartdoc present.
- [x] `dart analyze` passes on the changed file.

## Completion Notes
**Completed**: 2026-06-19
**Files changed**: `lib/features/meds/data/datasources/medication_local_data_source.dart`
**Contract**: Expects [2/2 verified] | Produces [3/3 verified]
**Notes**: `insertOnConflictUpdate` for both tables (cascade-safe); removed-slot delete scoped by `medicationId & id.isNotIn(ids)`; all in one transaction. Code review (checkpoint) = APPROVE WITH WARNINGS → added an `if (slots.isEmpty) throw ArgumentError` boundary guard to close the `NOT IN ()` data-loss footgun (empty list would match every row). 61 data-layer tests pass; analyze clean.

## Contracts

### Expects
- `medication_local_data_source.dart` declares `class MedicationLocalDataSource` with `insertMedication(MedicationsCompanion, List<TimeSlotsCompanion>)` and a `final AppDatabase _db`.
- `AppDatabase` exposes `medications`, `timeSlots`, `transaction(...)`, `into(...)`, and `delete(...)`; `TimeSlots` has columns `medicationId` and `id`.

### Produces
- `medication_local_data_source.dart` declares `Future<void> upsertMedication(MedicationsCompanion medication, List<TimeSlotsCompanion> slots)`.
- The `upsertMedication` body contains the literal `insertOnConflictUpdate` and does NOT contain `insertOrReplace`.
- The `upsertMedication` body contains a `delete(` on `_db.timeSlots` using `isNotIn(`.

**Spec criteria addressed**: AC-8, AC-9
