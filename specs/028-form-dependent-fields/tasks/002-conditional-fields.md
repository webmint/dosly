# Task 002: Hoist form selection and add the conditional fields to AddMedicationModal

**Agent**: mobile-engineer
**Files**: `lib/features/meds/presentation/widgets/add_medication_modal.dart`
**Depends on**: 001
**Blocks**: 003
**Context docs**: None (design source: `dosly_m3_template.html` — `FORM_FIELDS` `:2730–2739`, dose-row `:2088–2102`, qty-stepper `.qty-stepper` CSS `:622–667` + markup `:2111–2123` + `QTY_CONFIG` `:2864–2885`, stock-card `.stock-card` CSS `:1213–1233` + markup `:2127–2150`)
**Review checkpoint**: Yes

## Description

Add **form-dependent input fields** to the Add-medication modal, rendered between the `_MedicationFormPicker` and the Save `FilledButton`. To drive them, **hoist the picker's selection** to `_AddMedicationModalState` via a callback (the picker keeps its own `_selectedIndex`/`_isOpen` and existing behaviour — preserving the spec-027 tests). Based on the selected form, conditionally render: a **dose field + unit dropdown** (injection/syrup/drops), a **quantity-per-intake stepper** (tablet/capsule), and a **pack-stock card** (tablet/capsule only). All values are **local state, visual-only** — nothing is read by Save (still the documented no-op), validated, or persisted. No `domain/`/`data/`, no Riverpod, no new dependencies.

This is the first use of `DropdownButtonFormField`, `IconButton` for a stepper, and `TextEditingController`s beyond the name field in this modal.

## Change details

In `lib/features/meds/presentation/widgets/add_medication_modal.dart`:

- **Extend `_MedFormOption`** with per-form field config (defaults keep the 8 existing entries valid; populate per the matrix below):
  ```dart
  final bool hasDose;                                    // default false
  final bool hasQuantity;                                // default false
  final bool hasStock;                                   // default false
  final List<String Function(AppLocalizations l10n)> doseUnits;  // default const []
  final double quantityStep;                             // default 1
  final double quantityMin;                              // default 1
  final String Function(AppLocalizations l10n)? quantityUnit;    // default null
  ```
  Populate the 8 `_medFormOptions` entries:
  | key | hasDose | hasQuantity | hasStock | doseUnits | step / min / unit |
  |---|:--:|:--:|:--:|---|---|
  | tablet | – | ✓ | ✓ | – | 0.5 / 0.5 / `medsAddUnitTablet` |
  | capsule | – | ✓ | ✓ | – | 1 / 1 / `medsAddUnitCapsule` |
  | injection | ✓ | – | – | ml, mg, units | – |
  | syrup | ✓ | – | – | ml | – |
  | drops | ✓ | – | – | drops, ml | – |
  | inhaler | – | – | – | – | – |
  | cream | – | – | – | – | – |
  | sachet | – | – | – | – | – |
  (units = the `l.medsAddUnitMl`/`Mg`/`Units`/`Drops`/`Tablet`/`Capsule` getters from Task 001.)
- **Hoist the selection**: add `final ValueChanged<_MedFormOption> onFormSelected;` to `_MedicationFormPicker`; in the option chip `onTap`, after `setState`, call `widget.onFormSelected(_medFormOptions[index])`. Keep `_selectedIndex`/`_isOpen` and all other picker behaviour unchanged.
- **Parent state** in `_AddMedicationModalState`:
  - `_MedFormOption? _selectedForm;` (null = none selected).
  - `double _quantity = 0;` and `int _selectedDoseUnitIndex = 0;`.
  - four `final TextEditingController`s: `_doseController`, `_stockRemainingController`, `_stockTotalController`, `_stockWarnController` — **disposed** in `dispose()` alongside `_nameController`.
  - `void _onFormSelected(_MedFormOption form)`: in `setState`, if `form.key != _selectedForm?.key` call `_resetConditionalFields(form)`, then `_selectedForm = form`.
  - `void _resetConditionalFields(_MedFormOption form)`: `_doseController.clear()`, `_stockRemainingController.clear()`, `_stockTotalController.clear()`, `_stockWarnController.clear()`, `_selectedDoseUnitIndex = 0`, `_quantity = form.hasQuantity ? form.quantityMin : 0`.
  - `String _formatQuantity(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();`
- **Wire the picker**: pass `_MedicationFormPicker(onFormSelected: _onFormSelected)` (drop the `const` since it now takes a callback).
- **Conditional block** in `build`, inserted **after** the picker and **before** the `SizedBox(height: 16)` + Save button, in order **dose → quantity → stock**, each gated by `_selectedForm`:
  - if `_selectedForm?.hasDose ?? false` → `_DoseField(...)`
  - if `_selectedForm?.hasQuantity ?? false` → `_QuantityStepper(...)`
  - if `_selectedForm?.hasStock ?? false` → `_StockCard(...)`
