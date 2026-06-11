/// Application routing composition root.
///
/// Declares [appRouterProvider] — a keep-alive Riverpod provider
/// that creates a `StatefulShellRoute.indexedStack` with three branches
/// (Today `/`, Meds `/meds`, History `/history`) sharing a single [AppShell]
/// scaffold + [AppBottomNav], plus a sibling top-level [GoRoute] for
/// `/settings`. Branch 0 (`/`) is built by [HomeScreen] but is surfaced in the
/// bottom nav as the localized "Today" destination (class `HomeScreen`,
/// destination label "Today").
///
/// Branch order matches [AppBottomNav] destination order (0=Today, 1=Meds,
/// 2=History). Do not reorder without updating the bottom nav.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/meds/presentation/screens/meds_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../l10n/l10n_extensions.dart';
import '../logging/logger.dart';
import 'app_shell.dart';

part 'app_router.g.dart';

/// Application router provider.
///
/// Returns the single app-wide [GoRouter] instance and binds its
/// [GoRouter.dispose] to the [ProviderScope] lifetime via `ref.onDispose`.
/// Consumed by `DoslyApp` via `ref.watch(appRouterProvider)`.
///
/// Tests that need a different route topology override this provider with
/// `appRouterProvider.overrideWith((ref) { final r = ...; ref.onDispose(r.dispose); return r; })`.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // Capture the logger once at construction time so the provider dependency
  // is explicit here in the provider body, not buried inside a closure.
  final logger = ref.read(loggerProvider);

  // Guard that prevents duplicate log entries when [errorBuilder] is
  // re-invoked for the same routing exception (e.g. on rebuild). Captured by
  // the closure below; reset whenever a new [GoRouter] instance is created.
  Object? lastLoggedError;

  final router = GoRouter(
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
      return const _RouterErrorScreen();
    },
  );
  ref.onDispose(router.dispose);
  return router;
}

/// Private fallback screen rendered by [appRouter]'s `errorBuilder` when no
/// [GoRoute] matches the requested path.
///
/// Renders outside the [StatefulShellRoute] so no [AppBottomNav] is visible.
/// The only recovery action is the localized "Go to home" [FilledButton],
/// which calls `context.go('/')` to clear the route stack and land on the
/// home branch.
class _RouterErrorScreen extends StatelessWidget {
  const _RouterErrorScreen();

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
