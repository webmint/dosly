/// Tests for [MedicationRepositoryImpl] against a real in-memory drift DB.
///
/// Covers:
///   - Happy path: [add] returns [Right] and persists 1 medication row + N slot
///     rows in the database.
///   - Failure path: after the DB is closed, [add] returns [Left(Failure)]
///     without throwing — the repository absorbs the SqliteException and wraps
///     it as an [UnknownFailure].
///   - watchAll happy path: emits [Right] with fully-mapped [Medication]s.
///   - watchAll failure path: emits [Left(Failure)] on error — never throws.
///   - delete happy path: [delete] returns [Right(null)] and removes the row.
///   - delete failure path: a thrown data-source exception maps to
///     [Left(UnknownFailure)] — never throws.
library;

import 'package:dosly/core/database/database.dart';
import 'package:dosly/core/error/failures.dart';
import 'package:dosly/features/meds/data/datasources/medication_local_data_source.dart';
import 'package:dosly/features/meds/data/repositories/medication_repository_impl.dart';
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
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

/// A minimal valid [Medication] used for repository add tests.
final _medication = Medication(
  id: const MedicationId('repo-med-001'),
  name: 'Ibuprofen',
  form: MedicationForm.tablet,
  type: MedicationType.continuous(startDate: DateTime.utc(2026, 4, 1)),
  schedule: const Schedule(
    frequency: ScheduleFrequency.daily,
    slots: [
      TimeSlot(
        id: TimeSlotId('repo-slot-001'),
        minuteOfDay: 480, // 08:00
      ),
      TimeSlot(
        id: TimeSlotId('repo-slot-002'),
        minuteOfDay: 1200, // 20:00
      ),
    ],
  ),
  dosePerIntake: const Dosage(amount: 200.0, unit: DoseUnit.mg),
  stock: null,
  notes: null,
  createdAt: DateTime.utc(2026, 4, 1, 7, 0),
);

