# Tasks: Settings Data-Layer Error Containment

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Generated**: 2026-05-25
**Total tasks**: 3

## Dependency Graph

```
001 (Either-ify load + align consumers) ──→ 002 (widen save* catches) ──→ 003 (failure-path tests)
                                         └──────────────────────────────→ 003
```

001 must land as one atomic change (a public-interface signature change breaks
`dart analyze` across `lib/` and `test/` until every consumer/fake is aligned).
002 edits the same impl file as 001 (serialized). 003 converges on both.

## Task Index

| # | Title | Agent | Depends on | Status |
|---|-------|-------|-----------|--------|
| 001 | Either-ify `load()` and align all consumers | architect | None | Complete |
| 002 | Widen `save*` catches to `Failure.unknown` | architect | 001 | Complete |
| 003 | Add failure-path tests for `load()` and `save*` | qa-engineer | 001, 002 | Complete |

## Additions to Spec

Discovered during planning (Phase 2) and carried into the plan's File Impact:
the `load()` signature change forces edits to **6 hand-written test fakes** that
the spec's §4 Affected Areas did not list — `test/app_bootstrap_test.dart`,
`test/widget_test.dart`, `test/core/routing/app_router_test.dart`,
`test/features/settings/presentation/screens/settings_screen_test.dart`,
`test/features/settings/presentation/widgets/theme_selector_test.dart`,
`test/features/settings/presentation/widgets/language_selector_test.dart`. Each
overrides `AppSettings load()` and won't compile against the new interface. These
are one-line mechanical edits, bundled into Task 1 (the atomic signature change).
The 5 mocktail use-case mocks (`set_*_test.dart`, `cycle_theme_mode_test.dart`)
auto-stub via `noSuchMethod` and do not override `load()` — no change needed.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | High | Public-interface signature change touching 11 files (3 prod + 8 test); must land atomically to keep `dart analyze`/suite green; the provider fold must emit to `_errors` without re-entrant build issues |
| 002 | Low | Mechanical catch-widening in one file; existing `save*` tests assert on `isA<Left/Right>`, not message contents |
| 003 | Medium | Requires a throwing `SettingsLocalDataSource` double; must avoid forbidden partial `Either` extractors (§3.2); convergence on 001+002 |

## Review Checkpoints

| Before Task | Reason | What to Review |
|-------------|--------|----------------|
| 001 | High risk (signature change, 11 files) | `load()` is sync `Either`; impl try/catch contains all throwables; provider folds to default + emits; all 7 fakes + repo-impl call sites aligned; `dart analyze` green |
| 003 | Convergence (depends on 001 + 002) + test gate | New tests cover AC-2/3/5/6/7/8/9; no partial `Either` extractors; full `flutter test` green |

## Contract Chain Integrity

- **001 Produces** (`load()` returns `Either`; impl `Right`/`Left(Failure.unknown)`; provider fold + `_errors.add`; fakes aligned) → consumed by **002 Expects** (file already references `Failure.unknown`) and **003 Expects** (load returns `Either`, notifier folds), and maps to AC-1/AC-4.
- **002 Produces** (no `on Exception catch`; `Left(Failure.unknown(e, st))`; no `CacheFailure(e.toString())`) → consumed by **003 Expects** (each `save*` returns `Left(Failure.unknown)`), maps to AC-7/AC-8.
- **003 Produces** (failure-path + wrong-type tests; full suite green) → maps to AC-2/3/5/6/7/8/9/10.
- No orphaned Produces; no unsatisfied Expects. Chain is intact.

## Verification Summary (/verify 2026-05-25)

**Verdict: APPROVED.** Spec status → Complete. All 3 tasks Complete; all 10 ACs PASS.
- Code quality: `dart analyze` clean · `flutter test` 241/241 · `flutter build apk --debug` OK · no scope creep · no leftover artifacts.
- Cross-task consistency: PASS — the `Either<Failure, AppSettings>` contract threads cleanly interface → impl → notifier fold → tests; `Failure.unknown`/`UnknownFailure` used consistently.
- Review: Security 0C/0H/0M/5I (PASS — closes the CWE-209 path leak) · Performance 0H/0M/1L (pre-existing, dormant) · Test coverage ADEQUATE.
- Non-blocking notes: (1) `settings_screen_test.dart` fake still injects `CacheFailure` (payload ignored, test passes) — divergence from production; (2) AC-2 `themeMode` wrong-type asymmetry (guarded → `Right(default)`, not `Left`) lacks an explicit test. Both low priority.
