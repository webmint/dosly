/// Unit tests for [expandDueDoses] and [DueDose].
///
/// All dates are LOCAL [DateTime] objects so the day-boundary arithmetic in the
/// production code matches what these tests expect regardless of the machine's
/// timezone. Fixtures are built in-test via the private [_med] / [_slot]
/// helpers so no drift or uuid dependency is pulled into the domain tests.
library;

import 'package:clock/clock.dart';
import 'package:dosly/features/meds/domain/entities/dosage.dart';
import 'package:dosly/features/meds/domain/entities/dose_unit.dart';
import 'package:dosly/features/meds/domain/entities/medication.dart';
import 'package:dosly/features/meds/domain/entities/medication_form.dart';
import 'package:dosly/features/meds/domain/entities/medication_type.dart';
import 'package:dosly/features/meds/domain/entities/schedule.dart';
import 'package:dosly/features/meds/domain/entities/time_slot.dart';
import 'package:dosly/features/meds/domain/value_objects/due_dose.dart';
import 'package:dosly/features/meds/domain/value_objects/medication_id.dart';
import 'package:dosly/features/meds/domain/value_objects/time_slot_id.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Minimal fixture builders
// ---------------------------------------------------------------------------

/// Fixed creation timestamp used by all fixtures — irrelevant to due-dose
/// expansion but required by the [Medication] constructor.
final _createdAt = DateTime(2026, 1, 1);

/// A stub default dose so [DueDose.effectiveDose] has a non-null baseline.
const _defaultDose = Dosage(amount: 1, unit: DoseUnit.tablet);

/// Builds a [TimeSlot] at [minuteOfDay] with a stable [id] and optional
/// [doseOverride].
TimeSlot _slot(int minuteOfDay, {String id = 'slot', Dosage? doseOverride}) =>
    TimeSlot(
      id: TimeSlotId(id),
      minuteOfDay: minuteOfDay,
      doseOverride: doseOverride,
    );

/// Builds the smallest valid [Medication] for the temporal [type] and [slots]
/// under test. Non-relevant fields use stable stub values.
Medication _med({
  required MedicationType type,
  required List<TimeSlot> slots,
  Dosage? dosePerIntake = _defaultDose,
  String name = 'Test Medication',
  String id = 'test-med',
}) => Medication(
  id: MedicationId(id),
  name: name,
  form: MedicationForm.tablet,
  type: type,
  schedule: Schedule(slots: slots),
  dosePerIntake: dosePerIntake,
  createdAt: _createdAt,
);

