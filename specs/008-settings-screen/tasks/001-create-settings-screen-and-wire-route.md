# Task 001: Create Settings screen, add l10n keys, wire route and gear icon

**Agent**: mobile-engineer
**Files**:
- `lib/features/settings/presentation/screens/settings_screen.dart` (create)
- `lib/core/routing/app_router.dart` (modify)
- `lib/features/home/presentation/screens/home_screen.dart` (modify)
- `lib/l10n/app_en.arb` (modify)
- `lib/l10n/app_uk.arb` (modify)
- `lib/l10n/app_de.arb` (modify)

**Depends on**: None
**Blocks**: 002
**Review checkpoint**: No
**Context docs**: None

## Description

Create the empty `SettingsScreen` widget, add the `settingsTitle` l10n key to all three ARB files, register `/settings` as a sibling `GoRoute` in the router, and enable the gear `IconButton` on `HomeScreen`. All changes are mechanical — each follows an established pattern already in the codebase.

## Change Details

### `lib/l10n/app_en.arb`
- Add `"settingsTitle": "Settings"` with `@settingsTitle` description entry: `"Localized title for the Settings screen AppBar."`
- Insert after the existing `settingsTooltip` / `@settingsTooltip` block (before `bottomNavToday`)

### `lib/l10n/app_uk.arb`
- Add `"settingsTitle": "Налаштування"` after `settingsTooltip`

### `lib/l10n/app_de.arb`
- Add `"settingsTitle": "Einstellungen"` after `settingsTooltip`

### `lib/features/settings/presentation/screens/settings_screen.dart` (create)
- Create directory `lib/features/settings/presentation/screens/`
- Create `SettingsScreen` `StatelessWidget` with `const` constructor
- Pattern: identical to `MedsScreen` (`lib/features/meds/presentation/screens/meds_screen.dart`)
- `Scaffold` with `AppBar`:
  - `title: Text(context.l10n.settingsTitle)`
  - No `actions`
  - `bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, thickness: 1))`
- `body: const SizedBox.shrink()`
- Imports: `package:flutter/material.dart`, `../../../../l10n/l10n_extensions.dart`
- No manual `leading:` — Flutter auto-shows BackButton on push routes

### `lib/core/routing/app_router.dart`
- Add import for `SettingsScreen`: `import '../../features/settings/presentation/screens/settings_screen.dart';`
- Add `GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen())` as a sibling to the existing `/theme-preview` `GoRoute` — inside the `routes:` list, after the `StatefulShellRoute.indexedStack` block, alongside `/theme-preview`

### `lib/features/home/presentation/screens/home_screen.dart`
- Change the gear `IconButton.onPressed` from `null` to `() => context.push('/settings')`

## Contracts

### Expects
- `lib/features/meds/presentation/screens/meds_screen.dart` exists and contains `class MedsScreen extends StatelessWidget` (pattern reference)
- `lib/core/routing/app_router.dart` contains `GoRoute(path: '/theme-preview'` as a sibling route (pattern reference for adding `/settings`)
- `lib/features/home/presentation/screens/home_screen.dart` contains `onPressed: null` in the gear `IconButton`
- `lib/l10n/app_en.arb` contains `"settingsTooltip": "Settings"`

### Produces
- `lib/features/settings/presentation/screens/settings_screen.dart` exists and exports `class SettingsScreen extends StatelessWidget` with a `const SettingsScreen` constructor
- `lib/core/routing/app_router.dart` contains `GoRoute(path: '/settings'` with `builder` returning `const SettingsScreen()`
- `lib/features/home/presentation/screens/home_screen.dart` contains `onPressed: () => context.push('/settings')` in the gear `IconButton`
- `lib/l10n/app_en.arb` contains `"settingsTitle": "Settings"`, `app_uk.arb` contains `"settingsTitle": "Налаштування"`, `app_de.arb` contains `"settingsTitle": "Einstellungen"`
- `context.l10n.settingsTitle` resolves without error in Dart (l10n codegen succeeds)

## Done when
- [x] `dart analyze` reports zero issues on all changed/created files
- [x] Existing tests pass: `flutter test` (no regressions from route/l10n changes)
- [x] `SettingsScreen` renders a `Scaffold` with `AppBar` titled via `context.l10n.settingsTitle`, 1-px divider, empty body

## Spec criteria addressed
AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8

## Completion Notes

**Completed**: 2026-04-25
**Status**: Complete
**Files changed**: lib/features/settings/presentation/screens/settings_screen.dart (new), lib/core/routing/app_router.dart, lib/features/home/presentation/screens/home_screen.dart, lib/l10n/app_en.arb, app_uk.arb, app_de.arb, plus auto-generated l10n files
**Contract**: Expects 4/4 verified | Produces 5/5 verified
**Notes**: Code review flagged two warnings: (1) bare Divider() in home_screen.dart fixed to Divider(height: 1, thickness: 1), (2) stale dartdoc updated. Both fixed in-place.
