/// Tests for [IntakeRepositoryImpl] — proves every fallible operation maps
/// data-source outcomes onto `Either<Failure, T>` and that no exception ever
/// escapes the data layer (constitution §2.1).
///
/// Mirrors [MedicationRepositoryImpl]'s test suite (see
/// medication_repository_impl_test.dart), but mocks [IntakeLocalDataSource]
/// with mocktail rather than subclassing it against a real in-memory DB:
/// [IntakeRepositoryImpl] has no query-shaping logic of its own (unlike
/// [MedicationRepositoryImpl.watchAll], which joins/groups rows) — only the
/// try/catch → `Either` mapping — so a mocked collaborator is the narrower,
/// faster tool for exercising it.
///
/// Covers:
///   - watchAll happy path: maps the data source's `Stream<List<IntakeRow>>`
///     to `Right(List<Intake>)`.
///   - watchAll failure path: a source-stream error is absorbed into
///     `Left(CacheFailure)` — never thrown.
///   - markTaken / skip happy path: `Right(intake)` on success.
///   - markTaken / skip failure path: a thrown data-source exception maps to
///     `Left(CacheFailure)` — never rethrown.
///   - undo happy path: `Right(null)` on success.
///   - undo failure path: a thrown data-source exception maps to
///     `Left(CacheFailure)` — never rethrown.
///   - markMissed, against a REAL in-memory drift database (constitution
///     §3.4 — never a mock for the DB itself): happy path (a `missed` row
///     round-trips as UTC / by enum name), never-clobber (an existing
///     `taken`/`skipped` row for the same occurrence survives a `markMissed`
///     call untouched — the airtight proof that the mock-based use-case test
///     in reconcile_missed_intakes_test.dart cannot give, since a mock never
///     exercises the real `INSERT OR IGNORE` conflict resolution), and the
///     error path (a closed database maps to `Left(CacheFailure)`).
library;

