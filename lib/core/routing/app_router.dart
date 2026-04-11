/// Application routing composition root.
///
/// Declares the top-level [appRouter] — a flat `GoRouter` with exactly two
/// routes:
///
///   * `'/'`             → `HomeScreen`
///   * `'/theme-preview'` → `ThemePreviewScreen` (temporary dev-only route,
///     scheduled for removal post-MVP — see `specs/002-main-screen/spec.md`)
library;

import 'package:go_router/go_router.dart';

import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/theme_preview/presentation/screens/theme_preview_screen.dart';

/// Application singleton router instance.
///
/// Mirrors the top-level controller pattern used by `themeController` in
/// `lib/core/theme/theme_controller.dart`. Consumed by `DoslyApp` via
/// `MaterialApp.router`.
final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    // TODO(post-mvp): remove this route when lib/features/theme_preview/
    // is deleted — see specs/002-main-screen/spec.md §6 and §8.
    GoRoute(
      path: '/theme-preview',
      builder: (context, state) => const ThemePreviewScreen(),
    ),
  ],
);
