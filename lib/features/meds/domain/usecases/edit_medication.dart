/// The single business operation for editing an existing medication.
///
/// [EditMedication] is the one place medication-edit validation and
/// time-slot-ID reconciliation live: it validates the caller's input with the
/// SAME rules as `AddMedication`, preserves the original medication's identity
/// and creation time, reconciles [TimeSlotId]s across the schedule change, and
/// forwards the updated [Medication] to the [MedicationRepository]. Pure Dart
/// (constitution §2.1) — no Flutter, drift, or uuid imports.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/id/id_generator.dart';
import '../entities/dosage.dart';
import '../entities/medication.dart';
import '../entities/medication_form.dart';
import '../entities/medication_type.dart';
import '../entities/pack_stock.dart';
import '../entities/time_slot.dart';
import '../repositories/medication_repository.dart';
import '../value_objects/time_slot_id.dart';

/// Updates and persists an existing [Medication] after validating its inputs.
///
/// Validation mirrors `AddMedication` exactly so creation and editing enforce
/// the same rules: a non-empty name, at least one intake time, and (for a
/// [CourseType]) a course duration of at least one day. Unlike creation, this
/// use case does NOT mint a new [MedicationId] nor stamp a fresh `createdAt`:
/// the original aggregate's `id` and `createdAt` are preserved via `copyWith`.
///
/// Time slots are reconciled rather than rebuilt: a slot whose `minuteOfDay` is
/// unchanged is preserved verbatim — keeping both its original [TimeSlotId] and
/// any per-slot `doseOverride` — while a newly introduced minute receives a
/// freshly minted id from the injected [IdGenerator]. This keeps stable
/// identities and per-slot data for unchanged slots so downstream references
/// (e.g. reminders) survive an edit. On success the updated medication is forwarded
/// to [MedicationRepository.update]; otherwise a [ValidationFailure] is
/// returned via the [Left] branch and the repository is never called.
class EditMedication {
  /// Creates an [EditMedication] use case backed by [_repository] for
  /// persistence and [_idGenerator] for minting slot IDs introduced by the edit.
  const EditMedication(this._repository, this._idGenerator);

  final MedicationRepository _repository;
  final IdGenerator _idGenerator;

  /// Validates the supplied medication details and, if valid, persists an
  /// update of [original].
  ///
  /// [original] is the already-stored aggregate being edited; its `id` and
  /// `createdAt` are preserved unchanged. [name] is trimmed before storage and
  /// must be non-empty. [intakeMinutes] lists the wall-clock minutes-of-day at
  /// which the medication is taken and must contain at least one entry; each
  /// reuses the original [TimeSlot] verbatim (its [TimeSlotId] and any
  /// `doseOverride`) when the minute is unchanged, or becomes a new slot with a
  /// freshly generated id otherwise. When [type] is a
  /// [CourseType], its `durationDays` must be at least 1. [dosePerIntake],
  /// [stock], and [notes] replace the original metadata; when [dosePerIntake]
  /// is provided its `amount` must be greater than zero.
  ///
  /// Returns the persisted [Medication] on success, or a [Failure] (a
  /// [ValidationFailure] for invalid input, or whatever the repository
  /// surfaces) on failure.
  Future<Either<Failure, Medication>> call({
    required Medication original,
    required String name,
    required MedicationForm form,
    required List<int> intakeMinutes,
    required MedicationType type,
    Dosage? dosePerIntake,
    PackStock? stock,
    String? notes,
  }) async {
    if (name.trim().isEmpty) {
      return const Left(
        Failure.validation(field: 'name', message: 'Name is required'),
      );
    }

    if (intakeMinutes.isEmpty) {
      return const Left(
        Failure.validation(
          field: 'times',
          message: 'At least one intake time is required',
        ),
      );
    }

    if (type case CourseType(:final durationDays) when durationDays < 1) {
      return const Left(
        Failure.validation(
          field: 'durationDays',
          message: 'Course duration must be at least 1 day',
        ),
      );
    }

    final dose = dosePerIntake;
    if (dose != null && dose.amount <= 0) {
      return const Left(
        Failure.validation(field: 'dose', message: 'Dose must be greater than zero'),
      );
    }

    // Reconcile slots: reuse the original slot VERBATIM (id + any doseOverride)
    // where the minute is unchanged; mint a fresh slot for any new minute.
    final existing = {
      for (final slot in original.schedule.slots) slot.minuteOfDay: slot,
    };
    final slots = [
      for (final m in intakeMinutes)
        existing[m] ?? TimeSlot(id: TimeSlotId(_idGenerator.newId()), minuteOfDay: m),
    ];

    // copyWith preserves `id` and `createdAt`; schedule.copyWith preserves the
    // original frequency while swapping in the reconciled slots.
    final updated = original.copyWith(
      name: name.trim(),
      form: form,
      type: type,
      schedule: original.schedule.copyWith(slots: slots),
      dosePerIntake: dosePerIntake,
      stock: stock,
      notes: notes,
    );

    return _repository.update(updated);
  }
}
