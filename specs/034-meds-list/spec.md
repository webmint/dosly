# Spec: Medications List Screen

**Date**: 2026-06-18
**Status**: Complete
**Author**: Claude + Webmint

## 1. Overview

Replace the placeholder `MedsScreen` with a real medications list that reads every persisted medication from the local drift database via a **reactive** query, groups them into **Continuous** and **Course** sections, and renders a med-item tile per medication (form icon, name, `dose · times · stock` subtitle with a low-stock warning, and status/type chips) per the `#s-meds` design in `dosly_m3_template.html`. The screen adds **All/Active** filter chips and an app-bar **name search**. A separate **debug-only seeder** populates the database with representative variants so the screen can be exercised on-device without hand-entering data. The **Archive** state and its filter are explicitly deferred to a follow-up (they require a schema migration).

## 2. Current State

The write path for medications is complete and proven (spec 032 + integration tests in spec 033); the **read path does not exist yet**.

**What exists:**
- `lib/features/meds/presentation/screens/meds_screen.dart` — a `StatelessWidget` placeholder: `AppBar` (localized `bottomNavMeds` title + bottom divider), an **empty body** (`SizedBox.shrink()`), and a `FloatingActionButton` (`medsAddFab`) that opens `AddMedicationModal`. The bottom nav comes from the routing shell (`core/routing/app_shell.dart`).
- `lib/features/meds/presentation/providers/medication_providers.dart` — the meds **composition seam** (the one presentation file allowed to import `data/`, per the §2.1 amendment). Currently wires `medicationLocalDataSourceProvider`, `medicationRepositoryProvider`, and `addMedicationProvider`. **No list/read provider.**
- `lib/features/meds/domain/repositories/medication_repository.dart` — `abstract interface class MedicationRepository` with **only** `Future<Either<Failure, Medication>> add(Medication)`. **No read method.**
- `lib/features/meds/data/repositories/medication_repository_impl.dart` — implements `add` only (catches data-source exceptions → `Left(Failure.unknown)`).
- `lib/features/meds/data/datasources/medication_local_data_source.dart` — `insertMedication(...)` only (single transaction: medication row + time-slot batch).
- `lib/features/meds/data/mappers/medication_mapper.dart` — **already has the read mapper** `medicationFromRows(MedicationRow, List<TimeSlotRow>) → Medication` (built + tested in spec 032, currently only used by tests). Write mappers `medicationToCompanion` / `timeSlotsToCompanions` also present.
- Domain model (all pure-Dart, freezed): `Medication` (id, name, form, type, schedule, optional `dosePerIntake`, optional `stock`, notes, `createdAt`), `MedicationType` sealed union `ContinuousType{startDate}` | `CourseType{startDate, durationDays, pauseDays}` (end date **derived** = `startDate + durationDays − 1`; `pauseDays > 0` = cyclic, never ends; `pauseDays == 0` = single bounded course), `MedicationForm` (8 values), `Dosage{amount, unit}`, `DoseUnit` (9 values), `PackStock{remaining, total, warnAt}`, `Schedule{frequency=daily, slots}`, `TimeSlot{id, minuteOfDay 0..1439, doseOverride?}`, `ScheduleFrequency{daily}`.
- Drift: `AppDatabase` (`schemaVersion = 1`, tables `Medications` + `TimeSlots`, FK cascade on slots) at `lib/core/database/`. `appDatabaseProvider` is `@Riverpod(keepAlive: true)`.
- `lib/app_bootstrap.dart` — non-blocking startup root; mounts `DoslyApp` once `sharedPreferencesInitProvider` resolves. The DB (`appDatabaseProvider`) is the natural seam to read for a startup seeder.
- l10n: `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` (all three maintained), surfaced via `context.l10n`. Existing `medsAdd*` keys for the add form; no list-screen keys.
- The add modal owns a **private** `MedicationForm → LucideIcons` mapping (`_medFormOptions`): tablet→`tablets`, capsule→`pill`, syrup→`milk`, drops→`droplets`, injection→`syringe`, inhaler→`wind`, cream→`container`, sachet→`package`.
- Time injection uses **`package:clock`'s ambient `clock.now()`** directly (no `clockProvider`; `lib/core/clock/` does not exist). Tests override with `withClock(Clock.fixed(...))`.

