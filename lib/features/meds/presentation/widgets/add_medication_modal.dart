/// Meds feature — full-screen modal for the Add-medication flow (iteration 1).
///
/// This library hosts [AddMedicationModal], a full-screen modal route
/// pushed when the user taps the Add-medication FAB on the Meds screen.
/// The body renders a medication-name text field and a Save button.
/// In this first iteration (spec 026-add-med-name-input) the Save button
/// is an intentional no-op — no persistence layer exists yet. The
/// data-save iteration will supply real save behaviour and replace the
/// empty callback documented on [_AddMedicationModalState].
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/l10n_extensions.dart';

/// Full-screen modal shown when the user taps the Add-medication FAB on the
/// Meds screen.
///
/// Renders a [Scaffold] with:
/// * an [AppBar] (back-arrow leading + localized title via
///   [AppLocalizationsContext.l10n]),
/// * a padded [Column] containing a medication-name [TextField] with an
///   [OutlineInputBorder], and
/// * a full-width [FilledButton.icon] Save button (iteration-1 no-op;
///   persistence is not wired yet — see spec 026).
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
              // Intentional no-op for visual-only iteration 1 of spec
              // 026-add-med-name-input. The data-save iteration will replace
              // this empty callback with real persistence logic.
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
