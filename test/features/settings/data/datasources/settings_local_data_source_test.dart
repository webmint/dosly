library;

import 'package:dosly/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:dosly/features/settings/domain/entities/app_language.dart';
import 'package:dosly/features/settings/domain/entities/app_theme_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Builds a [SettingsLocalDataSource] backed by an in-memory prefs store
/// pre-seeded with [initialData].  Pass an empty map for an absent-key setup.
Future<SettingsLocalDataSource> _buildDataSource({
  Map<String, Object> initialData = const {},
}) async {
  SharedPreferencesAsyncPlatform.instance =
      initialData.isEmpty
          ? InMemorySharedPreferencesAsync.empty()
          : InMemorySharedPreferencesAsync.withData(initialData);
  // allowList must stay in sync with SettingsLocalDataSource's key constants.
  final prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: {
        'themeMode',
        'useSystemTheme',
        'useSystemLanguage',
        'manualLanguage',
      },
    ),
  );
  return SettingsLocalDataSource(prefs);
}

void main() {
  group('SettingsLocalDataSource', () {
    // -------------------------------------------------------------------------
    // getThemeMode
    // -------------------------------------------------------------------------
    group('getThemeMode', () {
      test('should return AppThemeMode.dark when stored code is "dark"',
          () async {
        final ds = await _buildDataSource(
          initialData: {'themeMode': 'dark'},
        );

        expect(ds.getThemeMode(), AppThemeMode.dark);
      });

      test(
          'should return AppThemeMode.light (default) when key is absent',
          () async {
        final ds = await _buildDataSource();

        expect(ds.getThemeMode(), AppThemeMode.light);
      });

      // The in-memory platform does not replicate the real prefs' String cast
      // TypeError when an int is stored, so the catch(_) branch cannot be
      // exercised via InMemorySharedPreferencesAsync.  Instead, we exercise
      // the same graceful-fallback path with an unrecognised string code that
      // reaches fromCodeOrDefault and returns the default.
      test(
          'should return AppThemeMode.light via fromCodeOrDefault orElse '
          'when stored code is unrecognised (catch branch unreachable via '
          'InMemorySharedPreferencesAsync — exercises the orElse default instead)',
          () async {
        final ds = await _buildDataSource(
          initialData: {'themeMode': 'legacy'},
        );

        expect(ds.getThemeMode(), AppThemeMode.light);
      });
    });

    // -------------------------------------------------------------------------
    // setThemeMode
    // -------------------------------------------------------------------------
    group('setThemeMode', () {
      test('should persist AppThemeMode.dark and read it back', () async {
        final ds = await _buildDataSource();

        await ds.setThemeMode(AppThemeMode.dark);

        expect(ds.getThemeMode(), AppThemeMode.dark);
      });
    });

    // -------------------------------------------------------------------------
    // getUseSystemTheme
    // -------------------------------------------------------------------------
    group('getUseSystemTheme', () {
      test('should return true (default) when key is absent', () async {
        final ds = await _buildDataSource();

        expect(ds.getUseSystemTheme(), isTrue);
      });

      test('should return false when stored value is false', () async {
        final ds = await _buildDataSource(
          initialData: {'useSystemTheme': false},
        );

        expect(ds.getUseSystemTheme(), isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // setUseSystemTheme
    // -------------------------------------------------------------------------
    group('setUseSystemTheme', () {
      test('should persist false and read it back', () async {
        final ds = await _buildDataSource();

        await ds.setUseSystemTheme(false);

        expect(ds.getUseSystemTheme(), isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // getUseSystemLanguage
    // -------------------------------------------------------------------------
    group('getUseSystemLanguage', () {
      test('should return true (default) when key is absent', () async {
        final ds = await _buildDataSource();

        expect(ds.getUseSystemLanguage(), isTrue);
      });

      test('should return false when stored value is false', () async {
        final ds = await _buildDataSource(
          initialData: {'useSystemLanguage': false},
        );

        expect(ds.getUseSystemLanguage(), isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // setUseSystemLanguage
    // -------------------------------------------------------------------------
    group('setUseSystemLanguage', () {
      test('should persist false and read it back', () async {
        final ds = await _buildDataSource();

        await ds.setUseSystemLanguage(false);

        expect(ds.getUseSystemLanguage(), isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // getManualLanguage
    // -------------------------------------------------------------------------
    group('getManualLanguage', () {
      test('should return AppLanguage.en when key is absent', () async {
        final ds = await _buildDataSource();

        expect(ds.getManualLanguage(), AppLanguage.en);
      });

      test('should return AppLanguage.en when stored code is unknown ("zz")',
          () async {
        final ds = await _buildDataSource(
          initialData: {'manualLanguage': 'zz'},
        );

        expect(ds.getManualLanguage(), AppLanguage.en);
      });

      test('should return AppLanguage.en when stored code is empty string',
          () async {
        final ds = await _buildDataSource(
          initialData: {'manualLanguage': ''},
        );

        expect(ds.getManualLanguage(), AppLanguage.en);
      });

      test('should return AppLanguage.uk when stored code is "uk"', () async {
        final ds = await _buildDataSource(
          initialData: {'manualLanguage': 'uk'},
        );

        expect(ds.getManualLanguage(), AppLanguage.uk);
      });
    });

    // -------------------------------------------------------------------------
    // setManualLanguage
    // -------------------------------------------------------------------------
    group('setManualLanguage', () {
      test('should persist AppLanguage.uk and read it back', () async {
        final ds = await _buildDataSource();

        await ds.setManualLanguage(AppLanguage.uk);

        expect(ds.getManualLanguage(), AppLanguage.uk);
      });
    });
  });
}
