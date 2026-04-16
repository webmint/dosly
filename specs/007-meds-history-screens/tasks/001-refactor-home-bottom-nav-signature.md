# Task 001: Refactor HomeBottomNav to accept selectedIndex + onDestinationSelected

**Agent**: mobile-engineer
**Files**:
- `lib/features/home/presentation/widgets/home_bottom_nav.dart`
- `lib/features/home/presentation/screens/home_screen.dart`
- `test/features/home/presentation/widgets/home_bottom_nav_test.dart`
- `test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart`

**Depends on**: None
**Blocks**: 004, 005
**Review checkpoint**: No
**Context docs**: `docs/features/home.md`

## Description

Convert `HomeBottomNav` from inert presentational widget to a router-agnostic widget whose `selectedIndex` and `onDestinationSelected` are supplied externally. Remove the top-level `_noop(int _)` function — with the new required parameters it is no longer needed. Cascade the signature change to its only production call site (`home_screen.dart`) by removing the `bottomNavigationBar: const HomeBottomNav()` line entirely — the future shell (Task 004) will re-introduce the bar at the shell level, so `HomeScreen` temporarily renders without a bottom nav between tasks 001 and 005. Update both existing widget tests to inject `selectedIndex` and a recording `onDestinationSelected` callback, and replace the "tap is a no-op" invariant with "tap invokes the callback with the correct index".

This is a coordinated signature migration: all four files change together so `dart analyze` and `flutter test` remain green at task-end. Without the cascade, the widget change alone would break both the `home_screen.dart` call site and the test files' `const HomeBottomNav()` constructors.

## Change details

- In `lib/features/home/presentation/widgets/home_bottom_nav.dart`:
  - Delete the top-level `void _noop(int _) {}` function and its dartdoc.
  - Add two required fields to `HomeBottomNav`: `final int selectedIndex;` and `final ValueChanged<int> onDestinationSelected;`.
  - Change the constructor to `const HomeBottomNav({required this.selectedIndex, required this.onDestinationSelected, super.key});`.
  - In `build()`, replace the hard-coded `selectedIndex: 0` with `selectedIndex: selectedIndex` and replace `onDestinationSelected: _noop` with `onDestinationSelected: onDestinationSelected`.
  - Update the library dartdoc: drop "is intentionally inert", "hard-coded at 0", "no-op" phrasing; replace with a description of the router-agnostic contract (takes `selectedIndex` + `onDestinationSelected` from its parent — typically the routing shell).
  - Update the class dartdoc similarly — document the new constructor parameters.

- In `lib/features/home/presentation/screens/home_screen.dart`:
  - Delete the `bottomNavigationBar: const HomeBottomNav(),` line from the `Scaffold`.
  - Delete the `import '../widgets/home_bottom_nav.dart';` line (no longer referenced here).
  - Update the class-level dartdoc: remove the paragraph describing the "three-destination `HomeBottomNav` sits in the bottom-navigation-bar slot…". Replace it with a one-line note that the bottom navigation bar is now provided by the routing shell (`lib/core/routing/app_shell.dart`) at the app level, not by `HomeScreen`.

- In `test/features/home/presentation/widgets/home_bottom_nav_test.dart`:
  - Change `_harness()` to accept optional parameters `{int selectedIndex = 0, ValueChanged<int>? onDestinationSelected}` and pass them into `HomeBottomNav(selectedIndex: selectedIndex, onDestinationSelected: onDestinationSelected ?? (_) {})`. The `HomeBottomNav` call inside the `Scaffold.bottomNavigationBar` must use the (non-const) constructor with those args.
  - Keep all existing test cases that verify destinations/icons/labelBehavior/divider unchanged — they only need the new constructor signature to compile.
  - Replace the "NavigationBar.selectedIndex is 0 on first render" test with a parametric version: when `selectedIndex` is 1, `NavigationBar.selectedIndex == 1`; when 2, `== 2`. (One test that pumps the harness with each index and asserts the rendered `NavigationBar.selectedIndex`.)
  - Replace the "tapping an inactive destination does not change selectedIndex" test with: "tapping a destination invokes `onDestinationSelected` with the tapped index". Collect invocations into a list; pump with `onDestinationSelected: indices.add`; tap "Meds" → expect `[1]`; tap "History" → expect `[1, 2]`.

- In `test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart`:
  - Change the `_harness({required Locale locale})` call to `HomeBottomNav(selectedIndex: 0, onDestinationSelected: (_) {})` at the bottomNavigationBar slot (drop the outer `const` on `Scaffold` if necessary).
  - Leave the locale loop and assertions unchanged — they only check rendered label text.

## Contracts

### Expects
- `lib/features/home/presentation/widgets/home_bottom_nav.dart` exists and declares `class HomeBottomNav extends StatelessWidget`.
- `lib/features/home/presentation/screens/home_screen.dart` currently contains the string `bottomNavigationBar: const HomeBottomNav()`.
- `lib/l10n/l10n_extensions.dart` exports the `context.l10n` extension (unchanged).

### Produces
- `lib/features/home/presentation/widgets/home_bottom_nav.dart` declares `const HomeBottomNav({required this.selectedIndex, required this.onDestinationSelected, super.key})` with `final int selectedIndex` and `final ValueChanged<int> onDestinationSelected` fields.
- `lib/features/home/presentation/widgets/home_bottom_nav.dart` does **not** contain the identifier `_noop`.
- `lib/features/home/presentation/screens/home_screen.dart` does **not** contain the substring `HomeBottomNav` or `home_bottom_nav.dart`.
- `test/features/home/presentation/widgets/home_bottom_nav_test.dart` compiles and all test cases pass. Its assertions cover: `selectedIndex` pass-through (tested with values 0/1/2), `onDestinationSelected` callback invocation with the correct index, icon identity, label count, `labelBehavior.alwaysShow`, and 1-px divider presence.
- `test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart` compiles and all three locale cases pass.

## Done when

- [x] `HomeBottomNav` constructor requires `selectedIndex` and `onDestinationSelected`; `_noop` is removed.
- [x] `HomeScreen` no longer imports or references `HomeBottomNav`.
- [x] `home_bottom_nav_test.dart` asserts `selectedIndex` pass-through and `onDestinationSelected` invocation with the tapped index.
- [x] `home_bottom_nav_l10n_test.dart` still passes across en/de/uk/fr-fallback.
- [x] `dart analyze 2>&1 | head -40` reports no issues on the four changed files.
- [x] `flutter test test/features/home/` passes (all HomeBottomNav tests green).
- [x] Root `test/widget_test.dart` still passes — it asserts `Hello World`, `Theme preview` button, and `Dosly` title in `DoslyApp`; none of those reference `HomeBottomNav`.

**Spec criteria addressed**: supports AC-8, AC-9, AC-10 (widget is now controllable by a shell), AC-12 (HomeScreen still renders settings + theme preview — only the bottom nav line is removed).

## Completion Notes

**Completed**: 2026-04-15
**Files changed**: lib/features/home/presentation/widgets/home_bottom_nav.dart, lib/features/home/presentation/screens/home_screen.dart, test/features/home/presentation/widgets/home_bottom_nav_test.dart, test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart
**Contract**: Expects 3/3 verified | Produces 5/5 verified
**Notes**: Clean execution, no surprises. Outer `Scaffold` in test harnesses lost `const` as expected (NavigationBar has no const constructor). `HomeBottomNav` constructor itself remains `const`-capable — simply can't be exercised at shell call sites with runtime `navigationShell.currentIndex`. 11/11 tests pass. Code review: APPROVE (no issues).

**Status**: Complete
