/// Widget tests for [TodayGroupSection] — the collapsible per-hour group
/// header (state badge per [TodayGroupState], the "now"-only left-border
/// accent, the rotating chevron), the collapse/expand toggle seeded from
/// `initiallyExpanded`, and the Mark-all button's gate on
/// [TodayHourGroup.hasActionablePending] (both branches, per task 005's
/// review note that this getter was previously untested).
///
/// Each test pumps a single [TodayGroupSection] inside a minimal localized
/// [MaterialApp]. No providers or `ProviderScope` are involved —
/// [TodayGroupSection] is a dumb display widget that receives a
/// `TodayHourGroup` directly and reports interaction via constructor
/// callbacks.
library;

import 'package:dosly/features/meds/domain/entities/dosage.dart';
import 'package:dosly/features/meds/domain/entities/dose_unit.dart';
import 'package:dosly/features/meds/domain/entities/intake_status.dart';
import 'package:dosly/features/meds/domain/entities/medication.dart';
import 'package:dosly/features/meds/domain/entities/medication_form.dart';
import 'package:dosly/features/meds/domain/entities/medication_type.dart';
import 'package:dosly/features/meds/domain/entities/schedule.dart';
import 'package:dosly/features/meds/domain/entities/time_slot.dart';
import 'package:dosly/features/meds/domain/value_objects/due_dose.dart';
import 'package:dosly/features/meds/domain/value_objects/intake_id.dart';
import 'package:dosly/features/meds/domain/value_objects/medication_id.dart';
import 'package:dosly/features/meds/domain/value_objects/time_slot_id.dart';
import 'package:dosly/features/meds/presentation/view_models/today_view_model.dart';
import 'package:dosly/features/meds/presentation/widgets/today_dose_tile.dart';
import 'package:dosly/features/meds/presentation/widgets/today_group_section.dart';
import 'package:dosly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Domain fixtures
// ---------------------------------------------------------------------------

/// Fixed "now" reused across tests.
final _fixedNow = DateTime.utc(2026, 6, 20, 8, 30);

Medication _medication({required String id, required String slotId}) =>
    Medication(
      id: MedicationId(id),
      name: 'Med-$id',
      form: MedicationForm.tablet,
      type: MedicationType.continuous(startDate: DateTime.utc(2026, 1, 1)),
      schedule: Schedule(slots: [TimeSlot(id: TimeSlotId(slotId), minuteOfDay: 480)]),
      dosePerIntake: const Dosage(amount: 100.0, unit: DoseUnit.mg),
      stock: null,
      notes: null,
      createdAt: DateTime.utc(2026, 1, 1),
    );

DueDose _dueDose(Medication medication) => DueDose(
  medication: medication,
  slot: medication.schedule.slots.first,
  effectiveDose: medication.dosePerIntake,
  scheduledAt: DateTime.utc(2026, 6, 20, 8),
);

final _medA = _medication(id: 'grp-med-a', slotId: 'grp-slot-a');
final _medB = _medication(id: 'grp-med-b', slotId: 'grp-slot-b');
final _dueDoseA = _dueDose(_medA);
final _dueDoseB = _dueDose(_medB);

/// A single-dose group, all doses [DoseWindowState.future] and NOT
/// actionable — [TodayGroupState.future], no Mark-all.
TodayHourGroup _futureGroup() {
  final TodayDose dose = TodayDose(
    dose: _dueDoseA,
    status: IntakeStatus.pending,
    confirmedAt: null,
    undoable: false,
    intakeId: null,
    windowState: DoseWindowState.future,
    actionable: false,
  );
  return TodayHourGroup(
    hour: 8,
    doses: [dose],
    state: TodayGroupState.future,
    takenCount: 0,
  );
}

