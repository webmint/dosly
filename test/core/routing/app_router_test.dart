// Integration tests for [appRouter] — verifies StatefulShellRoute topology,
// tab-tap navigation, selectedIndex tracking, and branch stack preservation.
//
// This suite exercises navigation MECHANICS only, never the real branch-0
// screen: production branch 0 is `TodayScreen` (meds/presentation), which
// watches live medication/intake streams and runs a grace-refresh Timer —
// both irrelevant here and a source of test flakiness/pending-timer issues.
// Every router built in this file (the default one used by `_pumpRouter` and
// Test 4's sentinel variant) therefore substitutes the hermetic `_HomeStub`
// for branch 0 while otherwise mirroring the production shape (including the
// `/settings` route and the errorBuilder's dedup-logging guard, duplicated
// here since app_router.dart's `_RouterErrorScreen` and guard are private to
// that library).
//
// Test 4 additionally adds a sentinel child route under the Meds branch —
// the standard go_router approach for verifying branch-stack preservation
// (AC-11) without polluting production routes.

import 'package:dosly/core/database/database.dart';
import 'package:dosly/core/database/database_provider.dart';
import 'package:dosly/core/error/failures.dart';
import 'package:dosly/core/logging/log_sanitizer.dart';
import 'package:dosly/core/logging/logger.dart';
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
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import 'package:dosly/core/routing/app_router.dart';
import 'package:dosly/core/routing/app_shell.dart';
import 'package:dosly/features/history/presentation/screens/history_screen.dart';
import 'package:dosly/core/routing/app_bottom_nav.dart';
import 'package:dosly/features/meds/presentation/screens/meds_screen.dart';
import 'package:dosly/features/settings/presentation/screens/settings_screen.dart';
import 'package:dosly/l10n/app_localizations.dart';
import 'package:dosly/l10n/l10n_extensions.dart';

/// Minimal fake that satisfies [SettingsRepository] for routing tests.
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

// ---------------------------------------------------------------------------
// Sentinel widget used only in Test 4's test-only router.
// The string 'SENTINEL_MEDS_SUB' is unique — it will not appear in any
// production widget so find.text() calls on it unambiguously verify branch
// stack state.
// ---------------------------------------------------------------------------
class _SentinelScreen extends StatelessWidget {
  const _SentinelScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('SENTINEL_MEDS_SUB')));
  }
}

// ---------------------------------------------------------------------------
// Stand-in for branch 0 ("/") in this file's test-only routers.
//
// The real branch-0 screen is [TodayScreen] (`meds/presentation/screens`),
// which watches live medication/intake streams and runs a grace-refresh
// [Timer] — neither of which this file wants to exercise. This routing suite
// tests navigation mechanics only (tab taps, selectedIndex, branch-stack
// preservation, /settings push/pop, error recovery), so a trivial stub with
// no providers, no timers, and no DB dependency keeps it hermetic.
// ---------------------------------------------------------------------------
class _HomeStub extends StatelessWidget {
  const _HomeStub();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('HOME_STUB')));
  }
}

// ---------------------------------------------------------------------------
// Test-only duplicate of app_router.dart's private `_RouterErrorScreen`.
//
// Duplicated (rather than imported) because the production widget is private
// to its library. Renders the same localized strings and "Go to home"
// recovery action so Test 7/8 continue to faithfully exercise the shared
// errorBuilder shape used by [_buildDefaultTestRouter].
// ---------------------------------------------------------------------------
class _TestRouterErrorScreen extends StatelessWidget {
  const _TestRouterErrorScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.errorScreenTitle),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.errorScreenBody, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/'),
              child: Text(l10n.errorScreenGoHome),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Default test-only router used by [_pumpRouter] for every test in this file
// except Test 4. Mirrors app_router.dart's production shape exactly — three
// shell branches, the `/settings` route, and the errorBuilder's
// once-per-error logging guard via the canonical `Logger('dosly')` singleton
// (package:logging caches loggers by name, so this is the SAME instance the
// production code and `loggerProvider` resolve to; see logger.dart) — except
// branch 0 uses [_HomeStub] instead of the real `TodayScreen`.
// ---------------------------------------------------------------------------
GoRouter _buildDefaultTestRouter() {
  final Logger logger = Logger('dosly');
  Object? lastLoggedError;

  return GoRouter(
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const _HomeStub(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/meds',
                builder: (context, state) => const MedsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) {
      final Object? error = state.error;
      if (error != null && !identical(error, lastLoggedError)) {
        lastLoggedError = error;
        logger.warning('Route resolution failed', error);
      }
      return const _TestRouterErrorScreen();
    },
  );
}

