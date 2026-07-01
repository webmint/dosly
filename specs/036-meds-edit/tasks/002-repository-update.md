# Task 002: Add `update` to the repository contract, impl, and test fakes

**Agent**: architect
**Files**: `lib/features/meds/domain/repositories/medication_repository.dart`, `lib/features/meds/data/repositories/medication_repository_impl.dart`, `test/features/meds/presentation/screens/meds_screen_test.dart`, `test/features/meds/presentation/widgets/add_medication_modal_test.dart`
**Depends on**: 001
**Blocks**: 003, 005
**Context docs**: None
**Review checkpoint**: No

**Description**:
Add `update(Medication)` to the `MedicationRepository` interface and implement it in `MedicationRepositoryImpl` by delegating to `upsertMedication` (Task 001), catching every data-source exception into `Left(Failure.unknown)`. **Atomicity requirement (MEMORY F032/F022):** adding a method to the interface breaks every hand-written `implements MedicationRepository` in `test/` at `dart analyze` time — so this task ALSO patches the four hand-written fakes (`_FakeMedicationRepository`, `_LoadingMedicationRepository`, `_ErrorMedicationRepository` in `meds_screen_test.dart`; `_FakeMedicationRepository` in `add_medication_modal_test.dart`) with an `update` definition in the same change, keeping analyze green. The mocktail mock in `add_medication_test.dart` needs no change (it auto-implements).

**Change details**:
- In `lib/features/meds/domain/repositories/medication_repository.dart`:
  - Add `Future<Either<Failure, Medication>> update(Medication medication);` to the `abstract interface class MedicationRepository`, with a dartdoc explaining it persists an in-place update of an already-stored medication (id must exist) and that slot reconciliation is decided by the caller (see `EditMedication`).
- In `lib/features/meds/data/repositories/medication_repository_impl.dart`:
  - Add the `update` override mirroring `add`:
    ```dart
    @override
    Future<Either<Failure, Medication>> update(Medication medication) async {
      try {
        await _dataSource.upsertMedication(
          medicationToCompanion(medication),
          timeSlotsToCompanions(medication),
        );
        return Right(medication);
      } catch (e, st) {
        return Left(Failure.unknown(e, st));
      }
    }
    ```
- In `test/features/meds/presentation/screens/meds_screen_test.dart`:
  - Add `@override Future<Either<Failure, Medication>> update(Medication medication) => throw UnimplementedError();` (or `async => Right(medication)`) to `_FakeMedicationRepository`, `_LoadingMedicationRepository`, and `_ErrorMedicationRepository`. These fakes only exercise `watchAll`; a throwing stub is acceptable (the screen test never saves an edit).
- In `test/features/meds/presentation/widgets/add_medication_modal_test.dart`:
  - Add a **recording** `update` stub to `_FakeMedicationRepository` mirroring its existing `add` behavior (capture the argument so Task 009 can assert it; return `Right(medication)`).

**Status**: Complete

**Done when**:
- [x] `MedicationRepository` declares `Future<Either<Failure, Medication>> update(Medication medication)`.
- [x] `MedicationRepositoryImpl` defines `update` delegating to `_dataSource.upsertMedication(...)` inside try/catch returning `Left(Failure.unknown(e, st))` on error.
- [x] All hand-written fakes in the two named test files define `update` (analyze passes — no "missing concrete implementation" error).
- [x] `dart analyze` passes on all changed files; `flutter test` still compiles.

## Completion Notes
**Completed**: 2026-06-19
**Files changed**: `medication_repository.dart`, `medication_repository_impl.dart`, `meds_screen_test.dart`, `add_medication_modal_test.dart`
**Contract**: Expects [3/3 verified] | Produces [3/3 verified]
**Notes**: **Five** fakes patched (not 4 — `add_medication_modal_test.dart` also has `_RecordingMedicationRepository`, which now records into a new `capturedUpdate` field for Task 009). `update` impl mirrors `add` exactly (try/catch → `Left(Failure.unknown)`). Code review = APPROVE. **Carry-forward for Task 009**: the modal-test `_FakeMedicationRepository` shares one `completer` field between `add` and `update` — if Task 009 needs to drive a slow edit-save in isolation, split into `_addCompleter`/`_updateCompleter` to avoid cross-path masking. 94 named-file tests pass; analyze clean.

## Contracts

### Expects
- `MedicationLocalDataSource.upsertMedication(MedicationsCompanion, List<TimeSlotsCompanion>)` exists (Task 001).
- `MedicationRepository` declares `add` and `watchAll`; `medicationToCompanion` and `timeSlotsToCompanions` exist in `medication_mapper.dart`.
- `meds_screen_test.dart` and `add_medication_modal_test.dart` declare classes `implements MedicationRepository`.

### Produces
- `medication_repository.dart` declares `Future<Either<Failure, Medication>> update(Medication medication)` on `MedicationRepository`.
- `medication_repository_impl.dart` contains `update(Medication medication)` calling `_dataSource.upsertMedication(` and returning `Left(Failure.unknown(`.
- Every class in `test/` that `implements MedicationRepository` defines `update(`.

**Spec criteria addressed**: AC-7
