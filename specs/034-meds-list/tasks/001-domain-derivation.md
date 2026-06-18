# Task 001: Domain activity + course-progress derivation

**Agent**: architect
**Files**: `lib/features/meds/domain/entities/medication_activity_status.dart` (new), `lib/features/meds/domain/entities/course_phase.dart` (new), `lib/features/meds/domain/value_objects/course_progress.dart` (new), `lib/features/meds/domain/value_objects/medication_activity.dart` (new)
**Depends on**: None
**Blocks**: 002, 009
**Context docs**: `specs/034-meds-list/data-model.md` (derivation rules), `specs/034-meds-list/research.md` (Q3 placement)
**Review checkpoint**: No

**Description**:
Create the pure, `now`-injected domain derivation that computes a medication's `Active`/`Completed` status and a course's cycle-day progress. This is the correctness heart of the feature — all date math lives here, exactly once. No Flutter, no drift, no `DateTime.now()` (the instant is a parameter). Leaf enums go in `entities/` (siblings of `medication_form.dart`); the composite value object + derivation functions go in `value_objects/`.

**Change details**:
- `entities/medication_activity_status.dart`: `enum MedicationActivityStatus { active, completed }` with a library/dartdoc comment.
- `entities/course_phase.dart`: `enum CoursePhase { activeWindow, paused }` with dartdoc.
- `value_objects/course_progress.dart`:
  - `@freezed class CourseProgress` with `int currentDay`, `int totalDays`, `CoursePhase phase` (+ `part 'course_progress.freezed.dart';`).
  - `static CourseProgress resolve({required CourseType course, required DateTime now})` implementing the data-model.md day-math: date-only (local) differencing; non-cyclic = single `activeWindow` with `currentDay = min(daysSinceStart+1, durationDays)`; cyclic uses `cycleLen = durationDays + pauseDays`, `posInCycle = daysSinceStart % cycleLen` → `activeWindow` (`currentDay = posInCycle+1`) or `paused` (`currentDay = durationDays`). Clamp `daysSinceStart < 0` to `currentDay = 1`, `activeWindow`.
- `value_objects/medication_activity.dart`:
  - top-level `MedicationActivityStatus resolveMedicationActivity(Medication medication, DateTime now)`: `continuous` → `active`; `course` with `pauseDays > 0` → `active`; `course` with `pauseDays == 0` → `active` while `localDate(now) ≤ localDate(startDate) + (durationDays-1)` else `completed`. Exhaustive `switch` over `MedicationType` (no `default`).
- Run `dart run build_runner build --delete-conflicting-outputs`; commit generated `*.freezed.dart`.

**Done when**:
- [x] All four files exist with the public symbols above; exhaustive switches, no `DateTime.now()`, no `!`.
- [x] `dart run build_runner build` regenerates `course_progress.freezed.dart` (committed).
- [x] `dart analyze` passes on changed files.

**Spec criteria addressed**: AC-4, AC-5

## Completion Notes
**Status**: Complete
**Completed**: 2026-06-18
**Files changed**: medication_activity_status.dart, course_phase.dart, course_progress.dart (+ .freezed.dart), medication_activity.dart (all new)
**Contract**: Expects 3/3 verified | Produces 4/4 verified
**Notes**: `_localDate` helper duplicated in course_progress.dart + medication_activity.dart (2 occurrences — DRY allows, extract on 3rd). Completion boundary computed from raw `daysSinceStart` in `resolveMedicationActivity` (not from clamped `CourseProgress.currentDay`, which can't distinguish last-active-day from completed). build_runner's `--delete-conflicting-outputs` is a no-op flag in this version (ignored harmlessly). Code reviewed inline: APPROVE.

## Contracts

### Expects
- `lib/features/meds/domain/entities/medication_type.dart` exports `sealed class MedicationType`, `ContinuousType`, `CourseType` with `startDate`, `durationDays`, `pauseDays`.
- `lib/features/meds/domain/entities/medication.dart` exports `class Medication` with `MedicationType type`.
- `package:clock`, `package:freezed_annotation` available (per `pubspec.yaml`).

### Produces
- `medication_activity_status.dart` exports `enum MedicationActivityStatus { active, completed }`.
- `course_phase.dart` exports `enum CoursePhase { activeWindow, paused }`.
- `course_progress.dart` exports `class CourseProgress` (fields `currentDay`, `totalDays`, `phase`) and `static CourseProgress resolve({required CourseType course, required DateTime now})`.
- `medication_activity.dart` exports `MedicationActivityStatus resolveMedicationActivity(Medication medication, DateTime now)`.
