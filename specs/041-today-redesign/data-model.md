# Data Model: Today Screen Redesign

**Note**: This feature persists **nothing new** (`schemaVersion` stays 2; no drift/table change). The "data model" here is the **pure presentation view-model** shape produced by `buildTodayView` and consumed by the widgets. All types live in `lib/features/meds/presentation/view_models/today_view_model.dart` unless noted. Entities (`Medication`, `Intake`, `PackStock`, `IntakeStatus`, `IntakeWindow`, `GracePeriod`, `CourseProgress`, `DueDose`) are **reused unchanged** from specs 032/038/039/040.

## Changed / New Presentation Types

### `TodayView` (CHANGED)
| Field | Type | Description |
|-------|------|-------------|
| `groups` | `List<TodayHourGroup>` | Hour-bucketed groups, ascending by hour. Replaces the flat `doses`. |
| `nextIntake` | `TodayDose?` | The countdown target: soonest dose with `windowState == future` and `status == pending`; `null` ⇒ all-done. |
| `isEmpty` | `bool` (getter) | `true` when no dose is due today (drives `TodayEmptyState`). `groups.isEmpty`. |
| `doses` | `List<TodayDose>` (getter) | **Transitional flattener** (`[for g in groups ...g.doses]`) retained across tasks 005→009 so the screen's interim flat list + grace timer compile unchanged. Task 009 replaces the flat list with `groups`; the getter is dropped then (or kept as a convenience) once no consumer remains. |

### `TodayHourGroup` (NEW)
| Field | Type | Description |
|-------|------|-------------|
| `hour` | `int` (0–23) | The bucket = `slot.minuteOfDay ~/ 60`. |
| `doses` | `List<TodayDose>` | Doses in this hour, preserving `expandDueDoses` ascending order. |
| `state` | `TodayGroupState` | Aggregate window state (see enum). |
| `takenCount` | `int` | Count of `doses` with `status == taken` (badge "✓ N/M"). |
| `total` | `int` (getter) | `doses.length` (badge denominator, count sub-label). |
| `hasActionablePending` | `bool` (getter) | `true` when any dose is `status == pending && actionable` (gates the Mark-all button). |

### `TodayGroupState` (NEW enum)
| Value | Rule (over all doses in the group) | Badge |
|-------|-------------------------------------|-------|
| `future` | every dose `windowState == future` | localized "Future", neutral |
| `past` | every dose `windowState == pastWindow` | "✓ {takenCount}/{total}", neutral |
| `now` | otherwise (≥1 dose `open`, or mixed) | localized "Now", primary + left-border accent |

### `DoseWindowState` (NEW enum) — time-only, status-independent
| Value | Rule (UTC; `windowClose = scheduledAt + intakeWindow.minutes`) |
|-------|------|
| `future` | `now < scheduledAt` (window not yet open) |
| `open` | `scheduledAt <= now <= windowClose` (inclusive both ends) |
| `pastWindow` | `now > windowClose` (lapsed; dovetails with spec 040's strict `>` missed rule) |

### `TodayDose` (CHANGED — additive)
Existing fields kept: `dose: DueDose`, `status: IntakeStatus`, `confirmedAt: DateTime?`, `undoable: bool`, `intakeId: IntakeId?`.

| New field | Type | Description |
|-----------|------|-------------|
| `windowState` | `DoseWindowState` | Time classification (feeds group state + countdown target). Computed for every dose regardless of `status`. |
| `actionable` | `bool` | For a `pending` dose: is the checkbox + skip icon interactive **now**? `false` for non-pending. Encodes §3.5 matrix: `open` ⇒ true; `future` ⇒ `allowMarkAhead`; `pastWindow` ⇒ false. |

Derived-by-widget (not stored): `checked = status == taken`; skip-icon shown `= status == pending && actionable`; checkbox enabled `= (status == pending && actionable) || ((status == taken || status == skipped) && undoable)`.

## Inputs to `buildTodayView` (CHANGED signature)

| Param | Type | Source |
|-------|------|--------|
| `meds` | `List<Medication>` | `medicationsListProvider` (unchanged) |
| `intakes` | `List<Intake>` | `intakesListProvider` (unchanged) |
| `now` | `DateTime` | `clock.now()` (unchanged) |
| `intakeWindow` | `IntakeWindow` | **NEW** — from settings projection |
| `gracePeriod` | `Duration` | **NEW** — from settings projection (`GracePeriod.minutes` → `Duration`) |
| `allowMarkAhead` | `bool` | **NEW** — from settings projection |

## Validation / Invariants
- A `TodayHourGroup` always has ≥1 dose (empty buckets are never emitted).
- `takenCount <= total`.
- Groups are ordered ascending by `hour`; within a group, doses keep `expandDueDoses` order.
- `nextIntake`, when non-null, satisfies `windowState == future && status == pending` and has the minimum `scheduledAt` among such doses.
- All window/grace comparisons are performed in **UTC**; times render in **local**.
