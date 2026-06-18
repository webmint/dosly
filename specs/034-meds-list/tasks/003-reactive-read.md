# Task 003: Reactive read — watched join + repository `watchAll`

**Agent**: architect
**Files**: `lib/features/meds/data/datasources/medication_local_data_source.dart` (modify), `lib/features/meds/domain/repositories/medication_repository.dart` (modify), `lib/features/meds/data/repositories/medication_repository_impl.dart` (modify)
**Depends on**: None
**Blocks**: 004, 005, 013
**Context docs**: `specs/034-meds-list/research.md` (Q1/Q2), `specs/034-meds-list/data-model.md` (read contract)
**Review checkpoint**: No

**Description**:
Add the reactive read across the data + domain boundary. The data source exposes a watched left-outer join of `medications ⨝ time_slots` that re-emits whenever either table changes, grouped into `(MedicationRow, List<TimeSlotRow>)` per medication. The repository wraps it as `Stream<Either<Failure, List<Medication>>>`, reconstructing entities via the existing `medicationFromRows` mapper and converting any thrown error into `Left(Failure.unknown(e, st))` (errors never escape `data/`, §3.2). The repository's reactive read is the read-side analog of the existing `Future<Either<…>> add` — document that in the impl's dartdoc.

**Change details**:
- `medication_local_data_source.dart`:
  - Add `Stream<List<(MedicationRow, List<TimeSlotRow>)>> watchAllMedications()` using `_db.select(_db.medications).join([leftOuterJoin(_db.timeSlots, _db.timeSlots.medicationId.equalsExp(_db.medications.id))]).watch()`, mapping each emission: group `TypedResult` rows by medication id (`readTable(_db.medications)` / `readTableOrNull(_db.timeSlots)`), preserving slot-less meds (null slot → empty list). Keep deterministic ordering inside the data source or leave ordering to the view-model (document which).
- `medication_repository.dart`: add `Stream<Either<Failure, List<Medication>>> watchAll();` with dartdoc.
- `medication_repository_impl.dart`: implement `watchAll()` as an `async*` generator — `try { await for (final rows in _dataSource.watchAllMedications()) { yield Right(rows.map((r) => medicationFromRows(r.$1, r.$2)).toList()); } } catch (e, st) { yield Left(Failure.unknown(e, st)); }`. Import the mapper (`medicationFromRows`).

**Done when**:
- [x] `watchAllMedications()` exists and uses a watched join (re-emits on both tables).
- [x] `MedicationRepository` declares `watchAll()`; `MedicationRepositoryImpl` implements it via `medicationFromRows`, mapping errors to `Left`.
- [x] No exception can escape `watchAll()` (mapping + iteration wrapped); no `!`, exhaustive handling.
- [x] `dart analyze` passes on changed files.

**Spec criteria addressed**: AC-1, AC-3

## Completion Notes
**Status**: Complete
**Completed**: 2026-06-18
**Files changed**: medication_local_data_source.dart, medication_repository.dart, medication_repository_impl.dart
**Contract**: Expects 4/4 verified | Produces 3/3 verified
**Notes**: Watched left-outer join; in-memory grouping preserves first-seen order + slot-less meds (empty list); zero `!` (used `putIfAbsent` + null-guarded reads). Repo `watchAll()` is `async*`+try → `Left(Failure.unknown)`; terminates the stream on first error (re-subscribe to recover), consistent with `add`. Domain interface has no drift import. **For /review**: data source annotates `JoinedSelectStatement<HasResultSet, dynamic>` explicitly — `final query = …` inference would avoid writing `dynamic` (type-param only, no dynamic dispatch; analyze-clean). Inline-reviewed: APPROVE.

## Contracts

### Expects
- `medication_mapper.dart` exports `Medication medicationFromRows(MedicationRow row, List<TimeSlotRow> slotRows)`.
- `database.dart` exposes `medications` and `timeSlots` tables on `AppDatabase` with generated `MedicationRow` / `TimeSlotRow`.
- `MedicationLocalDataSource` holds an `AppDatabase _db`.
- `failures.dart` exports `Failure.unknown(Object error, StackTrace stack)`.

### Produces
- `medication_local_data_source.dart` exports method `Stream<List<(MedicationRow, List<TimeSlotRow>)>> watchAllMedications()`.
- `medication_repository.dart` declares `Stream<Either<Failure, List<Medication>>> watchAll()`.
- `medication_repository_impl.dart` implements `watchAll()` calling `medicationFromRows` and yielding `Left(Failure.unknown(` on error.
