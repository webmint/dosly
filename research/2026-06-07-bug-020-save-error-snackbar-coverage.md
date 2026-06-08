# Research: Bug 020 — only 1 of 4 save-error SnackBar paths tested

**Date**: 2026-06-07
**Topic**: `settings_screen_test.dart` exercises only 1 of 4 save-error SnackBar paths
**Verdict**: **Feasible — single-file `/fix` (test-only), with multi-step interaction nuance**

## Summary

A genuine (not corroborative) coverage gap. `SettingsScreen` surfaces a localized SnackBar whenever any of the four `setX` mutators fails to persist, but the screen test exercises only the `saveUseSystemTheme` path (tap the first `SwitchListTile`). The other three — `saveUseSystemLanguage`, `saveThemeMode`, `saveManualLanguage` — have no test. The fix is three added widget tests in one file, no production change. The catch: **two of the three controls are disabled until a prerequisite toggle is turned off**, so those tests need multi-step interactions (toggle off → then act), plus the finicky `SegmentedButton`/`DropdownButton` tap patterns. The fake already supports per-method failure flags, so isolating "prerequisite save succeeds, target save fails" is straightforward.

## Codebase Findings

### How each save path is triggered (the load-bearing detail)

| Save path | Control | Trigger | Tested? |
|---|---|---|---|
| `saveUseSystemTheme` | `ThemeSelector` `SwitchListTile` (**1st** on screen) | tap toggle | yes (existing test) |
| `saveUseSystemLanguage` | `LanguageSelector` `SwitchListTile` (**2nd/last**) | tap toggle (`find.byType(SwitchListTile).last`) | **simple** — untested |
| `saveThemeMode` | `ThemeSelector` `SegmentedButton` (Light/Dark) | **disabled while "use system theme" is ON** → must toggle system-theme OFF first, then tap the **Dark** segment | **multi-step** — untested |
| `saveManualLanguage` | `LanguageSelector` `DropdownButton<AppLanguage>` | **disabled while "use device language" is ON** → must toggle device-language OFF first, then open dropdown + pick a different language | **multi-step** — untested |

### Patterns Available
- **Per-method failure isolation**: the existing `_FakeSettingsRepository` exposes `failOnSaveThemeMode / failOnSaveUseSystemTheme / failOnSaveUseSystemLanguage / failOnSaveManualLanguage`. Set **only** the target flag → the prerequisite toggle-off save (`setUseSystemTheme`/`setUseSystemLanguage`) succeeds and enables the disabled control, then the target action fails and emits the SnackBar.
- **Existing test as template**: the `setUseSystemTheme fails` test (tap → `pump()` → `pump(100ms)` for SnackBar enter → assert `find.text("Couldn't save your preference. Please try again.")`) is the exact shape to copy for the simple `saveUseSystemLanguage` case.
- **Error routing confirmed**: every `setX` mutator folds `(failure) => _errors.add(failure)` (`settings_provider.dart:108-188`); the screen's `ref.listen(settingsErrorsProvider, … whenData(showSnackBar))` fires for any post-build save failure (a listener is mounted), so all three paths are reachable and assert the same static string.

### Gaps / nuances the implementer must handle
- **`saveThemeMode`**: after toggling system-theme OFF, `manualThemeMode` is pre-filled to the device brightness (light in tests), so the **Dark** segment is the unselected one — tap **Dark** (tapping the already-selected Light won't fire `onSelectionChanged`).
- **`saveManualLanguage`**: `DropdownButton` renders selected items in a hidden `IndexedStack` plus the open menu, so a chosen `nativeName` (e.g. `'Deutsch'`) can match twice — use `find.text('Deutsch').last` and `pumpAndSettle` around open/select. Pick a language != the post-toggle default (`en`).
- These two are the only real authoring effort; the `saveUseSystemLanguage` case is a 5-line copy of the existing test with `.last`.

## Constitution Constraints

| Rule | Impact |
|------|--------|
| §3.4 Testing — screens with logic get widget tests; verify side effects | Directly on-point: this completes the screen's error-surfacing coverage across all four mutators. |
| §3.4 "honest test naming" | Name each test for the specific mutator path it drives. |
| §6.1 Minimal changes | Single test file; **no production change**. |
| §3.2/4.2.1 (no real DB, no `Future.delayed`) | Use `pump`/`pumpAndSettle` for SnackBar/menu timing, never `sleep` (existing test already does). |

## Complexity Assessment

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Codebase changes | **Low–Medium** | 3 tests, 1 file. One is trivial; two need multi-step interaction + finicky `SegmentedButton`/`Dropdown` taps. |
| New dependencies | **None** | Reuses the existing `_harness` + per-method fake flags. |
| Risk | **Low** | Test-only, no production logic touched. Main risk is flaky widget-finder/timing on the dropdown — mitigated by `.last` + `pumpAndSettle`. |

## Recommendation

**Use `/fix`, not `/specify`.** Single-file, test-only, no architectural decisions. It's the highest-value of the three feature-022 follow-ups (real gap, not corroborative like bug 021). Worth doing so a regression in any one mutator's error-surfacing is caught.

```
Next steps:
- To fix now:  /fix "Bug 020 — add 3 widget tests to the 'SettingsScreen error SnackBar' group in settings_screen_test.dart covering the untested save-error paths: (1) saveUseSystemLanguage — tap the 2nd/last SwitchListTile (simple copy of the existing test); (2) saveThemeMode — toggle the 1st SwitchListTile OFF (failOnSaveUseSystemTheme=false) then tap the Dark SegmentedButton segment (failOnSaveThemeMode=true); (3) saveManualLanguage — toggle the last SwitchListTile OFF (failOnSaveUseSystemLanguage=false) then open the DropdownButton and select Deutsch (failOnSaveManualLanguage=true). Each asserts the localized SnackBar 'Couldn't save your preference. Please try again.' appears. Test-only, no production change; use pumpAndSettle + find.text(...).last for the dropdown."
- To shelve: no action needed (Warning; the shared SnackBar code path is already proven by the existing useSystemTheme test).
```

One note for the `/fix`: because two paths require the prerequisite toggle-off to **succeed**, set only the single target `failOnSaveX` flag per test — the existing per-method fake already makes this clean.

## Related Issues

- bug 018 (the fix during whose test assessment this gap was surfaced — fixed 2026-06-07, PR #30)
- bug 019, bug 021 (same feature-022 follow-up batch)
- specs/014-surface-settings-errors (added the error-stream + SnackBar feedback)
- specs/022-settings-error-containment (widened save failures to `Failure.unknown`)
