# Spec: Bottom Nav Relocate

**Date**: 2026-05-26
**Status**: Complete
**Author**: Claude + Webmint

## 1. Overview

`lib/core/widgets/app_bottom_nav.dart` hardcodes the three feature destinations (Today/Meds/History — icon + localized label) yet lives in `lib/core/`, which constitution §2.1 requires to be feature-agnostic (Bug 015). This spec relocates the widget into `lib/core/routing/` — beside `app_shell.dart`, the composition root that already imports all four feature screens — so that `lib/core/widgets/` is restored to genuinely feature-agnostic, with no change to the widget's behavior or public API.

## 2. Current State

`AppBottomNav` is a `StatelessWidget` that renders a Material 3 `NavigationBar` with a 1-px top `Divider`. Its only parameters are `selectedIndex` (int) and `onDestinationSelected` (`ValueChanged<int>`); the three destinations are hardcoded inside `build()`.

- `lib/core/widgets/app_bottom_nav.dart` (entire file, 84 lines) — the widget. Hardcodes destination identity + Lucide icons + l10n label keys at lines 65–78 (`LucideIcons.house`/`l.bottomNavToday`, `LucideIcons.pill`/`l.bottomNavMeds`, `LucideIcons.activity`/`l.bottomNavHistory`). Imports `flutter/material.dart`, `lucide_icons_flutter`, and `../../l10n/l10n_extensions.dart` (for `context.l10n`).
- `lib/core/routing/app_shell.dart:18` — sole runtime consumer; imports the widget via `import '../widgets/app_bottom_nav.dart';` and constructs it at line 54, wiring `navigationShell.currentIndex` → `selectedIndex` and `navigationShell.goBranch` → `onDestinationSelected`.
- `lib/core/routing/app_router.dart` — the composition root, **already imports all four feature screens** (`app_router.dart:17-20`) and defines the `StatefulShellRoute` branch order matching the nav order (0=Today, 1=Meds, 2=History). It references `[AppBottomNav]` only in dartdoc comments (lines 6, 9, 82); it does not import the widget.

Composition-root precedent: `core/routing/` already legitimately "knows" the feature information architecture. Per constitution §2.2, the directory layout sanctions `core/routing/app_router.dart`, and routing inherently wires features — making `core/routing/` the natural, already-accepted home for feature-aware shell composition.

Tests reference the widget by its `package:` path (constitution §2.2: test files mirror source 1:1; MEMORY L25: `test/` mirrors `lib/`):
- `test/core/widgets/app_bottom_nav_test.dart:1` — behavior/structure tests; imports `package:dosly/core/widgets/app_bottom_nav.dart`.
- `test/core/widgets/app_bottom_nav_l10n_test.dart:1` — locale-switching label tests; same import.
- `test/core/routing/app_router_test.dart:26` — router/shell integration tests (AC-8: exactly one `AppBottomNav` across branches); imports the same `package:` path and uses `find.byType(AppBottomNav)`.

`lib/features/meds/presentation/screens/meds_screen.dart:56` references `[AppShell]`'s `[AppBottomNav]` in a dartdoc comment only (no import, no code dependency).

## 3. Desired Behavior

Relocate the widget file and its source-mirroring tests, with no change to the widget's public API, rendered output, or runtime behavior (Option C from `research/2026-05-26-bottom-nav-core-placement.md`):

1. Move `lib/core/widgets/app_bottom_nav.dart` → `lib/core/routing/app_bottom_nav.dart`. The class, constructor, parameters, dartdoc, and `build()` body remain byte-for-byte equivalent except for the relative l10n import path, which must be updated for the new location (`../../l10n/l10n_extensions.dart` → `../l10n/l10n_extensions.dart`).
2. Update `app_shell.dart:18` import from `'../widgets/app_bottom_nav.dart'` to `'app_bottom_nav.dart'` (same directory).
3. Update the `package:` import in the three test files to `package:dosly/core/routing/app_bottom_nav.dart`.
4. Move `test/core/widgets/app_bottom_nav_test.dart` → `test/core/routing/app_bottom_nav_test.dart` and `test/core/widgets/app_bottom_nav_l10n_test.dart` → `test/core/routing/app_bottom_nav_l10n_test.dart` so tests mirror source 1:1.
5. If `lib/core/widgets/` becomes empty after the move, remove the now-empty directory (and its test mirror `test/core/widgets/` if empty).

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Widget source | `lib/core/widgets/app_bottom_nav.dart` → `lib/core/routing/app_bottom_nav.dart` | Move file; update relative l10n import only |
| Shell consumer | `lib/core/routing/app_shell.dart` | Update import path (line 18) |
| Behavior test | `test/core/widgets/app_bottom_nav_test.dart` → `test/core/routing/app_bottom_nav_test.dart` | Move file; update `package:` import |
| L10n test | `test/core/widgets/app_bottom_nav_l10n_test.dart` → `test/core/routing/app_bottom_nav_l10n_test.dart` | Move file; update `package:` import |
| Router test | `test/core/routing/app_router_test.dart` | Update `package:` import (line 26); stays in place |
| Empty dirs | `lib/core/widgets/`, `test/core/widgets/` | Remove if empty after move |

