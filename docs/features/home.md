# Home

## Overview

The **home feature** owns the app's root screen — `HomeScreen` — and everything that renders inside it. Today that means the top `AppBar`, a placeholder body, and a Material 3 **bottom navigation bar** with three destinations (Today · Meds · History) rendered in Lucide icons. The bar is the app's long-term primary navigation surface: future features will hang real screens off each destination, but at this stage the buttons are intentionally inert — they light up with ripple feedback on tap and do nothing else.

Everything in this feature lives under `lib/features/home/presentation/`. There is no `domain/` or `data/` layer yet — the home screen is pure UI sitting on top of the core theme.

## The bottom navigation bar

`HomeBottomNav` (in `lib/features/home/presentation/widgets/home_bottom_nav.dart`) is a thin wrapper around Flutter's built-in M3 `NavigationBar`, with a 1-px `Divider` pinned to its top edge to match the HTML design template's `.bot-nav { border-top: 1px solid var(--md-outline-variant) }` rule. The `NavigationBar` itself declares exactly three `NavigationDestination`s in a fixed order:

| Index | Label     | Icon                    |
|------:|-----------|-------------------------|
| 0     | Today     | `LucideIcons.house`     |
| 1     | Meds      | `LucideIcons.pill`      |
| 2     | History   | `LucideIcons.activity`  |

The widget is a `StatelessWidget` with a hard-coded `selectedIndex: 0` and a no-op callback:

