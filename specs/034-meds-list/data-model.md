# Data Model: Medications List Screen

No **storage** schema change (constitution §6.5 — `schemaVersion` stays `1`). `Active`/`Completed` and the course day-counter are **derived at read time**, never persisted. This document defines the new **domain derivation types**, the **read contract**, the **l10n keys**, and the **seed set**.

## New domain types (pure Dart, no Flutter/drift)

### `MedicationActivityStatus` — `domain/entities/medication_activity_status.dart`
Leaf enum (sibling of `medication_form.dart`). NOT persisted.

| Value | Meaning |
|-------|---------|
| `active` | Continuous; cyclic course (always); non-cyclic course on/before its derived end |
| `completed` | Non-cyclic course past its derived end (`startDate + durationDays − 1`) |

### `CoursePhase` — `domain/entities/course_phase.dart`
Leaf enum. NOT persisted.

| Value | Meaning |
|-------|---------|
| `activeWindow` | `now` falls within an active `durationDays` window |
| `paused` | `now` falls within a `pauseDays` gap (cyclic courses only) |

### `CourseProgress` — `domain/value_objects/course_progress.dart`
`@freezed` value object describing a course's position as of an instant. Built only for `CourseType` (continuous meds have none).

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `currentDay` | `int` | yes | Day within the current window, `1..durationDays` (clamped to `durationDays` for a just-ended non-cyclic course) |
| `totalDays` | `int` | yes | `= durationDays` |
| `phase` | `CoursePhase` | yes | `activeWindow` or `paused` |

### Derivation functions (pure, `now`-injected)
- `CourseProgress CourseProgress.resolve({required CourseType course, required DateTime now})` — static factory in `course_progress.dart`.
- `MedicationActivityStatus resolveMedicationActivity(Medication medication, DateTime now)` — top-level fn in `domain/value_objects/medication_activity.dart`.

**Day-math rules** (the high-risk area — exhaustive tests per AC-6):
- Compare **calendar dates**, not raw instants: reduce both `now` and `course.startDate` to their **local** date (year/month/day) before differencing, so a 09:00-vs-23:00 same-day comparison and DST shifts don't move the day boundary. (MEMORY, spec 033: `startDate` is stored UTC with drift's local flag; compare via date-only, not `==`/`isAtSameMomentAs` on instants.)
- `daysSinceStart = localDate(now).difference(localDate(startDate)).inDays` (0 on the start day).
- Non-cyclic (`pauseDays == 0`): `Active` while `daysSinceStart ≤ durationDays − 1`; else `Completed`. `currentDay = min(daysSinceStart + 1, durationDays)`; `phase = activeWindow`.
- Cyclic (`pauseDays > 0`): `cycleLen = durationDays + pauseDays`; `posInCycle = daysSinceStart % cycleLen`; if `posInCycle < durationDays` → `phase = activeWindow`, `currentDay = posInCycle + 1`; else → `phase = paused`, `currentDay = durationDays`. Always `Active`.
- `daysSinceStart < 0` (future-dated start): treat as `activeWindow`, `currentDay = 1` (not yet started but listed as active). Edge captured by a test.

## Read contract (Dart signatures — no REST/GraphQL)

### Data source — `medication_local_data_source.dart`
```dart
/// Watched left-outer join of medications ⨝ time_slots. Re-emits on any change
/// to either table. medications with no slots yield a single null-slot row.
Stream<List<(MedicationRow, List<TimeSlotRow>)>> watchAllMedications();
```

### Repository — contract `medication_repository.dart`, impl `…_impl.dart`
```dart
/// Reactive read of all persisted medications. Emits Right(list) per change;
/// any data-source/mapping error is caught and emitted as Left(Failure).
Stream<Either<Failure, List<Medication>>> watchAll();
```
Impl (async* + try): `yield Right(rows.map((r) => medicationFromRows(r.$1, r.$2)).toList())`; on throw `yield Left(Failure.unknown(e, st))`.

### Provider — `medication_providers.dart` (composition seam)
```dart
@riverpod
Stream<List<Medication>> medicationsList(Ref ref) =>
    ref.watch(medicationRepositoryProvider).watchAll()
       .map((either) => either.fold((f) => throw f, (meds) => meds));
// Exposes AsyncValue<List<Medication>>.
```

## Presentation view-model (pure shaping; `presentation/view_models/`)
`MedsListView buildMedsListView({required List<Medication> meds, required DateTime now, required MedsFilter filter, required String query})`:
1. derive `(activity, progress)` per med via the domain functions,
2. apply `query` (case-insensitive substring on `name`),
3. apply `filter` (`all` keeps everything; `active` drops `completed`),
4. split into `continuous` / `course` lists, each sorted by `name` (case-insensitive),
5. return the two lists + a `totalCount` (for the no-meds-at-all empty state).

`MedsFilter` — presentation enum `{ all, active }` (selected chip state; no `archive` this slice).

