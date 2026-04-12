# Task 001: Update global AppBarTheme defaults

**Agent**: mobile-engineer
**Files**: `lib/core/theme/app_theme.dart`
**Depends on**: None
**Blocks**: 002
**Context docs**: None
**Review checkpoint**: No

## Description

Update the global `AppBarTheme` in `app_theme.dart` to align with the HTML template's design system. Two changes:

1. Change `backgroundColor` from `scheme.surface` to `scheme.surfaceContainer` — the HTML template uses `--md-surface-container` for all app bars.
2. Add `surfaceTintColor: Colors.transparent` — prevents Flutter's tonal elevation overlay from tinting the background on scroll, so only a shadow appears (matching the HTML where background stays constant and only `box-shadow` is added).

All other `AppBarTheme` properties (`foregroundColor`, `elevation`, `scrolledUnderElevation`, `centerTitle`, `titleTextStyle`) remain unchanged.

## Change details

- In `lib/core/theme/app_theme.dart`:
  - In the `AppBarTheme(...)` constructor inside `_build()`:
    - Change `backgroundColor: scheme.surface,` → `backgroundColor: scheme.surfaceContainer,`
    - Add `surfaceTintColor: Colors.transparent,` (after `backgroundColor` line)

## Contracts

### Expects
- `lib/core/theme/app_theme.dart` contains `AppBarTheme(` with `backgroundColor: scheme.surface,`
- `lib/core/theme/app_color_schemes.dart` defines `surfaceContainer` field on both `lightColorScheme` and `darkColorScheme`

### Produces
- `lib/core/theme/app_theme.dart` contains `backgroundColor: scheme.surfaceContainer,` inside `AppBarTheme(`
- `lib/core/theme/app_theme.dart` contains `surfaceTintColor: Colors.transparent,` inside `AppBarTheme(`

## Done when

- [x] `AppBarTheme.backgroundColor` is `scheme.surfaceContainer`
- [x] `AppBarTheme.surfaceTintColor` is `Colors.transparent`
- [x] No other `AppBarTheme` properties changed
- [x] `dart analyze` passes on `lib/core/theme/app_theme.dart`

**Spec criteria addressed**: AC-4, AC-5

## Completion Notes

**Completed**: 2026-04-12
**Files changed**: `lib/core/theme/app_theme.dart`
**Contract**: Expects 2/2 verified | Produces 2/2 verified
**Notes**: Clean execution, no deviations from plan.
