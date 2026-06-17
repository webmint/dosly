/// Pure mapping functions between the [Medication] domain aggregate and its
/// drift storage representation (companions for writes, rows for reads).
///
/// Lives in `data/mappers` (constitution §2.1): it bridges the domain entities
/// and the drift tables/rows in `core/database`. These functions are pure — no
/// I/O, no side effects — so they are trivially unit-testable and contain the
/// single source of truth for the domain ↔ storage field mapping documented in
/// `specs/032-med-persistence/data-model.md`.
library;

import 'package:drift/drift.dart';

import '../../../../core/database/database.dart';
import '../../../../core/database/tables/medications_table.dart';
import '../../domain/entities/dosage.dart';
import '../../domain/entities/dose_unit.dart';
import '../../domain/entities/medication.dart';
import '../../domain/entities/medication_type.dart';
import '../../domain/entities/pack_stock.dart';
import '../../domain/entities/schedule.dart';
import '../../domain/entities/time_slot.dart';
import '../../domain/value_objects/medication_id.dart';
import '../../domain/value_objects/time_slot_id.dart';

/// Builds the [MedicationsCompanion] used to insert [medication] into the
/// `medications` table.
///
/// Maps the sealed [MedicationType] onto the storage discriminator
/// [MedicationTypeKind] plus the nullable `durationDays`/`pauseDays` columns,
/// and collapses the optional [Medication.dosePerIntake] / [Medication.stock]
/// value objects into their nullable columns (absent when the value object is
/// `null`). Time slots are mapped separately by [timeSlotsToCompanions].
MedicationsCompanion medicationToCompanion(Medication medication) {
  final MedicationType type = medication.type;

  // Translate the sealed temporal type into the storage discriminator and its
  // course-only columns. Exhaustive switch over the sealed union — no default.
  final MedicationTypeKind typeKind;
  final DateTime startDate;
  final Value<int> durationDays;
  final Value<int> pauseDays;
  switch (type) {
    case ContinuousType(startDate: final DateTime continuousStart):
      typeKind = MedicationTypeKind.continuous;
      startDate = continuousStart;
      durationDays = const Value<int>.absent();
      pauseDays = const Value<int>.absent();
    case CourseType(
      startDate: final DateTime courseStart,
      durationDays: final int courseDuration,
      pauseDays: final int coursePause,
    ):
      typeKind = MedicationTypeKind.course;
      startDate = courseStart;
      durationDays = Value<int>(courseDuration);
      pauseDays = Value<int>(coursePause);
  }

  // Optional default dose → two nullable columns, both absent when untracked.
  final Dosage? dose = medication.dosePerIntake;
  final Value<double> doseAmount = dose == null
      ? const Value<double>.absent()
      : Value<double>(dose.amount);
  final Value<DoseUnit> doseUnit = dose == null
      ? const Value<DoseUnit>.absent()
      : Value<DoseUnit>(dose.unit);

  // Optional pack stock → three nullable columns, all absent when untracked.
  final PackStock? stock = medication.stock;
  final Value<int> stockRemaining = stock == null
      ? const Value<int>.absent()
      : Value<int>(stock.remaining);
  final Value<int> stockTotal = stock == null
      ? const Value<int>.absent()
      : Value<int>(stock.total);
  final Value<int> stockWarnAt = stock == null
      ? const Value<int>.absent()
      : Value<int>(stock.warnAt);

  return MedicationsCompanion.insert(
    id: medication.id.value,
    name: medication.name,
    form: medication.form,
    typeKind: typeKind,
    frequency: medication.schedule.frequency,
    startDate: startDate,
    durationDays: durationDays,
    pauseDays: pauseDays,
    doseAmount: doseAmount,
    doseUnit: doseUnit,
    stockRemaining: stockRemaining,
    stockTotal: stockTotal,
    stockWarnAt: stockWarnAt,
    notes: Value<String?>(medication.notes),
    createdAt: medication.createdAt,
  );
}

/// Builds one [TimeSlotsCompanion] per slot in [medication]'s schedule, each
/// keyed to [medication]'s id via the `medicationId` foreign key.
///
/// A slot's optional [TimeSlot.doseOverride] maps onto the nullable
/// `doseAmount`/`doseUnit` columns, left absent when the slot uses the
/// medication's default dose.
List<TimeSlotsCompanion> timeSlotsToCompanions(Medication medication) {
  final String medicationId = medication.id.value;
  return <TimeSlotsCompanion>[
    for (final TimeSlot slot in medication.schedule.slots)
      _timeSlotToCompanion(slot, medicationId),
  ];
}

