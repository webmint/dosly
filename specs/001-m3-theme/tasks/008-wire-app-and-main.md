# Task 008: Wire DoslyApp, replace main.dart, replace smoke test

**Agent**: mobile-engineer
**Files**:
- `lib/app.dart` *(create)*
- `lib/main.dart` *(replace)*
- `test/widget_test.dart` *(replace)*

**Depends on**: 004 (themeController), 005 (AppTheme), 007 (ThemePreviewScreen)
**Blocks**: None — final task
**Review checkpoint**: Yes — convergence point AND layer-boundary crossing AND highest stakes (replaces app entry point)
**Context docs**: None

## Description

Final wiring task. Three files change in lockstep:

1. `lib/app.dart` — `DoslyApp` widget that wraps `MaterialApp` in a `ListenableBuilder` driven by `themeController`. Sets `theme: AppTheme.lightTheme`, `darkTheme: AppTheme.darkTheme`, `themeMode: themeController.value`, `home: ThemePreviewScreen()`.

2. `lib/main.dart` — counter boilerplate is gone. New body is exactly: `import 'package:flutter/material.dart'; import 'app.dart'; void main() => runApp(const DoslyApp());`

3. `test/widget_test.dart` — counter test is gone. New test pumps `DoslyApp`, finds the preview-screen app bar title, and verifies the cycle action does not throw.

This task is the convergence point. Once it lands, `flutter run` produces the dosly preview screen on a real device.

## Change details

- Create `lib/app.dart`:
  - `import 'package:flutter/material.dart';`
  - `import 'core/theme/app_theme.dart';`
  - `import 'core/theme/theme_controller.dart';`
  - `import 'features/theme_preview/presentation/screens/theme_preview_screen.dart';`
  - File header dartdoc: "Application root. Wraps `MaterialApp` in a `ListenableBuilder` so the entire tree rebuilds when `themeController.value` changes."
  - Class `DoslyApp extends StatelessWidget`:
    - `const DoslyApp({super.key});`
    - `build` returns:
      ```dart
      ListenableBuilder(
        listenable: themeController,
        builder: (context, _) => MaterialApp(
          title: 'dosly',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeController.value,
          home: const ThemePreviewScreen(),
        ),
      )
      ```
  - Add `///` dartdoc on `DoslyApp`.

- Replace `lib/main.dart` (delete current 122 lines). New content:
  ```dart
  import 'package:flutter/material.dart';

  import 'app.dart';

  void main() {
    runApp(const DoslyApp());
  }
  ```
  - The `WidgetsFlutterBinding.ensureInitialized()` call is NOT needed yet — no async work in this spec.

