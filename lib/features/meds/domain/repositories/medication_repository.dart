/// Abstract contract for persisting and retrieving medications.
///
/// Defined in the domain layer as a pure-Dart interface (constitution §2.1):
/// the data layer supplies a concrete implementation, and domain use cases
/// depend on this abstraction rather than any storage technology. Every
/// fallible operation returns `Either<Failure, T>` so callers handle both the
/// success and failure paths explicitly.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/medication.dart';

/// Persistence contract for [Medication] aggregates.
///
/// Implemented in the data layer; consumed by domain use cases. Methods return
/// `Either<Failure, T>` to surface failures (e.g. [CacheFailure]) without
/// throwing.
abstract interface class MedicationRepository {
  /// Persists [medication] and returns the stored aggregate on success, or a
  /// [Failure] describing why the operation could not be completed.
  Future<Either<Failure, Medication>> add(Medication medication);

  /// Persists an UPDATE of an already-stored [medication] (its `id` must already
  /// exist), returning the stored aggregate on success or a [Failure] on error.
  /// The medication row is updated in place and its time slots are reconciled;
  /// callers (the EditMedication use case) decide which TimeSlotIds survive.
  Future<Either<Failure, Medication>> update(Medication medication);

  /// Reactively emits all persisted medications, re-emitting on any change.
  ///
  /// The stream yields a fresh list every time the underlying store changes, so
  /// callers can drive a live-updating UI. Errors are surfaced as
  /// `Left(Failure)`, never thrown.
  Stream<Either<Failure, List<Medication>>> watchAll();
}
