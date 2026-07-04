library;

import 'package:dosly/core/error/failures.dart';
import 'package:dosly/features/settings/domain/repositories/settings_repository.dart';
import 'package:dosly/features/settings/domain/usecases/set_grace_period.dart';
import 'package:dosly/features/settings/domain/value_objects/grace_period.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(GracePeriod.defaultValue);
  });

  group('SetGracePeriod', () {
    late _MockSettingsRepository repo;
    late SetGracePeriod useCase;

    setUp(() {
      repo = _MockSettingsRepository();
      useCase = SetGracePeriod(repo);
    });

    test('forwards the input to repo.saveGracePeriod and returns Right(null) '
        'on success', () async {
      when(
        () => repo.saveGracePeriod(any()),
      ).thenAnswer((_) async => const Right<Failure, void>(null));

      final grace = GracePeriod(10);
      final result = await useCase(grace);

      verify(() => repo.saveGracePeriod(grace)).called(1);
      expect(result, const Right<Failure, void>(null));
    });

    test('returns the repository Left when saveGracePeriod fails', () async {
      when(() => repo.saveGracePeriod(any())).thenAnswer(
        (_) async => const Left<Failure, void>(CacheFailure('mock failure')),
      );

      final grace = GracePeriod(10);
      final result = await useCase(grace);

      verify(() => repo.saveGracePeriod(grace)).called(1);
      expect(result, const Left<Failure, void>(CacheFailure('mock failure')));
    });
  });
}
