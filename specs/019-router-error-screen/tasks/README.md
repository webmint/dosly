# Tasks: Router Error Screen for Unmatched Routes

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Generated**: 2026-05-18
**Total tasks**: 3
**Status**: All Complete (3/3) — `/verify` rendered APPROVED on 2026-05-18 (15/15 ACs PASS, 1 Warning: Test 7 body-text assertion)

## Dependency Graph

```
001 (l10n: ARB + gen-l10n)
  └─→ 002 (source: errorBuilder + _RouterErrorScreen + Test 7)
        └─→ 003 (close bug 008 + docs/architecture.md bullet)
```

Linear chain. Each task gates the next.

## Task Index

| # | Title | Agent | Depends on | Status |
|---|-------|-------|-----------|--------|
| 001 | Add error-screen ARB keys and regenerate l10n | mobile-engineer | None | Complete |
| 002 | Wire `errorBuilder` + private `_RouterErrorScreen` + Test 7 | mobile-engineer | 001 | Complete |
| 003 | Close bug 008 and document the error screen in `docs/architecture.md` | tech-writer | 002 | Complete |

## Spec AC Coverage

| AC | Task |
|---|---|
| AC-1 (`errorBuilder:` arg present) | 002 |
| AC-2 (Scaffold/AppBar/body/FilledButton structure) | 002 |
| AC-3 (`/nonexistent` test → error screen + recovery) | 002 |
| AC-4 (en ARB keys + descriptions) | 001 |
| AC-5 (de ARB keys) | 001 |
| AC-6 (uk ARB keys) | 001 |
| AC-7 (gen-l10n clean; 4 generated files contain the getter) | 001 |
| AC-8 (no `AppBottomNav` on error screen) | 002 |
| AC-9 (zero new `!` sites) | 002 |
| AC-10 (no new `lib/features/` import in `app_router.dart`) | 002 |
| AC-11 (`dart analyze` exit 0) | 001 + 002 |
| AC-12 (`flutter test` exit 0, 7 tests pass) | 002 |
| AC-13 (`flutter build apk --debug` exit 0) | 002 |
| AC-14 (`bugs/008-*.md` Fixed + Resolution) | 003 |
| AC-15 (`docs/architecture.md` bullet) | 003 |

All 15 ACs covered.

## Additions to Spec

None. The task breakdown surfaces exactly the 7 hand-edited files (3 ARB + 1 source + 1 test + 1 bug + 1 doc) plus 4 auto-regenerated l10n files that `spec.md` §4 already enumerated. No new files discovered during analysis.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Low | Mechanical ARB additions in a well-trodden pipeline (features 006/008/009/010/011 all did the same). `flutter gen-l10n` is the gate — if any locale is missing a key, codegen errors out before Task 002 starts. |
| 002 | Med | Carries 9 of the 15 ACs and the load-bearing behavior assertion (AC-8: `errorBuilder` renders outside `StatefulShellRoute`). The risk is not the widget code (well-specified by plan §"Implementation Approach") but the `go_router` 17.2 interaction with `StatefulShellRoute`. Mitigated: Test 7's `find.byType(AppBottomNav) findsNothing` assertion verifies AC-8 directly; if the framework behavior is opposite to expectation the test fails fast. |
| 003 | Low | Pure documentation and bookkeeping. No source code touched. Bullet text is verbatim-fixed in the task body so no ambiguity. |

## Review Checkpoints

No formal review checkpoints (no convergence points; chain is linear; no task is rated High). The standard per-task `code-reviewer` agent runs at the end of every `/execute-task` already covers each task's outputs.

## Contract Chain Integrity

| Producer → Consumer | Verified |
|---|---|
| Task 001 Produces (`AppLocalizations` getters `errorScreenTitle` / `errorScreenBody` / `errorScreenGoHome`) → Task 002 Expects (same getters) | ✓ |
| Task 002 Produces (`errorBuilder:` arg + `_RouterErrorScreen` class) → Task 003 Expects (same symbols) | ✓ |
| Task 003 Produces (bug Status: Fixed + architecture.md bullet) → maps directly to AC-14, AC-15 | ✓ |

No orphan Produces. No unsatisfied Expects.
