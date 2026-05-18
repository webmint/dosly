# Research: Bug 007 — Top-level `GoRouter` `ChangeNotifier` Never Disposed

**Date**: 2026-05-18
**Topic**: Bug 007 — Top-level `GoRouter` `ChangeNotifier` never disposed
**Verdict**: **Feasible** (mechanical, single-file refactor)

## Summary

`lib/core/routing/app_router.dart:25` declares `final GoRouter appRouter` as a top-level constant. `GoRouter` extends `ChangeNotifier`, and this instance is never disposed. In production the leak is bounded (one instance per process), but the test suite already had to compensate (`test/core/routing/app_router_test.dart:76 _buildTestRouterWithSentinel()` + `testRouter.dispose()` at line 269). The bug file already prescribes the fix: wrap the router in a `@riverpod` codegen provider with `ref.onDispose(router.dispose)`. With spec 015 having landed `riverpod_annotation`/`riverpod_generator` (bug 004 resolved), this is now a mechanical 1-source-file + 1-consumer-file refactor.

## Codebase Findings

### Existing Related Code
| Area | Files | Relevance |
|------|-------|-----------|
| Router declaration | `lib/core/routing/app_router.dart:25` | The leak site — top-level `final GoRouter appRouter` |
| Router consumer | `lib/app.dart:91` | `routerConfig: appRouter` (the only production consumer) |
| Test router workaround | `test/core/routing/app_router_test.dart:76, 269` | `_buildTestRouterWithSentinel()` + manual `testRouter.dispose()` — evidence the leak is real, not theoretical |
| Test pump helper | `test/core/routing/app_router_test.dart:124–140` | Builds `MaterialApp.router(routerConfig: router, ...)` inside a `ProviderScope` — already plumbed to accept an override |
| Riverpod codegen reference (function-form) | `lib/core/providers/shared_preferences_provider.dart` | `@Riverpod(keepAlive: true) SharedPreferencesWithCache sharedPreferences(Ref ref) => ...` — exact shape to mirror |
| Riverpod codegen reference (class-form) | `lib/features/settings/presentation/providers/settings_provider.dart` | `@Riverpod(keepAlive: true, name: '...')` — class-form, NOT needed here |

### Patterns Available
- **`@riverpod` function-form provider** (in use): function-form does NOT need a `name:` annotation (MEMORY line 141). Emits `appRouterProvider` automatically from `GoRouter appRouter(Ref ref) { ... }`.
- **`ref.onDispose(callback)`**: standard Riverpod lifecycle hook — ties `router.dispose()` to provider disposal.
- **`@Riverpod(keepAlive: true)`**: prevents auto-dispose when no listener is mounted (correct for an app-lifetime singleton).
- **Test override**: `ProviderScope(overrides: [appRouterProvider.overrideWith((ref) => testRouter)])` — replaces the test helper without touching production routes.

### Gaps
- None. All required infrastructure (codegen, generated-file commit policy, test scope override) is already in place.

## Constitution Constraints

| Rule | Impact on This Idea |
|------|--------------------|
| §4.1.1 "Always use `@riverpod` codegen for new providers" | Directly mandates this refactor's approach |
| §2.1 layer boundaries | `core/routing/` is the right home (current location); no boundary crossing |
| §6.6 codegen step | Must run `dart run build_runner build --delete-conflicting-outputs` and commit `app_router.g.dart` |
| §2.2 generated files committed | `app_router.g.dart` must be added to git |
| §3.1 no `!`, no unchecked `as` | Trivially satisfied — refactor adds no new nullable touch points |
| §6.1 minimal changes | Scope is naturally minimal: 1 source file, 1 consumer file (`app.dart`), 1 generated `.g.dart` |

## Approaches

### Option A: `@riverpod` codegen provider with `ref.onDispose` (the bug file's prescription)

- **Description**: Convert `final GoRouter appRouter = ...` to `@Riverpod(keepAlive: true) GoRouter appRouter(Ref ref) { final router = GoRouter(...); ref.onDispose(router.dispose); return router; }`. Update `app.dart` to `routerConfig: ref.watch(appRouterProvider)`.
- **Pros**:
  - Constitution-aligned (§4.1.1)
  - Tied to `ProviderScope` lifetime → disposed automatically when the scope tears down (which IS how tests behave when a new `ProviderScope` is pumped)
  - Eliminates the need for `_buildTestRouterWithSentinel()` long-term — tests can `overrideWith` a per-test router
  - Mirrors `sharedPreferencesProvider` shape (already proven in the codebase)
  - MEMORY line 141 confirms function-form needs no `name:` annotation — emits `appRouterProvider` directly
