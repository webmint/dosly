# Research: Bug 009 — Cross-feature import in `theme_preview_screen.dart`

**Date**: 2026-05-22
**Topic**: Bug 009 — `ThemePreviewScreen` imports directly from `features/settings/presentation/providers/`, violating Constitution §2.1
**Verdict**: Feasible — clear-cut. Recommend **Option A (delete the feature)** with a fallback to **Option B (local `ValueNotifier`)** if the user wants to keep the dev tool.

## Summary

The bug is genuine and well-scoped. `theme_preview_screen.dart` reaches into Settings' deepest presentation layer to drive theme cycling, plus a second cross-feature import of `AppThemeMode` that the bug report didn't even flag. The codebase already has explicit `TODO(post-mvp): remove` markers in three coordinated places — `theme_preview_screen.dart`, `app_router.dart`, and `home_screen.dart` — and `specs/002-main-screen/spec.md §6` explicitly defers the deletion to a follow-up cleanup spec. Bug 009 is that cleanup spec. Option A (delete) is preferred because the removal scope is already mapped and the alternative (Option B's local `ValueNotifier`) creates a screen that no longer exercises the real theming pipeline, which is the only reason the preview exists.

## Codebase Findings

### Existing Related Code

| Area | Files | Relevance |
|------|-------|-----------|
| The feature itself | `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart`, `widgets/color_swatch_card.dart`, `widgets/typography_sample.dart` | Three files, ~275 + ~50 + ~50 lines. All deletable as a unit. |
| Router entry | `lib/core/routing/app_router.dart:74-79` | TODO already in place: "remove this route when lib/features/theme_preview/ is deleted". Also imports `ThemePreviewScreen` at line 22. |
| Dev entry point | `lib/features/home/presentation/screens/home_screen.dart:58-64` | TODO already in place: "remove this dev entry point when lib/features/theme_preview/ is deleted". The OutlinedButton + `context.push('/theme-preview')`. |
| Test that asserts the route exists | `test/core/routing/app_router_test.dart:287-313` (Test 5 / AC-13) | Asserts `/theme-preview` renders outside the shell. Must be deleted with the feature. |
| Test that exercises navigation | `test/widget_test.dart:87-126` | Navigates Home → Preview and cycles theme. Must be deleted; theme cycling needs to move to `settings_screen` tests if not already covered. |
| Spec referencing the removal | `specs/002-main-screen/spec.md §6 line 123` | Explicitly says deletion is *"final stages of development"* — a separate post-MVP spec. |
| Memory note | `.claude/memory/MEMORY.md:221` (Feature 019) | Documents `/theme-preview` as a sibling top-level route — irrelevant after removal. |

### Patterns Available

- **Settings → app theming wiring** already lives in `lib/app.dart:67-76` via narrow `ref.watch(settingsNotifierProvider.select(...))` calls. The "real" theming pipeline is exercised at app launch; the preview screen is duplicative.
- **Local `ValueNotifier<ThemeMode>`** pattern (if Option B chosen) — used previously in `lib/app.dart` before Riverpod migration. Trivial to introduce inside the preview screen as a self-contained widget.

### Gaps

- No test isolates color-scheme/typography rendering against the real theme. The preview screen's *coverage value* is humans-only ("does the M3 palette look right?"). If the user is past the design-validation phase, that value is zero.
- Bug report missed line 14: `import '../../../settings/domain/entities/app_theme_mode.dart';` — a second cross-feature import. It's softer than the provider import (domain entity, not presentation), but Constitution §2.1 still flags it: feature A's widget must not import from feature B at all. Both options below resolve it incidentally.

## Constitution Constraints

| Rule | Impact on This Idea |
|------|--------------------|
| §2.1 "Cross-feature rules: A widget in `features/A/presentation/` may NOT import from `features/B/`" | This is the rule being violated. Both options resolve it. |
| §3 "No dead code. Delete unused functions, variables, files." | Already cited in `spec.md:31`. Reinforces Option A. |
| "Never leave bare TODOs" | The three coordinated TODOs reference `specs/002-main-screen` and would be resolved by Option A. |
| "Minimal changes — every change should impact as little code as possible" | Option A is larger in file count but more aligned with intent ("the screen was always going to be deleted"). Option B is smaller but leaves a dead screen reachable. |

## Approaches

### Option A: Execute the scheduled removal (preferred)

- **Description**: Delete `lib/features/theme_preview/` entirely (3 source files), delete the `/theme-preview` `GoRoute` in `app_router.dart:74-79`, delete the `OutlinedButton` + comment block in `home_screen.dart:58-64`, delete or rework the two tests (`test/widget_test.dart` navigation test, `test/core/routing/app_router_test.dart` Test 5 / AC-13), update `lib/app.dart` library dartdoc at line 11 ("temporary dev-only `/theme-preview` route") and the `app_router.dart` library dartdoc at lines 6-8 ("plus a sibling top-level `GoRoute` for `/theme-preview`"), and the `home_screen.dart` class dartdoc at lines 20-27.
- **Pros**:
  - Resolves Bug 009 *and* the unflagged `AppThemeMode` import (line 14) in one shot.
  - Clears three coordinated TODOs marked for exactly this moment.
  - Constitution §3 ("No dead code") respected.
  - The dev value of the preview is essentially zero post-MVP — humans use it to validate the M3 palette during theme work, which is done (`Feature 001-m3-theme` is closed).
  - Reduces test surface (two tests deletable; AC-13 in `app_router_test.dart` becomes moot).
- **Cons**:
  - Larger blast radius: ~5 source files touched + 2 tests + 3 dartdoc updates.
  - Loses the ability to spot-check M3 palette changes without launching real screens. Mitigated: the palette is static; future changes can spin up a one-off scratch screen.
  - Cleanup spec touches features owned by `home`, `core/routing`, `theme_preview`, plus root `app.dart` — straddles enough modules that it needs careful tasking. Still mechanical.
- **Complexity**: Low–Medium (mechanical but coordinated across 5+ files and 2 tests).

### Option B: Self-contained local `ValueNotifier<ThemeMode>`

- **Description**: Replace lines 14-15 imports + the three `settingsNotifierProvider` references (lines 36-41, 60) with a local `ValueListenableBuilder<ThemeMode>` over a `ValueNotifier<ThemeMode>` owned by the screen. The cycle button mutates the local notifier; the surrounding `MaterialApp` doesn't see the change. The screen becomes a pure widget-gallery with a non-functional theme-cycle button (or a button that only re-themes the preview body via a local `Theme(data: ...)` wrap).
- **Pros**:
  - Minimal diff (~10-15 lines).
  - Resolves both cross-feature imports.
  - Preserves the dev tool for future palette spot-checks.
- **Cons**:
  - The cycle button stops exercising the real theming pipeline — its only legitimate purpose. The screen becomes static documentation that pretends to be interactive.
  - The two tests that assert theme cycling via the preview (`test/widget_test.dart:87-126` second test, the cycle assertions) must be rewritten or moved. Moving them to `settings_screen` tests is the right answer regardless — meaning Option B doesn't actually save the tests, it just delays.
  - Leaves dead-ish code in the tree, against Constitution §3.
- **Complexity**: Low.

**Recommended approach**: Option A (delete) — the TODOs, the spec reference, and Constitution §3 all already point at this. The only reason to choose Option B is if the user explicitly wants to keep a dev palette viewer; given the M3 theme feature is closed and tests cover the real pipeline elsewhere, that justification is thin.

## Complexity Assessment

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Codebase changes | Medium | Option A: 3 file deletions + 3 edits + 2 test edits/deletions. Option B: 1 file edit. |
| New dependencies | None | Both options remove or rearrange existing code only. |
| Risk | Low | Mechanical removal. Main risk is test churn (AC-13 in `app_router_test.dart`); manageable. |

## Recommendation

**Proceed with Option A as the working assumption.** Run:

```
/specify "Delete the theme_preview feature and all dev hooks: remove lib/features/theme_preview/ (3 files), remove the /theme-preview GoRoute in lib/core/routing/app_router.dart, remove the Theme preview OutlinedButton in lib/features/home/presentation/screens/home_screen.dart, update the library dartdoc in lib/app.dart and lib/core/routing/app_router.dart and the class dartdoc in lib/features/home/presentation/screens/home_screen.dart, and update tests (delete the second test in test/widget_test.dart and Test 5/AC-13 in test/core/routing/app_router_test.dart). This is the post-MVP cleanup deferred by specs/002-main-screen/spec.md §6 and closes Bug 009."
```

If the user wants to keep the preview as a dev tool, switch to Option B and run:

```
/fix "Bug 009: replace cross-feature settingsNotifierProvider usage in lib/features/theme_preview/presentation/screens/theme_preview_screen.dart with a local ValueNotifier<ThemeMode>, remove the cross-feature imports of settings_provider.dart and app_theme_mode.dart. Also rewrite the second test in test/widget_test.dart so theme cycling is asserted against settings_screen, not theme_preview_screen."
```
