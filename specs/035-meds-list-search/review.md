# Review Report: 035-meds-list-search

**Date**: 2026-06-19 (re-run after gap-closing test additions)
**Spec**: specs/035-meds-list-search/spec.md
**Changed files**: 9 (5 production, 4 test)

Production: `lib/core/utils/fuzzy_name_match.dart`, `lib/features/meds/presentation/view_models/meds_list_view_model.dart`, `lib/features/meds/presentation/widgets/medication_tile.dart`, `lib/features/meds/presentation/widgets/medication_section.dart`, `lib/features/meds/presentation/screens/meds_screen.dart`.
Tests: `test/core/utils/fuzzy_name_match_test.dart`, `test/features/meds/presentation/view_models/meds_list_view_model_test.dart`, `test/features/meds/presentation/widgets/medication_tile_test.dart`, `test/features/meds/presentation/widgets/medication_section_test.dart` (+ modified `meds_screen_test.dart`).

All 7 tasks Complete. Meds suite **235** (was 230; +5 gap-closing assertions). `dart analyze` clean. Production code is **unchanged** since the initial review — only test assertions were added.

## Security Review

*(Carried forward — production code byte-identical since the 2026-06-19 initial review.)*

- Critical: 0 | High: 0 | Medium: 0 | Info: 6 — **PASS**

- **Info** — PHI logging clean (§4.2.1): no `print`/`debugPrint`/logger in any changed file; the user-typed query (PHI-adjacent) and med names never reach a log sink.
- **Info** — Search state ephemeral (§4.2.1): `_query`/`_filter`/`_searchOpen` are plain `State` fields, cleared on close, disposed with the controller; no `SharedPreferences`/drift write added; `buildMedsListView` is pure.
- **Info** — No secrets in code or tests; fixtures use synthetic med names only.
- **Info (Low, CWE-1333)** — `meds_screen.dart` search `TextField` has no `maxLength`/debounce; per-keystroke fuzzy pass is O(query·Σname) on the UI thread. Trivial for a personal list; optional hardening.
  Recommendation: optionally add `maxLength: ~64` and/or a short debounce if the list could ever grow large. Non-blocking.
- **Info** — No swallowed errors introduced; `levenshtein` early returns are correct base cases.
- **Info (pre-existing, out of scope)** — error branch renders raw `e.toString()` (CWE-209); introduced by feature 034 (`10dffb6`), NOT touched by 035.
  Recommendation: track under a separate fix/spec.

## Performance Review

*(Carried forward — production code unchanged.)* Fine for the realistic scale (personal med list, tens of items).

- High: 0 | Medium: 1 | Low: 3

- **Medium** — `meds_list_view_model.dart`: activity + `CourseProgress` derivation re-runs for every item on every keystroke (screen re-reads `clock.now()` and recomputes in `build`). Microseconds at tens of items; measurable only at hundreds.
  Recommendation: cache `List<MedListItem>` keyed on (`meds` ref, current day) and apply search/filter as a lighter transform, or move derivation into a provider. Defer unless the list scales.
- **Low** — `_byNameCaseInsensitive` calls `.toLowerCase()` per comparison. Precompute a lowercased sort key. Negligible now.
- **Low** — body is `ListView` + two `Column` sections (eager, not `.builder`). Fine for a personal list; revisit with `SliverList` only if counts grow.
- **Low** — `levenshtein` re-materializes the query rune array per call. Pass pre-materialized runes if it ever matters. Negligible now.
- **Confirmed clean** — Task-006 animation disposal stuck: all 5 animation objects created in `initState`/disposed in `dispose`; no per-frame construction; no leak; `_openSearch` guards double-trigger.

## Test Assessment

- AC items with test coverage: **17 of 17** — **15 ADEQUATE, 2 PARTIAL**. Meds suite 235 tests, all pass.
- Verdict: **ADEQUATE**

**Gap-closing additions verified (all now ADEQUATE):**
- **AC-3** — focus deferral: `should NOT grant focus at mid-animation … but SHOULD after settle` (single zero-duration `pump()` catches pre-`.then()` state → `hasFocus` false; `pumpAndSettle` → true).
- **AC-2** — `surfaceContainer` bg: asserts a `Material` descendant of `AppBar` with `color == colorScheme.surfaceContainer`.
- **AC-4** — ≥48dp: `tester.getSize()` on the clear `IconButton` ≥ 48×48.
- **AC-13** — error colour: asserts the error `Text` `style.color == colorScheme.error` (was: any non-null colour).
- **AC-14** — completed status chip: asserts the "Completed" pill `Container` `BoxDecoration.color == surfaceContainerHighest`, disambiguated from the 48×48 icon badge.

**Remaining 2 PARTIAL (acceptable, not regressions):**
- **AC-1 (low)** — the `SlideTransition` mid-animation *position* is not sampled; the title `FadeTransition` (same controller) IS asserted at 0.0/1.0, so the animation is verified indirectly. Cosmetic.
- **AC-17 (resolved post-review)** — the on-device golden flow was initially unrunnable (emulator out of disk). After freeing space, the run exposed a latent **feature-034** regression: the debug seeder (`devSeedProvider`, fired from `AppBootstrap`) pre-populated the temp DB in `kDebugMode`, breaking the golden flow's exact-row-count assertions. Fixed test-only by overriding `devSeedProvider` to a no-op in `integration_test/support/app_harness.dart`. The golden flow now passes on-device **8/8**.

ADEQUATE: AC-2…AC-16 (incl. AC-9 all six scorer categories with transposition; AC-8 score-over-alphabetical proven; AC-11 queryActive gate all branches; AC-12 `findsNWidgets(2)`; AC-14 opacity+badge+chip; AC-15 chip order both types).

## Overall

No Critical/High/blocking findings. Security PASS. Performance fine for realistic scale (one Medium to revisit only if the list grows large). Tests now ADEQUATE — 5 of the 7 previously-PARTIAL ACs are closed; the 2 residuals are AC-1 (cosmetic) and AC-17 (infrastructure-blocked, functionally proxied). Nothing here blocks `/verify`.