## New l10n keys (add to `app_en.arb`, `app_de.arb`, `app_uk.arb`)

| Key | en | uk (design) | Notes |
|-----|----|----|-------|
| `medsListTitle` | My medications | Мої ліки | app-bar title |
| `medsListSearchHint` | Search medications… | Пошук ліків… | search field placeholder |
| `medsListSearchTooltip` | Search | Пошук | search icon button tooltip |
| `medsListFilterAll` | All | Всі | filter chip |
| `medsListFilterActive` | Active | Активні | filter chip |
| `medsListSectionContinuous` | Continuous | Постійні | section header |
| `medsListSectionCourse` | Courses | Курсові | section header |
| `medsListSectionEmpty` | Nothing found | Нічого не знайдено | per-section empty (filter/search) |
| `medsListEmptyTitle` | No medications yet | Поки що немає ліків | top-level empty (zero meds) |
| `medsListEmptyBody` | Tap + to add your first medication | Натисніть +, щоб додати ліки | top-level empty subtitle |
| `medsListStatusActive` | Active | Активний | status chip |
| `medsListStatusCompleted` | Completed | Завершено | status chip (ended course) |
| `medsListTypeContinuous` | continuous | постійний | type chip |
| `medsListTypeCourseDay` | Day {current}/{total} | День {current}/{total} | type chip (placeholders: int) |
| `medsListTypeCoursePaused` | Paused | Пауза | type chip (cyclic gap) |
| `medsListStock` | {remaining} of {total} pcs | {remaining} з {total} шт | subtitle stock segment (placeholders: int) |
| `doseUnitTablet` | tab | таб | dose-unit abbrev (subtitle) |
| `doseUnitCapsule` | cap | кап | " |
| `doseUnitMl` | ml | мл | " |
| `doseUnitMg` | mg | мг | " |
| `doseUnitDrops` | drops | крап | " |
| `doseUnitUnits` | IU | МО | " (design shows "МО" for Vitamin D3) |
| `doseUnitPuff` | puff | впорск | " |
| `doseUnitApplication` | dose | доза | " |
| `doseUnitSachet` | sachet | саше | " |

> `OQ-1` (spec §8): the exact `uk`/`de` abbreviations above are provisional — finalize against the design during implementation. German translations are authored in the same task (existing `app_de.arb` convention). Parameterized keys (`medsListTypeCourseDay`, `medsListStock`) use ARB `placeholders` with `type: int`.

## Seed set (`kDebugMode`-only, inserted via `repo.add` only when the table is empty)

Stable seed ids (`seed-*`) for idempotency robustness. `now = clock.now()`; dates are relative to `now`. Covers AC-17.

| # | name | form | type | dose | stock | slots | exercises |
|---|------|------|------|------|-------|-------|-----------|
| 1 | Omeprazole | tablet | continuous (start −90d) | 20 mg | 18/30 warn 10 | 08:00, 20:00 | continuous, multi-slot, normal stock |
| 2 | Vitamin D3 | capsule | continuous (start −200d) | 2000 units | — | 14:00 | continuous, no stock, single slot |
| 3 | Magnesium B6 | tablet | continuous (start −40d) | 48 mg | **5/60 warn 10** | 14:00 | **low-stock** (red) |
| 4 | Amoxicillin | capsule | course non-cyclic (start −2d, dur 7, pause 0) | 500 mg | 12/14 warn 4 | 08:00, 14:00, 20:00 | active non-cyclic course, `Day 3/7` |
| 5 | Mexiprim | injection | course cyclic (start −6d, dur 30, pause 7) | 125 mg | — | 14:00, 20:00 | cyclic course in active window |
| 6 | Vitamin B12 | injection | course cyclic (start −31d, dur 10, pause 20) | 1 ml | — | 09:00 | cyclic course in **paused** gap |
| 7 | Azithromycin | tablet | course non-cyclic (start −10d, dur 5, pause 0) | 500 mg | — | 09:00 | **Completed** course (Active filter hides it) |
| 8 | Salbutamol | inhaler | continuous (start −15d) | 2 puff | — | 08:00, 20:00 | inhaler form |
| 9 | Nasal drops | drops | course non-cyclic (start −1d, dur 5, pause 0) | 3 drops | — | 09:00, 21:00 | drops form, short course |
| 10 | Hydrocortisone | cream | continuous (start −20d) | 1 application | — | 08:00 | cream form |
| 11 | Rehydron | sachet | course non-cyclic (start 0d, dur 3, pause 0) | 1 sachet | — | 12:00 | sachet form; start == today (`Day 1/3`) |
| 12 | Ibuprofen syrup | syrup | continuous (start −5d) | 5 ml | — | 08:00, 20:00 | syrup form |

All 8 `MedicationForm` values appear (tablet, capsule, syrup, drops, injection, inhaler, cream, sachet); continuous + non-cyclic + cyclic; with/without dose-vs-stock; a low-stock pack (#3); a paused cyclic (#6); a completed course (#7).
