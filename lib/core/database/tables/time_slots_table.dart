/// Drift table definition for a medication's intended daily intake times.
///
/// Lives in `core/database` (constitution §2.2). Drift is a `data`/`core`-layer
/// concern; the domain layer never imports this file. The [DoseUnit] enum
/// imported here is a pure-Dart leaf type.
///
/// STORAGE CONTRACT — the [doseUnit] column uses drift's `textEnum`, which
/// persists the enum value BY NAME (its identifier string), not its index.
/// Renaming or removing a [DoseUnit] value silently breaks reads of previously
/// stored rows; any such change requires bumping [AppDatabase.schemaVersion]
/// and writing a migration.
///
/// COLUMN CONTRACT — never drop or alter an existing column without bumping
/// `schemaVersion` and adding a migration. This is health data.
library;

import 'package:drift/drift.dart';

import '../../../features/meds/domain/entities/dose_unit.dart';
import 'medications_table.dart';

/// Per-day intended intake times for a medication.
///
/// Each row maps to one domain `TimeSlot`. Drift generates the data class
/// `TimeSlotRow` for this table (see [DataClassName]). [medicationId] is a
/// foreign key into [Medications]; deleting a medication cascades to delete its
/// time slots ([KeyAction.cascade]). The optional [doseAmount]/[doseUnit]
/// override the medication's default dose for this specific slot.
///
/// COLUMN CONTRACT — never drop or alter a column without bumping
/// [AppDatabase.schemaVersion] and writing a migration; this is health data.
@DataClassName('TimeSlotRow')
class TimeSlots extends Table {
  /// Stable unique identifier (domain `TimeSlot` id). Primary key.
  TextColumn get id => text()();

  /// Owning medication. Cascades on delete so slots never outlive their med.
  TextColumn get medicationId =>
      text().references(Medications, #id, onDelete: KeyAction.cascade)();

  /// Local time of day, in minutes from midnight (`0..1439`).
  IntColumn get minuteOfDay => integer()();

  /// Per-slot dose amount override. `null` uses the medication default.
  RealColumn get doseAmount => real().nullable()();

  /// Unit for [doseAmount] override. Stored by enum name. `null` uses default.
  TextColumn get doseUnit => textEnum<DoseUnit>().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
