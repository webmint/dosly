## Feature Summary: 035 — Meds-List Search & Empty-State Fidelity

### What was built
Reworked the medications-list search to match the design: an animated slide-in search bar that filters the list as you type, now with **typo-tolerant fuzzy matching** (e.g. "omeprzol" still finds "Omeprazol") that ranks the closest matches first. Empty states were brought in line with the template — the per-section "nothing found" message only appears while searching — and completed-course medications are now visually de-emphasised. All changes are on-device only: no schema, dependency, or localization changes.

### Changes
- Task 001: Pure-Dart fuzzy name scorer — `levenshtein` + `fuzzyNameScore` (0–1, substring/prefix always outranks fuzzy) in `lib/core/utils/`, no dependency.
- Task 002: 38 unit tests for the scorer (exact/prefix/substring/typo/transposition/below-threshold/Cyrillic).
- Task 003: View-model now matches by fuzzy score (substring guaranteed) and orders by score while searching, alphabetically otherwise.
- Task 004: View-model tests for fuzzy inclusion, score-over-alphabetical ranking, and search-then-filter order.
- Task 005: Completed-course tiles de-emphasised (0.65 opacity + neutral badge + grey status chip); course tiles show the day chip before the status chip.
- Task 006: Animated slide-in search bar in the app bar (surface-container background, inline clear, deferred focus); per-section empty placeholder gated on an active query.
- Task 007: Widget tests for search open/close, empty-state gating, completed-tile styling, and chip order; golden-flow re-check.

### Files changed
- `lib/core/utils/` — 1 added (`fuzzy_name_match.dart`)
- `lib/features/meds/presentation/` — 4 modified (`screens/meds_screen.dart`, `view_models/meds_list_view_model.dart`, `widgets/medication_section.dart`, `widgets/medication_tile.dart`)
- `test/core/utils/` — 1 added
- `test/features/meds/presentation/` — 2 added (`widgets/medication_section_test.dart`, `widgets/medication_tile_test.dart`), 2 modified (`screens/meds_screen_test.dart`, `view_models/meds_list_view_model_test.dart`)
- `specs/035-meds-list-search/`, `research/`, `.claude/` — feature artifacts
- [Total: 25 files changed, 2900 insertions, 164 deletions — production: 1 added + 4 modified]

### Key decisions
- Fuzzy engine: hand-rolled pure-Dart Levenshtein (no package) — avoids §2.3 abandonment/telemetry risk for a ~40-line algorithm on a privacy-first local app.
- Matching/ranking stays in-memory in the pure view model over the already-reactive list — no DB/FTS query, no schema change.
- Inclusion = `fuzzyNameScore ≥ 0.6` (named const, subsumes the substring guarantee); score is transient, so `MedListItem` gains no field.
- Search bar lives in `AppBar.flexibleSpace` (overlay) so the routing shell / bottom-nav is untouched; animations are State fields; focus is requested after the open animation.

### Deviations from plan
- Task 003: inclusion-threshold const named `medsSearchIncludeThreshold` (lowerCamelCase) rather than the suggested `kMeds…` — matches constitution §3.3 (constants are lowerCamelCase; `k`-prefix reserved for private).
- Task 005: `ColorScheme.surfaceVariant` is deprecated in this Flutter version → used `surfaceContainerHighest` (the design's `--md-surface-variant` equivalent; `surfaceVariant` fails `dart analyze`).
- Task 007 (AC-17): the on-device golden integration test was initially unrunnable (emulator out of disk). After freeing emulator space, the run exposed a latent feature-034 regression — the debug seeder (`devSeedProvider`, fired from `AppBootstrap`) populated the temp DB in `kDebugMode`, breaking the golden flow's exact-row-count assertions. Fixed by overriding `devSeedProvider` to a no-op in the integration harness (`integration_test/support/app_harness.dart`, test-only); the golden flow now passes on-device 8/8.

### Acceptance criteria
- [x] AC-1: Search opens as an animated slide-in bar; title fades.
- [x] AC-2: Bar = leading icon + field + inline clear; `surfaceContainer` background.
- [x] AC-3: Focus requested after the open animation (not synchronous).
- [x] AC-4: Close collapses + clears + restores title; ≥48dp targets.
- [x] AC-5: Typo-tolerant matching, in-memory, pure.
- [x] AC-6: Substring always matches; close fuzzy included; unrelated excluded.
- [x] AC-7: Blank query = full list; filter applied after search.
- [x] AC-8: Score-ranked while searching; alphabetical when blank.
- [x] AC-9: Scorer pure + unit-tested across all required cases.
- [x] AC-10: Global zero-meds card on empty database.
- [x] AC-11: Per-section "nothing found" only while searching.
- [x] AC-12: Dual per-section placeholders on a global no-match.
- [x] AC-13: Loading + error states handled.
- [x] AC-14: Completed tiles de-emphasised (opacity + neutral badge + grey chip).
- [x] AC-15: Course tiles type-before-status; continuous status-before-type.
- [x] AC-16: `dart analyze` clean; no debug artifacts; no new dependency.
- [x] AC-17: Meds-list tests updated and green; add-medication golden flow passes on-device 8/8 (after a test-only harness fix disabling the 034 debug seeder during integration boots).
