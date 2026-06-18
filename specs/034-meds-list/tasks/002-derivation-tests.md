# Task 002: Derivation unit tests (fixed Clock)

**Agent**: qa-engineer
**Files**: `test/features/meds/domain/value_objects/course_progress_test.dart` (new), `test/features/meds/domain/value_objects/medication_activity_test.dart` (new)
**Depends on**: 001
**Blocks**: None
**Context docs**: `specs/034-meds-list/data-model.md` (day-math rules)
**Review checkpoint**: No

**Description**:
Exhaustively unit-test the derivation against fixed instants. These tests lock down the inclusive end-date boundary, the cyclic modulo, and the pause gap — the subtle math the rest of the feature trusts. Pass instants directly as literals (the functions take `now`), and additionally wrap at least one case in `withClock(Clock.fixed(...))` to prove ambient-clock callers behave.

**Change details**:
- `course_progress_test.dart` — `CourseProgress.resolve` cases:
  - non-cyclic active mid-course (e.g. start day 0, dur 7, now day 2 → `currentDay 3`, `totalDays 7`, `activeWindow`).
  - non-cyclic on the last active day (now day 6 of dur 7 → `currentDay 7`, `activeWindow`).
  - non-cyclic just past end (now day 7 of dur 7 → clamped `currentDay 7`).
  - cyclic in active window (dur 30, pause 7, now day 7 → `currentDay 8`, `activeWindow`).
  - cyclic in pause gap (dur 10, pause 20, now day 31 → `phase paused`, `currentDay 10`).
  - cyclic wrap into a second cycle (now day = cycleLen → `currentDay 1`, `activeWindow`).
  - future-dated start (now before start → `currentDay 1`, `activeWindow`).
  - intraday: two `now` times on the same local calendar day yield the same `currentDay` (no boundary drift).
- `medication_activity_test.dart` — `resolveMedicationActivity` cases: continuous → `active`; cyclic course → `active`; non-cyclic active (on end day) → `active`; non-cyclic completed (day after end) → `completed`; inclusive boundary asserted precisely. At least one case wrapped in `withClock(Clock.fixed(...))`.

**Done when**:
- [x] Both test files exist; all listed scenarios present with explicit expected values.
- [x] `flutter test test/features/meds/domain/value_objects/` is green.
- [x] `dart analyze` passes on changed files.

**Spec criteria addressed**: AC-6

## Completion Notes
**Status**: Complete
**Completed**: 2026-06-18
**Files changed**: course_progress_test.dart, medication_activity_test.dart (new) — 15 tests
**Contract**: Expects 1/1 verified | Produces 2/2 verified
**Notes**: Tests **caught a real production DST off-by-one** in Task 001's `_localDate` (local-midnight `.difference().inDays` truncates `N→N-1` across a spring-forward span). Self-repair (attempt 1) fixed both derivation files to anchor calendar dates to `DateTime.utc(...)` and added a DST-guard regression test. All 22 meds-domain tests pass; analyze clean. Logged to MEMORY (DST day-count gotcha). The qa agent initially avoided DST dates in fixtures — flagged as a process lesson (don't steer tests away from a boundary the production code gets wrong).

## Contracts

### Expects
- Task 001 `Produces` (the four derivation symbols).

### Produces
- `test/features/meds/domain/value_objects/course_progress_test.dart` calls `CourseProgress.resolve(` with fixed instants and asserts `currentDay`/`totalDays`/`phase`.
- `test/features/meds/domain/value_objects/medication_activity_test.dart` calls `resolveMedicationActivity(` and asserts `MedicationActivityStatus.active`/`.completed`, including a `withClock(Clock.fixed(` case.