import 'package:dosly/core/database/database.dart';
import 'package:dosly/core/database/tables/medications_table.dart';
import 'package:dosly/core/error/failures.dart';
import 'package:dosly/features/meds/data/datasources/intake_local_data_source.dart';
import 'package:dosly/features/meds/data/repositories/intake_repository_impl.dart';
import 'package:dosly/features/meds/domain/entities/intake.dart';
import 'package:dosly/features/meds/domain/entities/intake_status.dart';
import 'package:dosly/features/meds/domain/entities/medication_form.dart';
import 'package:dosly/features/meds/domain/entities/schedule_frequency.dart';
import 'package:dosly/features/meds/domain/value_objects/intake_id.dart';
import 'package:dosly/features/meds/domain/value_objects/medication_id.dart';
import 'package:dosly/features/meds/domain/value_objects/time_slot_id.dart';
// Hide drift's own `isNull` column-filter helper so it doesn't collide with
// package:matcher's `isNull` matcher used in `expect(..., isNull)` below.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class _MockIntakeLocalDataSource extends Mock
    implements IntakeLocalDataSource {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

final _intake = Intake(
  id: const IntakeId('repo-intake-001'),
  medicationId: const MedicationId('repo-med-001'),
  slotId: const TimeSlotId('repo-slot-001'),
  scheduledAt: DateTime.utc(2026, 6, 1, 8),
  confirmedAt: DateTime.utc(2026, 6, 1, 8, 5),
  status: IntakeStatus.taken,
  notes: null,
);

final _row = IntakeRow(
  id: 'repo-intake-001',
  medicationId: 'repo-med-001',
  slotId: 'repo-slot-001',
  scheduledAt: DateTime.utc(2026, 6, 1, 8),
  confirmedAt: DateTime.utc(2026, 6, 1, 8, 5),
  status: IntakeStatus.taken,
  notes: null,
);

// ---------------------------------------------------------------------------
// Fixtures — markMissed real-DB group only (mirrors
// intake_local_data_source_test.dart's fixture shapes).
// ---------------------------------------------------------------------------

/// The parent medication all real-DB markMissed fixtures reference (satisfies
/// the `intakes.medicationId` foreign key, enforced via `pragma foreign_keys
/// = ON`).
const String _realMedId = 'missed-med-001';

/// Slot + scheduled instant that together with [_realMedId] form the ONE
/// occurrence exercised by the never-clobber tests.
const String _realSlotId = 'missed-slot-001';
final DateTime _realScheduledAt = DateTime.utc(2026, 6, 1, 8);

/// A minimal parent medication row so the real-DB intake FKs resolve.
final MedicationsCompanion _realMedCompanion = MedicationsCompanion.insert(
  id: _realMedId,
  name: 'MissedMed',
  form: MedicationForm.tablet,
  typeKind: MedicationTypeKind.continuous,
  frequency: ScheduleFrequency.daily,
  startDate: DateTime.utc(2026, 1, 1),
  createdAt: DateTime.utc(2026, 1, 1),
);

/// Builds a `missed` [Intake] for the shared occurrence, with a distinct
/// [id] per call so tests never collide on the intake primary key.
Intake _missedIntake(String id) => Intake(
  id: IntakeId(id),
  medicationId: const MedicationId(_realMedId),
  slotId: const TimeSlotId(_realSlotId),
  scheduledAt: _realScheduledAt,
  confirmedAt: null,
  status: IntakeStatus.missed,
  notes: null,
);

/// Builds a `taken` [Intake] for the shared occurrence, with a distinct [id].
Intake _takenIntake(String id) => Intake(
  id: IntakeId(id),
  medicationId: const MedicationId(_realMedId),
  slotId: const TimeSlotId(_realSlotId),
  scheduledAt: _realScheduledAt,
  confirmedAt: DateTime.utc(2026, 6, 1, 8, 5),
  status: IntakeStatus.taken,
  notes: null,
);

/// Builds a `skipped` [Intake] for the shared occurrence, with a distinct
/// [id].
Intake _skippedIntake(String id) => Intake(
  id: IntakeId(id),
  medicationId: const MedicationId(_realMedId),
  slotId: const TimeSlotId(_realSlotId),
  scheduledAt: _realScheduledAt,
  confirmedAt: DateTime.utc(2026, 6, 1, 8, 10),
  status: IntakeStatus.skipped,
  notes: null,
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    // mocktail requires a fallback value for every custom type matched with
    // any() — String has a built-in fallback, but IntakesCompanion does not.
    registerFallbackValue(
      IntakesCompanion.insert(
        id: 'fallback',
        medicationId: 'fallback-med',
        slotId: 'fallback-slot',
        scheduledAt: DateTime.utc(2026, 1, 1),
        status: IntakeStatus.taken,
      ),
    );
  });

  late _MockIntakeLocalDataSource dataSource;
  late IntakeRepositoryImpl repository;

  setUp(() {
    dataSource = _MockIntakeLocalDataSource();
    repository = IntakeRepositoryImpl(dataSource);
  });

  // ---------------------------------------------------------------------------
  // watchAll
  // ---------------------------------------------------------------------------
  group('IntakeRepositoryImpl.watchAll()', () {
    group('happy path', () {
      test(
        'should emit Right(List<Intake>) mapped from the data-source rows',
        () async {
          when(
            () => dataSource.watchAllIntakes(),
          ).thenAnswer((_) => Stream.value(<IntakeRow>[_row]));

          final result = await repository.watchAll().first;

          final intakes = result.getOrElse(
            (f) => fail('expected Right, got Left: $f'),
          );
          expect(intakes.length, 1);
          expect(intakes.single.id, const IntakeId('repo-intake-001'));
          expect(
            intakes.single.medicationId,
            const MedicationId('repo-med-001'),
          );
          expect(intakes.single.slotId, const TimeSlotId('repo-slot-001'));
          expect(intakes.single.status, IntakeStatus.taken);
        },
      );

      test(
        'should emit Right(<empty list>) when the data source has no rows',
        () async {
          when(
            () => dataSource.watchAllIntakes(),
          ).thenAnswer((_) => Stream.value(<IntakeRow>[]));

          final result = await repository.watchAll().first;

          result.fold(
            (f) => fail('expected Right, got Left: $f'),
            (intakes) => expect(intakes, isEmpty),
          );
        },
      );
    });

    group('failure path', () {
      test(
        'should emit Left(CacheFailure) — not throw — when the source stream errors',
        () async {
          when(() => dataSource.watchAllIntakes()).thenAnswer(
            (_) => Stream.error(StateError('simulated data-source failure')),
          );

          final result = await repository.watchAll().first;

          expect(result.isLeft(), isTrue);
        },
      );

      test(
        'should wrap the error in CacheFailure when the source stream errors',
        () async {
          when(() => dataSource.watchAllIntakes()).thenAnswer(
            (_) => Stream.error(StateError('simulated data-source failure')),
          );

          final Either<Failure, List<Intake>> result = await repository
              .watchAll()
              .first;

          result.fold(
            (failure) => expect(failure, isA<CacheFailure>()),
            (_) => fail('expected Left, got Right'),
          );
        },
      );

      test(
        'should emit Left(CacheFailure) — not throw — when the source stream throws '
        'synchronously',
        () async {
          when(
            () => dataSource.watchAllIntakes(),
          ).thenThrow(StateError('simulated synchronous failure'));

          final result = await repository.watchAll().first;

          result.fold(
            (failure) => expect(failure, isA<CacheFailure>()),
            (_) => fail('expected Left, got Right'),
          );
        },
      );
    });
  });

  // ---------------------------------------------------------------------------
  // markTaken
  // ---------------------------------------------------------------------------
  group('IntakeRepositoryImpl.markTaken()', () {
    group('happy path', () {
      test(
        'should upsert via the data source and return Right(intake) on success',
        () async {
          when(() => dataSource.upsertIntake(any())).thenAnswer((_) async {});

          final result = await repository.markTaken(_intake);

          result.fold(
            (f) => fail('expected Right, got Left: $f'),
            (intake) => expect(intake, _intake),
          );
          verify(() => dataSource.upsertIntake(any())).called(1);
        },
      );
    });

    group('failure path', () {
      test(
        'should return Left(CacheFailure) — not throw — when upsertIntake throws',
        () async {
          when(
            () => dataSource.upsertIntake(any()),
          ).thenThrow(StateError('simulated upsert failure'));

          final Either<Failure, Intake> result = await repository.markTaken(
            _intake,
          );

          result.fold(
            (failure) => expect(failure, isA<CacheFailure>()),
            (_) => fail('expected Left, got Right'),
          );
        },
      );
    });
  });

  // ---------------------------------------------------------------------------
  // skip
  // ---------------------------------------------------------------------------
  group('IntakeRepositoryImpl.skip()', () {
    group('happy path', () {
      test(
        'should upsert via the data source and return Right(intake) on success',
        () async {
          final skippedIntake = _intake.copyWith(status: IntakeStatus.skipped);
          when(() => dataSource.upsertIntake(any())).thenAnswer((_) async {});

          final result = await repository.skip(skippedIntake);

          result.fold(
            (f) => fail('expected Right, got Left: $f'),
            (intake) => expect(intake, skippedIntake),
          );
          verify(() => dataSource.upsertIntake(any())).called(1);
        },
      );
    });

    group('failure path', () {
      test(
        'should return Left(CacheFailure) — not throw — when upsertIntake throws',
        () async {
          when(
            () => dataSource.upsertIntake(any()),
          ).thenThrow(StateError('simulated upsert failure'));

          final Either<Failure, Intake> result = await repository.skip(_intake);

          result.fold(
            (failure) => expect(failure, isA<CacheFailure>()),
            (_) => fail('expected Left, got Right'),
          );
        },
      );
    });
  });

  // ---------------------------------------------------------------------------
  // undo
  // ---------------------------------------------------------------------------
  group('IntakeRepositoryImpl.undo()', () {
    group('happy path', () {
      test(
        'should delete via the data source and return Right(null) on success',
        () async {
          when(() => dataSource.deleteIntake(any())).thenAnswer((_) async {});

          final result = await repository.undo(
            const IntakeId('repo-intake-001'),
          );

          expect(result.isRight(), isTrue);
          verify(() => dataSource.deleteIntake('repo-intake-001')).called(1);
        },
      );
    });

    group('failure path', () {
      test(
        'should return Left(CacheFailure) — not throw — when deleteIntake throws',
        () async {
          when(
            () => dataSource.deleteIntake(any()),
          ).thenThrow(StateError('simulated delete failure'));

          final Either<Failure, void> result = await repository.undo(
            const IntakeId('repo-intake-001'),
          );

          result.fold(
            (failure) => expect(failure, isA<CacheFailure>()),
            (_) => fail('expected Left, got Right'),
          );
        },
      );
    });
  });

  // ---------------------------------------------------------------------------
  // markMissed — proved against a REAL in-memory drift database, not the
  // mocked `dataSource` used above.
  //
  // Every other group in this file mocks IntakeLocalDataSource because
  // IntakeRepositoryImpl has no query-shaping logic of its own (see this
  // file's library doc). markMissed is the one exception: its whole contract
  // IS a piece of real SQL conflict resolution (`INSERT OR IGNORE` on the
  // occurrence unique key — see IntakeLocalDataSource.insertMissedIntake), so
  // a mock cannot prove the never-clobber guarantee — it would only prove
  // "the mock was configured to return successfully". Only a real drift
  // instance can show that a pre-existing `taken`/`skipped` row survives the
  // conflict untouched (constitution §3.4).
  // ---------------------------------------------------------------------------
  group('IntakeRepositoryImpl.markMissed() — real in-memory DB', () {
    late AppDatabase realDb;
    late IntakeRepositoryImpl realRepository;

    setUp(() async {
      realDb = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
      realRepository = IntakeRepositoryImpl(IntakeLocalDataSource(realDb));
      // Seed the parent medication so the intake FK resolves.
      await realDb.into(realDb.medications).insert(_realMedCompanion);
    });

    tearDown(() async {
      await realDb.close();
    });

    group('happy path', () {
      test('should return Right and persist a missed row that round-trips '
          '(status by name, scheduledAt UTC, confirmedAt null)', () async {
        final intake = _missedIntake('missed-intake-001');

        final result = await realRepository.markMissed(intake);

        result.fold(
          (f) => fail('expected Right, got Left: $f'),
          (returned) => expect(returned, intake),
        );

        final rows = await realDb.select(realDb.intakes).get();
        expect(rows.length, 1);
        final row = rows.single;
        expect(row.status, IntakeStatus.missed);
        expect(row.confirmedAt, isNull);
        // Drift round-trips the UTC instant but reads it back with a
        // local-flagged DateTime holding the same moment, so compare via
        // isAtSameMomentAs — never the isUtc flag (see MEMORY.md /
        // intake_mapper.dart's TIMESTAMP CONTRACT).
        expect(row.scheduledAt.isAtSameMomentAs(_realScheduledAt), isTrue);
      });
    });

    group('never-clobber', () {
      test(
        'should preserve an existing taken row — not downgrade it to missed — '
        'when markMissed targets the same occurrence',
        () async {
          final taken = _takenIntake('taken-intake-001');
          final takenResult = await realRepository.markTaken(taken);
          expect(takenResult.isRight(), isTrue);

          // Same occurrence (medicationId + slotId + scheduledAt), fresh id.
          final missed = _missedIntake('missed-intake-002');
          final result = await realRepository.markMissed(missed);

          expect(result.isRight(), isTrue);

          final rows = await realDb.select(realDb.intakes).get();
          expect(
            rows.length,
            1,
            reason:
                'insertOrIgnore must not add a second row for the '
                'same occurrence',
          );
          final row = rows.single;
          expect(
            row.id,
            'taken-intake-001',
            reason:
                'the original taken row must survive untouched — its id '
                "must not be replaced by the missed intake's id",
          );
          expect(row.status, IntakeStatus.taken);
          expect(
            row.confirmedAt?.isAtSameMomentAs(DateTime.utc(2026, 6, 1, 8, 5)),
            isTrue,
          );
        },
      );

      test(
        'should preserve an existing skipped row — not downgrade it to missed '
        '— when markMissed targets the same occurrence',
        () async {
          final skipped = _skippedIntake('skipped-intake-001');
          final skipResult = await realRepository.skip(skipped);
          expect(skipResult.isRight(), isTrue);

          // Same occurrence (medicationId + slotId + scheduledAt), fresh id.
          final missed = _missedIntake('missed-intake-003');
          final result = await realRepository.markMissed(missed);

          expect(result.isRight(), isTrue);

          final rows = await realDb.select(realDb.intakes).get();
          expect(
            rows.length,
            1,
            reason:
                'insertOrIgnore must not add a second row for the '
                'same occurrence',
          );
          final row = rows.single;
          expect(
            row.id,
            'skipped-intake-001',
            reason:
                'the original skipped row must survive untouched — its '
                "id must not be replaced by the missed intake's id",
          );
          expect(row.status, IntakeStatus.skipped);
          expect(
            row.confirmedAt?.isAtSameMomentAs(DateTime.utc(2026, 6, 1, 8, 10)),
            isTrue,
          );
        },
      );
    });

    group('failure path', () {
      test(
        'should return Left(CacheFailure) — not throw — when the database is '
        'closed',
        () async {
          await realDb.close();

          final result = await realRepository.markMissed(
            _missedIntake('missed-intake-closed-db'),
          );

          result.fold(
            (failure) => expect(failure, isA<CacheFailure>()),
            (_) => fail('expected Left, got Right'),
          );
        },
      );
    });
  });
}
