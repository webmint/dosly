# Spec: Today Screen — Daily Intake Checklist

**Date**: 2026-07-01
**Status**: Complete
**Author**: Claude + Mykola

## 1. Overview

Turn the placeholder **Today** tab (currently `Center(Text('Hello World'))`) into the app's daily-driver screen: a time-sorted checklist of every dose due today, derived by expanding each active medication's daily schedule. The user can mark each dose **taken** or **skipped**, and undo that action within a 5-minute grace window. Taken/skipped actions are persisted as `Intake` rows in a **new `intakes` drift table** (schemaVersion 1 → 2, the project's first migration). This is the **intake** pillar of the product vision (*medication → schedule → intake → adherence*); adherence/History, reminders, and auto-miss are explicit follow-ups.

This slice uses **lazy materialization**: an `Intake` row exists only once the user acts on a dose. A dose with no row is **pending** (derived). `missed` is not modeled in this slice.

## 2. Current State

### The Today screen (host)
`lib/features/home/presentation/screens/home_screen.dart` is a `StatelessWidget` (`HomeScreen`) mounted at `/` as branch 0 of the `StatefulShellRoute.indexedStack` (`lib/core/routing/app_router.dart`; the bottom nav labels it "Today" via `bottomNavToday`). It renders a `Scaffold` with an `AppBar` (hardcoded brand title `Text('Dosly')`, a settings-gear `IconButton` → `/settings`, a 1-px `outlineVariant` bottom `Divider`) and a body of `Center(child: Text('Hello World'))`. The bottom nav is supplied by the shell, not this screen.

### The medication domain & persistence (fully built — the pattern to mirror)
The meds feature (features 026–037) is a complete Clean-Architecture vertical slice under `lib/features/meds/`:

- **Domain entities** (pure Dart, no Flutter/drift): `Medication` (`entities/medication.dart` — `id, name, form, type, schedule, dosePerIntake?, stock?, notes?, createdAt`), `Schedule` (`frequency` defaults `daily`, `slots: List<TimeSlot>`), `TimeSlot` (`id`, `minuteOfDay` 0..1439 local wall-clock, `doseOverride?`), `MedicationType` (sealed `ContinuousType{startDate}` | `CourseType{startDate, durationDays, pauseDays}`; `pauseDays>0` ⇒ cyclic), `Dosage` (`amount` + `unit`), `MedicationForm` (8-value enum).
- **DST-safe day-math (reusable)**: `domain/value_objects/course_progress.dart` (`CourseProgress.resolve({course, now})` → cycle day + `CoursePhase.activeWindow`/`paused`) and `domain/value_objects/medication_activity.dart` (`resolveMedicationActivity(med, now)` → `active`/`completed`). Both reduce dates via a `_localDate(d)` helper that anchors the LOCAL calendar day to a UTC-midnight `DateTime` so `.inDays` counts whole calendar days without DST drift. This is the exact idiom to reuse for "is a dose due on date X".
- **Repository contract**: `domain/repositories/medication_repository.dart` — `add` / `update` / `watchAll()` (`Stream<Either<Failure, List<Medication>>>`) / `delete`, every fallible op returns `Either<Failure, T>` (constitution §3.2).
- **Data layer**: `data/datasources/medication_local_data_source.dart` (drift queries, incl. reactive `watchAllMedications()`), `data/mappers/medication_mapper.dart` (row ⇆ domain), `data/repositories/medication_repository_impl.dart` (maps to `Either`).
- **Presentation**: `presentation/providers/medication_providers.dart` (`@riverpod` — incl. the stream `medicationsListProvider` that maps `Left→throw`, `Right→value` into an `AsyncValue`), pure view-model `presentation/view_models/meds_list_view_model.dart` (`buildMedsListView({meds, now, filter, query})`, clock-injected via `clock.now()` at the call site), widgets `MedicationTile` / `MedicationSection`, `medicationFormIcon(form)` shared resolver.

### The database
`lib/core/database/database.dart` — `AppDatabase` `@DriftDatabase(tables: [Medications, TimeSlots])`, **`schemaVersion => 1`**, `MigrationStrategy(onCreate: createAll, beforeOpen: FK-pragma ON)`. **No `onUpgrade` exists yet** — this feature introduces the first one. Table defs live in `lib/core/database/tables/` (`medications_table.dart`, `time_slots_table.dart`), which document the health-data schema/column contract. `TimeSlots.medicationId` has `onDelete: cascade`.

### Localization
`lib/l10n/` ARB files (`app_en.arb`, `app_de.arb`, `app_uk.arb`) + generated `AppLocalizations`; strings read via `context.l10n.*` (`l10n_extensions.dart`). `bottomNavToday` ("Today") exists as the nav label. `@`-descriptions live in `app_en.arb`. 24-hour time is enforced project-wide via `MaterialLocalizations.formatTimeOfDay(t, alwaysUse24HourFormat: true)` (see meds intake-time chips).

### Constitution contract (already authored — this spec implements it)
`constitution.md §5.1/§5.2` pre-define the entities and rules:
- **`Intake`** = `{id, medicationId, slotId, scheduledAt (UTC), confirmedAt? (UTC), status, notes?}`; **`IntakeStatus`** = `{pending, taken, missed, skipped}`.
- **Schedule resolution**: "today's schedule" = union of all intakes due today across active meds, sorted by time; `Course` intakes not generated past derived end / during pause gaps; `Continuous` generated indefinitely.
- **State machine**: `pending→taken` (`MarkIntakeTaken`), `pending→skipped` (`SkipIntake`), `taken→pending` undo within `gracePeriodMinutes` (default **5**).
- **Time zones**: `scheduledAt`/`confirmedAt` stored UTC, displayed local; DST handled by local-calendar-day math.
- Relevant MEMORY.md: all timestamps UTC / display local; `Clock` injection over `DateTime.now()`; drift schema changes require bumped `schemaVersion` + migration (health data).

## 3. Desired Behavior

### 3.1 Schedule expansion (pure domain)
A new pure, clock-free function expands medications into the day's due doses for a given local calendar `date`:
- For each medication, decide whether it is **due on `date`**:
  - `ContinuousType`: due on every date `>= startDate` (local calendar). A future `startDate` ⇒ not due.
  - `CourseType`: due only on days inside an **active window** — reuse `CourseProgress.resolve` (`CoursePhase.activeWindow` ⇒ due, `paused` ⇒ not due) AND `resolveMedicationActivity` (`completed` ⇒ not due), AND guard `date < startDate` ⇒ not due.
- Each due medication contributes **one dose per `TimeSlot`** in its `schedule.slots`.
- Each expanded dose carries: the medication, the slot (id + `minuteOfDay`), the effective `Dosage` (slot `doseOverride` if present, else `dosePerIntake`), and the dose's **`scheduledAt`** (today's local date at `minuteOfDay`, expressed in UTC).
- Output is sorted **ascending by `minuteOfDay`**, ties broken by medication name (case-insensitive), then a stable id tiebreak.

