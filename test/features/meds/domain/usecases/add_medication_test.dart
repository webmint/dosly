library;

import 'package:clock/clock.dart';
import 'package:dosly/core/error/failures.dart';
import 'package:dosly/core/id/id_generator.dart';
import 'package:dosly/features/meds/domain/entities/dosage.dart';
import 'package:dosly/features/meds/domain/entities/dose_unit.dart';
import 'package:dosly/features/meds/domain/entities/medication.dart';
import 'package:dosly/features/meds/domain/entities/medication_form.dart';
import 'package:dosly/features/meds/domain/entities/medication_type.dart';
import 'package:dosly/features/meds/domain/entities/schedule.dart';
import 'package:dosly/features/meds/domain/repositories/medication_repository.dart';
import 'package:dosly/features/meds/domain/usecases/add_medication.dart';
import 'package:dosly/features/meds/domain/value_objects/medication_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class _MockMedicationRepository extends Mock implements MedicationRepository {}

/// Deterministic [IdGenerator] that returns 'id-1', 'id-2', … in order.
class _FakeIdGenerator implements IdGenerator {
  int _counter = 0;

  @override
  String newId() {
    _counter += 1;
    return 'id-$_counter';
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Fixed UTC instant used by all time-sensitive tests.
final _fixedNow = DateTime.utc(2026, 6, 17);
final _fixedClock = Clock.fixed(_fixedNow);

/// A valid continuous [MedicationType] anchored to the fixed clock date.
MedicationType get _continuousType =>
    MedicationType.continuous(startDate: _fixedNow);

void main() {
  setUpAll(() {
    // mocktail requires a fallback value for every type matched with any().
    registerFallbackValue(
      Medication(
        id: const MedicationId('fallback'),
        name: 'Fallback',
        form: MedicationForm.tablet,
        type: MedicationType.continuous(startDate: DateTime.utc(2026, 1, 1)),
        schedule: const Schedule(slots: []),
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
  });

  group('AddMedication', () {
    late _MockMedicationRepository repo;
    late _FakeIdGenerator idGen;
    late AddMedication useCase;

    setUp(() {
      repo = _MockMedicationRepository();
      idGen = _FakeIdGenerator();
      useCase = AddMedication(repo, idGen);
    });

    // -------------------------------------------------------------------------
    // 1. Empty / whitespace name → ValidationFailure(field: 'name')
    // -------------------------------------------------------------------------
    test(
      'should return ValidationFailure(field: name) when name is whitespace',
      () async {
        await withClock(_fixedClock, () async {
          final result = await useCase(
            name: '   ',
            form: MedicationForm.tablet,
            intakeMinutes: [480],
            type: _continuousType,
          );

          expect(result.isLeft(), isTrue);
          final failure = result.fold((f) => f, (_) => throw AssertionError());
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).field, 'name');
          verifyNever(() => repo.add(any()));
        });
      },
    );

    // -------------------------------------------------------------------------
    // 2. Empty intakeMinutes → ValidationFailure(field: 'times')
    // -------------------------------------------------------------------------
    test(
      'should return ValidationFailure(field: times) when intakeMinutes is empty',
      () async {
        await withClock(_fixedClock, () async {
          final result = await useCase(
            name: 'Aspirin',
            form: MedicationForm.tablet,
            intakeMinutes: [],
            type: _continuousType,
          );

          expect(result.isLeft(), isTrue);
          final failure = result.fold((f) => f, (_) => throw AssertionError());
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).field, 'times');
          verifyNever(() => repo.add(any()));
        });
      },
    );

    // -------------------------------------------------------------------------
    // 3. CourseType with durationDays == 0 → ValidationFailure(field: 'durationDays')
    // -------------------------------------------------------------------------
    test(
      'should return ValidationFailure(field: durationDays) when course durationDays is 0',
      () async {
        await withClock(_fixedClock, () async {
          final result = await useCase(
            name: 'Aspirin',
            form: MedicationForm.tablet,
            intakeMinutes: [480],
            type: MedicationType.course(
              startDate: _fixedNow,
              durationDays: 0,
              pauseDays: 0,
            ),
          );

          expect(result.isLeft(), isTrue);
          final failure = result.fold((f) => f, (_) => throw AssertionError());
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).field, 'durationDays');
          verifyNever(() => repo.add(any()));
        });
      },
    );

