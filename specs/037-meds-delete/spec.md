# Spec: Delete Medication

**Date**: 2026-07-01
**Status**: Complete
**Author**: Claude + Webmint

## 1. Overview

Completes the medication CRUD by adding a **delete** operation. From the edit-medication modal (opened by tapping a medication tile), the user can delete that medication via a trash icon in the AppBar, guarded by a confirmation dialog. On confirm the medication and its time slots are removed from the local drift database, the modal closes, and a success SnackBar is shown. This is the last missing CRUD verb: Create (`AddMedication`), Read (`watchAll`), and Update (`EditMedication`) already ship; delete does not exist in any layer today.

## 2. Current State

The meds feature follows Clean Architecture across `domain/` → `data/` → `presentation/`, wired through the composition seam `lib/features/meds/presentation/providers/medication_providers.dart` (the only presentation file permitted to import `data/`, per constitution §2.1 amendment / MEMORY 2026-06-09).

**Persistence stack (no delete anywhere):**
- `lib/features/meds/domain/repositories/medication_repository.dart` — contract exposes only `add(Medication)`, `update(Medication)`, `watchAll()`. No `delete`, no `getById`.
- `lib/features/meds/data/datasources/medication_local_data_source.dart` — `insertMedication` (create) and `upsertMedication` (edit, with manual slot reconciliation) and `watchAllMedications` (reactive join). No delete method.
- `lib/features/meds/data/repositories/medication_repository_impl.dart` — each method try/catches data-source exceptions → `Left(Failure.unknown(e, st))`, returns `Right(medication)` on success (constitution §3.2).
- `lib/features/meds/domain/usecases/` — `add_medication.dart`, `edit_medication.dart`. No `delete_medication.dart`.

**Cascade delete is already configured.** `lib/core/database/database.dart:31` documents that `TimeSlots.medicationId` carries `onDelete: cascade`, and `beforeOpen` runs `pragma foreign_keys = ON` for every connection. Therefore deleting a `medications` row automatically removes all of its `time_slots` rows in a single statement — no manual child cleanup is needed (unlike the edit/upsert path, which must reconcile slots and guard against the `NOT IN ()` wipe footgun — MEMORY 2026-06-19).