### 3.2 Persistence — new `intakes` table & lazy model
- Add a new drift table storing `Intake` rows. Only **user-confirmed** rows are ever written; stored `status` is always `taken` or `skipped` in this slice (`pending`/`missed` are never persisted). Columns cover the §5.1 `Intake` fields; `notes` is unused (null) this slice.
- A dose occurrence is uniquely identified by **(medicationId, slotId, scheduled calendar date)**. Marking is **idempotent/upsert**: re-marking the same occurrence updates the existing row (e.g. taken→skipped) rather than inserting a duplicate.
- Bump `AppDatabase.schemaVersion` **1 → 2** and add an `onUpgrade` migration that creates the new table (and only that — no changes to existing tables). `onCreate` continues to create all tables for fresh installs. The FK `beforeOpen` pragma is preserved.
- `Intake` rows reference a medication; deleting a medication must not leave the app in an inconsistent state (FK / cleanup behavior defined in `/plan`).

### 3.3 Today screen UI
`HomeScreen` renders the day's checklist:
- **AppBar**: keep the settings-gear action and 1-px divider; the title becomes the localized **"Today"** (new `todayTitle` key) instead of the hardcoded brand. A header shows **today's date** (localized, via `MaterialLocalizations`).
- **Body — reactive checklist**: a live list (updates on any medication or intake change) of today's doses, **flat, time-sorted ascending**. Each dose row shows: the medication-form icon (`medicationFormIcon`), the medication name, the scheduled time (`HH:mm`, 24-hour), and the effective dose amount when present. Each row exposes an affordance to mark **taken** and to **skip**.
- **Derived status per dose** (from stored intakes + `clock.now()`):
  - **pending** (no stored row): shows the take/skip affordances.
  - **taken** / **skipped**: shows the resolved state; if within the grace window, shows an **Undo** affordance.
