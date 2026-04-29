/// Application-wide user preferences.
///
/// Holds the user's theme and language preferences. The [effectiveThemeMode]
/// getter derives the [ThemeMode] to pass to [MaterialApp.themeMode] based on
/// whether the user has opted in to the system theme or chosen a manual
/// override. The [effectiveLocale] getter derives the [Locale] to pass to
/// [MaterialApp.locale] based on whether the user has opted in to the system
/// language or chosen a manual override.
library;

import 'package:flutter/material.dart';

import 'app_language.dart';

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
  /// Defaults to following the system language ([useSystemLanguage] = `true`)
  /// with [manualLanguage] = [AppLanguage.en] as the fallback manual choice.
  const AppSettings({
    this.useSystemTheme = true,
    this.manualThemeMode = ThemeMode.light,
    this.useSystemLanguage = true,
    this.manualLanguage = AppLanguage.en,
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

  /// Whether to follow the device language.
  ///
  /// When `true`, [effectiveLocale] returns `null` so [MaterialApp]'s
  /// `localeResolutionCallback` resolves the device locale.
  final bool useSystemLanguage;

  /// The language to use when [useSystemLanguage] is `false`.
  final AppLanguage manualLanguage;

  /// The effective [ThemeMode] to pass to [MaterialApp.themeMode].
  ///
  /// Returns [ThemeMode.system] when [useSystemTheme] is `true`; otherwise
  /// returns [manualThemeMode].
  ThemeMode get effectiveThemeMode =>
      useSystemTheme ? ThemeMode.system : manualThemeMode;

  /// The [Locale] to pass to [MaterialApp.locale].
  ///
  /// Returns `null` when [useSystemLanguage] is `true` so [MaterialApp]'s
  /// `localeResolutionCallback` runs and resolves the device locale (with
  /// the project's English fallback). Returns a non-null `Locale` derived
  /// from [manualLanguage] otherwise.
  Locale? get effectiveLocale =>
      useSystemLanguage ? null : Locale(manualLanguage.code);

  /// Returns a copy with the given fields replaced.
  AppSettings copyWith({
    bool? useSystemTheme,
    ThemeMode? manualThemeMode,
    bool? useSystemLanguage,
    AppLanguage? manualLanguage,
  }) => AppSettings(
    useSystemTheme: useSystemTheme ?? this.useSystemTheme,
    manualThemeMode: manualThemeMode ?? this.manualThemeMode,
    useSystemLanguage: useSystemLanguage ?? this.useSystemLanguage,
    manualLanguage: manualLanguage ?? this.manualLanguage,
  );
}
