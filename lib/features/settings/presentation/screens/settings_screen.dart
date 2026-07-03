/// Settings feature — settings screen with appearance and language controls.
///
/// This library hosts [SettingsScreen], the screen displayed when the user
/// taps the gear icon in the Today screen's AppBar. The screen renders an
/// Appearance section with a [ThemeSelector] widget and a Language section
/// with a [LanguageSelector] widget.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../providers/settings_provider.dart';
import '../widgets/language_selector.dart';
import '../widgets/theme_selector.dart';

/// Settings screen pushed from the home route's gear [IconButton].
///
/// Displays a Material 3 [AppBar] with the localized title from
/// [AppLocalizationsContext.l10n] (`settingsTitle`), no `actions`, and an
/// `outlineVariant`-coloured bottom [Divider] border (1 px, theme-driven).
///
/// Listens to [settingsErrorsProvider] and shows a localized floating
/// SnackBar each time a preference fails to persist (e.g. SharedPreferences
/// write failure).
///
/// The body contains an Appearance section with a [ThemeSelector] widget
/// and a Language section with a [LanguageSelector] widget.
/// Flutter automatically renders a back button in the leading slot because
/// this screen is pushed onto the navigator stack; no manual `leading:` is
/// needed.
class SettingsScreen extends ConsumerWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<Failure>>(settingsErrorsProvider, (prev, next) {
      next.whenData((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.settingsPersistenceError),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    });
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
          // Language group
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text(
              context.l10n.settingsLanguageHeader.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: LanguageSelector(),
          ),
        ],
      ),
    );
  }
}
