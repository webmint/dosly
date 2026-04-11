/// A small row showing one Material 3 type-scale style.
///
/// Used by `ThemePreviewScreen` to render the typography section. Each row
/// shows a small label (the style name) above a sample line rendered in the
/// supplied [style].
library;

import 'package:flutter/material.dart';

/// A reusable widget that displays a single text-style sample.
class TypographySample extends StatelessWidget {
  /// Creates a typography sample.
  const TypographySample({
    super.key,
    required this.styleName,
    required this.style,
  });

  /// Display name of the style (e.g. `'titleLarge'`, `'bodyMedium'`).
  final String styleName;

  /// The text style to apply to the sample line. Nullable so callers can pass
  /// `Theme.of(context).textTheme.titleLarge` directly without `!`.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            styleName,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text('The quick brown fox', style: style),
        ],
      ),
    );
  }
}
