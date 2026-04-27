library;

import 'package:dosly/core/error/failures.dart';
import 'package:dosly/features/settings/domain/entities/app_settings.dart';
import 'package:dosly/features/settings/domain/repositories/settings_repository.dart';
import 'package:dosly/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
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

  @override
  AppSettings load() => _settings;

  @override
  Future<Either<Failure, void>> saveThemeMode(ThemeMode mode) async {
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
      expect(settings.manualThemeMode, ThemeMode.light);
      expect(settings.effectiveThemeMode, ThemeMode.system);
    });

    test('setThemeMode(ThemeMode.dark) updates manualThemeMode to dark',
        () async {
      await container
          .read(settingsProvider.notifier)
          .setThemeMode(ThemeMode.dark);

      final settings = container.read(settingsProvider);

      expect(settings.manualThemeMode, ThemeMode.dark);
    });

    test('setThemeMode does not update state when save fails', () async {
      fakeRepo.failOnSaveThemeMode = true;

      await container
          .read(settingsProvider.notifier)
          .setThemeMode(ThemeMode.dark);

      final settings = container.read(settingsProvider);

      expect(settings.manualThemeMode, ThemeMode.light);
    });

    test('setUseSystemTheme(false) updates useSystemTheme to false', () async {
      await container
          .read(settingsProvider.notifier)
          .setUseSystemTheme(false);

      final settings = container.read(settingsProvider);

      expect(settings.useSystemTheme, isFalse);
      expect(settings.effectiveThemeMode, ThemeMode.light);
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
        'effectiveThemeMode returns system when useSystemTheme=true even if manualThemeMode=dark',
        () async {
      // First set manual to dark
      await container
          .read(settingsProvider.notifier)
          .setThemeMode(ThemeMode.dark);
      // Ensure system is still on
      final settings = container.read(settingsProvider);
      expect(settings.effectiveThemeMode, ThemeMode.system);
    });

    test(
        'effectiveThemeMode returns manualThemeMode when useSystemTheme=false',
        () async {
      await container
          .read(settingsProvider.notifier)
          .setThemeMode(ThemeMode.dark);
      await container
          .read(settingsProvider.notifier)
          .setUseSystemTheme(false);

      final settings = container.read(settingsProvider);

      expect(settings.effectiveThemeMode, ThemeMode.dark);
    });
  });
}
