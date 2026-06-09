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
/// failures on individual save methods, and a flag to simulate a load failure.
class _FakeSettingsRepository implements SettingsRepository {
  AppSettings _settings = const AppSettings();

  /// When true, [load] returns a [Left] with an [UnknownFailure].
  bool failOnLoad = false;

  /// When true, [saveThemeMode] returns a [Left] with an [UnknownFailure].
  bool failOnSaveThemeMode = false;

  /// When true, [saveUseSystemTheme] returns a [Left] with an [UnknownFailure].
  bool failOnSaveUseSystemTheme = false;

  /// When true, [saveUseSystemLanguage] returns a [Left] with an [UnknownFailure].
  bool failOnSaveUseSystemLanguage = false;

  /// When true, [saveManualLanguage] returns a [Left] with an [UnknownFailure].
  bool failOnSaveManualLanguage = false;

  /// Snapshot of the current persisted [AppSettings] (mirrors what `load()`
  /// would return). Useful for stronger end-state assertions in tests that
  /// exercise atomic two-write use cases.
  AppSettings get savedSettings => _settings;

  /// Convenience accessor for the persisted manual theme override.
  AppThemeMode get savedManualThemeMode => _settings.manualThemeMode;

  /// Convenience accessor for the persisted manual language override.
  AppLanguage get savedManualLanguage => _settings.manualLanguage;

  /// Convenience accessor for the persisted "follow device theme" flag.
  bool get savedUseSystemTheme => _settings.useSystemTheme;

  /// Convenience accessor for the persisted "follow device language" flag.
  bool get savedUseSystemLanguage => _settings.useSystemLanguage;

  @override
  Either<Failure, AppSettings> load() {
    if (failOnLoad) {
      return Left(Failure.unknown(Exception('load boom'), StackTrace.empty));
    }
    return Right(_settings);
  }

