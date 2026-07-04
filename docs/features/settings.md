# Settings

## Overview

The **settings feature** owns the Settings screen — a push destination reached from the gear icon in the Today screen's `AppBar` (`TodayScreen`, `lib/features/meds/presentation/screens/today_screen.dart` — the placeholder `HomeScreen` that originally hosted this gear icon was retired in feature 038). It introduced the first full Clean Architecture stack in the project (domain + data + presentation) and brought Riverpod, `shared_preferences`, and `fpdart` into the codebase.

The feature exposes three groups of controls: **Appearance** (theme mode), **Language**, and **Intake**. The user can follow the device system theme or manually select Light or Dark, separately can follow the device language or pin the app to English, German, or Ukrainian, and can tune three intake-behaviour preferences (intake window, grace period, allow-mark-ahead).

> **Foundation only (feature 039)**: the three Intake preferences are stored and surfaced on the Settings screen, but as of feature 039 nothing in the app *reads* them yet — no auto-miss transition and no Today-screen enforcement exist. They become load-bearing in a future spec (auto-miss / Today redesign).

## How it works

### Domain

`AppSettings` (`lib/features/settings/domain/entities/app_settings.dart`) is a plain immutable value object with seven fields:

| Field | Default | Meaning |
|---|---|---|
| `useSystemTheme` | `true` | Follow the device theme when `true` |
| `manualThemeMode` | `AppThemeMode.light` | Override used when `useSystemTheme` is `false` |
| `useSystemLanguage` | `true` | Follow the device language when `true` |
| `manualLanguage` | `AppLanguage.en` | Override used when `useSystemLanguage` is `false` |
| `intakeWindow` | `IntakeWindow.defaultValue` (120 min) | How long an intake stays `pending` after its scheduled time before it would auto-transition to `missed`. Clamped 15–240 min. |
| `gracePeriod` | `GracePeriod.defaultValue` (5 min) | How long after marking an intake `taken` the user may undo it back to `pending`. Clamped 0–30 min. |
| `allowMarkAhead` | `false` | Whether the user may mark an intake `taken` before its scheduled time. |

`AppThemeMode` (`lib/features/settings/domain/entities/app_theme_mode.dart`) is a domain-owned enum with two values — `light` and `dark`. It intentionally has no `system` value: the "follow system" concept is owned by the orthogonal `useSystemTheme: bool` flag. Each value carries a stable `code` field (`'light'` / `'dark'`) used for string persistence, and a `fromCodeOrDefault` static helper provides graceful fallback for unknown or legacy data. It lives alongside `AppLanguage` for the same domain-purity reason: both replace Flutter SDK types (`ThemeMode`, `Locale`) that would otherwise violate constitution §2.1 in the domain layer.

### Value objects: `IntakeWindow` and `GracePeriod`

`IntakeWindow` and `GracePeriod` (`lib/features/settings/domain/value_objects/`) are hand-rolled, self-clamping value objects — not `freezed` classes. A `freezed` `@Default` value must be `const`, but a clamping smart constructor cannot be `const` (`int.clamp` is not a const operation), so each is a plain class with a private `const` constructor plus a public clamping `factory`:

```dart
// lib/features/settings/domain/value_objects/intake_window.dart
class IntakeWindow {
  const IntakeWindow._(this.minutes);

  factory IntakeWindow(int minutes) =>
      IntakeWindow._(minutes.clamp(minMinutes, maxMinutes));

  final int minutes;

  static const int minMinutes = 15;
  static const int maxMinutes = 240;
  static const IntakeWindow defaultValue = IntakeWindow._(120);
  // ...
}
```

`GracePeriod` mirrors the same shape with `minMinutes = 0`, `maxMinutes = 30`, and `defaultValue = GracePeriod._(5)`. Both:

- Clamp any constructed value into range, so an instance is **always valid by construction** — callers never need to validate a `minutes` value themselves.
- Expose `defaultValue` as a compile-time constant (via the private unclamped ctor), which is what lets `AppSettings`'s `@Default(IntakeWindow.defaultValue)` / `@Default(GracePeriod.defaultValue)` annotations compile.
- Implement value equality (`==`/`hashCode`) on `minutes`.

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

`SettingsRepository` (`lib/features/settings/domain/repositories/settings_repository.dart`) is the abstract contract consumed by the presentation layer. It exposes one synchronous read and seven async writes, all returning `Either<Failure, T>`:

