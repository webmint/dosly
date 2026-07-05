/// Unit tests for [findAutoMissDoses] — the pure derivation of which of today's
/// due doses must be auto-missed as of an injected instant.
///
/// Every test passes an explicit fixed `now` and a fixed [IntakeWindow] (never
/// the wall clock via `DateTime.now()`), so the window-close and local-day
/// arithmetic in the production code is deterministic regardless of the
/// machine's timezone. Covers:
///   - a past-window pending dose (no intake row) IS eligible;
///   - exactly at the window boundary (`now == scheduledAt + window`) is NOT
///     eligible (strict comparison);
///   - strictly past the boundary IS eligible;
///   - a future-later-today dose is NOT eligible;
///   - an occurrence that already has a stored `taken` / `skipped` / `missed`
///     intake is EXCLUDED (idempotency — never re-missed);
///   - no medications → empty;
///   - a DST-adjacent day: the dose is still correctly "due today" (no
///     off-by-one) and a same-local-day intake stored at a different instant
///     still excludes it.
///
/// Fixtures are built in-test via the private helpers so no drift or uuid
/// dependency is pulled into the domain tests. All dates are LOCAL [DateTime]
/// literals so the day-boundary arithmetic matches expectations in any timezone.
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
import 'package:dosly/features/meds/domain/value_objects/due_dose.dart';
import 'package:dosly/features/meds/domain/value_objects/intake_id.dart';
import 'package:dosly/features/meds/domain/value_objects/medication_id.dart';
import 'package:dosly/features/meds/domain/value_objects/missed_intake_reconciliation.dart';
import 'package:dosly/features/meds/domain/value_objects/time_slot_id.dart';
import 'package:dosly/features/settings/domain/value_objects/intake_window.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Minimal fixture builders
// ---------------------------------------------------------------------------

/// Fixed creation timestamp used by all fixtures — irrelevant to the derivation
/// but required by the [Medication] constructor.
final DateTime _createdAt = DateTime(2026, 1, 1);

/// A stub default dose so [DueDose.effectiveDose] has a non-null baseline.
const Dosage _defaultDose = Dosage(amount: 1, unit: DoseUnit.tablet);

/// Builds a [TimeSlot] at [minuteOfDay] with a stable [id].
TimeSlot _slot(int minuteOfDay, {String id = 'slot'}) =>
    TimeSlot(id: TimeSlotId(id), minuteOfDay: minuteOfDay);

