/// Round-trip tests for the medication mapper.
///
/// Each test builds a domain [Medication] fixture, writes it to an in-memory
/// drift database via [MedicationLocalDataSource.insertMedication] (calling the
/// mapper internally), reads the raw [MedicationRow] + [TimeSlotRow]s back, and
/// calls [medicationFromRows] to reconstruct the aggregate. The reconstructed
/// value is then compared field-by-field against the original fixture.
///
/// Three fixture shapes are tested:
///   (a) tablet — Dosage + PackStock + ContinuousType, 2 time slots, notes set.
///   (b) syrup — Dosage, no stock, CourseType, 1 time slot, notes null.
///   (c) inhaler — no dose, no stock, ContinuousType, 1 time slot.
///
/// NOTE on DateTime round-trips: drift's [dateTime()] column stores a UTC epoch
/// millisecond timestamp but returns a *local* [DateTime] on read. As a result,
/// [DateTime.isUtc] is false after a round-trip even though the stored moment is
/// correct. Datetime assertions therefore use [DateTime.isAtSameMomentAs] to
/// compare the moment in time independently of the UTC flag, and also assert
/// that the local and UTC components still represent the same calendar instant.
library;

import 'package:dosly/core/database/database.dart';
import 'package:dosly/core/database/tables/medications_table.dart';
import 'package:dosly/features/meds/data/datasources/medication_local_data_source.dart';
import 'package:dosly/features/meds/data/mappers/medication_mapper.dart';
import 'package:dosly/features/meds/domain/entities/dosage.dart';
import 'package:dosly/features/meds/domain/entities/dose_unit.dart';
import 'package:dosly/features/meds/domain/entities/medication.dart';
import 'package:dosly/features/meds/domain/entities/medication_form.dart';
import 'package:dosly/features/meds/domain/entities/medication_type.dart';
import 'package:dosly/features/meds/domain/entities/pack_stock.dart';
import 'package:dosly/features/meds/domain/entities/schedule.dart';
import 'package:dosly/features/meds/domain/entities/schedule_frequency.dart';
import 'package:dosly/features/meds/domain/entities/time_slot.dart';
import 'package:dosly/features/meds/domain/value_objects/medication_id.dart';
import 'package:dosly/features/meds/domain/value_objects/time_slot_id.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

/// (a) Tablet: Dosage + PackStock + ContinuousType, 2 time slots, notes set.
final _tabletFixture = Medication(
  id: const MedicationId('med-tablet-001'),
  name: 'Aspirin',
  form: MedicationForm.tablet,
  type: MedicationType.continuous(startDate: DateTime.utc(2026, 1, 15)),
  schedule: const Schedule(
    frequency: ScheduleFrequency.daily,
    slots: [
      TimeSlot(
        id: TimeSlotId('slot-tablet-001'),
        minuteOfDay: 480, // 08:00
      ),
      TimeSlot(
        id: TimeSlotId('slot-tablet-002'),
        minuteOfDay: 1200, // 20:00
      ),
    ],
  ),
  dosePerIntake: const Dosage(amount: 1.0, unit: DoseUnit.tablet),
  stock: const PackStock(remaining: 30, total: 30, warnAt: 5),
  notes: 'Take with food',
  createdAt: DateTime.utc(2026, 1, 14, 10, 30),
);

/// (b) Syrup: Dosage, no stock, CourseType(7 days, 0 pause), 1 time slot,
/// notes null.
final _syrupFixture = Medication(
  id: const MedicationId('med-syrup-001'),
  name: 'Amoxicillin Syrup',
  form: MedicationForm.syrup,
  type: MedicationType.course(
    startDate: DateTime.utc(2026, 3, 1),
    durationDays: 7,
    pauseDays: 0,
  ),
  schedule: const Schedule(
    frequency: ScheduleFrequency.daily,
    slots: [
      TimeSlot(
        id: TimeSlotId('slot-syrup-001'),
        minuteOfDay: 720, // 12:00
      ),
    ],
  ),
  dosePerIntake: const Dosage(amount: 5.0, unit: DoseUnit.ml),
  stock: null,
  notes: null,
  createdAt: DateTime.utc(2026, 3, 1, 9, 0),
);

