/// Abstract contract for reading and persisting user settings.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_language.dart';
import '../entities/app_settings.dart';
import '../entities/app_theme_mode.dart';

/// Contract for reading and persisting user settings.
///
/// Implementations live in the data layer and may use shared preferences,
/// secure storage, or any other persistence mechanism. Covers theme and
/// language preferences.
abstract interface class SettingsRepository {
  /// Loads current settings synchronously from cache.
  ///
  /// Never fails — returns defaults if nothing is stored.
  AppSettings load();

  /// Persists the user's manual theme mode choice.
  ///
  /// Only [AppThemeMode.light] and [AppThemeMode.dark] are meaningful —
  /// the enum has no `system` value by design (the orthogonal
  /// [AppSettings.useSystemTheme] flag owns that concept).
  Future<Either<Failure, void>> saveThemeMode(AppThemeMode mode);

  /// Persists whether the app should follow the device system theme.
  Future<Either<Failure, void>> saveUseSystemTheme(bool value);

  /// Persists whether the app should follow the device language.
  ///
  /// When `true`, the active language is resolved from the device locale
  /// by the presentation layer; the manual selection is ignored until
  /// this flag is `false`.
  Future<Either<Failure, void>> saveUseSystemLanguage(bool value);

  /// Persists the user's manual [AppLanguage] choice.
  ///
  /// Consulted only when [AppSettings.useSystemLanguage] is `false`.
  Future<Either<Failure, void>> saveManualLanguage(AppLanguage language);
}
