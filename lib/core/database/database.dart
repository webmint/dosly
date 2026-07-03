/// The app's local drift database.
///
/// dosly is fully local-on-device (constitution §1): all medication and
/// schedule data lives here, never in `SharedPreferences` and never in the
/// cloud. This is the system of record for health data.
///
/// SCHEMA CONTRACT — never drop or alter a column, and never rename/remove a
/// stored enum value, without bumping [AppDatabase.schemaVersion] and writing a
/// migration (constitution §4.2.1, §6.5). Losing or silently defaulting health
/// data is unacceptable.
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/meds/domain/entities/dose_unit.dart';
import '../../features/meds/domain/entities/intake_status.dart';
import '../../features/meds/domain/entities/medication_form.dart';
import '../../features/meds/domain/entities/schedule_frequency.dart';
import 'tables/intakes_table.dart';
import 'tables/medications_table.dart';
import 'tables/time_slots_table.dart';

part 'database.g.dart';

/// Application-wide drift database.
///
/// Holds the [Medications], [TimeSlots], and [Intakes] tables. Construct with no
/// arguments for the real on-device SQLite file, or pass a [QueryExecutor]
/// (e.g. an in-memory `NativeDatabase.memory()`) to inject a test database.
///
/// Foreign keys are enabled per connection in [migration]'s `beforeOpen`, so
/// the `onDelete: cascade` on [TimeSlots.medicationId] is enforced.
///
/// SCHEMA HISTORY —
/// - v1: [Medications] + [TimeSlots].
/// - v2: adds [Intakes]. The v1→v2 migration is ADD-ONLY: it creates the new
///   `intakes` table and alters no existing column or table.
///
/// SCHEMA CONTRACT — see this file's library doc. Bumping [schemaVersion]
/// without a matching migration, or mutating a column without bumping it, will
/// corrupt or lose stored medication data.
@DriftDatabase(tables: [Medications, TimeSlots, Intakes])
class AppDatabase extends _$AppDatabase {
  /// Creates the database.
  ///
  /// Pass [executor] to inject a custom backend (tests use an in-memory one);
  /// when omitted, opens the real on-device SQLite file via [_openConnection].
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      // v1→v2: add-only. Create the new intakes table; alter nothing else.
      if (from < 2) {
        await m.createTable(intakes);
      }
    },
    beforeOpen: (details) async {
      // Enforce foreign keys (incl. ON DELETE CASCADE) for every connection.
      await customStatement('pragma foreign_keys = ON;');
    },
  );

  static QueryExecutor _openConnection() => driftDatabase(name: 'dosly');
}
