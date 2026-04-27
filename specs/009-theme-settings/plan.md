# Plan: Theme Settings

**Date**: 2026-04-25
**Spec**: specs/009-theme-settings/spec.md
**Status**: Approved

## Summary

Add a persisted theme-switching `SegmentedButton` to the Settings screen, backed by a new app-wide settings infrastructure using `SharedPreferencesWithCache` + Riverpod. This is the first feature that introduces Riverpod and SharedPreferences into the project — both are part of the constitution's planned stack but weren't needed until now. The existing `ThemeController` (ValueNotifier singleton) is fully retired and replaced by a Riverpod `Notifier`.

## Technical Context

**Architecture**: Clean Architecture — domain (entity + abstract repo), data (SharedPreferences data source + repo impl), presentation (Riverpod Notifier + SegmentedButton widget)
**Error Handling**: `Either<Failure, T>` at repository boundary (fpdart)
**State Management**: Riverpod `Notifier<AppSettings>` — hand-written, no codegen

## Constitution Compliance

| Rule | Status |
|------|--------|
| §2.1 Layer boundaries (domain pure Dart, no Flutter) | Compliant — `AppSettings` + `SettingsRepository` are pure Dart |
| §2.3 Dependencies via `flutter pub add` | Compliant |
| §3.1 No `!`, no `dynamic`, no unchecked `as` | Compliant — `context.l10n` extension for l10n |
| §3.1 `freezed` for entities [convention] | Deferred — see Key Decision D1 |
| §3.2 `Either<Failure, T>` at repo boundary [enforced] | Compliant — fpdart added, Failure class created |
| §3.4 Testing requirements | Compliant — tests for repo, provider, widget |

## Implementation Approach

### Layer Map

| Layer | What | Files |
|-------|------|-------|
| **Core (new)** | Failure sealed class, SharedPreferences provider | `lib/core/error/failures.dart` (create), `lib/core/providers/shared_preferences_provider.dart` (create) |
| **Domain** | Settings entity, repository interface | `lib/features/settings/domain/entities/app_settings.dart` (create), `lib/features/settings/domain/repositories/settings_repository.dart` (create) |
| **Data** | SharedPreferences data source, repository impl | `lib/features/settings/data/datasources/settings_local_data_source.dart` (create), `lib/features/settings/data/repositories/settings_repository_impl.dart` (create) |
| **Presentation** | Riverpod provider, settings screen, theme selector widget | `lib/features/settings/presentation/providers/settings_provider.dart` (create), `settings_screen.dart` (modify), `lib/features/settings/presentation/widgets/theme_selector.dart` (create) |
| **App root** | ProviderScope + async init, ConsumerWidget | `lib/main.dart` (modify), `lib/app.dart` (modify) |
| **Retired** | ThemeController singleton | `lib/core/theme/theme_controller.dart` (delete), `test/core/theme/theme_controller_test.dart` (delete) |
| **Side-effect** | ThemePreview uses themeController | `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` (modify — update to use settings provider) |
| **Localization** | New ARB keys | `lib/l10n/app_en.arb`, `app_uk.arb`, `app_de.arb` (modify) |

### Key Design Decisions

