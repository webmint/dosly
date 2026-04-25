# Settings

## Overview

The **settings feature** owns the Settings screen — a push destination reached from the gear icon in `HomeScreen`'s `AppBar`. Currently the feature contains a single placeholder screen (`SettingsScreen`) with a localized `AppBar` and an empty body. Real settings content (theme persistence, locale picker, notification preferences, etc.) will be added by future specs.

Everything in this feature lives under `lib/features/settings/presentation/`. There is no `domain/` or `data/` layer yet.

## SettingsScreen

`SettingsScreen` (in `lib/features/settings/presentation/screens/settings_screen.dart`) is a `StatelessWidget` that renders a `Scaffold` with:

- An `AppBar` whose title is the localized `settingsTitle` string (`context.l10n.settingsTitle`).
- A 1-px `Divider` pinned to the bottom of the `AppBar` via `PreferredSize`, matching the HTML design template's header border rule.
- A `SizedBox.shrink()` body — intentionally empty until the settings feature is implemented.
- A back button in the leading slot provided automatically by Flutter because this screen is pushed onto the navigator stack — no manual `leading:` is needed.

```dart
// lib/features/settings/presentation/screens/settings_screen.dart
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsTitle),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1),
        ),
      ),
      body: const SizedBox.shrink(),
    );
  }
}
```

## Routing

`SettingsScreen` is mounted at `/settings` as a **sibling** `GoRoute` outside the `StatefulShellRoute.indexedStack` in `lib/core/routing/app_router.dart`. This means the screen renders without the bottom navigation bar — it is a push destination, not a tab branch.

Navigate to it from any screen that has a `BuildContext` with a go_router scope:

```dart
context.push('/settings');
```

Use `context.push` (not `context.go`) so that the back button and the navigator back stack work correctly. `context.go` would replace the current history entry and break the back gesture.

The entry point in the current codebase is `HomeScreen`'s gear `IconButton`:

```dart
// lib/features/home/presentation/screens/home_screen.dart
IconButton(
  onPressed: () => context.push('/settings'),
  tooltip: context.l10n.settingsTooltip,
  icon: const Icon(LucideIcons.settings),
),
```

## Localized title

The `settingsTitle` ARB key is a dedicated key for the screen title. It differs from `settingsTooltip`, which is used for the `IconButton` tooltip in `HomeScreen`. Current translations:

| Key | English | German | Ukrainian |
|---|---|---|---|
| `settingsTitle` | Settings | Einstellungen | Налаштування |
| `settingsTooltip` | Settings | Einstellungen | Налаштування |

Both resolve to the same string in all three locales today. If the title and tooltip ever need different wording, they are already separate keys.

## Evolution

The empty body is a deliberate placeholder. When the real settings feature lands, it will:

- Add a theme-mode selector (persisting the current in-memory `ThemeController` value to a drift-backed store — see [`theme.md`](theme.md)).
- Add a locale picker (replacing the device-locale-only resolution described in [`i18n.md`](i18n.md)).
- Add notification-preference toggles (future spec).

No changes to `AppBar` structure or the `/settings` route path are expected. The route remaining outside `StatefulShellRoute` is intentional and permanent — settings is not a tab destination.

## Testing

Widget tests live at `test/features/settings/presentation/screens/settings_screen_test.dart`. They cover:

- `SettingsScreen` renders without throwing.
- The `AppBar` title text matches the English `settingsTitle` string.
- A 1-px bottom `Divider` is present on the `AppBar`.
- The body is empty (`SizedBox.shrink()`).
- The automatic back button is present (Flutter provides it because the screen is pushed).
- The screen does not render a `BottomNavigationBar` or `NavigationBar`.

A router integration test in `test/core/routing/app_router_test.dart` verifies that `context.push('/settings')` transitions to `SettingsScreen` from the home route.

## Related

- [`../../specs/008-settings-screen/spec.md`](../../specs/008-settings-screen/spec.md) — the spec that introduced this screen
- [`home.md`](home.md) — `HomeScreen`, which hosts the gear icon entry point
- [`../architecture.md`](../architecture.md) — route topology and the sibling-route pattern
- [`i18n.md`](i18n.md) — how `settingsTitle` and `settingsTooltip` are translated and how to add new strings
- [`theme.md`](theme.md) — `ThemeController`, whose persistence is deferred to the future settings feature
