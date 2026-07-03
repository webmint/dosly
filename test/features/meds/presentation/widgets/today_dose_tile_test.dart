/// Widget tests for [TodayDoseTile] — pending Take/Skip affordances, the
/// taken/skipped status label, and the Undo affordance's `undoable` gate.
///
/// Each test pumps a single [TodayDoseTile] inside a minimal localized
/// [MaterialApp]. No providers or `ProviderScope` are involved —
/// [TodayDoseTile] is a dumb display widget that receives a `TodayDose`
/// directly and reports taps via constructor callbacks.
library;

import 'package:dosly/core/l10n/locale_resolver.dart';
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
import 'package:dosly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Domain fixtures — a fixed medication + slot, reused by every TodayDose.
// ---------------------------------------------------------------------------

final _medication = Medication(
  id: const MedicationId('today-tile-001'),
  name: 'Aspirin',
  form: MedicationForm.tablet,
  type: MedicationType.continuous(startDate: DateTime.utc(2026, 1, 1)),
  schedule: const Schedule(
    slots: [TimeSlot(id: TimeSlotId('slot-001'), minuteOfDay: 480)],
  ),
  dosePerIntake: const Dosage(amount: 100.0, unit: DoseUnit.mg),
  stock: null,
  notes: null,
  createdAt: DateTime.utc(2026, 1, 1),
);

final _dueDose = DueDose(
  medication: _medication,
  slot: _medication.schedule.slots.first,
  effectiveDose: _medication.dosePerIntake,
  scheduledAt: DateTime.utc(2026, 6, 20, 8),
);

TodayDose _pendingDose() => TodayDose(
  dose: _dueDose,
  status: IntakeStatus.pending,
  confirmedAt: null,
  undoable: false,
  intakeId: null,
);

TodayDose _takenDose({required bool undoable}) => TodayDose(
  dose: _dueDose,
  status: IntakeStatus.taken,
  confirmedAt: DateTime.utc(2026, 6, 20, 8, 1),
  undoable: undoable,
  intakeId: const IntakeId('today-tile-intake-001'),
);

TodayDose _skippedDose({required bool undoable}) => TodayDose(
  dose: _dueDose,
  status: IntakeStatus.skipped,
  confirmedAt: DateTime.utc(2026, 6, 20, 8, 1),
  undoable: undoable,
  intakeId: const IntakeId('today-tile-intake-002'),
);

// ---------------------------------------------------------------------------
// Test harness
// ---------------------------------------------------------------------------

/// Wraps a single [TodayDoseTile] in a localized [MaterialApp].
///
/// [locale] defaults to English; the DE/UK locale-spot-check tests below pass
/// `Locale('de')` / `Locale('uk')` to prove a real translated string renders
/// (constitution — recurring MEMORY lesson: locale coverage must assert an
/// actual translated string, not just that the widget builds).
Widget _harness(
  TodayDose dose, {
  VoidCallback? onTaken,
  VoidCallback? onSkip,
  VoidCallback? onUndo,
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    localeResolutionCallback: resolveAppLocale,
    home: Scaffold(
      body: TodayDoseTile(
        dose: dose,
        onTaken: onTaken ?? () {},
        onSkip: onSkip ?? () {},
        onUndo: onUndo ?? () {},
      ),
    ),
  );
}

