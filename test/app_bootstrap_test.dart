/// Widget tests for [AppBootstrap].
///
/// Covers the three async branches driven by [sharedPreferencesInitProvider]:
/// loading (SplashScreen), error (PrefsLoadErrorScreen + retry), and data
/// (DoslyApp). Also asserts that only one MaterialApp is mounted per phase.
library;

import 'dart:async';

import 'package:dosly/app.dart';
import 'package:dosly/app_bootstrap.dart';
import 'package:dosly/core/database/database.dart';
import 'package:dosly/core/database/database_provider.dart';
import 'package:dosly/core/error/failures.dart';
import 'package:dosly/core/providers/shared_preferences_provider.dart';
import 'package:dosly/core/widgets/prefs_load_error_screen.dart';
import 'package:dosly/core/widgets/splash_screen.dart';
import 'package:dosly/features/meds/domain/usecases/reconcile_missed_intakes.dart';
import 'package:dosly/features/meds/presentation/providers/intake_providers.dart';
import 'package:dosly/features/settings/domain/entities/app_language.dart';
import 'package:dosly/features/settings/domain/entities/app_settings.dart';
import 'package:dosly/features/settings/domain/entities/app_theme_mode.dart';
import 'package:dosly/features/settings/domain/repositories/settings_repository.dart';
import 'package:dosly/features/settings/domain/value_objects/grace_period.dart';
import 'package:dosly/features/settings/domain/value_objects/intake_window.dart';
import 'package:dosly/features/settings/presentation/providers/settings_provider.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferencesWithCache, SharedPreferencesWithCacheOptions;
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Minimal [SettingsRepository] fake used so the data branch can fully
/// inflate [DoslyApp] without a real SharedPreferences instance driving
/// the settings provider tree.
class _FakeSettingsRepository implements SettingsRepository {
  @override
  Either<Failure, AppSettings> load() => const Right(AppSettings());

  @override
  Future<Either<Never, void>> saveThemeMode(AppThemeMode mode) async =>
      const Right(null);

  @override
  Future<Either<Never, void>> saveUseSystemTheme(bool value) async =>
      const Right(null);

  @override
  Future<Either<Never, void>> saveUseSystemLanguage(bool value) async =>
      const Right(null);

  @override
  Future<Either<Never, void>> saveManualLanguage(AppLanguage language) async =>
      const Right(null);

  @override
  Future<Either<Never, void>> saveIntakeWindow(IntakeWindow window) async =>
      const Right(null);

  @override
  Future<Either<Never, void>> saveGracePeriod(GracePeriod grace) async =>
      const Right(null);

  @override
  Future<Either<Never, void>> saveAllowMarkAhead(bool value) async =>
      const Right(null);
}

/// No-op [ReconcileMissedIntakes] fake used to neutralize the on-open
/// auto-miss trigger ([reconcileMissedOnOpenProvider]) that [AppBootstrap]
/// fires (fire-and-forget) on every data-branch build, so the real
/// repositories/DB are never touched by this startup side-effect during
/// bootstrap assertions.
///
/// [ReconcileMissedIntakes]'s constructor fields are private, so `implements`
/// only requires the public [call] method — this is the intended ergonomic
/// override shape for a use case with no public interface to re-declare.
class _NoOpReconcileMissedIntakes implements ReconcileMissedIntakes {
  @override
  Future<Either<Failure, int>> call({required DateTime now}) async =>
      const Right(0);
}

/// Recording [ReconcileMissedIntakes] fake used to prove that the data
/// branch's on-open auto-miss trigger ([reconcileMissedOnOpenProvider], read
/// by [AppBootstrap]) actually reads this use case, rather than merely
/// exercising a no-op stand-in that would look identical whether the trigger
/// line exists or was deleted. Mirrors
/// `_RecordingReconcileMissedIntakes` in
/// `test/features/meds/presentation/screens/today_screen_test.dart`.
class _RecordingReconcileMissedIntakes implements ReconcileMissedIntakes {
  int callCount = 0;

