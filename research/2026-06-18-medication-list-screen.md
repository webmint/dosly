# Research: Medication List Screen + Med Items (wired to DB, with test seed data)

**Date**: 2026-06-18
**Topic**: Build the medications-list screen and med-item tiles (design in `dosly_m3_template.html` `#s-meds`), wire it to the drift DB, and seed the DB with representative variants for testing.
**Verdict**: **Feasible with Caveats** — the write path is fully built and proven (spec 032); the entire *read* path is missing and must be added as a clean vertical slice. Two design concepts (Active/**Archive** state, and the course **"День X/Y"** progress chip) need explicit domain decisions before coding.

## Summary

Adding a medication you create already persists end-to-end (`add_medication_modal` → `addMedicationProvider` → `AddMedication` → `MedicationRepositoryImpl` → drift, spec 032). What's missing is everything that *reads it back*: there is **no `getAll`/`watch` on the repository**, no read use case, no list provider, and `MedsScreen` is still an empty placeholder (`SizedBox.shrink()` + FAB). The good news: the read-side mapper (`medicationFromRows`) is **already built and tested** — only the query, repository method, use case, and provider are absent. The design is richer than the current model in two places: it shows an **Active/Archive** state that has **no backing field** in the entity or schema, and a course **day-counter** (`День 7/30`) that must be **derived from `Clock.now()`** vs. the course start. Seeding test data needs a privacy- and lint-safe home. This is bigger than a `/fix` (a 3-layer slice + a widget + a schema decision + l10n in 3 locales) → recommend `/specify`.

## Codebase Findings

### Existing Related Code

| Area | File | Relevance |
|------|------|-----------|
| List screen (placeholder) | `lib/features/meds/presentation/screens/meds_screen.dart` | Empty body + FAB; the target to build out |
| Composition seam | `…/presentation/providers/medication_providers.dart` | Only wires `add`; add list/watch providers here |
| Repository contract | `…/domain/repositories/medication_repository.dart` | **Only `add(...)`** — no read method |
| Repository impl + data source | `…/data/repositories/…_impl.dart`, `…/data/datasources/medication_local_data_source.dart` | Only `insertMedication`; need a read query |
| **Read mapper (already done!)** | `…/data/mappers/medication_mapper.dart` → `medicationFromRows(row, slotRows)` | Row→entity reconstruction exists & is tested; reduces effort |
| Drift tables | `core/database/tables/medications_table.dart`, `time_slots_table.dart` | `schemaVersion = 1`; no archive/status column |
| Write path (proven) | `…/presentation/widgets/add_medication_modal.dart` | Confirms the full DI chain works; list mirrors it on the read side |
| Design source | `dosly_m3_template.html` lines 1838–1982 (`#s-meds`) | Search app-bar, `Всі/Активні/Архів` filter chips, `Постійні/Курсові` sections, `.mlt` tiles |

### Med-tile (`.mlt`) anatomy from the design
- **Leading icon** (`.med-iconify`): SVG *shape* encodes the `MedicationForm`; the color variant (`primary` / `tertiary` / `neutral`) encodes **state/category** (continuous-active / course-active / archived), **not** the form.
- **Body**:
  - `.mlt-name` → `Medication.name`
  - `.mlt-sub` → `dose · times · stock`, e.g. `20 мг · 08:00, 20:00 · 18 з 30 шт`. Stock turns **red** (`--md-error`) when `remaining ≤ warnAt`. Times come from `TimeSlot.minuteOfDay` formatted `HH:mm`.
  - `.mlt-chips` → `[status chip, type chip]`. Status = `Активний` (green) / `Архів` (grey). Type = `постійний` (continuous) or `День X/Y` (teal, course progress).
- **Trailing** `.mlt-trail` chevron → navigates to detail/edit (out of scope for the list-read slice).
- **Sections**: `Постійні` (continuous) and `Курсові` (course), each with a "Нічого не знайдено" empty state.

### Patterns Available
- **Composition-seam DI** (`@riverpod` provider file may import `data/`) — add the read providers here, same as `add`.
- **`AsyncValue.when(data/error/loading)`** in screens (see `settings_screen.dart`) — the list renders the same way.
- **drift reactive `.watch()`** — drift is already a dependency and supports live-updating `Stream<List<…>>` queries (list auto-refreshes after add/delete).
- **l10n** via `context.l10n` + `.arb` (en/de/uk all present) — `medsAdd*` keys already exist; the list screen needs its own keys.

### Gaps
- **No read method** anywhere (`getAll` or `watch`) on data source / repository.
- **No read use case** (`GetMedications` / `WatchMedications`) and **no list provider** exposing `AsyncValue<List<Medication>>`.
- **No med-tile widget** (`.mlt`: form icon + name + `dose · times · stock` subtitle + status/type chips + chevron).
- **No Active/Archive concept** in the domain entity *or* the drift schema.
- **No course-progress derivation** (`День X/Y`) — needs Clock-based date math (and cyclic-course handling for `pauseDays > 0`).
- **No list-screen l10n keys** (section headers, filter chips, search placeholder, empty states, chip labels) in any of the 3 locales.
- **No seeding mechanism** for test variants.

## Constitution Constraints

| Rule | Impact |
|------|--------|
| §2.1 Layer boundaries | Read path must mirror the write path across data → domain → presentation (no shortcuts). |
| §3.2 `Either<Failure,T>` at every boundary | A **reactive** read (`Stream`) doesn't compose cleanly with `Either`; decide `Stream<List<Medication>>`→`AsyncValue` vs. `Future<Either<…>>` + manual invalidate. |
| §4.2.1 Inject `Clock`, never `DateTime.now()` | The `День X/Y` counter and "is this course archived/ended today" check are **time-sensitive** → must go through `Clock.now()`. |
| §6.5 + §4.2.1 drift schema | Adding an `archivedAt`/`isArchived` column = **`schemaVersion` bump + migration** (health data, no silent default). |
| §3.5 / Never-rules | Seeding must **not** be a committed debug artifact and must **not log med names** — guard behind `kDebugMode` and keep it idempotent. |
| §4.2.1 never put Flutter in `domain/` | Form→icon (lucide) mapping and `minuteOfDay`→`HH:mm` formatting live at the **presentation** seam, not in domain. |

## Approaches

This breaks into three sub-decisions.

### Decision 1 — Read wiring
- **Option A: drift reactive `.watch()`** → `Stream<List<Medication>>` → stream provider → `AsyncValue`. List updates live after add/delete. *Con*: `Either`-over-stream is awkward (map drift errors straight to `AsyncError`). **Complexity: Medium.**
- **Option B: `Future getAll()` + `ref.invalidate`** after each mutation. Matches the existing `Either` pattern exactly; *con*: manual refresh, no live updates. **Complexity: Low.**

**Recommended: Option A** — a medication list is the canonical case for a reactive query, and it removes a whole class of "stale list after add" bugs.

### Decision 2 — Active / Archive state
- **Option A: derive Archive** from course completion (derived end date passed). **Zero schema change.** *Con*: can't archive a continuous med or a *mid-course* med — directly contradicts the design (`Флуоксетин · День 15/60 · Архів`).
- **Option B: explicit `archivedAt` column** → schema v2 + migration. Matches the design fully (manual archive of any med). **Complexity: Medium.**
- **Option C: defer Archive** — ship `Всі`/`Активні` + the `Постійні`/`Курсові` sections now; add the Archive filter + column in a follow-up. **Lowest-risk first slice.**

**Recommended: Option C for the first slice, Option B as the immediate follow-up** — keeps the initial read-slice tight and avoids coupling a schema migration to the screen build.

### Decision 3 — Seeding test variants
- **Option A: `kDebugMode`-guarded, idempotent seeder** (insert only when the table is empty) invoked in `app_bootstrap`. Fast for on-device manual testing. **Recommended.**
- **Option B: hidden dev action** (e.g. long-press FAB) — explicit, but adds throwaway UI.
- **Option C: reuse the spec 033 integration-test fixtures** — good for tests, not for poking the running app.

**Recommended: Option A** — covers every variant (each `MedicationForm`; continuous vs. course; with/without `dosePerIntake`; with/without `PackStock`; a low-stock pack at/below `warnAt`; single-slot and multi-slot schedules; a completed course).

**Overall recommended path**: one `/specify` for the **read slice + tile + sections + seed** (Decisions 1A, 2C, 3A), then a small follow-up spec for **Archive** (2B, the migration).

## Complexity Assessment

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Codebase changes | **Medium** | Vertical read slice (4 files) + tile widget + screen rebuild + l10n×3 + seeder |
| New dependencies | **None** | drift / riverpod / freezed / lucide_icons all already present |
| Risk | **Low–Medium** | Schema migration *only if* Archive is in scope; Clock-derivation correctness for `День X/Y`; reconciling reactive stream with `Either` |

## Recommendation

**Proceed to `/specify`.** Scope the first feature as the read slice (reactive list, form-icon tiles, `Постійні`/`Курсові` sections, `Всі`/`Активні` filters) + a `kDebugMode` seeder, and let the spec's clarifying questions settle the two open decisions:
1. **Reactive `.watch()` vs. `Future` + invalidate** (Decision 1).
2. **Archive now (schema v2 migration) vs. defer to a follow-up** (Decision 2).

Suggested next command:

```
/specify "Medications list screen: read all persisted medications from drift via a reactive query, group them into Continuous/Course sections, render med-item tiles (form icon, name, 'dose · times · stock' subtitle with low-stock warning, status/type chips) per the #s-meds design, with All/Active filter chips and name search. Add a kDebugMode-only idempotent seeder covering all forms, continuous+course, with/without stock and low-stock variants. Defer the Archive state + filter to a follow-up."
```
