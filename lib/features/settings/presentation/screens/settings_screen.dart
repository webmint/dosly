/// Settings feature — settings screen with appearance controls.
///
/// This library hosts [SettingsScreen], the screen displayed when the user
/// taps the gear icon in the [HomeScreen] AppBar. The screen renders an
/// Appearance section with a [ThemeSelector] segmented button that lets the
/// user pick between system, light, and dark theme modes.
library;

import 'package:flutter/material.dart';

import '../../../../l10n/l10n_extensions.dart';
import '../widgets/theme_selector.dart';

/// Settings screen pushed from the home route's gear [IconButton].
///
/// Displays a Material 3 [AppBar] with the localized title from
/// [AppLocalizationsContext.l10n] (`settingsTitle`), no `actions`, and an
/// `outlineVariant`-coloured bottom [Divider] border (1 px, theme-driven).
///
/// The body contains an Appearance section with a [ThemeSelector] widget.
/// Flutter automatically renders a back button in the leading slot because
/// this screen is pushed onto the navigator stack; no manual `leading:` is
/// needed. [ThemeSelector] is a [ConsumerWidget] and manages its own provider
/// subscription, so this screen can remain a plain [StatelessWidget].
class SettingsScreen extends StatelessWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsTitle),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1),
        ),
      ),
      body: ListView(
        children: [
          // Appearance group
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text(
              context.l10n.settingsAppearanceHeader.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ThemeSelector(),
          ),
        ],
      ),
    );
  }
}
