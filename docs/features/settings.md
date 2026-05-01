# Settings

## Overview

The **settings feature** owns the Settings screen — a push destination reached from the gear icon in `HomeScreen`'s `AppBar`. It introduced the first full Clean Architecture stack in the project (domain + data + presentation) and brought Riverpod, `shared_preferences`, and `fpdart` into the codebase.

The feature exposes two groups of controls: **Appearance** (theme mode) and **Language**. The user can follow the device system theme or manually select Light or Dark, and separately can follow the device language or pin the app to English, German, or Ukrainian.

## How it works

### Domain

`AppSettings` (`lib/features/settings/domain/entities/app_settings.dart`) is a plain immutable value object with four fields:

| Field | Default | Meaning |
|---|---|---|
| `useSystemTheme` | `true` | Follow the device theme when `true` |
| `manualThemeMode` | `AppThemeMode.light` | Override used when `useSystemTheme` is `false` |
| `useSystemLanguage` | `true` | Follow the device language when `true` |
| `manualLanguage` | `AppLanguage.en` | Override used when `useSystemLanguage` is `false` |

`AppThemeMode` (`lib/features/settings/domain/entities/app_theme_mode.dart`) is a domain-owned enum with two values — `light` and `dark`. It intentionally has no `system` value: the "follow system" concept is owned by the orthogonal `useSystemTheme: bool` flag. Each value carries a stable `code` field (`'light'` / `'dark'`) used for string persistence, and a `fromCodeOrDefault` static helper provides graceful fallback for unknown or legacy data. It lives alongside `AppLanguage` for the same domain-purity reason: both replace Flutter SDK types (`ThemeMode`, `Locale`) that would otherwise violate constitution §2.1 in the domain layer.

### Presentation seam

`AppSettings` intentionally exposes no Flutter SDK types — there are no `effectiveThemeMode` or `effectiveLocale` getters on the entity. Instead, `lib/app.dart` watches the four raw fields through separate narrow `ref.watch(settingsProvider.select(...))` calls and computes `MaterialApp.themeMode` and `locale` inline:

```dart
// lib/app.dart
final useSystemTheme = ref.watch(
  settingsProvider.select((s) => s.useSystemTheme),
);
final manualThemeMode = ref.watch(
  settingsProvider.select((s) => s.manualThemeMode),
);
final useSystemLanguage = ref.watch(
  settingsProvider.select((s) => s.useSystemLanguage),
);
final manualLanguage = ref.watch(
  settingsProvider.select((s) => s.manualLanguage),
);

return MaterialApp.router(
  locale: useSystemLanguage ? null : Locale(manualLanguage.code),
  themeMode: useSystemTheme
      ? ThemeMode.system
      : _toFlutterThemeMode(manualThemeMode),
  // ...
);
```

`_toFlutterThemeMode` is a private helper in `lib/app.dart` that maps `AppThemeMode` → `ThemeMode` exhaustively (no `default:` clause — the Dart compiler enforces exhaustiveness). This file is the single `Flutter SDK ↔ domain` mapping seam. When `locale` is `null` (system language mode), `MaterialApp`'s `localeResolutionCallback` fires and resolves the device locale against supported locales with an English fallback.

`AppLanguage` (`lib/features/settings/domain/entities/app_language.dart`) is an enum of the three supported languages. Each value carries its IETF code and a `nativeName` rendered in the language's own script:

| Value | `code` | `nativeName` |
|---|---|---|
| `AppLanguage.en` | `'en'` | `'English'` |
| `AppLanguage.de` | `'de'` | `'Deutsch'` |
| `AppLanguage.uk` | `'uk'` | `'Українська'` |

Native names are plain literals — they are never translated. This is the universal convention for language pickers so that users can find their language regardless of the app's current display language.

`SettingsRepository` (`lib/features/settings/domain/repositories/settings_repository.dart`) is the abstract contract consumed by the presentation layer. It exposes synchronous `load()` and async save operations, all returning `Either<Failure, T>`:

- `saveThemeMode(AppThemeMode)` — persists the manual theme choice
- `saveUseSystemTheme(bool)` — persists the system-theme toggle
- `saveUseSystemLanguage(bool)` — persists the system-language toggle
- `saveManualLanguage(AppLanguage)` — persists the manual language choice

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

