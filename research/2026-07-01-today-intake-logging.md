# Research: Today Screen & Intake Logging

**Date**: 2026-07-01
**Topic**: Today/intake-logging feature
**Verdict**: Feasible (with one scope decision to make)

## Summary

The "Today" tab is currently a `Hello World` placeholder, yet it's the core daily-use
screen and the missing third pillar of the product vision (*medication → schedule →
**intake** → adherence*). The intake domain is **already authored** in
`constitution.md §5.1/§5.2` — `Intake`, `IntakeStatus`, the state machine, grace period,
intake window, and adherence formula are all specified, they just aren't in code yet. All
the hard day-math (DST-safe course/cyclic-pause resolution) already exists and is reusable.
The main work is (1) a new `intakes` drift table + the project's **first schema
migration**, (2) a pure "expand today's schedule" function, and (3) the checklist UI. The
one real decision is **how much of the full state machine to build now** — recommend a
tightly-scoped MVP slice.

## Codebase Findings

### Existing Related Code (reusable)

| Area | Files | Relevance |
|------|-------|-----------|
| Temporal day-math | `domain/value_objects/course_progress.dart`, `medication_activity.dart` | `CourseProgress.resolve` + `_localDate` already compute active-window/cyclic-pause days DST-safely. Schedule expansion reuses this directly. |
| Domain model | `entities/medication.dart`, `schedule.dart`, `time_slot.dart`, `medication_type.dart` | `Schedule.slots` (minuteOfDay) + `MedicationType` (Continuous/Course) are exactly the inputs needed to derive "what's due today". |
| Persistence pattern | `data/datasources/medication_local_data_source.dart`, `repositories/medication_repository_impl.dart`, `core/database/database.dart` | Full drift + `Either` + `@riverpod` vertical slice to copy. `AppDatabase` is at `schemaVersion=1`. |
| Reactive read + pure VM | `presentation/providers/` (`medicationsListProvider`), `view_models/meds_list_view_model.dart` | Stream provider + pure `buildMedsListView(now:)` with `clock` injection — the template for a `todayView` + `todayProvider`. |
| Host screen | `features/home/presentation/screens/home_screen.dart` | The Today branch of `StatefulShellRoute`; today just renders `Center(Text('Hello World'))`, title hardcoded `'Dosly'`. Ready to fill. |

### Patterns Available

- **Clean vertical slice** (mapper → data source → repo(Either) → use case → provider) is well-worn across 6 features.
- **Pure, clock-injected view-model** keeps schedule expansion unit-testable without pumping widgets.
- **`_localDate` UTC-anchored calendar-day reduction** — copy this exact idiom for the "is a dose due on date X" check (constitution & memory both stress DST correctness for adherence).

### Gaps (to build)

- No `Intake` entity / `IntakeStatus` enum in code yet (specified in constitution, not implemented).
- No `intakes` drift table → requires **schemaVersion 1→2 + first migration file** (`lib/core/database/migrations/`).
- No schedule-expansion function ("today's due doses across all active meds, sorted by time").
- No `MarkIntakeTaken` / `SkipIntake` / undo use cases, repo, or provider.
- Today screen UI (checklist grouped by time; tap-to-take; undo within grace).

## Constitution Constraints (these *help* — the contract is pre-written)

| Rule | Impact |
|------|--------|
| §5.1 `Intake{id, medicationId, slotId, scheduledAt(UTC), confirmedAt?, status, notes?}`; `IntakeStatus{pending,taken,missed,skipped}` | Exact entity shape is given — no modeling debate. |
| §5.2 Schedule resolution | "Today = union of intakes due today across active meds, sorted by time." Course cyclic/pause + derived-end cutoff rules are spelled out. |
| §5.2 Intake state machine | `pending→taken` (`MarkIntakeTaken`), `pending→skipped` (`SkipIntake`), `taken→pending` undo within grace, `pending→missed` auto after window. Use-case names are prescribed. |
| §5.2 Adherence | `skipped` excluded from scheduled; future intakes don't dilute; `scheduledCount==0 → null` ("—"). (History-screen concern — defer.) |
| §2.1 / §2.2 | Domain stays Flutter/drift-free; drift table lives in `core/database/tables/`; migration bump mandatory for health data. |
| Memory: "all UTC, display local" + `Clock` injection | `scheduledAt`/`confirmedAt` stored UTC; all logic clock-injected. |

## Approaches — the one decision that matters: what to persist

### Option A: Lazy materialization (store only user actions) — Recommended

- **Description**: Today screen derives due doses purely from schedules; an `intakes` row is written **only** when the user marks *taken* or *skipped*. "pending" = absence of a row for `(medicationId, slotId, localDate)`.
- **Pros**: No background generation job; no orphan rows when a schedule is edited/deleted; smallest surface; matches "what's persisted is source of truth"; ships the daily value fast.
- **Cons**: `missed` becomes a *derived* state (not stored) for now; adherence `scheduledCount` is computed from schedule expansion, not a row count — a slight divergence from the literal §5.2 state machine (defer/flag).
- **Complexity**: Medium

### Option B: Eager pre-generation (full state machine now)

- **Description**: A job generates `pending` `Intake` rows per day; user actions update them; a sweep transitions `pending→missed` after the window.
- **Pros**: Matches §5.2 literally; `missed` is a real stored state; adherence is a plain row query.
- **Cons**: Needs a generation job **and** a miss-sweep (on app-open + background), dedup/orphan handling on schedule changes, notification wiring pressure — much larger; risky for a first migration.
- **Complexity**: High

**Recommended: Option A.** It delivers the daily-driver screen (see today's doses, tap to
take, skip, undo) with one new table and no background jobs, and leaves
`missed`/adherence/notifications as clean follow-ups. The only thing to confirm in
`/specify` is the "pending & missed are derived, not stored" interpretation of the
constitution's Intake model for this first slice.

## Suggested scope slicing (keep this feature small)

- **This feature (Today MVP)**: expand today's schedule → checklist grouped by time → `MarkIntakeTaken` / `SkipIntake` → persist `Intake` (taken/skipped) → undo within `gracePeriodMinutes`. New `intakes` table + first migration. l10n keys.
- **Follow-up 1 — History/adherence**: daily/weekly ratios per §5.2 (fills the empty History tab).
- **Follow-up 2 — missed + intake window**: auto-transition sweep, `Settings` (grace/window).
- **Follow-up 3 — reminders**: `flutter_local_notifications` + `timezone` + `permission_handler`, boot re-arm, privacy-safe text (its own research — new deps, platform permissions, DST notification matching).

## Complexity Assessment

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Codebase changes | Medium | New vertical slice (copy existing pattern) + Today UI + pure expansion fn. |
| New dependencies | Low/None | MVP slice uses only existing drift/riverpod/clock. (Notifications deps deferred.) |
| Risk | Medium | Concentrated in **the first drift migration** (schemaVersion 1→2) — health data; memory/constitution flag this as high-stakes. Adding a table (not altering columns) is the low-risk kind of migration. |

## Recommendation

**Proceed** — this is the highest-value next feature and unusually well-de-risked because
the domain contract already exists. Scope it to the lazy-materialization MVP.

```
/specify "Today screen: expand each active medication's daily schedule into today's due
doses (reusing the DST-safe course/cyclic-pause day-math), show them as a time-sorted
checklist, and let the user mark each dose taken or skipped with undo inside the grace
period. Persist taken/skipped as Intake rows in a new `intakes` drift table (schemaVersion
1→2, first migration). Pending/missed are derived from the schedule for this slice — no
notifications, no adherence screen, no auto-miss job (those are follow-ups)."
```
