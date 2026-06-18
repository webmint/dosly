# Task 008: Data layer — mapper, local data source, repository impl

**Agent**: architect
**Files**: `lib/features/meds/data/mappers/medication_mapper.dart`, `lib/features/meds/data/datasources/medication_local_data_source.dart`, `lib/features/meds/data/repositories/medication_repository_impl.dart`
**Depends on**: 005, 007
**Blocks**: 009, 013
**Context docs**: `specs/032-med-persistence/data-model.md` (Mapping rules), `specs/032-med-persistence/research.md` (transaction/batch)
**Review checkpoint**: Yes — convergence (DB + domain contract); the mapper + transaction are the persistence correctness core

**Description**:
Implement the drift-backed persistence: a pure mapper (domain ↔ drift companions/rows), a data source that inserts the medication and its time slots in one transaction, and a repository impl that catches every exception and returns `Left(Failure)`.

**Change details**:
- `medication_mapper.dart`: pure functions converting a `Medication` to a `MedicationsCompanion` + `List<TimeSlotsCompanion>` and back (`MedicationRow` + `List<TimeSlotRow>` → `Medication`). Apply data-model mapping rules: null `Dosage` ⇔ both dose columns `null` (`Value.absent()`/`null`); null `PackStock` ⇔ three stock columns null; `MedicationType` ⇔ (`typeKind`,`startDate`,`durationDays`,`pauseDays`) using an exhaustive `switch` (no `default:`); `Schedule.frequency` ⇔ `frequency`. Reconstruct `Schedule.slots` from the slot rows.
- `medication_local_data_source.dart`: `class MedicationLocalDataSource { const MedicationLocalDataSource(this._db); ... }` with `Future<void> insertMedication(MedicationsCompanion med, List<TimeSlotsCompanion> slots)` that runs `_db.transaction(() async { await _db.into(_db.medications).insert(med); await _db.batch((b) => b.insertAll(_db.timeSlots, slots)); })`. Throws drift exceptions (caught upstream).
- `medication_repository_impl.dart`: `class MedicationRepositoryImpl implements MedicationRepository` — maps the domain `Medication` via the mapper, calls the data source inside `try`, returns `Right(medication)` on success; `catch (e, st)` → `Left(Failure.cache(...))` or `Left(Failure.unknown(e, st))`. Exceptions never escape. Mirror `settings_repository_impl.dart`.

**Done when**:
- [ ] mapper round-trips every field per data-model.md (verified by task 013); uses exhaustive `switch` on `MedicationType`
- [ ] `MedicationLocalDataSource.insertMedication` wraps both inserts in a single `_db.transaction`
- [ ] `MedicationRepositoryImpl.add` returns `Either<Failure, Medication>` and never lets an exception escape `data/`
- [ ] no `presentation/` imports in `data/`; `dart analyze` passes

## Contracts
### Expects
- `AppDatabase`, `Medications`/`TimeSlots` tables + companions (`MedicationsCompanion`, `TimeSlotsCompanion`), `MedicationTypeKind` (task 005)
- `MedicationRepository.add` contract + `Medication` aggregate (tasks 004, 007)
### Produces
- `medication_mapper.dart` exports functions mapping `Medication` ↔ drift companions/rows
- `medication_local_data_source.dart` exports `MedicationLocalDataSource` with `insertMedication(...)` using `transaction`
- `medication_repository_impl.dart` exports `MedicationRepositoryImpl implements MedicationRepository`

**Spec criteria addressed**: AC-14, AC-15, AC-16, AC-20

## Completion Notes
**Completed**: 2026-06-17
**Status**: Complete
**Files changed**: data/mappers/medication_mapper.dart, data/datasources/medication_local_data_source.dart, data/repositories/medication_repository_impl.dart
**Contract**: Expects 2/2 | Produces 3/3
**Code review**: APPROVE WITH WARNINGS. Full field coverage both directions; null↔null symmetry for dose/stock; exhaustive sealed switches (no default:); `!`-free via flow promotion + 2 private helpers (`_dosageFromColumns`, `_timeSlotToCompanion`); atomic `_db.transaction`; corrupt course row → loud StateError caught by repo.
**Warning (W1, non-blocking, deferred to /review)**: `medication_mapper.dart` read-back uses `warnAt ?? 0` — a SILENT default, asymmetric with the loud StateError used for corrupt course rows. It is a NON-TRIGGERING defensive branch (write path always persists warnAt when stock present), so reviewer rated it acceptable. Optional hardening: throw StateError when remaining+total present but warnAt null.
**Notes**: `add()` only uses the write-direction mappers; `medicationFromRows` (with the StateError) is exercised by task 013's round-trip tests. No presentation imports in data/.
