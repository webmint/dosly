# Task 005: Rewrite widget tests for HomeScreen + navigation flow

**Status**: Complete
**Agent**: qa-engineer
**Files**: `test/widget_test.dart`
**Depends on**: 004
**Blocks**: None
**Context docs**: None
**Review checkpoint**: Yes

## Completion Notes

**Completed**: 2026-04-11
**Files changed**: `test/widget_test.dart` (42 → 60 lines)
**Contract**: Expects 6/6 verified | Produces 8/8 verified
**Integration gates**:
- `dart analyze` project-wide: No issues found
- `flutter test`: all 79 tests passing (2 rewritten widget tests + 77 pre-existing theme_controller_test / app_color_schemes_test / parameterized variants)
- `flutter build apk --debug`: built `build/app/outputs/flutter-apk/app-debug.apk` successfully
**Code review**: APPROVE, no findings
**Notes**: Router navigation through `go_router` → `context.push('/theme-preview')` → preview screen's AppBar works under `flutter_test` with standard `pumpAndSettle` timing — no flakiness observed. Router test-isolation concern (spec Open Q §8 #6) did not materialize: test 2 leaves the router on `/theme-preview` at completion, but test execution order + per-test `pumpWidget(const DoslyApp())` effectively resets router state. If a future test requires clean router state on entry, add `appRouter.go('/')` to `setUp` then.

## Description

Rewrite the two existing tests in `test/widget_test.dart` to match the post-task-004 behavior of `DoslyApp`:

1. **Test 1** previously asserted the app boots into `ThemePreviewScreen` (via `find.text('dosly · M3 preview')`). It must now assert the app boots into `HomeScreen` with `'Hello World'` visible and an `OutlinedButton` labelled `'Theme preview'` present.
2. **Test 2** previously tapped the `'Cycle theme mode'` tooltip button directly (available because the preview screen was the home). Since that button now lives on a screen reached by navigation, test 2 must first tap the `'Theme preview'` `OutlinedButton` to navigate, then assert the preview screen appeared (via its AppBar title), then tap the cycle button three times and assert the same `themeController.value` transitions as before.

Both tests continue to pump `const DoslyApp()`. The `setUp` block resetting `themeController.setMode(ThemeMode.system)` is preserved unchanged. No new test files are created; no new imports are needed (all required imports are already present on `origin/main`).

This task is the integration verification point — after it completes, `flutter test` passes end-to-end for the new routing + HomeScreen wiring.

## Change details

Starting from the current `test/widget_test.dart` (42 lines — read before editing):

- Leave the imports unchanged:
  ```
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';

  import 'package:dosly/app.dart';
  import 'package:dosly/core/theme/theme_controller.dart';
  ```
  No new imports needed. `OutlinedButton` is in `material.dart`; `HomeScreen` does not need to be imported because the test only uses text/widget finders, not the class directly.

- Leave the `setUp` block unchanged:
  ```
  setUp(() {
    themeController.setMode(ThemeMode.system);
  });
  ```

- Replace **test 1** (`'DoslyApp renders the theme preview screen'`) with:
  ```
  testWidgets(
    'DoslyApp renders the home screen with Hello World and a Theme preview button',
    (tester) async {
      await tester.pumpWidget(const DoslyApp());
      await tester.pumpAndSettle();

      expect(find.text('Hello World'), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, 'Theme preview'),
        findsOneWidget,
      );
    },
  );
  ```

- Replace **test 2** (`'cycling theme mode does not throw and updates state'`) with:
  ```
  testWidgets(
    'tapping Theme preview navigates to the preview and cycling theme mode works',
    (tester) async {
      await tester.pumpWidget(const DoslyApp());
      await tester.pumpAndSettle();

      // Navigate from HomeScreen → ThemePreviewScreen via the dev button.
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Theme preview'),
      );
      await tester.pumpAndSettle();

      // Confirm we arrived at the preview screen.
      expect(find.text('dosly · M3 preview'), findsOneWidget);
      expect(find.byTooltip('Cycle theme mode'), findsOneWidget);

      // Cycle once → light
      await tester.tap(find.byTooltip('Cycle theme mode'));
      await tester.pumpAndSettle();
      expect(themeController.value, ThemeMode.light);

      // Cycle again → dark
      await tester.tap(find.byTooltip('Cycle theme mode'));
      await tester.pumpAndSettle();
      expect(themeController.value, ThemeMode.dark);

      // Cycle again → system
      await tester.tap(find.byTooltip('Cycle theme mode'));
      await tester.pumpAndSettle();
      expect(themeController.value, ThemeMode.system);
    },
  );
  ```

- Leave the top-level `void main() { ... }` wrapper intact. Do not add a `tearDown` block. Do not add additional tests.

## Done when

