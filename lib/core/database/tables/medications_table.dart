/// Drift table definition for stored medications.
///
/// Lives in `core/database` (constitution §2.2). Drift is a `data`/`core`-layer
/// concern; the domain layer never imports this file. The domain enums imported
/// here ([MedicationForm], [DoseUnit], [ScheduleFrequency]) are pure-Dart leaf
/// types — importing them into a table definition does not pull Flutter or drift
/// into the domain.
///
/// STORAGE CONTRACT — enum columns use drift's `textEnum`, which persists the
/// enum value BY NAME (its identifier string), not its index. The enum value
/// names and the set of values are therefore an on-disk contract: reordering is
/// harmless for `textEnum` (names, not indices, are stored), but RENAMING or
/// REMOVING a value silently breaks reads of previously stored rows. Any such
/// change requires bumping [AppDatabase.schemaVersion] and writing a migration.
///
/// COLUMN CONTRACT — never drop or alter an existing column without bumping
/// `schemaVersion` and adding a migration. This is health data; a lost or
/// silently-defaulted column can corrupt a user's medication record.
library;

import 'package:drift/drift.dart';

import '../../../features/meds/domain/entities/dose_unit.dart';
import '../../../features/meds/domain/entities/medication_form.dart';
import '../../../features/meds/domain/entities/schedule_frequency.dart';

/// Discriminator for how a medication's course is bounded in time.
///
/// This is the storage-side counterpart of the domain `MedicationType` sealed
/// union: a [MedicationRow] is either [continuous] (taken indefinitely) or a
/// [course] (bounded/cyclic, using `durationDays` / `pauseDays`). The mapper
/// translates between this discriminator and the domain union.
///
/// STORAGE CONTRACT — persisted by NAME via `textEnum`. Renaming or removing a
/// value requires a schema migration (see this file's library doc).
enum MedicationTypeKind {
  /// Taken indefinitely until the medication is deleted.
  continuous,

  /// Bounded course (optionally cyclic via `pauseDays`).
  course,
}

/// Stored medications.
///
/// Each row maps to one domain `Medication`. Drift generates the data class
/// `MedicationRow` for this table (see [DataClassName]). Nullable columns hold
/// optional domain concepts: per-intake dose ([doseAmount]/[doseUnit]), course
/// bounds ([durationDays]/[pauseDays]), and pack inventory
/// ([stockRemaining]/[stockTotal]/[stockWarnAt]).
///
/// COLUMN CONTRACT — never drop or alter a column without bumping
/// [AppDatabase.schemaVersion] and writing a migration; this is health data.
@DataClassName('MedicationRow')
class Medications extends Table {
  /// Stable unique identifier (domain `MedicationId` value). Primary key.
  TextColumn get id => text()();

  /// Display name of the medication.
  TextColumn get name => text()();

  /// Physical form (tablet, syrup, …). Stored by enum name.
  TextColumn get form => textEnum<MedicationForm>()();

  /// Per-intake dose amount, when a dose is tracked. `null` when untracked.
  RealColumn get doseAmount => real().nullable()();

  /// Unit for [doseAmount], when a dose is tracked. Stored by enum name.
  TextColumn get doseUnit => textEnum<DoseUnit>().nullable()();

  /// Whether this medication is continuous or a (cyclic) course.
  TextColumn get typeKind => textEnum<MedicationTypeKind>()();

  /// Recurrence frequency. Non-nullable; the mapper always supplies it (MVP
  /// defaults to `daily`), so no DB default is needed. Stored by enum name.
  TextColumn get frequency => textEnum<ScheduleFrequency>()();

  /// First day the medication applies (UTC, per the UTC-storage convention).
  DateTimeColumn get startDate => dateTime()();

  /// Course duration in days. `null` for continuous medications.
  IntColumn get durationDays => integer().nullable()();

  /// Pause length in days for a cyclic course (`0` = single bounded course).
  /// `null` for continuous medications.
  IntColumn get pauseDays => integer().nullable()();

  /// Remaining pack inventory. `null` when stock is not tracked.
  IntColumn get stockRemaining => integer().nullable()();

  /// Total pack inventory. `null` when stock is not tracked.
  IntColumn get stockTotal => integer().nullable()();

  /// Low-stock warning threshold. `null` when stock is not tracked.
  IntColumn get stockWarnAt => integer().nullable()();

  /// Optional free-text notes.
  TextColumn get notes => text().nullable()();

  /// Creation timestamp (UTC).
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
