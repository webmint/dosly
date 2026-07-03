/// Drift table definition for user-confirmed intake events.
///
/// Lives in `core/database` (constitution §2.2). Drift is a `data`/`core`-layer
/// concern; the domain layer never imports this file. The [IntakeStatus] enum
/// imported here is a pure-Dart leaf type — importing it into a table
/// definition does not pull Flutter or drift into the domain.
///
/// STORAGE CONTRACT — the [status] column uses drift's `textEnum`, which
/// persists the enum value BY NAME (its identifier string), not its index. The
/// enum value names and the set of values are therefore an on-disk contract:
/// reordering is harmless for `textEnum` (names, not indices, are stored), but
/// RENAMING or REMOVING a value silently breaks reads of previously stored
/// rows. Any such change requires bumping [AppDatabase.schemaVersion] and
/// writing a migration.
///
/// COLUMN CONTRACT — never drop or alter an existing column without bumping
/// `schemaVersion` and adding a migration. This is health data; a lost or
/// silently-defaulted intake record can misrepresent whether a user took a dose.
library;

import 'package:drift/drift.dart';

import '../../../features/meds/domain/entities/intake_status.dart';
import 'medications_table.dart';

/// Stored intake events — one row per user-confirmed dose occurrence.
///
/// Each row maps to one domain `Intake`. Drift generates the data class
/// `IntakeRow` for this table (see [DataClassName]). A row records what the user
/// did with a single scheduled occurrence (taken/skipped) together with when it
/// was scheduled ([scheduledAt]) and when they acted ([confirmedAt]).
///
/// UNIQUENESS — [uniqueKeys] enforces one row per dose occurrence, keyed by
/// `{medicationId, slotId, scheduledAt}`. Drift emits a matching SQL `UNIQUE`
/// constraint so a duplicate confirmation for the same occurrence is rejected.
///
/// COLUMN CONTRACT — never drop or alter a column without bumping
/// [AppDatabase.schemaVersion] and writing a migration; this is health data.
@DataClassName('IntakeRow')
class Intakes extends Table {
  /// Stable unique identifier (domain `IntakeId` value). Primary key.
  TextColumn get id => text()();

  /// Owning medication. Cascades on delete so intakes never outlive their med.
  TextColumn get medicationId =>
      text().references(Medications, #id, onDelete: KeyAction.cascade)();

  /// The schedule slot this occurrence belongs to (domain `TimeSlot` id).
  ///
  /// Intentionally a PLAIN text column with NO foreign key. Slot rows are
  /// reconciled — inserted, updated, and deleted — whenever a medication's
  /// schedule is edited. An FK with `onDelete: cascade` would wipe historical
  /// intake rows the moment their slot was reconciled away, silently erasing a
  /// user's adherence history. Keeping [slotId] a plain column decouples intake
  /// history from slot reconciliation.
  TextColumn get slotId => text()();

  /// UTC instant of the scheduled dose (per the UTC-storage convention).
  DateTimeColumn get scheduledAt => dateTime()();

  /// UTC instant the user acted on the occurrence. `null` until confirmed.
  DateTimeColumn get confirmedAt => dateTime().nullable()();

  /// Lifecycle state of this occurrence. Stored by enum name.
  TextColumn get status => textEnum<IntakeStatus>()();

  /// Optional free-text notes. Unused in the current slice.
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {medicationId, slotId, scheduledAt},
  ];
}
