# Plan: GoRouter Disposal via @riverpod Provider

**Date**: 2026-05-18
**Spec**: [spec.md](spec.md)
**Status**: Approved

## Summary

Convert the top-level `final GoRouter appRouter` singleton to a function-form `@Riverpod(keepAlive: true)` provider that registers `ref.onDispose(router.dispose)`. The fix is mechanical: mirror the existing `lib/core/providers/shared_preferences_provider.dart` codegen shape, update the single production consumer (`lib/app.dart`), reshape the test pump helper to read the provider through a `Consumer`, rewire Test 4 to use `appRouterProvider.overrideWith(...)` with `ref.onDispose`, then update docs and close the bug file.

## Technical Context

**Architecture**: `lib/core/routing/` (composition root; the one place allowed to import multiple feature folders simultaneously, per constitution §2.1).
**Error Handling**: N/A — no fallible operations introduced. The provider's body builds and returns a `GoRouter` synchronously; `ref.onDispose` is a registration call, not an `Either`-producing operation.
**State Management**: Riverpod `@Riverpod(keepAlive: true)` function-form provider — matches `sharedPreferencesProvider`'s shape exactly.

## Constitution Compliance

| Rule | Status | Notes |
|---|---|---|
| §2.1 layer boundaries | Compliant | `core/routing/` is the documented composition root. No layer crossed. |
| §2.2 generated `.g.dart` committed | Compliant | `lib/core/routing/app_router.g.dart` will be generated and committed. |
| §3.1 no `!`, no unchecked `as`, no `dynamic` | Compliant | Refactor adds no nullable touch points. `Ref` and `GoRouter` are typed. |
| §4.1.1 always `@riverpod` codegen | Compliant — this fix IS the compliance | Removes the last hand-rolled routing primitive. |
| §4.1.1 const constructors when possible | Compliant | `GoRouter` itself is non-const (`ChangeNotifier`); leaves stay `const` where currently `const`. |
| §6.1 minimal changes | Compliant | 7 files total (3 lib/ + 2 test/ + 1 docs + 1 bug). Topology byte-identical. |
| §6.6 codegen step | Compliant | Plan calls out `dart run build_runner build --delete-conflicting-outputs`. |
| §3.3 naming | Compliant | Function name `appRouter` (lowerCamelCase imperative-noun) → emitted symbol `appRouterProvider`. Function-form — no `name:` annotation per MEMORY line 141. |

## Implementation Approach

### Layer Map

