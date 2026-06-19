/// Boot harness for on-device integration tests.
///
/// Exposes two entry-points for inflating the real [AppBootstrap] widget tree
/// with hermetic seams:
///
/// - [bootAppWithDb] — boots the app against a caller-supplied [AppDatabase].
///   The caller owns the DB lifecycle (creation and teardown). Use this when
///   you want to control which [QueryExecutor] backs the database — e.g. a
///   real `driftDatabase(name:)` file for native-path smoke tests.
/// - [bootAppWithTempDb] — convenience wrapper that creates a fresh
///   [NativeDatabase] over a system-temp file, registers teardown, and
///   delegates to [bootAppWithDb]. Use for the golden-flow suite where a
///   per-test hermetic temp file is the right choice.
///
/// Both functions override three leaf providers:
/// - [appDatabaseProvider] → the supplied [AppDatabase].
/// - [sharedPreferencesInitProvider] → [InMemorySharedPreferencesAsync],
///   so preferences state is deterministic and never persists across runs.
/// - [devSeedProvider] → a no-op, so the debug seeder (which runs in
///   `kDebugMode` and integration tests ARE debug builds) does NOT populate the
///   fresh DB with demo medications. Without this, the golden-flow assertions
///   that expect an exact row count after a single UI-driven add would see the
///   seeded rows too. The seeder is debug-only scaffolding, not behavior under
///   test, so disabling it does not mask any production wiring bug.
///
/// All other providers — including [settingsRepositoryProvider] and the entire
/// [DoslyApp] router chain — are the real production implementations. This
/// deliberately avoids overriding any consumer provider, so wiring bugs are
/// not masked (MEMORY lesson L127).
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:dosly/app_bootstrap.dart';
import 'package:dosly/core/database/database.dart';
import 'package:dosly/core/database/database_provider.dart';
import 'package:dosly/core/providers/shared_preferences_provider.dart';
import 'package:dosly/core/providers/settings_prefs_keys.dart';
import 'package:dosly/features/meds/presentation/providers/medication_providers.dart';

/// Boots the real [AppBootstrap] on-device with a caller-supplied [db] and
/// hermetic in-memory preferences.
///
/// What it overrides:
/// - [appDatabaseProvider] → [db] (the caller decides which executor backs it).
/// - [sharedPreferencesInitProvider] → [InMemorySharedPreferencesAsync], which
///   is deterministic and never persists between test runs.
/// - [devSeedProvider] → a no-op, so the `kDebugMode` debug seeder does not
///   pre-populate [db] with demo medications (integration tests run in debug).
///
/// All other providers are real production code. The real settings provider
/// chain ([DoslyApp] → [settingsNotifier] → [settingsRepository] →
/// [sharedPreferencesProvider]) is exercised without any override so wiring
/// bugs surface at integration-test time.
///
/// The caller is responsible for:
/// - Creating [db] before calling this function.
/// - Registering teardown (closing [db] and cleaning up any files) via
///   [addTearDown] — this function intentionally does NOT do that, so the
///   caller controls the exact order (e.g. close db before deleting files).
///
/// Call this once at the top of each `testWidgets` body:
/// ```dart
/// await bootAppWithDb(tester, db);
/// ```
///
/// Do NOT call [IntegrationTestWidgetsFlutterBinding.ensureInitialized] here —
/// that belongs in each test file's `main()`.
Future<void> bootAppWithDb(WidgetTester tester, AppDatabase db) async {
  // 1. Wire in-memory SharedPreferences so prefs state is hermetic.
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  final prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: settingsPrefsKeys,
    ),
  );

  // 2. Pump the real app with only the two leaf seams overridden.
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((ref) => db),
        sharedPreferencesInitProvider.overrideWith((ref) => Future.value(prefs)),
        // Disable the debug seeder: integration tests run in kDebugMode, and the
        // golden-flow assertions expect an exact medication-row count after a
        // single UI-driven add. Seeding the fresh DB would break that.
        devSeedProvider.overrideWith((ref) async {}),
      ],
      child: const AppBootstrap(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Boots the real [AppBootstrap] on-device with a fresh hermetic temp-file
/// [NativeDatabase] and in-memory preferences, returning the [AppDatabase]
/// handle for row assertions.
///
/// What it overrides (via [bootAppWithDb]):
/// - [appDatabaseProvider] → a fresh [NativeDatabase] over a temp file at
///   `<systemTemp>/dosly_it_<random>/dosly_it.sqlite`. A real native SQLite
///   connection is used so migrations, WAL, and foreign-key pragmas all run.
/// - [sharedPreferencesInitProvider] → [InMemorySharedPreferencesAsync], which
///   is deterministic and never persists between test runs.
///
/// All other providers are real production code. The real settings provider
/// chain ([DoslyApp] → [settingsNotifier] → [settingsRepository] →
/// [sharedPreferencesProvider]) is exercised without any override so wiring
/// bugs surface at integration-test time.
///
/// Teardown (registered via [addTearDown]):
/// - Closes [AppDatabase], releasing the SQLite connection.
/// - Deletes the temp directory and its SQLite file.
///
/// Call this once at the top of each `testWidgets` body:
/// ```dart
/// final db = await bootAppWithTempDb(tester);
/// ```
///
/// Do NOT call [IntegrationTestWidgetsFlutterBinding.ensureInitialized] here —
/// that belongs in each test file's `main()`.
Future<AppDatabase> bootAppWithTempDb(WidgetTester tester) async {
  // 1. Create a per-test temp directory and SQLite file path.
  final dir = Directory.systemTemp.createTempSync('dosly_it');
  final file = File('${dir.path}/dosly_it.sqlite');

  // 2. Open the database with a real NativeDatabase over the temp file.
  final db = AppDatabase(NativeDatabase(file));

  // 3. Register teardown before pumping — ensures cleanup even on pump failure.
  addTearDown(() async {
    await db.close();
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  // 4. Delegate to bootAppWithDb for the common pump logic.
  await bootAppWithDb(tester, db);

  return db;
}
