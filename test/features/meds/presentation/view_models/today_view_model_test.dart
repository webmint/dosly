/// Tests for [buildTodayView] — the pure shaping function that combines the
/// day's expanded due doses with the stored intakes into the render-ready Today
/// structure: hour-bucketed [TodayHourGroup]s, per-dose [DoseWindowState] +
/// [TodayDose.actionable] enablement, the [TodayDose.undoable] grace flag, and
/// the [TodayView.nextIntake] countdown target.
///
/// Covers, with an explicit injected `now` (never the wall clock):
///   - unmatched dose: no intake → `pending`, not undoable.
///   - matched `taken` intake (same med+slot+local date) → `taken`, with
///     `undoable` true inside the grace window and false past it.
///   - matched `skipped` intake → `skipped`, same undoable logic.
///   - local-date matching: an intake stored earlier the SAME local day (a
///     different instant) still matches.
///   - ordering: entries preserve the ascending minuteOfDay order.
///   - AC-10: every due dose appears whether its slot time is past or future
///     relative to `now`.
///   - empty: [TodayView.isEmpty] is true when nothing is due.
///   - hourly grouping: same-hour doses share one group; groups ascend by hour.
///   - group state: all-future / all-past / has-open → future / past / now.
///   - window/actionable matrix: future±mark-ahead, open, past-window.
///   - inclusive window boundary at `scheduledAt + intakeWindow`.
///   - `nextIntake`: earliest future-pending dose, else `null`.
///   - `undoable` honoring a non-default grace [Duration].
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
import 'package:dosly/features/meds/domain/value_objects/intake_id.dart';
import 'package:dosly/features/meds/domain/value_objects/medication_id.dart';
import 'package:dosly/features/meds/domain/value_objects/time_slot_id.dart';
import 'package:dosly/features/meds/presentation/view_models/today_view_model.dart';
import 'package:dosly/features/settings/domain/value_objects/intake_window.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Minimal fixture builders
// ---------------------------------------------------------------------------

/// Fixed creation timestamp used by all fixtures — irrelevant to shaping but
/// required by the [Medication] constructor.
final DateTime _createdAt = DateTime(2026, 1, 1);

/// A stub default dose so [DueDose.effectiveDose] has a non-null baseline.
const Dosage _defaultDose = Dosage(amount: 1, unit: DoseUnit.tablet);

