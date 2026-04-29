/// Low-level data source that reads and writes settings keys via
/// [SharedPreferencesWithCache].
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_language.dart';

/// Key used to persist the user's manual theme-mode preference.
const String _kThemeModeKey = 'themeMode';

/// Key used to persist whether the app follows the system theme.
const String _kUseSystemThemeKey = 'useSystemTheme';

/// Key used to persist whether the app follows the system language.
const String _kUseSystemLanguageKey = 'useSystemLanguage';

/// Key used to persist the user's manual language choice (IETF code).
const String _kManualLanguageKey = 'manualLanguage';

/// Thin wrapper around [SharedPreferencesWithCache] for raw read/write of
/// individual settings keys.
///
/// All reads are synchronous (backed by the in-memory cache); writes return
/// a [Future] that completes when the value is persisted to disk.
class SettingsLocalDataSource {
  /// Creates a [SettingsLocalDataSource] backed by the given [prefs] instance.
  const SettingsLocalDataSource(this._prefs);

  final SharedPreferencesWithCache _prefs;

  /// Returns the persisted manual [ThemeMode].
  ///
  /// Falls back to [ThemeMode.light] when no value has been stored or the
  /// stored index is out of range.
  ThemeMode getThemeMode() {
    final int? index = _prefs.getInt(_kThemeModeKey);
    if (index == null || index < 0 || index >= ThemeMode.values.length) {
      return ThemeMode.light;
    }
    return ThemeMode.values[index];
  }

  /// Persists the user's manual [mode] choice as an integer index.
  Future<void> setThemeMode(ThemeMode mode) =>
      _prefs.setInt(_kThemeModeKey, mode.index);

  /// Returns whether the app should follow the device system theme.
  ///
  /// Defaults to `true` when no value has been stored.
  bool getUseSystemTheme() => _prefs.getBool(_kUseSystemThemeKey) ?? true;

  /// Persists the [value] for the "use system theme" preference.
  Future<void> setUseSystemTheme(bool value) =>
      _prefs.setBool(_kUseSystemThemeKey, value);

  /// Returns whether the app should follow the device system language.
  ///
  /// Defaults to `true` when no value has been stored.
  bool getUseSystemLanguage() => _prefs.getBool(_kUseSystemLanguageKey) ?? true;

  /// Returns the persisted manual [AppLanguage].
  ///
  /// Falls back to [AppLanguage.en] when no value has been stored or the
  /// stored code does not match any [AppLanguage.code].
  AppLanguage getManualLanguage() {
    final String? code = _prefs.getString(_kManualLanguageKey);
    if (code == null) {
      return AppLanguage.en;
    }
    return AppLanguage.values.firstWhere(
      (AppLanguage lang) => lang.code == code,
      orElse: () => AppLanguage.en,
    );
  }

  /// Persists the [value] for the "use system language" preference.
  Future<void> setUseSystemLanguage(bool value) =>
      _prefs.setBool(_kUseSystemLanguageKey, value);

  /// Persists the user's manual [language] choice as its IETF code.
  Future<void> setManualLanguage(AppLanguage language) =>
      _prefs.setString(_kManualLanguageKey, language.code);
}