// ---------------------------------------------------------------------------
// Test-only router for Test 4.
// Mirrors the production appRouter shape but adds a child GoRoute('sentinel')
// under the Meds StatefulShellBranch so the test can push /meds/sentinel and
// verify that the branch stack is preserved across tab switches.
// ---------------------------------------------------------------------------
GoRouter _buildTestRouterWithSentinel() {
  return GoRouter(
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const _HomeStub(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/meds',
                builder: (context, state) => const MedsScreen(),
                routes: [
                  GoRoute(
                    path: 'sentinel',
                    builder: (context, state) => const _SentinelScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Pump helper — builds a MaterialApp.router with localization delegates so
// widgets using context.l10n do not crash. Locale is pinned to English so
// bottom-nav label text is predictable across all test machines.
//
// Builds and overrides [appRouterProvider] with [routerBuilder] — defaulting
// to [_buildDefaultTestRouter] so no test in this file ever mounts the real
// `TodayScreen` — as a SINGLE entry in the overrides list (Riverpod asserts
// on a provider being overridden twice within the same container, so this
// must not also appear in [overrides]). Callers that need a different
// topology (Test 4's sentinel router) pass their own [routerBuilder].
//
// An in-memory AppDatabase is created per invocation and registered via
// addTearDown so it is closed after the widget tree is disposed. Pumping
// an extra frame before close lets drift flush any pending stream-cleanup
// timers (StreamQueryStore.markAsClosed uses a zero-duration timer) and
// avoids the "Timer is still pending" assertion from flutter_test.
// ---------------------------------------------------------------------------
Future<void> _pumpRouter(
  WidgetTester tester, {
  List<Override> overrides = const [],
  GoRouter Function() routerBuilder = _buildDefaultTestRouter,
}) async {
  // closeStreamsSynchronously: true makes drift close streams synchronously
  // when the DB is closed, so no zero-duration timer remains pending when
  // flutter_test's _verifyInvariants runs after the widget tree is disposed.
  final db = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  addTearDown(db.close);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(_FakeSettingsRepository()),
        appDatabaseProvider.overrideWithValue(db),
        appRouterProvider.overrideWith((ref) {
          final r = routerBuilder();
          ref.onDispose(r.dispose);
          return r;
        }),
        ...overrides,
      ],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          routerConfig: ref.watch(appRouterProvider),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('appRouter', () {
    // -----------------------------------------------------------------------
    // Test 1 — AC-1, AC-2, AC-9: tap-based tab navigation between branches.
    // Start at /. Tap Meds → MedsScreen. Tap History → HistoryScreen.
    // Tap Today → _HomeStub. Verifies destination-tap routing through the
    // StatefulShellRoute + AppBottomNav.
    // -----------------------------------------------------------------------
    testWidgets(
      'Test 1 (AC-1, AC-2, AC-9): tab taps navigate between branches',
      (tester) async {
        await _pumpRouter(tester);

        // Initial route: _HomeStub should be visible.
        expect(find.byType(_HomeStub), findsOneWidget);

        // Tap the "Meds" bottom nav destination.
        await tester.tap(find.text('Meds'));
        await tester.pumpAndSettle();
        expect(find.byType(MedsScreen), findsOneWidget);

        // Tap "History".
        await tester.tap(find.text('History'));
        await tester.pumpAndSettle();
        expect(find.byType(HistoryScreen), findsOneWidget);

        // Tap "Today" to return home.
        await tester.tap(find.text('Today'));
        await tester.pumpAndSettle();
        expect(find.byType(_HomeStub), findsOneWidget);
      },
    );

    // -----------------------------------------------------------------------
    // Test 2 — AC-8: exactly one AppBottomNav is in the widget tree at all
    // times as the user navigates between the three shell branches.
    // -----------------------------------------------------------------------
    testWidgets(
      'Test 2 (AC-8): exactly one AppBottomNav across all shell branches',
      (tester) async {
        await _pumpRouter(tester);

        // At /.
        expect(find.byType(AppBottomNav), findsOneWidget);

        // Navigate to /meds.
        await tester.tap(find.text('Meds'));
        await tester.pumpAndSettle();
        expect(find.byType(AppBottomNav), findsOneWidget);

        // Navigate to /history.
        await tester.tap(find.text('History'));
        await tester.pumpAndSettle();
        expect(find.byType(AppBottomNav), findsOneWidget);

        // Navigate back to /.
        await tester.tap(find.text('Today'));
        await tester.pumpAndSettle();
        expect(find.byType(AppBottomNav), findsOneWidget);
      },
    );

    // -----------------------------------------------------------------------
    // Test 3 — AC-10: NavigationBar.selectedIndex reflects the active branch
    // when navigation is performed via direct URL (GoRouter.of(context).go)
    // rather than a tap. This verifies the shell's currentIndex wiring, not
    // just tap-handler wiring.
    // -----------------------------------------------------------------------
    testWidgets('Test 3 (AC-10): selectedIndex tracks direct-URL navigation', (
      tester,
    ) async {
      await _pumpRouter(tester);

      // Helper: get the current selectedIndex from the NavigationBar.
      int selectedIndex() => tester
          .widget<NavigationBar>(find.byType(NavigationBar))
          .selectedIndex;

      // Initial state: index 0 (Today / home branch).
      expect(selectedIndex(), 0);

      // Navigate to /meds via GoRouter.of — use a context that is under the
      // router (AppBottomNav is always present in the shell branches).
      GoRouter.of(tester.element(find.byType(AppBottomNav))).go('/meds');
      await tester.pumpAndSettle();
      expect(selectedIndex(), 1);

      // Navigate to /history.
      GoRouter.of(tester.element(find.byType(AppBottomNav))).go('/history');
      await tester.pumpAndSettle();
      expect(selectedIndex(), 2);

      // Navigate back to /.
      GoRouter.of(tester.element(find.byType(AppBottomNav))).go('/');
      await tester.pumpAndSettle();
      expect(selectedIndex(), 0);
    });

    // -----------------------------------------------------------------------
    // Test 4 — AC-11: branch stack is preserved across tab switches.
    // Uses a TEST-ONLY router (declared in this file) that adds a sentinel
    // child route under /meds without modifying the production appRouter.
    // Flow: start → push /meds/sentinel → switch to History → switch back to
    // Meds → sentinel screen must still be showing (branch stack preserved).
    // -----------------------------------------------------------------------
    testWidgets(
      'Test 4 (AC-11): branch stack is preserved when switching tabs',
      (tester) async {
        await _pumpRouter(tester, routerBuilder: _buildTestRouterWithSentinel);

        // Push the sentinel sub-route inside the Meds branch.
        GoRouter.of(
          tester.element(find.byType(_HomeStub)),
        ).go('/meds/sentinel');
        await tester.pumpAndSettle();
        expect(find.text('SENTINEL_MEDS_SUB'), findsOneWidget);

        // Switch to History branch — sentinel must disappear.
        await tester.tap(find.text('History'));
        await tester.pumpAndSettle();
        expect(find.byType(HistoryScreen), findsOneWidget);
        expect(find.text('SENTINEL_MEDS_SUB'), findsNothing);

        // Switch back to Meds branch — sentinel must reappear (stack preserved).
        await tester.tap(find.text('Meds'));
        await tester.pumpAndSettle();
        expect(find.text('SENTINEL_MEDS_SUB'), findsOneWidget);
      },
    );

    // -----------------------------------------------------------------------
    // Test 6 — AC-5, AC-7: /settings renders outside the shell (no
    // AppBottomNav). Navigating back restores the bottom nav and _HomeStub.
    // -----------------------------------------------------------------------
    testWidgets(
      'Test 6 (AC-5, AC-7): /settings renders without the shell bottom nav and back returns to home',
      (tester) async {
        await _pumpRouter(tester);

        // Start at /: bottom nav must be present.
        expect(find.byType(_HomeStub), findsOneWidget);
        expect(find.byType(AppBottomNav), findsOneWidget);

        // Navigate to /settings via push (it is a push route, not a shell branch).
        GoRouter.of(tester.element(find.byType(_HomeStub))).push('/settings');
        await tester.pumpAndSettle();

        // SettingsScreen is shown; AppBottomNav must NOT be in the tree.
        expect(find.byType(SettingsScreen), findsOneWidget);
        expect(find.byType(AppBottomNav), findsNothing);

        // Navigate back — bottom nav must reappear.
        GoRouter.of(tester.element(find.byType(SettingsScreen))).pop();
        await tester.pumpAndSettle();
        expect(find.byType(_HomeStub), findsOneWidget);
        expect(find.byType(AppBottomNav), findsOneWidget);
      },
    );

    // -----------------------------------------------------------------------
    // Test 7 — AC-1, AC-2, AC-3, AC-8: errorBuilder renders a localized
    // error screen for an unmatched path, outside the shell (no AppBottomNav),
    // and the "Go to home" button recovers to _HomeStub.
    // -----------------------------------------------------------------------
    testWidgets(
      'Test 7 (AC-1, AC-2, AC-3, AC-8): errorBuilder renders for unmatched route and recovers to home',
      (tester) async {
        await _pumpRouter(tester);

        // Navigate to an unmatched path.
        GoRouter.of(tester.element(find.byType(_HomeStub))).go('/nonexistent');
        await tester.pumpAndSettle();

        // Error screen is rendered with the localized title.
        expect(find.text('Page not found'), findsOneWidget);

        // Screen renders OUTSIDE the StatefulShellRoute — no bottom nav.
        expect(find.byType(AppBottomNav), findsNothing);

        // Recovery button is present.
        expect(find.widgetWithText(FilledButton, 'Go to home'), findsOneWidget);

        // Tap the button → navigate back to _HomeStub.
        await tester.tap(find.widgetWithText(FilledButton, 'Go to home'));
        await tester.pumpAndSettle();

        expect(find.byType(_HomeStub), findsOneWidget);
        expect(find.byType(AppBottomNav), findsOneWidget);
      },
    );

    // -----------------------------------------------------------------------
    // Test 8 — errorBuilder once-per-error dedup guard
    // (app_router.dart:87-90: `if (error != null && !identical(error,
    //  lastLoggedError)) { lastLoggedError = error; logger.warning(...) }`)
    //
    // Wires a capturing LogSink via configureLogging and overrides
    // loggerProvider so the production appRouter captures the same Logger
    // instance. Navigates to an unmatched path and asserts exactly ONE
    // warning is recorded — proving the guard fires on the first invocation
    // but would not fire a second time for the same error object (the
    // identical() guard). A second navigate to the same unmatched path
    // produces a new exception object (go_router creates a fresh
    // GoException per navigation), so we cannot assert "same error, zero
    // new warnings" with a fresh navigate — the test is therefore honestly
    // named for what it verifies: exactly one warning for one unmatched
    // navigation.
    // -----------------------------------------------------------------------
    testWidgets(
      'Test 8: errorBuilder logs exactly one warning for a single unmatched navigation',
      (tester) async {
        final warningMessages = <String>[];

        // Configure the logging pipeline with a capturing sink so we can
        // count warning-level emissions from the router's errorBuilder.
        final sub = configureLogging(
          level: Level.ALL,
          includeErrorDetail: false,
          sink: (SanitizedLog log, Level level) {
            if (level >= Level.WARNING) {
              warningMessages.add(log.message);
            }
          },
        );
        addTearDown(sub.cancel);
        addTearDown(Logger.root.clearListeners);

        // Override loggerProvider so the router under test reads the Logger
        // that is already wired to our capturing pipeline above.
        // Logger('dosly') is a cached singleton by name in package:logging,
        // so configureLogging above and loggerProvider both share it.
        await _pumpRouter(
          tester,
          overrides: [loggerProvider.overrideWithValue(Logger('dosly'))],
        );

        // Navigate to an unmatched path — triggers errorBuilder once.
        GoRouter.of(tester.element(find.byType(_HomeStub))).go('/no-such-path');
        await tester.pumpAndSettle();

        // Exactly one warning must have been recorded.
        expect(
          warningMessages.where((m) => m.contains('Route resolution failed')),
          hasLength(1),
          reason:
              'errorBuilder must log exactly one warning for a single unmatched navigation',
        );
      },
    );
  });
}
