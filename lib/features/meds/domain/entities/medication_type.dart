/// How a medication is taken over time: indefinitely ([ContinuousType]) or as
/// a bounded/cyclic [CourseType].
///
/// Pure Dart leaf type of the medication domain model — no Flutter, drift,
/// or uuid imports (constitution §2.1). See [MedicationType].
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'medication_type.freezed.dart';

/// The temporal pattern by which a medication is taken.
///
/// A `freezed` sealed union with two variants:
///
/// * [ContinuousType] — taken indefinitely from [ContinuousType.startDate], with
///   no end.
/// * [CourseType] — taken for a fixed number of days, optionally repeating in
///   cycles separated by pause periods.
///
/// Sealed so that the compiler enforces exhaustive handling of every variant in
/// `switch` expressions. Each factory redirects to a public subclass, so call
/// sites can use either the union factory (`MedicationType.course(...)`) or the
/// subclass directly (`CourseType(...)`). Equality and `hashCode` are generated
/// by freezed.
@freezed
sealed class MedicationType with _$MedicationType {
  /// A medication taken indefinitely, starting on [startDate].
  ///
  /// There is no end date — the medication is assumed to continue until the
  /// user stops or deletes it.
  const factory MedicationType.continuous({
    /// Local calendar date on which the medication regimen begins.
    required DateTime startDate,
  }) = ContinuousType;

  /// A medication taken for a bounded course of [durationDays] days, optionally
  /// repeating in cycles.
  ///
  /// The course's end date is DERIVED, not stored: it is
  /// `startDate + durationDays − 1` (the last active day, inclusive of
  /// [startDate]). For example, a 7-day course starting on the 1st runs through
  /// the 7th.
  ///
  /// [pauseDays] controls cyclic behaviour:
  ///
  /// * `pauseDays > 0` ⇒ the course is cyclic: an active window of
  ///   [durationDays] is followed by a gap of [pauseDays] days, then repeats.
  /// * `pauseDays == 0` ⇒ a single bounded course with no repetition.
  const factory MedicationType.course({
    /// Local calendar date on which the (first) course begins.
    required DateTime startDate,

    /// Number of active days in a single course window. The derived end date of
    /// the first window is `startDate + durationDays − 1`.
    required int durationDays,

    /// Number of off days between consecutive course windows. `0` means the
    /// course does not repeat; any value `> 0` makes the course cyclic.
    required int pauseDays,
  }) = CourseType;
}
