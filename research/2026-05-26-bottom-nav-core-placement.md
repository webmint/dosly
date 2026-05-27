# Research: Bug 015 — `AppBottomNav` is feature-aware but lives in `core/widgets/`

**Date**: 2026-05-26
**Topic**: Constitution §2.1 violation — `core/widgets/app_bottom_nav.dart` hardcodes the three feature destinations (Today/Meds/History), so `core/` is not feature-agnostic
**Verdict**: Feasible — small, localized structural fix (good `/fix` candidate)

## Summary

The bug is real: `app_bottom_nav.dart` hardcodes destination identity, Lucide icons, and l10n label keys, yet sits in `core/widgets/`, which §2.1 requires to be feature-agnostic. However, the bug file's framing slightly misdiagnoses the cleanest fix. The decisive fact is that **`core/routing/` is already the de facto composition root** — `app_router.dart:17-20` imports all four feature screens, and `app_shell.dart` composes them. The routing layer already legitimately "knows" the feature IA. That makes a third option (relocate the widget into `core/routing/`, beside `app_shell.dart`) the lowest-churn fix that respects the pattern already in the codebase. The new `lib/app/` layer proposed in the bug's Option A doesn't exist and isn't sanctioned by the constitution's directory layout.

## Codebase Findings

### Existing Related Code
| Area | Files | Relevance |
|------|-------|-----------|
| The widget | `lib/core/widgets/app_bottom_nav.dart` | Hardcodes 3 destinations (lines 65-78); only params are `selectedIndex` + `onDestinationSelected` |
| Composition root | `lib/core/routing/app_shell.dart` | Sole consumer of `AppBottomNav` (line 54) |
| Router | `lib/core/routing/app_router.dart` | **Already imports all 4 feature screens** (17-20) and defines branch order matching nav order |
| Tests | `test/core/widgets/app_bottom_nav_test.dart`, `..._l10n_test.dart`, `test/core/routing/app_router_test.dart` | 3 files import `package:dosly/core/widgets/app_bottom_nav.dart` directly — relocation requires updating these import paths |

### Patterns Available
- **`core/routing/` as composition root**: `app_router.dart` and `app_shell.dart` already import feature code. This is the constitution's implicit, accepted exception to "core is feature-agnostic" — routing inherently wires features together.

### Gaps
- `lib/app/` directory does **not** exist. Constitution §2.2 mentions a flat `lib/app.dart` (MaterialApp setup) but no `lib/app/` package layer. Bug's Option A would invent a new top-level layer.

## Constitution Constraints

| Rule | Impact on This Idea |
|------|---------------------|
| §2.1: "Anything in `core/` must be feature-agnostic" | The literal violation. But §2.2 itself places `routing/app_router.dart` in `core/`, and routing must know features — so routing is the sanctioned composition-root exception. |
| §2.2 directory layout | Defines `core/{clock,database,error,logging,notifications,permissions,routing,theme,utils}` — no `widgets/` shown for feature-aware widgets, and no `lib/app/`. Argues against Option A. |
| §2.2 filename rules | "One public type per file" + test files mirror source 1:1 — relocation must move the test file paths to match. |

## Approaches

### Option A (bug file): Relocate to new `lib/app/widgets/`
- **Pros**: Clean conceptual separation of "app shell" from "core infra".
- **Cons**: Invents a top-level layer not in the constitution; larger blast radius (new layer convention to document/enforce); inconsistent with `app_shell.dart` still living in `core/routing/`.
- **Complexity**: Medium

### Option B (bug file): Parameterize `destinations`
- **Pros**: Makes the widget genuinely reusable/testable in isolation; matches its "router-agnostic" dartdoc claim.
- **Cons**: Pushes the `LucideIcons` + `context.l10n` label wiring into `app_shell.dart` (which currently has no l10n import); the destination list is a singleton in practice, so this adds indirection for a hypothetical second shell that may never exist (KISS tension); the hardcoded labels still live *somewhere* in `core/routing/` — it relocates the smell rather than removing it.
- **Complexity**: Medium

### Option C (recommended — relocate within `core/routing/`): move `app_bottom_nav.dart` → `lib/core/routing/app_bottom_nav.dart`
- **Description**: Keep the widget exactly as-is, but move it beside its only consumer (`app_shell.dart`) into the layer that already legitimately knows feature IA.
- **Pros**: Smallest diff (move file + fix 1 internal import in `app_shell.dart` + 3 test import paths + move 2 test files to `test/core/routing/`); respects the existing composition-root pattern; restores `core/widgets/` to genuinely feature-agnostic; no new conventions, no parameterization churn.
- **Cons**: `core/routing/` still contains feature-aware code — but that's already true of `app_router.dart`/`app_shell.dart`, so this is internally consistent rather than a new violation.
- **Complexity**: Low

**Recommended approach**: **Option C** — it's the minimal change that resolves the §2.1 violation (`core/widgets/` becomes feature-agnostic) while staying consistent with the composition-root pattern already present in `core/routing/`. Option B is the right call *only* if a second nav composition is actually on the roadmap; otherwise it's speculative generality.

## Complexity Assessment

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Codebase changes | Low | Option C: 1 file move, 1 import edit in `app_shell.dart`, 3 test files' import paths, 2 test files relocated to mirror source |
| New dependencies | None | Pure restructuring |
| Risk | Low | Behavior-preserving; widget tests + `app_router_test` already lock current behavior |

## Recommendation

**Proceed** — small, localized, behavior-preserving change. Ideal for `/fix`, but if formalizing as a feature: confirm Option C vs Option B at the start.

One decision to confirm: **Option C (recommended) vs Option B**. Choose B instead only if a second/alternate bottom-nav composition is anticipated; otherwise C is cleaner and smaller.
