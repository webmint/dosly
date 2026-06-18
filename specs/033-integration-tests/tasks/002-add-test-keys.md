# Task 002: Add stable ValueKeys to the Meds FAB, form picker, and form chips

**Agent**: mobile-engineer
**Files**: `lib/features/meds/presentation/screens/meds_screen.dart`, `lib/features/meds/presentation/widgets/add_medication_modal.dart`
**Depends on**: None
**Blocks**: 005
**Context docs**: `specs/033-integration-tests/spec.md` (Affected Areas)
**Review checkpoint**: No

**Description**:
Add behavior-preserving `ValueKey`s to the production widgets the integration-test driver must locate: the Meds add-medication FAB, the medication-form picker toggle row, and each of the 8 form chips. These are additive keys only — no layout, style, or behavior change. The existing 393 tests must still pass.

**Change details**:
- In `lib/features/meds/presentation/screens/meds_screen.dart`:
  - On the `FloatingActionButton` (in `MedsScreen.build`), add `key: const ValueKey('medsAddFab')`.
- In `lib/features/meds/presentation/widgets/add_medication_modal.dart`:
  - On the form-picker display row `InkWell` inside `_MedicationFormPicker.build` (the tappable `InputDecorator` row), add `key: const ValueKey('medsFormPickerToggle')`.
  - In `_MedicationFormPickerState._buildChip`, add `key: ValueKey('medsForm_${option.key}')` to the chip's root `InkWell` (yields `medsForm_tablet` … `medsForm_sachet`).

**Done when**:
- [x] FAB has `key: const ValueKey('medsAddFab')`
- [x] Form-picker toggle row has `key: const ValueKey('medsFormPickerToggle')`
- [x] Each form chip has `key: ValueKey('medsForm_${option.key}')`
- [x] `flutter test` — all 393 existing tests still pass (no behavior change)
- [x] `dart analyze` passes on both files

**Spec criteria addressed**: AC-9

## Contracts

### Expects
- `meds_screen.dart` contains a `FloatingActionButton(` with no `key:` argument
- `add_medication_modal.dart` `_buildChip` returns an `InkWell(` with no `key:` argument
- `add_medication_modal.dart` `_MedFormOption` has a `final String key;` field used as `option.key`

### Produces
- `meds_screen.dart` contains `ValueKey('medsAddFab')`
- `add_medication_modal.dart` contains `ValueKey('medsFormPickerToggle')`
- `add_medication_modal.dart` contains `ValueKey('medsForm_${option.key}')`

## Completion Notes

**Status**: Complete
**Completed**: 2026-06-18
**Files changed**: `lib/features/meds/presentation/screens/meds_screen.dart` (FAB key, line 44), `lib/features/meds/presentation/widgets/add_medication_modal.dart` (toggle key line 311, chip key line 442)
**Contract**: Expects [3/3 verified] | Produces [3/3 verified]
**Notes**: Additive `ValueKey`s only. FAB + toggle use `const ValueKey` (literal); chip key is non-const (`option.key` interpolation) — satisfies `prefer_const_constructors`. `dart analyze`: No issues. `flutter test`: 393/393 pass → behavior preserved (AC-9). Code review skipped: 3-key additive change fully guarded by the passing suite; contract self-verified.
