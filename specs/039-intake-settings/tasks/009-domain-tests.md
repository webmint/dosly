# Task 009: Unit tests — value objects + use cases

**Agent**: qa-engineer
**Files**: `test/features/settings/domain/value_objects/intake_window_test.dart` (new), `test/features/settings/domain/value_objects/grace_period_test.dart` (new), `test/features/settings/domain/usecases/set_intake_window_test.dart` (new), `test/features/settings/domain/usecases/set_grace_period_test.dart` (new), `test/features/settings/domain/usecases/set_allow_mark_ahead_test.dart` (new)
**Depends on**: 001, 005
**Blocks**: None
**Context docs**: None
**Review checkpoint**: No

**Description**:
Cover the value objects' clamping/equality/purity and the three pass-through use cases. Use `mocktail` for the repository (mirror `set_theme_mode_test.dart`), verifying each use case forwards to the correct `saveX` and returns its `Either` unchanged (both `Right` and `Left`).

**Change details**:
- VO tests: in-range passthrough, below-min and above-max clamping (boundaries inclusive), value equality + `hashCode`, and `defaultValue.minutes` (120 / 5).
- Use-case tests: with a `_MockSettingsRepository extends Mock implements SettingsRepository`, stub `saveIntakeWindow`/etc. to return `Right(null)` then `Left(Failure.unknown(...))`; assert the use case returns the same and calls the method once with the expected argument.

**Contracts**:

### Expects
- `IntakeWindow`/`GracePeriod` exist with clamping factory + `defaultValue` (Task 001).
- `SetIntakeWindow`/`SetGracePeriod`/`SetAllowMarkAhead` exist and forward to the repo (Task 005).

### Produces
- Five new test files under `test/features/settings/domain/` exercising the above.

**Done when**:
- [x] `flutter test test/features/settings/domain/` passes.
- [x] Tests assert both `Right` and `Left` propagation for each use case.
- [x] `dart analyze` passes on the new test files.

**Spec criteria addressed**: AC-2, AC-3, AC-4, AC-11

## Completion Notes
**Status**: Complete
**Completed**: 2026-07-03
**Files changed**: 5 new test files under `test/features/settings/domain/` (2 VO + 3 use-case)
**Contract**: Produces [verified — clamp/boundary/equality/defaultValue + both Either branches per use case]
**Code review**: APPROVE (reviewer mutation-checked the clamp → tests are load-bearing, not tautological; 3 Info notes, all inherent/acceptable)
**Notes**: Mirrors `set_theme_mode_test.dart` mocktail idiom. AC-4 (purity) satisfied by inspection (no purity-test convention exists in the repo).
