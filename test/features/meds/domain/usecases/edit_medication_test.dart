library;

import 'package:dosly/core/error/failures.dart';
import 'package:dosly/core/id/id_generator.dart';
import 'package:dosly/features/meds/domain/entities/dosage.dart';
import 'package:dosly/features/meds/domain/entities/dose_unit.dart';
import 'package:dosly/features/meds/domain/entities/medication.dart';
import 'package:dosly/features/meds/domain/entities/medication_form.dart';
import 'package:dosly/features/meds/domain/entities/medication_type.dart';
import 'package:dosly/features/meds/domain/entities/schedule.dart';
import 'package:dosly/features/meds/domain/entities/time_slot.dart';
import 'package:dosly/features/meds/domain/repositories/medication_repository.dart';
import 'package:dosly/features/meds/domain/usecases/edit_medication.dart';
import 'package:dosly/features/meds/domain/value_objects/medication_id.dart';
import 'package:dosly/features/meds/domain/value_objects/time_slot_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class _MockMedicationRepository extends Mock implements MedicationRepository {}

/// Deterministic [IdGenerator] that returns 'new-id-1', 'new-id-2', … in order.
class _FakeIdGenerator implements IdGenerator {
  int _counter = 0;

  @override
  String newId() {
    _counter += 1;
    return 'new-id-$_counter';
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Fixed UTC instant used for all time-sensitive tests.
final _fixedNow = DateTime.utc(2026, 6, 17);

/// A valid continuous [MedicationType] anchored to the fixed date.
MedicationType get _continuousType =>
    MedicationType.continuous(startDate: _fixedNow);

/// Builds a minimal valid [Medication] with two slots at minute 480 and 1200.
///
/// Slot at minute 480 carries id 'slot-a'.
/// Slot at minute 1200 carries id 'slot-b'.
Medication _buildOriginalWithTwoSlots() {
  return Medication(
    id: const MedicationId('original-med-id'),
    name: 'Aspirin',
    form: MedicationForm.tablet,
    type: _continuousType,
    schedule: const Schedule(
      slots: [
        TimeSlot(id: TimeSlotId('slot-a'), minuteOfDay: 480),
        TimeSlot(id: TimeSlotId('slot-b'), minuteOfDay: 1200),
      ],
    ),
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

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

  group('EditMedication', () {
    late _MockMedicationRepository repo;
    late _FakeIdGenerator idGen;
    late EditMedication useCase;

    setUp(() {
      repo = _MockMedicationRepository();
      idGen = _FakeIdGenerator();
      useCase = EditMedication(repo, idGen);
    });

    // -------------------------------------------------------------------------
    // 1. Preserves original id and createdAt
    // -------------------------------------------------------------------------
    test(
      'should preserve original id and createdAt on successful update',
      () async {
        final original = _buildOriginalWithTwoSlots();

        when(
          () => repo.update(any()),
        ).thenAnswer((inv) async {
          if (inv.positionalArguments.first case final Medication med) {
            return Right(med);
          }
          throw ArgumentError('Expected a Medication argument');
        });

        final result = await useCase(
          original: original,
          name: 'New name',
          form: MedicationForm.tablet,
          intakeMinutes: [480],
          type: _continuousType,
        );

        expect(result.isRight(), isTrue);

        // captureAny() acts as both a verify and capture — hasLength(1) proves
        // the repo was called exactly once.
        final captured = verify(() => repo.update(captureAny())).captured;
        expect(captured, hasLength(1));
        expect(captured.single, isA<Medication>());
        if (captured.single is! Medication) fail('expected a Medication');
        final updated = captured.single as Medication;
        expect(updated.id, original.id);
        expect(updated.createdAt, original.createdAt);
      },
    );

    // -------------------------------------------------------------------------
    // 2. Slot-ID reconciliation: keep / add / remove
    // -------------------------------------------------------------------------
    test(
      'should preserve unchanged slot ids, mint new ids for new minutes, '
      'and drop removed minutes',
      () async {
        // original: slot-a @ 480, slot-b @ 1200
        final original = _buildOriginalWithTwoSlots();

        when(
          () => repo.update(any()),
        ).thenAnswer((inv) async {
          if (inv.positionalArguments.first case final Medication med) {
            return Right(med);
          }
          throw ArgumentError('Expected a Medication argument');
        });

        // keep 480 (slot-a), drop 1200 (slot-b), add 600 (should get new id)
        final result = await useCase(
          original: original,
          name: 'Aspirin',
          form: MedicationForm.tablet,
          intakeMinutes: [480, 600],
          type: _continuousType,
        );

        expect(result.isRight(), isTrue);

        // captureAny() acts as both a verify and capture — hasLength(1) proves
        // the repo was called exactly once.
        final captured = verify(() => repo.update(captureAny())).captured;
        expect(captured, hasLength(1));
        expect(captured.single, isA<Medication>());
        if (captured.single is! Medication) fail('expected a Medication');
        final updated = captured.single as Medication;
        final slots = updated.schedule.slots;

        // Exactly two slots total.
        expect(slots.length, 2);

        // Slot at minute 480 must keep the original TimeSlotId('slot-a').
        final slot480 = slots.firstWhere((s) => s.minuteOfDay == 480);
        expect(slot480.id, const TimeSlotId('slot-a'));

        // Slot at minute 600 must have the freshly minted id from the fake generator.
        final slot600 = slots.firstWhere((s) => s.minuteOfDay == 600);
        expect(slot600.id, const TimeSlotId('new-id-1'));

        // Slot at minute 1200 must be gone.
        expect(slots.any((s) => s.minuteOfDay == 1200), isFalse);
      },
    );

    // -------------------------------------------------------------------------
    // 3. Validation: empty / whitespace name
    // -------------------------------------------------------------------------
    test(
      'should return ValidationFailure(field: name) when name is whitespace '
      'and never call repo.update',
      () async {
        final original = _buildOriginalWithTwoSlots();

        final result = await useCase(
          original: original,
          name: '   ',
          form: MedicationForm.tablet,
          intakeMinutes: [480],
          type: _continuousType,
        );

        expect(result.isLeft(), isTrue);
        final failure = result.fold((f) => f, (_) => throw AssertionError());
        expect(failure, isA<ValidationFailure>());
        expect((failure as ValidationFailure).field, 'name');
        verifyNever(() => repo.update(any()));
      },
    );

    // -------------------------------------------------------------------------
    // 4. Validation: no intake times
    // -------------------------------------------------------------------------
    test(
      'should return ValidationFailure(field: times) when intakeMinutes is empty '
      'and never call repo.update',
      () async {
        final original = _buildOriginalWithTwoSlots();

        final result = await useCase(
          original: original,
          name: 'Aspirin',
          form: MedicationForm.tablet,
          intakeMinutes: [],
          type: _continuousType,
        );

        expect(result.isLeft(), isTrue);
        final failure = result.fold((f) => f, (_) => throw AssertionError());
        expect(failure, isA<ValidationFailure>());
        expect((failure as ValidationFailure).field, 'times');
        verifyNever(() => repo.update(any()));
      },
    );

    // -------------------------------------------------------------------------
    // 5. Validation: course durationDays < 1
    // -------------------------------------------------------------------------
    test(
      'should return ValidationFailure(field: durationDays) when course '
      'durationDays is 0 and never call repo.update',
      () async {
        final original = _buildOriginalWithTwoSlots();

        final result = await useCase(
          original: original,
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
        verifyNever(() => repo.update(any()));
      },
    );

    // -------------------------------------------------------------------------
    // 6. Validation: dose amount <= 0
    // -------------------------------------------------------------------------
    test(
      'should return ValidationFailure(field: dose) when dosePerIntake.amount '
      'is zero and never call repo.update',
      () async {
        final original = _buildOriginalWithTwoSlots();

        final result = await useCase(
          original: original,
          name: 'Aspirin',
          form: MedicationForm.syrup,
          intakeMinutes: [480],
          type: _continuousType,
          dosePerIntake: const Dosage(amount: 0, unit: DoseUnit.ml),
        );

        expect(result.isLeft(), isTrue);
        final failure = result.fold((f) => f, (_) => throw AssertionError());
        expect(failure, isA<ValidationFailure>());
        expect((failure as ValidationFailure).field, 'dose');
        verifyNever(() => repo.update(any()));
      },
    );

    // -------------------------------------------------------------------------
    // 7. Repository failure passthrough
    // -------------------------------------------------------------------------
    test(
      'should return the repository Left unchanged when repo.update fails',
      () async {
        final original = _buildOriginalWithTwoSlots();
        final repoFailure = Failure.unknown(
          Exception('db error'),
          StackTrace.empty,
        );

        when(
          () => repo.update(any()),
        ).thenAnswer((_) async => Left(repoFailure));

        final result = await useCase(
          original: original,
          name: 'Aspirin',
          form: MedicationForm.tablet,
          intakeMinutes: [480],
          type: _continuousType,
        );

        expect(result.isLeft(), isTrue);
        final failure = result.fold((f) => f, (_) => throw AssertionError());
        expect(failure, repoFailure);
        verify(() => repo.update(any())).called(1);
      },
    );
  });
}
