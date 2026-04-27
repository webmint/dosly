/// Application-wide user preferences.
///
/// Holds the user's theme preferences. The [effectiveThemeMode] getter derives
/// the [ThemeMode] to pass to [MaterialApp.themeMode] based on whether the
/// user has opted in to the system theme or chosen a manual override.
library;

import 'package:flutter/material.dart';

/// Application-wide user preferences.
///
/// When [useSystemTheme] is `true` (the default), [effectiveThemeMode] returns
/// [ThemeMode.system] and [manualThemeMode] is ignored by the app. When
/// [useSystemTheme] is `false`, [effectiveThemeMode] returns [manualThemeMode].
class AppSettings {
  /// Creates an [AppSettings] instance.
  ///
  /// Defaults to following the system theme ([useSystemTheme] = `true`) with
  /// [manualThemeMode] = [ThemeMode.light] as the fallback manual selection.
  const AppSettings({
    this.useSystemTheme = true,
    this.manualThemeMode = ThemeMode.light,
  });

  /// Whether to follow the device theme.
  ///
  /// When `true`, [effectiveThemeMode] returns [ThemeMode.system] and
  /// [manualThemeMode] is ignored by the app shell.
  final bool useSystemTheme;

  /// The theme to use when [useSystemTheme] is `false`.
  ///
  /// Only [ThemeMode.light] and [ThemeMode.dark] are semantically valid here;
  /// [ThemeMode.system] should not be stored in this field.
  final ThemeMode manualThemeMode;

  /// The effective [ThemeMode] to pass to [MaterialApp.themeMode].
  ///
  /// Returns [ThemeMode.system] when [useSystemTheme] is `true`; otherwise
  /// returns [manualThemeMode].
  ThemeMode get effectiveThemeMode =>
      useSystemTheme ? ThemeMode.system : manualThemeMode;

  /// Returns a copy with the given fields replaced.
  AppSettings copyWith({bool? useSystemTheme, ThemeMode? manualThemeMode}) =>
      AppSettings(
        useSystemTheme: useSystemTheme ?? this.useSystemTheme,
        manualThemeMode: manualThemeMode ?? this.manualThemeMode,
      );
}
