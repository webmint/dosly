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
library;

import 'package:dosly/core/database/database.dart';
import 'package:dosly/core/error/failures.dart';
import 'package:dosly/features/meds/data/datasources/intake_local_data_source.dart';
import 'package:dosly/features/meds/data/repositories/intake_repository_impl.dart';
import 'package:dosly/features/meds/domain/entities/intake.dart';
import 'package:dosly/features/meds/domain/entities/intake_status.dart';
import 'package:dosly/features/meds/domain/value_objects/intake_id.dart';
import 'package:dosly/features/meds/domain/value_objects/medication_id.dart';
import 'package:dosly/features/meds/domain/value_objects/time_slot_id.dart';
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
}
