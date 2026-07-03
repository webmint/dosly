/// Policy constant for the intake undo grace period.
///
/// Pure Dart leaf of the medication domain model — no Flutter, drift, or uuid
/// imports (constitution §2.1). See [kIntakeUndoGracePeriod].
library;

/// How long after marking an intake `taken` the user may still undo it back to
/// `pending` (constitution §5.2 "Grace period").
///
/// Defaults to 5 minutes. This is the fixed policy for the current slice; it
/// will become Settings-configurable (§5.2 range: 0–30 minutes) in a future
/// feature, at which point this constant becomes the default rather than the
/// hard-coded value.
const Duration kIntakeUndoGracePeriod = Duration(minutes: 5);
