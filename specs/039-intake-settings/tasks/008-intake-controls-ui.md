# Task 008: Build the Intake settings controls + wire into SettingsScreen

**Agent**: mobile-engineer
**Files**: `lib/features/settings/presentation/widgets/intake_settings_controls.dart` (new), `lib/features/settings/presentation/screens/settings_screen.dart`
**Depends on**: 006, 007
**Blocks**: 011
**Context docs**: `docs/features/settings.md`
**Review checkpoint**: Yes

**Description**:
Add a new "Intake" section to the Settings screen: two −/+ stepper rows (intake window, grace period) and a switch (allow mark-ahead), reading current values from `settingsNotifierProvider` and writing through its new mutators. Extract one file-private reusable stepper row (`_IntakeStepperTile`) used by both numeric rows (DRY — two real consumers); use `SwitchListTile` for the bool. Persistence failures already surface via the existing `settingsErrorsProvider` SnackBar wired in `SettingsScreen`.

**Change details**:
- In `intake_settings_controls.dart`:
  - `IntakeSettingsControls extends ConsumerWidget`.
  - Watch `settingsNotifierProvider` (select the three fields).
  - `_IntakeStepperTile` (private): props `label`, `description`, `valueLabel` (via `context.l10n.settingsMinutesValue(minutes)`), `onDecrement`, `onIncrement`, `decrementEnabled`, `incrementEnabled`; − / + `IconButton`s with the localized tooltips.
  - Intake-window row: value = `settings.intakeWindow.minutes`; `+` → `setIntakeWindow(IntakeWindow(minutes + 15))`, `−` → `IntakeWindow(minutes - 15)`; `−` disabled at `IntakeWindow.minMinutes` (15), `+` at `IntakeWindow.maxMinutes` (240).
  - Grace row: step 5; `−` disabled at `GracePeriod.minMinutes` (0), `+` at `GracePeriod.maxMinutes` (30).
  - Mark-ahead: `SwitchListTile` bound to `settings.allowMarkAhead` → `setAllowMarkAhead(value)`.
  - Read/write via `ref.read(settingsNotifierProvider.notifier)`.
- In `settings_screen.dart`:
  - After the Language section, add a `settingsIntakeHeader` section header (same `labelSmall`/primary/uppercase style as the existing headers) followed by `const IntakeSettingsControls()` padded like the other sections.

**Contracts**:

### Expects
- `SettingsNotifier` exposes `setIntakeWindow`/`setGracePeriod`/`setAllowMarkAhead` and `AppSettings` carries the three fields (Task 006).
- l10n keys `settingsIntakeHeader`, `settingsMinutesValue`, the labels/descriptions, and the stepper tooltips exist (Task 007).
- `IntakeWindow`/`GracePeriod` expose `minMinutes`/`maxMinutes` (Task 001).
- `SettingsScreen` already listens to `settingsErrorsProvider` for the failure SnackBar.

### Produces
- `intake_settings_controls.dart` declares `class IntakeSettingsControls` reading `settingsNotifierProvider` and calling `setIntakeWindow`/`setGracePeriod`/`setAllowMarkAhead`.
- `settings_screen.dart` references `settingsIntakeHeader` and `IntakeSettingsControls`.

**Done when**:
- [x] The Settings screen shows an "Intake" section after Language with the two steppers and the switch, reflecting current `AppSettings` values.
- [x] Window `+` goes 120→135 and persists; `−` decrements by 15; `−` disabled at 15, `+` at 240. Grace steps by 5, disabled at 0 (`−`) / 30 (`+`). Switch toggles `allowMarkAhead`.
- [x] A persistence failure surfaces the existing localized SnackBar and the displayed value does not change (inherent — notifier only updates state on success).
- [x] `dart analyze` passes on both files.

**Spec criteria addressed**: AC-13, AC-14, AC-15

## Completion Notes
**Status**: Complete
**Completed**: 2026-07-03
**Files changed**: `intake_settings_controls.dart` (new), `settings_screen.dart`; **repair**: `settings_screen_test.dart` (finder re-scope)
**Contract**: Produces [verified — `IntakeSettingsControls` reads provider + calls 3 mutators; screen references `settingsIntakeHeader` + widget]
**Code review**: APPROVE (1 Warning: 3× section-header DRY — FIXED by extracting `_SectionHeader`)
**Verification**: project-wide analyze clean; full suite 681/681 green.
**Notes**: (1) Adding a 3rd `SwitchListTile` broke `find.byType(SwitchListTile).last` in 2 language-switch tests (MEMORY F035 recurrence) → repaired to `find.descendant(of: LanguageSelector, ...)`. (2) Post-review DRY cleanup: extracted file-private `_SectionHeader` used by all 3 sections.
