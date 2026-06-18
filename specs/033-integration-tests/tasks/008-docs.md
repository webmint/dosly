# Task 008: Document the integration-test harness

**Agent**: tech-writer
**Files**: `docs/guides/testing.md`, `docs/architecture.md`
**Depends on**: 006, 007
**Context docs**: `docs/architecture.md`, `specs/033-integration-tests/spec.md`
**Review checkpoint**: No

**Description**:
Document the new on-device testing layer so future contributors/agents know it exists and how to run it. Capture the three-layer split (unit/widget/integration), the harness, the run command, and the hermetic-temp-DB vs real-file-smoke distinction.

**Change details**:
- In `docs/guides/testing.md` (new):
  - Test layers: unit (`test/.../domain`), data (`test/.../data`, in-memory drift), widget (`test/.../presentation`), and on-device integration (`integration_test/`).
  - The harness: `bootAppWithTempDb` boots the real app via `AppBootstrap` with `appDatabaseProvider` (temp-file drift DB) + `sharedPreferencesInitProvider` (in-memory) overridden; the add-medication driver uses keyboard-mode pickers.
  - How to run: `flutter test integration_test -d <device>` (e.g. `emulator-5554`); list the golden + smoke files.
  - Hermetic temp-file DB (golden flow, isolated/repeatable) vs the `dosly_inttest` real-file smoke test (exercises path_provider + native SQLite open — the regression guard for device-only DB failures).
- In `docs/architecture.md`:
  - Add one bullet under the testing/architecture section: on-device integration tests live in `integration_test/`, drive the real app via `AppBootstrap` with leaf-seam overrides.

**Done when**:
- [x] `docs/guides/testing.md` exists and covers layers, harness, run command, and the temp-DB vs real-file-smoke distinction
- [x] `docs/architecture.md` has a bullet referencing `integration_test/`
- [x] No code changes; `dart analyze` still clean

**Spec criteria addressed**: AC-10

## Contracts

### Expects
- Golden-flow test exists: `integration_test/add_medication_golden_test.dart` (Task 006 Produces)
- Smoke test exists: `integration_test/db_open_smoke_test.dart` (Task 007 Produces)

### Produces
- `docs/guides/testing.md` exists and references `integration_test` and `flutter test integration_test`
- `docs/architecture.md` references `integration_test/`

## Completion Notes

**Status**: Complete
**Completed**: 2026-06-18
**Files changed**: `docs/guides/testing.md` (new), `docs/architecture.md` (added "Testing" subsection bullet at line ~334)
**Contract**: Expects [2/2 verified] | Produces [2/2 verified]
**Notes**: testing.md documents the 4 test layers, the `bootAppWithTempDb`/`bootAppWithDb` harness, the golden + smoke suites, the driver + `enterTimeViaKeyboard`, the `MedFixture`/`expectPersisted` (incl. the `isAtSameMomentAs` drift caveat), the run commands, the hermetic-vs-real-file rationale, and the low-disk/uninstall caveat. Docs-only — no `.dart` changed, analyze unaffected.
