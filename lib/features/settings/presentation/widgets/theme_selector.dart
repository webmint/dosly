/// Settings feature — theme-mode selector widget.
///
/// Exports [ThemeSelector], a [ConsumerWidget] that renders a [SwitchListTile]
/// for the "Use system theme" toggle and a 2-segment [SegmentedButton] for the
/// manual Light / Dark choice. State is read from and written to
/// [settingsNotifierProvider].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/l10n_extensions.dart';
import '../../domain/entities/app_theme_mode.dart';
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
    // Narrow watches: only rebuild when these two fields change, not on any
    // unrelated AppSettings field (e.g. language toggles).
    final useSystemTheme = ref.watch(
      settingsNotifierProvider.select((s) => s.useSystemTheme),
    );
    final manualThemeMode = ref.watch(
      settingsNotifierProvider.select((s) => s.manualThemeMode),
    );
    final l10n = context.l10n;
    final systemBrightness = MediaQuery.platformBrightnessOf(context);

    // Derive the device mode once; reused for both the displayed segment and
    // the toggle callback so the derivation is never duplicated (DRY).
    final AppThemeMode deviceMode = systemBrightness == Brightness.dark
        ? AppThemeMode.dark
        : AppThemeMode.light;

    // When the system toggle is active, derive the displayed segment from the
    // actual device brightness so the user can see what the system is using.
    final AppThemeMode displayedMode =
        useSystemTheme ? deviceMode : manualThemeMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text(l10n.settingsUseSystemTheme),
          subtitle: Text(l10n.settingsUseSystemThemeSub),
          value: useSystemTheme,
          // Zero horizontal padding — the parent Padding widget already
          // provides the 16 px horizontal inset.
          contentPadding: EdgeInsets.zero,
          onChanged: (bool value) {
            ref.read(settingsNotifierProvider.notifier)
                .setUseSystemTheme(value, currentDeviceMode: deviceMode);
          },
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<AppThemeMode>(
          segments: <ButtonSegment<AppThemeMode>>[
            ButtonSegment<AppThemeMode>(
              value: AppThemeMode.light,
              label: Text(l10n.settingsThemeLight),
              icon: const Icon(LucideIcons.sun),
            ),
            ButtonSegment<AppThemeMode>(
              value: AppThemeMode.dark,
              label: Text(l10n.settingsThemeDark),
              icon: const Icon(LucideIcons.moon),
            ),
          ],
          selected: <AppThemeMode>{displayedMode},
          // Passing null disables the button in M3, but the selected segment
          // remains visually highlighted showing the current system theme.
          onSelectionChanged: useSystemTheme
              ? null
              : (Set<AppThemeMode> selection) {
                  ref
                      .read(settingsNotifierProvider.notifier)
                      .setThemeMode(selection.first);
                },
        ),
        ),
      ],
    );
  }
}
