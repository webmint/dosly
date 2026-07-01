/// Tests for [DeleteMedication].
///
/// [DeleteMedication] is a pure pass-through to [MedicationRepository.delete]:
/// it performs no validation, so these tests only prove forwarding and
/// Right/Left propagation.
library;

import 'package:dosly/core/error/failures.dart';
import 'package:dosly/features/meds/domain/repositories/medication_repository.dart';
import 'package:dosly/features/meds/domain/usecases/delete_medication.dart';
import 'package:dosly/features/meds/domain/value_objects/medication_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class _MockMedicationRepository extends Mock implements MedicationRepository {}

void main() {
  setUpAll(() {
    // mocktail requires a fallback value for every type matched with any().
    registerFallbackValue(const MedicationId('fallback'));
  });

  group('DeleteMedication', () {
    late _MockMedicationRepository repo;
    late DeleteMedication useCase;

    setUp(() {
      repo = _MockMedicationRepository();
      useCase = DeleteMedication(repo);
    });

    // -------------------------------------------------------------------------
    // 1. Forwarding — the use case calls repo.delete with the exact id and
    //    returns Right when the repository succeeds.
    // -------------------------------------------------------------------------
    test(
      'should call repo.delete with the given id and return Right on success',
      () async {
        const id = MedicationId('med-1');
        when(() => repo.delete(any())).thenAnswer((_) async => const Right(null));

        final result = await useCase.call(id);

        expect(result.isRight(), isTrue);
        verify(() => repo.delete(id)).called(1);
      },
    );

    // -------------------------------------------------------------------------
    // 2. Failure propagation — a Left returned by the repository is returned
    //    unchanged by the use case.
    // -------------------------------------------------------------------------
    test(
      'should return the repository Left unchanged when repo.delete fails',
      () async {
        const id = MedicationId('med-2');
        const repoFailure = CacheFailure('boom');
        when(() => repo.delete(any())).thenAnswer((_) async => const Left(repoFailure));

        final result = await useCase.call(id);

        expect(result.isLeft(), isTrue);
        final failure = result.fold((f) => f, (_) => throw AssertionError());
        expect(failure, repoFailure);
        verify(() => repo.delete(id)).called(1);
      },
    );
  });
}
