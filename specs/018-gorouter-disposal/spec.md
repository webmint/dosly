# Spec: GoRouter Disposal via @riverpod Provider

**Date**: 2026-05-18
**Status**: Complete
**Author**: Claude + Webmint
**Tracks bug**: [bugs/007-gorouter-never-disposed.md](../../bugs/007-gorouter-never-disposed.md)
**Research**: [research/2026-05-18-bug-007-gorouter-disposal.md](../../research/2026-05-18-bug-007-gorouter-disposal.md)

## 1. Overview

Convert the top-level `final GoRouter appRouter` singleton in `lib/core/routing/app_router.dart:25` to a `@Riverpod(keepAlive: true)` codegen provider that registers `ref.onDispose(router.dispose)`. This closes bug 007 (a `ChangeNotifier` leak that is bounded in production but accumulates across test pumps), removes the only routing primitive in the codebase that bypasses Riverpod, and brings routing in line with constitution §4.1.1 ("Always use `@riverpod` codegen for new providers"). Bug 004's resolution (spec 015) made `riverpod_annotation`/`riverpod_generator` available — this fix is now mechanical.

## 2. Current State

**Production declaration** (`lib/core/routing/app_router.dart:25`):

```dart
final GoRouter appRouter = GoRouter(
  routes: [
    StatefulShellRoute.indexedStack(...),
    GoRoute(path: '/settings', ...),
    GoRoute(path: '/theme-preview', ...),
  ],
);
```

`GoRouter` extends `ChangeNotifier`. Nothing in the app ever calls `appRouter.dispose()`. The single production consumer is `lib/app.dart:91` (`routerConfig: appRouter`).

**Why it persisted**: When the router was introduced (feature 002), Riverpod had not yet landed in the codebase. `docs/architecture.md` § Routing currently states:

> `appRouter` mirrors the `themeController` pattern — a top-level `final` declared next to its module, not a Riverpod provider. Riverpod will arrive with the first real feature; the router was deliberately kept on plain primitives.

Spec 015 (closing bug 004) landed `riverpod_annotation` + `riverpod_generator` and migrated all other providers in the codebase. The router is the last remaining hand-rolled primitive. The doc rationale above is now stale.

**Why it's a real bug, not theoretical**: `test/core/routing/app_router_test.dart` already contains a workaround. Test 4 (AC-11 branch-stack preservation) cannot use the production `appRouter` because the production router has no sub-routes under any branch, so the test builds its own router via `_buildTestRouterWithSentinel()` (line 76) and must call `testRouter.dispose()` at line 269 to avoid leaked-`ChangeNotifier` warnings. The fact that the workaround exists and is documented in MEMORY (lines 184–185) confirms the leak is observable.

**Test consumers** (5 sites total):

- `test/core/routing/app_router_test.dart` — 6 tests:
  - Tests 1, 2, 3, 5, 6 pass the production `appRouter` to `_pumpRouter` (lines 153, 182, 213, 280, 309).
  - Test 4 builds a test-local router with a sentinel sub-route and disposes it manually (lines 250, 269).
- `test/widget_test.dart` — 3 tests pumping `DoslyApp` inside a `ProviderScope`. They do NOT import `appRouter` directly; routing is reached through `DoslyApp`'s internal consumption.

**Constitution & docs context**:

- §2.1 `core/routing/` is the documented composition root (the one place allowed to import multiple feature folders simultaneously).
- §4.1.1 mandates `@riverpod` codegen for all providers.
- §2.2 mandates generated `*.g.dart` files committed next to source.
- §6.6 mandates `dart run build_runner build --delete-conflicting-outputs` after touching annotations.
- MEMORY line 141 confirms function-form `@riverpod` providers do NOT need a `name:` annotation — `GoRouter appRouter(Ref ref) { ... }` emits `appRouterProvider` directly.
- `lib/core/providers/shared_preferences_provider.dart` is the canonical function-form `@Riverpod(keepAlive: true)` exemplar.

## 3. Desired Behavior

After this spec:

1. The top-level `final GoRouter appRouter` is **gone**. Anyone importing `appRouter` as a value gets a compile error.
2. `lib/core/routing/app_router.dart` declares one function-form provider:

   ```dart
   @Riverpod(keepAlive: true)
   GoRouter appRouter(Ref ref) {
     final router = GoRouter(routes: [/* same topology */]);
     ref.onDispose(router.dispose);
     return router;
   }
   ```

   The emitted symbol is `appRouterProvider`. `keepAlive: true` matches the historical app-lifetime singleton semantics.
