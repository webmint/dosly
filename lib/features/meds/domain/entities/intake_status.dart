/// Lifecycle state of a single scheduled medication intake.
///
/// Pure Dart leaf type of the medication domain model — no Flutter, drift,
/// or uuid imports (constitution §2.1). See [IntakeStatus].
library;

/// The state of one scheduled intake occurrence within the intake state
/// machine (constitution §5.2).
///
/// STORAGE CONTRACT: these values are persisted by **name** via drift's
/// `textEnum` column. The order and the names below ARE the on-disk format.
/// Do NOT reorder, rename, or remove any value without a `schemaVersion` bump
/// plus a migration. New values may be appended at the end.
///
/// SLICE NOTE: in the current slice only [taken] and [skipped] are ever
/// persisted. [pending] is the derived "no intake row exists yet" state (an
/// occurrence that has neither been confirmed nor skipped) and is never
/// written to storage. [missed] is reserved for a later feature (the
/// window-expiry auto-transition described in §5.2) and is not produced yet.
enum IntakeStatus {
  /// Not yet acted upon. Derived state for a scheduled occurrence that has no
  /// persisted intake row; never stored.
  pending,

  /// The user confirmed the medication was taken.
  taken,

  /// The intake window elapsed without confirmation. Reserved for a later
  /// feature; not produced in the current slice.
  missed,

  /// The user explicitly opted out of this occurrence.
  skipped,
}
