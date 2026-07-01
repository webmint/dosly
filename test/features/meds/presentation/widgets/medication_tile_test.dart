/// Widget tests for [MedicationTile] — covers completed-tile de-emphasis
/// (AC-14) and chip order (AC-15).
///
/// Each test pumps a single [MedicationTile] inside a minimal localized
/// [MaterialApp] + [ProviderScope]. No providers are created; [MedicationTile]
/// is a dumb display widget that receives a [MedListItem] directly.
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
import 'package:dosly/features/meds/domain/value_objects/course_progress.dart';
import 'package:dosly/features/meds/domain/value_objects/medication_id.dart';
import 'package:dosly/features/meds/domain/value_objects/time_slot_id.dart';
import 'package:dosly/features/meds/presentation/view_models/meds_list_view_model.dart';
import 'package:dosly/features/meds/presentation/widgets/medication_tile.dart';
import 'package:dosly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fixed clock — explicit UTC literal, no DateTime.now() (constitution §DST rule)
// ---------------------------------------------------------------------------

/// Fixed "now" for course-day determinism: 2026-06-15 UTC.
final _fixedNow = DateTime.utc(2026, 6, 15);
final _fixedClock = Clock.fixed(_fixedNow);

// ---------------------------------------------------------------------------
// Domain fixtures
// ---------------------------------------------------------------------------

/// A continuous medication — "Aspirin" (active by definition).
final _continuousMed = Medication(
  id: const MedicationId('tile-cont-001'),
  name: 'Aspirin',
  form: MedicationForm.tablet,
  type: MedicationType.continuous(startDate: DateTime.utc(2026, 1, 1)),
  schedule: const Schedule(
    frequency: ScheduleFrequency.daily,
    slots: [TimeSlot(id: TimeSlotId('slot-c-001'), minuteOfDay: 480)],
  ),
  dosePerIntake: const Dosage(amount: 100.0, unit: DoseUnit.mg),
  stock: null,
  notes: null,
  createdAt: DateTime.utc(2026, 1, 1),
);

/// An active course medication — "Vitamin D", started 2026-06-10, 30 days.
/// As of _fixedNow (2026-06-15): day 6/30, active window.
final _activeCourseType = CourseType(
  startDate: DateTime.utc(2026, 6, 10),
  durationDays: 30,
  pauseDays: 0,
);
final _activeCourseMed = Medication(
  id: const MedicationId('tile-course-001'),
  name: 'Vitamin D',
  form: MedicationForm.capsule,
  type: _activeCourseType,
  schedule: const Schedule(
    frequency: ScheduleFrequency.daily,
    slots: [TimeSlot(id: TimeSlotId('slot-d-001'), minuteOfDay: 720)],
  ),
  dosePerIntake: const Dosage(amount: 2.5, unit: DoseUnit.ml),
  stock: null,
  notes: null,
  createdAt: DateTime.utc(2026, 6, 10),
);

/// A completed course medication — "Antibiotics", started 2026-03-17, 7 days
/// → finished 2026-03-23; well before _fixedNow.
final _completedCourseType = CourseType(
  startDate: DateTime.utc(2026, 3, 17),
  durationDays: 7,
  pauseDays: 0,
);
final _completedCourseMed = Medication(
  id: const MedicationId('tile-completed-001'),
  name: 'Antibiotics',
  form: MedicationForm.tablet,
  type: _completedCourseType,
  schedule: const Schedule(
    frequency: ScheduleFrequency.daily,
    slots: [TimeSlot(id: TimeSlotId('slot-a-001'), minuteOfDay: 480)],
  ),
  dosePerIntake: null,
  stock: null,
  notes: null,
  createdAt: DateTime.utc(2026, 3, 17),
);

// ---------------------------------------------------------------------------
// MedListItem builders
// ---------------------------------------------------------------------------

MedListItem _continuousItem() => MedListItem(
      medication: _continuousMed,
      activity: MedicationActivityStatus.active,
      progress: null,
    );

MedListItem _activeCourseItem() => MedListItem(
      medication: _activeCourseMed,
      activity: MedicationActivityStatus.active,
      progress: CourseProgress.resolve(
        course: _activeCourseType,
        now: _fixedNow,
      ),
    );

MedListItem _completedCourseItem() => MedListItem(
      medication: _completedCourseMed,
      activity: MedicationActivityStatus.completed,
      progress: CourseProgress.resolve(
        course: _completedCourseType,
        now: _fixedNow,
      ),
    );

// ---------------------------------------------------------------------------
// Test harness
// ---------------------------------------------------------------------------