- **Marking**: tapping "taken" invokes the mark-taken use case; "skip" invokes the skip use case. Both write/update an `Intake` (status + `confirmedAt = clock.now()` UTC). Because the list is reactive, the row reflects the new state without manual refresh.
- **Early marking allowed**: any of today's doses is markable regardless of whether its scheduled time has passed.
- **No overdue cue**: a past-scheduled pending dose looks identical to an upcoming one (no "missed"/overdue styling in this slice).
- **Empty state**: when no doses are due today (no meds, or all completed/paused), show a centered empty-state card (localized title + body), consistent with the meds-list empty state.
- **Loading / error**: while the reactive source loads, show a progress indicator; on stream error, show muted centered error text (mirrors `medicationsListProvider.when(...)`).

### 3.4 Undo & grace period
- After a dose is marked taken **or** skipped, an **Undo** affordance is available for **`kGracePeriodMinutes` = 5** minutes (a hardcoded default matching constitution §5.2; adjustable Settings arrives in a follow-up).
- Undo returns the dose to **pending** by **deleting** its stored `Intake` row.
- Grace state is derived from `confirmedAt` vs `clock.now()`. The screen **refreshes grace state periodically** so the Undo affordance disappears when the window elapses without requiring a manual interaction or restart.
- Once the grace window has elapsed, the dose is **locked** for this slice: its taken/skipped state is displayed but cannot be undone or changed (the explicit manual-correction flow is a follow-up). Attempting to undo after expiry is a no-op.

### 3.5 Use cases (domain)
Introduce use cases mirroring the meds feature and constitution naming: **`MarkIntakeTaken`**, **`SkipIntake`**, and an **undo** operation (`taken/skipped → pending`, i.e. delete the row, gated by the grace window). Each is a single-purpose class delegating to a new `IntakeRepository` and returning `Either<Failure, T>`.

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Domain entity | `lib/features/meds/domain/entities/intake.dart`, `intake_status.dart` | **Create** `Intake` (freezed) + `IntakeStatus` enum (`pending, taken, missed, skipped`; storage-by-name contract). |
| Domain value object | `lib/features/meds/domain/value_objects/intake_id.dart` | **Create** typed `IntakeId`. |
| Domain — schedule expansion | `lib/features/meds/domain/value_objects/` (e.g. `due_dose.dart` + expansion fn) | **Create** pure "doses due on date X" expansion, reusing `CourseProgress`/`resolveMedicationActivity`/`_localDate`. |
| Domain repository | `lib/features/meds/domain/repositories/intake_repository.dart` | **Create** contract: reactive read of intakes + mark-taken / skip / undo, all `Either`. |
| Domain use cases | `lib/features/meds/domain/usecases/mark_intake_taken.dart`, `skip_intake.dart`, `undo_intake.dart` | **Create** three single-purpose use cases. |
| DB table | `lib/core/database/tables/intakes_table.dart` | **Create** `Intakes` drift table (§5.1 fields; health-data column/enum contract docs). |
| DB schema + migration | `lib/core/database/database.dart` | **Modify**: register `Intakes`, bump `schemaVersion` 1→2, add `onUpgrade` creating the new table; preserve `onCreate` + FK `beforeOpen`. |
| Data layer | `lib/features/meds/data/datasources/intake_local_data_source.dart`, `data/mappers/intake_mapper.dart`, `data/repositories/intake_repository_impl.dart` | **Create** data source (reactive query + upsert/delete), mapper (row⇆domain, UTC storage), repo impl (→ `Either`). |
| Presentation providers | `lib/features/meds/presentation/providers/` (extend `medication_providers.dart` or new `intake_providers.dart`) | **Create** `@riverpod` intake repo/use-case providers + a reactive `todayProvider` combining meds + intakes into the Today view. |
| Presentation view-model | `lib/features/meds/presentation/view_models/today_view_model.dart` | **Create** pure `buildTodayView({meds, intakes, now})` → time-sorted dose items with derived status + grace flag. |
| Presentation UI | `lib/features/home/presentation/screens/home_screen.dart` + new widgets under `home/presentation/widgets/` (or `meds/presentation/widgets/`) | **Modify** `HomeScreen` (title, date header, reactive body); **create** the dose-row / checklist widgets and empty state. |
| Localization | `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` (+ regenerated `AppLocalizations`) | **Modify**: add Today keys (title, date/section chrome, taken/skip/undo labels, taken/skipped status labels, empty-state title+body, any snackbars). |
| Grace constant | e.g. `lib/features/meds/domain/` or `lib/core/` | **Create** `kGracePeriodMinutes = 5`. |
| Tests | `test/` mirrors of the above; optionally an `integration_test/` today flow | **Create** unit tests (expansion edge cases, view-model status/grace derivation, mapper UTC round-trip, migration 1→2), widget tests (mark/skip/undo/empty/lock). |

