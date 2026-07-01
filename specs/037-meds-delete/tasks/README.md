# Tasks: Delete Medication

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Generated**: 2026-07-01
**Total tasks**: 7

## Dependency Graph

```
001 (domain: contract + use case)
 ├─→ 002 (data: data source + repo impl) ─→ 006 (unit tests: domain + data)
 └─→ 003 (seam: provider) ─┐
                           ├─→ 005 (UI: modal delete) ─→ 007 (widget test)
004 (l10n: strings) ───────┘
```

Execution order: **001 → 002 → 003 → 004 → 005 → 006 → 007**.
(002/003/004 depend only on 001-or-nothing and may run in any order; 006 needs 002; 005 needs 003 + 004; 007 needs 005.)

## Task Index

| # | Title | Agent | Depends on | Checkpoint | Status |
|---|-------|-------|-----------|-----------|--------|
| 001 | Domain: `delete` contract + `DeleteMedication` use case | architect | None | No | Complete |
| 002 | Data: data source `deleteMedication` + repo impl `delete` | architect | 001 | No | Complete |
| 003 | Seam: `deleteMedicationProvider` | architect | 001 | No | Complete |
| 008 | Fix existing repo test fakes for `delete` (discovered) | qa-engineer | 001 | No | Complete |
| 004 | l10n: delete strings (EN/DE/UK) + regen | mobile-engineer | None | No | Complete |
| 005 | UI: modal trash affordance + confirm dialog + `_onDelete` | mobile-engineer | 003, 004 | **Yes** | Complete |
| 006 | Unit tests: use case + data-source cascade + repo impl | qa-engineer | 002 | No | Complete |
| 007 | Widget test: modal delete flow | qa-engineer | 005, 008 | No | Complete |

**Execution order (updated)**: 001 → 002 → 003 → **008** → 004 → 005 → 006 → 007.

## Additions to Spec

- **Generated files** made explicit (regeneration steps, not hand-edited): `medication_providers.g.dart` (Task 003, build_runner) and `app_localizations*.dart` (Task 004, gen-l10n). Both are in the spec's Affected Areas implicitly.
- **Test file name** pinned: the data-source cascade test lives in a new `medication_local_data_source_delete_test.dart` (mirrors the existing `..._watch_test.dart` split), rather than extending the watch test.
- **Task 008 (discovered during execution)**: adding `delete` to the `MedicationRepository` interface in Task 001 broke 5 hand-written test fakes (`meds_screen_test.dart` ×3, `add_medication_modal_test.dart` ×2) that `implements MedicationRepository` — the whole suite stopped compiling. Task 008 adds no-op `delete` stubs to restore the build. The original breakdown missed this interface-change cascade.
- No new production files beyond the spec's list.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Low | Additive domain contract + thin forwarder use case; established pattern. |
| 002 | Low | Single drift delete; cascade FK already configured. Only nuance: no manual slot delete, idempotent 0-row. |
| 003 | Low | Mirrors `add`/`edit` providers; build_runner regen. |
| 004 | Low | Locale sync — the only failure mode is a missing translation (gen-l10n catches it). |
| 005 | **High** | Edits the heavily-tested add/edit modal (specs 026–036); first `AlertDialog` in the codebase; `use_build_context_synchronously` across dialog + delete await. Additive + edit-mode-gated to contain blast radius. |
| 006 | Low | Follows existing test idioms (mocktail, in-memory drift). |
| 007 | Low–Med | Widget test of the risky modal; must keep existing modal tests green and avoid `find.byIcon` ambiguity. |

## Review Checkpoints

| Before Task | Reason | What to Review |
|-------------|--------|----------------|
| 005 | Convergence (deps 003 + 004) + first presentation-layer task + High risk | Confirm the domain→data→provider contract (001–003) is coherent and the l10n keys (004) exist before touching the tested modal; verify the delete path reuses the `_onSave` capture-before-await idiom and is edit-mode-gated. |

## Contract Consistency Check

**No orphans, no unsatisfied expects.**
- 001 Produces (`delete` decl, `DeleteMedication`/`call`) → consumed by 002, 003, 006. ✅
- 002 Produces (`deleteMedication`, repo-impl `delete` Right/Left) → consumed by 006; maps to AC-3/4/5. ✅
- 003 Produces (`deleteMedicationProvider`) → consumed by 005, 007. ✅
- 004 Produces (l10n keys + `AppLocalizations` getters) → consumed by 005. ✅
- 005 Produces (`_onDelete`/`_confirmDelete`/`_isDeleting`, trash `IconButton`, `showDialog`) → consumed by 007. ✅
- 006 / 007 Produces (test groups) → terminal, map directly to spec ACs. ✅

Every `Expects` traces to an upstream `Produces` or existing codebase state (contract interfaces, `_harness`, drift in-memory setup, `_onSave` idiom).

## Acceptance Criteria Coverage

| AC | Task(s) |
|----|---------|
| AC-1 | 001 |
| AC-2 | 001, 006 |
| AC-3 | 002, 006 |
| AC-4 | 002, 006 |
| AC-5 | 002, 006 |
| AC-6 | 003 |
| AC-7 | 005, 007 |
| AC-8 | 005, 007 |
| AC-9 | 005, 007 |
| AC-10 | 005, 007 |
| AC-11 | 005, 007 |
| AC-12 | 005 |
| AC-13 | 004 |
| AC-14 | all (each task ends with `dart analyze` + `flutter test`) |
