/// Abstract contract for reading and persisting user settings.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_language.dart';
import '../entities/app_settings.dart';
import '../entities/app_theme_mode.dart';
import '../value_objects/grace_period.dart';
import '../value_objects/intake_window.dart';

/// Contract for reading and persisting user settings.
///
/// Implementations live in the data layer and may use shared preferences,
/// secure storage, or any other persistence mechanism. Covers theme and
/// language preferences.
abstract interface class SettingsRepository {
  /// Reads current settings synchronously from cache.
  ///
  /// Returns `Right(settings)` on success, or `Left(Failure.unknown(...))` if
  /// the underlying cache read throws. Stored-but-unrecognized values fall back
  /// to their per-field defaults inside the data source.
  Either<Failure, AppSettings> load();

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

  /// Persists the user's intake [window] choice.
  ///
  /// The [IntakeWindow] value object is self-clamping, so the persisted
  /// length in minutes is always within [IntakeWindow.minMinutes]..
  /// [IntakeWindow.maxMinutes].
  Future<Either<Failure, void>> saveIntakeWindow(IntakeWindow window);

  /// Persists the user's grace-period ([grace]) choice.
  ///
  /// The [GracePeriod] value object is self-clamping, so the persisted
  /// length in minutes is always within [GracePeriod.minMinutes]..
  /// [GracePeriod.maxMinutes].
  Future<Either<Failure, void>> saveGracePeriod(GracePeriod grace);

  /// Persists whether the user may mark an intake `taken` before its
  /// scheduled time.
  Future<Either<Failure, void>> saveAllowMarkAhead(bool value);
}
