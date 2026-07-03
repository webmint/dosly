/// Low-level data source that reads and writes intake records to the local
/// drift database.
///
/// Lives in `data/datasources` (constitution §2.1): it owns the drift queries
/// for the intake aggregate and exposes a narrow, exception-throwing API.
/// Translating any thrown exception into a `Failure` is the repository's job —
/// this class never returns `Either` and never imports fpdart.
library;

import 'package:drift/drift.dart';

import '../../../../core/database/database.dart';

/// Persists user-confirmed intake occurrences to the local drift [AppDatabase].
///
/// Operates on drift companions produced by the intake mapper. Mirrors
/// [MedicationLocalDataSource]: a narrow surface of one reactive read
/// ([watchAllIntakes]) plus two writes ([upsertIntake], [deleteIntake]).
///
/// Throws on failure (e.g. `SqliteException`); callers in the repository layer
/// catch and convert these into `Left(Failure)`.
class IntakeLocalDataSource {
  /// Creates a data source backed by [_db].
  const IntakeLocalDataSource(this._db);

  final AppDatabase _db;

  /// Watches every stored intake row, re-emitting whenever the `intakes` table
  /// changes.
  ///
  /// Backed by drift's `watch()` so the stream fires on any insert/update/delete
  /// to the `intakes` table, keeping the presentation layer's derived
  /// occurrence state (taken/skipped) live without manual refreshes.
  ///
  /// Throws on query failure (e.g. `SqliteException`); the repository layer
  /// catches and converts these into `Left(Failure)`.
  Stream<List<IntakeRow>> watchAllIntakes() => _db.select(_db.intakes).watch();

  /// Upserts [companion] keyed on the occurrence unique index, so re-marking the
  /// SAME occurrence updates in place instead of inserting a duplicate.
  ///
  /// The conflict [target] is the occurrence unique key
  /// `{medicationId, slotId, scheduledAt}` — NOT the primary key `id`. This is
  /// load-bearing: each confirmation of an occurrence is minted with a fresh
  /// `id`, so a PK-targeted upsert would never collide and would insert a second
  /// row for the same dose. Targeting the occurrence unique index instead means
  /// a repeated confirmation of an already-recorded occurrence resolves to an
  /// `ON CONFLICT ... DO UPDATE`, overwriting the prior row's `status` and
  /// `confirmedAt` (and other columns) in place. This is the AC-6 idempotency
  /// guarantee: one occurrence is ever represented by at most one row.
  ///
  /// Throws on failure (e.g. `SqliteException`); callers in the repository layer
  /// catch and convert these into `Left(Failure)`.
  Future<void> upsertIntake(IntakesCompanion companion) async {
    await _db
        .into(_db.intakes)
        .insert(
          companion,
          onConflict: DoUpdate(
            (_) => companion,
            target: [
              _db.intakes.medicationId,
              _db.intakes.slotId,
              _db.intakes.scheduledAt,
            ],
          ),
        );
  }

  /// Deletes the intake with [id], if present.
  ///
  /// Issues a single `delete` on the `intakes` table filtered by [id]. Returns
  /// normally when no row matches [id]: deleting an absent intake affects 0 rows
  /// and is a no-op, not an error (idempotent success).
  ///
  /// Throws on failure (e.g. `SqliteException`); callers in the repository layer
  /// catch and convert these into `Left(Failure)`.
  Future<void> deleteIntake(String id) async {
    await (_db.delete(_db.intakes)..where((t) => t.id.equals(id))).go();
  }
}
