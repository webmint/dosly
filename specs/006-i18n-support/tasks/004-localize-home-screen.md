# Task 004: Localize `HomeScreen` literals

**Agent**: mobile-engineer
**Files**: `lib/features/home/presentation/screens/home_screen.dart`
**Depends on**: 003
**Blocks**: None
**Review checkpoint**: No
**Context docs**: None
**Status**: Complete

## Description

Replace the single hard-coded English literal on `HomeScreen` that the spec marks translatable (`'Settings'` IconButton tooltip) with a lookup through the generated `AppLocalizations`. The AppBar brand title `'Dosly'`, the placeholder body `'Hello World'` Text, and the dev-only `'Theme preview'` button label stay as hard-coded literals — the spec explicitly excludes all three from translation.

## Change details

- In `lib/features/home/presentation/screens/home_screen.dart`:
  - Add an import for the generated localizations file at the top of the file, alongside the existing imports: `import '../../../../l10n/app_localizations.dart';` (relative path from `lib/features/home/presentation/screens/` up to `lib/l10n/`).
  - Inside `build(BuildContext context)`:
    - Replace the `IconButton`'s `tooltip: 'Settings'` argument with `tooltip: AppLocalizations.of(context)!.settingsTooltip`.
  - Leave untouched:
    - `AppBar`'s `title: const Text('Dosly')` (brand name — stays hard-coded; keeps `const`).
    - The body `const Text('Hello World')` (temporary placeholder — stays hard-coded; keeps `const`).
    - The `OutlinedButton`'s `child: const Text('Theme preview')` (dev-only; scheduled for post-MVP removal — stays hard-coded; keeps `const`).
  - Use the `AppLocalizations.of(context)!` inline at the single call site rather than a local `l` binding — with only one lookup, the inline form is more readable and avoids introducing an otherwise-unused local. This is the single sanctioned `!` usage, documented in spec §7.

## Contracts

### Expects
- `lib/app.dart` has `localizationsDelegates: AppLocalizations.localizationsDelegates` wired on `MaterialApp.router` (produced by Task 003). This guarantees `AppLocalizations.of(context)!` resolves at runtime under `HomeScreen`.
- `lib/features/home/presentation/screens/home_screen.dart` currently contains the literal `'Settings'` as an `IconButton` tooltip.
- `lib/l10n/app_localizations.dart` exposes a getter `settingsTooltip`.

### Produces
- `home_screen.dart` imports `../../../../l10n/app_localizations.dart`.
- `home_screen.dart` contains the literal expression `AppLocalizations.of(context)!.settingsTooltip` exactly once.
- `home_screen.dart` does NOT contain the standalone string literal `'Settings'` as an `IconButton` tooltip (verified by absence of `tooltip: 'Settings'`).
- `home_screen.dart` retains the literal `'Dosly'` (AppBar title), `'Hello World'` (body placeholder — unchanged because the spec excludes it), and `'Theme preview'` (button label).
- `dart analyze` is clean.
- `flutter test` passes.

## Done when

- [x] `grep "import '../../../../l10n/app_localizations.dart'" lib/features/home/presentation/screens/home_screen.dart` finds a match.
- [x] `grep "AppLocalizations.of(context)!.settingsTooltip" lib/features/home/presentation/screens/home_screen.dart` finds a match.
- [x] `grep "tooltip: 'Settings'" lib/features/home/presentation/screens/home_screen.dart` returns no match.
- [x] `grep "'Dosly'" lib/features/home/presentation/screens/home_screen.dart` finds a match (brand preserved).
- [x] `grep "'Hello World'" lib/features/home/presentation/screens/home_screen.dart` finds a match (placeholder preserved).
- [x] `grep "'Theme preview'" lib/features/home/presentation/screens/home_screen.dart` finds a match (dev label preserved).
- [x] `dart analyze` produces zero warnings or errors.
- [x] `flutter test` passes all tests (pre-existing 84; no `HomeScreen` widget test exists today to break).
- [x] `flutter build apk --debug` succeeds.

## Spec criteria addressed
AC-6

## Completion Notes

**Completed**: 2026-04-15
**Files changed**: `lib/features/home/presentation/screens/home_screen.dart`
**Contract**: Expects 3/3 verified | Produces 6/6 verified
**Notes**: Single-line tooltip change + one relative import. Inlined `AppLocalizations.of(context)!.settingsTooltip` (no `l` local — only one call site). Out-of-scope literals (`'Dosly'`, `'Hello World'`, `'Theme preview'`) preserved. Code review APPROVE with no issues.