3. `lib/app.dart`'s `DoslyApp.build` reads the router via `ref.watch(appRouterProvider)` and passes it to `MaterialApp.router(routerConfig: ...)`. No other `app.dart` change.
4. `lib/core/routing/app_router.g.dart` exists and is committed.
5. **Test consumers**:
   - `test/core/routing/app_router_test.dart`'s `_pumpRouter(WidgetTester, GoRouter)` helper either (a) keeps its signature and is called with a router read from a `ProviderContainer` inside each test, or (b) is reshaped to accept an optional override and read `appRouterProvider` itself. The end state has tests 1, 2, 3, 5, 6 driven through `appRouterProvider` with no direct import of a top-level `appRouter` symbol (because that symbol no longer exists).
   - **Test 4** uses `appRouterProvider.overrideWith((ref) { final r = _buildTestRouterWithSentinel(); ref.onDispose(r.dispose); return r; })`. The explicit `testRouter.dispose()` at the end of Test 4 is removed — `ref.onDispose` handles it when the `ProviderScope` tears down at the end of the test. The `_buildTestRouterWithSentinel()` helper itself stays (it defines a different ROUTE TOPOLOGY, which is its real purpose).
   - `test/widget_test.dart` requires no source changes — `DoslyApp` is already a `ConsumerWidget` and reads the provider internally. (If a `pump` ordering issue surfaces, address per `/plan`.)
6. The router's runtime behavior — every route in the production table, branch order, AppShell wiring, `/settings` push semantics, `/theme-preview` dev route — is **byte-identical** to the pre-fix behavior. No route is added, removed, or reshaped. `dart analyze` stays clean. `flutter test` shows the same passing-test count, with no leaked-`ChangeNotifier` warnings.
7. `docs/architecture.md` § Routing is updated to reflect the new pattern. The stale "router was deliberately kept on plain primitives" paragraph is replaced with one describing the `@Riverpod(keepAlive: true)` shape, the `ref.onDispose(router.dispose)` lifecycle binding, and the `appRouterProvider.overrideWith(...)` test-override idiom.
8. `bugs/007-gorouter-never-disposed.md` has Status flipped to `Fixed`, `Fixed:` date set, and a Resolution section linking back to spec 018.

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Router declaration | `lib/core/routing/app_router.dart` | Remove top-level `final`; add `@Riverpod(keepAlive: true)` function-form provider; add `part 'app_router.g.dart';`; add `riverpod_annotation` import |
| Router declaration (generated) | `lib/core/routing/app_router.g.dart` | Create new (`build_runner` output); commit per §2.2 |
| Production consumer | `lib/app.dart` | Change `routerConfig: appRouter` → `routerConfig: ref.watch(appRouterProvider)`; add import of the new provider |
| Routing integration tests | `test/core/routing/app_router_test.dart` | (a) Tests 1, 2, 3, 5, 6: switch from `await _pumpRouter(tester, appRouter)` to a flow that reads `appRouterProvider` from the test's `ProviderScope`; (b) Test 4: switch to `appRouterProvider.overrideWith(...)` with `ref.onDispose(r.dispose)`; drop the explicit `testRouter.dispose()` |
| App widget tests | `test/widget_test.dart` | Expected: no change (consumes `DoslyApp` only). Verify during `/plan`/`/breakdown` and if needed add a no-op assertion that the provider exists in scope |
| Architecture docs | `docs/architecture.md` | § Routing: replace the "kept on plain primitives" paragraph; describe the `@Riverpod(keepAlive: true)` shape + `ref.onDispose` + the `overrideWith` test idiom |
| Bug bookkeeping | `bugs/007-gorouter-never-disposed.md` | Status → Fixed; set Fixed date; add Resolution section linking spec 018 |

## 5. Acceptance Criteria

