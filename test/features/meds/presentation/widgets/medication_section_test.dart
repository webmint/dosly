/// Widget tests for [MedicationSection] — covers the [queryActive] placeholder
/// gate and tile rendering.
///
/// Each test pumps a [MedicationSection] inside a minimal localized
/// [MaterialApp] + [ProviderScope]. No providers are created; [MedicationSection]
/// is a dumb display widget that receives [title], [items], and [queryActive]
/// directly.
library;

import 'package:clock/clock.dart';
import 'package:dosly/core/l10n/locale_resolver.dart';
import 'package:dosly/features/meds/domain/entities/dosage.dart';
import 'package:dosly/features/meds/domain/entities/dose_unit.dart';
import 'package:dosly/features/meds/domain/entities/medication.dart';
import 'package:dosly/features/meds/domain/entities/medication_activity_status.dart';
import 'package:dosly/features/meds/domain/entities/medication_form.dart';
import 'package:dosly/features/meds/domain/entities/medication_type.dart';
import 'package:dosly/features/meds/domain/entities/schedule.dart';
import 'package:dosly/features/meds/domain/entities/schedule_frequency.dart';
import 'package:dosly/features/meds/domain/entities/time_slot.dart';
import 'package:dosly/features/meds/domain/value_objects/medication_id.dart';
import 'package:dosly/features/meds/domain/value_objects/time_slot_id.dart';
import 'package:dosly/features/meds/presentation/view_models/meds_list_view_model.dart';
import 'package:dosly/features/meds/presentation/widgets/medication_section.dart';
import 'package:dosly/features/meds/presentation/widgets/medication_tile.dart';
import 'package:dosly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fixed clock — explicit UTC literal, no DateTime.now()
// ---------------------------------------------------------------------------

final _fixedNow = DateTime.utc(2026, 6, 15);
final _fixedClock = Clock.fixed(_fixedNow);

// ---------------------------------------------------------------------------
// Domain fixture helpers
// ---------------------------------------------------------------------------

/// Builds a minimal active continuous [MedListItem].
MedListItem _continuousItem({String id = 'sec-cont-001', String name = 'Aspirin'}) {
  final med = Medication(
    id: MedicationId(id),
    name: name,
    form: MedicationForm.tablet,
    type: MedicationType.continuous(startDate: DateTime.utc(2026, 1, 1)),
    schedule: Schedule(
      frequency: ScheduleFrequency.daily,
      slots: [TimeSlot(id: TimeSlotId('slot-$id'), minuteOfDay: 480)],
    ),
    dosePerIntake: const Dosage(amount: 100.0, unit: DoseUnit.mg),
    stock: null,
    notes: null,
    createdAt: DateTime.utc(2026, 1, 1),
  );
  return MedListItem(
    medication: med,
    activity: MedicationActivityStatus.active,
    progress: null,
  );
}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

/// Wraps [MedicationSection] in [ProviderScope] + localized [MaterialApp].
Widget _harness({
  required String title,
  required List<MedListItem> items,
  required bool queryActive,
}) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveAppLocale,
      home: Scaffold(
        body: SingleChildScrollView(
          child: MedicationSection(
            title: title,
            items: items,
            queryActive: queryActive,
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // queryActive gate
  // -------------------------------------------------------------------------
  group('MedicationSection queryActive placeholder gate', () {
    testWidgets(
      'should show medsListSectionEmpty placeholder when queryActive is true '
      'and items is empty',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(
            _harness(
              title: 'Continuous',
              items: const [],
              queryActive: true,
            ),
          );
          await tester.pumpAndSettle();
        });

        // The section header always renders.
        expect(find.text('Continuous'), findsOneWidget);

        // With queryActive==true and empty items, the placeholder must appear.
        expect(find.text('Nothing found'), findsOneWidget);

        // No tile widgets should be present.
        expect(find.byType(MedicationTile), findsNothing);
      },
    );

    testWidgets(
      'should NOT show placeholder when queryActive is false '
      'and items is empty',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(
            _harness(
              title: 'Courses',
              items: const [],
              queryActive: false,
            ),
          );
          await tester.pumpAndSettle();
        });

        // Section header renders.
        expect(find.text('Courses'), findsOneWidget);

        // With queryActive==false and empty items, NO placeholder shown.
        expect(find.text('Nothing found'), findsNothing);

        // No tile widgets either.
        expect(find.byType(MedicationTile), findsNothing);
      },
    );

    testWidgets(
      'should NOT show placeholder when queryActive is true '
      'but items is non-empty',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(
            _harness(
              title: 'Continuous',
              items: [_continuousItem()],
              queryActive: true,
            ),
          );
          await tester.pumpAndSettle();
        });

        // Placeholder must NOT appear when there are tiles to show.
        expect(find.text('Nothing found'), findsNothing);

        // The tile is rendered.
        expect(find.byType(MedicationTile), findsOneWidget);
      },
    );
  });

  // -------------------------------------------------------------------------
  // Tile rendering and dividers
  // -------------------------------------------------------------------------
  group('MedicationSection tile rendering', () {
    testWidgets(
      'should render a single tile with no divider',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(
            _harness(
              title: 'Continuous',
              items: [_continuousItem()],
              queryActive: false,
            ),
          );
          await tester.pumpAndSettle();
        });

        expect(find.byType(MedicationTile), findsOneWidget);
        // No divider between items when there is only one.
        expect(
          find.byWidgetPredicate(
            (w) => w is Divider && w.height == 1 && w.thickness == 1,
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'should render N tiles and N-1 dividers for multiple items',
      (tester) async {
        final items = [
          _continuousItem(id: 'sec-a-001', name: 'Alpha'),
          _continuousItem(id: 'sec-b-002', name: 'Bravo'),
          _continuousItem(id: 'sec-c-003', name: 'Charlie'),
        ];

        await withClock(_fixedClock, () async {
          await tester.pumpWidget(
            _harness(
              title: 'Continuous',
              items: items,
              queryActive: false,
            ),
          );
          await tester.pumpAndSettle();
        });

        expect(find.byType(MedicationTile), findsNWidgets(3));
        // 3 items → 2 dividers separating adjacent pairs.
        expect(
          find.byWidgetPredicate(
            (w) => w is Divider && w.height == 1 && w.thickness == 1,
          ),
          findsNWidgets(2),
        );
      },
    );

    testWidgets(
      'should render the section header text',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(
            _harness(
              title: 'My Section',
              items: [_continuousItem()],
              queryActive: false,
            ),
          );
          await tester.pumpAndSettle();
        });

        expect(find.text('My Section'), findsOneWidget);
      },
    );
  });
}
