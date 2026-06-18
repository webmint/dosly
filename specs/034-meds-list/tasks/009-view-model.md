# Task 009: View-model — filter / search / group / derive (+ tests)

**Agent**: architect
**Files**: `lib/features/meds/presentation/view_models/meds_list_view_model.dart` (new), `test/features/meds/presentation/view_models/meds_list_view_model_test.dart` (new)
**Depends on**: 001
**Blocks**: 010, 011
**Context docs**: `specs/034-meds-list/data-model.md` (view-model section)
**Review checkpoint**: No

**Description**:
Create the pure shaping function that turns `List<Medication>` + `now` + filter + search into the rendered structure, calling the domain derivations for status/progress. Pure and synchronous so it is unit-testable without pumping widgets. The tile and screen consume its output types; no Flutter widgets here beyond plain data classes.

**Change details**:
- `meds_list_view_model.dart`:
  - `enum MedsFilter { all, active }`.
  - `class MedListItem` (`@freezed` or a plain immutable class): `Medication medication`, `MedicationActivityStatus activity`, `CourseProgress? progress` (null for continuous).
  - `class MedsListView`: `List<MedListItem> continuous`, `List<MedListItem> course`, `int totalCount`.
  - `MedsListView buildMedsListView({required List<Medication> meds, required DateTime now, required MedsFilter filter, required String query})`:
    1. map each med → `MedListItem` via `resolveMedicationActivity(med, now)` and (for `CourseType`) `CourseProgress.resolve(course, now)`;
    2. `totalCount` = count of all meds (pre-filter, pre-search) — drives the no-meds empty state;
    3. apply `query` (trim, case-insensitive substring on `medication.name`; empty query = no filtering);
    4. apply `filter` (`all` keeps all; `active` drops items whose `activity == completed`);
    5. split by `medication.type` into `continuous` / `course`, each sorted by `name` (case-insensitive ascending).
- Tests: grouping/sort determinism; `active` filter hides a completed course but keeps continuous + cyclic; case-insensitive search across both sections; `totalCount` reflects pre-filter count; empty `meds` → empty view, `totalCount == 0`.

**Done when**:
- [x] `buildMedsListView` returns correctly grouped/sorted/filtered/searched data with per-item `activity`/`progress`.
- [x] Unit tests cover filter, search, grouping, sort, and `totalCount` — green.
- [x] `dart analyze` clean; build runner run if `MedListItem` uses freezed (generated committed).

**Spec criteria addressed**: AC-7, AC-10, AC-11, AC-12

## Completion Notes
**Status**: Complete
**Completed**: 2026-06-18
**Files changed**: meds_list_view_model.dart (new), meds_list_view_model_test.dart (new, 12 tests)
**Contract**: Expects 1/1 verified | Produces 1/1 verified
**Notes**: Plain immutable classes (no freezed → no codegen step). Pure + `now`-injected (no `clock.now()` inside). Pipeline: derive → totalCount(pre-filter) → search(trim, case-insensitive) → filter(active drops completed) → group by type → sort each by name (case-insensitive). Typed exhaustive `switch` over `MedicationType` (no `default`/`!`). 12/12 green; analyze clean. (Gotcha noted: `prefer_final_locals` requires `final CourseType course =>` in the switch pattern.)

## Contracts

### Expects
- Task 001 `Produces` (`resolveMedicationActivity`, `CourseProgress.resolve`, `MedicationActivityStatus`, `CoursePhase`).
- `Medication` exposes `name`, `type` (`ContinuousType`/`CourseType`).

### Produces
- `meds_list_view_model.dart` exports `enum MedsFilter { all, active }`, `class MedListItem` (`medication`, `activity`, `progress`), `class MedsListView` (`continuous`, `course`, `totalCount`), and `MedsListView buildMedsListView({required List<Medication> meds, required DateTime now, required MedsFilter filter, required String query})`.
