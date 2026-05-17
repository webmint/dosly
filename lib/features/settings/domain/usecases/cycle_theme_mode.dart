/// Cycles the theme through `system → light → dark → system` and returns the
/// post-cycle state as a Dart record so the caller (a Riverpod notifier) can
/// apply `state.copyWith(...)` without re-deriving the cycle rule.
///
/// Owns the cycle rule for spec 016 (AC-7). Centralising the rule in this use
/// case avoids re-introducing bug 011 in a new location: any caller that
/// re-implemented the branching would risk drifting from the persisted state.
/// The `Right` value carries `useSystemTheme` and `manualThemeMode` exactly as
/// they were just persisted, so the notifier becomes a thin "apply the
/// returned record" call site.
///
/// Branch table (input → repo writes → returned `Right`):
///
/// | currentUseSystemTheme | currentManualMode | Repo writes (in order)                                  | Right value                                       |
/// |-----------------------|-------------------|---------------------------------------------------------|---------------------------------------------------|
/// | `true`                | (ignored)         | `saveThemeMode(light)` then `saveUseSystemTheme(false)` | `(useSystemTheme: false, manualThemeMode: light)` |
/// | `false`               | `light`           | `saveThemeMode(dark)`                                   | `(useSystemTheme: false, manualThemeMode: dark)`  |
/// | `false`               | `dark`            | `saveUseSystemTheme(true)`                              | `(useSystemTheme: true,  manualThemeMode: dark)`  |
///
/// Short-circuit semantics: if any inner write returns `Left`, the use case
/// returns that `Left` immediately and skips remaining writes. The `Right`
/// always reflects what was actually persisted at the time of return.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_theme_mode.dart';
import '../repositories/settings_repository.dart';

/// Use case that cycles the theme `system → light → dark → system` and
/// returns the resulting post-cycle state in its `Right` value.
class CycleThemeMode {
  /// Creates a [CycleThemeMode] use case backed by [_repo].
  const CycleThemeMode(this._repo);

  final SettingsRepository _repo;

  /// Cycles the theme one step forward and persists the change.
  ///
  /// Branches on the current persisted state:
  ///
  /// 1. **system on** → writes `saveThemeMode(light)` then
  ///    `saveUseSystemTheme(false)`; returns
  ///    `(useSystemTheme: false, manualThemeMode: light)`.
  ///    [currentManualMode] is ignored on this branch — the cycle always
  ///    lands on `light` when leaving system mode.
  /// 2. **manual light** → writes `saveThemeMode(dark)` only; returns
  ///    `(useSystemTheme: false, manualThemeMode: dark)`.
  /// 3. **manual dark** (else branch) → writes `saveUseSystemTheme(true)`
  ///    only; returns `(useSystemTheme: true, manualThemeMode: dark)`.
  ///    The manual override is intentionally preserved as `dark` so that
  ///    when the user later flips system mode off, the manual value is
  ///    still meaningful (it stays at the last manual choice).
  ///
  /// Short-circuit: if any inner repository write returns `Left`, that
  /// `Left` is propagated immediately and any remaining writes are skipped.
  /// The returned `Right` therefore always describes state that was
  /// actually persisted.
  Future<Either<Failure, ({bool useSystemTheme, AppThemeMode manualThemeMode})>>
      call({
    required bool currentUseSystemTheme,
    required AppThemeMode currentManualMode,
  }) async {
    if (currentUseSystemTheme) {
      final manualResult = await _repo.saveThemeMode(AppThemeMode.light);
      if (manualResult.isLeft()) {
        return _propagateLeft(manualResult);
      }
      final toggleResult = await _repo.saveUseSystemTheme(false);
      if (toggleResult.isLeft()) {
        return _propagateLeft(toggleResult);
      }
      return const Right<Failure,
          ({bool useSystemTheme, AppThemeMode manualThemeMode})>(
        (useSystemTheme: false, manualThemeMode: AppThemeMode.light),
      );
    } else if (currentManualMode == AppThemeMode.light) {
      final manualResult = await _repo.saveThemeMode(AppThemeMode.dark);
      if (manualResult.isLeft()) {
        return _propagateLeft(manualResult);
      }
      return const Right<Failure,
          ({bool useSystemTheme, AppThemeMode manualThemeMode})>(
        (useSystemTheme: false, manualThemeMode: AppThemeMode.dark),
      );
    } else {
      final toggleResult = await _repo.saveUseSystemTheme(true);
      if (toggleResult.isLeft()) {
        return _propagateLeft(toggleResult);
      }
      return Right<Failure,
          ({bool useSystemTheme, AppThemeMode manualThemeMode})>(
        (useSystemTheme: true, manualThemeMode: currentManualMode),
      );
    }
  }

  /// Re-wraps a `Left<Failure, void>` as a `Left<Failure, record>`.
  ///
  /// Required because the repo writes return `Either<Failure, void>` while
  /// this use case returns `Either<Failure, record>` — the `Right` type
  /// parameter differs, so the failure must be lifted into the correct
  /// `Either` shape. The input is asserted to be a `Left` by the caller's
  /// `isLeft()` guard; the `fold` here just reads the failure.
  Either<Failure, ({bool useSystemTheme, AppThemeMode manualThemeMode})>
      _propagateLeft(Either<Failure, void> result) => result.fold(
            Left<Failure,
                ({bool useSystemTheme, AppThemeMode manualThemeMode})>.new,
            (_) => throw StateError(
              '_propagateLeft called with a Right value; guard with isLeft() '
              'first.',
            ),
          );
}
