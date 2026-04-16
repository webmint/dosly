# Task 002: Create MedsScreen + widget test

**Agent**: mobile-engineer
**Files**:
- `lib/features/meds/presentation/screens/meds_screen.dart` (new)
- `test/features/meds/presentation/screens/meds_screen_test.dart` (new)

**Depends on**: None
**Blocks**: 005
**Review checkpoint**: No
**Context docs**: `docs/features/home.md` (as the AppBar-shape reference)

## Description

Create the Meds screen — a presentation-only `StatelessWidget` at `lib/features/meds/presentation/screens/meds_screen.dart` that renders a `Scaffold` with an `AppBar` (localized title from `context.l10n.bottomNavMeds`, no `actions`, a 1-px bottom `Divider`) and an empty body (`SizedBox.shrink()`). Add a widget test that verifies the title renders correctly across English/German/Ukrainian and falls back to English for unsupported locales (matching the `home_bottom_nav_l10n_test.dart` pattern). The screen is not wired into the router in this task — Task 005 does that. The screen stands alone as a reachable `const MedsScreen()` widget.

## Change details

- Create `lib/features/meds/presentation/screens/meds_screen.dart`:
  - Library dartdoc describing the feature (placeholder screen for future medication-list content; currently empty body).
  - Imports: `package:flutter/material.dart`, the project's `context.l10n` extension via `../../../../l10n/l10n_extensions.dart`.
  - `class MedsScreen extends StatelessWidget` with `const MedsScreen({super.key})` and full dartdoc on the class (what it renders, why the body is empty).
  - `build()` returns:
    ```dart
    Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.bottomNavMeds),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: const SizedBox.shrink(),
    )
    ```
  - No `actions`. No `bottomNavigationBar` (shell provides it).

- Create `test/features/meds/presentation/screens/meds_screen_test.dart`:
  - Copy the `_resolveLocale` helper and `_harness({required Locale locale})` pattern from `test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart`, adapted to pump `MedsScreen` as `home:` (or inside a `Scaffold`-free `MaterialApp` with `home: const MedsScreen()`).
  - Register `AppLocalizations.localizationsDelegates` + `supportedLocales` + `localeResolutionCallback: _resolveLocale`.
  - Test cases:
    1. Renders "Meds" under `Locale('en')`.
    2. Renders "Medikamente" under `Locale('de')`.
    3. Renders "Ліки" under `Locale('uk')`.
    4. Falls back to "Meds" under `Locale('fr')` (unsupported).
    5. `AppBar` has no `actions`: `expect(tester.widget<AppBar>(find.byType(AppBar)).actions, anyOf(isNull, isEmpty))`.
    6. A `Divider` with `height == 1 && thickness == 1` is rendered as descendant of the `AppBar` (regression guard for AC-5).

## Contracts

### Expects
- `lib/l10n/app_localizations.dart` exports `AppLocalizations` with getter `bottomNavMeds` and delegates `localizationsDelegates` + `supportedLocales`. (Already true — spec 006 landed.)
- `lib/l10n/l10n_extensions.dart` exports `extension AppLocalizationsContext on BuildContext` with getter `l10n`. (Already true.)
- ARB files have `bottomNavMeds` translations: English "Meds", German "Medikamente", Ukrainian "Ліки". (Already true.)

### Produces
- `lib/features/meds/presentation/screens/meds_screen.dart` exports `class MedsScreen extends StatelessWidget` with `const MedsScreen({super.key})` constructor.
- `MedsScreen.build` returns a `Scaffold` whose `AppBar.title` is `Text(context.l10n.bottomNavMeds)`, whose `AppBar.bottom` is a `PreferredSize` wrapping a `Divider`, and whose `AppBar.actions` is absent (null/not declared).
- `MedsScreen.build` returns a `Scaffold` whose `body` is `const SizedBox.shrink()`.
- `test/features/meds/presentation/screens/meds_screen_test.dart` exists and all cases (en/de/uk/fr-fallback + no-actions + 1-px divider) pass.

## Done when

- [x] `MedsScreen` file created with dartdoc and compiles.
- [x] Widget test covers all four locales plus the AppBar-shape assertions.
- [x] `dart analyze 2>&1 | head -40` reports no issues on the two new files.
- [x] `flutter test test/features/meds/` passes.

**Spec criteria addressed**: AC-1 (creates the screen; Task 005 wires the route), AC-3 (localized title), AC-5 (1-px divider pattern), AC-6 (no actions), AC-7 (empty body), AC-14 (French fallback).

## Completion Notes

**Completed**: 2026-04-15
**Files changed**: lib/features/meds/presentation/screens/meds_screen.dart (new), test/features/meds/presentation/screens/meds_screen_test.dart (new)
**Contract**: Expects 3/3 verified | Produces 4/4 verified
**Notes**: Clean. 6/6 tests pass. Explicit `Divider(height: 1, thickness: 1)` needed so the AppBar-shape regression guard matches (bare `Divider()` stores null). No `color:` passed — theme default resolves correctly. Code review: APPROVE.

**Status**: Complete
