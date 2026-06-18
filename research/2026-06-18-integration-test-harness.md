# Research: Integration-test harness for dosly golden flows

**Date**: 2026-06-18
**Topic**: `integration_test` harness driving the real app on an emulator — golden flows (add-medication variations, mark-intake-taken, weekly-adherence), hermetic vs real DB, driving pickers, local vs CI
**Verdict**: **Feasible — recommended** (high fit; addresses a recurring, documented gap)

## Summary

dosly has 393 host-VM unit/widget tests but **zero on-device tests** — and its own memory shows this gap has bitten it at least twice: the Feature-026 `sharedPreferences` provider-wiring crash on first device run, and the drift native-library/DB-open failure that triggered this research. Both are "**build success ≠ runtime success**" failures that host-VM tests structurally cannot catch. The constitution (§3.4) already *mandates* golden-flow integration tests and names the three flows; the building blocks already exist (`ProviderScope` overrides, in-memory drift, and — critically — a **reliable keyboard-mode time-picker driver** already written in the modal widget test). The new pieces are small: the `integration_test` dev dependency, an `integration_test/` dir, a shared harness, and one real design decision (hermetic vs. real DB). Recommend proceeding to `/specify`, scoped to the **harness + add-medication flow first**.

## Codebase Findings

### Existing related code
| Area | Files | Relevance |
|------|-------|-----------|
| Picker driving (the adb blocker) | `test/features/meds/presentation/widgets/add_medication_modal_test.dart:160-197` | Already drives `showTimePicker` deterministically via **keyboard input mode** (`enterText` into 'Hour'/'Minute', tap OK). Lift-and-reuse. |
| Provider override seam | same file `:296` (`addMedicationProvider.overrideWith`) | Pattern for injecting a real/fake repo into the running widget tree |
| In-memory drift | `test/features/meds/data/repositories/medication_repository_impl_test.dart:68`, `medication_mapper_test.dart:156` | `AppDatabase(NativeDatabase.memory())` — the hermetic-DB pattern |
| App launch seam | `lib/app_bootstrap.dart`, `lib/main.dart` | `main()` -> `ProviderScope(child: AppBootstrap())`; override `appDatabaseProvider` / `sharedPreferencesInitProvider` at root |
| Widget keys | `lib/features/meds/presentation/widgets/add_medication_modal.dart` (many `ValueKey`s) | Form fields/buttons already keyed for `find.byKey` |
| Memory precedent | `.claude/memory/MEMORY.md` L127, L139, L248 | Project already recommends "add ONE integration test that drives the REAL chain"; calls device-only crashes out explicitly |

