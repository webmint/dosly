/// Unit of measure for a single medication dose (tablet, ml, mg, puff, …).
///
/// Pure Dart leaf type of the medication domain model — no Flutter, drift,
/// or uuid imports (constitution §2.1). See [DoseUnit].
library;

/// The unit a dose amount is measured in.
///
/// STORAGE CONTRACT: these values are persisted by **name** via drift's
/// `textEnum` column. The order and the names below ARE the on-disk format.
/// Do NOT reorder or rename any value, and do NOT remove values, without a
/// corresponding database migration. New values may be appended at the end
/// (still requires a migration plan for older app versions).
enum DoseUnit {
  /// Count of tablets.
  tablet,

  /// Count of capsules.
  capsule,

  /// Millilitres of liquid.
  ml,

  /// Milligrams of active substance.
  mg,

  /// Count of drops.
  drops,

  /// International units (or generic "units").
  units,

  /// Inhaler puffs.
  puff,

  /// Topical applications.
  application,

  /// Count of sachets.
  sachet,
}
