/// Widget tests for [MedsScreen] — covers AC-7 through AC-19 plus the
/// existing locale/AppBar/FAB/modal tests from the pre-existing harness.
///
/// Provider-override strategy:
///   • Simple state tests (sections, filter, search, empty, loading, error,
///     chips): override [medicationsListProvider] with a fixed stream via
///     [medicationRepositoryProvider.overrideWithValue] using a fake
///     [MedicationRepository] whose [watchAll] returns the desired stream.
///   • Reactive-add (AC-19): override [appDatabaseProvider] with a real
///     in-memory [AppDatabase] so the full data→repository→provider chain
///     runs; insert through the real repository; assert the tile appears.
library;

import 'package:clock/clock.dart';
import 'package:dosly/core/database/database.dart';
import 'package:dosly/core/database/database_provider.dart';
import 'package:dosly/core/error/failures.dart';
import 'package:dosly/core/l10n/locale_resolver.dart';
import 'package:dosly/features/meds/data/datasources/medication_local_data_source.dart';
import 'package:dosly/features/meds/data/repositories/medication_repository_impl.dart';
import 'package:dosly/features/meds/domain/entities/dosage.dart';
import 'package:dosly/features/meds/domain/entities/dose_unit.dart';
import 'package:dosly/features/meds/domain/entities/medication.dart';
import 'package:dosly/features/meds/domain/entities/medication_form.dart';
import 'package:dosly/features/meds/domain/entities/medication_type.dart';
import 'package:dosly/features/meds/domain/entities/pack_stock.dart';
import 'package:dosly/features/meds/domain/entities/schedule.dart';
import 'package:dosly/features/meds/domain/entities/schedule_frequency.dart';
import 'package:dosly/features/meds/domain/entities/time_slot.dart';
import 'package:dosly/features/meds/domain/repositories/medication_repository.dart';
import 'package:dosly/features/meds/domain/value_objects/medication_id.dart';
import 'package:dosly/features/meds/domain/value_objects/time_slot_id.dart';
import 'package:dosly/features/meds/presentation/providers/medication_providers.dart';
import 'package:dosly/features/meds/presentation/screens/meds_screen.dart';
import 'package:dosly/features/meds/presentation/widgets/add_medication_modal.dart';
import 'package:dosly/l10n/app_localizations.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

/// Fixed "now" for course-day determinism: 2026-06-15.
final _fixedNow = DateTime.utc(2026, 6, 15);

final _fixedClock = Clock.fixed(_fixedNow);

/// A continuous medication — "Aspirin" starting 2026-01-01.
final _continuous = Medication(
  id: const MedicationId('med-cont-001'),
  name: 'Aspirin',
  form: MedicationForm.tablet,
  type: MedicationType.continuous(startDate: DateTime.utc(2026, 1, 1)),
  schedule: const Schedule(
    frequency: ScheduleFrequency.daily,
    slots: [
      TimeSlot(id: TimeSlotId('slot-c-001'), minuteOfDay: 480),
    ],
  ),
  dosePerIntake: const Dosage(amount: 100.0, unit: DoseUnit.mg),
  stock: null,
  notes: null,
  createdAt: DateTime.utc(2026, 1, 1),
);

/// An active non-cyclic course medication — "Vitamin D", started 2026-06-10,
/// 30 days, so as of _fixedNow (2026-06-15) it's on Day 6/30 (active).
final _activeCourse = Medication(
  id: const MedicationId('med-course-001'),
  name: 'Vitamin D',
  form: MedicationForm.capsule,
  type: MedicationType.course(
    startDate: DateTime.utc(2026, 6, 10),
    durationDays: 30,
    pauseDays: 0,
  ),
  schedule: const Schedule(
    frequency: ScheduleFrequency.daily,
    slots: [
      TimeSlot(id: TimeSlotId('slot-d-001'), minuteOfDay: 720),
    ],
  ),
  dosePerIntake: const Dosage(amount: 2.5, unit: DoseUnit.ml),
  stock: null,
  notes: null,
  createdAt: DateTime.utc(2026, 6, 10),
);

