/// Persists the user's [IntakeWindow] choice through the
/// [SettingsRepository].
///
/// Pure pass-through: the use case simply forwards the input to
/// `SettingsRepository.saveIntakeWindow`. It exists as the indirection layer
/// the [SettingsNotifier] delegates through, per constitution §2.1
/// ("`usecases/` — single-purpose callable classes; one operation per
/// class") and §4.1.1 ("Screens never call repositories directly").
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/settings_repository.dart';
import '../value_objects/intake_window.dart';

/// Use case that persists the user's intake-window choice.
class SetIntakeWindow {
  /// Creates a [SetIntakeWindow] use case backed by [_repo].
  const SetIntakeWindow(this._repo);

  final SettingsRepository _repo;

  /// Persists [window] as the user's intake-window choice.
  ///
  /// Returns `Right(null)` on success or `Left(Failure)` if the underlying
  /// repository write fails.
  Future<Either<Failure, void>> call(IntakeWindow window) =>
      _repo.saveIntakeWindow(window);
}
