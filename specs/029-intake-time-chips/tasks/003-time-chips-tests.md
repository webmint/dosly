# Task 003: Widget tests for the intake-time chips

**Agent**: qa-engineer
**Files**: `test/features/meds/presentation/widgets/add_medication_modal_test.dart`
**Depends on**: 002
**Blocks**: None
**Review checkpoint**: No
**Context docs**: None

**Description**:
Add a widget-test group covering the intake-time section's behavior, reusing the existing `_harness(locale:)` helper at the top of the file. Tests must drive the real `showTimePicker` dialog (tap the add/edit affordance, interact with the dialog, confirm) and assert chip state. Follow constitution §3.4 (screens with logic get widget tests) and the existing test style (`testWidgets`, `find.*`, `pumpAndSettle`). Do not modify production code; if a test reveals a defect, report it (do not silently patch the widget here).

**Change details**:
- In `test/features/meds/presentation/widgets/add_medication_modal_test.dart`, add `group('AddMedicationModal intake time', () { … })` with tests:
  - **Initial empty state**: pump the modal (en locale); assert the section title `Intake time` is present, the add-chip label `Time` is present, and there are **zero** `InputChip`s (AC-1, AC-2).
  - **Add a time**: tap the add `ActionChip`; in the time-picker dialog, switch to input mode if needed and enter/confirm a time (e.g. 09:00); `pumpAndSettle`; assert one `InputChip` exists whose label reads the 24-hour string `09:00` (AC-3, AC-5, AC-10).
  - **Cancel adds nothing**: open the picker via the add chip, tap Cancel; assert still zero `InputChip`s (AC-4).
  - **Edit replaces**: with one chip present, tap the chip body; confirm a different time; assert the chip now shows the new time and there is still exactly one chip (AC-6).
  - **Delete via ×**: with one chip present, tap its delete icon (`find.byType(InputChip)` → its delete affordance, e.g. the `LucideIcons.x` icon); assert the chip is gone and **no** time-picker dialog opened (AC-7).
  - **Ascending order**: add 20:00 then 08:00; assert the rendered `InputChip` labels appear in ascending order `08:00` before `20:00` (AC-8).
  - **Duplicate rejected**: add 08:00, then add 08:00 again; assert there is still exactly one `08:00` chip and a `SnackBar` containing the localized duplicate message is shown (AC-9).
- Prefer entering times via the picker's text-input mode (`enterText` into the hour/minute fields) over dragging the dial, for deterministic results. Keep each test isolated (fresh `pumpWidget`).

**Done when**:
- [x] New `group('AddMedicationModal intake time', …)` covers add, cancel, edit, delete-no-picker, ascending order, duplicate-rejected-with-SnackBar, and edit-to-own-value silent no-op (8 tests).
- [x] All new tests pass via `flutter test test/features/meds/presentation/widgets/add_medication_modal_test.dart`.
- [x] The full suite (`flutter test`) passes — existing spec-026/027/028 tests still green (AC-14). 313/313.
- [x] `dart analyze` passes on the test file.

**Spec criteria addressed**: AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8, AC-9, AC-10, AC-14

## Completion Notes

**Completed**: 2026-06-14
**Files changed**: test/features/meds/presentation/widgets/add_medication_modal_test.dart (only)
**Contract**: Expects [3/3 verified] | Produces [3/3 verified — `group('AddMedicationModal intake time'`, `find.byType(InputChip)` + 24h-label assertions, `find.byType(SnackBar)` + duplicate-message assertion]
**Notes**: 8 tests added (full suite 305→313). Reliable picker interaction: toggle input mode via `Icons.keyboard_outlined`, enter hour/minute via `find.bySemanticsLabel('Hour')`/`('Minute')` (confirmed each matches exactly one widget), confirm with `'OK'` / cancel with `'Cancel'` (sentence case). Fixed test header W1 (now names specs 011/026/027/028/029). Code review APPROVE WITH WARNINGS (no Critical): applied W1 (`_pickTimeInDialog` now genuinely uses semantic labels — comment no longer lies) and W3 (added the AC-9 edit-to-own-value silent-no-op test, which passed immediately → widget already correct). No production code touched. No defects surfaced.

## Contracts

### Expects
- `add_medication_modal.dart` declares `_TimeChips`, the field `_intakeTimes`, and contains a `showTimePicker(` call and `alwaysUse24HourFormat: true` (from task 002).
- `add_medication_modal.dart` references `InputChip` and `ActionChip` (from task 002).
- `test/features/meds/presentation/widgets/add_medication_modal_test.dart` already defines a `_harness({required Locale locale})` helper returning a `MaterialApp` with `AppLocalizations.localizationsDelegates`.

### Produces
- `add_medication_modal_test.dart` contains `group('AddMedicationModal intake time'`.
- `add_medication_modal_test.dart` contains tests asserting `find.byType(InputChip)` counts and 24-hour label text (e.g. `find.text('08:00')`).
- `add_medication_modal_test.dart` contains a `find.byType(SnackBar)` (or duplicate-message) assertion.
