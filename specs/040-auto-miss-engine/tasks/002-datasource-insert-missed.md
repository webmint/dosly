# Task 002: Add `insertMissedIntake` (insert-or-ignore) to the data source

**Agent**: architect
**Review checkpoint**: No
**Files**: `lib/features/meds/data/datasources/intake_local_data_source.dart` (modify)
**Depends on**: None
**Blocks**: 003
**Context docs**: None

## Description

Add a narrow write to `IntakeLocalDataSource` that inserts a `missed` intake row **without ever overwriting** an existing occurrence row. Unlike the existing `upsertIntake` (which does `DoUpdate` on the occurrence unique key and would clobber a `taken`/`skipped` row), the new `insertMissedIntake` uses `InsertMode.insertOrIgnore` so a conflict on the `{medicationId, slotId, scheduledAt}` unique index (or the `id` PK) is silently skipped. This is the DB-level never-clobber guarantee for auto-miss (defense-in-depth on top of the use case's eligibility filter). No schema change — the `intakes` table and `IntakeStatus` `textEnum` already store `missed` by name.

## Change details

- In `lib/features/meds/data/datasources/intake_local_data_source.dart`:
  - Add `Future<void> insertMissedIntake(IntakesCompanion companion)` that does `await _db.into(_db.intakes).insert(companion, mode: InsertMode.insertOrIgnore);`.
  - dartdoc: explain it inserts a fresh missed row but IGNORES (does not update) if the occurrence already has a row — the never-clobber contract — and that callers in the repository layer catch any thrown exception into `Left(Failure)`.

## Contracts

### Expects
- `lib/core/database/database.dart` exposes the drift `Intakes` table with the `{medicationId, slotId, scheduledAt}` unique key and an `IntakesCompanion` type (already true — spec 038).
- `IntakeLocalDataSource` already has `upsertIntake(IntakesCompanion)` and `deleteIntake(String)`.

### Produces
- `intake_local_data_source.dart` has method `insertMissedIntake(IntakesCompanion companion)` using `InsertMode.insertOrIgnore`.

## Done when
- [x] `insertMissedIntake` exists and uses `InsertMode.insertOrIgnore` (not `DoUpdate`/`insertOrReplace`).
- [x] No change to `AppDatabase.schemaVersion` (stays 2) and no table/column edit.
- [x] `dart analyze` passes on changed files.

**Spec criteria addressed**: AC-7 (DB never-clobber), AC-9 (no schema change)

## Completion Notes

**Status**: Complete
**Completed**: 2026-07-04
**Files changed**: `lib/features/meds/data/datasources/intake_local_data_source.dart`
**Contract**: Expects [2/2 verified] | Produces [1/1 verified]
**Notes**: Added `insertMissedIntake(IntakesCompanion)` using `InsertMode.insertOrIgnore` (SQLite `INSERT OR IGNORE`) — skips on PK or `{medicationId, slotId, scheduledAt}` unique conflict, so a `missed` insert never overwrites a `taken`/`skipped` row (never-clobber, defense-in-depth). Data source still throws (no `Either`); schema untouched (v2). Code review APPROVE with warnings — new line was >80 cols; `dart format` wrapped it (diff confirmed it touched ONLY the new method, no pre-existing reflow).