/// A single-dose group with an actionable pending dose in its intake window —
/// [TodayGroupState.now], Mark-all shown.
TodayHourGroup _nowGroupActionable() {
  final TodayDose dose = TodayDose(
    dose: _dueDoseA,
    status: IntakeStatus.pending,
    confirmedAt: null,
    undoable: false,
    intakeId: null,
    windowState: DoseWindowState.open,
    actionable: true,
  );
  return TodayHourGroup(
    hour: 8,
    doses: [dose],
    state: TodayGroupState.now,
    takenCount: 0,
  );
}

/// A two-dose group, all doses past their window and already resolved (one
/// taken, one skipped) — [TodayGroupState.past], no actionable pending dose,
/// so no Mark-all.
TodayHourGroup _pastGroupResolved() {
  final TodayDose taken = TodayDose(
    dose: _dueDoseA,
    status: IntakeStatus.taken,
    confirmedAt: DateTime.utc(2026, 6, 20, 8, 1),
    undoable: false,
    intakeId: const IntakeId('grp-intake-taken'),
    windowState: DoseWindowState.pastWindow,
    actionable: false,
  );
  final TodayDose skipped = TodayDose(
    dose: _dueDoseB,
    status: IntakeStatus.skipped,
    confirmedAt: DateTime.utc(2026, 6, 20, 8, 2),
    undoable: false,
    intakeId: const IntakeId('grp-intake-skipped'),
    windowState: DoseWindowState.pastWindow,
    actionable: false,
  );
  return TodayHourGroup(
    hour: 8,
    doses: [taken, skipped],
    state: TodayGroupState.past,
    takenCount: 1,
  );
}

// ---------------------------------------------------------------------------
// Test harness
// ---------------------------------------------------------------------------

const _markAllKey = ValueKey<String>('todayMarkAll');

/// Wraps a single [TodayGroupSection] in a localized [MaterialApp].
Widget _harness(
  TodayHourGroup group, {
  bool initiallyExpanded = true,
  DateTime? now,
  void Function(TodayDose dose)? onTaken,
  void Function(TodayDose dose)? onSkip,
  void Function(TodayDose dose)? onUndo,
  VoidCallback? onMarkAll,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: TodayGroupSection(
        group: group,
        initiallyExpanded: initiallyExpanded,
        now: now ?? _fixedNow,
        onTaken: onTaken ?? (_) {},
        onSkip: onSkip ?? (_) {},
        onUndo: onUndo ?? (_) {},
        onMarkAll: onMarkAll ?? () {},
      ),
    ),
  );
}

ValueKey<String> _headerKey(TodayHourGroup group) =>
    ValueKey<String>('todayGroupHeader-${group.hour}');

ValueKey<String> _sectionKey(TodayHourGroup group) =>
    ValueKey<String>('todayGroupSection-${group.hour}');

