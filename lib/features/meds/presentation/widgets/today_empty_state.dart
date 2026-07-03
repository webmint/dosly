/// Meds feature — empty-state widget for the Today screen.
///
/// This library exports [TodayEmptyState], the centered placeholder rendered
/// when [TodayView.isEmpty] is `true` (AC-11): nothing is due on the current
/// local calendar day. Mirrors the meds-list screen's `_EmptyState` styling so
/// the two checklists share a consistent empty-state look.
library;

import 'package:flutter/material.dart';

import '../../../../l10n/l10n_extensions.dart';

/// Centered empty-state card shown when no doses are due today.
///
/// Displays [context.l10n.todayEmptyTitle] in [TextTheme.titleMedium] and
/// [context.l10n.todayEmptyBody] in [TextTheme.bodyMedium], both muted with
/// [ColorScheme.onSurfaceVariant].
class TodayEmptyState extends StatelessWidget {
  /// Creates the Today screen's empty-state placeholder.
  const TodayEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              l10n.todayEmptyTitle,
              textAlign: TextAlign.center,
              style: (tt.titleMedium ?? const TextStyle()).copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.todayEmptyBody,
              textAlign: TextAlign.center,
              style: (tt.bodyMedium ?? const TextStyle()).copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