/// Builds a continuous [Medication] starting at [startDate] with the given
/// [slots]. Continuous keeps the fixture unconditionally due from its start day.
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
  // Anchor in June to avoid DST transitions that would skew local-day diffs.
  final DateTime start = DateTime(2026, 6, 1);

  // A fixed 120-minute window used throughout. Slot 08:00 → window closes 10:00.
  const IntakeWindow window = IntakeWindow.defaultValue;

  group('findAutoMissDoses', () {
    // -----------------------------------------------------------------------
    // Window-boundary behaviour (strict close)
    // -----------------------------------------------------------------------
    group('window boundary', () {
      final Medication med = _med(
        slots: <TimeSlot>[_slot(480, id: 'morning')], // 08:00
        startDate: start,
      );

      test('a past-window pending dose (no intake row) IS eligible', () {
        // 12:00 is two hours past the 10:00 window close; no stored intake.
        final DateTime now = DateTime(2026, 6, 4, 12);

        final List<DueDose> result = findAutoMissDoses(
          meds: <Medication>[med],
          intakes: <Intake>[],
          window: window,
          now: now,
        );

        expect(result, hasLength(1));
        expect(result.single.slot.id.value, 'morning');
      });

      test(
        'exactly at the boundary (now == scheduledAt + window) is NOT eligible',
        () {
          // Window closes at 10:00 (08:00 + 120 min); at the boundary instant
          // the dose is not yet missed.
          final DateTime now = DateTime(2026, 6, 4, 10);

          final List<DueDose> result = findAutoMissDoses(
            meds: <Medication>[med],
            intakes: <Intake>[],
            window: window,
            now: now,
          );

          expect(result, isEmpty);
        },
      );

      test('strictly past the boundary IS eligible', () {
        // One minute past the 10:00 close.
        final DateTime now = DateTime(2026, 6, 4, 10, 1);

        final List<DueDose> result = findAutoMissDoses(
          meds: <Medication>[med],
          intakes: <Intake>[],
          window: window,
          now: now,
        );

        expect(result, hasLength(1));
      });

      test('a future-later-today dose is NOT eligible', () {
        // Evening slot 20:00, window closes 22:00; at midday it is still future.
        final Medication eveningMed = _med(
          slots: <TimeSlot>[_slot(1200, id: 'evening')], // 20:00
          startDate: start,
        );
        final DateTime now = DateTime(2026, 6, 4, 12);

        final List<DueDose> result = findAutoMissDoses(
          meds: <Medication>[eveningMed],
          intakes: <Intake>[],
          window: window,
          now: now,
        );

        expect(result, isEmpty);
      });
    });

    // -----------------------------------------------------------------------
    // Already-recorded occurrences are excluded (idempotency)
    // -----------------------------------------------------------------------
    group('excludes occurrences with a stored intake', () {
      // Every stored status must exclude the occurrence — a dose that already
      // has a row (taken, skipped, or previously missed) is never re-missed.
      for (final IntakeStatus status in <IntakeStatus>[
        IntakeStatus.taken,
        IntakeStatus.skipped,
        IntakeStatus.missed,
      ]) {
        test('a stored ${status.name} intake EXCLUDES the occurrence', () {
          final DateTime now = DateTime(2026, 6, 4, 12); // past the window
          final Medication med = _med(
            slots: <TimeSlot>[_slot(480, id: 'morning')],
            startDate: start,
          );
          // Same med+slot, same local day — matches by occurrence key even
          // though the stored instant differs from the dose's scheduledAt.
          final Intake intake = _intake(
            medicationId: 'test-med',
            slotId: 'morning',
            scheduledAt: DateTime(2026, 6, 4, 6, 30),
            status: status,
          );

          final List<DueDose> result = findAutoMissDoses(
            meds: <Medication>[med],
            intakes: <Intake>[intake],
            window: window,
            now: now,
          );

          expect(result, isEmpty);
        });
      }

      test('an intake from a DIFFERENT local day does NOT exclude', () {
        final DateTime now = DateTime(2026, 6, 4, 12);
        final Medication med = _med(
          slots: <TimeSlot>[_slot(480, id: 'morning')],
          startDate: start,
        );
        // Same med+slot but dated the PREVIOUS day → different occurrence key.
        final Intake intake = _intake(
          medicationId: 'test-med',
          slotId: 'morning',
          scheduledAt: DateTime(2026, 6, 3, 8).toUtc(),
          status: IntakeStatus.taken,
        );

        final List<DueDose> result = findAutoMissDoses(
          meds: <Medication>[med],
          intakes: <Intake>[intake],
          window: window,
          now: now,
        );

        expect(result, hasLength(1));
      });
    });

    // -----------------------------------------------------------------------
    // Mixed scenario: only the past-window, unmatched, due-today subset
    // -----------------------------------------------------------------------
    test('returns only past-window unmatched doses from a mix', () {
      // now is 13:00 so BOTH the 08:00 and 10:00 slots are STRICTLY past their
      // windows (which close at 10:00 and 12:00 respectively). This makes the
      // `mid` slot's exclusion attributable solely to its stored `taken` intake
      // rather than to the window check — without that row it would be eligible.
      final DateTime now = DateTime(2026, 6, 4, 13);
      final Medication med = _med(
        slots: <TimeSlot>[
          _slot(480, id: 'morning'), // 08:00 → window closes 10:00, unmatched
          _slot(600, id: 'mid'), // 10:00 → window closes 12:00, but taken
          _slot(1200, id: 'evening'), // 20:00 → window closes 22:00, future
        ],
        startDate: start,
      );
      // The 10:00 slot is strictly past its 12:00 window close, so the window
      // check alone would make it eligible; the stored `taken` intake is the
      // sole reason it is excluded from the result.
      final Intake taken = _intake(
        medicationId: 'test-med',
        slotId: 'mid',
        scheduledAt: DateTime(2026, 6, 4, 10).toUtc(),
        status: IntakeStatus.taken,
      );

      final List<DueDose> result = findAutoMissDoses(
        meds: <Medication>[med],
        intakes: <Intake>[taken],
        window: window,
        now: now,
      );

      // Only the unmatched, past-window `morning` dose is auto-missed. The
      // past-window `mid` dose is absent purely because of its `taken` row.
      expect(result, hasLength(1));
      expect(result.single.slot.id.value, 'morning');
      expect(
        result.map((DueDose d) => d.slot.id.value),
        isNot(contains('mid')),
      );
    });

    // -----------------------------------------------------------------------
    // Empty behaviour
    // -----------------------------------------------------------------------
    test('no medications → empty', () {
      final DateTime now = DateTime(2026, 6, 4, 12);

      final List<DueDose> result = findAutoMissDoses(
        meds: <Medication>[],
        intakes: <Intake>[],
        window: window,
        now: now,
      );

      expect(result, isEmpty);
    });

    // -----------------------------------------------------------------------
    // DST-adjacent day — no off-by-one in "due today"
    // -----------------------------------------------------------------------
    group('DST-adjacent day', () {
      // 2026 EU spring-forward (02:00 → 03:00) falls on 2026-03-29. A continuous
      // med started well before is unconditionally due that day; localCalendarDate
      // anchors the day to UTC-midnight so classification does not slip by one.
      final Medication med = _med(
        slots: <TimeSlot>[_slot(480, id: 'morning')], // 08:00 (after the jump)
        startDate: DateTime(2026, 3, 1),
      );

      test('a past-window pending dose on the DST day IS eligible', () {
        // 12:00 on the DST day, two hours past the 10:00 window close.
        final DateTime now = DateTime(2026, 3, 29, 12);

        final List<DueDose> result = findAutoMissDoses(
          meds: <Medication>[med],
          intakes: <Intake>[],
          window: window,
          now: now,
        );

        expect(result, hasLength(1));
        expect(result.single.medication.id.value, 'test-med');
      });

      test(
        'a same-local-day intake on the DST day excludes the occurrence',
        () {
          final DateTime now = DateTime(2026, 3, 29, 12);
          // Recorded at a different instant the SAME local day → same key.
          final Intake intake = _intake(
            medicationId: 'test-med',
            slotId: 'morning',
            scheduledAt: DateTime(2026, 3, 29, 6, 30),
            status: IntakeStatus.taken,
          );

          final List<DueDose> result = findAutoMissDoses(
            meds: <Medication>[med],
            intakes: <Intake>[intake],
            window: window,
            now: now,
          );

          expect(result, isEmpty);
        },
      );
    });
  });
}
