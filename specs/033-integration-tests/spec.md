# Spec: Integration-test harness + add-medication golden flow

**Date**: 2026-06-18
**Status**: Complete
**Author**: Claude + Webmint

## 1. Overview

dosly has 393 host-VM unit/widget tests but **zero on-device tests**, and this gap has caused at least two "build success ≠ runtime success" failures that host-VM tests structurally cannot catch (the Feature-026 `sharedPreferences` provider-wiring crash, and the drift native-library/DB-open failure that the medication-Save bug turned out to be). This spec introduces an `integration_test`-based harness that boots the **real app on a device/emulator** and adds the first constitution-mandated (§3.4) golden flow — **add medication** — exercised through all 8 form variations, plus a smoke test that proves the real `driftDatabase(...)` native/file path opens and persists. It directly closes the regression gap that produced the bug that started this work.

## 2. Current State

**Test infrastructure today** (all host-VM, no device):
- `test/` mirrors `lib/` (constitution §3.4). 393 tests across unit (use cases, mappers), data (in-memory drift), and widget (screens) layers.
- The medication-Save path is widget-tested in `test/features/meds/presentation/widgets/add_medication_modal_test.dart` (1947 lines), but with a **fake/recording repository** (`addMedicationProvider.overrideWith`, line ~296) — so the 8-variation persistence is never proven end-to-end against a real drift DB.
- Data-layer tests use `AppDatabase(NativeDatabase.memory())` (`medication_repository_impl_test.dart:68`, `medication_mapper_test.dart:156`). **No test ever exercises the real `driftDatabase(name: 'dosly')` path** (path_provider + native SQLite file).
- **Reusable asset**: the widget test already drives `showTimePicker` deterministically via keyboard/text-input mode (`add_medication_modal_test.dart:160-197`: tap keyboard icon, `enterText` into 'Hour'/'Minute', tap 'OK'). This is the exact technique that makes picker-driving reliable.

**App-launch seam** (`lib/main.dart`, `lib/app_bootstrap.dart`):
- `main()` → `runApp(ProviderScope(child: AppBootstrap()))`.
- `AppBootstrap` watches `sharedPreferencesInitProvider`; on `AsyncData` it mounts `const DoslyApp()` (router + bottom nav). On loading/error it shows splash/retry shells.
- DB is provided by `appDatabaseProvider` (`lib/core/database/database_provider.dart`, `@Riverpod(keepAlive: true)`), constructed as `AppDatabase()` → `driftDatabase(name: 'dosly')`. `AppDatabase` accepts an optional `QueryExecutor` for injection (`lib/core/database/database.dart:42`).

**Add-medication UI to be driven** (`lib/features/meds/presentation/...`):
- `MedsScreen` body is `SizedBox.shrink()`; a `FloatingActionButton` (no key) opens `AddMedicationModal` via `Navigator.push(rootNavigator)`.
- `AddMedicationModal` (`add_medication_modal.dart`) has a name field, a `_MedicationFormPicker` (collapsed; expands a grid of 8 chips found by localized text), form-dependent fields (`_DoseField` key `medsAddDoseField`/`medsAddDoseUnit`, `_QuantityStepper` keys `medsAddQty*`, `_StockCard` keys `medsAddStock*`), `_TimeChips` (add via `ActionChip`), a `SegmentedButton` (key `medsAddIntakeTypeSegmented`), `_CourseCard` (keys `medsAddCourse*`), and a `FilledButton` Save (found via `widgetWithText(FilledButton, 'Save')`).
- Persisted shape (drift): `medications(id, name, form, doseAmount?, doseUnit?, typeKind, frequency, startDate, durationDays?, pauseDays?, stockRemaining?, stockTotal?, stockWarnAt?, notes?, createdAt)` and `time_slots(id, medicationId FK cascade, minuteOfDay, doseAmount?, doseUnit?)`. Enums stored by name (`textEnum`). `schemaVersion = 1`. FK pragma enabled in `beforeOpen`.

