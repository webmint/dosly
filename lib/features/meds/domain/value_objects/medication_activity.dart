/// Derivation of a medication's Active/Completed status from its temporal
/// [MedicationType] and the current date.
///
/// Pure Dart derivation of the medication domain model — no Flutter, drift,
/// or uuid imports (constitution §2.1). All date math compares LOCAL calendar
/// dates so intraday time and DST shifts never move the day boundary.
library;

import '../entities/medication.dart';
import '../entities/medication_activity_status.dart';
import '../entities/medication_type.dart';

/// Reduces [d] to its LOCAL calendar date (year/month/day), anchored to UTC so
/// the time-of-day component is discarded and every per-day span is exactly 24h.
///
/// Stored start dates are UTC with drift's local flag; comparing local calendar
/// dates (rather than raw instants) keeps the day boundary stable across
/// intraday time, avoiding the instant-equality trap. The returned value uses
/// the LOCAL year/month/day but constructs them as a UTC midnight: UTC has no
/// DST, so `_localDate(a).difference(_localDate(b)).inDays` counts whole
/// calendar days without DST drift. A local-midnight constructor would make a
/// span crossing a spring-forward boundary only `N*24h - 1h`, which `.inDays`
/// would truncate to `N - 1` (an off-by-one in the active/completed boundary).
DateTime _localDate(DateTime d) {
  final DateTime local = d.toLocal();
  return DateTime.utc(local.year, local.month, local.day);
}

/// Resolves the [MedicationActivityStatus] of [medication] as of [now].
///
/// Continuous medications are always [MedicationActivityStatus.active]. Course
/// medications are [MedicationActivityStatus.active] while within their course
/// window and [MedicationActivityStatus.completed] once a non-cyclic course has
/// passed its final active day (`daysSinceStart > durationDays - 1`); cyclic
/// courses (`pauseDays > 0`) repeat indefinitely and never complete.
///
/// Compares LOCAL calendar dates, so intraday time and DST shifts never move
/// the day boundary. `daysSinceStart` is `0` on the start day.
MedicationActivityStatus resolveMedicationActivity(
  Medication medication,
  DateTime now,
) {
  switch (medication.type) {
    case ContinuousType():
      // No end date — a continuous medication is always active.
      return MedicationActivityStatus.active;
    case CourseType(
      :final DateTime startDate,
      :final int durationDays,
      :final int pauseDays,
    ):
      if (pauseDays > 0) {
        // Cyclic courses repeat indefinitely and never complete.
        return MedicationActivityStatus.active;
      }
      // Non-cyclic: active until the final active day has passed.
      final int daysSinceStart =
          _localDate(now).difference(_localDate(startDate)).inDays;
      return daysSinceStart <= durationDays - 1
          ? MedicationActivityStatus.active
          : MedicationActivityStatus.completed;
  }
}
