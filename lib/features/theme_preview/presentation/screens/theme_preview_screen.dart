/// Material 3 theme preview / smoke screen.
///
/// Renders every M3 color role, every type-scale style, and one of each
/// common widget. Used as the app's `home` until real screens land. Delete
/// when no longer needed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// Temporary cross-feature import — ThemePreviewScreen is a dev-only screen
// scheduled for removal (see specs/002-main-screen/spec.md §6 and §8).
import '../../../settings/presentation/providers/settings_provider.dart';
import '../widgets/color_swatch_card.dart';
import '../widgets/typography_sample.dart';

/// Top-level preview screen showing the full M3 design system.
class ThemePreviewScreen extends ConsumerWidget {
  /// Creates the preview screen.
  const ThemePreviewScreen({super.key});

  static IconData _iconForEffectiveMode(ThemeMode effectiveMode) {
    return switch (effectiveMode) {
      ThemeMode.system => LucideIcons.sunMoon,
      ThemeMode.light => LucideIcons.sun,
      ThemeMode.dark => LucideIcons.moon,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final effectiveMode = settings.effectiveThemeMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('dosly · M3 preview'),
        actions: [
          IconButton(
            tooltip: 'Cycle theme mode',
            icon: Icon(_iconForEffectiveMode(effectiveMode)),
            onPressed: () {
              final notifier = ref.read(settingsProvider.notifier);
              // Cycle: system → light → dark → system
              if (settings.useSystemTheme) {
                // system → light (manual)
                notifier.setThemeMode(ThemeMode.light);
                notifier.setUseSystemTheme(false);
              } else if (settings.manualThemeMode == ThemeMode.light) {
                // light → dark (manual)
                notifier.setThemeMode(ThemeMode.dark);
              } else {
                // dark → system
                notifier.setUseSystemTheme(true);
              }
            },
          ),
        ],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: _PreviewBody(),
      ),
      floatingActionButton: const FloatingActionButton(
        onPressed: null,
        tooltip: 'Demo FAB',
        child: Icon(LucideIcons.plus),
      ),
    );
  }
}

class _PreviewBody extends StatelessWidget {
  const _PreviewBody();

