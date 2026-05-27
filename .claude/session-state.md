<!-- This file is a fixed-size sliding window. Always fully overwritten, never appended. Max ~40 lines. -->
# Session State
Last updated after Task 001: relocate bottom nav

## Current Feature
023-bottom-nav-relocate

## Session Stats
Tasks completed this session: 1
Estimated context load: moderate (4)

## Progress
- Last completed: Task 001 — relocate AppBottomNav core/widgets → core/routing (Bug 015)
- Next pending: none — the feature's only task is Complete
- Tasks remaining in feature: 0

## Key Decisions This Session (last 3 only)
- Option C chosen (relocate to core/routing beside app_shell, the composition root) over Option A (new lib/app/ layer) and Option B (parameterize destinations)
- l10n import left unchanged (../../l10n/l10n_extensions.dart) — core/routing same depth as core/widgets; app_router.dart:21 precedent
- core/widgets/ NOT deleted — still holds feature-agnostic splash_screen + prefs_load_error_screen; AC-8 satisfied (no feature-aware widget remains)

## Files Modified Recently (last 3 tasks only)
- lib/core/routing/app_bottom_nav.dart (moved from core/widgets, verbatim via git mv)
- lib/core/routing/app_shell.dart (import → same-dir)
- test/core/routing/{app_bottom_nav_test,app_bottom_nav_l10n_test}.dart (moved from test/core/widgets) + app_router_test.dart (import)

## Active Constraints
- Feature complete. Next: /review → /verify → /summarize → /finalize
- Verification already green: dart analyze clean; flutter test 241 passed; code review APPROVE
- WIP commits accumulate on branch spec/023-bottom-nav-relocate; /finalize squashes into one refactor() commit
