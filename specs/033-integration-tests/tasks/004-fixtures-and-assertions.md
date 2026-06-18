# Task 004: Define the 8-variation fixtures + persisted-row assertions

**Agent**: qa-engineer
**Files**: `integration_test/support/medication_fixtures.dart`
**Depends on**: 001
**Blocks**: 005, 006, 007
**Context docs**: `specs/033-integration-tests/spec.md` (§3 variation matrix), `constitution.md` (§5.1 entity contract)
**Review checkpoint**: No

**Description**:
Create the typed `MedFixture` input model, the 8 representative fixtures from the spec matrix, and an `expectPersisted(db, fixture)` helper that queries the test `AppDatabase` and asserts the persisted `medications` row + `time_slots` rows match the fixture. Time-sensitive columns are asserted at the tolerance the plan specifies (date-granularity `startDate`, windowed `createdAt`); all other columns are asserted exactly.

**Change details**:
- In `integration_test/support/medication_fixtures.dart` (new):
  - Declare an immutable `MedFixture` with fields: `name` (String), `formKey` (String — `tablet`…`sachet`), `isCourse` (bool), `durationDays`/`pauseDays` (int?, course only), `doseAmount` (double?), `doseUnitName` (String?, `DoseUnit` name), `quantity` (double?, tablet/capsule), `stockRemaining`/`stockTotal`/`stockWarn` (int?), `times` (`List<({int hour, int minute})>`), plus the expected discriminators (`expectedTypeKind`, etc.) where they differ from inputs.
  - Declare `const List<MedFixture> medFixtures` with the 8 entries from spec §3 (ITTablet … ITSachet), covering all forms, continuous+course, cyclic+single course, stock present/absent, default+non-default dose unit, single+multiple times.
  - Declare `Future<void> expectPersisted(AppDatabase db, MedFixture f)`:
    - Query `db.select(db.medications).get()` → assert exactly 1 row; assert `name`, `form` (enum name == `formKey`), `typeKind`, `durationDays`, `pauseDays`, `doseAmount`, `doseUnit`, `stockRemaining`, `stockTotal`, `stockWarnAt`, `frequency == ScheduleFrequency.daily`.
    - Query `db.select(db.timeSlots).get()` → assert count == `f.times.length`, `minuteOfDay` set matches `{h*60+m}`, and every `medicationId` FK equals the medication row id.
    - For `startDate`: assert date-only equals expected (today UTC for continuous, fixture date for course). For `createdAt`: assert within a recent window (e.g. last 5 minutes, UTC).
  - Type-safe: no `!`, no `dynamic`, no unchecked `as`; use pattern matching / explicit null checks.

**Done when**:
- [x] `MedFixture` declared with the fields above
- [x] `medFixtures` contains exactly 8 entries matching spec §3
- [x] `expectPersisted(AppDatabase db, MedFixture f)` declared and asserts medications + time_slots columns
- [x] `dart analyze` passes

**Spec criteria addressed**: AC-5

## Contracts

### Expects
- `integration_test` dev dependency is present (Task 001 Produces)
- `lib/core/database/database.dart` exposes `AppDatabase` with `medications` and `timeSlots` tables and `MedicationRow`/`TimeSlotRow` data classes
- `lib/features/meds/domain/entities/schedule_frequency.dart` exports `ScheduleFrequency.daily`
- `lib/features/meds/domain/entities/dose_unit.dart` exports `DoseUnit` (names `tablet`, `capsule`, `ml`, `mg`, `drops`, …)

### Produces
- `medication_fixtures.dart` declares `class MedFixture`
- `medication_fixtures.dart` declares `const List<MedFixture> medFixtures` with 8 elements
- `medication_fixtures.dart` declares `expectPersisted(`

## Completion Notes

**Status**: Complete
**Completed**: 2026-06-18
**Files changed**: `integration_test/support/medication_fixtures.dart` (new)
**Contract**: Expects [4/4 verified] | Produces [3/3 verified]
**Notes**: `MedFixture` carries driver-input fields (formKey, isCourse, dur/pause, doseAmount, isQuantityDose, doseUnitIndex, stock, times) + expected `doseUnitName`. 8 fixtures match the §3 matrix (verified: minuteOfDay 480/1200, 540, 780, 1320, 450, 480/1380, 1260, 720). `expectPersisted` asserts all medications columns (incl. `startDate == todayUtc`, `createdAt` recent window) + time_slots count/minuteOfDay-set/FK. No `!`/`dynamic`/`as` (`?.name`, `meds.single`). analyze clean. Code review deferred to consolidated support-layer review after Task 005.
