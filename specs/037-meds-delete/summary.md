## Feature Summary: 037 — Delete Medication

### What was built
Completes medication CRUD by adding a **delete** operation. From the edit-medication screen (opened by tapping a medication), a trash icon in the app bar opens a confirmation dialog; confirming permanently removes the medication — and its schedule/time slots — from the on-device database, closes the screen, and shows a "Medication deleted" confirmation. Available in EN, DE, and UK.

### Changes
- **Task 001** — Domain contract + use case: added `MedicationRepository.delete(MedicationId)` and a pure-Dart `DeleteMedication` use case (`Either<Failure, void>`).
- **Task 002** — Data layer: `MedicationLocalDataSource.deleteMedication` (single drift delete; time slots removed by the existing cascade FK) + repository `delete` mapping success/failure to `Right`/`Left`.
- **Task 003** — Composition seam: `deleteMedicationProvider` wiring the use case to the repository (build_runner-regenerated).
- **Task 004** — l10n: 7 `medsDelete*` strings across EN/DE/UK (button, dialog title/body/confirm/cancel, success, error).
- **Task 005** — UI: edit-mode-only trash `IconButton` → Material `AlertDialog` confirm → invoke delete → pop + success SnackBar (failure → error SnackBar, stays open); reuses the `_onSave` capture-before-await idiom with an in-flight guard.
- **Task 008** (discovered) — Restored the test suite after the interface change broke 5 hand-written repository fakes (added no-op `delete` stubs).
- **Tasks 006–007** — Tests: use-case, data-source cascade proof, repo-impl delete cases; widget tests for the affordance gating, confirm dialog, cancel/success/failure flows. Plus a post-verify hardening pass (in-flight guard, DE/UK render, list re-emission).

### Files changed
- `lib/features/meds/domain/` — 2 files (repository contract +1, new `delete_medication.dart`)
- `lib/features/meds/data/` — 2 files (data source, repo impl)
- `lib/features/meds/presentation/` — 3 files (providers +generated `.g.dart`, modal)
- `lib/l10n/` — 7 files (3 ARB + 4 regenerated localizations)
- `test/features/meds/` — 5 files (3 new, 2 modified)
- `specs/037-meds-delete/` — spec, plan, review, 9 task files, README

[Total: 33 files changed, 1977 insertions, 16 deletions. Test suite 583 → 587 passing.]

### Key decisions
- **Return type** `Future<Either<Failure, void>>` with `const Right(null)` — matches the settings-layer convention (no fpdart `Unit` in this codebase).
- **Cascade over manual cleanup** — a single scoped `DELETE ... WHERE id = ?`; the existing `onDelete: cascade` FK (`foreign_keys = ON`) removes time slots. No transaction, no manual child delete, no schema change.
- **Idempotent success** — deleting an absent id returns `Right` (0 rows is not an error); only a thrown DB error becomes `Left(Failure.unknown)`.
- **Confirmation, no undo** — a Material `AlertDialog` (the codebase's first) gates the irreversible delete of sensitive local data; delete is final after confirm.

### Deviations from plan
- **Task 008 added mid-feature** — the plan/breakdown missed that adding `delete` to the `MedicationRepository` interface cascades to all implementers; 5 test fakes stopped compiling. A remediation task restored the build.
- **Task 005 review fix** — code review caught an asymmetric in-flight guard (the Save button stayed tappable during an in-flight delete → race on the same medication); fixed to `(_isSaving || _isDeleting)`.
- **Post-verify test hardening** — `/verify` flagged 3 implemented-but-untested clauses (AC-10/12/13); a follow-up pass added the in-flight-guard, DE/UK-render, and delete-re-emission tests (587 total).

### Acceptance criteria
- [x] AC-1: Repository declares `delete(MedicationId) → Future<Either<Failure, void>>`
- [x] AC-2: Pure-Dart `DeleteMedication` use case forwards to the repository
- [x] AC-3: Data source deletes the medication; time slots cascade-removed (proven)
- [x] AC-4: Repo impl → `Right(null)` on success, `Left(Failure.unknown)` on throw
- [x] AC-5: Deleting an absent id → `Right` (idempotent)
- [x] AC-6: `deleteMedicationProvider` exposes the domain-typed use case
- [x] AC-7: Trash affordance in edit mode only
- [x] AC-8: Confirm dialog names the medication
- [x] AC-9: Cancel = no-op
- [x] AC-10: Delete → pop + success SnackBar; list refreshes
- [x] AC-11: Failure → error SnackBar, screen stays open
- [x] AC-12: No `use_build_context_synchronously`; in-flight guard prevents double-invoke
- [x] AC-13: l10n keys present in EN/DE/UK
- [x] AC-14: `dart analyze` + `flutter test` green (587 tests)
