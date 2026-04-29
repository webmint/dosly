# Plan: Language Settings

**Date**: 2026-04-27
**Spec**: [spec.md](spec.md)
**Status**: Draft

## Summary

Extend the spec-009 settings infrastructure (`AppSettings` + `SettingsRepository` + Riverpod `settingsProvider` + `SharedPreferencesWithCache`) with two new fields — `useSystemLanguage: bool` (default `true`) and `manualLanguage: AppLanguage` (default `AppLanguage.en`). Wire `MaterialApp.locale` to a derived `effectiveLocale` getter so the manual choice (when active) overrides the existing `localeResolutionCallback`-based device-locale resolution. UI is a new `LanguageSelector` widget (Switch + 3 RadioListTile rows with native names) rendered as a "Language" section beneath "Appearance" on the Settings screen.

## Technical Context

**Architecture**: Clean Architecture (constitution §2.1). Domain (`AppLanguage` enum, `AppSettings` extension, repository contract) — no new Flutter imports. Data (`SettingsLocalDataSource` + `SettingsRepositoryImpl` extension) — wraps `SharedPreferencesWithCache`. Presentation (Riverpod `SettingsNotifier` extension, `LanguageSelector` widget, `SettingsScreen` extension, `MaterialApp.locale` wiring in `app.dart`).
**Error Handling**: `Either<Failure, void>` from `fpdart` for the two new save methods. `CacheFailure(e.toString())` on caught `Exception` — exact shape mirrors `saveThemeMode` / `saveUseSystemTheme`. On persistence failure the notifier logs via the existing `kDebugMode`-guarded `debugPrint` and leaves in-memory state unchanged.
**State Management**: Riverpod (`Provider<SettingsRepository>` + `NotifierProvider<SettingsNotifier, AppSettings>`) — same hand-written declarations as spec 009 (no codegen, no `freezed`). `MaterialApp.router` reads `effectiveLocale` via `ref.watch(settingsProvider.select((s) => s.effectiveLocale))` — `select` keeps the rebuild scope tight (no rebuild when only `themeMode` changes).
**Localization**: Three new ARB keys across `app_en.arb` / `app_de.arb` / `app_uk.arb`. Native language names (`English` / `Deutsch` / `Українська`) are NOT translated — they live as a `nativeName` field on the `AppLanguage` enum so the widget reads them directly.

## Constitution Compliance

- **§2.1 Layer Boundaries** — `AppLanguage` is a pure-Dart enum with no Flutter imports. `AppSettings` already imports `package:flutter/material.dart` for `ThemeMode` (pre-existing accepted compromise from spec 009); adding the `Locale? effectiveLocale` getter does NOT deepen that — `Locale` is from `dart:ui`, re-exported by `material.dart`, no new package boundary crossed. Compliant.
- **§3.1 Type Safety** — No `dynamic`, no `!` outside the existing `context.l10n` extension, no unchecked casts. The `manualLanguage` enum is its own typed value; the data source parses the persisted string by matching against `AppLanguage.values` rather than `as`-casting. Compliant.
- **§3.2 Error Handling** — All new repository methods return `Future<Either<Failure, void>>`. Exceptions never escape the data layer. Notifier's `.fold` handles both branches. Compliant.
- **§4.1.1 (codegen preference)** — Spec 009 deliberately deferred `@riverpod` / `freezed` codegen; this plan continues that decision. No codegen introduced. Acceptable deviation already accepted at the project level.
- **§4.2.1 (no `print`/`debugPrint`)** — The single `kDebugMode`-guarded `debugPrint` site in `SettingsNotifier` is reused for both new methods. No new logging sites. Compliant.
- **§3.7 (search before build)** — `SettingsRepository`, `SettingsLocalDataSource`, `SettingsNotifier`, `LanguageSelector`-shaped widgets — none exist. The closest analogues (`ThemeSelector`, theme save methods) are reused as templates, not duplicated. Compliant.
- **§6.1 (minimal changes)** — All modifications are additive; no behaviour-preserving rewrites of spec-009 code, no signature changes on existing methods (`load()` keeps its signature; only the populated fields grow), no test reshuffling. Compliant.

## Implementation Approach

### Layer Map

