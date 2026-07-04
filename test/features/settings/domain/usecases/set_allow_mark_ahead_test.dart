library;

import 'package:dosly/core/error/failures.dart';
import 'package:dosly/features/settings/domain/repositories/settings_repository.dart';
import 'package:dosly/features/settings/domain/usecases/set_allow_mark_ahead.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(false);
  });

  group('SetAllowMarkAhead', () {
    late _MockSettingsRepository repo;
    late SetAllowMarkAhead useCase;

    setUp(() {
      repo = _MockSettingsRepository();
      useCase = SetAllowMarkAhead(repo);
    });

    test(
      'forwards the input to repo.saveAllowMarkAhead and returns Right(null) '
      'on success',
      () async {
        when(
          () => repo.saveAllowMarkAhead(any()),
        ).thenAnswer((_) async => const Right<Failure, void>(null));

        final result = await useCase(true);

        verify(() => repo.saveAllowMarkAhead(true)).called(1);
        expect(result, const Right<Failure, void>(null));
      },
    );

    test('returns the repository Left when saveAllowMarkAhead fails', () async {
      when(() => repo.saveAllowMarkAhead(any())).thenAnswer(
        (_) async => const Left<Failure, void>(CacheFailure('mock failure')),
      );

      final result = await useCase(true);

      verify(() => repo.saveAllowMarkAhead(true)).called(1);
      expect(result, const Left<Failure, void>(CacheFailure('mock failure')));
    });
  });
}
