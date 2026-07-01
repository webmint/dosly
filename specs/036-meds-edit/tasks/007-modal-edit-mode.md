# Task 007: Parameterize the modal for edit mode + seed the form picker

**Agent**: mobile-engineer
**Files**: `lib/features/meds/presentation/widgets/add_medication_modal.dart`
**Depends on**: 003, 006
**Context docs**: `docs/features/meds.md`
**Review checkpoint**: Yes

**Description**:
Make `AddMedicationModal` serve both add and edit by adding an optional `Medication? initial`. When non-null, pre-fill every field in `initState`, render edit-mode chrome (title `medsEditTitle`, success `medsEditSaveSuccess`), and route Save to `editMedicationProvider`. Give `_MedicationFormPicker` an `initialFormKey` so its collapsed display shows the medication's form on first build. **This is the highest-regression-risk task** — the add path (`initial == null`) and the picker's behavior when `initialFormKey == null` must stay byte-identical so specs 026–034 tests pass untouched (AC-14, AC-6).

**Change details**:
- `_MedicationFormPicker`:
  - Add `final String? initialFormKey;` and accept it in the constructor (keep `onFormSelected` required).
  - Add `initState` that seeds `_selectedIndex` once: `final i = initialFormKey == null ? -1 : _medFormOptions.indexWhere((o) => o.key == initialFormKey); _selectedIndex = i < 0 ? null : i;`. When `initialFormKey == null` the picker behaves exactly as before (placeholder, `_selectedIndex == null`). Do NOT call `onFormSelected` from `initState` (the parent seeds its own `_selectedForm`).
- `AddMedicationModal`:
  - Add `final Medication? initial;` with `const AddMedicationModal({super.key, this.initial});` (const ctor preserved for add callers).
  - In `_AddMedicationModalState.initState`, when `widget.initial != null`, pre-fill from the medication (all derivable without `BuildContext`):
    - `_nameController.text = initial.name`.
    - Resolve the form option: `_selectedForm = _medFormOptions.firstWhere((o) => o.key == initial.form.name, orElse: ...)` and pass `initialFormKey: initial.form.name` to the picker in `build`.
    - Dose: if `_selectedForm.hasQuantity` → `_quantity = initial.dosePerIntake?.amount ?? _selectedForm.quantityMin`; if `_selectedForm.hasDose` → `_doseController.text = _formatQuantity(initial.dosePerIntake?.amount ?? 0)` and `_selectedDoseUnitIndex = _selectedForm.doseUnitValues.indexOf(unit)` clamped to `>= 0` (default 0 if not found).
    - Stock: if `_selectedForm.hasStock` and `initial.stock != null` → fill `_stockRemainingController`/`_stockTotalController`/`_stockWarnController` from `stock.remaining`/`total`/`warnAt`.
    - Times: `_intakeTimes` ← `initial.schedule.slots.map((s) => TimeOfDay(hour: s.minuteOfDay ~/ 60, minute: s.minuteOfDay % 60))`, then sort ascending by minutes-key (reuse the existing sort).
    - Intake type: `ContinuousType` → `_intakeType = _IntakeType.continuous`; `CourseType(:startDate, :durationDays, :pauseDays)` → `_intakeType = _IntakeType.course`, `_durationController.text = durationDays.toString()`, `_pauseController.text = pauseDays.toString()`, `_startDate = DateTime(startDate.year, startDate.month, startDate.day)` (UTC calendar date → local dateOnly; the save path re-wraps to UTC).
  - Title: `Text(widget.initial == null ? context.l10n.medsAddTitle : context.l10n.medsEditTitle)`.
  - Save (`_onSave`): keep the input-building logic; branch the call — `widget.initial == null` → `ref.read(addMedicationProvider).call(...)` (unchanged); else → `ref.read(editMedicationProvider).call(original: widget.initial!, ...)` passing the same edited fields. On `Right`, show `widget.initial == null ? medsAddSaveSuccess : medsEditSaveSuccess`, then pop. Error mapping (field → message) stays shared. Preserve the capture-context-before-await idiom and `_isSaving` disable. (Use a local non-null `final original = widget.initial;` with an `if (original != null)` guard rather than `!` if feasible; a single guarded `!` at the call site is acceptable only if the value is provably non-null in that branch.)
  - Save button label stays `medsAddSaveButton` in both modes.

**Status**: Complete

**Done when**:
- [x] `AddMedicationModal` has a `final Medication? initial` field and a const constructor accepting it; add callers (`const AddMedicationModal()`) still compile.
- [x] `_MedicationFormPicker` accepts `initialFormKey` and seeds `_selectedIndex` from it; with `initialFormKey == null` it shows the placeholder (existing picker tests pass).
- [x] In edit mode the title is `medsEditTitle`, Save calls `editMedicationProvider`, and success shows `medsEditSaveSuccess`; in add mode all three are the add equivalents.
- [x] Pre-fill covers name, form, dose/quantity, stock, time chips, intake type, and course fields.
- [x] No `!` on `widget.initial` without a provable non-null guard; `dart analyze` clean; existing add-flow tests still pass.

## Completion Notes
**Completed**: 2026-06-19
**Files changed**: `lib/features/meds/presentation/widgets/add_medication_modal.dart`
**Contract**: Expects [2/2 verified] | Produces [3/3 verified]
**Notes**: Add flow byte-identical when `initial == null` (54 add-flow + 247 meds tests pass). Pre-fill in `initState` (no context); picker seeds `_selectedIndex` from `initialFormKey` without firing `onFormSelected`; exhaustive `MedicationType` switch; UTC-calendar→local date round-trip. Code review (CHECKPOINT) = APPROVE WITH WARNINGS → applied 4 fixes: (W1) defensive `where(...).firstOrNull`-style form lookup (no `StateError` on unknown form); (W2) corrected now-stale library header + `_onSave` dartdoc (no lying comments, §3.5); (Fix 3) **spec-compliance** — edit now preserves fields the form doesn't collect: passes `notes: original.notes` (was wiping notes via `copyWith(notes:null)`) and preserves an already-Continuous medication's `startDate` instead of restamping today. No `!`; analyze clean.

## Contracts

### Expects
- `editMedicationProvider` exists (Task 003); `AppLocalizations` exposes `medsEditTitle`/`medsEditSaveSuccess` (Task 006).
- `AddMedicationModal` is a `ConsumerStatefulWidget`; `_MedicationFormPicker` keeps `_selectedIndex`/`_isOpen` and an `onFormSelected` callback; `_medFormOptions[i].key` equals the `MedicationForm` enum name.

### Produces
- `AddMedicationModal` declares `final Medication? initial` and `const AddMedicationModal({super.key, this.initial})`.
- `_MedicationFormPicker` declares `final String? initialFormKey` and seeds `_selectedIndex` in `initState`.
- `add_medication_modal.dart` references `editMedicationProvider`, `medsEditTitle`, and `medsEditSaveSuccess`, branched on `widget.initial == null`.

**Spec criteria addressed**: AC-3, AC-4, AC-5, AC-6, AC-12, AC-14