```dart
// lib/features/home/presentation/widgets/home_bottom_nav.dart
void _noop(int _) {}

class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Divider(height: 1, thickness: 1),
        NavigationBar(
          selectedIndex: 0,
          onDestinationSelected: _noop,
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

Destination labels flow from `AppLocalizations` via `context.l10n` (see [`i18n.md`](i18n.md)). Because labels are runtime values from `BuildContext`, the three `NavigationDestination` instances are no longer `const`; the outer `const HomeBottomNav({super.key})` constructor and the top-level `_noop` function are preserved. `Icon` leaves remain `const`.

Three design notes worth calling out:

- **`_noop` is a top-level function, not an inline lambda.** Inline lambdas are not `const`-compatible, which would force every call site to drop `const HomeBottomNav()`. Pulling the no-op out to a top-level function keeps the widget trivially const-constructable.
- **No hard-coded colors, no `NavigationBarTheme` overrides.** Material 3's default `NavigationBar` already reads `surfaceContainer`, `secondaryContainer`, `onSecondaryContainer`, `onSurface`, and `onSurfaceVariant` from the ambient `ColorScheme`. Because those tokens are populated in both `lightColorScheme` and `darkColorScheme` (see [`theme.md`](theme.md)), light/dark works with zero per-theme code.
- **The top `Divider` has no explicit color.** Material 3's `DividerTheme` default resolves to `ColorScheme.outlineVariant`, which is exactly the token the HTML template uses (`var(--md-outline-variant)`). Hard-coding a color would break dark-mode parity and duplicate what the theme already supplies.

`labelBehavior: NavigationDestinationLabelBehavior.alwaysShow` is explicit — platform defaults differ, and the HTML design reference shows all three labels permanently, so the choice is pinned in code.

## Usage

`HomeBottomNav` is consumed in exactly one place — `HomeScreen`:

```dart
// lib/features/home/presentation/screens/home_screen.dart
Scaffold(
  appBar: AppBar(
    title: const Text('Dosly'),
    actions: [
      IconButton(
        onPressed: null,
        tooltip: context.l10n.settingsTooltip,  // localized via AppLocalizations
        icon: const Icon(LucideIcons.settings),
      ),
    ],
    bottom: const PreferredSize(
      preferredSize: Size.fromHeight(1),
      child: Divider(),
    ),
  ),
  body: /* placeholder body */,
  bottomNavigationBar: const HomeBottomNav(),
);
```

Nothing outside `HomeScreen` should construct `HomeBottomNav` — it is a home-feature-scoped widget, not a shared component. If a second screen needs a bottom nav, that is the trigger to lift the widget into a shell route (see [Evolution](#evolution) below).

## Why built-in `NavigationBar` (not a custom widget)

The `dosly_m3_template.html` design uses a pill-shaped active indicator, 64×32 pill dimensions, and specific role colors — all of which are exactly what Material 3's `NavigationBar` produces out of the box. A custom `Row`-based widget was considered and rejected: it would re-implement the M3 pattern by hand, diverge from the spec on any future Flutter upgrade, and lose the automatic `ColorScheme` wiring. Built-in wins on every axis here.

The visual contract we accept is "matches M3 intent", not "pixel-exact to the HTML". Flutter's `NavigationBar` defaults (80 dp height, standard indicator size) are treated as canonical; if the user flags a visual mismatch on-device, a separate spec will introduce a `NavigationBarThemeData` override.

## Evolution

The shape of `HomeBottomNav` today is deliberately set up to evolve in two known steps:

1. **Wire real navigation.** A follow-up feature will:
   - Convert the widget to stateful (or pair it with a Riverpod provider / router-aware notifier) so `selectedIndex` tracks the active route.
   - Lift the bar into a `StatefulShellRoute` in `lib/core/routing/app_router.dart` so navigation state survives across tabs.
   - Destination labels are already localized (feature 006-i18n-support).
2. **Add the FAB.** The HTML template shows a FAB sitting above the center of the nav bar (`.fab-wrap` in lines 350–366). That is a separate spec — not added here to keep this feature minimal.

The **destination set itself** (Today / Meds / History, in that order) is the stable contract. Follow-up work will change what happens when you tap, not which destinations exist.

## Testing

Widget tests live at `test/features/home/presentation/widgets/home_bottom_nav_test.dart`. The test harness registers `AppLocalizations.localizationsDelegates` and `AppLocalizations.supportedLocales` on its `MaterialApp`, defaulting to the English locale. Tests cover six invariants:

- Exactly three `NavigationDestination`s are rendered, with labels `Today` / `Meds` / `History` in order.
- The three icons resolve to `LucideIcons.house`, `LucideIcons.pill`, `LucideIcons.activity`.
- `NavigationBar.selectedIndex == 0` on first render.
- Tapping `Meds` and tapping `History` leaves `selectedIndex` at `0` after `pumpAndSettle` — the tap-is-a-no-op contract.
- `labelBehavior == NavigationDestinationLabelBehavior.alwaysShow`.
- A 1-px `Divider` is rendered above the `NavigationBar` — regression guard for the HTML template's top border.

Locale-specific tests live at `test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart`. They pump the widget under `Locale('de')`, `Locale('uk')`, and `Locale('fr')` (unsupported — verifies English fallback).

If a future change breaks any of these, the failing test name will point directly at the invariant that slipped.

## Rules

- **Do not add icons to the bar without updating the Lucide canonical set.** New icons belong in both `theme_preview_screen.dart`'s showcase and [`icons.md`](icons.md). The current three (`house`, `pill`, `activity`) are already on that list.
- **Do not hard-code `selectedIndex` anywhere but in `HomeBottomNav` itself.** When the "wire real navigation" spec lands, `selectedIndex` becomes derived state — callers must not pre-empt that by passing it in.
- **Do not add a `NavigationBarThemeData` override until the user asks for one.** The M3 defaults match the design template; an override adds a second source of truth for something that is already right.

## Related

- [`../../specs/005-bottom-nav/spec.md`](../../specs/005-bottom-nav/spec.md) — the spec that introduced this feature
- [`../../specs/005-bottom-nav/plan.md`](../../specs/005-bottom-nav/plan.md) — design decisions (built-in vs custom, statefulness, theme wiring)
- [`../../specs/005-bottom-nav/summary.md`](../../specs/005-bottom-nav/summary.md) — concise feature summary
- [`i18n.md`](i18n.md) — how localized strings are sourced, how to add new strings and locales
- [`theme.md`](theme.md) — the `ColorScheme` roles the nav bar reads from
- [`icons.md`](icons.md) — the Lucide icon set the destinations use
- [`../architecture.md`](../architecture.md) — where the home feature sits in the Clean Architecture layering
