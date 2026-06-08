<!-- This file is a fixed-size sliding window. Always fully overwritten, never appended. Max ~40 lines. -->
# Session State

## Current Feature
None active. Last shipped: 025-typed-logger. Most recent work: bug 020 /fix (settings save-error SnackBar coverage).

## Progress
Bug 020 fixed on branch `fix/020-settings-save-error-snackbar-tests` — 1 clean commit (65a9102), local-only, not yet pushed/merged. Feature-022 follow-ups: 018 ✅ (PR #30), 019 ✅ (PR #31), 020 ✅ (this), 021 open (low/corroborative).

## Recently Completed (last 3)
- Bug 020 /fix: +3 widget tests covering setUseSystemLanguage/setThemeMode/setManualLanguage save-error SnackBars — test-only, 289/289 green, review APPROVE-with-warnings (warning investigated + rejected)
- Bug 019 /fix: themeMode AC-2 guarded-exception test (PR #31)
- Bug 018 /fix: realigned settings screen test fake to Failure.unknown (PR #30)

## Recent Decisions
- Bug 020: DropdownButton menu items render off-stage in flutter_test even after pumpAndSettle → find.text throws "No element"; use skipOffstage:false descendant + warnIfMissed:false, with a self-validating assertion (see MEMORY)
- Bug 020: code-reviewer's "prefer pumpAndSettle" warning was empirically rejected via controlled experiment
- Bug 020 fully closed; happy-path interactive coverage already in theme_selector_test/language_selector_test

## Recently Modified Files
- test/features/settings/presentation/screens/settings_screen_test.dart
- bugs/020-...md (→ Fixed), research/2026-06-07-bug-020-save-error-snackbar-coverage.md

## Verification
dart analyze: clean | flutter test: 289 pass
