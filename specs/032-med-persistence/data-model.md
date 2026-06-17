# Data Model: Medication Persistence (drift)

All entities are **new**. Domain entities are pure-Dart `freezed` classes under `lib/features/meds/domain/`; drift tables under `lib/core/database/tables/`. Mapping happens in `lib/features/meds/data/mappers/`.

## Domain Entities

### Medication (aggregate root)
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | `MedicationId` | yes | Typed value object (wraps a UUID string) |
| name | `String` | yes | Trimmed, non-empty |
| form | `MedicationForm` | yes | One of 8 forms |
| type | `MedicationType` | yes | Sealed `continuous` \| `course` |
| schedule | `Schedule` | yes | Frequency + time slots |
| dosePerIntake | `Dosage?` | no | Null for inhaler/cream/sachet |
| stock | `PackStock?` | no | Null unless a pack-tracked form with stock entered |
| notes | `String?` | no | Optional free text |
| createdAt | `DateTime` | yes | UTC instant (`clock.now().toUtc()`) |

### Dosage (value object)
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| amount | `double` | yes | Quantity per intake (pills) or dose (liquids) |
| unit | `DoseUnit` | yes | tablet, capsule, ml, mg, drops, units, puff, application, sachet |

### PackStock (value object)
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| remaining | `int` | yes | Units currently in pack (≥ 0) |
| total | `int` | yes | Pack size (≥ 0) |
| warnAt | `int` | yes | Low-stock threshold (≥ 0; defaults to 0 when blank) |

### MedicationType (sealed union)
- `MedicationType.continuous({ required DateTime startDate })`
- `MedicationType.course({ required DateTime startDate, required int durationDays, required int pauseDays })`
  - Inclusive end is **derived** (`startDate + durationDays − 1`), not stored. `pauseDays > 0` ⇒ cyclic; `pauseDays == 0` ⇒ single bounded course.
  - `startDate` is a UTC **calendar date** (`DateTime.utc(y, m, d)`).

### Schedule + TimeSlot
- `Schedule({ @Default(ScheduleFrequency.daily) ScheduleFrequency frequency, required List<TimeSlot> slots })`
- `TimeSlot({ required TimeSlotId id, required int minuteOfDay, Dosage? doseOverride })` — `minuteOfDay ∈ 0..1439` (local wall-clock minute). `doseOverride` reserved/unused by this spec (always null from the form).

### Enums
- `MedicationForm { tablet, capsule, syrup, drops, injection, inhaler, cream, sachet }`
- `DoseUnit { tablet, capsule, ml, mg, drops, units, puff, application, sachet }`
- `ScheduleFrequency { daily }` (only `daily` built; other frequencies out of scope)
- `MedicationTypeKind { continuous, course }` — **storage discriminator**, defined in the data layer (not domain; the domain type is sealed and needs no kind tag).

### Value-object IDs
- `MedicationId(String value)`, `TimeSlotId(String value)` — `freezed` single-field value objects (value equality, no hand-rolled `==`). **No `generate()`** — IDs are produced by the injected `IdGenerator` (`core/`), keeping `package:uuid` out of `domain/`.

## Relationships
- **Medication 1 — \* TimeSlot**: `TimeSlots.medicationId` → `Medications.id`, `onDelete: cascade`. Reconstructed into `Medication.schedule.slots` on read. (Cascade is dormant this spec — no delete path yet — but correct from v1; requires `pragma foreign_keys = ON`.)

## Drift Tables

### `Medications` (`@DataClassName('MedicationRow')`)
| Column | Drift type | Null | Notes |
|--------|-----------|------|-------|
| id | `text()` | no | Primary key |
| name | `text()` | no | |
| form | `textEnum<MedicationForm>()` | no | |
| doseAmount | `real()` | yes | `Dosage.amount`; null ⇔ `dosePerIntake == null` |
| doseUnit | `textEnum<DoseUnit>()` | yes | `Dosage.unit`; null ⇔ `dosePerIntake == null` |
| typeKind | `textEnum<MedicationTypeKind>()` | no | continuous \| course |
| frequency | `textEnum<ScheduleFrequency>()` | no | default `daily` |
| startDate | `dateTime()` | no | UTC calendar date |
| durationDays | `integer()` | yes | course only |
| pauseDays | `integer()` | yes | course only |
| stockRemaining | `integer()` | yes | null ⇔ `stock == null` |
| stockTotal | `integer()` | yes | null ⇔ `stock == null` |
| stockWarnAt | `integer()` | yes | null ⇔ `stock == null` |
| notes | `text()` | yes | |
| createdAt | `dateTime()` | no | UTC instant |
| **PK** | `{id}` | | |

### `TimeSlots` (`@DataClassName('TimeSlotRow')`)
| Column | Drift type | Null | Notes |
|--------|-----------|------|-------|
| id | `text()` | no | Primary key |
| medicationId | `text().references(Medications, #id, onDelete: KeyAction.cascade)` | no | FK |
| minuteOfDay | `integer()` | no | 0..1439 |
| doseAmount | `real()` | yes | `doseOverride.amount` |
| doseUnit | `textEnum<DoseUnit>()` | yes | `doseOverride.unit` |
| **PK** | `{id}` | | |

## Domain ↔ Storage Mapping (mapper rules)
| Domain | Storage |
|--------|---------|
| `dosePerIntake: Dosage(a, u)` | `doseAmount=a, doseUnit=u` |
| `dosePerIntake: null` | `doseAmount=null, doseUnit=null` |
| `stock: PackStock(r, t, w)` | `stockRemaining=r, stockTotal=t, stockWarnAt=w` |
| `stock: null` | all three stock columns null |
| `type: continuous(s)` | `typeKind=continuous, startDate=s, durationDays=null, pauseDays=null` |
| `type: course(s, d, p)` | `typeKind=course, startDate=s, durationDays=d, pauseDays=p` |
| `schedule.frequency` | `frequency` column |
| `schedule.slots[i]` | one `TimeSlots` row (FK = medication id) |

## Validation Rules (enforced in `AddMedication`)
- `name`: trimmed length ≥ 1 → else `ValidationFailure(field: 'name')`.
- `schedule.slots`: count ≥ 1 → else `ValidationFailure(field: 'times')`.
- when `type` is `course`: `durationDays ≥ 1` → else `ValidationFailure(field: 'durationDays')`. (`pauseDays ≥ 0` assumed from the stepper's min; not separately validated.)
- `PackStock` is built only when both `remaining` and `total` parse to non-negative ints (OQ-1); `warnAt` defaults to 0 when blank; otherwise `stock = null`.
