/// Material 3 theme preview / smoke screen.
///
/// Renders every M3 color role, every type-scale style, and one of each
/// common widget. Used as the app's `home` until real screens land. Delete
/// when no longer needed.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/theme_controller.dart';
import '../widgets/color_swatch_card.dart';
import '../widgets/typography_sample.dart';

/// Top-level preview screen showing the full M3 design system.
class ThemePreviewScreen extends StatelessWidget {
  /// Creates the preview screen.
  const ThemePreviewScreen({super.key});

  static IconData _iconForMode(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => Icons.brightness_auto_rounded,
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.dark => Icons.dark_mode_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('dosly · M3 preview'),
        actions: [
          IconButton(
            tooltip: 'Cycle theme mode',
            icon: Icon(_iconForMode(themeController.value)),
            onPressed: themeController.cycle,
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
        child: Icon(Icons.add_rounded),
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
              avatar: Icon(Icons.medication_rounded, size: 18),
            ),
            const Icon(Icons.schedule_rounded, size: 32),
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
            prefixIcon: Icon(Icons.medication_rounded),
          ),
        ),
        const SizedBox(height: 32),
      ],
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
