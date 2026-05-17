/// Persists the "follow device theme" toggle through the
/// [SettingsRepository], pre-filling the manual theme override atomically
/// when the toggle is flipped from ON to OFF.
///
/// Owns the cross-cutting "switch-to-manual must pre-fill from device" rule
/// for the theme axis (spec 016, AC-4 / AC-5). Lifting the rule out of the
/// `theme_selector` widget into this use case keeps the
/// `presentation/widgets/` layer free of business logic per constitution
/// §2.1 ("`usecases/` — single-purpose callable classes; one operation per
/// class") and §4.1.1 ("Screens never call repositories directly").
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_theme_mode.dart';
import '../repositories/settings_repository.dart';

/// Use case that toggles "follow device theme" with atomic pre-fill.
class SetUseSystemTheme {
  /// Creates a [SetUseSystemTheme] use case backed by [_repo].
  const SetUseSystemTheme(this._repo);

  final SettingsRepository _repo;

  /// Toggles the "follow device theme" preference.
  ///
  /// Atomic semantics:
  /// - When [value] is `false` (toggling OFF), the use case first persists
  ///   [currentDeviceMode] as the manual theme override via
  ///   `SettingsRepository.saveThemeMode`, then persists
  ///   `useSystemTheme=false` via `SettingsRepository.saveUseSystemTheme`.
  ///   If the manual write returns `Left`, the toggle write is skipped and
  ///   the `Left` is propagated immediately — this prevents the half-applied
  ///   state where `useSystemTheme=false` but `manualThemeMode` is stale.
  /// - When [value] is `true` (toggling ON), only the toggle write is
  ///   issued; [currentDeviceMode] is unused (the manual override remains
  ///   untouched so it can be restored if the user later flips back).
  ///
  /// Returns `Right(null)` on success or `Left(Failure)` if any underlying
  /// repository write fails.
  Future<Either<Failure, void>> call({
    required bool value,
    required AppThemeMode currentDeviceMode,
  }) async {
    if (!value) {
      final manualResult = await _repo.saveThemeMode(currentDeviceMode);
      if (manualResult.isLeft()) {
        return manualResult;
      }
    }
    return _repo.saveUseSystemTheme(value);
  }
}