**Gaps**: no `integration_test` dependency, no `integration_test/` directory, no test harness/helpers, no CI (`.github/workflows` absent), no testing section in `docs/`.

**Reference**: `research/2026-06-18-integration-test-harness.md`.

## 3. Desired Behavior

Add an on-device integration-test harness and the add-medication golden flow:

1. **Dependency + layout**: `integration_test` (Flutter SDK package) added as a dev dependency; an `integration_test/` directory at project root holding the harness and tests, runnable via `flutter test integration_test -d emulator-5554`.

2. **Shared harness** that boots the **real app** (`AppBootstrap`) inside a root `ProviderScope` whose `appDatabaseProvider` is overridden with a fresh **hermetic temp-file** drift `AppDatabase` (a real `NativeDatabase` over a file in a per-test temp directory — exercises real native SQLite + file I/O while staying isolated), with the `sharedPreferencesInitProvider` async seam satisfied so the app reaches the `DoslyApp` data branch. Temp DB created fresh per test, deleted on teardown.

3. **Reusable "drive add-medication modal" API** in the harness: navigate Today→Meds, open the modal via the FAB, fill name, select a form, fill the form-dependent fields that apply, add intake time(s) via the **keyboard-mode** picker technique, choose intake type (continuous, or course with duration/pause/start), tap Save.

4. **Add-medication golden flow**: drive all **8 representative variations** (one per form, intake type spread, all dose-unit kinds), each against a **fresh hermetic DB**, asserting the persisted `medications` + `time_slots` rows match the input.

5. **Real-path smoke test**: boot the real app with `appDatabaseProvider` overridden to a real-file drift DB named **`dosly_inttest`** (via the production `driftDatabase(name:)` path → exercises path_provider + the native SQLite file open), add one medication through the UI, assert it persisted, then delete the `dosly_inttest` file on teardown. This is the test that would have caught the native-lib/DB-open failure; it deliberately does **not** touch the real `dosly` file or real medication data.

### Representative 8-variation matrix (the golden flow)

| # | name | form | intake type | dose / quantity | stock | intake times |
|---|------|------|-------------|-----------------|-------|--------------|
| 1 | ITTablet | tablet | continuous | quantity 1.5 (unit tablet) | 20 / 30, warn 5 | 08:00, 20:00 |
| 2 | ITCapsule | capsule | course, duration 10, pause 2 | quantity 2 (unit capsule) | 14 / 14, warn 3 | 09:00 |
| 3 | ITSyrup | syrup | continuous | dose 5 ml | — | 13:00 |
| 4 | ITDrops | drops | course, duration 7, pause 0 | dose 2 drops (unit index 0) | — | 22:00 |
| 5 | ITInjection | injection | course, duration 14, pause 0 | dose 10 mg (**non-default** unit index 1 — exercises the unit dropdown) | — | 07:30 |
| 6 | ITInhaler | inhaler | continuous | none | — | 08:00, 23:00 |
| 7 | ITCream | cream | continuous | none | — | 21:00 |
| 8 | ITSachet | sachet | course, duration 5, pause 0 | none | — | 12:00 |

Coverage: all 8 forms; continuous (1,3,6,7) and course (2,4,5,8); cyclic course `pause>0` (2) and single bounded course `pause=0` (4,5,8); stock present (1,2) and absent; quantity dose (1,2) and liquid dose (3,4,5); default unit (3 syrup ml, 4 drops index 0) and non-default unit via dropdown (5 injection mg); multiple intake times (1,6) and single (others).

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Dependency | `pubspec.yaml` | Add `integration_test` (SDK) to `dev_dependencies` via `flutter pub add --dev` |
| Test harness | `integration_test/support/` (new) | Create: app-boot helper (real `AppBootstrap` + hermetic temp-file DB override + prefs seam), modal-driver API, keyboard-mode picker helper, DB-assertion helpers, the 8-variation fixture table |
| Golden-flow test | `integration_test/add_medication_golden_test.dart` (new) | Create: drives the 8 variations, asserts persisted rows per variation against a fresh hermetic DB |
| Smoke test | `integration_test/db_open_smoke_test.dart` (new) | Create: boots real app with a `dosly_inttest` real-file DB, adds one med, asserts persisted, deletes the file |
| Meds FAB key | `lib/features/meds/presentation/screens/meds_screen.dart` | Add a `ValueKey` to the FAB for stable finding (behavior-preserving) |
| Form chip keys | `lib/features/meds/presentation/widgets/add_medication_modal.dart` | Add stable `ValueKey`s to the 8 form chips (and any field lacking one needed by the driver); behavior-preserving |
| Docs | `docs/` (architecture testing section or new `docs/guides/testing.md`) | Document the harness, how to run it, and the hermetic-temp-DB vs real-file-smoke distinction |

