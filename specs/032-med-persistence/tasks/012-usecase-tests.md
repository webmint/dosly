# Task 012: Unit tests for AddMedication

**Agent**: qa-engineer
**Files**: `test/features/meds/domain/usecases/add_medication_test.dart`
**Depends on**: 007
**Context docs**: `constitution.md` §3.4 (testing), `.claude/memory/MEMORY.md` (clock/withClock)
**Review checkpoint**: No

**Description**:
Cover the `AddMedication` use case: happy path plus every validation branch and the repository-failure passthrough, using a `mocktail` mock repository, a fake/sequential `IdGenerator`, and a fixed `Clock`.

**Change details**:
- `class _MockRepo extends Mock implements MedicationRepository {}`; a `_FakeIdGenerator implements IdGenerator` returning deterministic ids (e.g. `'id-1'`, `'id-2'`, …).
- `registerFallbackValue` for `Medication` if matched via `any()`.
- Wrap time-sensitive bodies in `withClock(Clock.fixed(DateTime.utc(2026, 6, 17)), () async { ... })`.
- Tests:
  - empty/whitespace name → `Left(ValidationFailure)` with `field == 'name'`; `verifyNever(() => repo.add(any()))`.
  - empty `intakeMinutes` → `Left(ValidationFailure)` `field == 'times'`.
  - `course` with `durationDays == 0` → `Left(ValidationFailure)` `field == 'durationDays'`.
  - valid input → `verify(() => repo.add(any())).called(1)`; result equals the repo's `Right`; assert `createdAt` is the fixed UTC instant and ids come from the fake generator.
  - repo returns `Left(Failure.cache(...))` → use case returns the same `Left` unchanged.

**Done when**:
- [ ] all five scenarios above are covered and pass
- [ ] no real `DateTime.now()`; time controlled via `withClock`
- [ ] `flutter test test/features/meds/domain/usecases/add_medication_test.dart` is green; `dart analyze` passes

## Contracts
### Expects
- `AddMedication.call(...)` + `MedicationRepository` (task 007); `IdGenerator` (task 006); `Failure.validation` (core)
### Produces
- `add_medication_test.dart` exists with a `group('AddMedication', ...)` asserting validation fields `name`, `times`, `durationDays`, the happy path, and the failure passthrough

**Spec criteria addressed**: AC-10, AC-11, AC-12, AC-13, AC-22

## Completion Notes
**Completed**: 2026-06-17
**Status**: Complete
**Files changed**: test/features/meds/domain/usecases/add_medication_test.dart
**Contract**: Produces 1/1
**Notes**: 5 tests, all pass. Covers name/times/durationDays validation (repo never called), happy path (captured Medication: trimmed name, createdAt==fixed UTC, deterministic ids id-1/2/3, slot minuteOfDay match), and repo-Left passthrough. `withClock(Clock.fixed(2026-06-17))`; mocktail `_MockMedicationRepository` + `_FakeIdGenerator`. `flutter test` +5 green; analyze clean.
