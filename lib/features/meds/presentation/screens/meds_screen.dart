/// Meds feature — placeholder medication-list screen for the dosly MVP.
///
/// This library hosts [MedsScreen], the screen displayed when the user
/// selects the "Meds" destination in the bottom navigation bar. The screen
/// includes a [FloatingActionButton] that opens a placeholder
/// [AddMedicationModal] as a full-screen modal route while the real
/// medication-list feature is being built out.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/l10n_extensions.dart';
import '../widgets/add_medication_modal.dart';

/// Placeholder medication-list screen shown at the meds route.
///
/// Displays a Material 3 [AppBar] with the localized title from
/// [AppLocalizationsContext.l10n] (`bottomNavMeds`), no `actions`, and an
/// `outlineVariant`-coloured bottom [Divider] border (1 px, theme-driven).
///
/// The Scaffold body is still [SizedBox.shrink]; visible affordance is
/// provided by a [FloatingActionButton] that opens a placeholder
/// [AddMedicationModal] as a full-screen modal route via
/// `Navigator.push(MaterialPageRoute(fullscreenDialog: true, ...))`. The
/// bottom navigation bar is provided by the routing shell
/// (`lib/core/routing/app_shell.dart`), not by [MedsScreen].
class MedsScreen extends StatelessWidget {
  /// Creates the placeholder meds screen.
  const MedsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.bottomNavMeds),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1),
        ),
      ),
      body: const SizedBox.shrink(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddMedicationModal(context),
        tooltip: context.l10n.medsAddFabTooltip,
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}

/// Opens the placeholder Add-medication modal as a full-screen route.
///
/// Uses `rootNavigator: true` so the modal is pushed onto the top-level
/// navigator (above the [StatefulShellRoute] in `app_router.dart`),
/// covering the [AppShell]'s [AppBottomNav]. The push uses
/// `MaterialPageRoute(fullscreenDialog: true, ...)` which gives a
/// modal slide-up transition. The body is [AddMedicationModal] — a
/// [Scaffold] with an [AppBar] back-arrow + localized title and an
/// empty body until the real Add-medication form ships.
void _openAddMedicationModal(BuildContext context) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const AddMedicationModal(),
    ),
  );
}
