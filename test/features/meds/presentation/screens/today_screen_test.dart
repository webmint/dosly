/// Widget tests for [TodayScreen] — covers the reactive Today checklist:
/// empty/loading states, seeded doses rendering time-sorted, Take/Skip
/// actions persisting through the real repository chain, early marking of a
/// future-scheduled dose, and the Undo grace window (within vs. expired).
///
/// Provider-override strategy:
///   • Empty/seeded/action tests use a REAL in-memory [AppDatabase] with only
///     [appDatabaseProvider] overridden, so [medicationsListProvider] and
///     [intakesListProvider] run through the actual repository chain — this
///     is what proves persistence (AC-9) and reactivity end to end.
///   • The loading-state test overrides [medicationRepositoryProvider] and
///     [intakeRepositoryProvider] directly with fakes whose streams never
///     emit, so the `AsyncValue` stays `loading` deterministically.
///
/// The Undo-grace test drives a mutable [Clock] (not [Clock.fixed]) so the
/// screen's one-shot grace-refresh [Timer] — captured by flutter_test's
/// `FakeAsync` zone — can be advanced via `tester.pump(Duration(...))`
/// without a real wall-clock wait, and the subsequent rebuild observes an
/// ADVANCED `clock.now()` reading (mutated just before the pump) rather than
/// a value frozen at zone-creation time.
library;

import 'dart:async';

import 'package:clock/clock.dart';
import 'package:dosly/core/database/database.dart';
import 'package:dosly/core/database/database_provider.dart';
import 'package:dosly/core/error/failures.dart';
import 'package:dosly/features/meds/data/datasources/medication_local_data_source.dart';
import 'package:dosly/features/meds/data/repositories/medication_repository_impl.dart';
import 'package:dosly/features/meds/domain/entities/dosage.dart';
import 'package:dosly/features/meds/domain/entities/dose_unit.dart';
import 'package:dosly/features/meds/domain/entities/intake.dart';
import 'package:dosly/features/meds/domain/entities/intake_status.dart';
import 'package:dosly/features/meds/domain/entities/medication.dart';
import 'package:dosly/features/meds/domain/entities/medication_form.dart';
import 'package:dosly/features/meds/domain/entities/medication_type.dart';
import 'package:dosly/features/meds/domain/entities/schedule.dart';
import 'package:dosly/features/meds/domain/entities/time_slot.dart';
import 'package:dosly/features/meds/domain/repositories/intake_repository.dart';
import 'package:dosly/features/meds/domain/repositories/medication_repository.dart';
import 'package:dosly/features/meds/domain/value_objects/intake_id.dart';
import 'package:dosly/features/meds/domain/value_objects/medication_id.dart';
import 'package:dosly/features/meds/domain/value_objects/time_slot_id.dart';
import 'package:dosly/features/meds/presentation/providers/intake_providers.dart';
import 'package:dosly/features/meds/presentation/providers/medication_providers.dart';
import 'package:dosly/features/meds/presentation/screens/today_screen.dart';
import 'package:dosly/features/meds/presentation/widgets/today_dose_tile.dart';
import 'package:dosly/features/meds/presentation/widgets/today_empty_state.dart';
import 'package:dosly/l10n/app_localizations.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

/// Fixed "now": 2026-06-15 08:30 local. The morning slot (08:00) is in the
/// past relative to this instant, the evening slot (20:00) in the future —
/// exercising AC-8 ordering and AC-10 "early marking" in the same fixture.
final DateTime _fixedNow = DateTime(2026, 6, 15, 8, 30);
final Clock _fixedClock = Clock.fixed(_fixedNow);

/// A continuous medication ("Aspirin") with two daily slots: 08:00 and
/// 20:00. Continuous + a start date well in the past keeps it unconditionally
/// due on [_fixedNow]'s local calendar day.
final Medication _aspirin = Medication(
  id: const MedicationId('med-today-001'),
  name: 'Aspirin',
  form: MedicationForm.tablet,
  type: MedicationType.continuous(startDate: DateTime(2026, 1, 1)),
  schedule: const Schedule(
    slots: [
      TimeSlot(id: TimeSlotId('slot-morning'), minuteOfDay: 480), // 08:00
      TimeSlot(id: TimeSlotId('slot-evening'), minuteOfDay: 1200), // 20:00
    ],
  ),
  dosePerIntake: const Dosage(amount: 100, unit: DoseUnit.mg),
  createdAt: DateTime(2026, 1, 1),
);

