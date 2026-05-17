/// Persists the user's manual [AppThemeMode] choice through the
/// [SettingsRepository].
///
/// Pure pass-through: the use case simply forwards the input to
/// `SettingsRepository.saveThemeMode`. It exists as the indirection layer
/// the [SettingsNotifier] delegates through, per constitution §2.1
/// ("`usecases/` — single-purpose callable classes; one operation per
/// class") and §4.1.1 ("Screens never call repositories directly").
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_theme_mode.dart';
import '../repositories/settings_repository.dart';

/// Use case that persists the user's manual theme-mode override.
class SetThemeMode {
  /// Creates a [SetThemeMode] use case backed by [_repo].
  const SetThemeMode(this._repo);

  final SettingsRepository _repo;

  /// Persists [mode] as the manual theme-mode override.
  ///
  /// Returns `Right(null)` on success or `Left(Failure)` if the underlying
  /// repository write fails.
  Future<Either<Failure, void>> call(AppThemeMode mode) =>
      _repo.saveThemeMode(mode);
}