### Patterns available
- **`ProviderScope` overrides** to swap the DB at the root -> hermetic test DB.
- **Keyboard-mode picker driving** -> deterministic time/date entry (the exact thing adb couldn't do).
- **`find.byKey` / `byIcon` / `widgetWithText` + `pumpAndSettle`** -> standard `WidgetTester` API that runs unchanged under `integration_test`.

### Gaps
- No `integration_test` dependency, no `integration_test/` directory, no test harness/helpers.
- **No test ever exercises the real `driftDatabase(name: 'dosly')` path** (path_provider + the native file) — only `NativeDatabase.memory()`.
- Modal widget tests use a **fake repo**, so the 8-variation persistence is never proven end-to-end against a real DB.
- No CI at all (`.github/workflows` absent); `docs/architecture.md` has no testing section.

## Constitution Constraints

| Rule | Impact |
|------|--------|
| **§3.4** "Integration tests: golden flows only — add medication, mark intake taken, view weekly adherence" | **Defines the scope.** This is mandated, not speculative. |
| §2.3 packages via `flutter pub add`, new dep needs justification | `integration_test` (first-party) — justification is §3.4 + the recurring device-bug pattern |
| §3.1 no `!`, exhaustive switches (applies to test code) | Memory L248 already has the `!`-free router-context idiom for tests |
| §6.1 minimal changes | Harness is purely additive — no production-code changes |

## Approaches (the central design decision: which DB)

### Option A — In-memory DB override (hermetic, fast)
- Override `appDatabaseProvider` with `NativeDatabase.memory()`.
- **Pros**: repeatable, no data pollution, exact row assertions, CI-friendly, fast.
- **Cons**: skips path_provider + the real file path. *Would* have caught the native-lib-not-linked failure (the lib still loads), but not a path/file-specific failure.
- **Complexity**: Low

### Option B — Real default on-device DB (no override)
- **Pros**: exercises the entire real path including path_provider — catches everything.
- **Cons**: pollutes the real `dosly.sqlite`, needs cleanup, order-dependent, unsafe for CI.
- **Complexity**: Medium

### Option C — Temp-file drift DB per test + one real-launch smoke test *(recommended)*
- Each golden-flow test gets a fresh `NativeDatabase(File(tempDir/...))`; **plus** one minimal smoke test that boots the real `main()`/`AppBootstrap` with the **default** DB and asserts it opens + a single save succeeds.
- **Pros**: exercises real native sqlite3 + file I/O (catches the *class* of bug that triggered this research) while staying isolated and assertable; the smoke test guards the real documents-dir path; CI-safe.
- **Cons**: a little more harness code (temp-dir lifecycle).
- **Complexity**: Low–Medium

**Recommended: Option C.** It's the only one that both stays hermetic *and* exercises the real native/file path that host-VM tests can't reach — directly closing the gap that produced the save bug.

## External Research (new dependency involved)

- **`integration_test`** — first-party Flutter SDK package, stable. Provides `IntegrationTestWidgetsFlutterBinding`; the **same `WidgetTester` code** runs on a real device/emulator via `flutter test integration_test/...`. (Supersedes legacy `flutter_driver` for in-app E2E.)
- **CI**: Android needs an emulator in CI (`reactivecircus/android-emulator-runner`); known to be slow/flaky. iOS uses a simulator. **Recommend local-first, defer CI** to a follow-up so flakiness doesn't gate the harness landing.
- *(Facts from established knowledge; no web search needed — first-party, stable.)*

## Complexity Assessment

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Codebase changes | Low–Med | 1 dev dep, `integration_test/` dir, 1 harness helper, 1 golden-flow test (8 variations) |
| New dependencies | Low | `integration_test` (first-party) |
| Risk | Low | Additive; main risk is CI emulator flakiness — mitigated by deferring CI |

## Recommendation

**Proceed to `/specify`** — scope the first spec to the **harness + the add-medication golden flow only**. The other two §3.4 flows aren't buildable yet: the Today screen is still `"Hello World"` and History is a placeholder, so *mark-intake-taken* and *weekly-adherence* have no UI to drive. Defer them (and CI) to follow-up specs as those features ship.

Refined description to copy-paste:

> `/specify "integration_test harness + add-medication golden-flow test. Add the integration_test dev dependency and an integration_test/ dir; build a shared harness that boots the real app (main/AppBootstrap) with a hermetic temp-file drift DB override, plus one on-device smoke test asserting the real driftDatabase('dosly') opens and a save persists. First golden flow drives the add-medication modal through all 8 form variations (tablet, capsule, syrup, drops, injection, inhaler, cream, sachet x continuous/course) using the existing keyboard-mode picker pattern, and asserts the persisted medication + time_slot rows. Defer mark-intake and weekly-adherence flows (UI not built yet) and CI wiring to follow-ups."`

## Appendix — context that produced this research

- Triggered while diagnosing a "Couldn't save medication" error on the add-medication Save button.
- Root cause (confirmed): the app was running a build from before `sqlite3_flutter_libs` + `drift_flutter` were added (commit `4aa50f9`); a full reload linked the native library and saves began persisting. Verified on `emulator-5554`: 2 medications + 2 time-slots persisted, `PRAGMA integrity_check` ok, `foreign_key_check` clean.
- Attempting to add all form variations via blind `adb shell input` taps proved unreliable (the FAB would not respond to synthetic taps though nav-bar taps and a real finger worked), which motivated a proper keyed integration-test harness.
