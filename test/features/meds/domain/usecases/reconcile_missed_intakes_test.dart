/// Tests for [ReconcileMissedIntakes] — the write-side orchestration of the
/// auto-miss engine.
///
/// [ReconcileMissedIntakes] reads the intake window from settings, snapshots
/// medications and intakes via `watchAll().first`, runs the pure
/// [findAutoMissDoses] derivation, and persists one `missed` [Intake] per
/// eligible occurrence via [IntakeRepository.markMissed]. Every test injects a
/// FIXED `now` (never `DateTime.now()`) so window/local-day arithmetic is
/// deterministic in any timezone. Covers:
///   - writes one `missed` (status `missed`, `confirmedAt == null`) per eligible
///     occurrence and returns `Right(count)`, honouring the settings window,
///     each with a fresh, distinct id minted by the injected `IdGenerator`;
///   - idempotency / never-clobber: an occurrence that already has a stored
///     `taken`/`skipped`/`missed` row is NEVER written again (`verifyNever`);
///   - an empty medications list yields `Right(0)` and never calls
///     `markMissed` (AC-11 no-meds clause), proven through the full pipeline;
///   - a medications snapshot `Left` short-circuits (returns the `Left`, no
///     writes);
///   - an intakes snapshot `Left` short-circuits likewise;
///   - a settings `load()` `Left` falls back to [IntakeWindow.defaultValue]
///     (120 min) and STILL reconciles (resilience);
///   - a `markMissed` `Left` fails fast (returns that `Left`, stops the loop).
library;

import 'package:dosly/core/error/failures.dart';
import 'package:dosly/core/id/id_generator.dart';
import 'package:dosly/features/meds/domain/entities/dosage.dart';
import 'package:dosly/features/meds/domain/entities/dose_unit.dart';
import 'package:dosly/features/meds/domain/entities/intake.dart';
import 'package:dosly/features/meds/domain/entities/intake_status.dart';
import 'package:dosly/features/meds/domain/entities/medication.dart';
import 'package:dosly/features/meds/domain/entities/medication_form.dart';
import 'package:dosly/features/meds/domain/entities/medication_type.dart';
import 'package:dosly/features/meds/domain/entities/schedule.dart';
import 'package:dosly/features/meds/domain/entities/time_slot.dart';
import 'package:dosly/features/meds/domain/repositories/intake_repository.dart';
import 'package:dosly/features/meds/domain/repositories/medication_repository.dart';
import 'package:dosly/features/meds/domain/usecases/reconcile_missed_intakes.dart';
import 'package:dosly/features/meds/domain/value_objects/intake_id.dart';
import 'package:dosly/features/meds/domain/value_objects/medication_id.dart';
import 'package:dosly/features/meds/domain/value_objects/time_slot_id.dart';
import 'package:dosly/features/settings/domain/entities/app_settings.dart';
import 'package:dosly/features/settings/domain/repositories/settings_repository.dart';
import 'package:dosly/features/settings/domain/value_objects/intake_window.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class _MockMedicationRepository extends Mock implements MedicationRepository {}

class _MockIntakeRepository extends Mock implements IntakeRepository {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

/// Deterministic [IdGenerator] returning 'miss-id-1', 'miss-id-2', … in order —
/// mirrors mark_intake_taken_test.dart's `_FakeIdGenerator`.
class _FakeIdGenerator implements IdGenerator {
  int _counter = 0;

