# Task 001: Full-bleed dividers, group restructure, section-title restyle & spacing

**Agent**: mobile-engineer
**Files**: `lib/features/meds/presentation/widgets/add_medication_modal.dart`
**Depends on**: None
**Blocks**: 002
**Context docs**: None
**Review checkpoint**: Yes

**Description**:
Bring the Add-medication modal's structural separation and vertical rhythm into line with the HTML
template (`dosly_m3_template.html`, `#s-add`). This is a **presentation-only** change: no behavior,
state, persistence, or content is added or removed; Save stays a no-op. All edits are inside one file.

Restructure the modal body from a single outer `Padding(EdgeInsets.all(16))` into the template's three
visual groups, separated by two **full-bleed** hairline dividers (`.s-div`): edge-to-edge, while text
content keeps its 16px horizontal inset. Restyle the two top-level section titles (Intake time,
Intake type) to the muted `.fs-title` token. Add a bottom spacer below Save. Fold in the three
opted-in spacing corrections (stock note gap, form-option chip padding, picker grid-card padding).

**Change details**:
- In `lib/features/meds/presentation/widgets/add_medication_modal.dart`:
  - **Divider helper** — add a private helper near the other build helpers:
    ```dart
    /// Full-bleed section divider matching the template's `.s-div`
    /// (1px outlineVariant hairline, 4px above / 8px below, edge-to-edge).
    Widget _sectionDivider(ColorScheme colorScheme) => Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outlineVariant,
          ),
        );
    ```
  - **Body restructure** (`_AddMedicationModalState.build`, the `SingleChildScrollView`): replace the
    single `Padding(EdgeInsets.all(16))` wrapping the `Column` with an **outer `Column`
    (`crossAxisAlignment: stretch`) whose children are 3 padded group `Column`s + 2 `_sectionDivider`
    calls** (resolve `final colorScheme = Theme.of(context).colorScheme;` in `build` for the helper):
    - **Group A** `Padding(EdgeInsets.fromLTRB(16, 16, 16, 8))` → inner `Column(stretch)`: name
      `TextField`; `SizedBox(16)` + `_MedicationFormPicker`; then the existing
      `if (selectedForm?.hasDose) ...[SizedBox(16), _DoseField]`,
      `if (selectedForm?.hasQuantity) ...[SizedBox(16), _QuantityStepper]`,
      `if (selectedForm?.hasStock) ...[SizedBox(16), _StockCard]` blocks **unchanged**.
    - `_sectionDivider(colorScheme)` — **Divider A**.
    - **Group B** `Padding(EdgeInsets.fromLTRB(16, 0, 16, 8))` → inner `Column(stretch)`:
      `SizedBox(4)` + Intake-time title + `SizedBox(12)` + `_TimeChips(...)` (same args).
    - `_sectionDivider(colorScheme)` — **Divider B**.
    - **Group C** `Padding(EdgeInsets.symmetric(horizontal: 16))` → inner `Column(stretch)`:
      `SizedBox(4)` + Intake-type title + `SizedBox(12)` + `SegmentedButton<_IntakeType>(...)` (same
      args/keys); then existing `if (_intakeType == _IntakeType.course) ...[SizedBox(16), _CourseCard]`
      unchanged; then `SizedBox(16)` + Save `FilledButton.icon(...)` (same no-op `onPressed: () {}`,
      icon, label); then **`SizedBox(height: 24)`** as the bottom spacer.
  - **Section-title restyle** (both the Intake-time title and Intake-type title `Text` widgets):
    change `style: Theme.of(context).textTheme.titleSmall` →
    `style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colorScheme.onSurfaceVariant)`.
    (The 4px-above / 12px-below gaps come from the `SizedBox(4)` / `SizedBox(12)` added above.)
    Do **NOT** change `_StockCard`/`_CourseCard` headers.
  - **Spacing nit 1 — stock card**: in `_StockCard.build`, the header→note gap `SizedBox(height: 4)`
    → `SizedBox(height: 8)`.
  - **Spacing nit 2 — form-option chip**: in `_MedicationFormPickerState._buildChip`, the chip
    `Container` padding `EdgeInsets.symmetric(horizontal: 10, vertical: 8)` →
    `EdgeInsets.symmetric(horizontal: 12, vertical: 10)`.
  - **Spacing nit 3 — grid card**: in `_MedicationFormPickerState._buildGrid`, the card `Container`
    padding `EdgeInsets.fromLTRB(12, 10, 12, 12)` → `EdgeInsets.fromLTRB(12, 12, 12, 14)`.
  - **Library dartdoc**: update the file-header `library` doc comment to mention the three-group layout
    and the two full-bleed section dividers.

