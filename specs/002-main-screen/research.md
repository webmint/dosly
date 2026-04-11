# Research: Main Screen — go_router Foundation

**Date**: 2026-04-11
**Signals detected**: `go_router` is not in `pubspec.yaml`; first routing library adopted in dosly; architectural decision between `Navigator 1.0` / `MaterialApp.routes` / `go_router` / `auto_route`.

## Questions Investigated

1. **Should dosly adopt a routing library now, or stick with `MaterialApp.routes` as a built-in stopgap?**
   → **Adopt `go_router` now.** Real screens are planned (medications, schedules, intakes, settings per `MEMORY.md`). Migrating a 1-route stopgap → full router later costs more than paying the routing setup once while the surface is tiny. User argument (captured in spec discussion): "we will have another screens so go with best practice. because later u will have to change route systme again."

2. **Which routing package?**
   → **`go_router`.** Flutter-team-maintained, built on Navigator 2.0, declared "feature-complete, focused on stability and bug fixes" on pub.dev as of the research date. Referenced by constitution §7.1 item 9.

3. **What is the current `go_router` API shape?** (Verified against live pub.dev docs via context7 during spec Phase 3, not training-data memory.)
   → `GoRouter(routes: [GoRoute(path: '/', builder: (context, state) => ...), ...])` wired into `MaterialApp.router(routerConfig: _router)`. Imperative navigation via `context.push('/path')` / `context.pop()` / `context.go('/path')` extension methods on `BuildContext`. Path parameters (not needed in this spec): `state.pathParameters['id']` in current major versions (older code used `state.params` — stale examples appear in some docs snippets).

4. **What version should we pin to?**
   → **Let `flutter pub add go_router` resolve the current latest stable caret constraint at implementation time.** pub.dev's "feature-complete" status means floating constraints are safe — active breaking-change churn is no longer a concern. `/execute-task` will record the resolved version in `pubspec.lock`.

5. **How does `MaterialApp.router` interact with the existing `ListenableBuilder(listenable: themeController, ...)` wrapper in `lib/app.dart`?**
   → **No conflict.** `ListenableBuilder` rebuilds its child (the `MaterialApp.router`) on every `themeController` change. `MaterialApp.router` reads `routerConfig` on each build, but the `GoRouter` instance itself (`appRouter`) holds its own navigation-stack state internally and is not recreated — the rebuild just re-attaches the existing router to a fresh `MaterialApp`. This is the standard documented pattern for reactive theme + routing coexistence.

6. **How do `context.push` and `context.go` differ for the dev "Theme preview" button?**
   → **`context.push` pushes onto the stack**, preserving `HomeScreen` underneath so Flutter's default `AppBar` back button pops naturally. **`context.go` replaces the stack**, which would break back-navigation and require custom `WillPopScope` handling. Use `push` for this spec.

7. **Is cross-feature importing allowed in `lib/core/routing/app_router.dart`?** (The router imports both `features/home/...` and `features/theme_preview/...`.)
   → **Yes.** `lib/core/routing/` sits above `features/` in the Clean Architecture stack and is the composition root for routing wiring. Features themselves should not import each other, but the composition root is the *one* place cross-feature references belong. Not a violation.

8. **Is `HomeScreen` importing `package:go_router/go_router.dart` (for the `context.push` extension) a feature-layer leak?**
   → **Technically yes; pragmatically accepted.** This is the standard go_router usage pattern documented on pub.dev. The alternative — wrapping `context.push('/theme-preview')` in a helper function inside `app_router.dart` — is ceremony for a call site (the dev button) scheduled for deletion post-MVP. Open Question §8 #5 in the spec answered: keep the direct call.

## Alternatives Compared

