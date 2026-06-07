# Tasks: Typed Logger with PHI Sanitize Layer

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Generated**: 2026-06-01
**Total tasks**: 7
**Status**: ✅ Complete — all 7 tasks done; `/verify` 2026-06-02 → **APPROVED** (11/11 AC PASS; analyze clean; build OK; 285 tests pass). 3 non-blocking Warnings (2 security defense-in-depth, 1 test gap on AC-9 once-guard). Spec marked Complete.

## Dependency Graph

```
001 (dep) ──→ 002 (sanitizer) ──→ 003 (sanitizer tests)
          │                  └──→ 004 (logger) ──→ 005 (logger tests)
          └────────────────────→ 004              └──→ 006 (router pilot) ──→ 007 (docs)
```

Execution waves (sequential by dependency):
1. **001** — dependency
2. **002** — sanitizer (depends 001)
3. **003** — sanitizer tests (depends 002) · **004** — logger (depends 001, 002)
4. **005** — logger tests (depends 004) · **006** — router pilot (depends 004)
5. **007** — docs (depends 006)

## Task Index

| # | Title | Agent | Depends on | Review | Status |
|---|-------|-------|-----------|--------|--------|
| 001 | Add `logging` dependency | architect | None | No | Complete |
| 002 | Implement the pure PHI / `Failure`-aware sanitizer | architect | 001 | **Yes** | Complete |
| 003 | Sanitizer test suite (leak tests + per-variant) | qa-engineer | 002 | No | Complete |
| 004 | Implement `loggerProvider` + `Logger.root` config | architect | 001, 002 | **Yes** | Complete |
| 005 | Logger pipeline tests (level, idempotency, provider) | qa-engineer | 004 | No | Complete |
| 006 | Wire router pilot + startup registration | mobile-engineer | 004 | **Yes** | Complete |
| 007 | Update architecture docs | tech-writer | 006 | No | Complete |

## Additions to Spec

- `lib/app_bootstrap.dart` (Task 6) — not in spec §4. Discovered in `/plan`: `main()` is synchronous and wraps `ProviderScope`, so the `Logger.root` listener must be triggered through Riverpod at startup; `AppBootstrap` is the read point. One-line provider read.
- `lib/core/logging/logger.g.dart` (Task 4) — Riverpod codegen output, not hand-written.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 002 | High | Security surface — a missed redaction path leaks PHI / CWE-209/532 into logs. Mitigated by Task 3's mandatory leak tests + exhaustive sealed switch. |
| 004 | Medium | Global `Logger.root` listener + provider lifecycle; risk of double-registration / cross-test leakage. Mitigated by `ref.onDispose` + injectable sink + Task 5 idempotency test. |
| 006 | Medium | `onException` availability on `go_router ^17.2.0` (verify; fallback noted). Must keep `_RouterErrorScreen` UI byte-identical. |
| 001 | Low | Single pure-Dart dependency add. |
| 003 | Low | Test-only. |
| 005 | Low | Test-only. |
| 007 | Low | Docs-only. |

## Review Checkpoints

| Before/after Task | Reason | What to review |
|-------------------|--------|----------------|
| 002 | High-risk (security surface) | Redact-by-default applied to every variant; no `default:`; no PHI/`toString()` leak path; no `dart:developer`/Flutter import |
| 004 | Convergence (depends 001 + 002) | Single listener; `ref.onDispose` cancellation; `levelFor` purity; injectable sink seam; sanitizer invoked with `includeErrorDetail: kDebugMode` |
| 006 | Layer-boundary crossing (first presentation task) | `onException` logs once per error; `_RouterErrorScreen` unchanged; bootstrap reads provider once |

## Contract Chain Integrity

- **001 Produces** `logging:` dep → consumed by **002 Expects** and **004 Expects**. ✓
- **002 Produces** `SanitizedLog` + `sanitizeRecord` → consumed by **003 Expects** and **004 Expects**. ✓
- **004 Produces** `loggerProvider` + `levelFor` + injectable sink → consumed by **005 Expects** and **006 Expects**. ✓
- **006 Produces** router `onException` + bootstrap read → consumed by **007 Expects**. ✓
- No orphaned Produces; no unsatisfied Expects. Every leaf Produces maps to an AC (003→AC-7/8, 005→AC-2/3/4, 006→AC-9, 007→docs).

## Acceptance Criteria Coverage

| AC | Task(s) |
|----|---------|
| AC-1 | 001 |
| AC-2 | 004, 005 |
| AC-3 | 004, 005 |
| AC-4 | 004, 005 |
| AC-5 | 002 |
| AC-6 | 002, 003 |
| AC-7 | 003 |
| AC-8 | 002, 003 |
| AC-9 | 006 |
| AC-10 | all (PostToolUse `dart analyze` + `/review`) |
| AC-11 | 002, 004 (dartdoc on new public APIs) |

All 11 ACs covered.