- **`_DoseField`** (private `const StatelessWidget`): a `Row` of `Expanded(flex: 3, child: TextField(controller: _doseController, keyboardType: numberWithOptions(decimal: true), decoration: InputDecoration(labelText: context.l10n.medsAddDoseLabel), key: const ValueKey('medsAddDoseField')))`, a gap, and `Expanded(flex: 2, child: DropdownButtonFormField<int>(key: const ValueKey('medsAddDoseUnit'), value: selectedIndex, decoration: InputDecoration(labelText: context.l10n.medsAddDoseUnitLabel), items: [for (var i=0;i<units.length;i++) DropdownMenuItem(value: i, child: Text(units[i](l10n)))], onChanged: ...))`. Decoration flows from the global outlined `inputDecorationTheme`.
- **`_QuantityStepper`** (private `const StatelessWidget`): an `InputDecorator(isEmpty: false, decoration: InputDecoration(labelText: context.l10n.medsAddQuantityLabel), child: Row[ IconButton(key: ValueKey('medsAddQtyDecrement'), icon: Icon(LucideIcons.minus), onPressed: decrement), Expanded(child: Text(_formatQuantity(value), key: ValueKey('medsAddQtyValue'), textAlign: center)), Text(unitLabel), IconButton(key: ValueKey('medsAddQtyIncrement'), icon: Icon(LucideIcons.plus), onPressed: increment) ])`. Decrement clamps at `min` (`value - step` floored at `min`); increment adds `step`; both via parent `setState`. Tap targets stay ≥48dp (default `IconButton`).
- **`_StockCard`** (private `const StatelessWidget`): a `Container(decoration: BoxDecoration(color: colorScheme.surfaceContainerLow, border: Border.all(color: colorScheme.outlineVariant), borderRadius: BorderRadius.circular(16)))` containing a header `Row` (a stock/package icon in `colorScheme.secondary` + `Text(context.l10n.medsAddStockTitle)`), a note `Text(context.l10n.medsAddStockNote, style: bodySmall onSurfaceVariant)`, a `Row` of two `Expanded` `TextField`s (`key: ValueKey('medsAddStockRemaining')` labelled `medsAddStockRemainingLabel`; `key: ValueKey('medsAddStockTotal')` labelled `medsAddStockTotalLabel`), and a full-width `TextField` (`key: ValueKey('medsAddStockWarn')` labelled `medsAddStockWarnLabel`, with a trailing warning-triangle `suffixIcon`). All three use a numeric keyboard and start empty.
- **Icons**: stepper uses `LucideIcons.minus`/`LucideIcons.plus` (verify they compile). Stock header + warning-triangle: verify Lucide names (e.g. `LucideIcons.package`/`LucideIcons.packageOpen`, `LucideIcons.triangleAlert`/`LucideIcons.alertTriangle`); use a Material `Icons.*` fallback only where a name does not compile (spec §7 / 026–027 gotcha).
- **Dartdoc**: update the library + `AddMedicationModal` dartdoc to describe the form-dependent fields; add `///` to `_DoseField`/`_QuantityStepper`/`_StockCard` noting they are visual-only iteration 3 (spec 028), values are local and intentionally not persisted/consumed, Save remains a no-op.
- **No** `package:flutter_riverpod` import, **no** `ConsumerStatefulWidget`, **no** `drift`/domain/data imports, **no** hardcoded color literals (all via `Theme.of(context).colorScheme`), **no** `!` null-assertion.

## Contracts

### Expects
- `lib/l10n/app_localizations.dart` declares the 14 getters from Task 001 (`medsAddDoseLabel`, `medsAddDoseUnitLabel`, `medsAddQuantityLabel`, `medsAddStockTitle`, `medsAddStockNote`, `medsAddStockRemainingLabel`, `medsAddStockTotalLabel`, `medsAddStockWarnLabel`, `medsAddUnitMl`, `medsAddUnitMg`, `medsAddUnitUnits`, `medsAddUnitDrops`, `medsAddUnitTablet`, `medsAddUnitCapsule`).
- `add_medication_modal.dart` declares `class _MedicationFormPicker extends StatefulWidget`, `class _MedFormOption`, an 8-entry `_medFormOptions`, and `_AddMedicationModalState.build` mounting the picker between the name `TextField` and the Save `FilledButton.icon` (spec 027).