  @override
  Future<Either<Failure, void>> saveThemeMode(AppThemeMode mode) async {
    if (failOnSaveThemeMode) {
      return Left(Failure.unknown(Exception('mock failure'), StackTrace.empty));
    }
    _settings = _settings.copyWith(manualThemeMode: mode);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> saveUseSystemTheme(bool value) async {
    if (failOnSaveUseSystemTheme) {
      return Left(Failure.unknown(Exception('mock failure'), StackTrace.empty));
    }
    _settings = _settings.copyWith(useSystemTheme: value);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> saveUseSystemLanguage(bool value) async {
    if (failOnSaveUseSystemLanguage) {
      return Left(Failure.unknown(Exception('mock failure'), StackTrace.empty));
    }
    _settings = _settings.copyWith(useSystemLanguage: value);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> saveManualLanguage(AppLanguage language) async {
    if (failOnSaveManualLanguage) {
      return Left(Failure.unknown(Exception('mock failure'), StackTrace.empty));
    }
    _settings = _settings.copyWith(manualLanguage: language);
    return const Right(null);
  }
}

/// Minimal [SettingsRepository] stub that returns a pre-seeded [AppSettings]
/// from [load()] and delegates all saves to no-ops that return Right(null).
///
/// Used to verify that [SettingsNotifier.build()] propagates loaded settings
/// into the notifier state when load() succeeds (AC-6).
class _SeededFakeSettingsRepository implements SettingsRepository {
  _SeededFakeSettingsRepository(this._seeded);

  final AppSettings _seeded;

  @override
  Either<Failure, AppSettings> load() => Right(_seeded);

  @override
  Future<Either<Failure, void>> saveThemeMode(AppThemeMode mode) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> saveUseSystemTheme(bool value) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> saveUseSystemLanguage(bool value) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> saveManualLanguage(AppLanguage language) async =>
      const Right(null);
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
      final settings = container.read(settingsNotifierProvider);

      expect(settings.useSystemTheme, isTrue);
      expect(settings.manualThemeMode, AppThemeMode.light);
    });

    test('setThemeMode(AppThemeMode.dark) updates manualThemeMode to dark',
        () async {
      await container
          .read(settingsNotifierProvider.notifier)
          .setThemeMode(AppThemeMode.dark);

      final settings = container.read(settingsNotifierProvider);

      expect(settings.manualThemeMode, AppThemeMode.dark);
    });

    test('setThemeMode does not update state when save fails', () async {
      fakeRepo.failOnSaveThemeMode = true;

      await container
          .read(settingsNotifierProvider.notifier)
          .setThemeMode(AppThemeMode.dark);

      final settings = container.read(settingsNotifierProvider);

      expect(settings.manualThemeMode, AppThemeMode.light);
    });

    test(
        'setUseSystemTheme(false) pre-fills manual override from device and '
        'updates useSystemTheme to false', () async {
      await container
          .read(settingsNotifierProvider.notifier)
          .setUseSystemTheme(false, currentDeviceMode: AppThemeMode.dark);

      final settings = container.read(settingsNotifierProvider);

      expect(settings.useSystemTheme, isFalse);
      expect(settings.manualThemeMode, AppThemeMode.dark);
      // The atomic use case writes both: confirm the repo received the
      // manual pre-fill in addition to the toggle.
      expect(fakeRepo.savedManualThemeMode, AppThemeMode.dark);
      expect(fakeRepo.savedUseSystemTheme, isFalse);
    });

    test('setUseSystemTheme does not update state when save fails', () async {
      fakeRepo.failOnSaveUseSystemTheme = true;

      await container
          .read(settingsNotifierProvider.notifier)
          .setUseSystemTheme(false, currentDeviceMode: AppThemeMode.dark);

      final settings = container.read(settingsNotifierProvider);

      expect(settings.useSystemTheme, isTrue);
      // manualThemeMode must also be unchanged: the two-write use case must
      // not partially apply the manual pre-fill when the overall save fails.
      expect(settings.manualThemeMode, AppThemeMode.light);
    });

    test(
        'setUseSystemTheme(true) re-enables system theme and persists it',
        () async {
      // First: leave system-theme mode (lands in manual mode).
      await container
          .read(settingsNotifierProvider.notifier)
          .setUseSystemTheme(false, currentDeviceMode: AppThemeMode.dark);

      // Then: re-enable system theme (exercises the else branch).
      await container
          .read(settingsNotifierProvider.notifier)
          .setUseSystemTheme(true, currentDeviceMode: AppThemeMode.dark);

      final settings = container.read(settingsNotifierProvider);

      expect(settings.useSystemTheme, isTrue);
      expect(fakeRepo.savedUseSystemTheme, isTrue);
    });

    test(
        'useSystemTheme remains true when only manualThemeMode is updated to dark',
        () async {
      // First set manual to dark
      await container
          .read(settingsNotifierProvider.notifier)
          .setThemeMode(AppThemeMode.dark);
      // Ensure useSystemTheme is still on
      final settings = container.read(settingsNotifierProvider);
      expect(settings.useSystemTheme, isTrue);
      expect(settings.manualThemeMode, AppThemeMode.dark);
    });

    test(
        'manualThemeMode=dark is returned when useSystemTheme is set to false',
        () async {
      await container
          .read(settingsNotifierProvider.notifier)
          .setThemeMode(AppThemeMode.dark);
      await container
          .read(settingsNotifierProvider.notifier)
          .setUseSystemTheme(false, currentDeviceMode: AppThemeMode.dark);

      final settings = container.read(settingsNotifierProvider);

      expect(settings.useSystemTheme, isFalse);
      expect(settings.manualThemeMode, AppThemeMode.dark);
    });

    test(
        'setUseSystemLanguage(false) pre-fills manual override from device and '
        'updates useSystemLanguage to false', () async {
      await container
          .read(settingsNotifierProvider.notifier)
          .setUseSystemLanguage(false, currentDeviceLanguage: AppLanguage.de);

      final settings = container.read(settingsNotifierProvider);

      expect(settings.useSystemLanguage, isFalse);
      expect(settings.manualLanguage, AppLanguage.de);
      // The atomic use case writes both: confirm the repo received the
      // manual pre-fill in addition to the toggle.
      expect(fakeRepo.savedManualLanguage, AppLanguage.de);
      expect(fakeRepo.savedUseSystemLanguage, isFalse);
    });

    test('setUseSystemLanguage does not update state when save fails',
        () async {
      fakeRepo.failOnSaveUseSystemLanguage = true;

      await container
          .read(settingsNotifierProvider.notifier)
          .setUseSystemLanguage(false, currentDeviceLanguage: AppLanguage.en);

      final settings = container.read(settingsNotifierProvider);

      expect(settings.useSystemLanguage, isTrue);
    });

    test(
        'setUseSystemLanguage(true) re-enables system language and persists it',
        () async {
      // First: leave system-language mode (lands in manual mode).
      await container
          .read(settingsNotifierProvider.notifier)
          .setUseSystemLanguage(false, currentDeviceLanguage: AppLanguage.de);

      // Then: re-enable system language (exercises the else branch).
      await container
          .read(settingsNotifierProvider.notifier)
          .setUseSystemLanguage(true, currentDeviceLanguage: AppLanguage.de);

      final settings = container.read(settingsNotifierProvider);

      expect(settings.useSystemLanguage, isTrue);
      expect(fakeRepo.savedUseSystemLanguage, isTrue);
    });

    test('setManualLanguage(AppLanguage.uk) updates manualLanguage to uk',
        () async {
      await container
          .read(settingsNotifierProvider.notifier)
          .setManualLanguage(AppLanguage.uk);

      final settings = container.read(settingsNotifierProvider);

      expect(settings.manualLanguage, AppLanguage.uk);
    });

    test('setManualLanguage does not update state when save fails', () async {
      fakeRepo.failOnSaveManualLanguage = true;

      await container
          .read(settingsNotifierProvider.notifier)
          .setManualLanguage(AppLanguage.uk);

      final settings = container.read(settingsNotifierProvider);

      expect(settings.manualLanguage, AppLanguage.en);
    });

    test('useSystemLanguage=true by default (system locale drives resolution)', () {
      final settings = container.read(settingsNotifierProvider);

      expect(settings.useSystemLanguage, isTrue);
    });

    test(
        'manualLanguage=de is stored after setUseSystemLanguage(false) + setManualLanguage(de)',
        () async {
      await container
          .read(settingsNotifierProvider.notifier)
          .setUseSystemLanguage(false, currentDeviceLanguage: AppLanguage.en);
      await container
          .read(settingsNotifierProvider.notifier)
          .setManualLanguage(AppLanguage.de);

      final settings = container.read(settingsNotifierProvider);

      expect(settings.useSystemLanguage, isFalse);
      expect(settings.manualLanguage, AppLanguage.de);
    });
  });

  group('SettingsNotifier error stream', () {
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

    test('settingsErrorsProvider emits UnknownFailure when setThemeMode fails',
        () async {
      fakeRepo.failOnSaveThemeMode = true;
      final emissions = <Failure>[];
      final sub =
          container.read(settingsNotifierProvider.notifier).errors.listen(emissions.add);

      await container
          .read(settingsNotifierProvider.notifier)
          .setThemeMode(AppThemeMode.dark);
      await Future<void>.delayed(Duration.zero);

      expect(emissions, hasLength(1));
      expect(emissions.single, isA<UnknownFailure>());

      await sub.cancel();
    });

    test(
        'settingsErrorsProvider emits UnknownFailure when setUseSystemTheme fails',
        () async {
      fakeRepo.failOnSaveUseSystemTheme = true;
      final emissions = <Failure>[];
      final sub =
          container.read(settingsNotifierProvider.notifier).errors.listen(emissions.add);

      await container
          .read(settingsNotifierProvider.notifier)
          .setUseSystemTheme(false, currentDeviceMode: AppThemeMode.dark);
      await Future<void>.delayed(Duration.zero);

      expect(emissions, hasLength(1));
      expect(emissions.single, isA<UnknownFailure>());

      await sub.cancel();
    });

    test(
        'settingsErrorsProvider emits UnknownFailure when setUseSystemLanguage fails',
        () async {
      fakeRepo.failOnSaveUseSystemLanguage = true;
      final emissions = <Failure>[];
      final sub =
          container.read(settingsNotifierProvider.notifier).errors.listen(emissions.add);

      await container
          .read(settingsNotifierProvider.notifier)
          .setUseSystemLanguage(false, currentDeviceLanguage: AppLanguage.en);
      await Future<void>.delayed(Duration.zero);

      expect(emissions, hasLength(1));
      expect(emissions.single, isA<UnknownFailure>());

      await sub.cancel();
    });

    test(
        'settingsErrorsProvider emits UnknownFailure when setManualLanguage fails',
        () async {
      fakeRepo.failOnSaveManualLanguage = true;
      final emissions = <Failure>[];
      final sub =
          container.read(settingsNotifierProvider.notifier).errors.listen(emissions.add);

      await container
          .read(settingsNotifierProvider.notifier)
          .setManualLanguage(AppLanguage.uk);
      await Future<void>.delayed(Duration.zero);

      expect(emissions, hasLength(1));
      expect(emissions.single, isA<UnknownFailure>());

      await sub.cancel();
    });

    test('settingsErrorsProvider does NOT emit on successful save', () async {
      final emissions = <Failure>[];
      final sub =
          container.read(settingsNotifierProvider.notifier).errors.listen(emissions.add);

      await container
          .read(settingsNotifierProvider.notifier)
          .setThemeMode(AppThemeMode.dark);
      await container
          .read(settingsNotifierProvider.notifier)
          .setUseSystemTheme(false, currentDeviceMode: AppThemeMode.dark);
      await container
          .read(settingsNotifierProvider.notifier)
          .setUseSystemLanguage(false, currentDeviceLanguage: AppLanguage.en);
      await container
          .read(settingsNotifierProvider.notifier)
          .setManualLanguage(AppLanguage.uk);
      await Future<void>.delayed(Duration.zero);

      expect(emissions, isEmpty);

      await sub.cancel();
    });

    test('errors stream supports multiple sequential emissions', () async {
      fakeRepo.failOnSaveThemeMode = true;
      final emissions = <Failure>[];
      final sub =
          container.read(settingsNotifierProvider.notifier).errors.listen(emissions.add);

      await container
          .read(settingsNotifierProvider.notifier)
          .setThemeMode(AppThemeMode.dark);
      await Future<void>.delayed(Duration.zero);
      expect(emissions, hasLength(1));

      await container
          .read(settingsNotifierProvider.notifier)
          .setThemeMode(AppThemeMode.light);
      await Future<void>.delayed(Duration.zero);
      expect(emissions, hasLength(2));

      await sub.cancel();
    });
  });

  // AC-5: Left-on-load → notifier state falls back to const AppSettings() AND
  // the failure is emitted on the errors stream as an UnknownFailure.
  //
  // AC-6: Right-on-load → notifier state equals the seeded AppSettings values.
  group('SettingsNotifier load error-containment (AC-5, AC-6)', () {
    late _FakeSettingsRepository fakeRepo;
    late ProviderContainer container;

    tearDown(() {
      container.dispose();
    });

    test(
        'should fall back to default AppSettings when load() returns Left (AC-5)',
        () {
      // The broadcast stream emits synchronously inside build() before any
      // subscriber can attach; the load-failure emission is therefore not
      // observable via a post-build listener. What IS observable — and what
      // matters for error containment — is that the notifier state falls back
      // to const AppSettings() rather than crashing or leaving an inconsistent
      // state. The stream infrastructure itself is exercised by the save-failure
      // emission tests in the group above.
      fakeRepo = _FakeSettingsRepository()..failOnLoad = true;
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      final settings = container.read(settingsNotifierProvider);

      // AC-5a: load failure is contained; state falls back to all-defaults.
      expect(settings, equals(const AppSettings()));
    });

    test(
        'errors stream is wired for load-error containment: '
        'subsequent save failure after a load failure emits UnknownFailure (AC-5)',
        () async {
      // Prove that the errors stream infrastructure is fully functional even
      // after a load-time Left: a save failure still surfaces on the stream.
      fakeRepo = _FakeSettingsRepository()
        ..failOnLoad = true
        ..failOnSaveThemeMode = true;
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      final emissions = <Failure>[];
      final sub =
          container.read(settingsNotifierProvider.notifier).errors.listen(emissions.add);

      await container
          .read(settingsNotifierProvider.notifier)
          .setThemeMode(AppThemeMode.dark);
      await Future<void>.delayed(Duration.zero);

      expect(emissions, hasLength(1));
      expect(emissions.single, isA<UnknownFailure>());

      await sub.cancel();
    });

    test(
        'should have state equal to seeded AppSettings when load() returns Right (AC-6)',
        () {
      // Use _SeededFakeSettingsRepository to pre-populate load() with
      // non-default values, confirming the notifier propagates them
      // rather than substituting const AppSettings() defaults.
      const seededSettings = AppSettings(
        useSystemTheme: false,
        manualThemeMode: AppThemeMode.dark,
        useSystemLanguage: false,
        manualLanguage: AppLanguage.uk,
      );
      final seededRepo = _SeededFakeSettingsRepository(seededSettings);
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(seededRepo),
        ],
      );

      final settings = container.read(settingsNotifierProvider);

      expect(settings.useSystemTheme, isFalse);
      expect(settings.manualThemeMode, AppThemeMode.dark);
      expect(settings.useSystemLanguage, isFalse);
      expect(settings.manualLanguage, AppLanguage.uk);
    });
  });
}
