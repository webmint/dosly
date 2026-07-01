/// Meds feature — display section for a group of medications.
///
/// This library exports [MedicationSection], a dumb display widget that renders
/// a localized section header followed by a [Column] of [MedicationTile]s
/// separated by [Divider]s, or an inline empty-state placeholder when the
/// `[items]` list is empty and a search query is active
/// (`queryActive && items.isEmpty`). It carries NO business logic and NO
/// providers. An optional [MedicationSection.onTapItem] callback enables
/// per-tile tap interaction; behavior is supplied by the parent.
library;

import 'package:flutter/material.dart';

import '../../domain/entities/medication.dart';
import '../view_models/meds_list_view_model.dart';
import '../../../../l10n/l10n_extensions.dart';
import 'medication_tile.dart';

/// Renders a named section of medications — a header, then tiles or a
/// placeholder.
///
/// The [title] string is rendered as a section header (already-localized by the
/// caller). When [items] is empty AND [queryActive] is `true`, an inline muted
/// placeholder is shown instead of tiles. When [items] is empty and [queryActive]
/// is `false`, only the section header is rendered (no placeholder). When [items]
/// is non-empty, a [Column] of [MedicationTile]s is rendered, each pair separated
/// by a [Divider].
///
/// [queryActive] should be `true` when the user has entered a non-empty search
/// query — this gates the per-section empty-state placeholder so it only appears
/// as search-results feedback, not as permanent UI noise on the initial list view.
///
/// Uses a plain [Column] (not a nested scrollable) — the scroll context belongs
/// to the parent screen.
class MedicationSection extends StatelessWidget {
  /// Creates a [MedicationSection] with the given [title], [items],
  /// [queryActive] flag, and optional [onTapItem] callback.
  const MedicationSection({
    required this.title,
    required this.items,
    required this.queryActive,
    this.onTapItem,
    super.key,
  });

  /// The localized section header text (e.g. "Continuous" or "Courses").
  final String title;

  /// The medication items to render; may be empty.
  final List<MedListItem> items;

  /// Whether the user has an active (non-empty) search query.
  ///
  /// When `true` and [items] is empty, an inline placeholder is rendered to
  /// indicate no search results. When `false` and [items] is empty, only the
  /// section header is shown (no placeholder).
  final bool queryActive;

  /// Optional callback invoked when the user taps a medication tile.
  ///
  /// Receives the [Medication] corresponding to the tapped tile. When null,
  /// tiles are rendered non-interactively (no ripple).
  final void Function(Medication medication)? onTapItem;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionHeader(title: title),
        if (items.isEmpty && queryActive)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              l10n.medsListSectionEmpty,
              style: (tt.bodySmall ?? const TextStyle()).copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          )
        else if (items.isNotEmpty)
          ..._buildTileList(context, items),
      ],
    );
  }

  /// Builds the interleaved list of [MedicationTile]s and [Divider]s.
  ///
  /// Each adjacent pair of tiles is separated by a thin [Divider] inset 16 px
  /// on both sides, matching the `.divider` design spec
  /// (`margin: 0 16px; background: outline-variant`).
  ///
  /// When [onTapItem] is non-null, each tile receives a callback that forwards
  /// the tile's [Medication] to the caller. When null, tiles are non-interactive.
  List<Widget> _buildTileList(BuildContext context, List<MedListItem> items) {
    final Color dividerColor =
        Theme.of(context).colorScheme.outlineVariant;
    final void Function(Medication medication)? onTapItem = this.onTapItem;
    final List<Widget> children = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      children.add(
        MedicationTile(
          item: items[i],
          onTap: onTapItem == null
              ? null
              : () => onTapItem(items[i].medication),
        ),
      );
      if (i < items.length - 1) {
        children.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: dividerColor,
          ),
        );
      }
    }
    return children;
  }
}

/// Renders the section header text styled as a muted sub-heading.
///
/// Matches the `.sec-head` design spec: 14/20 `labelLarge`, muted
/// `onSurfaceVariant` color, weight 500, with 12 px top / 16 px side / 4 px
/// bottom padding.
///
/// Extracted to keep [MedicationSection.build] under ~40 lines.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: (tt.labelLarge ?? const TextStyle()).copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
