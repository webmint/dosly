/// Typed fixture data and DB assertion helper for the on-device medication
/// integration-test suite.
///
/// Exports:
/// - [MedFixture] — immutable input model describing one test medication.
/// - [medFixtures] — the 8 canonical fixtures covering every combination of
///   form, dose mode, stock, course/continuous, and time-slot count.
/// - [expectPersisted] — queries the real [AppDatabase] and asserts that the
///   `medications` row and its `time_slots` rows exactly match the fixture.
library;

import 'package:dosly/core/database/database.dart';
import 'package:dosly/core/database/tables/medications_table.dart';
import 'package:dosly/features/meds/domain/entities/schedule_frequency.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// MedFixture — input model
// ---------------------------------------------------------------------------

/// Immutable description of a single medication to be entered via the UI and
/// subsequently verified in the database.
///
/// The fields are split into three concerns:
/// 1. Identity / form (`name`, `formKey`, `isCourse`).
/// 2. Dose input mode (`doseAmount`, `doseUnitName`, `isQuantityDose`,
///    `doseUnitIndex`) — which controls how the driver interacts with the
///    add-medication modal.
/// 3. Expected persisted state (`durationDays`, `pauseDays`, `stockRemaining`,
///    `stockTotal`, `stockWarn`, `times`) — used by [expectPersisted] to
///    assert the rows written to the database.
class MedFixture {
  /// Creates an immutable medication fixture.
  const MedFixture({
    required this.name,
    required this.formKey,
    required this.isCourse,
    required this.durationDays,
    required this.pauseDays,
    required this.doseAmount,
    required this.doseUnitName,
    required this.isQuantityDose,
    required this.doseUnitIndex,
    required this.stockRemaining,
    required this.stockTotal,
    required this.stockWarn,
    required this.times,
  });

  /// Display name entered into the medication name field.
  final String name;

  /// The [MedicationForm] enum name (e.g. `'tablet'`, `'syrup'`).
  ///
  /// Used by the UI driver to select the correct form chip and by
  /// [expectPersisted] to assert `MedicationRow.form.name`.
  final String formKey;

  /// Whether this medication is a bounded course (`true`) or continuous
  /// (`false`).
  ///
  /// Determines which type toggle the driver taps and which
  /// [MedicationTypeKind] is expected in the persisted row.
  final bool isCourse;

  /// Course duration in days; `null` for continuous medications.
  final int? durationDays;

  /// Pause length in days for a cyclic course (`0` = single bounded course);
  /// `null` for continuous medications.
  final int? pauseDays;

  /// The numeric dose to enter; `null` when this form has no dose field
  /// (inhaler, cream, sachet).
  final double? doseAmount;

  /// The expected [DoseUnit] name stored in the database; `null` when there is
  /// no dose.
  ///
  /// For quantity forms (tablet/capsule) this equals [formKey] (the unit is the
  /// same as the form). For liquid forms it is determined by [doseUnitIndex].
  final String? doseUnitName;

  /// `true` for quantity forms (tablet / capsule) that use a stepper widget;
  /// `false` for liquid forms (syrup / drops / injection) that use a text field
  /// plus a unit dropdown.
  ///
  /// Governs which input interaction the UI driver performs.
  final bool isQuantityDose;

  /// Zero-based index into the unit dropdown for liquid dose forms; `null` for
  /// quantity forms and no-dose forms.
  ///
  /// - syrup: `[ml]` → index 0 = ml
  /// - drops: `[drops, ml]` → index 0 = drops
  /// - injection: `[ml, mg, units]` → index 1 = mg
  final int? doseUnitIndex;

  /// Remaining pack inventory; `null` when stock is not tracked.
  final int? stockRemaining;

  /// Total pack inventory; `null` when stock is not tracked.
  final int? stockTotal;

  /// Low-stock warning threshold; `null` when stock is not tracked.
  final int? stockWarn;

  /// Ordered list of intake times.
  ///
  /// Each record exposes `hour` and `minute`. The driver taps these times in
  /// the time-picker, and [expectPersisted] converts them to `minuteOfDay`
  /// values (`hour * 60 + minute`) for the assertion.
  final List<({int hour, int minute})> times;
}

// ---------------------------------------------------------------------------
// medFixtures — the 8 canonical fixtures
// ---------------------------------------------------------------------------

