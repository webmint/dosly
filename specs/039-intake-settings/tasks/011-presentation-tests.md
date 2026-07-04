# Task 011: Widget/state tests — notifier mutators + Intake controls

**Agent**: qa-engineer
**Files**: `test/features/settings/presentation/providers/settings_provider_test.dart` (extend), `test/features/settings/presentation/widgets/intake_settings_controls_test.dart` (new)
**Depends on**: 006, 008
**Blocks**: None
**Context docs**: None
**Review checkpoint**: Yes

**Description**:
Cover the three new `SettingsNotifier` mutators (success updates only the target field; failure emits on `errors` and leaves state unchanged) and the `IntakeSettingsControls` widget (renders steppers + switch, step/bounds behavior, switch toggle, and the failure SnackBar). Reuse the existing settings provider/widget test harness and the `_FakeSettingsRepository` pattern (now carrying the three new no-op/failable overrides from Task 004). This is the final verification checkpoint — confirm the full suite and project-wide analyze are green.

**Change details**:
- Notifier tests: on `Right`, `setIntakeWindow`/`setGracePeriod`/`setAllowMarkAhead` update `state.intakeWindow`/`.gracePeriod`/`.allowMarkAhead`; on `Left`, state is unchanged and a `Failure` reaches `errors`. Also assert a default-load `AppSettings()` exposes 120 / 5 / false.
- Widget tests: pump `SettingsScreen` (or `IntakeSettingsControls` in a harness); assert the "Intake" section renders; tapping `+` on the window row calls `setIntakeWindow(IntakeWindow(135))` and updates the label; `−` disabled at 15 and `+` at 240; grace steps by 5 with bounds; the switch toggles `allowMarkAhead`; a failing repository surfaces the localized error SnackBar and the value label does not change.

**Contracts**:

### Expects
- `SettingsNotifier` mutators exist and use `copyWith` on success (Task 006).
- `IntakeSettingsControls` renders steppers + switch wired to the notifier (Task 008).
- The `_FakeSettingsRepository` fakes already implement the three new methods (Task 004).

### Produces
- Extended provider test + new `intake_settings_controls_test.dart` covering state transitions, stepper bounds, switch, and the error SnackBar.

**Done when**:
- [x] `flutter test test/features/settings/` passes.
- [x] Success/failure state behavior asserted for all three mutators; stepper bounds + switch + SnackBar asserted for the widget.
- [x] Full suite `flutter test` is green and project-wide `dart analyze` is clean.

**Spec criteria addressed**: AC-1, AC-12, AC-13, AC-14, AC-15, AC-17

## Completion Notes
**Status**: Complete
**Completed**: 2026-07-03
**Files changed**: `settings_provider_test.dart` (extended, +10 tests), `intake_settings_controls_test.dart` (new, +14 tests)
**Contract**: Produces [verified — mutator success/failure/errors-stream, default-load AC-1, stepper bounds, switch, failure-leaves-value]
**Code review**: APPROVE (robust row-scoped finders confirmed; additive-only; 2 Info — pre-existing `Future.delayed(Duration.zero)` flush + non-exhaustive unchanged-field check, both optional)
**Verification**: FULL suite 756/756 green; project-wide `dart analyze` clean.
**Notes**: Widget SnackBar failure surface is covered at `settings_screen_test.dart` level; here the widget tests assert value-unchanged-on-failure. Finder subtlety: `find.byTooltip` matches the inner Tooltip, so walk up via `find.ancestor(..., matching: find.byType(IconButton))` to assert `onPressed == null` for disabled bounds.
