# Plan: Tap-to-Edit Medication

**Date**: 2026-06-19
**Spec**: [spec.md](spec.md)
**Status**: Approved

## Summary

Parameterize the existing `AddMedicationModal` with an optional `initial` medication so the same form serves both add and edit, and add the first medication **update** path through all three layers: a new `EditMedication` use case, a `MedicationRepository.update` method, and a drift `upsertMedication` data-source operation. Tapping a list tile opens the modal pre-filled; saving reconciles the medication in place, preserving `id`/`createdAt` and the IDs of unchanged time slots. No schema change, no new dependencies — entirely existing patterns (drift upsert, freezed `copyWith`, Riverpod codegen).

## Technical Context

**Architecture**: Clean Architecture — all three layers of the `meds` feature (domain use case + repo contract, data repo impl + data source, presentation modal + tile/section/screen + provider seam).
**Error Handling**: `Either<Failure, T>` (fpdart) at the new repo method and use case; modal `.fold`s both branches; data-source exceptions caught into `Left(Failure.unknown)`.
**State Management**: Riverpod codegen — new `editMedicationProvider` (autoDispose function provider) consumed imperatively (`ref.read`). The reactive `medicationsListProvider` already re-emits on DB update, so the list refresh is free.

## Constitution Compliance

| Rule | Status |
|------|--------|
| §2.1 layer boundaries (domain pure Dart; only provider seam imports `data/`) | Compliant — `EditMedication` imports only fpdart/domain/IdGenerator; provider seam wires it. |
| §3.2 Either/Failure on every fallible boundary; `fold` handles both branches | Compliant — `update` + `EditMedication.call` return `Either`; modal folds. |
| §4.1.1 screens never call repositories directly; intake/medication writes go through a use case | Compliant — modal calls `editMedicationProvider` → `EditMedication`, never the repo. |
| §3.4 mandatory domain + data tests | Compliant — new use-case test + repo `update` test + widget tests planned (AC-16). |
| §4.3.1 tap targets ≥48 dp, prefer `InkWell` over raw `GestureDetector` | Compliant — tile wrapped in `InkWell`; tile already ≥48 dp tall. |
| §3.1 no `!`, no unchecked `as`, exhaustive switches | Compliant — pre-fill uses null-guarded reads; `MedicationType` switch stays exhaustive. |
| §4.2.1 no PHI logging; `mounted` after await | Compliant — no logging added; edit save reuses the capture-before-await idiom. |
| §6.5 / §4.2.1 drift schema: no column drop/rename without migration | Compliant — no schema change; `schemaVersion` stays 1. |

## Implementation Approach

### Layer Map

