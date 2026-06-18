/// Meds feature — full-screen modal for the Add-medication flow (iteration 7).
///
/// This library hosts [AddMedicationModal], a full-screen modal route
/// pushed when the user taps the Add-medication FAB on the Meds screen.
/// The body renders three visual groups separated by two full-bleed section
/// dividers ([_sectionDivider]):
///
/// * **Group A** — medication name, form picker, and form-dependent fields
///   ([_DoseField], [_QuantityStepper], [_StockCard] — spec 028, iteration 3).
/// * **Group B** — intake-time section title + [_TimeChips] (spec 029,
///   iteration 4).
/// * **Group C** — intake-type title + [SegmentedButton], optional
///   [_CourseCard] (spec 030, iteration 5), and Save button.
///
/// **Persistence iteration 7 (spec 032)**: [AddMedicationModal] is now a
/// [ConsumerStatefulWidget]. The Save button invokes [AddMedication] via
/// [addMedicationProvider], maps form state to typed domain inputs, and
/// handles both the success (pop + SnackBar) and failure (field-mapped SnackBar,
/// stays open) branches. The button is disabled while a save is in flight.
library;

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/error/failures.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/entities/dosage.dart';
import 'medication_form_icon.dart';
import '../../domain/entities/dose_unit.dart';
import '../../domain/entities/medication_form.dart';
import '../../domain/entities/medication_type.dart';
import '../../domain/entities/pack_stock.dart';
import '../providers/medication_providers.dart';

// ---------------------------------------------------------------------------
// Presentation-only constants
// ---------------------------------------------------------------------------

/// Default [TimeOfDay] used to pre-fill the picker when adding the first time.
///
/// Fixed at 08:00 to match the HTML design seed values.  Must NOT be
/// [TimeOfDay.now()] — a fixed constant ensures deterministic widget tests.
const _defaultPickerTime = TimeOfDay(hour: 8, minute: 0);

// ---------------------------------------------------------------------------
// Presentation-only intake-type enum
// ---------------------------------------------------------------------------

/// Describes whether a medication is taken on a continuous (indefinite) basis
/// or as a bounded course with a defined duration, pause, and start date.
///
/// Selection is stored in [_AddMedicationModalState._intakeType] and read by
/// [_AddMedicationModalState._onSave] to determine the persisted
/// [MedicationType] (spec 030 / 032, iterations 5 and 7).
enum _IntakeType {
  /// Medication is taken continuously with no end date.
  continuous,

  /// Medication is taken as a timed course with duration, pause, and start date.
  course,
}

// ---------------------------------------------------------------------------
// Presentation-only form options data
// ---------------------------------------------------------------------------

/// An immutable descriptor for a single medication-form option displayed in
/// [_MedicationFormPicker].
///
/// Spec 027 / 028, iterations 2–3: instances are static configuration — they
/// are not written to storage, but their capability flags ([hasDose],
/// [hasQuantity], [hasStock], [doseUnitValues]) are read by
/// [_AddMedicationModalState._onSave] to build typed domain inputs.
/// The [key] string matches the planned domain enum name so future wiring
/// is a straightforward search-and-replace.
@immutable
class _MedFormOption {
  const _MedFormOption({
    required this.key,
    required this.icon,
    required this.name,
    required this.sub,
    this.hasDose = false,
    this.hasQuantity = false,
    this.hasStock = false,
    this.doseUnits = const [],
    this.doseUnitValues = const [],
    this.quantityStep = 1,
    this.quantityMin = 1,
    this.quantityUnit,
  });

  /// Stable identifier that matches the planned domain enum name.
  final String key;

  /// Icon representing this medication form.
  final IconData icon;

  /// Localized display name.
  final String Function(AppLocalizations l10n) name;

  /// Localized sub-description (e.g. route of administration).
  final String Function(AppLocalizations l10n) sub;

  /// Whether this form shows the dose amount + unit fields.
  ///
  /// Drives conditional rendering (spec 028, iteration 3) and is read by
  /// [_AddMedicationModalState._onSave] to determine the [Dosage] branch.
  final bool hasDose;

  /// Whether this form shows the quantity-per-intake stepper.
  ///
  /// Drives conditional rendering (spec 028, iteration 3) and is read by
  /// [_AddMedicationModalState._onSave] to determine the [Dosage] branch.
  final bool hasQuantity;

  /// Whether this form shows the pack-stock card.
  ///
  /// Drives conditional rendering (spec 028, iteration 3) and is read by
  /// [_AddMedicationModalState._onSave] to determine the [PackStock] value.
  final bool hasStock;

  /// Ordered list of localized dose-unit label builders for this form.
  ///
  /// Only meaningful when [hasDose] is `true`.
  /// Read by [_AddMedicationModalState._onSave] alongside [doseUnitValues]
  /// to build the [Dosage] unit label (spec 028, iteration 3).
  final List<String Function(AppLocalizations l10n)> doseUnits;

  /// Typed [DoseUnit] values parallel to [doseUnits], aligned index-for-index.
  ///
  /// Used by [_AddMedicationModalState._onSave] to resolve the selected unit
  /// to a domain [DoseUnit] without string-based lookup. Only meaningful when
  /// [hasDose] is `true`; defaults to an empty list for forms that do not use
  /// a dose text field. For [hasQuantity] forms (tablet/capsule) the unit is
  /// inferred from the form key instead.
  final List<DoseUnit> doseUnitValues;

  /// The increment / decrement step for the quantity stepper.
  ///
  /// Only meaningful when [hasQuantity] is `true`.
  /// Read by [_AddMedicationModalState._incrementQuantity] and
  /// [_AddMedicationModalState._decrementQuantity] (spec 028, iteration 3).
  final double quantityStep;

