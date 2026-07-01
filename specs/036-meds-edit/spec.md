# Spec: Tap-to-Edit Medication

**Date**: 2026-06-19
**Status**: Complete
**Author**: Claude + Webmint

## 1. Overview

Let the user edit an existing medication by tapping its tile in the medications list. Tapping opens the **same** add-medication modal, pre-filled with that medication's current values; saving persists the changes in place (preserving the medication's `id`, `createdAt`, and the IDs of unchanged time slots) and the reactive list reflects the update. This reuses the add-medication modal rather than building a second form, and adds the first medication **update** path through the domain and data layers.

## 2. Current State

The meds feature has a complete add-only vertical slice (specs 026–034). Reading this spec's affected code:

- **List tile** — `lib/features/meds/presentation/widgets/medication_tile.dart`. `MedicationTile` is an explicitly "dumb" display widget: *"There is no `InkWell` or `GestureDetector` — navigation is deferred to a later task"* (`medication_tile.dart:27-28`). Renders a `MedListItem` (icon badge, name, subtitle, chips, a non-interactive trailing chevron). Keyed `ValueKey('medTile-<id>')`.
- **Section wrapper** — `lib/features/meds/presentation/widgets/medication_section.dart`. `MedicationSection` builds a `Column` of `MedicationTile`s separated by `Divider`s. Also has "NO tap targets."
- **List screen** — `lib/features/meds/presentation/screens/meds_screen.dart`. Watches `medicationsListProvider`, builds the view via `buildMedsListView`, renders two `MedicationSection`s. The FAB opens the add modal via `_openAddMedicationModal` (`meds_screen.dart:389`) using `Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const AddMedicationModal()))`.
- **The modal** — `lib/features/meds/presentation/widgets/add_medication_modal.dart` (~1720 lines). `AddMedicationModal` is a parameterless `ConsumerStatefulWidget`. It owns all form state as local `State` fields/controllers (name, dose, stock ×3, duration, pause, `_quantity`, `_selectedDoseUnitIndex`, `_intakeTimes`, `_intakeType`, `_startDate`, `_selectedForm`). `_onSave` (`:1381`) maps that state to typed domain inputs and calls `ref.read(addMedicationProvider).call(...)`; on `Right` it shows `medsAddSaveSuccess` and pops, on `Left` it shows a field-mapped error and stays open. Title is `medsAddTitle`; Save button label is `medsAddSaveButton`.
- **Form picker** — `_MedicationFormPicker` (private, in the modal file). Keeps its **own** `_selectedIndex`/`_isOpen` state and hoists selection to the parent via `onFormSelected` (a `ValueChanged<_MedFormOption>`). There is **no** way for the parent to seed an initial selection — the collapsed display shows the placeholder until the user opens the grid and taps. `_MedFormOption.key` equals the `MedicationForm` enum name (`MedicationForm.values.byName(form.key)` is used at save).
- **Domain use case** — `lib/features/meds/domain/usecases/add_medication.dart`. `AddMedication.call(...)` validates (name non-empty, ≥1 intake time, course `durationDays ≥ 1`, dose `amount > 0`), mints a **new** `MedicationId` and new `TimeSlotId`s via the injected `IdGenerator`, stamps `createdAt = clock.now().toUtc()`, and calls `repository.add`.
- **Repository contract** — `lib/features/meds/domain/repositories/medication_repository.dart`. **Only** `add(Medication)` and `watchAll()`. No `update`, `getById`, or `delete`.
- **Repository impl** — `lib/features/meds/data/repositories/medication_repository_impl.dart`. `add` delegates to `_dataSource.insertMedication(...)`, catching every exception into `Left(Failure.unknown(e, st))`.
- **Data source** — `lib/features/meds/data/datasources/medication_local_data_source.dart`. `insertMedication(MedicationsCompanion, List<TimeSlotsCompanion>)` does a plain transactional `insert` + `batch.insertAll`. No update/upsert/delete. `watchAllMedications()` is a watched left-outer join that **re-emits on any insert/update/delete** to either table.
- **Mapper** — `lib/features/meds/data/mappers/medication_mapper.dart`. `medicationToCompanion(med)` and `timeSlotsToCompanions(med)` build `*.insert(...)` companions with the PK (`id`) populated — reusable as-is for an upsert. `medicationFromRows(...)` is the inverse used by `watchAll`.
- **Schema** — `lib/core/database/...`. `Medications` (PK `id`) + `TimeSlots` (PK `id`, FK `medicationId → Medications.id` `onDelete: cascade`, enforced via `pragma foreign_keys = ON`). `schemaVersion = 1`. Documented in `docs/features/medication-persistence.md`.
- **Provider seam** — `lib/features/meds/presentation/providers/medication_providers.dart` is the single `presentation/` file allowed to import `data/` (constitution §2.1 amendment). Exposes `medicationRepositoryProvider`, `addMedicationProvider`, `medicationsListProvider` (a `Stream<List<Medication>>`).
- **l10n** — `lib/l10n/app_en.arb` (+ `app_de.arb`, `app_uk.arb`). Existing keys include `medsAddTitle` ("Add medication"), `medsAddSaveButton` ("Save"), `medsAddSaveSuccess` ("Medication saved"), and `medsAddSaveError{Name,Times,Duration,Dose,Generic}`.

