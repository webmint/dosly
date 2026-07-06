/// Widget tests for [TodayDoseTile] — the Material 3 checkbox interaction
/// model (pending checkbox + secondary skip icon, taken/skipped checkbox
/// states, the Undo affordance's `undoable` gate), the continuous/course
/// type chip, and the inline low-stock warning.
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
import 'package:dosly/features/meds/domain/entities/pack_stock.dart';
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
// Domain fixtures
// ---------------------------------------------------------------------------

/// Fixed "now" reused across tests — also the CourseProgress anchor.
final _fixedNow = DateTime.utc(2026, 6, 20, 8, 30);

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

/// A course medication — started 2026-06-15, 30-day non-cyclic window.
/// As of [_fixedNow] (2026-06-20): day 6/30, active window.
final _courseType = CourseType(
  startDate: DateTime.utc(2026, 6, 15),
  durationDays: 30,
  pauseDays: 0,
);
final _courseMedication = Medication(
  id: const MedicationId('today-tile-course-001'),
  name: 'Vitamin D',
  form: MedicationForm.capsule,
  type: _courseType,
  schedule: const Schedule(
    slots: [TimeSlot(id: TimeSlotId('slot-course-001'), minuteOfDay: 480)],
  ),
  dosePerIntake: const Dosage(amount: 2.5, unit: DoseUnit.ml),
  stock: null,
  notes: null,
  createdAt: DateTime.utc(2026, 6, 15),
);
final _courseDueDose = DueDose(
  medication: _courseMedication,
  slot: _courseMedication.schedule.slots.first,
  effectiveDose: _courseMedication.dosePerIntake,
  scheduledAt: DateTime.utc(2026, 6, 20, 8),
);

/// A medication with stock at/below its `warnAt` threshold.
final _lowStockMedication = Medication(
  id: const MedicationId('today-tile-low-stock-001'),
  name: 'Metformin',
  form: MedicationForm.tablet,
  type: MedicationType.continuous(startDate: DateTime.utc(2026, 1, 1)),
  schedule: const Schedule(
    slots: [TimeSlot(id: TimeSlotId('slot-low-001'), minuteOfDay: 480)],
  ),
  dosePerIntake: const Dosage(amount: 500.0, unit: DoseUnit.mg),
  stock: const PackStock(remaining: 2, total: 30, warnAt: 5),
  notes: null,
  createdAt: DateTime.utc(2026, 1, 1),
);
final _lowStockDueDose = DueDose(
  medication: _lowStockMedication,
  slot: _lowStockMedication.schedule.slots.first,
  effectiveDose: _lowStockMedication.dosePerIntake,
  scheduledAt: DateTime.utc(2026, 6, 20, 8),
);

TodayDose _pendingDose({
  required bool actionable,
  DoseWindowState windowState = DoseWindowState.open,
  DueDose? dueDose,
}) => TodayDose(
  dose: dueDose ?? _dueDose,
  status: IntakeStatus.pending,
  confirmedAt: null,
  undoable: false,
  intakeId: null,
  windowState: windowState,
  actionable: actionable,
);

TodayDose _takenDose({required bool undoable, DueDose? dueDose}) => TodayDose(
  dose: dueDose ?? _dueDose,
  status: IntakeStatus.taken,
  confirmedAt: DateTime.utc(2026, 6, 20, 8, 1),
  undoable: undoable,
  intakeId: const IntakeId('today-tile-intake-001'),
  windowState: DoseWindowState.open,
  actionable: false,
);

TodayDose _skippedDose({required bool undoable}) => TodayDose(
  dose: _dueDose,
  status: IntakeStatus.skipped,
  confirmedAt: DateTime.utc(2026, 6, 20, 8, 1),
  undoable: undoable,
  intakeId: const IntakeId('today-tile-intake-002'),
  windowState: DoseWindowState.pastWindow,
  actionable: false,
);

TodayDose _missedDose() => TodayDose(
  dose: _dueDose,
  status: IntakeStatus.missed,
  confirmedAt: null,
  undoable: false,
  intakeId: null,
  windowState: DoseWindowState.pastWindow,
  actionable: false,
);

// ---------------------------------------------------------------------------
// Test harness
// ---------------------------------------------------------------------------

const _checkboxKey = ValueKey<String>('todayCheckbox');
const _skipIconKey = ValueKey<String>('todaySkipIcon');
const _undoKey = ValueKey<String>('todayUndo');

/// Wraps a single [TodayDoseTile] in a localized [MaterialApp].
Widget _harness(
  TodayDose dose, {
  DateTime? now,
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
        now: now ?? _fixedNow,
        onTaken: onTaken ?? () {},
        onSkip: onSkip ?? () {},
        onUndo: onUndo ?? () {},
      ),
    ),
  );
}