> No changes to domain, data, or DB-schema code. No drift `schemaVersion` bump (no schema change).

## 5. Acceptance Criteria

- [x] **AC-1**: `integration_test` is added to `dev_dependencies` (via `flutter pub add --dev integration_test`); `flutter pub get` resolves cleanly.
- [x] **AC-2**: An `integration_test/` directory exists at the project root; `flutter test integration_test -d emulator-5554` discovers and runs the suite on the connected Android emulator.
- [x] **AC-3**: A shared harness boots the real app via `AppBootstrap` inside a root `ProviderScope` with `appDatabaseProvider` overridden by a fresh **temp-file** `AppDatabase` (real `NativeDatabase` over a per-test temp file) and the `sharedPreferencesInitProvider` seam satisfied; the app reaches the `DoslyApp` data branch (Meds nav reachable). The temp DB file is created per test and deleted on teardown.
- [x] **AC-4**: The harness exposes a reusable add-medication driver that navigates Today→Meds, opens the modal via the FAB, fills name, selects the given form, fills the applicable form-dependent fields (quantity+stock, or dose+unit), adds each intake time via keyboard-mode entry, selects intake type (filling duration/pause/start for course), and taps Save.
- [x] **AC-5**: A golden-flow test runs all **8 variations** from the §3 matrix; for each it asserts the overridden test DB holds exactly one `medications` row whose `name`, `form`, `typeKind`, `durationDays`, `pauseDays`, `doseAmount`, `doseUnit`, `stockRemaining`, `stockTotal`, `stockWarnAt`, and `frequency`(=`daily`) match the input, and the expected `time_slots` rows (correct count, `minuteOfDay` values, and `medicationId` FK).
- [x] **AC-6**: Each of the 8 variations runs against a **fresh hermetic DB** — data/failure from one variation cannot affect another (verified by per-variation row-count assertions starting from empty).
- [x] **AC-7**: A separate smoke test boots the real app with `appDatabaseProvider` overridden to a real-file `driftDatabase(name: 'dosly_inttest')` (exercising path_provider + the native SQLite file-open path), adds one medication through the UI, asserts it persisted, and deletes the `dosly_inttest` file on teardown. It does not read or write the real `dosly` database.
- [x] **AC-8**: All intake times are entered via the time picker's keyboard/text-input mode (reusing the `add_medication_modal_test.dart:160-197` pattern), not by tapping the clock face.
- [x] **AC-9**: Production changes are limited to adding behavior-preserving `ValueKey`s (Meds FAB, form chips, any field the driver needs); the existing 393 tests still pass and `dart analyze` is clean.
- [x] **AC-10**: `docs/` gains a testing section covering the integration_test harness, the run command (`flutter test integration_test -d <device>`), and the hermetic-temp-DB vs real-file-smoke distinction.
- [x] **AC-11**: All new test/harness code complies with the constitution (§3.1 no `!`, no `dynamic`, exhaustive switches; §3.4 mocktail/fixture rules where applicable) and `dart analyze` passes.

## 6. Out of Scope

