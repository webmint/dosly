/// Meds feature — display tile for a single medication list item.
///
/// This library exports [MedicationTile], a dumb display widget that renders
/// one [MedListItem] — a filled rounded-square icon badge, name, subtitle,
/// status + type chips, and a trailing chevron. It carries NO business logic
/// and NO providers. An optional [MedicationTile.onTap] callback enables tap
/// interaction; behavior is supplied by the parent.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:dosly/l10n/app_localizations.dart';

import '../../domain/entities/course_phase.dart';
import '../../domain/entities/medication_activity_status.dart';
import '../../domain/entities/medication_type.dart';
import '../../domain/value_objects/course_progress.dart';
import '../view_models/meds_list_view_model.dart';
import '../../../../l10n/l10n_extensions.dart';
import 'medication_display.dart';
import 'medication_form_icon.dart';

/// Renders a single [MedListItem] as a custom Row tile with an optional tap target.
///
/// Layout: icon badge → 16 px gap → body Column (Expanded) → 16 px gap →
/// chevron. The root widget is keyed with `ValueKey('medTile-<id>')` for
/// stable identity in animated lists. An [InkWell] wraps the tile body and
/// is activated when [onTap] is non-null; when [onTap] is `null` the tile
/// renders identically to its previous non-interactive form. Navigation or
/// behavior is supplied by the parent widget — this widget remains dumb.
///
/// Icon badge: 48×48 filled rounded square (radius 12). Color variant by type:
/// - continuous → [ColorScheme.primaryContainer] / [ColorScheme.onPrimaryContainer]
/// - course → [ColorScheme.tertiaryContainer] / [ColorScheme.onTertiaryContainer]
///
/// Body: medication name (`bodyLarge`, weight 400), joined subtitle (dose ·
/// times · stock), and a [Wrap] of status and type chips.
class MedicationTile extends StatelessWidget {
  /// Creates a [MedicationTile] for the given [item].
  ///
  /// Supply [onTap] to make the tile tappable; omit it (or pass `null`) for a
  /// non-interactive tile that renders exactly as before.
  const MedicationTile({required this.item, this.onTap, super.key});

  /// The medication item to render.
  final MedListItem item;

  /// Optional callback invoked when the user taps the tile.
  ///
  /// When non-null, the tile body is wrapped in an [InkWell] that provides a
  /// ripple feedback. When null, the tile is non-interactive.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    final bool isContinuous = item.medication.type is ContinuousType;
    final bool isCompleted = item.activity == MedicationActivityStatus.completed;

    final Color badgeBg = isCompleted
        ? cs.surfaceContainerHighest
        : isContinuous
            ? cs.primaryContainer
            : cs.tertiaryContainer;
    final Color badgeFg = isCompleted
        ? cs.onSurfaceVariant
        : isContinuous
            ? cs.onPrimaryContainer
            : cs.onTertiaryContainer;

    return Opacity(
      key: ValueKey('medTile-${item.medication.id.value}'),
      opacity: isCompleted ? 0.65 : 1.0,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // ── Icon badge (.med-iconify) ──────────────────────────────────
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  medicationFormIcon(item.medication.form),
                  size: 26,
                  color: badgeFg,
                ),
              ),
              const SizedBox(width: 16),
              // ── Body column (.mlt-body) ────────────────────────────────────
              Expanded(child: _TileBody(item: item)),
              const SizedBox(width: 16),
              // ── Trailing chevron (.mlt-trail) ──────────────────────────────
              Icon(LucideIcons.chevronRight, size: 20, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders the body column: name, subtitle, and chips.
///
/// Extracted from [MedicationTile.build] to keep each method under ~40 lines.
class _TileBody extends StatelessWidget {
  const _TileBody({required this.item});

  final MedListItem item;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Name (.mlt-name) — bodyLarge weight 400 (not titleMedium/w500)
        Text(
          item.medication.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tt.bodyLarge?.copyWith(color: cs.onSurface),
        ),
        const SizedBox(height: 2),
        // Subtitle (.mlt-sub)
        _SubtitleText(item: item),
        const SizedBox(height: 6),
        // Chips (.mlt-chips) — course: type first; continuous: status first.
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: switch (item.medication.type) {
            CourseType() => <Widget>[
                _TypeChip(item: item),
                _StatusChip(activity: item.activity),
              ],
            ContinuousType() => <Widget>[
                _StatusChip(activity: item.activity),
                _TypeChip(item: item),
              ],
          },
        ),
      ],
    );
  }
}

/// Builds the joined subtitle row as [Text.rich].
///
/// Segments: dose · times · stock (all optional). The stock segment is ALWAYS
/// bold (`FontWeight.w600`); its color is [ColorScheme.error] when
/// [isLowStock] returns true, otherwise [ColorScheme.onSurfaceVariant].
/// Separators use the default (non-bold) style.
///
/// Kept as a [Text.rich] / [RichText] so test span-tree inspection can locate
/// the error-colored stock span.
class _SubtitleText extends StatelessWidget {
  const _SubtitleText({required this.item});

