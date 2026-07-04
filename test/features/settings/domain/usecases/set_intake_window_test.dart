library;

import 'package:dosly/core/error/failures.dart';
import 'package:dosly/features/settings/domain/repositories/settings_repository.dart';
import 'package:dosly/features/settings/domain/usecases/set_intake_window.dart';
import 'package:dosly/features/settings/domain/value_objects/intake_window.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(IntakeWindow.defaultValue);
  });

  group('SetIntakeWindow', () {
    late _MockSettingsRepository repo;
    late SetIntakeWindow useCase;

    setUp(() {
      repo = _MockSettingsRepository();
      useCase = SetIntakeWindow(repo);
    });

    test('forwards the input to repo.saveIntakeWindow and returns Right(null) '
        'on success', () async {
      when(
        () => repo.saveIntakeWindow(any()),
      ).thenAnswer((_) async => const Right<Failure, void>(null));

      final window = IntakeWindow(90);
      final result = await useCase(window);

      verify(() => repo.saveIntakeWindow(window)).called(1);
      expect(result, const Right<Failure, void>(null));
    });

    test('returns the repository Left when saveIntakeWindow fails', () async {
      when(() => repo.saveIntakeWindow(any())).thenAnswer(
        (_) async => const Left<Failure, void>(CacheFailure('mock failure')),
      );

      final window = IntakeWindow(90);
      final result = await useCase(window);

      verify(() => repo.saveIntakeWindow(window)).called(1);
      expect(result, const Left<Failure, void>(CacheFailure('mock failure')));
    });
  });
}