  @override
  String newId() {
    _counter += 1;
    return 'miss-id-$_counter';
  }
}

// ---------------------------------------------------------------------------
// Minimal fixture builders (mirror missed_intake_reconciliation_test.dart)
// ---------------------------------------------------------------------------

/// Fixed creation timestamp required by the [Medication] constructor; irrelevant
/// to the derivation.
final DateTime _createdAt = DateTime(2026, 1, 1);

/// A stub default dose so [DueDose.effectiveDose] has a non-null baseline.
const Dosage _defaultDose = Dosage(amount: 1, unit: DoseUnit.tablet);

/// Builds a [TimeSlot] at [minuteOfDay] with a stable [id].
TimeSlot _slot(int minuteOfDay, {String id = 'slot'}) =>
    TimeSlot(id: TimeSlotId(id), minuteOfDay: minuteOfDay);

/// Builds a continuous [Medication] (unconditionally due from [startDate]).
Medication _med({
  required List<TimeSlot> slots,
  required DateTime startDate,
  String id = 'test-med',
  String name = 'Test Medication',
}) => Medication(
  id: MedicationId(id),
  name: name,
  form: MedicationForm.tablet,
  type: MedicationType.continuous(startDate: startDate),
  schedule: Schedule(slots: slots),
  dosePerIntake: _defaultDose,
  createdAt: _createdAt,
);

/// Builds an [Intake] for [medicationId]/[slotId] due at [scheduledAt] with the
/// given [status].
Intake _intake({
  required String medicationId,
  required String slotId,
  required DateTime scheduledAt,
  required IntakeStatus status,
  String id = 'intake',
}) => Intake(
  id: IntakeId(id),
  medicationId: MedicationId(medicationId),
  slotId: TimeSlotId(slotId),
  scheduledAt: scheduledAt,
  status: status,
);

void main() {
  setUpAll(() {
    // mocktail requires a fallback value for every type matched with any().
    registerFallbackValue(
      Intake(
        id: const IntakeId('fallback'),
        medicationId: const MedicationId('fallback-med'),
        slotId: const TimeSlotId('fallback-slot'),
        scheduledAt: DateTime.utc(2026, 1, 1),
        status: IntakeStatus.missed,
      ),
    );
  });

  group('ReconcileMissedIntakes', () {
    late _MockMedicationRepository medRepo;
    late _MockIntakeRepository intakeRepo;
    late _MockSettingsRepository settingsRepo;
    late _FakeIdGenerator idGen;
    late ReconcileMissedIntakes useCase;

    // Continuous med active well before any test's `now`.
    final DateTime start = DateTime(2026, 6, 1);

    /// Stubs the medications snapshot with a `Right(meds)` stream.
    void stubMeds(List<Medication> meds) {
      when(() => medRepo.watchAll()).thenAnswer(
        (_) =>
            Stream<Either<Failure, List<Medication>>>.value(Right(meds)),
      );
    }

    /// Stubs the intakes snapshot with a `Right(intakes)` stream.
    void stubIntakes(List<Intake> intakes) {
      when(() => intakeRepo.watchAll()).thenAnswer(
        (_) =>
            Stream<Either<Failure, List<Intake>>>.value(Right(intakes)),
      );
    }

    setUp(() {
      medRepo = _MockMedicationRepository();
      intakeRepo = _MockIntakeRepository();
      settingsRepo = _MockSettingsRepository();
      idGen = _FakeIdGenerator();
      useCase = ReconcileMissedIntakes(
        medRepo,
        intakeRepo,
        settingsRepo,
        idGen,
      );

      // Defaults: settings readable with the default window; no stored intakes;
      // markMissed echoes the intake back. Individual tests override as needed.
      when(
        () => settingsRepo.load(),
      ).thenReturn(const Right<Failure, AppSettings>(AppSettings()));
      stubIntakes(<Intake>[]);
      when(() => intakeRepo.markMissed(any())).thenAnswer(
        (inv) async =>
            Right<Failure, Intake>(inv.positionalArguments.first as Intake),
      );
    });

    // -------------------------------------------------------------------------
    // 1. Writes one `missed` per eligible occurrence, honouring the settings
    //    window, and returns Right(count).
    // -------------------------------------------------------------------------
    test('writes one missed Intake per eligible occurrence and returns the '
        'count, using the settings window', () async {
      // A 30-minute window: 08:00 closes 08:30, 08:15 closes 08:45. At 09:00
      // both are strictly past — but only because the SETTINGS window (30) is
      // honoured; under the default 120 neither would yet be eligible.
      when(() => settingsRepo.load()).thenReturn(
        Right(AppSettings(intakeWindow: IntakeWindow(30))),
      );
      stubMeds(<Medication>[
        _med(
          slots: <TimeSlot>[
            _slot(480, id: 'morning'), // 08:00
            _slot(495, id: 'quarter'), // 08:15
          ],
          startDate: start,
        ),
      ]);
      final DateTime now = DateTime(2026, 6, 4, 9);

      final result = await useCase.call(now: now);

      expect(result.isRight(), isTrue);
      final count = result.fold((_) => throw AssertionError(), (c) => c);
      expect(count, 2);

      final captured =
          verify(() => intakeRepo.markMissed(captureAny())).captured;
      expect(captured.length, 2);
      final intakes = captured.map((e) => e as Intake).toList();

      // Every written intake is `missed` with no confirmation stamp.
      for (final intake in intakes) {
        expect(intake.status, IntakeStatus.missed);
        expect(intake.confirmedAt, isNull);
        expect(intake.medicationId, const MedicationId('test-med'));
        expect(intake.notes, isNull);
      }
      expect(
        intakes.map((i) => i.slotId).toSet(),
        <TimeSlotId>{const TimeSlotId('morning'), const TimeSlotId('quarter')},
      );

      // Each written intake carries a freshly minted id from the injected
      // IdGenerator, and the two ids are distinct — proves ids are not left
      // null/default/reused across occurrences.
      final Intake morningIntake = intakes.firstWhere(
        (i) => i.slotId == const TimeSlotId('morning'),
      );
      final Intake quarterIntake = intakes.firstWhere(
        (i) => i.slotId == const TimeSlotId('quarter'),
      );
      expect(morningIntake.id, const IntakeId('miss-id-1'));
      expect(quarterIntake.id, const IntakeId('miss-id-2'));
    });

    // -------------------------------------------------------------------------
    // 2. Idempotency / never-clobber: an occurrence with an existing row is
    //    never re-written, regardless of that row's status.
    // -------------------------------------------------------------------------
    for (final IntakeStatus status in <IntakeStatus>[
      IntakeStatus.taken,
      IntakeStatus.skipped,
      IntakeStatus.missed,
    ]) {
      test('never calls markMissed for a past-window occurrence that already '
          'has a stored ${status.name} row', () async {
        // 08:00 dose, default window closes 10:00; at 12:00 it is past-window,
        // so only the existing row keeps it out of the eligible set.
        stubMeds(<Medication>[
          _med(
            slots: <TimeSlot>[_slot(480, id: 'morning')],
            startDate: start,
          ),
        ]);
        stubIntakes(<Intake>[
          _intake(
            medicationId: 'test-med',
            slotId: 'morning',
            scheduledAt: DateTime(2026, 6, 4, 7),
            status: status,
          ),
        ]);
        final DateTime now = DateTime(2026, 6, 4, 12);

        final result = await useCase.call(now: now);

        expect(result.isRight(), isTrue);
        expect(result.fold((_) => throw AssertionError(), (c) => c), 0);
        verifyNever(() => intakeRepo.markMissed(any()));
      });
    }

    // -------------------------------------------------------------------------
    // 3. Medications snapshot Left → short-circuit, no writes.
    // -------------------------------------------------------------------------
    test('returns the medications Left unchanged and never writes', () async {
      const failure = CacheFailure('meds boom');
      when(() => medRepo.watchAll()).thenAnswer(
        (_) => Stream<Either<Failure, List<Medication>>>.value(
          const Left(failure),
        ),
      );

      final result = await useCase.call(now: DateTime(2026, 6, 4, 12));

      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f, (_) => throw AssertionError()), failure);
      verifyNever(() => intakeRepo.markMissed(any()));
    });

    // -------------------------------------------------------------------------
    // 4. Intakes snapshot Left → short-circuit, no writes.
    // -------------------------------------------------------------------------
    test('returns the intakes Left unchanged and never writes', () async {
      const failure = CacheFailure('intakes boom');
      stubMeds(<Medication>[
        _med(slots: <TimeSlot>[_slot(480, id: 'morning')], startDate: start),
      ]);
      when(() => intakeRepo.watchAll()).thenAnswer(
        (_) => Stream<Either<Failure, List<Intake>>>.value(
          const Left(failure),
        ),
      );

      final result = await useCase.call(now: DateTime(2026, 6, 4, 12));

      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f, (_) => throw AssertionError()), failure);
      verifyNever(() => intakeRepo.markMissed(any()));
    });

    // -------------------------------------------------------------------------
    // 5. Settings load() Left → falls back to the default window and STILL
    //    reconciles (resilience: a settings failure never blocks the engine).
    // -------------------------------------------------------------------------
    test('falls back to the default 120-minute window when settings load '
        'fails and still reconciles', () async {
      when(() => settingsRepo.load()).thenReturn(
        const Left(CacheFailure('no settings')),
      );
      stubMeds(<Medication>[
        _med(slots: <TimeSlot>[_slot(480, id: 'morning')], startDate: start),
      ]);
      // 08:00 + default 120 min closes 10:00; at 11:00 it is past-window.
      final DateTime now = DateTime(2026, 6, 4, 11);

      final result = await useCase.call(now: now);

      expect(result.isRight(), isTrue);
      expect(result.fold((_) => throw AssertionError(), (c) => c), 1);

      final captured =
          verify(() => intakeRepo.markMissed(captureAny())).captured;
      expect(captured.length, 1);
      final intake = captured.single as Intake;
      expect(intake.status, IntakeStatus.missed);
      expect(intake.confirmedAt, isNull);
      expect(intake.slotId, const TimeSlotId('morning'));
    });

    // -------------------------------------------------------------------------
    // 6. markMissed Left → fail-fast (returns that Left, stops the loop).
    // -------------------------------------------------------------------------
    test('returns the first markMissed Left and stops writing (fail-fast)',
        () async {
      const failure = CacheFailure('write boom');
      // Two eligible occurrences at 12:00 (windows close 10:00 and 11:00).
      stubMeds(<Medication>[
        _med(
          slots: <TimeSlot>[
            _slot(480, id: 'morning'), // 08:00
            _slot(540, id: 'mid'), // 09:00
          ],
          startDate: start,
        ),
      ]);
      when(() => intakeRepo.markMissed(any())).thenAnswer(
        (_) async => const Left<Failure, Intake>(failure),
      );

      final result = await useCase.call(now: DateTime(2026, 6, 4, 12));

      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f, (_) => throw AssertionError()), failure);
      // Fail-fast: the loop stopped after the first failing write.
      verify(() => intakeRepo.markMissed(any())).called(1);
    });

    // -------------------------------------------------------------------------
    // 7. No tracked medications (AC-11 no-meds clause): the pipeline still
    //    reads settings and snapshots, derives an empty eligible set, and
    //    returns Right(0) without ever writing.
    // -------------------------------------------------------------------------
    test('returns Right(0) and never calls markMissed when there are no '
        'tracked medications', () async {
      stubMeds(<Medication>[]);

      final result = await useCase.call(now: DateTime(2026, 6, 4, 12));

      expect(result.isRight(), isTrue);
      expect(result.fold((_) => throw AssertionError(), (c) => c), 0);
      verifyNever(() => intakeRepo.markMissed(any()));
    });
  });
}
