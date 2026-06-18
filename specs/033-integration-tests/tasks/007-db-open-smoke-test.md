# Task 007: Real-file DB-open smoke test

**Agent**: qa-engineer
**Files**: `integration_test/db_open_smoke_test.dart`
**Depends on**: 003, 005
**Context docs**: `specs/033-integration-tests/plan.md` (smoke-DB decision), `lib/core/database/database.dart`
**Review checkpoint**: Yes

**Description**:
The load-bearing test — the one that would have caught the native-library/DB-open failure that started this work. Boot the real app with `appDatabaseProvider` overridden to a real-file drift DB named `dosly_inttest` (the production `driftDatabase(name:)` path → exercises path_provider + the native SQLite file open), add one medication through the UI, assert it persisted, then delete the `dosly_inttest` file. It must NOT read or write the real `dosly` database.

**Change details**:
- In `integration_test/db_open_smoke_test.dart` (new):
  - `IntegrationTestWidgetsFlutterBinding.ensureInitialized();`
  - `testWidgets('real-file driftDatabase opens and persists a medication', (tester) async { ... })`:
    - Build `final db = AppDatabase(driftDatabase(name: 'dosly_inttest'));` (import `driftDatabase` from `drift_flutter`). Pump `ProviderScope(overrides: [appDatabaseProvider.overrideWith((ref) => db), sharedPreferencesInitProvider.overrideWith(...)], child: const AppBootstrap());` (reuse the in-memory prefs builder from the harness).
    - `await addMedication(tester, <one minimal fixture>);` (e.g. `medFixtures.first` or an inline minimal cream/tablet fixture).
    - Assert `db.select(db.medications).get()` returns ≥1 row.
    - In `addTearDown`: close `db`, then resolve the documents dir and delete `dosly_inttest.sqlite` (+ `-wal`/`-shm`). If a direct `path_provider` import is required for the path, add `path_provider` via `flutter pub add path_provider` (it is already transitive via `drift_flutter`).
  - Type-safe; no `!`, no `dynamic`.

**Done when**:
- [x] Smoke test boots the real app with a `driftDatabase(name: 'dosly_inttest')`-backed `AppDatabase`
- [x] Adds one medication via the UI driver and asserts it persisted in that DB
- [x] Does not touch the real `dosly` database; deletes `dosly_inttest` files on teardown
- [x] `flutter test integration_test/db_open_smoke_test.dart -d emulator-5554` passes
- [x] `dart analyze` passes

**Spec criteria addressed**: AC-2, AC-7, AC-11

## Contracts

### Expects
- `bootAppWithTempDb` / the in-memory prefs builder exist in `app_harness.dart` (Task 003 Produces) — reuse the prefs override
- `addMedication(WidgetTester, MedFixture)` exists (Task 005 Produces)
- `drift_flutter` exports `driftDatabase({required String name})`
- `lib/core/database/database_provider.dart` exports `appDatabaseProvider`

### Produces
- `db_open_smoke_test.dart` references `driftDatabase(name: 'dosly_inttest')`
- `db_open_smoke_test.dart` references `appDatabaseProvider.overrideWith`
- `db_open_smoke_test.dart` deletes `dosly_inttest` on teardown (references `dosly_inttest`)

## Completion Notes

**Status**: Complete
**Completed**: 2026-06-18
**Files changed**: `integration_test/db_open_smoke_test.dart` (new); `integration_test/support/app_harness.dart` (extracted `bootAppWithDb`, `bootAppWithTempDb` delegates — identical behavior); `pubspec.yaml`/`pubspec.lock` (added `path_provider` dev dep)
**Contract**: Expects [4/4 verified] | Produces [3/3 verified]
**On-device result**: full `flutter test integration_test -d emulator-5554` → **9/9 passed** — golden 8/8 (harness refactor caused NO regression) + smoke 1/1 (`real-file driftDatabase persists a medication`). The smoke test opened `driftDatabase('dosly_inttest')` via path_provider + native SQLite (the real path that would have caught the original native-lib/DB-open failure), persisted ITTablet, asserted non-empty, then teardown deleted the `dosly_inttest` files. Verified post-run: `dosly_inttest*` removed; real `dosly` never opened by the smoke test (AC-7 holds).
**Gotcha (recorded in MEMORY)**: on-device integration tests install/uninstall the app under the SAME applicationId (`dev.webmint.dosly`). The first golden run hit a low-disk `adb install` error → Flutter `Uninstalling old version...` → Android uninstall cleared the app data dir, wiping the real `dosly.sqlite` (the user's earlier manual `www`/`foo` meds). Inherent to E2E testing against the production package; mitigate by keeping emulator disk free, or use a separate test applicationId flavor for integration runs.
