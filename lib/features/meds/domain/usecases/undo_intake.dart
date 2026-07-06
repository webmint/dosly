/// The single business operation for undoing a confirmed intake.
///
/// [UndoIntake] owns the grace-window rule (constitution §5.2): an intake may
/// only be undone within the supplied [gracePeriod] of its confirmation. The
/// caller provides the window (derived from the `gracePeriod` setting) so this
/// use case stays settings-agnostic — pure domain, no settings value objects.
/// When the window has elapsed it returns a [ValidationFailure]; otherwise it
/// delegates removal to the [IntakeRepository]. Pure Dart (constitution §2.1) —
/// no Flutter, drift, or uuid imports.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/intake_repository.dart';
import '../value_objects/intake_id.dart';

/// Undoes a previously confirmed intake, subject to the grace window.
///
/// The domain owns the rule: an intake may be undone only while the elapsed
/// time since its confirmation is within the supplied [gracePeriod]. Once the
/// window closes the action is refused with a [ValidationFailure] and the
/// repository is never touched. The caller supplies the window (from the
/// `gracePeriod` setting) so this use case stays settings-agnostic. It exists
/// as the single business operation for reverting a dose (constitution §2.1,
/// §5.2).
class UndoIntake {
  /// Creates an [UndoIntake] use case backed by [_repository].
  const UndoIntake(this._repository);

  final IntakeRepository _repository;

  /// Undoes the intake identified by [id], confirmed at [confirmedAt], as of
  /// [now], within the supplied [gracePeriod].
  ///
  /// Both timestamps are compared in UTC. If `now - confirmedAt` exceeds the
  /// supplied [gracePeriod] the grace window has closed: a [ValidationFailure]
  /// is returned via [Left] and the repository is not called. The boundary is
  /// inclusive — exactly [gracePeriod] is still allowed. Otherwise the removal
  /// is delegated to [IntakeRepository.undo], whose result is returned
  /// unchanged.
  Future<Either<Failure, void>> call({
    required IntakeId id,
    required DateTime confirmedAt,
    required DateTime now,
    required Duration gracePeriod,
  }) {
    if (now.toUtc().difference(confirmedAt.toUtc()) > gracePeriod) {
      return Future.value(
        const Left(
          Failure.validation(
            field: 'confirmedAt',
            message: 'The undo grace period has expired',
          ),
        ),
      );
    }

    return _repository.undo(id);
  }
}
