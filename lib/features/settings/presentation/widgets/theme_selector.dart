/// Settings feature — theme-mode selector widget.
///
/// Exports [ThemeSelector], a [ConsumerWidget] that renders a [SwitchListTile]
/// for the "Use system theme" toggle and a 2-segment [SegmentedButton] for the
/// manual Light / Dark choice. State is read from and written to
/// [settingsProvider].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/l10n_extensions.dart';
import '../providers/settings_provider.dart';

/// A compound widget that lets the user control the app theme.
///
/// Contains:
/// - A [SwitchListTile] labelled "Use system theme". When ON the device theme
///   is followed. When OFF the manual selector below becomes active.
/// - A 2-segment [SegmentedButton] (Light / Dark). Disabled — but still
///   showing the current system-derived selection — while the toggle is ON.
///
/// When the user turns the toggle OFF, [manualThemeMode] is pre-filled with
/// the current system brightness so the transition feels seamless.
class ThemeSelector extends ConsumerWidget {
  /// Creates the theme selector widget.
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = context.l10n;
    final systemBrightness = MediaQuery.platformBrightnessOf(context);

    // When the system toggle is active, derive the displayed segment from the
    // actual device brightness so the user can see what the system is using.
    final displayedMode = settings.useSystemTheme
        ? (systemBrightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light)
        : settings.manualThemeMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text(l10n.settingsUseSystemTheme),
          subtitle: Text(l10n.settingsUseSystemThemeSub),
          value: settings.useSystemTheme,
          // Zero horizontal padding — the parent Padding widget already
          // provides the 16 px horizontal inset.
          contentPadding: EdgeInsets.zero,
          onChanged: (bool value) {
            if (!value) {
              // Switching to manual: pre-select the segment that matches the
              // current system brightness so the switch feels instant.
              final manualMode = systemBrightness == Brightness.dark
                  ? ThemeMode.dark
                  : ThemeMode.light;
              ref.read(settingsProvider.notifier).setThemeMode(manualMode);
            }
            ref.read(settingsProvider.notifier).setUseSystemTheme(value);
          },
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ThemeMode>(
          segments: <ButtonSegment<ThemeMode>>[
            ButtonSegment<ThemeMode>(
              value: ThemeMode.light,
              label: Text(l10n.settingsThemeLight),
              icon: const Icon(LucideIcons.sun),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.dark,
              label: Text(l10n.settingsThemeDark),
              icon: const Icon(LucideIcons.moon),
            ),
          ],
          selected: <ThemeMode>{displayedMode},
          // Passing null disables the button in M3, but the selected segment
          // remains visually highlighted showing the current system theme.
          onSelectionChanged: settings.useSystemTheme
              ? null
              : (Set<ThemeMode> selection) {
                  ref
                      .read(settingsProvider.notifier)
                      .setThemeMode(selection.first);
                },
        ),
        ),
      ],
    );
  }
}
