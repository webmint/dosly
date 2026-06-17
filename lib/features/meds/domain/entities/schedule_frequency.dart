/// How often a medication schedule repeats.
///
/// Pure Dart leaf type of the medication domain model — no Flutter, drift,
/// or uuid imports (constitution §2.1). See [ScheduleFrequency].
library;

/// The recurrence frequency of a medication schedule.
///
/// Currently only [daily] is supported; additional frequencies (e.g. weekly,
/// custom intervals) may be appended in future iterations.
///
/// STORAGE CONTRACT: these values are persisted by **name** via drift's
/// `textEnum` column. The order and the names below ARE the on-disk format.
/// Do NOT reorder or rename any value without a database migration. New
/// values may be appended at the end.
enum ScheduleFrequency {
  /// Repeats every day.
  daily,
}
