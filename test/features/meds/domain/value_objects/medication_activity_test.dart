/// Unit tests for [resolveMedicationActivity].
///
/// All dates are LOCAL [DateTime] objects so the day-boundary arithmetic in the
/// production code matches what these tests expect regardless of the machine's
/// timezone.
///
/// A private [_med] helper constructs the minimal [Medication] required to
/// exercise the derivation under test without importing drift or uuid.
library;

import 'package:clock/clock.dart';
import 'package:dosly/features/meds/domain/entities/medication.dart';
import 'package:dosly/features/meds/domain/entities/medication_activity_status.dart';
import 'package:dosly/features/meds/domain/entities/medication_form.dart';
import 'package:dosly/features/meds/domain/entities/medication_type.dart';
import 'package:dosly/features/meds/domain/entities/schedule.dart';
import 'package:dosly/features/meds/domain/value_objects/medication_activity.dart';
import 'package:dosly/features/meds/domain/value_objects/medication_id.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Minimal fixture builder
// ---------------------------------------------------------------------------

/// Fixed creation timestamp used by all fixtures — not relevant to activity
/// resolution but required by the [Medication] constructor.
final _createdAt = DateTime(2026, 1, 1);

/// Builds the smallest valid [Medication] for a given [type].
///
/// All non-type fields (id, name, form, schedule) use stable stub values so
/// the tests remain focused on the temporal logic under test.
Medication _med({required MedicationType type}) => Medication(
      id: const MedicationId('test-med'),
      name: 'Test Medication',
      form: MedicationForm.tablet,
      type: type,
      schedule: const Schedule(slots: []),
      createdAt: _createdAt,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // Anchor date for all cases — in June to avoid DST transitions that would
  // skew add(Duration(days: N)) by one hour and corrupt the local-day diff.
  final start = DateTime(2026, 6, 1); // 2026-06-01

  group('resolveMedicationActivity', () {
    // -------------------------------------------------------------------------
    // Continuous medication
    // -------------------------------------------------------------------------
    group('continuous medication', () {
      test('should return active for a continuous medication at any time', () {
        final med = _med(
          type: MedicationType.continuous(startDate: start),
        );
        // Continuous medications never complete — no end date exists.
        final result = resolveMedicationActivity(med, start.add(const Duration(days: 9999)));

        expect(result, MedicationActivityStatus.active);
      });
    });

    // -------------------------------------------------------------------------
    // Cyclic course (pauseDays > 0) — never completes
    // -------------------------------------------------------------------------
    group('cyclic course (pauseDays > 0)', () {
      test(
        'should return active for a cyclic course well past its first window',
        () {
          // Cyclic courses repeat indefinitely and never transition to completed.
          // Using a large offset (200 days) to prove it stays active beyond
          // multiple cycle repetitions.
          final med = _med(
            type: MedicationType.course(
              startDate: start,
              durationDays: 10,
              pauseDays: 5,
            ),
          );
          final now = start.add(const Duration(days: 200));

          final result = resolveMedicationActivity(med, now);

          expect(result, MedicationActivityStatus.active);
        },
      );
    });

    // -------------------------------------------------------------------------
    // Non-cyclic course (pauseDays == 0) — inclusive final-day boundary
    // -------------------------------------------------------------------------
    group('non-cyclic course (pauseDays == 0) — boundary', () {
      test(
        'should return active when now is the FINAL active day of the course '
        '(inclusive boundary: startDate + durationDays - 1)',
        () {
          // The last valid intake day is startDate + durationDays - 1.
          // daysSinceStart == durationDays - 1 → still active (≤ durationDays - 1).
          final med = _med(
            type: MedicationType.course(
              startDate: start,
              durationDays: 7,
              pauseDays: 0,
            ),
          );
          // Final active day: start + 6 days (0-based day 6, i.e. the 7th day)
          final now = start.add(const Duration(days: 6));

          final result = resolveMedicationActivity(med, now);

          expect(result, MedicationActivityStatus.active);
        },
      );

      test(
        'should return completed the day AFTER the final active day '
        '(now == startDate + durationDays)',
        () {
          // daysSinceStart == durationDays (7) → 7 > 7 - 1 → completed.
          // This verifies the exclusive-end semantics: the window is
          // [startDate, startDate + durationDays - 1] inclusive.
          final med = _med(
            type: MedicationType.course(
              startDate: start,
              durationDays: 7,
              pauseDays: 0,
            ),
          );
          // One day after the final active day
          final now = start.add(const Duration(days: 7));

          final result = resolveMedicationActivity(med, now);

          expect(result, MedicationActivityStatus.completed);
        },
      );
    });

    // -------------------------------------------------------------------------
    // Ambient-clock integration: withClock + Clock.fixed
    // -------------------------------------------------------------------------
    group('ambient-clock integration', () {
      test(
        'should return active when ambient clock is fixed to a day inside a '
        'non-cyclic course window',
        () {
          // This case proves that callers using clock.now() as the `now`
          // argument correctly observe the fixed ambient clock.
          final fixedNow = start.add(const Duration(days: 3));
          final fixedClock = Clock.fixed(fixedNow);

          withClock(fixedClock, () {
            final med = _med(
              type: MedicationType.course(
                startDate: start,
                durationDays: 10,
                pauseDays: 0,
              ),
            );

            // Pass clock.now() as the explicit `now` argument — the derivation
            // receives the fixed instant, not the real wall clock.
            final result = resolveMedicationActivity(med, clock.now());

            expect(result, MedicationActivityStatus.active);
          });
        },
      );

      test(
        'should return completed when ambient clock is fixed to a day after '
        'a non-cyclic course has ended',
        () {
          // Fixed clock is set to one day past the 5-day course end.
          final fixedNow = start.add(const Duration(days: 5)); // day 5 (0-based) > 4
          final fixedClock = Clock.fixed(fixedNow);

          withClock(fixedClock, () {
            final med = _med(
              type: MedicationType.course(
                startDate: start,
                durationDays: 5,
                pauseDays: 0,
              ),
            );

            final result = resolveMedicationActivity(med, clock.now());

            expect(result, MedicationActivityStatus.completed);
          });
        },
      );
    });
  });
}
