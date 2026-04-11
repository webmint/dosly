# Task 003: Create app_router.dart with flat two-route GoRouter

**Status**: Complete
**Agent**: mobile-engineer
**Files**: `lib/core/routing/app_router.dart` (new)
**Depends on**: 002
**Blocks**: 004, 005
**Context docs**: None
**Review checkpoint**: No

## Completion Notes

**Completed**: 2026-04-11
**Files changed**: `lib/core/routing/app_router.dart` (34 lines, new)
**Contract**: Expects 4/4 verified | Produces 7/7 verified
**Verification**: `dart analyze` clean per-file and project-wide
**Code review**: APPROVE, no findings
**Deviation from task file**: Task specified 4 imports including `package:flutter/material.dart`. During execution, the agent correctly identified that material.dart is genuinely unused — `go_router` transitively provides `BuildContext` via its internal Flutter widgets import, and the screen types come from their own relative imports. One repair round was needed: the first attempt added `// ignore: unused_import` to satisfy both constraints, which was rejected as a lint-suppression anti-pattern. The repair dropped the material import entirely. Final file has 3 imports, not 4. This is correct per constitution §3 "No dead code." Pattern match with `lib/core/theme/theme_controller.dart:46` (the `themeController` top-level pattern) confirmed by the reviewer.

## Description

Create the project's permanent routing composition root — a top-level `final GoRouter appRouter` constant declared in `lib/core/routing/app_router.dart`. The router has exactly two flat `GoRoute` entries: `'/'` → `HomeScreen`, `'/theme-preview'` → `ThemePreviewScreen`. Nothing else: no `ShellRoute`, no nested routes, no `redirect:`, no `errorBuilder:`, no `initialLocation:` override, no `refreshListenable:`, no observers. The constant mirrors the existing `themeController` pattern at `lib/core/theme/theme_controller.dart:46`.

This is the first file under `lib/core/routing/`, so the directory chain must be created. The router file imports both `features/home/...` and `features/theme_preview/...` — this cross-feature wiring is allowed because `lib/core/routing/` is the composition root, not a feature layer.

## Change details

- Create the directory `lib/core/routing/`.
- Create `lib/core/routing/app_router.dart` with:
  - A library-level dartdoc comment (using `library;` directive) describing the file as the app's routing composition root, naming the two routes, and noting that `/theme-preview` is a temporary dev-only route scheduled for post-MVP removal (reference `specs/002-main-screen/spec.md`).
  - Four imports, in this order (alphabetical within each group, `package:` before relative):
    1. `package:flutter/material.dart` (for the `BuildContext` / widget types used in `builder:` callbacks — specifically the `const HomeScreen()` and `const ThemePreviewScreen()` constructors)
    2. `package:go_router/go_router.dart`
    3. `../../features/home/presentation/screens/home_screen.dart`
    4. `../../features/theme_preview/presentation/screens/theme_preview_screen.dart`
  - A top-level `final GoRouter appRouter = GoRouter(...)` declaration with a dartdoc comment describing it as the application's singleton router instance. The `GoRouter` constructor receives exactly one argument: `routes: [ ... ]`. No other named arguments.
  - The `routes:` list has exactly two `GoRoute` entries:
    ```
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      // TODO(post-mvp): remove this route when lib/features/theme_preview/
      // is deleted — see specs/002-main-screen/spec.md §6 and §8.
      GoRoute(
        path: '/theme-preview',
        builder: (context, state) => const ThemePreviewScreen(),
      ),
    ],
    ```
    Note: the list literal can be written with or without the explicit `<RouteBase>` type parameter; if the Dart analyzer infers it cleanly without the annotation, the annotation is optional.
  - No `initialLocation:`, `errorBuilder:`, `errorPageBuilder:`, `redirect:`, `refreshListenable:`, `observers:`, `restorationScopeId:`, `navigatorKey:`, `debugLogDiagnostics:`, or `onException:` parameters on the `GoRouter` constructor.
  - No `ShellRoute`, no nested `routes:` inside either `GoRoute`, no `pageBuilder:` on either `GoRoute`, no `redirect:` on either `GoRoute`, no `parentNavigatorKey:`.

## Done when

