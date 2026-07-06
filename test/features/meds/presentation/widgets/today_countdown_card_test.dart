/// Widget tests for [TodayCountdownCard] — the Today screen's primary
/// -container next-intake countdown card.
///
/// Each test pumps a single [TodayCountdownCard] inside a minimal localized
/// [MaterialApp]. No providers or `ProviderScope` are involved —
/// [TodayCountdownCard] is a dumb display widget that receives its target
/// instant and "now" directly via constructor parameters.
library;

import 'package:dosly/features/meds/presentation/widgets/today_countdown_card.dart';
import 'package:dosly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixed "now" reused across tests.
final _fixedNow = DateTime.utc(2026, 6, 20, 8, 0);

/// Wraps a single [TodayCountdownCard] in a localized [MaterialApp].
Widget _harness({required DateTime? nextScheduledAt, DateTime? now}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: TodayCountdownCard(
        nextScheduledAt: nextScheduledAt,
        now: now ?? _fixedNow,
      ),
    ),
  );
}

void main() {
  testWidgets(
    'shows the hours+minutes countdown, the local HH:mm time, and the '
    '"Next intake" label when the next dose is 2h15m away',
    (tester) async {
      final DateTime target = _fixedNow.add(
        const Duration(hours: 2, minutes: 15),
      );

      await tester.pumpWidget(_harness(nextScheduledAt: target));
      await tester.pumpAndSettle();

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(TodayCountdownCard)),
      )!;

      expect(find.text(l10n.todayNextIntakeLabel), findsOneWidget);

      final String timeText = MaterialLocalizations.of(
        tester.element(find.byType(TodayCountdownCard)),
      ).formatTimeOfDay(
        TimeOfDay.fromDateTime(target.toLocal()),
        alwaysUse24HourFormat: true,
      );
      expect(
        find.text('${l10n.todayNextIntakeIn(2, 15)} · $timeText'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows the minutes-only countdown variant when the next dose is 40 '
    'minutes away',
    (tester) async {
      final DateTime target = _fixedNow.add(const Duration(minutes: 40));

      await tester.pumpWidget(_harness(nextScheduledAt: target));
      await tester.pumpAndSettle();

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(TodayCountdownCard)),
      )!;

      final String timeText = MaterialLocalizations.of(
        tester.element(find.byType(TodayCountdownCard)),
      ).formatTimeOfDay(
        TimeOfDay.fromDateTime(target.toLocal()),
        alwaysUse24HourFormat: true,
      );
      expect(
        find.text('${l10n.todayNextIntakeInMinutes(40)} · $timeText'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'shows the "All done for today" message and no countdown text when '
    'nextScheduledAt is null',
    (tester) async {
      await tester.pumpWidget(_harness(nextScheduledAt: null));
      await tester.pumpAndSettle();

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(TodayCountdownCard)),
      )!;

      expect(find.text(l10n.todayAllDone), findsOneWidget);
      expect(find.text(l10n.todayNextIntakeLabel), findsNothing);
      expect(find.textContaining('·'), findsNothing);
    },
  );
}
