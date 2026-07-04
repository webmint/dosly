library;

import 'package:dosly/core/error/failures.dart';
import 'package:dosly/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:dosly/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:dosly/features/settings/domain/entities/app_language.dart';
import 'package:dosly/features/settings/domain/entities/app_theme_mode.dart';
import 'package:dosly/features/settings/domain/value_objects/grace_period.dart';
import 'package:dosly/features/settings/domain/value_objects/intake_window.dart';
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
      allowList: {
        'themeMode',
        'useSystemTheme',
        'useSystemLanguage',
        'manualLanguage',
        'intakeWindowMinutes',
        'gracePeriodMinutes',
        'allowMarkAhead',
      },
    ),
  );
  final dataSource = SettingsLocalDataSource(prefs);
  return SettingsRepositoryImpl(dataSource);
}

/// Helper that builds an in-memory [SharedPreferencesWithCache] backed by an
/// empty store, suitable for wiring throwing data-source doubles.
Future<SharedPreferencesWithCache> _buildPrefs() async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  return SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: {
        'themeMode',
        'useSystemTheme',
        'useSystemLanguage',
        'manualLanguage',
        'intakeWindowMinutes',
        'gracePeriodMinutes',
        'allowMarkAhead',
      },
    ),
  );
}

/// Subclass of [SettingsLocalDataSource] that overrides individual getters to
/// throw a [StateError].
///
/// Used to prove that [SettingsRepositoryImpl.load()] converts any throwable
/// from the data source into a [Left(UnknownFailure)] (AC-3).
class _ThrowingGetterDataSource extends SettingsLocalDataSource {
  _ThrowingGetterDataSource(
    super.prefs, {
    this.throwOnGetIntakeWindow = false,
    this.throwOnGetGracePeriod = false,
    this.throwOnGetAllowMarkAhead = false,
  });

  /// Additional getters that can be toggled to throw for the new-settings
  /// Left(UnknownFailure) tests; each defaults to `false` so existing call
  /// sites (`_ThrowingGetterDataSource(prefs)`) keep relying on the
  /// unconditional [getUseSystemTheme] throw below.
  final bool throwOnGetIntakeWindow;
  final bool throwOnGetGracePeriod;
  final bool throwOnGetAllowMarkAhead;

  @override
  bool getUseSystemTheme() => throw StateError('boom: getUseSystemTheme');

  @override
  IntakeWindow getIntakeWindow() {
    if (throwOnGetIntakeWindow) throw StateError('boom: getIntakeWindow');
    return super.getIntakeWindow();
  }

  @override
  GracePeriod getGracePeriod() {
    if (throwOnGetGracePeriod) throw StateError('boom: getGracePeriod');
    return super.getGracePeriod();
  }

  @override
  bool getAllowMarkAhead() {
    if (throwOnGetAllowMarkAhead) throw StateError('boom: getAllowMarkAhead');
    return super.getAllowMarkAhead();
  }
}

/// Subclass of [SettingsLocalDataSource] that overrides individual setters to
/// throw a [StateError] (an [Error], not an [Exception]).
///
/// Used to prove that each [SettingsRepositoryImpl.save*()] method converts
/// any [Error] thrown by the data source into a [Left(UnknownFailure)] (AC-7).
/// Pass exactly one `throwOn*` flag as `true` per test instance.
class _ThrowingSetterDataSource extends SettingsLocalDataSource {
  _ThrowingSetterDataSource(
    super.prefs, {
    this.throwOnSetThemeMode = false,
    this.throwOnSetUseSystemTheme = false,
    this.throwOnSetUseSystemLanguage = false,
    this.throwOnSetManualLanguage = false,
    this.throwOnSetIntakeWindow = false,
    this.throwOnSetGracePeriod = false,
    this.throwOnSetAllowMarkAhead = false,
  });

