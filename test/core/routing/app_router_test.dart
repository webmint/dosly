// Integration tests for [appRouter] — verifies StatefulShellRoute topology,
// tab-tap navigation, selectedIndex tracking, branch stack preservation, and
// /theme-preview rendering outside the shell.
//
// Test 4 uses a test-only router that mirrors the production shape but adds a
// sentinel child route under the Meds branch. This is the standard go_router
// approach for verifying branch-stack preservation (AC-11) without polluting
// production routes.

import 'package:dosly/features/settings/domain/entities/app_language.dart';
import 'package:dosly/features/settings/domain/entities/app_settings.dart';
import 'package:dosly/features/settings/domain/entities/app_theme_mode.dart';
import 'package:dosly/features/settings/domain/repositories/settings_repository.dart';
import 'package:dosly/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';

import 'package:dosly/core/routing/app_router.dart';
import 'package:dosly/core/routing/app_shell.dart';
import 'package:dosly/features/history/presentation/screens/history_screen.dart';
import 'package:dosly/features/home/presentation/screens/home_screen.dart';
import 'package:dosly/core/widgets/app_bottom_nav.dart';
import 'package:dosly/features/meds/presentation/screens/meds_screen.dart';
import 'package:dosly/features/settings/presentation/screens/settings_screen.dart';
import 'package:dosly/features/theme_preview/presentation/screens/theme_preview_screen.dart';
import 'package:dosly/l10n/app_localizations.dart';

/// Minimal fake that satisfies [SettingsRepository] for routing tests.
class _FakeSettingsRepository implements SettingsRepository {
  @override
  AppSettings load() => const AppSettings();

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
    return const Scaffold(
      body: Center(child: Text('SENTINEL_MEDS_SUB')),
    );
  }
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
                builder: (context, state) => const HomeScreen(),
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
// ---------------------------------------------------------------------------
Future<void> _pumpRouter(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider
            .overrideWithValue(_FakeSettingsRepository()),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
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
    // Tap Today → HomeScreen. Verifies destination-tap routing through the
    // StatefulShellRoute + AppBottomNav.
    // -----------------------------------------------------------------------
    testWidgets(
      'Test 1 (AC-1, AC-2, AC-9): tab taps navigate between branches',
      (tester) async {
        await _pumpRouter(tester, appRouter);

        // Initial route: HomeScreen should be visible.
        expect(find.byType(HomeScreen), findsOneWidget);

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
        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );

    // -----------------------------------------------------------------------
    // Test 2 — AC-8: exactly one AppBottomNav is in the widget tree at all
    // times as the user navigates between the three shell branches.
    // -----------------------------------------------------------------------
    testWidgets(
      'Test 2 (AC-8): exactly one AppBottomNav across all shell branches',
      (tester) async {
        await _pumpRouter(tester, appRouter);

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
    testWidgets(
      'Test 3 (AC-10): selectedIndex tracks direct-URL navigation',
      (tester) async {
        await _pumpRouter(tester, appRouter);

        // Helper: get the current selectedIndex from the NavigationBar.
        int selectedIndex() =>
            tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

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
      },
    );

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
        final testRouter = _buildTestRouterWithSentinel();
        await _pumpRouter(tester, testRouter);

        // Push the sentinel sub-route inside the Meds branch.
        GoRouter.of(tester.element(find.byType(HomeScreen))).go('/meds/sentinel');
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

        testRouter.dispose();
      },
    );

    // -----------------------------------------------------------------------
    // Test 5 — AC-13: /theme-preview renders outside the shell (no
    // AppBottomNav). Navigating back to / restores the bottom nav.
    // -----------------------------------------------------------------------
    testWidgets(
      'Test 5 (AC-13): /theme-preview renders without the shell bottom nav',
      (tester) async {
        await _pumpRouter(tester, appRouter);

        // Start at /: bottom nav must be present.
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(AppBottomNav), findsOneWidget);

        // Tap the "Theme preview" OutlinedButton on HomeScreen.
        await tester.tap(find.widgetWithText(OutlinedButton, 'Theme preview'));
        await tester.pumpAndSettle();

        // ThemePreviewScreen is shown; AppBottomNav must NOT be in the tree.
        expect(find.byType(ThemePreviewScreen), findsOneWidget);
        expect(find.byType(AppBottomNav), findsNothing);

        // Navigate back to / — bottom nav must reappear.
        GoRouter.of(tester.element(find.byType(ThemePreviewScreen))).go('/');
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(AppBottomNav), findsOneWidget);
      },
    );

    // -----------------------------------------------------------------------
    // Test 6 — AC-5, AC-7: /settings renders outside the shell (no
    // AppBottomNav). Navigating back restores the bottom nav and HomeScreen.
    // -----------------------------------------------------------------------
    testWidgets(
      'Test 6 (AC-5, AC-7): /settings renders without the shell bottom nav and back returns to home',
      (tester) async {
        await _pumpRouter(tester, appRouter);

        // Start at /: bottom nav must be present.
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(AppBottomNav), findsOneWidget);

        // Navigate to /settings via push (it is a push route, not a shell branch).
        GoRouter.of(tester.element(find.byType(HomeScreen))).push('/settings');
        await tester.pumpAndSettle();

        // SettingsScreen is shown; AppBottomNav must NOT be in the tree.
        expect(find.byType(SettingsScreen), findsOneWidget);
        expect(find.byType(AppBottomNav), findsNothing);

        // Navigate back — bottom nav must reappear.
        GoRouter.of(tester.element(find.byType(SettingsScreen))).pop();
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(AppBottomNav), findsOneWidget);
      },
    );
  });
}
