/// Integration test suite: add-medication golden flow.
///
/// Boots the real [AppBootstrap] widget tree against a hermetic temp-file
/// SQLite database (via [bootAppWithTempDb]) for each of the 8 [medFixtures].
/// Every test variation:
///   1. Starts a fresh [ProviderScope] + fresh DB (complete isolation).
///   2. Drives the add-medication modal end-to-end via [addMedication].
///   3. Asserts that the persisted `medications` row and its `time_slots`
///      exactly match the fixture via [expectPersisted].
///
/// Covers: all medication forms (tablet, capsule, syrup, drops, injection,
/// inhaler, cream, sachet), quantity and liquid dose modes, stock tracking,
/// continuous and course intake types, and varying time-slot counts.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/add_medication_driver.dart';
import 'support/app_harness.dart';
import 'support/medication_fixtures.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('add-medication golden flow', () {
    for (final f in medFixtures) {
      testWidgets('persists ${f.name} (${f.formKey})', (tester) async {
        final db = await bootAppWithTempDb(tester);
        await addMedication(tester, f);
        await expectPersisted(db, f);
      });
    }
  });
}
