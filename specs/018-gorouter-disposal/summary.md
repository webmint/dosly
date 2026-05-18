# Feature Summary: 018 — GoRouter Disposal via @riverpod Provider

### What was built

Closed bug 007 by converting the top-level `final GoRouter appRouter` singleton in `lib/core/routing/app_router.dart` to a function-form `@Riverpod(keepAlive: true)` codegen provider that registers `ref.onDispose(router.dispose)`. The router's `ChangeNotifier` listeners are now released on `ProviderScope` teardown instead of leaking for the process lifetime, eliminating the leaked-`ChangeNotifier` warnings that the test suite was papering over with manual `testRouter.dispose()` calls. Route topology, branch order, AppShell wiring, and every consumer's UX is byte-identical pre- and post-fix.

### Changes

- **Task 001** — Convert appRouter to @riverpod provider + rewire test consumers: migrated the production singleton to `@Riverpod(keepAlive: true) GoRouter appRouter(Ref ref)` with `ref.onDispose(router.dispose)`; updated `DoslyApp` to read via `ref.watch(appRouterProvider)`; reshaped `_pumpRouter` to drop the `GoRouter` parameter and accept optional `List<Override> overrides`; rewrote Test 4 to use `appRouterProvider.overrideWith(...)` with internal `ref.onDispose(r.dispose)` instead of a manual `testRouter.dispose()` call.
- **Task 002** — Update docs/architecture.md and close bug 007: rewrote § Routing's inline code sample + rationale paragraph, added an `appRouterProvider` row to the provider wiring table, and closed `bugs/007-gorouter-never-disposed.md` with a Resolution section linking back to spec 018.

### Files changed

- `lib/core/routing/` — 3 files (1 new generated, 2 modified) — provider declaration + codegen output + dartdoc fix in `app_shell.dart`
- `lib/` (root) — 1 file modified — `app.dart` consumer update
- `test/core/routing/` — 1 file modified — `_pumpRouter` reshape + Test 4 rewire
- `docs/` — 1 file modified — § Routing rewritten
- `bugs/` — 1 file modified — bug 007 closed with Resolution section
- `specs/018-gorouter-disposal/` — 7 new files (spec, plan, review, verify, summary + 2 task files + tasks/README)
- `research/` — 1 new file — pre-spec feasibility report
- `.claude/` — 2 files modified — MEMORY (4 new lessons) + session-state

**Total**: 17 files changed, 1273 insertions, 108 deletions.

### Key decisions

- **Provider form** — function-form `@Riverpod(keepAlive: true)`, mirroring `lib/core/providers/shared_preferences_provider.dart`. Class-form was rejected because the router has no mutation API; autoDispose was rejected because the router must outlive transient absences of listeners (e.g., during hot reload).
- **Symbol replacement** — `appRouter` is deleted entirely, not kept as a backwards-compat getter. A getter alias would re-introduce a non-Provider surface that bypasses lifecycle binding.
- **Test helper signature** — `_pumpRouter` drops the `GoRouter` parameter and accepts optional `List<Override> overrides`; the helper itself wraps `MaterialApp.router` in a `Consumer` that watches `appRouterProvider`. Tests 1–6 became `_pumpRouter(tester)`; Test 4 became `_pumpRouter(tester, overrides: [appRouterProvider.overrideWith((ref) { ...; ref.onDispose(r.dispose); return r; })])`.
- **Same-spec doc + bug-file updates** — `docs/architecture.md` § Routing and `bugs/007-gorouter-never-disposed.md` were updated in this same spec (Task 002) rather than deferred. This avoids the doc-rationale drift pattern that originally allowed bug 007 to persist (cf. bug 012).

### Deviations from plan

- **Task 001** — `lib/core/routing/app_shell.dart` was edited outside the originally-listed file set to fix a single-word stale dartdoc reference (`[appRouter]` → `[appRouterProvider]`) so AC-6's grep predicate would pass. Legitimate one-word scope expansion documented in Task 001 completion notes.
- **Task 001** — Implementing agent committed the source changes as a `feat(core/routing): ...` commit instead of a `[WIP]` commit. Work is correct; `/finalize` will squash regardless of message form.
- **Test import addition** — `test/core/routing/app_router_test.dart` required adding `import 'package:flutter_riverpod/misc.dart';` because the `Override` type is NOT re-exported from the main `flutter_riverpod.dart` barrel. The plan called out the `Override`-as-parameter-type requirement but did not specify the secondary import. Recorded in MEMORY for future use.

### Acceptance criteria

- [x] **AC-1**: Function-form `@Riverpod(keepAlive: true)` provider; no top-level `final GoRouter appRouter`
- [x] **AC-2**: Provider body calls `ref.onDispose(router.dispose)`
- [x] **AC-3**: `lib/core/routing/app_router.g.dart` exists, committed, declares `appRouterProvider`
- [x] **AC-4**: No `name:` annotation on the new provider
- [x] **AC-5**: `lib/app.dart` reads `ref.watch(appRouterProvider)`; no `routerConfig: appRouter`
- [x] **AC-6**: No bare `appRouter` identifier anywhere in `lib/` outside the provider file
- [x] **AC-7**: Test 4 uses `appRouterProvider.overrideWith(...)`; no bare `testRouter.dispose()`
- [x] **AC-8**: All 6 routing tests still pass
- [x] **AC-9**: `dart analyze` clean
- [x] **AC-10**: `flutter test` passes (227/227); zero `ChangeNotifier` leak diagnostics
- [x] **AC-11**: `flutter build apk --debug` succeeds
- [x] **AC-12**: `docs/architecture.md` § Routing updated; "kept on plain primitives" gone; new pattern documented
- [x] **AC-13**: `bugs/007-gorouter-never-disposed.md` Status: Fixed; Resolution section links spec 018
