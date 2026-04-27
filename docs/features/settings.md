# Settings

## Overview

The **settings feature** owns the Settings screen — a push destination reached from the gear icon in `HomeScreen`'s `AppBar`. It introduced the first full Clean Architecture stack in the project (domain + data + presentation) and brought Riverpod, `shared_preferences`, and `fpdart` into the codebase.

Currently the feature exposes one group of controls: theme mode. The user can follow the device system theme (default) or manually select Light or Dark.

## How it works

### Domain

`AppSettings` (`lib/features/settings/domain/entities/app_settings.dart`) is a plain immutable value object with two fields:

| Field | Default | Meaning |
|---|---|---|
| `useSystemTheme` | `true` | Follow the device theme when `true` |
| `manualThemeMode` | `ThemeMode.light` | Override used when `useSystemTheme` is `false` |

The `effectiveThemeMode` getter derives what to pass to `MaterialApp.themeMode`:

```dart
ThemeMode get effectiveThemeMode =>
    useSystemTheme ? ThemeMode.system : manualThemeMode;
```

`SettingsRepository` (`lib/features/settings/domain/repositories/settings_repository.dart`) is the abstract contract consumed by the presentation layer. It exposes synchronous `load()` and async `saveThemeMode` / `saveUseSystemTheme` operations, all returning `Either<Failure, T>`.

### Data

`SettingsLocalDataSource` wraps `SharedPreferencesWithCache` — all reads are synchronous (cache hit), writes are async (flushes to platform storage).

`SettingsRepositoryImpl` implements the contract: catches platform exceptions, converts them to `CacheFailure`, and wraps results in `Either`.

### Presentation

`SettingsNotifier` (`lib/features/settings/presentation/providers/settings_provider.dart`) is a `Notifier<AppSettings>`. Its `build()` loads the initial state synchronously from the repository cache. Mutation methods follow an optimistic pattern: in-memory state is only updated if persistence succeeds.

```dart
Future<void> setUseSystemTheme(bool value) async {
  final result = await ref.read(settingsRepositoryProvider).saveUseSystemTheme(value);
  result.fold(
    (failure) { /* log, leave state unchanged */ },
    (_) { state = state.copyWith(useSystemTheme: value); },
  );
}
```

`DoslyApp` watches `settingsProvider` with a narrow selector so only a `ThemeMode` change triggers a root rebuild:

```dart
themeMode: ref.watch(settingsProvider.select((s) => s.effectiveThemeMode)),
```

## ThemeSelector widget

`ThemeSelector` (`lib/features/settings/presentation/widgets/theme_selector.dart`) is a `ConsumerWidget` composed of two controls:

1. A `SwitchListTile` — "Use system theme" toggle. Default ON.
2. A full-width `SegmentedButton<ThemeMode>` — Light / Dark. Disabled (but visually reflecting the current system brightness) while the toggle is ON.

When the user turns the toggle OFF, `ThemeSelector` pre-fills the manual segment with the current device brightness so the visual transition is seamless.

```dart
// Switching to manual: pre-select the segment that matches current system brightness
final manualMode = systemBrightness == Brightness.dark
    ? ThemeMode.dark
    : ThemeMode.light;
ref.read(settingsProvider.notifier).setThemeMode(manualMode);
```

## SettingsScreen

`SettingsScreen` (`lib/features/settings/presentation/screens/settings_screen.dart`) renders a `Scaffold` with:

- An `AppBar` with the localized `settingsTitle` and a 1-px bottom `Divider`.
- A `ListView` body containing `ThemeSelector` inside a `Padding` with 16 px horizontal inset.
- A back button provided automatically by Flutter (screen is pushed, not a tab).

## Routing

`SettingsScreen` is mounted at `/settings` as a sibling `GoRoute` outside `StatefulShellRoute.indexedStack` — it renders without the bottom navigation bar. Navigate to it with `context.push`:

```dart
context.push('/settings');
```

Use `push` (not `go`) to preserve the back stack. The entry point is `HomeScreen`'s gear `IconButton`.

## Persistence

Settings are stored in `SharedPreferencesWithCache` under two keys:

| Key | Type | Default |
|---|---|---|
| `themeMode` | `String` (`'light'` / `'dark'`) | `'light'` |
| `useSystemTheme` | `bool` | `true` |

The `allowList` in `main()` is fixed to these two keys — no other preferences are accidentally cached.

## Localized strings

| ARB key | English |
|---|---|
| `settingsTitle` | Settings |
| `settingsTooltip` | Settings |
| `settingsUseSystemTheme` | Use system theme |
| `settingsUseSystemThemeSub` | Follows your device light/dark setting |
| `settingsThemeLight` | Light |
| `settingsThemeDark` | Dark |

## Related

- [`../architecture.md`](../architecture.md) — Riverpod bootstrap, `sharedPreferencesProvider`, `Failure` hierarchy
- [`theme.md`](theme.md) — M3 theme tokens; `AppTheme.lightTheme` / `darkTheme`
- [`i18n.md`](i18n.md) — how to add or change localized strings
- [`home.md`](home.md) — `HomeScreen`, which hosts the gear icon entry point
- [`../../specs/009-theme-settings/spec.md`](../../specs/009-theme-settings/spec.md) — the spec that drove this feature
