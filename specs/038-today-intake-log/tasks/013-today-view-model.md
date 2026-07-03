# Task 013: Today view model (buildTodayView)

**Agent**: architect
**Files**: `lib/features/meds/presentation/view_models/today_view_model.dart`, `test/features/meds/presentation/view_models/today_view_model_test.dart`
**Depends on**: 002, 003
**Blocks**: 014, 015
**Context docs**: specs/038-today-intake-log/data-model.md
**Review checkpoint**: No

**Description**:
Pure, clock-injected view model that combines expanded due doses with stored intakes into the render-ready Today list, deriving each dose's status and its `undoable` grace flag. Mirrors `buildMedsListView` (pure, synchronous, takes explicit `now`). No Flutter/drift/data imports.

**Change details**:
- Define `class TodayDose { final DueDose dose; final IntakeStatus status; final DateTime? confirmedAt; final bool undoable; }` and `class TodayView { final List<TodayDose> doses; ... }` (a flag/getter to distinguish "no doses due").
- `TodayView buildTodayView({required List<Medication> meds, required List<Intake> intakes, required DateTime now})`:
  - `expandDueDoses(meds: meds, now: now)` → due doses (already time-sorted).
  - For each due dose, find a matching intake by `medicationId == dose.medication.id` AND `slotId == dose.slot.id` AND `localCalendarDate(intake.scheduledAt) == localCalendarDate(dose.scheduledAt)` (match by local date, NOT raw instant).
  - `status` = matched intake's status, else `IntakeStatus.pending`.
  - `undoable` = `status != pending && confirmedAt != null && now.difference(confirmedAt) <= kIntakeUndoGracePeriod`.
  - Preserve the expansion's time order.
- Unit tests: pending when no intake; taken/skipped when matched; `undoable` true within grace, false after (injected `now`); matching by local date across an intake stored earlier in the day; ordering preserved (AC-8); all doses present regardless of scheduled-vs-now time (AC-10).

**Contracts**:

### Expects
- `expandDueDoses`/`DueDose`/`localCalendarDate` (Task 003); `Intake`, `IntakeStatus`, `kIntakeUndoGracePeriod` (Task 002).

### Produces
- `today_view_model.dart` exports `TodayDose` (fields `dose, status, confirmedAt, undoable`), `TodayView`, and `TodayView buildTodayView({required List<Medication> meds, required List<Intake> intakes, required DateTime now})`.
- No Flutter/drift/data-layer import.

**Done when**:
- [ ] Status + `undoable` derivations correct (unit-tested, both grace branches).
- [ ] Matching keyed on local calendar date, not raw instant.
- [ ] Time ordering preserved; every due dose present.
- [ ] `dart analyze` + `flutter test test/features/meds/presentation/view_models/today_view_model_test.dart` pass.

**Spec criteria addressed**: AC-8, AC-10, AC-12, AC-13

## Completion Notes
**Status**: Complete
**Completed**: 2026-07-02
**Files changed**: `presentation/view_models/today_view_model.dart`, `test/features/meds/presentation/view_models/today_view_model_test.dart`
**Contract**: Expects [ok] | Produces [3/3] — `TodayDose`, `TodayView` (`isEmpty`), `buildTodayView`; 0 forbidden imports (pure).
**Notes**: Delegates to `expandDueDoses`; left-joins intakes by `(medicationId, slotId, localCalendarDate)` — not raw instant. `undoable` reuses UndoIntake's inclusive-boundary semantics + `!isNegative` guard (future confirmedAt never undoable). 11/11 tests pass (both grace branches, skipped, local-date match/non-match, ordering, AC-10 past/future, empty). `dart analyze` clean.
