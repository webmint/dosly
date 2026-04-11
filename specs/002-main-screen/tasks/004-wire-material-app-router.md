# Task 004: Swap MaterialApp for MaterialApp.router in DoslyApp

**Status**: Complete
**Agent**: mobile-engineer
**Files**: `lib/app.dart`
**Depends on**: 003
**Blocks**: 005
**Context docs**: None
**Review checkpoint**: No

## Completion Notes

**Completed**: 2026-04-11
**Files changed**: `lib/app.dart` (34 → 36 lines; imports swapped, `MaterialApp` → `MaterialApp.router`, dartdoc rewritten)
**Contract**: Expects 4/4 verified | Produces 11/11 verified
**Verification**: `dart analyze lib/app.dart` clean (no `unused_import`), project-wide `dart analyze` clean. `flutter test` intentionally NOT run — existing tests still assert on `ThemePreviewScreen` and will fail until task 005.
**Code review**: APPROVE, no findings
**Notes**: Outer `ListenableBuilder(listenable: themeController, ...)` wrapper preserved byte-for-byte. `MaterialApp.router` has exactly 6 named args: `title`, `debugShowCheckedModeBanner`, `theme`, `darkTheme`, `themeMode`, `routerConfig`. No `home:`, `routes:`, `onGenerateRoute:`, `navigatorKey:`, `initialRoute:`. App now boots into `HomeScreen` at `/`.

## Description

Wire the new `appRouter` into `DoslyApp` by replacing `MaterialApp(...)` with `MaterialApp.router(routerConfig: appRouter, ...)`. Drop the direct `home: const ThemePreviewScreen()` wiring and the now-unused `theme_preview_screen.dart` import. Preserve the outer `ListenableBuilder(listenable: themeController, ...)` wrapper — it still rebuilds `MaterialApp.router` on theme changes, and `GoRouter`'s internal navigation stack survives the rebuild untouched. Update the library-level dartdoc at the top of `lib/app.dart` so it no longer references `ThemePreviewScreen` as the home.

This is the integration point where the new routing becomes live — after this task, the app boots into `HomeScreen` at `/` and the theme preview is reachable at `/theme-preview`.

## Change details

Starting from the current `lib/app.dart` (34 lines — read before editing per "Read before write" rule):

- In `lib/app.dart` library-level dartdoc (lines 1-7 pre-edit):
  - Rewrite the dartdoc so it (a) no longer references `ThemePreviewScreen`, (b) describes `HomeScreen` as the current home reached via `appRouter` at `/`, (c) notes that `/theme-preview` is a temporary dev-only route that will be removed in the final development stages, and (d) retains the explanation that `ListenableBuilder` propagates `themeController` changes to `MaterialApp.router`. Keep the `library;` directive on its own line.
  - Example acceptable dartdoc content (not required verbatim):
    ```
    /// Application root.
    ///
    /// Wraps `MaterialApp.router` in a [ListenableBuilder] so the entire tree
    /// rebuilds when [themeController]'s value changes. Sets the M3 light and
    /// dark themes from [AppTheme]. Routing is delegated to [appRouter] which
    /// currently exposes `/` ([HomeScreen]) and a temporary dev-only
    /// `/theme-preview` route — the preview route will be removed in the
    /// final development stages (see specs/002-main-screen/spec.md).
    library;
    ```

- In `lib/app.dart` import block:
  - **Remove** the line `import 'features/theme_preview/presentation/screens/theme_preview_screen.dart';`.
  - **Add** the line `import 'core/routing/app_router.dart';`, placed alphabetically among the existing relative imports (which are `core/theme/app_theme.dart`, `core/theme/theme_controller.dart`). Final relative-import order: `core/routing/app_router.dart`, `core/theme/app_theme.dart`, `core/theme/theme_controller.dart`.
  - Leave `package:flutter/material.dart` unchanged.

