/// Meds feature — "next intake" countdown card for the Today screen.
///
/// This library exports [TodayCountdownCard], a dumb primary-container card
/// that renders the countdown to the next scheduled dose ("Next intake" +
/// "in Xh Ym · HH:mm"), or [AppLocalizations.todayAllDone] when there is no
/// upcoming dose left today. It carries NO business logic and NO Riverpod
/// provider access — the Today screen resolves the next scheduled instant
/// (and drives the periodic rebuild via its own timer) and supplies both
/// [TodayCountdownCard.nextScheduledAt] and [TodayCountdownCard.now] directly.
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n_extensions.dart';

/// Renders the Today screen's next-intake countdown card.
///
/// A rounded (16 px radius) `primaryContainer`-tinted card with a leading
/// clock icon, keyed `todayCountdownCard`. Two render branches:
///
/// * [nextScheduledAt] is `null` — no dose remains today; renders
///   [AppLocalizations.todayAllDone] as a single line.
/// * [nextScheduledAt] is non-null — renders [AppLocalizations.todayNextIntakeLabel]
///   as a small label above the countdown value. The countdown is
///   [AppLocalizations.todayNextIntakeInMinutes] when under an hour remains, or
///   [AppLocalizations.todayNextIntakeIn] otherwise, followed by the target's
///   local `HH:mm` time (e.g. "in 2h 15m · 14:30"). A negative remaining
///   duration (the target instant has already passed but the caller has not
///   yet refreshed [nextScheduledAt]) clamps to zero rather than showing a
///   negative countdown.
///
/// This widget is pure display: it takes no provider access and never
/// imports `data/`. Periodic re-render (e.g. a per-minute timer) is the
/// Today screen's responsibility, not this widget's.
class TodayCountdownCard extends StatelessWidget {
  /// Creates a [TodayCountdownCard] for [nextScheduledAt] relative to [now].
  const TodayCountdownCard({
    super.key,
    required this.nextScheduledAt,
    required this.now,
  });

  /// The scheduled instant of the next upcoming dose, or `null` when no dose
  /// remains due today.
  final DateTime? nextScheduledAt;

  /// The instant the countdown is computed relative to.
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;
    final AppLocalizations l10n = context.l10n;
    final DateTime? target = nextScheduledAt;

    return Container(
      key: const ValueKey<String>('todayCountdownCard'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(LucideIcons.clock, color: cs.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: target == null
                ? Text(
                    l10n.todayAllDone,
                    style: tt.titleMedium?.copyWith(
                      color: cs.onPrimaryContainer,
                    ),
                  )
                : _Countdown(target: target, now: now),
          ),
        ],
      ),
    );
  }
}

/// Renders the label + "in Xh Ym · HH:mm" countdown value for a non-null
/// next-intake target.
class _Countdown extends StatelessWidget {
  const _Countdown({required this.target, required this.now});

  final DateTime target;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;
    final AppLocalizations l10n = context.l10n;

    final Duration remaining = target.difference(now);
    final Duration r = remaining.isNegative ? Duration.zero : remaining;
    final int h = r.inHours;
    final int m = r.inMinutes % 60;
    final String countdownText = h == 0
        ? l10n.todayNextIntakeInMinutes(m)
        : l10n.todayNextIntakeIn(h, m);
    final String timeText = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(target.toLocal()),
      alwaysUse24HourFormat: true,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Opacity(
          opacity: 0.85,
          child: Text(
            l10n.todayNextIntakeLabel,
            style: tt.bodySmall?.copyWith(color: cs.onPrimaryContainer),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$countdownText · $timeText',
          style: tt.titleMedium?.copyWith(color: cs.onPrimaryContainer),
        ),
      ],
    );
  }
}