**Reactive list auto-refreshes.** `medicationsListProvider` (in the composition seam) watches `MedicationRepository.watchAll()`, whose underlying drift watched-join in `watchAllMedications` re-emits on any insert/update/**delete** to either table. The meds list (`lib/features/meds/presentation/screens/meds_screen.dart`) rebuilds automatically once a delete commits — no manual refresh.

**Edit-modal entry point (where delete lives).** Tapping a tile calls `_openEditMedicationModal` (`meds_screen.dart:408`) which pushes `AddMedicationModal(initial: medication)` on the root navigator as a `fullscreenDialog`. `AddMedicationModal` (`lib/features/meds/presentation/widgets/add_medication_modal.dart`) is add/edit dual-mode:
- `widget.initial == null` → add mode; `widget.initial != null` → edit mode (all fields pre-filled in `initState`).
- Its AppBar (build method, ~line 1685) currently has only `leading: IconButton(arrowLeft)` and `title` (`medsAddTitle` / `medsEditTitle`). **There is no `actions:` list yet.**
- `_onSave` (~line 1520) is the reference pattern for an async mutation from this modal: it captures `l10n` / `ScaffoldMessenger` / `Navigator` **before** the `await` (satisfying `use_build_context_synchronously`), calls the use case, then `result.fold(...)` — on `Left` shows a field-mapped error SnackBar and stays open, on `Right` shows a success SnackBar and `navigator.pop()`. A save-in-flight `_isSaving` bool disables the button during the call.

**No dialog pattern exists.** `showDialog` / `AlertDialog` / `Dismissible` appear **nowhere** in `lib/` today. The modal does use Material `showTimePicker` / `showDatePicker`. `SnackBarAction` (undo) is unused. The delete confirmation is the first `AlertDialog` in the codebase.

**Domain id.** `lib/features/meds/domain/value_objects/medication_id.dart` — `MedicationId(String value)`, freezed equality. `Medication.id` gives the `MedicationId`; the edit modal already holds the full `Medication` via `widget.initial`.

**l10n.** ARB files `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb`; generated Dart via `flutter gen-l10n`. Meds strings are namespaced `medsAdd*` / `medsEdit*` / `medsList*`. Existing edit keys: `medsEditTitle`, `medsEditSaveSuccess`. There are **no** shared `cancel`/`delete` keys — new strings will be namespaced `medsDelete*`.

**Failure types.** `lib/core/error/failures.dart` — sealed `Failure` with `Failure.notFound({String? id})`, `Failure.cache`, `Failure.validation`, `Failure.unknown(error, stack)`, etc.

## 3. Desired Behavior

**Affordance.** In **edit mode only** (`widget.initial != null`), `AddMedicationModal`'s AppBar shows a trailing delete action: an `IconButton` with a trash icon (`LucideIcons.trash2`), tinted with `ColorScheme.error`, tooltip from l10n. In add mode (`initial == null`) no such action is rendered.

**Confirmation.** Tapping the trash icon opens a Material `AlertDialog` via `showDialog<bool>()`:
- Title: localized (e.g. "Delete medication?").
- Body: localized, includes the medication's name (e.g. "Delete "Aspirin"? This can't be undone.") — the name is the user's own on-device data; it is fine to show on screen (it must never be *logged*, per constitution PHI rule).
- Actions: **Cancel** (`TextButton`, pops the dialog with `false`) and **Delete** (`TextButton`, error-colored label, pops with `true`).
- The dialog returns `Future<bool?>`; only a `true` result proceeds to delete. `false`/dismiss (barrier tap / back) cancels with no side effect.

**Deletion.** On confirm, the modal invokes a new `DeleteMedication` use case through `deleteMedicationProvider`, which calls `MedicationRepository.delete(MedicationId)` → `MedicationLocalDataSource.deleteMedication(String id)`. The data source issues a single drift delete (`delete(medications)..where((m) => m.id.equals(id))).go()`); the FK cascade removes the medication's time slots automatically.

**Idempotent success.** Deleting an id that no longer exists (0 rows affected) returns `Right` (success) — the end state (row absent) matches intent. Only a thrown data-source exception (real DB error) becomes `Left(Failure.unknown)`.

**Outcome UX (mirrors `_onSave`).**
- On `Right`: capture messenger/navigator before the await; pop the edit modal, then show a success SnackBar (`medsDeleteSuccess`, e.g. "Medication deleted"). The reactive list has already dropped the row.
- On `Left`: show an error SnackBar and keep the edit modal open so the user can retry. (The confirmation dialog is already closed by then.)
- A delete-in-flight guard (analogous to `_isSaving`) prevents double-invocation; context objects are captured before the `await` to satisfy `use_build_context_synchronously`.

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Repository contract | `lib/features/meds/domain/repositories/medication_repository.dart` | Add `Future<Either<Failure, Unit>> delete(MedicationId id);` (return type — see Open Questions) with dartdoc. |
| Delete use case | `lib/features/meds/domain/usecases/delete_medication.dart` | **Create new.** Pure-Dart `DeleteMedication` wrapping `MedicationRepository.delete`; `call(MedicationId id)` returns `Future<Either<Failure, Unit>>`. |
| Data source | `lib/features/meds/data/datasources/medication_local_data_source.dart` | Add `deleteMedication(String id)` — single drift `delete` on `medications` (slots cascade). Throws on failure per class contract. |
| Repository impl | `lib/features/meds/data/repositories/medication_repository_impl.dart` | Implement `delete`: try `deleteMedication(id.value)` → `Right(unit)`; catch → `Left(Failure.unknown(e, st))`. |
| Composition seam | `lib/features/meds/presentation/providers/medication_providers.dart` | Add `@riverpod DeleteMedication deleteMedication(Ref ref)` wired to `medicationRepositoryProvider`; regenerate `.g.dart`. |
| Edit modal | `lib/features/meds/presentation/widgets/add_medication_modal.dart` | Add AppBar `actions:` (edit-mode-only trash `IconButton`), a `_confirmDelete()` (showDialog) + `_onDelete()` method mirroring `_onSave`, and a delete-in-flight guard. |
| l10n (EN/DE/UK) | `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` | Add `medsDeleteButtonTooltip`, `medsDeleteDialogTitle`, `medsDeleteDialogBody` (placeholder: medication name), `medsDeleteDialogConfirm`, `medsDeleteDialogCancel`, `medsDeleteSuccess`, `medsDeleteError`. Regenerate via `flutter gen-l10n`. |
| Tests | `test/features/meds/...` (mirror structure) | Use-case unit tests; in-memory drift delete test (incl. cascade proof); repo-impl test; modal widget test (edit-only affordance, confirm→delete→pop→SnackBar, cancel = no-op). |

## 5. Acceptance Criteria

- [x] **AC-1**: `MedicationRepository` declares a `delete(MedicationId id)` method returning `Future<Either<Failure, Unit>>`, with dartdoc.
- [x] **AC-2**: A new `DeleteMedication` use case exists in `domain/usecases/delete_medication.dart`, is pure Dart (no Flutter/drift/uuid imports), takes a `MedicationRepository`, and its `call(MedicationId id)` forwards to `MedicationRepository.delete` returning `Future<Either<Failure, Unit>>`.
- [x] **AC-3**: `MedicationLocalDataSource.deleteMedication(String id)` deletes the matching `medications` row via a single drift delete; on success the medication's `time_slots` rows are also gone (FK cascade). Verified by an in-memory drift test that inserts a medication with ≥1 slot, deletes it, and asserts both the medication **and** its slots are absent.
- [x] **AC-4**: `MedicationRepositoryImpl.delete` returns `Right(unit)` when the data source completes, and `Left(Failure.unknown)` when the data source throws (no exception escapes the data layer).
- [x] **AC-5**: Deleting an id that is not present returns `Right` (idempotent success); no `Failure` is produced solely because 0 rows were affected.
- [x] **AC-6**: `deleteMedicationProvider` is defined in `medication_providers.dart`, exposes the domain-typed `DeleteMedication`, and is wired to `medicationRepositoryProvider`. No screen/widget imports `data/`.
- [x] **AC-7**: In edit mode (`AddMedicationModal(initial: <med>)`) the AppBar renders a trailing trash `IconButton` (error-tinted, with the `medsDeleteButtonTooltip` tooltip). In add mode (`initial == null`) no delete action is rendered.
- [x] **AC-8**: Tapping the trash icon opens a Material `AlertDialog` (via `showDialog<bool>`) whose body contains the medication's name and which offers Cancel and Delete actions.
- [x] **AC-9**: Choosing **Cancel** (or dismissing the dialog) performs no deletion, leaves the modal open, and mutates no state.
- [x] **AC-10**: Choosing **Delete** invokes `deleteMedicationProvider`; on success the edit modal is popped and a `medsDeleteSuccess` SnackBar is shown; the deleted medication no longer appears in the meds list (reactive refresh).
- [x] **AC-11**: On a delete failure (`Left`), an error SnackBar (`medsDeleteError`) is shown and the edit modal stays open.
- [x] **AC-12**: The delete flow captures `ScaffoldMessenger` / `Navigator` / l10n before the `await` and guards `mounted`/in-flight so `dart analyze` reports no `use_build_context_synchronously` and no double-invocation is possible.
- [x] **AC-13**: New l10n keys (`medsDeleteButtonTooltip`, `medsDeleteDialogTitle`, `medsDeleteDialogBody`, `medsDeleteDialogConfirm`, `medsDeleteDialogCancel`, `medsDeleteSuccess`, `medsDeleteError`) are present in **all three** ARB files (EN/DE/UK) with metadata, and `flutter gen-l10n` regenerates cleanly.
- [x] **AC-14**: `dart analyze` passes with no new warnings/errors; `flutter test` passes.

## 6. Out of Scope

- NOT included: **Swipe-to-delete / `Dismissible`** on the list tile, long-press context menus, or any delete affordance outside the edit modal.
- NOT included: **Undo** (no `SnackBarAction`, no re-insert path). Deletion is final after confirmation.
- NOT included: **Bulk/multi-select delete.**
- NOT included: **Adaptive/Cupertino dialog** (`AlertDialog.adaptive`) — a plain Material `AlertDialog` is used, consistent with the existing Material pickers. (Trivial future swap.)
- NOT included: **Archive / soft-delete / recycle bin** — this is a hard delete.
- NOT included: **`getById` / read-single** repository method.
- NOT included: Changes to intake/adherence-history reconciliation (no `Intakes` table exists yet; nothing downstream references a deleted medication).
- NOT included: Delete confirmation preferences/settings (e.g. "don't ask again").

## 7. Technical Constraints

- Must follow Clean Architecture layer boundaries (constitution §2.1): the use case is pure Dart; only `medication_providers.dart` touches `data/`.
- Must not let screens/widgets call the repository directly (constitution §4.1.1) — delete goes through the `DeleteMedication` use case.
- Every fallible operation returns `Either<Failure, T>` (constitution §3.2); the repo impl catches all data-source exceptions.
- Must use drift's cascade (existing `onDelete: cascade` + FK pragma) rather than manually deleting time slots.
- Must reuse the `_onSave` async-mutation idiom (capture context before `await`, `mounted` guard, in-flight flag) to satisfy `use_build_context_synchronously` (lints are errors in this project).
- Must not log medication names (PHI) — displaying the name in the dialog is allowed; logging it is not.
- New public functions/classes require dartdoc (constitution §"Document new code").
- Testing is mandatory (constitution §3.4): use-case unit tests, an in-memory drift delete+cascade test, and a modal widget test.
- l10n strings added to all three locales; no hardcoded user-facing text.

## 8. Open Questions

- **Return type `Unit` vs `Medication`.** Delete has nothing meaningful to return; the plan proposes `Either<Failure, Unit>` (fpdart `Unit`). If the codebase prefers `void`-style `Either<Failure, void>` or returning the deleted `MedicationId`, `/plan` can adjust. (Low impact — resolved at plan time by matching existing conventions.)
- **Trash icon glyph.** `LucideIcons.trash2` is assumed (the app uses `lucide_icons_flutter`); `/plan` confirms the exact glyph name.
- **Error string granularity.** A single `medsDeleteError` is planned; if a more specific message is desired for a particular `Failure` subtype, `/plan` can extend the mapping (mirrors `_onSave`'s field switch).

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Hard delete is irreversible; accidental data loss of sensitive med data | Med | High | Confirmation `AlertDialog` gate before any deletion; error-colored destructive action; no auto-delete. |
| Cascade doesn't fire (FK pragma off in a code path) → orphaned time_slots | Low | Med | FK pragma is set in `beforeOpen` for every connection; in-memory drift test (AC-3) asserts slots are gone after delete. |
| `use_build_context_synchronously` lint (errors in this project) from awaiting across the dialog + delete | Med | Low | Capture messenger/navigator/l10n before `await`; `mounted` guard; mirror the proven `_onSave` pattern. |
| First `AlertDialog` in the codebase → inconsistent/ad-hoc dialog | Low | Low | Use the standard `showDialog<bool>` + `AlertDialog` idiom; keep it self-contained; localized strings. |
| Regressing the well-tested add/edit modal (specs 026–036) by editing `add_medication_modal.dart` | Med | Med | Delete path is additive (new AppBar action + new methods), edit-mode-gated; existing add/edit widget tests must stay green. |
| Missing a locale (EN/DE/UK) → `flutter gen-l10n` untranslated-message error | Med | Low | Add all keys to all three ARB files in the same task; AC-13 verifies. |
