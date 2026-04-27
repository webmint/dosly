library;

import 'package:dosly/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:dosly/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Future<SettingsRepositoryImpl> _buildRepository({
  Map<String, Object> initialData = const {},
}) async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData(initialData);
  final prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: {'themeMode', 'useSystemTheme'},
    ),
  );
  final dataSource = SettingsLocalDataSource(prefs);
  return SettingsRepositoryImpl(dataSource);
}

void main() {
  group('SettingsRepositoryImpl', () {
    group('load()', () {
      test('returns useSystemTheme=true and manualThemeMode=light by default',
          () async {
        final repository = await _buildRepository();

        final settings = repository.load();

        expect(settings.useSystemTheme, isTrue);
        expect(settings.manualThemeMode, ThemeMode.light);
      });

      test('returns useSystemTheme=false after saveUseSystemTheme(false)',
          () async {
        final repository = await _buildRepository();
        await repository.saveUseSystemTheme(false);

        final settings = repository.load();

        expect(settings.useSystemTheme, isFalse);
      });

      test(
          'returns manualThemeMode=dark after saveThemeMode(ThemeMode.dark)',
          () async {
        final repository = await _buildRepository();
        await repository.saveThemeMode(ThemeMode.dark);

        final settings = repository.load();

        expect(settings.manualThemeMode, ThemeMode.dark);
      });

      test(
          'returns manualThemeMode=light when out-of-range int (99) is stored',
          () async {
        final repository = await _buildRepository(
          initialData: {'themeMode': 99},
        );

        final settings = repository.load();

        expect(settings.manualThemeMode, ThemeMode.light);
      });

      test('effectiveThemeMode is system when useSystemTheme=true', () async {
        final repository = await _buildRepository();
        await repository.saveUseSystemTheme(true);
        await repository.saveThemeMode(ThemeMode.dark);

        final settings = repository.load();

        expect(settings.effectiveThemeMode, ThemeMode.system);
      });

      test(
          'effectiveThemeMode equals manualThemeMode when useSystemTheme=false',
          () async {
        final repository = await _buildRepository();
        await repository.saveUseSystemTheme(false);
        await repository.saveThemeMode(ThemeMode.dark);

        final settings = repository.load();

        expect(settings.effectiveThemeMode, ThemeMode.dark);
      });
    });

    group('saveThemeMode()', () {
      test('returns Right(null) on success', () async {
        final repository = await _buildRepository();

        final result = await repository.saveThemeMode(ThemeMode.light);

        expect(result, isA<Right<dynamic, void>>());
      });
    });

    group('saveUseSystemTheme()', () {
      test('returns Right(null) on success', () async {
        final repository = await _buildRepository();

        final result = await repository.saveUseSystemTheme(false);

        expect(result, isA<Right<dynamic, void>>());
      });
    });

    group('persistence round-trip', () {
      test(
          'saved themeMode and useSystemTheme survive reconstruction '
          'from the same SharedPreferences instance', () async {
        // Arrange — build the first repository and persist values.
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.empty();
        final prefs = await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
            allowList: {'themeMode', 'useSystemTheme'},
          ),
        );
        final firstRepository =
            SettingsRepositoryImpl(SettingsLocalDataSource(prefs));

        await firstRepository.saveThemeMode(ThemeMode.dark);
        await firstRepository.saveUseSystemTheme(false);

        // Act — reconstruct a new repository from the same prefs instance.
        final secondRepository =
            SettingsRepositoryImpl(SettingsLocalDataSource(prefs));
        final settings = secondRepository.load();

        // Assert — persisted values are visible to the new instance.
        expect(settings.manualThemeMode, ThemeMode.dark);
        expect(settings.useSystemTheme, isFalse);
      });
    });
  });
}
