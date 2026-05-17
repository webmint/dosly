/// Persists the user's manual [AppLanguage] choice through the
/// [SettingsRepository].
///
/// Pure pass-through: the use case simply forwards the input to
/// `SettingsRepository.saveManualLanguage`. It exists as the indirection
/// layer the [SettingsNotifier] delegates through, per constitution §2.1
/// ("`usecases/` — single-purpose callable classes; one operation per
/// class") and §4.1.1 ("Screens never call repositories directly").
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_language.dart';
import '../repositories/settings_repository.dart';

/// Use case that persists the user's manual language override.
class SetManualLanguage {
  /// Creates a [SetManualLanguage] use case backed by [_repo].
  const SetManualLanguage(this._repo);

  final SettingsRepository _repo;

  /// Persists [language] as the manual language override.
  ///
  /// Returns `Right(null)` on success or `Left(Failure)` if the underlying
  /// repository write fails.
  Future<Either<Failure, void>> call(AppLanguage language) =>
      _repo.saveManualLanguage(language);
}
