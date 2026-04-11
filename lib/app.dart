/// Application root.
///
/// Wraps `MaterialApp` in a [ListenableBuilder] so the entire tree rebuilds
/// when [themeController]'s value changes. Sets the M3 light and dark themes
/// from [AppTheme] and uses [ThemePreviewScreen] as the home until real
/// screens land.
library;

import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/theme_preview/presentation/screens/theme_preview_screen.dart';

/// The dosly application root widget.
class DoslyApp extends StatelessWidget {
  /// Creates the application root.
  const DoslyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) => MaterialApp(
        title: 'dosly',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.value,
        home: const ThemePreviewScreen(),
      ),
    );
  }
}
