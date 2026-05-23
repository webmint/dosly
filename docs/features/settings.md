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

`AppSettings` intentionally exposes no Flutter SDK types — there are no `effectiveThemeMode` or `effectiveLocale` getters on the entity. Instead, `lib/app.dart` watches the four raw fields through separate narrow `ref.watch(settingsNotifierProvider.select(...))` calls and computes `MaterialApp.themeMode` and `locale` inline:

```dart
// lib/app.dart
final useSystemTheme = ref.watch(
  settingsNotifierProvider.select((s) => s.useSystemTheme),
);
final manualThemeMode = ref.watch(
  settingsNotifierProvider.select((s) => s.manualThemeMode),
);
final useSystemLanguage = ref.watch(
  settingsNotifierProvider.select((s) => s.useSystemLanguage),
);
final manualLanguage = ref.watch(
  settingsNotifierProvider.select((s) => s.manualLanguage),
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

### Use cases

Five callable classes in `lib/features/settings/domain/usecases/`, each with a `const` constructor taking exactly one `SettingsRepository`. All live in pure-Dart `domain/` and return `Future<Either<Failure, void>>` (except `CycleThemeMode` — see below). Each is exposed to the presentation layer via a `@riverpod` function provider in `settings_provider.dart`.

| Use case | File | Behaviour |
|---|---|---|
| `SetThemeMode` | `set_theme_mode.dart` | Persists the manual `AppThemeMode` via `SettingsRepository.saveThemeMode`. Pure pass-through. |
| `SetManualLanguage` | `set_manual_language.dart` | Persists the manual `AppLanguage` via `SettingsRepository.saveManualLanguage`. Pure pass-through. |
| `SetUseSystemTheme` | `set_use_system_theme.dart` | Atomic toggle. When `value=false`, pre-fills `manualThemeMode` with the resolved device brightness first (short-circuit on write failure), then persists the toggle. When `value=true`, only the toggle write fires — the stored manual override is left untouched. |
| `SetUseSystemLanguage` | `set_use_system_language.dart` | Symmetric atomic toggle for the language axis. Same two-write / short-circuit pattern with `AppLanguage`. |
| `CycleThemeMode` | `cycle_theme_mode.dart` | Encodes the `system → light → dark → system` cycle used by the Settings theme controls. Returns `Future<Either<Failure, ({bool useSystemTheme, AppThemeMode manualThemeMode})>>` — the `Right` carries the post-cycle state record so the notifier can apply `state.copyWith(...)` without re-deriving the cycle rule. Manual-dark-to-system-on intentionally preserves `manualThemeMode: dark` so the user's last manual choice survives the cycle. |

### Data

`SettingsLocalDataSource` wraps `SharedPreferencesWithCache` — all reads are synchronous (cache hit), writes are async (flushes to platform storage).

`SettingsRepositoryImpl` implements the contract: catches platform exceptions, converts them to `CacheFailure`, and wraps results in `Either`.

### Presentation

`SettingsNotifier` (`lib/features/settings/presentation/providers/settings_provider.dart`) is a `Notifier<AppSettings>`. Its `build()` loads the initial state synchronously from the repository cache and initializes a broadcast `StreamController<Failure>` for surfacing persistence errors. The controller is closed via `ref.onDispose` when the notifier is disposed. Mutation methods follow an optimistic pattern: in-memory state is only updated if persistence succeeds; on failure the `Failure` is emitted into the stream instead.

The notifier exposes five public methods — `setThemeMode`, `setUseSystemTheme`, `setUseSystemLanguage`, `setManualLanguage`, and `cycleThemeMode`. All four mutators delegate through use case providers (`setThemeModeProvider`, `setUseSystemThemeProvider`, etc.); `ref.read(settingsRepositoryProvider)` no longer appears in any mutator body.

```dart
Future<void> setUseSystemTheme(bool value, {required AppThemeMode currentDeviceMode}) async {
  final result = await ref.read(setUseSystemThemeProvider).call(
    value: value,
    currentDeviceMode: currentDeviceMode,
  );
  result.fold(
    (failure) => _errors.add(failure),
    (_) {
      if (!value) {
        state = state.copyWith(manualThemeMode: currentDeviceMode, useSystemTheme: false);
      } else {
        state = state.copyWith(useSystemTheme: true);
      }
    },
  );
}
```

A top-level `settingsErrorsProvider` (`StreamProvider<Failure>`) exposes the error stream to the widget tree. `SettingsScreen` listens to it via `ref.listen` and shows a localized M3 floating SnackBar (text from `context.l10n.settingsPersistenceError`) whenever a preference fails to persist.

`DoslyApp` in `lib/app.dart` watches `settingsNotifierProvider` with four narrow selectors so only the relevant field change triggers a root rebuild. See the [Presentation seam](#presentation-seam) section above for the full shape.

## ThemeSelector widget

`ThemeSelector` (`lib/features/settings/presentation/widgets/theme_selector.dart`) is a `ConsumerWidget` composed of two controls:

1. A `SwitchListTile` — "Use system theme" toggle. Default ON.
2. A full-width `SegmentedButton<AppThemeMode>` — Light / Dark. Disabled (but visually reflecting the current system brightness) while the toggle is ON.

On any toggle change, `ThemeSelector` resolves the device brightness once at the top of `build` (`MediaQuery.platformBrightnessOf(context)` → `AppThemeMode`) and passes the resolved value to `setUseSystemTheme(value, currentDeviceMode: deviceMode)`. The pre-fill rule lives entirely inside the `SetUseSystemTheme` use case — see the "Use cases" subsection above. When the user turns the toggle OFF, the use case persists the device-derived value as the manual override before flipping the toggle, atomically, in one notifier call.

## LanguageSelector widget

`LanguageSelector` (`lib/features/settings/presentation/widgets/language_selector.dart`) is a `ConsumerWidget` composed of two controls:

1. A `SwitchListTile` — "Use device language" toggle. Default ON.
2. A full-width `DropdownButton<AppLanguage>` populated from `AppLanguage.values`. Disabled (`onChanged: null`) while the toggle is ON, active when it is OFF.

`LanguageSelector` derives `deviceLanguage` once at the top of `build` via `AppLanguage.fromLanguageCodeOrDefault(Localizations.localeOf(context).languageCode)`, reusing it for the disabled-state display value AND the toggle callback. Toggling forwards `setUseSystemLanguage(value, currentDeviceLanguage: deviceLanguage)` — the pre-fill rule lives in `SetUseSystemLanguage`. `AppLanguage.fromLanguageCodeOrDefault` mirrors `AppThemeMode.fromCodeOrDefault`: it matches the language code against `AppLanguage.values` and falls back to `AppLanguage.en` for unknown codes.

Each dropdown menu item renders the language's `nativeName` — never a translated label.

## SettingsScreen

`SettingsScreen` (`lib/features/settings/presentation/screens/settings_screen.dart`) is a `ConsumerWidget` that renders a `Scaffold` with:

- An `AppBar` with the localized `settingsTitle` and a 1-px bottom `Divider`.
- A `ListView` body with two groups, each preceded by an uppercased `labelSmall` header in the primary colour:
  - **Appearance** — contains `ThemeSelector`
  - **Language** — contains `LanguageSelector`
- A back button provided automatically by Flutter (screen is pushed, not a tab).
- A `ref.listen` call on `settingsErrorsProvider` that shows a localized M3 floating SnackBar (`context.l10n.settingsPersistenceError`) when a preference fails to persist.

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
| `settingsPersistenceError` | Couldn't save your preference. Please try again. |

## Related

- [`../architecture.md`](../architecture.md) — Riverpod bootstrap, `sharedPreferencesProvider`, `Failure` hierarchy
- [`theme.md`](theme.md) — M3 theme tokens; `AppTheme.lightTheme` / `darkTheme`
- [`i18n.md`](i18n.md) — how to add or change localized strings
- [`home.md`](home.md) — `HomeScreen`, which hosts the gear icon entry point
- [`../../specs/009-theme-settings/spec.md`](../../specs/009-theme-settings/spec.md) — the spec that introduced the settings stack and theme control
- [`../../specs/010-language-settings/spec.md`](../../specs/010-language-settings/spec.md) — the spec that added the language control
- [`../../specs/014-surface-settings-errors/spec.md`](../../specs/014-surface-settings-errors/spec.md) — the spec that added the error-stream and SnackBar feedback
- [`../../specs/016-settings-usecases/spec.md`](../../specs/016-settings-usecases/spec.md) — the spec that introduced the use case layer, `CycleThemeMode`, and `AppLanguage.fromLanguageCodeOrDefault`
