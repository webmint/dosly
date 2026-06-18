/// DEBUG-only demo seed data for the medications database.
///
/// Pure seed-data builder (no I/O, no logging, no database access): it returns
/// a representative set of [Medication] aggregates covering every
/// [MedicationForm], both [MedicationType] variants (continuous and course,
/// including cyclic active / cyclic paused / completed states), and the
/// with/without dose-and-stock and low-stock cases. The data layer write path
/// is responsible for persistence; this file only constructs the entities.
///
/// All dates are relative to the caller-supplied `now` so the set is
/// deterministic for a given clock. See `specs/034-meds-list/data-model.md`.
///
/// Core-layer file that imports domain entities — `core → domain` is permitted
/// (constitution §2.1); it has no Flutter, drift, or uuid imports.
library;

import '../../features/meds/domain/entities/dosage.dart';
import '../../features/meds/domain/entities/dose_unit.dart';
import '../../features/meds/domain/entities/medication.dart';
import '../../features/meds/domain/entities/medication_form.dart';
import '../../features/meds/domain/entities/medication_type.dart';
import '../../features/meds/domain/entities/pack_stock.dart';
import '../../features/meds/domain/entities/schedule.dart';
import '../../features/meds/domain/entities/time_slot.dart';
import '../../features/meds/domain/value_objects/medication_id.dart';
import '../../features/meds/domain/value_objects/time_slot_id.dart';

// Wall-clock minute-of-day constants for the seed schedule slots.
const int _t0800 = 480; // 08:00
const int _t0900 = 540; // 09:00
const int _t1200 = 720; // 12:00
const int _t1400 = 840; // 14:00
const int _t2000 = 1200; // 20:00
const int _t2100 = 1260; // 21:00

