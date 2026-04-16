# Task 003: Create HistoryScreen + widget test

**Agent**: mobile-engineer
**Files**:
- `lib/features/history/presentation/screens/history_screen.dart` (new)
- `test/features/history/presentation/screens/history_screen_test.dart` (new)

**Depends on**: None
**Blocks**: 005
**Review checkpoint**: No
**Context docs**: `docs/features/home.md`

## Description

Mechanical mirror of Task 002 for the History feature. Create a presentation-only `HistoryScreen` with the same `Scaffold` + `AppBar` (title, 1-px divider, no actions) + `SizedBox.shrink()` body shape, differing only in the localized title key (`bottomNavHistory` instead of `bottomNavMeds`) and the feature folder name. The widget test mirrors the Meds test with History's expected strings.

## Change details

- Create `lib/features/history/presentation/screens/history_screen.dart`:
  - Identical shape to `meds_screen.dart` from Task 002, substituting:
    - Class name: `HistoryScreen` (both the class and `const HistoryScreen({super.key})` constructor).
    - Title: `Text(context.l10n.bottomNavHistory)`.
    - Library + class dartdoc adjusted to describe the history feature (placeholder for future adherence-history content; currently empty body).

- Create `test/features/history/presentation/screens/history_screen_test.dart`:
  - Identical shape to `meds_screen_test.dart` from Task 002, substituting the expected strings:
    - English "History".
    - German "Verlauf".
    - Ukrainian "Історія".
    - French fallback → "History".
  - The AppBar-shape assertions (no actions, 1-px divider) are identical.

## Contracts

### Expects
- ARB files have `bottomNavHistory` translations: English "History", German "Verlauf", Ukrainian "Історія". (Already true.)
- `lib/l10n/l10n_extensions.dart` exports `context.l10n` extension. (Already true.)

### Produces
- `lib/features/history/presentation/screens/history_screen.dart` exports `class HistoryScreen extends StatelessWidget` with `const HistoryScreen({super.key})` constructor.
- `HistoryScreen.build` returns a `Scaffold` whose `AppBar.title` is `Text(context.l10n.bottomNavHistory)`, whose `AppBar.bottom` is a `PreferredSize` wrapping a `Divider`, and whose `AppBar.actions` is absent.
- `HistoryScreen.build` returns a `Scaffold` whose `body` is `const SizedBox.shrink()`.
- `test/features/history/presentation/screens/history_screen_test.dart` exists and all cases (en/de/uk/fr-fallback + no-actions + 1-px divider) pass.

## Done when

- [x] `HistoryScreen` file created with dartdoc and compiles.
- [x] Widget test covers all four locales plus the AppBar-shape assertions.
- [x] `dart analyze 2>&1 | head -40` reports no issues on the two new files.
- [x] `flutter test test/features/history/` passes.

**Spec criteria addressed**: AC-2 (creates the screen; Task 005 wires the route), AC-4 (localized title), AC-5 (1-px divider), AC-6 (no actions), AC-7 (empty body), AC-14 (French fallback).

## Completion Notes

**Completed**: 2026-04-15
**Files changed**: lib/features/history/presentation/screens/history_screen.dart (new), test/features/history/presentation/screens/history_screen_test.dart (new)
**Contract**: Expects 2/2 verified | Produces 4/4 verified
**Notes**: Mechanical mirror of Task 002. 6/6 tests pass. Code review: APPROVE.

**Status**: Complete
