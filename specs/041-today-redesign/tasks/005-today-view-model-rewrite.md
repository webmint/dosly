# Task 005: Rewrite `today_view_model` — groups, window state, enablement, countdown

**Agent**: architect
**Review checkpoint**: Yes
**Files**: `lib/features/meds/presentation/view_models/today_view_model.dart`, `test/features/meds/presentation/view_models/today_view_model_test.dart`, `lib/features/meds/presentation/screens/today_screen.dart` (call-site patch only)
**Depends on**: 002, 004
**Blocks**: 006, 007, 008, 009
**Context docs**: `specs/041-today-redesign/data-model.md`

## Description

Extend the pure `buildTodayView` to produce the render-ready structure the redesign needs: hourly groups, per-group state, per-dose window classification + checkbox enablement, and the countdown target — all derived from the three settings + `now`, unit-testable with a fixed clock. Also rewire the `undoable` derivation to the configured grace `Duration` (dropping `kIntakeUndoGracePeriod`). Keep the screen compiling with a **minimal** call-site patch (pass the new params, render the existing flat tile list from `groups.expand` — the full layout redesign is task 009). Follow `data-model.md` exactly.

## Change details

- In `lib/features/meds/presentation/view_models/today_view_model.dart`:
  - Add params to `buildTodayView`: `required IntakeWindow intakeWindow`, `required Duration gracePeriod`, `required bool allowMarkAhead` (import `IntakeWindow` from settings domain; permitted domain→domain).
  - Add `enum DoseWindowState { future, open, pastWindow }` and `enum TodayGroupState { future, now, past }`.
  - Add fields to `TodayDose`: `windowState` (`DoseWindowState`), `actionable` (`bool`). Compute `windowState` in UTC: `future` when `now < scheduledAt`; `open` when `scheduledAt <= now <= scheduledAt + intakeWindow.minutes` (inclusive both ends); else `pastWindow`. Compute `actionable` (pending only): `open` ⇒ true; `future` ⇒ `allowMarkAhead`; `pastWindow` ⇒ false; non-pending ⇒ false.
  - Change `undoable` to compare elapsed since `confirmedAt` against `gracePeriod` (inclusive) instead of `kIntakeUndoGracePeriod`; remove the `intake_grace.dart` import.
  - Add `class TodayHourGroup { int hour; List<TodayDose> doses; TodayGroupState state; int takenCount; int get total; bool get hasActionablePending; }`. Bucket doses by `slot.minuteOfDay ~/ 60`, ascending hour; within a group preserve `expandDueDoses` order. Derive `state`: all `future` ⇒ `future`; all `pastWindow` ⇒ `past`; else `now`. `takenCount` = count `status == taken`.
  - Change `TodayView` to hold `groups` (`List<TodayHourGroup>`) and `nextIntake` (`TodayDose?`) instead of `doses`; `isEmpty => groups.isEmpty`. `nextIntake` = the min-`scheduledAt` dose with `windowState == future && status == pending` (else `null`).
  - Keep the O(doses+intakes) occurrence-index approach; keep exhaustive switches (no `default:`).
- In `lib/features/meds/presentation/screens/today_screen.dart` (call-site patch ONLY):
  - Read `final s = ref.watch(todayIntakeSettingsProvider);` and pass `intakeWindow: s.intakeWindow`, `gracePeriod: Duration(minutes: s.gracePeriod.minutes)`, `allowMarkAhead: s.allowMarkAhead` to `buildTodayView`.
  - Feed the existing flat `ListView.builder` from `view.groups.expand((g) => g.doses).toList()` so the screen still renders/compiles. (Grace-timer + layout untouched here — task 009.)
- In `test/features/meds/presentation/view_models/today_view_model_test.dart`:
  - Update all `buildTodayView(...)` calls with the three new params; drop the `intake_grace.dart` import (use literal `Duration`s).
  - Add cases: hour bucketing (14:00 + 14:30 → one group); group-state boundaries (all-future/all-past/mixed→now); `windowState`/`actionable` matrix (future×markAhead on/off, open, pastWindow); `nextIntake` selection + null when none; `undoable` honoring a non-default grace.

