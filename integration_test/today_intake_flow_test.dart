/// On-device golden flow: add a medication, mark a dose taken on the Today
/// checklist, then undo it within the grace window.
///
/// Boots the real [AppBootstrap] widget tree against a hermetic temp-file
/// SQLite database (via [bootAppWithTempDb], so the debug seeder is disabled
/// and the DB starts empty). Drives the real add-medication modal (via the
/// shared [addMedication] driver) to add `medFixtures.first` — a continuous
/// Tablet with two intake times (08:00 and 20:00) — then switches to the
/// Today tab and exercises the Take/Undo affordances on [TodayDoseTile].
///
/// Deliberately avoids `pumpAndSettle` immediately after tapping Take/Undo:
/// marking a dose taken schedules a one-shot 5-minute grace [Timer]
/// (`TodayScreen._scheduleGraceRefresh`), and `pumpAndSettle` would pump
/// frames until nothing is scheduled — safe here since a dormant Timer does
/// not itself request a frame, but bounded `pump(Duration)` calls are used
/// instead per the terminal-gate task's guidance, and the flow ends with an
/// Undo so no grace Timer is left pending when the test completes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'support/add_medication_driver.dart';
import 'support/app_harness.dart';
import 'support/medication_fixtures.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('add medication, mark dose taken on Today, then undo', (
    tester,
  ) async {
    // 1. Boot the app against a fresh hermetic temp-file DB (no dev seed).
    await bootAppWithTempDb(tester);

    // 2. Add a continuous medication with two intake times via the Meds tab
    //    + add modal (mirrors add_medication_golden_test.dart).
    final fixture = medFixtures.first; // ITTablet: continuous, 08:00 & 20:00.
    await addMedication(tester, fixture);

    // 3. Switch to the Today tab.
    await tester.tap(find.byIcon(LucideIcons.house));
    await tester.pumpAndSettle();

    // 4. Both intake-time slots for the newly-added continuous medication
    //    should appear as pending doses today.
    expect(find.text(fixture.name), findsNWidgets(2));
    expect(find.byKey(const ValueKey<String>('todayTake')), findsNWidgets(2));

    // 5. Mark the first dose taken. Avoid pumpAndSettle: this schedules the
    //    5-minute grace Timer; use bounded pumps to let the async use case +
    //    reactive stream settle instead.
    await tester.tap(find.byKey(const ValueKey<String>('todayTake')).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // 6. One dose is now taken (its tile shows Undo instead of Take/Skip);
    //    the other remains pending.
    expect(find.byKey(const ValueKey<String>('todayTake')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('todayUndo')), findsOneWidget);

    // 7. Undo within the grace window — reverts to pending and cancels the
    //    grace Timer, so nothing is left pending at test teardown.
    await tester.tap(find.byKey(const ValueKey<String>('todayUndo')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey<String>('todayTake')), findsNWidgets(2));
    expect(find.byKey(const ValueKey<String>('todayUndo')), findsNothing);
  });
}
