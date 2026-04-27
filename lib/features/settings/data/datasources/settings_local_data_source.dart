/// Low-level data source that reads and writes settings keys via
/// [SharedPreferencesWithCache].
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key used to persist the user's manual theme-mode preference.
const String _kThemeModeKey = 'themeMode';

/// Key used to persist whether the app follows the system theme.
const String _kUseSystemThemeKey = 'useSystemTheme';

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
}
