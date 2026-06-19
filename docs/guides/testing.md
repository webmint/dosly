# Testing

## Overview

dosly has four test layers. Each layer targets a different level of the stack; run all four to get complete coverage before merging.

| Layer | Location | Runner | What it exercises |
|---|---|---|---|
| Unit / domain | `test/features/**/domain/**` | `flutter test` | Use cases, value objects, pure-Dart logic |
| Data | `test/features/**/data/**` | `flutter test` | Repositories, mappers, SQL queries |
| Widget | `test/features/**/presentation/**` | `flutter test` | Screens and widgets with providers overridden |
| On-device integration | `integration_test/` | `flutter test -d <device>` | Real app + real SQLite on a device or emulator |

---

## Unit / Domain Tests (`test/features/**/domain/`)

Framework: `flutter_test` + `mocktail`.

Domain entities and use cases are pure Dart — no Flutter, drift, or uuid imports. Tests in this layer mock the repository interface with `mocktail` and assert `Either<Failure, T>` outcomes directly.

```dart
// Example: testing the AddMedication use case
when(() => mockRepo.add(any())).thenAnswer((_) async => Right(medication));
final result = await addMedication(params);
expect(result, isA<Right<Failure, Medication>>());
```

---

## Data Tests (`test/features/**/data/`)

Framework: `flutter_test`.

Repository and data-source tests run against an in-memory drift database:

```dart
final db = AppDatabase(NativeDatabase.memory());
addTearDown(db.close);
```

`NativeDatabase.memory()` gives a real SQLite engine in a RAM-only file. Migrations, foreign-key pragmas, and `textEnum` serialization all run — only the file path is synthetic.

---

## Widget Tests (`test/features/**/presentation/`)

Framework: `flutter_test`.

Widget tests pump a `ProviderScope` with the providers under test overridden. The rest of the provider graph is replaced by fakes so tests are fast and deterministic.

```dart
await tester.pumpWidget(
  ProviderScope(
    overrides: [medicationRepositoryProvider.overrideWith((_) => FakeRepo())],
    child: const MaterialApp(home: MedsScreen()),
  ),
);
```

---

## On-Device Integration Tests (`integration_test/`)

### What they are

Integration tests boot the **real `AppBootstrap` widget tree** on a connected device or emulator via the `integration_test` package. Unlike widget tests, no provider graph is replaced with fakes — the full production wiring (router, settings chain, drift database) is exercised. Only three leaf seams are overridden to make tests hermetic:

| Seam overridden | Test value | Why |
|---|---|---|
| `appDatabaseProvider` | Caller-supplied `AppDatabase` (temp file or real file) | Isolate test data |
| `sharedPreferencesInitProvider` | `InMemorySharedPreferencesAsync.empty()` | Deterministic, never persists across runs |
| `devSeedProvider` | No-op (`async {}`) | Integration tests run in `kDebugMode`; without this the debug seeder would pre-populate the fresh DB with 12 demo medications, breaking golden-flow assertions that expect an exact row count after a single UI-driven add |

Everything else — `settingsRepositoryProvider`, `settingsNotifierProvider`, the entire GoRouter chain — runs as production code.

### Running the suite

Run all integration tests on a device or emulator:

```
flutter test integration_test -d emulator-5554
```

Run a single file:

```
flutter test integration_test/add_medication_golden_test.dart -d emulator-5554
```

`emulator-5554` is the default Android emulator port; substitute your device ID from `flutter devices`.

---

### The boot harness (`integration_test/support/app_harness.dart`)

Two entry-points for booting the app in a test:

**`bootAppWithTempDb(tester)`** — creates a fresh `NativeDatabase` over a system-temp file (`<systemTemp>/dosly_it_<random>/dosly_it.sqlite`), registers teardown (close DB then delete temp dir), and boots the app. Returns the `AppDatabase` handle for row assertions. Use this for the golden flow suite — every test gets a completely isolated, hermetic database.

```dart
final db = await bootAppWithTempDb(tester);
```

**`bootAppWithDb(tester, db)`** — boots the app against a caller-supplied `AppDatabase`. The caller owns lifecycle (creation, close, file deletion). Use this when you need to control which executor backs the database, e.g. a real `driftDatabase(name:)` for native-path smoke tests.

```dart
await bootAppWithDb(tester, db);
```

