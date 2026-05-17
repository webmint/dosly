# Tasks: Settings feature — introduce `domain/usecases/`

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Review**: [../review.md](../review.md)
**Verify**: [../verify.md](../verify.md)
**Generated**: 2026-05-09
**Verified**: 2026-05-17 — APPROVED (20/20 ACs PASS)
**Total tasks**: 7 (all Complete)

## Dependency Graph

```
001 (AppLanguage helper + data adopt) ──┐
                                        │
002 (pass-through use cases)            ├──→ 005 (provider wiring + notifier) ──→ 006 (widgets + cycle screen) ──→ 007 (docs + bugs)
003 (atomic use cases)                  │
004 (CycleThemeMode use case)           ┘
```

Tasks 001–004 are independent of each other and can run in parallel in principle. Task 005 converges on all four. Task 006 is the integration gate (full `flutter test` + `flutter build apk --debug`). Task 007 is the docs/bookkeeping terminus.

## Task Index

| # | Title | Agent | Depends on | Status |
|---|-------|-------|-----------|--------|
| 001 | Add `AppLanguage.fromLanguageCodeOrDefault` + adopt in data source | architect | None | Complete |
| 002 | Create `SetThemeMode` and `SetManualLanguage` pass-through use cases | architect | None | Complete |
| 003 | Create `SetUseSystemTheme` and `SetUseSystemLanguage` atomic use cases | architect | None | Complete |
| 004 | Create `CycleThemeMode` use case (returns next-state record) | architect | None | Complete |
| 005 | Wire use case providers + rewrite `SettingsNotifier` mutators + adapt notifier test | architect | 001, 002, 003, 004 | Complete |
| 006 | Simplify selector callbacks + theme_preview cycle to one-call delegation + adapt widget tests (integration gate) | mobile-engineer | 005 | Complete |
| 007 | Update docs + close bugs 005 and 011 | tech-writer | 006 | Complete |

## Additions to Spec

None. The plan refined `CycleThemeMode`'s return type from `Future<Either<Failure, void>>` to `Future<Either<Failure, ({bool useSystemTheme, AppThemeMode manualThemeMode})>>` (documented in plan §"Key Design Decisions" and Risk Assessment); each task that touches this use case carries the refined type explicitly. AC-7's three-transition behavioural check is preserved.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Low | Single-file additive change + 1 mechanical call-site replacement; tests prove the helper |
| 002 | Low | Two thin pass-through use cases mirroring the constitution's `AddMedication` template |
| 003 | Medium | First introduction of `verifyInOrder` for atomicity; ordering bugs would silently leave `manualX` updated but `useSystemX` stale |
| 004 | Medium | Three-branch state-shape return; notifier downstream relies on the record matching the actually-persisted state |
| 005 | Medium | Layer-boundary task — wires 5 new providers, rewrites 4 mutators, changes 2 notifier signatures, regenerates `*.g.dart`, adapts notifier test fakes |
| 006 | Medium | UI layer rewrite + integration gate (full `flutter test` + `flutter build apk --debug`); existing widget tests must continue to pass |
| 007 | Low | Pure markdown — docs update + bug status flips |

## Review Checkpoints

| Before Task | Reason | What to Review |
|-------------|--------|----------------|
| 005 | Convergence (depends on 001–004) + first cross-layer integration | Are all five use cases shaped consistently? Does each carry the contract its provider needs? Does the cycle use case's return-type record semantically match the notifier's intended `copyWith` arguments? |
| 006 | Layer boundary — first presentation-layer task; high blast radius (4 widget files + integration gate) | Are the widget callbacks reduced to a single notifier call? Are the existing widget tests still asserting on the fake repo's `savedX` state, not a recently-removed two-call sequence? |

## Contract Chain Summary

- 001 produces `AppLanguage.fromLanguageCodeOrDefault` → consumed by 006 (widget firstWhere migration) and AC-12, AC-13.
- 002–004 produce the five use case classes → consumed by 005 (provider wiring).
- 005 produces 5 use case providers + rewritten notifier mutators with new signatures + `cycleThemeMode()` notifier method → consumed by 006 (widget callbacks call new notifier API) and AC-8, AC-18.
- 006 produces simplified callbacks + `firstWhere` removal + integration-gate green → consumed by 007 (docs reflect implementation reality) and AC-9–AC-11, AC-13–AC-17.
- 007 produces updated docs + closed bugs → satisfies AC-19, AC-20.

No orphaned Produces; no unsatisfied Expects.
