/// The single business operation for confirming a scheduled dose as taken.
///
/// [MarkIntakeTaken] mints a fresh [IntakeId] via the injected [IdGenerator],
/// stamps the confirmation time in UTC, assembles a TAKEN [Intake] for the
/// given dose occurrence, and forwards it to the [IntakeRepository]. Pure Dart
/// (constitution §2.1) — no Flutter, drift, or uuid imports.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/id/id_generator.dart';
import '../entities/intake.dart';
import '../entities/intake_status.dart';
import '../repositories/intake_repository.dart';
import '../value_objects/intake_id.dart';
import '../value_objects/medication_id.dart';
import '../value_objects/time_slot_id.dart';

/// Records a scheduled dose occurrence as [IntakeStatus.taken].
///
/// Builds the [Intake] for the occurrence — a freshly generated [IntakeId],
/// the confirmation timestamp in UTC, and the `taken` status — then delegates
/// persistence to [IntakeRepository.markTaken]. It exists as the single
/// business operation for confirming a dose (constitution §2.1, "one operation
/// per class") so presentation never touches the repository directly (§4.1.1).
class MarkIntakeTaken {
  /// Creates a [MarkIntakeTaken] use case backed by [_repository] for
  /// persistence and [_idGenerator] for minting the new intake ID.
  const MarkIntakeTaken(this._repository, this._idGenerator);

  final IntakeRepository _repository;
  final IdGenerator _idGenerator;

  /// Confirms the dose occurrence identified by [medicationId], [slotId], and
  /// [scheduledAt] as taken at [now].
  ///
  /// Both [scheduledAt] and [now] are normalised to UTC before storage
  /// (constitution "All timestamps in UTC, displayed in local"). Returns the
  /// persisted [Intake] on success, or whatever [Failure] the repository
  /// surfaces via the [Left] branch.
  Future<Either<Failure, Intake>> call({
    required MedicationId medicationId,
    required TimeSlotId slotId,
    required DateTime scheduledAt,
    required DateTime now,
  }) {
    final intake = Intake(
      id: IntakeId(_idGenerator.newId()),
      medicationId: medicationId,
      slotId: slotId,
      scheduledAt: scheduledAt.toUtc(),
      confirmedAt: now.toUtc(),
      status: IntakeStatus.taken,
      notes: null,
    );

    return _repository.markTaken(intake);
  }
}