/// The 8 representative medication fixtures covering every combination of
/// form, dose mode, stock tracking, course/continuous, and time-slot count.
///
/// They must be exercised in order (each integration test starts with a clean
/// database) and their indices are stable — downstream drivers index into this
/// list by position.
const List<MedFixture> medFixtures = [
  // 1. Tablet — continuous, quantity dose, stock tracked, 2 slots.
  MedFixture(
    name: 'ITTablet',
    formKey: 'tablet',
    isCourse: false,
    durationDays: null,
    pauseDays: null,
    doseAmount: 1.5,
    doseUnitName: 'tablet',
    isQuantityDose: true,
    doseUnitIndex: null,
    stockRemaining: 20,
    stockTotal: 30,
    stockWarn: 5,
    times: [
      (hour: 8, minute: 0), // 480 min
      (hour: 20, minute: 0), // 1200 min
    ],
  ),

  // 2. Capsule — course (dur 10, pause 2), quantity dose, stock tracked, 1 slot.
  MedFixture(
    name: 'ITCapsule',
    formKey: 'capsule',
    isCourse: true,
    durationDays: 10,
    pauseDays: 2,
    doseAmount: 2.0,
    doseUnitName: 'capsule',
    isQuantityDose: true,
    doseUnitIndex: null,
    stockRemaining: 14,
    stockTotal: 14,
    stockWarn: 3,
    times: [
      (hour: 9, minute: 0), // 540 min
    ],
  ),

  // 3. Syrup — continuous, liquid dose (5 ml, index 0), no stock, 1 slot.
  MedFixture(
    name: 'ITSyrup',
    formKey: 'syrup',
    isCourse: false,
    durationDays: null,
    pauseDays: null,
    doseAmount: 5.0,
    doseUnitName: 'ml',
    isQuantityDose: false,
    doseUnitIndex: 0,
    stockRemaining: null,
    stockTotal: null,
    stockWarn: null,
    times: [
      (hour: 13, minute: 0), // 780 min
    ],
  ),

  // 4. Drops — course (dur 7, pause 0), liquid dose (2 drops, index 0), no stock, 1 slot.
  MedFixture(
    name: 'ITDrops',
    formKey: 'drops',
    isCourse: true,
    durationDays: 7,
    pauseDays: 0,
    doseAmount: 2.0,
    doseUnitName: 'drops',
    isQuantityDose: false,
    doseUnitIndex: 0,
    stockRemaining: null,
    stockTotal: null,
    stockWarn: null,
    times: [
      (hour: 22, minute: 0), // 1320 min
    ],
  ),

  // 5. Injection — course (dur 14, pause 0), liquid dose (10 mg, index 1), no stock, 1 slot.
  MedFixture(
    name: 'ITInjection',
    formKey: 'injection',
    isCourse: true,
    durationDays: 14,
    pauseDays: 0,
    doseAmount: 10.0,
    doseUnitName: 'mg',
    isQuantityDose: false,
    doseUnitIndex: 1,
    stockRemaining: null,
    stockTotal: null,
    stockWarn: null,
    times: [
      (hour: 7, minute: 30), // 450 min
    ],
  ),

  // 6. Inhaler — continuous, no dose, no stock, 2 slots.
  MedFixture(
    name: 'ITInhaler',
    formKey: 'inhaler',
    isCourse: false,
    durationDays: null,
    pauseDays: null,
    doseAmount: null,
    doseUnitName: null,
    isQuantityDose: false,
    doseUnitIndex: null,
    stockRemaining: null,
    stockTotal: null,
    stockWarn: null,
    times: [
      (hour: 8, minute: 0), // 480 min
      (hour: 23, minute: 0), // 1380 min
    ],
  ),

  // 7. Cream — continuous, no dose, no stock, 1 slot.
  MedFixture(
    name: 'ITCream',
    formKey: 'cream',
    isCourse: false,
    durationDays: null,
    pauseDays: null,
    doseAmount: null,
    doseUnitName: null,
    isQuantityDose: false,
    doseUnitIndex: null,
    stockRemaining: null,
    stockTotal: null,
    stockWarn: null,
    times: [
      (hour: 21, minute: 0), // 1260 min
    ],
  ),

  // 8. Sachet — course (dur 5, pause 0), no dose, no stock, 1 slot.
  MedFixture(
    name: 'ITSachet',
    formKey: 'sachet',
    isCourse: true,
    durationDays: 5,
    pauseDays: 0,
    doseAmount: null,
    doseUnitName: null,
    isQuantityDose: false,
    doseUnitIndex: null,
    stockRemaining: null,
    stockTotal: null,
    stockWarn: null,
    times: [
      (hour: 12, minute: 0), // 720 min
    ],
  ),
];

// ---------------------------------------------------------------------------
// expectPersisted — DB assertion helper
// ---------------------------------------------------------------------------