- NOT included: the **mark-intake-taken** golden flow (UI not built — Today screen is `"Hello World"`).
- NOT included: the **weekly-adherence** golden flow (UI not built — History is a placeholder).
- NOT included: **CI wiring** (GitHub Actions Android emulator / iOS simulator) — deferred to a follow-up.
- NOT included: **iOS simulator** runs — test code stays platform-agnostic but only Android (`emulator-5554`) is targeted now.
- NOT included: medication **list rendering / edit / delete** flows (Meds body is still `SizedBox.shrink()`).
- NOT included: golden-image/screenshot testing, performance/load testing, accessibility auditing.
- NOT included: any refactor of production code beyond adding test `ValueKey`s.
- NOT included: changing the production `driftDatabase(name: 'dosly')` connection or the drift schema.

## 7. Technical Constraints

- **Constitution §3.4** — integration tests are golden flows only; this delivers the first one (add medication). Integration tests live in `integration_test/` (Flutter convention), distinct from `test/` which mirrors `lib/`.
- **Constitution §3.1 / §4.2.1** — test + harness code: no `!`, no `dynamic`, no unchecked `as`, exhaustive `switch`; no `print`/`debugPrint`.
- **Constitution §2.3** — add the dependency with `flutter pub add --dev`, never by hand-editing `pubspec.yaml`.
- **Must reuse** the existing keyboard-mode picker technique (`add_medication_modal_test.dart:160-197`) rather than inventing a new picker driver.
- **Must override at the seam** — `appDatabaseProvider` (and the prefs init seam), per MEMORY L127's lesson: override only the leaf async seam and drive the real chain above it; do not override the consumer under test.
- **UTC storage convention** — assertions account for `startDate` stored as a UTC calendar date and `createdAt` as a UTC timestamp.
- **Device locale = English** for the emulator run, so semantic labels ('Hour'/'Minute'/'OK') and form-chip text match; or the harness resolves labels via localization.
- **No schema migration** — `schemaVersion` stays 1.

## 8. Open Questions

- Whether to **extract** the currently-private keyboard-mode picker helper from `add_medication_modal_test.dart` into a shared test utility (DRY) or duplicate it in the harness — decide in `/plan`.
- Whether the golden-flow test boots the full app **per variation** (8 boots) or boots once and resets between variations — `/plan` decides the mechanism; AC-6 (per-variation isolation) must hold either way.
- Exact docs location for the testing section: extend `docs/architecture.md` vs. new `docs/guides/testing.md` — `/plan`/`tech-writer` decides.
- Whether a couple of form-dependent fields already expose enough stable finders or need additional `ValueKey`s beyond the FAB + form chips — surfaced during `/breakdown`.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Integration-test flakiness from `pumpAndSettle`/timing on a real device | Med | Med | Keyboard-mode pickers (deterministic), explicit finders + waits, injected `Clock` for any time-sensitive assertion, avoid real delays |
| Full-app boot per variation is slow | Low–Med | Low | Acceptable for local runs; CI deferred; `/plan` may boot once with per-variation fresh DB |
| Temp-file / `dosly_inttest` DB files leak on a crashed run | Low | Low | `addTearDown` + try/finally delete; use OS temp dir |
| Adding `ValueKey`s touches production widgets | Low | Low | Scope strictly to FAB + form chips; behavior-preserving; rerun full suite (AC-9) |
| `driftDatabase('dosly_inttest')` needs path_provider plugin registered under the test binding | Low | Med | `integration_test` runs the real app, so plugins are registered; the smoke test is the canary that proves it |
| Localized finder mismatch if emulator locale isn't English | Low | Med | Pin/assert device locale English, or resolve labels via `AppLocalizations` in the harness |

## 10. References

- `research/2026-06-18-integration-test-harness.md` — feasibility, approach options (hermetic temp-file = Option C), and the device-bug history that motivates this.
- `MEMORY.md` L127 (override the leaf seam, drive the real chain; build ≠ runtime), L139 (per-branch e2e coverage gap for `_onSave`), L248 (`!`-free router context in tests).
- Constitution §3.4 (golden flows), §3.1 (type safety), §2.3 (dependency policy).
