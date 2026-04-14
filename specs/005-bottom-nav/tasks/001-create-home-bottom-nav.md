# Task 001: Create HomeBottomNav widget and wire into HomeScreen

**Agent**: mobile-engineer
**Files**:
- `lib/features/home/presentation/widgets/home_bottom_nav.dart` (create)
- `lib/features/home/presentation/screens/home_screen.dart` (modify)
**Status**: Complete
**Depends on**: None
**Blocks**: 002
**Context docs**: None — task description is self-contained
**Review checkpoint**: No

## Completion Notes

**Completed**: 2026-04-14
**Files changed**:
- `lib/features/home/presentation/widgets/home_bottom_nav.dart` (NEW, 58 lines)
- `lib/features/home/presentation/screens/home_screen.dart` (+3 lines: 1 import, 1 Scaffold arg, 1 dartdoc paragraph)
**Contract**: Expects 3/3 verified | Produces 6/6 verified
**Notes**: Implementer correctly chose the top-level `_noop(int _)` function approach over an inline lambda — this preserves `const HomeBottomNav()` at the call site in `home_screen.dart:69`. `dart analyze` clean; `flutter test` 79/79 pass; code review APPROVE with praise notes only.

## Description

Create the new `HomeBottomNav` `StatelessWidget` that wraps Flutter's Material 3 `NavigationBar` with three fixed destinations (Today / Meds / History) using Lucide icons. Then wire it into the existing `HomeScreen.Scaffold` via `bottomNavigationBar:`.

This is a pure presentation-layer change. No `domain/` or `data/` files are touched, no new packages, no theme changes, no router changes.

## Change details

### `lib/features/home/presentation/widgets/home_bottom_nav.dart` (NEW)

Create a library file with:

- Library-level dartdoc explaining what the widget is, that `selectedIndex` is fixed at 0 ("Today"), that `onDestinationSelected` is intentionally a no-op (buttons tappable for ripple feedback but do not navigate), and that a future spec will convert it to stateful when real routes exist.
- Single import: `package:flutter/material.dart` + `package:lucide_icons_flutter/lucide_icons.dart`. Do NOT import `package:flutter/foundation.dart` (MEMORY.md: `unnecessary_import` trap — `material.dart` re-exports what we need).
- `class HomeBottomNav extends StatelessWidget` with a `const HomeBottomNav({super.key})` constructor.
- Constructor dartdoc: one short line.
- `build` returns a `NavigationBar` with:
  - `selectedIndex: 0`
  - `onDestinationSelected: (_) {}` (const empty lambda; if `const` placement causes trouble, use a top-level `void _noop(int _) {}` and pass it as `_noop`)
  - `labelBehavior: NavigationDestinationLabelBehavior.alwaysShow`
  - `destinations:` a `const <NavigationDestination>[ ... ]` list of exactly three entries, in this order:
    1. `NavigationDestination(icon: Icon(LucideIcons.house), label: 'Today')`
    2. `NavigationDestination(icon: Icon(LucideIcons.pill), label: 'Meds')`
    3. `NavigationDestination(icon: Icon(LucideIcons.activity), label: 'History')`
  - Every `Icon(...)` MUST be `const`.
- No colors are hard-coded anywhere. No `NavigationBarThemeData` customization — rely on `Theme.of(context).colorScheme` defaults.
- No `!` null-assertion operator anywhere.

### `lib/features/home/presentation/screens/home_screen.dart` (MODIFY)

- Add one import: `../widgets/home_bottom_nav.dart` (sorted in relative-import block per constitution §2.3).
- In the returned `Scaffold`, add `bottomNavigationBar: const HomeBottomNav(),` — placement convention: after `body:`.
- Update the class-level dartdoc to mention the bottom navigation bar briefly (1 short sentence — e.g., "A 3-destination [HomeBottomNav] sits in the bottom-navigation-bar slot.").
- Do NOT modify the `AppBar`, body contents, or the `Theme preview` `OutlinedButton`.

## Contracts

### Expects (preconditions)

- `lib/features/home/presentation/screens/home_screen.dart` exists and declares `class HomeScreen extends StatelessWidget` whose `build` returns a `Scaffold` with no existing `bottomNavigationBar:` argument.
- `package:lucide_icons_flutter/lucide_icons.dart` is resolvable (dependency present in `pubspec.yaml`). The names `LucideIcons.house`, `LucideIcons.pill`, and `LucideIcons.activity` compile (verified in MEMORY.md → Feature 004).
- `Theme.of(context).colorScheme` in this project has populated `surfaceContainer`, `secondaryContainer`, `onSecondaryContainer`, `onSurface`, `onSurfaceVariant`, and `outlineVariant` tokens (produced by Feature 001 `app_color_schemes.dart`).

### Produces (postconditions)

- `lib/features/home/presentation/widgets/home_bottom_nav.dart` exists and exports `class HomeBottomNav extends StatelessWidget` with a `const HomeBottomNav({super.key})` constructor.
- `HomeBottomNav.build` returns a `NavigationBar` whose `destinations` is a const list of exactly 3 `NavigationDestination` entries with labels `'Today'`, `'Meds'`, `'History'` in that order and icons `LucideIcons.house`, `LucideIcons.pill`, `LucideIcons.activity` in that order.
- `HomeBottomNav.build` passes `selectedIndex: 0` and a no-op `onDestinationSelected` callback to `NavigationBar`.
- `HomeBottomNav.build` passes `labelBehavior: NavigationDestinationLabelBehavior.alwaysShow` to `NavigationBar`.
- `lib/features/home/presentation/screens/home_screen.dart` imports `../widgets/home_bottom_nav.dart` and passes `bottomNavigationBar: const HomeBottomNav()` to its `Scaffold`.
- No file under `lib/features/home/domain/` or `lib/features/home/data/` was created or modified.

## Done when

- [x] `lib/features/home/presentation/widgets/home_bottom_nav.dart` exists with `class HomeBottomNav`.
- [x] `lib/features/home/presentation/screens/home_screen.dart`'s `Scaffold` wires `bottomNavigationBar: const HomeBottomNav()`.
- [x] `dart analyze 2>&1 | head -40` shows no new warnings/errors on the two changed files.
- [x] `flutter test` still passes (the existing 2 tests in `test/widget_test.dart` and all `test/core/theme/**` tests) — no regressions.
- [x] No import of `package:flutter/foundation.dart` in either file.
- [x] No hard-coded color literals (`Color(0x...)`, `Colors.xxx`) anywhere in `home_bottom_nav.dart`.
- [x] No `!` null-assertion operator in either file.

## Spec criteria addressed

AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-9, AC-12
