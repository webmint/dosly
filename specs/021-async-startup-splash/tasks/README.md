# Tasks: Async Startup Splash & Prefs-Failure Recovery

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Generated**: 2026-05-23
**Total tasks**: 5
**Status**: COMPLETE — verified 2026-05-23. All 10 ACs PASS; dart analyze clean; 230 tests pass; APK builds. Review: security PASS (0 Critical/High), performance net-positive, test coverage GAPS FOUND (Warnings only — see review.md). Verdict: APPROVED.

## Dependency Graph

```
001 (l10n strings) ───────────────→ 003 (splash + error widgets) ──┐
                                                                    ├─→ 004 (AppBootstrap + main + tests) ──→ 005 (docs + bug)
002 (init provider + locale resolver) ─────────────────────────────┘
```

001 and 002 are independent and can be done in either order; both must precede 004. 003 depends on 001 (l10n keys). 004 is the convergence/integration point. 005 is documentation, last.

## Task Index

| # | Title | Agent | Depends on | Status |
|---|-------|-------|-----------|--------|
| 001 | Add splash/error/retry localization strings | mobile-engineer | None | Complete |
| 002 | Add async prefs init provider + extract shared locale resolver | architect | None | Complete |
| 003 | Build splash and prefs-load-error widgets | mobile-engineer | 001 | Complete |
| 004 | Wire AppBootstrap, rewrite main(), add bootstrap tests | mobile-engineer | 002, 003 | Complete |
| 005 | Update architecture docs and close Bug 013 | tech-writer | 004 | Complete |

## Additions to Spec

Both were flagged during `/plan` and are carried here:
- `lib/core/l10n/locale_resolver.dart` (new) + `lib/app.dart` (modify) — the splash shell needs the same English-fallback locale policy as `DoslyApp`; extracting `_resolveLocale` to a shared core helper avoids a 2nd production copy (Task 002). The 7 pre-existing `_resolveLocale` copies in test harnesses are out of scope.
- `test/app_bootstrap_test.dart` (new) — widget tests for the failure/retry/normal/splash paths (Task 004).

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Low | Additive ARB keys + gen-l10n; natural rollback boundary |
| 002 | Med | New async provider + build_runner regen; `app.dart` resolver swap (behavior-preserving, but touches the app root) |
| 003 | Low | Mechanical widgets following the existing `_RouterErrorScreen` pattern |
| 004 | High | Integration + convergence: `main()` rewrite, double-`MaterialApp` hazard, async test timing |
| 005 | Low | Docs + bug closure |

## Review Checkpoints

| Before/After Task | Reason | What to Review |
|-------------------|--------|----------------|
| 004 | Convergence (depends on 002+003), layer crossing (first integration), high risk | No `await` before `runApp`; failure path shows the error screen (never blank); Retry recovers; exactly one `MaterialApp` mounted per phase; settings/theme/locale behavior unchanged; `lib/features/settings/**` untouched |

## Contract Chain Integrity

No orphans, no unsatisfied expectations:
- 001 Produces (l10n getters) → consumed by 003 Expects. ✓
- 002 Produces (`sharedPreferencesInitProvider`, `resolveAppLocale`) → consumed by 004 Expects. ✓
- 003 Produces (`SplashScreen`, `PrefsLoadErrorScreen`) → consumed by 004 Expects. ✓
- 004 Produces (`AppBootstrap`, synchronous `main()`) → consumed by 005 Expects + maps to AC-1/2/3/4/5/8/9. ✓
- 005 Produces (docs + bug closure) → maps to AC-10. ✓

## AC Coverage

| AC | Task(s) |
|----|---------|
| AC-1 (no await before runApp) | 004 |
| AC-2 (normal launch, settings applied) | 004 |
| AC-3 (failure → error screen) | 003, 004 |
| AC-4 (Retry recovers) | 004 |
| AC-5 (splash surface + progress) | 003, 004 |
| AC-6 (theme/locale identical) | 002, 004 |
| AC-7 (3 strings × 3 locales) | 001, 003 |
| AC-8 (settings unchanged) | 002, 004 |
| AC-9 (no print, analyze/test pass) | 004 |
| AC-10 (docs + bug) | 005 |
