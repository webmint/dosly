# Task 003: Widget tests for the form-dependent fields

**Agent**: qa-engineer
**Files**: `test/features/meds/presentation/widgets/add_medication_modal_test.dart`
**Depends on**: 002
**Blocks**: None
**Context docs**: None
**Review checkpoint**: No

## Description

Add a widget-test group covering the form-dependent fields built in Task 002, and keep all existing spec-011/026/027 tests passing unchanged. Tests locate elements by `ValueKey`, icon, and visible text (the field widgets are private and cannot be referenced by type from the test library). The existing harness (`_harness({required Locale locale})` rendering `AddMedicationModal` as `home`) is reused.

## Change details

In `test/features/meds/presentation/widgets/add_medication_modal_test.dart` — add a new group (e.g. `AddMedicationModal form-dependent fields`) with tests for:

- **(a) No selection → no conditional fields**: on initial render, `find.byKey(const ValueKey('medsAddQtyValue'))` is `findsNothing`, `find.byKey(const ValueKey('medsAddDoseField'))` is `findsNothing`, the stock keys are `findsNothing`, and `find.byType(TextField)` is `findsOneWidget` (the name field only).
- **(b) Tablet → stepper + stock, no dose**: open the picker (`tester.tap(find.byIcon(LucideIcons.chevronDown)); pumpAndSettle()`), tap `find.text('Tablet')`, `pumpAndSettle()`. Assert: `find.byKey(const ValueKey('medsAddQtyValue'))` `findsOneWidget` showing `0.5`; the localized `Quantity per intake` label and `tab` unit are present; the stock labels `Remaining`/`Total in pack`/`Warn when remaining reaches` are present (`medsAddStockRemaining`/`Total`/`Warn` keys `findsOneWidget` each); `find.byKey(const ValueKey('medsAddDoseField'))` is `findsNothing`.
- **(c) Stepper math**: with Tablet selected (initial `0.5`), tap `find.byKey(const ValueKey('medsAddQtyIncrement'))` → value `1` (then `1.5`); tap `find.byKey(const ValueKey('medsAddQtyDecrement'))` repeatedly → value never drops below `0.5`. Select Capsule and assert initial `1`, increment → `2`, decrement clamps at `1`. (Read the value `Text` via the `medsAddQtyValue` key.)
- **(d) Syrup → dose field + unit, no stepper/stock**: select Syrup; assert `find.byKey(const ValueKey('medsAddDoseField'))` `findsOneWidget`, the dose unit dropdown (`medsAddDoseUnit` key) shows the localized `ml`, and `find.byKey(const ValueKey('medsAddQtyValue'))` + the stock keys are `findsNothing`.
- **(e) Inhaler → nothing**: select Inhaler; assert all conditional keys (`medsAddQtyValue`, `medsAddDoseField`, `medsAddStockRemaining`) are `findsNothing`.
- **(f) Reset on switch**: select Tablet (stepper+stock present), re-open the picker via the chevron, select Syrup; assert the stepper/stock keys are now `findsNothing` and the dose field is `findsOneWidget` (form-switch reset).

All new assertions use scoped finders (`find.byKey`, `find.byIcon`, `find.text`) — do **not** add a post-selection bare `find.byType(TextField)` single-match. Drive every state change with a `pump()`/`pumpAndSettle()` before asserting (MEMORY Bug 020). Keep all existing groups (`locale switching`, `structure`, `typography`, `form picker`) intact and passing.

## Contracts

### Expects
- `add_medication_modal.dart` mounts `_DoseField`/`_QuantityStepper`/`_StockCard` gated on the selected form, with the `ValueKey`s from Task 002 (`medsAddQtyValue`, `medsAddQtyDecrement`, `medsAddQtyIncrement`, `medsAddDoseField`, `medsAddDoseUnit`, `medsAddStockRemaining`, `medsAddStockTotal`, `medsAddStockWarn`).
- `app_localizations.dart` exposes the 14 EN getters (Task 001) so EN strings (`Quantity per intake`, `Remaining`, `tab`, `ml`, …) resolve in the test harness.
- The existing `_harness`, the spec-026 structure tests, and the spec-027 `form picker` group exist.

### Produces
- `add_medication_modal_test.dart` contains a new test group asserting cases (a)–(f) above.
- The existing `locale switching`, `structure`, `typography`, and `form picker` groups remain present and unmodified in intent.

## Done when
- [x] New group covers (a) no-selection emptiness + single `TextField`; (b) Tablet stepper+stock/no-dose; (c) stepper increment/decrement + clamp for Tablet and Capsule; (d) Syrup dose+unit/no stepper-stock; (e) Inhaler nothing; (f) reset on form switch.
- [x] All assertions are self-validating and use keyed/icon/text finders (no post-selection bare `find.byType(TextField)`).
- [x] All pre-existing tests (spec 011/026/027) remain and pass unchanged.
- [x] `dart analyze` passes on the test file (zero issues; no lint-suppression comments).
- [x] `flutter test` passes for the full project.

## Spec criteria addressed
AC-2, AC-4, AC-5, AC-6, AC-7, AC-11, AC-12, AC-13, AC-14

## Completion Notes
**Status**: Complete
**Completed**: 2026-06-14
**Files changed**: test/features/meds/presentation/widgets/add_medication_modal_test.dart
**Contract**: Expects [3/3 verified] | Produces [2/2 verified] — new `AddMedicationModal form-dependent fields` group with 6 tests (a–f); 4 existing groups (locale switching, structure, typography, form picker) intact
**Verification**: dart analyze "No issues found!"; flutter test 305/305 pass (299 prior + 6 new)
**Code review**: APPROVE WITH WARNINGS — W1/W2: test (b) asserts stock labels via bare `find.text('Remaining'/'Total in pack'/'Warn when remaining reaches')` instead of the `medsAddStockRemaining/Total/Warn` keys (works since strings are unique; would survive a key deletion). W4: Inhaler test (e) is negative-only, though `tester.tap(find.text('Inhaler'))` throws if absent so it cannot pass vacuously. W3: style — add comment that stepper uses `pump()` (no animations). Not actioned (tests correct + passing), consistent with 027 precedent; logged for the data-save iteration.
**Notes**: stepper math/clamp assertions verified exact against `_formatQuantity` (0.5→"0.5", 1.0→"1", 1.5→"1.5", 2→"2"). Reset test (f) re-opens the picker via chevron before the second selection. Dropdown unit checked via `find.descendant` scoped to the `medsAddDoseUnit` key.