Both entry-points override `devSeedProvider` with a no-op in addition to the DB and preferences seams. See the seam table above for why this is necessary.

---

### The two suites

#### Add-medication golden flow (`integration_test/add_medication_golden_test.dart`)

Eight `testWidgets` — one per entry in `medFixtures`. Each test:

1. Boots a fresh hermetic temp-file `AppDatabase` via `bootAppWithTempDb`.
2. Drives the full add-medication modal via `addMedication(tester, fixture)`.
3. Asserts the persisted `medications` and `time_slots` rows match the fixture via `expectPersisted(db, fixture)`.

The fixture matrix (`medFixtures` in `integration_test/support/medication_fixtures.dart`) covers:

- All 8 medication forms: tablet, capsule, syrup, drops, injection, inhaler, cream, sachet
- Both intake types: continuous and course
- Varying time-slot counts, dose modes (quantity stepper vs. liquid dose field), and stock-tracking fields

Each test gets its own database — no shared state, no ordering dependency. This makes the suite safe to run in any order and repeatable on CI (given a device or emulator).

#### Real-path smoke test (`integration_test/db_open_smoke_test.dart`)

One `testWidgets` that opens a real on-disk database via `driftDatabase(name: 'dosly_inttest')` — the same factory used by production code. It adds one medication, asserts the row persisted, and deletes the `dosly_inttest.sqlite` file (and `-wal`, `-shm` siblings) on teardown.

This test exists to catch failures that in-memory databases cannot detect: missing native SQLite libraries, wrong `path_provider` path, or permission errors on a specific device model. It uses the name `dosly_inttest`, never `dosly`, so real user data is never touched.

---

### The medication driver (`integration_test/support/add_medication_driver.dart`)

`addMedication(tester, fixture)` drives the add-medication modal end-to-end:

1. Taps the Meds bottom-nav icon (`LucideIcons.pill`) to navigate Today → Meds.
2. Taps the FAB (`ValueKey('medsAddFab')`) to open the modal.
3. Fills name, form chip (`ValueKey('medsForm_<formKey>')`), dose/quantity/stock fields.
4. Enters each intake time via `enterTimeViaKeyboard` (switches the time picker to text-input mode, enters hour/minute by semantic label `"Hour"` / `"Minute"`, taps OK).
5. Selects intake type (course or continuous) via the segmented button.
6. Taps Save (`ValueKey('medsAddSaveButton')`).

`enterTimeViaKeyboard(tester, hour:, minute:)` is a standalone helper — use it any time a test needs to interact with the Material time picker deterministically.

---

### Fixtures and assertions (`integration_test/support/medication_fixtures.dart`)

`MedFixture` — the fixture data class. `medFixtures` — the 8-entry matrix.

`expectPersisted(db, fixture)` queries the `medications` and `time_slots` tables and asserts every column matches the fixture. One caveat for future maintainers: drift `dateTime()` columns read back with the `LOCAL` flag set, so date assertions use `isAtSameMomentAs` rather than `==`.

---

### Hermetic temp-file DB vs real-file smoke — why both

| | Golden flow | Real-path smoke |
|---|---|---|
| Database | `NativeDatabase` over a system-temp file | `driftDatabase(name: 'dosly_inttest')` |
| Per-test isolation | Yes — fresh file per test | No — one file for the whole suite |
| What it catches | Logic bugs, persistence correctness, all form variants | DB-open failures: native library loading, `path_provider` path, file permissions |
| CI-safe | Yes — temp files, no `path_provider` dependency | Requires a real device or emulator |

Both are necessary. The golden tests verify persistence logic exhaustively but use a synthetic temp path that bypasses `path_provider`. The smoke test exercises the exact native code path that can fail on a real device even when all other tests pass.

---

## Caveats

- On-device runs install the app under its production `applicationId`. On a low-disk emulator, `adb install` may trigger an automatic uninstall that clears real app data. Keep at least a few hundred MB free on the emulator before running the suite.
- Mark-intake and weekly-adherence golden flows are deferred — those feature UIs are not built yet.

---

## Related

- [architecture.md](../architecture.md) — local database schema, provider wiring
- [features/medication-persistence.md](../features/medication-persistence.md) — domain model and Save flow
- [specs/033-integration-test-harness/spec.md](../../specs/033-integration-test-harness/spec.md) — the spec that introduced the integration-test infrastructure
