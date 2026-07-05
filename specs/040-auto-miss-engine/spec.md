# Spec: Auto-Miss Engine for Intakes

**Date**: 2026-07-04
**Status**: Complete
**Author**: Claude + Mykola

## 1. Overview

Add the **auto-miss engine** that closes the gap left by the lazy-intake model shipped in spec 038: a pending due dose whose intake window has elapsed should become `missed`, not linger as `pending` forever. A new pure derivation plus a `ReconcileMissedIntakes` use case scans today's due doses, and for every one whose window has closed (`now > scheduledAt + intakeWindowMinutes`, reading the `intakeWindow` setting shipped in spec 039) **and that has no stored intake row yet**, writes a `missed` `Intake` row. Reconciliation is triggered on app open (`AppBootstrap`) and on Today-screen load. Finally, `IntakeStatus.missed` — which today renders `SizedBox.shrink()` — gets a real, display-only "Missed" tile.

This is **Spec B** of the three-spec Today-redesign chain (`research/2026-07-03-today-hourly-grouping-full-fidelity.md`): Spec A (039 intake-behavior settings) shipped the `intakeWindow` knob this engine consumes; Spec C (the Today hourly-grouping redesign) is out of scope here. It implements the constitution §5.2 rule "`pending → missed` automatically when `now > scheduledAt + intakeWindowMinutes` (background job + on next app open)" — delivering the **on-app-open** trigger; true OS-level background execution while the app is closed is a separate notifications-infra spec.

## 2. Current State

### The lazy-intake model & the reserved `missed` state (spec 038 — the foundation)
`lib/features/meds/` holds a complete intake vertical slice, deliberately **lazy**: an `Intake` row exists only once the user acts on a dose. A dose with no row is **pending** (derived, never stored). Today only `taken` and `skipped` are ever persisted; **`missed` is a reserved `IntakeStatus` value that nothing produces yet** (`intake_status.dart` dartdoc: "reserved for a later feature (the window-expiry auto-transition described in §5.2)").

