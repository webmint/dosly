# Task 001: Relocate AppBottomNav from core/widgets to core/routing

**Agent**: mobile-engineer
**Files**:
- `lib/core/widgets/app_bottom_nav.dart` → `lib/core/routing/app_bottom_nav.dart` (move)
- `lib/core/routing/app_shell.dart` (import edit)
- `test/core/widgets/app_bottom_nav_test.dart` → `test/core/routing/app_bottom_nav_test.dart` (move + import edit)
- `test/core/widgets/app_bottom_nav_l10n_test.dart` → `test/core/routing/app_bottom_nav_l10n_test.dart` (move + import edit)
- `test/core/routing/app_router_test.dart` (import edit)
- `lib/core/widgets/`, `test/core/widgets/` (remove if empty)
**Depends on**: None
**Blocks**: None
**Context docs**: None
**Review checkpoint**: No

**Description**:

Resolve Bug 015 (constitution §2.1: anything in `core/` must be feature-agnostic). `AppBottomNav` hardcodes the three feature destinations (Today/Meds/History — Lucide icons + l10n label keys) but lives in `lib/core/widgets/`. Relocate it verbatim into `lib/core/routing/`, beside `app_shell.dart` — the composition root that already imports all four feature screens (`app_router.dart:17-20`) and so legitimately knows the feature IA. This restores `core/widgets/` to feature-agnostic.

This is a single atomic task: moving the source breaks the shell import and all three test imports simultaneously, so they must all change together or `dart analyze`/test compilation fails in any intermediate state. Pure relocation — no change to the widget's public API, rendered output, or behavior (Option C from `research/2026-05-26-bottom-nav-core-placement.md`).

**Change details**:
- Move `lib/core/widgets/app_bottom_nav.dart` → `lib/core/routing/app_bottom_nav.dart`:
  - Move the file verbatim. The class, constructor, parameters, dartdoc, `library;` directive, and `build()` body are unchanged.
  - **Do NOT change the l10n import** — `import '../../l10n/l10n_extensions.dart';` stays exactly as-is. `core/routing/` is the same depth as `core/widgets/` (`lib/core/X/`); `app_router.dart:21` already uses this identical path from `core/routing/`.
- In `lib/core/routing/app_shell.dart`:
  - Change the import from `'../widgets/app_bottom_nav.dart'` to `'app_bottom_nav.dart'` (now same directory).
- Move `test/core/widgets/app_bottom_nav_test.dart` → `test/core/routing/app_bottom_nav_test.dart`:
  - Change import (line 1) `package:dosly/core/widgets/app_bottom_nav.dart` → `package:dosly/core/routing/app_bottom_nav.dart`. All assertions unchanged.
- Move `test/core/widgets/app_bottom_nav_l10n_test.dart` → `test/core/routing/app_bottom_nav_l10n_test.dart`:
  - Change import (line 1) to `package:dosly/core/routing/app_bottom_nav.dart`. All assertions unchanged.
- In `test/core/routing/app_router_test.dart` (stays in place):
  - Change import (line 26) `package:dosly/core/widgets/app_bottom_nav.dart` → `package:dosly/core/routing/app_bottom_nav.dart`. All assertions unchanged.
- After moving, if `lib/core/widgets/` and/or `test/core/widgets/` are empty, remove the empty directories.
- Do NOT touch `app_router.dart` (its `[AppBottomNav]` references are dartdoc-only; type name unchanged) or `meds_screen.dart:56` (dartdoc-only reference).

## Contracts

### Expects
- `lib/core/widgets/app_bottom_nav.dart` currently defines `class AppBottomNav extends StatelessWidget` with required params `selectedIndex` and `onDestinationSelected`.
- `lib/core/routing/app_shell.dart` imports `'../widgets/app_bottom_nav.dart'` and constructs `AppBottomNav(selectedIndex: ..., onDestinationSelected: ...)`.
- `test/core/widgets/app_bottom_nav_test.dart`, `test/core/widgets/app_bottom_nav_l10n_test.dart`, and `test/core/routing/app_router_test.dart` import `package:dosly/core/widgets/app_bottom_nav.dart`.
- `lib/l10n/l10n_extensions.dart` exists and is reachable from `lib/core/routing/` via `../../l10n/l10n_extensions.dart`.

### Produces
- `lib/core/routing/app_bottom_nav.dart` exists and defines `class AppBottomNav extends StatelessWidget` with required params `selectedIndex` and `onDestinationSelected`; it contains `NavigationDestination` entries using `LucideIcons.house`/`l.bottomNavToday`, `LucideIcons.pill`/`l.bottomNavMeds`, `LucideIcons.activity`/`l.bottomNavHistory`.
- `lib/core/widgets/app_bottom_nav.dart` no longer exists.
- `lib/core/routing/app_shell.dart` imports `'app_bottom_nav.dart'`.
- `test/core/routing/app_bottom_nav_test.dart` and `test/core/routing/app_bottom_nav_l10n_test.dart` exist and import `package:dosly/core/routing/app_bottom_nav.dart`; the old `test/core/widgets/app_bottom_nav*_test.dart` files no longer exist.
- `test/core/routing/app_router_test.dart` imports `package:dosly/core/routing/app_bottom_nav.dart`.

**Done when**:
- [x] `lib/core/routing/app_bottom_nav.dart` exists; `lib/core/widgets/app_bottom_nav.dart` does not (AC-1)
- [x] `AppBottomNav` public API unchanged — same class name, same two required params `selectedIndex: int` / `onDestinationSelected: ValueChanged<int>` (AC-2)
- [x] Widget renders identically — M3 `NavigationBar` + 1-px top `Divider`, three destinations in order with the same Lucide icons and `bottomNav*` l10n keys, `labelBehavior: alwaysShow` (AC-3)
- [x] `app_shell.dart` imports the widget from the new location and constructs it identically (AC-4)
- [x] All three test files import `package:dosly/core/routing/app_bottom_nav.dart`; the two widget-test files live under `test/core/routing/` (AC-5)
- [x] `lib/core/widgets/` holds no feature-aware widget (AC-8)
- [x] `flutter test` passes — the relocated widget tests and `app_router_test.dart` pass with assertion logic unchanged (AC-7)
- [x] `dart analyze` passes on all changed files with no new diagnostics (AC-6)

**Spec criteria addressed**: AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8

## Completion Notes

**Status**: Complete
**Completed**: 2026-05-26
**Files changed**: `lib/core/routing/app_bottom_nav.dart` (moved from `lib/core/widgets/`, verbatim via `git mv`), `lib/core/routing/app_shell.dart` (import → same-dir), `test/core/routing/app_bottom_nav_test.dart` + `test/core/routing/app_bottom_nav_l10n_test.dart` (moved from `test/core/widgets/`, import → new package path), `test/core/routing/app_router_test.dart` (import → new package path).
**Contract**: Expects [4/4 verified] | Produces [5/5 verified]
**Notes**: `lib/core/widgets/` was NOT removed — it still holds `prefs_load_error_screen.dart` and `splash_screen.dart`, both confirmed feature-agnostic by code review, so AC-8 ("no feature-aware widget in core/widgets/") is satisfied without deleting the directory. The plan/spec's contingent "remove if empty" step was a no-op. The l10n import inside the moved widget stayed unchanged (`../../l10n/l10n_extensions.dart`) as predicted (same depth as old location; `app_router.dart:21` precedent). `git mv` preserved file history; diff against checkpoint showed zero content delta on the widget. Verification: `dart analyze` clean; `flutter test` 241 passed; code review APPROVE (no critical/warning).