`DoslyApp` in `lib/app.dart` watches `settingsProvider` with four narrow selectors so only the relevant field change triggers a root rebuild. See the [Presentation seam](#presentation-seam) section above for the full shape.

## ThemeSelector widget

`ThemeSelector` (`lib/features/settings/presentation/widgets/theme_selector.dart`) is a `ConsumerWidget` composed of two controls:

1. A `SwitchListTile` — "Use system theme" toggle. Default ON.
2. A full-width `SegmentedButton<AppThemeMode>` — Light / Dark. Disabled (but visually reflecting the current system brightness) while the toggle is ON.

When the user turns the toggle OFF, `ThemeSelector` pre-fills the manual segment with the current device brightness so the visual transition is seamless.

```dart
// Switching to manual: pre-select the segment that matches current system brightness
final manualMode = systemBrightness == Brightness.dark
    ? AppThemeMode.dark
    : AppThemeMode.light;
ref.read(settingsProvider.notifier).setThemeMode(manualMode);
```

## LanguageSelector widget

`LanguageSelector` (`lib/features/settings/presentation/widgets/language_selector.dart`) is a `ConsumerWidget` composed of two controls:

1. A `SwitchListTile` — "Use device language" toggle. Default ON.
2. A full-width `DropdownButton<AppLanguage>` populated from `AppLanguage.values`. Disabled (`onChanged: null`) while the toggle is ON, active when it is OFF.

When the toggle is ON, the dropdown still renders and shows the **device-resolved language** (not the stale prior manual selection), derived at build time from `Localizations.localeOf(context)`:

```dart
final deviceCode = Localizations.localeOf(context).languageCode;
final deviceLanguage = AppLanguage.values.firstWhere(
  (lang) => lang.code == deviceCode,
  orElse: () => AppLanguage.en,
);
final displayedLanguage =
    settings.useSystemLanguage ? deviceLanguage : settings.manualLanguage;
```

When the user turns the toggle OFF, `LanguageSelector` pre-fills `manualLanguage` with the device-resolved language so the visual transition is seamless:

```dart
// Switching to manual: pre-fill the matching device language
final deviceCode = Localizations.localeOf(context).languageCode;
final pre = AppLanguage.values.firstWhere(
  (lang) => lang.code == deviceCode,
  orElse: () => AppLanguage.en,
);
ref.read(settingsProvider.notifier).setManualLanguage(pre);
```

Each dropdown menu item renders the language's `nativeName` — never a translated label.

## SettingsScreen

`SettingsScreen` (`lib/features/settings/presentation/screens/settings_screen.dart`) renders a `Scaffold` with:

- An `AppBar` with the localized `settingsTitle` and a 1-px bottom `Divider`.
- A `ListView` body with two groups, each preceded by an uppercased `labelSmall` header in the primary colour:
  - **Appearance** — contains `ThemeSelector`
  - **Language** — contains `LanguageSelector`
- A back button provided automatically by Flutter (screen is pushed, not a tab).

## Routing

`SettingsScreen` is mounted at `/settings` as a sibling `GoRoute` outside `StatefulShellRoute.indexedStack` — it renders without the bottom navigation bar. Navigate to it with `context.push`:

```dart
context.push('/settings');
```

Use `push` (not `go`) to preserve the back stack. The entry point is `HomeScreen`'s gear `IconButton`.

## Persistence

Settings are stored in `SharedPreferencesWithCache` under four keys:

| Key | Type | Default |
|---|---|---|
| `themeMode` | `String` (`'light'` / `'dark'`) | `'light'` |
| `useSystemTheme` | `bool` | `true` |
| `useSystemLanguage` | `bool` | `true` |
| `manualLanguage` | `String` (IETF code, e.g. `'en'`) | `'en'` |

The `allowList` in `main()` is fixed to these four keys — no other preferences are accidentally cached.

## Localized strings

| ARB key | English |
|---|---|
| `settingsTitle` | Settings |
| `settingsTooltip` | Settings |
| `settingsAppearanceHeader` | Appearance |
| `settingsUseSystemTheme` | Use system theme |
| `settingsUseSystemThemeSub` | Follows your device light/dark setting |
| `settingsThemeLight` | Light |
| `settingsThemeDark` | Dark |
| `settingsLanguageHeader` | Language |
| `settingsUseDeviceLanguage` | Use device language |
| `settingsUseDeviceLanguageSub` | Follows your device language setting |

## Related

- [`../architecture.md`](../architecture.md) — Riverpod bootstrap, `sharedPreferencesProvider`, `Failure` hierarchy
- [`theme.md`](theme.md) — M3 theme tokens; `AppTheme.lightTheme` / `darkTheme`
- [`i18n.md`](i18n.md) — how to add or change localized strings
- [`home.md`](home.md) — `HomeScreen`, which hosts the gear icon entry point
- [`../../specs/009-theme-settings/spec.md`](../../specs/009-theme-settings/spec.md) — the spec that introduced the settings stack and theme control
- [`../../specs/010-language-settings/spec.md`](../../specs/010-language-settings/spec.md) — the spec that added the language control
