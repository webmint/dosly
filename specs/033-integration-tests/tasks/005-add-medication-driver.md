# Task 005: Build the add-medication UI driver + keyboard-mode picker

**Agent**: qa-engineer
**Files**: `integration_test/support/add_medication_driver.dart`
**Depends on**: 002, 004
**Context docs**: `test/features/meds/presentation/widgets/add_medication_modal_test.dart` (`_pickTimeInDialog`, lines ~160-197), `lib/features/meds/presentation/widgets/add_medication_modal.dart` (field keys)
**Review checkpoint**: No

**Description**:
Create the reusable driver that, given a booted app and a `MedFixture`, performs the full add-medication UI flow: navigate Today→Meds, open the modal via the FAB, enter the name, select the form, fill the applicable form-dependent fields, add each intake time via keyboard-mode entry, choose the intake type (filling course params), and tap Save. Reproduce the keyboard-mode time-picker technique from the existing widget test (do not refactor that file).

**Change details**:
- In `integration_test/support/add_medication_driver.dart` (new):
  - `Future<void> enterTimeViaKeyboard(WidgetTester tester, {required String hour, required String minute})` — port of `_pickTimeInDialog`: tap `Icons.keyboard_outlined` (fallback `Icons.keyboard`), `enterText` into `find.bySemanticsLabel('Hour')` / `'Minute'`, tap `find.text('OK')`, `pumpAndSettle`.
  - `Future<void> addMedication(WidgetTester tester, MedFixture f)`:
    - Tap the Meds bottom-nav destination (find by its icon or localized label), `pumpAndSettle`.
    - Tap `find.byKey(const ValueKey('medsAddFab'))`, `pumpAndSettle`.
    - `enterText` the name into the name `TextField`.
    - Tap `find.byKey(const ValueKey('medsFormPickerToggle'))` to expand, then `find.byKey(ValueKey('medsForm_${f.formKey}'))`, `pumpAndSettle`.
    - If quantity form: adjust `medsAddQtyIncrement`/`Decrement` to reach `f.quantity`; fill stock via `medsAddStockRemaining`/`Total`/`Warn` when present. If dose form: `enterText` `medsAddDoseField`, select unit via `medsAddDoseUnit` dropdown when non-default.
    - For each time in `f.times`: tap the add-time `ActionChip`, then `enterTimeViaKeyboard`.
    - If `f.isCourse`: tap the course segment (e.g. `find.byIcon(LucideIcons.repeat)`); fill `medsAddCourseDuration`/`Pause`. Else leave continuous (default).
    - Tap `find.widgetWithText(FilledButton, <localized Save>)`, `pumpAndSettle`.
  - Type-safe: no `!`, no `dynamic`; resolve localized labels via `AppLocalizations` or stable English on the emulator.

**Done when**:
- [x] `add_medication_driver.dart` declares `addMedication(WidgetTester tester, MedFixture f)` and `enterTimeViaKeyboard(...)`
- [x] Uses keys `medsAddFab`, `medsFormPickerToggle`, `medsForm_<key>` and existing field keys
- [x] Times entered via keyboard mode (not clock-face taps)
- [x] `dart analyze` passes

**Spec criteria addressed**: AC-4, AC-8

## Contracts

### Expects
- Production keys exist: `ValueKey('medsAddFab')`, `ValueKey('medsFormPickerToggle')`, `ValueKey('medsForm_${option.key}')` (Task 002 Produces)
- `add_medication_modal.dart` field keys exist: `medsAddDoseField`, `medsAddDoseUnit`, `medsAddQtyIncrement`, `medsAddQtyDecrement`, `medsAddStockRemaining`, `medsAddStockTotal`, `medsAddStockWarn`, `medsAddCourseDuration`, `medsAddCoursePause`, `medsAddIntakeTypeSegmented`
- `medication_fixtures.dart` declares `MedFixture` (Task 004 Produces)

### Produces
- `add_medication_driver.dart` declares `addMedication(`
- `add_medication_driver.dart` declares `enterTimeViaKeyboard(`
- `add_medication_driver.dart` references `find.bySemanticsLabel('Hour')` and `find.bySemanticsLabel('Minute')`

## Completion Notes

**Status**: Complete
**Completed**: 2026-06-18
**Files changed**: `integration_test/support/add_medication_driver.dart` (new); `lib/features/meds/presentation/widgets/add_medication_modal.dart` (added `ValueKey('medsAddSaveButton')` during review repair); `integration_test/support/medication_fixtures.dart` (review repair — see below)
**Contract**: Expects [3/3 verified] | Produces [3/3 verified]
**Notes**: Driver navigates via `find.byIcon(LucideIcons.pill)` → FAB key → name (sole TextField) → form picker keys → per-form dose/quantity/stock → keyboard-mode times → course segment via `LucideIcons.repeat` → Save by key. No `!`.
**Consolidated code review (covers Tasks 003+004+005)**: REQUEST CHANGES → addressed. **Critical** caught & fixed: `expectPersisted` compared `startDate` with `==` to a UTC-flagged DateTime, but drift `dateTime()` reads back local-flagged (MEMORY L135) → would fail all 8; fixed to `isAtSameMomentAs` against the LOCAL calendar date (also fixes a UTC-vs-local midnight-boundary flake). Warnings fixed: added `medsAddSaveButton` production key for locale-independent Save tap; added post-stepper-loop target assertion. Skipped: reviewer's import-ordering finding (false positive — `dart analyze` clean, matches project convention). Re-verified by inspection: analyze clean, `flutter test` 393/393 pass.
