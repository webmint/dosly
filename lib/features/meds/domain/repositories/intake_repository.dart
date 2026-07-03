/// Abstract contract for persisting and retrieving medication intake events.
///
/// Defined in the domain layer as a pure-Dart interface (constitution §2.1):
/// the data layer supplies a concrete implementation, and domain use cases
/// depend on this abstraction rather than any storage technology. Every
/// fallible operation returns `Either<Failure, T>` so callers handle both the
/// success and failure paths explicitly.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/intake.dart';
import '../value_objects/intake_id.dart';

/// Persistence contract for [Intake] events.
///
/// Implemented in the data layer; consumed by domain use cases. Methods return
/// `Either<Failure, T>` to surface failures (e.g. [CacheFailure]) without
/// throwing.
///
/// Writes are idempotent per dose occurrence, keyed by
/// `(medicationId, slotId, scheduledAt)`: marking the same occurrence again
/// updates the existing record in place rather than creating a duplicate, so
/// the intake state machine (constitution §5.2) has at most one event per due
/// dose.
abstract interface class IntakeRepository {
  /// Reactively emits all persisted intake events, re-emitting on any change.
  ///
  /// The stream yields a fresh list every time the underlying store changes, so
  /// callers can drive a live-updating UI. Errors are surfaced as
  /// `Left(Failure)`, never thrown.
  Stream<Either<Failure, List<Intake>>> watchAll();

  /// Records a TAKEN [intake] for its dose occurrence, returning the stored
  /// event on success or a [Failure] on error.
  ///
  /// Idempotent per `(medicationId, slotId, scheduledAt)`: if an event already
  /// exists for that occurrence it is updated in place (e.g. re-marking a
  /// skipped dose as taken) rather than duplicated. Everything returns
  /// `Either<Failure, T>` so callers handle both paths (constitution §3.2).
  Future<Either<Failure, Intake>> markTaken(Intake intake);

  /// Records a SKIPPED [intake] for its dose occurrence, returning the stored
  /// event on success or a [Failure] on error.
  ///
  /// Idempotent per `(medicationId, slotId, scheduledAt)` in the same way as
  /// [markTaken]: an existing event for the occurrence is updated in place
  /// rather than duplicated. Failures surface as `Left(Failure)`, never thrown.
  Future<Either<Failure, Intake>> skip(Intake intake);

  /// Removes the intake identified by [id], returning its dose to the pending
  /// state.
  ///
  /// Deleting an [id] that does not exist is a successful no-op (idempotent),
  /// returning `Right`; only a storage error surfaces as `Left(Failure)`.
  /// Everything returns `Either<Failure, T>` so callers handle both paths
  /// (constitution §3.2).
  Future<Either<Failure, void>> undo(IntakeId id);
}
