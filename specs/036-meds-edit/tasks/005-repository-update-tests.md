# Task 005: Round-trip test the repository `update` path

**Agent**: qa-engineer
**Files**: `test/features/meds/data/repositories/medication_repository_impl_test.dart`
**Depends on**: 002
**Blocks**: None
**Context docs**: `docs/features/medication-persistence.md`
**Review checkpoint**: No

**Description**:
Extend the existing in-memory-drift repository test with an `update` group proving the in-place upsert + slot reconciliation works against a real (in-memory) database: the medication row is updated in place (not duplicated, slots not cascade-wiped), unchanged slot ids survive, removed slots are deleted, added slots appear, a sibling medication is untouched, and a data-source exception surfaces as `Left`.

**Change details**:
- In `test/features/meds/data/repositories/medication_repository_impl_test.dart`:
  - Reuse the existing in-memory setup. Per MEMORY F034, build the executor as `AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true))` so writes notify synchronously (no `Future.delayed`).
  - Add a `group('update', () { ... })`:
    - **in-place update**: `add` a medication with two slots; `update` the same medication (changed `name`, one slot minute kept, one changed); read back via the watch/select and assert exactly one medication row for that id with the new name, and that the kept slot retained its original `TimeSlotId`.
    - **removed slot deleted, added slot inserted**: update with a slot set that drops one original minute and adds a new one (new `TimeSlotId`); assert the dropped slot row is gone, the added row exists, and no orphan rows remain for that medication.
    - **sibling untouched**: with two medications persisted, updating one leaves the other's row and slots unchanged.
    - **failure path**: using the existing erroring-data-source pattern (a subclass overriding `upsertMedication` to throw), assert `repo.update(...)` returns `Left` (a `Failure`).
  - Construct the updated `Medication` directly (the test owns slot ids to assert preservation) — this test targets the repository/data-source, not the use case.

**Status**: Complete

**Done when**:
- [x] A `group('MedicationRepositoryImpl.update()'` exists with the in-place, removed/added, sibling-untouched, and failure-path tests.
- [x] The kept-slot test asserts the original `TimeSlotId` value is preserved after update; the removed-slot test asserts its row is deleted.
- [x] Tests use `closeStreamsSynchronously: true`; no `await Future.delayed`.
- [x] `flutter test test/features/meds/data/repositories/medication_repository_impl_test.dart` passes; `dart analyze` clean.

## Completion Notes
**Completed**: 2026-06-19
**Files changed**: `test/features/meds/data/repositories/medication_repository_impl_test.dart`
**Contract**: Expects [2/2 verified] | Produces [1/1 verified]
**Notes**: 5 update tests added (20 total pass): in-place no-duplicate row; kept-slot id preserved + removed-slot deleted; **full slot replacement** (all original removed, all new inserted); sibling-medication untouched; `_UpsertErroringDataSource` → `Left(UnknownFailure)`. Code review = APPROVE WITH WARNINGS → rewrote a duplicate test into the full-replacement scenario, and added a contextual TODO noting that an airtight cascade-safety proof needs an `Intakes` row referencing a kept slot (deferred until the Intakes table exists — slot-id preservation alone can't distinguish "no cascade" from "cascade + payload reinsert"). Uses the existing in-memory `closeStreamsSynchronously` setup (MEMORY F034).

## Contracts

### Expects
- `MedicationRepository.update` and `MedicationLocalDataSource.upsertMedication` exist (Task 002 / 001).
- `medication_repository_impl_test.dart` already sets up an in-memory `AppDatabase` and has an erroring-data-source pattern.

### Produces
- `medication_repository_impl_test.dart` contains a `group('update'` asserting in-place row update, preserved kept-slot `TimeSlotId`, deleted removed-slot, inserted added-slot, sibling-untouched, and a `Left` failure path.

**Spec criteria addressed**: AC-7, AC-8, AC-9, AC-16