| Layer | What | Files |
|-------|------|-------|
| Core (routing) | Replace top-level `final` with `@Riverpod(keepAlive: true) GoRouter appRouter(Ref ref)`; register `ref.onDispose(router.dispose)` | `lib/core/routing/app_router.dart` (modify), `lib/core/routing/app_router.g.dart` (create) |
| Presentation (app root) | Read router via `ref.watch(appRouterProvider)` inside existing `ConsumerWidget` | `lib/app.dart` (modify) |
| Test (routing) | Reshape `_pumpRouter` to drop the `GoRouter` parameter, accept optional `overrides`, build a `Consumer` that watches `appRouterProvider`; rewire Test 4 to use `appRouterProvider.overrideWith` with internal `ref.onDispose` | `test/core/routing/app_router_test.dart` (modify) |
| Test (widget) | Verify no change required (DoslyApp consumes provider internally); add a guarded `pumpAndSettle` if a fixture surfaces an ordering issue | `test/widget_test.dart` (verify, modify only if needed) |
| Docs | Update § Routing in architecture doc | `docs/architecture.md` (modify) |
| Bookkeeping | Close bug 007 | `bugs/007-gorouter-never-disposed.md` (modify) |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|---|---|---|---|
| Provider form | Function-form `@Riverpod(keepAlive: true) GoRouter appRouter(Ref ref) { ... }` | Router is a single instance, not a notifier with mutation API. Mirrors `sharedPreferencesProvider` exactly. | Class-form `@Riverpod class AppRouterNotifier extends _$AppRouterNotifier` — adds boilerplate for zero benefit; would also require a `name:` annotation to keep the canonical provider symbol. |
| `keepAlive` | `keepAlive: true` | Router must outlive any transient absence of listeners (e.g., during a hot reload). Matches historical app-lifetime semantics. | `autoDispose` (the codegen default) — would tear down the router whenever no widget watches it briefly, defeating the entire purpose. |
| `name:` annotation | Omit | Function-form codegen emits `appRouterProvider` directly (no suffix-stripping happens for functions). MEMORY line 141 confirms. | `name: 'appRouterProvider'` — redundant; AC-4 forbids it. |
| `Ref` import | `package:riverpod_annotation/riverpod_annotation.dart` re-exports `Ref` | Same import pattern as `settings_provider.dart` and `shared_preferences_provider.dart`. No additional import needed. | Importing `package:riverpod/riverpod.dart` directly — works but inconsistent with codebase. |
| `ref.onDispose` argument | Pass `router.dispose` as a tearoff: `ref.onDispose(router.dispose)` | Matches the spec's AC-2 grep predicate (`ref\.onDispose\(router\.dispose\)`) and Dart's tear-off idiom (MEMORY line 184 confirms tear-offs are first-class). | `ref.onDispose(() => router.dispose())` — adds a closure for no reason; would fail AC-2's grep. |
| `appRouter` getter/alias | Remove the symbol entirely | Spec §3 decision #1 + AC-6 forbid any non-Provider `appRouter` reference outside the provider file itself. Two ways to do the same thing is constitution §4.1.1 anti-pattern. | Keep `appRouter` as a top-level getter reading the provider — risk: consumer reading the getter outside a Provider scope crashes; bypasses lifecycle binding; re-introduces the leak surface in spirit. |
| `_pumpRouter` helper signature | Drop the `GoRouter` parameter; add optional `List<Override> overrides = const []` parameter; helper builds the `ProviderScope` with the existing `settingsRepositoryProvider.overrideWithValue(_FakeSettingsRepository())` AND any caller-supplied overrides; the inner widget is a `Consumer` that does `routerConfig: ref.watch(appRouterProvider)` | Eliminates the unused `GoRouter` parameter once the production import is gone. Tests 1, 2, 3, 5, 6 become `await _pumpRouter(tester)`. Test 4 becomes `await _pumpRouter(tester, overrides: [appRouterProvider.overrideWith(...)])`. | (a) Keep `(WidgetTester, GoRouter)` and pass `container.read(appRouterProvider)` at each call site — works, but every call site re-pays the wiring cost. (b) Build a separate `_pumpTestRouter(tester, GoRouter)` for Test 4 only — duplicates the `ProviderScope`/`MaterialApp.router` boilerplate; not DRY. |
| Test 4 router lifecycle | `appRouterProvider.overrideWith((ref) { final r = _buildTestRouterWithSentinel(); ref.onDispose(r.dispose); return r; })` | The override callback runs once when the provider is first read, gets its own `Ref`, and is disposed when the `ProviderScope` tears down at test end. Mirrors the production provider's onDispose pattern. AC-7 enforces no bare `testRouter.dispose()` remains. | (a) Continue with `testRouter.dispose()` after the override — the override callback doesn't expose the instance to the test scope cleanly. (b) Keep the production `appRouter` accessible to tests as an escape hatch — violates AC-6. |
| `_buildTestRouterWithSentinel()` lifetime | Helper itself stays in place | Test 4 needs a different ROUTE TOPOLOGY (sentinel child route under `/meds`) — that is the helper's real purpose. Only its leak-workaround consumer (`testRouter.dispose()`) is rewritten. | Inline the helper into Test 4 — adds 30 lines to the test body; reduces readability; no win. |
| Docs update scope | Rewrite the § Routing "kept on plain primitives" paragraph in-place to describe the new `@Riverpod(keepAlive: true)` shape, `ref.onDispose(router.dispose)`, and the `appRouterProvider.overrideWith(...)` test idiom. Update the inline code sample to match. Leave the route topology, AppShell, conventions, and provider wiring table untouched (except adding `appRouterProvider` to the table). | Doc-vs-code drift is bug 012's lesson. The stale "deliberately kept on plain primitives" claim becomes false after this fix; ratifying it in this same spec prevents the same drift recurring. | Defer to `/finalize`'s tech-writer — recurring lesson from MEMORY line 100: forward-looking drift is best fixed *with* the code change, not after. |
| Bug closure timing | Close bug 007 in the docs/bookkeeping task (same task that updates `docs/architecture.md`) | Mirrors how bug 004 was closed by spec 015 and bug 002 by spec 013 — the bug file is bookkeeping, not source-code-touching work, so it belongs with the tech-writer task. | Close in a separate trailing task — bookkeeping is small enough to bundle. |

### File Impact

