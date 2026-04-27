# Spec: Theme Settings

**Date**: 2026-04-25
**Status**: Complete
**Author**: Claude + Mykola

## 1. Overview

Add a functional theme-switching control to the Settings screen, allowing the user to choose between System (default), Light, and Dark theme modes. The selection must persist across app restarts and be the first concrete setting backed by a new app-wide settings infrastructure — a single source of truth for all user preferences, designed for easy extension with future settings (reminders, data, etc.).

## 2. Current State

### Settings screen
`lib/features/settings/presentation/screens/settings_screen.dart` — a placeholder `Scaffold` with a localized AppBar title (`context.l10n.settingsTitle`) and a 1-px divider bottom border. The body is `SizedBox.shrink()` — completely empty.

### Theme controller
`lib/core/theme/theme_controller.dart` — a `ThemeController extends ValueNotifier<ThemeMode>` singleton (`themeController`) with `setMode()` and `cycle()` methods. Used by `DoslyApp` in `lib/app.dart` via `ListenableBuilder` to drive `MaterialApp.themeMode`. **In-memory only** — resets to `ThemeMode.system` on every app restart. The file's own doc comments state: "Persistence belongs to the future Settings feature, which will use drift."

### App root
`lib/app.dart` — `DoslyApp` wraps `MaterialApp.router` in a `ListenableBuilder(listenable: themeController)`. The `themeMode:` reads `themeController.value`. Light/dark themes come from `AppTheme.lightTheme` / `AppTheme.darkTheme`.

### Theme infrastructure
- `lib/core/theme/app_theme.dart` — M3 `ThemeData` builder with `lightTheme` / `darkTheme` getters.
- `lib/core/theme/app_color_schemes.dart` — hand-coded `const ColorScheme` literals for light and dark.
- `lib/core/theme/app_text_theme.dart` — Roboto-based `TextTheme`.

### Localization
Three ARB files (`app_en.arb`, `app_uk.arb`, `app_de.arb`) with generated `AppLocalizations`. Currently has: `settingsTooltip`, `settingsTitle`, `bottomNavToday`, `bottomNavMeds`, `bottomNavHistory`. The `context.l10n` extension in `lib/l10n/l10n_extensions.dart` centralizes the single sanctioned `!` null-assertion for `AppLocalizations.of(context)!`.

### Constitution references
- `Settings` entity is defined in constitution §5.1 with medication-domain fields: `gracePeriodMinutes`, `intakeWindowMinutes`, `notificationLeadMinutes`, `quietHoursStart`, `quietHoursEnd`. Theme mode is not included — it's a UI preference that needs to be added.
- The constitution mandates `SharedPreferences` NEVER be used for medication/intake data (that's drift's job), but `SharedPreferences` is the idiomatic Flutter choice for simple key-value preferences like theme mode.

### HTML template reference
The HTML template (`dosly_m3_template.html`, lines 2545–2558) shows an "Зовнішній вигляд" (Appearance) settings group with a "Тема" (Theme) tile displaying the current value as a chip ("Системна") with a chevron. However, per user direction, the implementation should favor M3 patterns — specifically a `SegmentedButton` for the three-option theme selection rather than the template's tap-to-navigate tile pattern.

### No persistence dependency
`shared_preferences` is not currently in `pubspec.yaml`.

## 3. Desired Behavior

### 3.1 Settings infrastructure
A new app-wide settings persistence layer that acts as the single source of truth for all user preferences. The first (and currently only) preference is `themeMode`. The infrastructure must be designed so that adding future settings (notification toggle, grace period, etc.) requires only extending the data model — no plumbing changes.

### 3.2 Theme selection control
The Settings screen displays an "Appearance" section with a group subheader and a Material 3 `SegmentedButton` with three segments:
- **System** (default) — follows device setting
- **Light** — forces light theme
- **Dark** — forces dark theme

The selected segment reflects the persisted theme mode. Tapping a different segment immediately applies the theme (the app visually switches) and persists the choice.

### 3.3 Persistence
The selected theme mode survives app restarts. On app launch, the persisted value is read and applied before the first frame renders (or as close to it as possible to avoid a theme flash).

### 3.4 Localization
All new user-visible strings (the section subheader, the segment labels, and any supporting text) must be localized in all three languages: English, Ukrainian, German.

### 3.5 Integration with existing theme system
The current `ThemeController` / `ListenableBuilder` mechanism in `app.dart` must continue to work or be replaced with an equivalent Riverpod-based approach. The `MaterialApp.themeMode` must reflect the persisted setting at all times.

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Settings screen | `lib/features/settings/presentation/screens/settings_screen.dart` | Replace empty body with Appearance section containing SegmentedButton |
| Settings domain | `lib/features/settings/domain/` | Create new — entity, repository interface |
| Settings data | `lib/features/settings/data/` | Create new — data source (SharedPreferences), repository impl |
| Settings providers | `lib/features/settings/presentation/providers/` | Create new — Riverpod provider for settings state |
| App root | `lib/app.dart` | Convert `DoslyApp` from `StatelessWidget` + `ListenableBuilder` to `ConsumerWidget` watching the settings provider |
| App entry | `lib/main.dart` | Add `SharedPreferencesWithCache` init before `runApp()`, pass via `ProviderScope.overrides` |
| Theme controller | `lib/core/theme/theme_controller.dart` | Retire — delete file, remove all imports. Riverpod replaces it entirely |
| Localization | `lib/l10n/app_en.arb`, `app_uk.arb`, `app_de.arb` + generated files | Add new strings for section header and segment labels |
| Dependencies | `pubspec.yaml` | Add `shared_preferences` |
| Tests | `test/features/settings/` | Create new — repository tests, provider tests, widget tests |

