# Task 004: Reactive read data tests (in-memory drift)

**Agent**: qa-engineer
**Files**: `test/features/meds/data/datasources/medication_local_data_source_watch_test.dart` (new), `test/features/meds/data/repositories/medication_repository_impl_test.dart` (modify)
**Depends on**: 003
**Blocks**: None
**Context docs**: `specs/034-meds-list/data-model.md`
**Review checkpoint**: No

**Description**:
Prove the reactive read works against a real in-memory drift database: correct slot grouping, re-emission on changes to **both** tables, slot-less meds preserved, and the repository's `Right`/`Left` mapping. This is where AC-19 (a new med appears without manual refresh) is verified at the reactive boundary.

**Change details**:
- `..._watch_test.dart` (data source, `AppDatabase(NativeDatabase.memory())`):
  - insert one med with 2 slots + one med with 0 slots → first emission groups slots correctly and includes the slot-less med with an empty slot list.
  - insert a new medication → stream re-emits with the added med (**AC-19**: reactive on insert).
  - insert/delete a *time slot* only → stream re-emits (proves the join watches `timeSlots` too).
  - delete a medication → cascade removes its slots; stream re-emits without it.
- `medication_repository_impl_test.dart` (extend existing): `watchAll()` over an in-memory DB emits `Right(list)` with fully-mapped `Medication`s (slots/dose/stock/type intact); a forced data-source/mapping error surfaces as `Left(Failure)` (e.g. via a throwing fake data source).

**Done when**:
- [x] Data-source test asserts grouping + re-emission on medication insert/delete AND on slot-only change.
- [x] Repo test asserts `watchAll()` emits `Right` with correct entities and `Left(Failure)` on error.
- [x] `flutter test test/features/meds/data/` is green; `dart analyze` clean.

**Spec criteria addressed**: AC-1, AC-3, AC-19

## Completion Notes
**Status**: Complete
**Completed**: 2026-06-18
**Files changed**: medication_local_data_source_watch_test.dart (new, 9 tests), medication_repository_impl_test.dart (+6 watchAll tests)
**Contract**: Expects 2/2 verified | Produces 2/2 verified
**Notes**: 61/61 in `test/features/meds/data/` green; analyze clean; no production bugs. AC-19 (reactive add) verified at the data-source + repo levels. Technique: `DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true)` makes drift notify listeners synchronously after a write, so `await stream.first` after `await db.write()` is deterministic — no `Future.delayed`. Error path uses an `_ErroringDataSource` subclass returning `Stream.error(...)`.

## Contracts

### Expects
- Task 003 `Produces` (`watchAllMedications()`, `watchAll()`).
- `AppDatabase` accepts an injected executor (`AppDatabase([QueryExecutor? executor])`) for an in-memory backend.

### Produces
- `medication_local_data_source_watch_test.dart` builds `AppDatabase(NativeDatabase.memory())`, listens to `watchAllMedications()`, and asserts re-emission after a slot-only mutation.
- `medication_repository_impl_test.dart` asserts `watchAll()` emits `Right(` and `Left(` cases.
