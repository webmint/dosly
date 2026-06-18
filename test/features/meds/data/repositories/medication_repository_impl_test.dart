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
