/// Low-level data source that reads and writes settings keys via
/// [SharedPreferencesWithCache].
library;

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/settings_prefs_keys.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../../domain/value_objects/grace_period.dart';
import '../../domain/value_objects/intake_window.dart';

/// Key used to persist the user's manual theme-mode preference.
///
/// Aliases the canonical [themeModePrefsKey] so the literal string lives in
/// exactly one place (shared with the prefs cache `allowList`).
const String _kThemeModeKey = themeModePrefsKey;

/// Key used to persist whether the app follows the system theme.
const String _kUseSystemThemeKey = useSystemThemePrefsKey;

/// Key used to persist whether the app follows the system language.
const String _kUseSystemLanguageKey = useSystemLanguagePrefsKey;

/// Key used to persist the user's manual language choice (IETF code).
const String _kManualLanguageKey = manualLanguagePrefsKey;

/// Thin wrapper around [SharedPreferencesWithCache] for raw read/write of
/// individual settings keys.
///
/// All reads are synchronous (backed by the in-memory cache); writes return
/// a [Future] that completes when the value is persisted to disk.
class SettingsLocalDataSource {
  /// Creates a [SettingsLocalDataSource] backed by the given [prefs] instance.
  const SettingsLocalDataSource(this._prefs);

  final SharedPreferencesWithCache _prefs;

  /// Returns the persisted manual [AppThemeMode].
  ///
  /// Falls back to [AppThemeMode.light] when no value has been stored, the
  /// stored code does not match any [AppThemeMode.code], or the stored
  /// value is of the wrong type (e.g. legacy `int` data from a pre-spec-012
  /// build). The wrong-type case throws inside `SharedPreferencesWithCache`'s
  /// `getString` cast; we catch it and degrade gracefully.
  AppThemeMode getThemeMode() {
    try {
      final String? code = _prefs.getString(_kThemeModeKey);
      return AppThemeMode.fromCodeOrDefault(code);
    } catch (_) {
      // Pre-spec-012 builds persisted this key as `int` (`ThemeMode.index`).
      // `SharedPreferencesWithCache.getString` casts the cached value to
      // `String?` and throws `TypeError` on legacy int data. Treat any
      // throwable as "no usable code stored" and fall back to the default.
      return AppThemeMode.light;
    }
  }

  /// Persists the user's manual [mode] choice as its stable
  /// [AppThemeMode.code] string (e.g. `'light'` / `'dark'`).
  Future<void> setThemeMode(AppThemeMode mode) =>
      _prefs.setString(_kThemeModeKey, mode.code);

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
  ///
  /// Unlike [getThemeMode], a wrong-type cached value is deliberately NOT
  /// caught here: this getter is unguarded by design. A `TypeError` from a
  /// legacy non-string value propagates to [SettingsRepositoryImpl.load]'s
  /// `catch`, which is the single containment boundary for the unguarded
  /// getters (→ `Left(Failure.unknown)`). Only [getThemeMode] needs an internal
  /// guard, because its key had a documented legacy `int` → `String` migration.
  AppLanguage getManualLanguage() {
    final String? code = _prefs.getString(_kManualLanguageKey);
    if (code == null) {
      return AppLanguage.en;
    }
    return AppLanguage.fromLanguageCodeOrDefault(code);
  }

  /// Persists the [value] for the "use system language" preference.
  Future<void> setUseSystemLanguage(bool value) =>
      _prefs.setBool(_kUseSystemLanguageKey, value);

  /// Persists the user's manual [language] choice as its IETF code.
  Future<void> setManualLanguage(AppLanguage language) =>
      _prefs.setString(_kManualLanguageKey, language.code);

  /// Returns the persisted [IntakeWindow].
  ///
  /// The raw stored `int` is routed through the [IntakeWindow] factory, so an
  /// out-of-range persisted value is clamped on read. Falls back to
  /// [IntakeWindow.defaultValue] when no value has been stored.
  ///
  /// Unguarded by design: a wrong-type cached value throws inside
  /// `SharedPreferencesWithCache.getInt`; that `TypeError` propagates to
  /// [SettingsRepositoryImpl.load]'s `catch`, the single containment boundary.
  IntakeWindow getIntakeWindow() => IntakeWindow(
    _prefs.getInt(intakeWindowMinutesPrefsKey) ??
        IntakeWindow.defaultValue.minutes,
  );

  /// Persists the [value] intake window as its length in minutes.
  Future<void> setIntakeWindow(IntakeWindow value) =>
      _prefs.setInt(intakeWindowMinutesPrefsKey, value.minutes);

  /// Returns the persisted [GracePeriod].
  ///
  /// The raw stored `int` is routed through the [GracePeriod] factory, so an
  /// out-of-range persisted value is clamped on read. Falls back to
  /// [GracePeriod.defaultValue] when no value has been stored.
  ///
  /// Unguarded by design: a wrong-type cached value throws inside
  /// `SharedPreferencesWithCache.getInt`; that `TypeError` propagates to
  /// [SettingsRepositoryImpl.load]'s `catch`, the single containment boundary.
  GracePeriod getGracePeriod() => GracePeriod(
    _prefs.getInt(gracePeriodMinutesPrefsKey) ??
        GracePeriod.defaultValue.minutes,
  );

  /// Persists the [value] grace period as its length in minutes.
  Future<void> setGracePeriod(GracePeriod value) =>
      _prefs.setInt(gracePeriodMinutesPrefsKey, value.minutes);

  /// Returns whether the user may mark intakes ahead of their scheduled time.
  ///
  /// Defaults to `false` when no value has been stored.
  bool getAllowMarkAhead() => _prefs.getBool(allowMarkAheadPrefsKey) ?? false;

  /// Persists the [value] for the "allow marking intakes ahead of time" flag.
  Future<void> setAllowMarkAhead(bool value) =>
      _prefs.setBool(allowMarkAheadPrefsKey, value);
}
