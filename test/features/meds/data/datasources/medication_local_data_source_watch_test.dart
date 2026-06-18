/// Tests for [MedicationLocalDataSource.watchAllMedications()] against a real
/// in-memory drift DB.
///
/// Covers:
///   - Slot grouping: a med with 2 slots emits correctly paired; a slot-less
///     med emits with an empty slot list (left-outer-join guarantee).
///   - AC-19 reactive re-emission on medication insert: the stream re-fires
///     without manual refresh.
///   - Reactive re-emission on slot-only change: proves the join watches
///     `timeSlots`, not just `medications`.
///   - Cascade delete: deleting a medication also removes its slots and the
///     stream re-emits without that entry.
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

/// Med A: has 2 time slots at 08:00 and 20:00.
final _medA = Medication(
  id: const MedicationId('ds-med-a'),
  name: 'MedA',
  form: MedicationForm.tablet,
  type: MedicationType.continuous(startDate: DateTime.utc(2026, 1, 1)),
  schedule: const Schedule(
    frequency: ScheduleFrequency.daily,
    slots: [
      TimeSlot(id: TimeSlotId('ds-slot-a1'), minuteOfDay: 480),
      TimeSlot(id: TimeSlotId('ds-slot-a2'), minuteOfDay: 1200),
    ],
  ),
  dosePerIntake: const Dosage(amount: 500.0, unit: DoseUnit.mg),
  stock: null,
  notes: null,
  createdAt: DateTime.utc(2026, 1, 1),
);

/// Med B: has NO time slots — exercises the left-outer-join empty-list path.
final _medB = Medication(
  id: const MedicationId('ds-med-b'),
  name: 'MedB',
  form: MedicationForm.capsule,
  type: MedicationType.continuous(startDate: DateTime.utc(2026, 2, 1)),
  schedule: const Schedule(frequency: ScheduleFrequency.daily, slots: []),
  dosePerIntake: null,
  stock: null,
  notes: null,
  createdAt: DateTime.utc(2026, 2, 1),
);

