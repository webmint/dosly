/// Widget tests for [TodayScreen] — covers the reactive Today checklist:
/// empty/loading/error states, the countdown card + collapsible hour groups
/// (AC-1..AC-5), checkbox-based take/undo and the skip icon (AC-6/AC-7),
/// Mark-all (AC-10), and the boundary-refresh Timer's live re-derivation plus
/// its `pumpAndSettle` safety (AC-15).
///
/// Provider-override strategy:
///   • Empty/seeded/action tests use a REAL in-memory [AppDatabase] with only
///     [appDatabaseProvider] overridden, so [medicationsListProvider] and
///     [intakesListProvider] run through the actual repository chain — this
///     is what proves persistence and reactivity end to end.
///   • The loading-state test overrides [medicationRepositoryProvider] and
///     [intakeRepositoryProvider] directly with fakes whose streams never
///     emit, so the `AsyncValue` stays `loading` deterministically.
///   • [todayIntakeSettingsProvider] is pinned to the default intake settings
///     in [_harness] (120-minute window, 5-minute grace, mark-ahead off) so
///     every dose's derived `windowState`/`actionable`/`undoable` is
///     deterministic without seeding `sharedPreferences`.
///
/// The undo-grace and boundary-timer tests drive a mutable [Clock] (not
/// [Clock.fixed]) so the screen's one-shot boundary-refresh [Timer] —
/// captured by flutter_test's `FakeAsync` zone — can be advanced via
/// `tester.pump(Duration(...))` without a real wall-clock wait, and the
/// subsequent rebuild observes an ADVANCED `clock.now()` reading (mutated
/// just before the pump) rather than a value frozen at zone-creation time.
library;

import 'dart:async';

import 'package:clock/clock.dart';
import 'package:dosly/core/database/database.dart';
import 'package:dosly/core/database/database_provider.dart';
import 'package:dosly/core/error/failures.dart';
import 'package:dosly/features/meds/data/datasources/intake_local_data_source.dart';
import 'package:dosly/features/meds/data/datasources/medication_local_data_source.dart';
import 'package:dosly/features/meds/data/repositories/intake_repository_impl.dart';
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
import 'package:dosly/features/meds/domain/usecases/reconcile_missed_intakes.dart';
import 'package:dosly/features/meds/domain/value_objects/intake_id.dart';
import 'package:dosly/features/meds/domain/value_objects/medication_id.dart';
import 'package:dosly/features/meds/domain/value_objects/time_slot_id.dart';
import 'package:dosly/features/meds/presentation/providers/intake_providers.dart';
import 'package:dosly/features/meds/presentation/providers/medication_providers.dart';
import 'package:dosly/features/meds/presentation/screens/today_screen.dart';
import 'package:dosly/features/meds/presentation/widgets/today_dose_tile.dart';
import 'package:dosly/features/meds/presentation/widgets/today_empty_state.dart';
import 'package:dosly/features/settings/domain/value_objects/grace_period.dart';
import 'package:dosly/features/settings/domain/value_objects/intake_window.dart';
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

/// Fixed "now": 2026-06-15 08:30 local. The morning slot (08:00) is open
/// (its default 120-minute window is 08:00–10:00) relative to this instant —
/// its hour group is [TodayGroupState.now] and starts expanded — while the
/// evening slot (20:00) is still [DoseWindowState.future] — its hour group is
/// [TodayGroupState.future] and starts collapsed.
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

/// Two continuous medications sharing the SAME 08:00 slot hour, used by the
/// Mark-all test: both doses land in the single `todayGroupSection-8`, both
/// open (actionable) at [_fixedNow], so the group's Mark-all button is
/// visible without any interaction.
final Medication _medMarkAllA = Medication(
  id: const MedicationId('med-markall-a'),
  name: 'MarkAll A',
  form: MedicationForm.tablet,
  type: MedicationType.continuous(startDate: DateTime(2026, 1, 1)),
  schedule: const Schedule(
    slots: [TimeSlot(id: TimeSlotId('slot-markall-a'), minuteOfDay: 480)],
  ),
  dosePerIntake: const Dosage(amount: 10, unit: DoseUnit.mg),
  createdAt: DateTime(2026, 1, 1),
);