### Routing library

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **`go_router`** | Flutter-team-maintained; declarative; Navigator 2.0 based; feature-complete/stable per pub.dev; constitution §7.1 alignment; deep-link ready when needed; shell routes available for future bottom-nav | Slight learning curve vs. raw Navigator; one more dependency; extension methods on `BuildContext` leak into feature files | **Chosen** |
| `MaterialApp.routes` (built-in) | Zero dependencies; trivial for 1–2 routes | No deep linking; no type safety; no guards; migration to go_router later costs a second rewrite; Navigator 1.0 is legacy | Rejected — defers cost, doesn't eliminate it |
| Inline `Navigator.push(MaterialPageRoute(...))` | Zero dependencies; zero routing infrastructure | `HomeScreen` must import `ThemePreviewScreen` → cross-feature dependency smell; no named routes; Navigator 1.0 legacy | Rejected — architectural smell + deferred migration |
| `auto_route` | Stronger type safety than go_router; nested-route ergonomics | Third-party (not Flutter-team); heavy codegen dependency (`build_runner`); minority choice; breaking changes historically | Rejected — not Flutter-team, codegen overhead, minority ecosystem |
| `beamer` | Navigator 2.0 wrapper | Momentum shifted to go_router after Google's adoption; smaller community | Rejected — losing momentum |
| Raw Navigator 2.0 (`Router` / `RouterDelegate` / `RouteInformationParser`) | Maximum control | Verbose; `go_router` exists to avoid this | Rejected — re-inventing the wheel |

**Decision**: `go_router` — Flutter-team-maintained, feature-complete, constitution-aligned, sized correctly for dosly's eventual screen count.

### Router instance lifetime

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **Top-level `final GoRouter appRouter = GoRouter(...)` in `app_router.dart`** | Mirrors existing `themeController` pattern (`lib/core/theme/theme_controller.dart:46`); zero DI overhead; easy to import | Module-level state can leak across widget tests (flagged in spec Open Q §8 #6) | **Chosen** |
| Riverpod provider wrapping `GoRouter` | Per-test lifecycle; DI-native | Forces Riverpod adoption (this project doesn't use Riverpod yet) | Rejected — adopting Riverpod is a separate decision |
| Factory function `GoRouter buildRouter() => GoRouter(...)` called once in `main.dart` | Per-test lifecycle; no module state | Inconsistent with `themeController` pattern; extra plumbing | Rejected for this spec; reserved as a fallback if router test-isolation flakes |

**Decision**: top-level constant. Matches the one existing pattern in the repo.

### Navigation method for the dev button

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **`context.push('/theme-preview')`** | Preserves `HomeScreen` underneath; default AppBar back button pops naturally | Navigation stack grows (irrelevant for 2 screens) | **Chosen** |
| `context.go('/theme-preview')` | Replaces the stack — leaner semantically for "navigate to" | Breaks back navigation; requires custom `WillPopScope` or similar to return to `HomeScreen` | Rejected — breaks expected back behavior |
| Helper `void openThemePreview(BuildContext context) => context.push('/theme-preview')` in `app_router.dart` | Removes `go_router` import from `HomeScreen`; one place to change the route string | Ceremony for a call site scheduled for deletion; indirection with no benefit at N=1 call site | Rejected — see Open Q #5 |

**Decision**: direct `context.push('/theme-preview')` in `HomeScreen`.

## References

- pub.dev live docs via context7: `/websites/pub_dev_go_router` — fetched during spec Phase 3 (2026-04-11) for `GoRouter`, `GoRoute`, `MaterialApp.router`, `context.push`/`pop`/`go`, and package status.
- `lib/core/theme/theme_controller.dart:46` — existing top-level constant pattern that `appRouter` will mirror.
- `lib/app.dart:22-34` — existing `ListenableBuilder` + `MaterialApp` shape that `MaterialApp.router` slots into.
- `test/widget_test.dart:1-42` — existing widget tests that will be rewritten for the new nav flow.
- `test/core/theme/theme_controller_test.dart:1-57` — 8 unit tests that already cover `ThemeController` cycling end-to-end, so the rewritten widget test is not the primary coverage for cycling.
- Constitution §7.1 item 9 — declares `lib/core/routing/app_router.dart` as the canonical location for go_router wiring.
- Constitution §3 line 240 — "No dead code" — resolved because `ThemePreviewScreen` stays reachable via the `/theme-preview` route.
- Constitution rule — "Never leave bare TODOs" — TODOs must reference `specs/002-main-screen/spec.md`.
