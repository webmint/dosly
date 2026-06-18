/// Whether a medication is still being taken ([MedicationActivityStatus.active])
/// or its course has finished ([MedicationActivityStatus.completed]).
///
/// Pure Dart leaf type of the medication domain model — no Flutter, drift,
/// or uuid imports (constitution §2.1). See [MedicationActivityStatus].
library;

/// Derived activity state of a medication at a given instant.
///
/// This is a COMPUTED value, never stored: it is derived from the medication's
/// [MedicationType] and the current date (see `resolveMedicationActivity`).
/// Continuous medications are always [active]; a bounded, non-cyclic course
/// becomes [completed] once its final active day has passed.
enum MedicationActivityStatus {
  /// The medication is still being taken (continuous, or within its course).
  active,

  /// The medication's bounded course has run to its end.
  completed,
}