- Replace `test/widget_test.dart` (delete current counter test). New content:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';

  import 'package:dosly/app.dart';
  import 'package:dosly/core/theme/theme_controller.dart';

  void main() {
    setUp(() {
      // Reset the singleton between tests so we don't carry state across.
      themeController.setMode(ThemeMode.system);
    });

    testWidgets('DoslyApp renders the theme preview screen', (tester) async {
      await tester.pumpWidget(const DoslyApp());
      await tester.pumpAndSettle();

      expect(find.text('dosly · M3 preview'), findsOneWidget);
    });

    testWidgets('cycling theme mode does not throw and updates the icon', (tester) async {
      await tester.pumpWidget(const DoslyApp());
      await tester.pumpAndSettle();

      // Initial: system → auto icon
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
    });
  }
  ```
  - The `setUp` resets the singleton because the smoke test mutates it; without reset, the second `pumpWidget` in another test file could carry over state.
  - Tests use `Icons` finders only via tooltip — `find.byIcon` would also work but tooltip is more semantic.

- After all three files are written, run:
  - `dart analyze` — must be clean
  - `flutter test` — all tests across the project must pass (Tasks 002, 004 tests + this task's smoke test)

## Manual verification (AC-13)

After `flutter test` passes, the implementer must run the app on both platforms and visually confirm:

1. `flutter run -d ios` (or `open -a Simulator` first to boot iOS Simulator)
   - Theme preview renders correctly in light mode (default if simulator is in light mode)
   - Tap the app-bar cycle button → app switches to manual light, then dark, then system
   - All color swatches are visible and labelled
   - All typography samples render in Roboto
   - All component widgets render without overflow
2. `flutter run -d android` (Android Emulator must be running)
   - Same checks as above
3. Capture a screenshot of each platform via `flutter screenshot` (one in light mode, one in dark mode) and save to `specs/001-m3-theme/screenshots/{ios,android}-{light,dark}.png` for `/verify` to reference.

If any visual issue appears that requires code changes, STOP and report to the user — do not silently fix beyond the spec scope.

## Done when

- [x] `lib/app.dart` exists with `class DoslyApp extends StatelessWidget`
- [x] `lib/main.dart` is exactly the 7-line replacement above (no counter, no `MyApp`)
- [x] `test/widget_test.dart` is replaced with the smoke + cycle tests above
- [x] `dart analyze` reports zero issues across `lib/` and `test/`
- [x] `flutter test` passes (79/79 — 70 color schemes + 7 theme controller + 2 smoke)
- [ ] Manual: `flutter run -d ios` launches the preview screen and the cycle action works *(deferred to user — see Completion Notes)*
- [ ] Manual: `flutter run -d android` launches the preview screen and the cycle action works *(deferred to user)*
- [ ] Manual: screenshots captured to `specs/001-m3-theme/screenshots/` *(deferred to user)*

## Spec criteria addressed

AC-7, AC-8, AC-12 (smoke test portion), AC-13 *(automated portion satisfied; manual cross-platform run deferred)*

## Completion Notes

**Status**: Complete *(automated verification — manual cross-platform run is deferred to the user)*
**Completed**: 2026-04-11
**Files changed**:
- `lib/app.dart` (created — 34 lines)
- `lib/main.dart` (replaced — counter boilerplate → 7-line entry point)
- `test/widget_test.dart` (replaced — counter test → smoke + cycle tests)

**Contract**: Expects 4/4 verified | Produces 9/9 verified

**Verification**:
- `dart analyze`: PASS (zero issues)
- `flutter test`: 79/79 PASS (70 color schemes + 7 theme controller + 2 new widget tests)
- Forbidden strings (`MyApp`, `MyHomePage`, `_counter`, `_incrementCounter`, `Counter increments smoke test`) all gone
- Code review verdict: **APPROVE** (review checkpoint cleared)

**Notes**:
- Final convergence task. App now boots into `ThemePreviewScreen` via `DoslyApp` with full M3 theming.
- AC-13 manual run on iOS/Android is the user's responsibility — sandbox cannot drive simulators. The widget tests in `widget_test.dart` exercise the same compilation pipeline so failures would surface there.
- `lib/main.dart` includes `import 'package:flutter/material.dart';` which is technically unused at the symbol level (only `app.dart` is referenced) but conventional for Flutter entry points; analyzer does not flag it.
- 0 deviations from spec. Files written verbatim.

## Contracts

### Expects
- `lib/core/theme/app_theme.dart` exports `class AppTheme` with static getters `lightTheme` and `darkTheme` (produced by Task 005)
- `lib/core/theme/theme_controller.dart` exports `themeController` (produced by Task 004)
- `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` exports `class ThemePreviewScreen` (produced by Task 007)
- `pubspec.yaml` declares Roboto fonts (produced by Task 001) — required for the manual run to look correct, though tests pass without it

### Produces
- File `lib/app.dart` exists
- It declares `class DoslyApp extends StatelessWidget`
- It contains the literal string `ListenableBuilder` referencing `themeController`
- It contains `theme: AppTheme.lightTheme`, `darkTheme: AppTheme.darkTheme`, `themeMode: themeController.value`
- It contains `home: const ThemePreviewScreen()`
- File `lib/main.dart` exists and contains exactly one top-level function `void main()` whose body is `runApp(const DoslyApp());`
- The literal strings `class MyApp`, `class MyHomePage`, `_counter`, `_incrementCounter` do NOT appear anywhere under `lib/`
- File `test/widget_test.dart` exists and imports `package:dosly/app.dart`
- It contains a `testWidgets('DoslyApp renders the theme preview screen', ...)`
- It contains a `testWidgets('cycling theme mode does not throw and updates the icon', ...)`
- The literal string `Counter increments smoke test` does NOT appear in `test/widget_test.dart`
