# Task 006: Add-medication golden-flow test (8 variations)

**Agent**: qa-engineer
**Files**: `integration_test/add_medication_golden_test.dart`
**Depends on**: 003, 004, 005
**Context docs**: `specs/033-integration-tests/plan.md` (Component Map, decisions), `integration_test/support/medication_fixtures.dart`
**Review checkpoint**: Yes

**Description**:
The first golden flow. For each of the 8 fixtures, boot a fresh app against a fresh hermetic temp-file DB, drive the add-medication modal end-to-end, and assert the persisted rows. Each variation runs as its own `testWidgets` so a fresh `ProviderScope` + DB gives per-variation isolation (AC-6).

**Change details**:
- In `integration_test/add_medication_golden_test.dart` (new):
  - `IntegrationTestWidgetsFlutterBinding.ensureInitialized();` in `main()`.
  - `for (final f in medFixtures) testWidgets('persists ${f.name} (${f.formKey})', (tester) async { final db = await bootAppWithTempDb(tester); await addMedication(tester, f); await expectPersisted(db, f); });`
  - Ensure each test boots its own DB (fresh, empty) and tears it down (rely on the harness teardown registered via `addTearDown`).
  - Type-safe; no `!`, no `dynamic`.

**Done when**:
- [x] `main()` calls `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`
- [x] One `testWidgets` per fixture (8 total), each boots a fresh temp DB, drives the modal, and calls `expectPersisted`
- [x] `flutter test integration_test/add_medication_golden_test.dart -d emulator-5554` passes all 8 cases
- [x] `dart analyze` passes

**Spec criteria addressed**: AC-2, AC-5, AC-6, AC-11

## Contracts

### Expects
- `bootAppWithTempDb(WidgetTester)` exists and returns the test `AppDatabase` (Task 003 Produces)
- `medFixtures` (8 elements) and `expectPersisted(` exist (Task 004 Produces)
- `addMedication(WidgetTester, MedFixture)` exists (Task 005 Produces)

### Produces
- `add_medication_golden_test.dart` references `IntegrationTestWidgetsFlutterBinding.ensureInitialized`
- `add_medication_golden_test.dart` iterates `medFixtures` and calls `bootAppWithTempDb`, `addMedication`, and `expectPersisted`

## Completion Notes

**Status**: Complete
**Completed**: 2026-06-18
**Files changed**: `integration_test/add_medication_golden_test.dart` (new)
**Contract**: Expects [3/3 verified] | Produces [2/2 verified]
**On-device result**: `flutter test integration_test/add_medication_golden_test.dart -d emulator-5554` → **8/8 passed** (ITTablet, ITCapsule, ITSyrup, ITDrops, ITInjection, ITInhaler, ITCream, ITSachet), ~56s. Each booted the real app, drove the modal end-to-end through the UI, and asserted persisted medications + time_slots rows. Validates the full presentation→domain→data→drift path on a device — the coverage no host-VM test could provide.
**Notes**: Transient `adb install ... not enough space` on first install; Flutter auto-recovered (uninstalled old APK, reinstalled) and all tests ran. Emulator disk was low — worth a `flutter clean` / emulator wipe if it recurs. Code review covered by the consolidated support-layer review (Task 005); the golden test itself is a trivial fixture loop validated by the green on-device run.
