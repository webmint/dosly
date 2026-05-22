# Task 002: Update tests to drop theme_preview coverage

**Status**: Complete
**Agent**: qa-engineer
**Files**: `test/widget_test.dart`, `test/core/routing/app_router_test.dart`
**Depends on**: None
**Blocks**: 003
**Context docs**: None
**Review checkpoint**: No

**Description**:
Remove every test reference to the `theme_preview` feature. One widget test
navigates into the preview and asserts theme cycling through it; that test is
deleted (the cycle is independently covered by the Settings use-case, provider,
screen, and theme-selector tests). A second test merely asserts the "Theme
preview" button exists on the home screen; that assertion is removed but the test
itself stays (it still validates the home screen renders). The routing test's
`/theme-preview`-outside-shell case (Test 5 / AC-13) is deleted along with its
import. This task is independent of Task 001 (different files) and can run in
parallel with it.

**Change details**:
- In `test/widget_test.dart`:
  - In the **first** test (`'DoslyApp renders the home screen with app bar, Hello
    World, and Theme preview button'`, lines 65–85): remove the
    `find.widgetWithText(OutlinedButton, 'Theme preview')` assertion (lines 79–82)
    and remove "and Theme preview button" from the test's name string. The
    remaining assertions (`find.text('Hello World')`, `find.text('Dosly')`) stay.
  - Delete the **second** test in its entirety (`'tapping Theme preview navigates
    to the preview and cycling theme mode works'`, lines 87–126).
  - If removing the `OutlinedButton` assertion makes the `OutlinedButton` /
    `Material` imports unused, remove the now-unused import(s) so `dart analyze`
    stays clean. (`material.dart` is almost certainly still needed for other
    symbols; verify before removing.)
- In `test/core/routing/app_router_test.dart`:
  - Remove the import at line 29:
    `import 'package:dosly/features/theme_preview/presentation/screens/theme_preview_screen.dart';`
  - Delete **Test 5** (`'Test 5 (AC-13): /theme-preview renders without the shell
    bottom nav'`, the `testWidgets` block at lines 290–313) and its leading
    comment banner (lines 286–289).
  - Update the file header comment (line 3): remove the clause "and /theme-preview
    rendering outside the shell." Keep the rest (shell topology, tab-tap nav,
    selectedIndex, branch-stack preservation).

## Contracts

### Expects
- `test/widget_test.dart` currently contains two `testWidgets` blocks; the first
  asserts `find.widgetWithText(OutlinedButton, 'Theme preview')`, the second
  contains `find.text('dosly · M3 preview')`.
- `test/core/routing/app_router_test.dart` currently imports
  `theme_preview_screen.dart` and contains a test asserting
  `find.byType(ThemePreviewScreen)`.

### Produces
- `test/widget_test.dart` contains neither `'Theme preview'` nor
  `'dosly · M3 preview'`; the first test still asserts `find.text('Hello World')`
  and `find.text('Dosly')`.
- `test/core/routing/app_router_test.dart` contains neither `ThemePreviewScreen`
  nor `/theme-preview`; remaining tests (shell topology, tab nav, branch-stack,
  errorBuilder) are intact.

**Done when**:
- [x] `widget_test.dart` first test no longer references "Theme preview"; second test deleted; no unused imports introduced.
- [x] `app_router_test.dart` has no `ThemePreviewScreen` import, Test 5 deleted, header comment updated.
- [x] `dart analyze` passes on both files.
- [x] `flutter test` passes (the orphaned `theme_preview` folder still compiles, so the suite is green pre-deletion).

**Spec criteria addressed**: AC-6, AC-7

## Completion Notes

**Completed**: 2026-05-22
**Files changed**: test/widget_test.dart, test/core/routing/app_router_test.dart
**Contract**: Expects [2/2 verified] | Produces [2/2 verified]
**Notes**: `dart analyze` → "No issues found!"; `flutter test` → 226 passed. Code review APPROVE WITH WARNINGS surfaced a §3 dead-code issue: the deleted second test was the only consumer of four `_FakeSettingsRepository` recording getters (`lastSavedMode`, `lastSavedUseSystemTheme`, `savedUseSystemLanguage`, `savedManualLanguage`). `dart analyze` does not flag unused private-class members, so this was caught by review only. Fixed in a repair round (getters + docstring removed; `save*` methods kept for the `SettingsRepository` contract; `initial` ctor param kept — still used by a locale test). Lost theme-cycle coverage is fully retained by test/features/settings/ (use case, provider, screen, theme_selector).
