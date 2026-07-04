# Task 003: Extend AppSettings with 3 fields + amend constitution §5.1

**Agent**: architect
**Files**: `lib/features/settings/domain/entities/app_settings.dart` (+ regen `app_settings.freezed.dart`), `constitution.md`
**Depends on**: 001
**Blocks**: 004, 006
**Context docs**: `specs/039-intake-settings/data-model.md`
**Review checkpoint**: No

**Description**:
Add the three intake preferences to the `@freezed` `AppSettings` entity with const defaults, and record the model change in the constitution. `allowMarkAhead` is not in the constitution's §5.1 Settings enumeration — add it (additive amendment) and note that the two numerics are now represented by the `IntakeWindow`/`GracePeriod` value objects rather than bare ints.

**Change details**:
- In `lib/features/settings/domain/entities/app_settings.dart`:
  - Import `../value_objects/intake_window.dart` and `../value_objects/grace_period.dart`.
  - In the `const factory AppSettings({...})`, add:
    - `@Default(IntakeWindow.defaultValue) IntakeWindow intakeWindow,`
    - `@Default(GracePeriod.defaultValue) GracePeriod gracePeriod,`
    - `@Default(false) bool allowMarkAhead,`
  - Update the class dartdoc to describe the three new fields.
  - Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `app_settings.freezed.dart`.
- In `constitution.md` §5.1 (the `Settings` row of the entities table):
  - Add `allowMarkAhead` (default `false`) to the enumerated fields.
  - Add a short note that `intakeWindowMinutes`/`gracePeriodMinutes` are modeled as the `IntakeWindow` (15–240) and `GracePeriod` (0–30) value objects.

**Contracts**:

### Expects
- `IntakeWindow`/`GracePeriod` exist with `static const defaultValue` (Task 001).
- `AppSettings` is a `@freezed` class whose `const factory AppSettings({...})` currently has exactly the four `@Default` fields (`useSystemTheme`, `manualThemeMode`, `useSystemLanguage`, `manualLanguage`).

### Produces
- `app_settings.dart` factory contains `@Default(IntakeWindow.defaultValue) IntakeWindow intakeWindow`, `@Default(GracePeriod.defaultValue) GracePeriod gracePeriod`, and `@Default(false) bool allowMarkAhead`.
- `app_settings.dart` imports both VO files.
- `constitution.md` §5.1 `Settings` text contains `allowMarkAhead`.

**Done when**:
- [x] `const AppSettings()` yields `intakeWindow == IntakeWindow(120)`, `gracePeriod == GracePeriod(5)`, `allowMarkAhead == false`, with the four existing defaults unchanged.
- [x] `app_settings.freezed.dart` regenerates cleanly (no build_runner errors).
- [x] `constitution.md` §5.1 mentions `allowMarkAhead` and the VO representation.
- [x] `dart analyze` passes on the entity file.

**Spec criteria addressed**: AC-1

## Completion Notes
**Status**: Complete
**Completed**: 2026-07-03
**Files changed**: `lib/features/settings/domain/entities/app_settings.dart` (+ regen `.freezed.dart`), `constitution.md`
**Contract**: Expects [verified] | Produces [all verified — 3 @Default fields, VO imports, constitution amended]
**Code review**: APPROVE (no issues; const-default legality validated by reviewer)
**Notes**: build_runner (newer version) deletes conflicting outputs by default — `--delete-conflicting-outputs` now ignored, regen still clean. Class dartdoc updated to say "seven" fields.
