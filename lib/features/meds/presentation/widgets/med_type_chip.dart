/// Meds feature — shared medication type chip (continuous / Day N/M / paused).
///
/// This library exports [MedTypeChip], a dumb display widget that renders the
/// continuous/course type chip shared by the meds-list tile
/// ([MedicationTile]) and the redesigned Today dose tile, so the color+label
/// resolution logic lives in exactly one place.
library;

import 'package:flutter/material.dart';

import 'package:dosly/l10n/app_localizations.dart';

import '../../../../l10n/l10n_extensions.dart';
import '../../domain/entities/course_phase.dart';
import '../../domain/entities/medication.dart';
import '../../domain/entities/medication_type.dart';
import '../../domain/value_objects/course_progress.dart';

/// Renders the continuous/course type chip for a [medication].
///
/// Color mapping:
/// - continuous → neutral: [ColorScheme.surfaceContainerHigh] /
///   [ColorScheme.onSurfaceVariant]
/// - course activeWindow (Day X/Y) → teal: [ColorScheme.tertiaryContainer] /
///   [ColorScheme.onTertiaryContainer]
/// - course paused → neutral: [ColorScheme.surfaceContainerHigh] /
///   [ColorScheme.onSurfaceVariant]
///
/// For course medications, derives the label from [progress] — the
/// [CourseProgress] is expected to be non-null for all [CourseType]
/// medications, but [progress] is checked with an explicit
/// `if (progress != null)` guard before deriving the label, so no `!` is used;
/// when it is `null` this renders nothing ([SizedBox.shrink]).
class MedTypeChip extends StatelessWidget {
  /// Creates a [MedTypeChip] for [medication], using [progress] to derive the
  /// course-specific label (ignored for continuous medications).
  const MedTypeChip({required this.medication, required this.progress, super.key});

  /// The medication whose type chip is rendered.
  final Medication medication;

  /// Cycle-day progress for [CourseType] medications; `null` for continuous
  /// medications (which have no bounded course window).
  final CourseProgress? progress;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppLocalizations l10n = context.l10n;

    if (medication.type is ContinuousType) {
      return _Pill(
        label: l10n.medsListTypeContinuous,
        background: cs.surfaceContainerHigh,
        foreground: cs.onSurfaceVariant,
      );
    }

    // CourseType: derive label and colors from progress phase. Defensive
    // null-guard (no `!`) — should not occur in practice.
    final CourseProgress? resolvedProgress = progress;
    if (resolvedProgress == null) return const SizedBox.shrink();

    return switch (resolvedProgress.phase) {
      CoursePhase.activeWindow => _Pill(
          label: l10n.medsListTypeCourseDay(
            resolvedProgress.currentDay,
            resolvedProgress.totalDays,
          ),
          background: cs.tertiaryContainer,
          foreground: cs.onTertiaryContainer,
        ),
      CoursePhase.paused => _Pill(
          label: l10n.medsListTypeCoursePaused,
          background: cs.surfaceContainerHigh,
          foreground: cs.onSurfaceVariant,
        ),
    };
  }
}

/// A small pill-shaped (stadium) label container used for the type chip.
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
