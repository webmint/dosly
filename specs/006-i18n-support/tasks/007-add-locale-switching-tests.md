# Task 007: Add locale-switching widget tests for `HomeBottomNav`

**Agent**: qa-engineer
**Files**: `test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart` (new)
**Depends on**: 006
**Blocks**: None
**Review checkpoint**: Yes (final verification convergence — closes AC-9/11, gates the feature for `/verify`)
**Context docs**: None
**Status**: Complete

## Description

Create a new widget test file that exercises `HomeBottomNav`'s locale behavior. Three `testWidgets` cases pump the widget under German, Ukrainian, and an unsupported locale (French) respectively, asserting the translated labels render for the first two and that the English fallback renders for the third. This directly covers AC-9 and completes the feature's test coverage.

The file stands on its own — it does NOT import or depend on the existing `home_bottom_nav_test.dart`'s helpers. Keeping them separate lets each file own a single purpose (existing: structural/behavioral tests under default locale; new: locale-resolution tests) and avoids coupling that would complicate future test additions.

## Change details

- Create `test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart`.
- File structure:
  - Imports:
    - `import 'package:flutter/material.dart';`
    - `import 'package:flutter_test/flutter_test.dart';`
    - `import 'package:dosly/l10n/app_localizations.dart';`
    - `import 'package:dosly/features/home/presentation/widgets/home_bottom_nav.dart';`
  - A top-level helper `Widget _harness({required Locale locale})` that returns a `MaterialApp` wrapping `HomeBottomNav` with:
    - `locale: locale` (explicit override — this is the control knob the test uses to force a specific locale)
    - `localizationsDelegates: AppLocalizations.localizationsDelegates`
    - `supportedLocales: AppLocalizations.supportedLocales`
    - A `Scaffold(bottomNavigationBar: const HomeBottomNav())` as the `home:` (mirroring production placement).
  - A `main()` function with a single `group('HomeBottomNav locale switching', () { ... })` containing three `testWidgets` cases:
    1. `'renders German labels under Locale("de")'` — pumps `_harness(locale: Locale('de'))`, calls `await tester.pumpAndSettle()`, then asserts `find.text('Heute')`, `find.text('Medikamente')`, `find.text('Verlauf')` each evaluate to `findsOneWidget`.
    2. `'renders Ukrainian labels under Locale("uk")'` — pumps `_harness(locale: Locale('uk'))`, then asserts `find.text('Сьогодні')`, `find.text('Ліки')`, `find.text('Історія')` each evaluate to `findsOneWidget`.
    3. `'falls back to English for unsupported Locale("fr")'` — pumps `_harness(locale: Locale('fr'))`, then asserts `find.text('Today')`, `find.text('Meds')`, `find.text('History')` each evaluate to `findsOneWidget`. (Verifies the spec §3.2 fallback behavior.)
- Use `const Locale('de')` / `const Locale('uk')` / `const Locale('fr')` (the `Locale` constructor is const).
- Each `testWidgets` body should `await tester.pumpWidget(_harness(locale: ...))` then `await tester.pumpAndSettle()` before assertions, to ensure the `AppLocalizations` delegate has resolved asynchronously on first pump.
- No mocks or fakes required — the generated `AppLocalizations` subclasses provide the values directly.

## Contracts

### Expects
- `HomeBottomNav` (at `lib/features/home/presentation/widgets/home_bottom_nav.dart`) reads its three labels through `AppLocalizations.of(context)!` (produced by Task 006).
- `AppLocalizations` subclasses for `en`, `de`, `uk` exist at `lib/l10n/app_localizations_{en,de,uk}.dart` (produced by Task 002) and return the expected string values per spec §3.3.
- Flutter's default `localeResolutionCallback` maps `Locale('fr')` to English (since `fr` is not in `supportedLocales`) — confirmed by spec §3.2 and Flutter documentation.

### Produces
- `test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart` exists.
- The file defines a `main()` function containing a `group` with three `testWidgets` cases named `'renders German labels under Locale("de")'`, `'renders Ukrainian labels under Locale("uk")'`, and `'falls back to English for unsupported Locale("fr")'`.
- Running `flutter test test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart` exits with code 0 and all three cases pass.
- Running `flutter test` (full suite) passes all pre-existing tests (84) PLUS the three new cases = 87 total.
- `dart analyze` is clean.

## Done when

- [x] `test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart` exists.
- [x] `grep "group('HomeBottomNav locale switching'" test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart` finds a match.
- [x] `grep "Locale('de')" test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart` finds a match.
- [x] `grep "Locale('uk')" test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart` finds a match.
- [x] `grep "Locale('fr')" test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart` finds a match.
- [x] `grep "find.text('Heute')" test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart` finds a match.
- [x] `grep "find.text('Сьогодні')" test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart` finds a match.
- [x] `grep "find.text('Today')" test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart` finds a match.
- [x] `flutter test test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart` passes all three cases.
- [x] `flutter test` (full suite) passes — all 84 pre-existing + 3 new = 87 tests.
- [x] `dart analyze` produces zero warnings or errors.
- [x] `flutter build apk --debug` succeeds.

## Spec criteria addressed
AC-5 (update), AC-9, AC-10, AC-11, AC-12

## Completion Notes

**Completed**: 2026-04-15
**Files changed**:
- `test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart` (new)
- `lib/app.dart` (modified mid-task — scope expansion, see Notes)
- `specs/006-i18n-support/spec.md` (§3.2 and AC-5 updated to reflect the discovered fallback policy)
**Contract**: Expects 3/3 verified | Produces 5/5 verified (plus `_resolveLocale` function added to production)
**Notes**:
- **Scope expansion**: During test execution, the qa-engineer agent discovered that Flutter's default locale resolution does NOT fall back to English when `supportedLocales` doesn't start with English. `gen_l10n` emits `[Locale('de'), Locale('en'), Locale('uk')]` alphabetically; Flutter's default `BasicLocaleListResolutionCallback` returns the first entry for unsupported locales — so `fr` resolved to German, contradicting spec §3.2 and AC-9.
- **Fix**: added a top-level `_resolveLocale` function in `lib/app.dart` and wired it as `localeResolutionCallback` on `MaterialApp.router`. The function matches by `languageCode` and falls back to `const Locale('en')`. The test harness in the new file includes a local copy of the same function so tests exercise the same fallback path as production.
- **Spec updates**: §3.2 now explicitly documents the callback and the "Flutter default is not sufficient" discovery; AC-5 now mentions the callback.
- **Test count**: 85 → 88 (3 new cases).
- Code review APPROVE with two Info items (duplicated `_resolveLocale` between production and test — 2 copies is allowed per DRY rule; spec doc drift flagged — addressed by spec updates above).
- All verification clean: `dart analyze` no issues, `flutter test` 88/88, `flutter build apk --debug` success.
