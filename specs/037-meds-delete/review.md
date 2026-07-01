# Review Report: 037-meds-delete

**Date**: 2026-07-01
**Spec**: specs/037-meds-delete/spec.md
**Changed files**: 8 production/l10n + 5 test files

## Security Review

- Critical: 0 | High: 0 | Medium: 0 | Info: 6
- **Overall: PASS**

All Info items are verifications, not action items:
- **Info** — `medication_local_data_source.dart:108`: delete predicate is single-id scoped and parameterized (`..where((m) => m.id.equals(id))`) — no injection (CWE-89 N/A), no mass-delete; structurally avoids the `NOT IN ()` empty-list hazard the sibling `upsertMedication` must guard against.
- **Info** — `time_slots_table.dart:39` + `database.dart:52`: cascade is real (`onDelete: KeyAction.cascade`) and enforced per connection (`pragma foreign_keys = ON` in `beforeOpen`); no orphaned slots survive a delete.
- **Info** — delete path: no PHI logging — zero `print`/`debugPrint`/logger in the meds feature; medication name appears only in the on-device dialog body (`medsDeleteDialogBody(medication.name)`), which the constitution permits; error branch uses `Failure.unknown(e, st)` + a generic localized string, leaking no name.
- **Info** — `add_medication_modal.dart:1699`: irreversible delete gated behind an explicit `AlertDialog`; dismiss/back/barrier → `confirmed ?? false` no-op; trash button disabled while any save/delete is in flight.
- **Info** — trust boundary at `MedicationId` (from `widget.initial.id`, a loaded aggregate, not raw input) is sound; the use case's no-validation design is appropriate for a local idempotent delete.
- **Info** — `_onDelete` captures `messenger`/`navigator`/`l10n` before both awaits and re-checks `mounted` — no `use_build_context_synchronously` defect.

## Performance Review

- High: 0 | Medium: 0 | Low: 2

Both Low items are pre-existing patterns, negligible at this app's scale (local, single-user, tens–hundreds of rows); no action required:
- **Low** — `time_slots_table.dart:38-39`: `TimeSlots.medicationId` (FK column) has no explicit index, so the cascade `DELETE` scans `time_slots`. Sub-millisecond at this scale; only worth an `@TableIndex` (schema migration) if a large import/sync dataset is ever introduced.
- **Low** — `add_medication_modal.dart` (monolithic `build`): toggling `_isDeleting` via `setState` rebuilds the whole modal tree. Mirrors the existing `_isSaving` idiom, fires at most twice per tap, well within the 16 ms frame budget; splitting out a `Consumer` would be premature optimization.

Delete path confirmed optimal: single indexed-PK `DELETE`, no pre-read/existence check, no N+1 (cascade native), runs off the main isolate via `drift_flutter`; reactive list uses the unchanged watched join; `deleteMedicationProvider` is a thin `ref.read`-once wrapper (no watch churn).

## Test Assessment

- AC items with full test coverage: **14 of 14** (was 11/14 at review time; the 3 gaps below were closed in a post-verify test-hardening pass).
- **Verdict: ADEQUATE** (originally GAPS FOUND — all 3 gaps now closed; suite 583 → 587)

### Gaps — RESOLVED (post-verify test-hardening, 2026-07-01)
- **AC-12** ✅ closed — `add_medication_modal_test.dart:2784` "trash IconButton.onPressed is null while delete is in flight" (`Completer`-based, mirrors the Save-in-flight test).
- **AC-13** ✅ closed — `add_medication_modal_test.dart:2840` (DE) + `:2874` (UK) render the translated tooltip + dialog title.
- **AC-10** ✅ closed — `medication_local_data_source_delete_test.dart:167` asserts `watchAllMedications()` re-emits without the deleted medication.

### Original gaps (for the record)

Coverage is otherwise strong — precise assertions (call counts, exact captured id, SnackBar text + modal state together), a genuine cascade proof (both tables asserted empty with a populated pre-assert), and the erroring-data-source double mirrors the existing `_UpsertErroringDataSource` pattern. No redundant/weak assertions.

### Gaps
- **AC-12 (in-flight double-invoke guard) — behavioral test missing** _(Medium-High)_: the guard exists in code (`onPressed: (_isDeleting || _isSaving) ? null : _onDelete`, `add_medication_modal.dart:1810`) and `dart analyze` is clean (static half satisfied), but no test drives it. A `Completer`-based test mirroring the existing Save-in-flight test (`add_medication_modal_test.dart:452-492`) would assert the trash `IconButton.onPressed == null` mid-flight.
- **AC-13 (DE/UK translations) — not exercised in a widget test** _(Medium)_: all 7 keys are present + translated in `app_en/de/uk.arb`, but every spec-037 delete test uses `Locale('en')` only. The file's own convention spot-checks DE/UK for new strings (e.g. the locale-switching group at `:266-280`). `flutter gen-l10n` catches missing keys but not garbled content/placeholder errors; one `de`/`uk` render of the tooltip or dialog would close this.
- **AC-10 (reactive list refresh clause) — untested** _(Low-Medium)_: AC-10's "the deleted medication no longer appears in the meds list" reuses the proven watched-join machinery (insert/update re-emission is tested at `medication_repository_impl_test.dart:419-429`), but no test directly proves `watchAll()` re-emits a shorter list after a `delete()`. Acceptable residual risk (reused machinery), but a literal AC clause with no direct coverage.