    // -------------------------------------------------------------------------
    // 4. Valid continuous input → persists Medication with correct fields
    // -------------------------------------------------------------------------
    test(
      'should call repo.add once and return Right with the persisted medication '
      'on valid continuous input',
      () async {
        await withClock(_fixedClock, () async {
          when(
            () => repo.add(any()),
          ).thenAnswer((inv) async {
            final med = inv.positionalArguments.first as Medication;
            return Right(med);
          });

          final result = await useCase(
            name: '  Aspirin  ',
            form: MedicationForm.tablet,
            intakeMinutes: [480, 960], // 08:00 and 16:00
            type: _continuousType,
          );

          // Repository must have been called exactly once.
          final captured = verify(() => repo.add(captureAny())).captured;
          expect(captured.length, 1);

          final med = captured.single as Medication;

          // Name trimmed.
          expect(med.name, 'Aspirin');

          // createdAt equals the fixed clock instant.
          expect(med.createdAt, _fixedNow);

          // IDs come from the fake generator in call order:
          // slot id-1, slot id-2, medication id-3.
          expect(med.schedule.slots.length, 2);
          expect(med.schedule.slots[0].id.value, 'id-1');
          expect(med.schedule.slots[0].minuteOfDay, 480);
          expect(med.schedule.slots[1].id.value, 'id-2');
          expect(med.schedule.slots[1].minuteOfDay, 960);
          expect(med.id.value, 'id-3');

          // Result is Right.
          expect(result.isRight(), isTrue);
        });
      },
    );

    // -------------------------------------------------------------------------
    // 5. Zero dose amount → ValidationFailure(field: 'dose'), repo never called
    // -------------------------------------------------------------------------
    test(
      'should return ValidationFailure(field: dose) when dosePerIntake.amount is zero',
      () async {
        await withClock(_fixedClock, () async {
          final result = await useCase(
            name: 'Amoxicillin Syrup',
            form: MedicationForm.syrup,
            intakeMinutes: [720],
            type: _continuousType,
            dosePerIntake: const Dosage(amount: 0, unit: DoseUnit.ml),
          );

          expect(result.isLeft(), isTrue);
          final failure = result.fold((f) => f, (_) => throw AssertionError());
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).field, 'dose');
          verifyNever(() => repo.add(any()));
        });
      },
    );

    // -------------------------------------------------------------------------
    // 6. Negative dose amount → ValidationFailure(field: 'dose'), repo never called
    // -------------------------------------------------------------------------
    test(
      'should return ValidationFailure(field: dose) when dosePerIntake.amount is negative',
      () async {
        await withClock(_fixedClock, () async {
          final result = await useCase(
            name: 'Amoxicillin Syrup',
            form: MedicationForm.syrup,
            intakeMinutes: [720],
            type: _continuousType,
            dosePerIntake: const Dosage(amount: -5, unit: DoseUnit.ml),
          );

          expect(result.isLeft(), isTrue);
          final failure = result.fold((f) => f, (_) => throw AssertionError());
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).field, 'dose');
          verifyNever(() => repo.add(any()));
        });
      },
    );

    // -------------------------------------------------------------------------
    // 7. Repository failure passthrough → use case returns the same Left
    //    (was test 5 before dose-validation tests were added above)
    // -------------------------------------------------------------------------
    test(
      'should return the repository Left unchanged when repo.add fails',
      () async {
        await withClock(_fixedClock, () async {
          const repoFailure = CacheFailure('boom');
          when(
            () => repo.add(any()),
          ).thenAnswer((_) async => const Left(repoFailure));

          final result = await useCase(
            name: 'Aspirin',
            form: MedicationForm.tablet,
            intakeMinutes: [480],
            type: _continuousType,
          );

          expect(result.isLeft(), isTrue);
          final failure = result.fold((f) => f, (_) => throw AssertionError());
          expect(failure, repoFailure);
          verify(() => repo.add(any())).called(1);
        });
      },
    );
  });
}

