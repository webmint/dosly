/// A small card showing a single Material 3 color role.
///
/// Used by `ThemePreviewScreen` to render the palette grid. The card paints
/// its background with [color] and overlays the role [label] and [hex] string
/// in [onColor] so the contrast is correct for either light or dark mode.
library;

import 'package:flutter/material.dart';

/// A reusable card that visualizes one M3 color role.
class ColorSwatchCard extends StatelessWidget {
  /// Creates a swatch card.
  const ColorSwatchCard({
    super.key,
    required this.label,
    required this.color,
    required this.onColor,
    required this.hex,
  });

  /// Human-readable role name (e.g. `'primary'`, `'surfaceContainerHighest'`).
  final String label;

  /// Background color for the card.
  final Color color;

  /// Foreground color used for [label] and [hex] text — chosen by the caller
  /// to contrast against [color].
  final Color onColor;

  /// Hex string label (e.g. `'#2E7D32'`) shown in monospace below the role name.
  final String hex;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(minHeight: 72),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: onColor,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          Text(
            hex,
            style: TextStyle(
              color: onColor,
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
