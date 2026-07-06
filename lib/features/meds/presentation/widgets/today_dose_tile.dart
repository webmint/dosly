/// Meds feature — display tile for a single Today-checklist dose row.
///
/// This library exports [TodayDoseTile], a dumb display widget that renders
/// one [TodayDose]: a rounded icon badge, a body column (medication name,
/// "HH:mm · dose" subtitle, a continuous/course type chip, and an inline
/// low-stock warning when applicable), and a trailing Material 3 checkbox
/// interaction area. It carries NO business logic and NO Riverpod provider
/// access — the Today screen (`meds/presentation/screens/today_screen.dart`)
/// supplies the three callbacks and decides what they do.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/entities/intake_status.dart';
import '../../domain/entities/medication_form.dart';
import '../../domain/entities/medication_type.dart';
import '../../domain/value_objects/course_progress.dart';
import '../view_models/today_view_model.dart';
import 'med_type_chip.dart';
import 'medication_display.dart';
import 'medication_form_icon.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n_extensions.dart';

/// Renders a single [TodayDose] as a Today-checklist row.
///
/// Layout: a 48×48 rounded-square icon badge (resolved via
/// [medicationFormIcon]) → 16 px gap → body column (Expanded: medication
/// name, "HH:mm · dose" subtitle, then a chip row with the continuous/course
/// [MedTypeChip] and an optional inline low-stock warning) → 16 px gap → a
/// trailing checkbox-based actions area whose contents depend on
/// [TodayDose.status]:
///
/// * [IntakeStatus.pending] — a secondary skip [IconButton] (Lucide
///   `skipForward`, keyed `todaySkipIcon`) shown ONLY when
///   [TodayDose.actionable], plus a primary [Checkbox] (keyed
///   `todayCheckbox`, unchecked) that confirms the dose when tapped. The
///   checkbox is disabled (greyed) when the dose is not yet [TodayDose.actionable]
///   — e.g. a future slot with mark-ahead disabled.
/// * [IntakeStatus.taken] — a checked [Checkbox] (keyed `todayCheckbox`) that
///   reverts the confirmation via Undo when tapped, enabled only while
///   [TodayDose.undoable] is `true` (locked/greyed once the grace window
///   elapses). The medication name renders with a line-through and
///   [ColorScheme.onSurfaceVariant] tone to read as "done."
/// * [IntakeStatus.skipped] — a disabled, unchecked [Checkbox] plus the
///   localized `todayStatusSkipped` label, with an Undo [TextButton] (keyed
///   `todayUndo`) shown ONLY when [TodayDose.undoable] is `true`.
/// * [IntakeStatus.missed] — a localized, error-toned status label
///   (`context.l10n.todayStatusMissed`) with NO checkbox or actions. This
///   status is written by the auto-miss reconcile engine (spec 040,
///   `ReconcileMissedIntakes`) once a dose's intake window elapses without
///   action; it is locked in this slice — correcting a missed dose is the
///   out-of-scope Manual-Correction flow.
///
/// A pending, not-yet-[TodayDose.actionable] dose whose [TodayDose.windowState]
/// is [DoseWindowState.future] (the mark-ahead-disabled "future slot" look)
/// renders the whole tile at reduced opacity (0.55) — there is deliberately
/// NO equivalent dimming for a past-due (`pastWindow`) dose, preserving the
/// "no overdue styling" rule from spec 040.
///
/// This widget is pure display: it has no provider access and never imports
/// `data/`. All callbacks are supplied by the caller.
class TodayDoseTile extends StatelessWidget {
  /// Creates a [TodayDoseTile] for [dose], resolving course progress as of
  /// [now].
  const TodayDoseTile({
    super.key,
    required this.dose,
    required this.now,
    required this.onTaken,
    required this.onSkip,
    required this.onUndo,
  });

  /// The due dose to render, with its derived intake status.
  final TodayDose dose;

  /// The build instant, used to resolve [CourseProgress] for course
  /// medications (continuous medications ignore it).
  final DateTime now;

  /// Invoked when the user checks the box to confirm a pending dose (pending
  /// doses only).
  final VoidCallback onTaken;

  /// Invoked when the user taps the secondary Skip affordance (pending doses
  /// only).
  final VoidCallback onSkip;

  /// Invoked when the user taps the Undo affordance (shown only when
  /// [TodayDose.undoable] is `true`).
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    final bool dimmed =
        dose.status == IntakeStatus.pending &&
        !dose.actionable &&
        dose.windowState == DoseWindowState.future;

