<!-- This file is a fixed-size sliding window. Always fully overwritten, never appended. Max ~40 lines. -->
# Session State

## Current Feature
007-meds-history-screens — **All 5 tasks complete**. Ready for `/review` → `/verify` → `/summarize` → `/finalize`.

## Recently Completed Tasks
- **Task 005** (mobile-engineer, CHECKPOINT, terminal gate): Refactored `app_router.dart` to `StatefulShellRoute.indexedStack` (3 branches `/`,`/meds`,`/history`) + sibling `/theme-preview`. Added `app_router_test.dart` (5 integration tests). Full gate: `dart analyze` clean, 105/105 tests, APK build success. Code review: APPROVE.
- **Task 004** (mobile-engineer, CHECKPOINT): `AppShell` adapter — direct `goBranch` tearoff compiled cleanly. APPROVE.
- **Task 003** (mobile-engineer): HistoryScreen + test. APPROVE.
- **Task 002** (mobile-engineer): MedsScreen + test. APPROVE.
- **Task 001** (mobile-engineer): HomeBottomNav signature refactor + cascade. APPROVE.

## Recent Decisions
- Test-only router instances are the right pattern for verifying StatefulShellRoute branch-stack preservation without polluting production routes. Build via local function, dispose at test end.
- `GoRouter.of(tester.element(find.byType(HomeBottomNav)))` is the clean way to get router context in integration tests — avoids `!`.

## Recently Modified Files
- lib/core/routing/app_router.dart — StatefulShellRoute refactor
- test/core/routing/app_router_test.dart (new) — 5 integration tests
- lib/core/routing/app_shell.dart (new) — shell adapter
- lib/features/meds/, lib/features/history/ — new screens + tests
- lib/features/home/ — HomeBottomNav + HomeScreen modifications

## Verification State
- dart analyze: clean
- flutter test: 105/105 pass
- flutter build apk --debug: success

## Context Load
light