void main() {
  group('TodayDoseTile pending status', () {
    testWidgets(
      'actionable: shows an enabled checkbox and the skip icon; tapping '
      'each invokes the matching callback',
      (tester) async {
        var taken = false;
        var skipped = false;

        await tester.pumpWidget(
          _harness(
            _pendingDose(actionable: true),
            onTaken: () => taken = true,
            onSkip: () => skipped = true,
          ),
        );
        await tester.pumpAndSettle();

        final Checkbox checkbox = tester.widget<Checkbox>(
          find.byKey(_checkboxKey),
        );
        expect(checkbox.value, isFalse);
        expect(
          checkbox.onChanged,
          isNotNull,
          reason: 'An actionable pending dose must have an enabled checkbox.',
        );
        expect(find.byKey(_skipIconKey), findsOneWidget);

        await tester.tap(find.byKey(_checkboxKey));
        await tester.pump();
        expect(taken, isTrue);

        await tester.tap(find.byKey(_skipIconKey));
        await tester.pump();
        expect(skipped, isTrue);
      },
    );

    testWidgets(
      'NOT actionable (future slot, mark-ahead off): checkbox is disabled '
      'and the skip icon is absent',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            _pendingDose(
              actionable: false,
              windowState: DoseWindowState.future,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final Checkbox checkbox = tester.widget<Checkbox>(
          find.byKey(_checkboxKey),
        );
        expect(
          checkbox.onChanged,
          isNull,
          reason:
              'A non-actionable pending dose must have a disabled checkbox.',
        );
        expect(find.byKey(_skipIconKey), findsNothing);
      },
    );

    testWidgets('renders the subtitle time in 24-hour HH:mm format', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(_pendingDose(actionable: true)));
      await tester.pumpAndSettle();

      expect(find.textContaining('08:00'), findsOneWidget);
    });

    testWidgets(
      'NOT actionable, future window: renders the whole tile at 0.55 '
      'opacity (the mark-ahead-disabled "future slot" look)',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            _pendingDose(
              actionable: false,
              windowState: DoseWindowState.future,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final Opacity opacity = tester
            .widgetList<Opacity>(
              find.descendant(
                of: find.byType(TodayDoseTile),
                matching: find.byType(Opacity),
              ),
            )
            .first;
        expect(
          opacity.opacity,
          0.55,
          reason:
              'A pending, non-actionable, future-window dose must render '
              'dimmed.',
        );
      },
    );

    testWidgets(
      'NOT actionable, past-window: is NOT dimmed (no 0.55 opacity)',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            _pendingDose(
              actionable: false,
              windowState: DoseWindowState.pastWindow,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final Iterable<Opacity> opacities = tester.widgetList<Opacity>(
          find.descendant(
            of: find.byType(TodayDoseTile),
            matching: find.byType(Opacity),
          ),
        );
        expect(
          opacities.every((Opacity o) => o.opacity != 0.55),
          isTrue,
          reason:
              'A past-window pending dose must NOT use the future-slot dim '
              'styling — there is deliberately no overdue dimming.',
        );
      },
    );
  });

  group('TodayDoseTile taken status', () {
    testWidgets(
      'undoable: shows a checked, enabled checkbox; tapping it invokes '
      'onUndo; the name renders with a line-through',
      (tester) async {
        var undone = false;

        await tester.pumpWidget(
          _harness(_takenDose(undoable: true), onUndo: () => undone = true),
        );
        await tester.pumpAndSettle();

        final Checkbox checkbox = tester.widget<Checkbox>(
          find.byKey(_checkboxKey),
        );
        expect(checkbox.value, isTrue);
        expect(checkbox.onChanged, isNotNull);

        await tester.tap(find.byKey(_checkboxKey));
        await tester.pump();
        expect(undone, isTrue);

        final Text nameText = tester.widget<Text>(find.text('Aspirin'));
        expect(nameText.style?.decoration, TextDecoration.lineThrough);
      },
    );

    testWidgets('NOT undoable: the checked checkbox is locked (disabled)', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(_takenDose(undoable: false)));
      await tester.pumpAndSettle();

      final Checkbox checkbox = tester.widget<Checkbox>(
        find.byKey(_checkboxKey),
      );
      expect(checkbox.value, isTrue);
      expect(
        checkbox.onChanged,
        isNull,
        reason: 'A taken dose past its grace window must be locked.',
      );
    });
  });

  group('TodayDoseTile skipped status', () {
    testWidgets(
      'undoable: renders the skipped label and an Undo button; tapping it '
      'invokes onUndo',
      (tester) async {
        var undone = false;

        await tester.pumpWidget(
          _harness(_skippedDose(undoable: true), onUndo: () => undone = true),
        );
        await tester.pumpAndSettle();

        final AppLocalizations l10n = AppLocalizations.of(
          tester.element(find.byType(TodayDoseTile)),
        )!;

        expect(find.text(l10n.todayStatusSkipped), findsOneWidget);
        expect(find.byKey(_undoKey), findsOneWidget);

        await tester.tap(find.byKey(_undoKey));
        await tester.pump();
        expect(undone, isTrue);
      },
    );

    testWidgets('NOT undoable: no Undo button is rendered', (tester) async {
      await tester.pumpWidget(_harness(_skippedDose(undoable: false)));
      await tester.pumpAndSettle();

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(TodayDoseTile)),
      )!;

      expect(find.text(l10n.todayStatusSkipped), findsOneWidget);
      expect(find.byKey(_undoKey), findsNothing);
    });
  });

  group('TodayDoseTile missed status', () {
    testWidgets(
      'renders the missed status label in the error color with no '
      'checkbox/skip/undo affordances',
      (tester) async {
        await tester.pumpWidget(_harness(_missedDose()));
        await tester.pumpAndSettle();

        final BuildContext context = tester.element(
          find.byType(TodayDoseTile),
        );
        final AppLocalizations l10n = AppLocalizations.of(context)!;
        final ColorScheme cs = Theme.of(context).colorScheme;

        expect(find.text(l10n.todayStatusMissed), findsOneWidget);
        expect(find.byKey(_checkboxKey), findsNothing);
        expect(find.byKey(_skipIconKey), findsNothing);
        expect(find.byKey(_undoKey), findsNothing);

        final Text textWidget = tester.widget<Text>(
          find.text(l10n.todayStatusMissed),
        );
        expect(
          textWidget.style?.color,
          cs.error,
          reason: 'A missed dose is an error-toned status, not a neutral one.',
        );
      },
    );
  });

  group('TodayDoseTile type chip', () {
    testWidgets('continuous medication renders the continuous chip', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(_pendingDose(actionable: true)));
      await tester.pumpAndSettle();

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(TodayDoseTile)),
      )!;

      expect(find.text(l10n.medsListTypeContinuous), findsOneWidget);
    });

    testWidgets('course medication renders the "Day N/M" chip', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          _pendingDose(actionable: true, dueDose: _courseDueDose),
          now: _fixedNow,
        ),
      );
      await tester.pumpAndSettle();

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(TodayDoseTile)),
      )!;

      // _fixedNow (2026-06-20) is day 6 of the 30-day window starting
      // 2026-06-15.
      expect(find.text(l10n.medsListTypeCourseDay(6, 30)), findsOneWidget);
    });
  });

  group('TodayDoseTile low-stock warning', () {
    testWidgets('low-stock medication renders the error-colored stock text', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(_pendingDose(actionable: true, dueDose: _lowStockDueDose)),
      );
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(
        find.byType(TodayDoseTile),
      );
      final AppLocalizations l10n = AppLocalizations.of(context)!;
      final ColorScheme cs = Theme.of(context).colorScheme;

      final String stockText = l10n.medsListStock(2, 30);
      expect(find.text(stockText), findsOneWidget);

      final Text textWidget = tester.widget<Text>(find.text(stockText));
      expect(textWidget.style?.color, cs.error);
      expect(textWidget.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('non-low-stock medication renders no stock warning text', (
      tester,
    ) async {
      // _medication has stock: null — no stock tracking, never a warning.
      await tester.pumpWidget(_harness(_pendingDose(actionable: true)));
      await tester.pumpAndSettle();

      final String stockText = AppLocalizations.of(
        tester.element(find.byType(TodayDoseTile)),
      )!.medsListStock(2, 30);
      expect(find.text(stockText), findsNothing);
    });
  });

  // ---------------------------------------------------------------------
  // DE/UK locale spot-check (recurring MEMORY lesson: locale coverage must
  // assert an actual translated string, not just that the widget builds).
  // ---------------------------------------------------------------------
  group('TodayDoseTile locale spot-check', () {
    testWidgets('renders the German missed status label under Locale("de")', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(_missedDose(), locale: const Locale('de')),
      );
      await tester.pumpAndSettle();

      // German l10n key todayStatusMissed.
      expect(find.text('Verpasst'), findsOneWidget);
      expect(find.byKey(_checkboxKey), findsNothing);
    });

    testWidgets(
      'renders the Ukrainian skipped status label + Undo under Locale("uk")',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            _skippedDose(undoable: true),
            locale: const Locale('uk'),
          ),
        );
        await tester.pumpAndSettle();

        // Ukrainian l10n keys todayStatusSkipped / todayUndo.
        expect(find.text('Пропущено'), findsOneWidget);
        expect(find.byKey(_undoKey), findsOneWidget);
      },
    );
  });
}