  /// The minimum allowed value for the quantity stepper (also the reset value).
  ///
  /// Only meaningful when [hasQuantity] is `true`.
  /// Read by [_AddMedicationModalState._resetConditionalFields] and
  /// [_AddMedicationModalState._decrementQuantity] (spec 028, iteration 3).
  final double quantityMin;

  /// Localized unit label builder for the quantity stepper (e.g. "tab", "cap").
  ///
  /// `null` when [hasQuantity] is `false`.
  /// Used in [_AddMedicationModalState.build] to label the stepper
  /// (spec 028, iteration 3).
  final String Function(AppLocalizations l10n)? quantityUnit;
}

/// The 8 medication-form options shown in [_MedicationFormPicker], in the
/// grid order: tablet, capsule, syrup, drops, injection, inhaler, cream, sachet.
///
/// Static configuration (spec 027 / 028, iterations 2–3) — the list itself
/// is not written to storage, but entries are consulted by
/// [_AddMedicationModalState._onSave] via the selected [_MedFormOption].
// Cannot be `const`: items hold `String Function(AppLocalizations)` closures.
final List<_MedFormOption> _medFormOptions = [
  _MedFormOption(
    key: 'tablet',
    icon: medicationFormIcon(MedicationForm.tablet),
    name: (l10n) => l10n.medsAddFormTablet,
    sub: (l10n) => l10n.medsAddFormTabletSub,
    hasQuantity: true,
    hasStock: true,
    quantityStep: 0.5,
    quantityMin: 0.5,
    quantityUnit: (l10n) => l10n.medsAddUnitTablet,
  ),
  _MedFormOption(
    key: 'capsule',
    icon: medicationFormIcon(MedicationForm.capsule),
    name: (l10n) => l10n.medsAddFormCapsule,
    sub: (l10n) => l10n.medsAddFormCapsuleSub,
    hasQuantity: true,
    hasStock: true,
    quantityStep: 1,
    quantityMin: 1,
    quantityUnit: (l10n) => l10n.medsAddUnitCapsule,
  ),
  _MedFormOption(
    key: 'syrup',
    icon: medicationFormIcon(MedicationForm.syrup),
    name: (l10n) => l10n.medsAddFormSyrup,
    sub: (l10n) => l10n.medsAddFormSyrupSub,
    hasDose: true,
    doseUnits: [(l10n) => l10n.medsAddUnitMl],
    doseUnitValues: const [DoseUnit.ml],
  ),
  _MedFormOption(
    key: 'drops',
    icon: medicationFormIcon(MedicationForm.drops),
    name: (l10n) => l10n.medsAddFormDrops,
    sub: (l10n) => l10n.medsAddFormDropsSub,
    hasDose: true,
    doseUnits: [(l10n) => l10n.medsAddUnitDrops, (l10n) => l10n.medsAddUnitMl],
    doseUnitValues: const [DoseUnit.drops, DoseUnit.ml],
  ),
  _MedFormOption(
    key: 'injection',
    icon: medicationFormIcon(MedicationForm.injection),
    name: (l10n) => l10n.medsAddFormInjection,
    sub: (l10n) => l10n.medsAddFormInjectionSub,
    hasDose: true,
    doseUnits: [
      (l10n) => l10n.medsAddUnitMl,
      (l10n) => l10n.medsAddUnitMg,
      (l10n) => l10n.medsAddUnitUnits,
    ],
    doseUnitValues: const [DoseUnit.ml, DoseUnit.mg, DoseUnit.units],
  ),
  _MedFormOption(
    key: 'inhaler',
    icon: medicationFormIcon(MedicationForm.inhaler),
    name: (l10n) => l10n.medsAddFormInhaler,
    sub: (l10n) => l10n.medsAddFormInhalerSub,
  ),
  _MedFormOption(
    key: 'cream',
    icon: medicationFormIcon(MedicationForm.cream),
    name: (l10n) => l10n.medsAddFormCream,
    sub: (l10n) => l10n.medsAddFormCreamSub,
  ),
  _MedFormOption(
    key: 'sachet',
    icon: medicationFormIcon(MedicationForm.sachet),
    name: (l10n) => l10n.medsAddFormSachet,
    sub: (l10n) => l10n.medsAddFormSachetSub,
  ),
];

// ---------------------------------------------------------------------------
// _MedicationFormPicker widget
// ---------------------------------------------------------------------------

/// A self-contained medication-form picker.
///
/// Displays a tappable outlined display row (floating label, icon chip, name,
/// sub-description, animated chevron) that expands an animated grid of the
/// 8 options from [_medFormOptions].
///
/// Iteration 2 (spec 027-med-form-picker):
/// * Selection is stored in local [State] and hoisted to the parent via
///   [onFormSelected]; the parent persists it through [_onSave] (spec 032).
/// * [onFormSelected] is invoked whenever the user commits a selection so that
///   the parent can react (e.g. show form-dependent fields — spec 028).
///
/// No [AnimationController] is used — [AnimatedSize] and [AnimatedRotation]
/// are implicit animations that manage their own lifecycle.
class _MedicationFormPicker extends StatefulWidget {
  /// Creates a [_MedicationFormPicker].
  ///
  /// [onFormSelected] is called with the newly selected [_MedFormOption]
  /// every time the user picks an option from the grid.
  const _MedicationFormPicker({required this.onFormSelected});

  /// Callback invoked after the user taps an option chip.
  ///
  /// The parent uses this to conditionally render form-dependent fields
  /// (spec 028, iteration 3).  The picker keeps its own `_selectedIndex`
  /// and `_isOpen` state; this callback is purely additive.
  final ValueChanged<_MedFormOption> onFormSelected;

