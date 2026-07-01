/// The single business operation for deleting an existing medication.
///
/// [DeleteMedication] is a thin forwarder to the [MedicationRepository]: unlike
/// `AddMedication`/`EditMedication` it performs NO validation, because deleting
/// needs none — removing an unknown id is an idempotent no-op and the database's
/// `onDelete: cascade` foreign key handles time-slot cleanup. Pure Dart
/// (constitution §2.1) — no Flutter, drift, or uuid imports.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/medication_repository.dart';
import '../value_objects/medication_id.dart';

/// Use case that deletes a medication by its [MedicationId].
///
/// Pure pass-through: the use case simply forwards the input to
/// [MedicationRepository.delete]. It exists as the indirection layer through
/// which presentation delegates, per constitution §2.1 ("`usecases/` —
/// single-purpose callable classes; one operation per class") and §4.1.1
/// ("Screens never call repositories directly").
class DeleteMedication {
  /// Creates a [DeleteMedication] use case backed by [_repository].
  const DeleteMedication(this._repository);

  final MedicationRepository _repository;

  /// Deletes the medication identified by [id].
  ///
  /// Behavior is delegated to [MedicationRepository.delete]: removing an [id]
  /// that does not exist is a successful no-op (idempotent, returns `Right`),
  /// the database's `onDelete: cascade` foreign key removes the medication's
  /// time slots, and only a storage error surfaces as `Left(Failure)`.
  Future<Either<Failure, void>> call(MedicationId id) =>
      _repository.delete(id);
}
