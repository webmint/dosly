# Plan: Delete Medication

**Date**: 2026-07-01
**Spec**: [spec.md](spec.md)
**Status**: Approved

## Summary

Add a hard-delete vertical slice to the meds feature, mirroring the existing add/edit slices: a pure-Dart `DeleteMedication` use case → `MedicationRepository.delete(MedicationId)` → a single drift delete in `MedicationLocalDataSource` (time slots removed by the existing FK cascade). The UI is an edit-mode-only trash `IconButton` in `AddMedicationModal`'s AppBar that opens a Material `AlertDialog` confirmation (`showDialog<bool>`); on confirm it invokes the use case through a new `deleteMedicationProvider`, pops the modal, and shows a success SnackBar — reusing the proven `_onSave` async-mutation idiom.

## Technical Context

**Architecture**: Clean Architecture across `domain/` (contract + use case), `data/` (data source + repo impl), `presentation/` (composition-seam provider + modal widget). Composition seam `medication_providers.dart` is the only presentation file importing `data/`.
**Error Handling**: `Either<Failure, void>` throughout — matching the settings layer convention (`return const Right(null)` on success, `Left(Failure.unknown(e, st))` on caught exception). This resolves the spec's Open Question on return type: **`void`, not `Unit`.**
**State Management**: Riverpod codegen (`@riverpod`) provider exposing the domain-typed `DeleteMedication`. Modal keeps ephemeral in-flight state (`_isDeleting`) as widget `State`, like `_isSaving`.

## Constitution Compliance

- **§2.1 layer boundaries** — compliant: use case is pure Dart (imports only fpdart, failures, repo contract, `MedicationId`); only `medication_providers.dart` touches `data/`.
- **§4.1.1 screens never call repositories directly** — compliant: modal calls `DeleteMedication` via `deleteMedicationProvider`, never the repo.
- **§3.2 `Either<Failure, T>` everywhere** — compliant: contract, use case, repo impl all return `Future<Either<Failure, void>>`; impl catches all data-source exceptions.
- **§3.4 testing mandatory** — compliant: use-case unit test, in-memory drift delete+cascade test, repo-impl test, modal widget test.
- **§4.3.1 tap targets ≥48dp / prefer standard widgets** — compliant: `IconButton` (default 48dp) with tooltip.
- **PHI never logged** — compliant: medication name is shown in the dialog (allowed) but never logged.
- **Document new code (dartdoc)** — compliant: new public method/class/provider get `///` docs.
- **No `!` null-assertion; capture context before `await`** — compliant: reuse `_onSave`'s capture-before-await + `mounted` guard.

## Implementation Approach

### Layer Map