/// Med C: used as the "new med" in AC-19 re-emission tests.
final _medC = Medication(
  id: const MedicationId('ds-med-c'),
  name: 'MedC',
  form: MedicationForm.tablet,
  type: MedicationType.continuous(startDate: DateTime.utc(2026, 3, 1)),
  schedule: const Schedule(
    frequency: ScheduleFrequency.daily,
    slots: [TimeSlot(id: TimeSlotId('ds-slot-c1'), minuteOfDay: 720)],
  ),
  dosePerIntake: null,
  stock: null,
  notes: null,
  createdAt: DateTime.utc(2026, 3, 1),
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
    // closeStreamsSynchronously: true makes drift notify stream listeners
    // synchronously after each write completes, so `await write` then
    // `await stream.first` is deterministic with no wall-clock delays.
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

  group('MedicationLocalDataSource.watchAllMedications()', () {
    // -------------------------------------------------------------------------
    // Grouping
    // -------------------------------------------------------------------------
    group('grouping', () {
      test(
        'should pair med A with its 2 slots and med B with an empty slot list',
        () async {
          await _insert(src, _medA);
          await _insert(src, _medB);

          final emission = await src.watchAllMedications().first;

          expect(emission.length, 2);

          // Find the entry for A (order is insertion-order).
          final (MedicationRow medARow, List<TimeSlotRow> medASlots) =
              emission.firstWhere((e) => e.$1.id == 'ds-med-a');
          expect(medARow.id, 'ds-med-a');
          expect(medASlots.length, 2);
          expect(
            medASlots.map((s) => s.minuteOfDay).toSet(),
            {480, 1200},
          );

          // Find the entry for B: must have an EMPTY slot list (left-outer join).
          final (MedicationRow medBRow, List<TimeSlotRow> medBSlots) =
              emission.firstWhere((e) => e.$1.id == 'ds-med-b');
          expect(medBRow.id, 'ds-med-b');
          expect(medBSlots, isEmpty);
        },
      );

      test(
        'should set the medicationId foreign key correctly on each slot row',
        () async {
          await _insert(src, _medA);

          final emission = await src.watchAllMedications().first;
          final (_, List<TimeSlotRow> slots) = emission.single;

          for (final slot in slots) {
            expect(slot.medicationId, 'ds-med-a');
          }
        },
      );

      test(
        'should return an empty list when the database has no medications',
        () async {
          final emission = await src.watchAllMedications().first;
          expect(emission, isEmpty);
        },
      );
    });

    // -------------------------------------------------------------------------
    // AC-19: re-emission on medication insert
    // -------------------------------------------------------------------------
    group('re-emission on medication insert (AC-19)', () {
      test(
        'should emit again when a new medication is inserted after subscription',
        () async {
          // Pre-seed one med so the first emission is non-empty and the
          // second emission is distinguishably larger.
          await _insert(src, _medA);

          // Capture the first emission (the seeded state).
          final firstEmission = await src.watchAllMedications().first;
          expect(firstEmission.length, 1);

          // Insert a new medication AFTER subscribing to the stream.
          // Because closeStreamsSynchronously:true, the stream fires
          // synchronously when the write completes; `stream.first` on a
          // fresh listen therefore resolves on the very next microtask.
          await _insert(src, _medC);
          final secondEmission = await src.watchAllMedications().first;

          expect(secondEmission.length, 2);
          final ids = secondEmission.map((e) => e.$1.id).toSet();
          expect(ids, containsAll(['ds-med-a', 'ds-med-c']));
        },
      );

      test(
        'should include the new medication in the emission after insert',
        () async {
          await _insert(src, _medA);
          await _insert(src, _medC);

          final emission = await src.watchAllMedications().first;

          final found = emission.where((e) => e.$1.id == 'ds-med-c');
          expect(found.length, 1);
          expect(found.single.$2.single.minuteOfDay, 720);
        },
      );
    });

    // -------------------------------------------------------------------------
    // Re-emission on slot-only change
    // -------------------------------------------------------------------------
    group('re-emission on slot-only change', () {
      test(
        'should re-emit when a new time slot is inserted for an existing med',
        () async {
          // Seed a slot-less med so the slot list starts empty.
          await _insert(src, _medB);

          final beforeSlot = await src.watchAllMedications().first;
          final (_, List<TimeSlotRow> slotsBefore) = beforeSlot.single;
          expect(slotsBefore, isEmpty);

          // Insert a slot directly — only `timeSlots` table changes, NOT
          // `medications`. This verifies that the watch join covers both tables.
          await db.into(db.timeSlots).insert(
                TimeSlotsCompanion.insert(
                  id: 'direct-slot-1',
                  medicationId: 'ds-med-b',
                  minuteOfDay: 900,
                ),
              );

          // The stream must re-emit because the timeSlots table changed.
          final afterSlot = await src.watchAllMedications().first;
          final (_, List<TimeSlotRow> slotsAfter) = afterSlot.single;
          expect(slotsAfter.length, 1);
          expect(slotsAfter.single.minuteOfDay, 900);
        },
      );

      test(
        'should re-emit when a time slot is deleted from an existing med',
        () async {
          // Seed med A with 2 slots.
          await _insert(src, _medA);

          // Delete one slot directly — only `timeSlots` table changes.
          await (db.delete(db.timeSlots)
                ..where((t) => t.id.equals('ds-slot-a1')))
              .go();

          final emission = await src.watchAllMedications().first;
          final (_, List<TimeSlotRow> slots) = emission.single;
          expect(slots.length, 1);
          expect(slots.single.id, 'ds-slot-a2');
        },
      );
    });

    // -------------------------------------------------------------------------
    // Cascade delete
    // -------------------------------------------------------------------------
    group('cascade delete', () {
      test(
        'should re-emit without deleted medication after its row is removed',
        () async {
          await _insert(src, _medA);
          await _insert(src, _medB);

          // Delete med A from the medications table. ON DELETE CASCADE removes
          // its slots automatically.
          await (db.delete(db.medications)
                ..where((t) => t.id.equals('ds-med-a')))
              .go();

          final emission = await src.watchAllMedications().first;
          expect(emission.length, 1);
          expect(emission.single.$1.id, 'ds-med-b');
        },
      );

      test(
        'should cascade-delete all slots belonging to the deleted medication',
        () async {
          await _insert(src, _medA);

          // Verify slots are present before deletion.
          final slotsBefore = await db.select(db.timeSlots).get();
          expect(slotsBefore.length, 2);

          await (db.delete(db.medications)
                ..where((t) => t.id.equals('ds-med-a')))
              .go();

          final slotsAfter = await db.select(db.timeSlots).get();
          expect(slotsAfter, isEmpty);
        },
      );
    });
  });
}
