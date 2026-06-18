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
import '../../features/meds/domain/entities/medication_form.dart';
import '../../features/meds/domain/entities/schedule_frequency.dart';
import 'tables/medications_table.dart';
import 'tables/time_slots_table.dart';

part 'database.g.dart';

/// Application-wide drift database.
///
/// Holds the [Medications] and [TimeSlots] tables. Construct with no arguments
/// for the real on-device SQLite file, or pass a [QueryExecutor] (e.g. an
/// in-memory `NativeDatabase.memory()`) to inject a test database.
///
/// Foreign keys are enabled per connection in [migration]'s `beforeOpen`, so
/// the `onDelete: cascade` on [TimeSlots.medicationId] is enforced.
///
/// SCHEMA CONTRACT — see this file's library doc. Bumping [schemaVersion]
/// without a matching migration, or mutating a column without bumping it, will
/// corrupt or lose stored medication data.
@DriftDatabase(tables: [Medications, TimeSlots])
class AppDatabase extends _$AppDatabase {
  /// Creates the database.
  ///
  /// Pass [executor] to inject a custom backend (tests use an in-memory one);
  /// when omitted, opens the real on-device SQLite file via [_openConnection].
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      // Enforce foreign keys (incl. ON DELETE CASCADE) for every connection.
      await customStatement('pragma foreign_keys = ON;');
    },
  );

  static QueryExecutor _openConnection() => driftDatabase(name: 'dosly');
}