final Medication _medMarkAllB = Medication(
  id: const MedicationId('med-markall-b'),
  name: 'MarkAll B',
  form: MedicationForm.tablet,
  type: MedicationType.continuous(startDate: DateTime(2026, 1, 1)),
  schedule: const Schedule(
    slots: [TimeSlot(id: TimeSlotId('slot-markall-b'), minuteOfDay: 480)],
  ),
  dosePerIntake: const Dosage(amount: 20, unit: DoseUnit.mg),
  createdAt: DateTime(2026, 1, 1),
);

/// Key of the rendered dose tile for the morning (08:00) dose — matches the
/// `'todayTile-<medicationId>-<slotId>'` scheme `today_screen.dart` keys each
/// tile with (now nested inside a `TodayGroupSection`).
const ValueKey<String> _morningTileKey = ValueKey<String>(
  'todayTile-med-today-001-slot-morning',
);

/// Key of the rendered dose tile for the evening (20:00) dose.
const ValueKey<String> _eveningTileKey = ValueKey<String>(
  'todayTile-med-today-001-slot-evening',
);

const ValueKey<String> _markAllTileKeyA = ValueKey<String>(
  'todayTile-med-markall-a-slot-markall-a',
);
const ValueKey<String> _markAllTileKeyB = ValueKey<String>(
  'todayTile-med-markall-b-slot-markall-b',
);

const ValueKey<String> _checkboxKey = ValueKey<String>('todayCheckbox');
const ValueKey<String> _skipIconKey = ValueKey<String>('todaySkipIcon');
const ValueKey<String> _undoKey = ValueKey<String>('todayUndo');
const ValueKey<String> _markAllKey = ValueKey<String>('todayMarkAll');
const ValueKey<String> _countdownCardKey = ValueKey<String>(
  'todayCountdownCard',
);

/// Key of a [TodayGroupSection]'s tappable header for wall-clock [hour].
Key _groupHeaderKey(int hour) => ValueKey<String>('todayGroupHeader-$hour');

/// Key of a [TodayGroupSection]'s outer container for wall-clock [hour].
Key _groupSectionKey(int hour) => ValueKey<String>('todayGroupSection-$hour');

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
  Future<Either<Failure, Intake>> markMissed(Intake intake) async =>
      Right(intake);

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
  Future<Either<Failure, Intake>> markMissed(Intake intake) async =>
      Right(intake);

  @override
  Future<Either<Failure, void>> undo(IntakeId id) async => const Right(null);
}

// ---------------------------------------------------------------------------
// Fakes for the on-open auto-miss trigger
// ---------------------------------------------------------------------------

/// No-op [ReconcileMissedIntakes] fake used as the DEFAULT override in
/// [_harness] so every pre-existing test (which never exercised the on-open
/// auto-miss trigger before it existed) keeps its deterministic checklist:
/// with the real use case now read fire-and-forget from `initState`, an
/// unoverridden [reconcileMissedIntakesProvider] would try to build against
/// the real settings/medication/intake repositories and error inside a
/// widget test.
///
/// [ReconcileMissedIntakes]'s constructor fields are private, so `implements`
/// only requires the public [call] method — mirrors
/// `integration_test/support/app_harness.dart`'s `_NoOpReconcileMissedIntakes`.
class _NoOpReconcile implements ReconcileMissedIntakes {
  @override
  Future<Either<Failure, int>> call({required DateTime now}) async =>
      const Right(0);
}

/// Counts [call] invocations — proves the Today screen's auto-miss trigger
/// fires exactly once per mount (from `initState`) and does NOT re-fire when
/// the screen rebuilds in response to a stream re-emission.
class _RecordingReconcileMissedIntakes implements ReconcileMissedIntakes {
  int callCount = 0;

  @override
  Future<Either<Failure, int>> call({required DateTime now}) async {
    callCount += 1;
    return const Right(0);
  }
}

