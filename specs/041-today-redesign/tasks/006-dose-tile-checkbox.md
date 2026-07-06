# Task 006: Restyle `today_dose_tile` — checkbox, skip icon, chips, low-stock

**Agent**: mobile-engineer
**Review checkpoint**: Yes
**Files**: `lib/features/meds/presentation/widgets/today_dose_tile.dart`, `test/features/meds/presentation/widgets/today_dose_tile_test.dart`, `lib/features/meds/presentation/screens/today_screen.dart` (transitional tile-construction site only — pass `now:`)
**Depends on**: 005, 003, 001
**Blocks**: 008, 009
**Context docs**: None

## Description

Replace the Take/Skip/Undo button cluster with the M3 checkbox interaction model plus a trailing secondary skip icon, and add the status chip and inline low-stock warning. Keep the widget dumb (callbacks supplied by the caller) and keep the same `onTaken`/`onSkip`/`onUndo` callback constructor so the screen is unaffected until task 009. Keep the exhaustive `switch` over `IntakeStatus`.

## Change details

- In `lib/features/meds/presentation/widgets/today_dose_tile.dart`:
  - **Trailing area** dispatched on `dose.status` (exhaustive, no `default:`):
    - `pending` → a `Checkbox` (unchecked, keyed `todayCheckbox`) whose `onChanged` is `dose.actionable ? (_) => onTaken() : null` (disabled when not actionable), preceded by a skip `IconButton` (Lucide `skipForward`, keyed `todaySkipIcon`, tooltip `l10n.todaySkip`, ≥48 dp) shown ONLY when `dose.actionable`.
    - `taken` → a checked `Checkbox` (keyed `todayCheckbox`) whose `onChanged` is `dose.undoable ? (_) => onUndo() : null` (locked when past grace); the name renders line-through/muted.
    - `skipped` → an unchecked disabled `Checkbox` + a `todayStatusSkipped` label + an `Undo` `TextButton` (keyed `todayUndo`) shown only when `dose.undoable`.
    - `missed` → a `todayStatusMissed` error-toned label, no checkbox/actions.
  - **Body**: keep name + "HH:mm · dose" subtitle; add a `MedTypeChip(medication: dose.dose.medication, progress: CourseProgress.resolve(course: <course>, now: <now>))` for course meds / continuous chip (pass `now` in — add a `now` field to the tile, supplied by the screen, or resolve progress in the screen and pass it; prefer passing `now` since the tile already renders time). Append an inline low-stock segment ONLY when `isLowStock(dose.dose.medication.stock)`: `formatStock(stock, l10n)` bold `cs.error` (reuse `medication_display.dart`).
  - Use `surfaceContainerHighest`/container roles for any tinted surface — never `surfaceVariant`.
  - Add a `now` (`DateTime`) constructor field if course-progress resolution needs it; keep all other fields.
- In `test/features/meds/presentation/widgets/today_dose_tile_test.dart`:
  - Rewrite for: pending-actionable renders enabled `todayCheckbox` + `todaySkipIcon`; pending-not-actionable renders disabled checkbox, no skip icon; taken renders checked checkbox (enabled↔`undoable`), line-through name; skipped renders `todayStatusSkipped` + `todayUndo` when undoable; missed renders `todayStatusMissed`, no actions; continuous vs course chip; low-stock error span present only when low.

## Contracts

### Expects
- `TodayDose` exposes `windowState`, `actionable`, `status`, `undoable`, `dose.medication` (with `type`, `form`, `stock`, `dosePerIntake`) — task 005.
- `MedTypeChip` exists (task 003); `formatStock`/`isLowStock` exist in `medication_display.dart`; l10n keys `todayStatusSkipped/Missed`, `todaySkip`, `todayUndo` exist (task 001 + existing).

### Produces
- `today_dose_tile.dart` renders a `Checkbox` keyed `todayCheckbox` and a skip `IconButton` keyed `todaySkipIcon`; keeps `todayUndo` for skipped; uses `MedTypeChip`; renders low-stock via `isLowStock`/`formatStock`.
- The `_Actions`/trailing `switch` over `IntakeStatus` stays exhaustive with no `default:`.
- Constructor keeps `onTaken`, `onSkip`, `onUndo` callbacks.

## Done when
- [x] Each `IntakeStatus` renders per the matrix; checkbox enable/disable follows `actionable`/`undoable`; skip icon only for pending-actionable.
- [x] Continuous/Day-N/M chip and low-stock (only when low, error-toned) render.
- [x] No `surfaceVariant` usage; tap targets ≥48 dp.
- [x] `flutter test test/features/meds/presentation/widgets/today_dose_tile_test.dart` is green.
- [x] `dart analyze` passes on changed files.

**Spec criteria addressed**: AC-6, AC-7, AC-11, AC-12, AC-13

## Completion Notes

**Status**: Complete
**Completed**: 2026-07-05
**Files changed**: `today_dose_tile.dart` (restructure), `today_dose_tile_test.dart` (rewrite, 14 tests), `today_screen.dart` (`now: now` one-liner)
**Contract**: Expects [3/3 verified] | Produces [3/3 verified — `todayCheckbox`/`todaySkipIcon` keys, `todayUndo` for skipped, `MedTypeChip`, low-stock; exhaustive switch; callbacks unchanged]
**Notes**: `_Actions` switch — pending: skip `IconButton`(≥48dp, only if actionable)+`Checkbox`(onChanged actionable?take:null); taken: checked `Checkbox`(onChanged undoable?undo:null)+line-through name; skipped: `_SkippedActions` (disabled checkbox + label + `todayUndo` when undoable); missed: error label. `MedTypeChip` progress via `is CourseType` promotion. Low-stock bold `cs.error` only when `isLowStock`. Tile dimmed `Opacity 0.55` when pending/future/!actionable. Tile test 14/14; analyze clean project-wide.
**Code review**: APPROVE WITH WARNINGS. Warning: dimmed-tile `Opacity(0.55)` branch untested → coverage added to task 010 scope. Info: `0.55`/skip-gap spacing are design-auditor follow-ups.
**Expected transitional regression**: `today_screen_test.dart` 7 failures (retired `todayTake`/`todaySkip` keys) — owned by task 009; full-green gate is task 010.
