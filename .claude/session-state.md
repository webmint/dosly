<!-- This file is a fixed-size sliding window. Always fully overwritten, never appended. Max ~40 lines. -->
# Session State

## Current Feature
034-meds-list — reactive medications list screen (read slice + tiles + sections + filter/search + debug seeder). Branch `spec/034-meds-list`.

## Progress
ALL 13 tasks COMPLETE. Ready for `/review` → `/verify` → `/summarize` → `/finalize`.

| # | Task | Agent | Status |
|---|------|-------|--------|
| 001 | Domain derivation (activity + course progress) | architect | Complete |
| 002 | Derivation tests (caught + fixed DST off-by-one) | qa | Complete |
| 003 | Reactive read (watched join + repo watchAll) | architect | Complete |
| 004 | Reactive read data tests | qa | Complete |
| 005 | medicationsList stream provider | architect | Complete |
| 006 | l10n keys (en/de/uk) | mobile | Complete |
| 007 | Shared form-icon map + add-modal refactor | mobile | Complete |
| 008 | Display formatters | mobile | Complete |
| 009 | View-model (filter/search/group/derive) | architect | Complete |
| 010 | Tile + section widgets | mobile | Complete |
| 011 | Rebuild MedsScreen | mobile | Complete |
| 012 | Screen widget tests | qa | Complete |
| 013 | Debug seeder + bootstrap | architect | Complete |

## Recent Decisions
- Reactive `Stream<Either>` read folded to AsyncValue (mirrors settingsErrors); single watched left-outer join, no rxdart.
- Active/Completed derived (no schema change); DST-safe day count via `DateTime.utc` anchoring; cyclic-paused vs active math verified.
- Seeder: kDebugMode + empty-table guarded, insert-only via repo.add, fire-and-forget in app_bootstrap.

## Verification
Full `flutter test`: **481/481 pass**. `dart analyze`: clean. Code review at checkpoints 010/011/013 (010 + 013 had fixes applied; 011 APPROVE).

## Notes
3 self-repairs during run: DST day-count (002), watchAll test-double + router-test DB-override fallout (007/012), seeder ref.read + B12 paused-date (013). All logged to MEMORY. WIP commits accumulate — squash at /finalize.
