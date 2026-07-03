/// Tests for [UndoIntake].
///
/// [UndoIntake] owns the grace-window rule (constitution §5.2): these tests
/// prove that within the window it delegates to [IntakeRepository.undo], that
/// beyond the window it refuses with a [Left] and never touches the repository,
/// and that the boundary (exactly [kIntakeUndoGracePeriod]) is inclusive.
library;

import 'package:dosly/core/error/failures.dart';
import 'package:dosly/features/meds/domain/repositories/intake_repository.dart';
import 'package:dosly/features/meds/domain/usecases/undo_intake.dart';
import 'package:dosly/features/meds/domain/value_objects/intake_grace.dart';
import 'package:dosly/features/meds/domain/value_objects/intake_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class _MockIntakeRepository extends Mock implements IntakeRepository {}

void main() {
  setUpAll(() {
    // mocktail requires a fallback value for every type matched with any().
    registerFallbackValue(const IntakeId('fallback'));
  });

  group('UndoIntake', () {
    late _MockIntakeRepository repo;
    late UndoIntake useCase;

    // Fixed UTC reference point so the arithmetic in each test is explicit.
    final now = DateTime.utc(2026, 1, 1, 12, 0, 0);

    setUp(() {
      repo = _MockIntakeRepository();
      useCase = UndoIntake(repo);
    });

    // -------------------------------------------------------------------------
    // 1. Within grace — the confirmation is 1 minute old (< 5 min), so the use
    //    case delegates to repo.undo and returns Right.
    // -------------------------------------------------------------------------
    test(
      'delegates to repo.undo and returns Right when within the grace period',
      () async {
        const id = IntakeId('intake-1');
        final confirmedAt = now.subtract(const Duration(minutes: 1));
        when(() => repo.undo(any())).thenAnswer((_) async => const Right(null));

        final result = await useCase.call(
          id: id,
          confirmedAt: confirmedAt,
          now: now,
        );

        expect(result.isRight(), isTrue);
        verify(() => repo.undo(id)).called(1);
      },
    );

    // -------------------------------------------------------------------------
    // 2. Boundary — exactly 5 minutes old is still allowed (inclusive `<=`):
    //    repo.undo is called and Right is returned.
    // -------------------------------------------------------------------------
    test(
      'allows undo at exactly the grace period boundary (inclusive)',
      () async {
        const id = IntakeId('intake-boundary');
        final confirmedAt = now.subtract(kIntakeUndoGracePeriod);
        when(() => repo.undo(any())).thenAnswer((_) async => const Right(null));

        final result = await useCase.call(
          id: id,
          confirmedAt: confirmedAt,
          now: now,
        );

        expect(result.isRight(), isTrue);
        verify(() => repo.undo(id)).called(1);
      },
    );

    // -------------------------------------------------------------------------
    // 3. Beyond grace — the confirmation is 5 min 1 s old (> 5 min): the use
    //    case refuses with a ValidationFailure and never touches the repository.
    // -------------------------------------------------------------------------
    test(
      'returns a ValidationFailure and never calls repo.undo beyond the grace '
      'period',
      () async {
        const id = IntakeId('intake-expired');
        final confirmedAt = now.subtract(
          kIntakeUndoGracePeriod + const Duration(seconds: 1),
        );

        final result = await useCase.call(
          id: id,
          confirmedAt: confirmedAt,
          now: now,
        );

        expect(result.isLeft(), isTrue);
        final failure = result.fold((f) => f, (_) => throw AssertionError());
        expect(failure, isA<ValidationFailure>());
        verifyNever(() => repo.undo(any()));
      },
    );
  });
}
