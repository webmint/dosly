/// Low-level data source that writes medication records to the local drift
/// database.
///
/// Lives in `data/datasources` (constitution §2.1): it owns the drift queries
/// for the medication aggregate and exposes a narrow, exception-throwing API.
/// Translating any thrown exception into a `Failure` is the repository's job —
/// this class never returns `Either`.
library;

import 'package:drift/drift.dart';

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

  /// Watches all medications joined with their time slots, re-emitting whenever
  /// either table changes.
  ///
  /// Runs a watched left-outer join of `medications ⨝ time_slots` so the stream
  /// fires on any insert/update/delete to *either* table. The flat join result
  /// (one row per medication × slot pair) is grouped into one entry per
  /// medication, each pairing its [MedicationRow] with the ordered list of its
  /// [TimeSlotRow]s. Because the join is a left outer join, a medication with no
  /// time slots is still emitted, paired with an empty slot list. Medications
  /// are emitted in their first-seen (query) order.
  ///
  /// Throws on query failure (e.g. `SqliteException`); the repository layer
  /// catches and converts these into `Left(Failure)`.
  Stream<List<(MedicationRow, List<TimeSlotRow>)>> watchAllMedications() {
    final JoinedSelectStatement<HasResultSet, dynamic> query =
        _db.select(_db.medications).join([
          leftOuterJoin(
            _db.timeSlots,
            _db.timeSlots.medicationId.equalsExp(_db.medications.id),
          ),
        ]);
    return query.watch().map((rows) {
      // Group the flat (medication × slot) result rows by medication id,
      // preserving first-seen order and keeping meds that have no slots (the
      // left join yields a null time-slot row for those).
      final Map<String, MedicationRow> meds = <String, MedicationRow>{};
      final Map<String, List<TimeSlotRow>> slots =
          <String, List<TimeSlotRow>>{};
      final List<String> order = <String>[];
      for (final row in rows) {
        final MedicationRow med = row.readTable(_db.medications);
        // Capture the (possibly new) slot list in a local so the later `.add`
        // never needs a `!` to assert the map entry exists.
        final List<TimeSlotRow> medSlots = slots.putIfAbsent(
          med.id,
          () => <TimeSlotRow>[],
        );
        if (!meds.containsKey(med.id)) {
          meds[med.id] = med;
          order.add(med.id);
        }
        final TimeSlotRow? slot = row.readTableOrNull(_db.timeSlots);
        if (slot != null) {
          medSlots.add(slot);
        }
      }
      // Build the result from locals guarded by null checks so no `!` is needed
      // to read map values back out.
      final List<(MedicationRow, List<TimeSlotRow>)> result =
          <(MedicationRow, List<TimeSlotRow>)>[];
      for (final String id in order) {
        final MedicationRow? med = meds[id];
        final List<TimeSlotRow>? medSlots = slots[id];
        if (med != null && medSlots != null) {
          result.add((med, medSlots));
        }
      }
      return result;
    });
  }
}
