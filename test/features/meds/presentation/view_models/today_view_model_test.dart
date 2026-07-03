/// Tests for [buildTodayView] — the pure shaping function that combines the
/// day's expanded due doses with the stored intakes into the render-ready Today
/// list, deriving each dose's status and its `undoable` grace flag.
///
/// Covers, with an explicit injected `now` (never the wall clock):
///   - unmatched dose: no intake → `pending`, not undoable.
///   - matched `taken` intake (same med+slot+local date) → `taken`, with
///     `undoable` true inside the 5-minute grace window and false past it.
///   - matched `skipped` intake → `skipped`, same undoable logic.
///   - local-date matching: an intake stored earlier the SAME local day (a
///     different instant) still matches.
///   - ordering: entries preserve the ascending minuteOfDay order.
///   - AC-10: every due dose appears whether its slot time is past or future
///     relative to `now`.
///   - empty: [TodayView.isEmpty] is true when nothing is due.
///
/// Fixtures are built in-test via the private helpers so no drift or uuid
/// dependency is pulled into the presentation tests.
library;

import 'package:dosly/features/meds/domain/entities/dosage.dart';
import 'package:dosly/features/meds/domain/entities/dose_unit.dart';
import 'package:dosly/features/meds/domain/entities/intake.dart';
import 'package:dosly/features/meds/domain/entities/intake_status.dart';
import 'package:dosly/features/meds/domain/entities/medication.dart';
import 'package:dosly/features/meds/domain/entities/medication_form.dart';
import 'package:dosly/features/meds/domain/entities/medication_type.dart';
import 'package:dosly/features/meds/domain/entities/schedule.dart';
import 'package:dosly/features/meds/domain/entities/time_slot.dart';
import 'package:dosly/features/meds/domain/value_objects/intake_grace.dart';
import 'package:dosly/features/meds/domain/value_objects/intake_id.dart';
import 'package:dosly/features/meds/domain/value_objects/medication_id.dart';
import 'package:dosly/features/meds/domain/value_objects/time_slot_id.dart';
import 'package:dosly/features/meds/presentation/view_models/today_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Minimal fixture builders
// ---------------------------------------------------------------------------

/// Fixed creation timestamp used by all fixtures — irrelevant to shaping but
/// required by the [Medication] constructor.
final DateTime _createdAt = DateTime(2026, 1, 1);

/// A stub default dose so [DueDose.effectiveDose] has a non-null baseline.
const Dosage _defaultDose = Dosage(amount: 1, unit: DoseUnit.tablet);

/// Builds a [TimeSlot] at [minuteOfDay] with a stable [id].
TimeSlot _slot(int minuteOfDay, {String id = 'slot'}) =>
    TimeSlot(id: TimeSlotId(id), minuteOfDay: minuteOfDay);

/// Builds a continuous [Medication] starting at [startDate] with the given
/// [slots], [id] and [name]. Continuous keeps the fixtures unconditionally due.
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
/// given [status] and optional [confirmedAt].
Intake _intake({
  required String medicationId,
  required String slotId,
  required DateTime scheduledAt,
  required IntakeStatus status,
  DateTime? confirmedAt,
  String id = 'intake',
}) => Intake(
  id: IntakeId(id),
  medicationId: MedicationId(medicationId),
  slotId: TimeSlotId(slotId),
  scheduledAt: scheduledAt,
  confirmedAt: confirmedAt,
  status: status,
);