## 5. Acceptance Criteria

**Schedule expansion**
- [x] **AC-1**: A `ContinuousType` medication with `startDate <= today` contributes one dose per `TimeSlot` to today's list; a continuous med with a future `startDate` contributes none.
- [x] **AC-2**: A non-cyclic `CourseType` medication contributes doses only on dates within `[startDate, startDate + durationDays − 1]` (inclusive, local calendar); it contributes none once completed and none before `startDate`.
- [x] **AC-3**: A cyclic `CourseType` (`pauseDays > 0`) contributes doses on active-window days and **none** on pause-gap days, repeating across cycles — consistent with `CourseProgress.resolve`.
- [x] **AC-4**: Expanded doses are sorted ascending by `minuteOfDay`; a dose's effective dose is the slot `doseOverride` when present, else the medication's `dosePerIntake`. Day boundaries are computed with the DST-safe local-calendar-day idiom (no off-by-one across a DST transition).

**Persistence & migration**
- [x] **AC-5**: A new `intakes` drift table exists; `AppDatabase.schemaVersion == 2`; an `onUpgrade` from v1 creates the `intakes` table and makes **no** change to `medications`/`time_slots`; a fresh install (`onCreate`) creates all three tables. FK pragma still enabled per connection.
- [x] **AC-6**: Marking a dose writes exactly one `Intake` row keyed by (medicationId, slotId, scheduled calendar date) with `status ∈ {taken, skipped}` and `confirmedAt` set (UTC). Re-marking the same occurrence **updates** that row (no duplicate). `scheduledAt`/`confirmedAt` round-trip through the mapper as UTC.
- [x] **AC-7**: Existing v1 data (medications + time slots) is preserved intact after the 1→2 upgrade (verified by opening a v1-shaped DB and reading rows back unchanged).

**Today screen behavior**
- [x] **AC-8**: The Today screen shows a flat, time-sorted checklist of today's doses; each row shows form icon, medication name, `HH:mm` (24-hour) time, and dose amount when present.
- [x] **AC-9**: Tapping "taken" marks the dose taken and "skip" marks it skipped; the row reactively reflects the new state (taken/skipped) without a manual refresh, and the change survives a screen rebuild (read back from the DB).
- [x] **AC-10**: A dose whose scheduled time is later today is still markable now (early marking); a past-scheduled pending dose renders identically to an upcoming pending dose (no overdue styling).
- [x] **AC-11**: When no doses are due today, a localized empty-state card is shown (not an empty list); while the reactive source is loading, a progress indicator shows; on stream error, muted error text shows.

**Undo & grace**
- [x] **AC-12**: Immediately after marking taken **or** skipped, an Undo affordance is shown; using it deletes the stored `Intake` row and returns the dose to pending.
- [x] **AC-13**: Undo is available only while `clock.now() − confirmedAt <= kGracePeriodMinutes` (5). The affordance is gated on this window (evaluated with the injected clock) and disappears when the window elapses (screen refreshes grace state periodically). Attempting undo after expiry is a no-op; the taken/skipped state is then locked.

**Localization & quality**
- [x] **AC-14**: All new user-facing strings (Today title, date/chrome, taken/skip/undo, status labels, empty state) exist in `app_en.arb` (with `@`-descriptions), `app_de.arb`, and `app_uk.arb`, and are consumed only via `context.l10n.*`.
- [x] **AC-15**: `dart analyze` passes with no new issues; domain files add no Flutter/drift imports; every fallible operation returns `Either<Failure, T>`; new public APIs carry dartdoc. Unit + widget tests cover the ACs above and `flutter test` is green.

