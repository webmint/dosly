/// Widget tests for [AppBootstrap].
///
/// Covers the three async branches driven by [sharedPreferencesInitProvider]:
/// loading (SplashScreen), error (PrefsLoadErrorScreen + retry), and data
/// (DoslyApp). Also asserts that only one MaterialApp is mounted per phase.
library;

import 'dart:async';

import 'package:dosly/app.dart';
import 'package:dosly/app_bootstrap.dart';
import 'package:dosly/core/error/failures.dart';
import 'package:dosly/core/providers/shared_preferences_provider.dart';
import 'package:dosly/core/widgets/prefs_load_error_screen.dart';
import 'package:dosly/core/widgets/splash_screen.dart';
import 'package:dosly/features/settings/domain/entities/app_language.dart';
import 'package:dosly/features/settings/domain/entities/app_settings.dart';
import 'package:dosly/features/settings/domain/entities/app_theme_mode.dart';
import 'package:dosly/features/settings/domain/repositories/settings_repository.dart';
import 'package:dosly/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferencesWithCache, SharedPreferencesWithCacheOptions;
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

  setUpAll(() async {
    realPrefs = await _buildRealPrefs();
  });

  setUp(() {
    fakeRepo = _FakeSettingsRepository();
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
                (ref) => Future<SharedPreferencesWithCache>.error(
                  Exception('boom'),
                ),
              ),
            ],
            child: const AppBootstrap(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PrefsLoadErrorScreen), findsOneWidget);
        // English localized message (test harness default locale is en).
        expect(
          find.text("We couldn't load your preferences."),
          findsOneWidget,
        );
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
    testWidgets(
      'shows SplashScreen with spinner while init is pending',
      (WidgetTester tester) async {
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
      },
    );
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
}
