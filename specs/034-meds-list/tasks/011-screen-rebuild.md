# Task 011: Rebuild `MedsScreen` (search / filter / sections / states)

**Agent**: mobile-engineer
**Files**: `lib/features/meds/presentation/screens/meds_screen.dart` (modify)
**Depends on**: 005, 006, 009, 010
**Blocks**: 012
**Context docs**: `specs/034-meds-list/spec.md` (§3.3–3.5), `specs/034-meds-list/plan.md`
**Review checkpoint**: Yes

**Description**:
Replace the placeholder body with the real list. Convert `MedsScreen` to a `ConsumerStatefulWidget` holding the ephemeral search query + selected `MedsFilter` (UI state, `setState`). Watch `medicationsListProvider`, read `clock.now()` once per build, run `buildMedsListView`, and render the Continuous/Course sections, the All/Active filter chips, the search app-bar, and the loading/error/empty states. Keep the existing FAB (`medsAddFab`) that opens the add modal.

**Change details**:
- `meds_screen.dart`:
  - `ConsumerStatefulWidget`; state holds `String _query = ''` (+ a `TextEditingController`, disposed in `dispose`) and `MedsFilter _filter = MedsFilter.all`.
  - app-bar: title `medsListTitle`; a search toggle (icon → expanding `TextField` with `medsListSearchHint`/`medsListSearchTooltip`) updating `_query` on change (with clear).
  - filter chips row: `medsListFilterAll` / `medsListFilterActive` (Material 3 `FilterChip`/`ChoiceChip`, ≥48dp), selecting `_filter`.
  - body: `ref.watch(medicationsListProvider).when(loading: CircularProgressIndicator, error: <error view>, data: (meds) { final view = buildMedsListView(meds: meds, now: clock.now(), filter: _filter, query: _query); ... })`.
  - when `view.totalCount == 0` → top-level empty state (`medsListEmptyTitle` + `medsListEmptyBody`); else a scroll view with `MedicationSection(continuous)` + `MedicationSection(course)`.
  - keep the FAB + the existing `_openAddMedicationModal` (rootNavigator full-screen route).
  - `import 'package:clock/clock.dart';`.

**Done when**:
- [x] Screen watches `medicationsListProvider` and handles loading/error/data (all three branches).
- [x] Filter chips + search update the visible list reactively; `clock.now()` feeds `buildMedsListView`.
- [x] Top-level empty state shows only when there are zero meds; sections render otherwise; FAB intact.
- [x] `dart analyze` clean; no `BuildContext`-after-`await` without `mounted`.

**Spec criteria addressed**: AC-7, AC-10, AC-11, AC-12, AC-14

## Completion Notes
**Status**: Complete
**Completed**: 2026-06-18
**Files changed**: meds_screen.dart (placeholder → ConsumerStatefulWidget)
**Contract**: Expects 4/4 verified | Produces 1/1 verified
**Notes**: Ephemeral `setState` UI state (`_query`, `_filter`, `_searchOpen`, disposed `TextEditingController`); `clock.now()` in build → `buildMedsListView`; all three `AsyncValue` branches; `totalCount==0` → top-level empty state (per-section "Nothing found" handled by MedicationSection for filtered/search-empty); FAB preserved; 88px bottom padding for FAB clearance. **Code-reviewer (convergence/layer-crossing checkpoint): APPROVE** — no critical/warnings requiring fixes. (`?? const TextStyle()` confirmed correct: `TextTheme.*` is nullable in SDK 3.41.4.)

## Contracts

### Expects
- Task 005 (`medicationsListProvider` → `AsyncValue<List<Medication>>`), Task 009 (`buildMedsListView`, `MedsFilter`), Task 010 (`MedicationSection`), Task 006 (`medsListTitle`/`medsListFilter*`/`medsListSearchHint`/`medsListEmpty*`).

### Produces
- `meds_screen.dart` declares a `ConsumerStatefulWidget` that calls `ref.watch(medicationsListProvider)`, `buildMedsListView(`, and renders `MedicationSection`; retains the `medsAddFab` FAB.