## 5. Acceptance Criteria

Each criterion must be testable and unambiguous:

- [x] **AC-1**: The Settings screen displays a section with a visible subheader labeled "Appearance" (en) / "Зовнішній вигляд" (uk) / "Darstellung" (de), styled as a group title (M3 `labelSmall` or `titleSmall` in `primary` color, consistent with the HTML template's `.settings-group-title` intent).
- [x] **AC-2**: Below the subheader, a Material 3 `SegmentedButton` (or equivalent M3 control) displays three options: "System" / "Light" / "Dark" with appropriate localized labels in all three languages.
- [x] **AC-3**: The default selection is "System" on a fresh install (no prior preference stored).
- [x] **AC-4**: Tapping a segment immediately changes the app's theme — the `MaterialApp.themeMode` updates and the entire widget tree reflects the new theme without requiring a restart or navigation.
- [x] **AC-5**: The selected theme mode is persisted and survives a full app restart — relaunching the app applies the previously chosen mode.
- [x] **AC-6**: A single-source-of-truth settings model exists that currently holds `themeMode` and is designed so new preferences can be added by extending the model, not by creating parallel infrastructure.
- [x] **AC-7**: The settings persistence layer follows Clean Architecture boundaries: abstract repository in `domain/`, concrete implementation wrapping `SharedPreferences` in `data/`, exposed to UI via a Riverpod provider.
- [x] **AC-8**: All new user-facing strings are localized in `app_en.arb`, `app_uk.arb`, and `app_de.arb`, and the generated `AppLocalizations` class exposes them.
- [x] **AC-9**: `dart analyze` passes with zero issues on all new and modified files.
- [x] **AC-10**: `flutter test` passes — no regressions in existing tests, plus new tests covering the settings repository, provider, and widget.
- [x] **AC-11**: `flutter build apk --debug` succeeds.

## 6. Out of Scope

- NOT included: Notification/reminder settings (toggle, lead time) — future spec
- NOT included: Data management settings (backup, restore, clear all) — future spec
- NOT included: About section (version display) — future spec
- NOT included: Any changes to the theme itself (colors, typography) — those are already complete
- NOT included: Theme preview screen changes — the dev-only preview is unrelated
- NOT included: Drift-based persistence for settings — SharedPreferences is appropriate for simple preferences
- NOT included: The other settings groups visible in the HTML template (Reminders, Data, About) — only Appearance/Theme in this spec

## 7. Technical Constraints

- Must follow Clean Architecture layer boundaries (constitution §2.1): domain has no Flutter imports, data wraps the persistence SDK, presentation uses Riverpod providers
- Must use `freezed` for any new entity/model classes (constitution §3.1)
- Must use `Either<Failure, T>` at repository boundaries (constitution §3.2)
- No `!` null assertions (constitution §3.1) — use the `context.l10n` extension pattern
- No `dynamic` types (constitution §3.1)
- New dependency (`shared_preferences`) must be added via `flutter pub add`, not manual `pubspec.yaml` edit (constitution §2.3)
- Localization must cover en, uk, de — and the locale resolution callback in `app.dart` must continue to fall back to English for unsupported locales
- The existing `ListenableBuilder` + `themeController` pattern in `app.dart` is a known-working pattern (see MEMORY.md "What Worked") — any replacement must preserve the same UX (no theme flash, no navigation stack reset on theme change)

## 8. Open Questions

None — all resolved during spec review:

- **Q1 (resolved)**: Fully retire `ThemeController` (`ValueNotifier` singleton) in favor of a Riverpod `Notifier`. `DoslyApp` becomes a `ConsumerWidget` that watches the settings provider — no more `ListenableBuilder`. Having a `ValueNotifier` outside the Riverpod graph is an anti-pattern when the project already uses Riverpod for state management.
- **Q2 (resolved)**: Blocking initialization in `main()` using `SharedPreferencesWithCache`. The modern `shared_preferences` API provides synchronous reads after an initial async `create()` call (milliseconds). Init in `main()` before `runApp()`, pass the instance via `ProviderScope.overrides` — guarantees no theme flash and no `AsyncValue` loading state for settings.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Theme flash on startup if persistence loads asynchronously | Medium | Low | Initialize SharedPreferences in `main()` before `runApp` |
| Breaking existing `app.dart` listener pattern when integrating Riverpod | Low | Medium | Incremental migration — keep `ListenableBuilder` working throughout, test after each change |
| `shared_preferences` adding unwanted permissions | Low | Low | Verify no `INTERNET` permission added; SharedPreferences is local-only by design |
| Future settings additions conflicting with theme-only model | Low | Low | Design the settings model with extensibility from day one (freezed `copyWith`) |