| Layer | What | Files (existing or new) |
|-------|------|------------------------|
| Domain | `delete` on the repo contract; new `DeleteMedication` use case | `domain/repositories/medication_repository.dart` (modify), `domain/usecases/delete_medication.dart` (**new**) |
| Data | drift delete method; repo impl of `delete` | `data/datasources/medication_local_data_source.dart` (modify), `data/repositories/medication_repository_impl.dart` (modify) |
| Presentation | `deleteMedicationProvider`; AppBar trash action + confirm dialog + delete handler | `presentation/providers/medication_providers.dart` (modify + `.g.dart` regen), `presentation/widgets/add_medication_modal.dart` (modify) |
| l10n | 7 new strings × 3 locales; regenerate | `l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` (modify) + generated `app_localizations*.dart` (regen) |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| Return type | `Future<Either<Failure, void>>`, `const Right(null)` | Matches settings-layer convention (`SettingsRepository.save*`); no fpdart `Unit` used elsewhere | `Either<Failure, Unit>` (inconsistent), returning `MedicationId` (unused) |
| Delete SQL | `(delete(medications)..where((m) => m.id.equals(id))).go()` — single statement, no transaction | FK `onDelete: cascade` + `pragma foreign_keys = ON` already remove slots; nothing else to coordinate | Manual slot-then-med delete (redundant), transaction wrapper (unnecessary for one statement) |
| Absent-id semantics | Idempotent success — `go()` returning 0 is not an error | End state matches intent; avoids spurious error on benign race; standard DELETE semantics | `NotFoundFailure` on 0 rows (extra UI branch for a near-impossible case) |
| Use-case shape | Thin forwarder: `call(MedicationId id) => _repo.delete(id)` | Mirrors `SetThemeMode`/`SetManualLanguage`; no validation needed for delete | Adding pre-checks/getById (out of scope, no read-single method exists) |
| Confirmation | `showDialog<bool>` + Material `AlertDialog`, Cancel→`false` / Delete→`true`; error-colored Delete label | Idiomatic Flutter; consistent with existing Material pickers in the modal | `AlertDialog.adaptive` (inconsistent as the only adaptive dialog), inline/undo (out of scope) |
| Affordance gating | Render trash `IconButton` only when `widget.initial != null` | Delete is meaningless in add mode; spec AC-7 | Always-visible (invalid in add mode) |
| Outcome idiom | Capture `messenger`/`navigator`/`l10n` before `await`; on `Right` show SnackBar then `pop()`; on `Left` show error SnackBar, stay open; `_isDeleting` guard | Reuse `_onSave` exactly — proven against `use_build_context_synchronously` (lints are errors here) | New ad-hoc pattern (regression risk) |
| Icon | `LucideIcons.trash2`, tinted `ColorScheme.error` | Package already imported in the modal; `trash2` confirmed present | `Icons.delete` (app standardizes on Lucide) |

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `lib/features/meds/domain/repositories/medication_repository.dart` | Modify | Add `Future<Either<Failure, void>> delete(MedicationId id);` + dartdoc (idempotent, cascade note). |
| `lib/features/meds/domain/usecases/delete_medication.dart` | **Create** | `DeleteMedication(this._repository)`; `Future<Either<Failure, void>> call(MedicationId id) => _repository.delete(id);` pure Dart + dartdoc. |
| `lib/features/meds/data/datasources/medication_local_data_source.dart` | Modify | Add `Future<void> deleteMedication(String id)` → single drift delete on `medications`; dartdoc noting slots cascade and throw-on-failure contract. |
| `lib/features/meds/data/repositories/medication_repository_impl.dart` | Modify | Implement `delete`: `try { await _dataSource.deleteMedication(id.value); return const Right(null); } catch (e, st) { return Left(Failure.unknown(e, st)); }`. |
| `lib/features/meds/presentation/providers/medication_providers.dart` | Modify | Add `@riverpod DeleteMedication deleteMedication(Ref ref) => DeleteMedication(ref.watch(medicationRepositoryProvider));` + dartdoc. |
| `lib/features/meds/presentation/providers/medication_providers.g.dart` | Regen | `dart run build_runner build` regenerates provider. |
| `lib/features/meds/presentation/widgets/add_medication_modal.dart` | Modify | AppBar `actions:` with edit-only trash `IconButton`; add `_confirmDelete()` (showDialog<bool>) + `_onDelete()` (mirrors `_onSave`); add `_isDeleting` flag. |
| `lib/l10n/app_en.arb` / `app_de.arb` / `app_uk.arb` | Modify | Add `medsDeleteButtonTooltip`, `medsDeleteDialogTitle`, `medsDeleteDialogBody` (`{name}` placeholder), `medsDeleteDialogConfirm`, `medsDeleteDialogCancel`, `medsDeleteSuccess`, `medsDeleteError` (+ `@`-metadata). |
| `lib/l10n/app_localizations*.dart` | Regen | `flutter gen-l10n` regenerates. |
| `test/features/meds/domain/usecases/delete_medication_test.dart` | **Create** | Use case forwards to repo; propagates `Right`/`Left` (mocktail `MockMedicationRepository`). |
| `test/features/meds/data/datasources/medication_local_data_source_delete_test.dart` | **Create** | In-memory `NativeDatabase.memory()`: insert med+slots, delete, assert med **and** slots gone (cascade); delete-absent-id is a no-throw no-op. |
| `test/features/meds/data/repositories/medication_repository_impl_test.dart` | Modify | Add `delete` cases: success → `Right(null)`; data-source throw → `Left(Failure.unknown)`. |
| `test/features/meds/presentation/widgets/add_medication_modal_test.dart` | Modify | Add: trash shown in edit / absent in add (AC-7); tap → dialog with name (AC-8); Cancel = no-op (AC-9); Delete → provider called, pop + success SnackBar (AC-10); `Left` → error SnackBar, stays open (AC-11). Override `deleteMedicationProvider` with a mock. |

