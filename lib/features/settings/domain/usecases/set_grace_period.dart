/// Persists the user's [GracePeriod] choice through the
/// [SettingsRepository].
///
/// Pure pass-through: the use case simply forwards the input to
/// `SettingsRepository.saveGracePeriod`. It exists as the indirection layer
/// the [SettingsNotifier] delegates through, per constitution §2.1
/// ("`usecases/` — single-purpose callable classes; one operation per
/// class") and §4.1.1 ("Screens never call repositories directly").
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/settings_repository.dart';
import '../value_objects/grace_period.dart';

/// Use case that persists the user's grace-period choice.
class SetGracePeriod {
  /// Creates a [SetGracePeriod] use case backed by [_repo].
  const SetGracePeriod(this._repo);

  final SettingsRepository _repo;

  /// Persists [grace] as the user's grace-period choice.
  ///
  /// Returns `Right(null)` on success or `Left(Failure)` if the underlying
  /// repository write fails.
  Future<Either<Failure, void>> call(GracePeriod grace) =>
      _repo.saveGracePeriod(grace);
}
