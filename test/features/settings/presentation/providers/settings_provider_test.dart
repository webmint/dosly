library;

import 'package:dosly/core/error/failures.dart';
import 'package:dosly/features/settings/domain/entities/app_language.dart';
import 'package:dosly/features/settings/domain/entities/app_settings.dart';
import 'package:dosly/features/settings/domain/entities/app_theme_mode.dart';
import 'package:dosly/features/settings/domain/repositories/settings_repository.dart';
import 'package:dosly/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

/// Fake [SettingsRepository] for provider unit tests.
///
/// Holds an in-memory [AppSettings] and exposes flags to simulate persistence
/// failures on individual save methods.
class _FakeSettingsRepository implements SettingsRepository {
  AppSettings _settings = const AppSettings();

  /// When true, [saveThemeMode] returns a [Left] with a [CacheFailure].
  bool failOnSaveThemeMode = false;

  /// When true, [saveUseSystemTheme] returns a [Left] with a [CacheFailure].
  bool failOnSaveUseSystemTheme = false;

  /// When true, [saveUseSystemLanguage] returns a [Left] with a [CacheFailure].
  bool failOnSaveUseSystemLanguage = false;

  /// When true, [saveManualLanguage] returns a [Left] with a [CacheFailure].
  bool failOnSaveManualLanguage = false;

  @override
  AppSettings load() => _settings;

  @override
  Future<Either<Failure, void>> saveThemeMode(AppThemeMode mode) async {
    if (failOnSaveThemeMode) {
      return const Left(CacheFailure('mock failure'));
    }
    _settings = _settings.copyWith(manualThemeMode: mode);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> saveUseSystemTheme(bool value) async {
    if (failOnSaveUseSystemTheme) {
      return const Left(CacheFailure('mock failure'));
    }
    _settings = _settings.copyWith(useSystemTheme: value);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> saveUseSystemLanguage(bool value) async {
    if (failOnSaveUseSystemLanguage) {
      return const Left(CacheFailure('mock failure'));
    }
    _settings = _settings.copyWith(useSystemLanguage: value);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> saveManualLanguage(AppLanguage language) async {
    if (failOnSaveManualLanguage) {
      return const Left(CacheFailure('mock failure'));
    }
    _settings = _settings.copyWith(manualLanguage: language);
    return const Right(null);
  }
}

void main() {
  group('SettingsNotifier', () {
    late _FakeSettingsRepository fakeRepo;
    late ProviderContainer container;

    setUp(() {
      fakeRepo = _FakeSettingsRepository();
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
        'initial state has useSystemTheme=true and manualThemeMode=light from repo',
        () {
      final settings = container.read(settingsProvider);

      expect(settings.useSystemTheme, isTrue);
      expect(settings.manualThemeMode, AppThemeMode.light);
    });

    test('setThemeMode(AppThemeMode.dark) updates manualThemeMode to dark',
        () async {
      await container
          .read(settingsProvider.notifier)
          .setThemeMode(AppThemeMode.dark);

      final settings = container.read(settingsProvider);

      expect(settings.manualThemeMode, AppThemeMode.dark);
    });

    test('setThemeMode does not update state when save fails', () async {
      fakeRepo.failOnSaveThemeMode = true;

      await container
          .read(settingsProvider.notifier)
          .setThemeMode(AppThemeMode.dark);

      final settings = container.read(settingsProvider);

      expect(settings.manualThemeMode, AppThemeMode.light);
    });

    test('setUseSystemTheme(false) updates useSystemTheme to false', () async {
      await container
          .read(settingsProvider.notifier)
          .setUseSystemTheme(false);

      final settings = container.read(settingsProvider);

      expect(settings.useSystemTheme, isFalse);
      expect(settings.manualThemeMode, AppThemeMode.light);
    });

    test('setUseSystemTheme does not update state when save fails', () async {
      fakeRepo.failOnSaveUseSystemTheme = true;

      await container
          .read(settingsProvider.notifier)
          .setUseSystemTheme(false);

      final settings = container.read(settingsProvider);

      expect(settings.useSystemTheme, isTrue);
    });

    test(
        'useSystemTheme remains true when only manualThemeMode is updated to dark',
        () async {
      // First set manual to dark
      await container
          .read(settingsProvider.notifier)
          .setThemeMode(AppThemeMode.dark);
      // Ensure useSystemTheme is still on
      final settings = container.read(settingsProvider);
      expect(settings.useSystemTheme, isTrue);
      expect(settings.manualThemeMode, AppThemeMode.dark);
    });

    test(
        'manualThemeMode=dark is returned when useSystemTheme is set to false',
        () async {
      await container
          .read(settingsProvider.notifier)
          .setThemeMode(AppThemeMode.dark);
      await container
          .read(settingsProvider.notifier)
          .setUseSystemTheme(false);

      final settings = container.read(settingsProvider);

      expect(settings.useSystemTheme, isFalse);
      expect(settings.manualThemeMode, AppThemeMode.dark);
    });

    test('setUseSystemLanguage(false) updates useSystemLanguage to false',
        () async {
      await container
          .read(settingsProvider.notifier)
          .setUseSystemLanguage(false);

      final settings = container.read(settingsProvider);

      expect(settings.useSystemLanguage, isFalse);
    });

    test('setUseSystemLanguage does not update state when save fails',
        () async {
      fakeRepo.failOnSaveUseSystemLanguage = true;

      await container
          .read(settingsProvider.notifier)
          .setUseSystemLanguage(false);

      final settings = container.read(settingsProvider);

      expect(settings.useSystemLanguage, isTrue);
    });

    test('setManualLanguage(AppLanguage.uk) updates manualLanguage to uk',
        () async {
      await container
          .read(settingsProvider.notifier)
          .setManualLanguage(AppLanguage.uk);

      final settings = container.read(settingsProvider);

      expect(settings.manualLanguage, AppLanguage.uk);
    });

    test('setManualLanguage does not update state when save fails', () async {
      fakeRepo.failOnSaveManualLanguage = true;

      await container
          .read(settingsProvider.notifier)
          .setManualLanguage(AppLanguage.uk);

      final settings = container.read(settingsProvider);

      expect(settings.manualLanguage, AppLanguage.en);
    });

    test('useSystemLanguage=true by default (system locale drives resolution)', () {
      final settings = container.read(settingsProvider);

      expect(settings.useSystemLanguage, isTrue);
    });

    test(
        'manualLanguage=de is stored after setUseSystemLanguage(false) + setManualLanguage(de)',
        () async {
      await container
          .read(settingsProvider.notifier)
          .setUseSystemLanguage(false);
      await container
          .read(settingsProvider.notifier)
          .setManualLanguage(AppLanguage.de);

      final settings = container.read(settingsProvider);

      expect(settings.useSystemLanguage, isFalse);
      expect(settings.manualLanguage, AppLanguage.de);
    });
  });
}
