# Task 009: Intake mapper + repository impl

**Agent**: architect
**Files**: `lib/features/meds/data/mappers/intake_mapper.dart`, `lib/features/meds/data/repositories/intake_repository_impl.dart`, `test/features/meds/data/mappers/intake_mapper_test.dart`
**Depends on**: 002, 005, 007, 008
**Context docs**: None
**Review checkpoint**: No

**Description**:
Bridge the `Intake` domain entity to drift and implement the `IntakeRepository` contract. The mapper is pure (row ⇆ companion), mirroring `medication_mapper.dart` (using `Value`/`Value.absent`). The repo impl is mechanical glue: call the mapper, delegate to the data source, catch throws → `Left(CacheFailure)`, map the watch stream `List<IntakeRow> → Right(List<Intake>)`.

**Change details**:
- `intake_mapper.dart`:
  - `IntakesCompanion intakeToCompanion(Intake intake)` — maps ids to `.value`, `status`, UTC `scheduledAt`, nullable `confirmedAt`/`notes` via `Value<...>`.
  - `Intake intakeFromRow(IntakeRow row)` — inverse; wraps `IntakeId`/`MedicationId`/`TimeSlotId`; timestamps stay UTC.
- `intake_repository_impl.dart` (`class IntakeRepositoryImpl implements IntakeRepository`):
  - `watchAll()` → `_ds.watchAllIntakes().map((rows) => Either...Right(rows.map(intakeFromRow).toList()))`, wrapped so a thrown query error surfaces as `Left(CacheFailure)` (mirror `MedicationRepositoryImpl.watchAll`).
  - `markTaken`/`skip` → build companion via mapper, `try { await _ds.upsertIntake(...); return Right(intake); } catch (e) { return Left(Failure.cache(...)); }`.
  - `undo(id)` → `try { await _ds.deleteIntake(id.value); return const Right(null); } catch ... Left`.
- Mapper unit tests: `Intake` → companion → row → `Intake` round-trip preserves fields and UTC timestamps (AC-6).

**Contracts**:

### Expects
- `IntakeRepository` contract (Task 007); `IntakeLocalDataSource` (Task 008); `IntakeRow`/`IntakesCompanion` (Task 005); `Intake` (Task 002); `CacheFailure` in `failures.dart`.

### Produces
- `intake_mapper.dart` exports `intakeToCompanion(Intake)` and `intakeFromRow(IntakeRow)`.
- `intake_repository_impl.dart` declares `class IntakeRepositoryImpl implements IntakeRepository` implementing all four members and mapping errors to `Left(CacheFailure)`.

**Done when**:
- [ ] Mapper round-trip preserves all fields incl. UTC timestamps (unit-tested).
- [ ] Repo impl maps `Right`/`Left` correctly; no thrown exception escapes.
- [ ] `dart analyze` + `flutter test test/features/meds/data/mappers/intake_mapper_test.dart` pass.

**Spec criteria addressed**: AC-6, AC-9, AC-12

## Completion Notes
**Status**: Complete
**Completed**: 2026-07-02
**Files changed**: `data/mappers/intake_mapper.dart`, `data/repositories/intake_repository_impl.dart`, `test/features/meds/data/mappers/intake_mapper_test.dart`
**Contract**: Expects [ok] | Produces [2/2] — `intakeToCompanion`/`intakeFromRow`; `IntakeRepositoryImpl implements IntakeRepository` (4 members, `Left(CacheFailure)`); 0 empty catches.
**Notes**: `watchAll` mirrors medication repo's `async*`/`await for`/try-catch (yields `Left` on stream error). Chose `Failure.cache(...)` per this task's explicit contract (medication repo uses `Failure.unknown`); underlying error preserved in message, nothing swallowed. 14/14 round-trip tests pass (taken + skipped, UTC via `isAtSameMomentAs`). `dart analyze` clean.
