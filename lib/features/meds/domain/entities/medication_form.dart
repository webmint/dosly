/// Physical form a medication is taken in (tablet, syrup, injection, …).
///
/// Pure Dart leaf type of the medication domain model — no Flutter, drift,
/// or uuid imports (constitution §2.1). See [MedicationForm].
library;

/// The physical form a medication takes.
///
/// STORAGE CONTRACT: these values are persisted by **name** via drift's
/// `textEnum` column. The order and the names below ARE the on-disk format.
/// Do NOT reorder or rename any value, and do NOT remove values, without a
/// corresponding database migration — doing so will silently corrupt or fail
/// to read previously stored medications. New values may be appended at the
/// end (still requires a migration plan for older app versions).
enum MedicationForm {
  /// Solid pill swallowed whole.
  tablet,

  /// Gelatin-shell capsule.
  capsule,

  /// Liquid taken by mouth.
  syrup,

  /// Liquid measured in drops.
  drops,

  /// Administered by injection.
  injection,

  /// Inhaled via an inhaler device.
  inhaler,

  /// Topical cream or ointment.
  cream,

  /// Single-dose powder sachet.
  sachet,
}
