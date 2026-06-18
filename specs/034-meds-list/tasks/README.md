# Tasks: Medications List Screen

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Generated**: 2026-06-18
**Total tasks**: 13

## Dependency Graph

```
001 (derivation) ──→ 002 (derivation tests)
                 └──→ 009 (view-model) ──→ 010 (tile+section) ──→ 011 (screen) ──→ 012 (screen tests)
003 (reactive read) ──→ 004 (data tests)
                    ├──→ 005 (list provider) ─────────────────────→ 011
                    └──→ 013 (seeder)
006 (l10n) ──→ 008 (formatters) ──→ 010
          └──→ 010, 011
007 (form-icon map) ──→ 010
```

Execution waves (parallelizable within a wave):
- **Wave A**: 001, 003, 006, 007 (no deps)
- **Wave B**: 002 (←001), 004 (←003), 005 (←003), 008 (←006), 009 (←001), 013 (←003)
- **Wave C**: 010 (←006,007,008,009)
- **Wave D**: 011 (←005,009,010,006)
- **Wave E**: 012 (←011)

## Task Index

| # | Title | Agent | Depends on | Review | Status |
|---|-------|-------|-----------|--------|--------|
| 001 | Domain activity + course-progress derivation | architect | None | No | Complete |
| 002 | Derivation unit tests (fixed Clock) | qa-engineer | 001 | No | Complete |
| 003 | Reactive read: watched join + repo `watchAll` | architect | None | No | Complete |
| 004 | Reactive read data tests (in-memory drift) | qa-engineer | 003 | No | Complete |
| 005 | `medicationsList` stream provider | architect | 003 | No | Complete |
| 006 | List-screen l10n keys (en/de/uk) | mobile-engineer | None | No | Complete |
| 007 | Shared form→icon map + add-modal refactor | mobile-engineer | None | No | Complete |
| 008 | Display formatters (dose/times/stock) | mobile-engineer | 006 | No | Complete |
| 009 | View-model: filter/search/group/derive + tests | architect | 001 | No | Complete |
| 010 | Medication tile + section widgets | mobile-engineer | 006,007,008,009 | **Yes** | Complete |
| 011 | Rebuild `MedsScreen` (search/filter/sections/states) | mobile-engineer | 005,006,009,010 | **Yes** | Complete |
| 012 | Screen widget tests (incl. reactive add) | qa-engineer | 011 | No | Complete |
| 013 | Debug seeder + bootstrap wiring | architect | 003 | **Yes** | Complete |

## Verification Summary _(/verify 2026-06-18)_

**Verdict: APPROVED.** All 19 ACs PASS (code-reading mode — `AC_VERIFICATION: off`). `dart analyze` clean; full `flutter test` **481/481**; debug APK build PASS; cross-task consistency PASS; no scope creep; no leftover artifacts. Review: security PASS (0 Crit/High, 1 Medium), performance clean (no actionable), test coverage GAPS FOUND (16/19 ACs test-backed). Non-blocking Warnings carried forward (see `review.md`): (1) localize the screen error string vs raw `e.toString()` [CWE-209 Medium]; (2) add a pure `devSeedMedications` coverage test [AC-16/17]; (3) widget-test the Paused type chip [AC-9]; (4) provider-fold + de/uk locale assertions [Low].

## Additions to Spec

Refinements within the spec's "new derivation" / "section/list widgets" Affected Areas (not scope growth):
- Split the derivation into leaf enums `medication_activity_status.dart` + `course_phase.dart` (task 001).
- Extracted pure shaping into `presentation/view_models/meds_list_view_model.dart` (task 009).
- Added `presentation/widgets/medication_display.dart` (formatters, task 008) and `medication_section.dart` (task 010).

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Med | Cycle-day / inclusive-end / DST math — the correctness heart of the feature |
| 003 | Med | First watched-join read; slot grouping + re-emission on either table |
| 007 | Med | Modifies the shipped add modal (existing tests must stay green) |
| 013 | Med | Touches `app_bootstrap` + the real write path; must never duplicate/wipe data |
| others | Low | Pattern-following or isolated |

## Review Checkpoints

| Before Task | Reason | What to Review |
|-------------|--------|----------------|
| 010 | Convergence (4 deps); first rendered widgets | Tile renders icon/subtitle/chips from `MedListItem`; low-stock color; non-tappable chevron |
| 011 | Convergence + UI↔domain/data layer crossing | Screen wires provider→view-model→sections; filter/search/empty/loading/error all handled |
| 013 | High-risk (bootstrap + real DB) | `kDebugMode` + empty-table guard; insert-only; no PHI logging; covers all variants |

## Contract Chain

No orphans. Every `Produces` is consumed by a downstream `Expects` or maps to an AC (see per-task contracts + the plan's AC→file cross-reference). `Expects` for Wave-A tasks describe existing codebase state (verified during planning).