void main() {
  // Anchor date used throughout — in June to avoid DST transitions that would
  // skew add(Duration(days: N)) by one hour and corrupt the local-day diff.
  final start = DateTime(2026, 6, 1); // 2026-06-01, day 0

  group('expandDueDoses', () {
    // -----------------------------------------------------------------------
    // Continuous medication
    // -----------------------------------------------------------------------
    group('continuous medication', () {
      test(
        'should emit one DueDose per slot when the start day has arrived',
        () {
          final now = start.add(const Duration(days: 3));
          final med = _med(
            type: MedicationType.continuous(startDate: start),
            slots: <TimeSlot>[
              _slot(480, id: 'morning'), // 08:00
              _slot(780, id: 'noon'), // 13:00
              _slot(1200, id: 'evening'), // 20:00
            ],
          );

          final result = expandDueDoses(meds: <Medication>[med], now: now);

          expect(result, hasLength(3));
          // Every dose points back at its source medication.
          expect(result.every((d) => identical(d.medication, med)), isTrue);
        },
      );

      test('should emit no doses when the start date is in the FUTURE', () {
        // Start is five days after `now`; nothing is due yet.
        final now = start;
        final med = _med(
          type: MedicationType.continuous(
            startDate: start.add(const Duration(days: 5)),
          ),
          slots: <TimeSlot>[_slot(480)],
        );

        final result = expandDueDoses(meds: <Medication>[med], now: now);

        expect(result, isEmpty);
      });

      test('should be due on the exact start day (inclusive boundary)', () {
        final med = _med(
          type: MedicationType.continuous(startDate: start),
          slots: <TimeSlot>[_slot(600)],
        );

        final result = expandDueDoses(meds: <Medication>[med], now: start);

        expect(result, hasLength(1));
      });

      test('should build scheduledAt as a UTC instant at the slot minute', () {
        // now at 2026-06-04; slot 08:30 (minuteOfDay 510).
        final now = DateTime(2026, 6, 4, 15, 45); // time-of-day is ignored
        final med = _med(
          type: MedicationType.continuous(startDate: start),
          slots: <TimeSlot>[_slot(510)], // 08:30
        );

        final result = expandDueDoses(meds: <Medication>[med], now: now);

        expect(result, hasLength(1));
        final dose = result.single;
        expect(dose.scheduledAt.isUtc, isTrue);
        expect(dose.scheduledAt, DateTime(2026, 6, 4, 8, 30).toUtc());
      });
    });

    // -----------------------------------------------------------------------
    // Non-cyclic course (pauseDays == 0)
    // -----------------------------------------------------------------------
    group('non-cyclic course (pauseDays == 0)', () {
      MedicationType courseType() => MedicationType.course(
        startDate: start,
        durationDays: 7,
        pauseDays: 0,
      );

      test('should be due within the active window', () {
        final now = start.add(const Duration(days: 3));
        final med = _med(type: courseType(), slots: <TimeSlot>[_slot(480)]);

        final result = expandDueDoses(meds: <Medication>[med], now: now);

        expect(result, hasLength(1));
      });

      test('should NOT be due the day before the start date', () {
        final now = start.subtract(const Duration(days: 1));
        final med = _med(type: courseType(), slots: <TimeSlot>[_slot(480)]);

        final result = expandDueDoses(meds: <Medication>[med], now: now);

        expect(result, isEmpty);
      });

      test(
        'should be due on the FINAL active day (start + durationDays - 1)',
        () {
          // day 6 (0-based) is the 7th and last active day of a 7-day course.
          final now = start.add(const Duration(days: 6));
          final med = _med(type: courseType(), slots: <TimeSlot>[_slot(480)]);

          final result = expandDueDoses(meds: <Medication>[med], now: now);

          expect(result, hasLength(1));
        },
      );

      test('should NOT be due once the course has COMPLETED', () {
        // day 7 (0-based) is one day past the final active day → completed.
        final now = start.add(const Duration(days: 7));
        final med = _med(type: courseType(), slots: <TimeSlot>[_slot(480)]);

        final result = expandDueDoses(meds: <Medication>[med], now: now);

        expect(result, isEmpty);
      });
    });

    // -----------------------------------------------------------------------
    // Cyclic course (pauseDays > 0)
    // -----------------------------------------------------------------------
    group('cyclic course (pauseDays > 0)', () {
      // 10 active days followed by a 20-day pause gap, repeating.
      MedicationType cyclicType() => MedicationType.course(
        startDate: start,
        durationDays: 10,
        pauseDays: 20,
      );

      test('should be due on a day inside the active window', () {
        // day 5 (0-based) → posInCycle 5 < 10 → active window.
        final now = start.add(const Duration(days: 5));
        final med = _med(type: cyclicType(), slots: <TimeSlot>[_slot(480)]);

        final result = expandDueDoses(meds: <Medication>[med], now: now);

        expect(result, hasLength(1));
      });

      test('should NOT be due on a pause-gap day', () {
        // day 15 (0-based) → posInCycle 15 >= 10 → paused gap.
        final now = start.add(const Duration(days: 15));
        final med = _med(type: cyclicType(), slots: <TimeSlot>[_slot(480)]);

        final result = expandDueDoses(meds: <Medication>[med], now: now);

        expect(result, isEmpty);
      });

      test('should be due again when the next active window begins', () {
        // day 30 (0-based) → posInCycle 0 < 10 → first day of new window.
        final now = start.add(const Duration(days: 30));
        final med = _med(type: cyclicType(), slots: <TimeSlot>[_slot(480)]);

        final result = expandDueDoses(meds: <Medication>[med], now: now);

        expect(result, hasLength(1));
      });
    });

    // -----------------------------------------------------------------------
    // Effective dose resolution
    // -----------------------------------------------------------------------
    group('effectiveDose', () {
      test('should use the slot override when present, else the default', () {
        const override = Dosage(amount: 2, unit: DoseUnit.tablet);
        final now = start.add(const Duration(days: 1));
        final med = _med(
          type: MedicationType.continuous(startDate: start),
          dosePerIntake: _defaultDose,
          slots: <TimeSlot>[
            _slot(480, id: 'with-override', doseOverride: override),
            _slot(1200, id: 'default'),
          ],
        );

        final result = expandDueDoses(meds: <Medication>[med], now: now);

        expect(result, hasLength(2));
        // Sorted ascending by minute: override slot (480) comes first.
        expect(result[0].effectiveDose, override);
        expect(result[1].effectiveDose, _defaultDose);
      });

      test('should be null when neither override nor default dose exists', () {
        final now = start.add(const Duration(days: 1));
        final med = _med(
          type: MedicationType.continuous(startDate: start),
          dosePerIntake: null,
          slots: <TimeSlot>[_slot(480)],
        );

        final result = expandDueDoses(meds: <Medication>[med], now: now);

        expect(result.single.effectiveDose, isNull);
      });
    });

    // -----------------------------------------------------------------------
    // Ordering
    // -----------------------------------------------------------------------
    group('ordering', () {
      test('should sort doses ascending by minuteOfDay', () {
        final now = start.add(const Duration(days: 1));
        final med = _med(
          type: MedicationType.continuous(startDate: start),
          slots: <TimeSlot>[
            _slot(1200, id: 'evening'), // 20:00
            _slot(480, id: 'morning'), // 08:00
            _slot(780, id: 'noon'), // 13:00
          ],
        );

        final result = expandDueDoses(meds: <Medication>[med], now: now);

        expect(result.map((d) => d.slot.minuteOfDay).toList(), <int>[
          480,
          780,
          1200,
        ]);
      });

      test(
        'should break minuteOfDay ties by medication name (case-insensitive)',
        () {
          final now = start.add(const Duration(days: 1));
          final zinc = _med(
            id: 'zinc',
            name: 'zinc',
            type: MedicationType.continuous(startDate: start),
            slots: <TimeSlot>[_slot(480, id: 'z')],
          );
          final aspirin = _med(
            id: 'aspirin',
            name: 'Aspirin',
            type: MedicationType.continuous(startDate: start),
            slots: <TimeSlot>[_slot(480, id: 'a')],
          );

          // Passed in reverse alphabetical order to prove the sort reorders.
          final result = expandDueDoses(
            meds: <Medication>[zinc, aspirin],
            now: now,
          );

          expect(result.map((d) => d.medication.name).toList(), <String>[
            'Aspirin',
            'zinc',
          ]);
        },
      );

      test('should break name ties by slot id value', () {
        final now = start.add(const Duration(days: 1));
        // Same medication (same name), two slots at the same minute; the
        // tie-break falls through to the slot id.
        final med = _med(
          type: MedicationType.continuous(startDate: start),
          slots: <TimeSlot>[
            _slot(480, id: 'b'),
            _slot(480, id: 'a'),
          ],
        );

        final result = expandDueDoses(meds: <Medication>[med], now: now);

        expect(result.map((d) => d.slot.id.value).toList(), <String>['a', 'b']);
      });
    });

    // -----------------------------------------------------------------------
    // DST-boundary classification (not off by one)
    // -----------------------------------------------------------------------
    group('DST boundary classification', () {
      // The 2026 EU spring-forward (clocks jump 02:00 → 03:00) falls on
      // 2026-03-29. A 31-day non-cyclic course starting 2026-03-02 has its
      // final active day on 2026-04-01 (day 30, 0-based) and completes on
      // 2026-04-02 (day 31). Dates are explicit LOCAL literals — NOT
      // start.add(Duration(...)) — because Duration arithmetic across a DST
      // transition is itself unreliable. UTC-anchoring in localCalendarDate
      // keeps the count at exactly whole calendar days, so the due/completed
      // boundary does not slip by one day in a DST timezone.
      MedicationType dstCourse() => MedicationType.course(
        startDate: DateTime(2026, 3, 2),
        durationDays: 31,
        pauseDays: 0,
      );

      test('should be due on the final active day across the DST boundary', () {
        final med = _med(type: dstCourse(), slots: <TimeSlot>[_slot(480)]);

        final result = expandDueDoses(
          meds: <Medication>[med],
          now: DateTime(2026, 4, 1), // day 30 (0-based) → last active day
        );

        expect(result, hasLength(1));
      });

      test('should NOT be due the day after, across the DST boundary', () {
        final med = _med(type: dstCourse(), slots: <TimeSlot>[_slot(480)]);

        final result = expandDueDoses(
          meds: <Medication>[med],
          now: DateTime(2026, 4, 2), // day 31 (0-based) → completed
        );

        expect(result, isEmpty);
      });
    });

    // -----------------------------------------------------------------------
    // Empty / multi-med behaviour
    // -----------------------------------------------------------------------
    group('aggregate behaviour', () {
      test('should return an empty list when there are no medications', () {
        final result = expandDueDoses(meds: <Medication>[], now: start);

        expect(result, isEmpty);
      });

      test('should merge and interleave doses from multiple medications', () {
        final now = start.add(const Duration(days: 1));
        final morningMed = _med(
          id: 'a',
          name: 'A med',
          type: MedicationType.continuous(startDate: start),
          slots: <TimeSlot>[_slot(480, id: 'a-morning')], // 08:00
        );
        final eveningMed = _med(
          id: 'b',
          name: 'B med',
          type: MedicationType.continuous(startDate: start),
          slots: <TimeSlot>[_slot(1200, id: 'b-evening')], // 20:00
        );

        final result = expandDueDoses(
          meds: <Medication>[eveningMed, morningMed],
          now: now,
        );

        expect(result.map((d) => d.slot.minuteOfDay).toList(), <int>[
          480,
          1200,
        ]);
      });
    });

    // -----------------------------------------------------------------------
    // Ambient-clock integration: withClock + Clock.fixed
    // -----------------------------------------------------------------------
    group('ambient-clock integration', () {
      test(
        'should expand doses for a clock-driven `now` inside the course window',
        () {
          final fixedNow = start.add(const Duration(days: 2));

          withClock(Clock.fixed(fixedNow), () {
            final med = _med(
              type: MedicationType.course(
                startDate: start,
                durationDays: 10,
                pauseDays: 0,
              ),
              slots: <TimeSlot>[_slot(480)],
            );

            final result = expandDueDoses(
              meds: <Medication>[med],
              now: clock.now(),
            );

            expect(result, hasLength(1));
          });
        },
      );
    });
  });
}