void main() {
  group('TodayDoseTile pending status', () {
    testWidgets('should show Take and Skip affordances', (tester) async {
      await tester.pumpWidget(_harness(_pendingDose()));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('todayTake')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('todaySkip')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('todayUndo')), findsNothing);
    });

    testWidgets('should invoke onTaken when the Take affordance is tapped', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        _harness(_pendingDose(), onTaken: () => tapped = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('todayTake')));
      await tester.pump();

      expect(
        tapped,
        isTrue,
        reason: 'onTaken callback must be invoked when Take is tapped',
      );
    });

    testWidgets('should invoke onSkip when the Skip affordance is tapped', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        _harness(_pendingDose(), onSkip: () => tapped = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('todaySkip')));
      await tester.pump();

      expect(
        tapped,
        isTrue,
        reason: 'onSkip callback must be invoked when Skip is tapped',
      );
    });

    testWidgets('should render the subtitle time in 24-hour HH:mm format', (
      tester,
    ) async {
      // _dueDose's slot has minuteOfDay: 480 (08:00) — guards the
      // ~/60 / %60 hour+minute split and the alwaysUse24HourFormat flag.
      await tester.pumpWidget(_harness(_pendingDose()));
      await tester.pumpAndSettle();

      expect(find.textContaining('08:00'), findsOneWidget);
    });
  });

  group('TodayDoseTile taken status', () {
    testWidgets(
      'should show the status label and Undo when undoable is true, and hide Take/Skip',
      (tester) async {
        await tester.pumpWidget(_harness(_takenDose(undoable: true)));
        await tester.pumpAndSettle();

        final AppLocalizations l10n = AppLocalizations.of(
          tester.element(find.byType(TodayDoseTile)),
        )!;

        expect(find.text(l10n.todayStatusTaken), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('todayUndo')), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('todayTake')), findsNothing);
        expect(find.byKey(const ValueKey<String>('todaySkip')), findsNothing);
      },
    );

    testWidgets('should invoke onUndo when the Undo affordance is tapped', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        _harness(_takenDose(undoable: true), onUndo: () => tapped = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('todayUndo')));
      await tester.pump();

      expect(
        tapped,
        isTrue,
        reason: 'onUndo callback must be invoked when Undo is tapped',
      );
    });

    testWidgets(
      'should show the status label WITHOUT Undo when undoable is false',
      (tester) async {
        await tester.pumpWidget(_harness(_takenDose(undoable: false)));
        await tester.pumpAndSettle();

        final AppLocalizations l10n = AppLocalizations.of(
          tester.element(find.byType(TodayDoseTile)),
        )!;

        expect(find.text(l10n.todayStatusTaken), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('todayUndo')),
          findsNothing,
          reason: 'Undo must be absent once the grace window has elapsed',
        );
      },
    );
  });

  group('TodayDoseTile skipped status', () {
    testWidgets('should render the skipped status label', (tester) async {
      await tester.pumpWidget(_harness(_skippedDose(undoable: false)));
      await tester.pumpAndSettle();

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(TodayDoseTile)),
      )!;

      expect(find.text(l10n.todayStatusSkipped), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('todayUndo')), findsNothing);
    });

    testWidgets('should show Undo for a skipped dose when undoable is true', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        _harness(_skippedDose(undoable: true), onUndo: () => tapped = true),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey<String>('todayUndo')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('todayUndo')));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  // ---------------------------------------------------------------------
  // DE/UK locale spot-check (recurring MEMORY lesson: assert a translated
  // string actually renders, not just that the widget builds under a given
  // Locale). Mirrors the DE/UK convention in meds_screen_test.dart.
  // ---------------------------------------------------------------------
  group('TodayDoseTile locale spot-check', () {
    testWidgets('renders German Take/Skip affordances under Locale("de")', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(_pendingDose(), locale: const Locale('de')),
      );
      await tester.pumpAndSettle();

      // German l10n keys todayMarkTaken / todaySkip.
      expect(find.text('Einnehmen'), findsOneWidget);
      expect(find.text('Überspringen'), findsOneWidget);
    });

    testWidgets('renders Ukrainian Take/Skip affordances under Locale("uk")', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(_pendingDose(), locale: const Locale('uk')),
      );
      await tester.pumpAndSettle();

      // Ukrainian l10n keys todayMarkTaken / todaySkip.
      expect(find.text('Прийняти'), findsOneWidget);
      expect(find.text('Пропустити'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------
  // AC-10 — no overdue styling: a past-scheduled pending dose renders
  // structurally identical to a future-scheduled pending dose.
  // ---------------------------------------------------------------------
  group('TodayDoseTile AC-10 no overdue styling', () {
    testWidgets('renders identical Take/Skip affordances and badge tint for a '
        'past-scheduled and a future-scheduled pending dose', (tester) async {
      // A fixed reference instant splitting the two doses: the "past" slot
      // is scheduled before it, the "future" slot after it.
      final DateTime fixedNow = DateTime.utc(2026, 6, 20, 12);

      final DueDose pastDose = DueDose(
        medication: _medication,
        slot: const TimeSlot(id: TimeSlotId('slot-past'), minuteOfDay: 480),
        effectiveDose: _medication.dosePerIntake,
        scheduledAt: DateTime.utc(2026, 6, 20, 8),
      );
      final DueDose futureDose = DueDose(
        medication: _medication,
        slot: const TimeSlot(id: TimeSlotId('slot-future'), minuteOfDay: 1200),
        effectiveDose: _medication.dosePerIntake,
        scheduledAt: DateTime.utc(2026, 6, 20, 20),
      );
      // Sanity: one is genuinely overdue relative to fixedNow, the other
      // genuinely upcoming — otherwise this test would prove nothing.
      expect(pastDose.scheduledAt.isBefore(fixedNow), isTrue);
      expect(futureDose.scheduledAt.isAfter(fixedNow), isTrue);

      const pastKey = ValueKey<String>('past-tile');
      const futureKey = ValueKey<String>('future-tile');

      final TodayDose pastPending = TodayDose(
        dose: pastDose,
        status: IntakeStatus.pending,
        confirmedAt: null,
        undoable: false,
        intakeId: null,
      );
      final TodayDose futurePending = TodayDose(
        dose: futureDose,
        status: IntakeStatus.pending,
        confirmedAt: null,
        undoable: false,
        intakeId: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: resolveAppLocale,
          home: Scaffold(
            body: Column(
              children: <Widget>[
                TodayDoseTile(
                  key: pastKey,
                  dose: pastPending,
                  onTaken: () {},
                  onSkip: () {},
                  onUndo: () {},
                ),
                TodayDoseTile(
                  key: futureKey,
                  dose: futurePending,
                  onTaken: () {},
                  onSkip: () {},
                  onUndo: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Finder pastTile = find.byKey(pastKey);
      final Finder futureTile = find.byKey(futureKey);

      // Both doses expose the SAME pending affordances — Take + Skip, no
      // Undo — regardless of whether their scheduled time is in the past
      // or the future relative to fixedNow (TodayDoseTile has no
      // time-vs-now branch by design).
      for (final Finder tile in <Finder>[pastTile, futureTile]) {
        expect(
          find.descendant(
            of: tile,
            matching: find.byKey(const ValueKey<String>('todayTake')),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: tile,
            matching: find.byKey(const ValueKey<String>('todaySkip')),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: tile,
            matching: find.byKey(const ValueKey<String>('todayUndo')),
          ),
          findsNothing,
        );
      }

      // Regression guard: the leading icon badge uses the SAME fixed
      // primaryContainer tint on both tiles. If a future change added
      // overdue styling (e.g. tinting a past-due badge with
      // errorContainer/tertiaryContainer), the past tile's badge would no
      // longer match this predicate and this assertion would fail.
      final ColorScheme cs = Theme.of(tester.element(pastTile)).colorScheme;
      bool isUntintedBadge(Widget w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration! as BoxDecoration).color == cs.primaryContainer;

      expect(
        find.descendant(
          of: pastTile,
          matching: find.byWidgetPredicate(isUntintedBadge),
        ),
        findsOneWidget,
        reason:
            'The past-due dose badge must use the same untinted '
            'primaryContainer color as a future dose — no overdue styling.',
      );
      expect(
        find.descendant(
          of: futureTile,
          matching: find.byWidgetPredicate(isUntintedBadge),
        ),
        findsOneWidget,
      );
    });
  });
}
