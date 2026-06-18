# Plan: Integration-test harness + add-medication golden flow

**Date**: 2026-06-18
**Spec**: specs/033-integration-tests/spec.md
**Status**: Approved

## Summary

Add the `integration_test` SDK dev dependency and an `integration_test/` tree containing a small **support harness** (boot the real app via `AppBootstrap` with a hermetic temp-file drift DB + in-memory prefs override), a reusable **add-medication UI driver** (keyboard-mode pickers — the technique adb couldn't do but `WidgetTester` does precisely), the **8-variation golden flow** (fresh DB per case, asserts persisted rows), and a **real-file smoke test** (`dosly_inttest`) that exercises the production `driftDatabase(...)` path. The only production changes are behavior-preserving `ValueKey`s on the Meds FAB and form chips.

## Technical Context

**Architecture**: Test/infrastructure layer — no production logic changes. Drives the real Clean-Architecture stack end-to-end (presentation → domain → data → drift) on a device.
**Error Handling**: N/A (test code); assertions use `Either`/row queries, never partial extractors in production.
**State Management**: Riverpod provider **overrides at the root `ProviderScope`** — the established idiom (`test/app_bootstrap_test.dart:226-246`). Override only the leaf seams (`sharedPreferencesInitProvider`, `appDatabaseProvider`); let the real `DoslyApp → router → settings` chain inflate (MEMORY L127).

## Constitution Compliance

- **§3.4 (golden flows / test layout)**: integration tests live in `integration_test/` (Flutter convention), separate from `test/` which mirrors `lib/`. This delivers the first mandated golden flow (add medication). ✅
- **§3.1 / §4.2.1 (type safety)**: harness + tests use no `!`, no `dynamic`, no unchecked `as`, exhaustive switches; no `print`/`debugPrint`. ✅
- **§2.3 (dependency policy)**: add `integration_test` via `flutter pub add --dev` (never hand-edit pubspec). ✅
- **§6.1 (minimal changes)**: production touch limited to `ValueKey`s. ✅ (verified by AC-9: 393 tests still green)
- **MEMORY L127**: override the leaf async seam, drive the real chain — the smoke + golden harness deliberately do NOT override `settingsRepositoryProvider`. ✅
- **MEMORY L248**: `!`-free router context via `tester.element(...)` if direct navigation is ever needed. ✅

## Implementation Approach

### Component Map

| Component | What | Files (new/modified) |
|-----------|------|----------------------|
| Dependency | `integration_test` SDK dev dep (+ `path_provider` if needed for smoke-file cleanup) | `pubspec.yaml` (modify) |
| Boot harness | Pump `ProviderScope(overrides:[prefs, db], child: AppBootstrap())`; build a fresh temp-file `AppDatabase`; in-memory prefs; return the DB handle for assertions; teardown closes DB + deletes temp file | `integration_test/support/app_harness.dart` (new) |
| Add-med driver | Navigate Today→Meds (tap nav), open modal (FAB key), fill name/form/dose/quantity/stock, add intake times via keyboard-mode picker, set intake type (+course fields), tap Save | `integration_test/support/add_medication_driver.dart` (new) |
| Fixtures + assertions | The 8-variation matrix as typed data + expected-row expectations + `medications`/`time_slots` assertion helpers | `integration_test/support/medication_fixtures.dart` (new) |
| Golden flow | One `testWidgets` per variation (fresh boot + fresh temp DB), drives + asserts | `integration_test/add_medication_golden_test.dart` (new) |
| Smoke test | Boot real app with `appDatabaseProvider` → `AppDatabase(driftDatabase(name:'dosly_inttest'))`; add one med; assert persisted; delete the file | `integration_test/db_open_smoke_test.dart` (new) |
| Production keys | `ValueKey` on Meds FAB; `ValueKey`s on the 8 form chips | `lib/features/meds/presentation/screens/meds_screen.dart`, `.../widgets/add_medication_modal.dart` (modify) |
| Docs | Testing guide + architecture bullet | `docs/guides/testing.md` (new), `docs/architecture.md` (modify) |

### Key Design Decisions

| Decision | Chosen Approach | Why | Rejected |
|----------|----------------|-----|----------|
| Golden-flow DB | Temp-file `AppDatabase(NativeDatabase(File(tmp)))`, fresh per variation | Exercises real native sqlite3 + file I/O while staying hermetic (Option C from research) | In-memory (skips file path); real `dosly` (pollutes) |
| Smoke-test DB | `AppDatabase(driftDatabase(name:'dosly_inttest'))` | Real path_provider + native-file open path (catches the native-lib/DB-open class of bug) with zero risk to real data (Q3=b) | Real `dosly` file + cleanup |
| Per-variation isolation | One `testWidgets` per variation; each pumps a fresh `ProviderScope` + fresh temp DB | Satisfies AC-6 by construction; failures don't cascade | Single boot looping 8 saves on one DB (weaker isolation) — **resolves spec Open Q2** |
| Picker driving | Keyboard/text-input mode; helper **duplicated** into `support/` | `WidgetTester` hit-tests precisely (unlike adb); duplicating avoids touching the passing widget-test file (§6.1) | Extract shared util from `test/...modal_test.dart` (touches green tests across the test/↔integration_test/ boundary) — **resolves spec Open Q1** |
| Prefs seam | Override `sharedPreferencesInitProvider` → `Future.value(InMemorySharedPreferencesAsync)` using prod `settingsPrefsKeys`; do NOT override settings repo | Deterministic + drives the real settings chain (MEMORY L127) | Override `settingsRepositoryProvider` (masks wiring) |
| Reach the modal | Tap the Meds bottom-nav destination, then the FAB, via `find.byKey`/`byIcon` | True end-to-end; `WidgetTester.tap` resolves the FAB hit-test that adb couldn't | `context.go('/meds')` shortcut (less realistic) |
| DB assertions | Query the overridden `AppDatabase` instance directly (harness returns the handle) | Exact, fast, unambiguous row checks | Asserting via UI (Meds list isn't built) |
| Time-field assertions | Assert deterministic columns exactly; assert `startDate` at **date granularity** (computed) and `createdAt` within a recent **window** | Avoids `package:clock` zone-propagation flakiness in a booted app | Pin ambient `clock` via `withClock` (doesn't reliably reach widget callbacks) |
| Docs location | New `docs/guides/testing.md` + one bullet in `docs/architecture.md` | Matches storage-rules (how-to → guides) — **resolves spec Open Q3** | architecture.md only |

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `pubspec.yaml` | Modify | `flutter pub add --dev integration_test`; add `path_provider` only if the smoke-file path can't be resolved transitively |
| `integration_test/support/app_harness.dart` | Create | `bootApp(tester, {required AppDatabase db})` + `tempFileDatabase()` + in-memory prefs builder + teardown helpers |
| `integration_test/support/add_medication_driver.dart` | Create | `addMedication(tester, MedFixture)` driver + `enterTimeViaKeyboard(tester, h, m)` |
| `integration_test/support/medication_fixtures.dart` | Create | 8 typed `MedFixture`s (matrix) + expected medication/time-slot expectations + `expectPersisted(db, fixture)` |
| `integration_test/add_medication_golden_test.dart` | Create | 8 `testWidgets`, one per fixture: fresh boot → drive → assert → teardown |
| `integration_test/db_open_smoke_test.dart` | Create | Real-file `dosly_inttest` boot → add one med → assert → delete file |
| `lib/features/meds/presentation/screens/meds_screen.dart` | Modify | Add `key: const ValueKey('medsAddFab')` to the FAB |
| `lib/features/meds/presentation/widgets/add_medication_modal.dart` | Modify | Add `ValueKey('medsForm_<key>')` to each form chip in `_buildChip`; add any missing field keys the driver needs |

### Documentation Impact

| Doc File | Action | What Changes |
|----------|--------|-------------|
| `docs/guides/testing.md` | Create | How the test layers split (unit/widget/integration), the `integration_test` harness, run command (`flutter test integration_test -d <device>`), hermetic-temp-DB vs real-file-smoke distinction |
| `docs/architecture.md` | Update | One bullet: on-device integration tests live in `integration_test/`, drive the real app via `AppBootstrap` with leaf-seam overrides |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `pumpAndSettle` timing flakiness on a real device | Med | Med | Keyboard-mode pickers, explicit finders, no real delays; if a settle hangs on an animation, use bounded `pump` loops |
| Time-field (`startDate`/`createdAt`) nondeterminism | Med | Low | Assert date-granularity + window, not exact instants (see decision table) |
| Smoke-test `dosly_inttest` file path resolution for cleanup | Low | Med | Resolve via `getApplicationDocumentsDirectory()`; delete `.sqlite`(+`-wal`/`-shm`) in `addTearDown`; smoke test itself is the canary that path_provider works |
| `ValueKey` additions ripple into existing widget tests | Low | Low | Additive keys only; rerun full suite (AC-9) |
| Per-variation full-app boot is slow (8×) | Low–Med | Low | Acceptable locally; CI deferred |
| Emulator locale ≠ English breaks `'Hour'`/`'Minute'`/`'OK'`/chip-text finders | Low | Med | Pin/assert device locale English, or resolve labels via `AppLocalizations` in the driver |
| AC-7 path_provider plugin not registered under test binding | Low | Med | `integration_test` runs the real app (plugins registered); smoke test proves it |

## Dependencies

- **`integration_test`** — Flutter SDK package, `dev_dependencies`, via `flutter pub add --dev integration_test`.
- **`path_provider`** — already transitive via `drift_flutter`; add as a direct dep only if the smoke-file cleanup needs a direct import.
- No services, env vars, or schema/migration changes.

## Plan ↔ Spec AC Coverage

| AC | Covered by |
|----|-----------|
| AC-1 dep added | `pubspec.yaml` modify; Dependencies section |
| AC-2 `integration_test/` runs on emulator | All `integration_test/*` files; run command in docs |
| AC-3 harness boot + temp DB + prefs seam | `support/app_harness.dart`; prefs/db override decisions |
| AC-4 add-med driver API | `support/add_medication_driver.dart` |
| AC-5 8-variation row assertions | `support/medication_fixtures.dart` + `add_medication_golden_test.dart` |
| AC-6 per-variation isolation | "Per-variation isolation" decision (fresh ProviderScope+DB per `testWidgets`) |
| AC-7 real-file smoke test | `db_open_smoke_test.dart`; smoke-DB decision |
| AC-8 keyboard-mode pickers | `enterTimeViaKeyboard` in driver; picker decision |
| AC-9 key-only prod change, 393 green | FAB/chip key modifications; §6.1 compliance |
| AC-10 docs testing section | `docs/guides/testing.md` + `architecture.md` |
| AC-11 type-safe test code, analyze clean | Constitution Compliance section |

*All 11 ACs have an implementation path. File Impact additions beyond the spec's Affected Areas: the `support/*` files are an elaboration of the spec's "Test harness" row, and `docs/architecture.md` is added alongside the spec's docs row.*

## Supporting Documents

- [Research](../../research/2026-06-18-integration-test-harness.md) — feasibility + the hermetic-temp-file (Option C) decision; no new `research.md` needed (no unresolved external decisions).
- No `data-model.md` / `contracts.md` — no new entities or API contracts (reuses existing `Medication` aggregate + drift tables).
