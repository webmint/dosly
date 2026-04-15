# Task 003: Wire `MaterialApp.router` with i18n delegates

**Agent**: mobile-engineer
**Files**: `lib/app.dart`
**Depends on**: 002
**Blocks**: 004, 005, 006
**Review checkpoint**: Yes (layer crossing — first presentation file to consume generated code; mistakes surface as runtime nulls everywhere)
**Context docs**: None
**Status**: Complete

## Description

Configure `MaterialApp.router` in `DoslyApp` to register Flutter's i18n delegates and the three supported locales exposed by the generated `AppLocalizations` class. No explicit `locale:` override — Flutter's default resolution callback reads the device locale and falls back to English for unsupported locales, which is exactly the behavior the spec requires (§3.2).

This task does not change any rendered strings yet. Widgets still display hard-coded English literals; only the framework plumbing changes. Runtime behavior before + after this task is identical to the user. What it enables is: from this point on, `AppLocalizations.of(context)` returns a non-null value under the widget tree.

## Change details

- In `lib/app.dart`:
  - Add an import for the generated localizations file: `import 'l10n/app_localizations.dart';` (placed alphabetically among the existing `core/` imports — after `core/theme/theme_controller.dart`; import ordering follows Effective Dart).
  - In the `MaterialApp.router(...)` constructor call inside `build()`, add two new named arguments directly after `title: 'dosly',`:
    - `localizationsDelegates: AppLocalizations.localizationsDelegates,`
    - `supportedLocales: AppLocalizations.supportedLocales,`
  - Do NOT pass an explicit `locale:` argument.
  - Do NOT change `title:` — it stays the string literal `'dosly'` (brand name per spec §3.2).
  - Do NOT change `debugShowCheckedModeBanner`, `theme`, `darkTheme`, `themeMode`, or `routerConfig`.
  - Leave the `ListenableBuilder(listenable: themeController, ...)` wrapper unchanged.
  - Update the file's library-level dartdoc (top of file, `/// Application root.` block) with one added sentence noting that locale is auto-resolved from the device via `AppLocalizations.localizationsDelegates` + `supportedLocales`. Keep existing sentences intact.

## Contracts

### Expects
- `lib/l10n/app_localizations.dart` exists and exports `class AppLocalizations` with static `localizationsDelegates` and `supportedLocales` (produced by Task 002).
- `lib/app.dart` contains the existing structure: `import 'package:flutter/material.dart';`, three `core/...` relative imports, `class DoslyApp extends StatelessWidget`, and a `build` method returning `ListenableBuilder(listenable: themeController, builder: (context, _) => MaterialApp.router(...))`.

### Produces
- `lib/app.dart` imports `l10n/app_localizations.dart`.
- `lib/app.dart`'s `MaterialApp.router(...)` invocation contains the literal lines `localizationsDelegates: AppLocalizations.localizationsDelegates,` and `supportedLocales: AppLocalizations.supportedLocales,`.
- `lib/app.dart` does NOT contain a `locale:` argument on `MaterialApp.router`.
- `lib/app.dart` retains `title: 'dosly',` verbatim.
- `dart analyze` is clean.
- `flutter test` passes all pre-existing tests.

## Done when

- [x] `grep "import 'l10n/app_localizations.dart'" lib/app.dart` finds a match.
- [x] `grep 'localizationsDelegates: AppLocalizations.localizationsDelegates' lib/app.dart` finds a match.
- [x] `grep 'supportedLocales: AppLocalizations.supportedLocales' lib/app.dart` finds a match.
- [x] `grep -E "^\s*locale:" lib/app.dart` returns no match (no explicit locale override).
- [x] `grep "title: 'dosly'" lib/app.dart` finds a match (brand name preserved).
- [x] `dart analyze` produces zero warnings or errors.
- [x] `flutter test` passes all pre-existing tests (84 tests).
- [x] `flutter build apk --debug` succeeds.

## Spec criteria addressed
AC-5

## Completion Notes

**Completed**: 2026-04-15
**Files changed**: `lib/app.dart`
**Contract**: Expects 2/2 verified | Produces 6/6 verified
**Notes**: Import added alphabetically after `core/...` imports. Arguments placed grouped together immediately after `title:`. Dartdoc sentence appended without disrupting existing prose. No deviations. Code review APPROVE with no issues.
