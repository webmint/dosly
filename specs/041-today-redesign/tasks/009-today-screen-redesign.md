# Task 009: Redesign `today_screen` — countdown + groups + boundary timer

**Agent**: mobile-engineer
**Review checkpoint**: Yes
**Files**: `lib/features/meds/presentation/screens/today_screen.dart`, `test/features/meds/presentation/screens/today_screen_test.dart`, `lib/features/meds/domain/value_objects/intake_grace.dart` (delete)
**Depends on**: 005, 006, 007, 008, 002
**Blocks**: 010
**Context docs**: `docs/features` (Today), `specs/041-today-redesign/plan.md`

## Description

Assemble the redesigned Today screen: render the `TodayCountdownCard` above a list of `TodayGroupSection`s (replacing the flat tile list), wire Mark-all, generalize the one-shot grace timer into a single self-rescheduling **boundary** timer that re-derives the whole view at the next relevant instant (no DB writes, never `Timer.periodic`), and delete the now-unreferenced `intake_grace.dart`. Rewrite the screen test for the new interaction model.

## Change details

- In `lib/features/meds/presentation/screens/today_screen.dart`:
  - Body: `TodayCountdownCard(nextScheduledAt: view.nextIntake?.dose.scheduledAt, now: now)` then a `ListView` of `TodayGroupSection`s (one per `view.groups`), passing `now`, per-dose `onTaken/onSkip/onUndo`, `onMarkAll`, and `initiallyExpanded` = (`group.state == TodayGroupState.now`, or the soonest `future` group when no `now` group exists). Keep `TodayEmptyState` for `view.isEmpty`.
  - Replace `_scheduleGraceRefresh` with `_scheduleNextBoundaryRefresh(view, now)`: compute the minimum future instant among each future dose's `scheduledAt`, each open dose's `scheduledAt + intakeWindow`, and each taken/skipped dose's `confirmedAt + gracePeriod`; schedule ONE one-shot `Timer` for `(boundary - now)` that `setState(() {})` to re-derive. No `Timer.periodic`; cancel in `dispose` and before each reschedule; no DB writes; no reconcile call. Use the `intakeWindow`/`gracePeriod` from `todayIntakeSettingsProvider`.
  - Add `_onMarkAllInGroup(TodayHourGroup group)`: iterate `group.doses.where((d) => d.status == pending && d.actionable)`, `await markIntakeTakenProvider.call(...)` each (sequential), `mounted`-guard, show one `todayActionError` SnackBar on any failure.
  - Remove `import '../../domain/value_objects/intake_grace.dart';` and the `kIntakeUndoGracePeriod` usage in the timer.
  - Preserve the tile-key scheme `todayTile-<medId>-<slotId>` and the `initState` reconcile trigger (spec 040) unchanged.
- Delete `lib/features/meds/domain/value_objects/intake_grace.dart` (confirm zero remaining `kIntakeUndoGracePeriod`/`intake_grace` refs in `lib/` first).
- In `test/features/meds/presentation/screens/today_screen_test.dart`:
  - Rewrite for the new model: checkbox check→taken, uncheck-within-grace→undo, skip icon→skipped, Mark-all marks the group's actionable pending doses; countdown card shows next/all-done; groups render/collapse. Keep the mutable-`Clock` + `FakeAsync` idiom and assert `pumpAndSettle` settles (one-shot timer) and that advancing the clock past a boundary re-derives (badge/countdown change) with no new writes. Override `todayIntakeSettingsProvider` where a specific window/grace/mark-ahead is needed.

## Contracts

### Expects
- `TodayView` exposes `groups` (`List<TodayHourGroup>`) + `nextIntake` (`TodayDose?`); `TodayHourGroup` exposes `state`, `doses`, `hasActionablePending` (task 005).
- `TodayCountdownCard` (task 007) and `TodayGroupSection` (task 008) exist; `TodayDoseTile` uses the checkbox/skip model (task 006).
- `todayIntakeSettingsProvider` exposes `intakeWindow`/`gracePeriod`/`allowMarkAhead` (task 002).

### Produces
- `today_screen.dart` renders `TodayCountdownCard` + `TodayGroupSection`s (no flat `ListView` of `TodayDoseTile`), declares `_scheduleNextBoundaryRefresh` and `_onMarkAllInGroup`, uses exactly one one-shot `Timer` (no `Timer.periodic`), and imports no `intake_grace.dart`.
- `intake_grace.dart` is deleted; no `kIntakeUndoGracePeriod` reference remains in `lib/`.
- `today_screen_test.dart` exercises checkbox/skip/undo/mark-all/groups/countdown and is `pumpAndSettle`-safe.

## Done when
- [x] Countdown card + collapsible hour groups render; current group expanded by default; Mark-all marks the group's actionable pending doses.
- [x] One one-shot boundary `Timer` (never `Timer.periodic`) re-derives at the next boundary with no DB writes/reconcile; cancelled on dispose/reschedule.
- [x] `intake_grace.dart` deleted; `grep -r kIntakeUndoGracePeriod lib` is empty.
- [x] `flutter test test/features/meds/presentation/screens/today_screen_test.dart` is green and settles.
- [x] `dart analyze` passes on changed files.

**Spec criteria addressed**: AC-3, AC-5, AC-6, AC-7, AC-10, AC-14, AC-15

## Completion Notes

**Status**: Complete
**Completed**: 2026-07-06
**Files changed**: `today_screen.dart` (redesign + review repair), `today_screen_test.dart` (rewrite, 13 tests), `intake_grace.dart` (DELETED)
**Contract**: Expects [3/3 verified] | Produces [3/3 verified — card+sections body, `_scheduleNextBoundaryRefresh`/`_onMarkAllInGroup`, one-shot timer, no `intake_grace`]
**Notes**: Body = `ListView.builder` (card at index 0 + `TodayGroupSection` per group, keyed `todayGroupSectionItem-<hour>`). `_scheduleNextBoundaryRefresh`: candidates (future→open, open→close, undoable→grace-expiry) filtered to strictly-after-`now`, min scheduled as ONE one-shot `Timer`; fire = `setState` only (no DB/reconcile); cancelled dispose/loading/error/reschedule. `_onMarkAllInGroup` sequential `markTaken` over pending+actionable, per-iteration `mounted` guard, one error SnackBar. Full suite 834/834 (test/); meds 435/435; analyze clean.
**Code review**: APPROVE WITH WARNINGS → repaired. Timer verified correct + `pumpAndSettle`-safe (Critical: none). Fixed W1 (mark-all `ref.read`-after-`await` crash risk → per-iteration `mounted` guard) + Info hardening (explicit list-item key). Info deferred to task 010: `integration_test/today_intake_flow_test.dart` still uses retired `todayTake` key (task 010 scope updated to repair integration_test + confirm no retired-key refs).