| Layer | What | Files |
|---|---|---|
| Domain | `AppLanguage` enum (3 values, each with `code` + `nativeName`); `AppSettings` extended with `useSystemLanguage`, `manualLanguage`, `effectiveLocale` getter, extended `copyWith`; `SettingsRepository` extended with two `save…` methods | `lib/features/settings/domain/entities/app_language.dart` (NEW); `lib/features/settings/domain/entities/app_settings.dart` (MOD); `lib/features/settings/domain/repositories/settings_repository.dart` (MOD) |
| Data | `SettingsLocalDataSource` extended with 4 new methods + 2 key constants; `SettingsRepositoryImpl` extended with 2 new save methods + extended `load()` body | `lib/features/settings/data/datasources/settings_local_data_source.dart` (MOD); `lib/features/settings/data/repositories/settings_repository_impl.dart` (MOD) |
| Presentation | `SettingsNotifier` extended with 2 new methods; `LanguageSelector` widget (NEW); `SettingsScreen` body extended with the Language section; `MaterialApp.router.locale` wired to `effectiveLocale`; `main()` allowList extended | `lib/features/settings/presentation/providers/settings_provider.dart` (MOD); `lib/features/settings/presentation/widgets/language_selector.dart` (NEW); `lib/features/settings/presentation/screens/settings_screen.dart` (MOD); `lib/app.dart` (MOD); `lib/main.dart` (MOD) |
| l10n | 3 new ARB keys (en/de/uk) + `@key` metadata in en; regenerated `AppLocalizations` files | `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` (MOD); `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_de.dart`, `app_localizations_uk.dart` (REGEN, committed) |
| Tests | Extend repo test (data source defaults + 2 new save methods + extended load + extended round-trip); extend provider test (2 new methods × happy path + failure-leaves-state-unchanged); extend screen test (Language section header rendered); new `LanguageSelector` widget test; new `app_test.dart` for `MaterialApp.locale` reactivity | `test/features/settings/data/repositories/settings_repository_impl_test.dart` (MOD); `test/features/settings/presentation/providers/settings_provider_test.dart` (MOD); `test/features/settings/presentation/screens/settings_screen_test.dart` (MOD); `test/features/settings/presentation/widgets/language_selector_test.dart` (NEW); `test/app_test.dart` (NEW) |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|---|---|---|---|
| **D1: Native-name source** | Add `nativeName` field to `AppLanguage` enum (`en → 'English'`, `de → 'Deutsch'`, `uk → 'Українська'`) | Single source of truth; iterating `AppLanguage.values` in the widget is trivial; widget-side literals scattered across rows would be hard to keep in sync | Inline `Map<AppLanguage, String>` in widget (extra indirection); separate constants file (over-engineered for 3 values) |
| **D2: Locale construction site** | `effectiveLocale` getter on `AppSettings` returns `Locale?` (null when `useSystemLanguage`, else `Locale(manualLanguage.code)`) | Mirrors `effectiveThemeMode` precedent exactly; keeps `MaterialApp.locale` wiring trivial; `Locale` is from `dart:ui` — no new layer-boundary compromise beyond what spec 009 already accepted for `ThemeMode` | Construct `Locale` in `app.dart` (forces caller to know the mapping); store `Locale` directly in `AppSettings` (locale isn't serialisable as cleanly as a typed enum, harder to validate on read) |
| **D3: Manual-mode pre-fill at toggle-OFF** (spec Q2) | When `useSystemLanguage` flips OFF, `LanguageSelector` first calls `setManualLanguage(deviceMatch)` where `deviceMatch` = `AppLanguage` matching `Localizations.localeOf(context).languageCode` (or `AppLanguage.en` if unsupported), THEN calls `setUseSystemLanguage(false)` | User just saw the device-resolved UI; switching to manual should keep the same visible language as the starting selection — feels seamless. Mirrors `ThemeSelector`'s "pre-fill from `MediaQuery.platformBrightnessOf(context)`" precedent | Always default to `AppLanguage.en` at toggle-OFF (jarring if device was uk/de); leave the prior `manualLanguage` value (could be a stale "en" selection from a past session that no longer matches user expectation) |
| **D4: Manual selector control** (spec Q1) | `RadioListTile<AppLanguage>` × 3 rows | Semantically correct for single-selection; `onChanged: null` is the canonical "disabled" idiom (M3-aware); `groupValue` is testable as a first-class property | `SegmentedButton<AppLanguage>` (overflow risk for Cyrillic/German on narrow screens — see MEMORY.md `Medikamente` overflow note); custom `ListTile` with leading check icon (more code, less idiomatic, harder to test) |
| **D5: Section position** (spec Q3) | Below the existing "Appearance" section | Preserves visual continuity for users who already shipped under spec 009; "language" is a less-frequently-changed setting than theme | Above Appearance (would shift the existing UI users just saw); Sandwich within (over-thinking — they're peer concerns) |
| **D6: Persistence schema** | Two flat keys: `useSystemLanguage` (bool) and `manualLanguage` (string = enum's `code`). Both added to `SharedPreferencesWithCache.create(allowList:…)` set in `main.dart` | Mirrors `useSystemTheme` / `themeMode` exactly; keeps `SettingsLocalDataSource` symmetric (4 → 8 thin pass-throughs); strings survive enum reordering better than `index` | Persist `manualLanguage` as `index` (fragile if enum order ever changes); single combined JSON blob (over-engineered, harder to test, breaks the symmetric pattern) |
| **D7: Order of state mutations on toggle-OFF** | Pre-fill manual FIRST, then flip the system flag (matches `ThemeSelector` order) | Avoids a one-frame UI flicker where the manual selector momentarily reads the stale prior value before the pre-fill settles | Flip system flag first, then pre-fill (visible flicker); single combined `setLanguageSettings(...)` notifier method (forces a wider API change for a one-time UX nicety) |
| **D8: Save method state-update site** | `SettingsRepositoryImpl.saveX(...)` does NOT mutate any in-memory state; the Riverpod `SettingsNotifier` reads `Right(null)` from the fold and updates `state` itself | Matches spec 009's strict separation: repo persists, notifier owns reactive state. Keeps the repository pure from a UI perspective and predictable to test | Have the repo cache an in-memory `AppSettings` (duplicate state, sync hazard); push state updates inside the repo (couples persistence to UI reactivity) |
| **D9: Test for `MaterialApp.locale` reactivity** | New `test/app_test.dart` pumps `DoslyApp` inside a `ProviderScope` that overrides `sharedPreferencesProvider` (with `InMemorySharedPreferencesAsync`) and asserts `MaterialApp.locale` after toggling `settingsProvider` notifier methods | Exercises the actual `app.dart` wiring; can verify both null-locale (use device) and non-null cases without launching a device | Pure unit test on the `select` callback (doesn't catch wiring mistakes); full integration test via `flutter_driver` (overkill for a wiring assertion) |

### File Impact

| File | Action | What Changes |
|---|---|---|
| `lib/features/settings/domain/entities/app_language.dart` | **Create** | `enum AppLanguage { en('en', 'English'), de('de', 'Deutsch'), uk('uk', 'Українська') }` with `final String code` + `final String nativeName`. No Flutter imports. |
| `lib/features/settings/domain/entities/app_settings.dart` | Modify | Add `final bool useSystemLanguage` (default `true`); add `final AppLanguage manualLanguage` (default `AppLanguage.en`); add `Locale? get effectiveLocale`; extend `copyWith` with the two new nullable params. Keep existing fields and getters untouched. |
| `lib/features/settings/domain/repositories/settings_repository.dart` | Modify | Add `Future<Either<Failure, void>> saveUseSystemLanguage(bool value)` and `Future<Either<Failure, void>> saveManualLanguage(AppLanguage language)` to the abstract contract. `load()` signature unchanged (now returns an `AppSettings` populated with the new fields too — a behavioural extension, not an API change). |
| `lib/features/settings/data/datasources/settings_local_data_source.dart` | Modify | Add 2 key constants (`_kUseSystemLanguageKey = 'useSystemLanguage'`, `_kManualLanguageKey = 'manualLanguage'`); add `bool getUseSystemLanguage()` (default `true`); add `AppLanguage getManualLanguage()` (parse string → `AppLanguage.values.firstWhere(...code…, orElse: () => AppLanguage.en)`); add `Future<void> setUseSystemLanguage(bool)`; add `Future<void> setManualLanguage(AppLanguage)`. |
| `lib/features/settings/data/repositories/settings_repository_impl.dart` | Modify | Extend `load()` body to populate `useSystemLanguage` and `manualLanguage` from the data source. Implement `saveUseSystemLanguage` and `saveManualLanguage` with the same try/`CacheFailure(e.toString())` shape as the existing theme save methods. |
| `lib/features/settings/presentation/providers/settings_provider.dart` | Modify | Add two methods to `SettingsNotifier`: `Future<void> setUseSystemLanguage(bool value)` and `Future<void> setManualLanguage(AppLanguage language)`. Same fold/`kDebugMode`-`debugPrint` shape as `setThemeMode`. |
| `lib/features/settings/presentation/widgets/language_selector.dart` | **Create** | `ConsumerWidget` rendering: `SwitchListTile` (title/subtitle from `context.l10n`, `value: settings.useSystemLanguage`, `onChanged` honours D3 + D7 — pre-fill manual then flip flag); `Column` of 3 `RadioListTile<AppLanguage>` rows iterated from `AppLanguage.values` (title from `language.nativeName`, `groupValue: settings.manualLanguage`, `onChanged: null` when system on else `(v) => notifier.setManualLanguage(v!)` — the `!` here would violate constitution; instead use `(v) { if (v != null) notifier.setManualLanguage(v); }`). `contentPadding: EdgeInsets.zero` on every tile. |
| `lib/features/settings/presentation/screens/settings_screen.dart` | Modify | After the existing Appearance section's `Padding`/`ThemeSelector` block, append a second pair: `Padding(...Text(context.l10n.settingsLanguageHeader.toUpperCase(), style: …))` + `Padding(...LanguageSelector())`. Header style is identical to Appearance's: `theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w500, letterSpacing: 0.5)`. Padding insets `fromLTRB(16, 16, 16, 6)` (header) and `symmetric(horizontal: 16)` (selector). |
| `lib/app.dart` | Modify | Add `locale: ref.watch(settingsProvider.select((s) => s.effectiveLocale)),` to `MaterialApp.router(...)`. Insert it adjacent to the existing `themeMode:` line. `localeResolutionCallback: _resolveLocale` is left exactly as it is — it remains the resolver when `locale` is null. |
| `lib/main.dart` | Modify | Extend the `allowList` set passed to `SharedPreferencesWithCache.create(...)` from `{'themeMode', 'useSystemTheme'}` to `{'themeMode', 'useSystemTheme', 'useSystemLanguage', 'manualLanguage'}`. No other changes — the async init flow stays untouched. |
| `lib/l10n/app_en.arb` | Modify | Add `settingsLanguageHeader: "Language"`, `settingsUseDeviceLanguage: "Use device language"`, `settingsUseDeviceLanguageSub: "Follow your device settings"`, plus `@key` metadata blocks for each. |
| `lib/l10n/app_de.arb` | Modify | Add `settingsLanguageHeader: "Sprache"`, `settingsUseDeviceLanguage: "Sprache des Geräts verwenden"`, `settingsUseDeviceLanguageSub: "Geräteeinstellungen folgen"`. |
| `lib/l10n/app_uk.arb` | Modify | Add `settingsLanguageHeader: "Мова"`, `settingsUseDeviceLanguage: "Мова пристрою"`, `settingsUseDeviceLanguageSub: "Використовувати налаштування пристрою"`. |
| `lib/l10n/app_localizations.dart`, `app_localizations_{en,de,uk}.dart` | Regenerate | Run `flutter gen-l10n` (or implicit codegen via `flutter pub get`). New getters land for the three new keys. Committed per spec-006 `synthetic-package: false` decision. |
| `test/features/settings/data/repositories/settings_repository_impl_test.dart` | Modify | Add `'useSystemLanguage'` and `'manualLanguage'` to all `allowList:` literals. New test cases under `group('load()')` (defaults: useSystemLanguage=true, manualLanguage=en; non-default: after `saveUseSystemLanguage(false)` and `saveManualLanguage(AppLanguage.uk)`; out-of-range/unknown stored string falls back to en; `effectiveLocale` is null when system on else `Locale(code)`). New `group('saveUseSystemLanguage()')` + `group('saveManualLanguage()')` (each: returns `Right(null)` on success). Extend the persistence round-trip group to also round-trip `useSystemLanguage` and `manualLanguage`. |
| `test/features/settings/presentation/providers/settings_provider_test.dart` | Modify | Extend `_FakeSettingsRepository` with `failOnSaveUseSystemLanguage`, `failOnSaveManualLanguage`, and the two `save…` overrides. New tests: `setUseSystemLanguage(false) updates state`; `setUseSystemLanguage does not update state when save fails`; `setManualLanguage(AppLanguage.uk) updates state`; `setManualLanguage does not update state when save fails`; `effectiveLocale is null when useSystemLanguage=true`; `effectiveLocale equals Locale(de) when useSystemLanguage=false and manualLanguage=de`. |
| `test/features/settings/presentation/screens/settings_screen_test.dart` | Modify | Add a test that pumps the screen with localizations + `ProviderScope` overriding `settingsRepositoryProvider` (fake) and asserts `find.text('LANGUAGE')` (uppercased) is present. Existing Appearance-section assertion stays untouched. |
| `test/features/settings/presentation/widgets/language_selector_test.dart` | **Create** | Pump `LanguageSelector` inside `MaterialApp` with `AppLocalizations` delegates + `ProviderScope` (override repo with a fake). Test: switch is ON by default; toggling switch calls `setUseSystemLanguage(false)` and triggers a `setManualLanguage(...)` pre-fill (D3); each radio tile renders its native name literal (`English`, `Deutsch`, `Українська`); when system ON, all radios are non-interactive (`onChanged == null`); when system OFF, tapping a radio triggers `setManualLanguage(AppLanguage.X)` with the right value. |
| `test/widget_test.dart` | Modify | This file already exists and pumps `DoslyApp` under `ProviderScope` with a `_FakeSettingsRepository` override. Extend the fake to support the new save methods and add a test group exercising `MaterialApp.router.locale` reactivity. Test: with default settings → `find.byType(MaterialApp).widget.locale` is null (resolution callback wins); after the fake repo applies `useSystemLanguage:false, manualLanguage: AppLanguage.de` and the provider rebuilds → `MaterialApp.locale == Locale('de')` after pump; after re-toggling system on → locale becomes null again. (Discovered during breakdown — `test/app_test.dart` proposed in original plan is unnecessary; reusing existing app-level test file avoids duplicate setup.) |

### Documentation Impact

| Doc File | Action | What Changes |
|---|---|---|
| `docs/features/settings.md` | Update | Document the new Language section (`useSystemLanguage` + `manualLanguage` fields, `effectiveLocale` getter, persistence keys). Updated by `tech-writer` during `/finalize`. |
| `docs/features/i18n.md` (if it exists) | Update | Note that `MaterialApp.locale` is now driven by `settingsProvider`'s `effectiveLocale` and that the `localeResolutionCallback` is the device-locale fallback (still used when `effectiveLocale` is null). Updated by `tech-writer` during `/finalize`. |
| `docs/architecture.md` | No change expected | The architecture pattern — Riverpod-backed settings driving `MaterialApp` — was already established by spec 009. Adding a second field is not an architecture change. |

(Doc updates run during `/finalize`, NOT during task execution.)

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| `RadioListTile<AppLanguage>`'s `onChanged` callback receives a nullable `AppLanguage?`; using `!` would violate constitution §3.1 | Medium | Low | Use `if (value != null) notifier.setManualLanguage(value);` pattern (D in File Impact for `language_selector.dart`). The Material API guarantees non-null in practice when the user taps, but the type is nullable; null-check rather than null-assert. Compliant by construction. |
| Pre-fill at toggle-OFF (D3) reads `Localizations.localeOf(context)` inside the SwitchListTile's `onChanged` handler — context is still mounted there but the lookup is async-adjacent | Low | Low | Capture `Localizations.localeOf(context)` synchronously at the top of the handler before any `await`. The first `await` is on `setManualLanguage` which is a Riverpod call, but the `Locale` value has already been read into a local. Mirrors the `ThemeSelector` pattern. |
| Existing `settings_repository_impl_test.dart` uses `allowList: {'themeMode', 'useSystemTheme'}` — failing to update it will surface as a runtime cache miss when new code reads the new keys in tests | Medium | Low | Single global search/replace across test files. Plan calls this out explicitly in File Impact. The test fixture's `allowList` is the only place this pattern lives, so the change is localized. |
| Toggling `MaterialApp.locale` triggers a full widget tree rebuild; could reset navigation state | Low | Medium | Spec 009's `themeMode:` change already drives a full-tree rebuild without resetting nav (memory note: top-level `GoRouter` constant survives `MaterialApp` rebuilds). Same property holds for `locale:`. Verified via the AC-12 test. |
| `flutter gen-l10n` regeneration introduces unintended diff in unrelated files (e.g., reordered cases) | Low | Low | Run `flutter gen-l10n` on a clean tree, inspect diff before staging. Spec-006 set `synthetic-package: false` so files are deterministic. |
| Native `Українська` width pushes `RadioListTile` title past available width on a narrow phone | Low | Low | `RadioListTile` (via `ListTile`) wraps to a second line by default. Visual only. AC-18 manual verification will surface any wrapping that looks wrong. |
| `app_test.dart` (NEW) collides with an unrelated test file naming convention | Low | Low | Verified by `find` — no `test/app_test.dart` currently exists. The path follows spec-009's pattern of feature-scoped test files; `app_test.dart` at the test root is a recognised Flutter convention (mirrors `lib/app.dart`). |

## Dependencies

No new packages. All required dependencies (`shared_preferences`, `flutter_localizations`, `intl`, `flutter_riverpod`, `fpdart`) are already in `pubspec.yaml` from spec 006 + spec 009.

No environment variables. No native config (Android `Manifest.xml` / iOS `Info.plist`) changes — `MaterialApp.locale` is a pure Flutter-side concern.

## AC Cross-Reference

Verification that every AC has an implementation path:

| AC | Implementation Path |
|---|---|
| AC-1 (AppLanguage enum) | `app_language.dart` (NEW) — Layer Map: Domain |
| AC-2 (AppSettings extension) | `app_settings.dart` (MOD) — Layer Map: Domain |
| AC-3 (Repository contract) | `settings_repository.dart` (MOD) + `settings_repository_impl.dart` (MOD) — Layer Map: Domain + Data |
| AC-4 (Data source) | `settings_local_data_source.dart` (MOD) — Layer Map: Data |
| AC-5 (allowList) | `main.dart` (MOD) — Layer Map: Presentation |
| AC-6 (Notifier methods) | `settings_provider.dart` (MOD) — Layer Map: Presentation |
| AC-7 (MaterialApp.locale wiring) | `app.dart` (MOD) — Layer Map: Presentation |
| AC-8 (LanguageSelector widget) | `language_selector.dart` (NEW) — Layer Map: Presentation |
| AC-9 (Section header) | `settings_screen.dart` (MOD) — Layer Map: Presentation |
| AC-10 (ARB keys) | 3 ARB files (MOD) + regenerated AppLocalizations — Layer Map: l10n |
| AC-11 (LanguageSelector widget tests) | `language_selector_test.dart` (NEW) — Layer Map: Tests |
| AC-12 (MaterialApp.locale reactivity) | Extend `test/widget_test.dart` (existing app-level test file) — Layer Map: Tests; D9 |
| AC-13 (existing tests pass) | Regression check — Layer Map: Tests |
| AC-14 (persistence round-trip) | `settings_repository_impl_test.dart` (MOD) — Layer Map: Tests |
| AC-15 (`dart analyze` clean) | Verified by `/execute-task` post-step (PostToolUse hook + per-task gate) |
| AC-16 (`flutter test` passes) | Verified by `/execute-task` post-step on the terminal task |
| AC-17 (`flutter build apk --debug` succeeds) | Verified by `/execute-task` post-step on the terminal task |
| AC-18 (manual on-device verification) | Deferred to user post-merge — `/verify` records this as the only manual gap |

All 18 ACs are covered. No reverse mismatches: every file in this plan's File Impact is also in the spec's Affected Areas (the spec was thorough; this plan adds no surprise touches).

## Supporting Documents

- No `research.md` — no signals (all libs/patterns already in stack).
- No `data-model.md` — the only schema change is two flat fields on `AppSettings` already documented in §3.1 of the spec; a separate file would duplicate.
- No `contracts.md` — no API changes (dosly has no backend).