- [x] `lib/core/routing/app_router.dart` exists
- [x] Top-level `final GoRouter appRouter = GoRouter(...)` constant declared
- [x] `GoRouter` constructed with exactly one argument: `routes: [...]`
- [x] Two `GoRoute` entries
- [x] First: `path: '/'`, `builder` returns `const HomeScreen()`
- [x] Second: `path: '/theme-preview'`, `builder` returns `const ThemePreviewScreen()`
- [x] TODO adjacent to `/theme-preview` entry references `specs/002-main-screen/spec.md`
- [x] Imports: `package:go_router/go_router.dart` + 2 relative imports (material import dropped as genuinely unused — deviation from task file noted in completion notes)
- [x] Library-level dartdoc describes it as the routing composition root
- [x] `appRouter` has a dartdoc
- [x] `dart analyze lib/core/routing/app_router.dart` reports zero diagnostics
- [x] No `print`, `debugPrint`, `!`, `dynamic`
- [x] `dart analyze` project-wide reports zero diagnostics

## Contracts

### Expects

- `pubspec.yaml` lists `go_router` under `dependencies:` (produced by task 001).
- `lib/features/home/presentation/screens/home_screen.dart` exports a public class `HomeScreen extends StatelessWidget` with a `const HomeScreen({super.key})` constructor (produced by task 002).
- `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` exports a public class `ThemePreviewScreen extends StatelessWidget` with a `const ThemePreviewScreen({super.key})` constructor (pre-existing on `origin/main` from the m3-theme spec).
- `lib/core/routing/` directory does not yet exist.

### Produces

- `lib/core/routing/app_router.dart` exists with the literal declaration `final GoRouter appRouter = GoRouter(`.
- The file source contains the literal strings `path: '/'`, `path: '/theme-preview'`, `const HomeScreen()`, `const ThemePreviewScreen()`.
- The file source does NOT contain any of: `ShellRoute`, `initialLocation`, `errorBuilder`, `errorPageBuilder`, `redirect:`, `refreshListenable`, `observers:`, `navigatorKey`, `restorationScopeId`, `debugLogDiagnostics`, `onException`.
- The file source contains a `// TODO(post-mvp):` comment adjacent to the `/theme-preview` `GoRoute` entry that includes the literal substring `specs/002-main-screen/spec.md`.
- The file source contains the four imports listed in "Change details" and no others.
- `dart analyze lib/core/routing/app_router.dart` exits 0 with no diagnostics.

## Spec criteria addressed

- AC-2 (app_router.dart shape: flat two-route `GoRouter`, no extras — every forbidden feature explicitly not present)
- AC-3 (TODO on `/theme-preview` route with spec reference)
- AC-13 (dart analyze clean — per-file verification here)
- AC-16 (no `print`/`!`/`dynamic`)

## Notes

- **Pattern reference**: `lib/core/theme/theme_controller.dart:46` declares `final ThemeController themeController = ThemeController();` as a top-level constant. `appRouter` follows the same shape: single top-level `final` constant, no getter, no lazy init, no factory.
- **Import path style**: use relative imports (`../../features/...`) not package imports (`package:dosly/features/...`) for files within `lib/`. This matches the existing pattern in `lib/app.dart` which uses `'core/theme/app_theme.dart'` and `'features/theme_preview/presentation/screens/theme_preview_screen.dart'`.
- **Why `package:flutter/material.dart` is imported**: the `builder` callbacks construct `const HomeScreen()` and `const ThemePreviewScreen()` — both are `StatelessWidget` subclasses. The `GoRoute.builder` signature requires `Widget Function(BuildContext, GoRouterState)`. To reference `BuildContext` in a file that doesn't already import Flutter, the Flutter material import is needed. (Some files get away with `package:flutter/widgets.dart` only; use `material.dart` here to match the repo's existing style in `app.dart` and `home_screen.dart`.)
- **Cross-feature wiring is allowed here**: `app_router.dart` imports both `features/home/...` and `features/theme_preview/...`. This is the composition root and the one place cross-feature references are architectural correct — see research.md question 7.
- **No test for `appRouter` in isolation**: routing is exercised end-to-end via `DoslyApp` in task 005's rewritten widget tests. A standalone `app_router_test.dart` is out of scope per spec §6.
