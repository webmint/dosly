/// On-device golden flow: add a medication, mark a dose taken on the Today
/// checklist (checkbox model), then undo it within the grace window.
///
/// Boots the real [AppBootstrap] widget tree against a hermetic temp-file
/// SQLite database (via [bootAppWithTempDb], so the debug seeder is disabled
/// and the DB starts empty). Drives the real add-medication modal (via the
/// shared [addMedication] driver) to add `medFixtures.first` — a continuous
/// Tablet with two intake times (08:00 and 20:00) — then switches to the
/// Today tab and exercises the checkbox affordance on [TodayDoseTile], nested
/// inside its `TodayGroupSection` hour group.
///
/// The whole flow runs inside a fixed [Clock] (`2026-06-15 08:30` local),
/// pinned via [withClock]. Both the add-medication modal's `startDate` stamp
/// and the Today screen's `now` are read from `clock.now()` (never raw
/// `DateTime.now()`), so pinning the clock makes the flow fully deterministic
/// regardless of the real wall-clock time the suite happens to run at: the
/// 08:00 slot's default 120-minute window (08:00-10:00) is OPEN at 08:30 — its
/// hour group is `TodayGroupState.now` and starts EXPANDED — while the 20:00
/// slot is still `DoseWindowState.future` — its hour group starts collapsed
/// and is never expanded by this flow.
///
/// Deliberately avoids `pumpAndSettle` immediately after tapping the checkbox:
/// marking a dose taken (re)schedules the Today screen's one-shot
/// boundary-refresh `Timer` (`TodayScreen._scheduleNextBoundaryRefresh`, here
/// firing at the 5-minute grace expiry), and `pumpAndSettle` would pump frames
/// until nothing is scheduled — safe here since a dormant Timer does not
/// itself request a frame, but bounded `pump(Duration)` calls are used
/// instead per the terminal-gate task's guidance, and the flow ends with an
/// undo so no boundary Timer outcome is left unobserved when the test
/// completes.
library;

import 'package:clock/clock.dart';
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
    final Clock fixedClock = Clock.fixed(DateTime(2026, 6, 15, 8, 30));

    await withClock(fixedClock, () async {
      // 1. Boot the app against a fresh hermetic temp-file DB (no dev seed).
      await bootAppWithTempDb(tester);

      // 2. Add a continuous medication with two intake times via the Meds tab
      //    + add modal (mirrors add_medication_golden_test.dart).
      final fixture = medFixtures.first; // ITTablet: continuous, 08:00 & 20:00.
      await addMedication(tester, fixture);

      // 3. Switch to the Today tab.
      await tester.tap(find.byIcon(LucideIcons.house));
      await tester.pumpAndSettle();

      // 4. The 08:00 dose is due "now" (open window) — its hour group starts
      //    expanded, so its tile and checkbox render immediately. The 20:00
      //    dose is `future` — its hour group starts collapsed, so its tile is
      //    not yet in the tree (no need to expand it for this flow).
      expect(find.text(fixture.name), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('todayCheckbox')),
        findsOneWidget,
      );

      // 5. Check the box: marks the 08:00 dose taken. Avoid pumpAndSettle:
      //    this reschedules the boundary-refresh Timer; use bounded pumps to
      //    let the async use case + reactive stream settle instead.
      await tester.tap(find.byKey(const ValueKey<String>('todayCheckbox')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // 6. The dose is now taken: the checkbox renders checked and stays
      //    enabled — undoable within its 5-minute grace window.
      Checkbox checkbox = tester.widget<Checkbox>(
        find.byKey(const ValueKey<String>('todayCheckbox')),
      );
      expect(checkbox.value, isTrue);
      expect(checkbox.onChanged, isNotNull);

      // 7. Uncheck within the grace window — reverts to pending. A taken
      //    dose's undo path reuses the checkbox itself (unlike a skipped
      //    dose, which exposes a separate `todayUndo` button).
      await tester.tap(find.byKey(const ValueKey<String>('todayCheckbox')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      checkbox = tester.widget<Checkbox>(
        find.byKey(const ValueKey<String>('todayCheckbox')),
      );
      expect(checkbox.value, isFalse);
      expect(
        find.byKey(const ValueKey<String>('todayUndo')),
        findsNothing,
        reason: 'The undone dose is pending again — no skip-Undo button.',
      );
    });
  });
}
