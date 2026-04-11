# Tasks: Main Screen — Hello World + go_router Foundation

**Spec**: [../spec.md](../spec.md) (Complete)
**Plan**: [../plan.md](../plan.md) (Approved)
**Research**: [../research.md](../research.md)
**Review**: [../review.md](../review.md)
**Verify**: [../verify.md](../verify.md) — APPROVED
**Generated**: 2026-04-11
**Completed**: 2026-04-11
**Total tasks**: 5 (all Complete)

## Completion Summary

All 5 tasks completed successfully. 17 of 17 automated ACs PASS; AC-18 is manual-deferred per spec §8.

**Verification gates (final sweep, /verify phase)**:
- `dart analyze` — No issues found (project-wide)
- `flutter test` — 79/79 passing
- `flutter build apk --debug` — `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

**Reviews**:
- Security: PASS (0 Critical/High/Medium, 7 Info)
- Performance: APPROVED (0 regressions)
- Test coverage: ADEQUATE

**Verdict**: APPROVED — ready for `/summarize` → `/finalize`.

## Dependency Graph

```
001 (add go_router) ──→ 002 (create HomeScreen) ──→ 003 (create appRouter) ──→ 004 (wire DoslyApp) ──→ 005 (rewrite widget tests)
```

Linear chain — no parallelism. Each task is a strict prerequisite for the next. Tasks 003 and 004 transitively depend on task 001 via task 002, but the chain expresses only the nearest dependency for readability.

## Task Index

| # | Title | Agent | Files | Depends on | Status |
|---|-------|-------|-------|-----------|--------|
| 001 | Add go_router dependency | mobile-engineer | `pubspec.yaml`, `pubspec.lock` | None | Complete |
| 002 | Create HomeScreen widget | mobile-engineer | `lib/features/home/presentation/screens/home_screen.dart` (new) | 001 | Complete |
| 003 | Create app_router.dart with flat two-route GoRouter | mobile-engineer | `lib/core/routing/app_router.dart` (new) | 002 | Complete |
| 004 | Swap MaterialApp for MaterialApp.router in DoslyApp | mobile-engineer | `lib/app.dart` | 003 | Complete |
| 005 | Rewrite widget tests for HomeScreen + navigation flow | qa-engineer | `test/widget_test.dart` | 004 | Complete |

## Additions to Spec

None. The breakdown's File Impact matches spec §4 Affected Areas exactly — no new files or scope expansions discovered during breakdown.

## Risk Assessment

| Task | Risk | Reason |
|------|------|--------|
| 001 | Low-Med | `flutter pub add go_router` may fail on Flutter SDK mismatch if the installed SDK is older than the current `go_router` stable requires. Task notes include fallback instructions (upgrade Flutter or pin to an older go_router). |
| 002 | Low | Self-contained widget creation following the plan's exact shape. Only design-adjacent decisions (button style, gap size) were pre-locked in the spec's Open Questions. |
| 003 | Low | Self-contained router creation following the plan's exact shape. All `go_router` features except the flat two-route table are explicitly forbidden in the contract. |
| 004 | Med | Integration point where the new routing replaces the old `home:` wiring. The existing `widget_test.dart` tests will start failing after this task because they assert on the old preview-screen-as-home behavior — this is expected and task 005 fixes them. `dart analyze` clean is the gate for task 004; `flutter test` green is the gate for task 005. Risk of accidentally changing `ListenableBuilder` wrapping (would break theme reactivity) or dropping one of the theme props. |
| 005 | Med | Widget test rewrite is sensitive to widget-finder predicate correctness (`find.widgetWithText(OutlinedButton, 'Theme preview')` must match the exact button widget). Also the first point at which `flutter test` and `flutter build apk --debug` must both pass end-to-end. Self-repair in `/execute-task` Phase 3 may need to diagnose cross-task issues if gates fail here. |

No High-risk tasks.

## Review Checkpoints

| Before Task | Reason | What to Review |
|-------------|--------|----------------|
| 005 | End-to-end integration gate | Before running task 005, confirm tasks 001-004 produced the expected file state: `dart analyze` is clean across all four files, `lib/app.dart` uses `MaterialApp.router(routerConfig: appRouter, ...)`, `HomeScreen` renders correctly (no need to run the app — read the file), `appRouter` has exactly two routes with the expected builders. After task 005, verify `flutter test` and `flutter build apk --debug` both exit 0. |

No automatic checkpoints per the /breakdown rules (no convergence points because the chain is linear; no layer boundary crossings because there are no domain/data-layer tasks; no High-risk tasks). The task 005 checkpoint is manually placed because it's the integration verification point where the whole chain becomes live.

Users may add review checkpoints before any task during approval.

## Contract Chain Integrity

Verified during Phase 3.5. All "Expects" items trace to either pre-existing codebase state or an upstream task's "Produces". All "Produces" items are consumed by a downstream task's "Expects" or map directly to a spec AC.

**No orphaned contracts. No unsatisfied Expects.**

Chain walk:
- Task 001 Produces → Task 002 Expects (`package:go_router/go_router.dart` importable)
- Task 001 Produces → Task 003 Expects (same)
- Task 002 Produces → Task 003 Expects (`class HomeScreen` exists)
- Task 002 Produces → Task 005 Expects (HomeScreen renders Hello World + button)
- Task 003 Produces → Task 004 Expects (`final GoRouter appRouter` declared)
- Task 003 Produces → Task 005 Expects (`/` and `/theme-preview` routes registered)
- Task 004 Produces → Task 005 Expects (`MaterialApp.router(routerConfig: appRouter)`)
- Task 005 Produces → spec ACs 11, 12, 14, 15

Pre-existing codebase state consumed:
- Task 002: `pubspec.yaml` has `dependencies:` section
- Task 003: `ThemePreviewScreen` exported by `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` (unchanged from `origin/main`)
- Task 004: `lib/app.dart` current shape (`MaterialApp` wrapped in `ListenableBuilder`)
- Task 005: `ThemePreviewScreen` AppBar title `'dosly · M3 preview'` and cycle tooltip `'Cycle theme mode'` (unchanged)
- Task 005: `themeController` exports `.value`, `.setMode()`, `.cycle()`

## Spec AC Coverage

Every AC in the spec is addressed by at least one task:

| AC | Task(s) | Notes |
|----|---------|-------|
| AC-1 (pubspec declares go_router, lock resolves, no other deps) | 001 | |
| AC-2 (app_router.dart flat two-route shape, forbidden features absent) | 003 | |
| AC-3 (TODO on /theme-preview route with spec reference) | 003 | |
| AC-4 (HomeScreen Scaffold/Center/Column/Text/SizedBox/OutlinedButton with context.push) | 002 | |
| AC-5 (HomeScreen imports only material + go_router) | 002 | |
| AC-6 (HomeScreen no AppBar/FAB/BottomNav/Drawer) | 002 | |
| AC-7 (exact strings 'Hello World' and 'Theme preview') | 002, 005 | 002 produces; 005 verifies via finders |
| AC-8 (HomeScreen dartdoc references spec) | 002 | |
| AC-9 (lib/app.dart edits) | 004 | |
| AC-10 (lib/app.dart dartdoc update) | 004 | |
| AC-11 (widget test 1: Hello World + button) | 005 | |
| AC-12 (widget test 2: navigate then cycle) | 005 | |
| AC-13 (dart analyze clean) | 002, 003, 004, 005 (per-file) + 005 (project-wide) | |
| AC-14 (flutter test passes) | 005 | |
| AC-15 (flutter build apk --debug succeeds) | 005 | |
| AC-16 (no print/debugPrint/!/dynamic) | 002, 003, 004, 005 (writer discipline; analysis_options does not enforce) | |
| AC-17 (const where possible) | 002, 004 (linter-enforced via `prefer_const_constructors`) | |
| AC-18 (manual simulator verification) | Deferred to `/verify` — not in any task's done-when | |

All 18 ACs covered.

## Execution Order

Tasks must execute strictly in order: 001 → 002 → 003 → 004 → 005. Each task's "Expects" depends on the previous task's "Produces".

`/execute-task 001` starts the chain. Each task's post-execution verification includes `dart analyze` (per-file for tasks 002-004; project-wide for task 005) and task 005 additionally gates on `flutter test` and `flutter build apk --debug`.

## Post-Breakdown Follow-ups (not in this spec)

Tracked for future specs, not actionable now:
- **Post-MVP cleanup spec**: delete `lib/features/theme_preview/` folder, remove the `/theme-preview` `GoRoute` entry from `lib/core/routing/app_router.dart`, remove the `OutlinedButton` and the `go_router` import from `lib/features/home/presentation/screens/home_screen.dart`. Three coordinated edits in one atomic spec. Discover via `grep -r 'specs/002-main-screen'` across `lib/`.
- **Strict-mode analysis_options spec**: upgrade `analysis_options.yaml` to the strict-mode config from constitution §7.4 so `dart analyze` enforces `!`/`dynamic`/`print` bans that are currently only enforced by code review.
- **Routing architecture doc**: once the route table grows past ~4 screens, add a "Routing" section to `docs/architecture.md` describing the `appRouter` pattern, allowed `GoRoute` features, and the cross-feature wiring convention.