    return Opacity(
      opacity: dimmed ? 0.55 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _Badge(form: dose.dose.medication.form, colorScheme: cs),
            const SizedBox(width: 16),
            Expanded(child: _TileBody(dose: dose, now: now)),
            const SizedBox(width: 16),
            _Actions(
              dose: dose,
              onTaken: onTaken,
              onSkip: onSkip,
              onUndo: onUndo,
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders the leading 48×48 rounded-square icon badge for [form].
///
/// Mirrors the meds-list tile's badge treatment, using a fixed
/// primary-container tint — the Today checklist has no completed/active
/// distinction to color-code (that is a `meds`-list concept).
class _Badge extends StatelessWidget {
  const _Badge({required this.form, required this.colorScheme});

  final MedicationForm form;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        medicationFormIcon(form),
        size: 26,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }
}

/// Renders the body column: medication name, "HH:mm · dose" subtitle, and the
/// chip row (continuous/course type chip + optional low-stock warning).
class _TileBody extends StatelessWidget {
  const _TileBody({required this.dose, required this.now});

  final TodayDose dose;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;
    final AppLocalizations l10n = context.l10n;

    final TimeOfDay timeOfDay = TimeOfDay(
      hour: dose.dose.slot.minuteOfDay ~/ 60,
      minute: dose.dose.slot.minuteOfDay % 60,
    );
    final String timeStr = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(timeOfDay, alwaysUse24HourFormat: true);
    final String? doseStr = formatDose(dose.dose.effectiveDose, l10n);
    final String subtitle = doseStr == null ? timeStr : '$timeStr · $doseStr';

    final bool isTaken = dose.status == IntakeStatus.taken;

    final MedicationType type = dose.dose.medication.type;
    final CourseProgress? progress = type is CourseType
        ? CourseProgress.resolve(course: type, now: now)
        : null;

    final String? lowStockText = isLowStock(dose.dose.medication.stock)
        ? formatStock(dose.dose.medication.stock, l10n)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          dose.dose.medication.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tt.bodyLarge?.copyWith(
            color: isTaken ? cs.onSurfaceVariant : cs.onSurface,
            decoration: isTaken
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            MedTypeChip(medication: dose.dose.medication, progress: progress),
            if (lowStockText != null)
              Text(
                lowStockText,
                style:
                    tt.labelSmall?.copyWith(
                      color: cs.error,
                      fontWeight: FontWeight.w700,
                    ) ??
                    TextStyle(color: cs.error, fontWeight: FontWeight.w700),
              ),
          ],
        ),
      ],
    );
  }
}

/// Renders the trailing actions area, dispatching on [TodayDose.status].
///
/// Exhaustive `switch` over [IntakeStatus] (no `default:`) so the compiler
/// flags any new status value added later.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.dose,
    required this.onTaken,
    required this.onSkip,
    required this.onUndo,
  });

  final TodayDose dose;
  final VoidCallback onTaken;
  final VoidCallback onSkip;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;
    final AppLocalizations l10n = context.l10n;

    return switch (dose.status) {
      IntakeStatus.pending => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (dose.actionable)
            IconButton(
              key: const ValueKey<String>('todaySkipIcon'),
              tooltip: l10n.todaySkip,
              onPressed: onSkip,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: const Icon(LucideIcons.skipForward),
            ),
          Checkbox(
            key: const ValueKey<String>('todayCheckbox'),
            value: false,
            onChanged: dose.actionable ? (bool? _) => onTaken() : null,
          ),
        ],
      ),
      IntakeStatus.taken => Checkbox(
        key: const ValueKey<String>('todayCheckbox'),
        value: true,
        onChanged: dose.undoable ? (bool? _) => onUndo() : null,
      ),
      IntakeStatus.skipped => _SkippedActions(
        label: l10n.todayStatusSkipped,
        undoable: dose.undoable,
        onUndo: onUndo,
      ),
      // Written by the auto-miss reconcile engine (spec 040,
      // `ReconcileMissedIntakes`) once a dose's intake window elapses
      // without action. Intentionally action-free: a missed dose is locked
      // in this slice — no checkbox/skip/undo — correction is the separate,
      // out-of-scope Manual-Correction flow. Rendered in the error color to
      // distinguish it from the neutral taken/skipped labels.
      IntakeStatus.missed => Text(
        l10n.todayStatusMissed,
        style: tt.labelMedium?.copyWith(color: cs.error),
      ),
    };
  }
}

/// Renders the skipped state's disabled checkbox + status label, plus an
/// optional Undo affordance.
///
/// The Undo [TextButton] is included ONLY when [undoable] is `true` — this is
/// the sole gate for the Undo affordance's visibility (mirrors the
/// `TodayDose.undoable` grace-window rule computed in `today_view_model.dart`).
class _SkippedActions extends StatelessWidget {
  const _SkippedActions({
    required this.label,
    required this.undoable,
    required this.onUndo,
  });

  final String label;
  final bool undoable;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Checkbox(
              key: ValueKey<String>('todayCheckbox'),
              value: false,
              onChanged: null,
            ),
            Text(
              label,
              style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
        if (undoable) ...<Widget>[
          const SizedBox(height: 4),
          TextButton(
            key: const ValueKey<String>('todayUndo'),
            onPressed: onUndo,
            child: Text(context.l10n.todayUndo),
          ),
        ],
      ],
    );
  }
}