### Documentation Impact

| Doc File | Action | What Changes |
|----------|--------|-------------|
| `docs/features/*.md` (meds feature doc, if present) | Update (by `/finalize` tech-writer) | Document the delete flow completing CRUD. |

No architecture/API doc changes — internal implementation using existing patterns. Docs are refreshed at `/finalize`, not during tasks.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Editing well-tested `add_medication_modal.dart` (specs 026–036) regresses add/edit | Med | Med | Delete path is purely additive + edit-mode-gated; existing modal widget tests must stay green in verification. |
| `use_build_context_synchronously` lint (errors here) across dialog + delete await | Med | Low | Capture `messenger`/`navigator`/`l10n` before `await`; `mounted` guard; mirror `_onSave`. |
| Cascade proof is weak (re-insert of same ids looks identical) | Low | Low | Delete is a true removal (not upsert); the in-memory test asserts row **count = 0** for both tables after delete — unambiguous. |
| Missing a locale → `flutter gen-l10n` untranslated-message failure | Med | Low | Add all 7 keys to all 3 ARB files in the same task; AC-13 verifies. |
| `build_runner` not re-run after adding the provider → stale `.g.dart` | Low | Med | Task includes `dart run build_runner build --delete-conflicting-outputs`; PostToolUse `dart analyze` catches undefined provider symbol. |

## Dependencies

None. No new packages (drift, fpdart, riverpod_annotation, lucide_icons_flutter, flutter_localizations all present). No services or env vars. No schema/migration change — the `onDelete: cascade` FK and `pragma foreign_keys = ON` already exist (`core/database/database.dart`), so `schemaVersion` stays at 1.

## Supporting Documents

None generated — no external research (no signals), no new data entities (no schema change), no API contracts (local-only app).

## Plan ↔ Spec AC Coverage

| AC | Covered by |
|----|-----------|
| AC-1 repo `delete` contract | `medication_repository.dart` (modify) |
| AC-2 `DeleteMedication` pure-Dart use case | `delete_medication.dart` (new) |
| AC-3 data-source delete + cascade | `medication_local_data_source.dart` + `..._delete_test.dart` |
| AC-4 repo impl Right/Left | `medication_repository_impl.dart` + test |
| AC-5 idempotent success | Delete SQL decision + data-source test (absent-id no-op) |
| AC-6 `deleteMedicationProvider` in seam | `medication_providers.dart` |
| AC-7 edit-only trash affordance | modal AppBar `actions:` gating |
| AC-8 confirm dialog w/ name | `_confirmDelete()` + `medsDeleteDialogBody({name})` |
| AC-9 Cancel = no-op | dialog returns `false` → early return |
| AC-10 Delete → pop + success SnackBar + list drops row | `_onDelete()` Right branch + reactive `medicationsListProvider` |
| AC-11 failure → error SnackBar, stays open | `_onDelete()` Left branch |
| AC-12 no `use_build_context_synchronously` / no double-invoke | capture-before-await + `_isDeleting` guard |
| AC-13 l10n across EN/DE/UK | 3 ARB files + gen-l10n |
| AC-14 analyze + tests green | all tasks end with analyze/test |
