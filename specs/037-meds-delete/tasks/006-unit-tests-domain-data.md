# Task 006: Unit tests — use case, data-source cascade, repo impl

**Agent**: qa-engineer
**Status**: Complete
**Files**: `test/features/meds/domain/usecases/delete_medication_test.dart` (new), `test/features/meds/data/datasources/medication_local_data_source_delete_test.dart` (new), `test/features/meds/data/repositories/medication_repository_impl_test.dart` (modify)
**Depends on**: 002
**Blocks**: None
**Context docs**: None
**Review checkpoint**: No

**Description**:
Prove the delete data path: the use case forwards correctly, the drift delete removes the medication AND cascade-removes its time slots, absent-id is a no-op, and the repo impl maps success/failure to `Right`/`Left`. Follow the existing test idioms: mocktail `MockMedicationRepository` (use-case test, mirroring `add_medication_test.dart`), in-memory `AppDatabase(NativeDatabase.memory())` with `setUp`/`tearDown` (data-source test, mirroring `medication_local_data_source_watch_test.dart`), and the per-method groups in `medication_repository_impl_test.dart`.

**Change details**:
- Create `test/features/meds/domain/usecases/delete_medication_test.dart`:
  - `group('DeleteMedication')`: given a `MockMedicationRepository`, `when(() => repo.delete(any())).thenAnswer((_) async => const Right(null))` → `call(id)` returns `Right`; assert `verify(() => repo.delete(id)).called(1)`. A `Left` from the repo propagates unchanged. Register a `MedicationId` fallback if needed.
- Create `test/features/meds/data/datasources/medication_local_data_source_delete_test.dart`:
  - Insert a medication with ≥1 time slot via `insertMedication(...)`; call `deleteMedication(id)`; assert `select(medications).get()` is empty AND `select(timeSlots).get()` is empty (cascade proof — both row counts 0).
  - `deleteMedication('non-existent-id')` completes without throwing and leaves existing rows intact (idempotent no-op).
- In `test/features/meds/data/repositories/medication_repository_impl_test.dart`:
  - Add `group('MedicationRepositoryImpl.delete()')` with: success → `Right(null)` (with a real in-memory DB or a `MockMedicationLocalDataSource` whose `deleteMedication` completes); data-source throw → `Left` is an `UnknownFailure` (not thrown).

**Done when**:
- [x] `delete_medication_test.dart` asserts forwarding to `repo.delete` and `Right`/`Left` propagation.
- [x] `medication_local_data_source_delete_test.dart` asserts both the medication and its time-slot rows are gone after delete (cascade), and that an absent-id delete is a no-throw no-op.
- [x] `medication_repository_impl_test.dart` has a `delete()` group covering success (`Right(null)`) and thrown-exception → `Left(UnknownFailure)`.
- [x] `flutter test test/features/meds/` passes; `dart analyze` passes on the test files.

**Spec criteria addressed**: AC-2, AC-3, AC-4, AC-5

## Completion Notes

**Completed**: 2026-07-01
**Files changed**: `delete_medication_test.dart` (new, 2 tests), `medication_local_data_source_delete_test.dart` (new, 3 tests incl. cascade proof), `medication_repository_impl_test.dart` (+`delete()` group, 4 tests, +`_DeleteErroringDataSource` double mirroring `_UpsertErroringDataSource`)
**Contract**: Expects [4/4 verified] | Produces [3/3 verified]
**Code review**: Self-reviewed (test-only; cascade proof genuine — asserts both tables empty after delete at `..._delete_test.dart:125-127`; meds suite 268 green; analyze clean).
**Notes**: 9 new tests. Real in-memory drift for cascade; mocktail for use case; erroring data-source double for repo-impl failure path.

## Contracts

### Expects
- `DeleteMedication.call(MedicationId)` returns `Future<Either<Failure, void>>` (Task 001).
- `MedicationLocalDataSource.deleteMedication(String id)` performs a cascade-backed delete (Task 002).
- `MedicationRepositoryImpl.delete` returns `Right(null)` / `Left(Failure.unknown)` (Task 002).
- Existing test helpers: `AppDatabase(NativeDatabase.memory())` setup, `insertMedication`, `TimeSlotsCompanion.insert`, mocktail mocks.

### Produces
- `delete_medication_test.dart` exists with a `group('DeleteMedication'`.
- `medication_local_data_source_delete_test.dart` exists asserting `timeSlots` empty after medication delete.
- `medication_repository_impl_test.dart` contains `group('MedicationRepositoryImpl.delete()'`.