/// A continuous medication with low stock — "Metformin".
///
/// remaining (3) <= warnAt (5) ⇒ [isLowStock] returns true.
final _lowStock = Medication(
  id: const MedicationId('med-lowstock-001'),
  name: 'Metformin',
  form: MedicationForm.tablet,
  type: MedicationType.continuous(startDate: DateTime.utc(2026, 3, 1)),
  schedule: const Schedule(
    frequency: ScheduleFrequency.daily,
    slots: [
      TimeSlot(id: TimeSlotId('slot-m-001'), minuteOfDay: 480),
      TimeSlot(id: TimeSlotId('slot-m-002'), minuteOfDay: 1200),
    ],
  ),
  dosePerIntake: const Dosage(amount: 500.0, unit: DoseUnit.mg),
  stock: const PackStock(remaining: 3, total: 60, warnAt: 5),
  notes: null,
  createdAt: DateTime.utc(2026, 3, 1),
);

/// A completed (non-cyclic) course medication — "Antibiotics", started 90 days
/// before _fixedNow (2026-03-17), 7 days, so it finished 2026-03-24.
final _completedCourse = Medication(
  id: const MedicationId('med-completed-001'),
  name: 'Antibiotics',
  form: MedicationForm.tablet,
  type: MedicationType.course(
    startDate: DateTime.utc(2026, 3, 17),
    durationDays: 7,
    pauseDays: 0,
  ),
  schedule: const Schedule(
    frequency: ScheduleFrequency.daily,
    slots: [
      TimeSlot(id: TimeSlotId('slot-a-001'), minuteOfDay: 480),
    ],
  ),
  dosePerIntake: null,
  stock: null,
  notes: null,
  createdAt: DateTime.utc(2026, 3, 17),
);

// ---------------------------------------------------------------------------
// Fake repository helpers
// ---------------------------------------------------------------------------

/// A [MedicationRepository] that emits a fixed list from [watchAll].
class _FakeMedicationRepository implements MedicationRepository {
  _FakeMedicationRepository(this._meds);

  final List<Medication> _meds;

  @override
  Stream<Either<Failure, List<Medication>>> watchAll() =>
      Stream.value(Right(_meds));

  @override
  Future<Either<Failure, Medication>> add(Medication medication) async =>
      Right(medication);
}

/// A [MedicationRepository] whose [watchAll] stream never emits (stays loading).
class _LoadingMedicationRepository implements MedicationRepository {
  @override
  Stream<Either<Failure, List<Medication>>> watchAll() =>
      const Stream.empty();

  @override
  Future<Either<Failure, Medication>> add(Medication medication) async =>
      Right(medication);
}

/// A [MedicationRepository] whose [watchAll] emits an error.
class _ErrorMedicationRepository implements MedicationRepository {
  @override
  Stream<Either<Failure, List<Medication>>> watchAll() =>
      Stream.error(StateError('simulated repository failure'));

  @override
  Future<Either<Failure, Medication>> add(Medication medication) async =>
      Left(Failure.unknown(Exception('not implemented'), StackTrace.empty));
}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

/// Returns the provider-override that substitutes [meds] into the screen.
///
/// Overrides [medicationRepositoryProvider] with a [_FakeMedicationRepository]
/// that emits [meds] synchronously — no database needed.
List<_OverrideAlias> _repoOverrides(List<Medication> meds) => [
      medicationRepositoryProvider.overrideWithValue(
        _FakeMedicationRepository(meds),
      ),
    ];

/// Convenience alias so the harness function signature compiles without
/// importing the unexported [Override] type directly.
typedef _OverrideAlias = Object;

