/// Persists the "follow device language" toggle through the
/// [SettingsRepository], pre-filling the manual language override
/// atomically when the toggle is flipped from ON to OFF.
///
/// Owns the cross-cutting "switch-to-manual must pre-fill from device" rule
/// for the language axis (spec 016, AC-6). Lifting the rule out of the
/// `language_selector` widget into this use case keeps the
/// `presentation/widgets/` layer free of business logic per constitution
/// §2.1 ("`usecases/` — single-purpose callable classes; one operation per
/// class") and §4.1.1 ("Screens never call repositories directly").
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_language.dart';
import '../repositories/settings_repository.dart';

/// Use case that toggles "follow device language" with atomic pre-fill.
class SetUseSystemLanguage {
  /// Creates a [SetUseSystemLanguage] use case backed by [_repo].
  const SetUseSystemLanguage(this._repo);

  final SettingsRepository _repo;

  /// Toggles the "follow device language" preference.
  ///
  /// Atomic semantics:
  /// - When [value] is `false` (toggling OFF), the use case first persists
  ///   [currentDeviceLanguage] as the manual language override via
  ///   `SettingsRepository.saveManualLanguage`, then persists
  ///   `useSystemLanguage=false` via
  ///   `SettingsRepository.saveUseSystemLanguage`. If the manual write
  ///   returns `Left`, the toggle write is skipped and the `Left` is
  ///   propagated immediately — this prevents the half-applied state where
  ///   `useSystemLanguage=false` but `manualLanguage` is stale.
  /// - When [value] is `true` (toggling ON), only the toggle write is
  ///   issued; [currentDeviceLanguage] is unused (the manual override
  ///   remains untouched so it can be restored if the user later flips
  ///   back).
  ///
  /// Returns `Right(null)` on success or `Left(Failure)` if any underlying
  /// repository write fails.
  Future<Either<Failure, void>> call({
    required bool value,
    required AppLanguage currentDeviceLanguage,
  }) async {
    if (!value) {
      final manualResult = await _repo.saveManualLanguage(
        currentDeviceLanguage,
      );
      if (manualResult.isLeft()) {
        return manualResult;
      }
    }
    return _repo.saveUseSystemLanguage(value);
  }
}
