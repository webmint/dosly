# Task 004: Create AppShell shell scaffold

**Agent**: mobile-engineer
**Files**:
- `lib/core/routing/app_shell.dart` (new)

**Depends on**: 001
**Blocks**: 005
**Review checkpoint**: Yes
**Context docs**: `docs/architecture.md` (§Routing), `specs/007-meds-history-screens/research.md`

## Description

Introduce the first `StatefulShellRoute` consumer in the codebase. Create `AppShell`, a `StatelessWidget` that takes a `StatefulNavigationShell` from go_router and renders the shared tabbed layout: `Scaffold(body: navigationShell, bottomNavigationBar: HomeBottomNav(selectedIndex: navigationShell.currentIndex, onDestinationSelected: navigationShell.goBranch))`. The shell is the go_router ↔ `HomeBottomNav` adapter — it owns the coupling to go_router so that `HomeBottomNav` itself stays router-agnostic and trivially testable.

This task is a review checkpoint because `StatefulShellRoute` is a new pattern in this codebase and `AppShell` will be referenced by the router refactor in Task 005. Getting its shape right here is load-bearing for AC-8, AC-9, AC-10.

## Change details

- Create `lib/core/routing/app_shell.dart`:
  - Library dartdoc describing the shell's role: "Hosts the shared bottom navigation bar for the tabbed branches of [appRouter]'s `StatefulShellRoute`. The sole adapter between go_router's `StatefulNavigationShell` and the feature-scoped [HomeBottomNav]." Include a brief note that this file is allowed to import from `features/home/` because it sits in `lib/core/routing/` — the documented cross-feature composition root (constitution §2.1, `docs/architecture.md` §Routing).
  - Imports: `package:flutter/material.dart`, `package:go_router/go_router.dart`, `../../features/home/presentation/widgets/home_bottom_nav.dart`.
  - `class AppShell extends StatelessWidget` with:
    - `final StatefulNavigationShell navigationShell;`
    - `const AppShell({required this.navigationShell, super.key});`
    - Class-level dartdoc describing the `navigationShell` parameter and the shell's behavior (renders `body: navigationShell` + `HomeBottomNav` wired to the shell's current branch index).
    - `build()` returns:
      ```dart
      Scaffold(
        body: navigationShell,
        bottomNavigationBar: HomeBottomNav(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: navigationShell.goBranch,
        ),
      )
      ```
  - Note: `navigationShell.goBranch` is a method with signature `void goBranch(int index, {bool initialLocation = false})`. Passing it directly as `ValueChanged<int>` works via Dart method tearoff — default-valued named params don't affect tearoff compatibility against a positional-only function type. If `dart analyze` complains, wrap as `(index) => navigationShell.goBranch(index)`.

## Contracts

### Expects
- Task 001 produced `HomeBottomNav` with constructor `const HomeBottomNav({required int selectedIndex, required ValueChanged<int> onDestinationSelected, super.key})`.
- `go_router ^17.2.0` is in `pubspec.yaml` and exports `StatefulNavigationShell` with `currentIndex` (int getter) and `goBranch(int index, {bool initialLocation})` method. (Already true.)

### Produces
- `lib/core/routing/app_shell.dart` exports `class AppShell extends StatelessWidget`.
- `AppShell` has a `const AppShell({required this.navigationShell, super.key})` constructor and a `final StatefulNavigationShell navigationShell;` field.
- `AppShell.build` returns a `Scaffold` whose `body` is exactly `navigationShell` and whose `bottomNavigationBar` is `HomeBottomNav(selectedIndex: navigationShell.currentIndex, onDestinationSelected: <tearoff-or-wrapper-of navigationShell.goBranch>)`.
- `app_shell.dart` imports `home_bottom_nav.dart` (verified: the only cross-feature import from this file).

## Done when

- [x] `AppShell` class created with full dartdoc.
- [x] `dart analyze 2>&1 | head -40` reports no issues on the new file.
- [x] No `!` null-assertions introduced.
- [x] No color literals introduced.

**Spec criteria addressed**: supports AC-8 (single bottom nav hosted here), AC-9 (tap → `goBranch`), AC-10 (`selectedIndex` driven by `currentIndex`). Full verification of these ACs lands in Task 005's integration test.

## Completion Notes

**Completed**: 2026-04-15
**Files changed**: lib/core/routing/app_shell.dart (new, 66 lines)
**Contract**: Expects 2/2 verified | Produces 4/4 verified
**Notes**: Direct `navigationShell.goBranch` tearoff worked — no lambda wrapper needed. Dart subtype rule (function with extra optional named param assignable to function without it) held. dartdoc on library/class/constructor/field all substantive. Not yet wired into router — flutter test still 100/100 pre-existing. Code review: APPROVE (checkpoint passed).

**Status**: Complete
