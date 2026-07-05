# Task 001: Add the pure `findAutoMissDoses` derivation

**Agent**: architect
**Review checkpoint**: No
**Files**: `lib/features/meds/domain/value_objects/missed_intake_reconciliation.dart` (new), `test/features/meds/domain/value_objects/missed_intake_reconciliation_test.dart` (new)
**Depends on**: None
**Blocks**: 004
**Context docs**: None

## Description

Create the pure, clock-free derivation that computes which of today's due doses must be auto-missed as of `now`. It is the algorithmic heart of the engine and mirrors the existing `expandDueDoses` / `buildTodayView` pure-function pattern (no Flutter/drift/data imports). It reuses `expandDueDoses` for the single-day expansion and `localCalendarDate` for occurrence matching, and reads the intake window via the settings `IntakeWindow` value object (a permitted domain→domain import).

An occurrence is eligible when ALL hold: (a) it is due today (from `expandDueDoses`), (b) its window has strictly closed (`now > scheduledAt + window.minutes`, compared in UTC), and (c) it has **no** matching stored intake — matched by the occurrence key `(medicationId, slotId, localCalendarDate(scheduledAt))`, exactly as `buildTodayView` matches (not raw-instant equality). Return the eligible subset as `List<DueDose>` (no new type).

## Change details

- In `lib/features/meds/domain/value_objects/missed_intake_reconciliation.dart` (new):
  - `library;` dartdoc explaining purity + single-day scope + the three eligibility conditions.
  - Imports: `../entities/intake.dart`, `../entities/medication.dart`, `due_dose.dart` (for `DueDose` + `expandDueDoses`), `local_calendar_date.dart`, and `../../../settings/domain/value_objects/intake_window.dart`.
  - `List<DueDose> findAutoMissDoses({required List<Medication> meds, required List<Intake> intakes, required IntakeWindow window, required DateTime now})`:
    - `final due = expandDueDoses(meds: meds, now: now);`
    - Build a `Set<(String, String, DateTime)>` of present occurrence keys from `intakes`: `(i.medicationId.value, i.slotId.value, localCalendarDate(i.scheduledAt))`.
    - `final nowUtc = now.toUtc();`
    - Return the `due` doses where the occurrence key is NOT in the present-set AND `nowUtc.isAfter(d.scheduledAt.toUtc().add(Duration(minutes: window.minutes)))` (strict — boundary not yet missed).
  - dartdoc on the public function.
- In the test file (new): table-driven unit tests using fixed `now`/`window` (no `DateTime.now()`), covering: past-window pending dose eligible; exactly-at-boundary NOT eligible; strictly-past eligible; future-later-today NOT eligible; occurrence with an existing `taken`/`skipped`/`missed` row excluded; no-meds → empty; a DST-adjacent day (reuse the `localCalendarDate` idiom) with no off-by-one.

## Contracts

### Expects
- `lib/features/meds/domain/value_objects/due_dose.dart` exports `expandDueDoses({required List<Medication> meds, required DateTime now})` and class `DueDose` with fields `medication`, `slot`, `scheduledAt`.
- `lib/features/meds/domain/value_objects/local_calendar_date.dart` exports `localCalendarDate(DateTime)`.
- `lib/features/settings/domain/value_objects/intake_window.dart` exports `IntakeWindow` with an `int minutes` field.

### Produces
- `missed_intake_reconciliation.dart` exports `findAutoMissDoses` with named params `meds`, `intakes`, `window`, `now` returning `List<DueDose>`.
- `findAutoMissDoses` calls `expandDueDoses` and `localCalendarDate` (reuses existing day/occurrence math, no re-derivation).
- `missed_intake_reconciliation.dart` imports `intake_window.dart` and contains no `package:flutter`, `package:drift`, or `data/` import.

## Done when
- [x] `findAutoMissDoses` returns exactly the past-window, unmatched, due-today subset (verified by the tests).
- [x] Boundary is strict: `now == scheduledAt + window.minutes` yields NOT eligible.
- [x] File imports no Flutter/drift/data — pure Dart.
- [x] `flutter test test/features/meds/domain/value_objects/missed_intake_reconciliation_test.dart` is green.
- [x] `dart analyze` passes on changed files.

**Spec criteria addressed**: AC-1, AC-2, AC-3, AC-4

## Completion Notes

**Status**: Complete
**Completed**: 2026-07-04
**Files changed**: `lib/features/meds/domain/value_objects/missed_intake_reconciliation.dart` (new), `test/features/meds/domain/value_objects/missed_intake_reconciliation_test.dart` (new)
**Contract**: Expects [3/3 verified] | Produces [3/3 verified]
**Notes**: Pure total function returning `List<DueDose>` (no new type). Reuses `expandDueDoses` + `localCalendarDate`; occurrence key `(medId, slotId, localCalendarDate(scheduledAt))` matches `buildTodayView`. Strict UTC boundary via `isAfter`. 12 clock-injected tests (boundary, taken/skipped/missed exclusion, future, no-meds, DST). Code review: APPROVE with warnings — one misleading mixed-scenario test comment (the `mid` slot sat exactly on its window boundary so the strict check, not the `taken` row, excluded it) was fixed by pushing `now` to 13:00 so the stored intake is genuinely the exclusion reason (+ an explicit `isNot(contains('mid'))` assertion). Info-only follow-up noted: `intake_status.dart`'s "missed not produced yet" comment should be updated once a write path lands (later task).
