# Task 005: De-emphasise completed tiles + fix course chip order

**Agent**: mobile-engineer
**Files**: `lib/features/meds/presentation/widgets/medication_tile.dart`
**Depends on**: None
**Blocks**: 007
**Context docs**: None
**Review checkpoint**: No

**Description**:
Give completed-course tiles the design's de-emphasised treatment (dim + neutral badge + grey status chip), gated strictly on the derived `Completed` activity so active tiles are provably unchanged. Also reorder chips so course tiles show the type chip (Day X/Y / Paused) before the status chip, matching the design. No constructor/API change.

**Change details**:
- In `lib/features/meds/presentation/widgets/medication_tile.dart`:
  - Add a `final bool isCompleted = item.activity == MedicationActivityStatus.completed;` in `MedicationTile.build`.
  - **Badge**: when `isCompleted`, override `badgeBg`/`badgeFg` to `cs.surfaceVariant` / `cs.onSurfaceVariant` (instead of the type-based primary/tertiary container colours).
  - **Opacity**: wrap the tile's root in `Opacity(opacity: isCompleted ? 0.65 : 1.0, child: ...)` (keep the existing `ValueKey('medTile-<id>')` on the outer widget).
  - **Status chip**: in `_StatusChip`, change the `completed` branch background/foreground from `surfaceContainerHighest`/`onSurfaceVariant` to `surfaceVariant`/`onSurfaceVariant` (grey `.s-chip.grey`).
  - **Chip order**: in `_TileBody`, render the type chip **before** the status chip for `CourseType` items, and keep status-before-type for `ContinuousType` (match the design's per-type order). Implement by branching on `item.medication.type` when building the `Wrap` children — no change to `_StatusChip`/`_TypeChip` internals.
  - Do not change `MedicationTile`'s constructor, the subtitle formatting, or active-tile appearance.

**Status**: Complete

**Done when**:
- [x] A `Completed` tile renders at ~0.65 opacity, a neutral badge, and a grey status chip; an `Active` tile is visually unchanged.
- [x] Course tiles render the type chip before the status chip; continuous tiles render status before type.
- [x] `MedicationTile({required MedListItem item, Key? key})` constructor unchanged.
- [x] `dart analyze` passes (no `!`, exhaustive switches, const where possible).

## Completion Notes
**Completed**: 2026-06-18
**Files changed**: `lib/features/meds/presentation/widgets/medication_tile.dart`
**Contract**: Expects [2/2 verified] | Produces [3/3 verified]
**Notes**: **Token deviation**: `cs.surfaceVariant` is DEPRECATED in this Flutter version (since 3.18.0-0.1.pre) → used `cs.surfaceContainerHighest`, the modern M3 equivalent of the design's `--md-surface-variant` (`surfaceVariant` would fail `dart analyze`). Completed badge = `surfaceContainerHighest`/`onSurfaceVariant`; completed status chip already used `surfaceContainerHighest`, so visual distinction comes from the 0.65 `Opacity` wrapper + neutral badge (vs active's primary/tertiary container). `ValueKey('medTile-<id>')` moved up to the `Opacity` (exactly one in the tree). Chip order via exhaustive `switch (item.medication.type)` — `CourseType` → [type, status], `ContinuousType` → [status, type]. Existing screen test (33) still green.

## Contracts

### Expects
- `MedListItem` exposes `activity` (`MedicationActivityStatus`) and `medication.type` (`ContinuousType`/`CourseType`).
- `MedicationTile` is a `StatelessWidget` taking `{required MedListItem item}`.

### Produces
- `medication_tile.dart` references `MedicationActivityStatus.completed` to gate an `Opacity` wrapper (≈0.65), a `surfaceVariant` icon badge, and a `surfaceVariant` status chip.
- `_TileBody` orders the type chip before the status chip for `CourseType` items.
- `MedicationTile`'s public constructor signature is unchanged.

**Spec criteria addressed**: AC-14, AC-15
