/// Concrete [SettingsRepository] backed by local shared preferences.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/value_objects/grace_period.dart';
import '../../domain/value_objects/intake_window.dart';
import '../datasources/settings_local_data_source.dart';

/// Implementation of [SettingsRepository] that delegates persistence to
/// [SettingsLocalDataSource].
class SettingsRepositoryImpl implements SettingsRepository {
  /// Creates a [SettingsRepositoryImpl] backed by the given [dataSource].
  const SettingsRepositoryImpl(this._dataSource);

  final SettingsLocalDataSource _dataSource;

  @override
  Either<Failure, AppSettings> load() {
    try {
      return Right(
        AppSettings(
          useSystemTheme: _dataSource.getUseSystemTheme(),
          manualThemeMode: _dataSource.getThemeMode(),
          useSystemLanguage: _dataSource.getUseSystemLanguage(),
          manualLanguage: _dataSource.getManualLanguage(),
          intakeWindow: _dataSource.getIntakeWindow(),
          gracePeriod: _dataSource.getGracePeriod(),
          allowMarkAhead: _dataSource.getAllowMarkAhead(),
        ),
      );
    } catch (e, st) {
      return Left(Failure.unknown(e, st));
    }
  }

  @override
  Future<Either<Failure, void>> saveThemeMode(AppThemeMode mode) async {
    try {
      await _dataSource.setThemeMode(mode);
      return const Right(null);
    } catch (e, st) {
      return Left(Failure.unknown(e, st));
    }
  }

  @override
  Future<Either<Failure, void>> saveUseSystemTheme(bool value) async {
    try {
      await _dataSource.setUseSystemTheme(value);
      return const Right(null);
    } catch (e, st) {
      return Left(Failure.unknown(e, st));
    }
  }

  @override
  Future<Either<Failure, void>> saveUseSystemLanguage(bool value) async {
    try {
      await _dataSource.setUseSystemLanguage(value);
      return const Right(null);
    } catch (e, st) {
      return Left(Failure.unknown(e, st));
    }
  }

  @override
  Future<Either<Failure, void>> saveManualLanguage(AppLanguage language) async {
    try {
      await _dataSource.setManualLanguage(language);
      return const Right(null);
    } catch (e, st) {
      return Left(Failure.unknown(e, st));
    }
  }

  @override
  Future<Either<Failure, void>> saveIntakeWindow(IntakeWindow window) async {
    try {
      await _dataSource.setIntakeWindow(window);
      return const Right(null);
    } catch (e, st) {
      return Left(Failure.unknown(e, st));
    }
  }

  @override
  Future<Either<Failure, void>> saveGracePeriod(GracePeriod grace) async {
    try {
      await _dataSource.setGracePeriod(grace);
      return const Right(null);
    } catch (e, st) {
      return Left(Failure.unknown(e, st));
    }
  }

  @override
  Future<Either<Failure, void>> saveAllowMarkAhead(bool value) async {
    try {
      await _dataSource.setAllowMarkAhead(value);
      return const Right(null);
    } catch (e, st) {
      return Left(Failure.unknown(e, st));
    }
  }
}
