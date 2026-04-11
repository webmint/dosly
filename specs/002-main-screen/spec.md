# Spec: Main Screen — Hello World + go_router Foundation

**Date**: 2026-04-11
**Status**: Complete
**Author**: Claude + mykolakudlyk

## 1. Overview

Introduce the app's first real screen (`HomeScreen` — a minimal Hello World placeholder) and, at the same time, establish the project's permanent routing foundation using `go_router`. The current `ThemePreviewScreen` moves off the `home:` slot onto a named route (`/theme-preview`) reachable via a secondary button on `HomeScreen`. Both the button and the `theme_preview/` feature folder are temporary dev scaffolding scheduled for deletion in the final development stages — the routing infrastructure itself is permanent.

Scope grew by one decision from the previous draft: instead of using `MaterialApp.routes` as a built-in stopgap, this spec adopts `go_router` now (constitution §7.1 item 9) so the project does not incur a router migration later when real screens land. The adoption is deliberately minimal: a flat route table with two `GoRoute` entries, no `ShellRoute`, no redirects, no guards, no codegen, no typed routes.

## 2. Current State

Verified by reading the files on `spec/002-main-screen` (branched off updated `origin/main` at merge commit `030353e`, "Merge pull request #1"):

- `lib/main.dart` (7 lines) imports `app.dart` and calls `runApp(const DoslyApp())`. **Untouched by this spec.**
- `lib/app.dart` (34 lines) defines `DoslyApp` as a `StatelessWidget` returning `ListenableBuilder(listenable: themeController, builder: (context, _) => MaterialApp(...))`. The inner `MaterialApp` sets `title: 'dosly'`, `debugShowCheckedModeBanner: false`, `theme: AppTheme.lightTheme`, `darkTheme: AppTheme.darkTheme`, `themeMode: themeController.value`, and `home: const ThemePreviewScreen()`. No `routes:`, no `onGenerateRoute:`. The file's library-level dartdoc (lines 1-7) says *"uses [ThemePreviewScreen] as the home until real screens land."*
- `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` (205 lines) defines `ThemePreviewScreen` — a `Scaffold` with an `AppBar` (title `'dosly · M3 preview'` and a `'Cycle theme mode'` tooltip `IconButton` action wired to `themeController.cycle`), a scrollable body rendering every M3 color role + every type-scale sample + every common widget, and a demo `FloatingActionButton`. The file's own class-level dartdoc (lines 4-5) says *"Used as the app's `home` until real screens land. Delete when no longer needed."*
- `lib/features/theme_preview/presentation/widgets/color_swatch_card.dart` and `typography_sample.dart` are internal widgets used only by the preview screen.
- `lib/features/` contains no other features. There is no existing `lib/features/home/` folder.
- `lib/core/theme/` contains the full M3 theme machinery (`app_theme.dart`, `app_color_schemes.dart`, `app_text_theme.dart`, `theme_controller.dart`). **Untouched by this spec.**
- `lib/core/routing/` does **not** exist yet. Constitution §7.1 item 9 names this folder as the intended home for `app_router.dart`; this spec creates it.
- `pubspec.yaml` declares `flutter`, `cupertino_icons`, `flutter_lints`, and the four Roboto font files. **No `go_router`, no `flutter_riverpod`, no `fpdart`, no `drift`.** The project uses `ValueNotifier<ThemeMode>` (`themeController`) + `ListenableBuilder` for state — a deliberate departure from constitution §7.1 item 18 accepted during the m3-theme spec. This spec does **not** introduce Riverpod; it follows the existing pattern (CLAUDE.md rule #12 "search before building").
- `test/widget_test.dart` (42 lines) has two tests, both pumping `DoslyApp`:
  1. `'DoslyApp renders the theme preview screen'` — asserts `find.text('dosly · M3 preview')`.
  2. `'cycling theme mode does not throw and updates state'` — finds `find.byTooltip('Cycle theme mode')`, taps it three times, asserts `themeController.value` transitions `system → light → dark → system`. `setUp` resets `themeController.setMode(ThemeMode.system)` before each test.
- `test/core/theme/theme_controller_test.dart` has 8 unit tests that fully cover `ThemeController` cycling (`system→light`, `light→dark`, `dark→system`, three-cycle round-trip, `setMode`, `addListener` notification, default value). Cycling is completely covered at the unit level.
- `test/core/theme/app_color_schemes_test.dart` is unrelated and untouched.
- **go_router API shape** (confirmed via live pub.dev docs during this spec's Phase 3, not from training-data memory): a `GoRouter` is instantiated with a `routes:` list of `GoRoute(path: ..., builder: (context, state) => ...)` entries, and wired into a `MaterialApp` via `MaterialApp.router(routerConfig: appRouter, ...)`. Imperative navigation uses `context.push('/path')` (pushes onto the stack; default back-button pops it) or `context.go('/path')` (replaces the stack). Per pub.dev, go_router is currently **"feature-complete, focused on stability and bug fixes"** — active API churn is no longer a concern it was 2-3 years ago. Exact path-parameter accessor names (`state.pathParameters` vs the older `state.params`) are not needed in this spec because we define two zero-parameter routes; `/plan` will verify against the installed package version before writing code.
- **Constitution §3 line 240**: *"No dead code. Delete unused functions, variables, imports, and files."* — this spec keeps `ThemePreviewScreen` reachable via the `/theme-preview` route, so it is not dead code. The eventual removal (button + route + feature folder) is explicitly deferred to a post-MVP cleanup spec.
- **Constitution rule**: *"Never leave bare TODOs — every TODO must have context and a reference."* — every temporary-scaffold TODO this spec introduces references `specs/002-main-screen/spec.md` and explains the removal trigger (post-MVP, when real content ships).
- `MEMORY.md` confirms dosly is a greenfield medication tracker with no real features yet and lists future work under `features/medications/*`, `features/schedules/*`, `features/intakes/*`. That future work is exactly why the routing foundation is being built now rather than later.
- `docs/architecture.md` was populated by the m3-theme spec and does not currently describe routing. This spec is still thin enough that doc updates belong to `/finalize` on a richer future feature, not here.

## 3. Desired Behavior

After this spec is implemented, running `flutter run` on iOS or Android must:

1. Launch the app without runtime errors.
2. Display `HomeScreen` at the root route (`/`). The screen renders:
   - The text **"Hello World"** as the primary visual element.
   - A secondary **"Theme preview"** `OutlinedButton` below the text.
   - Both centered horizontally; the text + button pair is centered vertically.
   - No `AppBar`, no `FloatingActionButton`, no `Drawer`, no `BottomNavigationBar`.
3. Tapping the "Theme preview" button calls `context.push('/theme-preview')`, which pushes `ThemePreviewScreen` onto the Navigator stack. The screen appears with its existing `AppBar` — including the default Flutter-provided back button (Material "←" / Cupertino "<") in the leading slot — and the existing `'Cycle theme mode'` tooltip `IconButton` action on the right.
4. Tapping the back button on `ThemePreviewScreen` pops it via go_router's default behavior and returns the user to `HomeScreen`.
5. Theme cycling via the `ThemePreviewScreen` AppBar button continues to work exactly as before: `themeController.cycle` transitions `system → light → dark → system`, and the `ListenableBuilder` in `DoslyApp` rebuilds `MaterialApp.router` so the theme change propagates across both screens.
6. Theme inheritance is otherwise untouched — the `HomeScreen` background follows `AppTheme.lightTheme` / `AppTheme.darkTheme` via the existing `MaterialApp` theme props.
7. Portrait and landscape render correctly on a standard phone form factor.

`DoslyApp`'s state-management pattern (`ListenableBuilder` + `themeController`) is unchanged; the only structural change inside the builder is swapping `MaterialApp(...)` for `MaterialApp.router(...)` and supplying `routerConfig: appRouter`.

File structure after implementation:

```
lib/
  main.dart                                                   # unchanged
  app.dart                                                    # EDITED — MaterialApp → MaterialApp.router, dartdoc update
  core/
    routing/
      app_router.dart                                         # NEW — top-level GoRouter with two GoRoute entries
    theme/...                                                 # unchanged
  features/
    home/                                                     # NEW
      presentation/
        screens/
          home_screen.dart                                    # NEW — StatelessWidget, centered Column(Text + OutlinedButton)
    theme_preview/                                            # unchanged contents; still reachable via /theme-preview
      presentation/screens/theme_preview_screen.dart
      presentation/widgets/color_swatch_card.dart
      presentation/widgets/typography_sample.dart
test/
  widget_test.dart                                            # EDITED — test (1) asserts HomeScreen; test (2) navigates via button, then cycles
  core/theme/theme_controller_test.dart                       # unchanged
  core/theme/app_color_schemes_test.dart                      # unchanged
pubspec.yaml                                                  # EDITED — adds go_router
```

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Dependencies | `pubspec.yaml`, `pubspec.lock` | **Edit `pubspec.yaml`.** Add `go_router` under `dependencies:`. Version pinning is deferred to `/plan`, which will run `flutter pub add go_router` to let pub.dev resolve the current latest stable caret constraint. `pubspec.lock` will update mechanically. **No** `go_router_builder`, **no** `build_runner` additions — codegen is deliberately out of scope. No other dependencies added, removed, or upgraded. |
| Routing foundation | `lib/core/routing/app_router.dart` | **Create new** (plus the `lib/core/routing/` directory). File exports a top-level `final GoRouter appRouter = GoRouter(routes: [...])` with exactly two `GoRoute` entries: (a) `path: '/'`, `builder: (context, state) => const HomeScreen()`; (b) `path: '/theme-preview'`, `builder: (context, state) => const ThemePreviewScreen()`. No `initialLocation:` override (defaults to `/`), no `errorBuilder:` override (default error page is acceptable for this spec), no `redirect:`, no `refreshListenable:`, no `ShellRoute`, no `GoRoute.routes` nesting. A single TODO comment adjacent to the `/theme-preview` entry references `specs/002-main-screen/spec.md` and explains the removal trigger. The file has a library-level dartdoc describing it as the composition root for app routing. Imports: `package:flutter/material.dart` (for the widget types in the builders), `package:go_router/go_router.dart`, `../../features/home/presentation/screens/home_screen.dart`, `../../features/theme_preview/presentation/screens/theme_preview_screen.dart`. |
| New home feature | `lib/features/home/presentation/screens/home_screen.dart` | **Create new** (plus `lib/features/home/`, `lib/features/home/presentation/`, `lib/features/home/presentation/screens/` directories). Public `HomeScreen` `StatelessWidget`. Its `build` returns `const Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('Hello World'), SizedBox(height: 24), OutlinedButton(...)])))` — `const` where possible. The `OutlinedButton`'s `onPressed` is a non-const closure: `() => context.push('/theme-preview')`. Imports: `package:flutter/material.dart` and `package:go_router/go_router.dart` (needed for the `context.push` extension method). **No** imports from `core/`, **no** imports from `features/theme_preview/`, **no** `package:flutter_riverpod/*`. `HomeScreen` has a dartdoc class comment describing it as the current placeholder home and explicitly flagging the "Theme preview" button as temporary dev scaffolding scheduled for removal post-MVP, with a reference to `specs/002-main-screen/spec.md`. A TODO comment on the button widget explains its removal trigger ("TODO(post-mvp): remove this dev entry point when `theme_preview/` is deleted — see `specs/002-main-screen/spec.md` §6 and §8"). |
| App root wiring | `lib/app.dart` | **Edit.** (a) Remove the import of `features/theme_preview/presentation/screens/theme_preview_screen.dart` (it is no longer referenced here — the router owns that import now). (b) Add `import 'core/routing/app_router.dart';`. (c) Replace `MaterialApp(...)` with `MaterialApp.router(...)`. (d) Remove the `home: const ThemePreviewScreen(),` line. (e) Add `routerConfig: appRouter,`. (f) Leave `title: 'dosly'`, `debugShowCheckedModeBanner: false`, `theme: AppTheme.lightTheme`, `darkTheme: AppTheme.darkTheme`, `themeMode: themeController.value` **byte-for-byte unchanged**. (g) Leave the outer `ListenableBuilder(listenable: themeController, builder: ...)` wrapper **unchanged** — it still needs to rebuild `MaterialApp.router` when theme mode changes. (h) Update the library-level dartdoc (lines 1-7) so it (i) no longer mentions `ThemePreviewScreen` as the home, (ii) describes `HomeScreen` as the current home reached via `appRouter` at `/`, (iii) notes that `ThemePreviewScreen` is reachable at `/theme-preview` as a temporary dev route, (iv) retains the `ListenableBuilder` + `themeController` explanation. |
| Theme preview feature | `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart`, `.../widgets/color_swatch_card.dart`, `.../widgets/typography_sample.dart` | **Untouched.** Zero edits. The "Delete when no longer needed" dartdoc on `theme_preview_screen.dart` stays as-is — accurate; "when" just shifts from "now" to "post-MVP". |
| Widget test | `test/widget_test.dart` | **Edit.** (a) Rename the first test to something like `'DoslyApp renders the home screen with Hello World and a Theme preview button'` and replace its assertions with `expect(find.text('Hello World'), findsOneWidget)` **and** `expect(find.widgetWithText(OutlinedButton, 'Theme preview'), findsOneWidget)`. (b) Rewrite the second test so it: pumps `const DoslyApp()`, calls `pumpAndSettle`, taps `find.widgetWithText(OutlinedButton, 'Theme preview')` to navigate via `context.push`, calls `pumpAndSettle`, asserts `find.text('dosly · M3 preview')` is found (navigation succeeded), then taps `find.byTooltip('Cycle theme mode')` three times (with `pumpAndSettle` between each tap) and asserts the same `themeController.value` transitions as before (`system → light → dark → system`). (c) Keep all existing imports (`flutter_test`, `flutter/material`, `package:dosly/app.dart`, `package:dosly/core/theme/theme_controller.dart`); no new imports needed. The `setUp` resetting `themeController.setMode(ThemeMode.system)` stays. |
| `lib/main.dart`, `lib/core/theme/**`, `test/core/theme/**`, `assets/**`, `analysis_options.yaml`, `ios/**`, `android/**`, `docs/**` | — | **Unchanged.** |

## 5. Acceptance Criteria

- [x] **AC-1**: `pubspec.yaml` declares `go_router` as a runtime dependency under `dependencies:` with a caret constraint chosen by `flutter pub add go_router` at `/plan` or `/execute-task` time. `pubspec.lock` resolves cleanly. No other dependencies added, removed, or upgraded. No `go_router_builder`, no `build_runner`.
- [x] **AC-2**: `lib/core/routing/app_router.dart` exists and exports a top-level `final GoRouter appRouter` with exactly two `GoRoute` entries: `path: '/'` builds `const HomeScreen()`, `path: '/theme-preview'` builds `const ThemePreviewScreen()`. No `initialLocation:`, no `errorBuilder:`, no `redirect:`, no `refreshListenable:`, no `ShellRoute`, no nested `GoRoute.routes`, no `observers:`. The file has a library-level dartdoc describing it as the app's routing composition root.
- [x] **AC-3**: `lib/core/routing/app_router.dart` has a single TODO comment adjacent to the `/theme-preview` `GoRoute` entry that references `specs/002-main-screen/spec.md` and explains the removal trigger (post-MVP cleanup when `theme_preview/` is deleted). The TODO is not a bare `// TODO` — it includes the spec reference per constitution rule "Never leave bare TODOs."
- [x] **AC-4**: `lib/features/home/presentation/screens/home_screen.dart` defines a public `HomeScreen` `StatelessWidget`. Its `build` returns a `Scaffold` whose `body` centers a `Column(mainAxisSize: MainAxisSize.min, ...)` containing a `Text('Hello World')`, a `SizedBox(height: 24)`, and an `OutlinedButton` labelled `'Theme preview'` whose `onPressed` calls `context.push('/theme-preview')`.
- [x] **AC-5**: `HomeScreen` imports **only** `package:flutter/material.dart` and `package:go_router/go_router.dart`. It does **not** import `ThemePreviewScreen`, any file under `lib/core/`, `lib/features/theme_preview/`, `flutter_riverpod`, or `fpdart`. (Cross-feature dependency avoidance: `HomeScreen` never references `ThemePreviewScreen` directly — only the route path string.)
- [x] **AC-6**: `HomeScreen`'s `Scaffold` has **no** `AppBar`, **no** `FloatingActionButton`, **no** `BottomNavigationBar`, and **no** `Drawer`. The only interactive widget is the single `OutlinedButton`.
- [x] **AC-7**: The text `'Hello World'` is rendered exactly (single space, title case H and W, no punctuation, no trailing whitespace). The button label `'Theme preview'` is rendered exactly (leading capital T, lowercase p, single space).
- [x] **AC-8**: `HomeScreen` has a dartdoc class comment that (i) describes it as the app's current placeholder home and (ii) explicitly notes that the "Theme preview" button is temporary dev scaffolding scheduled for removal post-MVP, referencing `specs/002-main-screen/spec.md`. Constitution rule "Never leave bare TODOs" is satisfied by the spec reference.
- [x] **AC-9**: `lib/app.dart`:
  - No longer imports `features/theme_preview/presentation/screens/theme_preview_screen.dart`.
  - Imports `core/routing/app_router.dart`.
  - `DoslyApp.build` returns `ListenableBuilder(listenable: themeController, builder: (context, _) => MaterialApp.router(...))` — the `ListenableBuilder` wrapper is unchanged.
  - Inside `MaterialApp.router`: `title: 'dosly'`, `debugShowCheckedModeBanner: false`, `theme: AppTheme.lightTheme`, `darkTheme: AppTheme.darkTheme`, `themeMode: themeController.value` are byte-for-byte unchanged.
  - `routerConfig: appRouter` replaces `home: const ThemePreviewScreen()`.
  - No `home:`, no `routes:`, no `onGenerateRoute:` on `MaterialApp.router`.
- [x] **AC-10**: `lib/app.dart`'s library-level dartdoc (lines 1-7) no longer references `ThemePreviewScreen` as the home. It describes `HomeScreen` as the current home (reached via `appRouter` at `/`) and notes that `/theme-preview` is a temporary dev-only route. The `ListenableBuilder` + `themeController` explanation is retained.
- [x] **AC-11**: `test/widget_test.dart`'s first test pumps `const DoslyApp()`, calls `pumpAndSettle`, and asserts **both** `find.text('Hello World')` is found and `find.widgetWithText(OutlinedButton, 'Theme preview')` is found. No other assertions in this test.
- [x] **AC-12**: `test/widget_test.dart`'s second test pumps `const DoslyApp()`, calls `pumpAndSettle`, taps `find.widgetWithText(OutlinedButton, 'Theme preview')`, calls `pumpAndSettle`, asserts `find.text('dosly · M3 preview')` is found, then taps `find.byTooltip('Cycle theme mode')` three times (with `pumpAndSettle` between each tap) and asserts `themeController.value` transitions `system → light → dark → system`. The `setUp` block resetting `themeController.setMode(ThemeMode.system)` is preserved.
- [x] **AC-13**: `dart analyze` reports **zero** errors, warnings, and info-level diagnostics across the entire project. Specifically: no `unused_import` in `lib/app.dart` (the theme-preview import has been removed), no `unused_import` in `lib/core/routing/app_router.dart`, no `unused_import` in `lib/features/home/presentation/screens/home_screen.dart`, no `unused_import` in `test/widget_test.dart`.
- [x] **AC-14**: `flutter test` passes — all tests in `test/core/theme/theme_controller_test.dart`, all tests in `test/core/theme/app_color_schemes_test.dart`, and the two tests in `test/widget_test.dart`.
- [x] **AC-15**: `flutter build apk --debug` completes successfully.
- [x] **AC-16**: No `print()`, `debugPrint()`, `!` null assertion, or `dynamic` usage in any file created or edited by this spec. No `package:flutter/*` imports leak into any `domain/` folder (n/a — no `domain/` folders are created).
- [x] **AC-17**: All widgets that can be `const` are marked `const` (constitution `prefer_const_constructors` lint). The `OutlinedButton`'s `onPressed` closure captures `context`, so the button itself cannot be `const` — that's expected.
- [x] **AC-18**: Manual simulator verification (performed at `/verify` time — see Open Questions §8 #4): launching the app shows the Hello World screen; tapping "Theme preview" navigates to the preview; Flutter's default AppBar back button returns to the home screen; the theme-cycle button on the preview still rotates `system → light → dark → system` and the background color changes visibly on both screens.

## 6. Out of Scope

The user's directive: a main screen with "Hello World", a button that opens the theme preview, both button-and-screen removable in final development stages, best-practice routing. Everything below is deferred.

- NOT included: Deleting `lib/features/theme_preview/**`. The user said **final stages of development**, not now. This spec keeps the feature folder intact and reachable via the `/theme-preview` route. A post-MVP cleanup spec will coordinate the removal of (a) the `/theme-preview` `GoRoute` entry in `app_router.dart`, (b) the `OutlinedButton` in `HomeScreen`, and (c) the entire `lib/features/theme_preview/` folder — three coordinated edits in one atomic spec.
- NOT included: Feature flags, environment-based gating (`kReleaseMode`), or any runtime mechanism to hide the dev button in release builds. The removal is a manual source-code deletion later, not a runtime toggle.
- NOT included: Any `go_router` feature beyond the flat two-route table: **no** `ShellRoute`, **no** nested `GoRoute.routes`, **no** `redirect:` / guards, **no** `refreshListenable:`, **no** `errorBuilder:` / `errorPageBuilder:` override, **no** `initialLocation:` override, **no** `observers:`, **no** `onException:`, **no** custom transitions, **no** `GoRouter.of` usage anywhere outside `home_screen.dart`'s single `context.push` call.
- NOT included: `go_router_builder` codegen, typed routes, or `TypedGoRoute` annotations. Plain `GoRoute` entries with string paths only.
- NOT included: Deep-link configuration in `ios/Runner/Info.plist` or `android/app/src/main/AndroidManifest.xml`. The app is not web and has no deep-link sources yet.
- NOT included: Web support (`flutter run -d chrome`, URL-bar behavior, `usePathUrlStrategy`). The project is iOS + Android only per `MEMORY.md` and CLAUDE.md.
- NOT included: Introducing `flutter_riverpod`, `ProviderScope`, `@riverpod` providers. Pattern in repo is `ValueNotifier` + `ListenableBuilder`; this spec follows it. If the router ever needs to react to auth state or similar, a future spec will decide whether to wrap `appRouter` in a Riverpod provider or add a `refreshListenable`.
- NOT included: Any code under `lib/features/home/domain/` or `lib/features/home/data/`. No entities, value objects, repositories, use cases, DTOs. Only `presentation/screens/` is created inside `features/home/`.
- NOT included: Any other `core/` changes beyond creating `lib/core/routing/app_router.dart`. `core/error/failures.dart`, `core/clock/`, `core/logging/`, `core/database/`, `core/notifications/`, `core/permissions/` remain absent. Constitution §7.1's ordered scaffolding is **not** otherwise advanced by this spec.
- NOT included: Custom theme work or any modification under `lib/core/theme/**`.
- NOT included: `freezed`, `freezed_annotation`, `fpdart`, `drift`, `flutter_local_notifications`, `permission_handler`, `clock`, `logging`.
- NOT included: New widget, unit, or integration tests beyond the forced edits to `test/widget_test.dart`. No new test files. No test for `app_router.dart` in isolation (the existing `widget_test.dart` tests exercise routing end-to-end via `DoslyApp`).
- NOT included: Upgrading `analysis_options.yaml` to the strict-mode config from constitution §7.4.
- NOT included: App icons, launch screens, splash screens, platform `Info.plist` / `AndroidManifest.xml` changes.
- NOT included: Localization / `flutter_localizations` / ARB files. Both strings are hardcoded English.
- NOT included: Accessibility semantics beyond Flutter defaults (no explicit `Semantics` wrapper, no custom labels).
- NOT included: `docs/` updates. The feature is too thin to warrant a doc page; `/finalize` for a later richer home-screen spec will pick it up. A follow-up spec should add routing guidance to `docs/architecture.md` once the route table has grown enough to have shape.
- NOT included: Any changes to `lib/main.dart`, `test/core/theme/theme_controller_test.dart`, or `test/core/theme/app_color_schemes_test.dart`.
- NOT included: Back-button / system-back behavior customization. `go_router`'s default pop behavior is accepted as-is.
- NOT included: Transition animation customization. `go_router`'s default `MaterialPage` transitions are used.

## 7. Technical Constraints

- **Must follow**: Clean Architecture directory layout — the home screen lives under `lib/features/home/presentation/screens/`; the router lives under `lib/core/routing/`.
- **Must follow**: The existing `ValueNotifier` + `ListenableBuilder` + `themeController` pattern in `lib/app.dart`. Do not refactor toward Riverpod. The `ListenableBuilder` wrapper around `MaterialApp.router` must stay; it's what propagates theme changes.
- **Must follow**: `go_router` as the routing solution (adopted in this spec). No `Navigator.push(MaterialPageRoute(...))` shortcuts from `HomeScreen`; the button uses `context.push('/theme-preview')`. Do not register routes via `MaterialApp.routes` — only via `appRouter`.
- **Must follow**: Constitution strict-mode rules already in force — no `!`, no `dynamic`, no `print`/`debugPrint`, all const-able widgets `const`.
- **Must follow**: Constitution rule *"Document new code — all new public functions/classes must have dartdoc (`///`) comments."* `HomeScreen` and `appRouter` each get a dartdoc.
- **Must follow**: Constitution rule *"Never leave bare TODOs — every TODO must have context and a reference."* Temporary-scaffold TODOs reference `specs/002-main-screen/spec.md`.
- **Must follow**: CLAUDE.md rule #12 *"search before building"* — reuse existing `DoslyApp`, `AppTheme`, `themeController`, `ThemePreviewScreen`.
- **Must not break**: `flutter test`, `dart analyze`, `flutter build apk --debug`.
- **Must not break**: Theme cycling behavior. `themeController`'s API is untouched; the cycle button's call site inside `ThemePreviewScreen` is untouched.
- **Must use**: `package:go_router/go_router.dart` in exactly two files: `lib/core/routing/app_router.dart` (defining `appRouter`) and `lib/features/home/presentation/screens/home_screen.dart` (for the `context.push` extension method). Nowhere else.
- **Keep the router minimal**: Flat route table, two entries. Every `go_router` feature not explicitly listed in AC-2 is forbidden in this spec. Resist the temptation to "add error handling while we're here" or "set up a ShellRoute for future bottom-nav" — those are separate specs.
- **Pubspec discipline**: Add `go_router` only. No `go_router_builder`, no `build_runner`, no codegen dependencies.

## 8. Open Questions

1. **Version constraint for `go_router`.** Default: let `/plan` or `/execute-task` run `flutter pub add go_router` and accept whatever caret constraint pub.dev resolves (currently `^16.x` or similar — not pinned in this spec because it will be the then-current latest at implementation time). Alternative: pin to a specific known-good version. *Recommendation*: accept pub.dev's latest. The package is officially "feature-complete, focused on stability and bug fixes" (pub.dev), so pinning is unnecessary paranoia.

2. **`appRouter` lifecycle.** Default: top-level `final GoRouter appRouter = GoRouter(...)` — a module-level constant, matching the existing `themeController` pattern (`lib/core/theme/theme_controller.dart` exports a top-level `final themeController = ...`). Alternative: expose it through a Riverpod provider. *Recommendation*: top-level constant. It matches the repo's existing state pattern, tests can pump `DoslyApp` without touching the router directly, and migration to a provider is a one-file change if/when Riverpod lands.

3. **Button style and placement.** Default: `OutlinedButton` labelled `'Theme preview'`, placed below the "Hello World" `Text` in a centered `Column` with a 24-pixel `SizedBox` gap. Alternatives: `TextButton` (more subtle), `FilledButton.tonal` (more prominent), `IconButton` in an AppBar (requires adding AppBar, which I deliberately avoided). *Recommendation*: `OutlinedButton`. Visible enough to tap during development without signalling "primary action". Easy to flip at approval time or later.

4. **Manual simulator verification (AC-18).** `/execute-task` runs `dart analyze`, `flutter test`, and `flutter build apk --debug` but does not auto-launch a simulator. AC-18 is a manual check the user performs during `/verify`. If you'd rather rely purely on automated gates (AC-13/14/15), tell me and I'll drop AC-18. *Recommendation*: keep AC-18.

5. **`HomeScreen` importing `package:go_router/go_router.dart`.** The `context.push` extension method is defined on `BuildContext` in the `go_router` package, so `HomeScreen` must import it. This is the one place `go_router` leaks into a feature layer in this spec. Alternative: wrap the push in a helper inside `app_router.dart` (e.g., `void pushThemePreview(BuildContext context) => context.push('/theme-preview')`). *Recommendation*: keep the direct `context.push` call in `HomeScreen`. Adding a one-line helper in `app_router.dart` for a call site that's scheduled for deletion is ceremony for its own sake.

6. **`appRouter` test isolation.** Because `appRouter` is a top-level `final`, its internal navigation-stack state persists across widget tests. If a test navigates to `/theme-preview` and doesn't pop back, the next test inherits that location. Default approach in this spec: the only test that navigates (AC-12) completes its flow by tapping the cycle button on the preview screen — it does not need to pop back, and the subsequent `setUp` only resets `themeController`, not the router. If this becomes flaky, a future fix is to either (a) add `appRouter.go('/')` to `setUp`, or (b) convert `appRouter` to a factory function and rebuild it per test. *Recommendation*: ship the simple version; revisit only if the test actually flakes. Flagged here so future-you has the trail.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `go_router` resolves a version whose API differs from what `/plan` assumes (e.g., `state.params` vs `state.pathParameters`) | Low | Low | This spec defines zero-parameter routes only, so path-parameter API differences are irrelevant. `/plan` will fetch live docs via context7 before writing any `GoRoute` body, per Phase 3 discipline. |
| Top-level `appRouter` state leaks between widget tests (navigation stack persists) | Med | Low | See Open Questions §8 #6. Mitigation: AC-12's test flow does not require a clean router state on entry. If other tests get added later, convert to factory. |
| `ListenableBuilder` rebuilding `MaterialApp.router` causes router state reset | Very Low | Med | `MaterialApp.router` reads `routerConfig` on each build; the `GoRouter` instance holds its own navigation stack internally and is not recreated. This is the standard and documented pattern. AC-14 (`flutter test`) catches regressions. |
| `/plan` or `/breakdown` over-scopes toward `ShellRoute`, `redirect:`, or `errorBuilder:` because they're "free to add" | Med | Med | Section 6 is binding and explicitly lists every `go_router` feature that is forbidden in this spec. `/plan` must treat §6 as the contract. |
| Cross-feature reference inside `app_router.dart` (imports both `features/home/...` and `features/theme_preview/...`) feels odd | Low | Low | `lib/core/routing/` lives above features and is the composition root for routing — it's the right place for feature wiring. Not a Clean Architecture violation. |
| `context.push('/theme-preview')` extension import pulls `go_router` into the feature layer | Low | Low | This is the standard go_router usage pattern documented on pub.dev. The alternative (helper function) is ceremony for a call site scheduled for deletion. Flagged in Open Questions §8 #5. |
| TODO comments get forgotten and shipped to production | Med | Low | TODOs reference `specs/002-main-screen/spec.md` for discoverability. The post-MVP cleanup spec should `grep -r 'specs/002-main-screen'` across `lib/` to find them. |
| Post-MVP cleanup spec forgets one of the three coordinated edits (route, button, folder) | Low | Med | Documented here in §6 as "three coordinated edits in one atomic spec" so the future spec has the removal checklist upfront. |
| Button mis-positioned on small screens (overflow, clipping) | Low | Low | `mainAxisSize: MainAxisSize.min` on the `Column` + `Center` wrapper ensures natural sizing; AC-18 manual check on a phone-size simulator confirms. |
| `go_router` breaking change between pub.dev current version and `/execute-task` run time | Very Low | Low | pub.dev states the package is feature-complete. Realistic window between `/plan` and `/execute-task` is minutes to days, not months. |
