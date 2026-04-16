# Tasks: Meds & History Screens + Tabbed Routing

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Generated**: 2026-04-15
**Total tasks**: 5
**Status**: All Complete — feature verified 2026-04-15 (see [verify.md](../verify.md))

## Dependency Graph

```
001 (HomeBottomNav refactor) ──→ 004 (AppShell) ──→ 005 (Router + integration test)
002 (MedsScreen + test) ─────────────────────────→ 005
003 (HistoryScreen + test) ──────────────────────→ 005
```

Tasks 001, 002, 003 are independent and can run in any order (or in parallel). Task 004 requires 001. Task 005 converges on all four.

## Task Index

| # | Title | Agent | Depends on | Review checkpoint | Status |
|---|-------|-------|-----------|-------------------|--------|
| 001 | Refactor HomeBottomNav signature | mobile-engineer | None | No | Complete |
| 002 | Create MedsScreen + widget test | mobile-engineer | None | No | Complete |
| 003 | Create HistoryScreen + widget test | mobile-engineer | None | No | Complete |
| 004 | Create AppShell shell scaffold | mobile-engineer | 001 | **Yes** | Complete |
| 005 | Refactor router to StatefulShellRoute + integration test | mobile-engineer | 001, 002, 003, 004 | **Yes** | Complete |

## Additions to Spec

None. All files called out in the task breakdown were already present in the plan's File Impact table. The plan's Documentation Impact entries (`docs/features/meds.md`, `docs/features/history.md`, `docs/architecture.md` §Routing update, `docs/features/home.md` §Evolution update) will be authored by the tech-writer agent during `/finalize` and are not task-gated.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Low | Signature migration with tight call-site control (one production caller + two test files, all updated in the same task) — cascading compile errors surface immediately under `dart analyze`. |
| 002 | Low | Mechanical — mirrors the existing `home_screen.dart` AppBar pattern and the `home_bottom_nav_l10n_test.dart` harness. |
| 003 | Low | Mechanical mirror of 002, differing only in strings and folder name. |
| 004 | Medium | First `StatefulShellRoute` consumer in the codebase. `navigationShell.goBranch` tearoff must satisfy `ValueChanged<int>` — worked around with a wrapper lambda if `dart analyze` rejects the direct tearoff. Isolated risk — only touches one file, no other tasks depend on internal shape beyond the public class signature. |
| 005 | Medium-High | Convergence task + first `StatefulShellRoute` wiring at the router level. AC-11 (branch stack preservation) requires a test-only sub-route under the Meds branch — a novel pattern for this codebase. Full integration gate (`flutter test` + `flutter build apk --debug`) runs here per the Feature 002 integration-gate ordering pattern. |

## Review Checkpoints

| Before Task | Reason | What to Review |
|-------------|--------|----------------|
| 004 | First use of `StatefulShellRoute` / `StatefulNavigationShell` in the codebase | Verify: (a) imports are correct, (b) `AppShell` does NOT call `!` on any nullable, (c) `navigationShell.goBranch` tearoff matches `ValueChanged<int>` or uses a `(i) => navigationShell.goBranch(i)` wrapper, (d) no hard-coded colors, (e) dartdoc explains the go_router adapter role. |
| 005 | Convergence + layer-boundary integration + high risk. | Verify: (a) the `StatefulShellRoute` has exactly 3 branches in the expected order (0=Home, 1=Meds, 2=History), (b) `/theme-preview` is a **sibling** top-level route (not nested under any branch), (c) the integration test covers all 7 targeted ACs (1, 2, 8, 9, 10, 11, 13), (d) the AC-11 test uses a test-only router instance (not the production `appRouter`) so production routes stay clean, (e) `flutter build apk --debug` passes. |

## Contract Chain Check

- Task 001 Produces → consumed by Task 004 Expects (HomeBottomNav constructor shape) ✓
- Task 002 Produces → consumed by Task 005 Expects (MedsScreen importable) ✓
- Task 003 Produces → consumed by Task 005 Expects (HistoryScreen importable) ✓
- Task 004 Produces → consumed by Task 005 Expects (AppShell class + constructor) ✓
- Task 005 Produces → maps to spec ACs 1, 2, 8, 9, 10, 11, 13, 15, 16, 17 ✓

No orphan Produces and no unsatisfied Expects.

## AC Coverage Map

| AC | Description | Covered by task(s) |
|----|-------------|--------------------|
| AC-1  | `/meds` → MedsScreen | 002 (screen), 005 (route + test) |
| AC-2  | `/history` → HistoryScreen | 003 (screen), 005 (route + test) |
| AC-3  | MedsScreen title localized (en/de/uk) | 002 |
| AC-4  | HistoryScreen title localized | 003 |
| AC-5  | 1-px divider on new screens | 002, 003 |
| AC-6  | No actions on new screens | 002, 003 |
| AC-7  | Empty body on new screens | 002, 003 |
| AC-8  | Single bottom nav across all tabs | 004 (shell), 005 (test) |
| AC-9  | Tap destination navigates to correct route | 005 (test) |
| AC-10 | `selectedIndex` reflects current route | 004 (wiring), 005 (test) |
| AC-11 | Branch stack preservation | 005 (test with test-only sub-route) |
| AC-12 | HomeScreen retains settings + theme preview | 001 (only nav line removed), 005 (verified via existing `widget_test.dart`) |
| AC-13 | `/theme-preview` renders without shell | 005 (test) |
| AC-14 | French fallback to English titles | 002 test, 003 test |
| AC-15 | `flutter test` passes | 005 terminal gate |
| AC-16 | `dart analyze` passes | Every task's done-when |
| AC-17 | `flutter build apk --debug` succeeds | 005 terminal gate |

All 17 ACs covered.
