/// Settings feature — settings screen with appearance, language, and intake
/// controls.
///
/// This library hosts [SettingsScreen], the screen displayed when the user
/// taps the gear icon in the Today screen's AppBar. The screen renders an
/// Appearance section with a [ThemeSelector] widget, a Language section
/// with a [LanguageSelector] widget, and an Intake section with an
/// [IntakeSettingsControls] widget.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../providers/settings_provider.dart';
import '../widgets/intake_settings_controls.dart';
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
/// The body contains an Appearance section with a [ThemeSelector] widget,
/// a Language section with a [LanguageSelector] widget, and an Intake
/// section with an [IntakeSettingsControls] widget.
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
          _SectionHeader(label: context.l10n.settingsAppearanceHeader),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ThemeSelector(),
          ),
          // Language group
          _SectionHeader(label: context.l10n.settingsLanguageHeader),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: LanguageSelector(),
          ),
          // Intake group
          _SectionHeader(label: context.l10n.settingsIntakeHeader),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: IntakeSettingsControls(),
          ),
        ],
      ),
    );
  }
}

/// Uppercase section header used to separate groups of settings controls
/// (Appearance, Language, Intake) within [SettingsScreen]'s body.
///
/// Renders [label] uppercased with the theme's `labelSmall` text style,
/// tinted with `colorScheme.primary`, medium weight, and letter-spaced —
/// matching the Material 3 list-section header convention.
class _SectionHeader extends StatelessWidget {
  /// Creates a section header displaying [label] in uppercase.
  const _SectionHeader({required this.label});

  /// The section title, e.g. "Appearance". Uppercased at render time.
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