/// Queries [db] and asserts that the single persisted `medications` row and
/// its `time_slots` rows exactly match the values encoded in [f].
///
/// Precondition: the database must contain exactly one medication (the one
/// that was just added via the UI). Call this immediately after the add
/// operation completes and the modal is dismissed.
///
/// Assertions performed:
/// - Exactly one `medications` row exists.
/// - `name`, `form`, `typeKind`, `durationDays`, `pauseDays`, `doseAmount`,
///   `doseUnit`, `stockRemaining`, `stockTotal`, `stockWarnAt`, `frequency`
///   all match the fixture values.
/// - `startDate` equals today's UTC calendar date (year/month/day, time 00:00).
/// - `createdAt` is within a reasonable window around now.
/// - `time_slots` count equals `f.times.length`.
/// - The set of persisted `minuteOfDay` values equals the set derived from
///   `f.times` (`hour * 60 + minute`).
/// - Every slot's `medicationId` foreign key matches `med.id`.
Future<void> expectPersisted(AppDatabase db, MedFixture f) async {
  // ------------------------------------------------------------------
  // medications row
  // ------------------------------------------------------------------
  final meds = await db.select(db.medications).get();
  expect(meds.length, 1, reason: '${f.name}: expected exactly 1 medication row');

  final med = meds.single;

  expect(
    med.name,
    f.name,
    reason: '${f.name}: name mismatch',
  );

  expect(
    med.form.name,
    f.formKey,
    reason: '${f.name}: form mismatch (expected ${f.formKey}, got ${med.form.name})',
  );

  final expectedTypeKind =
      f.isCourse ? MedicationTypeKind.course : MedicationTypeKind.continuous;
  expect(
    med.typeKind,
    expectedTypeKind,
    reason: '${f.name}: typeKind mismatch',
  );

  expect(
    med.durationDays,
    f.durationDays,
    reason: '${f.name}: durationDays mismatch',
  );

  expect(
    med.pauseDays,
    f.pauseDays,
    reason: '${f.name}: pauseDays mismatch',
  );

  expect(
    med.doseAmount,
    f.doseAmount,
    reason: '${f.name}: doseAmount mismatch',
  );

  expect(
    med.doseUnit?.name,
    f.doseUnitName,
    reason: '${f.name}: doseUnit mismatch '
        '(expected ${f.doseUnitName}, got ${med.doseUnit?.name})',
  );

  expect(
    med.stockRemaining,
    f.stockRemaining,
    reason: '${f.name}: stockRemaining mismatch',
  );

  expect(
    med.stockTotal,
    f.stockTotal,
    reason: '${f.name}: stockTotal mismatch',
  );

  expect(
    med.stockWarnAt,
    f.stockWarn,
    reason: '${f.name}: stockWarnAt mismatch',
  );

  expect(
    med.frequency,
    ScheduleFrequency.daily,
    reason: '${f.name}: frequency must be daily',
  );

  // ------------------------------------------------------------------
  // Date / time assertions
  // ------------------------------------------------------------------

  // Modal stores start date as UTC-midnight of the device's LOCAL calendar date.
  // Drift dateTime() reads back local-flagged, so compare by moment, not ==.
  final localNow = DateTime.now();
  final startDateUtc = DateTime.utc(localNow.year, localNow.month, localNow.day);
  expect(
    med.startDate.isAtSameMomentAs(startDateUtc),
    isTrue,
    reason: '${f.name}: startDate must be UTC-midnight of today\'s local date '
        '(${startDateUtc.toIso8601String()}), got ${med.startDate.toIso8601String()}',
  );

  final nowUtc = DateTime.now().toUtc();
  expect(
    med.createdAt.isAfter(startDateUtc.subtract(const Duration(days: 1))),
    isTrue,
    reason: '${f.name}: createdAt is suspiciously old',
  );
  expect(
    med.createdAt.isBefore(nowUtc.add(const Duration(minutes: 1))),
    isTrue,
    reason: '${f.name}: createdAt is in the future',
  );

  // ------------------------------------------------------------------
  // time_slots rows
  // ------------------------------------------------------------------
  final slots = await db.select(db.timeSlots).get();

  expect(
    slots.length,
    f.times.length,
    reason: '${f.name}: expected ${f.times.length} time_slot row(s), '
        'got ${slots.length}',
  );

  final expectedMinutes =
      f.times.map((t) => t.hour * 60 + t.minute).toSet();
  final actualMinutes = slots.map((s) => s.minuteOfDay).toSet();

  expect(
    actualMinutes,
    expectedMinutes,
    reason: '${f.name}: minuteOfDay set mismatch '
        '(expected $expectedMinutes, got $actualMinutes)',
  );

  for (final slot in slots) {
    expect(
      slot.medicationId,
      med.id,
      reason: '${f.name}: slot.medicationId does not match med.id',
    );
  }
}
