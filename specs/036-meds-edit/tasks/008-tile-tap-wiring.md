# Task 008: Wire tile tap → open the edit modal (tile, section, screen)

**Agent**: mobile-engineer
**Files**: `lib/features/meds/presentation/widgets/medication_tile.dart`, `lib/features/meds/presentation/widgets/medication_section.dart`, `lib/features/meds/presentation/screens/meds_screen.dart`
**Depends on**: 007
**Context docs**: None
**Review checkpoint**: No

**Description**:
Make a list tile tappable and route the tap to the pre-filled edit modal. The tile stays a dumb widget — it gains an optional `onTap` and an `InkWell`; the section threads a per-item callback; the screen supplies it via a new `_openEditMedicationModal` that pushes `AddMedicationModal(initial: medication)` exactly like the FAB pushes the add modal. This is the end-to-end convergence that makes the feature usable.

**Change details**:
- In `lib/features/meds/presentation/widgets/medication_tile.dart`:
  - Add `final VoidCallback? onTap;` to `MedicationTile` (keep `required this.item`).
  - Wrap the tile's content in an `InkWell(onTap: onTap, child: ...)` (NOT a raw `GestureDetector`, §4.3.1). Keep the root `ValueKey('medTile-${item.medication.id.value}')` on the outermost widget for stable identity. With `onTap == null` the `InkWell` is non-interactive (no ripple) so the default render is unchanged. The tile is already ≥48 dp tall (48 badge + 12×2 padding).
- In `lib/features/meds/presentation/widgets/medication_section.dart`:
  - Add `final void Function(Medication medication)? onTapItem;` to `MedicationSection`.
  - In `_buildTileList`, pass `onTap: onTapItem == null ? null : () => onTapItem!(items[i].medication)` to each `MedicationTile` (guard the `!` behind the null check, or capture into a local).
- In `lib/features/meds/presentation/screens/meds_screen.dart`:
  - Add a top-level `void _openEditMedicationModal(BuildContext context, Medication medication)` mirroring `_openAddMedicationModal` but `builder: (_) => AddMedicationModal(initial: medication)`.
  - Pass `onTapItem: (med) => _openEditMedicationModal(context, med)` to both `MedicationSection`s (continuous and course).

**Status**: Complete

**Done when**:
- [x] `MedicationTile` has `VoidCallback? onTap` and wraps its content in an `InkWell`; default (no `onTap`) render is visually unchanged and existing tile tests pass.
- [x] `MedicationSection` has `void Function(Medication)? onTapItem` and forwards it per tile.
- [x] `meds_screen.dart` declares `_openEditMedicationModal` constructing `AddMedicationModal(initial: ...)` on the root navigator as a fullscreen dialog, wired to both sections.
- [x] No raw `GestureDetector`; no unguarded `!`; `dart analyze` clean; existing meds widget/screen tests pass.

## Completion Notes
**Completed**: 2026-06-19
**Files changed**: `medication_tile.dart`, `medication_section.dart`, `meds_screen.dart`, + `meds_screen_test.dart` (incidental)
**Contract**: Expects [1/1 verified] | Produces [3/3 verified]
**Notes**: Tile gains `onTap` + `InkWell` (root `Opacity` keeps `ValueKey('medTile-<id>')`); section threads `onTapItem` (non-null local capture, no `!`); screen `_openEditMedicationModal` mirrors `_openAddMedicationModal` with `AddMedicationModal(initial:)`. **Incidental (justified)**: the pre-existing `meds_screen_test.dart` "AC-13 tile not tappable" test (asserting spec-034's deferred-navigation behavior) was rewritten to "tile tappable → modal opens" — required since this task removes that deferral. Code review = APPROVE (1 warning: `InkWell` inside `Opacity` could mis-clip ripple if the tile is ever reused inside a `Card`/clip — not an issue in the current `Scaffold`-body column; noted for future reuse). 152 presentation tests pass; analyze clean.

## Contracts

### Expects
- `AddMedicationModal({Medication? initial})` exists (Task 007); `MedicationTile`, `MedicationSection`, `MedsScreen`, `_openAddMedicationModal` exist; `MedListItem.medication` is a `Medication`.

### Produces
- `medication_tile.dart` declares `final VoidCallback? onTap` on `MedicationTile` and contains an `InkWell(`.
- `medication_section.dart` declares `final void Function(Medication` (the `onTapItem` callback) and forwards it to `MedicationTile`.
- `meds_screen.dart` declares `_openEditMedicationModal(` and constructs `AddMedicationModal(initial:`.

**Spec criteria addressed**: AC-1, AC-2
