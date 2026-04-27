/// Abstract contract for reading and persisting user settings.
library;

import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_settings.dart';

/// Contract for reading and persisting user settings.
///
/// Implementations live in the data layer and may use shared preferences,
/// secure storage, or any other persistence mechanism.
abstract interface class SettingsRepository {
  /// Loads current settings synchronously from cache.
  ///
  /// Never fails — returns defaults if nothing is stored.
  AppSettings load();

  /// Persists the user's manual theme mode choice.
  ///
  /// Only [ThemeMode.light] and [ThemeMode.dark] are meaningful values here.
  Future<Either<Failure, void>> saveThemeMode(ThemeMode mode);

  /// Persists whether the app should follow the device system theme.
  Future<Either<Failure, void>> saveUseSystemTheme(bool value);
}