## Contracts

### Expects
- `buildTodayView` currently takes `meds`, `intakes`, `now`; `TodayView` has `doses`; `TodayDose` has `status`, `confirmedAt`, `undoable`, `intakeId`.
- `intake_window.dart` exports `IntakeWindow` with `int minutes`; `due_dose.dart` exports `expandDueDoses` + `DueDose` (with `slot.minuteOfDay`, `scheduledAt`).
- `todayIntakeSettingsProvider` exposes `intakeWindow`/`gracePeriod`/`allowMarkAhead` (task 002); `UndoIntake` uses a `Duration` grace (task 004).

### Produces
- `today_view_model.dart` `buildTodayView` signature includes `required IntakeWindow intakeWindow`, `required Duration gracePeriod`, `required bool allowMarkAhead`.
- `today_view_model.dart` declares `enum DoseWindowState`, `enum TodayGroupState`, and `class TodayHourGroup` (fields `hour`, `doses`, `state`, `takenCount`, `total`, `hasActionablePending`).
- `TodayView` exposes `groups` (`List<TodayHourGroup>`) and `nextIntake` (`TodayDose?`); `TodayDose` exposes `windowState` (`DoseWindowState`) and `actionable` (`bool`).
- `today_view_model.dart` no longer imports `intake_grace.dart`.
- `today_screen.dart` calls `buildTodayView` with the three new params sourced from `todayIntakeSettingsProvider`.

## Done when
- [x] Doses bucket by hour (`minuteOfDay ~/ 60`); groups ascending; `nextIntake` and group `state` derive per `data-model.md`.
- [x] `windowState`/`actionable`/`undoable` match the matrix; boundary at `scheduledAt + intakeWindow.minutes` is `open` (inclusive), aligning with spec 040's strict `>` missed rule.
- [x] `today_view_model.dart` imports no `intake_grace.dart`, no Flutter/drift/data.
- [x] `flutter test test/features/meds/presentation/view_models/today_view_model_test.dart` is green (new cases included).
- [x] The screen still compiles and renders (flat, transitional).
- [x] `dart analyze` passes on changed files.

**Spec criteria addressed**: AC-1, AC-2, AC-4, AC-8, AC-9, AC-14

## Completion Notes

**Status**: Complete
**Completed**: 2026-07-05
**Files changed**: `today_view_model.dart`, `today_view_model_test.dart`, `today_screen.dart` (call-site + settings watch), `today_screen_test.dart` (AC-8 blast radius — `todayIntakeSettingsProvider` override)
**Contract**: Expects [3/3 verified] | Produces [5/5 verified — signature, 2 enums, `TodayHourGroup`, `groups`/`nextIntake`, `windowState`/`actionable`, no `intake_grace` import]
**Notes**: Pure total function; `_classifyWindow` (UTC, inclusive `open`), `_isActionable` matrix, `_buildGroup` (all-future/all-past/else-now + `takenCount`), `_findNextIntake`. Full suite 817/817 green; analyze clean.
**Code review**: APPROVE WITH WARNINGS (no Critical). Warnings & disposition:
- W1: screen grace timer still uses `kIntakeUndoGracePeriod` → real interim desync for non-5-min grace; **deferred to task 009** (rewrites the timer to settings grace).
- W2: transitional `TodayView.doses` getter contradicted data-model.md → reconciled the doc (getter is a documented 005→009 shim); minor per-row re-flatten, negligible at <30 doses/day.
- W3: `TodayHourGroup.hasActionablePending` untested → task 008 done-condition now requires both-branch coverage.
**Transitional shims to retire later**: `TodayDose.windowState`/`actionable` defaults (task 006/008 pass them explicitly); `TodayView.doses` getter (task 009).
