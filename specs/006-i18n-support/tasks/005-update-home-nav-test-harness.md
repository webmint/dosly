# Task 005: Register delegates in `home_bottom_nav_test` harness

**Agent**: qa-engineer
**Files**: `test/features/home/presentation/widgets/home_bottom_nav_test.dart`
**Depends on**: 003
**Blocks**: 006
**Review checkpoint**: No
**Context docs**: None
**Status**: Complete

## Description

Update the existing `_harness()` helper in `home_bottom_nav_test.dart` to register `AppLocalizations.localizationsDelegates` and `supportedLocales` on its inner `MaterialApp`. This is a prerequisite change that must land BEFORE Task 006 replaces the widget's hard-coded strings — otherwise the harness would render a widget that calls `AppLocalizations.of(context)!` with no delegates registered, throwing a null-assertion error and breaking all five existing tests.

After this task, the harness can render the widget under the default English locale (no `locale:` override needed — `MaterialApp` resolves to `en` in widget tests when no device locale is set). Existing `find.text('Today'/'Meds'/'History')` assertions continue to pass because the widget is still rendering hard-coded English literals at this point; they will continue to pass after Task 006 because English ARB values match the old literals verbatim.

## Change details

- In `test/features/home/presentation/widgets/home_bottom_nav_test.dart`:
  - Add an import for the generated localizations file: `import 'package:dosly/l10n/app_localizations.dart';` (use the `package:` form in test files — test files live outside `lib/` and cannot use relative imports into `lib/`).
  - Inside the existing `_harness()` helper (the function that returns the `MaterialApp` under test):
    - Add `localizationsDelegates: AppLocalizations.localizationsDelegates,` and `supportedLocales: AppLocalizations.supportedLocales,` as named arguments on the `MaterialApp` constructor.
    - If the harness's `MaterialApp` was previously `const`, drop the `const` — `localizationsDelegates` is a runtime list and cannot appear in a const expression. Inner widgets (`Scaffold`, `SizedBox.shrink()`, etc.) keep their existing `const` where they had it.
  - Do NOT change any of the existing five `testWidgets` cases.
  - Do NOT change the `find.text('Today'|'Meds'|'History')` assertions.
  - Do NOT add a `locale:` override — let `MaterialApp` resolve to English by default (its behavior in widget tests).

## Contracts

### Expects
- `lib/app.dart` wires `AppLocalizations.localizationsDelegates` (produced by Task 003) — confirms the import path `package:dosly/l10n/app_localizations.dart` resolves and the class is stable.
- `test/features/home/presentation/widgets/home_bottom_nav_test.dart` currently exists with a `_harness()` helper that returns a `MaterialApp` wrapping `HomeBottomNav`, and with existing `testWidgets` cases asserting on `find.text('Today'|'Meds'|'History')`.
- `HomeBottomNav` still renders hard-coded English literals `'Today'`, `'Meds'`, `'History'` (Task 006 changes this, but this task lands first).

### Produces
- `home_bottom_nav_test.dart` imports `package:dosly/l10n/app_localizations.dart`.
- The `_harness()` helper's `MaterialApp` includes both `localizationsDelegates: AppLocalizations.localizationsDelegates` and `supportedLocales: AppLocalizations.supportedLocales`.
- The `_harness()` helper's outer `MaterialApp` is NOT marked `const` (but inner widgets retain `const` where they had it previously).
- All five pre-existing `testWidgets` cases in this file still pass unchanged.
- `dart analyze` is clean.
- `flutter test test/features/home/presentation/widgets/home_bottom_nav_test.dart` passes.

## Done when

- [x] `grep "import 'package:dosly/l10n/app_localizations.dart'" test/features/home/presentation/widgets/home_bottom_nav_test.dart` finds a match.
- [x] `grep "localizationsDelegates: AppLocalizations.localizationsDelegates" test/features/home/presentation/widgets/home_bottom_nav_test.dart` finds a match.
- [x] `grep "supportedLocales: AppLocalizations.supportedLocales" test/features/home/presentation/widgets/home_bottom_nav_test.dart` finds a match.
- [x] `grep -E "locale:\s*Locale" test/features/home/presentation/widgets/home_bottom_nav_test.dart` returns no match (no explicit locale override).
- [x] `dart analyze` produces zero warnings or errors.
- [x] `flutter test test/features/home/presentation/widgets/home_bottom_nav_test.dart` passes all five pre-existing cases.
- [x] `flutter test` (full suite) passes all 84 pre-existing tests.

## Spec criteria addressed
AC-8 (prepares harness so Task 006 does not break existing assertions)

## Completion Notes

**Completed**: 2026-04-15
**Files changed**: `test/features/home/presentation/widgets/home_bottom_nav_test.dart`
**Contract**: Expects 3/3 verified | Produces 6/6 verified
**Notes**: Added `AppLocalizations` import; registered delegates + supportedLocales on outer `MaterialApp`; moved `const` from outer to inner `Scaffold`. All 6 pre-existing testWidgets cases pass unchanged. (Note: file had 6 cases, not the 5 originally estimated in spec — minor count mismatch, no functional impact.) Code review APPROVE with no issues.