**Design reference** — `dosly_m3_template.html` lines 1838–1982 (`#s-meds`): search app-bar (title "Мої ліки"), filter chips `Всі / Активні / Архів`, sections `Постійні` / `Курсові` (each with a "Нічого не знайдено" empty placeholder), `.mlt` tiles (`.med-iconify` color-variant icon + `.mlt-name` + `.mlt-sub` `dose · times · stock` with low-stock in `--md-error` + `.mlt-chips` status/type chips + `.mlt-trail` chevron), and a FAB.

## 3. Desired Behavior

### 3.1 Reactive read
- A reactive repository read emits the full list of persisted `Medication` aggregates and **re-emits whenever the `Medications` or `TimeSlots` tables change** (so an add/delete is reflected without any manual refresh). Each medication is reconstructed via the existing `medicationFromRows` mapper (including its time slots, dose, stock, type, notes).
- The read honors the §3.2 boundary contract: the repository returns `Stream<Either<Failure, List<Medication>>>` (data-source exceptions caught → `Left(Failure)`); a `@riverpod` stream provider folds each emission into `AsyncValue<List<Medication>>` (`Right` → data, `Left`/error → `AsyncError(Failure)`).

### 3.2 Activity + course-progress derivation (domain, Clock-injected)
A pure, instant-injected domain derivation computes, for a medication as of a given instant `now`:
- **Activity status** — `Active` or `Completed`:
  - Continuous → always `Active`.
  - Cyclic course (`pauseDays > 0`) → always `Active` (cycles indefinitely; never ends).
  - Non-cyclic course (`pauseDays == 0`) → `Active` while `now` ≤ derived end (`startDate + durationDays − 1`, inclusive through end-of-day local time); otherwise `Completed`.
- **Course cycle-day counter** (courses only): `currentDay ∈ 1..durationDays` measured **within the current active window**, `totalDays = durationDays`, and a **phase** flag — `activeWindow` vs `paused` (a `paused` phase only occurs for cyclic courses during a pause gap). The counter resets at the start of each cycle.
- All date math goes through the injected `now` — never `DateTime.now()` (constitution §4.2.1, §5.2).

### 3.3 Screen layout & tiles
- `MedsScreen` renders the list grouped into two ordered sections: **Continuous** (continuous meds) then **Course** (course meds), each med ordered by name (case-insensitive, ascending) for deterministic output. Section headers use localized strings (`Постійні` / `Курсові`).
- Each med tile renders:
  - **Leading form icon** using the shared `MedicationForm → IconData` map (extracted from the add modal, §3.7 DRY), tinted by a **color variant**: `primary` for continuous, `tertiary` for course.
  - **Name** (`Medication.name`).
  - **Subtitle** = `dose · times · stock`, segments joined by ` · ` and **omitted when absent**:
    - `dose` (only when `dosePerIntake != null`): amount with no trailing `.0` + localized `DoseUnit` abbreviation (e.g. `20 мг`).
    - `times`: schedule slots formatted `HH:mm` (local), sorted ascending, comma-joined (e.g. `08:00, 20:00`).
    - `stock` (only when `stock != null`): `remaining of total` + localized "pcs" (e.g. `18 з 30 шт`), rendered in the **theme error color** when `remaining ≤ warnAt`.
  - **Chips**:
    - **Status chip**: `Active` (positive/green tone) for active meds; `Completed` (neutral/grey tone) for completed courses.
    - **Type chip**: `continuous` for continuous meds; for courses, `Day X/Y` (cycle-day counter) during an active window, or `Paused` during a cyclic pause gap.
  - **Trailing chevron** — rendered but **not interactive** (no detail screen yet).

### 3.4 Filter chips & search
- Filter chips **All** and **Active** are rendered (no Archive chip this slice). **All** shows every medication; **Active** hides `Completed` (ended non-cyclic) courses. Switching chips updates the list reactively (no reload).
- An app-bar **search** affordance filters the visible medications by **name** (case-insensitive substring) across both sections. Clearing the query restores the (filter-respecting) full list.

### 3.5 States
- **Loading**: while the stream has not produced its first value, show a loading indicator.
- **Error**: on stream error, show an error view (all three `AsyncValue.when` branches handled).
- **Empty (no meds at all)**: a single friendly top-level empty state with guidance to tap **+** to add one.
- **Empty section (filter/search)**: a section with zero matching meds shows its inline "Нічого не знайдено" placeholder (the other section still renders normally).

