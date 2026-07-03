/// Round-trip tests for the intake mapper.
///
/// Each test builds a domain [Intake] fixture, writes it to an in-memory drift
/// database via [IntakeLocalDataSource.upsertIntake] (calling
/// [intakeToCompanion] internally), reads the raw [IntakeRow] back, and calls
/// [intakeFromRow] to reconstruct the entity. The reconstructed value is then
/// compared field-by-field against the original fixture, confirming the UTC
/// round-trip (AC-6) and the nullable-column handling.
///
/// Two fixture shapes are tested:
///   (a) taken — `confirmedAt` + `notes` set, status `taken`.
///   (b) skipped — `confirmedAt` + `notes` left `null`, status `skipped` — this
///       intentionally exercises the nullable-column round-trip.
///
/// The `intakes.medicationId` foreign key is enforced (the database enables
/// `pragma foreign_keys = ON` in `beforeOpen`), so a parent medication row is
/// seeded in `setUp` before any intake is written.
///
/// NOTE on DateTime round-trips: drift's `dateTime()` column stores a UTC epoch
/// millisecond timestamp but returns a *local* [DateTime] on read. As a result,
/// [DateTime.isUtc] is false after a round-trip even though the stored moment is
/// correct. Datetime assertions therefore use [DateTime.isAtSameMomentAs] to
/// compare the moment in time independently of the UTC flag — matching the
/// project convention (see medication_mapper_test.dart / migration_test.dart).
library;

import 'package:dosly/core/database/database.dart';
import 'package:dosly/core/database/tables/medications_table.dart';
import 'package:dosly/features/meds/data/datasources/intake_local_data_source.dart';
import 'package:dosly/features/meds/data/mappers/intake_mapper.dart';
import 'package:dosly/features/meds/domain/entities/intake.dart';
import 'package:dosly/features/meds/domain/entities/intake_status.dart';
import 'package:dosly/features/meds/domain/entities/medication_form.dart';
import 'package:dosly/features/meds/domain/entities/schedule_frequency.dart';
import 'package:dosly/features/meds/domain/value_objects/intake_id.dart';
import 'package:dosly/features/meds/domain/value_objects/medication_id.dart';
import 'package:dosly/features/meds/domain/value_objects/time_slot_id.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

/// The parent medication all seeded intakes reference (satisfies the FK).
const String _medId = 'med-1';

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

/// (a) Taken: confirmedAt set, notes set, status taken.
final Intake _takenIntake = Intake(
  id: const IntakeId('intake-taken-001'),
  medicationId: const MedicationId(_medId),
  slotId: const TimeSlotId('slot-1'),
  scheduledAt: DateTime.utc(2026, 6, 1, 8),
  confirmedAt: DateTime.utc(2026, 6, 1, 8, 5),
  status: IntakeStatus.taken,
  notes: 'Taken with breakfast',
);

/// (b) Skipped: confirmedAt null, notes null, status skipped — exercises the
/// nullable-column round-trip.
final Intake _skippedIntake = Intake(
  id: const IntakeId('intake-skipped-001'),
  medicationId: const MedicationId(_medId),
  slotId: const TimeSlotId('slot-2'),
  scheduledAt: DateTime.utc(2026, 6, 2, 20),
  status: IntakeStatus.skipped,
);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Performs a full round-trip: writes [original] into [db] via the mapper,
/// reads the raw row back, maps it through [intakeFromRow], and returns the
/// reconstructed entity.
Future<Intake> _roundTrip(AppDatabase db, Intake original) async {
  final dataSource = IntakeLocalDataSource(db);
  await dataSource.upsertIntake(intakeToCompanion(original));

  final row = await (db.select(
    db.intakes,
  )..where((t) => t.id.equals(original.id.value))).getSingle();

  return intakeFromRow(row);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    // Seed the parent medication so intake FKs resolve.
    await db.into(db.medications).insert(_medCompanion);
  });

  tearDown(() async {
    await db.close();
  });

  group('IntakeMapper round-trip', () {
    // -----------------------------------------------------------------------
    // (a) Taken fixture — confirmedAt + notes set.
    // -----------------------------------------------------------------------
    group('(a) taken — confirmedAt set, notes set', () {
      late Intake result;

      setUp(() async {
        result = await _roundTrip(db, _takenIntake);
      });

      test('should preserve intake id', () {
        expect(result.id, _takenIntake.id);
      });

      test('should preserve medicationId', () {
        expect(result.medicationId, _takenIntake.medicationId);
      });

      test('should preserve slotId', () {
        expect(result.slotId, _takenIntake.slotId);
      });

      // Drift returns a local DateTime on read; the stored UTC moment is
      // correct, so compare the moment via isAtSameMomentAs (AC-6).
      test('should preserve scheduledAt moment (UTC round-trip)', () {
        expect(
          result.scheduledAt.isAtSameMomentAs(DateTime.utc(2026, 6, 1, 8)),
          isTrue,
        );
      });

      test('should preserve confirmedAt moment (UTC round-trip)', () {
        expect(result.confirmedAt, isNotNull);
        expect(
          result.confirmedAt?.isAtSameMomentAs(DateTime.utc(2026, 6, 1, 8, 5)),
          isTrue,
        );
      });

      test('should preserve status (taken)', () {
        expect(result.status, IntakeStatus.taken);
      });

      test('should preserve notes', () {
        expect(result.notes, 'Taken with breakfast');
      });
    });

    // -----------------------------------------------------------------------
    // (b) Skipped fixture — confirmedAt + notes null.
    // -----------------------------------------------------------------------
    group('(b) skipped — confirmedAt null, notes null', () {
      late Intake result;

      setUp(() async {
        result = await _roundTrip(db, _skippedIntake);
      });

      test('should preserve intake id', () {
        expect(result.id, _skippedIntake.id);
      });

      test('should preserve medicationId', () {
        expect(result.medicationId, _skippedIntake.medicationId);
      });

      test('should preserve slotId', () {
        expect(result.slotId, _skippedIntake.slotId);
      });

      test('should preserve scheduledAt moment (UTC round-trip)', () {
        expect(
          result.scheduledAt.isAtSameMomentAs(DateTime.utc(2026, 6, 2, 20)),
          isTrue,
        );
      });

      test('should preserve null confirmedAt', () {
        expect(result.confirmedAt, isNull);
      });

      test('should preserve status (skipped)', () {
        expect(result.status, IntakeStatus.skipped);
      });

      test('should preserve null notes', () {
        expect(result.notes, isNull);
      });
    });
  });
}
