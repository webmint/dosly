<!-- This file is a fixed-size sliding window. Always fully overwritten, never appended. Max ~40 lines. -->
# Session State
Last updated after Task 3: Widget tests for the form-dependent fields

## Current Feature
028-form-dependent-fields

## Session Stats
Tasks completed this session: 3
Estimated context load: moderate (3-5)

## Progress
- Last completed: Task 3 — Widget tests for the form-dependent fields
- Next pending: none — all 3 tasks Complete
- Tasks remaining in feature: 0 → ready for /review → /verify → /summarize → /finalize

## Key Decisions This Session (last 3 only)
- Hoist picker selection via `ValueChanged<_MedFormOption>` callback (not full state-lift) → spec-027 tests untouched.
- Conditional fields gated on `_selectedForm?.hasX ?? false` → absent before selection → spec-026 single-TextField test preserved.
- Controllers are permanent State fields cleared on form change; per-form config lives on `_MedFormOption` (no String switch).

Older decisions are persisted in .claude/memory/MEMORY.md.

## Files Modified Recently (last 3 tasks only)
- test/features/meds/presentation/widgets/add_medication_modal_test.dart: +6 tests, new `form-dependent fields` group (Task 3)
- lib/features/meds/presentation/widgets/add_medication_modal.dart: hoist + _DoseField/_QuantityStepper/_StockCard + config + controllers (Task 2)
- lib/l10n/app_{en,de,uk}.arb (+ regenerated app_localizations*.dart): 14 new keys (Task 1)

## Active Constraints
- Visual-only iteration: Save stays a no-op; no domain/data/persistence.
- W1 RESOLVED: `medsAddUnitUnits` set to International Units — EN "IU" / DE "IE" / UK "МО" (user choice 2026-06-14).
