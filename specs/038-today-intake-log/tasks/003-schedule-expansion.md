# Task 003: Schedule expansion — DueDose + expandDueDoses

**Agent**: architect
**Files**: `lib/features/meds/domain/value_objects/due_dose.dart`, `lib/features/meds/domain/value_objects/local_calendar_date.dart`
**Depends on**: None
**Blocks**: 013
**Context docs**: specs/038-today-intake-log/data-model.md
**Review checkpoint**: No

**Description**:
Create the pure, clock-free function that expands medications into the doses due on a given day, plus a shared DST-safe local-calendar-date helper. Reuses the existing `CourseProgress.resolve` and `resolveMedicationActivity` derivations rather than re-deriving day math. This is the algorithmic heart of the Today screen; it must handle continuous, non-cyclic course, cyclic (pause-gap) course, future-start, and completed cases correctly.

**Change details**:
- `local_calendar_date.dart`: expose `DateTime localCalendarDate(DateTime d)` implementing the existing `_localDate` idiom (`toLocal()` → `DateTime.utc(y, m, d)`) with dartdoc explaining the DST rationale. (Existing private copies in `course_progress.dart`/`medication_activity.dart` are left untouched — minimal change.)
- `due_dose.dart`:
  - `class DueDose { final Medication medication; final TimeSlot slot; final Dosage? effectiveDose; final DateTime scheduledAt; ... }` (immutable).
  - `List<DueDose> expandDueDoses({required List<Medication> meds, required DateTime now})`:
    - Continuous: due when `localCalendarDate(now) >= localCalendarDate(startDate)`.
    - Course: due only when `localCalendarDate(now) >= localCalendarDate(startDate)` AND `resolveMedicationActivity(med, now) == active` AND `CourseProgress.resolve(course: c, now: now).phase == CoursePhase.activeWindow`.
    - One `DueDose` per `slot` in `schedule.slots`; `effectiveDose = slot.doseOverride ?? medication.dosePerIntake`; `scheduledAt = DateTime(now.year, now.month, now.day, slot.minuteOfDay ~/ 60, slot.minuteOfDay % 60).toUtc()`.
    - Sort ascending by `slot.minuteOfDay`, ties by `medication.name` (case-insensitive), then `slot.id.value`.
- Add unit tests covering AC-1..4 (continuous incl. future start; non-cyclic course window incl. before-start/completed; cyclic active vs paused; sort + effectiveDose; a DST-boundary day count). Use `withClock`/explicit `now`.

**Contracts**:

### Expects
- `medication.dart`, `medication_type.dart`, `time_slot.dart`, `dosage.dart` exist; `CourseProgress.resolve({course, now})` and `resolveMedicationActivity(med, now)` exist; `CoursePhase.activeWindow` exists.

### Produces
- `due_dose.dart` exports `DueDose` (with `medication, slot, effectiveDose, scheduledAt`) and `List<DueDose> expandDueDoses({required List<Medication> meds, required DateTime now})`.
- `local_calendar_date.dart` exports `DateTime localCalendarDate(DateTime d)`.
- Neither file imports `package:flutter` or `package:drift`.

**Done when**:
- [ ] `expandDueDoses` returns correct doses for continuous / non-cyclic course / cyclic course / future-start / completed cases (unit-tested).
- [ ] Output is sorted by `minuteOfDay` with documented tiebreaks.
- [ ] No Flutter/drift import.
- [ ] `dart analyze` + scoped `flutter test test/features/meds/domain/` pass.

**Spec criteria addressed**: AC-1, AC-2, AC-3, AC-4

## Completion Notes
**Status**: Complete
**Completed**: 2026-07-02
**Files changed**: `value_objects/due_dose.dart`, `value_objects/local_calendar_date.dart`, `test/features/meds/domain/value_objects/due_dose_test.dart`
**Contract**: Expects [ok] | Produces [3/3] — `DueDose`, `expandDueDoses`, `localCalendarDate`; 0 forbidden imports.
**Notes**: Reused `CourseProgress.resolve` + `resolveMedicationActivity` (no re-derivation); exhaustive switch over sealed `MedicationType` via type promotion (no `as` cast). 21/21 unit tests pass incl. DST-boundary + cyclic pause-gap. First agent launch no-op'd (0 tool uses); re-launched successfully. `dart analyze` clean project-wide.