- `load()` — synchronously reads all seven settings fields from the cache. Returns `Right(AppSettings)` on success, or `Left(Failure.unknown(error, stack))` if the cache read throws (e.g. a wrong-type stored value). Never throws.
- `saveThemeMode(AppThemeMode)` — persists the manual theme choice
- `saveUseSystemTheme(bool)` — persists the system-theme toggle
- `saveUseSystemLanguage(bool)` — persists the system-language toggle
- `saveManualLanguage(AppLanguage)` — persists the manual language choice
- `saveIntakeWindow(IntakeWindow)` — persists the intake-window choice (self-clamping, so the persisted value is always in range)
- `saveGracePeriod(GracePeriod)` — persists the grace-period choice (self-clamping)
- `saveAllowMarkAhead(bool)` — persists the allow-mark-ahead flag

### Use cases

Seven callable classes in `lib/features/settings/domain/usecases/`, each with a `const` constructor taking exactly one `SettingsRepository`. All live in pure-Dart `domain/` and return `Future<Either<Failure, void>>`. Each is exposed to the presentation layer via a `@riverpod` function provider in `settings_provider.dart`.

| Use case | File | Behaviour |
|---|---|---|
| `SetThemeMode` | `set_theme_mode.dart` | Persists the manual `AppThemeMode` via `SettingsRepository.saveThemeMode`. Pure pass-through. |
| `SetManualLanguage` | `set_manual_language.dart` | Persists the manual `AppLanguage` via `SettingsRepository.saveManualLanguage`. Pure pass-through. |
| `SetUseSystemTheme` | `set_use_system_theme.dart` | Atomic toggle. When `value=false`, pre-fills `manualThemeMode` with the resolved device brightness first (short-circuit on write failure), then persists the toggle. When `value=true`, only the toggle write fires — the stored manual override is left untouched. |
| `SetUseSystemLanguage` | `set_use_system_language.dart` | Symmetric atomic toggle for the language axis. Same two-write / short-circuit pattern with `AppLanguage`. |
| `SetIntakeWindow` | `set_intake_window.dart` | Persists the `IntakeWindow` via `SettingsRepository.saveIntakeWindow`. Pure pass-through. |
| `SetGracePeriod` | `set_grace_period.dart` | Persists the `GracePeriod` via `SettingsRepository.saveGracePeriod`. Pure pass-through. |
| `SetAllowMarkAhead` | `set_allow_mark_ahead.dart` | Persists the `bool` via `SettingsRepository.saveAllowMarkAhead`. Pure pass-through. |

### Data

`SettingsLocalDataSource` wraps `SharedPreferencesWithCache` — all reads are synchronous (cache hit), writes are async (flushes to platform storage).

The intake-behaviour getters route the raw stored `int` through the corresponding value object's clamping factory, so an out-of-range persisted value is **clamped on read** as well as on write:

```dart
// lib/features/settings/data/datasources/settings_local_data_source.dart
IntakeWindow getIntakeWindow() => IntakeWindow(
  _prefs.getInt(intakeWindowMinutesPrefsKey) ??
      IntakeWindow.defaultValue.minutes,
);

Future<void> setIntakeWindow(IntakeWindow value) =>
    _prefs.setInt(intakeWindowMinutesPrefsKey, value.minutes);
```

`getGracePeriod()`/`setGracePeriod()` follow the identical shape with `GracePeriod`. A missing key (never stored) falls back to `IntakeWindow.defaultValue`/`GracePeriod.defaultValue` before clamping; `getAllowMarkAhead()` defaults to `false` via `_prefs.getBool(...) ?? false`.

`SettingsRepositoryImpl` implements the contract: wraps `load()`'s seven-getter chain in a single `try/catch (e, st)` and all seven `save*` methods in their own `catch (e, st)` blocks. Any throwable — including `Error` subtypes such as `TypeError` that the platform bridge can raise on wrong-type cached values — is caught and returned as `Left(Failure.unknown(e, st))`. The raw exception message is never forwarded to `CacheFailure` (avoids a potential filesystem-path leak in the failure message — CWE-209).

### Presentation

