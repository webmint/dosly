# Task 002: Data-layer delete — data source method + repo impl

**Agent**: architect
**Status**: Complete
**Files**: `lib/features/meds/data/datasources/medication_local_data_source.dart`, `lib/features/meds/data/repositories/medication_repository_impl.dart`
**Depends on**: 001
**Blocks**: 006
**Context docs**: None
**Review checkpoint**: No

**Description**:
Implement the delete in the data layer. Add a single-statement drift delete to `MedicationLocalDataSource`, then implement `MedicationRepository.delete` in `MedicationRepositoryImpl` by wrapping the data source call with the existing try/catch → `Left(Failure.unknown)` idiom (mirrors `add`/`update`). No transaction and no manual slot cleanup — the `TimeSlots.medicationId onDelete: cascade` FK (with `pragma foreign_keys = ON`, set in `database.dart`'s `beforeOpen`) removes slots automatically. Deleting a non-existent id affects 0 rows and must NOT throw (idempotent success).

**Change details**:
- In `lib/features/meds/data/datasources/medication_local_data_source.dart`:
  - Add `Future<void> deleteMedication(String id)` that runs `await (_db.delete(_db.medications)..where((m) => m.id.equals(id))).go();`.
  - Dartdoc: single-statement delete; the medication's time-slot rows are removed by the FK cascade (no manual delete); returns normally when 0 rows match (idempotent); throws on failure (e.g. `SqliteException`) per this class's throw-on-failure contract — the repository converts to `Left`.
- In `lib/features/meds/data/repositories/medication_repository_impl.dart`:
  - Add the `@override Future<Either<Failure, void>> delete(MedicationId medication...)` implementation: `try { await _dataSource.deleteMedication(id.value); return const Right(null); } catch (e, st) { return Left(Failure.unknown(e, st)); }`.
  - Add `import '../../domain/value_objects/medication_id.dart';` if not already imported.

**Done when**:
- [x] `MedicationLocalDataSource.deleteMedication(String id)` issues a single drift delete on `medications` filtered by `id`.
- [x] `MedicationRepositoryImpl.delete` returns `const Right(null)` on success and `Left(Failure.unknown(e, st))` on a caught exception (no exception escapes).
- [x] No manual `delete(_db.timeSlots)` call is added (cascade handles slots).
- [x] `dart analyze` passes on both files.

**Spec criteria addressed**: AC-3, AC-4, AC-5

## Completion Notes

**Completed**: 2026-07-01
**Files changed**: `medication_local_data_source.dart` (+`deleteMedication`), `medication_repository_impl.dart` (+`delete` override, +`MedicationId` import)
**Contract**: Expects [4/4 verified] | Produces [3/3 verified]
**Code review**: APPROVE (no issues; reviewer confirmed cascade FK `KeyAction.cascade` at `time_slots_table.dart:39` + `pragma foreign_keys = ON`)
**Notes**: Single scoped delete (`..where((m) => m.id.equals(id))`), no transaction, no manual slot delete — cascade FK handles slots. Runtime cascade proof deferred to Task 006 test.

## Contracts

### Expects
- `medication_repository.dart` declares `Future<Either<Failure, void>> delete(MedicationId id)` (from Task 001).
- `MedicationLocalDataSource` has field `final AppDatabase _db;` and existing `insertMedication`/`upsertMedication` methods.
- `MedicationRepositoryImpl implements MedicationRepository` with `final MedicationLocalDataSource _dataSource;` and try/catch→`Left(Failure.unknown(e, st))` in `add`/`update`.
- `core/database/database.dart` configures `TimeSlots.medicationId` with `onDelete: cascade` and `pragma foreign_keys = ON`.

### Produces
- `medication_local_data_source.dart` declares `Future<void> deleteMedication(String id)` performing `_db.delete(_db.medications)..where(` … `.equals(id)`.
- `medication_repository_impl.dart` declares `@override` `Future<Either<Failure, void>> delete(MedicationId` … `)` returning `const Right(null)` on success.
- `MedicationRepositoryImpl.delete` catches exceptions and returns `Left(Failure.unknown(e, st))`.
