/// Meds feature — collapsible per-hour group section for the Today screen.
///
/// This library exports [TodayGroupSection], a widget that renders one
/// [TodayHourGroup] as a collapsible card: a filled, tappable header (hour
/// label, a [TodayGroupState] badge, a dose-count sub-label, and a rotating
/// chevron) over a tinted body of [TodayDoseTile]s plus an optional Mark-all
/// button. The widget is named `TodayGroupSection` — not
/// `TodayHourGroupSection` — to avoid colliding with the view-model class
/// [TodayHourGroup] it renders.
///
/// Collapse state is ephemeral [State] seeded from [TodayGroupSection.initiallyExpanded]
/// on first build; it is NOT persisted or hoisted to a provider. This widget
/// carries no business logic and no Riverpod provider access — the Today
/// screen supplies the group, the callbacks, and decides what they do
/// (including any timer-driven reconciliation, which is out of scope here).
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../view_models/today_view_model.dart';
import 'today_dose_tile.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n_extensions.dart';

/// Renders one [TodayHourGroup] as a collapsible Today-screen card.
///
/// Layout:
/// * A rounded, clipped card. Every group shares the same chrome — a
///   uniform `surfaceContainerLow` header and a uniformly tinted body — the
///   [TodayHourGroup.state] is surfaced ONLY via the header's state badge,
///   never via distinct card chrome.
/// * A filled, tappable header showing the wall-clock hour as `HH:00`, a
///   state badge switching on [TodayHourGroup.state] ([TodayGroupState.now]
///   → primary "Now" pill; [TodayGroupState.future] → neutral "Future" pill;
///   [TodayGroupState.past] → neutral "✓ taken/total" pill), a muted
///   dose-count sub-label, and a chevron that rotates -90° when the section
///   is collapsed.
/// * A tinted body — rendered only while expanded — of one [TodayDoseTile]
///   per [TodayHourGroup.doses], followed by a Mark-all
///   [FilledButton.tonalIcon] shown ONLY when
///   [TodayHourGroup.hasActionablePending] is `true`.
///
/// Collapse state lives in local [State], seeded once from
/// [initiallyExpanded]; tapping the header toggles it. This widget is pure
/// display: it never imports `data/` and takes no provider access — all data
/// and callbacks are supplied by the caller.
class TodayGroupSection extends StatefulWidget {
  /// Creates a [TodayGroupSection] for [group], collapsed/expanded per
  /// [initiallyExpanded] on first build.
  const TodayGroupSection({
    super.key,
    required this.group,
    required this.initiallyExpanded,
    required this.now,
    required this.onTaken,
    required this.onSkip,
    required this.onUndo,
    required this.onMarkAll,
  });

  /// The hour group this section renders.
  final TodayHourGroup group;

  /// Whether the section starts expanded. Seeds the ephemeral collapse state
  /// on first build only — later changes to this value do not affect an
  /// already-mounted section.
  final bool initiallyExpanded;

  /// The build instant, forwarded to each [TodayDoseTile] to resolve course
  /// progress.
  final DateTime now;

  /// Invoked with the tapped [TodayDose] when its checkbox confirms a
  /// pending dose.
  final void Function(TodayDose dose) onTaken;

  /// Invoked with the tapped [TodayDose] when its skip affordance is used.
  final void Function(TodayDose dose) onSkip;

  /// Invoked with the tapped [TodayDose] when its undo affordance is used.
  final void Function(TodayDose dose) onUndo;

  /// Invoked when the Mark-all button is tapped. Shown only when
  /// [TodayHourGroup.hasActionablePending] is `true`.
  final VoidCallback onMarkAll;

  @override
  State<TodayGroupSection> createState() => _TodayGroupSectionState();
}

class _TodayGroupSectionState extends State<TodayGroupSection> {
  late bool _expanded = widget.initiallyExpanded;

  void _toggleExpanded() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final TodayHourGroup group = widget.group;

