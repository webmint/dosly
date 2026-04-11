# Plan: Main Screen — Hello World + go_router Foundation

**Date**: 2026-04-11
**Spec**: [spec.md](spec.md) (Status: Approved)
**Status**: Approved

## Summary

Introduce dosly's permanent routing foundation (`go_router`) while shipping the first real placeholder screen (`HomeScreen` — a minimal Hello World). Two new files (`lib/core/routing/app_router.dart`, `lib/features/home/presentation/screens/home_screen.dart`), three edits (`pubspec.yaml`, `lib/app.dart`, `test/widget_test.dart`), one new dependency (`go_router`). Zero new entities, zero API calls, zero new `core/` modules beyond routing. `ThemePreviewScreen` moves from `home:` to the `/theme-preview` route and stays reachable via a dev button on `HomeScreen`.

## Technical Context

**Architecture**: Clean Architecture (constitution §1). This spec touches the **presentation** layer (`lib/features/home/presentation/screens/`) and the **composition** layer (`lib/core/routing/`). No domain, no data, no use cases, no repositories. No `domain/` or `data/` folders under `features/home/` in this spec.

**Error Handling**: N/A at the application level — no fallible operations in this scope. `GoRouter`'s default `errorBuilder` handles hypothetical unknown-route cases, but both navigation call sites in this spec are hardcoded strings matching registered routes (`/` implicit, `/theme-preview` explicit), so the error path is unreachable by construction. The spec deliberately excludes `errorBuilder:` override.

**State Management**: Existing pattern preserved. `themeController` (top-level `ValueNotifier<ThemeMode>` at `lib/core/theme/theme_controller.dart:46`) drives theme changes via an outer `ListenableBuilder` wrapping `MaterialApp.router`. `appRouter` is introduced as a second top-level constant following the same shape. No Riverpod.

**Dart / Flutter SDK**: `pubspec.yaml` declares `environment.sdk: ^3.11.1`. `go_router` 16.x requires Dart ≥ 3.7 — satisfied. Verify at `/execute-task` time via `flutter pub add go_router` (if resolution fails on SDK constraint, the task stops and asks the user to upgrade Flutter; the plan cannot fix an SDK mismatch).

## Constitution Compliance

