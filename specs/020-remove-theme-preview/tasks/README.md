# Tasks: Remove theme_preview feature

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Generated**: 2026-05-22
**Total tasks**: 3
**Status**: All tasks Complete — spec verified APPROVED 2026-05-22 (12/12 ACs PASS, `dart analyze` clean, 226 tests, apk built). Next: `/summarize` → `/finalize` (clears pending docs cleanup).

## Dependency Graph

```
001 (remove source refs)  ──┐
                            ├──→ 003 (delete folder + close bug)
002 (update tests)        ──┘
```

001 and 002 are independent (source vs. test files) and may run in either order
or in parallel. 003 is the convergence point — it physically deletes the folder
and must run only after both 001 and 002 have removed every inbound reference.

## Task Index

| # | Title | Agent | Depends on | Status |
|---|-------|-------|-----------|--------|
| 001 | Remove all source references to theme_preview | mobile-engineer | None | Complete |
| 002 | Update tests to drop theme_preview coverage | qa-engineer | None | Complete |
| 003 | Delete the theme_preview folder and close Bug 009 | mobile-engineer | 001, 002 | Complete |

## Additions to Spec

None. All files match the spec's "Affected Areas". Doc prose cleanup
(`docs/architecture.md`, `docs/overview.md`, `docs/features/{i18n,settings,home,theme,icons}.md`)
is intentionally excluded from these tasks — it is handled by the tech-writer
agent at `/finalize` per spec §6 and the plan's Documentation Impact table.

## Ordering Rationale

References are removed **before** the folder is deleted (reverse of the usual
"build bottom-up" order) so that `dart analyze` stays green after every task. If
the folder were deleted first, the imports in `app_router.dart` and
`app_router_test.dart` would point at nonexistent files and fail analysis.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Low | Mechanical reference removal; only watch item is keeping the `go_router` import in `home_screen.dart` (caught by `dart analyze`) |
| 002 | Low | Test deletion + one assertion edit; theme-cycle coverage preserved elsewhere |
| 003 | Low | Pure deletion after refs are gone; verified by grep + full analyze/test/build gate |

## Review Checkpoints

| Before Task | Reason | What to Review |
|-------------|--------|----------------|
| 003 | Convergence (depends on 001 + 002) + the irreversible deletion | Confirm 001 and 002 left zero `theme_preview` references in source and tests before the folder is physically removed; confirm `go_router` import survived in `home_screen.dart` |

## Contract Chain Integrity

- Task 001 **Produces** (no refs in `app_router.dart` / `home_screen.dart` / `app.dart`)
  → consumed by Task 003 **Expects**. ✓
- Task 002 **Produces** (no refs in the two test files) → consumed by Task 003
  **Expects**. ✓
- Task 003 **Produces** (folder gone, grep clean, bug Fixed) → maps to AC-1, AC-2,
  AC-8. ✓
- No orphaned Produces; no unsatisfied Expects. Chain is intact.