| Layer | What | Files |
|-------|------|-------|
| Domain | `update` on the repo contract; new `EditMedication` use case | `domain/repositories/medication_repository.dart` (mod), `domain/usecases/edit_medication.dart` (new) |
| Data | `update` impl; `upsertMedication` (transactional in-place upsert + slot reconciliation) | `data/repositories/medication_repository_impl.dart` (mod), `data/datasources/medication_local_data_source.dart` (mod) |
| Presentation | provider; modal `initial` param + pre-fill + edit-mode chrome + save routing; picker `initialFormKey`; tile `onTap`; section callback; screen edit launcher | `presentation/providers/medication_providers.dart` (mod), `presentation/widgets/add_medication_modal.dart` (mod), `presentation/widgets/medication_tile.dart` (mod), `presentation/widgets/medication_section.dart` (mod), `presentation/screens/meds_screen.dart` (mod) |
| l10n | two new keys ×3 locales | `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` (mod) + regenerate |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| Reuse strategy | Parameterize `AddMedicationModal` with `Medication? initial` (const ctor preserved) | Smallest surface; literal "reuse the add modal"; add path stays byte-identical when `initial == null` | Extract a shared form widget + Add/Edit wrappers (bigger refactor of a 1700-line file, premature for 2 modes — research Option B) |
| Update persistence | `insertOnConflictUpdate` for the medication row | UPDATEs in place; does **not** trigger the `onDelete: cascade` FK on time slots | `insertOrReplace` / `InsertMode.insertOrReplace` — REPLACE = delete+insert → cascade-wipes all slots every edit |
| Slot-ID preservation | Reconcile in the **use case**: reuse original ID where `minuteOfDay` matches, mint new otherwise; data source deletes IDs absent from the new set + upserts the rest | Keeps ID/validation logic in the domain (it holds `IdGenerator` + original); data source just persists what it's given | Reconcile by diffing inside the data source (leaks domain logic into `data/`); replace-all slots with fresh IDs (user chose to preserve IDs) |
| No `getById` | Modal passes the in-hand `Medication` (`widget.initial`) into `EditMedication` | Avoids a new read method; the modal already holds the aggregate | Add `MedicationRepository.getById` + fetch in the use case (unnecessary round-trip + new contract) |
| Form-picker seeding | New `initialFormKey` seeds the picker's own `_selectedIndex` in its `initState`; parent sets `_selectedForm` directly in edit mode | Picker keeps its private state (MEMORY F028) so 027/028 tests stay green; the picker won't fire `onFormSelected` for a programmatic selection, so the parent seeds its own copy | Make the picker fully "controlled" (breaks existing picker tests) |
| Validation duplication | Duplicate the 4 validation rules in `EditMedication` (don't extract yet) | Constitution DRY abstracts at 3+ occurrences; 2 use cases is fine | Extract a shared validator now (premature; `/breakdown` may revisit if it reads cleaner) |
| Tile interactivity | Add `VoidCallback? onTap`; wrap body in `InkWell(onTap: onTap, …)`; `null` onTap → non-interactive | Keeps the tile "dumb" (parent supplies behavior); default render unchanged for existing tests | Open the modal from inside the tile (tile would need providers — violates its dumb-widget role) |

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `domain/repositories/medication_repository.dart` | Modify | Add `Future<Either<Failure, Medication>> update(Medication)` to the interface + dartdoc. |
| `domain/usecases/edit_medication.dart` | Create | `EditMedication(repo, idGenerator)`; validate (4 rules); reconcile slot IDs; `original.copyWith(...)` preserving id/createdAt; call `repo.update`. |
| `data/repositories/medication_repository_impl.dart` | Modify | Implement `update` → `dataSource.upsertMedication(medicationToCompanion(m), timeSlotsToCompanions(m))` in try/catch → `Left(Failure.unknown)`. |
| `data/datasources/medication_local_data_source.dart` | Modify | Add `upsertMedication`: transaction → `insertOnConflictUpdate` med row; delete slots `medicationId == id & id NOT IN newIds`; `insertOnConflictUpdate` each slot. |
| `presentation/providers/medication_providers.dart` | Modify | Add `@riverpod EditMedication editMedication(Ref ref)` + regenerate `.g.dart`. |
| `presentation/widgets/add_medication_modal.dart` | Modify | `final Medication? initial`; `initState` pre-fill (name, form+`_selectedForm`, dose/qty, stock, time chips, intake type, course fields, start date); branch title (`medsEditTitle`) + success (`medsEditSaveSuccess`) + save target (`editMedicationProvider`); pass `initialFormKey` to picker. |
| `presentation/widgets/medication_tile.dart` | Modify | Add `VoidCallback? onTap`; wrap content in `InkWell`; keep `ValueKey('medTile-<id>')` + dumb default. |
| `presentation/widgets/medication_section.dart` | Modify | Add `void Function(Medication)? onTapItem`; pass `onTap: …` per tile. |
| `presentation/screens/meds_screen.dart` | Modify | Add `_openEditMedicationModal(context, med)` (mirrors `_openAddMedicationModal`, `AddMedicationModal(initial: med)`); wire `onTapItem` on both sections. |
| `lib/l10n/app_en.arb` (+ de/uk) | Modify | Add `medsEditTitle` ("Edit medication") + `medsEditSaveSuccess` ("Medication updated"); `@`-descriptions in en; run `flutter gen-l10n`. |
| `test/features/meds/domain/usecases/edit_medication_test.dart` | Create | Happy path, id/createdAt preservation, slot-ID reconciliation (keep/add/remove), 4 validation branches, repo-failure passthrough. |
| `test/features/meds/data/repositories/medication_repository_impl_test.dart` | Modify | Add `update` round-trip (in-memory drift, `closeStreamsSynchronously`): in-place row update, preserved/added/removed slot IDs, sibling medication untouched, failure path. |
| `test/features/meds/presentation/widgets/add_medication_modal_test.dart` | Modify | Edit-mode pre-fill assertions; edit Save invokes `editMedicationProvider` (overridden) + pops + success; add-mode tests untouched. |
| `test/features/meds/presentation/widgets/medication_tile_test.dart` (and/or section/screen test) | Create/Modify | Tapping a tile triggers `onTap`; `InkWell` present; default (no onTap) unchanged. |

### Documentation Impact

| Doc File | Action | What Changes |
|----------|--------|-------------|
| `docs/features/medication-persistence.md` | Update | Add the update path: `EditMedication` use case, `MedicationRepository.update`, `upsertMedication` + the `insertOnConflictUpdate`-not-`insertOrReplace` rationale and slot reconciliation rule. Remove "Editing … beyond add" from the "Does NOT Include" list. |
| `docs/features/meds.md` | Update | Note the modal's add/edit dual mode (`initial` param) and the form picker's `initialFormKey`. |

(Handled by tech-writer at `/finalize`; listed here so `/breakdown` schedules the docs task.)

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `insertOrReplace` used → cascade-deletes slots every edit | Med | High | §7 constraint + this plan's decision table; AC-9 + repo test assert slot rows survive/reconcile and preserved IDs hold. |
| Interface change breaks implementers/fakes silently until compile | Med | Med | Land impl + any `implements MedicationRepository` fakes in the same task; grep `test/` first; mocktail mocks unaffected. |
| Pre-fill regresses the tested add flow (026–034) | Med | High | Edit is additive (`initial == null` ⇒ today's behavior); AC-14 + untouched add tests; `initialFormKey == null` keeps picker byte-identical. |
| Dose-unit pre-fill mismatch if stored `DoseUnit` ∉ form's `doseUnitValues` | Low | Low | Default dropdown index to 0 when `indexOf` returns −1 (data was written by the same form, so practically impossible). |
| `_intakeTimes`/course-date round-trip drift | Low | Low | Map `minuteOfDay`→`TimeOfDay` exactly; pre-fill `_startDate` from UTC calendar `y/m/d` as local `DateTime(y,m,d)` (save re-wraps to UTC). |
| ARB `@`-description drift propagates to dartdoc (MEMORY F011) | Low | Low | Accurate `@`-descriptions for both new keys; re-run `flutter gen-l10n`. |
| Stale hot-reload null after touching top-level option lists (MEMORY F028) | Low | Low | No new `_MedFormOption` fields needed; hot RESTART (not reload) when verifying on device. |

## Dependencies

None. No packages to add (`flutter pub add` not needed), no schema migration (`schemaVersion` stays 1), no services/env vars. Codegen step required after editing the `@riverpod` provider and (if touched) any freezed type: `dart run build_runner build` (drop the deprecated `--delete-conflicting-outputs`, MEMORY F032).

## Supporting Documents

- [Contracts](contracts.md) — new `MedicationRepository.update`, `EditMedication`, `upsertMedication`, `editMedicationProvider`.
- No `research.md` — no signals (all tech already in-stack).
- No `data-model.md` — no new/changed entities or schema (the `Medication` aggregate and v1 tables are reused as-is).
