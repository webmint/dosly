library;

import 'package:dosly/core/error/failures.dart';
import 'package:dosly/features/settings/domain/entities/app_language.dart';
import 'package:dosly/features/settings/domain/repositories/settings_repository.dart';
import 'package:dosly/features/settings/domain/usecases/set_manual_language.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(AppLanguage.en);
  });

  group('SetManualLanguage', () {
    late _MockSettingsRepository repo;
    late SetManualLanguage useCase;

    setUp(() {
      repo = _MockSettingsRepository();
      useCase = SetManualLanguage(repo);
    });

    test(
      'forwards the input to repo.saveManualLanguage and returns Right(null) '
      'on success',
      () async {
        when(() => repo.saveManualLanguage(any()))
            .thenAnswer((_) async => const Right<Failure, void>(null));

        final result = await useCase(AppLanguage.uk);

        verify(() => repo.saveManualLanguage(AppLanguage.uk)).called(1);
        expect(result, const Right<Failure, void>(null));
      },
    );

    test(
      'returns the repository Left when saveManualLanguage fails',
      () async {
        when(() => repo.saveManualLanguage(any())).thenAnswer(
          (_) async => const Left<Failure, void>(CacheFailure('mock failure')),
        );

        final result = await useCase(AppLanguage.uk);

        verify(() => repo.saveManualLanguage(AppLanguage.uk)).called(1);
        expect(result, const Left<Failure, void>(CacheFailure('mock failure')));
      },
    );
  });
}
