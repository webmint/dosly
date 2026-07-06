/// Tests for [UndoIntake].
///
/// [UndoIntake] owns the grace-window rule (constitution §5.2), but the window
/// itself is supplied by the caller (the use case stays settings-agnostic):
/// these tests prove that within the supplied `gracePeriod` it delegates to
/// [IntakeRepository.undo], that beyond it the action is refused with a [Left]
/// and the repository is never touched, that the boundary (exactly the period)
/// is inclusive, and that a non-default period is honored.
library;

import 'package:dosly/core/error/failures.dart';
import 'package:dosly/features/meds/domain/repositories/intake_repository.dart';
import 'package:dosly/features/meds/domain/usecases/undo_intake.dart';
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

    // The default grace window (the app's historical constant), passed
    // explicitly now that the use case is settings-agnostic.
    const gracePeriod = Duration(minutes: 5);

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
          gracePeriod: gracePeriod,
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
        final confirmedAt = now.subtract(gracePeriod);
        when(() => repo.undo(any())).thenAnswer((_) async => const Right(null));

        final result = await useCase.call(
          id: id,
          confirmedAt: confirmedAt,
          now: now,
          gracePeriod: gracePeriod,
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
          gracePeriod + const Duration(seconds: 1),
        );

        final result = await useCase.call(
          id: id,
          confirmedAt: confirmedAt,
          now: now,
          gracePeriod: gracePeriod,
        );

        expect(result.isLeft(), isTrue);
        final failure = result.fold((f) => f, (_) => throw AssertionError());
        expect(failure, isA<ValidationFailure>());
        verifyNever(() => repo.undo(any()));
      },
    );

    // -------------------------------------------------------------------------
    // 4. Zero-length window — with gracePeriod: Duration.zero even a 1-second-old
    //    confirmation is beyond the window, so the use case refuses with a
    //    ValidationFailure and never touches the repository. Proves the supplied
    //    period (not a hardcoded constant) drives the rule.
    // -------------------------------------------------------------------------
    test(
      'refuses a 1-second-old confirmation when gracePeriod is Duration.zero',
      () async {
        const id = IntakeId('intake-zero-window');
        final confirmedAt = now.subtract(const Duration(seconds: 1));

        final result = await useCase.call(
          id: id,
          confirmedAt: confirmedAt,
          now: now,
          gracePeriod: Duration.zero,
        );

        expect(result.isLeft(), isTrue);
        final failure = result.fold((f) => f, (_) => throw AssertionError());
        expect(failure, isA<ValidationFailure>());
        verifyNever(() => repo.undo(any()));
      },
    );

    // -------------------------------------------------------------------------
    // 5. Wider window — with gracePeriod: 30 min a 20-minute-old confirmation is
    //    still within the window (it would be refused under the 5-min default),
    //    so the use case delegates to repo.undo and returns Right.
    // -------------------------------------------------------------------------
    test(
      'allows a 20-minute-old confirmation when gracePeriod is 30 minutes',
      () async {
        const id = IntakeId('intake-wide-window');
        final confirmedAt = now.subtract(const Duration(minutes: 20));
        when(() => repo.undo(any())).thenAnswer((_) async => const Right(null));

        final result = await useCase.call(
          id: id,
          confirmedAt: confirmedAt,
          now: now,
          gracePeriod: const Duration(minutes: 30),
        );

        expect(result.isRight(), isTrue);
        verify(() => repo.undo(id)).called(1);
      },
    );
  });
}
