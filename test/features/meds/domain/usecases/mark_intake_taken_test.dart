/// Tests for [MarkIntakeTaken].
///
/// [MarkIntakeTaken] mints a fresh [IntakeId] via the injected [IdGenerator],
/// stamps the confirmation time in UTC, and assembles a TAKEN [Intake] before
/// delegating to [IntakeRepository.markTaken]. These tests prove the built
/// [Intake]'s shape via `captureAny` (mirrors add_medication_test.dart's
/// capture pattern) and that the repository's `Either` result passes through
/// unchanged in both directions (mirrors undo_intake_test.dart).
library;

import 'package:dosly/core/error/failures.dart';
import 'package:dosly/core/id/id_generator.dart';
import 'package:dosly/features/meds/domain/entities/intake.dart';
import 'package:dosly/features/meds/domain/entities/intake_status.dart';
import 'package:dosly/features/meds/domain/repositories/intake_repository.dart';
import 'package:dosly/features/meds/domain/usecases/mark_intake_taken.dart';
import 'package:dosly/features/meds/domain/value_objects/intake_id.dart';
import 'package:dosly/features/meds/domain/value_objects/medication_id.dart';
import 'package:dosly/features/meds/domain/value_objects/time_slot_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class _MockIntakeRepository extends Mock implements IntakeRepository {}

/// Deterministic [IdGenerator] that returns 'mark-id-1', 'mark-id-2', … in
/// order — mirrors add_medication_test.dart's `_FakeIdGenerator`.
class _FakeIdGenerator implements IdGenerator {
  int _counter = 0;

  @override
  String newId() {
    _counter += 1;
    return 'mark-id-$_counter';
  }
}

void main() {
  setUpAll(() {
    // mocktail requires a fallback value for every type matched with any().
    registerFallbackValue(
      Intake(
        id: const IntakeId('fallback'),
        medicationId: const MedicationId('fallback-med'),
        slotId: const TimeSlotId('fallback-slot'),
        scheduledAt: DateTime.utc(2026, 1, 1),
        status: IntakeStatus.taken,
      ),
    );
  });

  group('MarkIntakeTaken', () {
    late _MockIntakeRepository repo;
    late _FakeIdGenerator idGen;
    late MarkIntakeTaken useCase;

    const medicationId = MedicationId('med-mark-001');
    const slotId = TimeSlotId('slot-mark-001');
    final scheduledAt = DateTime.utc(2026, 6, 20, 8);
    final now = DateTime.utc(2026, 6, 20, 8, 1);

    setUp(() {
      repo = _MockIntakeRepository();
      idGen = _FakeIdGenerator();
      useCase = MarkIntakeTaken(repo, idGen);
    });

    // -------------------------------------------------------------------------
    // 1. Builds a TAKEN Intake with the fresh id, UTC timestamps, and no notes.
    // -------------------------------------------------------------------------
    test('should call repo.markTaken with a TAKEN Intake carrying the fresh id '
        'and UTC timestamps', () async {
      when(() => repo.markTaken(any())).thenAnswer(
        (inv) async => Right(inv.positionalArguments.first as Intake),
      );

      final result = await useCase.call(
        medicationId: medicationId,
        slotId: slotId,
        scheduledAt: scheduledAt,
        now: now,
      );

      final captured = verify(() => repo.markTaken(captureAny())).captured;
      expect(captured.length, 1);
      final intake = captured.single as Intake;

      expect(intake.status, IntakeStatus.taken);
      expect(intake.id, const IntakeId('mark-id-1'));
      expect(intake.medicationId, medicationId);
      expect(intake.slotId, slotId);

      expect(intake.scheduledAt.isUtc, isTrue);
      expect(intake.scheduledAt.isAtSameMomentAs(scheduledAt), isTrue);

      expect(intake.confirmedAt, isNotNull);
      expect(intake.confirmedAt!.isUtc, isTrue);
      expect(intake.confirmedAt!.isAtSameMomentAs(now), isTrue);

      expect(intake.notes, isNull);

      expect(result.isRight(), isTrue);
    });

    // -------------------------------------------------------------------------
    // 2. Non-UTC inputs are normalised to UTC before being forwarded.
    // -------------------------------------------------------------------------
    test(
      'should normalise local scheduledAt/now to UTC before calling repo.markTaken',
      () async {
        when(() => repo.markTaken(any())).thenAnswer(
          (inv) async => Right(inv.positionalArguments.first as Intake),
        );

        final localScheduledAt = DateTime(2026, 6, 20, 8);
        final localNow = DateTime(2026, 6, 20, 8, 1);

        await useCase.call(
          medicationId: medicationId,
          slotId: slotId,
          scheduledAt: localScheduledAt,
          now: localNow,
        );

        final captured = verify(() => repo.markTaken(captureAny())).captured;
        final intake = captured.single as Intake;

        expect(intake.scheduledAt.isUtc, isTrue);
        expect(intake.scheduledAt.isAtSameMomentAs(localScheduledAt), isTrue);
        expect(intake.confirmedAt!.isUtc, isTrue);
        expect(intake.confirmedAt!.isAtSameMomentAs(localNow), isTrue);
      },
    );

    // -------------------------------------------------------------------------
    // 3. Repository failure passthrough — the use case's Left is unchanged.
    // -------------------------------------------------------------------------
    test(
      'should return the repository Left unchanged when repo.markTaken fails',
      () async {
        const repoFailure = CacheFailure('boom');
        when(
          () => repo.markTaken(any()),
        ).thenAnswer((_) async => const Left(repoFailure));

        final result = await useCase.call(
          medicationId: medicationId,
          slotId: slotId,
          scheduledAt: scheduledAt,
          now: now,
        );

        expect(result.isLeft(), isTrue);
        final failure = result.fold((f) => f, (_) => throw AssertionError());
        expect(failure, repoFailure);
        verify(() => repo.markTaken(any())).called(1);
      },
    );
  });
}
