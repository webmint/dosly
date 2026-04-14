# Tasks: Lucide Icons

**Spec**: specs/004-lucide-icons/spec.md
**Plan**: specs/004-lucide-icons/plan.md
**Generated**: 2026-04-12
**Total tasks**: 2

## Dependency Graph

```
001 (add dependency) ──→ 002 (replace icons + showcase)
```

## Task Index

| # | Title | Agent | Depends on | Status |
|---|-------|-------|-----------|--------|
| 001 | Add lucide_icons_flutter dependency | mobile-engineer | None | Complete |
| 002 | Replace Material icons with Lucide equivalents and add icon showcase | mobile-engineer | 001 | Complete |

## Additions to Spec

None — no files discovered beyond the spec's Affected Areas.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Low | Single dependency addition; package is well-maintained |
| 002 | Low | Mechanical icon swap + small showcase widget; `dart analyze` catches any wrong icon names instantly |

## Review Checkpoints

| Before Task | Reason | What to Review |
|-------------|--------|----------------|
| (after 002) | Layer crossing — only presentation task, final gate | All icons render correctly, showcase section present, no Material icon leftovers |

## AC Coverage

| AC | Task(s) |
|----|---------|
| AC-1 | 001 |
| AC-2 | 002 |
| AC-3 | 002 |
| AC-4 | 002 |
| AC-5 | 002 |
| AC-6 | 002 |
| AC-7 | 001, 002 |
| AC-8 | 002 |
| AC-9 | 002 |

## Contract Chain Integrity

All contract chains verified:
- Task 001 Produces → consumed by Task 002 Expects (`lucide_icons_flutter` in pubspec)
- Task 002 Produces → maps directly to AC-2, AC-3, AC-4, AC-5, AC-6
- No orphaned Produces, no unsatisfied Expects