/// The default grace period the Today screen projects (`GracePeriod.defaultValue`
/// → 5 minutes) — used everywhere a case does not exercise the grace boundary.
const Duration _grace = Duration(minutes: 5);

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
        intakeWindow: IntakeWindow.defaultValue,
        gracePeriod: _grace,
        allowMarkAhead: false,
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
          intakeWindow: IntakeWindow.defaultValue,
          gracePeriod: _grace,
          allowMarkAhead: false,
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
          confirmedAt: now.subtract(_grace),
        );

        final TodayView view = buildTodayView(
          meds: <Medication>[med],
          intakes: <Intake>[intake],
          now: now,
          intakeWindow: IntakeWindow.defaultValue,
          gracePeriod: _grace,
          allowMarkAhead: false,
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
          confirmedAt: now.subtract(const Duration(minutes: 6)),
        );

        final TodayView view = buildTodayView(
          meds: <Medication>[med],
          intakes: <Intake>[intake],
          now: now,
          intakeWindow: IntakeWindow.defaultValue,
          gracePeriod: _grace,
          allowMarkAhead: false,
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
          intakeWindow: IntakeWindow.defaultValue,
          gracePeriod: _grace,
          allowMarkAhead: false,
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
          intakeWindow: IntakeWindow.defaultValue,
          gracePeriod: _grace,
          allowMarkAhead: false,
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
        intakeWindow: IntakeWindow.defaultValue,
        gracePeriod: _grace,
        allowMarkAhead: false,
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
        intakeWindow: IntakeWindow.defaultValue,
        gracePeriod: _grace,
        allowMarkAhead: false,
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
        intakeWindow: IntakeWindow.defaultValue,
        gracePeriod: _grace,
        allowMarkAhead: false,
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
        intakeWindow: IntakeWindow.defaultValue,
        gracePeriod: _grace,
        allowMarkAhead: false,
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
        intakeWindow: IntakeWindow.defaultValue,
        gracePeriod: _grace,
        allowMarkAhead: false,
      );

      expect(view.groups, isEmpty);
      expect(view.doses, isEmpty);
      expect(view.isEmpty, isTrue);
    });

    // -----------------------------------------------------------------------
    // Hourly grouping (AC-1)
    // -----------------------------------------------------------------------
    group('hourly grouping', () {
      test('buckets two doses in the same hour into one group', () {
        final DateTime now = DateTime(2026, 6, 4, 9);
        final Medication med = _med(
          slots: <TimeSlot>[
            _slot(840, id: 'two'), // 14:00
            _slot(870, id: 'twoThirty'), // 14:30
          ],
          startDate: start,
        );

        final TodayView view = buildTodayView(
          meds: <Medication>[med],
          intakes: <Intake>[],
          now: now,
          intakeWindow: IntakeWindow.defaultValue,
          gracePeriod: _grace,
          allowMarkAhead: false,
        );

        expect(view.groups, hasLength(1));
        expect(view.groups.single.hour, 14);
        expect(view.groups.single.doses, hasLength(2));
        expect(view.groups.single.total, 2);
      });

      test('orders groups ascending by hour', () {
        final DateTime now = DateTime(2026, 6, 4, 9);
        final Medication med = _med(
          slots: <TimeSlot>[
            _slot(1200, id: 'evening'), // hour 20
            _slot(480, id: 'morning'), // hour 8
            _slot(780, id: 'noon'), // hour 13
          ],
          startDate: start,
        );

        final TodayView view = buildTodayView(
          meds: <Medication>[med],
          intakes: <Intake>[],
          now: now,
          intakeWindow: IntakeWindow.defaultValue,
          gracePeriod: _grace,
          allowMarkAhead: false,
        );

        expect(view.groups.map((TodayHourGroup g) => g.hour).toList(), <int>[
          8,
          13,
          20,
        ]);
      });

      test('counts taken doses into takenCount', () {
        final DateTime now = DateTime(2026, 6, 4, 9);
        final Medication med = _med(
          slots: <TimeSlot>[
            _slot(840, id: 'two'), // 14:00
            _slot(870, id: 'twoThirty'), // 14:30
          ],
          startDate: start,
        );
        final Intake intake = _intake(
          medicationId: 'test-med',
          slotId: 'two',
          scheduledAt: DateTime(2026, 6, 4, 14).toUtc(),
          status: IntakeStatus.taken,
          confirmedAt: DateTime(2026, 6, 4, 9),
        );

        final TodayView view = buildTodayView(
          meds: <Medication>[med],
          intakes: <Intake>[intake],
          now: now,
          intakeWindow: IntakeWindow.defaultValue,
          gracePeriod: _grace,
          allowMarkAhead: true,
        );

        expect(view.groups.single.takenCount, 1);
        expect(view.groups.single.total, 2);
      });
    });

    // -----------------------------------------------------------------------
    // Group state (AC-2)
    // -----------------------------------------------------------------------
    group('group state', () {
      test('is future when every dose window is future', () {
        final DateTime now = DateTime(2026, 6, 4, 9); // before 14:00
        final Medication med = _med(
          slots: <TimeSlot>[_slot(840, id: 'two')], // 14:00
          startDate: start,
        );

        final TodayView view = buildTodayView(
          meds: <Medication>[med],
          intakes: <Intake>[],
          now: now,
          intakeWindow: IntakeWindow(120),
          gracePeriod: _grace,
          allowMarkAhead: false,
        );

        expect(view.groups.single.state, TodayGroupState.future);
      });

      test('is past when every dose window has lapsed', () {
        final DateTime now = DateTime(2026, 6, 4, 18); // well past 08:00 + 2h
        final Medication med = _med(
          slots: <TimeSlot>[_slot(480, id: 'morning')], // 08:00, close 10:00
          startDate: start,
        );

        final TodayView view = buildTodayView(
          meds: <Medication>[med],
          intakes: <Intake>[],
          now: now,
          intakeWindow: IntakeWindow(120),
          gracePeriod: _grace,
          allowMarkAhead: false,
        );

        expect(view.groups.single.state, TodayGroupState.past);
      });

      test('is now when the group contains an open dose', () {
        final DateTime now = DateTime(2026, 6, 4, 8, 30); // inside 08:00 window
        final Medication med = _med(
          slots: <TimeSlot>[_slot(480, id: 'morning')], // 08:00, close 10:00
          startDate: start,
        );

        final TodayView view = buildTodayView(
          meds: <Medication>[med],
          intakes: <Intake>[],
          now: now,
          intakeWindow: IntakeWindow(120),
          gracePeriod: _grace,
          allowMarkAhead: false,
        );

        expect(view.groups.single.state, TodayGroupState.now);
      });
    });

    // -----------------------------------------------------------------------
    // windowState / actionable matrix (AC-8)
    // -----------------------------------------------------------------------
    group('windowState and actionable matrix', () {
      test('future dose is not actionable when mark-ahead is off', () {
        final DateTime now = DateTime(2026, 6, 4, 9); // before 14:00
        final Medication med = _med(
          slots: <TimeSlot>[_slot(840, id: 'two')], // 14:00
          startDate: start,
        );

        final TodayView view = buildTodayView(
          meds: <Medication>[med],
          intakes: <Intake>[],
          now: now,
          intakeWindow: IntakeWindow(120),
          gracePeriod: _grace,
          allowMarkAhead: false,
        );

        expect(view.doses.single.windowState, DoseWindowState.future);
        expect(view.doses.single.actionable, isFalse);
      });

      test('future dose is actionable when mark-ahead is on', () {
        final DateTime now = DateTime(2026, 6, 4, 9); // before 14:00
        final Medication med = _med(
          slots: <TimeSlot>[_slot(840, id: 'two')], // 14:00
          startDate: start,
        );

        final TodayView view = buildTodayView(
          meds: <Medication>[med],
          intakes: <Intake>[],
          now: now,
          intakeWindow: IntakeWindow(120),
          gracePeriod: _grace,
          allowMarkAhead: true,
        );

        expect(view.doses.single.windowState, DoseWindowState.future);
        expect(view.doses.single.actionable, isTrue);
      });

      test('open dose is actionable regardless of mark-ahead', () {
        final DateTime now = DateTime(2026, 6, 4, 8, 30); // inside 08:00 window
        final Medication med = _med(
          slots: <TimeSlot>[_slot(480, id: 'morning')], // 08:00, close 10:00
          startDate: start,
        );

        final TodayView view = buildTodayView(
          meds: <Medication>[med],
          intakes: <Intake>[],
          now: now,
          intakeWindow: IntakeWindow(120),
          gracePeriod: _grace,
          allowMarkAhead: false,
        );

        expect(view.doses.single.windowState, DoseWindowState.open);
        expect(view.doses.single.actionable, isTrue);
      });

      test('past-window pending dose is not actionable', () {
        final DateTime now = DateTime(2026, 6, 4, 11); // past 08:00 + 2h
        final Medication med = _med(
          slots: <TimeSlot>[_slot(480, id: 'morning')], // 08:00, close 10:00
          startDate: start,
        );

        final TodayView view = buildTodayView(
          meds: <Medication>[med],
          intakes: <Intake>[],
          now: now,
          intakeWindow: IntakeWindow(120),
          gracePeriod: _grace,
          allowMarkAhead: true, // mark-ahead cannot rescue a lapsed window
        );

        expect(view.doses.single.windowState, DoseWindowState.pastWindow);
        expect(view.doses.single.actionable, isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // Inclusive window boundary (AC-9)
    // -----------------------------------------------------------------------
    group('window boundary', () {
      test('a dose exactly at scheduledAt + window is open (inclusive)', () {
        // 08:00 slot + 120-minute window ⇒ window close at local 10:00.
        final DateTime now = DateTime(2026, 6, 4, 10); // exactly at close
        final Medication med = _med(
          slots: <TimeSlot>[_slot(480, id: 'morning')], // 08:00
          startDate: start,
        );

        final TodayView view = buildTodayView(
          meds: <Medication>[med],
          intakes: <Intake>[],
          now: now,
          intakeWindow: IntakeWindow(120),
          gracePeriod: _grace,
          allowMarkAhead: false,
        );

        expect(view.doses.single.windowState, DoseWindowState.open);
        expect(view.doses.single.actionable, isTrue);
      });

      test('a dose one minute past the window close is pastWindow', () {
        final DateTime now = DateTime(2026, 6, 4, 10, 1); // just past close
        final Medication med = _med(
          slots: <TimeSlot>[_slot(480, id: 'morning')], // 08:00
          startDate: start,
        );

        final TodayView view = buildTodayView(
          meds: <Medication>[med],
          intakes: <Intake>[],
          now: now,
          intakeWindow: IntakeWindow(120),
          gracePeriod: _grace,
          allowMarkAhead: false,
        );

        expect(view.doses.single.windowState, DoseWindowState.pastWindow);
      });
    });

    // -----------------------------------------------------------------------
    // nextIntake countdown target (AC-4)
    // -----------------------------------------------------------------------
    group('nextIntake', () {
      test('selects the earliest future pending dose', () {
        final DateTime now = DateTime(
          2026,
          6,
          4,
          9,
        ); // 08:00 open, 14:00/20:00 future
        final Medication med = _med(
          slots: <TimeSlot>[
            _slot(480, id: 'morning'), // 08:00 (open at 09:00)
            _slot(840, id: 'two'), // 14:00 (future) — the soonest upcoming
            _slot(1200, id: 'evening'), // 20:00 (future)
          ],
          startDate: start,
        );

        final TodayView view = buildTodayView(
          meds: <Medication>[med],
          intakes: <Intake>[],
          now: now,
          intakeWindow: IntakeWindow(120),
          gracePeriod: _grace,
          allowMarkAhead: false,
        );

        expect(view.nextIntake, isNotNull);
        expect(view.nextIntake?.dose.slot.minuteOfDay, 840);
        expect(view.nextIntake?.windowState, DoseWindowState.future);
        expect(view.nextIntake?.status, IntakeStatus.pending);
      });

      test('is null when no dose is future and pending', () {
        final DateTime now = DateTime(2026, 6, 4, 21); // everything lapsed
        final Medication med = _med(
          slots: <TimeSlot>[_slot(480, id: 'morning')], // 08:00
          startDate: start,
        );

        final TodayView view = buildTodayView(
          meds: <Medication>[med],
          intakes: <Intake>[],
          now: now,
          intakeWindow: IntakeWindow(120),
          gracePeriod: _grace,
          allowMarkAhead: false,
        );

        expect(view.nextIntake, isNull);
      });

      test('excludes a future dose that is already taken', () {
        final DateTime now = DateTime(2026, 6, 4, 9); // before 14:00
        final Medication med = _med(
          slots: <TimeSlot>[_slot(840, id: 'two')], // 14:00 (future)
          startDate: start,
        );
        // Marked ahead: the only future dose is taken → no future-pending dose.
        final Intake intake = _intake(
          medicationId: 'test-med',
          slotId: 'two',
          scheduledAt: DateTime(2026, 6, 4, 14).toUtc(),
          status: IntakeStatus.taken,
          confirmedAt: DateTime(2026, 6, 4, 9),
        );

        final TodayView view = buildTodayView(
          meds: <Medication>[med],
          intakes: <Intake>[intake],
          now: now,
          intakeWindow: IntakeWindow(120),
          gracePeriod: _grace,
          allowMarkAhead: true,
        );

        expect(view.doses.single.windowState, DoseWindowState.future);
        expect(view.doses.single.status, IntakeStatus.taken);
        expect(view.nextIntake, isNull);
      });
    });

    // -----------------------------------------------------------------------
    // undoable honors the configured grace period (AC-14)
    // -----------------------------------------------------------------------
    group('configured grace period', () {
      test('is never undoable with a zero grace period', () {
        final DateTime now = DateTime(2026, 6, 4, 8, 1);
        final Medication med = _med(
          slots: <TimeSlot>[_slot(480, id: 'morning')], // 08:00
          startDate: start,
        );
        // Confirmed one minute ago — inside the default 5-min grace, but the
        // configured grace here is zero.
        final Intake intake = _intake(
          medicationId: 'test-med',
          slotId: 'morning',
          scheduledAt: DateTime(2026, 6, 4, 8).toUtc(),
          status: IntakeStatus.taken,
          confirmedAt: now.subtract(const Duration(minutes: 1)),
        );

        final TodayView view = buildTodayView(
          meds: <Medication>[med],
          intakes: <Intake>[intake],
          now: now,
          intakeWindow: IntakeWindow.defaultValue,
          gracePeriod: Duration.zero,
          allowMarkAhead: false,
        );

        expect(view.doses.single.status, IntakeStatus.taken);
        expect(view.doses.single.undoable, isFalse);
      });

      test('a 20-minute-old taken dose is undoable with a 30-minute grace', () {
        final DateTime now = DateTime(2026, 6, 4, 8, 30);
        final Medication med = _med(
          slots: <TimeSlot>[_slot(480, id: 'morning')], // 08:00
          startDate: start,
        );
        // Confirmed 20 minutes ago — past the default 5-min grace, but inside
        // the configured 30-min grace.
        final Intake intake = _intake(
          medicationId: 'test-med',
          slotId: 'morning',
          scheduledAt: DateTime(2026, 6, 4, 8).toUtc(),
          status: IntakeStatus.taken,
          confirmedAt: now.subtract(const Duration(minutes: 20)),
        );

        final TodayView view = buildTodayView(
          meds: <Medication>[med],
          intakes: <Intake>[intake],
          now: now,
          intakeWindow: IntakeWindow.defaultValue,
          gracePeriod: const Duration(minutes: 30),
          allowMarkAhead: false,
        );

        expect(view.doses.single.status, IntakeStatus.taken);
        expect(view.doses.single.undoable, isTrue);
      });
    });
  });
}