- **Cons**:
  - `app.dart`'s `DoslyApp` is already a `ConsumerWidget` (no churn — it already calls `ref.watch`)
  - The `_buildTestRouterWithSentinel()` removal is a follow-up nicety, not part of this fix's minimum scope
- **Complexity**: **Low** (mechanical)

### Option B: `Provider` (manual) wrapper with `ref.onDispose`

- **Description**: Same lifecycle binding but using `Provider<GoRouter>((ref) { ... ref.onDispose(...); return router; })` instead of codegen.
- **Pros**: No build_runner step
- **Cons**:
  - Violates constitution §4.1.1 ("No manual `Provider`/`StateNotifierProvider` declarations")
  - Re-introduces exactly the anti-pattern spec 015 eliminated
- **Complexity**: Low, but **disqualified by the constitution**

### Option C: Convert `DoslyApp` to `StatefulWidget` + dispose in `dispose()`

- **Description**: Make `DoslyApp` stateful, own `GoRouter` as a field, dispose it in `State.dispose()`.
- **Pros**: No dependency on Riverpod for routing
- **Cons**:
  - The root widget's `dispose()` only fires on app teardown — same effective lifecycle as the current leak in production
  - Doesn't help the test scenario (tests still need their own router)
  - Forces `DoslyApp` from `ConsumerWidget` to `ConsumerStatefulWidget` (more code churn than Option A)
  - Diverges from the project's "always use codegen for state-shaped objects" idiom
- **Complexity**: Medium (more churn than A, no real benefit)

**Recommended approach**: **Option A** — directly matches the bug file's prescription, satisfies constitution §4.1.1, mirrors the existing `sharedPreferencesProvider` shape, and unblocks future test cleanup.

## Complexity Assessment

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Codebase changes | **Low** | 2 files edited (`app_router.dart`, `app.dart`) + 1 generated (`app_router.g.dart`) |
| New dependencies | **None** | `riverpod_annotation`, `riverpod_generator`, `build_runner`, `go_router` all already present |
| Risk | **Low** | Function-form codegen pattern proven by `sharedPreferencesProvider`; `app.dart` is already a `ConsumerWidget`; existing tests use a `ProviderScope` that can absorb the new provider |

### Likely scope (precise)
- `lib/core/routing/app_router.dart` — wrap in `@Riverpod(keepAlive: true) GoRouter appRouter(Ref ref)`, add `ref.onDispose(router.dispose)`, add `part 'app_router.g.dart';`, import `riverpod_annotation`
- `lib/app.dart` — change `routerConfig: appRouter` → `routerConfig: ref.watch(appRouterProvider)`
- `lib/core/routing/app_router.g.dart` — generated, committed
- Test consumers (`test/core/routing/app_router_test.dart`, `test/widget_test.dart`) — currently pass `appRouter` directly to the pump helper; they will need to either (a) read `appRouterProvider` from the `ProviderScope` they already mount, or (b) keep working by importing the new public `appRouterProvider` symbol. Verify during `/plan`.

### Open questions for `/specify`
- Should test 4's `_buildTestRouterWithSentinel()` be cleaned up in the same fix (replace with `appRouterProvider.overrideWith(...)`)? Or defer to a follow-up — keeping the fix minimal per §6.1 — and leave the workaround in place?
- Naming: keep the public symbol identifier `appRouter` as a top-level alias for ergonomics, or only expose `appRouterProvider`? (Recommend: only expose `appRouterProvider` — Option A's whole point is lifecycle binding.)

## Recommendation

**Proceed** — this is a well-scoped, mechanical fix. Bug 004 (the codegen prerequisite) is already resolved. The bug file already prescribes the exact shape.

Suggested next command:

```
/fix "Bug 007: wrap appRouter in @riverpod codegen provider with ref.onDispose(router.dispose) per bugs/007-gorouter-never-disposed.md"
```

`/fix` is appropriate here (not `/specify`) because the scope is ≤5 files, behavior-preserving, and a tracking bug file already exists. If `/fix` Phase 2 surfaces the test-cleanup question above as larger than expected, it will recommend escalation to `/specify`.