- [x] **AC-1**: `lib/core/routing/app_router.dart` declares exactly one top-level provider — a function-form `@Riverpod(keepAlive: true) GoRouter appRouter(Ref ref) { ... }`. Verified by `grep -nE "^final GoRouter appRouter" lib/core/routing/app_router.dart` returning zero matches AND `grep -nE "@Riverpod\\(keepAlive: true\\)" lib/core/routing/app_router.dart` returning exactly one match.
- [x] **AC-2**: The provider's body calls `ref.onDispose(router.dispose)` before returning. Verified by `grep -nE "ref\\.onDispose\\(router\\.dispose\\)" lib/core/routing/app_router.dart` returning exactly one match.
- [x] **AC-3**: `lib/core/routing/app_router.g.dart` exists, is committed (`git ls-files lib/core/routing/app_router.g.dart` is non-empty), and declares an `appRouterProvider` symbol. Verified by `grep -nE "appRouterProvider" lib/core/routing/app_router.g.dart` returning ≥ 1 match.
- [x] **AC-4**: The function-form provider does NOT carry a `name:` annotation argument (per MEMORY line 141, function-form providers emit the correct symbol without it). Verified by `grep -nE "name: '" lib/core/routing/app_router.dart` returning zero matches.
- [x] **AC-5**: `lib/app.dart` reads the router via `ref.watch(appRouterProvider)` and passes the result to `MaterialApp.router(routerConfig: ...)`. Verified by `grep -nE "ref\\.watch\\(appRouterProvider\\)" lib/app.dart` returning ≥ 1 match AND `grep -nE "routerConfig: appRouter\\b" lib/app.dart` returning zero matches.
- [x] **AC-6**: No source file under `lib/` outside the new provider file references the bare identifier `appRouter` as a value. Verified by `grep -rnE "\\bappRouter\\b" lib/ | grep -v "lib/core/routing/app_router\\.dart" | grep -v "lib/core/routing/app_router\\.g\\.dart" | grep -v "appRouterProvider"` returning zero matches.
- [x] **AC-7**: `test/core/routing/app_router_test.dart` Test 4 (AC-11 branch-stack preservation) uses `appRouterProvider.overrideWith(...)` and does NOT contain a bare `testRouter.dispose()` call. Verified by `grep -nE "appRouterProvider\\.overrideWith" test/core/routing/app_router_test.dart` returning ≥ 1 match AND `grep -nE "testRouter\\.dispose\\(\\)" test/core/routing/app_router_test.dart` returning zero matches.
- [x] **AC-8**: All routes from the production table render at the same paths with the same shell membership (`/`, `/meds`, `/history` under shell; `/settings`, `/theme-preview` outside). Verified by the existing 6 tests in `test/core/routing/app_router_test.dart` continuing to pass with no AC text changes.
- [x] **AC-9**: `dart analyze 2>&1 | head -40` is clean (no errors, no new warnings) after `dart run build_runner build --delete-conflicting-outputs`.
- [x] **AC-10**: `flutter test` passes with the same passing-test count as `main` at fix start (current main: 185+ tests passing per spec 017 verify report), and reports zero "A ChangeNotifier was used after being disposed" or "ChangeNotifier with N listeners was leaked" diagnostics.
- [x] **AC-11**: `flutter build apk --debug` succeeds.
- [x] **AC-12**: `docs/architecture.md` § Routing is updated. The phrase "the router was deliberately kept on plain primitives" no longer appears. The new text mentions `@Riverpod(keepAlive: true)`, `ref.onDispose(router.dispose)`, and `appRouterProvider.overrideWith(...)`. Verified by `grep -nE "kept on plain primitives" docs/architecture.md` returning zero matches AND `grep -nE "appRouterProvider" docs/architecture.md` returning ≥ 1 match.
- [x] **AC-13**: `bugs/007-gorouter-never-disposed.md` front-matter Status is `Fixed`, `Fixed:` has today's date (2026-05-18 or later — match the implementation date per MEMORY line 147), and a Resolution section links spec 018. Verified by `grep -nE "^\\*\\*Status\\*\\*: Fixed$" bugs/007-gorouter-never-disposed.md` and `grep -nE "spec 018\\|018-gorouter-disposal" bugs/007-gorouter-never-disposed.md` each returning ≥ 1 match.

## 6. Out of Scope

- **NOT included**: Removal of `_buildTestRouterWithSentinel()` from `test/core/routing/app_router_test.dart`. This helper exists because Test 4 needs a different ROUTE TOPOLOGY (a sentinel child route under `/meds`) — that purpose survives the lifecycle fix. Only the lifecycle workaround inside the test (`testRouter.dispose()`) is replaced.
- **NOT included**: Adding a `GoRouter.errorBuilder` to handle malformed deep links. That's tracked separately by `bugs/008-approuter-no-errorbuilder.md` and was previously deferred to the feature that first ships deep linking.
- **NOT included**: Any change to the route topology — `/`, `/meds`, `/history`, `/settings`, `/theme-preview` are byte-identical pre- and post-fix.
- **NOT included**: Reordering or renaming the three `StatefulShellBranch`es. Branch order is load-bearing (matches `AppBottomNav` destination order per spec 005 / spec 007).
- **NOT included**: Refactoring `lib/app.dart`'s `_resolveLocale` / `_toFlutterThemeMode` / `ref.watch(settingsNotifierProvider.select(...))` calls — those are unrelated.
- **NOT included**: Removal or rewrite of the `TODO(post-mvp)` comment on the `/theme-preview` route (tracked by spec 002 post-MVP cleanup).
- **NOT included**: Adding a typed logger or sanitize layer (tracked by `bugs/017-typed-logger-missing.md`).
- **NOT included**: Any new dependency. `riverpod_annotation`, `riverpod_generator`, `build_runner`, and `go_router` are all already in `pubspec.yaml`.

