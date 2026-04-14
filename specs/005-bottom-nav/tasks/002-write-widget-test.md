# Task 002: Write widget test for HomeBottomNav

**Agent**: qa-engineer
**Files**:
- `test/features/home/presentation/widgets/home_bottom_nav_test.dart` (create)
**Status**: Complete
**Depends on**: 001
**Blocks**: None
**Context docs**: None
**Review checkpoint**: Yes
(Reason: final integration gate for the feature — first full-stack verification that the widget behaves per spec across dart analyze + flutter test + debug APK build.)

## Completion Notes

**Completed**: 2026-04-14
**Files changed**:
- `test/features/home/presentation/widgets/home_bottom_nav_test.dart` (NEW, 82 lines, 5 testWidgets cases + `_harness()` helper)
**Contract**: Expects 2/2 verified | Produces 3/3 verified
**Notes**: `_harness()` returns a `const MaterialApp` — preserves the `const HomeBottomNav()` call-site invariant established in Task 001. Test count: 79 → 84 (added 5). Integration gate clean: `dart analyze` 0 issues, `flutter test` 84/84, `flutter build apk --debug` succeeded. Code review APPROVE with praise notes only.

## Description

Create a widget test file that exercises `HomeBottomNav` in isolation inside a minimal `MaterialApp` + `Scaffold` test harness. The test must verify rendering, labels, selected-index invariant, the no-op tap behavior, and the `alwaysShow` label-behavior setting.

This task is the integration-gate point for the feature — its `Done when` includes `flutter build apk --debug`.

## Change details

### `test/features/home/presentation/widgets/home_bottom_nav_test.dart` (NEW)

Create a Dart test file with:

- Imports: `package:flutter/material.dart`, `package:flutter_test/flutter_test.dart`, `package:lucide_icons_flutter/lucide_icons.dart`, and `package:dosly/features/home/presentation/widgets/home_bottom_nav.dart`.
- A single `void main() { group('HomeBottomNav', () { ... }); }` with these `testWidgets` cases:
  1. **renders exactly 3 NavigationDestinations in Today/Meds/History order**
     - Pump `MaterialApp(home: Scaffold(bottomNavigationBar: const HomeBottomNav(), body: const SizedBox.shrink()))`.
     - Call `pumpAndSettle`.
     - `expect(find.byType(NavigationDestination), findsNWidgets(3));`
     - `expect(find.text('Today'), findsOneWidget);`
     - `expect(find.text('Meds'), findsOneWidget);`
     - `expect(find.text('History'), findsOneWidget);`
  2. **renders the correct Lucide icons**
     - Same harness.
     - `expect(find.byIcon(LucideIcons.house), findsOneWidget);`
     - `expect(find.byIcon(LucideIcons.pill), findsOneWidget);`
     - `expect(find.byIcon(LucideIcons.activity), findsOneWidget);`
  3. **NavigationBar.selectedIndex is 0 on first render**
     - Same harness. Retrieve the widget via `tester.widget<NavigationBar>(find.byType(NavigationBar))` and assert `.selectedIndex == 0`.
  4. **tapping an inactive destination does not change selectedIndex**
     - Same harness.
     - `await tester.tap(find.text('Meds')); await tester.pumpAndSettle();`
     - Re-read the `NavigationBar` and assert `.selectedIndex == 0`.
     - Repeat for `find.text('History')` — `.selectedIndex == 0`.
  5. **labelBehavior is alwaysShow**
     - Retrieve the `NavigationBar` and assert `.labelBehavior == NavigationDestinationLabelBehavior.alwaysShow`.

- No mocks, no `mocktail`, no `setUp/tearDown` hooks (the widget has no state to reset).

## Contracts

### Expects (preconditions)

- `package:dosly/features/home/presentation/widgets/home_bottom_nav.dart` exports `class HomeBottomNav extends StatelessWidget` with a `const HomeBottomNav({super.key})` constructor (produced by Task 001).
- `HomeBottomNav.build` returns a `NavigationBar` with the three destinations in order (produced by Task 001).

### Produces (postconditions)

- `test/features/home/presentation/widgets/home_bottom_nav_test.dart` exists and contains a `group('HomeBottomNav', ...)` with at least 5 `testWidgets(...)` cases covering: three-destination rendering, Lucide icons, `selectedIndex == 0`, tap-is-no-op invariant, and `labelBehavior == alwaysShow`.
- `flutter test` passes with zero failures on the full suite (existing + new tests).
- `flutter build apk --debug` produces a debug APK without errors.

## Done when

- [x] `test/features/home/presentation/widgets/home_bottom_nav_test.dart` exists with the 5 `testWidgets` cases listed in the Change details.
- [x] `dart analyze 2>&1 | head -40` is clean on the new test file.
- [x] `flutter test` passes — all tests green, including the 5 new ones.
- [x] `flutter build apk --debug` succeeds.
- [x] No `!` null-assertion operator in the test file.

## Spec criteria addressed

AC-8, AC-10, AC-11