  static String _hex(Color c) {
    final v = c.toARGB32();
    return '#${v.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final swatches = <Widget>[
      _swatch('primary', scheme.primary, scheme.onPrimary),
      _swatch('onPrimary', scheme.onPrimary, scheme.primary),
      _swatch('primaryContainer', scheme.primaryContainer, scheme.onPrimaryContainer),
      _swatch('onPrimaryContainer', scheme.onPrimaryContainer, scheme.primaryContainer),

      _swatch('secondary', scheme.secondary, scheme.onSecondary),
      _swatch('onSecondary', scheme.onSecondary, scheme.secondary),
      _swatch('secondaryContainer', scheme.secondaryContainer, scheme.onSecondaryContainer),
      _swatch('onSecondaryContainer', scheme.onSecondaryContainer, scheme.secondaryContainer),

      _swatch('tertiary', scheme.tertiary, scheme.onTertiary),
      _swatch('onTertiary', scheme.onTertiary, scheme.tertiary),
      _swatch('tertiaryContainer', scheme.tertiaryContainer, scheme.onTertiaryContainer),
      _swatch('onTertiaryContainer', scheme.onTertiaryContainer, scheme.tertiaryContainer),

      _swatch('error', scheme.error, scheme.onError),
      _swatch('onError', scheme.onError, scheme.error),
      _swatch('errorContainer', scheme.errorContainer, scheme.onErrorContainer),
      _swatch('onErrorContainer', scheme.onErrorContainer, scheme.errorContainer),

      _swatch('surface', scheme.surface, scheme.onSurface),
      _swatch('onSurface', scheme.onSurface, scheme.surface),
      _swatch('onSurfaceVariant', scheme.onSurfaceVariant, scheme.surfaceContainerHigh),

      _swatch('outline', scheme.outline, scheme.surface),
      _swatch('outlineVariant', scheme.outlineVariant, scheme.onSurface),

      _swatch('surfaceContainerLowest', scheme.surfaceContainerLowest, scheme.onSurface),
      _swatch('surfaceContainerLow', scheme.surfaceContainerLow, scheme.onSurface),
      _swatch('surfaceContainer', scheme.surfaceContainer, scheme.onSurface),
      _swatch('surfaceContainerHigh', scheme.surfaceContainerHigh, scheme.onSurface),
      _swatch('surfaceContainerHighest', scheme.surfaceContainerHighest, scheme.onSurface),

      _swatch('inverseSurface', scheme.inverseSurface, scheme.onInverseSurface),
      _swatch('inversePrimary', scheme.inversePrimary, scheme.onSurface),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(label: 'Color roles'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: swatches,
        ),
        const _SectionHeader(label: 'Typography'),
        TypographySample(styleName: 'displayLarge', style: textTheme.displayLarge),
        TypographySample(styleName: 'displayMedium', style: textTheme.displayMedium),
        TypographySample(styleName: 'displaySmall', style: textTheme.displaySmall),
        TypographySample(styleName: 'headlineLarge', style: textTheme.headlineLarge),
        TypographySample(styleName: 'headlineMedium', style: textTheme.headlineMedium),
        TypographySample(styleName: 'headlineSmall', style: textTheme.headlineSmall),
        TypographySample(styleName: 'titleLarge', style: textTheme.titleLarge),
        TypographySample(styleName: 'titleMedium', style: textTheme.titleMedium),
        TypographySample(styleName: 'titleSmall', style: textTheme.titleSmall),
        TypographySample(styleName: 'bodyLarge', style: textTheme.bodyLarge),
        TypographySample(styleName: 'bodyMedium', style: textTheme.bodyMedium),
        TypographySample(styleName: 'bodySmall', style: textTheme.bodySmall),
        TypographySample(styleName: 'labelLarge', style: textTheme.labelLarge),
        TypographySample(styleName: 'labelMedium', style: textTheme.labelMedium),
        TypographySample(styleName: 'labelSmall', style: textTheme.labelSmall),
        const _SectionHeader(label: 'Icons'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _iconTile(LucideIcons.pill, 'pill'),
            _iconTile(LucideIcons.house, 'house'),
            _iconTile(LucideIcons.settings, 'settings'),
            _iconTile(LucideIcons.history, 'history'),
            _iconTile(LucideIcons.circlePlus, 'circlePlus'),
            _iconTile(LucideIcons.thermometer, 'thermometer'),
            _iconTile(LucideIcons.syringe, 'syringe'),
            _iconTile(LucideIcons.glasses, 'glasses'),
            _iconTile(LucideIcons.droplets, 'droplets'),
            _iconTile(LucideIcons.activity, 'activity'),
            _iconTile(LucideIcons.clock, 'clock'),
            _iconTile(LucideIcons.check, 'check'),
            _iconTile(LucideIcons.chevronDown, 'chevronDown'),
            _iconTile(LucideIcons.chevronRight, 'chevronRight'),
            _iconTile(LucideIcons.arrowLeft, 'arrowLeft'),
            _iconTile(LucideIcons.search, 'search'),
            _iconTile(LucideIcons.plus, 'plus'),
            _iconTile(LucideIcons.eye, 'eye'),
            _iconTile(LucideIcons.x, 'x'),
            _iconTile(LucideIcons.phone, 'phone'),
          ],
        ),
        const _SectionHeader(label: 'Components'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton(onPressed: () {}, child: const Text('Filled')),
            FilledButton.tonal(onPressed: () {}, child: const Text('Tonal')),
            OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
            TextButton(onPressed: () {}, child: const Text('Text')),
            const Chip(
              label: Text('Chip'),
              avatar: Icon(LucideIcons.pill, size: 18),
            ),
            const Icon(LucideIcons.clock, size: 32),
            Switch(value: true, onChanged: (_) {}),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Card title', style: textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Cards use surfaceContainer as their background per the M3 elevation overlay model.',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Text field',
            helperText: 'Demonstrates the input decoration theme',
            prefixIcon: Icon(LucideIcons.pill),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  static Widget _iconTile(IconData icon, String label) {
    return SizedBox(
      width: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _swatch(String label, Color color, Color onColor) {
    return SizedBox(
      width: 160,
      child: ColorSwatchCard(
        label: label,
        color: color,
        onColor: onColor,
        hex: _hex(color),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
