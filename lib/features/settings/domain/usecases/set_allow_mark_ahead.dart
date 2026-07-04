/// Persists whether the user may mark an intake `taken` before its
/// scheduled time, through the [SettingsRepository].
///
/// Pure pass-through: the use case simply forwards the input to
/// `SettingsRepository.saveAllowMarkAhead`. It exists as the indirection layer
/// the [SettingsNotifier] delegates through, per constitution §2.1
/// ("`usecases/` — single-purpose callable classes; one operation per
/// class") and §4.1.1 ("Screens never call repositories directly").
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/settings_repository.dart';

/// Use case that persists the user's allow-mark-ahead choice.
class SetAllowMarkAhead {
  /// Creates a [SetAllowMarkAhead] use case backed by [_repo].
  const SetAllowMarkAhead(this._repo);

  final SettingsRepository _repo;

  /// Persists [value] as whether the user may mark an intake ahead of time.
  ///
  /// Returns `Right(null)` on success or `Left(Failure)` if the underlying
  /// repository write fails.
  Future<Either<Failure, void>> call(bool value) =>
      _repo.saveAllowMarkAhead(value);
}