| File | Action | What Changes |
|---|---|---|
| `lib/core/routing/app_router.dart` | Modify | Replace `final GoRouter appRouter = GoRouter(...);` with `@Riverpod(keepAlive: true) GoRouter appRouter(Ref ref) { final router = GoRouter(routes: [...]); ref.onDispose(router.dispose); return router; }`. Add `part 'app_router.g.dart';`. Add `import 'package:riverpod_annotation/riverpod_annotation.dart';`. Library-level dartdoc updated to describe the new provider shape (consumer reads it via `ref.watch(appRouterProvider)`). |
| `lib/core/routing/app_router.g.dart` | Create | `build_runner` output. Declares `appRouterProvider` (`final appRouterProvider = AppRouterProvider._();`) — same shape as `sharedPreferencesProvider`'s generated file. Committed per §2.2. |
| `lib/app.dart` | Modify | One line in `DoslyApp.build`: `routerConfig: appRouter` → `routerConfig: ref.watch(appRouterProvider)`. Add import of `core/routing/app_router.dart` (already imported — verify and replace if the import line changes). Library-level dartdoc's mention of "delegated to [appRouter]" updated to "delegated to [appRouterProvider]". |
| `test/core/routing/app_router_test.dart` | Modify | (1) Drop `import 'package:dosly/core/routing/app_router.dart' show appRouter;` semantics — the import line stays for the new provider symbol. (2) Rewrite `_pumpRouter(WidgetTester tester, GoRouter router)` → `_pumpRouter(WidgetTester tester, {List<Override> overrides = const []})`. The new body wraps a `Consumer(builder: (context, ref, _) => MaterialApp.router(routerConfig: ref.watch(appRouterProvider), ...))` inside the existing `ProviderScope`, merging `[settingsRepositoryProvider.overrideWithValue(...)] + overrides`. (3) Tests 1, 2, 3, 5, 6: change call to `await _pumpRouter(tester);` (remove the `, appRouter` argument). (4) Test 4: change to `await _pumpRouter(tester, overrides: [appRouterProvider.overrideWith((ref) { final r = _buildTestRouterWithSentinel(); ref.onDispose(r.dispose); return r; })]);`. Remove the trailing `testRouter.dispose();` line. |
| `test/widget_test.dart` | Verify (expected no change) | All three tests pump `DoslyApp` inside `ProviderScope`. `DoslyApp` now reads `appRouterProvider` internally. No direct `appRouter` import in this file. If the test suite reports a `pump` ordering issue after running, address per Open Question §8 — minimum change. |
| `docs/architecture.md` | Modify | Section "## Routing" — replace the "kept on plain primitives" paragraph (around line 242, the third bullet under "### Conventions") with a new paragraph describing the `@Riverpod(keepAlive: true)` provider shape, the `ref.onDispose(router.dispose)` lifecycle binding, and the `appRouterProvider.overrideWith(...)` test-override idiom. Update the inline code snippet (around line 183) from `final GoRouter appRouter = ...` to the new function-form. Add `appRouterProvider` to the provider wiring table at line 124 with the entry `\| appRouterProvider \| @Riverpod(keepAlive: true) function \| App-wide GoRouter with onDispose-bound lifecycle \|`. |
| `bugs/007-gorouter-never-disposed.md` | Modify | Flip front-matter `**Status**: Open` → `**Status**: Fixed`; set `**Fixed**:` to the implementation date (yyyy-mm-dd matching when the source task completes — see MEMORY line 147 for the spec-date vs fix-date pattern). Append a `## Resolution` section: "Closed by [spec 018](../specs/018-gorouter-disposal/spec.md). `appRouter` is now a `@Riverpod(keepAlive: true)` function-form provider in `lib/core/routing/app_router.dart` that registers `ref.onDispose(router.dispose)`. Test 4 of `test/core/routing/app_router_test.dart` uses `appRouterProvider.overrideWith(...)` with `ref.onDispose` instead of a bare `testRouter.dispose()` call." |

### Documentation Impact

