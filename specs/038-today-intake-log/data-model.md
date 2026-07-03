# Data Model: Today Screen — Daily Intake Checklist

Only **new** or **changed** types are documented. Existing meds domain types (`Medication`, `Schedule`, `TimeSlot`, `MedicationType`, `Dosage`, `MedicationForm`, `MedicationId`, `TimeSlotId`) are reused unchanged.

## Domain entities (new)

### `IntakeStatus` (enum — pure Dart leaf)
`{ pending, taken, missed, skipped }` — full §5.1 set. **Storage contract**: persisted BY NAME via drift `textEnum`; order/names are the on-disk format (do not rename/remove without a migration).

> This slice only ever **persists** `taken` or `skipped`. `pending` is the derived state of a dose with no stored row; `missed` is unused until the auto-miss follow-up. Keeping all four values now avoids a rename/migration later.

### `IntakeId` (value object — freezed)
`const factory IntakeId(String value)` — mirrors `MedicationId`/`TimeSlotId`. No `generate()`; ids come from the injected `IdGenerator`.

### `Intake` (entity — freezed)
Constitution §5.1 shape.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | `IntakeId` | yes | Stable typed identifier. |
| `medicationId` | `MedicationId` | yes | Owning medication. |
| `slotId` | `TimeSlotId` | yes | The schedule slot this dose came from. |
| `scheduledAt` | `DateTime` (UTC) | yes | The dose's scheduled instant (local scheduled time → UTC). |
| `confirmedAt` | `DateTime?` (UTC) | no | When the user acted; set for taken/skipped. |
| `status` | `IntakeStatus` | yes | `taken` or `skipped` in this slice. |
| `notes` | `String?` | no | Unused this slice (always null). |

### `DueDose` (value object — new; expansion output)
One expanded occurrence for a given day. Pure Dart, no persistence.

| Field | Type | Description |
|-------|------|-------------|
| `medication` | `Medication` | Source medication. |
| `slot` | `TimeSlot` | The slot that produced this dose. |
| `effectiveDose` | `Dosage?` | `slot.doseOverride ?? medication.dosePerIntake`. |
| `scheduledAt` | `DateTime` (UTC) | The day's local date at `slot.minuteOfDay`, as UTC. |

## Presentation view types (new)

### `TodayDose`
A `DueDose` paired with its **derived** status for rendering.

| Field | Type | Description |
|-------|------|-------------|
| `dose` | `DueDose` | The expanded occurrence. |
| `status` | `IntakeStatus` | `taken`/`skipped` if a matching `Intake` exists, else `pending`. |
| `confirmedAt` | `DateTime?` | From the matching intake (for grace math). |
| `undoable` | `bool` | `status != pending && (now − confirmedAt) <= kIntakeUndoGracePeriod`. |

### `TodayView`
Result of `buildTodayView`: `List<TodayDose> doses` (time-sorted ascending), plus a flag/count distinguishing "no doses due today" from a loaded list.

## Domain policy constant (new)
`const Duration kIntakeUndoGracePeriod = Duration(minutes: 5);` (constitution §5.2 default; Settings-configurable in a follow-up).

## Pure domain function (new)
`List<DueDose> expandDueDoses({required List<Medication> meds, required DateTime now})`

Rules (reusing existing DST-safe day math):
- **Continuous** (`ContinuousType`): due when `localDate(now) >= localDate(startDate)`; one `DueDose` per slot. Future start ⇒ not due.
- **Course** (`CourseType`): due only when **all** hold: `localDate(now) >= localDate(startDate)`; `resolveMedicationActivity(med, now) == active` (drops completed non-cyclic courses); `CourseProgress.resolve(course, now).phase == activeWindow` (drops pause-gap days). Then one `DueDose` per slot.
- Sorted ascending by `slot.minuteOfDay`, ties by `medication.name` (case-insensitive), then `slot.id` for stability.
- `scheduledAt` = local `DateTime(now.year, now.month, now.day, h, m).toUtc()` where `h = minuteOfDay ~/ 60`, `m = minuteOfDay % 60`.

## Drift table (new): `Intakes`
Lives in `lib/core/database/tables/intakes_table.dart`. Registered in `AppDatabase` (`@DriftDatabase(tables: [Medications, TimeSlots, Intakes])`). Generated data class `IntakeRow`.

| Column | Drift type | Notes |
|--------|-----------|-------|
| `id` | `text()` PK | domain `IntakeId`. |
| `medicationId` | `text().references(Medications, #id, onDelete: KeyAction.cascade)` | owning med; cascades on delete (no orphans). |
| `slotId` | `text()` | plain text — **no** FK, so slot reconciliation on edit never cascade-deletes intake history. |
| `scheduledAt` | `dateTime()` | UTC instant of the scheduled dose. |
| `confirmedAt` | `dateTime().nullable()` | UTC; set on taken/skipped. |
| `status` | `textEnum<IntakeStatus>()` | stored by name. |
| `notes` | `text().nullable()` | unused this slice. |

**Constraints / indexes**: UNIQUE index on `(medicationId, slotId, scheduledAt)` — one row per occurrence; the mark path upserts on this target.

**Column/enum contract**: same health-data rule as the other tables — never drop/alter a column or rename an enum value without bumping `schemaVersion` + a migration.

## Schema migration
`AppDatabase.schemaVersion`: **1 → 2**.
- `onCreate`: unchanged (`m.createAll()` — now includes `Intakes`).
- `onUpgrade`: `if (from < 2) { await m.createTable(intakes); }` — add-only; no change to existing tables.
- `beforeOpen` FK pragma: unchanged.

## Relationships
- `Intake.medicationId` → `Medication.id` (FK, cascade delete).
- `Intake.slotId` → `TimeSlot.id` (logical reference only; no DB FK).

## Validation / invariants
- Persisted `Intake.status` ∈ `{taken, skipped}` (never `pending`/`missed`).
- `scheduledAt` and `confirmedAt` are always stored UTC (mapper enforces).
- Marking is idempotent per `(medicationId, slotId, scheduledAt)`.
- Undo is permitted only while within `kIntakeUndoGracePeriod` of `confirmedAt` (enforced in the undo use case using the injected clock).