- [x] `test/widget_test.dart` contains exactly two `testWidgets(...)` calls
- [x] Test 1 pumps `const DoslyApp()`, calls `pumpAndSettle()`, and asserts `find.text('Hello World')` finds one widget
- [x] Test 1 also asserts `find.widgetWithText(OutlinedButton, 'Theme preview')` finds one widget
- [x] Test 2 pumps `const DoslyApp()`, calls `pumpAndSettle()`, taps `find.widgetWithText(OutlinedButton, 'Theme preview')`, calls `pumpAndSettle()`
- [x] Test 2 asserts `find.text('dosly · M3 preview')` finds one widget after navigation
- [x] Test 2 then taps `find.byTooltip('Cycle theme mode')` three times with `pumpAndSettle()` between taps and asserts `themeController.value` transitions `system → light → dark → system`
- [x] The `setUp` block still resets `themeController.setMode(ThemeMode.system)`
- [x] No new top-level imports added
- [x] `dart analyze test/widget_test.dart` reports zero diagnostics
- [x] `flutter test` exits 0 — all tests in `test/widget_test.dart`, `test/core/theme/theme_controller_test.dart`, and `test/core/theme/app_color_schemes_test.dart` pass
- [x] `dart analyze` reports zero diagnostics project-wide
- [x] `flutter build apk --debug` completes successfully

## Contracts

### Expects

- `lib/app.dart` uses `MaterialApp.router(routerConfig: appRouter, ...)` and boots the app into `HomeScreen` at `/` (produced by task 004).
- `lib/features/home/presentation/screens/home_screen.dart` renders `'Hello World'` and an `OutlinedButton` with text `'Theme preview'` whose `onPressed` calls `context.push('/theme-preview')` (produced by task 002).
- `lib/core/routing/app_router.dart` registers `/` → `HomeScreen` and `/theme-preview` → `ThemePreviewScreen` (produced by task 003).
- `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` (unchanged from `origin/main`) has an `AppBar` with title `'dosly · M3 preview'` and an `IconButton` with tooltip `'Cycle theme mode'` whose `onPressed` is `themeController.cycle`.
- `lib/core/theme/theme_controller.dart` exports a top-level `final ThemeController themeController` with `.value` of type `ThemeMode` and a `.setMode(ThemeMode)` method and a `.cycle()` method.
- `test/widget_test.dart` pre-task state has two tests asserting the old preview-screen home behavior.

### Produces

- `test/widget_test.dart` source contains exactly two `testWidgets(` calls.
- Test 1 source contains the literal strings `find.text('Hello World')` and `find.widgetWithText(OutlinedButton, 'Theme preview')`.
- Test 2 source contains the literal strings `tester.tap(find.widgetWithText(OutlinedButton, 'Theme preview'))`, `find.text('dosly · M3 preview')`, `find.byTooltip('Cycle theme mode')`, `ThemeMode.light`, `ThemeMode.dark`, `ThemeMode.system`.
- `test/widget_test.dart` source still contains the `setUp(() { themeController.setMode(ThemeMode.system); });` block.
- `test/widget_test.dart` source does NOT contain any reference to the old test name `'DoslyApp renders the theme preview screen'` or the old test behavior that tapped the cycle button without navigating first.
- `flutter test` exits 0.
- `flutter build apk --debug` exits 0.
- `dart analyze` exits 0 project-wide.

## Spec criteria addressed

- AC-7 (exact strings `'Hello World'` and `'Theme preview'` verified via `find.text` / `find.widgetWithText`)
- AC-11 (widget test 1 asserts HomeScreen content)
- AC-12 (widget test 2 navigates then cycles)
- AC-13 (dart analyze clean project-wide — final verification)
- AC-14 (flutter test passes — final verification)
- AC-15 (flutter build apk --debug succeeds — final verification)
- AC-16 (no `print`/`!`/`dynamic`)
- AC-18 (manual simulator verification — deferred to `/verify`, not executed here)

## Notes

- **This is the integration gate**: task 005's `flutter test` and `flutter build apk --debug` checks are the first point at which the full new routing + `HomeScreen` + rewritten tests are exercised end-to-end. If either fails, the root cause is likely in tasks 002, 003, or 004 — not in task 005's test authoring. Self-repair loop in `/execute-task` Phase 3 should diagnose before re-running.
- **Review checkpoint: Yes** — this is the only review checkpoint in the breakdown. The user should verify the tests read naturally and that `flutter test` / `flutter build apk --debug` are green before the breakdown is declared complete.
- **Router state isolation** (spec Open Q §8 #6): because `appRouter` is a top-level `final`, its navigation stack persists across widget tests. Test 1 does not navigate (stays on `/`). Test 2 navigates to `/theme-preview` and does not explicitly pop. In principle test 2 could leave the router at `/theme-preview`, which would break a hypothetical test 3 that expects to start at `/`. This breakdown has only two tests and test execution order is not guaranteed by `flutter_test`, so the risk is: if tests run test 2 first then test 1, test 1 would find both `/theme-preview`'s content AND not find `'Hello World'` (because `HomeScreen` is beneath the preview in the stack but not visible). If this flakes in practice, the fix is to add `appRouter.go('/')` to `setUp`. Not doing it preemptively — defer until observed.
- **Cycling coverage is not lost**: `test/core/theme/theme_controller_test.dart` has 8 unit tests covering `ThemeController` cycling (`system→light`, `light→dark`, `dark→system`, three-cycle round-trip, `setMode`, notification, default value). Test 2's cycling assertions are integration-level redundancy on top of that unit coverage, not primary coverage.
- **No new imports needed**: `OutlinedButton` is in `flutter/material.dart` which is already imported. `HomeScreen` is not referenced by name (only by finder predicates), so no import of the home screen file. `ThemePreviewScreen` is not referenced by name either. Do not add imports "to be safe".
- **Do not add `tearDown`**: the `setUp` block resets `themeController.setMode(ThemeMode.system)` before each test, which is sufficient. Adding `tearDown` is premature and out of scope.
