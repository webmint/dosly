/// DST-safe reduction of an instant to its LOCAL calendar date, anchored to
/// UTC-midnight so whole-calendar-day arithmetic never drifts across
/// daylight-saving transitions.
///
/// Pure Dart helper of the medication domain model — no Flutter, drift, or
/// uuid imports (constitution §2.1). See [localCalendarDate].
///
/// ## Why anchor the local date to UTC-midnight?
///
/// Stored dates are UTC instants; the user reasons in their LOCAL calendar.
/// To decide "is this the same calendar day / how many whole days apart", we
/// must compare LOCAL year/month/day, not raw instants (two instants seconds
/// apart can straddle midnight). But we also must NOT build the reduced value
/// with a LOCAL-midnight constructor: `DateTime(y, m, d)` is a local wall-clock
/// time, and a span between two local midnights that crosses a spring-forward
/// boundary is only `N*24h - 1h`. `Duration.inDays` truncates toward zero, so
/// that span reports `N - 1` whole days — an off-by-one in every day counter.
///
/// Anchoring to `DateTime.utc(y, m, d)` keeps the LOCAL year/month/day but
/// removes DST from the arithmetic entirely: UTC has no DST, so every
/// per-day span is exactly 24h and `localCalendarDate(a).difference(
/// localCalendarDate(b)).inDays` counts whole calendar days regardless of the
/// machine's timezone.
library;

/// Reduces [d] to its LOCAL calendar date (year/month/day), returned as a
/// UTC-midnight [DateTime].
///
/// The time-of-day component is discarded. The result carries the LOCAL
/// year/month/day of [d] but is constructed as UTC midnight so that
/// `.difference(...).inDays` and date comparisons (`isBefore` / `isAfter` /
/// `==`) count whole calendar days without daylight-saving drift. See the
/// library-level documentation for the full DST rationale.
///
/// This is the shared, public counterpart of the private `_localDate` idiom
/// duplicated inside `course_progress.dart` and `medication_activity.dart`;
/// new call sites should prefer this function.
DateTime localCalendarDate(DateTime d) {
  final DateTime local = d.toLocal();
  return DateTime.utc(local.year, local.month, local.day);
}