  /// Which setter should throw; exactly one flag set to true per test instance.
  final bool throwOnSetThemeMode;
  final bool throwOnSetUseSystemTheme;
  final bool throwOnSetUseSystemLanguage;
  final bool throwOnSetManualLanguage;
  final bool throwOnSetIntakeWindow;
  final bool throwOnSetGracePeriod;
  final bool throwOnSetAllowMarkAhead;

  @override
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (throwOnSetThemeMode) throw StateError('boom: setThemeMode');
    return super.setThemeMode(mode);
  }

  @override
  Future<void> setUseSystemTheme(bool value) async {
    if (throwOnSetUseSystemTheme) throw StateError('boom: setUseSystemTheme');
    return super.setUseSystemTheme(value);
  }

  @override
  Future<void> setUseSystemLanguage(bool value) async {
    if (throwOnSetUseSystemLanguage) {
      throw StateError('boom: setUseSystemLanguage');
    }
    return super.setUseSystemLanguage(value);
  }

  @override
  Future<void> setManualLanguage(AppLanguage language) async {
    if (throwOnSetManualLanguage) throw StateError('boom: setManualLanguage');
    return super.setManualLanguage(language);
  }

  @override
  Future<void> setIntakeWindow(IntakeWindow value) async {
    if (throwOnSetIntakeWindow) throw StateError('boom: setIntakeWindow');
    return super.setIntakeWindow(value);
  }

  @override
  Future<void> setGracePeriod(GracePeriod value) async {
    if (throwOnSetGracePeriod) throw StateError('boom: setGracePeriod');
    return super.setGracePeriod(value);
  }

  @override
  Future<void> setAllowMarkAhead(bool value) async {
    if (throwOnSetAllowMarkAhead) throw StateError('boom: setAllowMarkAhead');
    return super.setAllowMarkAhead(value);
  }
}