/// Key of the rendered [TodayDoseTile] for the morning (08:00) dose — matches
/// the `'todayTile-<medicationId>-<slotId>'` scheme `today_screen.dart` keys
/// each tile with.
const ValueKey<String> _morningTileKey = ValueKey<String>(
  'todayTile-med-today-001-slot-morning',
);

/// Key of the rendered [TodayDoseTile] for the evening (20:00) dose.
const ValueKey<String> _eveningTileKey = ValueKey<String>(
  'todayTile-med-today-001-slot-evening',
);

const ValueKey<String> _takeKey = ValueKey<String>('todayTake');
const ValueKey<String> _skipKey = ValueKey<String>('todaySkip');
const ValueKey<String> _undoKey = ValueKey<String>('todayUndo');

// ---------------------------------------------------------------------------
// Fakes for the loading-state test
// ---------------------------------------------------------------------------

/// A [MedicationRepository] whose [watchAll] stream never emits — keeps the
/// screen's `medicationsListProvider` `AsyncValue` in `loading` forever.
class _LoadingMedicationRepository implements MedicationRepository {
  @override
  Stream<Either<Failure, List<Medication>>> watchAll() => const Stream.empty();

  @override
  Future<Either<Failure, Medication>> add(Medication medication) async =>
      Right(medication);

  @override
  Future<Either<Failure, Medication>> update(Medication medication) async =>
      Right(medication);

  @override
  Future<Either<Failure, void>> delete(MedicationId id) async =>
      const Right(null);
}

/// An [IntakeRepository] whose [watchAll] stream never emits — mirrors
/// [_LoadingMedicationRepository] for `intakesListProvider`.
class _LoadingIntakeRepository implements IntakeRepository {
  @override
  Stream<Either<Failure, List<Intake>>> watchAll() => const Stream.empty();

  @override
  Future<Either<Failure, Intake>> markTaken(Intake intake) async =>
      Right(intake);

  @override
  Future<Either<Failure, Intake>> skip(Intake intake) async => Right(intake);

  @override
  Future<Either<Failure, void>> undo(IntakeId id) async => const Right(null);
}

// ---------------------------------------------------------------------------
// Fake for the error-state test
// ---------------------------------------------------------------------------

/// An [IntakeRepository] whose [watchAll] stream emits a single
/// `Left(Failure)` — [intakesListProvider] folds that into a thrown error, so
/// the provider's `AsyncValue` settles into `error` (constitution §3.2). Used
/// to drive the Today screen's error branch without touching the database.
class _ErrorIntakeRepository implements IntakeRepository {
  @override
  Stream<Either<Failure, List<Intake>>> watchAll() =>
      Stream.value(const Left(Failure.cache('simulated load failure')));

  @override
  Future<Either<Failure, Intake>> markTaken(Intake intake) async =>
      Right(intake);

  @override
  Future<Either<Failure, Intake>> skip(Intake intake) async => Right(intake);

  @override
  Future<Either<Failure, void>> undo(IntakeId id) async => const Right(null);
}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

/// Wraps [TodayScreen] in [ProviderScope] + [MaterialApp] with localization
/// pinned to English. [overrides] are appended after the base
/// [appDatabaseProvider] override.
Widget _harness({
  required AppDatabase db,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db), ...overrides],
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TodayScreen(),
    ),
  );
}

/// Finds a keyed action button scoped to a specific tile, so identically-keyed
/// actions (`todayTake`/`todaySkip`/`todayUndo`) in different tiles never
/// collide.
Finder _actionIn(Key tileKey, Key actionKey) =>
    find.descendant(of: find.byKey(tileKey), matching: find.byKey(actionKey));

