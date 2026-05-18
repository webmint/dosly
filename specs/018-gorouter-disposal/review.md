# Review Report: 018-gorouter-disposal

**Date**: 2026-05-18
**Spec**: [spec.md](spec.md)
**Plan**: [plan.md](plan.md)
**Changed files**: 7 (5 source/test + 2 docs/bookkeeping)

## Security Review

- **Critical: 0 | High: 0 | Medium: 0 | Info: 8**

### Info (hardening observations)

- **Info** — `lib/core/routing/app_router.dart:36–78`: Deep-link surface unchanged. Same five static-path routes (`/`, `/meds`, `/history`, `/settings`, `/theme-preview`); no path parameters, no query handling, no `redirect:`, no `errorBuilder:`. Migration is route-shape-identical. Bug 008 (missing `errorBuilder`) remains a separately tracked item and is correctly out of scope.

- **Info** — PHI scan: clean. No medication names, dosages, intake history, or notification payloads in the diff. Routing-only changes per constitution §4.2.1.

- **Info** — `lib/core/routing/app_router.dart:80`: Lifecycle correctness verified. `ref.onDispose(router.dispose)` is registered *after* `router` is constructed (lines 36–79) and *before* it is returned (line 81). `keepAlive: true` ties disposal to `ProviderScope` teardown — by definition no consumer is left to read the value after dispose. The `dispose` tearoff captures `router` by reference safely.

- **Info** — Constitution §3.1 audit clean. Zero `!`, `as`, or `dynamic` in any changed source or test file. `.g.dart` codegen is exempt per constitution.

- **Info** — `keepAlive: true` is intentional and isolation-safe. Each `_pumpRouter` call constructs a fresh `ProviderScope` (`test/core/routing/app_router_test.dart:130`), so `keepAlive` scopes to that test's `ProviderScope` — no cross-test state leakage.

- **Info** — Test 4 override-dispose firing confirmed. `appRouterProvider.overrideWith((ref) { ... ref.onDispose(r.dispose); return r; })` (lines 260–264) receives a real `Ref` from the overriding `ProviderScope`. When `tester.pumpWidget` tears down between tests, the scope disposes, firing the override's `onDispose` and disposing the sentinel router.

- **Info** — `package:flutter_riverpod/misc.dart` import is safe. Public secondary entry point exporting the `Override` type used by `ProviderScope.overrides`. Not flagged by `dart analyze`; does not expose private internals.

- **Info** — No `print`/`debugPrint`/swallowed errors; no new cross-feature imports. Constitution §4.2 + §2.1 satisfied.

### Security verdict: PASS

## Performance Review

- **High: 0 | Medium: 0 | Low: 0**

### Focus areas — all CLEAN

- **Provider rebuild scope**: `appRouterProvider` (`keepAlive: true`, synchronous, zero upstream dependencies) returns the cached `GoRouter` instance via reference identity. `DoslyApp.build` re-runs only on `settingsNotifierProvider` selector firings; `MaterialApp.router` receives the same `routerConfig` object every time — no rebuild loop possible.
- **Test pump-helper allocation cost**: `_pumpRouter` inserts one `Consumer` widget between `ProviderScope` and `MaterialApp.router`. Six tests × one extra element each = below any measurable threshold.
- **Codegen file size**: `app_router.g.dart` is 76 lines, structurally identical to `settings_provider.g.dart` shape. Tree-shakable in release builds.
- **Provider lifecycle overhead vs. former singleton**: ~5–7 fields of `ProviderElement` wrapper overhead. Indistinguishable from zero at mobile scale. **Net improvement** — `ChangeNotifier` listeners now released on `ProviderScope` teardown instead of accumulating.
- **Test 4 override hot path**: Override closure runs once per `ProviderScope` instantiation. No loop, no shared mutable state.
- **Build-runner side-effect diff**: Task 001 commit touches exactly five files; `shared_preferences_provider.g.dart` and `settings_provider.g.dart` not regenerated (or regenerated with identical content). No diff balloon.

### Performance verdict: CLEAN

The migration is a strict lifecycle improvement: identical runtime allocation profile to the former singleton plus a correctly wired `ref.onDispose`, with negligible `ProviderElement` wrapper overhead.

## Test Assessment

### Coverage Summary

| Area | Tests |
|------|-------|
| Routing topology (AC-8) | 6 integration tests — all pass |
| Leak prevention (AC-10) | Zero `ChangeNotifier` diagnostics across full 227-test run |
| Override + dispose pattern (AC-7) | Test 4 exercises `appRouterProvider.overrideWith` with `ref.onDispose` |

### AC-to-Test Traceability

**Behavioral ACs — all covered:**

- **AC-8** (routing topology unchanged): Tests 1–6 cover tab navigation, single `AppBottomNav` invariant, `selectedIndex` wiring, `/settings` and `/theme-preview` shell-membership. Pass.
- **AC-10** (zero leak diagnostics): Full `flutter test` output contains zero "ChangeNotifier was used after being disposed" or "listeners was leaked" strings across 227 tests. Pass.
- **AC-7** (Test 4 uses `overrideWith` + `ref.onDispose`; no bare `testRouter.dispose()`): Confirmed at `test/core/routing/app_router_test.dart:260–263`. Pass.

**Structural ACs** — AC-1 through AC-6, AC-9, AC-11, AC-12, AC-13 are verified by grep predicates and `flutter build apk --debug`. Correct per Feature 014 precedent (MEMORY L131).

### Specific concerns assessed

- **`ref.onDispose` on production provider exercised?** Not by a dedicated test, and that is acceptable. The provider is `keepAlive: true`; its lifecycle is bounded by `ProviderScope` teardown. Zero leak diagnostics on every test = the binding fires correctly. A spy-router test would be test-of-the-framework overhead.
- **Test 4 `ref.onDispose` — live or dead?** Live. `_pumpRouter` creates a `ProviderScope` with the `overrideWith` callback; widget-tree teardown fires `ref.onDispose(r.dispose)`. The absence of any leak diagnostic in Test 4 confirms the callback fires.
- **Hot reload behavior**: not testable in `flutter test`. Not a regression risk — `keepAlive: true` skips re-evaluation. Out of scope per spec.
- **`widget_test.dart` indirect coverage**: Three `DoslyApp` widget tests reach `appRouterProvider` through `DoslyApp`'s `ref.watch` without overriding. They exercise the production provider body including `ref.onDispose`. Sufficient.

### Gaps

- **Low** — No test asserts `GoRouter.dispose()` is called when `ProviderScope` tears down (would require a mock/spy router). The "no leak diagnostic" signal is equivalent; AC-2 grep predicate enforces the line's presence; project policy for similar lifecycle bindings (`SharedPreferencesProvider`) accepts the same signal level. Not worth adding now.

### Test verdict: ADEQUATE

All behavioral ACs are covered by existing tests. The `ref.onDispose` lifecycle path is validated indirectly at a level consistent with project precedent.

---

## Overall Review Verdict: CLEAN

Zero Critical, High, or Medium findings across security, performance, or test coverage. Eight Info-level security observations are provenance — no remediation required. One Low-priority test observation (spy-based dispose verification) is intentionally deferred per project precedent.

Feature is ready for `/verify`.
