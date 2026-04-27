/// Concrete [SettingsRepository] backed by local shared preferences.
library;

import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_data_source.dart';

/// Implementation of [SettingsRepository] that delegates persistence to
/// [SettingsLocalDataSource].
class SettingsRepositoryImpl implements SettingsRepository {
  /// Creates a [SettingsRepositoryImpl] backed by the given [dataSource].
  const SettingsRepositoryImpl(this._dataSource);

  final SettingsLocalDataSource _dataSource;

  @override
  AppSettings load() => AppSettings(
        useSystemTheme: _dataSource.getUseSystemTheme(),
        manualThemeMode: _dataSource.getThemeMode(),
      );

  @override
  Future<Either<Failure, void>> saveThemeMode(ThemeMode mode) async {
    try {
      await _dataSource.setThemeMode(mode);
      return const Right(null);
    } on Exception catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveUseSystemTheme(bool value) async {
    try {
      await _dataSource.setUseSystemTheme(value);
      return const Right(null);
    } on Exception catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
