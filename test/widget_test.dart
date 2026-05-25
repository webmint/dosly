import 'package:dosly/core/error/failures.dart';
import 'package:dosly/features/settings/domain/entities/app_language.dart';
import 'package:dosly/features/settings/domain/entities/app_settings.dart';
import 'package:dosly/features/settings/domain/entities/app_theme_mode.dart';
import 'package:dosly/features/settings/domain/repositories/settings_repository.dart';
import 'package:dosly/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:dosly/app.dart';

/// Minimal fake that satisfies [SettingsRepository] for widget tests.
///
/// Returns defaults from [load] and accepts an optional [initial] to
/// pre-seed state.
class _FakeSettingsRepository implements SettingsRepository {
  AppSettings _settings;

  _FakeSettingsRepository({AppSettings? initial})
      : _settings = initial ?? const AppSettings();

  @override
  Either<Failure, AppSettings> load() => Right(_settings);

  @override
  Future<Either<Never, void>> saveThemeMode(AppThemeMode mode) async {
    _settings = _settings.copyWith(manualThemeMode: mode);
    return const Right(null);
  }

  @override
  Future<Either<Never, void>> saveUseSystemTheme(bool value) async {
    _settings = _settings.copyWith(useSystemTheme: value);
    return const Right(null);
  }

  @override
  Future<Either<Never, void>> saveUseSystemLanguage(bool value) async {
    _settings = _settings.copyWith(useSystemLanguage: value);
    return const Right(null);
  }

  @override
  Future<Either<Never, void>> saveManualLanguage(AppLanguage language) async {
    _settings = _settings.copyWith(manualLanguage: language);
    return const Right(null);
  }
}

void main() {
  late _FakeSettingsRepository fakeRepo;

  setUp(() {
    fakeRepo = _FakeSettingsRepository();
  });


  testWidgets(
    'DoslyApp renders the home screen with app bar and Hello World',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const DoslyApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello World'), findsOneWidget);
      expect(find.text('Dosly'), findsOneWidget);
    },
  );

  group('MaterialApp.locale reactivity', () {
    testWidgets(
      'is null by default (useSystemLanguage=true → resolution callback drives locale)',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: const DoslyApp(),
          ),
        );
        await tester.pumpAndSettle();

        // DoslyApp uses MaterialApp.router — find it by type.
        final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(app.locale, isNull);
      },
    );

    testWidgets(
      'becomes Locale("de") when pre-seeded with useSystemLanguage=false and manualLanguage=de',
      (tester) async {
        final preSeededRepo = _FakeSettingsRepository(
          initial: const AppSettings(
            useSystemLanguage: false,
            manualLanguage: AppLanguage.de,
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsRepositoryProvider.overrideWithValue(preSeededRepo),
            ],
            child: const DoslyApp(),
          ),
        );
        await tester.pumpAndSettle();

        final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(app.locale, const Locale('de'));
      },
    );
  });
}
