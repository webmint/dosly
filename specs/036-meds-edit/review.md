# Review Report: 036-meds-edit

**Date**: 2026-06-19
**Spec**: specs/036-meds-edit/spec.md
**Changed files**: 14 source/doc/l10n + 5 test files (all 10 tasks Complete)

## Security Review

- Critical: 0 | High: 0 | Medium: 1 | Info: 7
- **Overall: PASS** — no new exploitable vulnerabilities, no constitution §4.2.1 (PHI) violations.

- **Medium** — `add_medication_modal.dart` (`_onSave` failure fold): The edit/update path's `Left(Failure.unknown(error, stack))` is correctly NOT surfaced — a non-`ValidationFailure` falls into the `_ => medsAddSaveErrorGeneric` wildcard arm, so a raw `SqliteException` (which could echo a medication name/dosage) never reaches the SnackBar or a log. This is the correct, load-bearing control.
  Recommendation: Preserve the wildcard arm — do NOT add a branch that renders `failure.toString()`/`error.toString()` in a future refactor.

- **Info (verified-good)**:
  - No PHI logging anywhere in the changed code (`grep print/debugPrint/logger/developer.log` over `lib/features/meds/` = 0 hits); the repo `update` catch wraps into `Left(Failure.unknown)` without logging — satisfies §4.2.1.
  - `upsertMedication` empty-slots `ArgumentError` guard prevents the `NOT IN ()` cascade-delete footgun; its message never reaches UI/logs.
  - `insertOnConflictUpdate` (not REPLACE) correctly avoids cascade-deleting intake history (availability/data-integrity control).
  - Domain-boundary validation in `EditMedication` mirrors `AddMedication` (name/times/duration/dose) before any write; `*.values.byName(form.key)` operate on a closed internal set, not user free-text (no injection risk).
  - No raw SQL, no untrusted deserialization, no `dart:mirrors`/`Process.run`/`dart:io` in changed code.
  - Drift DB unencrypted at rest — pre-existing accepted MVP trade-off, not introduced here.

- **Pre-existing, OUT OF SCOPE for 036** — `meds_screen.dart:209` renders `e.toString()` in the read-path (`watchAll`) error state, which could surface a raw `SqliteException`. Introduced by spec 034 (commit `10dffb6`); 036 only added the tap-to-edit wiring in this file.
  Recommendation: A future hardening pass should map read-path failures to a generic localized string (as the edit save path already does). Not a blocker for 036.

## Performance Review

- High: 0 | Medium: 0 | Low: 1 (+5 confirmed fine-as-is)
- **Overall: No performance issues at the target scale** (personal med list: 1–20 meds, 1–6 slots each).

- **Low** — `medication_local_data_source.dart` `upsertMedication`: the per-slot `insertOnConflictUpdate` loop issues N sequential awaits inside the transaction, diverging from the sibling `insertMedication` which uses `_db.batch(...)`. At 1–6 slots this is sub-millisecond and not user-observable, but asymmetric with the create path.
  Recommendation: Fine as-is; optionally note `_db.batch((b) => b.insertAllOnConflictUpdate(_db.timeSlots, slots))` in a comment as the future-proof alternative (would matter only for a hypothetical bulk-import reuse). Do not block on it.

- **Confirmed fine-as-is** (Low/none): `initState` pre-fill (`where` over 8 options + 6-element sort, one-shot off the frame path); per-tile `onTap` closures (negligible, rebuilt only on a stream emission); `InkWell` wrapper (`onTap: null` ⇒ no recognizer/splash, ≈`Padding` cost); reactive list rebuild (single transaction ⇒ exactly one stream emission, not N); slot reconciliation map+comprehension (O(n), n≤6, no O(n²)).

## Test Assessment

- AC items with test coverage: **10 of 16 fully Covered; 5 Partial; 0 with zero coverage**
- New tests: 7 use-case + 5 repo (real in-memory drift) + 5 modal edit-mode + 3 tile + 1 screen. Full suite 566/566 pass.
- **Verdict: GAPS FOUND** (no AC is entirely untested; gaps are missing edge-case/negative-path assertions)

### AC coverage
- **Covered**: AC-1, AC-3, AC-5, AC-6, AC-7, AC-8, AC-9, AC-10, AC-11, AC-14, AC-16
- **Partial**: AC-2 (≥48dp tap-target size not asserted), AC-4 (name + form-display tested; dose/dose-unit-index/stock pre-fill NOT asserted), AC-12 (Right/success path tested; edit-mode **validation-failure** SnackBar+no-pop NOT tested; save-disabled-in-flight tested only in add mode), AC-13 (tile-tap-opens-modal tested; no end-to-end "edit→save→list shows updated value"), AC-15 (keys present in all 3 ARB; no `uk`-locale render assertion)

### Coverage gaps (by priority)
- **High — Gap 2**: Edit-mode validation-failure path (e.g. clear the name then Save) is not widget-tested. `_onSave` shares the `fold` across modes, but a regression making the edit branch always pop would pass unnoticed.
- **Medium — Gap 4**: Edit pre-fill of the quantity stepper value, dose-unit dropdown index, and stock controllers (remaining/total/warnAt) is seeded in `initState` but never asserted — a seeding regression would be invisible.
- **Medium — Gap 1**: `upsertMedication`'s empty-slots `ArgumentError` guard is untested (upstream-blocked by validation, but it guards a destructive SQLite footgun — worth a direct datasource test).
- **Low — Gap 3**: `MedicationTile` ≥48dp tap target not asserted (`tester.getSize`). Relies on natural content height (no explicit `BoxConstraints`).
- **Low — Gap 5**: Save-disabled-while-in-flight not asserted for edit mode (same `_isSaving` flag as add).
- **Low — Gaps 6/7**: `notes` and Continuous `startDate` preservation through the `update` path not asserted — these were the Task-007 spec-compliance fixes; a one-line `capturedUpdate.type as ContinuousType` + `.startDate` / `.notes` assertion in the existing edit save test would close them.
- **Low — Gap 8**: Form-switch during edit (Tablet→Syrup clears stock via `_resetConditionalFields` over pre-seeded controllers) not exercised.
- **Info — Gap 9**: Edit-mode strings only rendered under `en` (consistent with project locale policy / MEMORY F143).

## Summary for /verify

Security PASS (1 Medium = "preserve the generic-error control"; the one actionable item is pre-existing spec-034 scope). Performance clean (1 Low cosmetic batch-asymmetry note). Tests: solid domain/data coverage; the most valuable top-up is **Gap 2** (edit-mode validation-failure widget test) then **Gap 4** (assert edit pre-fill of dose/stock). None of these block correctness — they are regression-net improvements. Recommend addressing Gap 2 (and optionally Gaps 4/6/7 via a one-line assertion in the existing save test) before `/finalize`.