  @override
  Future<Either<Failure, int>> call({required DateTime now}) async {
    callCount += 1;
    return const Right(0);
  }
}

/// Failing [ReconcileMissedIntakes] fake used to prove that
/// [reconcileMissedOnOpenProvider]'s internal fold-to-logger (see
/// `intake_providers.dart`) swallows a reconcile [Left] instead of letting it
/// surface as a startup error — [AppBootstrap] must still mount [DoslyApp]
/// normally.
class _FailingReconcileMissedIntakes implements ReconcileMissedIntakes {
  @override
  Future<Either<Failure, int>> call({required DateTime now}) async =>
      const Left(Failure.cache('boom'));
}

/// Creates a real [SharedPreferencesWithCache] instance wired to in-memory
/// storage, ready for use in success-branch tests.
///
/// Uses [InMemorySharedPreferencesAsync] — the correct platform mock for
/// the async SharedPreferences API used by [SharedPreferencesWithCache].
Future<SharedPreferencesWithCache> _buildRealPrefs() async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  return SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: <String>{
        'themeMode',
        'useSystemTheme',
        'useSystemLanguage',
        'manualLanguage',
      },
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferencesWithCache realPrefs;
  late _FakeSettingsRepository fakeRepo;
  late AppDatabase db;

  setUpAll(() async {
    realPrefs = await _buildRealPrefs();
  });

  setUp(() {
    fakeRepo = _FakeSettingsRepository();
    // Every test that reaches the data branch mounts the real DoslyApp router,
    // whose '/' branch is TodayScreen — it watches medicationsListProvider /
    // intakesListProvider, both derived from appDatabaseProvider. Without this
    // override the real (unregistered-platform-channel) database never
    // resolves, so TodayScreen stays in AsyncValue.loading and its
    // CircularProgressIndicator's indeterminate animation makes
    // pumpAndSettle() time out. closeStreamsSynchronously: true avoids a
    // "Timer is still pending" teardown failure, mirroring app_router_test.dart.
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

  // -------------------------------------------------------------------------
  // Error branch
  // -------------------------------------------------------------------------

  group('error branch', () {
    /// When init throws, the error branch must show [PrefsLoadErrorScreen]
    /// with the localized "couldn't load" message inside exactly one
    /// [MaterialApp].
    testWidgets(
      'shows PrefsLoadErrorScreen with localized message when init fails',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesInitProvider.overrideWith(
                (ref) =>
                    Future<SharedPreferencesWithCache>.error(Exception('boom')),
              ),
              // Neutralize the on-open auto-miss trigger for isolation (this
              // branch never reaches `data:`, so it would never be read here,
              // but overriding keeps every AppBootstrap ProviderScope in this
              // file consistent — see MEMORY 035).
              reconcileMissedIntakesProvider.overrideWith(
                (ref) => _NoOpReconcileMissedIntakes(),
              ),
            ],
            child: const AppBootstrap(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PrefsLoadErrorScreen), findsOneWidget);
        // English localized message (test harness default locale is en).
        expect(find.text("We couldn't load your preferences."), findsOneWidget);
        // Exactly one MaterialApp — the bootstrap shell.
        expect(find.byType(MaterialApp), findsOneWidget);
      },
    );
  });

  // -------------------------------------------------------------------------
  // Loading branch
  // -------------------------------------------------------------------------

  group('loading branch', () {
    /// While init is pending, the loading branch must show [SplashScreen] with
    /// a [CircularProgressIndicator] inside exactly one [MaterialApp]. We
    /// complete the Completer at the end to avoid a pending-timer failure.
    testWidgets('shows SplashScreen with spinner while init is pending', (
      WidgetTester tester,
    ) async {
      final completer = Completer<SharedPreferencesWithCache>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesInitProvider.overrideWith(
              (ref) => completer.future,
            ),
            // Provide a fake settings repo so DoslyApp can inflate once the
            // completer resolves (avoids the synchronous-provider throw).
            settingsRepositoryProvider.overrideWithValue(fakeRepo),
            appDatabaseProvider.overrideWithValue(db),
            // Neutralize the on-open auto-miss trigger: once the completer
            // resolves, the data branch mounts and reads
            // reconcileMissedOnOpenProvider, which would otherwise run the
            // real use case against db.
            reconcileMissedIntakesProvider.overrideWith(
              (ref) => _NoOpReconcileMissedIntakes(),
            ),
          ],
          child: const AppBootstrap(),
        ),
      );
      // One frame — the future is still pending.
      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Resolve to avoid a "pending timers" failure at the end of the test.
      completer.complete(realPrefs);
      await tester.pumpAndSettle();
    });
  });

  // -------------------------------------------------------------------------
  // Retry recovery
  // -------------------------------------------------------------------------

  group('retry recovery', () {
    /// The Retry button must call [ref.invalidate] on the init provider,
    /// causing AppBootstrap to re-watch it. When the second attempt succeeds
    /// [PrefsLoadErrorScreen] must disappear.
    testWidgets(
      'tapping Retry recovers from error when the second attempt succeeds',
      (WidgetTester tester) async {
        var shouldFail = true;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesInitProvider.overrideWith(
                (ref) => shouldFail
                    ? Future<SharedPreferencesWithCache>.error(
                        Exception('boom'),
                      )
                    : Future<SharedPreferencesWithCache>.value(realPrefs),
              ),
              // Provide a fake settings repo so DoslyApp can inflate after
              // retry succeeds.
              settingsRepositoryProvider.overrideWithValue(fakeRepo),
              appDatabaseProvider.overrideWithValue(db),
              // Neutralize the on-open auto-miss trigger: after a successful
              // retry, the data branch mounts and reads
              // reconcileMissedOnOpenProvider, which would otherwise run the
              // real use case against db.
              reconcileMissedIntakesProvider.overrideWith(
                (ref) => _NoOpReconcileMissedIntakes(),
              ),
            ],
            child: const AppBootstrap(),
          ),
        );
        await tester.pumpAndSettle();

        // Error screen is shown.
        expect(find.byType(PrefsLoadErrorScreen), findsOneWidget);

        // Next attempt will succeed.
        shouldFail = false;

        // Tap the Retry FilledButton.
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        // Error screen is gone and DoslyApp is mounted — recovery confirmed.
        expect(find.byType(PrefsLoadErrorScreen), findsNothing);
        expect(find.byType(DoslyApp), findsOneWidget);
      },
    );
  });

  // -------------------------------------------------------------------------
  // Normal launch (data branch)
  // -------------------------------------------------------------------------

  group('normal launch', () {
    /// On a successful init the data branch must mount [DoslyApp] directly
    /// (no bootstrap shell) so there is still exactly one [MaterialApp].
    testWidgets(
      'reaches DoslyApp with exactly one MaterialApp on successful init',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesInitProvider.overrideWith(
                (ref) => Future<SharedPreferencesWithCache>.value(realPrefs),
              ),
              // Provide a fake settings repo so the settings provider tree
              // does not hit the real SharedPreferences.
              settingsRepositoryProvider.overrideWithValue(fakeRepo),
              appDatabaseProvider.overrideWithValue(db),
              // Neutralize the on-open auto-miss trigger: the data branch
              // reads reconcileMissedOnOpenProvider immediately, which would
              // otherwise run the real use case against db.
              reconcileMissedIntakesProvider.overrideWith(
                (ref) => _NoOpReconcileMissedIntakes(),
              ),
            ],
            child: const AppBootstrap(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DoslyApp), findsOneWidget);
        // DoslyApp brings MaterialApp.router; the bootstrap shell must NOT be
        // present at the same time.
        expect(find.byType(MaterialApp), findsOneWidget);
      },
    );
  });

  // -------------------------------------------------------------------------
  // Real settings wiring (regression)
  // -------------------------------------------------------------------------

  group('real settings wiring', () {
    /// Regression test for the startup crash where the settings provider tree
    /// resolved [sharedPreferencesProvider] in the root container (throwing
    /// "must be overridden by AppBootstrap") because a nested-scope override
    /// did not propagate to the un-scoped settings providers.
    ///
    /// Unlike the other data-branch tests, this one deliberately does NOT
    /// override [settingsRepositoryProvider], so the REAL chain runs:
    /// DoslyApp → settingsNotifier → settingsRepository →
    /// sharedPreferencesProvider. With the fix, sharedPreferencesProvider reads
    /// the resolved [sharedPreferencesInitProvider] value, so DoslyApp inflates
    /// without throwing.
    testWidgets(
      'data branch inflates DoslyApp via the real settings provider chain',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesInitProvider.overrideWith(
                (ref) => Future<SharedPreferencesWithCache>.value(realPrefs),
              ),
              // settingsRepositoryProvider is intentionally NOT overridden —
              // sharedPreferencesProvider must serve the resolved prefs.
              appDatabaseProvider.overrideWithValue(db),
              // Neutralize the on-open auto-miss trigger: the data branch
              // reads reconcileMissedOnOpenProvider immediately, which would
              // otherwise run the real use case against db and could leave a
              // dangling async operation racing db.close() in tearDown.
              reconcileMissedIntakesProvider.overrideWith(
                (ref) => _NoOpReconcileMissedIntakes(),
              ),
            ],
            child: const AppBootstrap(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DoslyApp), findsOneWidget);
        // No ProviderException (or any error) escaped during build.
        expect(tester.takeException(), isNull);
      },
    );
  });

  // -------------------------------------------------------------------------
  // On-open reconcile trigger fires (AC-10)
  // -------------------------------------------------------------------------

  group('on-open reconcile trigger', () {
    /// Every other data-branch test in this file neutralizes the on-open
    /// auto-miss trigger with a bare no-op fake and never asserts it was
    /// called — so none of them would fail if
    /// `ref.read(reconcileMissedOnOpenProvider)` were deleted from
    /// [AppBootstrap]. This test closes that gap.
    ///
    /// IMPORTANT: [TodayScreen] (mounted by the real router inside
    /// [DoslyApp]) ALSO independently reads [reconcileMissedIntakesProvider]
    /// from its own `initState` microtask (its own reactive-missed trigger,
    /// unrelated to [AppBootstrap]). That means a RECORDING fake's
    /// `callCount` alone cannot distinguish "AppBootstrap's trigger fired"
    /// from "only TodayScreen's own trigger fired" — a callCount >= 1 would
    /// stay true even if `ref.read(reconcileMissedOnOpenProvider)` were
    /// deleted from AppBootstrap entirely. To isolate AppBootstrap's own
    /// trigger, this test uses an explicit [ProviderContainer] (via
    /// [UncontrolledProviderScope]) and asserts
    /// `container.exists(reconcileMissedOnOpenProvider)` — which reports
    /// whether that SPECIFIC provider's element was ever created, without
    /// creating it itself (unlike `container.read`, which would trivially
    /// create it right here and always pass). Production code greps show
    /// `reconcileMissedOnOpenProvider` is read ONLY from
    /// `app_bootstrap.dart`, so a `true` here can only come from
    /// [AppBootstrap]'s `data:` branch.
    testWidgets(
      'reads reconcileMissedOnOpenProvider on the data branch, invoking '
      'the reconcile use case',
      (WidgetTester tester) async {
        final recorder = _RecordingReconcileMissedIntakes();
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesInitProvider.overrideWith(
              (ref) => Future<SharedPreferencesWithCache>.value(realPrefs),
            ),
            // Same fake settings repo as the other data-branch tests so
            // DoslyApp inflates without touching real SharedPreferences.
            settingsRepositoryProvider.overrideWithValue(fakeRepo),
            appDatabaseProvider.overrideWithValue(db),
            // The fake under test: records every `call` instead of
            // no-op'ing silently.
            reconcileMissedIntakesProvider.overrideWith((ref) => recorder),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const AppBootstrap(),
          ),
        );
        // The keepAlive FutureProvider's build starts synchronously on
        // first read, but pumpAndSettle drains any pending
        // microtasks/frames from the rest of the DoslyApp tree (router,
        // TodayScreen's own data watches) so the widget tree is fully
        // settled before asserting.
        await tester.pumpAndSettle();

        expect(find.byType(DoslyApp), findsOneWidget);
        expect(
          container.exists(reconcileMissedOnOpenProvider),
          isTrue,
          reason:
              'AppBootstrap.build must read reconcileMissedOnOpenProvider '
              'on the data branch — its element must exist in the '
              'container. Deleting `ref.read(reconcileMissedOnOpenProvider)` '
              'from AppBootstrap would make this false even though '
              "TodayScreen's own independent trigger still fires.",
        );
        // Sanity check: the use case itself was reached (via either
        // trigger) — the container.exists assertion above is what actually
        // isolates AppBootstrap's contribution.
        expect(recorder.callCount, greaterThanOrEqualTo(1));
      },
    );
  });

  // -------------------------------------------------------------------------
  // On-open reconcile failure is swallowed (AC-10)
  // -------------------------------------------------------------------------

  group('on-open reconcile failure swallowed', () {
    /// [reconcileMissedOnOpenProvider] folds the reconcile `Either`
    /// internally and never rethrows: a `Left` is only logged. This test
    /// proves that contract holds end-to-end through [AppBootstrap] — a
    /// failing reconcile use case must not surface as a startup error.
    /// [DoslyApp] still mounts normally, no [PrefsLoadErrorScreen] appears,
    /// and no exception escapes the build.
    ///
    /// The widget-tree assertions alone (DoslyApp mounted, no error shell,
    /// `tester.takeException()` is null) are necessary but NOT sufficient:
    /// [AppBootstrap] only ever fire-and-forget `ref.read`s
    /// [reconcileMissedOnOpenProvider] and never watches/awaits it, so an
    /// unhandled error inside that provider's own Future is contained by
    /// Riverpod as that provider's `AsyncError` state — it can never
    /// propagate into the widget tree regardless of whether the fold
    /// actually swallows it correctly. So this test ALSO reads the
    /// provider's own resolved [AsyncValue] straight from the
    /// [ProviderContainer] and asserts `hasError` is false — the assertion
    /// that actually distinguishes "the Left was folded into a logged
    /// warning" from "the Left was left unhandled inside the provider".
    testWidgets(
      'reconcile Left failure does not surface as a startup error',
      (WidgetTester tester) async {
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesInitProvider.overrideWith(
              (ref) => Future<SharedPreferencesWithCache>.value(realPrefs),
            ),
            settingsRepositoryProvider.overrideWithValue(fakeRepo),
            appDatabaseProvider.overrideWithValue(db),
            // The fake under test: always fails, mirroring a real cache
            // error surfaced from ReconcileMissedIntakes.
            reconcileMissedIntakesProvider.overrideWith(
              (ref) => _FailingReconcileMissedIntakes(),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const AppBootstrap(),
          ),
        );
        await tester.pumpAndSettle();

        // App boots normally: DoslyApp mounted, no error shell, no
        // uncaught exception from the swallowed reconcile failure.
        expect(find.byType(DoslyApp), findsOneWidget);
        expect(find.byType(PrefsLoadErrorScreen), findsNothing);
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(tester.takeException(), isNull);

        // The falsifiable check: reconcileMissedOnOpenProvider's own
        // resolved AsyncValue must be error-free.
        final AsyncValue<void> resolved = container.read(
          reconcileMissedOnOpenProvider,
        );
        expect(
          resolved.hasError,
          isFalse,
          reason:
              'reconcileMissedOnOpen must fold the reconcile Left into a '
              'logged warning and complete normally — an AsyncError here '
              'means the failure was NOT actually swallowed internally, '
              'even though AppBootstrap itself never observed it.',
        );
      },
    );
  });
}