The list already auto-refreshes on DB updates (the watch join fires on `update`), so no list-side reactivity work is required beyond writing the update.

## 3. Desired Behavior

1. **Tap to edit.** Tapping anywhere on a medication tile opens the add-medication modal in **edit mode** for that medication, pushed the same way the add modal is (root navigator, `fullscreenDialog: true`).
2. **Pre-fill.** In edit mode the modal opens with every field populated from the tapped `Medication`:
   - name; selected form (the form picker's collapsed display shows the correct form, not the placeholder);
   - the form-dependent fields for that form — quantity (tablet/capsule) or dose amount + unit (liquid forms), and pack stock (remaining/total/warn) when present;
   - all intake-time chips (from the medication's time slots, ascending);
   - intake type (Continuous/Course) and, for a course, duration / pause / start date.
3. **Full edit.** All fields remain editable, including the medication form. Changing the form behaves exactly as in add mode (form-dependent fields reset/show per the selected form).
4. **Edit-mode chrome.** The app-bar title reads **"Edit medication"** (`medsEditTitle`). The Save button keeps the existing **"Save"** label (`medsAddSaveButton`).
5. **Save (update).** Tapping Save validates with the **same** rules as add, then persists an **update** of the existing medication:
   - the medication's `id` and `createdAt` are preserved (not regenerated);
   - the medication row is updated in place;
   - intake time slots are reconciled **preserving the IDs of unchanged slots**: a slot whose `minuteOfDay` exists in both the original and the new set keeps its `TimeSlotId`; a newly-added time gets a freshly-minted `TimeSlotId`; a removed time's row is deleted.
   - On success the modal shows **"Medication updated"** (`medsEditSaveSuccess`) and pops; the list reflects the change reactively.
   - On a validation failure the modal stays open and shows the same field-mapped error messages as add mode; the Save button is disabled while the update is in flight.
6. **Add mode unchanged.** Opening the modal from the FAB (no medication) behaves exactly as today — title "Add medication", inserts a new medication, success "Medication saved".
7. **Back discards.** Backing out of the edit modal pops immediately and discards changes (no confirmation dialog) — identical to the add flow.

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Repository contract | `lib/features/meds/domain/repositories/medication_repository.dart` | Add `Future<Either<Failure, Medication>> update(Medication medication)`. **Signature change to a shared interface** — every implementer must update atomically (see Risks). |
| Repository impl | `lib/features/meds/data/repositories/medication_repository_impl.dart` | Implement `update` → delegate to a new data-source upsert method, catching exceptions into `Left(Failure.unknown)`. |
| Data source | `lib/features/meds/data/datasources/medication_local_data_source.dart` | Add `upsertMedication(MedicationsCompanion, List<TimeSlotsCompanion>)`: in one transaction, **`insertOnConflictUpdate`** the medication row, delete `TimeSlots` for this medication whose `id` is not in the incoming slot-id set, then `insertOnConflictUpdate` each incoming slot. |
| Edit use case | `lib/features/meds/domain/usecases/edit_medication.dart` | **Create new.** Validates (same rules as `AddMedication`), preserves `id`/`createdAt` from the original, reconciles slot IDs (reuse original slot's `TimeSlotId` where `minuteOfDay` matches, else mint new via `IdGenerator`), builds the updated `Medication`, calls `repository.update`. |
| Provider seam | `lib/features/meds/presentation/providers/medication_providers.dart` | Add `editMedicationProvider` wiring `EditMedication(repo, idGenerator)`. |
| Modal | `lib/features/meds/presentation/widgets/add_medication_modal.dart` | Add `final Medication? initial;` to `AddMedicationModal` (const ctor preserved). When non-null: pre-fill all controllers/state in `initState`; set `_selectedForm` directly; render `medsEditTitle`; on save call `editMedicationProvider` and show `medsEditSaveSuccess`. Add `initialFormKey` param to `_MedicationFormPicker` so its collapsed display pre-selects. |
| List tile | `lib/features/meds/presentation/widgets/medication_tile.dart` | Wrap the tile content in an `InkWell` exposing an `onTap` (≥48 dp target per §4.3.1). Keep it dumb — `onTap` is supplied by the parent. |
| Section wrapper | `lib/features/meds/presentation/widgets/medication_section.dart` | Thread an `onTapItem(MedListItem)` (or `onTap(Medication)`) callback down to each `MedicationTile`. |
| List screen | `lib/features/meds/presentation/screens/meds_screen.dart` | Provide the tile callback → `_openEditMedicationModal(context, medication)` that pushes `AddMedicationModal(initial: medication)`. |
| l10n | `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` | Add `medsEditTitle` ("Edit medication") and `medsEditSaveSuccess` ("Medication updated") in all three locales, with the `@`-description block in `app_en.arb`. Run `flutter gen-l10n`. |
| Tests | `test/features/meds/domain/usecases/edit_medication_test.dart`, `test/features/meds/data/repositories/medication_repository_impl_test.dart`, `test/features/meds/presentation/widgets/add_medication_modal_test.dart`, tile/section/screen tests | Create the use-case test; extend the repo test for `update`; extend modal tests for edit-mode pre-fill + update routing; add tile-tap test. |

## 5. Acceptance Criteria

- [x] **AC-1**: Tapping a `MedicationTile` opens `AddMedicationModal` pushed on the root navigator as a fullscreen dialog, constructed with `initial` set to the tapped medication.
- [x] **AC-2**: `MedicationTile` exposes an `onTap` callback and wraps its content in an `InkWell` (not a raw `GestureDetector`); the tap target is ≥ 48 dp tall. With no `onTap` supplied the tile renders unchanged.
- [x] **AC-3**: In edit mode the app-bar title is `medsEditTitle` ("Edit medication"); in add mode it remains `medsAddTitle` ("Add medication"). The Save button label is `medsAddSaveButton` ("Save") in both modes.
- [x] **AC-4**: In edit mode the name field, form picker (collapsed display shows the medication's form, not the placeholder), and the form-dependent fields (quantity OR dose amount+unit, and pack stock when present) are pre-filled from the medication.
- [x] **AC-5**: In edit mode the intake-time chips are pre-filled from the medication's time slots, in ascending order; the intake-type segmented control reflects Continuous vs Course, and for a course the duration, pause, and start-date fields are pre-filled.
- [x] **AC-6**: `_MedicationFormPicker` accepts an `initialFormKey`; when provided it seeds the picker's selected index so the collapsed display shows that form on first build. When `null` the picker behaves exactly as before (placeholder, existing tests pass unchanged).
- [x] **AC-7**: `MedicationRepository` declares `update(Medication)` returning `Future<Either<Failure, Medication>>`, and `MedicationRepositoryImpl` implements it, converting any data-source exception into `Left(Failure.unknown(e, st))` (no exception escapes the data layer).
- [x] **AC-8**: `MedicationLocalDataSource.upsertMedication` updates an existing medication **in place** — after an update the medications table still has exactly one row for that `id`, with the edited column values.
- [x] **AC-9**: Slot reconciliation preserves IDs: after editing a medication, a time slot whose `minuteOfDay` was unchanged retains its original `TimeSlotId`; an added time produces a new row with a new `TimeSlotId`; a removed time's row is deleted. No orphan slots remain and no slot belonging to another medication is affected.
- [x] **AC-10**: `EditMedication` preserves the original `id` and `createdAt` on the persisted aggregate (they are not regenerated/re-stamped).
- [x] **AC-11**: `EditMedication` enforces the same validation as `AddMedication` — empty name → `ValidationFailure(field:'name')`; no intake times → `field:'times'`; course `durationDays < 1` → `field:'durationDays'`; `dosePerIntake.amount <= 0` → `field:'dose'`; the repository is not called on invalid input.
- [x] **AC-12**: Saving in edit mode invokes `editMedicationProvider` (not `addMedicationProvider`); on `Right` it shows `medsEditSaveSuccess` ("Medication updated") and pops; on `Left(ValidationFailure)` it shows the matching field message and does not pop. The Save button is disabled while the update is in flight.
- [x] **AC-13**: After a successful edit, the medications list updates reactively (no manual refresh) to show the changed values.
- [x] **AC-14**: Add mode is behaviorally unchanged — opening from the FAB inserts a new medication and shows `medsAddSaveSuccess`; existing add-flow tests pass without modification.
- [x] **AC-15**: `medsEditTitle` and `medsEditSaveSuccess` exist in `app_en.arb`, `app_de.arb`, and `app_uk.arb`, with an `@`-description for each in `app_en.arb`; `flutter gen-l10n` regenerates cleanly.
- [x] **AC-16**: `dart analyze` is clean and `flutter test` passes, including: an `EditMedication` use-case test (happy path + slot-ID preservation + each validation branch + repo-failure passthrough), a repository `update` round-trip test (in-memory drift, ID preservation, removed-slot deletion, failure path), edit-mode modal pre-fill/update-routing widget tests, and a tile-tap test.

## 6. Out of Scope

- NOT included: **Deleting** a medication (no delete affordance, no `DeleteMedication` use case, no `repository.delete`). Deferred to a separate spec. The cascade FK already supports it when that spec lands.
- NOT included: An **unsaved-changes / "discard changes?" confirmation** on back — edit parity with add is to pop immediately.
- NOT included: A dedicated **read-only detail screen**. Tapping goes straight to the editable modal.
- NOT included: **Per-slot dose overrides** editing (`TimeSlot.doseOverride` stays as written by the form — always `null` from this form).
- NOT included: Editing fields the form does not collect (e.g. `notes`, `ScheduleFrequency` other than `daily`) — these round-trip unchanged.
- NOT included: **Schema/migration changes**. The upsert uses the existing v1 schema; `schemaVersion` is not bumped.
- NOT included: Notifications/reminders, intake records, adherence, or stock decrement.
- NOT included: A separate `getById` repository method — the modal passes the in-hand `Medication` into the edit use case.
- NOT included: Refactoring the modal into a shared form widget + Add/Edit wrappers (Option B from the research). This spec parameterizes the existing modal in place.

## 7. Technical Constraints

- **Clean Architecture (§2.1)**: `EditMedication` is pure Dart (no Flutter/drift). Only `medication_providers.dart` may import `data/`. Screens/widgets depend on the domain abstractions via providers.
- **Use case mediation (§4.1.1)**: the modal must call the `EditMedication` use case through `editMedicationProvider` — it must NOT call the repository directly.
- **Either/Failure (§3.2)**: `update` and `EditMedication.call` return `Future<Either<Failure, T>>`; the modal `.fold`s both branches.
- **drift upsert API**: use **`insertOnConflictUpdate`** for the medication row, NOT `insertOrReplace`/`InsertMode.insertOrReplace`. With the `onDelete: cascade` FK, a REPLACE deletes+reinserts the parent row and would cascade-delete all of its time slots; `insertOnConflictUpdate` performs an UPDATE and does not trigger the cascade. Removed slots are deleted explicitly (`id` not in the new set); surviving/added slots use `insertOnConflictUpdate`.
- **Slot-ID assignment lives in the use case**: `EditMedication` (which holds the `IdGenerator` and the original aggregate) decides which `TimeSlotId`s to preserve vs mint, so the data source only persists what it is given. Preservation rule: reuse the original slot's ID when its `minuteOfDay` is present in the new set; mint a new ID for new minutes. (An edited time, e.g. 08:00→09:00, is treated as remove-old + add-new.)
- **Form-picker seeding (MEMORY F028)**: the picker hoists selection via a `ValueChanged` callback and keeps its own `_selectedIndex`. `initialFormKey` must seed `_selectedIndex` in the picker's own `initState`; the parent sets `_selectedForm` itself in edit mode (the picker does NOT fire `onFormSelected` for a programmatic initial selection). Keep the picker's existing observable behavior byte-identical when `initialFormKey == null` so spec 027/028 picker tests pass untouched.
- **Date round-trip**: `MedicationType.course.startDate` is stored as a UTC calendar date `DateTime.utc(y,m,d)`. Pre-fill `_startDate` as a local `DateTime(startDate.year, startDate.month, startDate.day)` (the save path already re-wraps it to UTC) so the y/m/d components round-trip without timezone shift.
- **`mounted` after await (§4.2.1)**: the edit save path reuses the add path's capture-context-before-await idiom (`use_build_context_synchronously`).
- **No PHI logging (§4.2.1)**: do not log medication names/dosages anywhere in the new code.
- **Testing drift reactivity (MEMORY F034)**: repo `update` tests that assert the watch stream re-emits should use `AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true))`; never `Future.delayed`.
- **Atomic interface change (MEMORY F032/F022)**: adding `update` to `MedicationRepository` breaks every `implements MedicationRepository` at `dart analyze`. Update the impl and any hand-written test fakes in the same task; mocktail mocks need no change. Grep `test/` for `implements MedicationRepository` / `extends Mock implements MedicationRepository`.

## 8. Open Questions

- **Validation sharing between Add and Edit**: the two use cases enforce identical rules. With only 2 occurrences, the constitution's DRY guidance (abstract at 3+) says duplication is acceptable for now; `/plan` may optionally extract a shared private validator if it reads cleaner. Not a blocker.
- **Edit-mode Save button label**: kept as the generic "Save" (`medsAddSaveButton`). If a future design wants "Save changes", that's a one-key addition — out of scope here.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `insertOrReplace` used instead of `insertOnConflictUpdate` → cascade-deletes time slots on every edit | Med | High | Explicit constraint in §7; AC-9 asserts slot rows survive/reconcile; repo test must assert preserved-slot IDs after update. |
| Adding `update` to the interface breaks implementers / hand-written fakes (silent until compile) | Med | Med | Land impl + fakes in the same task; grep `test/` for `implements MedicationRepository`; mocktail mocks unaffected. |
| Pre-fill regresses the well-tested add flow (specs 026–034) | Med | High | Edit is purely additive (`initial == null` → today's behavior); AC-14 + untouched add tests guard it; `initialFormKey == null` keeps the picker byte-identical. |
| Stale-state crash after adding fields to `_MedFormOption` or top-level lists (hot reload) (MEMORY F028) | Low | Low | No new `_MedFormOption` fields are required; if any are added, hot RESTART (not reload) when verifying on device. |
| Form/dose-unit pre-fill mismatch if a stored `DoseUnit` isn't in the selected form's `doseUnitValues` | Low | Low | Defensively default the dropdown index to 0; data was written by the same form so this should not occur. |
| ARB description drift (gen-l10n copies `@`-descriptions into dartdoc, MEMORY F011) | Low | Low | Add accurate `@`-descriptions for the two new keys; re-run `flutter gen-l10n`. |
