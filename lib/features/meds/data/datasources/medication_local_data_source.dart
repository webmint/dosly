/// Low-level data source that writes medication records to the local drift
/// database.
///
/// Lives in `data/datasources` (constitution §2.1): it owns the drift queries
/// for the medication aggregate and exposes a narrow, exception-throwing API.
/// Translating any thrown exception into a `Failure` is the repository's job —
/// this class never returns `Either`.
library;

import '../../../../core/database/database.dart';

/// Persists medication aggregates to the local drift [AppDatabase].
///
/// Operates on drift companions produced by the medication mapper. Writes are
/// atomic: a medication and all of its time slots are inserted inside a single
/// transaction, so a failure mid-write leaves no orphaned medication row.
///
/// Throws on failure (e.g. `SqliteException`); callers in the repository layer
/// catch and convert these into `Left(Failure)`.
class MedicationLocalDataSource {
  /// Creates a data source backed by [_db].
  const MedicationLocalDataSource(this._db);

  final AppDatabase _db;

  /// Inserts [medication] and its [slots] in a single transaction.
  ///
  /// The medication row is inserted first, then all time-slot rows are inserted
  /// as a batch so their `medicationId` foreign keys resolve. If any insert
  /// fails the whole transaction is rolled back, guaranteeing the database
  /// never holds a medication without its scheduled slots (or vice versa).
  Future<void> insertMedication(
    MedicationsCompanion medication,
    List<TimeSlotsCompanion> slots,
  ) async {
    await _db.transaction(() async {
      await _db.into(_db.medications).insert(medication);
      await _db.batch((b) => b.insertAll(_db.timeSlots, slots));
    });
  }
}
