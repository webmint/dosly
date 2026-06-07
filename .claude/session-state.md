<!-- This file is a fixed-size sliding window. Always fully overwritten, never appended. Max ~40 lines. -->
# Session State

## Current Feature
None active. Last shipped: 025-typed-logger. Most recent work: bug 019 /fix (themeMode AC-2 guarded-exception test).

## Progress
Bug 019 fixed on branch `fix/019-thememode-asymmetry-test` — 1 clean commit (0672bb0), local-only, not yet pushed/merged. Bug 018 merged to main (PR #30). Feature-022 follow-ups: 018 ✅, 019 ✅, 020 open, 021 open (spun off from 019).

## Recently Completed (last 3)
- Bug 019 /fix: added a test in the AC-2 group naming `themeMode` as the guarded exception (wrong-type → Right(light), not Left) — test-only, 286/286 green, review APPROVE
- Bug 018 /fix: realigned settings screen test fake to `Failure.unknown` — merged via PR #30
- Feature 025 Task 7: docs/architecture.md logging subsection

## Recent Decisions
- Bug 019: co-locate a named exception test in the group named for the majority rule (test discoverability is a regression contract); use a wrong-type value distinct from the existing probe (`double 2.5` vs `int 1`)
- Bug 019: no production change — `getThemeMode()` dartdoc already documents the fallback
- Filed bug 021 (low/corroborative): a `useSystemTheme`-as-int wrong-type probe

## Recently Modified Files
- test/features/settings/data/repositories/settings_repository_impl_test.dart
- bugs/019-...md (→ Fixed), research/2026-06-07-bug-019-thememode-asymmetry.md

## Verification
dart analyze: clean | flutter test: 286 pass
