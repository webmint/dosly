# Tasks: Integration-test harness + add-medication golden flow

**Spec**: specs/033-integration-tests/spec.md
**Plan**: specs/033-integration-tests/plan.md
**Generated**: 2026-06-18
**Total tasks**: 8

## Dependency Graph

```
001 (dep) ──┬──→ 003 (harness) ──┬──────────────→ 006 (golden) ──┐
            └──→ 004 (fixtures) ─┼──→ 005 (driver) ─┬─→ 006 ─────┼─→ 008 (docs)
002 (keys) ──────────────────────┴──→ 005 ─────────┴─→ 007 ─────┘
                                  003 ───────────────────→ 007 (smoke)
```

- `001` and `002` have no dependencies (can run first, in either order).
- `003` and `004` need `001`; `005` needs `002` + `004`.
- `006` converges `003` + `004` + `005`; `007` needs `003` + `005`.
- `008` needs `006` + `007`.

## Task Index

| # | Title | Agent | Depends on | Status |
|---|-------|-------|-----------|--------|
| 001 | Add the integration_test dev dependency | qa-engineer | None | Complete |
| 002 | Add stable ValueKeys (FAB, picker, chips) | mobile-engineer | None | Complete |
| 003 | Build the integration-test boot harness | qa-engineer | 001 | Complete |
| 004 | Define 8-variation fixtures + assertions | qa-engineer | 001 | Complete |
| 005 | Build the add-medication UI driver + picker | qa-engineer | 002, 004 | Complete |
| 006 | Add-medication golden-flow test (8 variations) | qa-engineer | 003, 004, 005 | Complete |
| 007 | Real-file DB-open smoke test | qa-engineer | 003, 005 | Complete |
| 008 | Document the integration-test harness | tech-writer | 006, 007 | Complete |

## Verification (/verify, 2026-06-18)

**Verdict: APPROVED.** All 8 tasks Complete; spec marked Complete.
- **Acceptance criteria**: 11/11 PASS (code-reading mode — AC verification off per CLAUDE.md).
- **On-device**: `flutter test integration_test -d emulator-5554` → 9/9 (golden 8 + smoke 1). **Host**: 393/393. `dart analyze`: clean. Debug APK built (`assembleDebug`) during integration runs.
- **Review**: Security 0 Critical/0 High/0 Medium/7 Info; Performance 0 High/0 Medium/2 Low; Test coverage ADEQUATE.
- **Non-blocking follow-up**: validation/error-path UI coverage on-device (Medium, not AC-mandated) — candidate for a future golden-flow spec.

## Additions to Spec

- `integration_test/support/*` files (harness, driver, fixtures) are an elaboration of the spec's single "Test harness" Affected-Areas row.
- `docs/architecture.md` bullet added alongside the spec's `docs/` row.
- `path_provider` may be added as a direct dep in Task 007 only if the smoke-file cleanup path cannot be resolved transitively (already pulled by `drift_flutter`).

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Low | SDK dep add; clean rollback boundary |
| 002 | Low | Additive keys only; 393 tests guard behavior |
| 003 | Med | First on-device boot+override; pumpAndSettle timing |
| 004 | Low | Pure data + assertions |
| 005 | Med | UI driving across pickers/dropdowns; locale-sensitive finders |
| 006 | Med | Convergence; 8 full-app boots; flakiness surface |
| 007 | Med | Real path_provider + native file open; the load-bearing regression guard |
| 008 | Low | Docs only |

## Review Checkpoints

| Before Task | Reason | What to Review |
|-------------|--------|----------------|
| 006 | Convergence (003+004+005) + first full golden flow | Harness boots the real app; driver fills every form variant; all 8 cases assert correct rows; per-variation isolation holds |
| 007 | Convergence (003+005) + high-value real-path test | `dosly_inttest` real-file DB opens via path_provider; one med persists; real `dosly` untouched; teardown deletes the file |

## Contract Chain Integrity

- No orphan "Produces" — every produced symbol is consumed downstream or maps to an AC:
  - 001 → 003/004 expects (AC-1)
  - 002 → 005 expects (AC-9)
  - 003 → 006/007 expects (AC-3)
  - 004 → 005/006/007 expects (AC-5)
  - 005 → 006/007 expects (AC-4, AC-8)
  - 006 → 008 expects (AC-2/5/6/11)
  - 007 → 008 expects (AC-2/7/11)
  - 008 → AC-10
- No unsatisfied "Expects" — every precondition is existing codebase state or an upstream Produces.

## AC Coverage

AC-1→001 · AC-2→006/007 · AC-3→003 · AC-4→005 · AC-5→004/006 · AC-6→006 · AC-7→007 · AC-8→005 · AC-9→002 · AC-10→008 · AC-11→003/004/005/006/007 (all test code, dart analyze).