  @override
  State<_MedicationFormPicker> createState() => _MedicationFormPickerState();
}

class _MedicationFormPickerState extends State<_MedicationFormPicker> {
  /// Index into [_medFormOptions] for the currently selected form.
  /// `null` means no selection yet (shows placeholder text).
  int? _selectedIndex;

  /// Whether the option grid is currently visible.
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    // Resolve display content without null-assertion.
    final i = _selectedIndex;
    final selected = i == null ? null : _medFormOptions[i];
    final displayName = selected == null
        ? l10n.medsAddFormPlaceholder
        : selected.name(l10n);
    final displaySub = selected == null ? null : selected.sub(l10n);
    final displayIcon = selected?.icon ?? LucideIcons.shapes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ----------------------------------------------------------------
        // Display row — tappable, 1px outlined border per design .fpd-label.
        // ----------------------------------------------------------------
        InkWell(
          key: const ValueKey('medsFormPickerToggle'),
          borderRadius: BorderRadius.circular(4),
          onTap: () => setState(() => _isOpen = !_isOpen),
          child: Semantics(
            button: true,
            label: selected == null
                ? l10n.medsAddFormPlaceholder
                : selected.name(l10n),
            child: InputDecorator(
            // isEmpty:false keeps the label permanently floated so that
            // the outlined border always shows with the label cut-out.
            isEmpty: false,
            decoration: InputDecoration(
              labelText: l10n.medsAddFormLabel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: colorScheme.outline,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: colorScheme.outline,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Icon chip — 32×32, secondaryContainer background.
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    displayIcon,
                    color: colorScheme.onSecondaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Name + optional sub-description.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(displayName, style: textTheme.bodyLarge),
                      if (displaySub != null)
                        Text(
                          displaySub,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                // Rotating chevron: 0.5 turns = 180° when open.
                AnimatedRotation(
                  turns: _isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 280),
                  child: Icon(
                    LucideIcons.chevronDown,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          ),
        ),

        // ----------------------------------------------------------------
        // Expanding grid — conditionally built (not merely hidden) so that
        // option widgets are absent from the tree when collapsed.
        // ----------------------------------------------------------------
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _isOpen ? _buildGrid(context) : const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// Builds the expanded options grid card.
  Widget _buildGrid(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    // Build rows of 2 chips each from the flat list.
    final rows = <Widget>[];
    for (var r = 0; r < _medFormOptions.length; r += 2) {
      if (r > 0) rows.add(const SizedBox(height: 7));
      final left = _medFormOptions[r];
      final right = (r + 1 < _medFormOptions.length)
          ? _medFormOptions[r + 1]
          : null;
      rows.add(
        Row(
          children: [
            Expanded(child: _buildChip(context, left, r)),
            const SizedBox(width: 7),
            Expanded(
              child: right != null
                  ? _buildChip(context, right, r + 1)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.medsAddFormGridTitle.toUpperCase(),
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: .3,
            ),
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  /// Builds a single option chip for [option] at [index].
  Widget _buildChip(BuildContext context, _MedFormOption option, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = index == _selectedIndex;

    return InkWell(
      key: ValueKey('medsForm_${option.key}'),
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          _selectedIndex = index;
          _isOpen = false;
        });
        widget.onFormSelected(_medFormOptions[index]);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              option.icon,
              size: 22,
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                option.name(context.l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelLarge?.copyWith(
                  fontSize: 13,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _DoseField widget
// ---------------------------------------------------------------------------

/// A row with a dose amount [TextField] and a unit [DropdownButtonFormField].
///
/// Iteration 3 (spec 028) — the [controller] value and [selectedUnitIndex]
/// are owned by [_AddMedicationModalState] and read by [_onSave] to build
/// the persisted [Dosage] (spec 032).
class _DoseField extends StatelessWidget {
  /// Creates a [_DoseField].
  const _DoseField({
    required this.controller,
    required this.units,
    required this.selectedUnitIndex,
    required this.onUnitChanged,
  });

  /// Controller for the dose amount text input.
  final TextEditingController controller;

  /// Ordered list of localized unit label builders for the dropdown.
  final List<String Function(AppLocalizations l10n)> units;

  /// Currently selected index in [units].
  final int selectedUnitIndex;

  /// Callback invoked when the user picks a different unit.
  final ValueChanged<int?> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            key: const ValueKey('medsAddDoseField'),
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.medsAddDoseLabel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<int>(
            key: const ValueKey('medsAddDoseUnit'),
            initialValue: selectedUnitIndex,
            decoration: InputDecoration(labelText: l10n.medsAddDoseUnitLabel),
            items: [
              for (var i = 0; i < units.length; i++)
                DropdownMenuItem<int>(value: i, child: Text(units[i](l10n))),
            ],
            onChanged: onUnitChanged,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _QuantityStepper widget
// ---------------------------------------------------------------------------

/// A quantity-per-intake stepper rendered inside an [InputDecorator] so it
/// matches the form's outlined field style.
///
/// Iteration 3 (spec 028) — [formattedValue], [onIncrement], and [onDecrement]
/// are driven by [_AddMedicationModalState._quantity], which is read by
/// [_onSave] to build the persisted [Dosage] (spec 032).
class _QuantityStepper extends StatelessWidget {
  /// Creates a [_QuantityStepper].
  const _QuantityStepper({
    required this.formattedValue,
    required this.unitLabel,
    required this.onIncrement,
    required this.onDecrement,
  });

  /// The quantity value already formatted (no trailing ".0" for whole numbers).
  final String formattedValue;

  /// Localized unit label displayed next to the value (e.g. "tab", "cap").
  final String unitLabel;

  /// Called when the user taps the increment (+) button.
  final VoidCallback onIncrement;

  /// Called when the user taps the decrement (−) button.
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecorator(
      isEmpty: false,
      decoration: InputDecoration(
        labelText: context.l10n.medsAddQuantityLabel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: colorScheme.outline,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: colorScheme.outline,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 56,
            child: IconButton(
              key: const ValueKey('medsAddQtyDecrement'),
              icon: const Icon(LucideIcons.minus),
              iconSize: 20,
              color: colorScheme.onSurface,
              onPressed: onDecrement,
            ),
          ),
          Expanded(
            child: Text(
              formattedValue,
              key: const ValueKey('medsAddQtyValue'),
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              unitLabel,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(
            height: 56,
            child: IconButton(
              key: const ValueKey('medsAddQtyIncrement'),
              icon: const Icon(LucideIcons.plus),
              iconSize: 20,
              color: colorScheme.onSurface,
              onPressed: onIncrement,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _StockCard widget
// ---------------------------------------------------------------------------

/// A pack-stock card with remaining, total, and warn fields.
///
/// Iteration 3 (spec 028) — the three [TextEditingController]s are owned by
/// [_AddMedicationModalState] and read by [_onSave] to build the persisted
/// [PackStock] (spec 032).
class _StockCard extends StatelessWidget {
  /// Creates a [_StockCard].
  const _StockCard({
    required this.remainingController,
    required this.totalController,
    required this.warnController,
  });

  /// Controller for the "remaining in pack" text field.
  final TextEditingController remainingController;

  /// Controller for the "total in pack" text field.
  final TextEditingController totalController;

  /// Controller for the "warn when remaining reaches" text field.
  final TextEditingController warnController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row: icon + title.
          Row(
            children: [
              Icon(LucideIcons.packageOpen, color: colorScheme.secondary),
              const SizedBox(width: 8),
              Text(l10n.medsAddStockTitle, style: textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.medsAddStockNote,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          // Remaining + Total row.
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('medsAddStockRemaining'),
                  controller: remainingController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.medsAddStockRemainingLabel,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  key: const ValueKey('medsAddStockTotal'),
                  controller: totalController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.medsAddStockTotalLabel,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Low-stock warning threshold field.
          TextField(
            key: const ValueKey('medsAddStockWarn'),
            controller: warnController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.medsAddStockWarnLabel,
              suffixIcon: const Icon(LucideIcons.triangleAlert),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _TimeChips widget
// ---------------------------------------------------------------------------

/// A presentation-only wrapping row of intake-time chips with a trailing
/// add-chip.
///
/// Renders one [InputChip] per entry in [times] (leading clock icon, 24-hour
/// `HH:MM` label, × delete affordance, body tap → edit) followed by a single
/// [ActionChip] (dashed solid outline, leading + icon) that calls [onAdd] to
/// open the time picker.
///
/// Iteration 4 (spec 029): [times] is driven by
/// [_AddMedicationModalState._intakeTimes] and read by [_onSave] to persist
/// intake schedule (spec 032).
class _TimeChips extends StatelessWidget {
  /// Creates a [_TimeChips] widget.
  const _TimeChips({
    required this.times,
    required this.onEdit,
    required this.onRemove,
    required this.onAdd,
  });

  /// The ordered list of [TimeOfDay] values to render as chips.
  final List<TimeOfDay> times;

  /// Called with the chip index when the user taps a chip body to edit it.
  final void Function(int index) onEdit;

  /// Called with the chip index when the user taps the × affordance to remove.
  final void Function(int index) onRemove;

  /// Called when the user taps the trailing add chip.
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = MaterialLocalizations.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // One InputChip per selected time.
        for (var i = 0; i < times.length; i++)
          InputChip(
            avatar: Icon(
              LucideIcons.clock,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            label: Text(
              localizations.formatTimeOfDay(
                times[i],
                alwaysUse24HourFormat: true,
              ),
            ),
            onPressed: () => onEdit(i),
            onDeleted: () => onRemove(i),
            deleteIcon: const Icon(LucideIcons.x, size: 14),
            deleteButtonTooltipMessage: context.l10n.medsAddTimeRemoveTooltip,
          ),

        // Trailing add chip — solid outline approximates the dashed HTML design.
        ActionChip(
          avatar: Icon(LucideIcons.plus, size: 18, color: colorScheme.primary),
          label: Text(context.l10n.medsAddTimeAddChip),
          labelStyle: TextStyle(color: colorScheme.primary),
          side: BorderSide(color: colorScheme.outline),
          backgroundColor: Colors.transparent,
          onPressed: onAdd,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _CourseCard widget
// ---------------------------------------------------------------------------

/// A card displaying course-parameter fields: duration, pause, start date
/// (with a [showDatePicker] tap target), and a live-computed info chip showing
/// the inclusive date range.
///
/// Iteration 5 (spec 030) — all controllers and [startDate] are owned by
/// [_AddMedicationModalState] and read by [_onSave] to build the persisted
/// [MedicationType.course] value (spec 032).
class _CourseCard extends StatelessWidget {
  /// Creates a [_CourseCard].
  const _CourseCard({
    required this.durationController,
    required this.pauseController,
    required this.startDate,
    required this.onPickStart,
    required this.onDurationChanged,
    required this.infoLabel,
  });

  /// Controller for the course-duration field (number of days).
  final TextEditingController durationController;

  /// Controller for the pause-between-courses field (number of days).
  final TextEditingController pauseController;

  /// The currently selected course start date.
  final DateTime startDate;

  /// Called when the user taps the start-date field to open [showDatePicker].
  final VoidCallback onPickStart;

  /// Called when the user changes the duration field text (drives info-chip recompute).
  final ValueChanged<String> onDurationChanged;

  /// Pre-computed localized label for the info chip (inclusive date range or start-only).
  final String infoLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row: icon + title.
          Row(
            children: [
              Icon(LucideIcons.repeat, color: colorScheme.tertiary),
              const SizedBox(width: 8),
              Text(l10n.medsAddCourseParamsTitle, style: textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 14),
          // Duration + Pause fields side by side.
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('medsAddCourseDuration'),
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.medsAddCourseDurationLabel,
                  ),
                  onChanged: onDurationChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  key: const ValueKey('medsAddCoursePause'),
                  controller: pauseController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.medsAddCoursePauseLabel,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Start-date tap target styled like an outlined input field.
          InkWell(
            key: const ValueKey('medsAddCourseStartField'),
            borderRadius: BorderRadius.circular(4),
            onTap: onPickStart,
            child: InputDecorator(
              isEmpty: false,
              decoration: InputDecoration(
                labelText: l10n.medsAddCourseStartLabel,
                suffixIcon: const Icon(LucideIcons.calendarDays),
              ),
              child: Text(
                MaterialLocalizations.of(context).formatMediumDate(startDate),
                style: textTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Info chip — tertiaryContainer background, inclusive range text.
          Container(
            key: const ValueKey('medsAddCourseInfoChip'),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  LucideIcons.info,
                  size: 18,
                  color: colorScheme.onTertiaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    infoLabel,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AddMedicationModal
// ---------------------------------------------------------------------------

/// Full-screen modal shown when the user taps the Add-medication FAB on the
/// Meds screen.
///
/// Renders a [Scaffold] with:
/// * an [AppBar] (back-arrow leading + localized title via
///   [AppLocalizationsContext.l10n]),
/// * a padded [Column] containing:
///   - a medication-name [TextField] (spec 026),
///   - a medication-form picker [_MedicationFormPicker] (spec 027,
///     iteration 2),
///   - form-dependent fields (spec 028, iteration 3):
///     * [_DoseField] for injection / syrup / drops,
///     * [_QuantityStepper] for tablet / capsule,
///     * [_StockCard] for tablet / capsule,
///   - an intake-time chips section [_TimeChips] (spec 029, iteration 4),
///   - a full-width [FilledButton.icon] Save button that invokes
///     [addMedicationProvider] on tap (spec 032, iteration 7).
///
/// **Persistence iteration 7 (spec 032)**: [AddMedicationModal] extends
/// [ConsumerStatefulWidget]. Save maps local form state to typed domain
/// inputs, calls [AddMedication] via [addMedicationProvider], shows a
/// success SnackBar and pops on the Right branch, or shows a field-mapped
/// error SnackBar and stays open on the Left branch. The Save button is
/// disabled while saving is in flight.
///
/// The modal is pushed via `Navigator.push(MaterialPageRoute(
/// fullscreenDialog: true, ...))` from `meds_screen.dart`.
class AddMedicationModal extends ConsumerStatefulWidget {
  /// Creates the Add-medication modal.
  const AddMedicationModal({super.key});

  @override
  ConsumerState<AddMedicationModal> createState() =>
      _AddMedicationModalState();
}

class _AddMedicationModalState extends ConsumerState<AddMedicationModal> {
  // -------------------------------------------------------------------------
  // Controllers
  // -------------------------------------------------------------------------

  /// Controller for the medication-name text field (spec 026).
  final TextEditingController _nameController = TextEditingController();

  /// Controller for the dose amount text field (liquid forms — spec 028).
  /// Read by [_onSave] and persisted via [addMedicationProvider].
  final TextEditingController _doseController = TextEditingController();

  /// Controller for the "remaining in pack" field in the stock card (spec 028).
  /// Read by [_onSave] and persisted via [addMedicationProvider].
  final TextEditingController _stockRemainingController =
      TextEditingController();

  /// Controller for the "total in pack" field in the stock card (spec 028).
  /// Read by [_onSave] and persisted via [addMedicationProvider].
  final TextEditingController _stockTotalController = TextEditingController();

  /// Controller for the low-stock warning threshold field (spec 028).
  /// Read by [_onSave] and persisted via [addMedicationProvider].
  final TextEditingController _stockWarnController = TextEditingController();

  // -------------------------------------------------------------------------
  // Form-dependent state (spec 028)
  // -------------------------------------------------------------------------

  /// The medication form currently selected by the user, or `null` if none.
  ///
  /// Drives conditional rendering of [_DoseField], [_QuantityStepper], and
  /// [_StockCard].  Read by [_onSave] and persisted via [addMedicationProvider].
  _MedFormOption? _selectedForm;

  /// Current quantity-per-intake value for the stepper.
  ///
  /// Reset to [_MedFormOption.quantityMin] on form change.
  /// Read by [_onSave] and persisted via [addMedicationProvider].
  double _quantity = 0;

  /// Currently selected index in the dose-unit dropdown.
  ///
  /// Reset to 0 on form change.
  /// Read by [_onSave] and persisted via [addMedicationProvider].
  int _selectedDoseUnitIndex = 0;

  // -------------------------------------------------------------------------
  // Intake-time state (spec 029)
  // -------------------------------------------------------------------------

  /// Sorted list of intake times selected by the user.
  ///
  /// Always kept in ascending order by time-of-day (hour × 60 + minute).
  /// Duplicates are rejected before insertion.
  /// Read by [_onSave] and persisted via [addMedicationProvider].
  final List<TimeOfDay> _intakeTimes = [];

  // -------------------------------------------------------------------------
  // Intake-type state (spec 030)
  // -------------------------------------------------------------------------

  /// Whether the user has selected Continuous or Course intake.
  ///
  /// Drives [SegmentedButton] selection and conditional [_CourseCard]
  /// visibility.  Read by [_onSave] and persisted via [addMedicationProvider].
  _IntakeType _intakeType = _IntakeType.continuous;

  /// Controller for the course-duration field (days).  Pre-filled with "7".
  ///
  /// Read by [_onSave] and persisted via [addMedicationProvider].
  final TextEditingController _durationController =
      TextEditingController(text: '7');

  /// Controller for the pause-between-courses field (days).  Pre-filled
  /// with "0".
  ///
  /// Read by [_onSave] and persisted via [addMedicationProvider].
  final TextEditingController _pauseController =
      TextEditingController(text: '0');

  /// The currently selected course start date, normalised to midnight.
  ///
  /// Defaults to today via [clock.now()] (not [DateTime.now()]) so tests
  /// can override the clock.  Normalised with [DateUtils.dateOnly] to strip
  /// the time component.
  DateTime _startDate = DateUtils.dateOnly(clock.now());

  // -------------------------------------------------------------------------
  // Save-in-flight state (spec 032, iteration 7)
  // -------------------------------------------------------------------------

  /// Whether a save call is currently in flight.
  ///
  /// While `true` the Save button is disabled to prevent double-taps.
  bool _isSaving = false;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _stockRemainingController.dispose();
    _stockTotalController.dispose();
    _stockWarnController.dispose();
    _durationController.dispose();
    _pauseController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Form-selection logic
  // -------------------------------------------------------------------------

  /// Called by [_MedicationFormPicker] when the user selects a form.
  ///
  /// Resets conditional fields when the form key changes, then updates
  /// [_selectedForm].
  void _onFormSelected(_MedFormOption form) {
    setState(() {
      if (form.key != _selectedForm?.key) {
        _resetConditionalFields(form);
      }
      _selectedForm = form;
    });
  }

  /// Clears all conditional field controllers and resets stepper state to
  /// the defaults for [form].
  ///
  /// Called inside a [setState] block by [_onFormSelected].
  void _resetConditionalFields(_MedFormOption form) {
    _doseController.clear();
    _stockRemainingController.clear();
    _stockTotalController.clear();
    _stockWarnController.clear();
    _selectedDoseUnitIndex = 0;
    _quantity = form.hasQuantity ? form.quantityMin : 0;
  }

  // -------------------------------------------------------------------------
  // Quantity stepper logic
  // -------------------------------------------------------------------------

  /// Formats [v] without a trailing ".0" for whole-number values.
  ///
  /// Examples: `1.0 → "1"`, `1.5 → "1.5"`.
  String _formatQuantity(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toString();

  /// Increments [_quantity] by [_MedFormOption.quantityStep].
  void _incrementQuantity() {
    final step = _selectedForm?.quantityStep ?? 1;
    setState(() {
      _quantity += step;
    });
  }

  /// Decrements [_quantity] by [_MedFormOption.quantityStep], clamped at
  /// [_MedFormOption.quantityMin].
  void _decrementQuantity() {
    final step = _selectedForm?.quantityStep ?? 1;
    final min = _selectedForm?.quantityMin ?? 1;
    setState(() {
      _quantity = (_quantity - step).clamp(min, double.infinity);
    });
  }

  // -------------------------------------------------------------------------
  // Intake-time logic (spec 029)
  // -------------------------------------------------------------------------

  /// Opens Flutter's built-in [showTimePicker] dialog pre-filled at [initial].
  ///
  /// Forces 24-hour display via a [MediaQuery] wrapper regardless of the device
  /// locale setting, as required by spec 029 AC-10.
  /// Returns `null` if the user cancels.
  Future<TimeOfDay?> _pickTime(TimeOfDay initial) {
    return showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }

  /// Opens the time picker to add a new intake time.
  ///
  /// Uses [_defaultPickerTime] as the default `initialTime`.  On confirm,
  /// delegates to [_commitTime]; on cancel, changes nothing.
  Future<void> _addTime() async {
    final picked = await _pickTime(_defaultPickerTime);
    if (picked == null) return;
    if (!mounted) return;
    _commitTime(picked, replacingIndex: null);
  }

  /// Opens the time picker to edit the chip at [index].
  ///
  /// Pre-fills the picker with the chip's current time.  If the user confirms
  /// the same value (silent no-op) or cancels (`null`), the list is unchanged.
  /// Otherwise delegates to [_commitTime] with [replacingIndex] set to [index].
  Future<void> _editTime(int index) async {
    final current = _intakeTimes[index];
    final picked = await _pickTime(current);
    if (picked == null) return;
    if (!mounted) return;
    // Silent no-op when the user confirms the chip's own existing value.
    if (picked.hour == current.hour && picked.minute == current.minute) return;
    _commitTime(picked, replacingIndex: index);
  }

  /// Removes the chip at [index] from [_intakeTimes] without opening the picker.
  void _removeTime(int index) {
    setState(() => _intakeTimes.removeAt(index));
  }

  /// Validates [time] for duplicates and, if accepted, inserts or replaces it.
  ///
  /// [replacingIndex]: when non-null, the slot being edited (excluded from the
  /// duplicate check so a chip is never flagged as a duplicate of itself).
  ///
  /// If a duplicate is found (another slot at a different index has the same
  /// minutes-key), a [SnackBar] is shown via [ScaffoldMessenger] and the list
  /// is left unchanged.
  ///
  /// This method touches `context` (via [ScaffoldMessenger]) and therefore
  /// self-guards with a `mounted` check as its first statement, making it safe
  /// to call directly after any `await` without an external guard.
  void _commitTime(TimeOfDay time, {required int? replacingIndex}) {
    if (!mounted) return;
    final minutesKey = time.hour * 60 + time.minute;

    // Duplicate check: scan every index except the one being replaced.
    for (var i = 0; i < _intakeTimes.length; i++) {
      if (i == replacingIndex) continue;
      final existing = _intakeTimes[i];
      if (existing.hour * 60 + existing.minute == minutesKey) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.medsAddTimeDuplicate)),
        );
        return;
      }
    }

    setState(() {
      if (replacingIndex != null) {
        _intakeTimes[replacingIndex] = time;
      } else {
        _intakeTimes.add(time);
      }
      // Keep chips in ascending chronological order.
      _intakeTimes.sort(
        (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
      );
    });
  }

  // -------------------------------------------------------------------------
  // Course date-picker logic (spec 030)
  // -------------------------------------------------------------------------

  /// Opens Flutter's built-in [showDatePicker] dialog pre-filled at
  /// [_startDate].
  ///
  /// Guards with `if (picked == null) return` and `if (!mounted) return`
  /// (in that order) before calling [setState], mirroring the idiom used in
  /// [_addTime] and [_editTime].  On confirm, normalises the result to
  /// midnight via [DateUtils.dateOnly].
  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(_startDate.year - 1),
      lastDate: DateTime(_startDate.year + 5),
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() => _startDate = DateUtils.dateOnly(picked));
  }

  /// Computes the localized info-chip label for the [_CourseCard].
  ///
  /// When [_durationController] contains a valid integer ≥ 1, returns a
  /// [AppLocalizations.medsAddCourseRangeLabel] string showing the inclusive
  /// date range.  Otherwise falls back to
  /// [AppLocalizations.medsAddCourseStartOnly] showing only the start date.
  String _courseInfoLabel(AppLocalizations l10n, MaterialLocalizations ml) {
    final n = int.tryParse(_durationController.text.trim());
    if (n != null && n >= 1) {
      final end = _startDate.add(Duration(days: n - 1));
      return l10n.medsAddCourseRangeLabel(
        '${ml.formatMediumDate(_startDate)} — ${ml.formatMediumDate(end)}',
        n,
      );
    }
    return l10n.medsAddCourseStartOnly(ml.formatMediumDate(_startDate));
  }

  // -------------------------------------------------------------------------
  // Save logic (spec 032, iteration 7)
  // -------------------------------------------------------------------------

  /// Maps the current form state to typed domain inputs and invokes
  /// [AddMedication] via [addMedicationProvider].
  ///
  /// On the [Right] branch shows a success [SnackBar] and pops the modal.
  /// On the [Left] branch shows a field-mapped error [SnackBar] and stays
  /// open so the user can correct the input.  The Save button is disabled
  /// for the duration of the async call via [_isSaving].
  ///
  /// Context objects ([ScaffoldMessenger], [Navigator], l10n) are captured
  /// before the `await` to satisfy `use_build_context_synchronously`.
  Future<void> _onSave() async {
    // Capture context-dependent objects before any await (and before the
    // null-form guard) to satisfy `use_build_context_synchronously`.
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final form = _selectedForm;
    if (form == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.medsAddSaveErrorGeneric)),
      );
      return;
    }

    // --- Resolve typed domain inputs ---

    final medForm = MedicationForm.values.byName(form.key);

    final intakeMinutes = [
      for (final t in _intakeTimes) t.hour * 60 + t.minute,
    ];

    // Dosage — varies by form capability.
    final Dosage? dose;
    if (form.hasQuantity) {
      // tablet or capsule: unit name matches the form key exactly.
      dose = Dosage(
        amount: _quantity,
        unit: DoseUnit.values.byName(form.key),
      );
    } else if (form.hasDose) {
      // liquid forms: use the typed unit parallel to the dropdown index.
      dose = Dosage(
        amount:
            double.tryParse(
              _doseController.text.trim().replaceAll(',', '.'),
            ) ??
            0,
        unit: form.doseUnitValues[_selectedDoseUnitIndex],
      );
    } else {
      // inhaler / cream / sachet: no dose field.
      dose = null;
    }

    // Pack stock — only for forms that show the stock card.
    final PackStock? stock;
    if (form.hasStock) {
      final remaining = int.tryParse(_stockRemainingController.text.trim());
      final total = int.tryParse(_stockTotalController.text.trim());
      final warn = int.tryParse(_stockWarnController.text.trim()) ?? 0;
      if (remaining != null &&
          total != null &&
          remaining >= 0 &&
          total >= 0) {
        stock = PackStock(remaining: remaining, total: total, warnAt: warn);
      } else {
        stock = null;
      }
    } else {
      stock = null;
    }

    // Medication type — continuous or course.
    final MedicationType type;
    if (_intakeType == _IntakeType.continuous) {
      final now = clock.now();
      type = MedicationType.continuous(
        startDate: DateTime.utc(now.year, now.month, now.day),
      );
    } else {
      type = MedicationType.course(
        startDate: DateTime.utc(
          _startDate.year,
          _startDate.month,
          _startDate.day,
        ),
        durationDays: int.tryParse(_durationController.text.trim()) ?? 0,
        pauseDays: int.tryParse(_pauseController.text.trim()) ?? 0,
      );
    }

    setState(() => _isSaving = true);

    final result = await ref.read(addMedicationProvider).call(
      name: _nameController.text,
      form: medForm,
      intakeMinutes: intakeMinutes,
      type: type,
      dosePerIntake: dose,
      stock: stock,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _isSaving = false);
        final msg = switch (failure) {
          ValidationFailure(:final field) => switch (field) {
            'name' => l10n.medsAddSaveErrorName,
            'times' => l10n.medsAddSaveErrorTimes,
            'durationDays' => l10n.medsAddSaveErrorDuration,
            'dose' => l10n.medsAddSaveErrorDose,
            _ => l10n.medsAddSaveErrorGeneric,
          },
          _ => l10n.medsAddSaveErrorGeneric,
        };
        messenger.showSnackBar(SnackBar(content: Text(msg)));
      },
      (_) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.medsAddSaveSuccess)),
        );
        navigator.pop();
      },
    );
  }

  // -------------------------------------------------------------------------
  // Section-divider helper
  // -------------------------------------------------------------------------

  /// Full-bleed section divider matching the template's `.s-div`
  /// (1px outlineVariant hairline, 4px above / 8px below, edge-to-edge).
  Widget _sectionDivider(ColorScheme colorScheme) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: Divider(
          height: 1,
          thickness: 1,
          color: colorScheme.outlineVariant,
        ),
      );

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final selectedForm = _selectedForm;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        title: Text(context.l10n.medsAddTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outlineVariant,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ------------------------------------------------------------------
            // Group A: name field, form picker, form-dependent fields.
            // ------------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameController,
                    // Outline/label styling comes from the global
                    // `inputDecorationTheme` (outlined, transparent) — no
                    // call-site border/color overrides.
                    decoration: InputDecoration(
                      labelText: context.l10n.medsAddNameLabel,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Medication-form picker (spec 027, iteration 2).
                  // Selection is hoisted to the parent via _onFormSelected
                  // for conditional field rendering and persistence in _onSave.
                  _MedicationFormPicker(onFormSelected: _onFormSelected),

                  // ----------------------------------------------------------------
                  // Form-dependent fields (spec 028, iteration 3).
                  // Each block is gated on the selected form's capability flags so
                  // that NO conditional widget appears in the tree when no form is
                  // selected (preserving the spec-026 test assertion).
                  // ----------------------------------------------------------------

                  // Dose field: injection, syrup, drops.
                  if (selectedForm?.hasDose ?? false) ...[
                    const SizedBox(height: 16),
                    _DoseField(
                      controller: _doseController,
                      units: selectedForm?.doseUnits ?? const [],
                      selectedUnitIndex: _selectedDoseUnitIndex,
                      onUnitChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedDoseUnitIndex = value);
                        }
                      },
                    ),
                  ],

                  // Quantity stepper: tablet, capsule.
                  if (selectedForm?.hasQuantity ?? false) ...[
                    const SizedBox(height: 16),
                    _QuantityStepper(
                      formattedValue: _formatQuantity(_quantity),
                      unitLabel:
                          selectedForm?.quantityUnit?.call(context.l10n) ?? '',
                      onIncrement: _incrementQuantity,
                      onDecrement: _decrementQuantity,
                    ),
                  ],

                  // Pack-stock card: tablet, capsule.
                  if (selectedForm?.hasStock ?? false) ...[
                    const SizedBox(height: 16),
                    _StockCard(
                      remainingController: _stockRemainingController,
                      totalController: _stockTotalController,
                      warnController: _stockWarnController,
                    ),
                  ],
                ],
              ),
            ),

            // DIVIDER A — full-bleed, direct child of outer Column.
            _sectionDivider(colorScheme),

            // ------------------------------------------------------------------
            // Group B: intake-time section title + time chips.
            // ------------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  // Intake-time section (spec 029, iteration 4).
                  Text(
                    context.l10n.medsAddTimeTitle,
                    style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _TimeChips(
                    times: _intakeTimes,
                    onEdit: _editTime,
                    onRemove: _removeTime,
                    onAdd: _addTime,
                  ),
                ],
              ),
            ),

            // DIVIDER B — full-bleed, direct child of outer Column.
            _sectionDivider(colorScheme),

            // ------------------------------------------------------------------
            // Group C: intake-type section title, segmented button, course card,
            //          Save button, and bottom spacer.
            // ------------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  // Intake-type section (spec 030, iteration 5).
                  Text(
                    context.l10n.medsAddIntakeTypeTitle,
                    style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<_IntakeType>(
                    key: const ValueKey('medsAddIntakeTypeSegmented'),
                    segments: <ButtonSegment<_IntakeType>>[
                      ButtonSegment<_IntakeType>(
                        value: _IntakeType.continuous,
                        label: Text(context.l10n.medsAddIntakeTypeContinuous),
                        icon: const Icon(LucideIcons.infinity),
                      ),
                      ButtonSegment<_IntakeType>(
                        value: _IntakeType.course,
                        label: Text(context.l10n.medsAddIntakeTypeCourse),
                        icon: const Icon(LucideIcons.repeat),
                      ),
                    ],
                    selected: <_IntakeType>{_intakeType},
                    onSelectionChanged: (Set<_IntakeType> selection) {
                      if (selection.isEmpty) return;
                      setState(() => _intakeType = selection.first);
                    },
                  ),

                  // Course-parameters card — visible only when Course is selected.
                  if (_intakeType == _IntakeType.course) ...[
                    const SizedBox(height: 16),
                    _CourseCard(
                      durationController: _durationController,
                      pauseController: _pauseController,
                      startDate: _startDate,
                      onPickStart: _pickStartDate,
                      onDurationChanged: (_) => setState(() {}),
                      infoLabel: _courseInfoLabel(
                        context.l10n,
                        MaterialLocalizations.of(context),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: const ValueKey('medsAddSaveButton'),
                    onPressed: _isSaving ? null : _onSave,
                    icon: const Icon(LucideIcons.save),
                    label: Text(context.l10n.medsAddSaveButton),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
