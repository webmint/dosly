# Tasks: 018-gorouter-disposal

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Generated**: 2026-05-18
**Total tasks**: 2
**Pattern**: 2-task surgical fix (source + docs/bookkeeping) — per MEMORY L129
**Verification**: APPROVED (2026-05-18) — see [verify.md](../verify.md) — 13/13 ACs PASS, review CLEAN

## Dependency Graph

```
001 (source: provider + tests + integration gate)
   └──→ 002 (docs + bug closure)
```

## Task Index

| # | Title | Agent | Depends on | Review checkpoint | Status |
|---|-------|-------|-----------|---|--------|
| 001 | Convert appRouter to @riverpod provider + rewire test consumers | mobile-engineer | None | No | Complete |
| 002 | Update docs and close bug 007 | tech-writer | 001 | Yes (before 002) | Complete |

## Additions to Spec

None. The task list is a strict subset of the spec's "Affected Areas" — no files discovered during planning that weren't already in the spec.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Medium | Multi-file refactor across `lib/` + `test/` (5 files including the generated `.g.dart`). Integration gate (`flutter test` + `flutter build apk --debug`) lands on this task. Three Low-likelihood sub-risks: (a) Test 4 override timing, (b) `test/widget_test.dart` pump ordering, (c) side-effect `build_runner` regenerations of unrelated `.g.dart` files. All mitigations are documented in the plan's Risk Assessment. |
| 002 | Low | Pure documentation + bookkeeping. No source code changes. Doc edits are scoped to one section of one file and one bug file. |

## Review Checkpoints

| Before Task | Reason | What to Review |
|-------------|--------|----------------|
| 002 | Source convergence point — Task 001 is the only source-edit task; review before bookkeeping locks the spec down | (1) `lib/core/routing/app_router.dart` matches the function-form `@Riverpod(keepAlive: true)` shape exactly (mirrors `shared_preferences_provider.dart`). (2) `lib/core/routing/app_router.g.dart` is committed and emits `appRouterProvider`. (3) `lib/app.dart` reads via `ref.watch(appRouterProvider)`; no bare `appRouter` left in `lib/`. (4) Test 4 uses `appRouterProvider.overrideWith(...)` with `ref.onDispose(r.dispose)`; no bare `testRouter.dispose()`. (5) All 6 routing tests + all 3 widget tests pass with no leaked-`ChangeNotifier` diagnostics. (6) `flutter build apk --debug` succeeds. |

## Contract Chain Integrity

Verified: every Task 002 "Expects" maps to a Task 001 "Produces"; every Task 001 "Produces" is consumed by either Task 002's "Expects" or a spec AC; no orphans, no unsatisfied preconditions.

| Task 001 Produces | Consumed by |
|---|---|
| `app_router.dart` has function-form `@Riverpod(keepAlive: true)` provider with `ref.onDispose` | AC-1, AC-2, AC-4; referenced by Task 002 Expects |
| `app_router.g.dart` is generated + committed; declares `appRouterProvider` | AC-3; referenced by Task 002 Expects |
| `app.dart` reads `ref.watch(appRouterProvider)`; no bare `appRouter` in `lib/` | AC-5, AC-6 |
| `_pumpRouter` helper accepts `{List<Override> overrides = const []}` and reads provider via `Consumer` | AC-8 (all 6 routing tests still pass) |
| Test 4 uses `appRouterProvider.overrideWith(...)` with `ref.onDispose`; no bare `testRouter.dispose()` | AC-7 |
| `flutter test` passes; no `ChangeNotifier` leak diagnostics | AC-10 |
| `flutter build apk --debug` succeeds | AC-11 |
| `dart analyze` clean | AC-9 |

| Task 002 Produces | Consumed by |
|---|---|
| `docs/architecture.md` § Routing updated (no "kept on plain primitives"; contains `appRouterProvider`, `@Riverpod(keepAlive: true)`, `ref.onDispose`) | AC-12 |
| `bugs/007-gorouter-never-disposed.md` Status: Fixed with Resolution section linking spec 018 | AC-13 |

All 13 ACs covered. ✅

## AC ↔ Task Coverage Matrix

| AC | Task | Verification |
|---|---|---|
| AC-1 (function-form `@Riverpod(keepAlive: true)`) | 001 | grep predicate in Done-when |
| AC-2 (`ref.onDispose(router.dispose)`) | 001 | grep predicate in Done-when |
| AC-3 (`app_router.g.dart` exists + `appRouterProvider`) | 001 | grep + `git ls-files` in Done-when |
| AC-4 (no `name:` annotation) | 001 | grep predicate in Done-when |
| AC-5 (`ref.watch(appRouterProvider)` in `app.dart`) | 001 | grep predicate in Done-when |
| AC-6 (no bare `appRouter` in `lib/`) | 001 | scoped grep in Done-when |
| AC-7 (Test 4 uses `overrideWith`, no `testRouter.dispose()`) | 001 | grep predicates in Done-when |
| AC-8 (all 6 routing tests still pass) | 001 | `flutter test` in Done-when |
| AC-9 (`dart analyze` clean) | 001 | gate in Done-when |
| AC-10 (`flutter test` passes, no `ChangeNotifier` leak warnings) | 001 | `flutter test` + output scan |
| AC-11 (`flutter build apk --debug` succeeds) | 001 | build gate in Done-when |
| AC-12 (`docs/architecture.md` updated) | 002 | grep predicates in Done-when |
| AC-13 (`bugs/007-…` flipped to Fixed with Resolution) | 002 | grep predicates in Done-when |