## 7. Technical Constraints

- Must follow **constitution §4.1.1**: `@riverpod` codegen, not hand-rolled providers.
- Must follow **constitution §2.1**: `lib/core/routing/` remains the routing composition root (no layer-boundary changes).
- Must follow **constitution §2.2**: the generated `app_router.g.dart` is committed to the repo next to its source.
- Must follow **constitution §6.6**: run `dart run build_runner build --delete-conflicting-outputs` after editing annotations.
- Must follow **constitution §3.1**: no `!` introduced; no unchecked `as`. (Trivially satisfied — the refactor adds no nullable touch points.)
- Must mirror the **function-form codegen shape** of `lib/core/providers/shared_preferences_provider.dart` (the project's canonical `@Riverpod(keepAlive: true)` exemplar).
- Must NOT introduce a `name:` annotation argument — per MEMORY line 141, function-form providers emit the correct symbol (`appRouterProvider`) directly.
- Must NOT introduce a backwards-compat `appRouter` getter that reads the provider — symbol replacement is total per Phase 2 decision.
- Must NOT break `test/widget_test.dart` — if a test ordering or pump issue surfaces, it MUST be addressed without rewriting the existing tests' assertions.

## 8. Open Questions

- **Pump ordering for `test/widget_test.dart`**: The widget tests pump `DoslyApp` inside a `ProviderScope` and call `pumpAndSettle()`. `appRouterProvider` will resolve synchronously when `DoslyApp.build` runs `ref.watch`. No async hop is added. If for any reason an extra `pump()` is required to settle, `/plan` should specify it; otherwise the file needs no edit.
- **`_pumpRouter` helper signature in `app_router_test.dart`**: two equally valid shapes — (a) keep `(WidgetTester, GoRouter)` and pass `container.read(appRouterProvider)` from each call site, or (b) drop the `GoRouter` parameter and have the helper itself stand up a `ProviderScope` and read the provider. Decision deferred to `/plan` — pick the lower-churn option.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Test 4's `overrideWith` callback runs early/late and the override isn't honored | Low | Medium (Test 4 fails) | `ProviderScope` resolves overrides synchronously on the first `ref.read`/`ref.watch` of the provider. `MaterialApp.router`'s build triggers that read. Verified by parallel pattern: `settingsRepositoryProvider.overrideWithValue(...)` already works in the same test file. |
| `test/widget_test.dart` ordering surprises | Low | Low | The three existing tests already pump `ProviderScope(child: const DoslyApp())` and call `pumpAndSettle()`. The `appRouterProvider` is `keepAlive: true` and synchronous. If a test fails, `/plan` adjusts pump count without rewriting assertions. |
| `dart analyze` complaints from new `riverpod_annotation` import in `lib/core/routing/` | Low | Low | `riverpod_annotation` is already in `pubspec.yaml` and used by `shared_preferences_provider.dart`. Pattern proven. |
| Lost `appRouter` symbol breaks an unexpected non-test consumer | Very low | Low | AC-6 enforces a `grep` audit of all `lib/` for bare `appRouter` references. Anything found is in scope of this fix. |
| `_buildTestRouterWithSentinel()` lifecycle now bound to a child `ProviderScope` causes Test 4 to dispose the router while a navigation is in flight | Very low | Medium (Test 4 flake) | `pumpAndSettle()` is called between every navigation and the test's terminal assertion; provider disposal happens at the end of the test after the final assertion. Equivalent to the current `testRouter.dispose()` at line 269. |
| Doc update edits an unrelated paragraph by accident | Low | Low | Doc edit is constrained to the § Routing section's "kept on plain primitives" paragraph + (optionally) one new paragraph; AC-12 enforces both content checks. |
| `build_runner` regenerates unrelated `*.g.dart` files (e.g., settings_provider.g.dart) producing a noisy diff | Medium | Low | Acceptable per spec 015 MEMORY guidance — generated diffs that come along for the ride are committed alongside. |
