# Task 010: Document the edit/update path

**Agent**: tech-writer
**Files**: `docs/features/medication-persistence.md`, `docs/features/meds.md`
**Depends on**: 008, 009
**Context docs**: `specs/036-meds-edit/spec.md`, `specs/036-meds-edit/plan.md`
**Review checkpoint**: No

**Description**:
Update the feature docs to cover the new medication-edit/update path now that it ships. Document the `update` contract through all three layers and the modal's add/edit dual mode, and retire the now-false "editing not included" note.

**Change details**:
- In `docs/features/medication-persistence.md`:
  - Add an "Update / Edit" subsection mirroring the existing "Save Flow" diagram: `AddMedicationModal(initial:)` → `editMedicationProvider` → `EditMedication` (validate → reconcile slot ids → `copyWith` preserving id/createdAt) → `MedicationRepository.update` → `MedicationRepositoryImpl` → `MedicationLocalDataSource.upsertMedication` (transaction: `insertOnConflictUpdate` med row, delete removed slots, upsert the rest).
  - Document the **`insertOnConflictUpdate` (not `insertOrReplace`)** rationale w.r.t. the `onDelete: cascade` FK, and the slot-ID preservation rule (same `minuteOfDay` keeps its `TimeSlotId`).
  - In "What This Feature Does NOT Include", remove/adjust the "Editing … beyond add" bullet (editing now exists; deleting still does not).
- In `docs/features/meds.md`:
  - Note that `AddMedicationModal` now has a `Medication? initial` add/edit dual mode (edit-mode title `medsEditTitle`, success `medsEditSaveSuccess`, Save routes to `editMedicationProvider`) and that `_MedicationFormPicker` accepts `initialFormKey` to pre-select.
  - Add the two new l10n keys (`medsEditTitle`, `medsEditSaveSuccess`) to the localization-keys listing.
- Do not document code that did not change; keep edits scoped to the edit feature.

**Status**: Complete

**Done when**:
- [x] `medication-persistence.md` documents the update flow, the `insertOnConflictUpdate` cascade rationale, and the slot-ID preservation rule.
- [x] The "does NOT include" list no longer claims editing is unsupported (delete remains listed as unsupported).
- [x] `meds.md` documents the modal's `initial` dual mode, the picker `initialFormKey`, and the two new l10n keys.
- [x] Markdown is well-formed; internal references resolve.

## Completion Notes
**Completed**: 2026-06-19
**Files changed**: `docs/features/medication-persistence.md`, `docs/features/meds.md`
**Contract**: Expects [1/1 verified] | Produces [2/2 verified]
**Notes**: Added "Update / Edit Flow (end to end)" diagram + "Load-bearing decisions" (insertOnConflictUpdate-vs-insertOrReplace cascade rationale, slot-ID preservation incl. doseOverride, round-trip-unchanged fields) + `editMedicationProvider` wiring + feature-036 l10n keys to medication-persistence.md; retired the "editing not supported" / hypothetical-update-path notes (delete stays listed as unsupported). Added the modal `initial` dual-mode + `_MedicationFormPicker.initialFormKey` + tile tap-to-edit wiring + new l10n keys to meds.md. Verified the new persistence-doc section against the shipped code (accurate — no invented APIs). No code review needed (pure markdown by the docs specialist; accuracy spot-checked directly).

## Contracts

### Expects
- The implementation tasks are complete: `EditMedication`, `editMedicationProvider`, `MedicationRepository.update`, `upsertMedication`, modal `initial`, picker `initialFormKey`, tile `onTap` (Tasks 001–008).

### Produces
- `docs/features/medication-persistence.md` describes the `update`/`EditMedication`/`upsertMedication` path and the `insertOnConflictUpdate` rationale.
- `docs/features/meds.md` describes the modal add/edit dual mode and `initialFormKey`.

**Spec criteria addressed**: (documentation — supports AC-1 … AC-16 traceability)
