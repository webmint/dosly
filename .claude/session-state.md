<!-- This file is a fixed-size sliding window. Always fully overwritten, never appended. Max ~40 lines. -->
# Session State

## Current Feature
035-meds-list-search — meds-list search rework (animated slide-in bar + typo-tolerant ranked fuzzy + empty-state/completed-tile design fidelity). Branch `spec/035-meds-list-search`.

## Progress
ALL 7 tasks COMPLETE. Ready for `/review` → `/verify` → `/summarize` → `/finalize`.

| # | Task | Agent | Status |
|---|------|-------|--------|
| 001 | Pure-Dart fuzzy scorer (core/utils) | architect | Complete |
| 002 | Fuzzy scorer unit tests (38) | qa | Complete |
| 003 | View-model fuzzy + score ranking | architect | Complete |
| 004 | View-model fuzzy/ranking tests (19) | qa | Complete |
| 005 | Completed-tile de-emphasis + chip order | mobile | Complete |
| 006 | Animated search bar + queryActive gating | mobile | Complete |
| 007 | Widget tests (search/empty/tiles) + golden | qa | Complete |

## Recent Decisions
- Fuzzy = pure-Dart Levenshtein (no package); bands exact≥prefix>contains>fuzzy; inclusion `score>=0.6`; score-ranked while query active, alphabetical otherwise; transient `(double,MedListItem)`, no model field.
- Search bar in `AppBar.flexibleSpace` + `SlideTransition`; animations promoted to State fields; focus deferred post-animation; `IgnorePointer` gating.
- Completed tile: `Opacity(0.65)` + neutral `surfaceContainerHighest` badge/chip (`surfaceVariant` deprecated). Course chip order = type-then-status.

## Verification
Full `flutter test`: **541/541 pass**. `dart analyze`: clean. Code review at 006 (APPROVE+3 warnings fixed) and 007 (APPROVE, 1 Critical `as` cast fixed + re-verified). Golden integration test headless-skipped (emulator low disk); AC-19 reactive-add proxy passes.

## Notes
No schema/pubspec/l10n change (existing keys reused). 2 new files: `lib/core/utils/fuzzy_name_match.dart`, + tile/section tests. WIP commits accumulate — squash at /finalize. Lessons logged to MEMORY (surfaceVariant deprecation, find.byIcon ambiguity, emulator low-disk).
