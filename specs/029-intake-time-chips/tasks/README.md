# Tasks: Add-Medication Intake-Time Chips (visual-only, iteration 4)

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Generated**: 2026-06-14
**Total tasks**: 3
**Status**: ✅ All tasks Complete · spec **Complete** (verified 2026-06-15)

> **Verification** (`/verify`, 2026-06-15): all 14 ACs PASS (code-reading mode). `dart analyze` clean; `flutter test` 313/313. Security PASS (0 Critical/High); performance frame-budget-safe; test coverage **GAPS FOUND** (3 Medium — clock-icon assert, add-chip-last assert, 24h-under-12h-locale — all non-blocking quality top-ups). Verdict: **APPROVED**. See [../verify.md](../verify.md) and [../review.md](../review.md).

## Dependency Graph

```
001 (l10n keys) ──→ 002 (time-chips widget) ──→ 003 (widget tests)
```

Linear chain — each task gates the next. Mirrors the spec-028 structure (l10n → widget → tests).

## Task Index

| # | Title | Agent | Depends on | Review checkpoint | Status |
|---|-------|-------|-----------|-------------------|--------|
| 001 | Add the intake-time l10n keys | mobile-engineer | None | No | Complete |
| 002 | Add the intake-time chips section to the modal | mobile-engineer | 001 | Yes | Complete |
| 003 | Widget tests for the intake-time chips | qa-engineer | 002 | No | Complete |

## Additions to Spec

None. All affected files were already enumerated in the spec's "Affected Areas" (modal widget, 3 arb files + regenerated delegates, modal widget test). No cascading changes discovered — the new section is additive and independent of the spec-028 form-dependent gating.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Low | Mechanical arb additions following the existing `medsAdd*` pattern + `flutter gen-l10n`. |
| 002 | Med | Core logic: overlapping edit/delete tap targets (mitigated by `InputChip.onDeleted`), 24-hour enforcement, sort/dedupe, and the `mounted`-after-await rule. Carries the plan's Med-rated risks. |
| 003 | Med | Driving the real `showTimePicker` dialog in widget tests can be finicky (dial vs input mode); use the picker's text-input mode for determinism. |

## Review Checkpoints

| Before Task | Reason | What to Review |
|-------------|--------|----------------|
| (after) 002 | High-value core task / layer concentration | Separate edit-vs-delete tap targets; no `!`; `context.mounted` guards before SnackBar/setState; 24-hour format in both picker and labels; sort + dedupe correctness; Save still a no-op; no domain/data touched. |

## Contract Chain Integrity

No orphans, no unsatisfied expectations:
- **001 Produces** `medsAddTime*` getters → consumed by **002 Expects**; also maps to AC-11.
- **002 Produces** `_TimeChips` / `_intakeTimes` / `showTimePicker` / `alwaysUse24HourFormat` / `InputChip` / `ActionChip` → consumed by **003 Expects**; also map to AC-1…AC-10, AC-12, AC-13.
- **003 Produces** the test group + assertions → map to AC-1…AC-10, AC-14 (verification).
- **001 Expects** (`medsAddSaveButton`, arb files, `l10n.yaml`) and **002 Expects** Scaffold/Save/imports trace to existing codebase state.

## AC Coverage

| AC | Task(s) |
|----|---------|
| AC-1 section present/positioned/titled | 002 (+001 string), 003 |
| AC-2 empty initial state | 002, 003 |
| AC-3 add → 24h chip | 002, 003 |
| AC-4 cancel = no-op, no `!` | 002, 003 |
| AC-5 chip = clock + HH:MM + × | 002, 003 |
| AC-6 tap edits prefilled | 002, 003 |
| AC-7 × removes, no picker | 002 (+001 tooltip), 003 |
| AC-8 ascending order | 002, 003 |
| AC-9 dup rejected + SnackBar | 002 (+001 message), 003 |
| AC-10 24h everywhere | 002, 003 |
| AC-11 strings localized ×3 | 001 |
| AC-12 no-op Save, no domain/data | 002 |
| AC-13 analyze clean, no `!`, mounted | 002 |
| AC-14 existing tests pass | 003 |