### 3.6 Debug seeder
- A **`kDebugMode`-only** seeder persists a representative set of medications **via the real write path** (the repository), and **only when the `Medications` table is empty** — idempotent across launches, never duplicating, and a **no-op in release builds**. Invoked once during startup (e.g. from `app_bootstrap` after the DB is available).
- The seed set covers (see AC-17): all 8 forms; continuous + non-cyclic course + cyclic course; with/without dose; with/without stock; at least one low-stock pack; single- and multi-slot schedules; and at least one completed (ended, non-cyclic) course.
- The seeder logs **nothing containing medication names** (PHI sanitize rule).

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Read data source | `lib/features/meds/data/datasources/medication_local_data_source.dart` | Add reactive `watch` over medications + time slots (re-emits on change) |
| Repository contract | `lib/features/meds/domain/repositories/medication_repository.dart` | Add reactive read → `Stream<Either<Failure, List<Medication>>>` |
| Repository impl | `lib/features/meds/data/repositories/medication_repository_impl.dart` | Implement reactive read; catch data-source errors → `Left(Failure)` |
| Read mapper | `lib/features/meds/data/mappers/medication_mapper.dart` | Reuse `medicationFromRows` (no change, or add a list/grouping helper) |
| Domain derivation | `lib/features/meds/domain/value_objects/course_progress.dart` **(new)** + `lib/features/meds/domain/entities/medication_activity.dart` **(new, or co-located)** | Create — Clock-injected activity + cycle-day derivation (pure) |
| Providers (seam) | `lib/features/meds/presentation/providers/medication_providers.dart` | Add the list stream provider exposing `AsyncValue<List<Medication>>` |
| Screen | `lib/features/meds/presentation/screens/meds_screen.dart` | Rebuild: sections, filter chips, search app bar, loading/error/empty states |
| Tile widget | `lib/features/meds/presentation/widgets/medication_tile.dart` **(new)** | Create — the `.mlt` tile (icon, name, subtitle, chips, chevron) |
| Section/list widgets | `lib/features/meds/presentation/widgets/medication_section.dart` **(new, optional)** | Create — section header + list + empty placeholder |
| Shared form-icon map | `lib/features/meds/presentation/widgets/medication_form_icon.dart` **(new)** | Extract `MedicationForm → IconData` from `add_medication_modal.dart` (DRY) and reuse in both |
| Display formatters | `lib/features/meds/presentation/.../medication_display.dart` **(new)** or l10n-driven | Create — dose/time/stock subtitle formatting |
| Seeder | `lib/core/database/dev_seed.dart` **(new)** + `lib/app_bootstrap.dart` | Create + wire behind `kDebugMode`, empty-table guard |
| l10n | `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` (+ generated) | Add list-screen keys (×3 locales) |
| Tests | `test/features/meds/...` (domain derivation, data source/repo reactive read, tile + screen widget tests) | Create per §3.4 coverage targets |

## 5. Acceptance Criteria

**Reactive read**
- [x] **AC-1**: The repository exposes a reactive read returning `Stream<Either<Failure, List<Medication>>>` that re-emits whenever the `Medications` or `TimeSlots` tables change; data-source exceptions are caught and emitted as `Left(Failure)` (never thrown out of `data/`).
- [x] **AC-2**: A `@riverpod` provider exposes the list as `AsyncValue<List<Medication>>` — a successful emission → `AsyncData`, a `Left`/stream error → `AsyncError(Failure)`.
- [x] **AC-3**: Each emitted `Medication` is reconstructed via the existing `medicationFromRows` mapper, including its time slots, dose, stock, type, and notes.
- [x] **AC-19**: Adding a medication through the existing add-medication modal makes it appear in the list with **no manual refresh** (verified end-to-end, e.g. via a widget/integration test or the reactive provider test).

**Domain derivation (Clock-injected, pure)**
- [x] **AC-4**: The activity derivation, given a medication and an instant `now`, returns `Active` for continuous and cyclic courses, `Active` for a non-cyclic course while `now` ≤ `startDate + durationDays − 1` (inclusive through end-of-day local), and `Completed` once past that end.
- [x] **AC-5**: The course cycle-day derivation returns `currentDay ∈ 1..durationDays` within the current active window, `totalDays = durationDays`, and a phase of `activeWindow` or (cyclic only) `paused` during a pause gap; the counter resets each cycle.
- [x] **AC-6**: The derivation is unit-tested with **fixed `Clock` instants** covering: continuous; non-cyclic active; non-cyclic completed at the just-past-end inclusive boundary; cyclic in an active window; cyclic in a pause gap; and day-boundary edges. No `DateTime.now()` is used in domain code.

