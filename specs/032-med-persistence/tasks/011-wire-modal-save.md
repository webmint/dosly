# Task 011: Wire the modal Save button to persistence

**Agent**: mobile-engineer
**Files**: `lib/features/meds/presentation/widgets/add_medication_modal.dart`
**Depends on**: 002, 009, 010
**Context docs**: `specs/032-med-persistence/spec.md` (§3 mapping), `.claude/memory/MEMORY.md` (modal pitfalls)
**Review checkpoint**: Yes — first presentation-layer task after the domain/data layers; highest integration risk

**Description**:
Convert `AddMedicationModal` to a `ConsumerStatefulWidget` and replace the no-op Save with a real persistence call: map the current form state to typed domain inputs, invoke `addMedicationProvider`, and handle both branches with SnackBars and an in-flight disable.

**Change details**:
- Change `AddMedicationModal extends StatefulWidget` → `ConsumerStatefulWidget`; `State` → `ConsumerState`.
- Give each `_MedFormOption` dose-unit entry a typed `DoseUnit` (replace/augment the label-only `doseUnits` closures so Save can read the selected unit as a `DoseUnit`); map the quantity unit for tablet/capsule to `DoseUnit.tablet`/`DoseUnit.capsule`. (Hot **restart** after editing the top-level `_medFormOptions` list — MEMORY 2026-06-14.)
- Add `bool _isSaving = false`. Implement `_onSave()`:
  - build `intakeMinutes` = `_intakeTimes.map((t) => t.hour*60 + t.minute)`;
  - build `dosePerIntake` per form (tablet/capsule → `Dosage(amount: _quantity, unit: tablet|capsule)`; syrup/drops/injection → `Dosage(amount: double.parse(_doseController…), unit: selected)`; inhaler/cream/sachet → `null`);
  - build `stock` (tablet/capsule, only when remaining+total parse to non-negative ints, `warnAt` default 0, else `null`);
  - build `type` (continuous → `MedicationType.continuous(startDate: DateTime.utc(today.y,m,d))`; course → `MedicationType.course(startDate: DateTime.utc(_startDate…), durationDays: parse, pauseDays: parse)`);
  - map form `key` → `MedicationForm` (values already match);
  - set `_isSaving = true` (setState), `await ref.read(addMedicationProvider).call(...)`, then `if (!mounted) return;` and `result.fold(...)`:
    - `Left` → set `_isSaving=false`, show error SnackBar (ValidationFailure.field → `medsAddSaveErrorName/Times/Duration`; else `medsAddSaveErrorGeneric`); stay open;
    - `Right` → show `medsAddSaveSuccess` SnackBar and `Navigator.of(context).pop()`.
- `FilledButton.icon`: `onPressed: _isSaving ? null : _onSave` (replaces `onPressed: () {}`). Keep the existing icon/label.
- Preserve all existing form behavior/widgets; do not change unrelated layout.

**Done when**:
- [ ] modal is a `ConsumerStatefulWidget`; Save calls `addMedicationProvider`, no longer a no-op
- [ ] success → SnackBar + pop; failure → localized error SnackBar + stays open; button disabled while saving
- [ ] `mounted` checked after the `await` before using `context`; no `!`/`dynamic`; per-form dose/stock mapping matches §3
- [ ] `dart analyze` passes (incl. `use_build_context_synchronously`)

## Contracts
### Expects
- `addMedicationProvider` exposes `AddMedication` with `call(...)` (task 009)
- `medsAddSaveSuccess`/`...ErrorName`/`...ErrorTimes`/`...ErrorDuration`/`...ErrorGeneric` exist (task 010)
- `MedicationForm`, `DoseUnit`, `Dosage`, `PackStock`, `MedicationType` available (tasks 002–004)
### Produces
- `add_medication_modal.dart` declares `class AddMedicationModal extends ConsumerStatefulWidget`
- the Save `FilledButton.icon` uses `onPressed: _isSaving ? null : _onSave` (no `onPressed: () {}`)
- `_onSave` reads `ref.read(addMedicationProvider)` and calls `Navigator...pop()` on `Right`

**Spec criteria addressed**: AC-17, AC-18, AC-19, AC-20

## Completion Notes
**Completed**: 2026-06-17
**Status**: Complete
**Files changed**: presentation/widgets/add_medication_modal.dart
**Contract**: Produces 3/3 (ConsumerStatefulWidget; `onPressed: _isSaving ? null : _onSave`; `_onSave` reads addMedicationProvider + pops on Right)
**Code review**: APPROVE WITH WARNINGS (no Critical). Mapping faithful to §3/AC-20; mounted guard correct; context objects captured before await; failure switch = ValidationFailure(field) + wildcard; null-form guard present; no `!`/`dynamic`; no data/ import.
**Fixes applied post-review**: W1 (pre-capture l10n/messenger/navigator before the null-form guard) + I7 (corrected ALL now-false "Visual-only / not persisted / Save is a no-op" docstrings across state fields, `_MedFormOption`, and the 6 sub-widgets — no lying comments remain).
**Open gap for /review (W2)**: a blank/unparseable dose field silently persists `Dosage(amount: 0.0)` — the use case validates name/times/duration but NOT dose>0 (outside AC-10/11/12). Faithful to the approved spec; flag as a follow-up (add a dose-positive ValidationFailure) if desired.
**Notes**: doseUnitValues aligned index-for-index with doseUnits (syrup=[ml], drops=[drops,ml], injection=[ml,mg,units]); tablet/capsule unit via `DoseUnit.values.byName(form.key)`. Hot RESTART required on a running device (top-level _medFormOptions changed).