/// Builds a representative set of demo medications for DEBUG seeding.
///
/// Pure — every start date is computed relative to [now] via
/// `now.subtract(Duration(days: N))` (acceptable for seed data; this is NOT the
/// DST-sensitive day-count path). Each medication gets a stable
/// `MedicationId('seed-…')` and each time slot a unique
/// `TimeSlotId('seed-…-tN')`, and all share `createdAt: now`.
///
/// The returned list covers all eight [MedicationForm] values, both continuous
/// and course (single, cyclic-active, cyclic-paused, completed) temporal types,
/// medications with and without a default dose and stock, and a deliberately
/// low-stock entry.
List<Medication> devSeedMedications(DateTime now) {
  TimeSlot slot(String medSeed, int index, int minuteOfDay) => TimeSlot(
    id: TimeSlotId('seed-$medSeed-t$index'),
    minuteOfDay: minuteOfDay,
  );

  return <Medication>[
    // 1. Omeprazole — tablet, continuous, with dose + stock, two daily slots.
    Medication(
      id: const MedicationId('seed-omeprazole'),
      name: 'Omeprazole',
      form: MedicationForm.tablet,
      type: MedicationType.continuous(
        startDate: now.subtract(const Duration(days: 90)),
      ),
      schedule: Schedule(
        slots: <TimeSlot>[
          slot('omeprazole', 1, _t0800),
          slot('omeprazole', 2, _t2000),
        ],
      ),
      dosePerIntake: const Dosage(amount: 20, unit: DoseUnit.mg),
      stock: const PackStock(remaining: 18, total: 30, warnAt: 10),
      createdAt: now,
    ),
    // 2. Vitamin D3 — capsule, continuous, dose only (no stock), single slot.
    Medication(
      id: const MedicationId('seed-vitamin-d3'),
      name: 'Vitamin D3',
      form: MedicationForm.capsule,
      type: MedicationType.continuous(
        startDate: now.subtract(const Duration(days: 200)),
      ),
      schedule: Schedule(
        slots: <TimeSlot>[slot('vitamin-d3', 1, _t1400)],
      ),
      dosePerIntake: const Dosage(amount: 2000, unit: DoseUnit.units),
      createdAt: now,
    ),
    // 3. Magnesium B6 — tablet, continuous, LOW stock (5/60 warn 10).
    Medication(
      id: const MedicationId('seed-magnesium-b6'),
      name: 'Magnesium B6',
      form: MedicationForm.tablet,
      type: MedicationType.continuous(
        startDate: now.subtract(const Duration(days: 40)),
      ),
      schedule: Schedule(
        slots: <TimeSlot>[slot('magnesium-b6', 1, _t1400)],
      ),
      dosePerIntake: const Dosage(amount: 48, unit: DoseUnit.mg),
      stock: const PackStock(remaining: 5, total: 60, warnAt: 10),
      createdAt: now,
    ),
    // 4. Amoxicillin — capsule, single bounded course (pause 0), with stock.
    Medication(
      id: const MedicationId('seed-amoxicillin'),
      name: 'Amoxicillin',
      form: MedicationForm.capsule,
      type: MedicationType.course(
        startDate: now.subtract(const Duration(days: 2)),
        durationDays: 7,
        pauseDays: 0,
      ),
      schedule: Schedule(
        slots: <TimeSlot>[
          slot('amoxicillin', 1, _t0800),
          slot('amoxicillin', 2, _t1400),
          slot('amoxicillin', 3, _t2000),
        ],
      ),
      dosePerIntake: const Dosage(amount: 500, unit: DoseUnit.mg),
      stock: const PackStock(remaining: 12, total: 14, warnAt: 4),
      createdAt: now,
    ),
    // 5. Mexiprim — injection, cyclic course currently ACTIVE (dur 30, pause 7).
    Medication(
      id: const MedicationId('seed-mexiprim'),
      name: 'Mexiprim',
      form: MedicationForm.injection,
      type: MedicationType.course(
        startDate: now.subtract(const Duration(days: 6)),
        durationDays: 30,
        pauseDays: 7,
      ),
      schedule: Schedule(
        slots: <TimeSlot>[
          slot('mexiprim', 1, _t1400),
          slot('mexiprim', 2, _t2000),
        ],
      ),
      dosePerIntake: const Dosage(amount: 125, unit: DoseUnit.mg),
      createdAt: now,
    ),
    // 6. Vitamin B12 — injection, cyclic course currently in its pause window:
    //    day 25 of a 30-day cycle (10 active + 20 pause), so genuinely PAUSED.
    Medication(
      id: const MedicationId('seed-vitamin-b12'),
      name: 'Vitamin B12',
      form: MedicationForm.injection,
      type: MedicationType.course(
        startDate: now.subtract(const Duration(days: 25)),
        durationDays: 10,
        pauseDays: 20,
      ),
      schedule: Schedule(
        slots: <TimeSlot>[slot('vitamin-b12', 1, _t0900)],
      ),
      dosePerIntake: const Dosage(amount: 1, unit: DoseUnit.ml),
      createdAt: now,
    ),
    // 7. Azithromycin — tablet, single course already COMPLETED (dur 5, pause 0).
    Medication(
      id: const MedicationId('seed-azithromycin'),
      name: 'Azithromycin',
      form: MedicationForm.tablet,
      type: MedicationType.course(
        startDate: now.subtract(const Duration(days: 10)),
        durationDays: 5,
        pauseDays: 0,
      ),
      schedule: Schedule(
        slots: <TimeSlot>[slot('azithromycin', 1, _t0900)],
      ),
      dosePerIntake: const Dosage(amount: 500, unit: DoseUnit.mg),
      createdAt: now,
    ),
    // 8. Salbutamol — inhaler, continuous, dose only, two slots.
    Medication(
      id: const MedicationId('seed-salbutamol'),
      name: 'Salbutamol',
      form: MedicationForm.inhaler,
      type: MedicationType.continuous(
        startDate: now.subtract(const Duration(days: 15)),
      ),
      schedule: Schedule(
        slots: <TimeSlot>[
          slot('salbutamol', 1, _t0800),
          slot('salbutamol', 2, _t2000),
        ],
      ),
      dosePerIntake: const Dosage(amount: 2, unit: DoseUnit.puff),
      createdAt: now,
    ),
    // 9. Nasal drops — drops, short course, two slots.
    Medication(
      id: const MedicationId('seed-nasal-drops'),
      name: 'Nasal drops',
      form: MedicationForm.drops,
      type: MedicationType.course(
        startDate: now.subtract(const Duration(days: 1)),
        durationDays: 5,
        pauseDays: 0,
      ),
      schedule: Schedule(
        slots: <TimeSlot>[
          slot('nasal-drops', 1, _t0900),
          slot('nasal-drops', 2, _t2100),
        ],
      ),
      dosePerIntake: const Dosage(amount: 3, unit: DoseUnit.drops),
      createdAt: now,
    ),
    // 10. Hydrocortisone — cream, continuous, single morning application.
    Medication(
      id: const MedicationId('seed-hydrocortisone'),
      name: 'Hydrocortisone',
      form: MedicationForm.cream,
      type: MedicationType.continuous(
        startDate: now.subtract(const Duration(days: 20)),
      ),
      schedule: Schedule(
        slots: <TimeSlot>[slot('hydrocortisone', 1, _t0800)],
      ),
      dosePerIntake: const Dosage(amount: 1, unit: DoseUnit.application),
      createdAt: now,
    ),
    // 11. Rehydron — sachet, course starting today (dur 3, pause 0), midday slot.
    Medication(
      id: const MedicationId('seed-rehydron'),
      name: 'Rehydron',
      form: MedicationForm.sachet,
      type: MedicationType.course(
        startDate: now,
        durationDays: 3,
        pauseDays: 0,
      ),
      schedule: Schedule(
        slots: <TimeSlot>[slot('rehydron', 1, _t1200)],
      ),
      dosePerIntake: const Dosage(amount: 1, unit: DoseUnit.sachet),
      createdAt: now,
    ),
    // 12. Ibuprofen syrup — syrup, continuous, two slots.
    Medication(
      id: const MedicationId('seed-ibuprofen-syrup'),
      name: 'Ibuprofen syrup',
      form: MedicationForm.syrup,
      type: MedicationType.continuous(
        startDate: now.subtract(const Duration(days: 5)),
      ),
      schedule: Schedule(
        slots: <TimeSlot>[
          slot('ibuprofen-syrup', 1, _t0800),
          slot('ibuprofen-syrup', 2, _t2000),
        ],
      ),
      dosePerIntake: const Dosage(amount: 5, unit: DoseUnit.ml),
      createdAt: now,
    ),
  ];
}
