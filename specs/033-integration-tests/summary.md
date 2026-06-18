## Feature Summary: 033 — Integration-test harness + add-medication golden flow

### What was built
dosly's first **on-device test layer**: an `integration_test` harness that boots the real app on a device/emulator and a golden flow that drives the add-medication form through all 8 medication-form variations, asserting each persists correctly to the drift database. A separate real-file smoke test exercises the production `driftDatabase(...)` native/file path — the exact regression guard that would have caught the "Couldn't save medication" native-library failure that motivated this work. Closes the "build success ≠ runtime success" gap that host-VM tests structurally can't cover.

### Changes
- Task 001: Add `integration_test` dev dependency — enabled the on-device suite (SDK-pinned form).
- Task 002: Add stable `ValueKey`s — FAB, form-picker toggle, 8 form chips (+ Save button) so the driver can find them; behavior-preserving.
- Task 003: Boot harness — `bootAppWithTempDb` boots the real `AppBootstrap` with a hermetic temp-file drift DB + in-memory prefs, overriding only the two leaf seams.
- Task 004: Fixtures + assertions — `MedFixture`, the 8-variation matrix, and `expectPersisted` (drift-safe `isAtSameMomentAs` date checks).
- Task 005: UI driver — `addMedication` drives the modal end-to-end; `enterTimeViaKeyboard` for deterministic time entry.
- Task 006: Golden-flow test — one case per fixture (8), each a fresh boot+DB; **8/8 pass on emulator**.
- Task 007: Real-file smoke test — `driftDatabase('dosly_inttest')` opens via path_provider + native SQLite, persists, cleans up; never touches real `dosly` data.
- Task 008: Docs — `docs/guides/testing.md` + an `architecture.md` testing bullet.

### Files changed
- `integration_test/` — 5 files added (harness, driver, fixtures, golden test, smoke test; ~936 lines)
- `lib/features/meds/presentation/` — 2 files modified (4 `ValueKey` additions, no logic change)
- `docs/` — 1 added (`guides/testing.md`), 1 modified (`architecture.md`)
- `pubspec.yaml`/`pubspec.lock` — `integration_test` + `path_provider` (both dev-scoped)
- Total (code + docs): 11 files changed, ~1173 insertions. With spec/plan/tasks/research artifacts: 26 files, ~2049 insertions, across 19 WIP/checkpoint commits.

### Key decisions
- **Hermetic temp-file drift DB per golden case** (not in-memory) — exercises real native SQLite + file I/O while staying isolated; **real-file `dosly_inttest`** for the smoke test exercises path_provider with zero risk to real data.
- **Override only the two leaf seams** (`appDatabaseProvider`, `sharedPreferencesInitProvider`) and drive the real settings/router chain — surfaces wiring bugs instead of masking them (MEMORY L127).
- **Boot-per-variation** (fresh `ProviderScope` + DB per `testWidgets`) for isolation; **keyboard-mode pickers** for deterministic time entry (the technique adb couldn't do).

### Deviations from plan
- Task 001: `flutter pub add` resolves `integration_test` to a discontinued pre-null-safety pub.dev package; declared as `integration_test: { sdk: flutter }` instead (the canonical SDK form) — justified deviation from §2.3's "use pub add".
- Task 005/007: added one extra production key (`medsAddSaveButton`) for locale-independent Save finding, and extracted `bootAppWithDb` from the harness (DRY) so the smoke test can supply its own DB — both within the spec's "keys/harness as needed" intent.

### Acceptance criteria
- [x] AC-1: `integration_test` dev dependency added
- [x] AC-2: `integration_test/` runs on the emulator (9/9 pass)
- [x] AC-3: harness boots the real app with a temp-file DB + prefs override
- [x] AC-4: reusable add-medication driver
- [x] AC-5: 8-variation golden flow asserts persisted medications + time_slots rows
- [x] AC-6: per-variation hermetic isolation
- [x] AC-7: real-file `dosly_inttest` smoke test (real native/file path, no real-data risk)
- [x] AC-8: keyboard-mode time pickers
- [x] AC-9: production change limited to `ValueKey`s; 393 host tests still green
- [x] AC-10: testing docs
- [x] AC-11: type-safe test code; `dart analyze` clean
