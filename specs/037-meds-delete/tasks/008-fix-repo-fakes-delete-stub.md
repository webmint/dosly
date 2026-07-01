# Task 008: Add `delete` override to existing `MedicationRepository` test fakes

**Agent**: qa-engineer
**Status**: Complete
**Files**: `test/features/meds/presentation/screens/meds_screen_test.dart`, `test/features/meds/presentation/widgets/add_medication_modal_test.dart`
**Depends on**: 001
**Blocks**: 005 (verification), 007
**Context docs**: None
**Review checkpoint**: No

> **Discovered during execution** (not in the original breakdown). Task 001 added `delete(MedicationId)` to the `MedicationRepository` interface. Five hand-written fake repositories that `implements MedicationRepository` now fail to compile ("Missing concrete implementation of `MedicationRepository.delete`"), breaking the whole test suite. This task restores compilation. Sequenced immediately after Task 003, before Tasks 004/005.

**Description**:
Add a minimal `delete` override to every hand-written class that `implements MedicationRepository` in the two affected test files, so the test suite compiles again. These tests do not exercise deletion (delete lives in the modal, covered later by Task 007), so a safe no-op returning `const Right(null)` is sufficient. Do NOT change any existing test logic or the other fake methods.

**Change details**:
- In `test/features/meds/presentation/screens/meds_screen_test.dart` — add to each of the 3 fakes (`_FakeMedicationRepository`, `_LoadingMedicationRepository`, `_ErrorMedicationRepository`):
  ```dart
  @override
  Future<Either<Failure, void>> delete(MedicationId id) async =>
      const Right(null);
  ```
- In `test/features/meds/presentation/widgets/add_medication_modal_test.dart` — add the same `delete` override to `_FakeMedicationRepository` and `_RecordingMedicationRepository`.
- Ensure `MedicationId` is imported in both files (add the import if the analyzer flags it missing).
- Keep each override consistent with the file's existing `add`/`update` stub style (e.g. expression-bodied async returning a `Right`).

**Done when**:
- [x] All 5 fake classes implement `delete(MedicationId) → Future<Either<Failure, void>>` returning `const Right(null)`.
- [x] `dart analyze` reports **zero** errors project-wide (the 5 "Missing concrete implementation" errors are gone).
- [x] `flutter test test/features/meds/presentation/screens/meds_screen_test.dart test/features/meds/presentation/widgets/add_medication_modal_test.dart` passes (existing tests unchanged and green).
- [x] No existing test logic or non-`delete` fake methods were modified.

**Spec criteria addressed**: AC-14 (build/tests green) — enabling AC-7…AC-12 verification downstream.

## Completion Notes

**Completed**: 2026-07-01
**Files changed**: `meds_screen_test.dart` (+3 `delete` stubs), `add_medication_modal_test.dart` (+2 `delete` stubs) — 20 insertions, 0 deletions
**Contract**: Expects [3/3 verified] | Produces [2/2 verified]
**Code review**: Self-reviewed via diff (test-only no-op stubs; whole-project `dart analyze` clean; full suite 568 tests green) — no separate reviewer agent for a trivial mechanical build-fix.
**Notes**: `MedicationId` already imported in both files; no import changes needed. Full `flutter test` = 568 passed.

## Contracts

### Expects
- `MedicationRepository` declares `Future<Either<Failure, void>> delete(MedicationId id)` (Task 001).
- `meds_screen_test.dart` defines `_FakeMedicationRepository`, `_LoadingMedicationRepository`, `_ErrorMedicationRepository` implementing `MedicationRepository`.
- `add_medication_modal_test.dart` defines `_FakeMedicationRepository`, `_RecordingMedicationRepository` implementing `MedicationRepository`.

### Produces
- Each of the 5 fakes declares an `@override Future<Either<Failure, void>> delete(MedicationId` returning `const Right(null)`.
- Project-wide `dart analyze` is error-free.