| Doc File | Action | What Changes |
|---|---|---|
| `docs/architecture.md` | Update | § Routing inline code sample + "kept on plain primitives" paragraph + provider wiring table (see File Impact above) |
| `docs/features/*.md` | None | Routing isn't a feature folder; no per-feature doc. |
| `docs/api/*.md` | None | No API contracts changed. |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Test 4 override callback runs after the test scope tears down, leaving a leak | Low | Medium | `ref.onDispose` registration on the override's own `Ref` ties disposal to the `ProviderScope` lifetime, which `pumpWidget` controls. Same mechanism `settingsRepositoryProvider.overrideWithValue` already relies on. |
| `_pumpRouter` rewrite breaks an existing assertion that depends on a specific widget-tree depth | Low | Low | The `Consumer` adds one extra widget node in the tree. Existing assertions use `find.byType` and `find.text` — neither depends on absolute depth. |
| `test/widget_test.dart` fails after the provider change | Low | Low | Provider is `keepAlive: true` and synchronous; `pumpAndSettle()` in the existing tests covers any extra microtask. If a real ordering issue surfaces, add ONE extra `tester.pump()` before the first assertion — minimal-change rule per spec §7. |
| `build_runner` emits side-effect regenerations to `settings_provider.g.dart` or `shared_preferences_provider.g.dart` | Medium | Low | Acceptable per spec 015's MEMORY guidance. Commit the side-effect diff alongside `app_router.g.dart` and note it in the WIP commit. |
| The `riverpod_annotation`-emitted `appRouterProvider` symbol clashes with something existing | Very Low | Low | `grep -rn "appRouterProvider" lib/ test/` returns zero matches today (verified during research). |
| `_buildTestRouterWithSentinel()` callsite is the only thing keeping the helper alive; future linter flags it as unused | Very Low | Low | Helper is used by Test 4's override callback. `dart analyze` sees the reference. |
| Spec's grep-count ACs become impossible after a future edit (cf. MEMORY line 151 lesson) | Low | Low | Each AC's grep is scoped narrowly (one file, one regex). Re-verified each AC's regex against the planned post-fix file contents during plan write. |
| Doc paragraph rewrite accidentally drops a referenced anchor (e.g., `[App-wide state]`) | Low | Low | Doc edit uses targeted `Edit` calls — `old_string` includes the surrounding paragraph; AC-12 grep enforces both content checks. |

## Dependencies

No new dependencies. All required packages are present:

| Package | Already in `pubspec.yaml` | Purpose |
|---|---|---|
| `go_router` | yes | `GoRouter` class |
| `riverpod_annotation` | yes (runtime) | `@Riverpod` annotation, `Ref` type |
| `flutter_riverpod` | yes | `ProviderScope`, `Consumer`, `ref.watch`, `appRouterProvider.overrideWith` |
| `riverpod_generator` | yes (dev) | Codegen for `app_router.g.dart` |
| `build_runner` | yes (dev) | Runs the generator |

## Supporting Documents

- [Research](../../research/2026-05-18-bug-007-gorouter-disposal.md) — pre-spec feasibility check (saved at project root)
- No `data-model.md` — no entities introduced or modified
- No `contracts.md` — no API contracts introduced or modified

## Spec ↔ Plan Cross-Reference

Every AC mapped to a concrete implementation site:

| AC | Implementation site | File Impact row |
|---|---|---|
| AC-1 (function-form `@Riverpod(keepAlive: true)`) | New provider declaration | `lib/core/routing/app_router.dart` |
| AC-2 (`ref.onDispose(router.dispose)`) | Provider body | `lib/core/routing/app_router.dart` |
| AC-3 (`app_router.g.dart` exists & contains `appRouterProvider`) | Codegen output | `lib/core/routing/app_router.g.dart` |
| AC-4 (no `name:` annotation arg) | Provider declaration | `lib/core/routing/app_router.dart` |
| AC-5 (`ref.watch(appRouterProvider)` in `app.dart`) | DoslyApp.build line | `lib/app.dart` |
| AC-6 (no bare `appRouter` reference in `lib/`) | Cleanup of old usages | `lib/app.dart` + provider file (provider file is excluded by the grep) |
| AC-7 (Test 4 uses overrideWith, no bare `testRouter.dispose()`) | Test 4 rewrite | `test/core/routing/app_router_test.dart` |
| AC-8 (all 6 routing tests still pass) | All test bodies unchanged; only the pump-helper signature flips | `test/core/routing/app_router_test.dart` |
| AC-9 (`dart analyze` clean) | Build-runner step | All edited files |
| AC-10 (`flutter test` passes, no leaked-`ChangeNotifier` warnings) | All edits combined | All edited files |
| AC-11 (`flutter build apk --debug` succeeds) | Integration gate | All edited files |
| AC-12 (`docs/architecture.md` updated, no "kept on plain primitives") | Doc rewrite | `docs/architecture.md` |
| AC-13 (`bugs/007-…` flipped to Fixed with Resolution section) | Bug bookkeeping | `bugs/007-gorouter-never-disposed.md` |

Reverse check — files in this plan NOT in the spec's Affected Areas: none. The plan's file set is a subset of the spec's. ✅