/// Fake [ReconcileMissedIntakes] for the AC-12 reactive-missed test.
///
/// The real [ReconcileMissedIntakes] derives eligibility itself via
/// `watchAll().first` reads against the medication/intake repositories — those
/// drift `.watch()` first-emissions do not resolve inside the widget tester's
/// fake-async zone (the screen's `initState` reconcile call runs as a
/// [Future.microtask]), which hangs the test forever. Instead, this fake
/// writes the pre-computed [_missed] row DIRECTLY into the SAME shared
/// [_db] via a real [IntakeRepositoryImpl] — mirroring exactly how the
/// take/skip tests prove reactivity: a write lands in the shared db, the real
/// [intakesListProvider] (drift `.watch()`) re-emits, and the tile updates,
/// all with plain `pump()`/`pumpAndSettle()` — no `runAsync`, no polling.
class _WritesMissedReconcile implements ReconcileMissedIntakes {
  _WritesMissedReconcile(this._db, this._missed);

  final AppDatabase _db;
  final Intake _missed;

  @override
  Future<Either<Failure, int>> call({required DateTime now}) async {
    await IntakeRepositoryImpl(IntakeLocalDataSource(_db)).markMissed(_missed);
    return const Right(1);
  }
}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

/// Wraps [TodayScreen] in [ProviderScope] + [MaterialApp] with localization
/// pinned to English. [overrides] are appended after the base
/// [appDatabaseProvider], [reconcileMissedIntakesProvider], and
/// [todayIntakeSettingsProvider] overrides.
///
/// [reconcile] builds the [ReconcileMissedIntakes] the screen's `initState`
/// reads; it defaults to [_NoOpReconcile] because [TodayScreen] now fires
/// [reconcileMissedIntakesProvider] fire-and-forget from `initState` on every
/// mount, and leaving it unoverridden would build the real use case against
/// real (unwired) settings/medication/intake repositories and error. Tests
/// that exercise the trigger itself (the single-fire and AC-12 groups below)
/// pass their own [reconcile] builder instead of layering a second override
/// for the same provider into [overrides] — Riverpod asserts when the same
/// provider is overridden twice within one container.
///
/// [todayIntakeSettingsProvider] is pinned to [settings] — which defaults to
/// (120-minute window, 5-minute grace, mark-ahead off) — so [TodayScreen]'s
/// build-time `ref.watch` resolves deterministically without seeding
/// `sharedPreferences`. Every dose's derived `windowState`/`actionable`
/// (which gate the checkbox/skip-icon enablement) and `undoable` (which gates
/// the Undo affordance and a taken dose's checkbox reverting it) are computed
/// against these pinned values. Tests that need a specific value (e.g.
/// mark-ahead enabled) pass their own [settings] record instead of layering a
/// second override for the same provider into [overrides] — Riverpod asserts
/// when the same provider is overridden twice within one container (mirrors
/// why [reconcile] is its own parameter rather than an [overrides] entry).
Widget _harness({
  required AppDatabase db,
  List<Override> overrides = const [],
  ReconcileMissedIntakes Function(Ref ref)? reconcile,
  ({IntakeWindow intakeWindow, GracePeriod gracePeriod, bool allowMarkAhead})?
  settings,
}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      reconcileMissedIntakesProvider.overrideWith(
        reconcile ?? (ref) => _NoOpReconcile(),
      ),
      todayIntakeSettingsProvider.overrideWith(
        (ref) =>
            settings ??
            (
              intakeWindow: IntakeWindow.defaultValue,
              gracePeriod: GracePeriod.defaultValue,
              allowMarkAhead: false,
            ),
      ),
      ...overrides,
    ],
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TodayScreen(),
    ),
  );
}

