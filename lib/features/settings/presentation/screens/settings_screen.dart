/// Settings feature — placeholder settings screen for the dosly MVP.
///
/// This library hosts [SettingsScreen], the screen displayed when the user
/// taps the gear icon in the [HomeScreen] AppBar. The body is intentionally
/// empty while the real settings feature is being built out; the AppBar and
/// 1-px bottom divider are already in place so that the screen is visually
/// consistent with the rest of the app.
library;

import 'package:flutter/material.dart';

import '../../../../l10n/l10n_extensions.dart';

/// Placeholder settings screen pushed from the home route's gear [IconButton].
///
/// Displays a Material 3 [AppBar] with the localized title from
/// [AppLocalizationsContext.l10n] (`settingsTitle`), no `actions`, and an
/// `outlineVariant`-coloured bottom [Divider] border (1 px, theme-driven).
///
/// The body is [SizedBox.shrink] — empty until the settings feature is
/// implemented. Flutter automatically renders a back button in the leading
/// slot because this screen is pushed onto the navigator stack; no manual
/// `leading:` is needed.
class SettingsScreen extends StatelessWidget {
  /// Creates the placeholder settings screen.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsTitle),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1),
        ),
      ),
      body: const SizedBox.shrink(),
    );
  }
}