void main() {
  group('SettingsRepositoryImpl', () {
    group('load()', () {
      test(
        'returns useSystemTheme=true and manualThemeMode=light by default',
        () async {
          final repository = await _buildRepository();

          final settings = repository.load().getOrElse(
            (f) => fail('expected Right, got Left: $f'),
          );

          expect(settings.useSystemTheme, isTrue);
          expect(settings.manualThemeMode, AppThemeMode.light);
        },
      );

      test(
        'returns useSystemTheme=false after saveUseSystemTheme(false)',
        () async {
          final repository = await _buildRepository();
          await repository.saveUseSystemTheme(false);

          final settings = repository.load().getOrElse(
            (f) => fail('expected Right, got Left: $f'),
          );

          expect(settings.useSystemTheme, isFalse);
        },
      );

      test(
        'returns manualThemeMode=dark after saveThemeMode(AppThemeMode.dark)',
        () async {
          final repository = await _buildRepository();
          await repository.saveThemeMode(AppThemeMode.dark);

          final settings = repository.load().getOrElse(
            (f) => fail('expected Right, got Left: $f'),
          );

          expect(settings.manualThemeMode, AppThemeMode.dark);
        },
      );

      test(
        'returns manualThemeMode=light when unknown string code is stored',
        () async {
          final repository = await _buildRepository(
            initialData: {'themeMode': 'unknown'},
          );

          final settings = repository.load().getOrElse(
            (f) => fail('expected Right, got Left: $f'),
          );

          expect(settings.manualThemeMode, AppThemeMode.light);
        },
      );

      // AC-8: legacy `int` themeMode (pre-spec-012 format, persisted as
      // ThemeMode.index) falls back to AppThemeMode.light. The data source's
      // try/catch around _prefs.getString absorbs the TypeError that
      // SharedPreferencesWithCache raises when casting the cached int to
      // String?, returning the default instead of crashing.
      test(
        'returns manualThemeMode=light when legacy int themeMode (1) is stored',
        () async {
          final repository = await _buildRepository(
            initialData: {'themeMode': 1},
          );

          final settings = repository.load().getOrElse(
            (f) => fail('expected Right, got Left: $f'),
          );

          expect(settings.manualThemeMode, AppThemeMode.light);
        },
      );

      test(
        'returns useSystemLanguage=true and manualLanguage=en by default',
        () async {
          final repository = await _buildRepository();

          final settings = repository.load().getOrElse(
            (f) => fail('expected Right, got Left: $f'),
          );

          expect(settings.useSystemLanguage, isTrue);
          expect(settings.manualLanguage, AppLanguage.en);
        },
      );

      test(
        'returns useSystemLanguage=false after saveUseSystemLanguage(false)',
        () async {
          final repository = await _buildRepository();
          await repository.saveUseSystemLanguage(false);

          final settings = repository.load().getOrElse(
            (f) => fail('expected Right, got Left: $f'),
          );

          expect(settings.useSystemLanguage, isFalse);
        },
      );

      test(
        'returns manualLanguage=uk after saveManualLanguage(AppLanguage.uk)',
        () async {
          final repository = await _buildRepository();
          await repository.saveManualLanguage(AppLanguage.uk);

          final settings = repository.load().getOrElse(
            (f) => fail('expected Right, got Left: $f'),
          );

          expect(settings.manualLanguage, AppLanguage.uk);
        },
      );

      test(
        'returns manualLanguage=en when an unknown code (xx) is stored',
        () async {
          final repository = await _buildRepository(
            initialData: {'manualLanguage': 'xx'},
          );

          final settings = repository.load().getOrElse(
            (f) => fail('expected Right, got Left: $f'),
          );

          expect(settings.manualLanguage, AppLanguage.en);
        },
      );

      test(
        'useSystemLanguage=true and manualLanguage=en by default (system locale drives resolution)',
        () async {
          final repository = await _buildRepository();

          final settings = repository.load().getOrElse(
            (f) => fail('expected Right, got Left: $f'),
          );

          expect(settings.useSystemLanguage, isTrue);
          expect(settings.manualLanguage, AppLanguage.en);
        },
      );

      test(
        'manualLanguage=de is stored when useSystemLanguage=false and saveManualLanguage(de)',
        () async {
          final repository = await _buildRepository();
          await repository.saveUseSystemLanguage(false);
          await repository.saveManualLanguage(AppLanguage.de);

          final settings = repository.load().getOrElse(
            (f) => fail('expected Right, got Left: $f'),
          );

          expect(settings.useSystemLanguage, isFalse);
          expect(settings.manualLanguage, AppLanguage.de);
        },
      );
    });

    group('load() — intake window / grace period / allow mark ahead', () {
      test(
        'returns AppSettings.defaultValue-equivalent intake=120, grace=5, '
        'allowMarkAhead=false when keys are absent',
        () async {
          final repository = await _buildRepository();

          final settings = repository.load().getOrElse(
            (f) => fail('expected Right, got Left: $f'),
          );

          expect(settings.intakeWindow, IntakeWindow.defaultValue);
          expect(settings.gracePeriod, GracePeriod.defaultValue);
          expect(settings.allowMarkAhead, isFalse);
        },
      );

      test(
        'returns intake/grace/allowMarkAhead reflecting seeded non-default values',
        () async {
          final repository = await _buildRepository(
            initialData: {
              'intakeWindowMinutes': 90,
              'gracePeriodMinutes': 10,
              'allowMarkAhead': true,
            },
          );

          final settings = repository.load().getOrElse(
            (f) => fail('expected Right, got Left: $f'),
          );

          expect(settings.intakeWindow, IntakeWindow(90));
          expect(settings.gracePeriod, GracePeriod(10));
          expect(settings.allowMarkAhead, isTrue);
        },
      );
    });

    group('saveThemeMode()', () {
      test('returns Right(null) on success', () async {
        final repository = await _buildRepository();

        final result = await repository.saveThemeMode(AppThemeMode.light);

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

    group('saveUseSystemLanguage()', () {
      test('returns Right(null) on success', () async {
        final repository = await _buildRepository();

        final result = await repository.saveUseSystemLanguage(false);

        expect(result, isA<Right<dynamic, void>>());
      });
    });

    group('saveManualLanguage()', () {
      test('returns Right(null) on success', () async {
        final repository = await _buildRepository();

        final result = await repository.saveManualLanguage(AppLanguage.de);

        expect(result, isA<Right<dynamic, void>>());
      });
    });

    group('saveIntakeWindow()', () {
      test('returns Right(null) on success and persists the value', () async {
        final repository = await _buildRepository();

        final result = await repository.saveIntakeWindow(IntakeWindow(90));

        expect(result, isA<Right<dynamic, void>>());
        final settings = repository.load().getOrElse(
          (f) => fail('expected Right, got Left: $f'),
        );
        expect(settings.intakeWindow, IntakeWindow(90));
      });

      test(
        'returns Left(UnknownFailure) when setter throws StateError',
        () async {
          final prefs = await _buildPrefs();
          final repository = SettingsRepositoryImpl(
            _ThrowingSetterDataSource(prefs, throwOnSetIntakeWindow: true),
          );

          final result = await repository.saveIntakeWindow(IntakeWindow(90));

          expect(result.isLeft(), isTrue);
          result.fold((failure) {
            expect(failure, isA<UnknownFailure>());
            expect(failure, isNot(isA<CacheFailure>()));
          }, (_) => fail('expected Left, got Right'));
        },
      );
    });

    group('saveGracePeriod()', () {
      test('returns Right(null) on success and persists the value', () async {
        final repository = await _buildRepository();

        final result = await repository.saveGracePeriod(GracePeriod(10));

        expect(result, isA<Right<dynamic, void>>());
        final settings = repository.load().getOrElse(
          (f) => fail('expected Right, got Left: $f'),
        );
        expect(settings.gracePeriod, GracePeriod(10));
      });

      test(
        'returns Left(UnknownFailure) when setter throws StateError',
        () async {
          final prefs = await _buildPrefs();
          final repository = SettingsRepositoryImpl(
            _ThrowingSetterDataSource(prefs, throwOnSetGracePeriod: true),
          );

          final result = await repository.saveGracePeriod(GracePeriod(10));

          expect(result.isLeft(), isTrue);
          result.fold((failure) {
            expect(failure, isA<UnknownFailure>());
            expect(failure, isNot(isA<CacheFailure>()));
          }, (_) => fail('expected Left, got Right'));
        },
      );
    });

    group('saveAllowMarkAhead()', () {
      test('returns Right(null) on success and persists the value', () async {
        final repository = await _buildRepository();

        final result = await repository.saveAllowMarkAhead(true);

        expect(result, isA<Right<dynamic, void>>());
        final settings = repository.load().getOrElse(
          (f) => fail('expected Right, got Left: $f'),
        );
        expect(settings.allowMarkAhead, isTrue);
      });

      test(
        'returns Left(UnknownFailure) when setter throws StateError',
        () async {
          final prefs = await _buildPrefs();
          final repository = SettingsRepositoryImpl(
            _ThrowingSetterDataSource(prefs, throwOnSetAllowMarkAhead: true),
          );

          final result = await repository.saveAllowMarkAhead(true);

          expect(result.isLeft(), isTrue);
          result.fold((failure) {
            expect(failure, isA<UnknownFailure>());
            expect(failure, isNot(isA<CacheFailure>()));
          }, (_) => fail('expected Left, got Right'));
        },
      );
    });

    group('persistence round-trip', () {
      test('saved themeMode and useSystemTheme survive reconstruction '
          'from the same SharedPreferences instance', () async {
        // Arrange — build the first repository and persist values.
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.empty();
        final prefs = await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
            allowList: {
              'themeMode',
              'useSystemTheme',
              'useSystemLanguage',
              'manualLanguage',
              'intakeWindowMinutes',
              'gracePeriodMinutes',
              'allowMarkAhead',
            },
          ),
        );
        final firstRepository = SettingsRepositoryImpl(
          SettingsLocalDataSource(prefs),
        );

        await firstRepository.saveThemeMode(AppThemeMode.dark);
        await firstRepository.saveUseSystemTheme(false);

        // Act — reconstruct a new repository from the same prefs instance.
        final secondRepository = SettingsRepositoryImpl(
          SettingsLocalDataSource(prefs),
        );
        final settings = secondRepository.load().getOrElse(
          (f) => fail('expected Right, got Left: $f'),
        );

        // Assert — persisted values are visible to the new instance.
        expect(settings.manualThemeMode, AppThemeMode.dark);
        expect(settings.useSystemTheme, isFalse);
      });

      test('saved useSystemLanguage and manualLanguage survive reconstruction '
          'from the same SharedPreferences instance', () async {
        // Arrange — build the first repository and persist values.
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.empty();
        final prefs = await SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
            allowList: {
              'themeMode',
              'useSystemTheme',
              'useSystemLanguage',
              'manualLanguage',
              'intakeWindowMinutes',
              'gracePeriodMinutes',
              'allowMarkAhead',
            },
          ),
        );
        final firstRepository = SettingsRepositoryImpl(
          SettingsLocalDataSource(prefs),
        );

        await firstRepository.saveUseSystemLanguage(false);
        await firstRepository.saveManualLanguage(AppLanguage.uk);

        // Act — reconstruct a new repository from the same prefs instance.
        final secondRepository = SettingsRepositoryImpl(
          SettingsLocalDataSource(prefs),
        );
        final settings = secondRepository.load().getOrElse(
          (f) => fail('expected Right, got Left: $f'),
        );

        // Assert — persisted values are visible to the new instance.
        expect(settings.useSystemLanguage, isFalse);
        expect(settings.manualLanguage, AppLanguage.uk);
      });
    });

    // AC-2: wrong-type cache never throws out of load().
    //
    // SharedPreferencesWithCache raises a TypeError when a key was stored as
    // one type (e.g. int, String) but the getter calls a mismatched accessor
    // (e.g. getBool, getString). Because getUseSystemTheme(), getUseSystemLanguage(),
    // and getManualLanguage() have no internal try/catch, the TypeError propagates
    // to SettingsRepositoryImpl.load()'s outer try/catch, which converts it to
    // Left(UnknownFailure). load() must therefore never throw — even with
    // corrupt cache data — and must return Left (not Right) for these keys.
    group('load() — wrong-type cache values return Left (AC-2)', () {
      test(
        'returns Left when useSystemTheme is stored as a String (not bool)',
        () async {
          // 'not-a-bool' is a String; getBool() raises a TypeError that is not
          // caught inside getUseSystemTheme() — load()'s outer catch converts
          // it into Left(UnknownFailure).
          final repository = await _buildRepository(
            initialData: {'useSystemTheme': 'not-a-bool'},
          );

          final result = repository.load();

          expect(result.isLeft(), isTrue);
          result.fold(
            (f) => expect(f, isA<UnknownFailure>()),
            (_) => fail('expected Left'),
          );
        },
      );

      test(
        'returns Left when useSystemLanguage is stored as a String (not bool)',
        () async {
          // Same TypeError path as useSystemTheme but for the language toggle.
          final repository = await _buildRepository(
            initialData: {'useSystemLanguage': 'not-a-bool'},
          );

          final result = repository.load();

          expect(result.isLeft(), isTrue);
          result.fold(
            (f) => expect(f, isA<UnknownFailure>()),
            (_) => fail('expected Left'),
          );
        },
      );

      test(
        'returns Left when manualLanguage is stored as an int (not String)',
        () async {
          // getString() on an int-cached value raises TypeError; getManualLanguage()
          // is unguarded, so load()'s outer catch promotes it to Left(UnknownFailure).
          final repository = await _buildRepository(
            initialData: {'manualLanguage': 123},
          );

          final result = repository.load();

          expect(result.isLeft(), isTrue);
          result.fold(
            (f) => expect(f, isA<UnknownFailure>()),
            (_) => fail('expected Left'),
          );
        },
      );

      test(
        'returns Left when useSystemTheme is stored as an int (not bool)',
        () async {
          // getBool() casts the cached int to bool? and throws TypeError (same as
          // the String case); getUseSystemTheme() is unguarded, so load()'s outer
          // catch promotes it to Left(UnknownFailure).
          final repository = await _buildRepository(
            initialData: {'useSystemTheme': 1},
          );

          final result = repository.load();

          expect(result.isLeft(), isTrue);
          result.fold(
            (f) => expect(f, isA<UnknownFailure>()),
            (_) => fail('expected Left'),
          );
        },
      );

      test(
        'returns Left when useSystemLanguage is stored as an int (not bool)',
        () async {
          // getBool() casts the cached int to bool? and throws TypeError (same as
          // the String case); getUseSystemLanguage() is unguarded, so load()'s outer
          // catch promotes it to Left(UnknownFailure).
          final repository = await _buildRepository(
            initialData: {'useSystemLanguage': 1},
          );

          final result = repository.load();

          expect(result.isLeft(), isTrue);
          result.fold(
            (f) => expect(f, isA<UnknownFailure>()),
            (_) => fail('expected Left'),
          );
        },
      );

      // themeMode is the deliberate EXCEPTION to the AC-2 wrong-type→Left rule.
      // getThemeMode() wraps _prefs.getString('themeMode') in its own try/catch
      // and falls back to AppThemeMode.light, so the TypeError never reaches
      // load()'s outer catch — load() returns Right(light), not Left.
      test(
        'returns Right(manualThemeMode=light) when themeMode is wrong-type — the guarded exception to the AC-2 wrong-type→Left rule',
        () async {
          // 2.5 (double) is distinct from the legacy-int(1) test; getString() on a
          // double-cached value raises TypeError, which getThemeMode()'s internal
          // catch absorbs, yielding AppThemeMode.light as the default.
          final repository = await _buildRepository(
            initialData: {'themeMode': 2.5},
          );

          final settings = repository.load().getOrElse(
            (f) => fail('expected Right, got Left: $f'),
          );

          expect(settings.manualThemeMode, AppThemeMode.light);
        },
      );
    });

    // AC-3: a throwing data-source getter makes load() return Left(UnknownFailure).
    group(
      'load() — data-source getter throw → Left(UnknownFailure) (AC-3)',
      () {
        test(
          'returns Left(UnknownFailure) when the data source getter throws',
          () async {
            final prefs = await _buildPrefs();
            final throwingSource = _ThrowingGetterDataSource(prefs);
            final repository = SettingsRepositoryImpl(throwingSource);

            final result = repository.load();

            expect(result.isLeft(), isTrue);
            // Fold to extract the failure and assert its runtime type.
            result.fold(
              (failure) => expect(failure, isA<UnknownFailure>()),
              (_) => fail('expected Left, got Right'),
            );
          },
        );
      },
    );

    // Same AC-3 containment boundary, exercised for each of the 3 new
    // intake/grace/mark-ahead getters individually.
    group(
      'load() — new-setting getter throw → Left(UnknownFailure)',
      () {
        test(
          'returns Left(UnknownFailure) when getIntakeWindow throws',
          () async {
            final prefs = await _buildPrefs();
            final throwingSource = _ThrowingGetterDataSource(
              prefs,
              throwOnGetIntakeWindow: true,
            );
            final repository = SettingsRepositoryImpl(throwingSource);

            final result = repository.load();

            expect(result.isLeft(), isTrue);
            result.fold(
              (failure) => expect(failure, isA<UnknownFailure>()),
              (_) => fail('expected Left, got Right'),
            );
          },
        );

        test(
          'returns Left(UnknownFailure) when getGracePeriod throws',
          () async {
            final prefs = await _buildPrefs();
            final throwingSource = _ThrowingGetterDataSource(
              prefs,
              throwOnGetGracePeriod: true,
            );
            final repository = SettingsRepositoryImpl(throwingSource);

            final result = repository.load();

            expect(result.isLeft(), isTrue);
            result.fold(
              (failure) => expect(failure, isA<UnknownFailure>()),
              (_) => fail('expected Left, got Right'),
            );
          },
        );

        test(
          'returns Left(UnknownFailure) when getAllowMarkAhead throws',
          () async {
            final prefs = await _buildPrefs();
            final throwingSource = _ThrowingGetterDataSource(
              prefs,
              throwOnGetAllowMarkAhead: true,
            );
            final repository = SettingsRepositoryImpl(throwingSource);

            final result = repository.load();

            expect(result.isLeft(), isTrue);
            result.fold(
              (failure) => expect(failure, isA<UnknownFailure>()),
              (_) => fail('expected Left, got Right'),
            );
          },
        );
      },
    );

    // AC-7: each save* method catches Error (not just Exception) and returns
    // Left(UnknownFailure) — proven here with StateError, a subtype of Error.
    //
    // AC-8: the failure is UnknownFailure, NOT CacheFailure, proving the
    // legacy raw-toString / CacheFailure path is gone.
    group(
      'save*() — StateError from setter → Left(UnknownFailure), not CacheFailure (AC-7, AC-8)',
      () {
        test(
          'saveThemeMode returns Left(UnknownFailure) when setter throws StateError',
          () async {
            final prefs = await _buildPrefs();
            final repository = SettingsRepositoryImpl(
              _ThrowingSetterDataSource(prefs, throwOnSetThemeMode: true),
            );

            final result = await repository.saveThemeMode(AppThemeMode.dark);

            expect(result.isLeft(), isTrue);
            result.fold((failure) {
              expect(failure, isA<UnknownFailure>());
              expect(failure, isNot(isA<CacheFailure>()));
            }, (_) => fail('expected Left, got Right'));
          },
        );

        test(
          'saveUseSystemTheme returns Left(UnknownFailure) when setter throws StateError',
          () async {
            final prefs = await _buildPrefs();
            final repository = SettingsRepositoryImpl(
              _ThrowingSetterDataSource(prefs, throwOnSetUseSystemTheme: true),
            );

            final result = await repository.saveUseSystemTheme(false);

            expect(result.isLeft(), isTrue);
            result.fold((failure) {
              expect(failure, isA<UnknownFailure>());
              expect(failure, isNot(isA<CacheFailure>()));
            }, (_) => fail('expected Left, got Right'));
          },
        );

        test(
          'saveUseSystemLanguage returns Left(UnknownFailure) when setter throws StateError',
          () async {
            final prefs = await _buildPrefs();
            final repository = SettingsRepositoryImpl(
              _ThrowingSetterDataSource(
                prefs,
                throwOnSetUseSystemLanguage: true,
              ),
            );

            final result = await repository.saveUseSystemLanguage(false);

            expect(result.isLeft(), isTrue);
            result.fold((failure) {
              expect(failure, isA<UnknownFailure>());
              expect(failure, isNot(isA<CacheFailure>()));
            }, (_) => fail('expected Left, got Right'));
          },
        );

        test(
          'saveManualLanguage returns Left(UnknownFailure) when setter throws StateError',
          () async {
            final prefs = await _buildPrefs();
            final repository = SettingsRepositoryImpl(
              _ThrowingSetterDataSource(prefs, throwOnSetManualLanguage: true),
            );

            final result = await repository.saveManualLanguage(AppLanguage.uk);

            expect(result.isLeft(), isTrue);
            result.fold((failure) {
              expect(failure, isA<UnknownFailure>());
              expect(failure, isNot(isA<CacheFailure>()));
            }, (_) => fail('expected Left, got Right'));
          },
        );
      },
    );
  });
}