**Screen & tiles**
- [x] **AC-7**: `MedsScreen` renders medications grouped into a **Continuous** section then a **Course** section, each ordered by name (case-insensitive ascending), with localized section headers.
- [x] **AC-8**: Each tile renders a leading form icon (from the shared `MedicationForm → IconData` map; tint `primary` for continuous, `tertiary` for course), the name, and a `dose · times · stock` subtitle where: dose shows amount without a trailing `.0` + localized unit abbrev (omitted when no dose); times are slots formatted `HH:mm` local, sorted ascending, comma-joined; stock shows `remaining of total` + localized "pcs" (omitted when no stock) and is rendered in the **theme error color** when `remaining ≤ warnAt`.
- [x] **AC-9**: Each tile renders a status chip (`Active` positive tone for active meds, `Completed` neutral tone for completed courses) and a type chip (`continuous` for continuous; `Day X/Y` for a course active window; `Paused` for a cyclic pause gap).
- [x] **AC-10**: `All` and `Active` filter chips are rendered; `All` shows every medication, `Active` hides `Completed` courses; switching chips updates the list reactively without a reload.
- [x] **AC-11**: The app-bar search filters visible medications by name (case-insensitive substring) across both sections; clearing the query restores the full (filter-respecting) list.
- [x] **AC-12**: With zero medications total, a single friendly top-level empty state is shown (guidance to add one); a section with zero meds matching the current filter/search shows its inline "Nothing found" placeholder while the other section renders normally.
- [x] **AC-13**: Tiles render a trailing chevron but are **not tappable** (no detail navigation in this slice).
- [x] **AC-14**: Loading shows a progress indicator and stream errors show an error view (all three `AsyncValue.when` branches handled).

**Localization**
- [x] **AC-15**: All new user-facing strings — title, search hint + icon tooltip, filter labels (`All`/`Active`), section headers (`Continuous`/`Course`), status chips (`Active`/`Completed`), type chips (`continuous`/`Day {current}/{total}`/`Paused`), stock (`{remaining} of {total} pcs`), dose-unit abbreviations, and both empty states — are added to `app_en.arb`, `app_de.arb`, and `app_uk.arb` with real translations (no hardcoded literals in widgets). Ukrainian matches the design wording ("Мої ліки", "Постійні", "Курсові", "Всі", "Активні", "Пошук ліків...", "Нічого не знайдено", "День {current}/{total}", "{remaining} з {total} шт").

**Seeder**
- [x] **AC-16**: A `kDebugMode`-guarded seeder persists the seed set via the real repository write path, **only when the `Medications` table is empty** — idempotent across launches, never duplicating rows, and a no-op in release builds.
- [x] **AC-17**: The seed set covers: all 8 `MedicationForm` values; at least one continuous, one non-cyclic course, and one cyclic course; meds with and without `dosePerIntake`; meds with and without `PackStock`; at least one low-stock pack (`remaining ≤ warnAt`); at least one single-slot and one multi-slot schedule; and at least one completed (ended, non-cyclic) course to exercise the `Completed` state and the `Active` filter.
- [x] **AC-18**: The seeder logs nothing containing medication names (PHI sanitize rule); `dart analyze` is clean and no debug artifacts (`print`, etc.) are introduced.

## 6. Out of Scope

- NOT included: **Archive** state, the `Архів` filter chip, and archived (neutral/dimmed) tile styling — follow-up spec (requires an `archivedAt`/`isArchived` column → `schemaVersion` bump + migration).
- NOT included: Medication **detail / edit / delete** screens and any tile-tap navigation (the chevron is decorative this slice).
- NOT included: **Intake tracking** / "today" intake status on tiles (the list shows schedule + stock + course progress, not per-intake state).
- NOT included: **Non-daily frequency** UI or scheduling (`Schedule.frequency` stays `daily` per MVP).
- NOT included: Editing or refilling **stock** from the list.
- NOT included: Tile **reordering / drag-and-drop**, multi-select, swipe actions.
- NOT included: **Pull-to-refresh** (the reactive stream makes it unnecessary).
- NOT included: Any **drift schema change** — `Active`/`Completed` are derived, never stored.

## 7. Technical Constraints

