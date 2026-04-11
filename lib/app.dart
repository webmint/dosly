/// Application root.
///
/// Wraps `MaterialApp.router` in a [ListenableBuilder] so the entire tree
/// rebuilds when [themeController]'s value changes. Sets the M3 light and
/// dark themes from [AppTheme]. Routing is delegated to [appRouter] which
/// currently exposes `/` ([HomeScreen]) and a temporary dev-only
/// `/theme-preview` route — the preview route will be removed in the
/// final development stages (see specs/002-main-screen/spec.md).
library;

import 'package:flutter/material.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

/// The dosly application root widget.
class DoslyApp extends StatelessWidget {
  /// Creates the application root.
  const DoslyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) => MaterialApp.router(
        title: 'dosly',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.value,
        routerConfig: appRouter,
      ),
    );
  }
}