- In `DoslyApp.build`:
  - Leave the outer `ListenableBuilder(listenable: themeController, builder: (context, _) => ...)` wrapper **exactly as-is**. Do not rename parameters, do not change the listenable, do not move logic out.
  - Inside the builder callback, replace `MaterialApp(` with `MaterialApp.router(`.
  - **Remove** the line `home: const ThemePreviewScreen(),`.
  - **Add** the line `routerConfig: appRouter,` in its place (or at the end of the argument list — Dart argument order doesn't matter for named parameters, but convention is to put `routerConfig` either first or last; the existing file puts `home:` last, so put `routerConfig:` last for minimal diff).
  - Leave `title: 'dosly',`, `debugShowCheckedModeBanner: false,`, `theme: AppTheme.lightTheme,`, `darkTheme: AppTheme.darkTheme,`, `themeMode: themeController.value,` **byte-for-byte unchanged**.
  - Do not add `routes:`, `onGenerateRoute:`, `navigatorKey:`, or `initialRoute:` to the `MaterialApp.router` — `appRouter` owns all routing.

- In `DoslyApp` class declaration and constructor:
  - Leave unchanged. Still `class DoslyApp extends StatelessWidget`, still `const DoslyApp({super.key});`.

## Done when

- [x] `lib/app.dart` does NOT contain the string `ThemePreviewScreen` anywhere (not in imports, not in `home:`, not in dartdoc)
- [x] `lib/app.dart` does NOT contain the string `theme_preview_screen.dart` (import removed)
- [x] `lib/app.dart` imports `core/routing/app_router.dart`
- [x] `lib/app.dart` imports `package:flutter/material.dart`, `core/routing/app_router.dart`, `core/theme/app_theme.dart`, `core/theme/theme_controller.dart` — exactly those four
- [x] `DoslyApp.build` returns `ListenableBuilder(listenable: themeController, builder: (context, _) => MaterialApp.router(...))` — the outer wrapper is unchanged
- [x] The `MaterialApp.router` has `routerConfig: appRouter`
- [x] The `MaterialApp.router` does NOT have `home:`, `routes:`, `onGenerateRoute:`, `navigatorKey:`, or `initialRoute:`
- [x] The `MaterialApp.router` still has `title: 'dosly'`, `debugShowCheckedModeBanner: false`, `theme: AppTheme.lightTheme`, `darkTheme: AppTheme.darkTheme`, `themeMode: themeController.value` — all five, unchanged
- [x] The library-level dartdoc no longer contains `ThemePreviewScreen`
- [x] The library-level dartdoc contains the literal substring `HomeScreen` and the literal substring `appRouter` (or `/theme-preview`)
- [x] `dart analyze lib/app.dart` reports zero diagnostics (specifically: no `unused_import` warning)
- [x] `dart analyze` reports zero diagnostics project-wide
- [x] No `print()`, `debugPrint()`, `!`, or `dynamic` usage in touched sections
- [x] `flutter test` still passes task 005's tests will still be the old ones at this point, so test 1 (`find.text('dosly · M3 preview')`) will FAIL. **This task's done-when does NOT include `flutter test` passing** — that comes after task 005 rewrites the tests. `dart analyze` clean is the gate for this task.

## Contracts

### Expects

- `lib/core/routing/app_router.dart` exists and declares a top-level `final GoRouter appRouter` (produced by task 003).
- `lib/features/home/presentation/screens/home_screen.dart` exists and exports `class HomeScreen extends StatelessWidget` (produced by task 002).
- `lib/app.dart` currently contains the literal lines `import 'features/theme_preview/presentation/screens/theme_preview_screen.dart';` and `home: const ThemePreviewScreen(),` (pre-task state verified by reading the file first).
- `lib/app.dart` currently wraps its `MaterialApp` in `ListenableBuilder(listenable: themeController, builder: ...)`.

### Produces

- `lib/app.dart` source contains the literal string `MaterialApp.router(` (the `.router` constructor, not the bare `MaterialApp(` constructor).
- `lib/app.dart` source contains the literal string `routerConfig: appRouter`.
- `lib/app.dart` source contains the literal import `import 'core/routing/app_router.dart';`.
- `lib/app.dart` source does NOT contain the literal string `ThemePreviewScreen` anywhere (case-sensitive).
- `lib/app.dart` source does NOT contain the literal string `theme_preview_screen.dart`.
- `lib/app.dart` source does NOT contain the literal strings `home: const` or `home: `  within the `MaterialApp.router` call.
- `lib/app.dart` source still contains the literal lines `title: 'dosly'`, `debugShowCheckedModeBanner: false`, `theme: AppTheme.lightTheme`, `darkTheme: AppTheme.darkTheme`, `themeMode: themeController.value`.
- `lib/app.dart` source still contains `ListenableBuilder(` wrapping the `MaterialApp.router(` call.
- `dart analyze lib/app.dart` exits 0 with no diagnostics including no `unused_import`.

## Spec criteria addressed

- AC-9 (lib/app.dart edits — imports swapped, `MaterialApp` → `MaterialApp.router`, `routerConfig: appRouter`, `home:` removed, outer `ListenableBuilder` preserved, other props unchanged)
- AC-10 (lib/app.dart library dartdoc no longer references `ThemePreviewScreen` as the home)
- AC-13 (dart analyze clean — per-file verification here)
- AC-16 (no `print`/`!`/`dynamic`)

## Notes

- **Why the outer `ListenableBuilder` stays**: `themeController` is a `ValueNotifier<ThemeMode>`. `MaterialApp.themeMode` must be set at construction time; if the theme mode changes, `MaterialApp.router` must be rebuilt to reflect it. `ListenableBuilder` is the reactive bridge. See research.md question 5.
- **Why `GoRouter` state survives the rebuild**: `appRouter` is a top-level `final` constant. `MaterialApp.router` reads `routerConfig` on every build, but it does not reconstruct the `GoRouter` — it re-attaches the existing one. Navigation-stack state lives inside the `GoRouter` instance and is preserved across rebuilds.
- **Test state after this task**: `test/widget_test.dart`'s existing tests assert on `ThemePreviewScreen`'s AppBar title `'dosly · M3 preview'`. After task 004, the app boots into `HomeScreen` instead, so the existing tests will FAIL. This is expected and intentional — task 005 rewrites the tests. Do not run `flutter test` as a gate for task 004; run it as a gate for task 005.
- **Minimal diff principle**: this edit should touch ~10 lines total (dartdoc rewrite + 2 import line changes + 2 `MaterialApp` → `MaterialApp.router` edits + 1 line removed + 1 line added). Do not refactor unrelated code, do not reformat, do not reorder other arguments.