  final MedListItem item;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;
    final AppLocalizations l10n = context.l10n;

    final String? doseSegment =
        formatDose(item.medication.dosePerIntake, l10n);
    final String timesSegment = formatTimes(item.medication.schedule.slots);
    final String? stockSegment = formatStock(item.medication.stock, l10n);
    final bool lowStock = isLowStock(item.medication.stock);

    final TextStyle defaultStyle =
        tt.bodySmall?.copyWith(color: cs.onSurfaceVariant) ??
            TextStyle(color: cs.onSurfaceVariant);

    final List<InlineSpan> spans = <InlineSpan>[];

    // Leading segments: dose, times.
    final List<String> leading = <String>[
      if (doseSegment != null && doseSegment.isNotEmpty) doseSegment,
      if (timesSegment.isNotEmpty) timesSegment,
    ];

    if (leading.isNotEmpty) {
      spans.add(TextSpan(text: leading.join(' · '), style: defaultStyle));
    }

    // Stock segment — always bold; red when low.
    if (stockSegment != null && stockSegment.isNotEmpty) {
      if (spans.isNotEmpty) {
        spans.add(TextSpan(text: ' · ', style: defaultStyle));
      }
      spans.add(
        TextSpan(
          text: stockSegment,
          style: defaultStyle.copyWith(
            fontWeight: FontWeight.w600,
            color: lowStock ? cs.error : cs.onSurfaceVariant,
          ),
        ),
      );
    }

    if (spans.isEmpty) return const SizedBox.shrink();

    return Text.rich(TextSpan(children: spans));
  }
}

/// Renders the active/completed status chip.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.activity});

  final MedicationActivityStatus activity;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppLocalizations l10n = context.l10n;

    final (String label, Color background, Color foreground) =
        switch (activity) {
      MedicationActivityStatus.active => (
          l10n.medsListStatusActive,
          cs.primaryContainer,
          cs.onPrimaryContainer,
        ),
      MedicationActivityStatus.completed => (
          l10n.medsListStatusCompleted,
          cs.surfaceContainerHighest,
          cs.onSurfaceVariant,
        ),
    };

    return _Pill(label: label, background: background, foreground: foreground);
  }
}

/// Renders the continuous/course type chip.
///
/// Color mapping:
/// - continuous → neutral: [ColorScheme.surfaceContainerHigh] /
///   [ColorScheme.onSurfaceVariant]
/// - course activeWindow (Day X/Y) → teal: [ColorScheme.tertiaryContainer] /
///   [ColorScheme.onTertiaryContainer]
/// - course paused → neutral: [ColorScheme.surfaceContainerHigh] /
///   [ColorScheme.onSurfaceVariant]
///
/// For course medications, derives the label from [MedListItem.progress] — the
/// [CourseProgress] is non-null for all [CourseType] items (see
/// [buildMedsListView]). The [progress] field is checked with an explicit
/// `if (progress != null)` guard before deriving the label, so no `!` is used.
class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.item});

  final MedListItem item;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppLocalizations l10n = context.l10n;

    final _ChipSpec? spec = _resolveTypeSpec(item, l10n, cs);
    if (spec == null) return const SizedBox.shrink();

    return _Pill(
      label: spec.label,
      background: spec.background,
      foreground: spec.foreground,
    );
  }

  /// Resolves the type-chip [_ChipSpec] from [item].
  ///
  /// Returns `null` when a course item has no progress yet (which should not
  /// occur in practice but is handled defensively to avoid `!`).
  static _ChipSpec? _resolveTypeSpec(
    MedListItem item,
    AppLocalizations l10n,
    ColorScheme cs,
  ) {
    if (item.medication.type is ContinuousType) {
      return _ChipSpec(
        label: l10n.medsListTypeContinuous,
        background: cs.surfaceContainerHigh,
        foreground: cs.onSurfaceVariant,
      );
    }

    // CourseType: derive label and colors from progress phase.
    final CourseProgress? progress = item.progress;
    if (progress == null) return null;

    return switch (progress.phase) {
      CoursePhase.activeWindow => _ChipSpec(
          label: l10n.medsListTypeCourseDay(
            progress.currentDay,
            progress.totalDays,
          ),
          background: cs.tertiaryContainer,
          foreground: cs.onTertiaryContainer,
        ),
      CoursePhase.paused => _ChipSpec(
          label: l10n.medsListTypeCoursePaused,
          background: cs.surfaceContainerHigh,
          foreground: cs.onSurfaceVariant,
        ),
    };
  }
}

/// Immutable value holder for a chip's label and colors.
class _ChipSpec {
  const _ChipSpec({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;
}

/// A small pill-shaped (stadium) label container used for status and type chips.
///
/// Styled as a fully rounded stadium pill (`borderRadius: 100`), matching the
/// `.s-chip` design spec. Intentionally non-interactive — no [InkWell] or
/// [GestureDetector].
class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final TextTheme tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: tt.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w500,
            ) ??
            TextStyle(color: foreground, fontWeight: FontWeight.w500),
      ),
    );
  }
}
