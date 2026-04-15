# Task 006: Localize `HomeBottomNav` destination labels

**Agent**: mobile-engineer
**Files**: `lib/features/home/presentation/widgets/home_bottom_nav.dart`
**Depends on**: 003, 005
**Blocks**: 007
**Review checkpoint**: No
**Context docs**: None
**Status**: Complete

## Description

Replace the three hard-coded English destination labels (`'Today'`, `'Meds'`, `'History'`) in `HomeBottomNav` with lookups through the generated `AppLocalizations`. The outer `const HomeBottomNav({super.key})` constructor stays `const` (widget instance is still compile-time constant at the call site). The three `NavigationDestination` children lose their `const` because their `label:` argument is now a runtime `BuildContext` lookup — this is an unavoidable `const` downgrade documented in spec §3.4 and acknowledged in MEMORY.md (constitution §4.1.1 exception).

Task 005 has already updated the widget test harness to register `AppLocalizations` delegates, so the existing five `testWidgets` cases continue to pass after this task (English ARB values match the prior hard-coded literals verbatim: `Today`/`Meds`/`History`).

## Change details

- In `lib/features/home/presentation/widgets/home_bottom_nav.dart`:
  - Add an import for the generated localizations file: `import '../../../../l10n/app_localizations.dart';` (relative path from `lib/features/home/presentation/widgets/` up to `lib/l10n/`). Place alphabetically: `flutter/material.dart` first, then the relative l10n import, then `lucide_icons_flutter/...`. Confirm against Effective Dart import ordering (dart:, package:, relative — within each group, alphabetical).
  - Inside `build(BuildContext context)`:
    - Near the top of the method (before the `return Column(...)` call), introduce a local: `final l = AppLocalizations.of(context)!;`.
    - Drop the `const` keyword on the `<NavigationDestination>[...]` list literal at line 48 — the list can no longer be const because its children's labels are runtime values.
    - On each of the three `NavigationDestination(...)` constructor calls (lines 49–60), the outer expression is no longer `const` (inherits non-const from the list). The `icon: Icon(LucideIcons.xxx)` child stays — it can still be `const Icon(LucideIcons.xxx)` to preserve const-ness at the leaf (add `const` prefix to each `Icon(...)` explicitly now that the outer `const` no longer covers them).
    - Replace `label: 'Today'` with `label: l.bottomNavToday`.
    - Replace `label: 'Meds'` with `label: l.bottomNavMeds`.
    - Replace `label: 'History'` with `label: l.bottomNavHistory`.
  - Preserve:
    - The outer `const HomeBottomNav({super.key})` constructor.
    - The top-level `void _noop(int _) {}` function and its dartdoc.
    - The `const Divider(height: 1, thickness: 1)` at the top of the `Column`'s children list.
    - The library dartdoc at the top of the file (no content changes required — the widget's stated behavior is unchanged).
    - `NavigationBar` remains non-const (as it always was per MEMORY.md — `NavigationBar` has no `const` constructor).
- Maintain exactly one `!` null-assertion (on `AppLocalizations.of(context)!`) — this is the sanctioned exception. No other `!` introduced.

## Contracts

### Expects
- `lib/app.dart` has `localizationsDelegates: AppLocalizations.localizationsDelegates` wired (Task 003).
- `lib/l10n/app_localizations.dart` exposes getters `bottomNavToday`, `bottomNavMeds`, `bottomNavHistory` (Task 002).
- `test/features/home/presentation/widgets/home_bottom_nav_test.dart`'s `_harness()` has been updated to register the delegates (Task 005) — otherwise the existing five tests would fail in the window between this task landing and the harness update.
- `lib/features/home/presentation/widgets/home_bottom_nav.dart` currently contains the literals `'Today'`, `'Meds'`, `'History'` as `NavigationDestination` labels.

### Produces
- `home_bottom_nav.dart` imports `../../../../l10n/app_localizations.dart`.
- `home_bottom_nav.dart` contains the literal expression `AppLocalizations.of(context)!` exactly once (bound to local `l`).
- `home_bottom_nav.dart` contains the literal tokens `l.bottomNavToday`, `l.bottomNavMeds`, `l.bottomNavHistory` (one occurrence of each).
- `home_bottom_nav.dart` does NOT contain the standalone string literals `'Today'`, `'Meds'`, or `'History'` (verified by grep on each).
- `home_bottom_nav.dart` retains the literal source `const HomeBottomNav({super.key})` (outer widget const-ness preserved).
- `home_bottom_nav.dart` retains the literal source `void _noop(int _) {}` (top-level no-op preserved).
- `home_bottom_nav.dart` retains the literal source `const Divider(height: 1, thickness: 1)`.
- `dart analyze` is clean (no `prefer_const_constructors` warning on the `NavigationDestination` children, since they provably cannot be const — the analyzer recognizes this).
- `flutter test` passes all tests (including the five pre-existing `home_bottom_nav_test.dart` cases, which assert English strings).

## Done when

- [x] `grep "import '../../../../l10n/app_localizations.dart'" lib/features/home/presentation/widgets/home_bottom_nav.dart` finds a match.
- [x] `grep "AppLocalizations.of(context)!" lib/features/home/presentation/widgets/home_bottom_nav.dart` finds exactly one match.
- [x] `grep "l.bottomNavToday" lib/features/home/presentation/widgets/home_bottom_nav.dart` finds a match.
- [x] `grep "l.bottomNavMeds" lib/features/home/presentation/widgets/home_bottom_nav.dart` finds a match.
- [x] `grep "l.bottomNavHistory" lib/features/home/presentation/widgets/home_bottom_nav.dart` finds a match.
- [x] `grep -F "'Today'" lib/features/home/presentation/widgets/home_bottom_nav.dart` returns no match.
- [x] `grep -F "'Meds'" lib/features/home/presentation/widgets/home_bottom_nav.dart` returns no match.
- [x] `grep -F "'History'" lib/features/home/presentation/widgets/home_bottom_nav.dart` returns no match.
- [x] `grep "const HomeBottomNav({super.key})" lib/features/home/presentation/widgets/home_bottom_nav.dart` finds a match (outer const preserved).
- [x] `grep "void _noop" lib/features/home/presentation/widgets/home_bottom_nav.dart` finds a match.
- [x] `grep "const Divider(height: 1, thickness: 1)" lib/features/home/presentation/widgets/home_bottom_nav.dart` finds a match.
- [x] `dart analyze` produces zero warnings or errors.
- [x] `flutter test test/features/home/presentation/widgets/home_bottom_nav_test.dart` passes all five pre-existing cases (English default).
- [x] `flutter test` (full suite) passes all 84 pre-existing tests.
- [x] `flutter build apk --debug` succeeds.

## Spec criteria addressed
AC-7, AC-8 (joint with Task 005)

## Completion Notes

**Completed**: 2026-04-15
**Files changed**: `lib/features/home/presentation/widgets/home_bottom_nav.dart`
**Contract**: Expects 4/4 verified | Produces 10/10 verified
**Notes**: Three label lookups via `final l = AppLocalizations.of(context)!;` (single sanctioned `!`). Dropped `const` from destinations list; pushed `const` down to each `Icon(LucideIcons.xxx)` to preserve leaf-level const-ness. `_noop`, `Divider`, `HomeBottomNav` constructor all preserved. Code review APPROVE with no issues.
