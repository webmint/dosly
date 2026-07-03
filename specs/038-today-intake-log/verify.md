# Verification Report

**Feature**: 038-today-intake-log
**Spec**: specs/038-today-intake-log/spec.md
**Tasks**: specs/038-today-intake-log/tasks/
**Date**: 2026-07-02
**Mode**: code-reading (`AC_VERIFICATION: off` — mobile app, verified by reading code + `flutter test`)

### Acceptance Criteria
| AC | Status |
|----|--------|
| AC-1 Continuous due / future-start none | PASS |
| AC-2 Non-cyclic course window (incl./excl. boundaries, completed) | PASS |
| AC-3 Cyclic course active-window vs pause-gap | PASS |
| AC-4 Sort by minuteOfDay, effectiveDose, DST-safe | PASS |
| AC-5 `intakes` table, schemaVersion 2, add-only onUpgrade, onCreate, FK | PASS |
| AC-6 Idempotent mark by (medId,slotId,scheduledAt), UTC round-trip | PASS |
| AC-7 v1 data survives 1→2 upgrade | PASS |
| AC-8 Flat time-sorted checklist (icon/name/24h/dose) | PASS |
| AC-9 Mark taken/skip reactive + survives rebuild | PASS |
| AC-10 Early marking; no overdue styling | PASS (⚠ no negative-styling test) |
| AC-11 Empty / loading / error states | PASS (⚠ error branch untested) |
| AC-12 Undo affordance → deletes row → pending | PASS |
| AC-13 5-min grace gating (boundary, disappears, no-op after) | PASS |
| AC-14 Strings in en/de/uk + @-desc; consumed via context.l10n | PASS (⚠ no DE/UK render test) |
| AC-15 analyze clean, pure domain, Either, dartdoc, green suite | PASS (⚠ isolated use-case/repo-impl tests missing) |

**Result: 15 of 15 PASS** (behavior verified by code + tests). The four ⚠ marks are test-coverage gaps (Warnings), not behavior failures.

### Code Quality
- Type checker (`dart analyze`): **PASS** — No issues found.
- Linter (`dart analyze`): **PASS**.
- Build (`flutter build apk --debug`): **PASS** (Task 016).
- Full test suite (`flutter test`): **PASS** — 659/659 (Task 016; unchanged since — only docs + whitespace format edits).
- Cross-task consistency: **PASS** — the intake slice connects end-to-end (contract → data source/mapper/repo-impl → `@riverpod` seam → `buildTodayView` → `TodayScreen`); `TodayDose.intakeId` wires the view-model→screen undo path; router branch 0 → `TodayScreen`.
- No scope creep: **PASS (with documented deviation)** — retiring `HomeScreen`, the `app_router_test` `_HomeStub`, and the `app_bootstrap_test`/`widget_test` DB overrides were beyond the spec's original Affected Areas, but were the necessary consequence of the §2.1 architecture correction (Today UI must live in `meds`, routed) surfaced at the Task-014 layer-boundary code-review checkpoint. Documented in Task 014/015 completion notes.
- No leftover artifacts: **PASS** — no `print`/`debugPrint`/`debugger`/bare-TODO in changed production files.

### Review Findings (from review.md)
**Security**: Critical: 0 | High: 0 | Medium: 0 | Info: 2 — **PASS**. No PHI logged; sanitizer intact; add-only migration; parameterized drift queries; `allowBackup=false`; no network added.
**Performance**: High: 0 | Medium: 2 | Low: 4 — one cheap do-now (`buildTodayView` O(doses×intakes) → map), one documented deferral (`watchAllIntakes` unbounded).
**Test Coverage**: **GAPS FOUND** — 12/15 fully covered, 3 partial. Gaps folded into Warnings below.

### Issues Found

#### Critical (must fix before merge)
None.

#### Warning (should fix, not blocking)
1. **AC-11 error path untested** — `today_screen.dart`'s stream-error branch (`todayLoadError`) is never driven into `AsyncValue.error`, and `IntakeRepositoryImpl` has **no test file** (its `watchAll`/`markTaken`/`skip`/`undo` catch→`Left(CacheFailure)` conversions are unverified). Breaks the project's own repo-impl-test convention (`medication_repository_impl_test.dart` has a failure-path group).
2. **AC-6/AC-15: MarkIntakeTaken/SkipIntake lack isolated unit tests** — only `UndoIntake` has one; their UTC-normalize / `IdGenerator` mint / `notes:null` logic is exercised only through the widget→DB path, unlike every other meds use case.
3. **AC-14: no DE/UK locale spot-check** — every today-feature widget test is EN-only. **Recurrence of the feature-037 lesson already recorded in MEMORY.md** ("a passing EN-only suite is not proof"); the DE/UK convention exists in sibling meds tests.
4. **AC-10: no negative styling assertion** — no test proves a past-scheduled pending tile is styling-identical to a future one (a one-sided overdue-styling regression wouldn't be caught).
5. **Perf (do-now, cheap): `buildTodayView` O(doses×intakes)** — pre-build a `(medId,slotId,localDate)` map (`today_view_model.dart`) → O(doses+intakes); also drops the now-dead "prefer non-pending" fallback.
6. **FK cascade untested** — `intakes.medicationId onDelete: cascade` (resolves spec §8's open question) has no test proving a medication delete cascades to its intake rows.

#### Info (nice to have)
- `Failure.cache('…: $e')` in `intake_repository_impl.dart` embeds the raw exception — safe today (never rendered/logged), preserve that contract.
- Pre-existing/out-of-scope: `meds_screen.dart:209` renders `e.toString()` (align to the Today screen's generic-message pattern later).
- Perf deferral: date-scope `watchAllIntakes` + add a `scheduledAt` index when the History feature lands.

### Overall Verdict
**APPROVED** — all 15 acceptance criteria are satisfied (behavior) and every code-quality gate passes; security review is clean. The 6 Warnings are non-blocking, additive (test-only) or performance-enhancement items with no behavior defect and no constitution violation (the §2.1 issue was resolved during execution). Recommended: close Warnings 1–3 (and optionally 5) via `/fix` before `/finalize`.
