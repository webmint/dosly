# Task 009: Widget tests for edit-mode pre-fill, save routing, and tile tap

**Agent**: qa-engineer
**Files**: `test/features/meds/presentation/widgets/add_medication_modal_test.dart`, `test/features/meds/presentation/widgets/medication_tile_test.dart`
**Depends on**: 007, 008
**Context docs**: None
**Review checkpoint**: Yes

**Description**:
Add the presentation tests proving edit mode works end to end and the tile is tappable, without regressing the add-flow tests. Reuse the existing harness/fakes (the `_FakeMedicationRepository.update` recording stub was added in Task 002). Cover edit-mode pre-fill, edit Save routing through `editMedicationProvider`, the edit title, and the tile `onTap`/`InkWell`.

**Change details**:
- In `test/features/meds/presentation/widgets/add_medication_modal_test.dart`:
  - Add an **edit-mode** group that pumps `AddMedicationModal(initial: <fixture medication>)` inside a `ProviderScope` overriding `editMedicationProvider` with a fake-backed `EditMedication` (mirror the existing `addMedicationProvider.overrideWith` pattern). Use a fixture covering a quantity form (e.g. tablet) with stock + multiple time chips, and a course type.
  - Assert pre-fill: the name field shows the medication's name; the form picker's collapsed display shows the medication's form (not the placeholder); the intake-time chips match the medication's slots; the intake-type segmented shows Course; the course duration/pause/start fields are populated. Assert the app-bar title is `medsEditTitle` ("Edit medication").
  - Assert save routing: editing a field and tapping Save invokes the overridden `editMedicationProvider` (the fake records an `update`), shows the `medsEditSaveSuccess` SnackBar, and pops. Assert that `addMedicationProvider` is NOT invoked in edit mode.
  - Keep all existing add-mode tests; optionally assert add mode still shows `medsAddTitle` and routes to `addMedicationProvider` (regression guard for AC-14).
- In `test/features/meds/presentation/widgets/medication_tile_test.dart`:
  - Add a test that pumps a `MedicationTile` with an `onTap` spy and asserts tapping the tile invokes it; assert an `InkWell` is present (`find.byType(InkWell)`).
  - Add/keep a test that a tile with no `onTap` still renders its content (default unchanged).

**Status**: Complete

**Done when**:
- [x] Edit-mode modal tests assert pre-fill (name, form display, chips, segmented Course, course fields) and the `medsEditTitle` title.
- [x] An edit-save test asserts `editMedicationProvider` is invoked (and the edited value forwarded), `medsEditSaveSuccess` shows, the modal pops, and `addMedicationProvider` is not used.
- [x] Tile tests assert `onTap` fires on tap and an `InkWell` is present (scoped to the tile); the no-`onTap` default render is covered.
- [x] `flutter test` passes for both files (and the full suite still green); `dart analyze` clean.

## Completion Notes
**Completed**: 2026-06-19
**Files changed**: `add_medication_modal_test.dart`, `medication_tile_test.dart`
**Contract**: Expects [2/2 verified] | Produces [2/2 verified]
**Notes**: 5 edit-mode modal tests + 3 tile-tap tests (69 in the two files, 255 full meds suite pass). Routing proof is conclusive — both providers overridden to one recording fake; assert `capturedUpdate != null` AND `captured == null` (edit taken, add not). Code review (CONVERGENCE CHECKPOINT) = APPROVE WITH WARNINGS → applied: (W3) assert `capturedUpdate?.name == 'Ibuprofen 400mg'` (proves the EDITED value forwarded, not the original); (W1) `withClock` now wraps the full save test body; (W2) tile InkWell assertion scoped via `find.descendant(of: MedicationTile, ...)` so removing the tile's own InkWell fails. Locale pinned `en` for deterministic strings.

## Contracts

### Expects
- `AddMedicationModal({Medication? initial})`, edit-mode title/success wiring, and `editMedicationProvider` exist (Task 007).
- `MedicationTile` has `onTap` + `InkWell` (Task 008); the modal-test `_FakeMedicationRepository` defines a recording `update` (Task 002).

### Produces
- `add_medication_modal_test.dart` contains an edit-mode group asserting pre-fill, `medsEditTitle`, and a Save path that exercises `editMedicationProvider` (not `addMedicationProvider`).
- `medication_tile_test.dart` asserts `onTap` is invoked on tap and `find.byType(InkWell)` matches.

**Spec criteria addressed**: AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-12, AC-13, AC-14, AC-16
