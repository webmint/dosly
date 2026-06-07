# Bug 020: `settings_screen_test.dart` exercises only 1 of 4 save-error SnackBar paths

**Status**: Open
**Severity**: Warning
**Source**: fix (bug 018 — Phase 7 test assessment)
**Feature**: specs/014-surface-settings-errors/spec.md (error-SnackBar feature)
**AC**: N/A (test-coverage gap, not an AC failure)
**Reported**: 2026-06-07
**Fixed**:

## Description

`_FakeSettingsRepository` in the settings screen test exposes four per-method
failure flags — `failOnSaveThemeMode`, `failOnSaveUseSystemTheme`,
`failOnSaveUseSystemLanguage`, `failOnSaveManualLanguage` — but only
`failOnSaveUseSystemTheme` is exercised by a test (the single
"shows localized error SnackBar when setUseSystemTheme fails" case). The other
three save-error paths have no widget test asserting that a failed save surfaces
the localized error SnackBar.

This is a **pre-existing** gap (it predates bug 018; bug 018 only realigned the
fake's failure payload from the stale `CacheFailure` to `Failure.unknown`). It
was surfaced by the qa-engineer during the bug 018 `/fix` test-assessment phase
and deliberately deferred to keep that fix to its single-file scope.

The screen handler (`settings_screen.dart`) is payload-agnostic — `ref.listen`
→ `next.whenData((_) { showSnackBar(static localized string) })` — so all four
paths share one code path. The risk of the gap is low, but coverage of all four
trigger points guards against a future regression where one mutator forgets to
route its failure onto `settingsErrorsProvider`.

## File(s)

| File | Detail |
|------|--------|
| test/features/settings/presentation/screens/settings_screen_test.dart | Only `failOnSaveUseSystemTheme` is exercised (~line 213); `failOnSaveThemeMode`, `failOnSaveUseSystemLanguage`, `failOnSaveManualLanguage` are declared but never triggered by a test |

## Evidence

Reported by code-reviewer (Info) and qa-engineer during bug 018 `/fix`:

> The fake exposes four `failOnSaveX` flags but only `failOnSaveUseSystemTheme`
> is exercised (line ~213). The other three — `failOnSaveThemeMode`,
> `failOnSaveUseSystemLanguage`, `failOnSaveManualLanguage` — are untested error
> paths. This gap predates bug 018 and is not introduced or widened by it.

## Fix Notes

Add three `testWidgets` cases to the `SettingsScreen error SnackBar` group,
following the exact pattern of the existing case: set the corresponding
`failOnSaveX` flag, tap the control that triggers that mutator, pump for the
SnackBar to enter, and assert
`find.text("Couldn't save your preference. Please try again.")`. Identify the
right control per path:
- `failOnSaveThemeMode` → the theme-mode control
- `failOnSaveUseSystemLanguage` → the "use system language" SwitchListTile
- `failOnSaveManualLanguage` → the manual language selector

Trivial, single-file. Candidate for `/fix` or a small coverage task.

## Related Issues

- bug 018 (the fidelity fix during whose test assessment this gap was surfaced)
- specs/014-surface-settings-errors (added the error-stream + SnackBar feedback)
