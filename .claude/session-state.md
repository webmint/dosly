<!-- This file is a fixed-size sliding window. Always fully overwritten, never appended. Max ~40 lines. -->
# Session State
Last updated after Task 005: Update architecture docs and close Bug 013

## Current Feature
021-async-startup-splash

## Session Stats
Tasks completed this session: 5
Estimated context load: heavy (6+)

## Progress
- Last completed: Task 005 — Docs + bug closure
- Next pending: none — ALL 5 tasks Complete
- Tasks remaining in feature: 0

## Key Decisions This Session (last 3 only)
- Nested ProviderScope (in AppBootstrap data branch) overrides the synchronous sharedPreferencesProvider — preserves the settings tree's sync-read contract unchanged; the override moved out of main()
- Test SharedPreferencesWithCache without mocking the static create: drive the FutureProvider seam (sharedPreferencesInitProvider.overrideWith) + InMemorySharedPreferencesAsync for a real instance
- Retry = ref.invalidate(sharedPreferencesInitProvider); function-form @riverpod Future provider needs no name:

Older decisions are persisted in .claude/memory/MEMORY.md.

## Files Modified Recently (last 3 tasks only)
- lib/core/widgets/splash_screen.dart + prefs_load_error_screen.dart: new startup widgets (Task 003)
- lib/app_bootstrap.dart (new), lib/main.dart (sync rewrite), test/app_bootstrap_test.dart (Task 004)
- docs/architecture.md (Bootstrap section), bugs/013 closed (Task 005)

## Active Constraints
- Feature complete. Next: /review → /verify → /summarize → /finalize
- Pre-existing uncommitted bugs/012 doc-closure change got bundled into a feature-021 WIP commit — flag at /finalize
