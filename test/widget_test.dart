import 'package:dosly/core/database/database.dart';
import 'package:dosly/core/database/database_provider.dart';
import 'package:dosly/core/error/failures.dart';
import 'package:dosly/features/settings/domain/entities/app_language.dart';
import 'package:dosly/features/settings/domain/entities/app_settings.dart';
import 'package:dosly/features/settings/domain/entities/app_theme_mode.dart';
import 'package:dosly/features/settings/domain/repositories/settings_repository.dart';
import 'package:dosly/features/settings/domain/value_objects/grace_period.dart';
import 'package:dosly/features/settings/domain/value_objects/intake_window.dart';
import 'package:dosly/features/settings/presentation/providers/settings_provider.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
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

  @override
  Future<Either<Never, void>> saveIntakeWindow(IntakeWindow window) async {
    _settings = _settings.copyWith(intakeWindow: window);
    return const Right(null);
  }

  @override
  Future<Either<Never, void>> saveGracePeriod(GracePeriod grace) async {
    _settings = _settings.copyWith(gracePeriod: grace);
    return const Right(null);
  }

  @override
  Future<Either<Never, void>> saveAllowMarkAhead(bool value) async {
    _settings = _settings.copyWith(allowMarkAhead: value);
    return const Right(null);
  }
}

void main() {
  late _FakeSettingsRepository fakeRepo;
  late AppDatabase db;

  setUp(() {
    fakeRepo = _FakeSettingsRepository();
    // DoslyApp's '/' branch is TodayScreen, which watches
    // medicationsListProvider / intakesListProvider — both derived from
    // appDatabaseProvider. Without this override the real (unregistered
    // platform-channel) database never resolves, so TodayScreen stays in
    // AsyncValue.loading and its CircularProgressIndicator's indeterminate
    // animation makes pumpAndSettle() time out. closeStreamsSynchronously:
    // true avoids a "Timer is still pending" teardown failure.
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
    'DoslyApp renders the Today screen with app bar and empty state',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(fakeRepo),
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: const DoslyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Empty DB → the Today screen's empty-state copy (AC-11).
      expect(find.text('Nothing due today'), findsOneWidget);
      // "Today" appears twice (AppBar title + bottom-nav destination label);
      // scope to the AppBar to assert the title specifically.
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Today')),
        findsOneWidget,
      );
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
              appDatabaseProvider.overrideWithValue(db),
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
              appDatabaseProvider.overrideWithValue(db),
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
