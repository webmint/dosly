# Task 005: Add SetIntakeWindow / SetGracePeriod / SetAllowMarkAhead use cases

**Agent**: architect
**Files**: `lib/features/settings/domain/usecases/set_intake_window.dart` (new), `set_grace_period.dart` (new), `set_allow_mark_ahead.dart` (new)
**Depends on**: 004
**Blocks**: 006, 009
**Context docs**: None
**Review checkpoint**: No

**Description**:
Add three single-purpose pass-through use cases mirroring `SetThemeMode` exactly — each holds a `SettingsRepository` and forwards `call(...)` to the matching `saveX`. Screens never call repositories directly (constitution §4.1.1); the notifier delegates through these.

**Change details**:
- `set_intake_window.dart`: `class SetIntakeWindow { const SetIntakeWindow(this._repo); final SettingsRepository _repo; Future<Either<Failure, void>> call(IntakeWindow window) => _repo.saveIntakeWindow(window); }` with dartdoc; import the VO + repo + failures.
- `set_grace_period.dart`: same for `SetGracePeriod` → `saveGracePeriod(GracePeriod grace)`.
- `set_allow_mark_ahead.dart`: same for `SetAllowMarkAhead` → `saveAllowMarkAhead(bool value)`.

**Contracts**:

### Expects
- `SettingsRepository` declares `saveIntakeWindow`, `saveGracePeriod`, `saveAllowMarkAhead` (Task 004).

### Produces
- `set_intake_window.dart` declares `class SetIntakeWindow` with `call(IntakeWindow` forwarding to `saveIntakeWindow`.
- `set_grace_period.dart` declares `class SetGracePeriod` with `call(GracePeriod` forwarding to `saveGracePeriod`.
- `set_allow_mark_ahead.dart` declares `class SetAllowMarkAhead` with `call(bool` forwarding to `saveAllowMarkAhead`.

**Done when**:
- [x] Each use case forwards to the matching repo method and returns its `Either` unchanged.
- [x] `dart analyze` passes on the three files.

**Spec criteria addressed**: AC-11

## Completion Notes
**Status**: Complete
**Completed**: 2026-07-03
**Files changed**: `set_intake_window.dart`, `set_grace_period.dart`, `set_allow_mark_ahead.dart` (all new)
**Contract**: Produces [all verified — 3 classes forwarding to the matching saveX]
**Code review**: APPROVE (no issues)
**Notes**: Exact structural copies of `SetThemeMode`; pure Dart, thin delegates (clamping stays in the VOs).