    return Container(
      key: ValueKey<String>('todayGroupSection-${group.hour}'),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _Header(group: group, expanded: _expanded, onTap: _toggleExpanded),
            if (_expanded)
              _Body(
                group: group,
                now: widget.now,
                onTaken: widget.onTaken,
                onSkip: widget.onSkip,
                onUndo: widget.onUndo,
                onMarkAll: widget.onMarkAll,
              ),
          ],
        ),
      ),
    );
  }
}

/// Renders the tappable section header: hour label, state badge, dose-count
/// sub-label, and rotating chevron.
class _Header extends StatelessWidget {
  const _Header({
    required this.group,
    required this.expanded,
    required this.onTap,
  });

  final TodayHourGroup group;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;
    final AppLocalizations l10n = context.l10n;

    final String hourLabel = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: group.hour, minute: 0),
      alwaysUse24HourFormat: true,
    );

    return Material(
      color: cs.surfaceContainerLow,
      child: InkWell(
        key: ValueKey<String>('todayGroupHeader-${group.hour}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(hourLabel, style: tt.titleSmall),
              const SizedBox(width: 8),
              _GroupBadge(group: group),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.todayGroupDoseCount(group.total),
                  textAlign: TextAlign.end,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: expanded ? 0 : -0.25,
                duration: const Duration(milliseconds: 200),
                child: Icon(LucideIcons.chevronDown, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders the header's state badge, switching exhaustively on
/// [TodayHourGroup.state] (no `default:`, so a new [TodayGroupState] value
/// fails to compile here until handled).
class _GroupBadge extends StatelessWidget {
  const _GroupBadge({required this.group});

  final TodayHourGroup group;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppLocalizations l10n = context.l10n;

    switch (group.state) {
      case TodayGroupState.now:
        return _Pill(
          label: l10n.todayGroupBadgeNow,
          background: cs.primary,
          foreground: cs.onPrimary,
        );
      case TodayGroupState.future:
        return _Pill(
          label: l10n.todayGroupBadgeFuture,
          background: cs.surfaceContainerHighest,
          foreground: cs.onSurfaceVariant,
        );
      case TodayGroupState.past:
        return _Pill(
          label: l10n.todayGroupTakenCount(group.takenCount, group.total),
          background: cs.surfaceContainerHighest,
          foreground: cs.onSurfaceVariant,
          leadingIcon: LucideIcons.check,
        );
    }
  }
}

/// A small stadium-pill label used for the header's state badge, with an
/// optional leading icon (used by the [TodayGroupState.past] "✓ N/M" badge).
class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
    this.leadingIcon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final TextTheme tt = Theme.of(context).textTheme;
    final IconData? icon = leadingIcon;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style:
                tt.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w500,
                ) ??
                TextStyle(color: foreground, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// Renders the section body: one [TodayDoseTile] per [TodayHourGroup.doses],
/// then a Mark-all button gated on [TodayHourGroup.hasActionablePending].
class _Body extends StatelessWidget {
  const _Body({
    required this.group,
    required this.now,
    required this.onTaken,
    required this.onSkip,
    required this.onUndo,
    required this.onMarkAll,
  });

  final TodayHourGroup group;
  final DateTime now;
  final void Function(TodayDose dose) onTaken;
  final void Function(TodayDose dose) onSkip;
  final void Function(TodayDose dose) onUndo;
  final VoidCallback onMarkAll;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppLocalizations l10n = context.l10n;
    final Color bodyBg =
        Color.lerp(cs.surface, cs.surfaceContainer, 0.15) ?? cs.surfaceContainer;

    return Container(
      color: bodyBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final TodayDose d in group.doses)
            TodayDoseTile(
              key: ValueKey<String>(
                'todayTile-${d.dose.medication.id.value}-${d.dose.slot.id.value}',
              ),
              dose: d,
              now: now,
              onTaken: () => onTaken(d),
              onSkip: () => onSkip(d),
              onUndo: () => onUndo(d),
            ),
          if (group.hasActionablePending)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  key: const ValueKey<String>('todayMarkAll'),
                  onPressed: onMarkAll,
                  icon: const Icon(LucideIcons.check, size: 18),
                  label: Text(l10n.todayMarkAllInGroup),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
