/// Tests for [IntakeLocalDataSource] against a real in-memory drift DB.
///
/// Covers:
///   - Reactive read: an inserted intake surfaces on `watchAllIntakes()` with
///     its stored fields intact.
///   - AC-6 idempotency: re-marking the SAME occurrence (same
///     `{medicationId, slotId, scheduledAt}`, different `id`/`status`/
///     `confirmedAt`) UPDATES the existing row in place — exactly one row
///     survives, never a duplicate.
///   - Delete-by-id: deleting an existing id removes the row; deleting an
///     absent id is a no-throw no-op that leaves other rows untouched.
///
/// The `intakes.medicationId` foreign key is enforced (the database enables
/// `pragma foreign_keys = ON` in `beforeOpen`), so a parent medication row is
/// seeded in `setUp` before any intake is written.
library;

import 'package:dosly/core/database/database.dart';
import 'package:dosly/core/database/tables/medications_table.dart';
import 'package:dosly/features/meds/data/datasources/intake_local_data_source.dart';
import 'package:dosly/features/meds/data/datasources/medication_local_data_source.dart';
import 'package:dosly/features/meds/domain/entities/intake_status.dart';
import 'package:dosly/features/meds/domain/entities/medication_form.dart';
import 'package:dosly/features/meds/domain/entities/schedule_frequency.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

/// The parent medication all seeded intakes reference (satisfies the FK).
const String _medId = 'med-1';

/// Slot + scheduled instant that together with [_medId] form one occurrence —
/// the unique key the upsert conflicts on.
const String _slotId = 'slot-1';
final DateTime _scheduledAt = DateTime.utc(2026, 6, 1, 8);

