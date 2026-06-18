/// Which part of a cyclic course's rhythm the medication is currently in:
/// an active intake window ([CoursePhase.activeWindow]) or an off-day gap
/// ([CoursePhase.paused]).
///
/// Pure Dart leaf type of the medication domain model — no Flutter, drift,
/// or uuid imports (constitution §2.1). See [CoursePhase].
library;

/// Derived phase of a course's cycle at a given instant.
///
/// This is a COMPUTED value, never stored: it is derived from the course's
/// timing and the current date (see `CourseProgress.resolve`). Non-cyclic
/// courses are always in the [activeWindow] phase; cyclic courses alternate
/// between [activeWindow] (active intake days) and [paused] (off days).
enum CoursePhase {
  /// The medication is within an active intake window of the course.
  activeWindow,

  /// The medication is in an off-day gap between active windows.
  paused,
}
