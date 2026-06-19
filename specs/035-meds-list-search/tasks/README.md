# Tasks: Meds-List Search & Empty-State Fidelity

**Spec**: [../spec.md](../spec.md)
**Plan**: [../plan.md](../plan.md)
**Generated**: 2026-06-18
**Total tasks**: 7

## Dependency Graph

```
001 fuzzy scorer ──→ 002 scorer tests
                 └─→ 003 view-model fuzzy+rank ──→ 004 view-model tests
                                              └──→ 006 search bar + empty gating ──→ 007 widget tests
005 tile + chip order ──────────────────────────────────────────────────────────→ 007 widget tests
```

Execution waves (parallelizable within a wave):
- **Wave 1**: 001, 005
- **Wave 2**: 002, 003
- **Wave 3**: 004, 006
- **Wave 4**: 007

## Task Index

| # | Title | Agent | Depends on | Checkpoint | Status |
|---|-------|-------|-----------|-----------|--------|
| 001 | Create pure-Dart fuzzy name scorer | architect | None | No | Complete |
| 002 | Unit-test the fuzzy name scorer | qa-engineer | 001 | No | Complete |
| 003 | Fuzzy + ranked search in the view model | architect | 001 | No | Complete |
| 004 | Test fuzzy inclusion + ranking in the view model | qa-engineer | 003 | No | Complete |
| 005 | De-emphasise completed tiles + fix course chip order | mobile-engineer | None | No | Complete |
| 006 | Animated slide-in search bar + query-gated empty placeholder | mobile-engineer | 003 | **Yes** | Complete |
| 007 | Widget tests for search, empty states, tiles + golden re-check | qa-engineer | 005, 006 | **Yes** | Complete |

## Acceptance-Criteria Coverage

| AC | Task(s) | AC | Task(s) |
|----|---------|----|---------|
| AC-1 | 006 | AC-10 | 006, 007 |
| AC-2 | 006 | AC-11 | 006, 007 |
| AC-3 | 006 | AC-12 | 006, 007 |
| AC-4 | 006 | AC-13 | 006, 007 |
| AC-5 | 001, 003 | AC-14 | 005, 007 |
| AC-6 | 001, 003, 004 | AC-15 | 005, 007 |
| AC-7 | 003, 004 | AC-16 | all (per-task `dart analyze`; no new dep in 001) |
| AC-8 | 003, 004 | AC-17 | 007 |
| AC-9 | 002 | | |

All 17 ACs are covered. AC-16 (analyze clean / no artifacts / no-or-vetted dependency) is cross-cutting — enforced by every task's "Done when" and the PostToolUse `dart analyze` hook; Task 001 explicitly adds no `pubspec.yaml` entry.

## Additions to Spec

Discovered during planning/breakdown (folded into the spec's "Tests" + "Fuzzy matcher (likely new)" rows, now made explicit):
- **New** `lib/core/utils/fuzzy_name_match.dart` (the pure scorer) + **new** `test/core/utils/fuzzy_name_match_test.dart`.
- **New** widget tests `test/features/meds/presentation/widgets/medication_tile_test.dart` and `medication_section_test.dart` (no tile/section tests existed before).
- Confirmed **unchanged**: `pubspec.yaml` (no package), all `.arb` files (existing keys reused), drift schema, repository/data source.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Low | Self-contained pure function |
| 002 | Low | Pure unit tests |
| 003 | Med | Fuzzy include-threshold tuning + score-vs-alphabetical sort switch (anchored by Task 004) |
| 004 | Low | Test-only; uses fixed Clock/dates |
| 005 | Low–Med | Must gate every override on `completed` so active tiles don't change |
| 006 | High | Animated search-bar rebuild (breaks existing title-swap tests), focus race, must not disturb the routing shell / bottom nav |
| 007 | Med | Rewriting widget tests; golden flow is device-dependent (run via integration harness) |

## Review Checkpoints

| Before Task | Reason | What to Review |
|-------------|--------|----------------|
| 006 | Layer boundary (first screen task after core/view-model) + High risk (animation) | Slide-in animation + `surfaceContainer` bg + inline clear match the template; focus deferred to post-animation; `queryActive` gating correct; global empty card + chips intact; routing shell/bottom-nav unaffected |
| 007 | Convergence (depends on 005 + 006) | Updated tests truly assert the new search/empty/tile behaviour (not the old title-swap); completed-tile + chip-order assertions correct; meds suite green; spec-033 golden flow confirmed |

## Contract Chain Integrity

- **No orphans**: every "Produces" is consumed downstream or maps to an AC.
  - 001 → 002, 003 · 003 → 004, 006 (+AC-8) · 005 → 007 (+AC-14/15) · 006 → 007 (+AC-1–4/10–13) · 002/004/007 → AC-9/6-8/10-17.
- **No unsatisfied "Expects"**: 001 and 005 expect only existing codebase state; all other Expects map to an upstream Produces.

## Completion Summary

**Verified**: 2026-06-19 — verdict **APPROVED**. All 7 tasks Complete; spec marked Complete.
- **Acceptance criteria**: 17/17 PASS (code-reading mode; AC_VERIFICATION off). AC-17: the on-device golden flow now passes **8/8** on `emulator-5554` (after freeing emulator disk and a test-only harness fix disabling the 034 debug seeder during integration boots — see Post-verify fix below).
- **Code quality**: `dart analyze` clean (whole project); `flutter test` **546/546**; debug APK builds (`app-debug.apk`).
- **Review** (`review.md`, re-run): Security PASS (0 Critical/High); Performance 1 Medium (per-keystroke derivation — non-blocking, scale-only) + 3 Low; Test coverage ADEQUATE (15/17 ADEQUATE, 2 PARTIAL: AC-1 mid-slide cosmetic, AC-17 infra-blocked).
- **No scope creep** (changes confined to `lib/core/utils` + meds presentation + tests; no schema/pubspec/l10n change); **no leftover artifacts** (no `print`/`debugPrint`, no bare TODOs).
- **Next**: `/summarize` → `/finalize`.

### Post-verify fix (2026-06-19)
Running the AC-17 on-device golden flow (once emulator disk was freed) exposed a latent **feature-034** regression: the debug seeder (`devSeedProvider`, fired from `AppBootstrap`) populated the temp DB in `kDebugMode`, breaking the golden flow's exact-row-count assertions (all 8 fixtures failed `expectPersisted`). Fixed test-only by overriding `devSeedProvider` to a no-op in `integration_test/support/app_harness.dart`. Golden flow now passes **8/8** on-device. No production code changed.
