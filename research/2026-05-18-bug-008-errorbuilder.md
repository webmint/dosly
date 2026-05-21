# Research: Add `errorBuilder` to `appRouter`

**Date**: 2026-05-18
**Topic**: Bug 008 — `appRouter` has no `errorBuilder` → malformed routes silently fail in release
**Verdict**: Feasible — small, well-scoped, fits existing patterns

## Summary

This is a small, localized bug fix (1 file changed + 3 ARB files + 1 test). The fix adds an `errorBuilder` parameter to the `GoRouter` constructor in `lib/core/routing/app_router.dart`, pointing to a localized error screen with a "Go Home" action. Three new ARB keys are required (`errorScreenTitle`, `errorScreenBody`, `errorScreenGoHome`). The repository already has all the infrastructure needed — `context.l10n` extension, `flutter gen-l10n` pipeline, existing router test file, and the recently-stabilized `appRouterProvider` (spec 018). Recommended next step: skip `/specify` and use **`/fix`** — this is exactly the small-localized-bug shape that workflow was built for.

## Codebase Findings

### Existing Related Code
| Area | Files | Relevance |
|------|-------|-----------|
| Router declaration | `lib/core/routing/app_router.dart:35–82` | The single line to add (`errorBuilder:`) lives here. Post-spec 018 it is now a `@Riverpod(keepAlive: true)` provider — bug 007 already paired with this file. |
| Localization extension | `lib/l10n/l10n_extensions.dart` | `context.l10n` already exists; the error screen consumes it without any new `!`. |
| ARB sources | `lib/l10n/app_{en,de,uk}.arb` | Three new keys must be added in parallel across all three locales; `flutter gen-l10n` regenerates `app_localizations*.dart`. |
| Existing router tests | `test/core/routing/app_router_test.dart` | Pattern for pumping the router under `MaterialApp.router` with l10n delegates is already set up — a 7th test pushing `/nonexistent` slots in cleanly. |
| Audit trail | `audits/2026-04-30-audit.md` (F8), `specs/007-meds-history-screens/review.md`, `specs/018-gorouter-disposal/spec.md` §"NOT included" | This bug was deferred from specs 002, 007, 011, 012, and 018; audit 2026-04-30 escalated to Critical. |

### Patterns Available
- **Localized screen with action**: `SettingsScreen` consumes `context.l10n.settingsXxx` and renders a `Scaffold(AppBar, body)` — identical shape needed for the error screen.
- **ARB key addition**: Feature 011's recent ARB description-update pattern (MEMORY L203) documents the `flutter gen-l10n` regeneration step.
- **Router test pumping**: `_pumpRouter` helper in `test/core/routing/app_router_test.dart:125` accepts `overrides` and pins the locale to `en` — reusable as-is for the new test.

### Gaps
- No existing centralized "error screen" widget. The `errorBuilder` can either be an inline `Scaffold` in `app_router.dart` (matching the bug's Fix Notes) **or** a new `lib/core/widgets/app_error_screen.dart`. The 1-file inline form is simpler and matches the bug's suggestion.

## Constitution Constraints

| Rule | Impact on This Idea |
|------|---------------------|
| §5.2 / §5.3 — Notification actions plan deep links | Drives the criticality: this isn't hypothetical; the constitution itself plans the user-facing failure mode. |
| §3.1 — No `!` operator | Resolved by `context.l10n` (single sanctioned `!` site). No new `!` introduced. |
| §4.2 — `lib/core/` may not import `lib/features/` | "Go Home" target is `/` which routes to a feature, but `context.go('/')` is a STRING — no feature import. OK. |
| `tests/` mirrors `lib/` (CLAUDE.md) | Test goes into existing `test/core/routing/app_router_test.dart` as a new `testWidgets`. |
| Commit convention | Final commit: `fix(core/routing): add localized errorBuilder for malformed routes (bug 008)` — mirrors recent bugs 006/007. |

## Approaches

### Option A: Inline `errorBuilder` in `app_router.dart` (Recommended)
- **Description**: Add an `errorBuilder:` parameter to the existing `GoRouter(...)` call inside the `appRouter` provider; the builder returns an inline `Scaffold` consuming `context.l10n` for title/body/button label.
- **Pros**: Matches the bug report's Fix Notes verbatim; 1 source file changed; no new files; smallest possible diff; co-located with the routes it serves.
- **Cons**: Inline widget structure in a routing file is slightly atypical; if a second error screen variant ever appears it would need extraction.
- **Complexity**: Low — single `errorBuilder:` block in one file.

### Option B: Extract `AppErrorScreen` widget to `lib/core/widgets/app_error_screen.dart`
- **Description**: Same UI, but the widget is a top-level `class AppErrorScreen extends StatelessWidget` in `lib/core/widgets/`; `errorBuilder:` becomes `(context, state) => const AppErrorScreen()`.
- **Pros**: Separates routing config from widget layout; easier to widget-test in isolation; matches the `AppBottomNav` precedent in `lib/core/widgets/`.
- **Cons**: One extra file for what is currently a single ~15-line widget with one consumer; speculative reuse.
- **Complexity**: Low–Medium — one extra file + import wiring.

**Recommended approach**: Option A — matches the bug's suggested fix, minimizes diff, no premature abstraction (constitution KISS rule, project guidance "Three similar lines is better than a premature abstraction"). Extract to a widget only when a second error variant appears.

## Complexity Assessment

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Codebase changes | Low | 1 source file edited; 3 ARB files edited; ~1 generated l10n file regenerated; 1 new test added. ~50 lines total diff. |
| New dependencies | None | All required APIs (`GoRouter.errorBuilder`, `context.go`, `context.l10n`) already in use. |
| Risk | Low | Pure additive change. Existing route resolution is unchanged; `errorBuilder` only fires on un-matched paths. The new router test (push `/nonexistent`) directly verifies the fix. Pairs with bug 007 (just merged commit `bd2a1fe`) without conflict — the file is fresh. |

## Recommendation

**Proceed via `/fix`, not `/specify`**:

```
/fix "Bug 008: add localized errorBuilder to appRouter (lib/core/routing/app_router.dart). Add 3 ARB keys (errorScreenTitle, errorScreenBody, errorScreenGoHome) to app_{en,de,uk}.arb. Regenerate l10n. Add a router test pushing /nonexistent that asserts the error screen renders and the 'Go Home' button returns to /."
```

**Why `/fix` and not `/specify`**:
- Touches 1 source file + 3 ARB files + 1 test file = 5 files, the upper bound `/fix` is designed for.
- Root cause is identified (Fix Notes in bug 008); no diagnosis phase needed beyond rubber-stamp confirmation.
- Bug already has a suggested fix verbatim — no design space to explore.
- Pairs naturally with the just-shipped bug 007 (commit `bd2a1fe`) — both touch `app_router.dart`.
