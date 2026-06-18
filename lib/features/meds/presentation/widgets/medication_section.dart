/// Meds feature — display section for a group of medications.
///
/// This library exports [MedicationSection], a dumb display widget that renders
/// a localized section header followed by a [Column] of [MedicationTile]s
/// separated by [Divider]s, or an inline empty-state placeholder when the
/// [items] list is empty. It carries NO business logic, NO providers, and NO
/// tap targets.
library;

import 'package:flutter/material.dart';

import '../view_models/meds_list_view_model.dart';
import '../../../../l10n/l10n_extensions.dart';
import 'medication_tile.dart';

/// Renders a named section of medications — a header, then tiles or a
/// placeholder.
///
/// The [title] string is rendered as a section header (already-localized by the
/// caller). When [items] is empty, an inline muted placeholder is shown instead
/// of tiles. When [items] is non-empty, a [Column] of [MedicationTile]s is
/// rendered, each pair separated by a [Divider].
///
/// Uses a plain [Column] (not a nested scrollable) — the scroll context belongs
/// to the parent screen.
class MedicationSection extends StatelessWidget {
  /// Creates a [MedicationSection] with the given [title] and [items].
  const MedicationSection({
    required this.title,
    required this.items,
    super.key,
  });

  /// The localized section header text (e.g. "Continuous" or "Courses").
  final String title;

  /// The medication items to render; may be empty.
  final List<MedListItem> items;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionHeader(title: title),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              l10n.medsListSectionEmpty,
              style: (tt.bodySmall ?? const TextStyle()).copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          )
        else
          ..._buildTileList(context, items),
      ],
    );
  }

  /// Builds the interleaved list of [MedicationTile]s and [Divider]s.
  ///
  /// Each adjacent pair of tiles is separated by a thin [Divider] inset 16 px
  /// on both sides, matching the `.divider` design spec
  /// (`margin: 0 16px; background: outline-variant`).
  List<Widget> _buildTileList(BuildContext context, List<MedListItem> items) {
    final Color dividerColor =
        Theme.of(context).colorScheme.outlineVariant;
    final List<Widget> children = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      children.add(MedicationTile(item: items[i]));
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
