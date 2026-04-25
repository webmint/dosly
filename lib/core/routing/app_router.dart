/// Application routing composition root.
///
/// Declares the top-level [appRouter] — a `StatefulShellRoute.indexedStack`
/// with three branches (Home `/`, Meds `/meds`, History `/history`) sharing
/// a single [AppShell] scaffold + [AppBottomNav], plus a sibling top-level
/// [GoRoute] for `/theme-preview` that renders WITHOUT the shell (so the
/// dev-preview screen has no bottom nav).
///
/// Branch order matches [AppBottomNav] destination order (0=Today, 1=Meds,
/// 2=History). Do not reorder without updating the bottom nav.
library;

import 'package:go_router/go_router.dart';

import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/meds/presentation/screens/meds_screen.dart';
import '../../features/theme_preview/presentation/screens/theme_preview_screen.dart';
import 'app_shell.dart';

/// Application singleton router instance.
///
/// Mirrors the top-level controller pattern used by `themeController` in
/// `lib/core/theme/theme_controller.dart`. Consumed by `DoslyApp` via
/// `MaterialApp.router`.
final GoRouter appRouter = GoRouter(
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
    // TODO(post-mvp): remove this route when lib/features/theme_preview/
    // is deleted — see specs/002-main-screen/spec.md §6 and §8.
    GoRoute(
      path: '/theme-preview',
      builder: (context, state) => const ThemePreviewScreen(),
    ),
  ],
);