/// Finds a keyed action button scoped to a specific tile, so identically-keyed
/// actions (`todayCheckbox`/`todaySkipIcon`/`todayUndo`) in different tiles
/// never collide.
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
      expect(find.byKey(_countdownCardKey), findsNothing);
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
        // No boundary Timer is ever scheduled on the error branch (it is
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
  // AC-1..AC-5 — countdown card + collapsible hour groups
  // ---------------------------------------------------------------------
  group('TodayScreen countdown card and hour groups', () {
    testWidgets(
      'renders the countdown card above the hour groups (ascending hour), '
      'with the "now" group expanded and the future group collapsed by '
      'default',
      (tester) async {
        await withClock(_fixedClock, () async {
          final repo = MedicationRepositoryImpl(MedicationLocalDataSource(db));
          await repo.add(_aspirin);

          await tester.pumpWidget(_harness(db: db));
          await tester.pumpAndSettle();
        });

        final double cardY = tester
            .getTopLeft(find.byKey(_countdownCardKey))
            .dy;
        final double group8Y = tester
            .getTopLeft(find.byKey(_groupSectionKey(8)))
            .dy;
        final double group20Y = tester
            .getTopLeft(find.byKey(_groupSectionKey(20)))
            .dy;
        expect(
          cardY,
          lessThan(group8Y),
          reason: 'The countdown card must render above the hour groups',
        );
        expect(
          group8Y,
          lessThan(group20Y),
          reason: 'The 08:00 group must render above the 20:00 group',
        );

        // The countdown card shows the next (evening) intake, not "all done".
        final AppLocalizations l10n = AppLocalizations.of(
          tester.element(find.byType(TodayScreen)),
        )!;
        expect(
          find.descendant(
            of: find.byKey(_countdownCardKey),
            matching: find.text(l10n.todayAllDone),
          ),
          findsNothing,
        );

        // AC-3: the 08:00 group is "now" (its dose's window is open) and
        // starts expanded — its tile renders with no interaction.
        expect(find.byKey(_morningTileKey), findsOneWidget);

        // The 20:00 group is "future" and starts collapsed — its tile does
        // not render until the header is tapped.
        expect(find.byKey(_eveningTileKey), findsNothing);

        await tester.tap(find.byKey(_groupHeaderKey(20)));
        await tester.pumpAndSettle();

        expect(find.byKey(_eveningTileKey), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------
  // AC-6 — checkbox marks a pending dose taken
  // ---------------------------------------------------------------------
  group('TodayScreen checkbox — mark taken', () {
    testWidgets(
      "checking a pending dose's todayCheckbox marks it taken and persists "
      'the intake',
      (tester) async {
        await withClock(_fixedClock, () async {
          final repo = MedicationRepositoryImpl(MedicationLocalDataSource(db));
          await repo.add(_aspirin);

          await tester.pumpWidget(_harness(db: db));
          await tester.pumpAndSettle();

          await tester.tap(_actionIn(_morningTileKey, _checkboxKey));
          // Drain the microtask/stream re-emit, then rebuild.
          await tester.pump();
          await tester.pump();
        });

        expect(
          tester
              .widget<Checkbox>(_actionIn(_morningTileKey, _checkboxKey))
              .value,
          isTrue,
        );

        final rows = await db.select(db.intakes).get();
        expect(rows, hasLength(1));
        expect(rows.single.status, IntakeStatus.taken);
        expect(rows.single.medicationId, 'med-today-001');
        expect(rows.single.slotId, 'slot-morning');
      },
    );

    testWidgets(
      'a mark-ahead-enabled dose scheduled later today can still be marked '
      'taken once its collapsed group is expanded (early marking)',
      (tester) async {
        await withClock(_fixedClock, () async {
          final repo = MedicationRepositoryImpl(MedicationLocalDataSource(db));
          await repo.add(_aspirin);

          // The evening (20:00) dose is DoseWindowState.future relative to
          // _fixedNow (08:30) — only actionable ahead of its window when
          // mark-ahead is enabled, so this test overrides it explicitly
          // (the harness default pins allowMarkAhead to false).
          await tester.pumpWidget(
            _harness(
              db: db,
              settings: (
                intakeWindow: IntakeWindow.defaultValue,
                gracePeriod: GracePeriod.defaultValue,
                allowMarkAhead: true,
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(_groupHeaderKey(20)));
          await tester.pumpAndSettle();

          await tester.tap(_actionIn(_eveningTileKey, _checkboxKey));
          await tester.pump();
          await tester.pump();
        });

        final rows = await db.select(db.intakes).get();
        expect(rows, hasLength(1));
        expect(rows.single.slotId, 'slot-evening');
        expect(rows.single.status, IntakeStatus.taken);
      },
    );
  });

  // ---------------------------------------------------------------------
  // AC-6 — unchecking a just-taken dose undoes it within grace
  // ---------------------------------------------------------------------
  group('TodayScreen checkbox — undo within grace', () {
    testWidgets(
      'unchecking a just-taken dose within its grace window reverts it to '
      'pending',
      (tester) async {
        await withClock(_fixedClock, () async {
          final repo = MedicationRepositoryImpl(MedicationLocalDataSource(db));
          await repo.add(_aspirin);

          await tester.pumpWidget(_harness(db: db));
          await tester.pumpAndSettle();

          await tester.tap(_actionIn(_morningTileKey, _checkboxKey));
          await tester.pump();
          await tester.pump();
          expect(
            tester
                .widget<Checkbox>(_actionIn(_morningTileKey, _checkboxKey))
                .value,
            isTrue,
            reason: 'The checkbox must render checked once taken',
          );

          // Unchecking the checked checkbox invokes onUndo (AC-6).
          await tester.tap(_actionIn(_morningTileKey, _checkboxKey));
          await tester.pump();
          await tester.pump();
        });

        expect(
          tester
              .widget<Checkbox>(_actionIn(_morningTileKey, _checkboxKey))
              .value,
          isFalse,
          reason: 'Undo must revert the dose back to pending',
        );
        final rows = await db.select(db.intakes).get();
        expect(rows, isEmpty);
      },
    );
  });

  // ---------------------------------------------------------------------
  // AC-7 — skip icon marks a pending dose skipped
  // ---------------------------------------------------------------------
  group('TodayScreen skip icon', () {
    testWidgets(
      'tapping todaySkipIcon marks a pending dose skipped and persists the '
      'intake',
      (tester) async {
        await withClock(_fixedClock, () async {
          final repo = MedicationRepositoryImpl(MedicationLocalDataSource(db));
          await repo.add(_aspirin);

          await tester.pumpWidget(_harness(db: db));
          await tester.pumpAndSettle();

          await tester.tap(_actionIn(_morningTileKey, _skipIconKey));
          await tester.pump();
          await tester.pump();
        });

        final rows = await db.select(db.intakes).get();
        expect(rows, hasLength(1));
        expect(rows.single.status, IntakeStatus.skipped);

        // A skipped dose within grace still offers Undo (distinct from the
        // checkbox-based undo used for a taken dose).
        expect(_actionIn(_morningTileKey, _undoKey), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------
  // AC-10 — Mark-all confirms every actionable pending dose in a group
  // ---------------------------------------------------------------------
  group('TodayScreen Mark-all', () {
    testWidgets(
      'tapping todayMarkAll marks every actionable pending dose in the '
      'group taken',
      (tester) async {
        await withClock(_fixedClock, () async {
          final repo = MedicationRepositoryImpl(MedicationLocalDataSource(db));
          await repo.add(_medMarkAllA);
          await repo.add(_medMarkAllB);

          await tester.pumpWidget(_harness(db: db));
          await tester.pumpAndSettle();

          expect(find.byKey(_markAllKey), findsOneWidget);

          await tester.tap(find.byKey(_markAllKey));
          await tester.pumpAndSettle();
        });

        final rows = await db.select(db.intakes).get();
        expect(rows, hasLength(2));
        expect(rows.every((r) => r.status == IntakeStatus.taken), isTrue);

        expect(
          tester
              .widget<Checkbox>(_actionIn(_markAllTileKeyA, _checkboxKey))
              .value,
          isTrue,
        );
        expect(
          tester
              .widget<Checkbox>(_actionIn(_markAllTileKeyB, _checkboxKey))
              .value,
          isTrue,
        );
      },
    );
  });

  // ---------------------------------------------------------------------
  // AC-15 — boundary Timer re-derives live and never busy-loops
  // ---------------------------------------------------------------------
  group('TodayScreen boundary timer', () {
    testWidgets(
      'advancing the clock past the grace window locks the checkbox; '
      'pumpAndSettle settles without hanging (one-shot Timer, no busy-loop)',
      (tester) async {
        // A mutable clock (not Clock.fixed): the boundary-refresh Timer runs
        // in this zone, so mutating `mutableNow` just before advancing the
        // FakeAsync clock via tester.pump(duration) lets the Timer-triggered
        // rebuild observe the ADVANCED time.
        DateTime mutableNow = _fixedNow;
        final Clock testClock = Clock(() => mutableNow);

        await withClock(testClock, () async {
          final repo = MedicationRepositoryImpl(MedicationLocalDataSource(db));
          await repo.add(_aspirin);

          await tester.pumpWidget(_harness(db: db));
          await tester.pumpAndSettle();

          // 1) Check the box; the dose is undoable within its grace window.
          await tester.tap(_actionIn(_morningTileKey, _checkboxKey));
          await tester.pump();
          await tester.pump();
          expect(
            tester
                .widget<Checkbox>(_actionIn(_morningTileKey, _checkboxKey))
                .onChanged,
            isNotNull,
            reason: 'Just-taken dose must be undoable within grace',
          );

          // 2) Advance past the 5-minute default grace window. The boundary
          // Timer scheduled for the grace expiry fires during the FakeAsync
          // elapse, calls setState, and the rebuild reads the now-advanced
          // clock.
          mutableNow = _fixedNow.add(const Duration(minutes: 6));
          await tester.pump(const Duration(minutes: 6));

          // 3) The one-shot Timer must not busy-loop: settling here must not
          // hang or time out.
          await tester.pumpAndSettle();
        });

        expect(
          tester
              .widget<Checkbox>(_actionIn(_morningTileKey, _checkboxKey))
              .value,
          isTrue,
          reason: 'The dose stays taken once the grace window has elapsed',
        );
        expect(
          tester
              .widget<Checkbox>(_actionIn(_morningTileKey, _checkboxKey))
              .onChanged,
          isNull,
          reason:
              'The checkbox must lock (no more Undo) once the grace window '
              'has elapsed',
        );
      },
    );
  });

  // ---------------------------------------------------------------------
  // Spec 040 — on-open auto-miss trigger: fires once per mount, never on a
  // rebuild (no reconcile↔rebuild loop)
  // ---------------------------------------------------------------------
  group('TodayScreen on-open auto-miss trigger', () {
    testWidgets(
      'fires reconcileMissedIntakesProvider exactly once on mount; a rebuild '
      'driven by an intakesListProvider re-emission does not re-fire it',
      (tester) async {
        final recorder = _RecordingReconcileMissedIntakes();

        await withClock(_fixedClock, () async {
          final repo = MedicationRepositoryImpl(MedicationLocalDataSource(db));
          await repo.add(_aspirin);

          await tester.pumpWidget(
            _harness(db: db, reconcile: (ref) => recorder),
          );
          await tester.pumpAndSettle();

          expect(
            recorder.callCount,
            1,
            reason:
                '`initState` runs exactly once per mount, so opening the '
                'Today screen must fire reconcile exactly once',
          );

          // Checking the box persists an intake through the real repository
          // chain, so intakesListProvider re-emits — the resulting rebuild
          // flows through ref.watch in build(), never through initState.
          await tester.tap(_actionIn(_morningTileKey, _checkboxKey));
          await tester.pump();
          await tester.pump();

          expect(
            recorder.callCount,
            1,
            reason:
                'A rebuild triggered by a stream re-emission must NOT '
                're-enter initState — there is no reconcile↔rebuild loop',
          );
        });
      },
    );
  });

  // ---------------------------------------------------------------------
  // Spec 040 AC-12 — reactive auto-miss on load
  // ---------------------------------------------------------------------
  group('TodayScreen spec 040 AC-12 reactive auto-miss on load', () {
    testWidgets(
      'a past-window pending dose renders Missed after mount with no manual '
      "refresh, once its (collapsed-by-default) group is expanded; a dose "
      "whose window has not yet closed stays pending in its expanded-by-"
      'default group',
      (tester) async {
        // 09:00 local: the 05:00 slot's default 120-minute window closed at
        // 07:00 (strictly past) — eligible for auto-miss, so its hour group
        // is "past" and starts COLLAPSED. The 10:00 slot's window closes at
        // 12:00 (not yet elapsed) — its hour group is the soonest "future"
        // group and starts EXPANDED (no "now" group exists).
        final DateTime fixedNow = DateTime(2026, 6, 15, 9);
        final Clock testClock = Clock.fixed(fixedNow);

        final Medication med = Medication(
          id: const MedicationId('med-automiss-001'),
          name: 'Ibuprofen',
          form: MedicationForm.tablet,
          type: MedicationType.continuous(startDate: DateTime(2026, 1, 1)),
          schedule: const Schedule(
            slots: [
              TimeSlot(id: TimeSlotId('slot-early'), minuteOfDay: 300), // 05:00
              TimeSlot(id: TimeSlotId('slot-late'), minuteOfDay: 600), // 10:00
            ],
          ),
          dosePerIntake: const Dosage(amount: 200, unit: DoseUnit.mg),
          createdAt: DateTime(2026, 1, 1),
        );

        const ValueKey<String> earlyTileKey = ValueKey<String>(
          'todayTile-med-automiss-001-slot-early',
        );
        const ValueKey<String> lateTileKey = ValueKey<String>(
          'todayTile-med-automiss-001-slot-late',
        );

        // The occurrence a real [ReconcileMissedIntakes] run would derive for
        // slot-early: its window (05:00 + the default 120-minute window =
        // 07:00) has closed before `fixedNow` (09:00), so reconciliation
        // would write exactly this row. [_WritesMissedReconcile] writes it
        // directly into the shared [db] instead of re-deriving it via its own
        // `watchAll().first` reads, so the test proves the REACTIVE pickup —
        // real db write → real `intakesListProvider` stream → tile rebuild —
        // the same real-DB-through-drift-watch path the take/skip tests
        // already exercise, with plain `pump()`/`pumpAndSettle()`.
        final Intake missedIntake = Intake(
          id: const IntakeId('intake-automiss-early-001'),
          medicationId: med.id,
          slotId: const TimeSlotId('slot-early'),
          scheduledAt: DateTime(2026, 6, 15, 5).toUtc(),
          confirmedAt: null,
          status: IntakeStatus.missed,
        );

        await withClock(testClock, () async {
          final repo = MedicationRepositoryImpl(MedicationLocalDataSource(db));
          await repo.add(med);

          await tester.pumpWidget(
            _harness(
              db: db,
              reconcile: (ref) => _WritesMissedReconcile(db, missedIntake),
            ),
          );
          await tester.pumpAndSettle();

          // The early dose's group is "past" and starts collapsed — expand
          // it to reveal the reconciled Missed row.
          await tester.tap(find.byKey(_groupHeaderKey(5)));
          await tester.pumpAndSettle();
        });

        // The early dose's window closed before `now` — reconciled to
        // `missed` reactively on load, with no manual refresh.
        expect(
          find.descendant(
            of: find.byKey(earlyTileKey),
            matching: find.text('Missed'),
          ),
          findsOneWidget,
        );
        expect(_actionIn(earlyTileKey, _checkboxKey), findsNothing);
        expect(_actionIn(earlyTileKey, _skipIconKey), findsNothing);

        // The late dose's group is the soonest "future" group and starts
        // expanded; its window has not yet closed — stays pending. The
        // checkbox renders (disabled: mark-ahead is off) but the skip icon
        // is hidden (only shown while actionable).
        expect(_actionIn(lateTileKey, _checkboxKey), findsOneWidget);
        expect(
          tester
              .widget<Checkbox>(_actionIn(lateTileKey, _checkboxKey))
              .onChanged,
          isNull,
        );
        expect(_actionIn(lateTileKey, _skipIconKey), findsNothing);

        final rows = await db.select(db.intakes).get();
        expect(rows, hasLength(1));
        expect(rows.single.slotId, 'slot-early');
        expect(rows.single.status, IntakeStatus.missed);
      },
    );
  });

  // ---------------------------------------------------------------------
  // Spec 040 AC-12 (second half) — idle-open: no live flip to missed
  // ---------------------------------------------------------------------
  group('TodayScreen spec 040 AC-12 idle-open no live flip', () {
    testWidgets(
      'a pending dose whose window closes while the screen sits idle-open '
      'does NOT live-flip to missed — enablement re-derives live via the '
      'boundary timer, but status only ever changes on the next '
      'reconcile-on-load',
      (tester) async {
        // A mutable clock (not Clock.fixed), mirroring the boundary-timer
        // test above: mutating `mutableNow` just before advancing the
        // FakeAsync clock via tester.pump(duration) lets any rebuild
        // triggered by that pump observe the ADVANCED time.
        //
        // 11:00 local: the 10:00 slot's default 120-minute window closes at
        // 12:00 — still OPEN at mount, so the dose renders pending and
        // actionable (checkbox enabled, skip icon shown).
        DateTime mutableNow = DateTime(2026, 6, 15, 11);
        final Clock testClock = Clock(() => mutableNow);

        final Medication med = Medication(
          id: const MedicationId('med-idleopen-001'),
          name: 'Paracetamol',
          form: MedicationForm.tablet,
          type: MedicationType.continuous(startDate: DateTime(2026, 1, 1)),
          schedule: const Schedule(
            slots: [
              TimeSlot(id: TimeSlotId('slot-idle'), minuteOfDay: 600), // 10:00
            ],
          ),
          dosePerIntake: const Dosage(amount: 500, unit: DoseUnit.mg),
          createdAt: DateTime(2026, 1, 1),
        );

        const ValueKey<String> idleTileKey = ValueKey<String>(
          'todayTile-med-idleopen-001-slot-idle',
        );

        await withClock(testClock, () async {
          final repo = MedicationRepositoryImpl(MedicationLocalDataSource(db));
          await repo.add(med);

          // No override for `reconcile` — the harness default
          // `_NoOpReconcile` fires on `initState` and writes NOTHING, so the
          // db stays exactly as seeded.
          await tester.pumpWidget(_harness(db: db));
          await tester.pumpAndSettle();

          // Window still open at mount (10:00 + 120 min = 12:00 > 11:00):
          // pending, checkbox enabled, skip icon shown, no Missed label.
          expect(_actionIn(idleTileKey, _checkboxKey), findsOneWidget);
          expect(
            tester
                .widget<Checkbox>(_actionIn(idleTileKey, _checkboxKey))
                .onChanged,
            isNotNull,
          );
          expect(_actionIn(idleTileKey, _skipIconKey), findsOneWidget);
          expect(
            find.descendant(
              of: find.byKey(idleTileKey),
              matching: find.text('Missed'),
            ),
            findsNothing,
          );

          // Advance the mutable clock PAST the window close (11:00 -> 14:00)
          // while the screen stays mounted, with NO fresh reconcile run. A
          // boundary Timer WAS scheduled for the window-close instant
          // (12:00): it fires during this elapse and calls setState, but it
          // performs NO database write and triggers NO reconciliation — only
          // the derived enablement re-renders.
          mutableNow = mutableNow.add(const Duration(hours: 3));
          await tester.pump(const Duration(hours: 3));
          await tester.pumpAndSettle();

          // Still pending: the window has closed, so the checkbox locks
          // (disabled) and the skip icon disappears, but the STATUS must not
          // flip to missed from time passing alone — only the next
          // reconcile-on-load can do that.
          expect(
            _actionIn(idleTileKey, _checkboxKey),
            findsOneWidget,
            reason:
                'Time passing alone while the screen sits idle-open must '
                'not remove the checkbox, and must never flip a pending '
                'dose to missed — there is no live-flip to missed (AC-12)',
          );
          expect(
            tester
                .widget<Checkbox>(_actionIn(idleTileKey, _checkboxKey))
                .onChanged,
            isNull,
            reason: 'The checkbox must lock once the window has closed',
          );
          expect(_actionIn(idleTileKey, _skipIconKey), findsNothing);
          expect(
            find.descendant(
              of: find.byKey(idleTileKey),
              matching: find.text('Missed'),
            ),
            findsNothing,
          );
        });

        // Nothing was written by time passing — the db stays exactly as
        // seeded (empty), proving no reconcile ran.
        final rows = await db.select(db.intakes).get();
        expect(rows, isEmpty);
      },
    );
  });
}