void main() {
  group('TodayGroupSection badge', () {
    testWidgets('now group shows the "Now" badge', (tester) async {
      await tester.pumpWidget(_harness(_nowGroupActionable()));
      await tester.pumpAndSettle();

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(TodayGroupSection)),
      )!;
      expect(find.text(l10n.todayGroupBadgeNow), findsOneWidget);
    });

    testWidgets('future group shows the "Future" badge', (tester) async {
      await tester.pumpWidget(_harness(_futureGroup()));
      await tester.pumpAndSettle();

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(TodayGroupSection)),
      )!;
      expect(find.text(l10n.todayGroupBadgeFuture), findsOneWidget);
    });

    testWidgets('past group shows the taken-count badge ("1/2")', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(_pastGroupResolved()));
      await tester.pumpAndSettle();

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(TodayGroupSection)),
      )!;
      expect(find.text(l10n.todayGroupTakenCount(1, 2)), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
    });
  });

  group('TodayGroupSection left-border accent', () {
    testWidgets('present for a "now" group', (tester) async {
      final TodayHourGroup group = _nowGroupActionable();
      await tester.pumpWidget(_harness(group));
      await tester.pumpAndSettle();

      final Container container = tester.widget<Container>(
        find.byKey(_sectionKey(group)),
      );
      final BoxDecoration? decoration =
          container.decoration as BoxDecoration?;
      expect(
        decoration?.border,
        isNotNull,
        reason: 'A "now" group must render the left-border accent.',
      );
    });

    testWidgets('absent for a "future" group', (tester) async {
      final TodayHourGroup group = _futureGroup();
      await tester.pumpWidget(_harness(group));
      await tester.pumpAndSettle();

      final Container container = tester.widget<Container>(
        find.byKey(_sectionKey(group)),
      );
      final BoxDecoration? decoration =
          container.decoration as BoxDecoration?;
      expect(decoration?.border, isNull);
    });

    testWidgets('absent for a "past" group', (tester) async {
      final TodayHourGroup group = _pastGroupResolved();
      await tester.pumpWidget(_harness(group));
      await tester.pumpAndSettle();

      final Container container = tester.widget<Container>(
        find.byKey(_sectionKey(group)),
      );
      final BoxDecoration? decoration =
          container.decoration as BoxDecoration?;
      expect(decoration?.border, isNull);
    });
  });

  group('TodayGroupSection collapse/expand', () {
    testWidgets('initiallyExpanded: true shows the tiles', (tester) async {
      final TodayHourGroup group = _nowGroupActionable();
      await tester.pumpWidget(_harness(group, initiallyExpanded: true));
      await tester.pumpAndSettle();

      expect(find.byType(TodayDoseTile), findsOneWidget);
    });

    testWidgets('initiallyExpanded: false starts hidden', (tester) async {
      final TodayHourGroup group = _nowGroupActionable();
      await tester.pumpWidget(_harness(group, initiallyExpanded: false));
      await tester.pumpAndSettle();

      expect(find.byType(TodayDoseTile), findsNothing);
    });

    testWidgets('tapping the header hides an initially-expanded body', (
      tester,
    ) async {
      final TodayHourGroup group = _nowGroupActionable();
      await tester.pumpWidget(_harness(group, initiallyExpanded: true));
      await tester.pumpAndSettle();
      expect(find.byType(TodayDoseTile), findsOneWidget);

      await tester.tap(find.byKey(_headerKey(group)));
      await tester.pumpAndSettle();

      expect(find.byType(TodayDoseTile), findsNothing);
    });

    testWidgets('tapping the header re-shows a collapsed body', (
      tester,
    ) async {
      final TodayHourGroup group = _nowGroupActionable();
      await tester.pumpWidget(_harness(group, initiallyExpanded: false));
      await tester.pumpAndSettle();
      expect(find.byType(TodayDoseTile), findsNothing);

      await tester.tap(find.byKey(_headerKey(group)));
      await tester.pumpAndSettle();

      expect(find.byType(TodayDoseTile), findsOneWidget);
    });
  });

  group('TodayGroupSection Mark-all', () {
    testWidgets(
      'shown and invokes onMarkAll when the group hasActionablePending',
      (tester) async {
        var markedAll = false;
        final TodayHourGroup group = _nowGroupActionable();
        expect(group.hasActionablePending, isTrue);

        await tester.pumpWidget(
          _harness(group, onMarkAll: () => markedAll = true),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(_markAllKey), findsOneWidget);

        await tester.tap(find.byKey(_markAllKey));
        await tester.pump();
        expect(markedAll, isTrue);
      },
    );

    testWidgets(
      'absent when the group has only taken/skipped/past-window doses',
      (tester) async {
        final TodayHourGroup group = _pastGroupResolved();
        expect(group.hasActionablePending, isFalse);

        await tester.pumpWidget(_harness(group));
        await tester.pumpAndSettle();

        expect(find.byKey(_markAllKey), findsNothing);
      },
    );

    testWidgets(
      'absent when the group has only a non-actionable pending (future) dose',
      (tester) async {
        final TodayHourGroup group = _futureGroup();
        expect(group.hasActionablePending, isFalse);

        await tester.pumpWidget(_harness(group));
        await tester.pumpAndSettle();

        expect(find.byKey(_markAllKey), findsNothing);
      },
    );
  });
}
