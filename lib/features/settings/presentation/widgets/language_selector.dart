/// Settings feature — language-selector widget.
///
/// Exports [LanguageSelector], a [ConsumerWidget] that renders a
/// [SwitchListTile] for the "Use device language" toggle and a
/// [DropdownButton] populated from [AppLanguage.values] for the manual
/// language override. State is read from and written to [settingsProvider].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/l10n_extensions.dart';
import '../../domain/entities/app_language.dart';
import '../providers/settings_provider.dart';

/// A compound widget that lets the user control the app language.
///
/// Contains:
/// - A [SwitchListTile] labelled "Use device language". When ON the device
///   language drives [MaterialApp.locale]. When OFF the dropdown below
///   becomes interactive.
/// - A full-width [DropdownButton] showing the language's native name.
///   Disabled (greyed) — but still visually showing the current selection —
///   while the toggle is ON.
///
/// When the user turns the toggle OFF, [manualLanguage] is pre-filled with
/// the language matching the current device locale (or [AppLanguage.en] when
/// the device locale is unsupported) so the transition feels seamless.
class LanguageSelector extends ConsumerWidget {
  /// Creates the language selector widget.
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = context.l10n;

    // When the system toggle is active, derive the displayed entry from the
    // actual device-resolved locale so the user can see what the system is
    // using — not the stale prior manual selection.
    final deviceCode = Localizations.localeOf(context).languageCode;
    final deviceLanguage = AppLanguage.values.firstWhere(
      (lang) => lang.code == deviceCode,
      orElse: () => AppLanguage.en,
    );
    final displayedLanguage =
        settings.useSystemLanguage ? deviceLanguage : settings.manualLanguage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text(l10n.settingsUseDeviceLanguage),
          subtitle: Text(l10n.settingsUseDeviceLanguageSub),
          value: settings.useSystemLanguage,
          // Zero horizontal padding — the parent Padding widget already
          // provides the 16 px horizontal inset.
          contentPadding: EdgeInsets.zero,
          onChanged: (bool value) {
            if (!value) {
              // Switching to manual — pre-fill the matching device language
              // so the visible UI doesn't lurch to a different language.
              final deviceCode =
                  Localizations.localeOf(context).languageCode;
              final pre = AppLanguage.values.firstWhere(
                (lang) => lang.code == deviceCode,
                orElse: () => AppLanguage.en,
              );
              ref.read(settingsProvider.notifier).setManualLanguage(pre);
            }
            ref.read(settingsProvider.notifier).setUseSystemLanguage(value);
          },
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: DropdownButton<AppLanguage>(
            value: displayedLanguage,
            isExpanded: true,
            onChanged: settings.useSystemLanguage
                ? null
                : (AppLanguage? selected) {
                    if (selected != null) {
                      ref
                          .read(settingsProvider.notifier)
                          .setManualLanguage(selected);
                    }
                  },
            items: [
              for (final language in AppLanguage.values)
                DropdownMenuItem<AppLanguage>(
                  value: language,
                  child: Text(language.nativeName),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
