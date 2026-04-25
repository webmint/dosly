# Home

## Overview

The **home feature** owns the app's root screen — `HomeScreen`. `HomeScreen` renders the top `AppBar` and a placeholder body for the Today tab. The shared bottom navigation bar (`AppBottomNav`) lives in `lib/core/widgets/` — not inside this feature — and is hosted by the routing shell at `lib/core/routing/app_shell.dart`, which wires it to go_router's `StatefulShellRoute` and supplies real `selectedIndex` / `onDestinationSelected` values.

Everything in this feature lives under `lib/features/home/presentation/`. There is no `domain/` or `data/` layer yet — the home screen is pure UI sitting on top of the core theme.

## HomeScreen

`HomeScreen` (in `lib/features/home/presentation/screens/home_screen.dart`) is a `StatelessWidget` that renders a `Scaffold` with:

- An `AppBar` with the hard-coded title `"Dosly"` (not localized — the app name is a proper noun).
- A settings gear `IconButton` in `actions` that calls `context.push('/settings')`. The tooltip is the localized `settingsTooltip` string.
- A 1-px `Divider` pinned to the bottom of the `AppBar` via `PreferredSize`.
- A placeholder `body` with a centered "Hello World" text and a temporary "Theme preview" `OutlinedButton` (scheduled for post-MVP removal — see `specs/002-main-screen/spec.md` §6).

```dart
// lib/features/home/presentation/screens/home_screen.dart
AppBar(
  title: const Text('Dosly'),
  actions: [
    IconButton(
      onPressed: () => context.push('/settings'),
      tooltip: context.l10n.settingsTooltip,
      icon: const Icon(LucideIcons.settings),
    ),
  ],
  bottom: const PreferredSize(
    preferredSize: Size.fromHeight(1),
    child: Divider(height: 1, thickness: 1),
  ),
),
```

`context.push` is used (not `context.go`) so that the settings screen is pushed onto the navigator stack — the back button and back gesture work correctly, and the user returns to the home tab when they dismiss settings.

## The bottom navigation bar

`AppBottomNav` (in `lib/core/widgets/app_bottom_nav.dart`) is a thin wrapper around Flutter's built-in M3 `NavigationBar`, with a 1-px `Divider` pinned to its top edge to match the HTML design template's `.bot-nav { border-top: 1px solid var(--md-outline-variant) }` rule. The widget was moved from `lib/features/home/presentation/widgets/` to `lib/core/widgets/` because it is shared across all three tab screens (Today, Meds, History) and belongs in `lib/core/` per constitution §2.1 — feature A must not own cross-feature code. The `NavigationBar` itself declares exactly three `NavigationDestination`s in a fixed order:

| Index | Label     | Icon                    |
|------:|-----------|-------------------------|
| 0     | Today     | `LucideIcons.house`     |
| 1     | Meds      | `LucideIcons.pill`      |
| 2     | History   | `LucideIcons.activity`  |

The widget is a `StatelessWidget` whose active state and tap handling are entirely external — both `selectedIndex` and `onDestinationSelected` are required constructor parameters:

```dart
// lib/core/widgets/app_bottom_nav.dart
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Divider(height: 1, thickness: 1),
        NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: <NavigationDestination>[
            NavigationDestination(icon: const Icon(LucideIcons.house),    label: l.bottomNavToday),
            NavigationDestination(icon: const Icon(LucideIcons.pill),     label: l.bottomNavMeds),
            NavigationDestination(icon: const Icon(LucideIcons.activity), label: l.bottomNavHistory),
          ],
        ),
      ],
    );
  }
}
```

Destination labels flow from `AppLocalizations` via `context.l10n` (see [`i18n.md`](i18n.md)). `Icon` leaves remain `const`; the `NavigationDestination`s are not `const` because labels are runtime values.

Two design notes worth calling out:

- **No hard-coded colors, no `NavigationBarTheme` overrides.** Material 3's default `NavigationBar` already reads `surfaceContainer`, `secondaryContainer`, `onSecondaryContainer`, `onSurface`, and `onSurfaceVariant` from the ambient `ColorScheme`. Because those tokens are populated in both `lightColorScheme` and `darkColorScheme` (see [`theme.md`](theme.md)), light/dark works with zero per-theme code.
- **The top `Divider` has no explicit color.** Material 3's `DividerTheme` default resolves to `ColorScheme.outlineVariant`, which is exactly the token the HTML template uses (`var(--md-outline-variant)`). Hard-coding a color would break dark-mode parity and duplicate what the theme already supplies.

`labelBehavior: NavigationDestinationLabelBehavior.alwaysShow` is explicit — platform defaults differ, and the HTML design reference shows all three labels permanently, so the choice is pinned in code.

## Usage

`AppBottomNav` is constructed by `AppShell` (in `lib/core/routing/app_shell.dart`), which is the sole consumer:

```dart
// lib/core/routing/app_shell.dart
AppBottomNav(
  selectedIndex: navigationShell.currentIndex,
  onDestinationSelected: navigationShell.goBranch,
)
```

`navigationShell.goBranch` is a method tearoff that satisfies `ValueChanged<int>` directly — no lambda wrapper. The shell provides `selectedIndex` from `navigationShell.currentIndex`, which go_router updates automatically as branches are switched.

`HomeScreen` does not host `AppBottomNav`. Each branch screen (`HomeScreen`, `MedsScreen`, `HistoryScreen`) provides only its own `AppBar`; the shell provides the shared bottom bar around all three.

## Why built-in `NavigationBar` (not a custom widget)

The `dosly_m3_template.html` design uses a pill-shaped active indicator, 64×32 pill dimensions, and specific role colors — all of which are exactly what Material 3's `NavigationBar` produces out of the box. A custom `Row`-based widget was considered and rejected: it would re-implement the M3 pattern by hand, diverge from the spec on any future Flutter upgrade, and lose the automatic `ColorScheme` wiring. Built-in wins on every axis here.

The visual contract we accept is "matches M3 intent", not "pixel-exact to the HTML". Flutter's `NavigationBar` defaults (80 dp height, standard indicator size) are treated as canonical; if the user flags a visual mismatch on-device, a separate spec will introduce a `NavigationBarThemeData` override.

## Evolution

The shape of `AppBottomNav` was set up to evolve in two steps:

1. **Wire real navigation.** Done in spec `007-meds-history-screens`:
   - `AppBottomNav` converted to router-agnostic (`selectedIndex` + `onDestinationSelected` required params).
   - Lifted into `AppShell` + `StatefulShellRoute.indexedStack` in `lib/core/routing/` — navigation state now survives across tab switches.
   - `MedsScreen` (`/meds`) and `HistoryScreen` (`/history`) added as real branch destinations.
   - Destination labels were already localized (feature 006-i18n-support), reused as AppBar titles on the new screens.
2. **Add the FAB.** The HTML template shows a FAB sitting above the center of the nav bar (`.fab-wrap` in lines 350–366). That is a separate spec — not added yet to keep each feature minimal.

The **destination set itself** (Today / Meds / History, in that order) is the stable contract. Follow-up work will replace the placeholder bodies with real content, not change which destinations exist.

## Testing

Widget tests live at `test/core/widgets/app_bottom_nav_test.dart`. The test harness wraps `AppBottomNav` in a `MaterialApp` + `Scaffold`, accepting `selectedIndex` and an optional `onDestinationSelected` callback (defaults to a no-op). Tests cover six invariants:

- Exactly three `NavigationDestination`s are rendered, with labels `Today` / `Meds` / `History` in order.
- The three icons resolve to `LucideIcons.house`, `LucideIcons.pill`, `LucideIcons.activity`.
- `NavigationBar.selectedIndex` reflects the `selectedIndex` parameter passed in (tested for 0, 1, and 2).
- Tapping `Meds` invokes `onDestinationSelected` with index `1`; tapping `History` invokes it with `2`.
- `labelBehavior == NavigationDestinationLabelBehavior.alwaysShow`.
- A 1-px `Divider` is rendered above the `NavigationBar` — regression guard for the HTML template's top border.

Locale-specific tests live at `test/core/widgets/app_bottom_nav_l10n_test.dart`. They pump the widget under `Locale('de')`, `Locale('uk')`, and `Locale('fr')` (unsupported — verifies English fallback).

If a future change breaks any of these, the failing test name will point directly at the invariant that slipped.

## Rules

- **Do not add icons to the bar without updating the Lucide canonical set.** New icons belong in both `theme_preview_screen.dart`'s showcase and [`icons.md`](icons.md). The current three (`house`, `pill`, `activity`) are already on that list.
- **Do not construct `AppBottomNav` outside `AppShell`.** Although it lives in `lib/core/widgets/`, it is purpose-built for the routing shell. Adding a second call site would duplicate navigation state.
- **Do not add a `NavigationBarThemeData` override until the user asks for one.** The M3 defaults match the design template; an override adds a second source of truth for something that is already right.

## Related

- [`../../specs/005-bottom-nav/spec.md`](../../specs/005-bottom-nav/spec.md) — the spec that introduced this feature
- [`../../specs/005-bottom-nav/plan.md`](../../specs/005-bottom-nav/plan.md) — design decisions (built-in vs custom, statefulness, theme wiring)
- [`../../specs/005-bottom-nav/summary.md`](../../specs/005-bottom-nav/summary.md) — concise feature summary
- [`i18n.md`](i18n.md) — how localized strings are sourced, how to add new strings and locales
- [`theme.md`](theme.md) — the `ColorScheme` roles the nav bar reads from
- [`icons.md`](icons.md) — the Lucide icon set the destinations use
- [`settings.md`](settings.md) — the Settings screen pushed from the home gear icon
- [`../architecture.md`](../architecture.md) — where the home feature sits in the Clean Architecture layering