void main() {
  late AppDatabase db;

  setUp(() {
    // closeStreamsSynchronously: true makes drift close streams synchronously
    // when the DB is closed, so no zero-duration timer remains pending when
    // flutter_test's _verifyInvariants runs after the widget tree is disposed.
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

  // ---------------------------------------------------------------------
  // AC-11 — empty state
  // ---------------------------------------------------------------------
  group('TodayScreen AC-11 empty state', () {
    testWidgets('shows TodayEmptyState when no medications are due', (
      tester,
    ) async {
      await withClock(_fixedClock, () async {
        await tester.pumpWidget(_harness(db: db));
        await tester.pumpAndSettle();
      });

      expect(find.byType(TodayEmptyState), findsOneWidget);
      expect(find.byType(TodayDoseTile), findsNothing);
    });
  });

  // ---------------------------------------------------------------------
  // Loading state
  // ---------------------------------------------------------------------
  group('TodayScreen loading state', () {
    testWidgets('shows CircularProgressIndicator before the streams emit', (
      tester,
    ) async {
      await withClock(_fixedClock, () async {
        await tester.pumpWidget(
          _harness(
            db: db,
            overrides: [
              medicationRepositoryProvider.overrideWithValue(
                _LoadingMedicationRepository(),
              ),
              intakeRepositoryProvider.overrideWithValue(
                _LoadingIntakeRepository(),
              ),
            ],
          ),
        );
        // A single frame: both streams stay loading (never emit).
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });
  });

  // ---------------------------------------------------------------------
  // Error state — intakesListProvider surfaces as AsyncValue.error
  // ---------------------------------------------------------------------
  group('TodayScreen error state', () {
    testWidgets('shows the localized load-error text and no TodayDoseTile when '
        'intakesListProvider errors', (tester) async {
      await withClock(_fixedClock, () async {
        await tester.pumpWidget(
          _harness(
            db: db,
            overrides: [
              intakeRepositoryProvider.overrideWithValue(
                _ErrorIntakeRepository(),
              ),
            ],
          ),
        );
        // No grace Timer is ever scheduled on the error branch (it is
        // cancelled before the error text is returned), so pumpAndSettle
        // is safe here — unlike the seeded/action tests it does not race a
        // pending one-shot Timer.
        await tester.pumpAndSettle();
      });

      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(TodayScreen)),
      )!;

      expect(find.text(l10n.todayLoadError), findsOneWidget);
      expect(find.byType(TodayDoseTile), findsNothing);
      expect(find.byType(TodayEmptyState), findsNothing);
    });
  });

  // ---------------------------------------------------------------------
  // AC-8 — seeded doses render time-sorted
  // ---------------------------------------------------------------------
  group('TodayScreen AC-8 seeded doses', () {
    testWidgets(
      'renders a TodayDoseTile per due dose, morning before evening',
      (tester) async {
        await withClock(_fixedClock, () async {
          final repo = MedicationRepositoryImpl(MedicationLocalDataSource(db));
          await repo.add(_aspirin);

          await tester.pumpWidget(_harness(db: db));
          await tester.pumpAndSettle();
        });

        expect(find.byKey(_morningTileKey), findsOneWidget);
        expect(find.byKey(_eveningTileKey), findsOneWidget);

        final double morningY = tester
            .getTopLeft(find.byKey(_morningTileKey))
            .dy;
        final double eveningY = tester
            .getTopLeft(find.byKey(_eveningTileKey))
            .dy;
        expect(
          morningY,
          lessThan(eveningY),
          reason: 'The 08:00 dose must render above the 20:00 dose',
        );
      },
    );
  });

  // ---------------------------------------------------------------------
  // AC-9 — Take persists and transitions the tile
  // ---------------------------------------------------------------------
  group('TodayScreen AC-9 take', () {
    testWidgets(
      'tapping Take transitions the tile to Taken and persists the intake',
      (tester) async {
        await withClock(_fixedClock, () async {
          final repo = MedicationRepositoryImpl(MedicationLocalDataSource(db));
          await repo.add(_aspirin);

          await tester.pumpWidget(_harness(db: db));
          await tester.pumpAndSettle();

          await tester.tap(_actionIn(_morningTileKey, _takeKey));
          // Drain the microtask/stream re-emit, then rebuild.
          await tester.pump();
          await tester.pump();
        });

        expect(
          find.descendant(
            of: find.byKey(_morningTileKey),
            matching: find.text('Taken'),
          ),
          findsOneWidget,
        );
        expect(_actionIn(_morningTileKey, _undoKey), findsOneWidget);

        // Read back proves persistence, independent of the UI.
        final rows = await db.select(db.intakes).get();
        expect(rows, hasLength(1));
        expect(rows.single.status, IntakeStatus.taken);
        expect(rows.single.medicationId, 'med-today-001');
        expect(rows.single.slotId, 'slot-morning');
      },
    );
  });

  // ---------------------------------------------------------------------
  // AC-9 — Skip persists and transitions the tile
  // ---------------------------------------------------------------------
  group('TodayScreen AC-9 skip', () {
    testWidgets(
      'tapping Skip transitions the tile to Skipped and persists the intake',
      (tester) async {
        await withClock(_fixedClock, () async {
          final repo = MedicationRepositoryImpl(MedicationLocalDataSource(db));
          await repo.add(_aspirin);

          await tester.pumpWidget(_harness(db: db));
          await tester.pumpAndSettle();

          await tester.tap(_actionIn(_morningTileKey, _skipKey));
          await tester.pump();
          await tester.pump();
        });

        expect(
          find.descendant(
            of: find.byKey(_morningTileKey),
            matching: find.text('Skipped'),
          ),
          findsOneWidget,
        );

        final rows = await db.select(db.intakes).get();
        expect(rows, hasLength(1));
        expect(rows.single.status, IntakeStatus.skipped);
      },
    );
  });

  // ---------------------------------------------------------------------
  // AC-10 — early marking of a future-scheduled dose
  // ---------------------------------------------------------------------
  group('TodayScreen AC-10 early marking', () {
    testWidgets(
      'a dose scheduled later today is still tappable and transitions',
      (tester) async {
        await withClock(_fixedClock, () async {
          final repo = MedicationRepositoryImpl(MedicationLocalDataSource(db));
          await repo.add(_aspirin);

          await tester.pumpWidget(_harness(db: db));
          await tester.pumpAndSettle();

          // The evening (20:00) dose is in the future relative to
          // _fixedNow (08:30) — tapping Take must still succeed.
          await tester.tap(_actionIn(_eveningTileKey, _takeKey));
          await tester.pump();
          await tester.pump();
        });

        expect(
          find.descendant(
            of: find.byKey(_eveningTileKey),
            matching: find.text('Taken'),
          ),
          findsOneWidget,
        );

        final rows = await db.select(db.intakes).get();
        expect(rows, hasLength(1));
        expect(rows.single.slotId, 'slot-evening');
      },
    );
  });

  // ---------------------------------------------------------------------
  // AC-12 / AC-13 — Undo within grace vs. expired grace
  // ---------------------------------------------------------------------
  group('TodayScreen AC-12/AC-13 undo grace window', () {
    testWidgets(
      'undo within grace reverts to pending; the affordance disappears once '
      'the grace window elapses',
      (tester) async {
        // A mutable clock (not Clock.fixed): the grace-refresh Timer runs in
        // this zone, so mutating `mutableNow` just before advancing the
        // FakeAsync clock via tester.pump(duration) lets the Timer-triggered
        // rebuild observe the ADVANCED time.
        DateTime mutableNow = _fixedNow;
        final Clock testClock = Clock(() => mutableNow);

        await withClock(testClock, () async {
          final repo = MedicationRepositoryImpl(MedicationLocalDataSource(db));
          await repo.add(_aspirin);

          await tester.pumpWidget(_harness(db: db));
          await tester.pumpAndSettle();

          // 1) Mark taken; Undo is offered within the grace window.
          await tester.tap(_actionIn(_morningTileKey, _takeKey));
          await tester.pump();
          await tester.pump();
          expect(_actionIn(_morningTileKey, _undoKey), findsOneWidget);

          // 2) Undo within grace reverts the dose to pending (AC-12).
          await tester.tap(_actionIn(_morningTileKey, _undoKey));
          await tester.pump();
          await tester.pump();
          expect(
            _actionIn(_morningTileKey, _takeKey),
            findsOneWidget,
            reason: 'Undo must revert the dose back to pending',
          );
          final List<dynamic> afterUndo = await db.select(db.intakes).get();
          expect(afterUndo, isEmpty);

          // 3) Re-confirm as taken to exercise grace EXPIRY this time.
          await tester.tap(_actionIn(_morningTileKey, _takeKey));
          await tester.pump();
          await tester.pump();
          expect(_actionIn(_morningTileKey, _undoKey), findsOneWidget);

          // 4) Advance past the 5-minute grace window. The scheduled
          // one-shot Timer fires during the FakeAsync elapse, calls
          // setState, and the rebuild reads the now-advanced clock.
          mutableNow = _fixedNow.add(const Duration(minutes: 6));
          await tester.pump(const Duration(minutes: 6));

          expect(
            _actionIn(_morningTileKey, _undoKey),
            findsNothing,
            reason:
                'The Undo affordance must disappear once the grace window '
                'has elapsed (AC-13)',
          );
        });
      },
    );
  });
}
