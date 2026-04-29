## Feature Summary: 010 — Language Settings

### What was built

Users can now override the auto-detected device language from Settings, choosing between English, Deutsch, and Українська. Until they pick one, the app continues to follow the device locale (with English fallback). The choice persists across restarts via the existing settings infrastructure built in spec 009.

### Changes

- Task 001: Extend domain layer — added `AppLanguage` enum, two `AppSettings` fields (`useSystemLanguage`, `manualLanguage`), `effectiveLocale` getter, and two abstract repository methods.
- Task 002: Extend data layer — added four `SettingsLocalDataSource` accessors and two `SettingsRepositoryImpl` save methods, mirroring the existing theme persistence shape.
- Task 003: Extend notifier and wire `MaterialApp.locale` — added `setUseSystemLanguage` / `setManualLanguage`, extended the `SharedPreferencesWithCache` allowList, and bound `MaterialApp.router.locale` to `effectiveLocale`.
- Task 004: Add localizations and build UI — three new ARB keys across en/de/uk, regenerated `AppLocalizations`, new `LanguageSelector` widget, and a "Language" section on the Settings screen.
- Task 005: Write feature tests — extended five existing test files and added one new widget test, raising the suite from 117 to 170 passing.

### Files changed

- `lib/features/settings/domain/` — 1 file added, 2 modified
- `lib/features/settings/data/` — 2 files modified
- `lib/features/settings/presentation/` — 1 file added, 3 modified
- `lib/l10n/` — 3 ARB files modified, 4 generated files regenerated
- `lib/app.dart`, `lib/main.dart` — 2 files modified
- `test/` — 1 file added (`language_selector_test.dart`), 5 modified
- `specs/010-language-settings/` — feature spec, plan, 5 task files, review, verify

Total: 36 files changed, 2678 insertions, 47 deletions.

### Key decisions

- **Native-name source**: `nativeName` field on `AppLanguage` enum (single source of truth; literals never translated, per universal language-picker convention).
- **Locale construction**: `effectiveLocale` getter on `AppSettings` returns `Locale?` (null when system mode on), mirroring the `effectiveThemeMode` precedent.
- **Pre-fill at toggle-OFF**: when the user flips "Use device language" off, the manual selector is pre-filled from `Localizations.localeOf(context).languageCode` (or `AppLanguage.en` if unsupported) before flipping the system flag — keeps the visible language stable across the toggle.
- **Persistence schema**: two flat keys (`useSystemLanguage` bool + `manualLanguage` string=`code`); strings survive enum reordering better than indices.

### Deviations from plan

- **Task 004 — RadioGroup migration**: Flutter 3.32+ deprecated `RadioListTile.groupValue` / `onChanged` in favour of a `RadioGroup<T>` ancestor. The widget was migrated to the new API (disabled state expressed via `enabled: !useSystemLanguage` instead of `onChanged: null`). AC-11's behavioural contract preserved.
- **Post-Task 004 refactor — Dropdown over Radio**: The spec prescribed `RadioListTile × 3`. After Task 005 shipped, the user requested a UX refactor to a single full-width `DropdownButton<AppLanguage>` to scale better as more Settings sections land. A follow-up fix made the dropdown reflect the device-resolved language when system mode is on (mirrors `ThemeSelector`'s system-brightness pattern). Behavioural contract from AC-8 preserved.
- **Task 005 — `test/widget_test.dart` instead of `test/app_test.dart`**: AC-12's `MaterialApp.locale` reactivity test extended the existing app-level test file rather than creating a parallel one (the spec's "or wherever" clause anticipated this).

### Acceptance criteria

- [x] AC-1: `AppLanguage` enum with three values, no Flutter imports
- [x] AC-2: `AppSettings` extended with language fields + `effectiveLocale` getter
- [x] AC-3: `SettingsRepository` declares + implements two new save methods
- [x] AC-4: `SettingsLocalDataSource` reads/writes both new keys with safe defaults
- [x] AC-5: `main.dart` allowList includes both new keys
- [x] AC-6: `SettingsNotifier.setUseSystemLanguage` / `setManualLanguage` exist with documented failure shape
- [x] AC-7: `MaterialApp.router.locale` wired to `effectiveLocale`; resolution callback unchanged
- [x] AC-8: `LanguageSelector` renders switch + manual picker (dropdown) with disabled state
- [x] AC-9: "Language" section header matches Appearance header styling
- [x] AC-10: All three ARB files contain the new keys; English includes `@key` metadata
- [x] AC-11: `LanguageSelector` widget tests cover switch / disabled / native names / tap-to-save / pre-fill
- [x] AC-12: `MaterialApp.locale` reactivity test passes
- [x] AC-13: All 117 existing tests still pass (suite now 170/170)
- [x] AC-14: Persistence round-trip test reads back both new keys
- [x] AC-15: `dart analyze` reports zero issues
- [x] AC-16: `flutter test` passes (170/170)
- [x] AC-17: `flutter build apk --debug` succeeds
- [ ] AC-18: Manual on-device verification (deferred to user post-merge, per spec §5)
