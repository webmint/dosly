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
/// SLICE NOTE: [taken] and [skipped] are persisted when the user acts on an
/// occurrence. [pending] is the derived "no intake row exists yet" state (an
/// occurrence that has neither been confirmed nor skipped) and is never
/// written to storage. [missed] is written by the auto-miss reconcile engine
/// (`ReconcileMissedIntakes`, spec 040) when a dose's intake window elapses
/// without action (the window-expiry auto-transition described in §5.2).
enum IntakeStatus {
  /// Not yet acted upon. Derived state for a scheduled occurrence that has no
  /// persisted intake row; never stored.
  pending,

  /// The user confirmed the medication was taken.
  taken,

  /// The intake window elapsed without confirmation. Written by the
  /// auto-miss reconcile engine (`ReconcileMissedIntakes`, spec 040,
  /// constitution §5.2) — never set directly by user action.
  missed,

  /// The user explicitly opted out of this occurrence.
  skipped,
}
