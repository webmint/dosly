# Tasks: Bottom Nav Relocate

**Spec**: ../spec.md
**Plan**: ../plan.md
**Generated**: 2026-05-26
**Total tasks**: 1

## Dependency Graph

```
001 (relocate widget + tests, fix imports) ── standalone
```

## Task Index

| # | Title | Agent | Depends on | Status |
|---|-------|-------|-----------|--------|
| 001 | Relocate AppBottomNav from core/widgets to core/routing | mobile-engineer | None | Complete |

## Additions to Spec

None. The breakdown introduces no files beyond the spec's Affected Areas. As the plan already noted, `app_router.dart` and `meds_screen.dart` need no change (dartdoc-only `[AppBottomNav]` references; type name unchanged).

## Why one task

This is a tightly-coupled atomic relocation, not a multi-step change. Moving the source file breaks `app_shell.dart`'s import and all three test imports simultaneously — any intermediate state fails `dart analyze`/test compilation. Per breakdown rule 7 ("a simple find-and-replace across files is ONE task"), the move + all import edits + empty-dir cleanup are verified together by a single `dart analyze` + `flutter test` pass.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Low | Behavior-preserving verbatim move; unchanged test suite (AC-3/AC-7) locks structure/order/icons/labels/divider; `dart analyze` (AC-6) confirms import resolution. The only subtlety — the l10n relative import — is resolved: it stays unchanged (`app_router.dart:21` proves the path at the same depth). |

## Review Checkpoints

None. Single low-risk task; the `/execute-task` post-execution `dart analyze` + `flutter test` + code-reviewer pass is sufficient. (The `/review` stage still runs security/performance/test assessment on the changed files per the workflow.)

## Verification Summary

**Verified**: 2026-05-27 — verdict **APPROVED**. All 8 ACs PASS. `dart analyze` clean; `flutter test` 241 passed (count unchanged — no tests lost in the move); scope clean (exactly the 5 spec'd files); no leftover artifacts. Review: security PASS (0 Crit/High), performance no blocking findings (1 pre-existing Low, out of scope), test coverage ADEQUATE. Spec status set to Complete.

## Contract Consistency

Consistent. Task 001's `Expects` all describe existing codebase state (verified during analysis). All `Produces` items map directly to spec acceptance criteria (AC-1, AC-2/3, AC-4, AC-5, AC-8). No downstream task exists to consume them — expected for a single-task breakdown where Produces map to ACs rather than to a successor's Expects. No orphans, no unsatisfied Expects.