**Status**: Complete

**Done when**:
- [x] `_sectionDivider` helper exists and is invoked **exactly twice** in `build`.
- [x] `build` no longer contains `EdgeInsets.all(16)`; group `Column`s are wrapped with
      `EdgeInsets.symmetric(horizontal: 16)` / `EdgeInsets.fromLTRB(16, …)`, and the two dividers are
      direct children of the outer stretch `Column` (no horizontal inset).
- [x] Both section-title `Text`s use `titleSmall?.copyWith(color: colorScheme.onSurfaceVariant)`;
      `_StockCard`/`_CourseCard` headers are unchanged.
- [x] A `SizedBox(height: 24)` follows the Save `FilledButton.icon`.
- [x] Stock head→note gap = `SizedBox(height: 8)`; chip padding = `symmetric(horizontal: 12, vertical: 10)`;
      grid card padding = `fromLTRB(12, 12, 12, 14)`.
- [x] Save remains a no-op (`onPressed: () {}`); all `ValueKey('medsAdd*')` selectors unchanged; no new
      l10n keys; titles still use `medsAddTimeTitle` / `medsAddIntakeTypeTitle`.
- [x] `dart analyze` passes on the changed file (no `!`, no `dynamic`, no hardcoded colors).
- [x] `flutter test` — existing suite passes unchanged.

**Spec criteria addressed**: AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8, AC-9, AC-10, AC-12

## Completion Notes

**Completed**: 2026-06-16
**Files changed**: `lib/features/meds/presentation/widgets/add_medication_modal.dart`
**Contract**: Expects [3/3 verified] | Produces [4/4 verified]
**Verification**: `dart analyze` clean; `flutter test` 324/324 pass (existing suite unchanged).
**Code review**: APPROVE with warnings — one consistency nit (`build` cached `colorScheme` but not
`textTheme`); fixed via repair agent (`final textTheme = Theme.of(context).textTheme;` added, two title
styles updated to use it).
**Notes**: The two `EdgeInsets.all(16)` that remain in the file are the `_StockCard`/`_CourseCard`
card container paddings (outside `build`) — correctly untouched. The app's `DividerThemeData` already
defaults to `outlineVariant`/`thickness:1`; the helper re-specifies them for self-documentation (safe,
slightly redundant). Dividers are full-bleed because `indent`/`endIndent` default to 0 and the helper
is a direct child of the un-padded outer `Column`.

## Contracts

### Expects
- `add_medication_modal.dart` defines `_AddMedicationModalState` whose `build` returns a `Scaffold`
  with a `SingleChildScrollView` body wrapping content in `Padding(... EdgeInsets.all(16))`.
- The two section titles render `context.l10n.medsAddTimeTitle` and
  `context.l10n.medsAddIntakeTypeTitle` with `Theme.of(context).textTheme.titleSmall`.
- Private widgets `_StockCard`, `_MedicationFormPicker` (with `_buildChip`/`_buildGrid`), and
  `_CourseCard` exist in the same file.

### Produces
- `add_medication_modal.dart` declares `_sectionDivider(ColorScheme` and calls `_sectionDivider(`
  exactly twice; the helper builds a `Divider(` with `thickness: 1` and
  `color: colorScheme.outlineVariant` inside `EdgeInsets.only(top: 4, bottom: 8)`.
- `EdgeInsets.all(16)` no longer appears in `build`; group sections use
  `EdgeInsets.symmetric(horizontal: 16)` / `EdgeInsets.fromLTRB(16,`.
- Both section-title `Text`s use `titleSmall?.copyWith(color: colorScheme.onSurfaceVariant)`.
- `SizedBox(height: 24)` appears after `FilledButton.icon`; `_StockCard` contains `SizedBox(height: 8)`
  for the head→note gap; `_buildChip` uses `EdgeInsets.symmetric(horizontal: 12, vertical: 10)`;
  `_buildGrid` uses `EdgeInsets.fromLTRB(12, 12, 12, 14)`.
