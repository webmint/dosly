/// Real-path regression guard: verifies that `driftDatabase(name:)` can open
/// and write to a native SQLite file on the device's application-documents
/// directory.
///
/// This test exists specifically to catch the class of failures where the
/// production database path (`driftDatabase(name: 'dosly')`) fails to open —
/// e.g. missing native libraries, wrong path, or permission errors — that
/// unit-test in-memory databases cannot detect.
///
/// Uses the DB name `dosly_inttest` (NOT `dosly`) so the real user data is
/// never touched. The `dosly_inttest` files are deleted on teardown.
library;

import 'dart:io';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:dosly/core/database/database.dart';

import 'support/add_medication_driver.dart';
import 'support/app_harness.dart';
import 'support/medication_fixtures.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'real-file driftDatabase persists a medication (native-path smoke)',
    (tester) async {
      // 1. Open a real on-disk database via the same driftDatabase() factory
      //    used by production code — just with a different name so user data
      //    is never touched.
      final db = AppDatabase(driftDatabase(name: 'dosly_inttest'));

      // 2. Register teardown: close the DB first, THEN delete the files.
      //    Closing before deletion prevents SQLite from holding file locks
      //    that would cause deleteSync to fail on some platforms.
      addTearDown(() async {
        await db.close();
        final dir = await getApplicationDocumentsDirectory();
        for (final suffix in const ['', '-wal', '-shm']) {
          final f = File('${dir.path}/dosly_inttest.sqlite$suffix');
          if (f.existsSync()) {
            f.deleteSync();
          }
        }
      });

      // 3. Boot the real app against this database. The caller (this test)
      //    owns the DB lifecycle, so bootAppWithDb is used — it does NOT
      //    register teardown.
      await bootAppWithDb(tester, db);

      // 4. Drive the add-medication flow for the first fixture (ITTablet).
      await addMedication(tester, medFixtures.first);

      // 5. Assert that the row was written to the real on-disk database.
      final meds = await db.select(db.medications).get();
      expect(
        meds,
        isNotEmpty,
        reason: 'real-file driftDatabase must persist the medication',
      );
    },
  );
}