/// Wraps a single [MedicationTile] in [ProviderScope] + localized [MaterialApp].
Widget _harness(MedListItem item) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveAppLocale,
      home: Scaffold(
        body: MedicationTile(item: item),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // AC-14 — completed-tile de-emphasis (Opacity 0.65)
  // -------------------------------------------------------------------------
  group('MedicationTile AC-14 completed de-emphasis', () {
    testWidgets(
      'should wrap a completed tile in Opacity(0.65)',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(_harness(_completedCourseItem()));
          await tester.pumpAndSettle();
        });

        // The Opacity widget is the root wrapper (carries the ValueKey).
        final opacityFinder = find.byKey(
          const ValueKey('medTile-tile-completed-001'),
        );
        expect(opacityFinder, findsOneWidget);

        final opacity = tester.widget<Opacity>(opacityFinder);
        expect(opacity.opacity, closeTo(0.65, 0.001),
            reason: 'Completed tile must use opacity 0.65');
      },
    );

    testWidgets(
      'should use full opacity (1.0) for an active continuous tile',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(_harness(_continuousItem()));
          await tester.pumpAndSettle();
        });

        final opacityFinder = find.byKey(
          const ValueKey('medTile-tile-cont-001'),
        );
        expect(opacityFinder, findsOneWidget);

        final opacity = tester.widget<Opacity>(opacityFinder);
        expect(opacity.opacity, closeTo(1.0, 0.001),
            reason: 'Active tile must use opacity 1.0');
      },
    );

    testWidgets(
      'should use full opacity (1.0) for an active course tile',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(_harness(_activeCourseItem()));
          await tester.pumpAndSettle();
        });

        final opacityFinder = find.byKey(
          const ValueKey('medTile-tile-course-001'),
        );
        expect(opacityFinder, findsOneWidget);

        final opacity = tester.widget<Opacity>(opacityFinder);
        expect(opacity.opacity, closeTo(1.0, 0.001));
      },
    );

    testWidgets(
      'should use surfaceContainerHighest as the Completed status-chip pill color',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(_harness(_completedCourseItem()));
          await tester.pumpAndSettle();
        });

        final ColorScheme cs =
            Theme.of(tester.element(find.byType(MedicationTile))).colorScheme;
        final AppLocalizations l10n = AppLocalizations.of(
          tester.element(find.byType(MedicationTile)),
        )!;

        // Resolve the localized "Completed" string the same way the production
        // code does — via the AppLocalizations instance from the pumped widget.
        final String completedLabel = l10n.medsListStatusCompleted;

        final tileFinder =
            find.byKey(const ValueKey('medTile-tile-completed-001'));

        // The status chip is a _Pill → Container ancestor of the "Completed"
        // Text. The icon-badge Container is disambiguated by its 48×48 explicit
        // BoxConstraints (set via width/height on the Container), so iterating
        // all Container ancestors of the "Completed" text and asserting at
        // least one has BoxDecoration.color == surfaceContainerHighest is safe.
        //
        // We use the guarded `is BoxDecoration && (as BoxDecoration)` pattern
        // (constitution §3.1) — no unchecked cast.
        final completedTextFinder = find.descendant(
          of: tileFinder,
          matching: find.text(completedLabel),
        );

        expect(completedTextFinder, findsOneWidget,
            reason: 'The localized "Completed" text must be present in the tile');

        // Walk ancestor Containers looking for one whose BoxDecoration color
        // matches surfaceContainerHighest. The _Pill Container has only
        // `padding` + `decoration` — no explicit width/height constraints —
        // which distinguishes it from the 48×48 icon-badge Container.
        bool foundStatusChipColor = false;
        final allContainerAncestors = find.ancestor(
          of: completedTextFinder,
          matching: find.byType(Container),
        );

        for (final element in allContainerAncestors.evaluate()) {
          final w = element.widget as Container;
          final deco = w.decoration;
          if (deco is BoxDecoration && deco.color == cs.surfaceContainerHighest) {
            // Ensure this is the pill (not the icon badge): pill has no explicit
            // width/height fields on the Container.
            if (w.constraints == null ||
                (w.constraints!.maxWidth != 48 &&
                    w.constraints!.maxHeight != 48)) {
              foundStatusChipColor = true;
              break;
            }
          }
        }

        expect(
          foundStatusChipColor,
          isTrue,
          reason:
              'Completed status-chip pill Container must use '
              'colorScheme.surfaceContainerHighest as its BoxDecoration.color',
        );
      },
    );

    testWidgets(
      'should use surfaceContainerHighest badge color for a completed tile',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(_harness(_completedCourseItem()));
          await tester.pumpAndSettle();
        });

        final ColorScheme cs =
            Theme.of(tester.element(find.byType(MedicationTile))).colorScheme;

        // The badge is the 48×48 Container (constraints w=48, h=48) with the
        // icon inside it. The _Pill containers share the same color but have
        // no explicit BoxConstraints — filtering by constraints disambiguates.
        final tileFinder =
            find.byKey(const ValueKey('medTile-tile-completed-001'));
        final badgeFinder = find.descendant(
          of: tileFinder,
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.constraints?.maxWidth == 48 &&
                w.constraints?.maxHeight == 48 &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).color ==
                    cs.surfaceContainerHighest,
          ),
        );

        expect(badgeFinder, findsOneWidget,
            reason:
                'Completed tile badge must use colorScheme.surfaceContainerHighest');
      },
    );
  });

  // -------------------------------------------------------------------------
  // AC-15 — chip order
  // -------------------------------------------------------------------------
  group('MedicationTile AC-15 chip order', () {
    testWidgets(
      'should render type chip BEFORE status chip for a CourseType medication',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(_harness(_activeCourseItem()));
          await tester.pumpAndSettle();
        });

        // "Day 6/30" is the type chip; "Active" is the status chip.
        final typeChipFinder = find.text('Day 6/30');
        final statusChipFinder = find.text('Active');

        expect(typeChipFinder, findsOneWidget);
        expect(statusChipFinder, findsAtLeastNWidgets(1));

        // Type chip must appear above (lower dy = higher on screen = earlier
        // in the Wrap flow) the status chip.
        final typeTop = tester.getTopLeft(typeChipFinder).dy;
        // Find the status chip that is inside the tile (not a filter chip).
        final tileFinder =
            find.byKey(const ValueKey('medTile-tile-course-001'));
        final statusInsideTile = find.descendant(
          of: tileFinder,
          matching: find.text('Active'),
        );
        final statusTop = tester.getTopLeft(statusInsideTile).dy;

        // Both chips are on the same row in the Wrap, so compare dx (x position).
        final typeLeft = tester.getTopLeft(typeChipFinder).dx;
        final statusLeft = tester.getTopLeft(statusInsideTile).dx;

        // Type chip renders first → smaller x in LTR layout (or same row, type
        // has smaller or equal x than status).
        expect(typeLeft, lessThanOrEqualTo(statusLeft),
            reason:
                'For CourseType, type chip (Day X/Y) must appear before status chip');
        // They should be on the same row (dy within 1 logical pixel).
        expect(typeTop, closeTo(statusTop, 1.0));
      },
    );

    testWidgets(
      'should render status chip BEFORE type chip for a ContinuousType medication',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(_harness(_continuousItem()));
          await tester.pumpAndSettle();
        });

        // "Active" is the status chip; "continuous" is the type chip.
        final tileFinder = find.byKey(
          const ValueKey('medTile-tile-cont-001'),
        );
        final statusInsideTile = find.descendant(
          of: tileFinder,
          matching: find.text('Active'),
        );
        final typeChipFinder = find.text('continuous');

        expect(statusInsideTile, findsOneWidget);
        expect(typeChipFinder, findsOneWidget);

        final statusLeft = tester.getTopLeft(statusInsideTile).dx;
        final typeLeft = tester.getTopLeft(typeChipFinder).dx;
        final statusTop = tester.getTopLeft(statusInsideTile).dy;
        final typeTop = tester.getTopLeft(typeChipFinder).dy;

        // Status chip renders first → smaller x in LTR layout on the same row.
        expect(statusLeft, lessThanOrEqualTo(typeLeft),
            reason:
                'For ContinuousType, status chip must appear before type chip');
        expect(statusTop, closeTo(typeTop, 1.0));
      },
    );
  });

  // -------------------------------------------------------------------------
  // onTap wiring (spec 036)
  // -------------------------------------------------------------------------
  group('MedicationTile onTap (spec 036)', () {
    testWidgets(
      'should invoke onTap callback when tile is tapped',
      (tester) async {
        var tapped = false;

        await withClock(_fixedClock, () async {
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                locale: const Locale('en'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                localeResolutionCallback: resolveAppLocale,
                home: Scaffold(
                  body: MedicationTile(
                    item: _continuousItem(),
                    onTap: () => tapped = true,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
        });

        await tester.tap(find.byType(MedicationTile));
        await tester.pump();

        expect(tapped, isTrue,
            reason: 'onTap callback must be invoked when the tile is tapped');
      },
    );

    testWidgets(
      'should contain an InkWell when onTap is supplied',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                locale: const Locale('en'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                localeResolutionCallback: resolveAppLocale,
                home: Scaffold(
                  body: MedicationTile(
                    item: _continuousItem(),
                    onTap: () {},
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
        });

        expect(
          find.descendant(
            of: find.byType(MedicationTile),
            matching: find.byType(InkWell),
          ),
          findsOneWidget,
          reason: 'MedicationTile must include an InkWell when onTap is supplied',
        );
      },
    );

    testWidgets(
      'should render without error when onTap is null (default non-interactive)',
      (tester) async {
        // This test confirms the existing no-onTap render path is preserved by
        // spec 036's changes — the _harness helper already omits onTap.
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(_harness(_continuousItem()));
          await tester.pumpAndSettle();
        });

        // Name and status chip are present — tile renders correctly.
        expect(find.text('Aspirin'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('medTile-tile-cont-001')),
            matching: find.text('Active'),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
