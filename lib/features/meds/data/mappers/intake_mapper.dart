/// Pure mapping functions between the [Intake] domain entity and its drift
/// storage representation (a companion for writes, a row for reads).
///
/// Lives in `data/mappers` (constitution §2.1): it bridges the domain entity
/// and the drift `intakes` table/row in `core/database`. These functions are
/// pure — no I/O, no side effects — so they are trivially unit-testable and
/// hold the single source of truth for the domain ↔ storage field mapping.
///
/// TIMESTAMP CONTRACT: [Intake.scheduledAt] and the optional
/// [Intake.confirmedAt] are UTC instants in the domain. On write they are
/// normalised with `toUtc()` before storage, honouring the UTC-storage
/// convention. On read the stored value is passed through unchanged: drift's
/// `dateTime()` column returns a *local*-flagged [DateTime] holding the same
/// absolute moment, so consumers treat it as a UTC instant and compare with
/// `isAtSameMomentAs`, never on the `isUtc` flag.
library;

import 'package:drift/drift.dart';

import '../../../../core/database/database.dart';
import '../../domain/entities/intake.dart';
import '../../domain/value_objects/intake_id.dart';
import '../../domain/value_objects/medication_id.dart';
import '../../domain/value_objects/time_slot_id.dart';

/// Builds the [IntakesCompanion] used to upsert [intake] into the `intakes`
/// table.
///
/// The required occurrence columns (`id`, `medicationId`, `slotId`,
/// `scheduledAt`, `status`) are passed to [IntakesCompanion.insert] directly;
/// the optional `confirmedAt`/`notes` columns are wrapped in [Value] and hold
/// `null` when the intake carries none (an explicit `NULL` write, not
/// `Value.absent()`, since the domain value is the source of truth). Both
/// [Intake.scheduledAt] and the optional [Intake.confirmedAt] are normalised to
/// UTC with `toUtc()` before storage.
IntakesCompanion intakeToCompanion(Intake intake) {
  return IntakesCompanion.insert(
    id: intake.id.value,
    medicationId: intake.medicationId.value,
    slotId: intake.slotId.value,
    scheduledAt: intake.scheduledAt.toUtc(),
    status: intake.status,
    confirmedAt: Value<DateTime?>(intake.confirmedAt?.toUtc()),
    notes: Value<String?>(intake.notes),
  );
}

/// Reconstructs an [Intake] entity from its stored [row].
///
/// Inverse of [intakeToCompanion]: each raw identifier column is rewrapped into
/// its typed value object ([IntakeId] / [MedicationId] / [TimeSlotId]) and the
/// scalar columns are copied across verbatim. Timestamps are passed through as
/// stored — drift returns them with a local `isUtc` flag but the same absolute
/// moment, and consumers treat them as UTC instants (see the timestamp contract
/// in this library's docs).
Intake intakeFromRow(IntakeRow row) {
  return Intake(
    id: IntakeId(row.id),
    medicationId: MedicationId(row.medicationId),
    slotId: TimeSlotId(row.slotId),
    scheduledAt: row.scheduledAt,
    confirmedAt: row.confirmedAt,
    status: row.status,
    notes: row.notes,
  );
}
