# Plan: Bottom Nav Relocate

**Date**: 2026-05-26
**Spec**: spec.md
**Status**: Approved

## Summary

Behavior-preserving relocation of `app_bottom_nav.dart` from `lib/core/widgets/` to `lib/core/routing/` (beside `app_shell.dart`, the composition root that already imports features), with its two widget tests moved to `test/core/routing/` to mirror source 1:1. Pure file moves plus import-path edits — no change to the widget's API, rendered output, or any runtime behavior (Option C from `research/2026-05-26-bottom-nav-core-placement.md`).

## Technical Context

**Architecture**: Touches only `lib/core/routing/` (the sanctioned composition-root layer) and its test mirror. No domain/data/presentation feature layers involved.
**Error Handling**: N/A — no fallible operations added or changed.
**State Management**: N/A — `AppBottomNav` stays a stateless, parameter-driven widget; state continues to flow from `StatefulNavigationShell` via `app_shell.dart`.

## Constitution Compliance

- **§2.1 (anything in `core/` must be feature-agnostic)**: The change resolves the violation — after the move, `core/widgets/` holds no feature-aware widget, and the feature-aware nav lives in `core/routing/`, the layer that already legitimately knows the feature IA (`app_router.dart:17-20` imports all four feature screens). Compliant.
- **§2.2 (test files mirror source 1:1; `snake_case.dart`; one public type per file)**: Tests move with the source to `test/core/routing/`; filenames keep `snake_case`; one public type per file preserved. Compliant.
- **§4.2.1 (no `print`/`debugPrint`)**: Untouched — no logging changes. Compliant.
- **`NavigationBar` has no `const` constructor (MEMORY, Feature 005)**: The existing non-const `build()` tree is moved verbatim; no attempt to add `const`. Compliant.
- **Read before write**: The widget, shell, router, and all three test files were read during `/research` and `/specify`. Compliant.

## Implementation Approach

### Layer Map

| Layer | What | Files (existing or new) |
|-------|------|------------------------|
| Core / routing | Relocate the feature-aware bottom-nav widget beside its sole consumer | `lib/core/routing/app_bottom_nav.dart` (moved from `lib/core/widgets/`); `lib/core/routing/app_shell.dart` (import edit) |
| Test (core/routing mirror) | Move widget tests to mirror new source location; fix imports | `test/core/routing/app_bottom_nav_test.dart`, `test/core/routing/app_bottom_nav_l10n_test.dart` (moved); `test/core/routing/app_router_test.dart` (import edit) |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| Where the widget lives | `lib/core/routing/` beside `app_shell.dart` | Routing is the already-accepted composition root that knows feature IA; smallest diff; restores `core/widgets/` to feature-agnostic | Option A (`lib/app/` layer) — invents a top-level dir not in §2.2; Option B (parameterize `destinations`) — speculative generality, no second nav planned (spec §6) |
| Relative l10n import after move | Keep `import '../../l10n/l10n_extensions.dart'` **unchanged** | `core/routing/` and `core/widgets/` are the same depth (`lib/core/X/`); `app_router.dart:21` already uses this exact path from `core/routing/` (resolves OQ-1) | Changing to `../l10n/...` — would be wrong depth and break the import |
| Test relocation scope | Move the two `app_bottom_nav*` test files; leave `app_router_test.dart` in place (only edit its import) | `app_router_test.dart` tests the router/shell, not the widget — it already correctly lives in `test/core/routing/`; only its `package:` import to the widget needs updating | Moving/renaming `app_router_test.dart` — out of scope, would churn unrelated tests |
| Empty dir cleanup | Remove `lib/core/widgets/` and `test/core/widgets/` if empty after the move | Keeps tree clean; AC-8 requires `core/widgets/` hold no feature-aware widget | Leaving empty dirs — stale, misleading |

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `lib/core/widgets/app_bottom_nav.dart` | Delete (moved) | File removed from old location |
| `lib/core/routing/app_bottom_nav.dart` | Create (moved) | Byte-identical to old file; `import '../../l10n/l10n_extensions.dart'` stays unchanged (same depth) |
| `lib/core/routing/app_shell.dart` | Modify | Line 18 import `'../widgets/app_bottom_nav.dart'` → `'app_bottom_nav.dart'` (same dir) |
| `test/core/widgets/app_bottom_nav_test.dart` | Delete (moved) | File removed from old location |
| `test/core/routing/app_bottom_nav_test.dart` | Create (moved) | Import → `package:dosly/core/routing/app_bottom_nav.dart`; assertions unchanged |
| `test/core/widgets/app_bottom_nav_l10n_test.dart` | Delete (moved) | File removed from old location |
| `test/core/routing/app_bottom_nav_l10n_test.dart` | Create (moved) | Import → `package:dosly/core/routing/app_bottom_nav.dart`; assertions unchanged |
| `test/core/routing/app_router_test.dart` | Modify | Line 26 import → `package:dosly/core/routing/app_bottom_nav.dart`; assertions unchanged |
| `lib/core/widgets/`, `test/core/widgets/` | Delete if empty | Remove now-empty directories |

> Discovered during planning: no change needed to `app_router.dart` (its `[AppBottomNav]` references are dartdoc only and the type name is unchanged) or `meds_screen.dart:56` (dartdoc reference only) — consistent with spec §6. No additions beyond the spec's Affected Areas.

### Documentation Impact

No documentation changes expected — internal structural move only. The widget's own dartdoc already says the active state/tap handling are external and the caller is "typically the routing shell at `lib/core/routing/app_shell.dart`"; that statement remains accurate (and is now same-directory). No `docs/` feature/architecture file references the widget's path.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Relative l10n import wrong after move | Very Low | Low | Resolved in planning — identical depth, `app_router.dart:21` proves the path; `dart analyze` (AC-6) confirms |
| A test/doc reference to old `package:` path missed | Low | Low | Grep confirmed exactly 3 importers + 2 dartdoc-only refs; AC-7 full suite run catches stragglers |
| Stale empty `core/widgets/` dir left behind | Low | Low | AC-8 explicitly removes empty dirs |
| Behavior accidentally altered during move | Low | Med | Move verbatim; unchanged tests (AC-3/AC-7) lock structure, order, icons, labels, divider |

## Dependencies

None. No packages to install, no services, no env vars. All referenced libraries (`flutter/material`, `lucide_icons_flutter`, `go_router`, l10n) are already in the project stack.

## Supporting Documents

- [Research](../../research/2026-05-26-bottom-nav-core-placement.md) — pre-spec feasibility analysis (Option A/B/C comparison; Option C chosen). No `/plan`-level `research.md` needed — no signals (pure relocation, all libs in-stack).
- Data Model — N/A (no entities).
- Contracts — N/A (no API changes).
