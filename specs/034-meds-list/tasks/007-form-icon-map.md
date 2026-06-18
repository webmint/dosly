# Task 007: Shared form→icon map + add-modal refactor

**Agent**: mobile-engineer
**Files**: `lib/features/meds/presentation/widgets/medication_form_icon.dart` (new), `lib/features/meds/presentation/widgets/add_medication_modal.dart` (modify)
**Depends on**: None
**Blocks**: 010
**Context docs**: None
**Review checkpoint**: No

**Description**:
Extract the `MedicationForm → IconData` mapping currently hard-coded in `add_medication_modal.dart`'s private `_medFormOptions` into a single shared source of truth, then have the modal consume it. Behavior-preserving (§3.7 DRY, §6.1 minimal change) — the add modal's icons and existing tests must remain identical.

**Change details**:
- `medication_form_icon.dart`: expose `IconData medicationFormIcon(MedicationForm form)` (exhaustive `switch`, no `default`) mapping per the existing modal: tablet→`LucideIcons.tablets`, capsule→`LucideIcons.pill`, syrup→`LucideIcons.milk`, drops→`LucideIcons.droplets`, injection→`LucideIcons.syringe`, inhaler→`LucideIcons.wind`, cream→`LucideIcons.container`, sachet→`LucideIcons.package`.
- `add_medication_modal.dart`: replace the per-option hard-coded `icon:` literals so each `_MedFormOption` derives its icon from `medicationFormIcon(MedicationForm.values.byName(key))` (or build the options from `medicationFormIcon`). Do not change any other modal behavior, labels, or keys.

**Done when**:
- [x] `medicationFormIcon` exists with an exhaustive switch over all 8 forms.
- [x] The add modal sources its form icons from `medicationFormIcon` (no duplicate icon literals remain).
- [x] Existing add-modal tests pass unchanged; `dart analyze` clean.

**Spec criteria addressed**: AC-8 (supporting; tile reuses this map)

## Completion Notes
**Status**: Complete
**Completed**: 2026-06-18
**Files changed**: medication_form_icon.dart (new), add_medication_modal.dart (8 icon literals → `medicationFormIcon(...)` + import), add_medication_modal_test.dart (repair: `watchAll` stubs on 2 fakes)
**Contract**: Expects 2/2 verified | Produces 2/2 verified
**Notes**: Surfaced + fixed a **Task 003 fallout**: the new `watchAll()` interface method broke 2 hand-written `implements MedicationRepository` fakes in the modal test (invisible to `dart analyze lib/`). Repaired with empty-stream stubs. Full project `dart analyze` now clean; all 150 meds tests pass. Logged to MEMORY (analyze `test/` too after interface changes).

## Contracts

### Expects
- `add_medication_modal.dart` defines form options keyed by `MedicationForm` name with `LucideIcons` icons (current state).
- `lucide_icons_flutter` provides `LucideIcons.tablets/pill/milk/droplets/syringe/wind/container/package`.

### Produces
- `medication_form_icon.dart` exports `IconData medicationFormIcon(MedicationForm form)`.
- `add_medication_modal.dart` imports and calls `medicationFormIcon(`.