/// A second valid [Medication] with distinct id and slot ids — used for
/// watchAll AC-19 re-emission tests where two different meds must coexist.
final _medicationTwo = Medication(
  id: const MedicationId('repo-med-002'),
  name: 'Paracetamol',
  form: MedicationForm.tablet,
  type: MedicationType.continuous(startDate: DateTime.utc(2026, 5, 1)),
  schedule: const Schedule(
    frequency: ScheduleFrequency.daily,
    slots: [
      TimeSlot(
        id: TimeSlotId('repo-slot-003'),
        minuteOfDay: 720, // 12:00
      ),
    ],
  ),
  dosePerIntake: null,
  stock: null,
  notes: null,
  createdAt: DateTime.utc(2026, 5, 1),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late AppDatabase db;
  late MedicationRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    repository = MedicationRepositoryImpl(MedicationLocalDataSource(db));
  });

  tearDown(() async {
    await db.close();
  });

  group('MedicationRepositoryImpl.add()', () {
    // -------------------------------------------------------------------------
    // Happy path
    // -------------------------------------------------------------------------
    group('happy path', () {
      test('should return Right when medication is successfully persisted', () async {
        final result = await repository.add(_medication);

        expect(result.isRight(), isTrue);
      });

      test('should return Right containing the same Medication passed in', () async {
        final result = await repository.add(_medication);

        final persisted = result.getOrElse(
          (f) => fail('expected Right, got Left: $f'),
        );
        expect(persisted, _medication);
      });

      test('should persist exactly 1 medication row in the database', () async {
        await repository.add(_medication);

        final rows = await db.select(db.medications).get();
        expect(rows.length, 1);
      });

      test('should persist medication row with the correct id', () async {
        await repository.add(_medication);

        final rows = await db.select(db.medications).get();
        expect(rows.single.id, 'repo-med-001');
      });

      test('should persist 2 time-slot rows in the database', () async {
        await repository.add(_medication);

        final slotRows = await db.select(db.timeSlots).get();
        expect(slotRows.length, 2);
      });

      test('should persist time-slot rows with correct minuteOfDay values', () async {
        await repository.add(_medication);

        final slotRows = await db.select(db.timeSlots).get();
        final minutes = slotRows.map((s) => s.minuteOfDay).toSet();
        expect(minutes, {480, 1200});
      });

      test('should persist time-slot rows with correct medicationId foreign key',
          () async {
        await repository.add(_medication);

        final slotRows = await db.select(db.timeSlots).get();
        for (final slot in slotRows) {
          expect(slot.medicationId, 'repo-med-001');
        }
      });
    });

    // -------------------------------------------------------------------------
    // Failure path
    // -------------------------------------------------------------------------
    group('failure path', () {
      // Induce failure by inserting the same medication twice: the second
      // insert violates the primary-key unique constraint, causing drift to
      // throw a SqliteException that the repository catches and converts into
      // Left(UnknownFailure).
      test('should return Left when a duplicate-PK insert is attempted', () async {
        // First insert succeeds.
        await repository.add(_medication);

        // Second insert with the same ID must fail.
        final result = await repository.add(_medication);

        expect(result.isLeft(), isTrue);
      });

      test('should return Left(UnknownFailure) — not throw — on duplicate-PK insert',
          () async {
        // Seed the DB so the second add collides.
        await repository.add(_medication);

        final Either<Failure, Medication> result = await repository.add(_medication);

        result.fold(
          (failure) => expect(failure, isA<UnknownFailure>()),
          (_) => fail('expected Left, got Right'),
        );
      });
    });
  });

  // ---------------------------------------------------------------------------
  // update
  // ---------------------------------------------------------------------------
  group('MedicationRepositoryImpl.update()', () {
    // -------------------------------------------------------------------------
    // In-place update — no duplicate row
    // -------------------------------------------------------------------------
    test(
      'should return Right and update the row in place without duplicating it',
      () async {
        await repository.add(_medication);

        final updated = _medication.copyWith(name: 'Naproxen');
        final result = await repository.update(updated);

        expect(result.isRight(), isTrue);

        final rows = await db.select(db.medications).get();
        expect(rows.length, 1);
        expect(rows.single.id, 'repo-med-001');
        expect(rows.single.name, 'Naproxen');
      },
    );

    // -------------------------------------------------------------------------
    // Slot reconciliation — kept slot id preserved
    // -------------------------------------------------------------------------
    // TODO(036-meds-edit): once an Intakes table referencing slotId exists,
    // add a test that inserts an intake on a kept slot and asserts it survives
    // the update — that is the airtight proof the parent row was UPDATEd (no
    // insertOrReplace cascade), since slot-id preservation alone cannot
    // distinguish "no cascade" from "cascade + payload reinsert".
    test(
      'should preserve the TimeSlotId of a kept slot and delete the removed slot',
      () async {
        await repository.add(_medication);

        // Keep minute 480 with its original id; drop minute 1200; add minute 600
        // with a new id.
        final updated = _medication.copyWith(
          schedule: const Schedule(
            frequency: ScheduleFrequency.daily,
            slots: [
              TimeSlot(id: TimeSlotId('repo-slot-001'), minuteOfDay: 480),
              TimeSlot(id: TimeSlotId('repo-slot-NEW'), minuteOfDay: 600),
            ],
          ),
        );
        await repository.update(updated);

        final slotRows = await db.select(db.timeSlots).get();

        // Exactly 2 slot rows survive for this medication.
        expect(slotRows.length, 2);

        // The kept slot id must be preserved.
        final ids = slotRows.map((s) => s.id).toSet();
        expect(ids, {'repo-slot-001', 'repo-slot-NEW'});

        // The old slot id must be gone.
        expect(ids.contains('repo-slot-002'), isFalse);

        // Minutes are correct.
        final minutes = slotRows.map((s) => s.minuteOfDay).toSet();
        expect(minutes, {480, 600});

        // The old minute must be gone.
        expect(minutes.contains(1200), isFalse);
      },
    );

    // -------------------------------------------------------------------------
    // Slot reconciliation — full replacement (all original slots removed)
    // -------------------------------------------------------------------------
    test(
      'should remove all original slots and insert all new ones on full slot replacement',
      () async {
        await repository.add(_medication);

        // Replace both original slots (480/repo-slot-001, 1200/repo-slot-002)
        // with entirely new minutes and ids that share no overlap with the
        // originals — proving the reconciliation path deletes every old row.
        final updated = _medication.copyWith(
          schedule: const Schedule(
            frequency: ScheduleFrequency.daily,
            slots: [
              TimeSlot(id: TimeSlotId('repo-slot-X'), minuteOfDay: 900),
              TimeSlot(id: TimeSlotId('repo-slot-Y'), minuteOfDay: 1380),
            ],
          ),
        );
        await repository.update(updated);

        final slotRows = await db.select(db.timeSlots).get();

        // Exactly 2 slot rows survive — same count, entirely replaced content.
        expect(slotRows.length, 2);

        final ids = slotRows.map((s) => s.id).toSet();
        expect(ids, {'repo-slot-X', 'repo-slot-Y'});

        final minutes = slotRows.map((s) => s.minuteOfDay).toSet();
        expect(minutes, {900, 1380});

        // Both original ids must be absent.
        expect(ids.contains('repo-slot-001'), isFalse);
        expect(ids.contains('repo-slot-002'), isFalse);
      },
    );

    // -------------------------------------------------------------------------
    // Sibling isolation
    // -------------------------------------------------------------------------
    test(
      'should not touch a sibling medication or its slots',
      () async {
        await repository.add(_medication);
        await repository.add(_medicationTwo);

        final updatedFirst = _medication.copyWith(name: 'Naproxen');
        await repository.update(updatedFirst);

        // Both medication rows still exist.
        final medRows = await db.select(db.medications).get();
        expect(medRows.length, 2);

        // Sibling row is untouched.
        final sibling = medRows.firstWhere((r) => r.id == 'repo-med-002');
        expect(sibling.name, 'Paracetamol');

        // Sibling slot is untouched.
        final slotRows = await db.select(db.timeSlots).get();
        final siblingSlots =
            slotRows.where((s) => s.medicationId == 'repo-med-002').toList();
        expect(siblingSlots.length, 1);
        expect(siblingSlots.single.id, 'repo-slot-003');
        expect(siblingSlots.single.minuteOfDay, 720);
      },
    );

    // -------------------------------------------------------------------------
    // Failure path — data source throws → Left(UnknownFailure)
    // -------------------------------------------------------------------------
    test(
      'should return Left(UnknownFailure) — not throw — when upsertMedication throws',
      () async {
        final errorSource = _UpsertErroringDataSource();
        final errorRepo = MedicationRepositoryImpl(errorSource);

        final Either<Failure, Medication> result =
            await errorRepo.update(_medication);

        result.fold(
          (failure) => expect(failure, isA<UnknownFailure>()),
          (_) => fail('expected Left, got Right'),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // watchAll
  // ---------------------------------------------------------------------------
  group('MedicationRepositoryImpl.watchAll()', () {
    group('happy path', () {
      test(
        'should emit Right containing an empty list when DB is empty',
        () async {
          final result = await repository.watchAll().first;

          result.fold(
            (f) => fail('expected Right, got Left: $f'),
            (meds) => expect(meds, isEmpty),
          );
        },
      );

      test(
        'should emit Right with a Medication that round-trips through the mapper',
        () async {
          // Insert via the repository so both tables are populated.
          await repository.add(_medication);

          final result = await repository.watchAll().first;

          final meds = result.getOrElse((f) => fail('expected Right, got Left: $f'));
          expect(meds.length, 1);

          final Medication med = meds.single;
          expect(med.id.value, 'repo-med-001');
          expect(med.name, 'Ibuprofen');
          expect(med.form, MedicationForm.tablet);
          expect(med.dosePerIntake?.amount, 200.0);
          expect(med.dosePerIntake?.unit, DoseUnit.mg);
        },
      );

      test(
        'should emit Right with all slots preserved in the mapped Medication',
        () async {
          await repository.add(_medication);

          final result = await repository.watchAll().first;
          final meds = result.getOrElse((f) => fail('expected Right, got Left: $f'));

          final slots = meds.single.schedule.slots;
          expect(slots.length, 2);
          expect(slots.map((s) => s.minuteOfDay).toSet(), {480, 1200});
          expect(slots.map((s) => s.id.value).toSet(), {'repo-slot-001', 'repo-slot-002'});
        },
      );

      test(
        'should emit an updated Right after a second medication is added (AC-19)',
        () async {
          await repository.add(_medication);

          // Confirm initial state.
          final firstResult = await repository.watchAll().first;
          final firstMeds =
              firstResult.getOrElse((f) => fail('expected Right, got Left: $f'));
          expect(firstMeds.length, 1);

          // Add a second medication with completely distinct ids (including
          // slots) so no PK collision occurs on the timeSlots table.
          await repository.add(_medicationTwo);

          // The next emission must include both medications.
          final secondResult = await repository.watchAll().first;
          final secondMeds =
              secondResult.getOrElse((f) => fail('expected Right, got Left: $f'));
          expect(secondMeds.length, 2);
        },
      );
    });

    group('failure path', () {
      test(
        'should emit Left(Failure) — not throw — when the data source errors',
        () async {
          // Use a fake data source whose watchAllMedications() is an error
          // stream. This exercises the catch block in watchAll() without
          // needing to corrupt the DB or race against close().
          final fakeSource = _ErroringDataSource();
          final errorRepo = MedicationRepositoryImpl(fakeSource);

          final result = await errorRepo.watchAll().first;

          expect(result.isLeft(), isTrue);
        },
      );

      test(
        'should wrap the error in UnknownFailure when the data source errors',
        () async {
          final fakeSource = _ErroringDataSource();
          final errorRepo = MedicationRepositoryImpl(fakeSource);

          final Either<Failure, List<Medication>> result =
              await errorRepo.watchAll().first;

          result.fold(
            (failure) => expect(failure, isA<UnknownFailure>()),
            (_) => fail('expected Left, got Right'),
          );
        },
      );
    });
  });

  // ---------------------------------------------------------------------------
  // delete
  // ---------------------------------------------------------------------------
  group('MedicationRepositoryImpl.delete()', () {
    group('happy path', () {
      test(
        'should return Right(null) when the medication is successfully removed',
        () async {
          await repository.add(_medication);

          final Either<Failure, void> result =
              await repository.delete(_medication.id);

          expect(result.isRight(), isTrue);
          expect(result, isA<Right<Failure, void>>());
        },
      );

      test('should remove the medication row from the database', () async {
        await repository.add(_medication);

        await repository.delete(_medication.id);

        final rows = await db.select(db.medications).get();
        expect(rows, isEmpty);
      });

      test(
        'should return Right(null) — a no-op — when deleting an id that does not exist',
        () async {
          final result = await repository.delete(
            const MedicationId('does-not-exist'),
          );

          expect(result.isRight(), isTrue);
        },
      );
    });

    group('failure path', () {
      test(
        'should return Left(UnknownFailure) — not throw — when deleteMedication throws',
        () async {
          final errorSource = _DeleteErroringDataSource();
          final errorRepo = MedicationRepositoryImpl(errorSource);

          final Either<Failure, void> result =
              await errorRepo.delete(_medication.id);

          result.fold(
            (failure) => expect(failure, isA<UnknownFailure>()),
            (_) => fail('expected Left, got Right'),
          );
        },
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// A [MedicationLocalDataSource] subclass whose [watchAllMedications] returns
/// an error stream. Used to verify [MedicationRepositoryImpl.watchAll()] maps
/// stream errors to [Left(Failure)] without throwing.
///
/// The injected [StateError] stands in for any real I/O failure (e.g. a
/// SqliteException); what matters is that the repository absorbs it.
class _ErroringDataSource extends MedicationLocalDataSource {
  _ErroringDataSource() : super(_unreachableDb());

  // The database passed here is never used — _ErroringDataSource overrides the
  // only method under test. NativeDatabase.memory() is the smallest valid
  // constructor argument; it will not be opened because no method calls through
  // to super.
  static AppDatabase _unreachableDb() =>
      AppDatabase(NativeDatabase.memory());

  @override
  Stream<List<(MedicationRow, List<TimeSlotRow>)>> watchAllMedications() =>
      Stream.error(StateError('simulated data-source failure'));
}

/// A [MedicationLocalDataSource] subclass whose [upsertMedication] always
/// throws. Used to verify [MedicationRepositoryImpl.update()] maps data-source
/// exceptions to [Left(UnknownFailure)] without rethrowing.
///
/// Mirrors [_ErroringDataSource]'s pattern: the injected DB is never opened
/// because only the overridden method is exercised.
class _UpsertErroringDataSource extends MedicationLocalDataSource {
  _UpsertErroringDataSource() : super(_unreachableDb());

  static AppDatabase _unreachableDb() =>
      AppDatabase(NativeDatabase.memory());

  @override
  Future<void> upsertMedication(
    MedicationsCompanion medication,
    List<TimeSlotsCompanion> slots,
  ) =>
      throw StateError('simulated upsert failure');
}

/// A [MedicationLocalDataSource] subclass whose [deleteMedication] always
/// throws. Used to verify [MedicationRepositoryImpl.delete()] maps data-source
/// exceptions to [Left(UnknownFailure)] without rethrowing.
///
/// Mirrors [_UpsertErroringDataSource]'s pattern: the injected DB is never
/// opened because only the overridden method is exercised.
class _DeleteErroringDataSource extends MedicationLocalDataSource {
  _DeleteErroringDataSource() : super(_unreachableDb());

  static AppDatabase _unreachableDb() =>
      AppDatabase(NativeDatabase.memory());

  @override
  Future<void> deleteMedication(String id) =>
      throw StateError('simulated delete failure');
}
