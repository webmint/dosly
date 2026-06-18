/// Unit tests for [CourseProgress.resolve].
///
/// All dates are LOCAL [DateTime] objects so the day-boundary arithmetic in the
/// production code matches what these tests expect regardless of the machine's
/// timezone.  Every `now` value is derived by adding a fixed [Duration] to a
/// well-known `startDate` so the arithmetic is unambiguous and reviewable.
library;

import 'package:dosly/features/meds/domain/entities/course_phase.dart';
import 'package:dosly/features/meds/domain/entities/medication_type.dart';
import 'package:dosly/features/meds/domain/value_objects/course_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Anchor date used throughout — in June to avoid DST transitions that would
  // skew add(Duration(days: N)) by one hour and corrupt the local-day diff.
  final start = DateTime(2026, 6, 1); // 2026-06-01, day 0

  group('CourseProgress.resolve', () {
    // -------------------------------------------------------------------------
    // Non-cyclic course (pauseDays == 0)
    // -------------------------------------------------------------------------
    group('non-cyclic course (pauseDays == 0)', () {
      test(
        'should return currentDay 3, totalDays 7, phase activeWindow '
        'when now is day 2 of a 7-day course',
        () {
          // day 0 = startDate; day 2 = startDate + 2 days → 1-based day 3
          final now = start.add(const Duration(days: 2));
          final course = CourseType(
            startDate: start,
            durationDays: 7,
            pauseDays: 0,
          );

          final result = CourseProgress.resolve(course: course, now: now);

          expect(result.currentDay, 3);
          expect(result.totalDays, 7);
          expect(result.phase, CoursePhase.activeWindow);
        },
      );

      test(
        'should return currentDay 7, phase activeWindow '
        'when now is the last active day (day 6 of a 7-day course)',
        () {
          // day 6 (0-based) → 1-based day 7, still inside the window
          final now = start.add(const Duration(days: 6));
          final course = CourseType(
            startDate: start,
            durationDays: 7,
            pauseDays: 0,
          );

          final result = CourseProgress.resolve(course: course, now: now);

          expect(result.currentDay, 7);
          expect(result.totalDays, 7);
          expect(result.phase, CoursePhase.activeWindow);
        },
      );

      test(
        'should clamp currentDay to 7, phase activeWindow '
        'when now is one day PAST the end of a 7-day course',
        () {
          // Non-cyclic courses never enter a paused phase; they are clamped at
          // totalDays.  The inclusive end-date boundary is day 6 (0-based);
          // day 7 (0-based) is past the window but still clamped, not paused.
          final now = start.add(const Duration(days: 7));
          final course = CourseType(
            startDate: start,
            durationDays: 7,
            pauseDays: 0,
          );

          final result = CourseProgress.resolve(course: course, now: now);

          expect(result.currentDay, 7); // clamped, never exceeds totalDays
          expect(result.totalDays, 7);
          expect(result.phase, CoursePhase.activeWindow);
        },
      );

      test(
        'should return currentDay 31 across a span crossing EU spring-forward '
        '(DST-robustness guard)',
        () {
          // DST-robustness guard. The 2026 EU spring-forward (clocks jump from
          // 02:00 to 03:00) falls on 2026-03-29, inside this span. Dates are
          // built as explicit LOCAL literals — NOT start.add(Duration(days:30))
          // — because Duration arithmetic across a DST transition is itself
          // unreliable and would silently skew the input.
          //
          // March 2 → April 1 is exactly 30 calendar days (March 2 = day 1, so
          // April 1 = currentDay 31). A local-midnight `_localDate` would
          // measure the physical span as 30*24h - 1h and `.inDays` would
          // truncate to 29 calendar days (currentDay 30) in any DST timezone.
          // The UTC-anchoring in `_localDate` makes the count exactly 30 whole
          // calendar days regardless of the machine's timezone.
          final dstStart = DateTime(2026, 3, 2);
          final dstNow = DateTime(2026, 4, 1);
          final course = CourseType(
            // durationDays 60 keeps `now` inside the active window so the
            // counter is exercised, not clamped at totalDays.
            startDate: dstStart,
            durationDays: 60,
            pauseDays: 0,
          );

          final result = CourseProgress.resolve(course: course, now: dstNow);

          expect(result.currentDay, 31);
          expect(result.totalDays, 60);
          expect(result.phase, CoursePhase.activeWindow);
        },
      );
    });

    // -------------------------------------------------------------------------
    // Cyclic course (pauseDays > 0)
    // -------------------------------------------------------------------------
    group('cyclic course (pauseDays > 0)', () {
      test(
        'should return currentDay 8, totalDays 30, phase activeWindow '
        'when now is day 7 of a 30-day / 7-day-pause course',
        () {
          // cycleLen = 37; posInCycle = 7 % 37 = 7; 7 < 30 → activeWindow
          // 1-based day = 7 + 1 = 8
          final now = start.add(const Duration(days: 7));
          final course = CourseType(
            startDate: start,
            durationDays: 30,
            pauseDays: 7,
          );

          final result = CourseProgress.resolve(course: course, now: now);

          expect(result.currentDay, 8);
          expect(result.totalDays, 30);
          expect(result.phase, CoursePhase.activeWindow);
        },
      );

      test(
        'should return phase paused, currentDay pinned to 10 '
        'when now is in the pause gap (day 15 of a dur-10 / pause-20 course)',
        () {
          // cycleLen = 30; posInCycle = 15 % 30 = 15; 15 >= 10 → pause gap.
          // Day 31 was intentionally avoided: 31 % 30 = 1 < 10 → activeWindow
          // (that would be the START of the second active window, not the gap).
          // Day 15 is squarely in the 20-day pause that follows the first
          // 10-day active window.
          final now = start.add(const Duration(days: 15));
          final course = CourseType(
            startDate: start,
            durationDays: 10,
            pauseDays: 20,
          );

          final result = CourseProgress.resolve(course: course, now: now);

          expect(result.phase, CoursePhase.paused);
          // currentDay is pinned to durationDays (10) while in the pause gap
          expect(result.currentDay, 10);
          expect(result.totalDays, 10);
        },
      );

      test(
        'should return currentDay 1, phase activeWindow '
        'when now is exactly at the cycleLen boundary (wraps into new cycle)',
        () {
          // cycleLen = 30; posInCycle = 30 % 30 = 0; 0 < 10 → activeWindow
          // 1-based day = 0 + 1 = 1 (first day of the new active window)
          final now = start.add(const Duration(days: 30)); // exactly cycleLen
          final course = CourseType(
            startDate: start,
            durationDays: 10,
            pauseDays: 20,
          );

          final result = CourseProgress.resolve(course: course, now: now);

          expect(result.currentDay, 1);
          expect(result.phase, CoursePhase.activeWindow);
          expect(result.totalDays, 10);
        },
      );
    });

    // -------------------------------------------------------------------------
    // Future-dated start
    // -------------------------------------------------------------------------
    group('future-dated start', () {
      test(
        'should return currentDay 1, phase activeWindow '
        'when now is strictly before startDate',
        () {
          // now is one day before startDate → daysSinceStart = -1 → anchor to day 1
          final now = start.subtract(const Duration(days: 1));
          final course = CourseType(
            startDate: start,
            durationDays: 7,
            pauseDays: 0,
          );

          final result = CourseProgress.resolve(course: course, now: now);

          expect(result.currentDay, 1);
          expect(result.totalDays, 7);
          expect(result.phase, CoursePhase.activeWindow);
        },
      );
    });

    // -------------------------------------------------------------------------
    // Intraday stability
    // -------------------------------------------------------------------------
    group('intraday stability', () {
      test(
        'should return the same currentDay for 00:01 and 23:59 on the same '
        'calendar date',
        () {
          // Two instants on the same LOCAL calendar day must hash to the same
          // day number because _localDate strips the time component.
          final base = start.add(const Duration(days: 4)); // day 4 (0-based)
          final earlyMorning =
              DateTime(base.year, base.month, base.day, 0, 1); // 00:01
          final lateNight =
              DateTime(base.year, base.month, base.day, 23, 59); // 23:59

          final course = CourseType(
            startDate: start,
            durationDays: 14,
            pauseDays: 0,
          );

          final resultEarly =
              CourseProgress.resolve(course: course, now: earlyMorning);
          final resultLate =
              CourseProgress.resolve(course: course, now: lateNight);

          expect(resultEarly, resultLate);
        },
      );
    });
  });
}