/// Builds a single [TimeSlotsCompanion] for [slot] owned by [medicationId].
///
/// The optional [TimeSlot.doseOverride] is read into a local so its `amount`
/// and `unit` can be accessed without a null-assertion (`!`); both columns are
/// left absent when the slot carries no override.
TimeSlotsCompanion _timeSlotToCompanion(TimeSlot slot, String medicationId) {
  final Dosage? override = slot.doseOverride;
  final Value<double> doseAmount = override == null
      ? const Value<double>.absent()
      : Value<double>(override.amount);
  final Value<DoseUnit> doseUnit = override == null
      ? const Value<DoseUnit>.absent()
      : Value<DoseUnit>(override.unit);
  return TimeSlotsCompanion.insert(
    id: slot.id.value,
    medicationId: medicationId,
    minuteOfDay: slot.minuteOfDay,
    doseAmount: doseAmount,
    doseUnit: doseUnit,
  );
}

/// Reconstructs a [Medication] aggregate from its stored [row] and the
/// [slotRows] belonging to it.
///
/// Inverse of [medicationToCompanion] / [timeSlotsToCompanions]. Nullable
/// columns are read into locals and combined explicitly so a partially-written
/// row never produces a half-built value object: a [Dosage] is built only when
/// both amount and unit are present, and a [PackStock] only when remaining,
/// total and warnAt are all present. A `course` row missing its
/// `durationDays`/`pauseDays`, or a stock row carrying remaining+total but a
/// null warnAt, is a corrupt record and throws a descriptive [StateError].
Medication medicationFromRows(MedicationRow row, List<TimeSlotRow> slotRows) {
  // Default dose: present only when BOTH columns are non-null.
  final Dosage? dosePerIntake = _dosageFromColumns(
    row.doseAmount,
    row.doseUnit,
  );

  // Pack stock: present only when remaining, total AND warnAt are all
  // non-null. A row carrying remaining+total but a missing warn threshold is
  // corrupt and fails loudly rather than guessing a default — symmetric with
  // the course durationDays/pauseDays guard below.
  final int? stockRemaining = row.stockRemaining;
  final int? stockTotal = row.stockTotal;
  final int? stockWarnAt = row.stockWarnAt;
  final PackStock? stock;
  if (stockRemaining != null && stockTotal != null) {
    if (stockWarnAt == null) {
      throw StateError(
        'Corrupt medication row ${row.id}: stock requires a non-null '
        'stockWarnAt when stockRemaining and stockTotal are present, got '
        'stockRemaining=$stockRemaining, stockTotal=$stockTotal, '
        'stockWarnAt=$stockWarnAt',
      );
    }
    stock = PackStock(
      remaining: stockRemaining,
      total: stockTotal,
      warnAt: stockWarnAt,
    );
  } else {
    stock = null;
  }

  // Temporal type: exhaustive switch over the storage discriminator — no
  // default. Course rows must carry both course columns; otherwise the record
  // is corrupt and we fail loudly rather than guessing a default.
  final MedicationType type;
  switch (row.typeKind) {
    case MedicationTypeKind.continuous:
      type = MedicationType.continuous(startDate: row.startDate);
    case MedicationTypeKind.course:
      final int? durationDays = row.durationDays;
      final int? pauseDays = row.pauseDays;
      if (durationDays == null || pauseDays == null) {
        throw StateError(
          'Corrupt medication row ${row.id}: typeKind=course requires '
          'non-null durationDays and pauseDays, got '
          'durationDays=$durationDays, pauseDays=$pauseDays',
        );
      }
      type = MedicationType.course(
        startDate: row.startDate,
        durationDays: durationDays,
        pauseDays: pauseDays,
      );
  }

  final Schedule schedule = Schedule(
    frequency: row.frequency,
    slots: <TimeSlot>[
      for (final TimeSlotRow slotRow in slotRows)
        TimeSlot(
          id: TimeSlotId(slotRow.id),
          minuteOfDay: slotRow.minuteOfDay,
          doseOverride: _dosageFromColumns(slotRow.doseAmount, slotRow.doseUnit),
        ),
    ],
  );

  return Medication(
    id: MedicationId(row.id),
    name: row.name,
    form: row.form,
    type: type,
    schedule: schedule,
    dosePerIntake: dosePerIntake,
    stock: stock,
    notes: row.notes,
    createdAt: row.createdAt,
  );
}

/// Builds a [Dosage] from a nullable [amount]/[unit] column pair, returning
/// `null` unless BOTH are present.
///
/// Reading the nullable columns into local parameters lets Dart's flow analysis
/// promote them to non-null inside the guard, so the [Dosage] is constructed
/// without any null-assertion (`!`).
Dosage? _dosageFromColumns(double? amount, DoseUnit? unit) {
  if (amount == null || unit == null) {
    return null;
  }
  return Dosage(amount: amount, unit: unit);
}
