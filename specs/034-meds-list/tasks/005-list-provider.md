# Task 005: `medicationsList` stream provider

**Agent**: architect
**Files**: `lib/features/meds/presentation/providers/medication_providers.dart` (modify)
**Depends on**: 003
**Blocks**: 011
**Context docs**: `specs/034-meds-list/research.md` (Q4 stream-provider precedent)
**Review checkpoint**: No

**Description**:
Expose the reactive read to the UI as `AsyncValue<List<Medication>>` from the meds composition seam. Mirror the in-repo precedent `settingsErrors` (`@riverpod Stream<…>`): fold each `Either` emission so `Right` → data and `Left` → an error event (throw the `Failure`), per constitution §3.2 and the §7.2 `MedicationsList` example.

**Change details**:
- In `medication_providers.dart`, add:
  ```dart
  @riverpod
  Stream<List<Medication>> medicationsList(Ref ref) =>
      ref.watch(medicationRepositoryProvider).watchAll().map(
            (either) => either.fold((failure) => throw failure, (meds) => meds),
          );
  ```
  Add the `Medication` import; keep the seam's "only presentation file allowed to import `data/`" dartdoc intact.
- Run `dart run build_runner build --delete-conflicting-outputs`; commit `medication_providers.g.dart`.

**Done when**:
- [x] `medicationsListProvider` is generated and exposes `AsyncValue<List<Medication>>`.
- [x] Build runner regenerates the `.g.dart` (committed); `dart analyze` clean.

**Spec criteria addressed**: AC-2

## Completion Notes
**Status**: Complete
**Completed**: 2026-06-18
**Files changed**: medication_providers.dart (+ .g.dart)
**Contract**: Expects 2/2 verified | Produces 1/1 verified
**Notes**: Mirrors `settingsErrors` stream-provider shape; folds `Either` (`Right`→data, `Left`→throw → `AsyncValue.error`). Returns the raw list (filtering/grouping deferred to view-model T009). Mechanical; inline-reviewed.

## Contracts

### Expects
- `MedicationRepository` declares `Stream<Either<Failure, List<Medication>>> watchAll()` (Task 003 `Produces`).
- `medicationRepositoryProvider` exists in `medication_providers.dart`.

### Produces
- `medication_providers.dart` contains `@riverpod Stream<List<Medication>> medicationsList(Ref ref)` (generates `medicationsListProvider`).
