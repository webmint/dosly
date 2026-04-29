# Spec: Language Settings

**Date**: 2026-04-27
**Status**: Complete
**Author**: Claude + Mykola

## 1. Overview

Add a language picker to the Settings screen so users can override the auto-detected device language. Until the user explicitly picks a language, the app continues to follow the device locale (with English as the fallback for unsupported locales — current behaviour). Once picked, the choice is persisted across restarts via the existing settings infrastructure built in spec 009.

The feature mirrors the theme-settings pattern (spec 009): a `SwitchListTile` toggles "use device language" mode, and a manual selector lists the three currently-supported languages (English, Deutsch, Українська) — the manual selector is disabled while the toggle is on. The `AppSettings` entity, `SettingsRepository`, Riverpod `settingsProvider`, and `SharedPreferencesWithCache`-backed persistence are extended in place.

## 2. Current State

### Settings infrastructure (built in spec 009)

- `lib/features/settings/domain/entities/app_settings.dart` — `AppSettings` value class with `useSystemTheme`, `manualThemeMode`, `effectiveThemeMode` getter, and `copyWith`.
- `lib/features/settings/domain/repositories/settings_repository.dart` — abstract `SettingsRepository` with `load()`, `saveThemeMode(...)`, `saveUseSystemTheme(...)`.
- `lib/features/settings/data/datasources/settings_local_data_source.dart` — `SettingsLocalDataSource` thin wrapper over `SharedPreferencesWithCache`. Keys `themeMode`, `useSystemTheme`.
- `lib/features/settings/data/repositories/settings_repository_impl.dart` — concrete implementation returning `Either<Failure, void>` from save methods.
- `lib/features/settings/presentation/providers/settings_provider.dart` — `settingsRepositoryProvider` + `settingsProvider` (`NotifierProvider<SettingsNotifier, AppSettings>`). On persistence failure, in-memory state is NOT updated and a `kDebugMode`-guarded `debugPrint` logs the failure.
- `lib/features/settings/presentation/screens/settings_screen.dart` — renders an "Appearance" group header (`labelSmall`, `primary` colour, uppercased) and the `ThemeSelector` widget.
- `lib/features/settings/presentation/widgets/theme_selector.dart` — `SwitchListTile("Use system theme")` + 2-segment `SegmentedButton<ThemeMode>` for Light/Dark, full-width, manual selector disabled when system toggle is on.
- `lib/main.dart` — `WidgetsFlutterBinding.ensureInitialized()` + blocking `SharedPreferencesWithCache.create(allowList: {'themeMode', 'useSystemTheme'})` before `runApp(...)`.
- `lib/core/providers/shared_preferences_provider.dart` — `Provider<SharedPreferencesWithCache>` with throwing placeholder; overridden in `main()` via `ProviderScope.overrides`.

### Localization (built in spec 006)

