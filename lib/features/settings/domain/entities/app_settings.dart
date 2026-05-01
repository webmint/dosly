/// Application-wide user preferences.
///
/// Holds the user's theme and language preferences as plain domain fields:
/// [AppSettings.useSystemTheme] / [AppSettings.manualThemeMode] and
/// [AppSettings.useSystemLanguage] / [AppSettings.manualLanguage]. The
/// domain entity intentionally exposes no Flutter SDK types — the
/// `Flutter SDK ↔ domain` mapping (e.g. translating `manualThemeMode` to
/// `package:flutter`'s `ThemeMode`, or building a `Locale` from
/// `manualLanguage.code`) is confined to the presentation seam in
/// `lib/app.dart`. See constitution §2.1: `domain/` must not import
/// `package:flutter/*`.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_language.dart';
import 'app_theme_mode.dart';

part 'app_settings.freezed.dart';

/// Application-wide user preferences.
///
/// Each field is a raw domain value; presentation code reads the four
/// fields through narrow `ref.watch(settingsProvider.select(...))` calls
/// and computes the Flutter-typed values it needs at the seam. When
/// [useSystemTheme] is `true` (the default) the manual [manualThemeMode]
/// is ignored by the app shell. Likewise [manualLanguage] is ignored
/// when [useSystemLanguage] is `true`.
@freezed
abstract class AppSettings with _$AppSettings {
  /// Creates an [AppSettings] instance.
  ///
  /// Defaults to following the system theme ([useSystemTheme] = `true`)
  /// with [manualThemeMode] = [AppThemeMode.light] as the fallback manual
  /// selection. Defaults to following the system language
  /// ([useSystemLanguage] = `true`) with [manualLanguage] = [AppLanguage.en]
  /// as the fallback manual choice.
  const factory AppSettings({
    @Default(true) bool useSystemTheme,
    @Default(AppThemeMode.light) AppThemeMode manualThemeMode,
    @Default(true) bool useSystemLanguage,
    @Default(AppLanguage.en) AppLanguage manualLanguage,
  }) = _AppSettings;
}
