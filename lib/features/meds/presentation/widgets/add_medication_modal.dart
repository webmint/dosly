/// Meds feature — placeholder full-screen modal for the Add-medication flow.
///
/// This library hosts [AddMedicationModal], a full-screen modal route
/// pushed when the user taps the Add-medication FAB on the Meds screen.
/// The body is intentionally empty — it renders only an AppBar with a
/// back-arrow leading and a localized title — because the real
/// Add-medication form will replace this body in a future feature spec.
/// When that spec is written and approved, a new feature directory
/// (e.g. `specs/NNN-add-medication/`) will describe the full form; the
/// implementation there will supersede this placeholder by replacing
/// the [AddMedicationModal] body.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/l10n_extensions.dart';

/// Placeholder full-screen modal shown when the user taps the
/// Add-medication FAB on the Meds screen.
///
/// Renders a [Scaffold] with an [AppBar] (back-arrow leading +
/// localized title via [AppLocalizationsContext.l10n]) and an empty
/// body. The modal is pushed via `Navigator.push(MaterialPageRoute(
/// fullscreenDialog: true, ...))` from `meds_screen.dart`.
class AddMedicationModal extends StatelessWidget {
  /// Creates the placeholder Add-medication modal.
  const AddMedicationModal({super.key});

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
      body: const SizedBox.shrink(),
    );
  }
}
