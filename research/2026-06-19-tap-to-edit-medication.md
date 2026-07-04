# Research: Tap-to-Edit Medication (Reusing the Add-Medication Modal)

**Date**: 2026-06-19
**Topic**: "When I tap an item on the medication list I want to edit the medication. If possible reuse the add-medication modal."
**Verdict**: **Feasible with Caveats** — the idea fits cleanly, but "reuse the modal" requires real refactoring (the modal is hardcoded for *add*, and there is no update path in the domain/data layers yet).

## Summary

Tap-to-edit is the natural next step and the code was clearly built anticipating it — `MedicationTile`'s own docs say *"navigation is deferred to a later task."* The add-medication modal **can** be reused, but not as-is: it's a parameterless `ConsumerStatefulWidget` hardwired to the `AddMedication` use case, and its form picker holds private selection state that can't currently be pre-seeded. Reuse means parameterizing the modal with an optional existing `Medication`, pre-filling all fields, and routing Save to a **new `EditMedication` use case**. Separately, the persistence stack has **no update path at all** — `MedicationRepository` exposes only `add()` and `watchAll()` — so that has to be built regardless of which UI approach you pick. None of this needs new dependencies; the reactive list already auto-refreshes on DB updates.

## Codebase Findings

### Existing Related Code

| Area | Files | Relevance |
|------|-------|-----------|
| List tile (tap site) | `presentation/widgets/medication_tile.dart` | **Dumb display widget, explicitly no `InkWell`/`GestureDetector`** — "navigation is deferred to a later task." This is where the tap gets wired. |
| Section wrapper | `presentation/widgets/medication_section.dart` | Renders the tiles; also "NO tap targets." Could pass an `onTap(item)` down, or wrap each tile. |
| The modal to reuse | `presentation/widgets/add_medication_modal.dart` (~1720 lines) | `const AddMedicationModal()` — **no params**. Hardcodes add: title `medsAddTitle`, Save → `addMedicationProvider`, success → `medsAddSaveSuccess` + pop. |
| Launch point | `presentation/screens/meds_screen.dart:389` | `_openAddMedicationModal` pushes via `rootNavigator` `MaterialPageRoute(fullscreenDialog: true)`. An edit launcher would mirror this. |
| Persistence contract | `domain/repositories/medication_repository.dart` | **Only `add()` + `watchAll()`.** No `update`, `getById`, or `delete`. |
| Data source | `data/datasources/medication_local_data_source.dart` | `insertMedication` does a plain `insert` (throws on PK conflict). No update/upsert/delete. |
| Add use case | `domain/usecases/add_medication.dart` | Always mints a **new** `MedicationId` + stamps `createdAt`. Not reusable for edit without branching. |
| Entity | `domain/entities/medication.dart` | Full `freezed` aggregate → `copyWith` makes building the edited medication trivial. |
| View model item | `presentation/view_models/meds_list_view_model.dart` | `MedListItem.medication` gives the full `Medication` at the tap site — everything needed to pre-fill. |

### Patterns Available
- **Composition seam** (`medication_providers.dart`): the one presentation file allowed to import `data/`. A new `editMedicationProvider` slots in next to `addMedicationProvider`.
- **`freezed copyWith`**: rebuild the edited aggregate while preserving `id` + `createdAt`.
- **Reactive list**: the drift join in `watchAllMedications` already fires on `update`, so the list refreshes automatically once an update path writes.
- **Form-state pre-fill idiom**: the modal already owns every controller/field as local state — pre-filling in `initState` is mechanical for most fields.

### Gaps (must be built regardless of UI approach)
- `MedicationRepository.update(Medication)` (or `upsert`) + impl + data-source method (drift `insertOnConflictUpdate`, or update-row + replace-slots in one transaction).
- An `EditMedication` use case (preserve `id`/`createdAt`, re-validate, replace time slots). Constitution **forbids** screens calling repos directly.
- `editMedicationProvider`.
- **The blocker for true reuse**: `_MedicationFormPicker` keeps `_selectedIndex`/`_isOpen` as private state with no way for a parent to inject an initial selection. To pre-fill the form picker in edit mode it needs an `initialFormKey` (or `initialIndex`) parameter.

