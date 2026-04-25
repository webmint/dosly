# Tasks: Settings Screen

**Spec**: specs/008-settings-screen/spec.md
**Plan**: specs/008-settings-screen/plan.md
**Generated**: 2026-04-25
**Total tasks**: 2

## Dependency Graph

```
001 (screen + l10n + route + wiring) ──→ 002 (tests, TERMINAL GATE)
```

## Task Index

| # | Title | Agent | Depends on | Status |
|---|-------|-------|-----------|--------|
| 001 | Create Settings screen, add l10n keys, wire route and gear icon | mobile-engineer | None | Complete |
| 002 | Add SettingsScreen widget test and router integration test | mobile-engineer | 001 | Complete |

## Additions to Spec

None — all files match the spec's Affected Areas table.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Low | All changes are mechanical copies of existing patterns (MedsScreen, /theme-preview route) |
| 002 | Low | Tests follow established meds_screen_test.dart and app_router_test.dart Test 5 patterns exactly |

## Review Checkpoints

| Before Task | Reason | What to Review |
|-------------|--------|----------------|
| (after 002) | Terminal task — full integration gate | `dart analyze` clean, `flutter test` all pass, `flutter build apk --debug` succeeds |

## Contract Chain Integrity

All "Produces" from Task 001 are consumed by Task 002's "Expects". Task 002's "Produces" map directly to spec AC-9 through AC-12. No orphaned or unsatisfied contracts.