- **Entities**: `Intake` (`entities/intake.dart` — `id, medicationId, slotId, scheduledAt (UTC), confirmedAt? (UTC), status, notes?`), `IntakeStatus` (`entities/intake_status.dart` — enum `pending, taken, missed, skipped`; **storage-by-name** `textEnum` contract — reordering is harmless, renaming/removing needs a migration).
- **Schedule expansion** (pure, single-day): `expandDueDoses({meds, now})` in `domain/value_objects/due_dose.dart` → the flat, time-sorted `List<DueDose>` due on the **local calendar day** of `now`. Each `DueDose` carries `medication`, `slot`, `effectiveDose`, and a `scheduledAt` **UTC** instant (today's local date at `slot.minuteOfDay`, converted to UTC). "Due today" reuses the DST-safe `localCalendarDate` idiom + `CourseProgress.resolve` + `resolveMedicationActivity` (excludes future starts, completed courses, cyclic pause-gap days). **This is single-day only** — it expands exactly `now`'s local calendar day.
- **View model** (pure): `buildTodayView({meds, intakes, now})` in `presentation/view_models/today_view_model.dart` → `TodayView(doses: List<TodayDose>)`. Indexes stored intakes once into a map keyed `(medicationId, slotId, localCalendarDate(scheduledAt))`, then resolves each due dose's `status` (`pending` when unmatched), `confirmedAt`, `intakeId`, and `undoable` (grace-window) flag. Derives `missed` NOWHERE today — a past-window pending dose resolves to `pending` and renders identically to an upcoming one (no overdue styling, spec 038 §3.3).
- **Repository contract**: `domain/repositories/intake_repository.dart` — `watchAll()` (`Stream<Either<Failure, List<Intake>>>`), `markTaken(Intake)`, `skip(Intake)`, `undo(IntakeId)`. **There is no snapshot read and no "write a missed row" method.** All reads today are the reactive stream; all writes are user-confirmed `taken`/`skipped` upserts.
- **Data layer**: `data/datasources/intake_local_data_source.dart` — `watchAllIntakes()` plus `upsertIntake(IntakesCompanion)` (upsert keyed on the occurrence unique index `{medicationId, slotId, scheduledAt}` — **NOT** the PK `id`, so re-marking an occurrence updates in place) and `deleteIntake(id)`. `data/mappers/intake_mapper.dart` (`intakeToCompanion` / `intakeFromRow`, UTC normalization). `data/repositories/intake_repository_impl.dart` (catches every exception → `Left(CacheFailure)`).
- **Providers** (composition seam): `presentation/providers/intake_providers.dart` — `intakeLocalDataSourceProvider`, `intakeRepositoryProvider`, use-case providers (`markIntakeTakenProvider`, `skipIntakeProvider`, `undoIntakeProvider`), and the reactive `intakesListProvider` (`Stream<List<Intake>>`, `Left→throw`). ID minting via `core/id/id_generator_provider.dart` (`idGeneratorProvider`).

### The Today screen & the `missed` tile stub
`presentation/screens/today_screen.dart` (`TodayScreen`, a `ConsumerStatefulWidget` mounted at `/`) watches `medicationsListProvider` + `intakesListProvider`, shapes them via `buildTodayView(... now: clock.now())`, and renders a flat `ListView.builder` of `TodayDoseTile`s (plus a one-shot grace-refresh `Timer`). `presentation/widgets/today_dose_tile.dart` `_Actions` does an **exhaustive `switch` over `IntakeStatus`** (no `default:`): `pending` → Skip/Take buttons; `taken`/`skipped` → status label + optional Undo; **`IntakeStatus.missed => const SizedBox.shrink()`** (line ~216, with a comment "Reserved for a later feature … Render nothing rather than inventing an unlocalized label"). This is the render this spec replaces.

### The intake-window setting (spec 039 — shipped, not yet consumed)
`lib/features/settings/`: `AppSettings` (freezed, `entities/app_settings.dart`) now carries `intakeWindow: IntakeWindow` (default `IntakeWindow.defaultValue` = 120), plus `gracePeriod` and `allowMarkAhead`. `IntakeWindow` (`domain/value_objects/intake_window.dart`) is a pure, self-clamping VO (`minutes` clamped to [15, 240]) with a `const` default. `settingsNotifierProvider` (`@Riverpod(keepAlive: true, name: 'settingsNotifierProvider')`) holds `AppSettings` **synchronously** (seeded from `repo.load().fold(default, id)` against the resolved `SharedPreferencesWithCache`). Spec 039 shipped this as **foundation only — nothing reads `intakeWindow` yet**; this spec is its first consumer.

### App startup (`AppBootstrap`) — the on-open trigger site
`lib/app_bootstrap.dart` — on the `data:` branch (prefs resolved) it mounts `DoslyApp` and, in `kDebugMode` only, fires the demo seeder fire-and-forget (`ref.read(devSeedProvider)`). By this branch the synchronous `sharedPreferencesProvider` (and thus `settingsNotifierProvider`) and the lazy `appDatabaseProvider` are serviceable. This is where the on-app-open reconcile trigger belongs.

### The database & migration posture
`lib/core/database/database.dart` — `@DriftDatabase(tables: [Medications, TimeSlots, Intakes])`, `schemaVersion => 2`, add-only v1→v2 `onUpgrade` (created the `intakes` table). The `intakes` table (`core/database/tables/intakes_table.dart`) already stores all four `IntakeStatus` values by name and has the `{medicationId, slotId, scheduledAt}` unique key. **Writing `missed` rows needs NO schema change** — the column and enum contract already accommodate it.

### Constitution contract (already authored — this spec implements it)
- **§5.2 state machine**: "`pending → missed` automatically when `now > scheduledAt + intakeWindowMinutes` (background job + on next app open)." `skipped` is **only** an explicit user action; `missed` (lapsed) and `skipped` (deliberate) are **distinct** — a future adherence calc treats them differently. After the window, a `taken`/`missed` intake is editable **only** via the separate audit-logged "Manual Correction" flow.
- **§5.2 intake window**: default 120, adjustable in Settings (range 15–240). Window closes at `scheduledAt + intakeWindowMinutes` (`notificationLeadMinutes` = 0, not built).

### Relevant MEMORY.md lessons
- **Interface-change blast radius** (Feature 037/039): adding a method to a repository interface breaks every hand-written `implements` fake; per-task changed-file `dart analyze` misses them. Enumerate all implementers and run **project-wide** `dart analyze`. Confirmed implementers below.
- **`AppBootstrap` side-effects poison integration tests** (Feature 035): `devSeedProvider` fires from `AppBootstrap`, runs in `kDebugMode`, and pre-populated the DB — breaking golden-flow row-count assertions until the harness overrode it with a no-op. **Any new `AppBootstrap` side-effect (including this reconcile trigger) must be neutralizable in `integration_test/support/app_harness.dart`**, or it will pollute the golden flows.
- **Never let an upsert clobber user data** (Feature 036 cascade lessons): the occurrence upsert overwrites in place. Auto-miss must therefore write `missed` **only for occurrences with no existing row**, never over a `taken`/`skipped` (or already-`missed`) row.
- **Clock injection over `DateTime.now()`**; **all timestamps UTC, displayed local**.

## 3. Desired Behavior

### 3.1 Pure derivation — which occurrences become `missed`
A new pure, clock-free derivation (mirroring `expandDueDoses` / `buildTodayView`) computes the set of dose occurrences that must be auto-missed as of `now`, given the day's medications, the stored intakes, and the intake window:

- Start from `expandDueDoses({meds, now})` — today's due doses (single local calendar day; the confirmed scope).
- An occurrence is **auto-miss-eligible** when ALL hold:
  1. Its window has **closed**: `now > dose.scheduledAt + intakeWindow.minutes` (strict inequality; compared in UTC; exactly-at-the-boundary is **not** yet missed).
  2. It has **no stored `Intake` row** for that occurrence — matched by `(medicationId, slotId, localCalendarDate(scheduledAt))`, the same local-calendar-date match `buildTodayView` uses (not raw-instant equality). Any existing row — `taken`, `skipped`, or already `missed` — makes the occurrence ineligible.
- The derivation returns enough per occurrence (medication id, slot id, scheduled UTC instant) for the use case to build a `missed` `Intake`. ID minting and persistence stay outside the pure layer (mirrors how `expandDueDoses` stays free of `IdGenerator`).
- Determinism: the eligible occurrences preserve `expandDueDoses`' ascending order (not user-visible, but keeps tests stable).

### 3.2 Use case — `ReconcileMissedIntakes`
A new domain use case `ReconcileMissedIntakes` (`domain/usecases/reconcile_missed_intakes.dart`), one operation per class (constitution §2.1), returning `Future<Either<Failure, T>>`:

- Obtains a **point-in-time snapshot** of today's medications and the stored intakes, applies the §3.1 derivation for the supplied `intakeWindow` and `now`, mints a fresh `IntakeId` per eligible occurrence, and writes each as a `missed` `Intake` (`confirmedAt` = `null` — a missed dose was never confirmed; `notes` = `null`).
- **Idempotent**: running it repeatedly writes nothing new once every eligible occurrence has a row (each already-written `missed` row makes its occurrence ineligible on the next run). It never overwrites or deletes an existing row.
- **Never clobbers user intent**: because eligibility excludes any occurrence that already has a row, a `taken`/`skipped` dose is never converted to `missed`, even if its window has since closed.
- Returns the result on both paths (e.g. the count of rows written, or `Unit`) as `Either<Failure, T>`; any storage failure surfaces as `Left(Failure)` and is swallowed by neither the use case nor its callers (the triggers log/ignore rather than crash — see §3.4).
- The `intakeWindow` and `now` are inputs to the operation (the caller supplies the current `AppSettings.intakeWindow` and `clock.now()`), keeping the use case unit-testable with a fixed clock and window. Whether the medication/intake snapshots come from a new repository snapshot read or from the existing `watchAll()` stream's first emission is a `/plan` decision (see Open Questions).

### 3.3 Persisting a `missed` intake (repository/data surface)
The `IntakeRepository` contract gains a single operation to persist an auto-generated `missed` occurrence (e.g. `markMissed(Intake)` — exact name in `/plan`), implemented in `IntakeRepositoryImpl` by reusing the existing `upsertIntake` path and mapper, and catching exceptions into `Left(CacheFailure)`. No new drift table, column, or `schemaVersion` bump — the `intakes` table and `IntakeStatus` `textEnum` already store `missed` by name. Adding this method is an **interface change** with the blast radius enumerated in §4.

### 3.4 Triggers — on app open and on Today-screen load
Reconciliation runs at exactly two points (the "on next app open" trigger the constitution names, applied to both cold start and the daily-driver screen):

- **On app open** (`AppBootstrap`, `data:` branch): fire-and-forget, **non-blocking** (never awaited on the startup path — mirrors the `devSeedProvider` idiom), reading the current `intakeWindow` from `settingsNotifierProvider` and `now` from `clock.now()`. A failure is logged/ignored, never surfaced as a startup error. Because the reconcile writes rows through the same store, `intakesListProvider` re-emits and any open UI updates reactively.
- **On Today-screen load**: reconciliation runs **once when the screen is opened** (e.g. a fire-and-forget in `initState`/first build), **not on every rebuild** — the write → stream re-emit → rebuild cycle must not re-trigger a reconcile loop (already-missed occurrences are ineligible, so at worst it converges, but it must not busy-loop). A failure shows nothing intrusive (at most the existing generic error affordance); the checklist simply doesn't gain `missed` rows.
- **No live in-place transition** (confirmed scope): a dose whose window closes while the Today screen sits idle does **not** flip to `missed` until the next screen load or app open. No new window-expiry `Timer` is added in this slice (that is Spec C's concern).
- Both triggers must be **safe to run with an empty/opening database** and before any medication exists (no meds ⇒ no due doses ⇒ nothing written).

### 3.5 `IntakeStatus.missed` tile rendering (Today screen)
Replace `today_dose_tile.dart`'s `IntakeStatus.missed => const SizedBox.shrink()` branch with a **display-only** rendering (confirmed scope):

- Shows a localized **"Missed"** status label (new ARB key, e.g. `todayStatusMissed`), visually distinct and error-toned (e.g. `colorScheme.error`), consistent with the tile's existing `_ConfirmedActions` label treatment but carrying **no actions** — no Take, no Skip, no Undo.
- A missed dose is therefore **locked** in this slice: correcting it (missed → taken) is the constitution's separate audit-logged "Manual Correction" flow, which is out of scope. The tile's other slots (badge, name, "HH:mm · dose" subtitle) are unchanged.
- The `_Actions` `switch` stays **exhaustive over `IntakeStatus` with no `default:`** (constitution §3.1) — the `missed` arm is simply now a real widget.
- Because reconciliation converts past-window pending doses to `missed`, a past-window dose that previously showed Take/Skip will, after a trigger fires, render the locked "Missed" label instead. This is the intended §5.2 behavior.

### 3.6 Localization
One new ARB key (the "Missed" status label, e.g. `todayStatusMissed`) added to `app_en.arb` (with `@`-description), `app_de.arb`, and `app_uk.arb`, consumed only via `context.l10n.*`. No other user-facing strings are introduced (the reconcile engine is silent; failures reuse existing affordances).

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Domain — pure derivation | `lib/features/meds/domain/value_objects/` (e.g. `missed_intake_reconciliation.dart` or extend `due_dose.dart`) | **Create** pure "which occurrences are auto-miss-eligible as of `now`" derivation, reusing `expandDueDoses` + `localCalendarDate`, reading `IntakeWindow`. |
| Domain — use case | `lib/features/meds/domain/usecases/reconcile_missed_intakes.dart` | **Create** `ReconcileMissedIntakes` — snapshot → derive → mint id → write `missed`; idempotent, never clobbers; returns `Either`. |
| Domain — repository contract | `lib/features/meds/domain/repositories/intake_repository.dart` | **Modify**: add one method to persist a `missed` intake (e.g. `markMissed(Intake)`). **Interface change — blast radius below.** Possibly add a snapshot read (or use `watchAll().first`; see Open Questions). |
| Cross-feature domain import | (the derivation/use case) | Reads settings' `IntakeWindow` VO — a permitted domain→domain import (spec 039 OQ-1; pure Dart, no cycle). |
| Data — repository impl | `lib/features/meds/data/repositories/intake_repository_impl.dart` | **Modify**: implement the new persist-missed method via `upsertIntake` + mapper, exceptions → `Left(CacheFailure)`. |
| Data — data source (maybe) | `lib/features/meds/data/datasources/intake_local_data_source.dart` | Reuse `upsertIntake` (no new query expected); add a snapshot read only if `/plan` chooses that over `watchAll().first`. |
| Presentation — providers | `lib/features/meds/presentation/providers/intake_providers.dart` | **Modify**: add `reconcileMissedIntakesProvider` wiring the use case (repo(s) + `idGeneratorProvider`). |
| Presentation — trigger (startup) | `lib/app_bootstrap.dart` | **Modify**: fire-and-forget reconcile on the `data:` branch, non-blocking, reading `intakeWindow` from `settingsNotifierProvider` + `clock.now()`. |
| Presentation — trigger (Today) | `lib/features/meds/presentation/screens/today_screen.dart` | **Modify**: run reconcile once on screen open (not per rebuild); no reconcile loop. |
| Presentation — missed tile | `lib/features/meds/presentation/widgets/today_dose_tile.dart` | **Modify**: replace the `IntakeStatus.missed => SizedBox.shrink()` arm with a display-only error-toned "Missed" label; keep the exhaustive `switch`. |
| Localization | `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` (+ regenerated `AppLocalizations`) | **Modify**: add `todayStatusMissed` (with `@`-description) in all three locales. |
| Test fakes (blast radius) | `test/features/meds/presentation/screens/today_screen_test.dart` (`_LoadingIntakeRepository`, `_ErrorIntakeRepository`) | **Modify**: add a no-op override for the new `IntakeRepository` method to the **2 hand-written `implements IntakeRepository` fakes** (the 3 `extends Mock implements IntakeRepository` mocks auto-satisfy). |
| Integration harness | `integration_test/support/app_harness.dart` | **Modify (likely)**: neutralize the new `AppBootstrap` reconcile side-effect (override the reconcile provider with a no-op) so golden flows aren't polluted — mirroring the `devSeedProvider` override (MEMORY, Feature 035). |
| Startup test | `test/app_bootstrap_test.dart` | **Modify**: account for the new fire-and-forget reconcile side-effect (override/no-op so the test's expectations hold). |
| New tests | `test/features/meds/domain/{value_objects,usecases}/…`, `.../data/repositories/…`, `.../presentation/widgets/today_dose_tile_test.dart`, `.../presentation/view_models/…`, screen/trigger tests, optionally `integration_test/` | **Create**: derivation edge cases (window-closed boundary, existing-row exclusion, no-meds), use-case idempotency + never-clobber, repo persist-missed happy/error, missed-tile render (+ de/uk), trigger fires once / non-blocking. |

## 5. Acceptance Criteria

**Pure derivation**
- [x] **AC-1**: Given today's medications and the stored intakes, the derivation returns exactly the occurrences that are (a) due today, (b) past window (`now > scheduledAt + intakeWindow.minutes`, strict; compared in UTC), and (c) have no matching stored intake (matched by `(medicationId, slotId, localCalendarDate(scheduledAt))`). It reuses `expandDueDoses` and `localCalendarDate` rather than re-deriving day/window math.
- [x] **AC-2**: An occurrence exactly at the boundary (`now == scheduledAt + intakeWindow.minutes`) is **not** eligible; one strictly past it is. A dose whose window has not yet closed is never eligible. A future-scheduled dose later today is never eligible.
- [x] **AC-3**: An occurrence that already has ANY stored intake row — `taken`, `skipped`, or `missed` — is excluded from the eligible set (never re-derived), regardless of window state.
- [x] **AC-4**: The derivation is pure Dart (no Flutter/drift/data-layer imports; passes the domain-purity check), clock-free (takes `now`), and reads the window via the settings `IntakeWindow` VO.

**Use case & persistence**
- [x] **AC-5**: `ReconcileMissedIntakes` writes exactly one `missed` `Intake` per eligible occurrence, each with a fresh `IntakeId`, `status == IntakeStatus.missed`, `confirmedAt == null`, `scheduledAt` the occurrence's UTC instant, and `notes == null`.
- [x] **AC-6**: Idempotency — running the use case twice over the same state writes rows on the first run and **nothing** on the second (every eligible occurrence now has a `missed` row and is excluded). No duplicate rows are ever created for one occurrence.
- [x] **AC-7**: Never-clobber — an occurrence already `taken` or `skipped` is not modified or deleted by reconciliation, even when its window has closed (verified by reading the row back unchanged).
- [x] **AC-8**: The use case returns `Either<Failure, T>`; a storage failure from the repository surfaces as `Left(Failure)` (not thrown, not swallowed). `IntakeRepository`'s new persist-missed method returns `Right` on success and `Left(CacheFailure)` when the data source throws.
- [x] **AC-9**: Writing `missed` requires **no** `schemaVersion` change: `AppDatabase.schemaVersion` stays `2`, and a `missed` row round-trips through the mapper (`missed` stored/read by enum name; `scheduledAt` UTC).

**Triggers**
- [x] **AC-10**: On app open, `AppBootstrap` fires reconciliation **fire-and-forget** on the `data:` branch (startup is never blocked/awaited on it), using the current `intakeWindow` from `settingsNotifierProvider` and `clock.now()`; a reconcile failure does not produce a startup error screen.
- [x] **AC-11**: Opening the Today screen triggers reconciliation **once** (not on every rebuild); after the resulting stream re-emission and rebuild, no further reconcile is triggered for the same state (no busy-loop). With no medications, reconciliation writes nothing and does not error.
- [x] **AC-12**: After a trigger runs, previously past-window `pending` doses appear as `missed` in the reactive Today checklist without a manual refresh (the `intakesListProvider` stream re-emits). A dose whose window closes while the screen sits idle (no load/open) does **not** flip to `missed` (no live timer added).

**Missed tile & localization**
- [x] **AC-13**: A `TodayDose` with `status == IntakeStatus.missed` renders a display-only, error-toned localized "Missed" label with **no** Take/Skip/Undo affordances; the `_Actions` `switch` over `IntakeStatus` stays exhaustive with no `default:`.
- [x] **AC-14**: `todayStatusMissed` exists in `app_en.arb` (with `@`-description), `app_de.arb`, and `app_uk.arb`, is consumed only via `context.l10n.*`, and `AppLocalizations` regenerates cleanly.

**Quality & blast radius**
- [x] **AC-15**: The 2 hand-written `implements IntakeRepository` fakes in `today_screen_test.dart` gain a no-op override for the new method; the integration harness (and `app_bootstrap_test.dart`) neutralize/account for the new `AppBootstrap` reconcile side-effect; **project-wide** `dart analyze` is clean and the full suite (`flutter test`) is green. New public APIs carry dartdoc; every fallible op returns `Either<Failure, T>`.

## 6. Out of Scope

- **NOT included**: OS-level background execution while the app is closed (WorkManager / BGTaskScheduler / boot receivers) — a separate notifications-infra spec. This slice delivers only the on-app-open + on-Today-load triggers the constitution names.
- **NOT included**: the Today hourly-grouping redesign, countdown card, checkbox interaction model, per-tile chips, low-stock warnings, and mark-all-in-group (**Spec C**).
- **NOT included**: backfilling `missed` rows for **prior days** the user never opened the app for. Reconciliation is **today-only** (single local calendar day, reusing `expandDueDoses`); multi-day expansion is a future concern tied to adherence.
- **NOT included**: the "Manual Correction" audit-logged edit flow — a `missed` (or post-grace `taken`) dose stays locked; converting `missed → taken` is not offered.
- **NOT included**: rewiring the hardcoded `kIntakeUndoGracePeriod` to read the `gracePeriod` setting (Spec C), and consuming `allowMarkAhead` (auto-miss concerns the window's CLOSE, not its open).
- **NOT included**: adherence / History computation (`AdherenceRecord`) — this spec only produces the `missed` rows a future adherence calc will read.
- **NOT included**: reminders / notifications, `notificationLeadMinutes`, quiet hours; live in-place window-expiry `Timer` on the Today screen; decrementing `PackStock`; `notes` on intakes; any drift schema/migration change.

## 7. Technical Constraints

- **Constitution §5.2 is law**: auto-transition target is **`missed`, never `skipped`**; the window closes at `scheduledAt + intakeWindowMinutes`; a post-window/post-grace intake is editable only via the (out-of-scope) Manual-Correction flow.
- **Clean Architecture (§2.1)**: the derivation and use case are pure Dart (no Flutter/drift/data imports); drift stays in `core/database` + `data/`; presentation reaches the use case only via a `@riverpod` provider. Reading the settings `IntakeWindow` VO from the meds domain is a permitted domain→domain import (spec 039 OQ-1).
- **Mirror the shipped intake slice**: derivation like `expandDueDoses`/`buildTodayView`; use case like `MarkIntakeTaken`/`SkipIntake` (single op, `IdGenerator` injected, `Either` return); repo/impl/mapper/provider following the existing composition seam.
- **Reuse DST-safe day/window math**: `localCalendarDate`, `expandDueDoses`, `CourseProgress`, `resolveMedicationActivity` — do not re-derive day boundaries.
- **UTC storage / local display**; **inject `Clock` (`clock.now()`)**, never `DateTime.now()` in domain/derivation.
- **Idempotent, non-destructive writes**: reconcile writes `missed` only for occurrences with no row; it must never overwrite/delete `taken`/`skipped`/`missed` rows (the occurrence upsert would clobber — so eligibility, not the upsert, is the guard).
- **No schema change**: `schemaVersion` stays `2`; `missed` already fits the `intakes` table + `IntakeStatus` `textEnum` contract.
- **Non-blocking startup (§4.2.1)**: the `AppBootstrap` trigger is fire-and-forget; never `await`ed on the path to `runApp`/`DoslyApp`.
- **Interface-change blast radius (MEMORY 037/039)**: enumerate all `IntakeRepository` implementers (2 hand-written fakes + 3 `extends Mock`), update the fakes, run **project-wide** `dart analyze` and the full suite (not just changed-file analyze).
- **`AppBootstrap` side-effect discipline (MEMORY 035)**: the new startup side-effect must be overridable/neutralized in `integration_test/support/app_harness.dart` and handled in `app_bootstrap_test.dart`, or golden flows and startup tests break.
- **Exhaustive `switch`** over `IntakeStatus` in the tile — no `default:` (§3.1).

## 8. Open Questions

- **OQ-1 (snapshot source)**: does `ReconcileMissedIntakes` read medication/intake snapshots via a new repository snapshot method (`getAll()`) or via the existing `watchAll().first`? A new `MedicationRepository` method has a **large** fake blast radius (many meds fakes); `watchAll().first` avoids that. Lean toward `watchAll().first` (or an intake-only snapshot). Resolve in `/plan`.
- **OQ-2 (persist-missed method name/shape)**: `markMissed(Intake)` vs a more general `save(Intake)`/`putMissed(...)`. Prefer a `missed`-specific, intent-revealing name symmetric with `markTaken`/`skip`. `/plan`.
- **OQ-3 (settings read at the trigger)**: read `intakeWindow` via `ref.read(settingsNotifierProvider).intakeWindow` at each trigger (chosen — synchronous, kept-alive) vs re-loading from the repository. Confirm the `settingsNotifierProvider` is serviceable at the `AppBootstrap` `data:` branch (it is — prefs are resolved there).
- **OQ-4 (Today trigger mechanism)**: `initState` fire-and-forget vs a dedicated one-shot provider vs a `ref.listenManual`. Must guarantee "once per open, no rebuild loop." `/plan`.
- **OQ-5 (return value)**: `Either<Failure, int>` (count written, useful for logging/tests) vs `Either<Failure, Unit>`. Cosmetic; `/plan`.
- **OQ-6 (derivation home)**: a new `value_objects/` file vs extending `due_dose.dart`. Cosmetic; keep it a separate pure function for testability.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Reconcile upsert **clobbers** a `taken`/`skipped` row with `missed` (the upsert overwrites in place on the occurrence key) | Medium | High | Eligibility EXCLUDES any occurrence that already has a row (AC-3/AC-7); reconcile writes only truly-pending occurrences. Test never-clobber explicitly by reading the row back unchanged. |
| Today-screen trigger creates a **reconcile ↔ stream-re-emit ↔ rebuild loop** | Medium | Medium | Run once per screen open (not per rebuild); already-missed occurrences are ineligible so it converges even if re-fired (AC-11). Verify no busy-loop in a widget test. |
| New `AppBootstrap` side-effect **poisons integration/startup tests** (repeat of the devSeed lesson) | High | Medium | Neutralize in `app_harness.dart` + `app_bootstrap_test.dart` (AC-15); fire-and-forget + non-blocking so startup can't error (AC-10). |
| Adding a method to `IntakeRepository` **breaks the 2 hand-written fakes** and slips past changed-file analyze | High | Medium | Enumerated in Affected Areas; add no-op overrides; run project-wide `dart analyze` + full suite (AC-15). |
| Off-by-one / DST error at the **window-close boundary** | Low | Medium | Reuse `localCalendarDate`/`expandDueDoses`; strict `>` boundary with clock-injected unit tests at and past the edge (AC-2). |
| A dose becomes **un-takeable** the moment its window closes (locked `missed`), surprising the user | Low | Low | Deliberate per §5.2 (confirmed: display-only missed tile); Manual-Correction is the sanctioned recovery, tracked as out-of-scope follow-up. |
| Scope creep toward adherence / Spec C redesign / OS background | Medium | Medium | Exhaustive §6 Out of Scope; ACs bound to reconcile + missed rendering + two app-side triggers only. |
