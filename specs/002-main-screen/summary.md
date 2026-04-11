# Feature Summary: 002 — Main Screen (Hello World + go_router Foundation)

### What was built

dosly now boots into a real `HomeScreen` at `/` showing a centered "Hello World" placeholder with a temporary "Theme preview" button instead of directly rendering the development theme preview. Under the hood, the project adopts `go_router` as its permanent routing foundation — all future screens will register routes through a single `appRouter` in `lib/core/routing/app_router.dart` rather than swapping `MaterialApp.home:`. The theme preview screen moves to a `/theme-preview` route reachable only via the dev button, scheduled for post-MVP removal alongside the button.

### Changes

- **Task 001** — Added `go_router: ^17.2.0` via `flutter pub add`. Transitive deps: `logging 1.3.0`.
- **Task 002** — Created `HomeScreen` as a `StatelessWidget` with `Scaffold → Center → Column → [Text('Hello World'), SizedBox(24), OutlinedButton('Theme preview')]`. Button calls `context.push('/theme-preview')`.
- **Task 003** — Created `lib/core/routing/app_router.dart` with a top-level `final GoRouter appRouter` containing a flat two-route table: `/` → `HomeScreen`, `/theme-preview` → `ThemePreviewScreen`. No `ShellRoute`, redirects, guards, or codegen — deliberately minimal. (Repair round: dropped an originally-mandated `package:flutter/material.dart` import that was genuinely unused, rather than suppressing the `unused_import` lint.)
- **Task 004** — Swapped `MaterialApp(...)` → `MaterialApp.router(routerConfig: appRouter, ...)` inside `DoslyApp`. Preserved the outer `ListenableBuilder(listenable: themeController, ...)` wrapper so theme reactivity still propagates. Dropped the `theme_preview_screen.dart` import from `app.dart`.
- **Task 005** — Rewrote `test/widget_test.dart`: test 1 asserts `HomeScreen` content ('Hello World' + 'Theme preview' button); test 2 taps the button to navigate, asserts arrival at the preview screen, then cycles the theme three times asserting `themeController.value` transitions `system → light → dark → system`.

### Files changed

**Source / tests** (6 files, +195 / -37):
- `pubspec.yaml`, `pubspec.lock` — new `go_router` dependency
- `lib/core/routing/app_router.dart` (new, 34 lines)
- `lib/features/home/presentation/screens/home_screen.dart` (new, 46 lines)
- `lib/app.dart` — `MaterialApp` → `MaterialApp.router`
- `test/widget_test.dart` — rewritten for new navigation flow

**Workflow artifacts** (13 files, +1331 / 0): spec.md, plan.md, research.md, review.md, verify.md, tasks/README.md + 5 task files, session-state.md, MEMORY.md updates.

**Total diff vs `main`**: 19 files, 1526 insertions, 37 deletions.

### Key decisions

- **Routing library: `go_router` (adopted now, not deferred)** — rather than use `MaterialApp.routes` as a built-in stopgap, the project pays the routing setup cost once while the surface is tiny. Rationale: more screens are coming (medications, schedules, intakes, settings per `MEMORY.md`); migrating a stopgap later costs strictly more than adopting the target solution now. `go_router` is Flutter-team-maintained and declared "feature-complete, stability focus" on pub.dev.
- **`appRouter` lifetime: top-level `final GoRouter`** — mirrors the existing `themeController` pattern at `lib/core/theme/theme_controller.dart:46`. Zero DI overhead, no Riverpod dependency. If router DI is ever needed, migration to a factory function or provider is a one-file change.
- **Routing scope: flat two-route table only** — no `ShellRoute`, redirects, guards, `errorBuilder`, `initialLocation` override, typed routes, or codegen. At N=2 routes there's no shape to design around; premature structure would anchor decisions to a sample size of 2.
- **Theme reactivity preserved via outer `ListenableBuilder`** — `ListenableBuilder(listenable: themeController, ...)` wraps `MaterialApp.router`, not the other way around. `GoRouter` owns its navigation-stack state internally, so rebuilds of `MaterialApp.router` on theme changes are safe (verified by reading `pub-cache/.../go_router-17.2.0/lib/src/router.dart` during performance review).

### Deviations from plan

- **Task 003**: plan specified 4 imports for `app_router.dart` including `package:flutter/material.dart`. During execution, material.dart was correctly identified as genuinely unused — `go_router` transitively provides `BuildContext`, and screen types come from their own relative imports. First attempt added `// ignore: unused_import` to satisfy both constraints, was rejected as a lint-suppression anti-pattern, and the repair dropped the import entirely. Final file has 3 imports. Captured as a lesson in `MEMORY.md` ("What Failed": avoid over-prescriptive 'exact imports' lists in task files).

### Acceptance criteria

All 17 automated ACs PASS. AC-18 is manual-deferred per spec §8.

- [x] AC-1: `pubspec.yaml` declares `go_router: ^17.2.0`; lock resolves; no other deps changed
- [x] AC-2: `app_router.dart` is a flat two-route `GoRouter` with no forbidden features
- [x] AC-3: TODO adjacent to `/theme-preview` references `specs/002-main-screen/spec.md`
- [x] AC-4: `HomeScreen` structure matches spec shape (Scaffold/Center/Column/Text/SizedBox/OutlinedButton with `context.push`)
- [x] AC-5: `HomeScreen` imports only `material.dart` + `go_router.dart`
- [x] AC-6: No AppBar/FAB/Drawer/BottomNav on `HomeScreen`
- [x] AC-7: Exact strings `'Hello World'` and `'Theme preview'`
- [x] AC-8: `HomeScreen` dartdoc references spec
- [x] AC-9: `lib/app.dart` uses `MaterialApp.router(routerConfig: appRouter)`, outer `ListenableBuilder` preserved, no `home:`
- [x] AC-10: `lib/app.dart` library dartdoc updated (no `ThemePreviewScreen` reference)
- [x] AC-11: Widget test 1 asserts HomeScreen + button
- [x] AC-12: Widget test 2 navigates then cycles theme 3×
- [x] AC-13: `dart analyze` clean project-wide
- [x] AC-14: `flutter test` passes (79/79)
- [x] AC-15: `flutter build apk --debug` succeeds
- [x] AC-16: No `print`/`debugPrint`/`!`/`dynamic` in changed files
- [x] AC-17: `const` where possible
- [ ] AC-18: Manual simulator verification (deferred to user — not blocking)

### Review outcomes

- **Security**: PASS (0 Critical / 0 High / 0 Medium, 7 Info observations)
- **Performance**: APPROVED (0 regressions; `const` discipline optimal; `ListenableBuilder` + `MaterialApp.router` coexistence verified safe against go_router source)
- **Test coverage**: ADEQUATE (one non-blocking future recommendation: add `appRouter.go('/')` to `setUp` the next time a third widget test is added — spec Open Q §8 #6)

**Verdict**: APPROVED — ready for `/finalize`.