## 6. Out of Scope

- **NOT included**: reminders / local notifications (`flutter_local_notifications`, `timezone`, permissions) — separate future feature.
- **NOT included**: the History / adherence screen and any adherence ratio computation/aggregation (`AdherenceRecord`).
- **NOT included**: automatic `pending → missed` transition, the intake window, and any background/on-open sweep job.
- **NOT included**: a Settings UI for `gracePeriodMinutes` / `intakeWindowMinutes` (a hardcoded 5-min default is used); the `Settings` entity from §5.1.
- **NOT included**: the post-grace "Manual Correction" audit-logged edit flow.
- **NOT included**: decrementing `PackStock` / low-stock alerts when a dose is taken.
- **NOT included**: `notes` on intakes, editing a dose's time from the Today screen, per-dose history, or weekly/other schedule frequencies (schedule stays `daily`).
- **NOT included**: showing future days / a calendar; only **today** is rendered.

## 7. Technical Constraints

- **Must follow** Clean Architecture layer boundaries (constitution §2.1): domain stays pure Dart (no Flutter, drift, or uuid imports); drift lives in `core/database` + the data layer.
- **Must mirror** the established meds vertical-slice pattern (entity/value-object → repository contract → use case → data source/mapper/repo-impl → `@riverpod` provider → pure view-model → widget), and the reactive stream-provider + `Either` (`Left→throw` in the stream provider) idiom.
- **Must reuse** the existing DST-safe local-calendar-day math (`_localDate` idiom, `CourseProgress`, `resolveMedicationActivity`) rather than re-deriving day boundaries.
- **Must** bump `schemaVersion` and add a migration for the schema change (constitution §4.2.1/§6.5); **must not** drop or alter existing columns. This is health data.
- **Must** store all timestamps in UTC and display in local; **must** inject `Clock` (`clock.now()`) rather than call `DateTime.now()`.
- **Must not** break the existing meds list, add/edit/delete flows, routing shell, or the settings navigation from the Today AppBar.
- **Must** enforce 24-hour time display via `MaterialLocalizations.formatTimeOfDay(..., alwaysUse24HourFormat: true)`.

## 8. Open Questions

- **Provider composition**: whether `todayProvider` combines the existing `medicationsListProvider` with a new intakes stream, or a dedicated joined data-source query is added. (Decided in `/plan`; both satisfy the ACs.)
- **Intake table shape**: whether to store a full `scheduledAt` instant plus a derived date key, or a date-only column, to back the (med, slot, date) uniqueness/upsert. (Decided in `/plan`.)
- **Grace-refresh mechanism**: periodic ticker vs. a stream that re-emits — exact mechanism deferred to `/plan`; AC-13 only requires that the affordance disappears on expiry.
- **Delete-medication interaction**: whether stored intakes are cleaned up (FK cascade) or intentionally retained when a medication is deleted. Retention has no effect on this slice's Today view (deleted meds aren't expanded); resolved in `/plan`.
- **Widget placement**: whether the new dose-row/checklist widgets live under `home/presentation/widgets/` or `meds/presentation/widgets/`, given the domain lives in `features/meds/`. (Cosmetic; `/plan`.)

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| First drift migration (1→2) mishandled — data loss on upgrade | Medium | High | Add-only migration (new table, no column changes); test upgrade from a v1-shaped DB reading old rows back (AC-7); follow the health-data schema contract. |
| Off-by-one in "due today" across DST / future-start / pause-gap edges | Medium | Medium | Reuse the proven `_localDate`/`CourseProgress`/`resolveMedicationActivity` logic; cover edge cases with clock-injected unit tests (AC-1..4). |
| Lazy model diverges from constitution's literal `pending`/`missed` stored states | Medium | Low | Documented, deliberate MVP interpretation: `pending`/`missed` are derived; the full `IntakeStatus` enum is retained so no rename/migration is needed when auto-miss/adherence land. |
| Grace-window UI drift (affordance lingers/vanishes at wrong time) | Medium | Low | Derive grace from `confirmedAt` vs injected clock; periodic refresh; undo re-checks the window at tap time (no-op if expired) — AC-13. |
| Scope creep toward adherence/notifications/stock | Medium | Medium | Explicit, exhaustive §6 Out of Scope; ACs bound to the checklist + lazy intake log only. |
