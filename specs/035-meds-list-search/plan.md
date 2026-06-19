# Plan: Meds-List Search & Empty-State Fidelity

**Date**: 2026-06-18
**Spec**: [spec.md](spec.md)
**Status**: Approved

## Summary

Add a dependency-free, pure-Dart Levenshtein scorer in `core/utils`, swap the view-model's substring filter for it (with a substring guarantee and score-ranked ordering while searching), rebuild the meds-list search affordance as an animated slide-in app-bar overlay, gate the per-section "nothing found" placeholder on an active query, and give completed-course tiles the design's de-emphasised treatment. All changes are confined to **presentation + a generic core util + tests** — the reactive read path, repository, data source, drift schema, and l10n keys are untouched.

## Technical Context

**Architecture**: Clean Architecture. Touches **presentation** (`screens/`, `widgets/`, `view_models/`) and **core/utils** only. No `domain/` or `data/` change — the live list already arrives via `medicationsListProvider` (`Stream<Either>` → `AsyncValue`).
**Error Handling**: Unchanged — the boundary `Either`→`AsyncValue` fold stays in the provider; this slice only shapes/renders the already-loaded `List<Medication>`.
**State Management**: Ephemeral widget `State` in `MedsScreen` keeps `_query`/`_searchOpen`/`_filter` (no new Riverpod providers); the search animation is driven by an `AnimationController`/transition local to the screen.

## Constitution Compliance

- **§2.1 layer boundaries** — fuzzy logic is a pure helper in `core/utils` consumed by the presentation view-model; no Flutter/drift in the scorer; no `data/` import added. ✅
- **§2.1 domain purity** — scorer is pure Dart, no `DateTime.now()`, no Flutter. ✅
- **§2.3 dependencies** — **no new package** (pure-Dart Levenshtein) → sidesteps the allowlist/abandonment risk entirely. ✅
- **§3.2 Either at boundaries** — untouched; read path stays `Stream<Either>`→`AsyncValue`. ✅
- **§3.4 testing** — scorer + view-model get mandatory unit tests; screen states get widget tests; spec-033 golden flow must stay green. ✅
- **§3.6/§3.7 KISS / search-before-build** — own a tiny generic util instead of pulling a library for a 40-line algorithm; placed in `core/utils` for reuse. ✅
- **§4.2.1 no print/debugPrint; §6.5 no schema change** — neither introduced. ✅
- **§4.3.1 M3 / ≥48dp** — search bar + clear use M3 tokens (`surfaceContainer`) and ≥48dp targets; standard Flutter transitions. ✅

## Implementation Approach

### Layer Map

