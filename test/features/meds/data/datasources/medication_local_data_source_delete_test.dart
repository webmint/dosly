/// Tests for [MedicationLocalDataSource.deleteMedication] against a real
/// in-memory drift DB.
///
/// Covers:
///   - Cascade proof: deleting a medication removes its row AND the
///     `onDelete: cascade` foreign key removes its time-slot rows too.
///   - Absent-id delete: deleting an id that does not exist is a no-throw
///     no-op that leaves existing rows untouched.
library;

import 'package:dosly/core/database/database.dart';
import 'package:dosly/features/meds/data/datasources/medication_local_data_source.dart';
import 'package:dosly/features/meds/data/mappers/medication_mapper.dart';
import 'package:dosly/features/meds/domain/entities/dosage.dart';
import 'package:dosly/features/meds/domain/entities/dose_unit.dart';
import 'package:dosly/features/meds/domain/entities/medication.dart';
import 'package:dosly/features/meds/domain/entities/medication_form.dart';
import 'package:dosly/features/meds/domain/entities/medication_type.dart';
import 'package:dosly/features/meds/domain/entities/schedule.dart';
import 'package:dosly/features/meds/domain/entities/schedule_frequency.dart';
import 'package:dosly/features/meds/domain/entities/time_slot.dart';
import 'package:dosly/features/meds/domain/value_objects/medication_id.dart';
import 'package:dosly/features/meds/domain/value_objects/time_slot_id.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

/// Med with 2 time slots — used to prove the cascade delete removes both the
/// medication row and its slot rows.
final _medA = Medication(
  id: const MedicationId('del-med-a'),
  name: 'MedA',
  form: MedicationForm.tablet,
  type: MedicationType.continuous(startDate: DateTime.utc(2026, 1, 1)),
  schedule: const Schedule(
    frequency: ScheduleFrequency.daily,
    slots: [
      TimeSlot(id: TimeSlotId('del-slot-a1'), minuteOfDay: 480),
      TimeSlot(id: TimeSlotId('del-slot-a2'), minuteOfDay: 1200),
    ],
  ),
  dosePerIntake: const Dosage(amount: 500.0, unit: DoseUnit.mg),
  stock: null,
  notes: null,
  createdAt: DateTime.utc(2026, 1, 1),
);

/// A second, distinct medication — used to prove a no-op delete leaves
/// unrelated rows untouched.
final _medB = Medication(
  id: const MedicationId('del-med-b'),
  name: 'MedB',
  form: MedicationForm.capsule,
  type: MedicationType.continuous(startDate: DateTime.utc(2026, 2, 1)),
  schedule: const Schedule(
    frequency: ScheduleFrequency.daily,
    slots: [TimeSlot(id: TimeSlotId('del-slot-b1'), minuteOfDay: 600)],
  ),
  dosePerIntake: null,
  stock: null,
  notes: null,
  createdAt: DateTime.utc(2026, 2, 1),
);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Inserts a [Medication] via the mapper (same path as production code).
Future<void> _insert(
  MedicationLocalDataSource src,
  Medication med,
) async {
  await src.insertMedication(
    medicationToCompanion(med),
    timeSlotsToCompanions(med),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late AppDatabase db;
  late MedicationLocalDataSource src;

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    src = MedicationLocalDataSource(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('MedicationLocalDataSource.deleteMedication()', () {
    // -------------------------------------------------------------------------
    // Cascade proof
    // -------------------------------------------------------------------------
    test(
      'should remove both the medication row and its time-slot rows on delete',
      () async {
        await _insert(src, _medA);

        // Sanity pre-assert: both tables are populated before the delete.
        final medsBefore = await db.select(db.medications).get();
        expect(medsBefore.length, 1);
        final slotsBefore = await db.select(db.timeSlots).get();
        expect(slotsBefore.length, 2);

        await src.deleteMedication('del-med-a');

        // Cascade proof: the medication row AND its time-slot rows are gone.
        final medsAfter = await db.select(db.medications).get();
        expect(medsAfter, isEmpty);
        final slotsAfter = await db.select(db.timeSlots).get();
        expect(slotsAfter, isEmpty);
      },
    );

    // -------------------------------------------------------------------------
    // Absent-id delete — no-throw no-op
    // -------------------------------------------------------------------------
    test(
      'should complete without throwing when deleting an id that does not exist',
      () async {
        await expectLater(src.deleteMedication('does-not-exist'), completes);
      },
    );

    test(
      'should leave existing rows untouched when deleting an unrelated id',
      () async {
        await _insert(src, _medB);

        await src.deleteMedication('does-not-exist');

        final medsAfter = await db.select(db.medications).get();
        expect(medsAfter.length, 1);
        expect(medsAfter.single.id, 'del-med-b');

        final slotsAfter = await db.select(db.timeSlots).get();
        expect(slotsAfter.length, 1);
        expect(slotsAfter.single.id, 'del-slot-b1');
      },
    );

    // -------------------------------------------------------------------------
    // AC-10 — reactive list refresh: watchAllMedications() re-emits a list
    // that no longer contains the deleted medication, without a manual
    // refresh. Mirrors the before/after `.first` re-emission style used by
    // medication_local_data_source_watch_test.dart's "cascade delete" group,
    // but drives the delete through the datasource's deleteMedication (the
    // same path production code uses) rather than a raw table delete.
    // -------------------------------------------------------------------------
    test(
      'should make watchAllMedications() re-emit without the deleted medication',
      () async {
        await _insert(src, _medA);
        await _insert(src, _medB);

        final before = await src.watchAllMedications().first;
        expect(before.length, 2);
        expect(before.map((e) => e.$1.id).toSet(), {'del-med-a', 'del-med-b'});

        await src.deleteMedication('del-med-a');

        final after = await src.watchAllMedications().first;
        final afterIds = after.map((e) => e.$1.id).toSet();

        // Survivor is still present; deleted medication is gone.
        expect(afterIds, contains('del-med-b'));
        expect(afterIds, isNot(contains('del-med-a')));
        expect(after.length, 1);
      },
    );
  });
}