## Constitution Constraints

| Rule | Impact |
|------|--------|
| §4.1.1 "Screens never call repositories directly" + "wrap … in a use case" | Edit **must** go through an `EditMedication` use case, not a raw repo call from the modal. |
| §3.2 `Either<Failure, T>` everywhere | New repo method + use case return `Future<Either<Failure, T>>`; modal `.fold`s both branches (the add path already does this). |
| §2.1 layer boundaries | New use case is pure-Dart domain; only `medication_providers.dart` touches `data/`. |
| §3.4 Testing (mandatory) | New use case → unit tests (happy/validation/repo-failure). New repo method → in-memory drift test. Edit pre-fill → widget test. |
| §4.3.1 tap targets ≥48dp; prefer `InkWell` with explicit `constraints` over raw `GestureDetector` | Wrap the tile in `InkWell`, not `GestureDetector`. |
| §6.1 Minimal changes | Favors parameterizing the existing modal over a large extraction refactor. |

> Note: §5.2's intake-regeneration concerns don't bite yet — intakes/schedule-resolution aren't implemented, so replacing a medication's `TimeSlot`s on edit (with fresh `TimeSlotId`s) has no downstream intake records to reconcile.

## Approaches

### Option A — Parameterize the existing modal *(recommended)*
- **Description**: Add `AddMedicationModal({Medication? initial})`. In `initState`, when `initial != null`, pre-fill all controllers + local state; branch title / Save label / success text / Save target (`AddMedication` vs `EditMedication`) on add-vs-edit. Add an `initialFormKey` param to `_MedicationFormPicker`.
- **Pros**: True reuse (one form, one set of sub-widgets); smallest surface; respects "minimal changes."
- **Cons**: Touches the well-tested add flow (specs 026–032) — regression risk; the form picker needs an initial-selection param; `initState` pre-fill is a bit fiddly (form → index, dose unit → dropdown index, times → chips, course params).
- **Complexity**: Medium.

### Option B — Extract a shared form body + thin Add/Edit wrappers
- **Description**: Pull the form `Column` into a reusable `MedicationForm` widget taking an optional initial value + an `onSubmit`; `AddMedicationModal` and a new `EditMedicationModal` become thin wrappers.
- **Pros**: Cleanest separation; add/edit semantics fully isolated; easiest to test long-term.
- **Cons**: Bigger refactor of a 1700-line file; higher churn through tested code; arguably premature for a 2-mode form (KISS).
- **Complexity**: Medium-High.

**Recommended**: **Option A** — it's the literal "reuse the add modal" the request asks for, and the constitution prefers minimal change. Revisit Option B only if a third mode (e.g. duplicate) appears.

## Complexity Assessment

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Codebase changes | Medium | ~6–8 files: tile (tap), section/screen (wire onTap + edit launcher), modal (params + pre-fill + save branch), form picker (initial selection), repo contract+impl, data source, new use case, new provider, l10n strings. |
| New dependencies | None | Drift upsert, freezed, Riverpod codegen — all already in use. |
| Risk | Medium | Main risk is regressing the tested add flow and the form picker's internal-state change. Mitigated by Option A's branch-don't-replace strategy + new tests. |

## Recommendation

**Proceed.** Run:

```
/specify "Tap a medication tile to edit it in the existing add-medication modal: wrap MedicationTile in an InkWell that opens AddMedicationModal pre-filled with that medication; add an EditMedication use case + MedicationRepository.update + drift upsert; branch the modal's title/Save/success and Save target on add-vs-edit; add an initialFormKey to the form picker so it pre-selects."
```

`/specify` should pin down a few decisions: (1) whether to add `update` vs a single `upsert` to the repository; (2) whether replacing all `TimeSlot`s on save (fresh IDs) is acceptable; (3) whether a delete affordance belongs in the same feature or a later one. These are the only real open questions — everything else follows existing patterns.
