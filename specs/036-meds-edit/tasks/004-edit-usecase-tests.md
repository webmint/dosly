# Task 004: Unit-test the `EditMedication` use case

**Agent**: qa-engineer
**Files**: `test/features/meds/domain/usecases/edit_medication_test.dart` (new)
**Depends on**: 003
**Blocks**: None
**Context docs**: None
**Review checkpoint**: No

**Description**:
Write the mandatory domain unit tests for `EditMedication`, mirroring `add_medication_test.dart` (mocktail `MedicationRepository` mock + stub `IdGenerator` + fixed `Clock`). Cover the happy path, id/createdAt preservation, slot-ID reconciliation (keep / add / remove), all four validation branches, and repository-failure passthrough.

**Change details**:
- Create `test/features/meds/domain/usecases/edit_medication_test.dart`, following the structure of `add_medication_test.dart`:
  - `class _MockMedicationRepository extends Mock implements MedicationRepository {}`; `registerFallbackValue` a sample `Medication`; fresh mock in `setUp`; deterministic `IdGenerator` stub (returns predictable new ids).
  - Build an `original` medication fixture with at least two time slots carrying known `TimeSlotId`s.
  - Tests (group `EditMedication`):
    - **preserves id and createdAt**: `when(() => repo.update(any())).thenAnswer((_) async => Right(captured))`; call with edited name; `verify(() => repo.update(captured))` and assert the captured medication's `id` and `createdAt` equal `original`'s.
    - **preserves unchanged slot ids, mints for new, drops removed**: call with an `intakeMinutes` list that keeps one original minute, drops another, and adds a new one; assert the resulting `schedule.slots` reuse the original `TimeSlotId` for the kept minute, contain a new (generator) id for the added minute, and contain no slot for the dropped minute.
    - **validation: empty name** → `Left(ValidationFailure)` with `field == 'name'`; `verifyNever(() => repo.update(any()))`.
    - **validation: no times** → `field == 'times'`; repo not called.
    - **validation: course duration < 1** → `field == 'durationDays'`; repo not called.
    - **validation: dose amount <= 0** → `field == 'dose'`; repo not called.
    - **repository failure passthrough**: `repo.update` returns `Left(Failure.unknown(...))` → the use case returns that same `Left`.
  - Use `withClock(Clock.fixed(...))` where a clock is needed; never real `DateTime.now()` (constitution §3.4).

**Status**: Complete

**Done when**:
- [x] `edit_medication_test.dart` exists with the test groups above (happy path, id/createdAt preservation, slot reconciliation keep/add/remove, 4 validation branches, repo-failure passthrough).
- [x] Each validation test asserts `verifyNever(() => repo.update(any()))`.
- [x] `flutter test test/features/meds/domain/usecases/edit_medication_test.dart` passes; `dart analyze` clean.

## Completion Notes
**Completed**: 2026-06-19
**Files changed**: `test/features/meds/domain/usecases/edit_medication_test.dart` (new)
**Contract**: Expects [2/2 verified] | Produces [2/2 verified]
**Notes**: 7 tests, all pass; analyze clean. Mirrors `add_medication_test.dart` (mocktail mock, deterministic `_FakeIdGenerator`, fixed UTC `createdAt`). Code review = APPROVE WITH WARNINGS → applied: added `expect(result.isRight(), isTrue)` to the two success tests (closes the Left-after-repo-call gap), folded call-count into `expect(captured, hasLength(1))`, and guarded the captured-arg casts (`expect(isA<Medication>())` + `is!`-fail before the `as`). Two textual `as Medication` casts remain but are immediately guarded (runtime-safe, matches the sibling add test) — accepted rather than a third repair round.

## Contracts

### Expects
- `EditMedication` exists with `call({required Medication original, ...})` returning `Future<Either<Failure, Medication>>` (Task 003).
- `MedicationRepository.update` exists to mock.

### Produces
- `edit_medication_test.dart` declares a `group('EditMedication'` containing tests that assert original `id`/`createdAt` are preserved and slot ids are reconciled (keep/add/remove).
- The file contains `verifyNever(() => repo.update(` assertions for each validation branch.

**Spec criteria addressed**: AC-9, AC-10, AC-11, AC-16