## 5. Acceptance Criteria

- [x] **AC-1**: `lib/core/routing/app_bottom_nav.dart` exists and defines `AppBottomNav`; `lib/core/widgets/app_bottom_nav.dart` no longer exists.
- [x] **AC-2**: `AppBottomNav`'s public API is unchanged — same class name, same two required parameters (`selectedIndex: int`, `onDestinationSelected: ValueChanged<int>`), same constructor signature.
- [x] **AC-3**: The rendered widget is unchanged — Material 3 `NavigationBar` with a 1-px top `Divider`, three destinations in order (Today/`LucideIcons.house`, Meds/`LucideIcons.pill`, History/`LucideIcons.activity`) using the same `bottomNavToday`/`bottomNavMeds`/`bottomNavHistory` l10n keys, `labelBehavior: alwaysShow`.
- [x] **AC-4**: `app_shell.dart` imports the widget from its new location and constructs it identically (same `selectedIndex`/`onDestinationSelected` wiring).
- [x] **AC-5**: All three test files import `package:dosly/core/routing/app_bottom_nav.dart`; the two widget-test files live under `test/core/routing/`.
- [x] **AC-6**: `dart analyze` reports no new errors, warnings, or info diagnostics introduced by the change.
- [x] **AC-7**: The full test suite passes unchanged — the two relocated widget tests and `app_router_test.dart` assert the same behavior they did before (behavior-preserving), with no assertion logic modified beyond import paths.
- [x] **AC-8**: `lib/core/widgets/` contains no feature-aware widget after the move, satisfying constitution §2.1. (`prefs_load_error_screen.dart` + `splash_screen.dart` remain — both verified feature-agnostic; the directory was not empty so was retained.)

## 6. Out of Scope

- NOT included: **Option B (parameterizing `destinations`)** — the widget keeps its hardcoded destination list; no `destinations` parameter is added. (Revisit only if a second/alternate bottom-nav composition is planned.)
- NOT included: **Option A (new `lib/app/` layer)** — no new top-level directory is introduced.
- NOT included: any change to `app_router.dart` route topology, branch order, or its dartdoc `[AppBottomNav]` references (the type name is unchanged, so doc links remain valid).
- NOT included: changes to the widget's visual design, icons, labels, divider, or l10n strings.
- NOT included: changes to `meds_screen.dart` (its `[AppBottomNav]` reference is a dartdoc comment that stays valid).
- NOT included: adding a lint/CI rule to enforce that `core/widgets/` stays feature-agnostic (separate concern).

## 7. Technical Constraints

- Must follow constitution §2.1 (anything in `core/` must be feature-agnostic) and §2.2 (test files mirror source 1:1; `snake_case.dart`; one public type per file).
- Must not break: the `StatefulShellRoute` composition in `app_router.dart`/`app_shell.dart`, or the AC-8 invariant in `app_router_test.dart` (exactly one `AppBottomNav` across shell branches).
- Must use the existing widget verbatim — this is a behavior-preserving move, not a rewrite. `NavigationBar` has no `const` constructor (MEMORY, Feature 005), so the existing non-const tree shape must be preserved as-is.
- Relative import paths must be corrected for the new file depth (`lib/core/routing/` is the same depth as `lib/core/widgets/`, so `../../l10n/...` stays `../l10n/...` — verify actual depth during implementation).

## 8. Open Questions

- OQ-1: None blocking. The relative-import path correction (Desired Behavior step 1) must be verified against the actual directory depth during implementation, since both old and new locations are two levels under `lib/` — the existing `../../l10n/l10n_extensions.dart` may remain correct unchanged. Implementation must confirm `dart analyze` resolves the import.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Relative import to `l10n_extensions.dart` breaks after move | Low | Low | `dart analyze` (AC-6) catches immediately; correct the `../` depth |
| A test or doc reference to the old `package:` path is missed | Low | Low | Grep confirms exactly 3 importers + 1 dartdoc (meds_screen); AC-7 full suite run catches stragglers |
| Stale empty `core/widgets/` dir left in tree | Low | Low | AC-8 explicitly removes empty dirs |
| Behavior accidentally altered during move | Low | Med | Move verbatim; unchanged tests (AC-7) lock structure, order, icons, labels, divider |