- `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` — three template/translation files, ten keys today (`settingsTooltip`, `settingsTitle`, `bottomNavToday`, `bottomNavMeds`, `bottomNavHistory`, `settingsAppearanceHeader`, `settingsUseSystemTheme`, `settingsUseSystemThemeSub`, `settingsThemeLight`, `settingsThemeDark`). Generated `AppLocalizations` lives at `lib/l10n/app_localizations.dart` (committed — `synthetic-package: false` is the modern default).
- `lib/l10n/l10n_extensions.dart` — `BuildContext.l10n` getter is the **single sanctioned `!` site** for `AppLocalizations.of(context)!`. All consumer widgets call `context.l10n.xxx`.
- `lib/app.dart` — `MaterialApp.router` is configured with `localizationsDelegates: AppLocalizations.localizationsDelegates`, `supportedLocales: AppLocalizations.supportedLocales`, and `localeResolutionCallback: _resolveLocale`. The callback matches the device locale by `languageCode` and explicitly falls back to `Locale('en')` for unsupported locales (works around gen_l10n's alphabetical `supportedLocales` ordering — see spec 006 §3.2). **No `locale:` parameter is currently set on `MaterialApp.router`.**

### What's missing

There is no UI to override the device-resolved locale, no persistence of a user-selected language, and no `locale:` parameter on `MaterialApp.router`. Setting `MaterialApp.locale` to a non-null value bypasses the resolution callback entirely — this is the standard Flutter mechanism for a user-selected language.

### Constitution constraints relevant to this feature

- **§2.1 Layer Boundaries**: language is a presentation concern — `Locale` and any `AppLanguage`-shaped enum live in `domain/` only as plain Dart types (no Flutter imports). Today the existing `AppSettings` entity DOES import `package:flutter/material.dart` for `ThemeMode` (this is a known accepted compromise in the current `domain/` layer — `ThemeMode` is technically a Flutter type but is treated as a plain enum). The new language enum will follow the same pattern: a pure Dart `enum AppLanguage { en, de, uk }` with no Flutter imports. `Locale`-construction lives in the presentation layer (in `app.dart` and the selector widget).
- **§3.1 Type Safety**: no `dynamic`, no `!`, no unchecked casts. The existing `context.l10n` extension covers the only sanctioned `!` site.
- **§3.2 Error Handling**: `Either<Failure, T>` at every repository boundary. New persistence methods follow the `saveThemeMode` precedent.
- **§4.1.1**: `@riverpod` codegen is preferred but spec 009 deliberately deferred codegen and uses hand-written `Provider`/`NotifierProvider` declarations. This spec follows that decision (no codegen introduced here).
- **§4.2.1**: no `print()`/`debugPrint()` outside the typed logger, except the existing `kDebugMode`-guarded `debugPrint` in `SettingsNotifier` for persistence failures. New persistence methods use the same pattern.

## 3. Desired Behavior

### 3.1 Domain extension — `AppSettings`

`AppSettings` (`lib/features/settings/domain/entities/app_settings.dart`) gains two new fields and one new getter:

- `useSystemLanguage: bool` — default `true`. When `true`, the app follows the device locale (resolved through the existing `localeResolutionCallback`).
- `manualLanguage: AppLanguage` — default `AppLanguage.en`. Only consulted when `useSystemLanguage` is `false`.
- `effectiveLocale: Locale?` getter — returns `null` when `useSystemLanguage` is `true` (so `MaterialApp.locale` stays `null` and the resolution callback fires); returns `Locale(manualLanguage.code)` otherwise.

A new `AppLanguage` enum (`lib/features/settings/domain/entities/app_language.dart`) lists the three currently-supported options with their language codes:

```dart
enum AppLanguage {
  en('en'),
  de('de'),
  uk('uk');

  const AppLanguage(this.code);
  final String code;
}
```

The enum lives in `domain/entities/` as a plain Dart enum (no Flutter imports). The mapping to `Locale` is done in the presentation layer because `Locale` is a Flutter type.

`copyWith` is extended to accept the two new fields (nullable parameters, fall through to current value when omitted — same pattern as theme fields).

### 3.2 Persistence — data source + repository

`SettingsLocalDataSource` gains four new methods, mirroring the theme pattern exactly:

- `bool getUseSystemLanguage()` — reads bool key `useSystemLanguage`, defaults to `true` when missing.
- `AppLanguage getManualLanguage()` — reads string key `manualLanguage`, parses by `code`, falls back to `AppLanguage.en` when missing or invalid.
- `Future<void> setUseSystemLanguage(bool)` — writes bool key `useSystemLanguage`.
- `Future<void> setManualLanguage(AppLanguage)` — writes string key `manualLanguage` as the enum's `code`.

The persistence keys (`useSystemLanguage`, `manualLanguage`) are added to the `allowList` set passed to `SharedPreferencesWithCache.create(...)` in `lib/main.dart`. The set becomes `{'themeMode', 'useSystemTheme', 'useSystemLanguage', 'manualLanguage'}`.

`SettingsRepository` gains two new abstract methods:

- `Future<Either<Failure, void>> saveUseSystemLanguage(bool value)`
- `Future<Either<Failure, void>> saveManualLanguage(AppLanguage language)`

`SettingsRepository.load()` is extended to read the two new keys and populate the new `AppSettings` fields.

`SettingsRepositoryImpl` implements both new methods exactly like `saveThemeMode` / `saveUseSystemTheme` — try/catch, return `Right(null)` on success or `Left(CacheFailure(e.toString()))` on `Exception`.

### 3.3 State — Riverpod notifier

`SettingsNotifier` (`settings_provider.dart`) gains two new methods:

- `Future<void> setUseSystemLanguage(bool value)` — calls `repo.saveUseSystemLanguage(value)`, on success updates `state = state.copyWith(useSystemLanguage: value)`. On failure logs via the existing `kDebugMode`-guarded `debugPrint` and leaves state unchanged.
- `Future<void> setManualLanguage(AppLanguage language)` — same pattern.

### 3.4 App wiring — `MaterialApp.router`

`lib/app.dart`'s `DoslyApp.build` adds a `locale:` parameter to `MaterialApp.router`:

```dart
locale: ref.watch(settingsProvider.select((s) => s.effectiveLocale)),
```

When `useSystemLanguage` is `true`, `effectiveLocale` returns `null` and `MaterialApp` falls through to the existing `localeResolutionCallback` (device-locale-based). When `useSystemLanguage` is `false`, `effectiveLocale` returns a `Locale` for the manual choice, `MaterialApp` honours it directly, and `localeResolutionCallback` is bypassed (Flutter's documented behaviour).

The `localeResolutionCallback` is **kept as-is** — it still serves device-locale resolution when no manual language is selected.

### 3.5 UI — `LanguageSelector` widget

A new widget `LanguageSelector` lives at `lib/features/settings/presentation/widgets/language_selector.dart`, mirroring `ThemeSelector`'s structure:

- `SwitchListTile`:
  - title: `context.l10n.settingsUseDeviceLanguage`
  - subtitle: `context.l10n.settingsUseDeviceLanguageSub`
  - value: `settings.useSystemLanguage`
  - onChanged: `(v) => ref.read(settingsProvider.notifier).setUseSystemLanguage(v)` — no pre-fill from device locale (different from `ThemeSelector` because the manual default `AppLanguage.en` is meaningful, while there is no neutral "manual" theme value).
  - `contentPadding: EdgeInsets.zero` (parent `Padding` provides the 16-px inset).
- A vertical list of three `RadioListTile<AppLanguage>` rows, one per `AppLanguage` value:
  - Title text uses **native names** rendered as plain literals (NOT translated): `'English'`, `'Deutsch'`, `'Українська'`. Native names are the universal convention for language pickers — they let users find their language regardless of the currently-displayed UI language. This is the Flutter team's documented recommendation.
  - `groupValue: settings.manualLanguage`
  - `onChanged`: when `useSystemLanguage` is `true`, set to `null` (disabled, but the current selection is still shown). When `false`: `(language) => ref.read(settingsProvider.notifier).setManualLanguage(language)`.
  - `contentPadding: EdgeInsets.zero` (consistency with the SwitchListTile).

The widget is a `ConsumerWidget` (consistent with `ThemeSelector`).

**Why a radio list instead of a `SegmentedButton`?** Three multi-character language names (especially Ukrainian's "Українська" at 10 characters and German's "Deutsch" at 7) plus the constraint of equal-width segments would overflow on narrow screens. A radio list scales cleanly to 4+ languages when more are added later. This also reads more naturally as "a list" per the user's phrasing.

### 3.6 UI — Settings screen layout

`SettingsScreen` (`settings_screen.dart`) gains a second section below the Appearance section, identical in shape:

- A `Padding` row with the section header label (uppercased, `labelSmall`, `primary` colour, `letterSpacing: 0.5`, `fontWeight: w500`) reading `context.l10n.settingsLanguageHeader`.
- A `Padding` row hosting the `LanguageSelector` widget.

Padding values match the Appearance section (`fromLTRB(16, 16, 16, 6)` for the header, `symmetric(horizontal: 16)` for the selector body). Both sections sit inside the existing `ListView`.

### 3.7 Localization

Three new keys are added to all three ARB files. The generated `AppLocalizations` is regenerated (committed — `synthetic-package: false`). Native language names ARE NOT translated — they are literal strings inside `LanguageSelector`.

| Key | English | German | Ukrainian |
|---|---|---|---|
| `settingsLanguageHeader` | `Language` | `Sprache` | `Мова` |
| `settingsUseDeviceLanguage` | `Use device language` | `Sprache des Geräts verwenden` | `Мова пристрою` |
| `settingsUseDeviceLanguageSub` | `Follow your device settings` | `Geräteeinstellungen folgen` | `Використовувати налаштування пристрою` |

**Translation notes**:
- English `Use device language` and Ukrainian `Мова пристрою` are intentionally compact (the SwitchListTile title gets crowded next to the toggle on small screens). German has historically run long (`Medikamente` overflow risk noted in spec 006); `Sprache des Geräts verwenden` is acceptable but should be sanity-checked at AC-13-equivalent manual verification.
- The German subtitle `Geräteeinstellungen folgen` reuses the existing translation pattern from `settingsUseSystemThemeSub` for consistency.
- The user is fluent in Ukrainian and will verify `app_uk.arb` at review time. German strings are accepted as-provided unless flagged.

## 4. Affected Areas

| Area | Files | Impact |
|---|---|---|
| Domain — language enum | `lib/features/settings/domain/entities/app_language.dart` | **Create new** — `AppLanguage` enum with `code` field |
| Domain — entity | `lib/features/settings/domain/entities/app_settings.dart` | Extend — add `useSystemLanguage`, `manualLanguage`, `effectiveLocale` getter; extend `copyWith` |
| Domain — repository contract | `lib/features/settings/domain/repositories/settings_repository.dart` | Extend — add `saveUseSystemLanguage`, `saveManualLanguage` |
| Data — local data source | `lib/features/settings/data/datasources/settings_local_data_source.dart` | Extend — add `getUseSystemLanguage`, `getManualLanguage`, `setUseSystemLanguage`, `setManualLanguage`; add two key constants |
| Data — repository impl | `lib/features/settings/data/repositories/settings_repository_impl.dart` | Extend — implement two new save methods; extend `load()` to populate new fields |
| Presentation — provider | `lib/features/settings/presentation/providers/settings_provider.dart` | Extend `SettingsNotifier` — add `setUseSystemLanguage`, `setManualLanguage` |
| Presentation — selector widget | `lib/features/settings/presentation/widgets/language_selector.dart` | **Create new** — Switch + RadioListTile list |
| Presentation — screen | `lib/features/settings/presentation/screens/settings_screen.dart` | Extend — add Language section below Appearance |
| App root | `lib/app.dart` | Add `locale:` parameter to `MaterialApp.router` |
| App entry | `lib/main.dart` | Add `useSystemLanguage` and `manualLanguage` to `SharedPreferencesWithCache.create(allowList: ...)` |
| Localization — ARB | `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` | Add three new keys (`settingsLanguageHeader`, `settingsUseDeviceLanguage`, `settingsUseDeviceLanguageSub`) — `@key` metadata in `app_en.arb` only |
| Localization — generated | `lib/l10n/app_localizations.dart`, `app_localizations_{en,de,uk}.dart` | Auto-regenerate via `flutter gen-l10n` (committed per `synthetic-package: false` decision) |
| Tests — data source | `test/features/settings/data/datasources/settings_local_data_source_test.dart` | Extend — cases for new getters/setters and default fallbacks |
| Tests — repository | `test/features/settings/data/repositories/settings_repository_impl_test.dart` | Extend — happy path + failure path for two new save methods + load() with new fields |
| Tests — provider | `test/features/settings/presentation/providers/settings_provider_test.dart` | Extend — set/persist/state-mutation tests for two new methods + failure-leaves-state-unchanged |
| Tests — language selector | `test/features/settings/presentation/widgets/language_selector_test.dart` | **Create new** — switch behaviour, radio selection, disabled-when-system-on, native-name labels |
| Tests — settings screen | `test/features/settings/presentation/screens/settings_screen_test.dart` | Extend — assert Language section header is rendered alongside Appearance |
| Tests — app | `test/app_test.dart` (or wherever `MaterialApp.locale` reactivity is asserted) | **Create or extend** — verify `MaterialApp.locale` reacts to `effectiveLocale` changes via `settingsProvider` |
| Documentation | `docs/features/settings.md`, `docs/features/i18n.md` (if exists) | Updated by `tech-writer` during `/finalize`, NOT in this spec's scope |

## 5. Acceptance Criteria

Each criterion is testable and unambiguous.

- [x] **AC-1**: `AppLanguage` enum exists at `lib/features/settings/domain/entities/app_language.dart` with three values (`en`, `de`, `uk`), each carrying its `code` string. The file imports nothing from `package:flutter/*`.
- [x] **AC-2**: `AppSettings` exposes `useSystemLanguage: bool` (default `true`), `manualLanguage: AppLanguage` (default `AppLanguage.en`), and `Locale? effectiveLocale` (returns `null` when `useSystemLanguage` is `true`, otherwise `Locale(manualLanguage.code)`). `copyWith` accepts both new fields.
- [x] **AC-3**: `SettingsRepository` declares `saveUseSystemLanguage(bool)` and `saveManualLanguage(AppLanguage)`, both returning `Future<Either<Failure, void>>`. `load()` returns an `AppSettings` with the persisted language fields populated (or defaults if absent).
- [x] **AC-4**: `SettingsLocalDataSource` reads/writes `useSystemLanguage` (bool key) and `manualLanguage` (string key, value = `AppLanguage.code`). `getUseSystemLanguage` defaults to `true`. `getManualLanguage` defaults to `AppLanguage.en` when the stored value is missing or doesn't match a known code.
- [x] **AC-5**: `SharedPreferencesWithCache.create(...)` in `main.dart` includes `useSystemLanguage` and `manualLanguage` in its `allowList`.
- [x] **AC-6**: `SettingsNotifier` exposes `setUseSystemLanguage(bool)` and `setManualLanguage(AppLanguage)`. On persistence success, state is updated via `copyWith`. On `CacheFailure`, in-memory state is **not** updated and a `kDebugMode`-guarded `debugPrint` logs the failure (matches the existing `setThemeMode` / `setUseSystemTheme` precedent).
- [x] **AC-7**: `MaterialApp.router` in `lib/app.dart` is configured with `locale: ref.watch(settingsProvider.select((s) => s.effectiveLocale))`. When the user has `useSystemLanguage: true`, `MaterialApp.locale` is `null` and `localeResolutionCallback` resolves the device locale (existing behaviour preserved). When `useSystemLanguage: false`, `MaterialApp.locale` is a non-null `Locale` and the manual choice wins.
- [x] **AC-8**: A new `LanguageSelector` widget is rendered on the Settings screen below the Appearance section. It contains:
  - A `SwitchListTile` whose title and subtitle are localized (`settingsUseDeviceLanguage`, `settingsUseDeviceLanguageSub`) and whose value is bound to `settings.useSystemLanguage`.
  - Three `RadioListTile<AppLanguage>` rows whose titles are the literal native names `English`, `Deutsch`, `Українська` (NOT localized).
  - When `useSystemLanguage` is `true`, the radio rows have `onChanged: null` (disabled) but `groupValue` still shows the current `manualLanguage`.
  - When `useSystemLanguage` is `false`, tapping a radio row calls `settingsProvider.notifier.setManualLanguage(...)`.
- [x] **AC-9**: The Settings screen renders a "Language" section header above the `LanguageSelector`, styled identically to the existing Appearance header (`labelSmall`, `primary`, `letterSpacing: 0.5`, `fontWeight: w500`, uppercased) and reading `context.l10n.settingsLanguageHeader`.
- [x] **AC-10**: All three ARB files contain the keys `settingsLanguageHeader`, `settingsUseDeviceLanguage`, `settingsUseDeviceLanguageSub` with the translations specified in §3.7. `app_en.arb` includes `@key` metadata for each new key. The generated `AppLocalizations` exposes corresponding getters.
- [x] **AC-11**: A widget test for `LanguageSelector` proves:
  - With `useSystemLanguage: true`, all three radio rows are disabled (rendered but non-interactive) and the `groupValue` matches the current `manualLanguage`.
  - With `useSystemLanguage: false`, tapping a radio row triggers `setManualLanguage` with the correct enum value.
  - Toggling the switch triggers `setUseSystemLanguage`.
  - The native name strings `English`, `Deutsch`, `Українська` render exactly once each, regardless of the active locale.
- [x] **AC-12**: A widget/integration test proves `MaterialApp.locale` reacts to `settingsProvider`:
  - Pumping the app with `useSystemLanguage: false`, `manualLanguage: de` results in `MaterialApp.locale == Locale('de')`.
  - Calling `settingsProvider.notifier.setManualLanguage(AppLanguage.uk)` causes `MaterialApp.locale` to become `Locale('uk')` after the next pump.
  - Calling `setUseSystemLanguage(true)` causes `MaterialApp.locale` to become `null`.
- [x] **AC-13**: All existing tests continue to pass unchanged. (Spec 009 left the suite at 117/117 — the new feature must not regress that.)
- [x] **AC-14**: The selected language is persisted across app restarts: a test that writes to `SharedPreferencesWithCache`, recreates the cache, and rebuilds `SettingsRepositoryImpl` reads back the same `useSystemLanguage` + `manualLanguage` values.
- [x] **AC-15**: `dart analyze` produces zero warnings or errors on all new and modified files.
- [x] **AC-16**: `flutter test` passes (existing 117 + new tests).
- [x] **AC-17**: `flutter build apk --debug` succeeds.
- [x] **AC-18**: Manual on-device verification (deferred to user, post-merge): with the app running and `useSystemLanguage` toggled off, picking each of English / Deutsch / Українська from the list updates the entire UI (AppBar titles, bottom-nav labels, settings strings) immediately and persists across a full app restart. With `useSystemLanguage` toggled back on, the UI reverts to the device-locale-resolved language.

## 6. Out of Scope

- **NOT included**: A "follow first day of week" / regional formatting override. Locale-aware date/number formatting will arrive with the schedule/intake screens that need it.
- **NOT included**: Adding additional locales beyond `en`, `de`, `uk`. Adding a new locale = new spec (new ARB file + translation pass + new `AppLanguage` enum value).
- **NOT included**: A flag / banner that surfaces when the device locale changes mid-session while `useSystemLanguage` is `true`. Flutter handles the locale change automatically via `MaterialApp`'s rebuild — no custom UI needed.
- **NOT included**: Splash-screen language detection or first-run language onboarding. The default `useSystemLanguage: true` path covers the cold-start experience automatically.
- **NOT included**: Documentation updates (`docs/`) — produced by `tech-writer` during `/finalize`, not part of this spec.
- **NOT included**: Renaming, refactoring, or restructuring any spec-009 code that this spec touches. Extensions only — no behaviour-preserving rewrites.
- **NOT included**: Changes to `localeResolutionCallback`. Its existing behaviour (match by `languageCode`, fall back to `Locale('en')`) is correct and stays as-is.
- **NOT included**: A "system" option inside the radio list. The "use device language" toggle is the gateway to system-language mode — having both a toggle and a fourth "System" radio option would duplicate the same control. The toggle wins for UX clarity (matches `ThemeSelector` precedent).
- **NOT included**: Native script in any UI strings other than the language names themselves. Section headers and switch labels are translated normally.
- **NOT included**: Notification-text translation tied to manual language selection. (Constitution §5.2 says notification text is the generic "Time for your medication" string; not implemented yet, doubly out of scope.)
- **NOT included**: Persisting `effectiveLocale` directly. The persistence layer stores the user's *intent* (`useSystemLanguage` flag + `manualLanguage` enum); `effectiveLocale` is a derived getter computed at read time.
- **NOT included**: A `LocaleResolverService` or other generic locale-handling abstraction. Existing pattern (typed enum + `effectiveLocale` getter on settings) is sufficient — KISS over speculative abstraction (constitution §3.6).

## 7. Technical Constraints

- **MUST extend**, not replace, the spec-009 `AppSettings` / `SettingsRepository` / `SettingsNotifier` infrastructure. The single-source-of-truth design from spec 009 §AC-6 is the entire reason new settings should require only model extension, not parallel plumbing.
- **MUST follow** Clean Architecture (constitution §2.1): `AppLanguage` enum lives in `domain/entities/` with no Flutter imports. `Locale` construction (a Flutter type) happens in the presentation layer (in `app.dart` and inside the `effectiveLocale` getter — note: `Locale` is from `dart:ui` and is technically importable in domain code, BUT to keep the domain layer aligned with constitution §2.1's spirit, `effectiveLocale` will be defined to return `Locale?` from a domain entity that imports `package:flutter/material.dart` only because the existing `AppSettings` already does so for `ThemeMode`. No new Flutter imports introduced — this is a pre-existing accepted compromise that this spec does not deepen).
- **MUST follow** Either/Failure pattern (constitution §3.2) for new repository methods. Same try/catch + `CacheFailure(e.toString())` shape as `saveThemeMode`.
- **MUST NOT introduce** any new `!` null-assertion sites. The existing `context.l10n` extension covers all `AppLocalizations.of` access.
- **MUST NOT introduce** any new `print()` / `debugPrint()` outside the existing `kDebugMode`-guarded log line in `SettingsNotifier`. Reuse the same shape for both new methods.
- **MUST persist** via the existing `SharedPreferencesWithCache` instance. Keys must be added to `allowList` in `main.dart` (an explicit safety check — keys not in the allowList are not cached and `getX()` calls would throw at runtime).
- **MUST keep** `localeResolutionCallback` unchanged. Adding `locale:` does NOT remove or modify the existing fallback chain.
- **MUST NOT** add `shared_preferences` as a new dependency — it's already in `pubspec.yaml` from spec 009.
- **MUST keep** `dart analyze` clean under the project's strict-mode `analysis_options.yaml`.
- **MUST keep** the existing 117 tests green.
- **MUST commit** the regenerated `AppLocalizations` files (`synthetic-package: false` decision from spec 006).
- **SHOULD use** `@key` metadata in `app_en.arb` for each new key, consistent with existing keys.
- **SHOULD render** native language names as plain literals — not translations. (This follows the universal language-picker convention; documented in §3.5 and §3.7.)

## 8. Open Questions

- **Q1**: Should the `LanguageSelector` use `RadioListTile` (selected via radio dot) or `ListTile` with a leading check icon (M3-flavoured style)? Both are acceptable; `RadioListTile` is more semantically correct for a single-selection list and is what Flutter's design samples use. **Suggested resolution**: Use `RadioListTile<AppLanguage>` for AC-11 testability (radio state is a first-class widget property). Not blocking.
- **Q2**: When the user toggles "Use device language" OFF after never having picked a manual language, what does the manual selector show? `manualLanguage` defaults to `AppLanguage.en`, so the English row will appear selected. This may be surprising if the device locale is German and the user just sees "English now selected" the moment they toggle off. **Suggested resolution**: Pre-fill `manualLanguage` with the current `Localizations.localeOf(context).languageCode` (mapped to `AppLanguage` if supported, else fallback to `en`) at the moment of the toggle-OFF — same shape as `ThemeSelector`'s "pre-fill from system brightness" trick. Confirm at plan time.
- **Q3**: Should the "Language" section appear above or below the "Appearance" section? Two reasonable placements; user preference. **Suggested resolution**: BELOW Appearance (spec 009 ships first; preserves visual continuity for users who already know Appearance). Not blocking.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| `Українська` (10 chars) overflows `RadioListTile` title on the smallest supported device width | Low | Low | RadioListTile uses `ListTile` defaults — wraps to a second line if needed. Visual only, no crash. AC-18 manual verification will catch any wrapping that looks wrong. |
| Setting `MaterialApp.locale` causes a full widget tree rebuild that resets navigation state | Low | Medium | Mirror precedent: spec 009 (theme switch) drives a similar full-tree rebuild via `themeMode:` and there was no nav-stack reset. `GoRouter`'s top-level instance survives `MaterialApp` rebuilds (memory note: "MEMORY.md → Feature 002 — `ListenableBuilder` + `MaterialApp.router` + top-level `GoRouter` constant coexist cleanly"). The same property holds for `locale:` changes. |
| Stored `manualLanguage` value becomes invalid (e.g., user downgrades app and `uk` is removed) | Very Low | Low | `getManualLanguage()` defaults to `AppLanguage.en` when the stored code doesn't match a known enum value. No crash. |
| Extending `allowList` in `main.dart` without bumping a SharedPreferences cache version causes a stale cache miss | Very Low | Low | `SharedPreferencesWithCache` rebuilds the in-memory cache on each `create(...)` call from disk-backed values. Adding keys to the allowList simply causes them to be loaded on next `create`. No migration required. |
| German `Sprache des Geräts verwenden` (24 chars) overflows the `SwitchListTile` title at narrow widths | Medium | Low | Visual only. AC-18 manual verification on a small phone will surface any overflow. If it overflows, follow-up shortens to `Geräte-Sprache` (12 chars). Not blocking. |
| `Locale` construction in the `effectiveLocale` getter inside the domain entity | Low | Low | The existing `AppSettings` already imports `package:flutter/material.dart` for `ThemeMode`. Adding a `Locale` reference does not deepen that compromise — `Locale` is from `dart:ui`, but `material.dart` re-exports it. No new layer-boundary violation. Documented in §7. |
| User picks a language, then later expects the device-language toggle to "remember" their manual pick | Low | Low | The persistence model already does this — `useSystemLanguage` and `manualLanguage` are independent fields. Toggling system on does NOT erase the manual choice. |
