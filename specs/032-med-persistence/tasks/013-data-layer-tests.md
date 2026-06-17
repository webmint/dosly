# Task 013: Data-layer tests (in-memory drift)

**Agent**: qa-engineer
**Files**: `test/features/meds/data/repositories/medication_repository_impl_test.dart`, `test/features/meds/data/mappers/medication_mapper_test.dart`
**Depends on**: 005, 008
**Context docs**: `specs/032-med-persistence/research.md` (in-memory DB setup), `specs/032-med-persistence/data-model.md`
**Review checkpoint**: No

**Description**:
Verify persistence correctness against a real (in-memory) drift database: a full domain→insert→read round-trip through the mapper + data source, and the repository's failure path.

**Change details**:
- `setUp`: `database = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));` `tearDown`: `await database.close();`.
- Mapper test: for representative medications — (a) tablet with `Dosage(tablet)` + `PackStock` + 2 time slots + `continuous`; (b) syrup with `Dosage(ml)`, no stock, `course(durationDays, pauseDays)`; (c) inhaler with `dosePerIntake == null`, `stock == null` — insert via data source, read back, map to domain, and assert deep equality of all fields (null dose/stock preserved; `minuteOfDay`s preserved; `startDate`/`createdAt` UTC).
- Repo test: a happy-path `add` returns `Right`; an induced failure (e.g. a closed DB or a constraint violation) returns a `Left(Failure)` and does not throw.

**Done when**:
- [ ] round-trip tests for the three representative shapes pass (fields preserved, nulls preserved)
- [ ] `MedicationRepositoryImpl.add` happy path returns `Right`; failure path returns `Left` without throwing
- [ ] uses `NativeDatabase.memory()` (no real DB file, no disk); `flutter test` green; `dart analyze` passes

## Contracts
### Expects
- `AppDatabase` optional-executor constructor (task 005); mapper + `MedicationLocalDataSource` + `MedicationRepositoryImpl` (task 008)
### Produces
- `medication_mapper_test.dart` and `medication_repository_impl_test.dart` exist and assert round-trip fidelity + the failure path against an in-memory drift DB

**Spec criteria addressed**: AC-14, AC-15, AC-16, AC-20, AC-23

## Completion Notes
**Completed**: 2026-06-17
**Status**: Complete
**Files changed**: test/features/meds/data/mappers/medication_mapper_test.dart, test/features/meds/data/repositories/medication_repository_impl_test.dart; + side-fix lib/core/database/database.dart (3 imports — necessary-for-compilation)
**Contract**: Produces 1/1
**Notes**: 45 new tests (36 mapper round-trip across tablet/syrup/inhaler fixtures + 9 repo happy/failure). Full suite **382 green**, analyze clean.
**Two findings**:
1. **Latent task-005 defect fixed**: `database.g.dart` (part) references `MedicationForm`/`DoseUnit`/`ScheduleFrequency` (textEnum columns), but the owning library `database.dart` only imported them transitively via the table files. `dart analyze` was GREEN, yet `flutter test` (kernel compile) failed to resolve them in the part. Fix = 3 direct imports in database.dart. → analyze ≠ compile for part-file symbol resolution.
2. **drift `dateTime()` round-trip drops the `isUtc` flag**: stored moment is correct but reads back as local-flagged DateTime. Tests assert with `isAtSameMomentAs` (moment equality), not `==`. Not a mapper bug; documented in the test.