void main() {
  // Anchor in June to avoid DST transitions that would skew local-day diffs.
  final DateTime start = DateTime(2026, 6, 1);

  group('buildTodayView', () {
    // -----------------------------------------------------------------------
    // Unmatched dose → pending
    // -----------------------------------------------------------------------
    test('unmatched due dose is pending and not undoable', () {
      final DateTime now = DateTime(2026, 6, 4, 9);
      final Medication med = _med(
        slots: <TimeSlot>[_slot(480, id: 'morning')],
        startDate: start,
      );

      final TodayView view = buildTodayView(
        meds: <Medication>[med],
        intakes: <Intake>[],
        now: now,
      );

      expect(view.doses, hasLength(1));
      expect(view.doses.single.status, IntakeStatus.pending);
      expect(view.doses.single.confirmedAt, isNull);
      expect(view.doses.single.undoable, isFalse);
      expect(view.doses.single.intakeId, isNull);
    });

    // -----------------------------------------------------------------------
    // Matched `taken` intake → grace window branches
    // -----------------------------------------------------------------------
    group('matched taken intake', () {
      test('is taken and undoable when confirmed within the grace window', () {
        final DateTime now = DateTime(2026, 6, 4, 8, 3);
        final Medication med = _med(
          slots: <TimeSlot>[_slot(480, id: 'morning')], // 08:00
          startDate: start,
        );
        // Confirmed 3 minutes ago (<= 5-minute grace) → undoable.
        final Intake intake = _intake(
          medicationId: 'test-med',
          slotId: 'morning',
          scheduledAt: DateTime(2026, 6, 4, 8).toUtc(),
          status: IntakeStatus.taken,
          confirmedAt: now.subtract(const Duration(minutes: 3)),
        );

        final TodayView view = buildTodayView(
          meds: <Medication>[med],
          intakes: <Intake>[intake],
          now: now,
        );

        expect(view.doses.single.status, IntakeStatus.taken);
        expect(view.doses.single.confirmedAt, intake.confirmedAt);
        expect(view.doses.single.undoable, isTrue);
        expect(view.doses.single.intakeId, intake.id);
      });

      test('is undoable exactly at the grace-period boundary (inclusive)', () {
        final DateTime now = DateTime(2026, 6, 4, 8, 5);
        final Medication med = _med(
          slots: <TimeSlot>[_slot(480, id: 'morning')],
          startDate: start,
        );
        final Intake intake = _intake(
          medicationId: 'test-med',
          slotId: 'morning',
          scheduledAt: DateTime(2026, 6, 4, 8).toUtc(),
          status: IntakeStatus.taken,
          confirmedAt: now.subtract(kIntakeUndoGracePeriod),
        );

        final TodayView view = buildTodayView(
          meds: <Medication>[med],
          intakes: <Intake>[intake],
          now: now,
        );

        expect(view.doses.single.undoable, isTrue);
      });

      test('is NOT undoable once the grace window has elapsed', () {
        final DateTime now = DateTime(2026, 6, 4, 8, 10);
        final Medication med = _med(
          slots: <TimeSlot>[_slot(480, id: 'morning')],
          startDate: start,
        );
        // Confirmed 6 minutes ago (> 5-minute grace) → not undoable.
        final Intake intake = _intake(
          medicationId: 'test-med',
          slotId: 'morning',
          scheduledAt: DateTime(2026, 6, 4, 8).toUtc(),
          status: IntakeStatus.taken,
          confirmedAt: now.subtract(
            kIntakeUndoGracePeriod + const Duration(minutes: 1),
          ),
        );

        final TodayView view = buildTodayView(
          meds: <Medication>[med],
          intakes: <Intake>[intake],
          now: now,
        );

        expect(view.doses.single.status, IntakeStatus.taken);
        expect(view.doses.single.undoable, isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // Matched `skipped` intake → same undoable logic
    // -----------------------------------------------------------------------
    group('matched skipped intake', () {
      test('is skipped and undoable within the grace window', () {
        final DateTime now = DateTime(2026, 6, 4, 8, 2);
        final Medication med = _med(
          slots: <TimeSlot>[_slot(480, id: 'morning')],
          startDate: start,
        );
        final Intake intake = _intake(
          medicationId: 'test-med',
          slotId: 'morning',
          scheduledAt: DateTime(2026, 6, 4, 8).toUtc(),
          status: IntakeStatus.skipped,
          confirmedAt: now.subtract(const Duration(minutes: 2)),
        );

        final TodayView view = buildTodayView(
          meds: <Medication>[med],
          intakes: <Intake>[intake],
          now: now,
        );

        expect(view.doses.single.status, IntakeStatus.skipped);
        expect(view.doses.single.undoable, isTrue);
      });

      test('is skipped and NOT undoable past the grace window', () {
        final DateTime now = DateTime(2026, 6, 4, 8, 30);
        final Medication med = _med(
          slots: <TimeSlot>[_slot(480, id: 'morning')],
          startDate: start,
        );
        final Intake intake = _intake(
          medicationId: 'test-med',
          slotId: 'morning',
          scheduledAt: DateTime(2026, 6, 4, 8).toUtc(),
          status: IntakeStatus.skipped,
          confirmedAt: now.subtract(const Duration(minutes: 20)),
        );

        final TodayView view = buildTodayView(
          meds: <Medication>[med],
          intakes: <Intake>[intake],
          now: now,
        );

        expect(view.doses.single.status, IntakeStatus.skipped);
        expect(view.doses.single.undoable, isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // Local-date matching (not raw-instant equality)
    // -----------------------------------------------------------------------
    test('matches an intake stored earlier the same LOCAL day', () {
      final DateTime now = DateTime(2026, 6, 4, 21);
      final Medication med = _med(
        slots: <TimeSlot>[_slot(480, id: 'morning')], // dose scheduled 08:00
        startDate: start,
      );
      // Intake recorded at a DIFFERENT instant (early morning) on the SAME
      // local calendar day — its scheduledAt does not equal the dose's, but
      // both reduce to 2026-06-04. Confirmed at midday.
      final Intake intake = _intake(
        medicationId: 'test-med',
        slotId: 'morning',
        scheduledAt: DateTime(2026, 6, 4, 6, 30),
        status: IntakeStatus.taken,
        confirmedAt: DateTime(2026, 6, 4, 12),
      );

      final TodayView view = buildTodayView(
        meds: <Medication>[med],
        intakes: <Intake>[intake],
        now: now,
      );

      expect(view.doses.single.status, IntakeStatus.taken);
      expect(view.doses.single.confirmedAt, intake.confirmedAt);
    });

    test('does NOT match an intake from a different local day', () {
      final DateTime now = DateTime(2026, 6, 4, 9);
      final Medication med = _med(
        slots: <TimeSlot>[_slot(480, id: 'morning')],
        startDate: start,
      );
      // Same med+slot but the intake is dated the PREVIOUS day → no match.
      final Intake intake = _intake(
        medicationId: 'test-med',
        slotId: 'morning',
        scheduledAt: DateTime(2026, 6, 3, 8).toUtc(),
        status: IntakeStatus.taken,
        confirmedAt: DateTime(2026, 6, 3, 8),
      );

      final TodayView view = buildTodayView(
        meds: <Medication>[med],
        intakes: <Intake>[intake],
        now: now,
      );

      expect(view.doses.single.status, IntakeStatus.pending);
      expect(view.doses.single.confirmedAt, isNull);
      expect(view.doses.single.undoable, isFalse);
    });

    // -----------------------------------------------------------------------
    // Ordering preserved
    // -----------------------------------------------------------------------
    test('preserves ascending minuteOfDay order from expandDueDoses', () {
      final DateTime now = DateTime(2026, 6, 4, 9);
      final Medication med = _med(
        slots: <TimeSlot>[
          _slot(1200, id: 'evening'), // 20:00
          _slot(480, id: 'morning'), // 08:00
          _slot(780, id: 'noon'), // 13:00
        ],
        startDate: start,
      );

      final TodayView view = buildTodayView(
        meds: <Medication>[med],
        intakes: <Intake>[],
        now: now,
      );

      expect(
        view.doses.map((TodayDose t) => t.dose.slot.minuteOfDay).toList(),
        <int>[480, 780, 1200],
      );
    });

    // -----------------------------------------------------------------------
    // AC-10: every due dose present regardless of past/future slot time
    // -----------------------------------------------------------------------
    test('includes doses whose slot time is both past and future vs now', () {
      // now sits between the two slots: 08:00 is in the past, 20:00 in the
      // future — both must still appear.
      final DateTime now = DateTime(2026, 6, 4, 12);
      final Medication med = _med(
        slots: <TimeSlot>[
          _slot(480, id: 'morning'), // 08:00 (past)
          _slot(1200, id: 'evening'), // 20:00 (future)
        ],
        startDate: start,
      );

      final TodayView view = buildTodayView(
        meds: <Medication>[med],
        intakes: <Intake>[],
        now: now,
      );

      expect(view.doses, hasLength(2));
      expect(
        view.doses.map((TodayDose t) => t.dose.slot.id.value).toList(),
        <String>['morning', 'evening'],
      );
    });

    // -----------------------------------------------------------------------
    // Empty state
    // -----------------------------------------------------------------------
    test('isEmpty is true when no medications are due', () {
      final DateTime now = DateTime(2026, 6, 4, 9);
      // Start date is in the future → nothing due today.
      final Medication med = _med(
        slots: <TimeSlot>[_slot(480)],
        startDate: start.add(const Duration(days: 30)),
      );

      final TodayView view = buildTodayView(
        meds: <Medication>[med],
        intakes: <Intake>[],
        now: now,
      );

      expect(view.doses, isEmpty);
      expect(view.isEmpty, isTrue);
    });
  });
}