| Layer | What | Files (existing or new) |
|-------|------|------------------------|
| Core / utils | Pure `fuzzyNameScore(query, name) → double` (0..1) + a small `levenshtein` helper; substring/prefix bonus so substring always outranks fuzzy-only | `lib/core/utils/fuzzy_name_match.dart` **(new)** |
| Presentation / view-model | Replace `.contains()` with the scorer; include if substring **or** score ≥ threshold; rank by descending score while query active (ties → name asc), else name asc; keep `totalCount` pre-filter | `lib/features/meds/presentation/view_models/meds_list_view_model.dart` **(modify)** |
| Presentation / screen | Animated slide-in search bar (icon + field + inline ×, `surfaceContainer`, title fade, focus-after-animation); compute `queryActive` and pass to sections; keep global zero-meds card; keep two filter chips | `lib/features/meds/presentation/screens/meds_screen.dart` **(modify)** |
| Presentation / widget | Gate per-section placeholder on `queryActive && items.isEmpty`; always render header | `lib/features/meds/presentation/widgets/medication_section.dart` **(modify)** |
| Presentation / widget | Completed-state de-emphasis (0.65 opacity + neutral `surfaceVariant` badge + grey `surfaceVariant` status chip); course chip order = type-then-status | `lib/features/meds/presentation/widgets/medication_tile.dart` **(modify)** |
| Tests | Scorer unit tests; view-model fuzzy/ranking tests; updated screen widget tests (search states, empty gating, completed tile, chip order) | `test/core/utils/fuzzy_name_match_test.dart` **(new)**, `test/features/meds/presentation/...` **(modify/extend)** |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| Fuzzy engine | Pure-Dart normalized Levenshtein + substring/prefix bonus | Zero deps, privacy/KISS, full threshold control, trivially testable | `fuzzywuzzy` (dep + staleness risk), `string_similarity` (Dice, not Levenshtein), `fuzzy` (subsequence) |
| Matcher location (OQ-4) | `lib/core/utils/fuzzy_name_match.dart` | Generic + reusable (future history/today search); fits §2.2 core/utils scope | Feature-local in `meds/presentation/` (not reusable) |
| Match score handling | Transient `(double score, MedListItem item)` records during shaping; sort, then emit `MedListItem`s | Score is presentation-transient and meaningless without a query | Adding a nullable `matchScore` field to `MedListItem` (pollutes the model) |
| Inclusion rule (AC-6) | Include if name **contains** query (case-insensitive) **OR** `fuzzyNameScore ≥ threshold` | Guarantees no regression vs substring; adds typo tolerance on top | Pure-threshold only (would drop short-query/prefix matches) |
| Ordering scope (OQ-3) | Rank by score **within each section**; sections preserved | Matches spec assumption; grouping stays intact | Global cross-section ranking (would fight the section grouping) |
| Threshold / normalization (OQ-2) | `score = max(substringScore, 1 − dist/maxLen)`; substring/prefix scored above fuzzy-only; inclusion threshold ≈ 0.6, tuned against the debug seed set with tests | Concrete, tunable, test-anchored | Hard-coded magic numbers with no test anchor |
| `queryActive` flag | Screen computes `_query.trim().isNotEmpty`, passes a bool to each `MedicationSection` | Screen already owns `_query`; no provider/view-model coupling | Threading it through `MedsListView` (unnecessary) |
| Search affordance | Animated overlay inside the screen's own `AppBar` (`flexibleSpace` `Stack` + `SlideTransition`/`AnimatedSwitcher`); focus requested on animation-complete | Matches template slide-in; stays inside the screen AppBar so the `StatefulShellRoute`/bottom-nav is untouched | Full title-swap (current; un-animated), separate route/overlay (overkill) |
| Completed-tile styling | Gate every override on `item.activity == MedicationActivityStatus.completed` in `MedicationTile` | Active tiles provably unchanged; derived state already on the item | Styling by type only (current; can't distinguish completed) |

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `lib/core/utils/fuzzy_name_match.dart` | Create | Pure `levenshtein(a,b)` + `fuzzyNameScore(query, name)` returning 0..1 (substring/prefix bonus + normalized edit distance); operates on characters; dartdoc'd |
| `lib/features/meds/presentation/view_models/meds_list_view_model.dart` | Modify | Swap substring filter → scorer (include on substring OR score≥threshold); compute transient scores; conditional sort (score desc / name asc); `totalCount` unchanged |
| `lib/features/meds/presentation/screens/meds_screen.dart` | Modify | Replace title-swap with animated slide-in search bar (icon+field+inline ×, `surfaceContainer`, title `AnimatedOpacity`, deferred focus); derive + pass `queryActive`; retain global `_EmptyState`; ≥48dp targets |
| `lib/features/meds/presentation/widgets/medication_section.dart` | Modify | Add `queryActive` param; render placeholder only when `queryActive && items.isEmpty`; header always renders |
| `lib/features/meds/presentation/widgets/medication_tile.dart` | Modify | Completed-state overrides (opacity, neutral badge, grey status chip); reorder chips to type-then-status for courses |
| `test/core/utils/fuzzy_name_match_test.dart` | Create | Unit tests: exact, substring, prefix, 1-char typo, transposition, below-threshold non-match, Cyrillic case-fold |
| `test/features/meds/presentation/view_models/meds_list_view_model_test.dart` | Modify | Fuzzy inclusion + score-ranked ordering + alphabetical-when-no-query + filter-after-search |
| `test/features/meds/presentation/screens/meds_screen_test.dart` (+ tile/section tests) | Modify | Search open/close + animation/focus, empty-gating, no-match dual placeholders, completed-tile styling, chip order |

> **Discovered during planning** (not separately enumerated in the spec's Affected Areas, which folded them into "Tests" and "Fuzzy matcher"): the new `lib/core/utils/fuzzy_name_match.dart` and its `test/core/utils/...` mirror. l10n `.arb` files and `pubspec.yaml` are confirmed **unchanged** (existing keys reused; no package added).

### Documentation Impact

| Doc File | Action | What Changes |
|----------|--------|-------------|
| (none) | — | `docs/` does not exist in this project; no documentation changes. Behaviour is captured by the spec + tests. |

No documentation changes expected — presentation + util implementation only.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Fuzzy threshold too loose/tight | Med | Med | Tune against the debug seed set; unit-test boundary cases (AC-9); substring always included (AC-6) |
| Animated search-bar rebuild breaks existing meds-list widget tests (asserted the title-swap) | High | Low | Expected — update those tests this slice (AC-17); keep stable widget keys for finders |
| Score-ranked order conflicts with alphabetical assumptions in existing tests | Med | Low | Sort conditioned on `queryActive`; assert both orderings explicitly |
| Focus race (keyboard before bar settles) / animation jank | Med | Low | Request focus on animation-status `completed`; standard `SlideTransition`; `pumpAndSettle` in tests |
| Completed-tile restyle bleeds into active tiles | Low | Med | Gate every override on `activity == completed`; widget-test active vs completed side-by-side |
| Cyrillic case-fold / character counting in Levenshtein | Low | Low | `toLowerCase()` (Unicode-aware) + iterate characters; Cyrillic/Latin med names are BMP single-unit; covered by a Cyrillic test |
| Search overlay interferes with routing shell / bottom-nav | Low | Med | Keep search inside the screen's own `AppBar`/`flexibleSpace`; verify on-device against `StatefulShellRoute` |

## Dependencies

**None.** No new packages (pure-Dart Levenshtein), no schema change, no l10n keys, no config/env. `flutter gen-l10n` not required (no `.arb` change).

## Supporting Documents

- [Research](research.md) — fuzzy engine + placement decision (pure-Dart Levenshtein chosen)
- Data Model — not applicable (no entities/schema change; `MedListItem` unchanged)
- Contracts — not applicable (no API/DB contract change)

---

## Plan ↔ Spec AC Cross-Reference

| AC | Covered by |
|----|-----------|
| AC-1 (slide-in + title fade) | `meds_screen.dart` animated overlay (`SlideTransition`/`AnimatedSwitcher` + `AnimatedOpacity` title) |
| AC-2 (icon+field+inline ×, `surfaceContainer`) | `meds_screen.dart` search-bar layout/tokens |
| AC-3 (focus after animation) | `meds_screen.dart` focus on animation-status complete |
| AC-4 (close collapses+clears, ≥48dp) | `meds_screen.dart` close handler + tap-target constraints |
| AC-5 (typo-tolerant, in-memory, pure) | `fuzzy_name_match.dart` + `meds_list_view_model.dart` |
| AC-6 (substring always + close fuzzy, exclude unrelated) | `fuzzyNameScore` substring bonus + threshold; view-model inclusion rule |
| AC-7 (blank query = full list; filter after search) | `meds_list_view_model.dart` pipeline (search→filter) |
| AC-8 (score desc while query, name asc otherwise) | `meds_list_view_model.dart` conditional sort |
| AC-9 (pure, unit-tested cases) | `fuzzy_name_match.dart` + `test/core/utils/fuzzy_name_match_test.dart` |
| AC-10 (global zero-meds card) | `meds_screen.dart` retained `_EmptyState` on `totalCount==0` |
| AC-11 (per-section placeholder only while searching) | `medication_section.dart` `queryActive` gate |
| AC-12 (dual placeholders on global no-match) | `meds_screen.dart` renders both sections + `medication_section.dart` gate |
| AC-13 (loading/error unchanged) | `meds_screen.dart` `AsyncValue.when` untouched |
| AC-14 (completed de-emphasis: opacity+badge+chip) | `medication_tile.dart` completed-state overrides |
| AC-15 (course chip order type-then-status) | `medication_tile.dart` `_TileBody` order |
| AC-16 (analyze clean, no artifacts, no/vetted dep) | No new dep; analyze gate per task |
| AC-17 (golden flow green; meds-list tests updated) | Test files modified/extended; spec-033 integration flow re-run |

All 17 ACs have a clear implementation path. No orphan ACs; no plan files outside the spec's intent (the new `core/utils` scorer + its test are the planning-time refinement of the spec's "Fuzzy matcher (likely new)" row).