/// (c) Inhaler: no dose, no stock, ContinuousType, 1 time slot, notes null.
final _inhalerFixture = Medication(
  id: const MedicationId('med-inhaler-001'),
  name: 'Ventolin',
  form: MedicationForm.inhaler,
  type: MedicationType.continuous(startDate: DateTime.utc(2026, 2, 10)),
  schedule: const Schedule(
    frequency: ScheduleFrequency.daily,
    slots: [
      TimeSlot(
        id: TimeSlotId('slot-inhaler-001'),
        minuteOfDay: 540, // 09:00
      ),
    ],
  ),
  dosePerIntake: null,
  stock: null,
  notes: null,
  createdAt: DateTime.utc(2026, 2, 10, 8, 0),
);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Performs a full round-trip: inserts [original] into [db], reads the rows
/// back, maps them through [medicationFromRows], and returns the result.
Future<Medication> _roundTrip(
  AppDatabase db,
  Medication original,
) async {
  final dataSource = MedicationLocalDataSource(db);
  await dataSource.insertMedication(
    medicationToCompanion(original),
    timeSlotsToCompanions(original),
  );

  final row =
      await (db.select(db.medications)
            ..where((t) => t.id.equals(original.id.value)))
          .getSingle();

  final slotRows =
      await (db.select(db.timeSlots)
            ..where((t) => t.medicationId.equals(original.id.value)))
          .get();

  return medicationFromRows(row, slotRows);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('MedicationMapper corrupt-stock guard', () {
    // -----------------------------------------------------------------------
    // Gap W1: stockRemaining + stockTotal present but stockWarnAt absent →
    //         medicationFromRows must throw StateError (not silently default).
    // -----------------------------------------------------------------------
    test(
      'should throw StateError when stockRemaining and stockTotal are set but stockWarnAt is absent',
      () async {
        // Insert a raw row with stockRemaining + stockTotal but no stockWarnAt.
        // We use a ContinuousType with all required columns satisfied so that
        // the only broken invariant is the corrupt-stock combination.
        await db.into(db.medications).insert(
          MedicationsCompanion.insert(
            id: 'med-corrupt-stock-001',
            name: 'Corrupt Stock Med',
            form: MedicationForm.tablet,
            typeKind: MedicationTypeKind.continuous,
            frequency: ScheduleFrequency.daily,
            startDate: DateTime.utc(2026, 1, 1),
            stockRemaining: const Value(10),
            stockTotal: const Value(30),
            // stockWarnAt intentionally absent (Value.absent is the default)
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );

        final row =
            await (db.select(db.medications)
                  ..where((t) => t.id.equals('med-corrupt-stock-001')))
                .getSingle();

        // No time slots needed — the guard fires before slot mapping.
        expect(
          () => medicationFromRows(row, []),
          throwsStateError,
        );
      },
    );
  });

  group('MedicationMapper round-trip', () {
    // -----------------------------------------------------------------------
    // (a) Tablet fixture
    // -----------------------------------------------------------------------
    group('(a) tablet — Dosage + PackStock + ContinuousType, 2 slots, notes', () {
      late Medication result;

      setUp(() async {
        result = await _roundTrip(db, _tabletFixture);
      });

      test('should preserve medication id', () {
        expect(result.id, _tabletFixture.id);
      });

      test('should preserve name', () {
        expect(result.name, _tabletFixture.name);
      });

      test('should preserve form', () {
        expect(result.form, _tabletFixture.form);
      });

      test('should preserve MedicationType variant as ContinuousType', () {
        expect(result.type, isA<ContinuousType>());
      });

      // Drift's dateTime() column returns local DateTime on read. The stored
      // UTC epoch is correct; the isAtSameMomentAs check verifies the moment
      // is preserved without requiring the UTC flag to be set.
      test('should preserve startDate moment for continuous type', () {
        final startDate = (result.type as ContinuousType).startDate;
        final expected = DateTime.utc(2026, 1, 15);
        expect(startDate.isAtSameMomentAs(expected), isTrue);
      });

      test('should preserve schedule frequency', () {
        expect(result.schedule.frequency, ScheduleFrequency.daily);
      });

      test('should preserve all minuteOfDay values from 2 time slots', () {
        final minutes =
            result.schedule.slots.map((s) => s.minuteOfDay).toSet();
        expect(minutes, {480, 1200});
      });

      test('should preserve slot count (2 slots)', () {
        expect(result.schedule.slots.length, 2);
      });

      test('should preserve dosePerIntake amount (1.0)', () {
        expect(result.dosePerIntake, isNotNull);
        expect(result.dosePerIntake!.amount, 1.0);
      });

      test('should preserve dosePerIntake unit (tablet)', () {
        expect(result.dosePerIntake!.unit, DoseUnit.tablet);
      });

      test('should preserve PackStock remaining (30)', () {
        expect(result.stock, isNotNull);
        expect(result.stock!.remaining, 30);
      });

      test('should preserve PackStock total (30)', () {
        expect(result.stock!.total, 30);
      });

      test('should preserve PackStock warnAt (5)', () {
        expect(result.stock!.warnAt, 5);
      });

      test('should preserve notes', () {
        expect(result.notes, 'Take with food');
      });

      test('should preserve createdAt moment', () {
        final expected = DateTime.utc(2026, 1, 14, 10, 30);
        expect(result.createdAt.isAtSameMomentAs(expected), isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // (b) Syrup fixture
    // -----------------------------------------------------------------------
    group('(b) syrup — Dosage, null stock, CourseType, 1 slot, null notes', () {
      late Medication result;

      setUp(() async {
        result = await _roundTrip(db, _syrupFixture);
      });

      test('should preserve MedicationType variant as CourseType', () {
        expect(result.type, isA<CourseType>());
      });

      test('should preserve CourseType startDate moment', () {
        final startDate = (result.type as CourseType).startDate;
        final expected = DateTime.utc(2026, 3, 1);
        expect(startDate.isAtSameMomentAs(expected), isTrue);
      });

      test('should preserve CourseType durationDays (7)', () {
        expect((result.type as CourseType).durationDays, 7);
      });

      test('should preserve CourseType pauseDays (0)', () {
        expect((result.type as CourseType).pauseDays, 0);
      });

      test('should preserve dosePerIntake amount (5.0)', () {
        expect(result.dosePerIntake, isNotNull);
        expect(result.dosePerIntake!.amount, 5.0);
      });

      test('should preserve dosePerIntake unit (ml)', () {
        expect(result.dosePerIntake!.unit, DoseUnit.ml);
      });

      test('should preserve null stock', () {
        expect(result.stock, isNull);
      });

      test('should preserve null notes', () {
        expect(result.notes, isNull);
      });

      test('should preserve single time slot count (1)', () {
        expect(result.schedule.slots.length, 1);
      });

      test('should preserve single time slot minuteOfDay (720)', () {
        expect(result.schedule.slots.first.minuteOfDay, 720);
      });

      test('should preserve schedule frequency', () {
        expect(result.schedule.frequency, ScheduleFrequency.daily);
      });

      test('should preserve createdAt moment', () {
        final expected = DateTime.utc(2026, 3, 1, 9, 0);
        expect(result.createdAt.isAtSameMomentAs(expected), isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // (c) Inhaler fixture
    // -----------------------------------------------------------------------
    group('(c) inhaler — null dose, null stock, ContinuousType, 1 slot', () {
      late Medication result;

      setUp(() async {
        result = await _roundTrip(db, _inhalerFixture);
      });

      test('should preserve null dosePerIntake', () {
        expect(result.dosePerIntake, isNull);
      });

      test('should preserve null stock', () {
        expect(result.stock, isNull);
      });

      test('should preserve MedicationType variant as ContinuousType', () {
        expect(result.type, isA<ContinuousType>());
      });

      test('should preserve ContinuousType startDate moment', () {
        final startDate = (result.type as ContinuousType).startDate;
        final expected = DateTime.utc(2026, 2, 10);
        expect(startDate.isAtSameMomentAs(expected), isTrue);
      });

      test('should preserve single time slot count (1)', () {
        expect(result.schedule.slots.length, 1);
      });

      test('should preserve single time slot minuteOfDay (540)', () {
        expect(result.schedule.slots.first.minuteOfDay, 540);
      });

      test('should preserve null notes', () {
        expect(result.notes, isNull);
      });

      test('should preserve form (inhaler)', () {
        expect(result.form, MedicationForm.inhaler);
      });

      test('should preserve createdAt moment', () {
        final expected = DateTime.utc(2026, 2, 10, 8, 0);
        expect(result.createdAt.isAtSameMomentAs(expected), isTrue);
      });
    });
  });
}