| # | Decision | Chosen Approach | Why | Alternatives Rejected |
|---|----------|----------------|-----|----------------------|
| D1 | Codegen stack (freezed + riverpod_generator) | **Defer** — hand-write Notifier + Settings class | Neither `freezed`, `riverpod_generator`, nor `build_runner` are installed. Adding 4+ packages and a build step for a one-field class is disproportionate. Adopt codegen when first data-heavy feature (medications) ships. | Install full codegen now (correct per constitution convention, but massive overhead for one enum field) |
| D2 | Settings persistence backend | **SharedPreferencesWithCache** | Synchronous reads after async init. Constitution reserves drift for relational data (medications/intakes). Simple key-value prefs are SharedPreferences territory. | Drift (overkill for k-v prefs), Hive (extra dep not in constitution) |
| D3 | Failure class without freezed | **Hand-written Dart 3 sealed class** | Clean Architecture requires Failure at repo boundaries (fpdart `Either`). Without freezed installed, use Dart 3 `sealed class` with manual subclasses. Migrate to `@freezed` when codegen arrives. | Skip Either entirely (violates §3.2 [enforced]), or install freezed just for Failure (overkill) |
| D4 | ThemeController retirement | **Full retirement** — delete file, replace all usages | Resolved in spec Q&A. Having a ValueNotifier singleton alongside Riverpod splits state into two systems. Clean cut. | Keep as bridge (adds complexity, two state systems coexist) |
| D5 | Theme loading on startup | **Blocking init in `main()`** | Resolved in spec Q&A. `SharedPreferencesWithCache.create()` in `main()` before `runApp()`. Fast (ms), guarantees no theme flash. Passed to ProviderScope via override. | Lazy init (causes theme flash on cold start) |
| D6 | SegmentedButton type parameter | **`SegmentedButton<ThemeMode>`** | Flutter's `ThemeMode` enum has exactly 3 values matching our needs (system, light, dark). Using it directly avoids a mapping layer. `selected: {currentThemeMode}`, single-selection. | Custom enum (unnecessary indirection) |
| D7 | SharedPreferences provider shape | **`Provider<SharedPreferencesWithCache>`** overridden in `main()` | Standard Riverpod pattern for injecting async-initialized singletons. Provider throws if accessed without override (catches wiring bugs). Data source reads from this provider. | Pass prefs directly to repository constructor (harder to test, breaks DI pattern) |
| D8 | ThemePreviewScreen update | **Minimal — swap themeController for provider** | ThemePreviewScreen is dev-only (marked for post-MVP removal) but it compiles today. Deleting `theme_controller.dart` breaks it. Minimal update: make it a `ConsumerWidget`, watch settings provider. Not in spec scope but necessary for compilation. | Delete ThemePreviewScreen now (out of scope, belongs to separate cleanup) |

### Data Model

```dart
/// lib/features/settings/domain/entities/app_settings.dart
class AppSettings {
  const AppSettings({this.themeMode = ThemeMode.system});
  final ThemeMode themeMode;  // Uses Flutter's ThemeMode enum

  AppSettings copyWith({ThemeMode? themeMode}) =>
      AppSettings(themeMode: themeMode ?? this.themeMode);
}
```

Note: `ThemeMode` is from `package:flutter/material.dart`. This means `AppSettings` imports Flutter — which technically violates the "domain = pure Dart" rule. However, `ThemeMode` is a simple 3-value enum with no Flutter framework dependency at runtime. The pragmatic choice: keep it in domain for simplicity. The alternative (a domain-local `AppThemeMode` enum + mapper) adds a mapping layer for zero benefit. If this becomes a problem when the domain layer grows, extract then.

**SharedPreferences key mapping**: `themeMode` → stored as `int` (ThemeMode.index: 0=system, 1=light, 2=dark).

### Failure Class (Core Infrastructure)

```dart
/// lib/core/error/failures.dart
/// Hand-written Dart 3 sealed class. Migrate to @freezed when codegen is adopted.
sealed class Failure {
  const Failure();
}
class CacheFailure extends Failure {
  const CacheFailure(this.message);
  final String message;
}
// Additional subclasses from constitution §3.2 added as needed by future features
```

Only `CacheFailure` is needed now. Other variants (`NotFoundFailure`, `ValidationFailure`, etc.) are added when their features land.

### Provider Architecture

```
main() ──async──► SharedPreferencesWithCache.create()
                        │
                        ▼
              ProviderScope(overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs)
              ])
                        │
                        ▼
              settingsProvider (Notifier<AppSettings>)
                ├── reads initial ThemeMode from SharedPrefs (sync)
                ├── setThemeMode() → updates state + persists
                └── watched by DoslyApp (themeMode) and SettingsScreen (UI)
```

**Provider definitions:**

```dart
/// lib/core/providers/shared_preferences_provider.dart
/// Throws UnimplementedError if not overridden — catches wiring bugs.
final sharedPreferencesProvider = Provider<SharedPreferencesWithCache>(
  (ref) => throw UnimplementedError('Must be overridden in main()'),
);
```

```dart
/// lib/features/settings/presentation/providers/settings_provider.dart
final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final repo = ref.watch(settingsRepositoryProvider);
    return repo.load();  // sync — reads from cache
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final repo = ref.read(settingsRepositoryProvider);
    final result = await repo.saveThemeMode(mode);
    result.fold(
      (failure) { /* log or ignore — persistence failure is non-fatal */ },
      (_) { state = state.copyWith(themeMode: mode); },
    );
  }
}
```

### Repository Contract

```dart
/// lib/features/settings/domain/repositories/settings_repository.dart
abstract interface class SettingsRepository {
  /// Loads settings synchronously from cache. Never fails — returns defaults.
  AppSettings load();

  /// Persists theme mode. Returns Either for consistency even though failure is rare.
  Future<Either<Failure, void>> saveThemeMode(ThemeMode mode);
}
```

