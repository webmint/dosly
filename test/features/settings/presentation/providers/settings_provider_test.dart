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

    test('settingsErrorsProvider emits CacheFailure when setThemeMode fails',
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
      expect(emissions.single, isA<CacheFailure>());

      await sub.cancel();
    });

    test(
        'settingsErrorsProvider emits CacheFailure when setUseSystemTheme fails',
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
      expect(emissions.single, isA<CacheFailure>());

      await sub.cancel();
    });

    test(
        'settingsErrorsProvider emits CacheFailure when setUseSystemLanguage fails',
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
      expect(emissions.single, isA<CacheFailure>());

      await sub.cancel();
    });

    test(
        'settingsErrorsProvider emits CacheFailure when setManualLanguage fails',
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
      expect(emissions.single, isA<CacheFailure>());

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

  group('cycleThemeMode', () {
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
        'cycles system on -> manual light: state.useSystemTheme=false, '
        'state.manualThemeMode=light', () async {
      // Initial state: default = useSystemTheme: true, manualThemeMode: light.
      final initial = container.read(settingsNotifierProvider);
      expect(initial.useSystemTheme, isTrue);
      expect(initial.manualThemeMode, AppThemeMode.light);

      await container
          .read(settingsNotifierProvider.notifier)
          .cycleThemeMode();

      final settings = container.read(settingsNotifierProvider);

      expect(settings.useSystemTheme, isFalse);
      expect(settings.manualThemeMode, AppThemeMode.light);
      // Repo received both writes from the atomic cycle.
      expect(fakeRepo.savedManualThemeMode, AppThemeMode.light);
      expect(fakeRepo.savedUseSystemTheme, isFalse);
    });

    test('cycles manual light -> manual dark: only manual write, system stays off',
        () async {
      // Move to (useSystemTheme: false, manualThemeMode: light) first.
      await container
          .read(settingsNotifierProvider.notifier)
          .setUseSystemTheme(false, currentDeviceMode: AppThemeMode.light);

      await container
          .read(settingsNotifierProvider.notifier)
          .cycleThemeMode();

      final settings = container.read(settingsNotifierProvider);

      expect(settings.useSystemTheme, isFalse);
      expect(settings.manualThemeMode, AppThemeMode.dark);
      expect(fakeRepo.savedManualThemeMode, AppThemeMode.dark);
      expect(fakeRepo.savedUseSystemTheme, isFalse);
    });

    test('failure during cycle is forwarded to settingsErrorsProvider',
        () async {
      // Initial state is system on, so the first inner write is
      // saveThemeMode(light). Failing that write must surface a Failure on
      // the error stream and leave state unchanged.
      fakeRepo.failOnSaveThemeMode = true;

      final emissions = <Failure>[];
      final sub = container
          .read(settingsNotifierProvider.notifier)
          .errors
          .listen(emissions.add);

      await container
          .read(settingsNotifierProvider.notifier)
          .cycleThemeMode();
      await Future<void>.delayed(Duration.zero);

      expect(emissions, hasLength(1));
      expect(emissions.single, isA<CacheFailure>());

      // State must remain at the initial values (no partial application).
      final settings = container.read(settingsNotifierProvider);
      expect(settings.useSystemTheme, isTrue);
      expect(settings.manualThemeMode, AppThemeMode.light);

      await sub.cancel();
    });
  });
}
