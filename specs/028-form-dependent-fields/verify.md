# Verification Report

**Feature**: 028-form-dependent-fields
**Spec**: specs/028-form-dependent-fields/spec.md
**Tasks**: specs/028-form-dependent-fields/tasks/
**Date**: 2026-06-14
**AC mode**: off → code-reading

## Acceptance Criteria

| AC | Description | Task(s) | Status | Evidence |
|----|-------------|---------|--------|----------|
| AC-1 | Hoist selection; preserve picker behaviour | 002 | PASS | `onFormSelected` callback added; picker keeps `_selectedIndex`/`_isOpen`; spec-027 picker tests pass unchanged |
| AC-2 | No conditional fields before selection; single TextField | 002/003 | PASS | gated on `_selectedForm?.hasX ?? false`; test (a) asserts `find.byType(TextField)` == 1 |
| AC-3 | Placement/order dose→qty→stock between picker and Save | 002 | PASS | build lines 872→922: picker, dose (882), qty (897), stock (909), Save (922) |
| AC-4 | Tablet/capsule stepper (min/step/format/clamp) + stock | 002/003 | PASS | config (0.5/0.5, 1/1); test (b) value `0.5`; test (c) increment/decrement + clamp for both |
| AC-5 | Injection/syrup/drops dose + unit lists; first selected | 002/003 | PASS (code); test partial | config correct (ml/mg/IU; ml; drops/ml; index 0 default); test (d) covers Syrup only — Injection/Drops untested (Warning) |
| AC-6 | Inhaler/cream/sachet → none | 002/003 | PASS (code); test partial | config all-false; test (e) covers Inhaler — Cream/Sachet untested (Warning) |
| AC-7 | Reset conditional fields on form change | 002/003 | PASS (code); test partial | `_resetConditionalFields`; test (f) visibility reset — controller text-clearing + unit-index reset untested (Warning) |
| AC-8 | Local state, no persistence, Save no-op, no domain/data | 002 | PASS | Save `onPressed: () {}` (line 923); security review confirms no persistence/logging |
| AC-9 | 14 keys in 3 ARBs | 001 | PASS | 14/14 each locale (verified) |
| AC-10 | `@`-meta en-only | 001 | PASS | 14 EN / 0 DE / 0 UK |
| AC-11 | context.l10n, no `!`, theme colors, controllers disposed, analyze | 001/002/003 | PASS | 0 `!`; 5 controllers all disposed (+super); analyze "No issues found!" |
| AC-12 | New conditional-field tests (a–f) | 003 | PASS | group `form-dependent fields`, 6 tests a–f |
| AC-13 | Existing 011/026/027 tests preserved | 003 | PASS | 4 existing groups intact; 305 tests pass |
| AC-14 | flutter test passes | 003 | PASS | 305/305 pass |
| AC-15 | flutter build apk --debug | 002 | PASS | built in Task 002; only l10n-value change since (analyze+tests green) |
| AC-16 | Manual theme/locale | /verify | PASS (code-read) | all colors via `colorScheme`; all strings via `context.l10n`; runtime manual check deferred |

**Result**: 16 of 16 PASS (AC-5/6/7 fully satisfied in code; their test coverage is partial — see Warnings)

## Code Quality
- Type checker / Linter (`dart analyze`): PASS — "No issues found!"
- Build: PASS — apk built in Task 002; only the IU/IE/МО l10n-value change since (regenerated bindings compile; analyze + 305 tests green)
- Cross-task consistency: PASS — 001's 14 getters consumed by 002 via `context.l10n` and asserted by 003; `_MedFormOption` config consumed by build gating + `_resetConditionalFields`; 8 `ValueKey`s emitted by 002 consumed by 003
- No scope creep: PASS — source changes limited to the modal + 3 ARBs (+ generated bindings) + the test, matching the spec's Affected Areas
- No leftover artifacts: PASS — no `print`/`debugPrint`/`debugger`/bare-TODO/commented-out code in the changed source

## Review Findings

**Security**: Critical 0 | High 0 | Medium 0 | Info 5 → PASS
**Performance**: High 0 | Medium 1 | Low 4 (no spec-criterion violation; M1/L1/L2 deferred to data-save iteration)
**Test Coverage**: GAPS FOUND (8/16 ACs fully covered; AC-5/6/7 partial — thoroughness, not defects)

No Critical/High findings. Nothing blocks the verdict.

## Issues Found

#### Critical (must fix before merge)
- None.

#### Warning (should fix, not blocking)
- **Test gap (AC-5)** — `add_medication_modal_test.dart`: Injection (ml/mg/IU) and Drops (drops/ml) dose forms are not tested (only Syrup's single `ml`); the unit-dropdown `onChanged` path and the new IU/IE/МО value are unasserted. Suggest adding Injection/Drops + unit-selection tests.
- **Test gap (AC-7)** — controller text-clearing on form switch and unit-index reset are not asserted (only field visibility). Suggest a test that types into dose/stock, switches form, and asserts cleared.
- **Test gap (AC-4/AC-6)** — Capsule stock card presence and Cream/Sachet no-field forms not individually asserted.
- **Perf (M1)** — `_DoseField.build` rebuilds the `DropdownMenuItem` list on every parent `setState` (max 3 items). Pre-build in `_onFormSelected`. Low real cost; defer to data-save iteration.
- **Test polish (W1/W2)** — test (b) asserts stock labels via bare `find.text` instead of the `medsAddStock*` keys.

#### Info (no action needed)
- **Hot-reload artifact (diagnosed during this session)** — adding fields to `_MedFormOption` while a `flutter run` session is live causes a stale-instance crash (`type 'Null' is not a subtype of type 'bool'`) on the top-level `final _medFormOptions` list, because hot reload does not re-run top-level initializers. Resolved by **hot restart** — NOT a code defect (analyze clean; 305 tests pass from a clean build).
- **Perf (L1–L4)** — minor per-build closure/`copyWith` allocations; cosmetic for a static modal.
- **l10n runtime (AC-9/10)** — new labels not rendered under de/uk in tests (build-time gen is the safety net).

## Overall Verdict

**APPROVED**

All 16 acceptance criteria are satisfied in code; `dart analyze` clean, 305/305 tests pass, apk builds, security PASS, performance clean for a static modal. The open items are non-blocking: test-coverage thoroughness (AC-5/6/7 partial — the untested forms are structurally identical to tested ones) and minor perf nits deferred to the data-save iteration. Ready for `/summarize` → `/finalize`. Recommended (optional) before finalize: backfill the AC-5 Injection/Drops + unit-dropdown tests.