`SettingsNotifier` (`lib/features/settings/presentation/providers/settings_provider.dart`) is a `Notifier<AppSettings>`. Its `build()` calls `repo.load()` synchronously and folds the `Either` result: on `Right(settings)` it returns those settings as the initial state; on `Left(failure)` it returns `const AppSettings()` (safe defaults from the entity's `@Default` annotations) and emits the `Failure` to the `_errors` broadcast stream. The controller is initialized in `build()` and closed via `ref.onDispose` when the notifier is disposed.

Note on startup emission: `build()` runs during notifier construction, before any UI subscriber can attach to `settingsErrorsProvider`. Because the controller is a broadcast stream, a `Left` emitted here is dropped rather than buffered. The observable guarantee is the safe-default state — the failure is not shown to the user at startup (this is accepted design per spec 022, OQ-2). Mutation methods follow the same optimistic pattern: in-memory state is only updated if persistence succeeds; on failure the `Failure` is emitted into the stream instead.

The notifier exposes seven public methods — `setThemeMode`, `setUseSystemTheme`, `setUseSystemLanguage`, `setManualLanguage`, `setIntakeWindow`, `setGracePeriod`, and `setAllowMarkAhead`. All seven delegate through use case providers (`setThemeModeProvider`, `setUseSystemThemeProvider`, `setIntakeWindowProvider`, etc.); `ref.read(settingsRepositoryProvider)` no longer appears in any mutator body. The three intake mutators follow the same optimistic pattern as the others — on success `state = state.copyWith(...)`, on failure only `_errors.add(failure)` fires:

```dart
// lib/features/settings/presentation/providers/settings_provider.dart
Future<void> setIntakeWindow(IntakeWindow window) async {
  final result = await ref.read(setIntakeWindowProvider).call(window);
  result.fold((failure) => _errors.add(failure), (_) {
    state = state.copyWith(intakeWindow: window);
  });
}
```

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

## IntakeSettingsControls widget

`IntakeSettingsControls` (`lib/features/settings/presentation/widgets/intake_settings_controls.dart`) is a `ConsumerWidget` composed of three controls, stacked in a `Column`:

1. A −/+ stepper row for **intake window** — steps by 15 minutes, disabled at the `IntakeWindow.minMinutes`/`maxMinutes` bounds (15/240).
2. A −/+ stepper row for **grace period** — steps by 5 minutes, disabled at the `GracePeriod.minMinutes`/`maxMinutes` bounds (0/30).
3. A `SwitchListTile` for **allow mark-ahead**.

Each stepper row is rendered by a private `_IntakeStepperTile` (title, subtitle, and a decrement/increment `IconButton` pair around a formatted value label). The widget narrow-watches each of the three `AppSettings` fields via `.select(...)` so it doesn't rebuild on unrelated theme/language changes, and increments/decrements by constructing a new value object through the notifier:

```dart
// lib/features/settings/presentation/widgets/intake_settings_controls.dart
final intakeWindow = ref.watch(
  settingsNotifierProvider.select((s) => s.intakeWindow),
);
// ...
onIncrement: () => notifier.setIntakeWindow(
  IntakeWindow(intakeWindow.minutes + _intakeWindowStepMinutes),
),
```

Because `IntakeWindow`/`GracePeriod` are self-clamping, incrementing past the max (or decrementing past the min) is also guarded proactively by disabling the button (`incrementEnabled`/`decrementEnabled`), rather than relying solely on the value object's clamp. Persistence failures are not shown by this widget itself — they surface through `SettingsScreen`'s `settingsErrorsProvider` listener, same as the other two sections.

## SettingsScreen

`SettingsScreen` (`lib/features/settings/presentation/screens/settings_screen.dart`) is a `ConsumerWidget` that renders a `Scaffold` with:

- An `AppBar` with the localized `settingsTitle` and a 1-px bottom `Divider`.
- A `ListView` body with three groups, each preceded by an uppercased `labelSmall` header in the primary colour (rendered by the private `_SectionHeader` widget):
  - **Appearance** — contains `ThemeSelector`
  - **Language** — contains `LanguageSelector`
  - **Intake** — contains `IntakeSettingsControls`
- A back button provided automatically by Flutter (screen is pushed, not a tab).
- A `ref.listen` call on `settingsErrorsProvider` that shows a localized M3 floating SnackBar (`context.l10n.settingsPersistenceError`) when a preference fails to persist.

## Routing

`SettingsScreen` is mounted at `/settings` as a sibling `GoRoute` outside `StatefulShellRoute.indexedStack` — it renders without the bottom navigation bar. Navigate to it with `context.push`:

```dart
context.push('/settings');
```

Use `push` (not `go`) to preserve the back stack. The entry point is `TodayScreen`'s gear `IconButton`.

## Persistence

Settings are stored in `SharedPreferencesWithCache` under seven keys:

| Key | Constant | Type | Default |
|---|---|---|---|
| `themeMode` | `themeModePrefsKey` | `String` (`'light'` / `'dark'`) | `'light'` |
| `useSystemTheme` | `useSystemThemePrefsKey` | `bool` | `true` |
| `useSystemLanguage` | `useSystemLanguagePrefsKey` | `bool` | `true` |
| `manualLanguage` | `manualLanguagePrefsKey` | `String` (IETF code, e.g. `'en'`) | `'en'` |
| `intakeWindowMinutes` | `intakeWindowMinutesPrefsKey` | `int` (minutes, clamped 15–240) | `120` |
| `gracePeriodMinutes` | `gracePeriodMinutesPrefsKey` | `int` (minutes, clamped 0–30) | `5` |
| `allowMarkAhead` | `allowMarkAheadPrefsKey` | `bool` | `false` |

The key string literals are defined once in `lib/core/providers/settings_prefs_keys.dart` (as `themeModePrefsKey`, `useSystemThemePrefsKey`, `useSystemLanguagePrefsKey`, `manualLanguagePrefsKey`, `intakeWindowMinutesPrefsKey`, `gracePeriodMinutesPrefsKey`, `allowMarkAheadPrefsKey`) and collected in the `settingsPrefsKeys` set. Both `shared_preferences_provider.dart`'s cache `allowList` and `settings_local_data_source.dart` derive from that set — no other preferences are accidentally cached, and a rename cannot silently split the two sites.

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
| `settingsIntakeHeader` | Intake |
| `settingsIntakeWindowLabel` | Intake window |
| `settingsIntakeWindowDescription` | How long after the scheduled time a dose can still be marked |
| `settingsGracePeriodLabel` | Grace period |
| `settingsGracePeriodDescription` | How long you can undo a dose after marking it |
| `settingsAllowMarkAheadLabel` | Allow marking ahead |
| `settingsAllowMarkAheadDescription` | Let doses be marked before their window opens |
| `settingsMinutesValue` | `{minutes} min` (ICU placeholder, `minutes: int`) |
| `settingsStepperIncreaseTooltip` | Increase |
| `settingsStepperDecreaseTooltip` | Decrease |

## Related

- [`../architecture.md`](../architecture.md) — Riverpod bootstrap, `sharedPreferencesProvider`, `Failure` hierarchy
- [`theme.md`](theme.md) — M3 theme tokens; `AppTheme.lightTheme` / `darkTheme`
- [`i18n.md`](i18n.md) — how to add or change localized strings
- [`home.md`](home.md) — `AppBottomNav`/`AppShell`, and where the Today screen (which now hosts the gear icon entry point) lives
- [`../../specs/009-theme-settings/spec.md`](../../specs/009-theme-settings/spec.md) — the spec that introduced the settings stack and theme control
- [`../../specs/010-language-settings/spec.md`](../../specs/010-language-settings/spec.md) — the spec that added the language control
- [`../../specs/014-surface-settings-errors/spec.md`](../../specs/014-surface-settings-errors/spec.md) — the spec that added the error-stream and SnackBar feedback
- [`../../specs/016-settings-usecases/spec.md`](../../specs/016-settings-usecases/spec.md) — the spec that introduced the use case layer, `CycleThemeMode`, and `AppLanguage.fromLanguageCodeOrDefault`
- [`../../specs/022-settings-error-containment/spec.md`](../../specs/022-settings-error-containment/spec.md) — the spec that changed `load()` to return `Either<Failure, AppSettings>` and hardened all `save*` catch blocks to `catch (e, st)`
- [`../../specs/039-intake-settings/spec.md`](../../specs/039-intake-settings/spec.md) — the spec that added `intakeWindow`, `gracePeriod`, `allowMarkAhead`, the `IntakeWindow`/`GracePeriod` value objects, and the Intake settings section (foundation only — not yet consumed by app behaviour)
