/// Meds feature — placeholder medication-list screen for the dosly MVP.
///
/// This library hosts [MedsScreen], the screen displayed when the user
/// selects the "Meds" destination in the bottom navigation bar. The body
/// is intentionally empty while the real medication-list feature is being
/// built out; the AppBar and 1-px bottom divider are already in place.
library;

import 'package:flutter/material.dart';

import '../../../../l10n/l10n_extensions.dart';

/// Placeholder medication-list screen shown at the meds route.
///
/// Displays a Material 3 [AppBar] with the localized title from
/// [AppLocalizationsContext.l10n] (`bottomNavMeds`), no `actions`, and an
/// `outlineVariant`-coloured bottom [Divider] border (1 px, theme-driven).
///
/// The body is [SizedBox.shrink] — empty until the medication-list feature
/// is implemented. The bottom navigation bar is provided by the routing
/// shell (`lib/core/routing/app_shell.dart`), not by [MedsScreen].
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
    );
  }
}
