library;

import 'package:dosly/core/error/failures.dart';
import 'package:dosly/features/settings/domain/entities/app_language.dart';
import 'package:dosly/features/settings/domain/repositories/settings_repository.dart';
import 'package:dosly/features/settings/domain/usecases/set_use_system_language.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(AppLanguage.en);
  });

  group('SetUseSystemLanguage', () {
    late _MockSettingsRepository repo;
    late SetUseSystemLanguage useCase;

    setUp(() {
      repo = _MockSettingsRepository();
      useCase = SetUseSystemLanguage(repo);
    });

    test(
      'value=false, repo healthy: writes saveManualLanguage then '
      'saveUseSystemLanguage in that order, returns Right(null)',
      () async {
        when(() => repo.saveManualLanguage(any()))
            .thenAnswer((_) async => const Right<Failure, void>(null));
        when(() => repo.saveUseSystemLanguage(any()))
            .thenAnswer((_) async => const Right<Failure, void>(null));

        final result = await useCase(
          value: false,
          currentDeviceLanguage: AppLanguage.uk,
        );

        verifyInOrder([
          () => repo.saveManualLanguage(AppLanguage.uk),
          () => repo.saveUseSystemLanguage(false),
        ]);
        expect(result, const Right<Failure, void>(null));
      },
    );

    test(
      'value=true: writes saveUseSystemLanguage(true) only, never touches '
      'saveManualLanguage',
      () async {
        when(() => repo.saveUseSystemLanguage(any()))
            .thenAnswer((_) async => const Right<Failure, void>(null));

        final result = await useCase(
          value: true,
          currentDeviceLanguage: AppLanguage.uk,
        );

        verify(() => repo.saveUseSystemLanguage(true)).called(1);
        verifyNever(() => repo.saveManualLanguage(any()));
        expect(result, const Right<Failure, void>(null));
      },
    );

    test(
      'value=false, saveManualLanguage fails: returns Left and skips '
      'saveUseSystemLanguage',
      () async {
        when(() => repo.saveManualLanguage(any())).thenAnswer(
          (_) async => const Left<Failure, void>(CacheFailure('boom')),
        );

        final result = await useCase(
          value: false,
          currentDeviceLanguage: AppLanguage.uk,
        );

        expect(result, const Left<Failure, void>(CacheFailure('boom')));
        verify(() => repo.saveManualLanguage(AppLanguage.uk)).called(1);
        verifyNever(() => repo.saveUseSystemLanguage(any()));
      },
    );

    test(
      'value=false, saveUseSystemLanguage fails after saveManualLanguage '
      'succeeds: returns the saveUseSystemLanguage Left',
      () async {
        when(() => repo.saveManualLanguage(any()))
            .thenAnswer((_) async => const Right<Failure, void>(null));
        when(() => repo.saveUseSystemLanguage(any())).thenAnswer(
          (_) async =>
              const Left<Failure, void>(CacheFailure('toggle failed')),
        );

        final result = await useCase(
          value: false,
          currentDeviceLanguage: AppLanguage.uk,
        );

        expect(
          result,
          const Left<Failure, void>(CacheFailure('toggle failed')),
        );
        verify(() => repo.saveManualLanguage(AppLanguage.uk)).called(1);
        verify(() => repo.saveUseSystemLanguage(false)).called(1);
      },
    );
  });
}