/// A minimal parent medication row so intake foreign keys resolve.
final MedicationsCompanion _medCompanion = MedicationsCompanion.insert(
  id: _medId,
  name: 'MedA',
  form: MedicationForm.tablet,
  typeKind: MedicationTypeKind.continuous,
  frequency: ScheduleFrequency.daily,
  startDate: DateTime.utc(2026, 1, 1),
  createdAt: DateTime.utc(2026, 1, 1),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late AppDatabase db;
  late IntakeLocalDataSource src;

  setUp(() async {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    src = IntakeLocalDataSource(db);
    // Seed the parent medication so intake FKs resolve.
    await db.into(db.medications).insert(_medCompanion);
  });

  tearDown(() async {
    await db.close();
  });

  group('IntakeLocalDataSource.watchAllIntakes()', () {
    test(
      'should emit exactly one row with the stored fields after an insert',
      () async {
        await src.upsertIntake(
          IntakesCompanion.insert(
            id: 'intake-1',
            medicationId: _medId,
            slotId: _slotId,
            scheduledAt: _scheduledAt,
            status: IntakeStatus.taken,
            confirmedAt: Value(DateTime.utc(2026, 6, 1, 8, 5)),
          ),
        );

        final List<IntakeRow> rows = await src.watchAllIntakes().first;

        expect(rows.length, 1);
        final IntakeRow row = rows.single;
        expect(row.id, 'intake-1');
        expect(row.medicationId, _medId);
        expect(row.slotId, _slotId);
        // Drift round-trips the UTC instant but reads it back as a local
        // DateTime, so compare moments (not the isUtc flag) via
        // isAtSameMomentAs — matching the project convention (see
        // medication_mapper_test.dart / migration_test.dart).
        expect(row.scheduledAt.isAtSameMomentAs(_scheduledAt), isTrue);
        expect(row.status, IntakeStatus.taken);
        expect(
          row.confirmedAt?.isAtSameMomentAs(DateTime.utc(2026, 6, 1, 8, 5)),
          isTrue,
        );
      },
    );
  });

  group('IntakeLocalDataSource.upsertIntake()', () {
    test('should UPDATE in place (no duplicate) when re-marking the same '
        'occurrence with a different id/status/confirmedAt (AC-6)', () async {
      // First confirmation: taken.
      await src.upsertIntake(
        IntakesCompanion.insert(
          id: 'intake-1',
          medicationId: _medId,
          slotId: _slotId,
          scheduledAt: _scheduledAt,
          status: IntakeStatus.taken,
          confirmedAt: Value(DateTime.utc(2026, 6, 1, 8, 5)),
        ),
      );

      // Re-mark the SAME occurrence (same medicationId+slotId+scheduledAt)
      // with a fresh id and different status/confirmedAt.
      await src.upsertIntake(
        IntakesCompanion.insert(
          id: 'intake-2',
          medicationId: _medId,
          slotId: _slotId,
          scheduledAt: _scheduledAt,
          status: IntakeStatus.skipped,
          confirmedAt: Value(DateTime.utc(2026, 6, 1, 9, 30)),
        ),
      );

      final List<IntakeRow> rows = await src.watchAllIntakes().first;

      // Idempotent per occurrence: still exactly one row, no duplicate.
      expect(rows.length, 1);
      final IntakeRow row = rows.single;
      // status/confirmedAt were updated in place by the DoUpdate.
      expect(row.status, IntakeStatus.skipped);
      expect(
        row.confirmedAt?.isAtSameMomentAs(DateTime.utc(2026, 6, 1, 9, 30)),
        isTrue,
      );
      // The occurrence key is unchanged.
      expect(row.medicationId, _medId);
      expect(row.slotId, _slotId);
      expect(row.scheduledAt.isAtSameMomentAs(_scheduledAt), isTrue);
    });

    test('should insert distinct rows for distinct occurrences', () async {
      await src.upsertIntake(
        IntakesCompanion.insert(
          id: 'intake-1',
          medicationId: _medId,
          slotId: _slotId,
          scheduledAt: _scheduledAt,
          status: IntakeStatus.taken,
        ),
      );
      // Different scheduledAt → different occurrence → separate row.
      await src.upsertIntake(
        IntakesCompanion.insert(
          id: 'intake-2',
          medicationId: _medId,
          slotId: _slotId,
          scheduledAt: DateTime.utc(2026, 6, 2, 8),
          status: IntakeStatus.taken,
        ),
      );

      final List<IntakeRow> rows = await src.watchAllIntakes().first;

      expect(rows.length, 2);
      expect(rows.map((r) => r.id).toSet(), {'intake-1', 'intake-2'});
    });
  });

  group('IntakeLocalDataSource.deleteIntake()', () {
    test('should remove the row with the given id', () async {
      await src.upsertIntake(
        IntakesCompanion.insert(
          id: 'intake-1',
          medicationId: _medId,
          slotId: _slotId,
          scheduledAt: _scheduledAt,
          status: IntakeStatus.taken,
        ),
      );

      await src.deleteIntake('intake-1');

      final List<IntakeRow> rows = await src.watchAllIntakes().first;
      expect(rows, isEmpty);
    });

    test(
      'should be a no-op (no throw, other rows untouched) for an absent id',
      () async {
        await src.upsertIntake(
          IntakesCompanion.insert(
            id: 'intake-1',
            medicationId: _medId,
            slotId: _slotId,
            scheduledAt: _scheduledAt,
            status: IntakeStatus.taken,
          ),
        );

        await expectLater(src.deleteIntake('does-not-exist'), completes);

        final List<IntakeRow> rows = await src.watchAllIntakes().first;
        expect(rows.length, 1);
        expect(rows.single.id, 'intake-1');
      },
    );
  });

  // ---------------------------------------------------------------------------
  // FK cascade — deleting the owning medication removes its intake rows.
  // ---------------------------------------------------------------------------
  group('IntakeLocalDataSource FK cascade (medication delete)', () {
    test('should remove intake rows when their owning medication is deleted '
        '(onDelete: KeyAction.cascade, pragma foreign_keys = ON)', () async {
      // Seed a time slot for the parent medication (realistic shape — a
      // real due dose always has a backing slot row, even though
      // intakes.slotId itself carries no FK; see intakes_table.dart).
      await db
          .into(db.timeSlots)
          .insert(
            TimeSlotsCompanion.insert(
              id: _slotId,
              medicationId: _medId,
              minuteOfDay: 480,
            ),
          );

      await src.upsertIntake(
        IntakesCompanion.insert(
          id: 'intake-cascade-1',
          medicationId: _medId,
          slotId: _slotId,
          scheduledAt: _scheduledAt,
          status: IntakeStatus.taken,
          confirmedAt: Value(DateTime.utc(2026, 6, 1, 8, 5)),
        ),
      );

      // Sanity pre-assert: the intake exists before the delete.
      final before = await src.watchAllIntakes().first;
      expect(before, hasLength(1));

      // Delete the parent medication through the same production code path
      // MedicationRepositoryImpl.delete() uses.
      final medSrc = MedicationLocalDataSource(db);
      await medSrc.deleteMedication(_medId);

      final after = await src.watchAllIntakes().first;
      expect(
        after,
        isEmpty,
        reason:
            'onDelete: KeyAction.cascade on intakes.medicationId must '
            'remove intake rows when their medication is deleted — this '
            'requires pragma foreign_keys = ON (enabled in beforeOpen), '
            'without which SQLite silently ignores the FK and orphans the '
            'intake row.',
      );
    });
  });
}
