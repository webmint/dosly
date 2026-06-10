library;

import 'package:dosly/core/error/failures.dart';
import 'package:dosly/features/settings/domain/entities/app_theme_mode.dart';
import 'package:dosly/features/settings/domain/repositories/settings_repository.dart';
import 'package:dosly/features/settings/domain/usecases/set_use_system_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(AppThemeMode.light);
  });

  group('SetUseSystemTheme', () {
    late _MockSettingsRepository repo;
    late SetUseSystemTheme useCase;

    setUp(() {
      repo = _MockSettingsRepository();
      useCase = SetUseSystemTheme(repo);
    });

    test('value=false, repo healthy: writes saveThemeMode then '
        'saveUseSystemTheme in that order, returns Right(null)', () async {
      when(
        () => repo.saveThemeMode(any()),
      ).thenAnswer((_) async => const Right<Failure, void>(null));
      when(
        () => repo.saveUseSystemTheme(any()),
      ).thenAnswer((_) async => const Right<Failure, void>(null));

      final result = await useCase(
        value: false,
        currentDeviceMode: AppThemeMode.dark,
      );

      verifyInOrder([
        () => repo.saveThemeMode(AppThemeMode.dark),
        () => repo.saveUseSystemTheme(false),
      ]);
      expect(result, const Right<Failure, void>(null));
    });

    test('value=true: writes saveUseSystemTheme(true) only, never touches '
        'saveThemeMode', () async {
      when(
        () => repo.saveUseSystemTheme(any()),
      ).thenAnswer((_) async => const Right<Failure, void>(null));

      final result = await useCase(
        value: true,
        currentDeviceMode: AppThemeMode.dark,
      );

      verify(() => repo.saveUseSystemTheme(true)).called(1);
      verifyNever(() => repo.saveThemeMode(any()));
      expect(result, const Right<Failure, void>(null));
    });

    test('value=false, saveThemeMode fails: returns Left and skips '
        'saveUseSystemTheme', () async {
      when(() => repo.saveThemeMode(any())).thenAnswer(
        (_) async => const Left<Failure, void>(CacheFailure('boom')),
      );

      final result = await useCase(
        value: false,
        currentDeviceMode: AppThemeMode.dark,
      );

      expect(result, const Left<Failure, void>(CacheFailure('boom')));
      verify(() => repo.saveThemeMode(AppThemeMode.dark)).called(1);
      verifyNever(() => repo.saveUseSystemTheme(any()));
    });

    test('value=false, saveUseSystemTheme fails after saveThemeMode succeeds: '
        'returns the saveUseSystemTheme Left', () async {
      when(
        () => repo.saveThemeMode(any()),
      ).thenAnswer((_) async => const Right<Failure, void>(null));
      when(() => repo.saveUseSystemTheme(any())).thenAnswer(
        (_) async => const Left<Failure, void>(CacheFailure('toggle failed')),
      );

      final result = await useCase(
        value: false,
        currentDeviceMode: AppThemeMode.dark,
      );

      expect(result, const Left<Failure, void>(CacheFailure('toggle failed')));
      verify(() => repo.saveThemeMode(AppThemeMode.dark)).called(1);
      verify(() => repo.saveUseSystemTheme(false)).called(1);
    });
  });
}
