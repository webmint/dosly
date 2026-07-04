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

import '../value_objects/grace_period.dart';
import '../value_objects/intake_window.dart';
import 'app_language.dart';
import 'app_theme_mode.dart';

part 'app_settings.freezed.dart';

/// Application-wide user preferences.
///
/// Each field is a raw domain value; presentation code reads the
/// fields through narrow `ref.watch(settingsNotifierProvider.select(...))` calls
/// and computes the Flutter-typed values it needs at the seam. When
/// [useSystemTheme] is `true` (the default) the manual [manualThemeMode]
/// is ignored by the app shell. Likewise [manualLanguage] is ignored
/// when [useSystemLanguage] is `true`.
///
/// Intake behaviour is captured by three further preferences:
/// [intakeWindow] — how long an intake stays `pending` after its scheduled
/// time before auto-transitioning to `missed` (modeled by the self-clamping
/// [IntakeWindow] value object, 15–240 minutes); [gracePeriod] — how long
/// after marking an intake `taken` the user may undo it (modeled by the
/// self-clamping [GracePeriod] value object, 0–30 minutes); and
/// [allowMarkAhead] — whether the user may mark an intake `taken` before its
/// scheduled time (defaults to `false`).
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
    @Default(IntakeWindow.defaultValue) IntakeWindow intakeWindow,
    @Default(GracePeriod.defaultValue) GracePeriod gracePeriod,
    @Default(false) bool allowMarkAhead,
  }) = _AppSettings;
}