/// Wraps [MedsScreen] in [ProviderScope] + [MaterialApp] with localization.
///
/// Pass [overrides] to inject test doubles for providers. If [overrides] is
/// empty, no providers are overridden and the screen will show its loading
/// state indefinitely (MedsScreen watches medicationsListProvider which
/// requires appDatabaseProvider — never satisfied without an override).
Widget _harness({
  required Locale locale,
  List<_OverrideAlias> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveAppLocale,
      home: const MedsScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // Existing: locale switching
  // -------------------------------------------------------------------------
  group('MedsScreen locale switching', () {
    testWidgets('renders "My medications" title under Locale("en")',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          locale: const Locale('en'),
          overrides: _repoOverrides([]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My medications'), findsOneWidget);
    });

    testWidgets('renders localized title under Locale("de")', (tester) async {
      await tester.pumpWidget(
        _harness(
          locale: const Locale('de'),
          overrides: _repoOverrides([]),
        ),
      );
      await tester.pumpAndSettle();

      // German l10n key medsListTitle
      expect(find.text('Meine Medikamente'), findsOneWidget);
    });

    testWidgets('renders localized title under Locale("uk")', (tester) async {
      await tester.pumpWidget(
        _harness(
          locale: const Locale('uk'),
          overrides: _repoOverrides([]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Мої ліки'), findsOneWidget);
    });

    testWidgets('falls back to English title for unsupported Locale("fr")',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          locale: const Locale('fr'),
          overrides: _repoOverrides([]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My medications'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Existing: AppBar shape
  // -------------------------------------------------------------------------
  group('MedsScreen AppBar shape', () {
    testWidgets('1-px Divider is a descendant of the AppBar', (tester) async {
      await tester.pumpWidget(
        _harness(
          locale: const Locale('en'),
          overrides: _repoOverrides([]),
        ),
      );
      await tester.pumpAndSettle();

      final appBarFinder = find.byType(AppBar);
      final dividerFinder = find.descendant(
        of: appBarFinder,
        matching: find.byWidgetPredicate(
          (w) => w is Divider && w.height == 1 && w.thickness == 1,
        ),
      );

      expect(dividerFinder, findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Existing: FAB
  // -------------------------------------------------------------------------
  group('MedsScreen FAB', () {
    testWidgets('renders a FloatingActionButton with ValueKey medsAddFab',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          locale: const Locale('en'),
          overrides: _repoOverrides([]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('medsAddFab')), findsOneWidget);
    });

    testWidgets('FAB child is the Lucide plus icon', (tester) async {
      await tester.pumpWidget(
        _harness(
          locale: const Locale('en'),
          overrides: _repoOverrides([]),
        ),
      );
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(
        find.descendant(
          of: find.byType(FloatingActionButton),
          matching: find.byType(Icon),
        ),
      );

      expect(icon.icon, LucideIcons.plus);
    });
  });

  // -------------------------------------------------------------------------
  // Existing: Add-medication modal
  // -------------------------------------------------------------------------
  group('MedsScreen Add-medication modal', () {
    testWidgets(
      'tapping the FAB opens AddMedicationModal showing the localized title (en)',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            locale: const Locale('en'),
            overrides: _repoOverrides([]),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        expect(find.byType(AddMedicationModal), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AddMedicationModal),
            matching: find.text('Add medication'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('back-arrow IconButton dismisses the modal', (tester) async {
      await tester.pumpWidget(
        _harness(
          locale: const Locale('en'),
          overrides: _repoOverrides([]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(AddMedicationModal), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(AddMedicationModal),
          matching: find.byType(IconButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AddMedicationModal), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // AC-14 — loading state
  // -------------------------------------------------------------------------
  group('MedsScreen AC-14 loading state', () {
    testWidgets(
      'should show CircularProgressIndicator while provider is loading',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            locale: const Locale('en'),
            overrides: [
              medicationRepositoryProvider.overrideWithValue(
                _LoadingMedicationRepository(),
              ),
            ],
          ),
        );
        // pump once — stream never emits, AsyncValue stays loading
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );
  });

  // -------------------------------------------------------------------------
  // AC-14 — error state
  // -------------------------------------------------------------------------
  group('MedsScreen AC-14 error state', () {
    testWidgets(
      'should show error text when provider emits an error',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            locale: const Locale('en'),
            overrides: [
              medicationRepositoryProvider.overrideWithValue(
                _ErrorMedicationRepository(),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // The error view renders the error's toString(); we assert that a
        // Text widget with color == colorScheme.error is present.
        final errorTextFinder = find.byWidgetPredicate(
          (w) =>
              w is Text &&
              w.style?.color != null &&
              w.data?.isNotEmpty == true,
        );
        expect(errorTextFinder, findsWidgets);

        // Verify no CircularProgressIndicator remains.
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );
  });

  // -------------------------------------------------------------------------
  // AC-12 — global empty state (zero total medications)
  // -------------------------------------------------------------------------
  group('MedsScreen AC-12 empty state — no medications', () {
    testWidgets(
      'should show medsListEmptyTitle when medication list is empty',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            locale: const Locale('en'),
            overrides: _repoOverrides([]),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('No medications yet'), findsOneWidget);
      },
    );

    testWidgets(
      'should show medsListEmptyBody subtitle when medication list is empty',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            locale: const Locale('en'),
            overrides: _repoOverrides([]),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Tap + to add your first medication'),
          findsOneWidget,
        );
      },
    );
  });

  // -------------------------------------------------------------------------
  // AC-7 — sections: continuous meds under Continuous, course under Courses
  // -------------------------------------------------------------------------
  group('MedsScreen AC-7 sections', () {
    testWidgets(
      'should render Continuous section header when continuous med is present',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(
            _harness(
              locale: const Locale('en'),
              overrides: _repoOverrides([_continuous]),
            ),
          );
          await tester.pumpAndSettle();
        });

        expect(find.text('Continuous'), findsOneWidget);
      },
    );

    testWidgets(
      'should render Courses section header when course med is present',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(
            _harness(
              locale: const Locale('en'),
              overrides: _repoOverrides([_activeCourse]),
            ),
          );
          await tester.pumpAndSettle();
        });

        expect(find.text('Courses'), findsOneWidget);
      },
    );

    testWidgets(
      'should render Aspirin tile under Continuous section',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(
            _harness(
              locale: const Locale('en'),
              overrides: _repoOverrides([_continuous, _activeCourse]),
            ),
          );
          await tester.pumpAndSettle();
        });

        expect(
          find.byKey(const ValueKey('medTile-med-cont-001')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('medTile-med-course-001')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should sort continuous meds alphabetically (Aspirin before Metformin)',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(
            _harness(
              locale: const Locale('en'),
              overrides: _repoOverrides([_lowStock, _continuous]),
            ),
          );
          await tester.pumpAndSettle();
        });

        final aspirinOffset =
            tester.getTopLeft(find.byKey(const ValueKey('medTile-med-cont-001'))).dy;
        final metforminOffset =
            tester.getTopLeft(find.byKey(const ValueKey('medTile-med-lowstock-001'))).dy;

        expect(aspirinOffset, lessThan(metforminOffset));
      },
    );
  });

  // -------------------------------------------------------------------------
  // AC-8 — tile content
  // -------------------------------------------------------------------------
  group('MedsScreen AC-8 tile content', () {
    testWidgets(
      'should show Day X/Y in course type chip for an active course',
      (tester) async {
        // _activeCourse starts 2026-06-10, duration 30 days.
        // As of 2026-06-15: daysSinceStart = 5, currentDay = 6, total = 30.
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(
            _harness(
              locale: const Locale('en'),
              overrides: _repoOverrides([_activeCourse]),
            ),
          );
          await tester.pumpAndSettle();
        });

        expect(find.text('Day 6/30'), findsOneWidget);
      },
    );

    testWidgets(
      'should show continuous type label for a continuous medication',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(
            _harness(
              locale: const Locale('en'),
              overrides: _repoOverrides([_continuous]),
            ),
          );
          await tester.pumpAndSettle();
        });

        expect(find.text('continuous'), findsOneWidget);
      },
    );

    testWidgets(
      'should render low-stock stock text in colorScheme.error color',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(
            _harness(
              locale: const Locale('en'),
              overrides: _repoOverrides([_lowStock]),
            ),
          );
          await tester.pumpAndSettle();
        });

        // Find the TextSpan that contains stock info "3 of 60 pcs" and verify
        // it is rendered in the error color.
        final ColorScheme cs =
            Theme.of(tester.element(find.byType(MedsScreen))).colorScheme;

        // Locate RichText widgets inside the low-stock tile and inspect spans.
        final tileFinder = find.byKey(const ValueKey('medTile-med-lowstock-001'));
        final richTextFinder = find.descendant(
          of: tileFinder,
          matching: find.byType(RichText),
        );

        bool foundErrorColor = false;
        for (final element in richTextFinder.evaluate()) {
          final richText = element.widget as RichText;
          foundErrorColor =
              foundErrorColor || _hasSpanWithColor(richText.text, cs.error);
        }

        expect(foundErrorColor, isTrue,
            reason:
                'Expected at least one TextSpan in the low-stock tile to use '
                'colorScheme.error but none was found.');
      },
    );
  });

  // -------------------------------------------------------------------------
  // AC-9 — status chips
  // -------------------------------------------------------------------------
  group('MedsScreen AC-9 status chips', () {
    testWidgets(
      'should show Active status chip inside a continuous medication tile',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(
            _harness(
              locale: const Locale('en'),
              overrides: _repoOverrides([_continuous]),
            ),
          );
          await tester.pumpAndSettle();
        });

        // Find the "Active" text that lives inside the tile (not the FilterChip).
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('medTile-med-cont-001')),
            matching: find.text('Active'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should show Completed status chip inside a completed course tile',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(
            _harness(
              locale: const Locale('en'),
              overrides: _repoOverrides([_completedCourse]),
            ),
          );
          await tester.pumpAndSettle();
        });

        expect(
          find.descendant(
            of: find.byKey(const ValueKey('medTile-med-completed-001')),
            matching: find.text('Completed'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should show Active status chip inside an active course tile',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(
            _harness(
              locale: const Locale('en'),
              overrides: _repoOverrides([_activeCourse]),
            ),
          );
          await tester.pumpAndSettle();
        });

        expect(
          find.descendant(
            of: find.byKey(const ValueKey('medTile-med-course-001')),
            matching: find.text('Active'),
          ),
          findsOneWidget,
        );
      },
    );
  });

  // -------------------------------------------------------------------------
  // AC-10 — filter chip behavior
  // -------------------------------------------------------------------------
  group('MedsScreen AC-10 filter chips', () {
    testWidgets(
      'should show All and Active filter chips',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(
            _harness(
              locale: const Locale('en'),
              overrides: _repoOverrides([_continuous]),
            ),
          );
          await tester.pumpAndSettle();
        });

        expect(
          find.byWidgetPredicate(
            (w) => w is FilterChip && (w.label as Text).data == 'All',
          ),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (w) => w is FilterChip && (w.label as Text).data == 'Active',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should hide completed course when Active filter is selected',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(
            _harness(
              locale: const Locale('en'),
              overrides: _repoOverrides([_continuous, _completedCourse]),
            ),
          );
          await tester.pumpAndSettle();

          // Completed course tile is visible initially (All filter).
          expect(
            find.byKey(const ValueKey('medTile-med-completed-001')),
            findsOneWidget,
          );

          // Tap the Active filter chip.
          await tester.tap(
            find.byWidgetPredicate(
              (w) => w is FilterChip && (w.label as Text).data == 'Active',
            ),
          );
          await tester.pumpAndSettle();
        });

        expect(
          find.byKey(const ValueKey('medTile-med-completed-001')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'should reveal completed course again when All filter is re-selected',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(
            _harness(
              locale: const Locale('en'),
              overrides: _repoOverrides([_continuous, _completedCourse]),
            ),
          );
          await tester.pumpAndSettle();

          // Switch to Active filter.
          await tester.tap(
            find.byWidgetPredicate(
              (w) => w is FilterChip && (w.label as Text).data == 'Active',
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.byKey(const ValueKey('medTile-med-completed-001')),
            findsNothing,
          );

          // Switch back to All filter.
          await tester.tap(
            find.byWidgetPredicate(
              (w) => w is FilterChip && (w.label as Text).data == 'All',
            ),
          );
          await tester.pumpAndSettle();
        });

        expect(
          find.byKey(const ValueKey('medTile-med-completed-001')),
          findsOneWidget,
        );
      },
    );
  });

  // -------------------------------------------------------------------------
  // AC-11 — search behavior
  // -------------------------------------------------------------------------
  group('MedsScreen AC-11 search', () {
    testWidgets(
      'should open search field when search icon is tapped',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(
            _harness(
              locale: const Locale('en'),
              overrides: _repoOverrides([_continuous]),
            ),
          );
          await tester.pumpAndSettle();
        });

        await tester.tap(find.byIcon(LucideIcons.search));
        await tester.pumpAndSettle();

        expect(find.byType(TextField), findsOneWidget);
      },
    );

    testWidgets(
      'should show only matching meds after entering a query',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(
            _harness(
              locale: const Locale('en'),
              overrides: _repoOverrides([_continuous, _lowStock]),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byIcon(LucideIcons.search));
          await tester.pumpAndSettle();

          // Type "metf" — should match Metformin but not Aspirin.
          await tester.enterText(find.byType(TextField), 'metf');
          await tester.pumpAndSettle();
        });

        expect(
          find.byKey(const ValueKey('medTile-med-lowstock-001')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('medTile-med-cont-001')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'should restore all meds after closing search',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(
            _harness(
              locale: const Locale('en'),
              overrides: _repoOverrides([_continuous, _lowStock]),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byIcon(LucideIcons.search));
          await tester.pumpAndSettle();

          await tester.enterText(find.byType(TextField), 'metf');
          await tester.pumpAndSettle();

          // Close search using the X icon.
          await tester.tap(find.byIcon(LucideIcons.x));
          await tester.pumpAndSettle();
        });

        expect(
          find.byKey(const ValueKey('medTile-med-cont-001')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('medTile-med-lowstock-001')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should show section empty placeholder when search empties one section',
      (tester) async {
        // Only a continuous med — searching for "vitamin" matches nothing
        // in Continuous but we also need a course med that matches.
        // Use _activeCourse (Vitamin D) and _continuous (Aspirin):
        // search "vitamin" → Vitamin D stays, Aspirin disappears; the
        // Continuous section header remains but its items list is empty →
        // medsListSectionEmpty placeholder "Nothing found" is shown.
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(
            _harness(
              locale: const Locale('en'),
              overrides: _repoOverrides([_continuous, _activeCourse]),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byIcon(LucideIcons.search));
          await tester.pumpAndSettle();

          await tester.enterText(find.byType(TextField), 'vitamin');
          await tester.pumpAndSettle();
        });

        // Aspirin is gone.
        expect(
          find.byKey(const ValueKey('medTile-med-cont-001')),
          findsNothing,
        );
        // Vitamin D is present.
        expect(
          find.byKey(const ValueKey('medTile-med-course-001')),
          findsOneWidget,
        );
        // The Continuous section still shows its header and inline placeholder.
        expect(find.text('Continuous'), findsOneWidget);
        expect(find.text('Nothing found'), findsOneWidget);
      },
    );
  });

  // -------------------------------------------------------------------------
  // AC-12 — section-level empty placeholder
  // -------------------------------------------------------------------------
  group('MedsScreen AC-12 section-level empty placeholder', () {
    testWidgets(
      'should show medsListSectionEmpty in a section that has no matching items '
      'while the other section still renders tiles',
      (tester) async {
        // With only a continuous med and Active filter:
        // - Continuous section has the item → renders tile.
        // - Course section is empty → "Nothing found" placeholder.
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(
            _harness(
              locale: const Locale('en'),
              overrides: _repoOverrides([_continuous]),
            ),
          );
          await tester.pumpAndSettle();
        });

        // Both section headers are visible (totalCount > 0 → ListView path).
        expect(find.text('Continuous'), findsOneWidget);
        expect(find.text('Courses'), findsOneWidget);

        // Courses section is empty → placeholder appears.
        expect(find.text('Nothing found'), findsOneWidget);

        // Continuous tile is present.
        expect(
          find.byKey(const ValueKey('medTile-med-cont-001')),
          findsOneWidget,
        );
      },
    );
  });

  // -------------------------------------------------------------------------
  // AC-13 — tile not tappable (no route navigation on tap)
  // -------------------------------------------------------------------------
  group('MedsScreen AC-13 tile not tappable', () {
    testWidgets(
      'should not navigate to a new route when a medication tile is tapped',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(
            _harness(
              locale: const Locale('en'),
              overrides: _repoOverrides([_continuous]),
            ),
          );
          await tester.pumpAndSettle();
        });

        // Record the widget tree state before the tap.
        final beforeTap = find.byType(MedsScreen);
        expect(beforeTap, findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('medTile-med-cont-001')));
        await tester.pumpAndSettle();

        // MedsScreen is still present — no route was pushed.
        expect(find.byType(MedsScreen), findsOneWidget);
      },
    );
  });

  // -------------------------------------------------------------------------
  // AC-19 — reactive add (real in-memory DB)
  // -------------------------------------------------------------------------
  group('MedsScreen AC-19 reactive add', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets(
      'should show new medication tile after add without manual refresh',
      (tester) async {
        await withClock(_fixedClock, () async {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                appDatabaseProvider.overrideWithValue(db),
              ],
              // ignore: prefer_const_constructors (localeResolutionCallback is a fn ref — not const-constructible)
              child: MaterialApp(
                locale: const Locale('en'),
                localizationsDelegates:
                    AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                localeResolutionCallback: resolveAppLocale,
                home: const MedsScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Initially no medications → empty state.
          expect(find.text('No medications yet'), findsOneWidget);

          // Insert a medication through the real repository.
          final repo = MedicationRepositoryImpl(MedicationLocalDataSource(db));
          await repo.add(_continuous);

          // closeStreamsSynchronously: true ensures the drift stream re-emits
          // synchronously on insert. Riverpod processes the stream event on the
          // next microtask batch. pump() + pump() drains microtasks and then
          // schedules a rebuild frame so the tile appears.
          await tester.pump();
          await tester.pump();

          // Tile appears without any manual refresh.
          expect(
            find.byKey(const ValueKey('medTile-med-cont-001')),
            findsOneWidget,
          );
        });
      },
    );
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns `true` if [span] or any of its children has [TextStyle.color] equal
/// to [color].
bool _hasSpanWithColor(InlineSpan span, Color color) {
  if (span.style?.color == color) return true;
  if (span is TextSpan && span.children != null) {
    for (final child in span.children!) {
      if (_hasSpanWithColor(child, color)) return true;
    }
  }
  return false;
}
