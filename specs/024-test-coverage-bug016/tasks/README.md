# Tasks: Test-coverage hardening (Bug 016)

**Spec**: specs/024-test-coverage-bug016/spec.md
**Plan**: specs/024-test-coverage-bug016/plan.md
**Generated**: 2026-05-27
**Total tasks**: 5

## Dependency Graph

```
001 (datasource test) ───────────────────────────┐
002 (home-nav test) ──────────────────────────────┤
003 (locale_resolver test) ──→ 004 (harness dedup)─┤
                                                   └──→ 005 (guard doc + bug bookkeeping)
```

- 001, 002, 003 are independent (each a new, self-contained test file).
- 004 depends on 003 (production `resolveAppLocale` proven before 7 harnesses rely on it).
- 005 depends on 001-004 (the bug record marks them Fixed only once they exist).

## Task Index

| # | Title | Agent | Depends on | Status |
|---|-------|-------|-----------|--------|
| 001 | Add SettingsLocalDataSource unit tests | qa-engineer | None | Complete |
| 002 | Add HomeScreen gear-tap navigation test | qa-engineer | None | Complete |
| 003 | Add resolveAppLocale unit test | qa-engineer | None | Complete |
| 004 | Deduplicate _resolveLocale across 7 harnesses | qa-engineer | 003 | Complete |
| 005 | Document guard + update Bug 016 record | tech-writer | 001,002,003,004 | Complete |

## Additions to Spec

None. All files map to the spec's Affected Areas. Note carried from spec/plan:
the duplication is **7-way**, not the "4-way" stated in the original bug file
(verified by grep during /specify).

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Low | New isolated file; only uncertainty is whether seeding an `int` throws in `getString` (documented fallback in the task) |
| 002 | Low | New isolated widget test; OQ-1 route-observer fallback if real `SettingsScreen` is heavy to mount |
| 003 | Low | Pure-Dart unit test, no harness |
| 004 | Med | Touches 7 existing test files backing many tests; mechanical but the largest blast radius. `flutter test` is the backstop |
| 005 | Low | Documentation-only; one `//` line + Markdown bookkeeping, no behavior change |

## Review Checkpoints

| Before Task | Reason | What to Review |
|-------------|--------|----------------|
| 005 | Convergence (depends on 4 tasks) + presentation-layer `lib/` edit | Confirm all 4 new/changed test groups pass and the bug record's per-sub-item dispositions are accurate before the guard comment + bug file are finalized |

## Contract Consistency

- All "Produces" map to a spec AC (new test files → AC-1..7) or are consumed downstream (003's `resolveAppLocale`-proven → 004's Expects; 001-004's outputs → 005's Expects for the bug record).
- All "Expects" trace to existing codebase state (production source, providers, `InMemorySharedPreferencesAsync`) or an upstream "Produces" (003 → 004; 001-004 → 005).
- No orphaned or unsatisfied contracts.

## Verification (2026-05-28)

**Verdict: APPROVED.** All 5 tasks Complete; spec marked Complete.
- Acceptance criteria: 10 / 10 PASS (code-reading mode — AC_VERIFICATION off).
- Code quality: `dart analyze` clean · `flutter test` 261 passed · cross-task consistency PASS (all harnesses + new tests use production `resolveAppLocale`) · no scope creep · no leftover artifacts.
- Review findings: Security PASS (0 Critical/High/Medium, 5 Info) · Performance nothing material (1 Low, cosmetic) · Test coverage ADEQUATE.
- Accepted limitation: the legacy-`int` `catch (_)` branch in `getThemeMode()` is unreachable via `InMemorySharedPreferencesAsync`; degrade outcome is covered, named honestly. Not an AC failure.

## Notes

- AC-10 (`dart analyze` clean + `flutter test` passes) is addressed by every task's "Done when".
- No production logic changes; the only `lib/` edit is the one-line comment in Task 005.