| Rule | Status | Notes |
|------|--------|-------|
| §1 Clean Architecture (feature = data/domain/presentation) | Compliant | Only `presentation/screens/` created under `features/home/`; no domain or data in scope |
| §3 "No dead code" (line 240) | Compliant | `ThemePreviewScreen` remains reachable via `/theme-preview` route; not dead |
| §7.1 item 9: `lib/core/routing/app_router.dart` uses `go_router` | Compliant | This spec creates exactly that file |
| §7.1 item 18: `main.dart` wraps `runApp(ProviderScope(child: DoslyApp()))` | **Intentional deviation** | Project does not use Riverpod yet — m3-theme spec established `ValueNotifier` + `ListenableBuilder` pattern. CLAUDE.md rule #12 ("search before building") takes precedence over §7.1's aspirational order. A future spec will decide Riverpod adoption on its own merits. |
| §7.3 initial dependencies list (Riverpod, fpdart, drift, freezed, etc.) | Intentional deviation — same reason as above | Not advanced in this spec |
| §7.4 strict-mode `analysis_options.yaml` | **Known gap** | Current `analysis_options.yaml` is the default `flutter_lints` include — **not** the strict-mode config from §7.4. This means `dart analyze` does **not** enforce "no `!`", "no `dynamic`", "no `print`" at the linter level. These rules are enforced by convention + code review (code-reviewer agent in `/execute-task`'s Phase 4). A future spec will upgrade `analysis_options.yaml`. Not in scope here. |
| "Read before write" | Compliant | All files to be modified have been read in Phase 0 |
| "Document new code" | Compliant | `HomeScreen` and `appRouter` get dartdoc per AC-8 and AC-2 |
| "Never leave bare TODOs" | Compliant | All temporary-scaffold TODOs reference `specs/002-main-screen/spec.md` per AC-3, AC-8 |
| "Handle both paths" (`Either<Failure, T>`) | N/A | No fallible operations in scope |
| "Never use `!` null assertion" | Compliant by construction | No nullable types in scope |
| "Never put Flutter imports in `domain/`" | N/A | No `domain/` folder created |
| "SOLID, DRY, KISS" | Compliant | Minimal by design |
| CLAUDE.md rule #12 "search before building" | Compliant | Reusing `DoslyApp`, `themeController`, `AppTheme`, `ThemePreviewScreen` |

**No blocking compliance issues.** The two intentional deviations (no Riverpod, default `analysis_options.yaml`) are pre-existing states of the repo that this spec does not change and does not need to change to satisfy its ACs.

## Implementation Approach

### Layer Map

| Layer | What | Files (new or existing) |
|-------|------|-------------------------|
| Presentation (feature) | `HomeScreen` — placeholder main screen | **New**: `lib/features/home/presentation/screens/home_screen.dart` |
| Presentation (app root) | `DoslyApp` — swap `MaterialApp` → `MaterialApp.router` | **Edit**: `lib/app.dart` |
| Composition / core routing | `appRouter` — top-level `GoRouter` constant with two flat routes | **New**: `lib/core/routing/app_router.dart` (and the `lib/core/routing/` directory) |
| Config / dependencies | Add `go_router` package | **Edit**: `pubspec.yaml`; regenerate `pubspec.lock` via `flutter pub add` |
| Tests | Rewrite widget tests to match new navigation flow | **Edit**: `test/widget_test.dart` |
| Untouched | Domain, data, other features, other core modules, other tests | — |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|-----------------|-----|----------------------|
| Routing library | `go_router` (latest stable caret) | Flutter-team-maintained; pub.dev declares "feature-complete, stability focus"; constitution §7.1 item 9 alignment; user chose to pay migration cost once now vs twice later | `MaterialApp.routes` (defers cost); inline `Navigator.push(MaterialPageRoute(...))` (cross-feature import); `auto_route` (codegen, minority); raw Navigator 2.0 (verbose) — see `research.md` for full comparison |
| Router instance | Top-level `final GoRouter appRouter = GoRouter(...)` in `lib/core/routing/app_router.dart` | Mirrors `themeController` at `lib/core/theme/theme_controller.dart:46`; zero DI overhead; no Riverpod dependency | Riverpod provider (forces Riverpod adoption); factory function (inconsistent with repo pattern) |
| Router features enabled | Flat two-route table: `/` → `HomeScreen`, `/theme-preview` → `ThemePreviewScreen`. **Nothing else.** | Spec §6 is binding; N=2 routes doesn't justify structure; every excluded feature is explicitly listed in AC-2 and spec §6 | `ShellRoute` (premature); `redirect:`/guards (no auth yet); `errorBuilder:` (unreachable by construction); `initialLocation:` (default `/` is correct); codegen/typed routes (complexity); observers (no analytics yet) |
| `MaterialApp.router` wiring | Keep outer `ListenableBuilder(listenable: themeController, ...)` unchanged. Inside its builder, replace `MaterialApp(...)` with `MaterialApp.router(routerConfig: appRouter, title: 'dosly', debugShowCheckedModeBanner: false, theme: AppTheme.lightTheme, darkTheme: AppTheme.darkTheme, themeMode: themeController.value)`. Drop `home:`. | Preserves theme-switching; `GoRouter` instance owns its nav stack internally so outer rebuilds are safe; documented standard pattern | Moving `ListenableBuilder` inside `MaterialApp.router` (structurally impossible — theme must be set on construction); dropping `ListenableBuilder` (breaks theme switching) |
| Navigation method | `context.push('/theme-preview')` on the `HomeScreen` button | Preserves `HomeScreen` underneath → default AppBar back button works naturally | `context.go` (replaces stack, breaks back nav); helper wrapper (ceremony — see Open Q #5) |
| `HomeScreen` ↔ `go_router` coupling | `HomeScreen` imports `package:go_router/go_router.dart` directly for the `context.push` extension | Standard go_router pattern per pub.dev; minimal indirection at a call site scheduled for deletion | Helper function `openThemePreview(context)` in `app_router.dart` (adds one file edit, removes one import — net zero benefit) |
| Button widget | `OutlinedButton` with text `'Theme preview'`, 24-pixel `SizedBox` gap above | User's approval implicitly accepted the Open Q #3 default; visible for dev use without "primary action" signal | `TextButton` (too subtle); `FilledButton.tonal` (too prominent); `IconButton` in AppBar (requires adding AppBar, avoided) |
| Version pinning | `flutter pub add go_router` at execution time; no hardcoded version in the spec or plan | Package is feature-complete → caret constraint is safe; pinning would be stale by execution time | Hardcoded `^16.0.0` (wrong if resolution moves); exact pin (blocks patch upgrades) |
| Test rewrite strategy | Preserve **both** existing tests: first one asserts `HomeScreen` content; second one taps the dev button, asserts navigation, then taps cycle button as before. | Keeps integration-level coverage of theme cycling through the full nav flow; adds navigation coverage for free; zero new test files | Delete the second test (loses integration coverage); add a third navigation-only test (duplicates work of the rewritten test 2) |

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `pubspec.yaml` | **Edit** | Add `go_router` under `dependencies:` with a caret constraint resolved by `flutter pub add go_router`. No other changes. `pubspec.lock` regenerates automatically. |
| `lib/core/routing/app_router.dart` | **Create new** | Library-level dartdoc describing the file as the routing composition root. Imports: `package:flutter/material.dart`, `package:go_router/go_router.dart`, `../../features/home/presentation/screens/home_screen.dart`, `../../features/theme_preview/presentation/screens/theme_preview_screen.dart`. Exports `final GoRouter appRouter = GoRouter(routes: [GoRoute(path: '/', builder: (context, state) => const HomeScreen()), GoRoute(path: '/theme-preview', builder: (context, state) => const ThemePreviewScreen())]);`. Single TODO comment adjacent to the `/theme-preview` entry referencing `specs/002-main-screen/spec.md` with the removal trigger (post-MVP cleanup). |
| `lib/features/home/presentation/screens/home_screen.dart` | **Create new** | Dartdoc class comment describing `HomeScreen` as the placeholder main screen and explicitly flagging the "Theme preview" button as temporary dev scaffolding scheduled for removal post-MVP, referencing `specs/002-main-screen/spec.md`. Imports: `package:flutter/material.dart`, `package:go_router/go_router.dart`. Defines `HomeScreen` as a public `StatelessWidget`. `build` returns `Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('Hello World'), const SizedBox(height: 24), OutlinedButton(onPressed: () => context.push('/theme-preview'), child: const Text('Theme preview'))])))`. TODO comment on the button block referencing the spec. Every widget that can be `const` is `const`. |
| `lib/app.dart` | **Edit** | (1) Remove `import 'features/theme_preview/presentation/screens/theme_preview_screen.dart';`. (2) Add `import 'core/routing/app_router.dart';`. (3) Replace `MaterialApp(...)` with `MaterialApp.router(...)`. (4) Remove the `home: const ThemePreviewScreen(),` line. (5) Add `routerConfig: appRouter,`. (6) Leave `title: 'dosly'`, `debugShowCheckedModeBanner: false`, `theme: AppTheme.lightTheme`, `darkTheme: AppTheme.darkTheme`, `themeMode: themeController.value` byte-for-byte unchanged. (7) Leave the outer `ListenableBuilder(listenable: themeController, ...)` wrapper unchanged. (8) Update the library-level dartdoc (lines 1-7) to describe `HomeScreen` at `/` as the current home, note that `/theme-preview` is a temporary dev-only route, and retain the `ListenableBuilder` + `themeController` explanation. |
| `test/widget_test.dart` | **Edit** | **Test 1** — rename to `'DoslyApp renders the home screen with Hello World and a Theme preview button'`; replace both assertions with `expect(find.text('Hello World'), findsOneWidget)` and `expect(find.widgetWithText(OutlinedButton, 'Theme preview'), findsOneWidget)`. **Test 2** — rewrite as: `pumpWidget(const DoslyApp())` → `pumpAndSettle` → `tester.tap(find.widgetWithText(OutlinedButton, 'Theme preview'))` → `pumpAndSettle` → `expect(find.text('dosly · M3 preview'), findsOneWidget)` → three cycles of `tester.tap(find.byTooltip('Cycle theme mode'))` + `pumpAndSettle`, asserting `themeController.value` transitions `system → light → dark → system`. `setUp` block (resetting `themeController.setMode(ThemeMode.system)`) is preserved unchanged. No new imports needed. |
| `pubspec.lock` | **Auto-regenerated** | Mechanical result of `flutter pub add go_router` — not a manual edit |
| `lib/main.dart`, `lib/core/theme/**`, `lib/features/theme_preview/**`, `test/core/theme/**`, `assets/**`, `analysis_options.yaml`, `ios/**`, `android/**`, `docs/**` | — | **Untouched** |

### Documentation Impact

| Doc File | Action | Reason |
|----------|--------|--------|
| `docs/features/home.md` | **Not created** | Feature is a placeholder; too thin to warrant a doc page. A future richer home-screen spec will own this via `/finalize`. |
| `docs/features/theme.md` | **Not updated** | `ThemePreviewScreen`'s behavior is unchanged; only how it's reached has changed. The theme feature doc describes the theme system, not the preview screen's navigation entry point. |
| `docs/architecture.md` | **Not updated** | Routing guidance belongs in this file eventually, but at N=2 routes the route table has no shape yet. A follow-up spec should add a "Routing" section when the table grows past ~4 screens. Flagged as future work, not this spec's concern. |
| `docs/api/*` | N/A | No API surface |

**Summary**: No documentation changes in this spec. The spec's Out-of-Scope section explicitly defers doc updates; the plan honors that.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `flutter pub add go_router` fails because installed Flutter is older than go_router latest's minimum | Low | Med | `/execute-task` stops at the dependency step with a clear error; user upgrades Flutter. Plan cannot fix SDK mismatch. Fallback: pin to an older go_router release that matches the installed SDK. |
| `go_router` API shifts between plan time and execution time (hours to days window) | Very Low | Low | pub.dev declares the package "feature-complete, stability focus". Realistic drift in days is zero. `/execute-task` fetches live docs via context7 again before writing any code (per spec §8 note 1). |
| Router navigation-stack state leaks across widget tests because `appRouter` is a top-level `final` | Med | Low | AC-12's flow does not require a clean router on entry. Test 1 doesn't navigate. Test 2 navigates once and completes its assertions without needing to return. If flakiness appears in a future spec, convert `appRouter` to a factory function — noted in spec Open Q §8 #6 for future-you. |
| `ListenableBuilder` rebuilding `MaterialApp.router` resets the router state | Very Low | Med | `MaterialApp.router` reads `routerConfig` on each build; the `GoRouter` instance holds its own state internally and is not recreated. Standard documented pattern. AC-14 (`flutter test`) catches regressions. |
| `/breakdown` over-scopes toward `ShellRoute` / `redirect:` / `errorBuilder:` / typed routes because they're "free to add" | Med | Med | Spec §6 and this plan's Key Design Decisions table explicitly list every go_router feature that is forbidden in this spec. `/breakdown` must treat both as contractual. |
| TODO comments get forgotten and ship to production | Med | Low | TODOs reference `specs/002-main-screen/spec.md`. Post-MVP cleanup spec should `grep -r 'specs/002-main-screen'` across `lib/`. |
| Post-MVP cleanup spec forgets one of the three coordinated edits (route, button, folder) | Low | Med | Documented in spec §6: "three coordinated edits in one atomic spec". |
| `analysis_options.yaml` is the default flutter_lints (not constitution §7.4 strict mode), so `dart analyze` does not enforce `!`/`dynamic`/`print` bans | Known pre-existing state | N/A for this spec | Code-reviewer agent in `/execute-task` Phase 4 catches violations at the manual review layer. Spec §6 keeps analysis_options upgrade out of scope. Future spec should handle. |
| `HomeScreen` imports `package:go_router/go_router.dart`, creating a feature-layer dependency on a composition concern | Low | Low | Standard go_router usage; the alternative helper wrapper was rejected in spec Open Q §8 #5 as ceremony. Call site is scheduled for deletion. |
| Cross-feature imports inside `app_router.dart` (both `features/home/...` and `features/theme_preview/...`) | Low | Low | `lib/core/routing/` is the composition root — the one place cross-feature wiring belongs. Not a Clean Architecture violation. |
| Button mis-positioned on small screens (overflow, clipping) | Low | Low | `mainAxisSize: MainAxisSize.min` on the `Column` + `Center` wrapper ensures natural sizing. AC-18 manual simulator check on phone form factor confirms. |

## Dependencies

**New runtime dependency**:
- `go_router` — added via `flutter pub add go_router` at `/execute-task` time. Latest stable caret constraint. No version hardcoded in the plan.

**No dev dependencies added.** Explicitly excluded: `go_router_builder`, `build_runner`, any codegen.

**No environment variables.** No services to configure. No platform-specific changes (`ios/Runner/Info.plist`, `android/app/src/main/AndroidManifest.xml` untouched — deep-linking is out of scope).

## Supporting Documents

- [Research](research.md) — go_router alternatives comparison + API shape findings from live pub.dev docs (via context7)
- No `data-model.md` — no entities introduced or modified
- No `contracts.md` — no API surface

## Phase 2.5 Cross-Reference (spec ACs ↔ plan coverage)

Every spec AC has an implementation path in this plan. Verified:

| AC | Covered by |
|----|------------|
| AC-1 (pubspec declares go_router; lock resolves; no other deps changed) | File Impact → `pubspec.yaml` row |
| AC-2 (`app_router.dart` shape — flat two-route GoRouter, no extras) | File Impact → `app_router.dart` row; Design Decisions → "Router features enabled"; Risks → over-scoping mitigation |
| AC-3 (TODO on `/theme-preview` route with spec reference) | File Impact → `app_router.dart` row |
| AC-4 (`home_screen.dart` widget shape: Scaffold/Center/Column/Text/SizedBox/OutlinedButton with `context.push`) | File Impact → `home_screen.dart` row; Design Decisions → "Navigation method" |
| AC-5 (`home_screen.dart` imports only material + go_router) | File Impact → `home_screen.dart` row |
| AC-6 (no AppBar/FAB/Drawer/BottomNav) | File Impact → `home_screen.dart` row |
| AC-7 (exact strings `'Hello World'` and `'Theme preview'`) | File Impact → `home_screen.dart` row; widget test assertions in `test/widget_test.dart` row |
| AC-8 (`HomeScreen` dartdoc with spec reference) | File Impact → `home_screen.dart` row |
| AC-9 (`app.dart` edits — imports, MaterialApp.router, routerConfig, no home:, outer ListenableBuilder preserved) | File Impact → `lib/app.dart` row |
| AC-10 (`app.dart` dartdoc update) | File Impact → `lib/app.dart` row step (8) |
| AC-11 (widget test 1: asserts Hello World + button) | File Impact → `test/widget_test.dart` row "Test 1" |
| AC-12 (widget test 2: navigate then cycle) | File Impact → `test/widget_test.dart` row "Test 2" |
| AC-13 (`dart analyze` zero diagnostics) | Verified in `/execute-task` Phase 3 post-execution gates |
| AC-14 (`flutter test` passes) | Verified in `/execute-task` Phase 3 post-execution gates |
| AC-15 (`flutter build apk --debug` succeeds) | Verified in `/execute-task` Phase 3 post-execution gates |
| AC-16 (no `print`/`debugPrint`/`!`/`dynamic`) | Writer discipline + code-reviewer agent in Phase 4 (analysis_options does not enforce — noted in Constitution Compliance) |
| AC-17 (const where possible) | Flutter_lints baseline `prefer_const_constructors` rule catches this at `dart analyze` time |
| AC-18 (manual simulator verification) | Performed by user during `/verify`; not blocking `/execute-task` gates |

**Reverse check**: no files in the plan's File Impact list that are absent from spec §4 "Affected Areas". No scope drift discovered during planning.

## Notes for `/breakdown`

- The three file creations/edits have weak interdependencies:
  - `app_router.dart` imports `HomeScreen` and `ThemePreviewScreen`, so `home_screen.dart` must exist first.
  - `lib/app.dart` imports `appRouter` from `app_router.dart`, so `app_router.dart` must exist first.
  - `test/widget_test.dart` exercises the full `DoslyApp` chain — should run last.
  - `pubspec.yaml` edit must precede any file that imports `package:go_router/go_router.dart` (so the package resolves).
- Suggested task order for breakdown:
  1. Add `go_router` dependency (`pubspec.yaml` + `pubspec.lock`).
  2. Create `home_screen.dart` (can be written against a yet-to-exist router because it only knows the route *string* `/theme-preview`, not the router instance).
  3. Create `app_router.dart` (now both screens exist).
  4. Edit `lib/app.dart` (now the router exists).
  5. Edit `test/widget_test.dart` (now the full chain exists and `flutter test` can run).
- Each step is small enough to be a single task per `/breakdown` granularity norms.
- Agent assignment: `mobile-engineer` for all file edits (presentation + composition layer); `code-reviewer` in Phase 4; `qa-engineer` for the widget-test rewrite task specifically.
- No cross-task interdependencies beyond the linear order above.