### Localization Keys

| Key | en | uk | de |
|-----|----|----|-----|
| `settingsAppearanceHeader` | Appearance | Зовнішній вигляд | Darstellung |
| `settingsThemeSystem` | System | Системна | System |
| `settingsThemeLight` | Light | Світла | Hell |
| `settingsThemeDark` | Dark | Темна | Dunkel |

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `pubspec.yaml` | Modify | Add `flutter_riverpod`, `shared_preferences`, `fpdart` via `flutter pub add` |
| `lib/core/error/failures.dart` | Create | Hand-written sealed `Failure` class with `CacheFailure` |
| `lib/core/providers/shared_preferences_provider.dart` | Create | `Provider<SharedPreferencesWithCache>` (overridden in main) |
| `lib/features/settings/domain/entities/app_settings.dart` | Create | `AppSettings` immutable class with `themeMode` field |
| `lib/features/settings/domain/repositories/settings_repository.dart` | Create | Abstract `SettingsRepository` interface |
| `lib/features/settings/data/datasources/settings_local_data_source.dart` | Create | Wraps `SharedPreferencesWithCache` — read/write theme mode |
| `lib/features/settings/data/repositories/settings_repository_impl.dart` | Create | Implements `SettingsRepository`, catches exceptions → `Left(CacheFailure)` |
| `lib/features/settings/presentation/providers/settings_provider.dart` | Create | `SettingsNotifier` + `settingsRepositoryProvider` |
| `lib/features/settings/presentation/widgets/theme_selector.dart` | Create | `SegmentedButton<ThemeMode>` with localized labels |
| `lib/features/settings/presentation/screens/settings_screen.dart` | Modify | Add Appearance section with subheader + ThemeSelector widget, become `ConsumerWidget` |
| `lib/main.dart` | Modify | `async main()`, `WidgetsFlutterBinding.ensureInitialized()`, `SharedPreferencesWithCache.create()`, wrap in `ProviderScope` |
| `lib/app.dart` | Modify | `DoslyApp` → `ConsumerWidget`, watch `settingsProvider.themeMode`, remove `ListenableBuilder` + `themeController` import |
| `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` | Modify | `ConsumerWidget`, replace `themeController.cycle`/`.value` with provider-based equivalents |
| `lib/core/routing/app_router.dart` | Modify | Update doc comment that references `themeController` pattern |
| `lib/core/theme/theme_controller.dart` | Delete | Retired — Riverpod replaces it |
| `lib/l10n/app_en.arb` | Modify | Add 4 new keys |
| `lib/l10n/app_uk.arb` | Modify | Add 4 new keys |
| `lib/l10n/app_de.arb` | Modify | Add 4 new keys |
| `test/core/theme/theme_controller_test.dart` | Delete | Tests for retired controller |
| `test/features/settings/data/repositories/settings_repository_impl_test.dart` | Create | Repository tests with fake SharedPreferences |
| `test/features/settings/presentation/providers/settings_provider_test.dart` | Create | Notifier tests with overridden repository |
| `test/features/settings/presentation/screens/settings_screen_test.dart` | Create | Widget test for SegmentedButton rendering and selection |
| `test/widget_test.dart` | Modify | Rewrite — use ProviderScope with overrides, no themeController |

### Documentation Impact

No documentation changes expected — `docs/` directory does not exist yet for this project.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `ThemeMode` import in domain entity | Low | Low | `ThemeMode` is a pure enum with no framework dependency. Extract to domain-local enum only if domain purity becomes a real problem. |
| ThemePreviewScreen breakage during migration | Medium | Low | Update in same task that deletes `theme_controller.dart`. Dev-only screen, low stakes. |
| `widget_test.dart` rewrite is fragile | Medium | Low | The test already needs rework (asserts on "Hello World" which is stale). Rewrite fully to test current UI. |
| Missing `ProviderScope` in tests causes runtime error | Medium | Medium | Every widget test must wrap in `ProviderScope` with overrides. Add a test helper early. |

## Dependencies

| Package | Version | Justification |
|---------|---------|--------------|
| `flutter_riverpod` | latest (^2.x) | State management — first usage, constitution-mandated |
| `shared_preferences` | latest | Settings persistence — `SharedPreferencesWithCache` API |
| `fpdart` | latest | `Either<Failure, T>` — constitution-mandated error handling |

## Supporting Documents

- [Research](research.md) — signal investigation (SharedPreferencesWithCache pattern, Riverpod overrides, codegen deferral)
