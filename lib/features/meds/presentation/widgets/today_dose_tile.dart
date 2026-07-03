/// Meds feature — display tile for a single Today-checklist dose row.
///
/// This library exports [TodayDoseTile], a dumb display widget that renders
/// one [TodayDose]: a rounded icon badge, the medication name, a
/// "HH:mm · dose" subtitle, and a status-dependent actions area (Take/Skip
/// while pending; a status label plus an optional Undo once taken/skipped).
/// It carries NO business logic and NO Riverpod provider access — the Today
/// screen (also in `meds`, spec 038 Task 015) supplies the three callbacks
/// and decides what they do.
library;

import 'package:flutter/material.dart';

import '../../domain/entities/intake_status.dart';
import '../../domain/entities/medication_form.dart';
import '../view_models/today_view_model.dart';
import 'medication_display.dart';
import 'medication_form_icon.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n_extensions.dart';

/// Renders a single [TodayDose] as a Today-checklist row.
///
/// Layout: a 48×48 rounded-square icon badge (resolved via
/// [medicationFormIcon]) → 16 px gap → body column (Expanded: medication name,
/// then a "HH:mm · dose" subtitle) → 16 px gap → a trailing actions area whose
/// contents depend on [TodayDose.status]:
///
/// * [IntakeStatus.pending] — a Skip affordance (`context.l10n.todaySkip`,
///   keyed `todaySkip`) and a Take affordance (`context.l10n.todayMarkTaken`,
///   keyed `todayTake`). Both are enabled regardless of the dose's scheduled
///   time relative to "now" — early marking is allowed, and there is
///   deliberately NO overdue styling: a past-time pending dose renders
///   identically to an upcoming one.
/// * [IntakeStatus.taken] / [IntakeStatus.skipped] — a localized status label
///   (`context.l10n.todayStatusTaken` / `todayStatusSkipped`), plus an Undo
///   affordance (`context.l10n.todayUndo`, keyed `todayUndo`) shown ONLY when
///   [TodayDose.undoable] is `true`.
/// * [IntakeStatus.missed] — reserved for a later feature (see
///   `IntakeStatus`'s dartdoc); not produced by `buildTodayView` in the
///   current slice, so it renders an empty trailing area.
///
/// This widget is pure display: it has no provider access and never imports
/// `data/`. All callbacks are supplied by the caller.
class TodayDoseTile extends StatelessWidget {
  /// Creates a [TodayDoseTile] for [dose].
  const TodayDoseTile({
    super.key,
    required this.dose,
    required this.onTaken,
    required this.onSkip,
    required this.onUndo,
  });

  /// The due dose to render, with its derived intake status.
  final TodayDose dose;

  /// Invoked when the user taps the Take affordance (pending doses only).
  final VoidCallback onTaken;

  /// Invoked when the user taps the Skip affordance (pending doses only).
  final VoidCallback onSkip;

  /// Invoked when the user taps the Undo affordance (shown only when
  /// [TodayDose.undoable] is `true`).
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _Badge(form: dose.dose.medication.form, colorScheme: cs),
          const SizedBox(width: 16),
          Expanded(child: _TileBody(dose: dose)),
          const SizedBox(width: 16),
          _Actions(
            dose: dose,
            onTaken: onTaken,
            onSkip: onSkip,
            onUndo: onUndo,
          ),
        ],
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

/// Renders the body column: medication name, then the "HH:mm · dose" subtitle.
class _TileBody extends StatelessWidget {
  const _TileBody({required this.dose});

  final TodayDose dose;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          dose.dose.medication.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tt.bodyLarge?.copyWith(color: cs.onSurface),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
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
    final AppLocalizations l10n = context.l10n;

    return switch (dose.status) {
      IntakeStatus.pending => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          OutlinedButton(
            key: const ValueKey<String>('todaySkip'),
            onPressed: onSkip,
            child: Text(l10n.todaySkip),
          ),
          const SizedBox(width: 8),
          FilledButton(
            key: const ValueKey<String>('todayTake'),
            onPressed: onTaken,
            child: Text(l10n.todayMarkTaken),
          ),
        ],
      ),
      IntakeStatus.taken => _ConfirmedActions(
        label: l10n.todayStatusTaken,
        undoable: dose.undoable,
        onUndo: onUndo,
      ),
      IntakeStatus.skipped => _ConfirmedActions(
        label: l10n.todayStatusSkipped,
        undoable: dose.undoable,
        onUndo: onUndo,
      ),
      // Reserved for a later feature (window-expiry auto-transition); never
      // produced by `buildTodayView` in the current slice. Render nothing
      // rather than inventing an unlocalized label for an unreachable state.
      IntakeStatus.missed => const SizedBox.shrink(),
    };
  }
}

/// Renders the taken/skipped status label plus an optional Undo affordance.
///
/// The Undo [TextButton] is included ONLY when [undoable] is `true` — this is
/// the sole gate for the Undo affordance's visibility (mirrors the
/// `TodayDose.undoable` grace-window rule computed in `today_view_model.dart`).
class _ConfirmedActions extends StatelessWidget {
  const _ConfirmedActions({
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
        Text(
          label,
          style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
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
