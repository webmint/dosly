library;

import 'package:dosly/core/error/failures.dart';
import 'package:dosly/features/settings/domain/entities/app_theme_mode.dart';
import 'package:dosly/features/settings/domain/repositories/settings_repository.dart';
import 'package:dosly/features/settings/domain/usecases/cycle_theme_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(AppThemeMode.light);
  });

  group('CycleThemeMode', () {
    late _MockSettingsRepository repo;
    late CycleThemeMode useCase;

    setUp(() {
      repo = _MockSettingsRepository();
      useCase = CycleThemeMode(repo);
    });

    test(
      'system on cycles to manual light: writes saveThemeMode(light) then '
      'saveUseSystemTheme(false), returns (useSystemTheme: false, '
      'manualThemeMode: light)',
      () async {
        when(() => repo.saveThemeMode(any()))
            .thenAnswer((_) async => const Right<Failure, void>(null));
        when(() => repo.saveUseSystemTheme(any()))
            .thenAnswer((_) async => const Right<Failure, void>(null));

        // currentManualMode is intentionally `dark` to prove this branch
        // ignores it and always lands on `light`.
        final result = await useCase(
          currentUseSystemTheme: true,
          currentManualMode: AppThemeMode.dark,
        );

        verifyInOrder([
          () => repo.saveThemeMode(AppThemeMode.light),
          () => repo.saveUseSystemTheme(false),
        ]);
        expect(
          result,
          const Right<Failure,
              ({bool useSystemTheme, AppThemeMode manualThemeMode})>(
            (useSystemTheme: false, manualThemeMode: AppThemeMode.light),
          ),
        );
        result.fold(
          (_) => fail('expected Right'),
          (record) {
            expect(record.useSystemTheme, false);
            expect(record.manualThemeMode, AppThemeMode.light);
          },
        );
      },
    );

    test(
      'manual light cycles to manual dark: writes saveThemeMode(dark) only, '
      'never saveUseSystemTheme, returns (false, dark)',
      () async {
        when(() => repo.saveThemeMode(any()))
            .thenAnswer((_) async => const Right<Failure, void>(null));

        final result = await useCase(
          currentUseSystemTheme: false,
          currentManualMode: AppThemeMode.light,
        );

        verify(() => repo.saveThemeMode(AppThemeMode.dark)).called(1);
        verifyNever(() => repo.saveUseSystemTheme(any()));
        expect(
          result,
          const Right<Failure,
              ({bool useSystemTheme, AppThemeMode manualThemeMode})>(
            (useSystemTheme: false, manualThemeMode: AppThemeMode.dark),
          ),
        );
        result.fold(
          (_) => fail('expected Right'),
          (record) {
            expect(record.useSystemTheme, false);
            expect(record.manualThemeMode, AppThemeMode.dark);
          },
        );
      },
    );

    test(
      'manual dark cycles to system on: writes saveUseSystemTheme(true) only, '
      'never saveThemeMode, returns (true, dark)',
      () async {
        when(() => repo.saveUseSystemTheme(any()))
            .thenAnswer((_) async => const Right<Failure, void>(null));

        final result = await useCase(
          currentUseSystemTheme: false,
          currentManualMode: AppThemeMode.dark,
        );

        verify(() => repo.saveUseSystemTheme(true)).called(1);
        verifyNever(() => repo.saveThemeMode(any()));
        expect(
          result,
          const Right<Failure,
              ({bool useSystemTheme, AppThemeMode manualThemeMode})>(
            (useSystemTheme: true, manualThemeMode: AppThemeMode.dark),
          ),
        );
        // The third branch must preserve the manual override as `dark`
        // (not collapse to `light`) so a later flip-off has a meaningful
        // value to surface.
        result.fold(
          (_) => fail('expected Right'),
          (record) {
            expect(record.useSystemTheme, true);
            expect(record.manualThemeMode, AppThemeMode.dark);
          },
        );
      },
    );

    test(
      'first write fails (system on branch): returns Left, skips '
      'saveUseSystemTheme',
      () async {
        when(() => repo.saveThemeMode(any())).thenAnswer(
          (_) async => const Left<Failure, void>(CacheFailure('boom')),
        );

        final result = await useCase(
          currentUseSystemTheme: true,
          currentManualMode: AppThemeMode.dark,
        );

        verify(() => repo.saveThemeMode(AppThemeMode.light)).called(1);
        verifyNever(() => repo.saveUseSystemTheme(any()));
        expect(
          result,
          const Left<Failure,
              ({bool useSystemTheme, AppThemeMode manualThemeMode})>(
            CacheFailure('boom'),
          ),
        );
      },
    );
  });
}
