/// The single business operation for creating a new medication.
///
/// [AddMedication] is the one place medication-creation validation lives: it
/// validates the caller's input, mints the required typed identifiers via the
/// injected [IdGenerator], stamps the creation time from the ambient [clock],
/// and forwards the assembled [Medication] to the [MedicationRepository].
/// Pure Dart (constitution §2.1) — no Flutter, drift, or uuid imports.
library;

import 'package:clock/clock.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/id/id_generator.dart';
import '../entities/dosage.dart';
import '../entities/medication.dart';
import '../entities/medication_form.dart';
import '../entities/medication_type.dart';
import '../entities/pack_stock.dart';
import '../entities/schedule.dart';
import '../entities/time_slot.dart';
import '../repositories/medication_repository.dart';
import '../value_objects/medication_id.dart';
import '../value_objects/time_slot_id.dart';

/// Creates and persists a new [Medication] after validating its inputs.
///
/// Validation is centralised here so every creation path enforces the same
/// rules: a non-empty name, at least one intake time, and (for a
/// [CourseType]) a course duration of at least one day. On success the
/// freshly built medication is forwarded to [MedicationRepository.add];
/// otherwise a [ValidationFailure] is returned via the [Left] branch.
class AddMedication {
  /// Creates an [AddMedication] use case backed by [_repository] for
  /// persistence and [_idGenerator] for minting medication and slot IDs.
  const AddMedication(this._repository, this._idGenerator);

  final MedicationRepository _repository;
  final IdGenerator _idGenerator;

  /// Validates the supplied medication details and, if valid, persists a new
  /// [Medication].
  ///
  /// [name] is trimmed before storage and must be non-empty. [intakeMinutes]
  /// lists the wall-clock minutes-of-day at which the medication is taken and
  /// must contain at least one entry; each becomes a [TimeSlot] with a
  /// generated [TimeSlotId]. When [type] is a [CourseType], its
  /// `durationDays` must be at least 1. [dosePerIntake], [stock], and [notes]
  /// are optional metadata; when [dosePerIntake] is provided its `amount`
  /// must be greater than zero.
  ///
  /// Returns the persisted [Medication] on success, or a [Failure] (a
  /// [ValidationFailure] for invalid input, or whatever the repository
  /// surfaces) on failure.
  Future<Either<Failure, Medication>> call({
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

    final slots = [
      for (final m in intakeMinutes)
        TimeSlot(id: TimeSlotId(_idGenerator.newId()), minuteOfDay: m),
    ];

    final medication = Medication(
      id: MedicationId(_idGenerator.newId()),
      name: name.trim(),
      form: form,
      type: type,
      schedule: Schedule(slots: slots),
      dosePerIntake: dosePerIntake,
      stock: stock,
      notes: notes,
      createdAt: clock.now().toUtc(),
    );

    return _repository.add(medication);
  }
}