### Produces
- `_MedicationFormPicker` declares `final ValueChanged<_MedFormOption> onFormSelected;` and invokes `onFormSelected(` in the option `onTap`.
- `_MedFormOption` declares the fields `hasDose`, `hasQuantity`, `hasStock`, `doseUnits`, `quantityStep`, `quantityMin`, `quantityUnit`.
- `add_medication_modal.dart` declares `class _DoseField`, `class _QuantityStepper`, and `class _StockCard`.
- `_AddMedicationModalState` declares `_selectedForm`, `_quantity`, `_doseController`, `_stockRemainingController`, `_stockTotalController`, `_stockWarnController`, `_resetConditionalFields`, and `_formatQuantity`; `dispose()` disposes all four new controllers plus `_nameController`.
- The build inserts `_DoseField`/`_QuantityStepper`/`_StockCard` gated on `_selectedForm?.hasDose`/`hasQuantity`/`hasStock`, between the picker and the Save button.
- Test-target keys exist: `ValueKey('medsAddQtyValue')`, `ValueKey('medsAddQtyDecrement')`, `ValueKey('medsAddQtyIncrement')`, `ValueKey('medsAddDoseField')`, `ValueKey('medsAddDoseUnit')`, `ValueKey('medsAddStockRemaining')`, `ValueKey('medsAddStockTotal')`, `ValueKey('medsAddStockWarn')`.
- The file contains no `ConsumerStatefulWidget`, no `flutter_riverpod` import, and no `!` null-assertion; no `lib/features/meds/domain/` or `.../data/` file is created; `pubspec.yaml` is unchanged.

## Done when
- [x] With no form selected, none of `_DoseField`/`_QuantityStepper`/`_StockCard` are built (exactly one `TextField` — the name field — and one `FilledButton` exist). _(gated on `_selectedForm?.hasX ?? false`; spec-026 single-TextField test still passes)_
- [x] Selecting Tablet/Capsule shows the stepper (correct min 0.5/1, step 0.5/1, value formatted without trailing `.0`, minus clamped at min) and the stock card, no dose field. _(config on `_MedFormOption`; fully test-proven in Task 003)_
- [x] Selecting Injection/Syrup/Drops shows the dose field + unit dropdown with that form's localized units (first selected by default), no stepper/stock.
- [x] Selecting Inhaler/Cream/Sachet shows none of the conditional fields.
- [x] Switching forms resets the block (qty→new min, dose/stock cleared, unit index→0). _(`_resetConditionalFields` in `_onFormSelected`)_
- [x] All new strings via `context.l10n`; all colors via `Theme.of(context).colorScheme`; no `!`, no Riverpod, no domain/data, no `pubspec.yaml` change; the four new controllers are disposed.
- [x] The name `TextField` and the Save `FilledButton` (no-op) are unchanged.
- [x] `dart analyze` passes on the changed file (zero issues; no lint-suppression comments).
- [x] `flutter build apk --debug` succeeds.

## Spec criteria addressed
AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8, AC-10, AC-11, AC-15

## Completion Notes
**Status**: Complete
**Completed**: 2026-06-14
**Files changed**: lib/features/meds/presentation/widgets/add_medication_modal.dart
**Contract**: Expects [2/2 verified] | Produces [7/7 verified] — `onFormSelected` callback declared+invoked; `_MedFormOption` gained hasDose/hasQuantity/hasStock/doseUnits/quantityStep/quantityMin/quantityUnit; `_DoseField`/`_QuantityStepper`/`_StockCard` declared; parent state + 4 controllers disposed; gated insertion; 8 ValueKeys present; no `!`/Riverpod/domain-data; pubspec unchanged
**Verification**: dart analyze "No issues found!"; flutter test 299 pass (spec-026/027 preserved); flutter build apk --debug succeeded
**Code review**: APPROVE WITH WARNINGS — W1: `DropdownButtonFormField(initialValue:)` works on Flutter 3.41.4 (verified) but relies on `didUpdateWidget`; `DropdownButton(value:)` more idiomatic (no `Form` here) — defer to data-save iteration. W2: `?.` inside `if (selectedForm?.hasX ?? false)` blocks is required (Dart won't promote through `?.`) — not a defect. W3: `_quantity=0` initial is harmless dead state (reset sets min before the stepper ever renders).
**Notes**: All Lucide names compile — `minus`/`plus`/`packageOpen` (stock header)/`triangleAlert` (warn suffix); no Material fallback needed. Used `DropdownButtonFormField(initialValue:)` (not deprecated `value:`). Hoist done via callback (picker keeps `_selectedIndex`/`_isOpen`), so spec-027 tests untouched. 521 lines added (3 widgets + config + state).
