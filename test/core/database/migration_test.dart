/// Verifies the schemaVersion 1→2 drift migration is safe for health data.
///
/// This is the migration safety net referenced by `database.dart`'s SCHEMA
/// CONTRACT: it proves, against the real v1 schema captured in
/// `drift_schemas/drift_schema_v1.json`, that upgrading a v1 database to v2
/// (which adds the `intakes` table) is structurally valid AND does not lose
/// or corrupt any pre-existing `medications`/`time_slots` data. A fresh
/// install (no prior schema) is also checked, since it takes a different
/// code path (`onCreate` instead of `onUpgrade`).
///
/// Uses drift's [SchemaVerifier] fed by the generated `schema/` helper
/// (`dart run drift_dev schema generate`, run against `drift_schemas/`),
/// which instantiates a real v1-shaped SQLite database to migrate from. Only
/// a v1 snapshot exists (captured before the v2 bump), so structural
/// validation uses drift's `validateDatabaseSchema()` self-check — it
/// compares the migrated-from-v1 schema against a from-scratch `createAll()`
/// of AppDatabase's currently-declared (v2) tables, rather than a second
/// captured snapshot.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dosly/core/database/database.dart';
import 'package:dosly/core/database/tables/medications_table.dart'
    show MedicationTypeKind;
import 'package:dosly/features/meds/domain/entities/dose_unit.dart';
import 'package:dosly/features/meds/domain/entities/medication_form.dart';
import 'package:dosly/features/meds/domain/entities/schedule_frequency.dart';

import 'schema/schema.dart';
import 'schema/schema_v1.dart' as v1;

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('upgrade v1 to v2 validates', () async {
    // Boots a database on the v1 schema, then opens it as AppDatabase,
    // which lazily triggers AppDatabase's real MigrationStrategy
    // (`onUpgrade`) on first use. `validateDatabaseSchema` then compares the
    // resulting live schema against a from-scratch `createAll()` of
    // AppDatabase's *currently declared* tables (Medications, TimeSlots,
    // Intakes) — i.e. it proves the add-only `onUpgrade`
    // (`if (from < 2) createTable(intakes)`) produces a structurally
    // identical result to a fresh v2 install, with no drift between
    // migrated-from-v1 and declared-v2 schema.
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection);
    await db.validateDatabaseSchema();
    await db.close();
  });

  test('v1 data survives the upgrade', () async {
    // Seeds a v1-shaped database directly through the generated v1
    // table/companion classes (bypassing AppDatabase's domain type
    // converters, since the v1 helper only knows the raw on-disk shape:
    // enums as their stored name strings, DateTime as unix-seconds ints).
    // Then opens AppDatabase on a *fresh independent connection* to the same
    // underlying raw database — which triggers the v1→v2 onUpgrade
    // migration — and reads the rows back through the real app schema (with
    // domain enum/DateTime conversion) to prove the add-only migration
    // altered no existing column or row.
    //
    // Uses schemaAt()/newConnection() rather than startAt(): each call to
    // newConnection() gives an independent connection wrapper drift
    // considers freshly "closed" (so opening it re-runs drift's normal
    // version-check/migration flow), while all connections share the same
    // underlying raw database — this is drift's documented pattern for
    // migration data-integrity tests (see migrations_common.dart's
    // InitializedSchema.newConnection doc example).
    //
    // NOTE on DateTime: drift's dateTime() column stores a UTC epoch second
    // timestamp but returns a *local* DateTime on read (see the same note in
    // medication_mapper_test.dart), so DateTime fields are compared with
    // isAtSameMomentAs rather than ==.
    final schema = await verifier.schemaAt(1);
    final seedDb = v1.DatabaseAtV1(schema.newConnection());

    final startDate = DateTime.utc(2024, 1, 15, 8, 30);
    await seedDb
        .into(seedDb.medications)
        .insert(
          v1.MedicationsCompanion.insert(
            id: 'med-1',
            name: 'Amoxicillin',
            form: 'capsule',
            typeKind: 'course',
            frequency: 'daily',
            startDate: startDate.millisecondsSinceEpoch ~/ 1000,
            doseAmount: const Value(500),
            doseUnit: const Value('mg'),
            durationDays: const Value(7),
            pauseDays: const Value(0),
            stockRemaining: const Value(14),
            stockTotal: const Value(14),
            stockWarnAt: const Value(3),
            notes: const Value('Take with food'),
            createdAt: startDate.millisecondsSinceEpoch ~/ 1000,
          ),
        );
    await seedDb
        .into(seedDb.timeSlots)
        .insert(
          v1.TimeSlotsCompanion.insert(
            id: 'slot-1',
            medicationId: 'med-1',
            minuteOfDay: 480,
            doseAmount: const Value(500),
            doseUnit: const Value('mg'),
          ),
        );
    await seedDb.close();

    final db = AppDatabase(schema.newConnection());

    final medications = await db.select(db.medications).get();
    expect(medications, hasLength(1));
    final medication = medications.single;
    expect(medication.id, 'med-1');
    expect(medication.name, 'Amoxicillin');
    expect(medication.form, MedicationForm.capsule);
    expect(medication.typeKind, MedicationTypeKind.course);
    expect(medication.frequency, ScheduleFrequency.daily);
    expect(medication.startDate.isAtSameMomentAs(startDate), isTrue);
    expect(medication.doseAmount, 500);
    expect(medication.doseUnit, DoseUnit.mg);
    expect(medication.durationDays, 7);
    expect(medication.pauseDays, 0);
    expect(medication.stockRemaining, 14);
    expect(medication.stockTotal, 14);
    expect(medication.stockWarnAt, 3);
    expect(medication.notes, 'Take with food');
    expect(medication.createdAt.isAtSameMomentAs(startDate), isTrue);

    final timeSlots = await db.select(db.timeSlots).get();
    expect(timeSlots, hasLength(1));
    final timeSlot = timeSlots.single;
    expect(timeSlot.id, 'slot-1');
    expect(timeSlot.medicationId, 'med-1');
    expect(timeSlot.minuteOfDay, 480);
    expect(timeSlot.doseAmount, 500);
    expect(timeSlot.doseUnit, DoseUnit.mg);

    // The migration is add-only: no pre-existing intakes could have existed,
    // but the new table must now be present and empty.
    final intakes = await db.select(db.intakes).get();
    expect(intakes, isEmpty);

    await db.close();
  });

  test('fresh install has all three tables', () async {
    // A brand-new install has no prior schema at all, so AppDatabase takes
    // the onCreate path (`m.createAll()`) rather than onUpgrade. This proves
    // onCreate produces every table declared at the current schemaVersion,
    // including intakes — the table introduced in v2.
    final db = AppDatabase(NativeDatabase.memory());

    await db.select(db.medications).get();
    await db.select(db.timeSlots).get();
    await db.select(db.intakes).get();

    await db.close();
  });

  test('schemaVersion is 2', () async {
    // Feature 040 made no schema change: the schemaVersion literal must stay
    // at 2. This guards against an accidental version bump slipping through
    // unnoticed — if it fires, the v1→v2 migration tests above also need a
    // new v2 snapshot/onUpgrade branch.
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    expect(db.schemaVersion, 2);
  });
}
