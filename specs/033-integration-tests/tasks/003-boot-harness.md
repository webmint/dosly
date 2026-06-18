# Task 003: Build the integration-test boot harness

**Agent**: qa-engineer
**Files**: `integration_test/support/app_harness.dart`
**Depends on**: 001
**Blocks**: 006, 007
**Context docs**: `test/app_bootstrap_test.dart` (boot/override idiom), `specs/033-integration-tests/plan.md` (Key Design Decisions)
**Review checkpoint**: No

**Description**:
Create the shared harness that boots the **real app** (`AppBootstrap`) on the device with the two leaf seams overridden: `appDatabaseProvider` → a fresh hermetic **temp-file** drift `AppDatabase`, and `sharedPreferencesInitProvider` → an in-memory prefs instance. It returns the `AppDatabase` handle so tests can assert persisted rows, and provides teardown that closes the DB and deletes the temp file. Override only the leaf seams; let the real `DoslyApp → router → settings` chain inflate (MEMORY L127).

**Change details**:
- In `integration_test/support/app_harness.dart` (new):
  - Expose `Future<AppDatabase> bootAppWithTempDb(WidgetTester tester)`:
    - Create a temp dir + file (e.g. `Directory.systemTemp.createTempSync('dosly_it')` → `File('.../db.sqlite')`).
    - Build `final db = AppDatabase(NativeDatabase(file));`
    - Build in-memory prefs via `SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();` then `SharedPreferencesWithCache.create(cacheOptions: SharedPreferencesWithCacheOptions(allowList: settingsPrefsKeys))` — reuse the production `settingsPrefsKeys` constant.
    - `await tester.pumpWidget(ProviderScope(overrides: [appDatabaseProvider.overrideWith((ref) => db), sharedPreferencesInitProvider.overrideWith((ref) => Future.value(prefs))], child: const AppBootstrap()));`
    - `await tester.pumpAndSettle();` then return `db`.
  - Expose a teardown helper `Future<void> disposeTempDb(AppDatabase db, {File? file})` (or register via `addTearDown` inside `bootAppWithTempDb`) that closes the DB and deletes the temp file (+ `-wal`/`-shm` if present).
  - Type-safe: no `!`, no `dynamic`, no unchecked `as`.

**Done when**:
- [x] `app_harness.dart` declares `Future<AppDatabase> bootAppWithTempDb(WidgetTester tester)`
- [x] Boot uses `appDatabaseProvider.overrideWith(...)` and `sharedPreferencesInitProvider.overrideWith(...)` and mounts `const AppBootstrap()`
- [x] Returns the `AppDatabase` instance backing the override; temp file is cleaned up on teardown
- [x] `dart analyze` passes

**Spec criteria addressed**: AC-3

## Contracts

### Expects
- `integration_test` dev dependency is present (Task 001 Produces)
- `lib/core/database/database_provider.dart` exports `appDatabaseProvider`
- `lib/core/providers/shared_preferences_provider.dart` exports `sharedPreferencesInitProvider`
- `lib/core/database/database.dart` exports `AppDatabase` with a constructor accepting an optional `QueryExecutor`
- `settingsPrefsKeys` is exported from `lib/core/providers/settings_prefs_keys.dart`

### Produces
- `integration_test/support/app_harness.dart` declares `bootAppWithTempDb(`
- `app_harness.dart` references `appDatabaseProvider.overrideWith` and `sharedPreferencesInitProvider.overrideWith`
- `app_harness.dart` returns an `AppDatabase` from `bootAppWithTempDb`

## Completion Notes

**Status**: Complete
**Completed**: 2026-06-18
**Files changed**: `integration_test/support/app_harness.dart` (new)
**Contract**: Expects [5/5 verified] | Produces [3/3 verified]
**Notes**: `bootAppWithTempDb` builds `AppDatabase(NativeDatabase(File(systemTemp/dosly_it...)))`, sets `InMemorySharedPreferencesAsync` + `SharedPreferencesWithCache` using prod `settingsPrefsKeys`, registers `addTearDown` (close DB + delete temp dir) BEFORE pumping, then pumps `ProviderScope` overriding only `appDatabaseProvider` + `sharedPreferencesInitProvider` around `const AppBootstrap()`. Real settings/router chain left intact (L127). dartdoc + imports ordered; no `!`/`dynamic`/`as`. analyze clean. Library-only — not exercised until 006/007. Code review deferred to consolidated support-layer review after Task 005.
