# Tasks: Tap-to-Edit Medication

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Generated**: 2026-06-19
**Total tasks**: 10

## Completion Summary

**Status**: ✅ Complete — verified 2026-07-01 (`/verify`).

- All 10 tasks Complete; all 16 acceptance criteria PASS (code-reading + tests).
- `dart analyze`: clean (No issues found). `flutter test`: **568/568 pass**. `flutter build apk`: ✅ built (62.7 MB release APK).
- `/review` (see `../review.md`): Security PASS (1 Medium = preserve generic-error control), Performance clean (1 Low cosmetic), Tests GAPS FOUND.
- `/fix` closed the high-value test gaps: edit-mode validation-failure widget test (Gap 2) + notes & Continuous-startDate preservation assertions (Gaps 6/7). Low gaps 1/3/4/5/8/9 parked in `../review.md` for `/audit`.
- Cross-task integration consistent (contract→impl→use case→provider→modal→tile→section→screen); no scope creep; no leftover artifacts.
- Next: `/summarize` → `/finalize` (squashes the accumulated `[WIP]`/`[checkpoint]` commits, incl. the mid-feature `/fix` commits, into one feature commit).

## Dependency Graph

```
001 (datasource upsert) ──→ 002 (repo update + fakes) ──→ 003 (use case + provider) ──→ 004 (use case tests)
                                          │                          │
                                          └──→ 005 (repo tests)      └──→ 007 (modal edit mode) ──→ 008 (tile/section/screen) ──→ 009 (widget tests) ──→ 010 (docs)
006 (l10n keys) ─────────────────────────────────────────────────────→ 007
```

Sequential execution order `001 → 010` respects every dependency (each task's deps have lower numbers).

## Task Index

| # | Title | Agent | Depends on | Status |
|---|-------|-------|-----------|--------|
| 001 | Add transactional upsert to the medication data source | architect | None | Complete |
| 002 | Add `update` to the repository contract, impl, and test fakes | architect | 001 | Complete |
| 003 | Create the `EditMedication` use case + `editMedicationProvider` | architect | 002 | Complete |
| 004 | Unit-test the `EditMedication` use case | qa-engineer | 003 | Complete |
| 005 | Round-trip test the repository `update` path | qa-engineer | 002 | Complete |
| 006 | Add edit-mode localization keys | mobile-engineer | None | Complete |
| 007 | Parameterize the modal for edit mode + seed the form picker | mobile-engineer | 003, 006 | Complete |
| 008 | Wire tile tap → open the edit modal (tile, section, screen) | mobile-engineer | 007 | Complete |
| 009 | Widget tests for edit-mode pre-fill, save routing, and tile tap | qa-engineer | 007, 008 | Complete |
| 010 | Document the edit/update path | tech-writer | 008, 009 | Complete |

## Additions to Spec

- **Test-fake patching folded into Task 002**: the spec's Affected Areas listed the modal/screen tests generically; analysis confirmed four hand-written `implements MedicationRepository` fakes (3 in `meds_screen_test.dart`, 1 in `add_medication_modal_test.dart`) that the interface change breaks at `dart analyze`. They are patched in Task 002 (same change as the interface edit) to keep analyze green — the MEMORY F032/F022 atomic-interface-change lesson. No new source files beyond the spec.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | High | The `insertOnConflictUpdate` vs `insertOrReplace` choice is load-bearing — a REPLACE would cascade-delete the medication's time slots via the FK on every edit. |
| 002 | Med | Interface-method addition breaks every hand-written fake at compile; must land impl + 4 fake stubs atomically. |
| 003 | Med | Slot-ID reconciliation correctness (preserve unchanged, mint new, drop removed); pure-Dart purity. |
| 007 | High | Largest-regression-risk: pre-filling a 1700-line modal without breaking the tested add flow (specs 026–034); picker must stay byte-identical when `initialFormKey == null`. |
| 008 | Med | First end-to-end wiring; must not regress the list screen; `InkWell` not `GestureDetector`. |
| 004, 005, 009 | Low | Test authoring against settled contracts. |
| 006, 010 | Low | l10n strings / docs. |

## Review Checkpoints

| Before Task | Reason | What to Review |
|-------------|--------|----------------|
| 001 | High risk | `upsertMedication` uses `insertOnConflictUpdate` (NOT `insertOrReplace`); removed-slot delete is scoped by `medicationId` + `isNotIn`; transactional. |
| 007 | High risk + first presentation-layer task | Add path byte-identical when `initial == null`; picker unchanged when `initialFormKey == null`; correct pre-fill mapping (form, dose-unit index, course date round-trip); edit Save routes to `editMedicationProvider`; no unguarded `!` on `widget.initial`. |
| 009 | Convergence (depends on 007 + 008) | Edit-mode tests assert pre-fill + `editMedicationProvider` routing (not add); tile `onTap`/`InkWell`; add-flow regression guard green; full suite passes. |

## Contract Consistency

- **No orphans**: every "Produces" is consumed by a downstream "Expects" (001→002/005, 002→003/005/009, 003→004/007, 006→007, 007→008/009, 008→009) or maps to a spec AC (test/doc tasks 004/005/009/010).
- **No unsatisfied "Expects"**: every precondition traces to an upstream "Produces" or existing codebase state (Task 001's Expects describe the current data source/`AppDatabase`).
- **All 16 ACs covered**: AC-1/2 (008, 009); AC-3/4/5/6 (007, 009); AC-7 (002, 005); AC-8 (001, 005); AC-9 (001, 003, 004, 005); AC-10/11 (003, 004); AC-12 (007, 009); AC-13 (009); AC-14 (007, 009); AC-15 (006); AC-16 (004, 005, 009).
