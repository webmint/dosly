# Tasks: Home Screen App Bar

**Spec**: specs/003-home-app-bar/spec.md
**Plan**: specs/003-home-app-bar/plan.md
**Generated**: 2026-04-12
**Total tasks**: 2

## Dependency Graph

```
001 (theme) ──→ 002 (home screen + tests)
```

## Task Index

| # | Title | Agent | Depends on | Status |
|---|-------|-------|-----------|--------|
| 001 | Update global AppBarTheme defaults | mobile-engineer | None | Complete |
| 002 | Add AppBar to HomeScreen and update tests | mobile-engineer | 001 | Complete |

## Additions to Spec

None — all files and changes match the spec's Affected Areas table exactly.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Low | 2-line change in an existing theme builder; no logic, pure configuration |
| 002 | Low | Adding a standard AppBar widget to an existing Scaffold; well-documented Flutter pattern |

## Review Checkpoints

| Before Task | Reason | What to Review |
|-------------|--------|----------------|
| 002 | Layer boundary crossing (core/theme → presentation) | Verify Task 001's AppBarTheme changes compile and the theme preview screen's AppBar still renders correctly |

## Contract Chain Verification

All "Produces" items are consumed:
- Task 001 produces `surfaceContainer` + `surfaceTintColor` → consumed by Task 002's Expects
- Task 002 produces AppBar widget + test assertion → maps directly to spec AC-1 through AC-13

All "Expects" items are satisfied:
- Task 001 expects existing `AppBarTheme` with `scheme.surface` → true in current codebase
- Task 002 expects Task 001 outputs + existing Scaffold with no appBar → both satisfied

No orphaned contracts.