- **Clean Architecture (§2.1)**: the read path mirrors the write path across `data → domain → presentation`. Screens/widgets consume only `domain`-typed providers; only `medication_providers.dart` (the composition seam) imports `data/`.
- **Either at boundaries (§3.2)**: the reactive read returns `Stream<Either<Failure, List<Medication>>>` (the read-side analog of the existing `Future<Either<…>>` write methods); the provider folds emissions into `AsyncValue` (`Right` → data, `Left`/error → error). If the reactive-stream pattern proliferates beyond this feature, consider a constitution note in a later `/constitute` — not blocking here.
- **Clock (§4.2.1)**: all activity/cycle-day math takes an injected `now` (supplied from `package:clock`'s `clock.now()` at the provider seam); never `DateTime.now()` in domain. Tests use `withClock(Clock.fixed(...))`.
- **Domain purity (§2.1)**: form→icon mapping, `minuteOfDay → HH:mm` formatting, and dose/stock string building live in `presentation/`, never in `domain/`.
- **DRY (§3.7)**: extract the `MedicationForm → IconData` map out of `add_medication_modal.dart` into a shared widget/helper and have both the add modal and the tile consume it (do not duplicate the mapping).
- **Reuse (§3.7)**: reuse the existing `medicationFromRows` mapper for reconstruction; reuse existing theme tokens and lucide icons (no hardcoded colors).
- **No schema change (§6.5)**: this spec must not bump `schemaVersion` or alter any column.
- **Seeder safety (§3.5, §4.2.1 privacy)**: `kDebugMode` guard + empty-table guard + no PHI logging; must not be a committed artifact that runs in release.
- **l10n**: keys added to all three `.arb` files; regenerate via `flutter gen-l10n`; widget tests assert localized output (mind the `MaterialLocalizations` date/format gotchas noted in MEMORY).
- **Testing (§3.4)**: domain derivation unit-tested (mandatory); data source/repository reactive read tested with an in-memory drift DB (mandatory); the screen/tiles covered by widget tests with overridden providers.
- **Material 3**: filter chips, sections, and tiles use M3 widgets/theme; tap targets ≥ 48dp where interactive (filter chips, search).

## 8. Open Questions

- **OQ-1**: Exact localized **dose-unit abbreviations** per `DoseUnit` (e.g. `units` → "МО"/"IU" vs "од") and the "pcs" word per locale — to be finalized during implementation against the design and existing `unit`/`units` l10n keys (reuse if suitable, else add display abbreviations).
- **OQ-2**: Whether the **shared form-icon map** lives as a top-level `Map<MedicationForm, IconData>` or a small helper widget — a `/plan` structuring detail; either satisfies the DRY constraint.
- **OQ-3**: Whether the cyclic `Paused` type chip should also show the **next active day** (e.g. "Пауза · далі день 1") — default is a plain `Paused` label; richer text can be a later polish.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `Stream<Either<…>>` read deviates from the `Future<Either<…>>` idiom and gets flagged in review | Med | Low | Document it as the sanctioned read-side analog in the seam's dartdoc; fold cleanly to `AsyncValue`; get architect sign-off in `/plan`. |
| Cycle-day / inclusive-end / pause-boundary math is subtly wrong (incl. DST) | Med | Med | Centralize in one pure derivation; exhaustive `Clock`-injected unit tests at boundaries (AC-6); reuse the §5.2 schedule-resolution rules verbatim. |
| Seeder duplicates or (worse) wipes real data | Low | High | Empty-table guard + `kDebugMode` + no destructive ops; it only **inserts when empty**, never deletes. (MEMORY: a low-disk uninstall once wiped the real `dosly.sqlite` during on-device integration runs — unrelated to the seeder, but reinforces "never delete real data".) |
| Drift reactive query mis-joins medications↔time-slots (slots attached to wrong med, or list not re-emitting on slot change) | Med | Med | Test with an in-memory DB: insert/modify/delete and assert re-emission + correct slot grouping; ensure the watch covers both tables. |
| l10n keys drift across the 3 locales / wrong plural or format | Low | Low | Add all keys to all three `.arb` in one task; `flutter gen-l10n` fails fast on mismatches; widget tests assert localized strings. |
| Extracting the form-icon map breaks the add modal | Low | Med | Behavior-preserving extraction; the existing add-modal tests must stay green; `dart analyze` clean. |
| Feature spans >5 files (read slice + widgets + seeder + l10n) | High | Low | Expected for a vertical slice; `/breakdown` sequences it into atomic tasks with the dependency graph. |
