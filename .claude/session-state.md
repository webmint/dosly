<!-- This file is a fixed-size sliding window. Always fully overwritten, never appended. Max ~40 lines. -->
# Session State

## Current Feature
033-integration-tests — on-device `integration_test` harness + add-medication golden flow (8 form variations) + real-path DB-open smoke test. Branch `spec/033-integration-tests`.

## Progress
ALL 8 tasks COMPLETE. Ready for `/review` → `/verify` → `/summarize` → `/finalize`.

| # | Task | Agent | Status |
|---|------|-------|--------|
| 001 | Add integration_test dev dep | qa-engineer | Complete |
| 002 | Add test ValueKeys (FAB, picker, chips, Save) | mobile-engineer | Complete |
| 003 | Boot harness (bootAppWithTempDb) | qa-engineer | Complete |
| 004 | 8-variation fixtures + expectPersisted | qa-engineer | Complete |
| 005 | Add-medication UI driver + keyboard picker | qa-engineer | Complete |
| 006 | Golden-flow test (8 variations) | qa-engineer | Complete |
| 007 | Real-file dosly_inttest smoke test | qa-engineer | Complete |
| 008 | Docs (testing guide + architecture) | tech-writer | Complete |

## Recent Decisions
- Hermetic temp-file drift DB per golden case (Option C); real-file `dosly_inttest` for the smoke test (real path_provider path, zero risk to real data).
- Boot-per-variation (fresh ProviderScope+DB) for isolation; keyboard-mode pickers; override only the 2 leaf seams (L127).
- Extracted `bootAppWithDb` from harness during T007 (DRY); added `medsAddSaveButton` key + `path_provider` dev dep.

## Verification
On-device `flutter test integration_test -d emulator-5554`: **9/9 pass** (golden 8 + smoke 1). Host suite: **393/393 pass**. `dart analyze`: clean. Code review (consolidated support layer) caught + fixed a Critical (`startDate` `==` vs drift local-flag → `isAtSameMomentAs`).

## Notes
WIP commits accumulate (squash at /finalize). Gotcha logged in MEMORY: on-device integration runs install/uninstall under the prod applicationId and a low-disk uninstall wiped the real `dosly.sqlite` (user's earlier `www`/`foo` meds). Deferred: mark-intake/adherence golden flows, CI, iOS.
