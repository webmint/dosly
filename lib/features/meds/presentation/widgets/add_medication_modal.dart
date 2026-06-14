/// Meds feature — full-screen modal for the Add-medication flow (iteration 2).
///
/// This library hosts [AddMedicationModal], a full-screen modal route
/// pushed when the user taps the Add-medication FAB on the Meds screen.
/// The body renders a medication-name text field, a medication-form picker
/// ([_MedicationFormPicker] — spec 027, iteration 2), and a Save button.
/// In this second iteration (spec 027-med-form-picker) the Save button
/// remains an intentional no-op and the selected form is local state only —
/// the data-save iteration will wire both fields to a real persistence layer.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n_extensions.dart';

// ---------------------------------------------------------------------------
// Presentation-only form options data
// ---------------------------------------------------------------------------

/// An immutable descriptor for a single medication-form option displayed in
/// [_MedicationFormPicker].
///
/// Visual-only (spec 027, iteration 2): instances are never persisted.
/// The [key] string matches the planned domain enum name so future wiring
/// is a straightforward search-and-replace.
@immutable
class _MedFormOption {
  const _MedFormOption({
    required this.key,
    required this.icon,
    required this.name,
    required this.sub,
  });

  /// Stable identifier that matches the planned domain enum name.
  final String key;

  /// Icon representing this medication form.
  final IconData icon;

  /// Localized display name.
  final String Function(AppLocalizations l10n) name;

  /// Localized sub-description (e.g. route of administration).
  final String Function(AppLocalizations l10n) sub;
}

/// The 8 medication-form options shown in [_MedicationFormPicker], in the
/// HTML grid order: tablet, capsule, syrup, drops, injection, inhaler,
/// cream, sachet.
///
/// Visual-only (spec 027, iteration 2) — not persisted anywhere.
// Cannot be `const`: items hold `String Function(AppLocalizations)` closures.
final List<_MedFormOption> _medFormOptions = [
  _MedFormOption(
    key: 'tablet',
    icon: LucideIcons.tablets,
    name: (l10n) => l10n.medsAddFormTablet,
    sub: (l10n) => l10n.medsAddFormTabletSub,
  ),
  _MedFormOption(
    key: 'capsule',
    icon: LucideIcons.pill,
    name: (l10n) => l10n.medsAddFormCapsule,
    sub: (l10n) => l10n.medsAddFormCapsuleSub,
  ),
  _MedFormOption(
    key: 'syrup',
    icon: LucideIcons.milk,
    name: (l10n) => l10n.medsAddFormSyrup,
    sub: (l10n) => l10n.medsAddFormSyrupSub,
  ),
  _MedFormOption(
    key: 'drops',
    icon: LucideIcons.droplets,
    name: (l10n) => l10n.medsAddFormDrops,
    sub: (l10n) => l10n.medsAddFormDropsSub,
  ),
  _MedFormOption(
    key: 'injection',
    icon: LucideIcons.syringe,
    name: (l10n) => l10n.medsAddFormInjection,
    sub: (l10n) => l10n.medsAddFormInjectionSub,
  ),
  _MedFormOption(
    key: 'inhaler',
    icon: LucideIcons.wind,
    name: (l10n) => l10n.medsAddFormInhaler,
    sub: (l10n) => l10n.medsAddFormInhalerSub,
  ),
  _MedFormOption(
    key: 'cream',
    icon: LucideIcons.container,
    name: (l10n) => l10n.medsAddFormCream,
    sub: (l10n) => l10n.medsAddFormCreamSub,
  ),
  _MedFormOption(
    key: 'sachet',
    icon: LucideIcons.package,
    name: (l10n) => l10n.medsAddFormSachet,
    sub: (l10n) => l10n.medsAddFormSachetSub,
  ),
];

// ---------------------------------------------------------------------------
// _MedicationFormPicker widget
// ---------------------------------------------------------------------------

/// A self-contained, presentation-only medication-form picker.
///
/// Displays a tappable outlined display row (floating label, icon chip, name,
/// sub-description, animated chevron) that expands an animated grid of the
/// 8 options from [_medFormOptions].
///
/// Visual-only iteration 2 (spec 027-med-form-picker):
/// * Selection is stored in local [State] only — it is intentionally NOT
///   persisted, not passed to a Riverpod provider, and not consumed by the
///   Save button (which remains a no-op).
/// * The data-save iteration will accept a callback or use a provider to
///   wire the selected form into the repository call.
///
/// No [AnimationController] is used — [AnimatedSize] and [AnimatedRotation]
/// are implicit animations that manage their own lifecycle.
class _MedicationFormPicker extends StatefulWidget {
  /// Creates a [_MedicationFormPicker].
  const _MedicationFormPicker();

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
    final displayName =
        selected == null ? l10n.medsAddFormPlaceholder : selected.name(l10n);
    final displaySub = selected == null ? null : selected.sub(l10n);
    final displayIcon = selected?.icon ?? LucideIcons.shapes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ----------------------------------------------------------------
        // Display row — tappable, inherits global inputDecorationTheme.
        // ----------------------------------------------------------------
        InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => setState(() => _isOpen = !_isOpen),
          child: InputDecorator(
            // isEmpty:false keeps the label permanently floated so that
            // the outlined border always shows with the label cut-out.
            isEmpty: false,
            decoration: InputDecoration(
              labelText: l10n.medsAddFormLabel,
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
                      Text(
                        displayName,
                        style: textTheme.bodyLarge,
                      ),
                      if (displaySub != null)
                        Text(
                          displaySub,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
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
                  ),
                ),
              ],
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
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
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
  Widget _buildChip(
    BuildContext context,
    _MedFormOption option,
    int index,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = index == _selectedIndex;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() {
        _selectedIndex = index;
        _isOpen = false;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
///     iteration 2 — visual-only, selection not yet persisted), and
///   - a full-width [FilledButton.icon] Save button (no-op — data-save
///     iteration will wire persistence).
///
/// The modal is pushed via `Navigator.push(MaterialPageRoute(
/// fullscreenDialog: true, ...))` from `meds_screen.dart`.
class AddMedicationModal extends StatefulWidget {
  /// Creates the Add-medication modal.
  const AddMedicationModal({super.key});

  @override
  State<AddMedicationModal> createState() => _AddMedicationModalState();
}

class _AddMedicationModalState extends State<AddMedicationModal> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        title: Text(context.l10n.medsAddTitle),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
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
              // Medication-form picker — visual-only iteration 2 (spec 027).
              // Selection is local to _MedicationFormPicker; Save remains
              // a no-op until the data-save iteration wires the picker.
              const _MedicationFormPicker(),
              const SizedBox(height: 16),
              // Intentional no-op for spec 026/027 visual iterations.
              // The data-save iteration will replace this empty callback
              // with real persistence logic.
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.save),
                label: Text(context.l10n.medsAddSaveButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
