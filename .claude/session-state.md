<!-- This file is a fixed-size sliding window. Always fully overwritten, never appended. Max ~40 lines. -->
# Session State

## Current Feature
030-intake-type-control — Add-medication: intake-type control (Continuous/Course) (visual-only, iteration 5)

## Progress
All 3 tasks COMPLETE. Ready for `/review` → `/verify` → `/summarize` → `/finalize`.

| # | Task | Agent | Status |
|---|------|-------|--------|
| 001 | intake-type l10n keys (en/uk/de) | mobile-engineer | Complete |
| 002 | intake-type widget + course card (+ promote clock) | mobile-engineer | Complete |
| 003 | widget tests (11) | qa-engineer | Complete |

## Recent Decisions
- Default type = Continuous (card hidden on open); info chip = live-computed (end = start + duration-1, inclusive); start date = today via `DateUtils.dateOnly(clock.now())`.
- First ICU plural + placeholder in project. `medsAddCourseRangeLabel(String,int)` + `medsAddCourseStartOnly(String)`. uk one/few/many/other.
- `clock` promoted transitive→direct (resolved 1.1.2). Dates via `MaterialLocalizations.formatMediumDate` (en = "Thu, Mar 26", no year).

## Recently Modified Files
- lib/l10n/app_{en,uk,de}.arb (+ regenerated app_localizations*.dart) (Task 001)
- lib/features/meds/presentation/widgets/add_medication_modal.dart, pubspec.yaml (Task 002)
- test/features/meds/presentation/widgets/add_medication_modal_test.dart (Task 003 — +11 tests)

## Verification
dart analyze clean; flutter test 324/324 pass. Reviews: 001 APPROVE w/warnings; 002 (checkpoint) APPROVE w/warnings; 003 APPROVE w/warnings (W1/W2 repaired). No Critical anywhere.

## Notes
10 WIP commits on branch spec/030-intake-type-control — squashed by /finalize. heavy `flutter build apk` deferred; compile confirmed via clean analyze + full test suite. Two non-blocking notes: pubspec hand-edit (logged), showDatePicker window derived from _startDate (spec-accepted).
