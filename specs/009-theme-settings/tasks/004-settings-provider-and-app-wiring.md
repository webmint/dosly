### Task 004: Create settings provider and wire app root

**Agent**: architect
**Files**:
- `lib/features/settings/presentation/providers/settings_provider.dart` (create)
- `lib/main.dart` (modify)
- `lib/app.dart` (modify)

**Depends on**: 003
**Blocks**: 005, 006, 007
**Review checkpoint**: Yes (convergence point — first Riverpod usage, app root rewrite)
**Context docs**: None

**Description**:
Create the Riverpod provider that exposes `AppSettings` to the widget tree, then wire `main.dart` and `app.dart` to use it. This is the central integration task — after this, the app's theme is driven by the persisted settings provider instead of the in-memory `ThemeController` singleton.

**Part 1: Settings provider** (`settings_provider.dart`)

Create two providers:
- `settingsRepositoryProvider` — a `Provider<SettingsRepository>` that constructs `SettingsRepositoryImpl(SettingsLocalDataSource(ref.watch(sharedPreferencesProvider)))`. This wires the full DI chain.
- `settingsProvider` — a `NotifierProvider<SettingsNotifier, AppSettings>` whose `build()` calls `ref.watch(settingsRepositoryProvider).load()` (synchronous — returns immediately from cache).
- `SettingsNotifier` exposes `Future<void> setThemeMode(ThemeMode mode)` that calls `repo.saveThemeMode(mode)` and on `Right` updates `state = state.copyWith(themeMode: mode)`.

**Part 2: main.dart**

Rewrite `main()` to:
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `final prefs = await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions(allowList: <String>{'themeMode'}))`
3. `runApp(ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)], child: const DoslyApp()))`

**Part 3: app.dart**

Convert `DoslyApp` from `StatelessWidget` + `ListenableBuilder` to `ConsumerWidget`:
- Remove `import 'core/theme/theme_controller.dart'`
- Add `import 'package:flutter_riverpod/flutter_riverpod.dart'` and import for `settingsProvider`
- Change `extends StatelessWidget` → `extends ConsumerWidget`
- Change `build(BuildContext context)` → `build(BuildContext context, WidgetRef ref)`
- Remove `ListenableBuilder(listenable: themeController, builder: ...)` wrapper
- Replace `themeMode: themeController.value` with `themeMode: ref.watch(settingsProvider).themeMode`
- Keep everything else (localization, router, theme data) unchanged

After this task, `app.dart` no longer imports `theme_controller.dart`. The singleton is still referenced by `theme_preview_screen.dart` and tests — those are updated in Tasks 005 and 006.

**Change details**:
- `lib/features/settings/presentation/providers/settings_provider.dart`:
  - Import `flutter_riverpod`, `settings_repository.dart`, `settings_repository_impl.dart`, `settings_local_data_source.dart`, `shared_preferences_provider.dart`, `app_settings.dart`
  - Define `settingsRepositoryProvider`, `settingsProvider`, `SettingsNotifier`
- `lib/main.dart`:
  - Add imports: `flutter_riverpod`, `shared_preferences`, `core/providers/shared_preferences_provider.dart`
  - Make `main()` async
  - Add `WidgetsFlutterBinding.ensureInitialized()`
  - Init `SharedPreferencesWithCache` with `allowList: {'themeMode'}`
  - Wrap `DoslyApp` in `ProviderScope` with `sharedPreferencesProvider` override
- `lib/app.dart`:
  - Remove `themeController` import, add `flutter_riverpod` + `settingsProvider` imports
  - `DoslyApp` → `ConsumerWidget`, add `WidgetRef ref` param to `build()`
  - Remove `ListenableBuilder` wrapper
  - Replace `themeController.value` → `ref.watch(settingsProvider).themeMode`

**Done when**:
- [ ] `lib/features/settings/presentation/providers/settings_provider.dart` exists with `settingsRepositoryProvider`, `settingsProvider`, and `SettingsNotifier`
- [ ] `lib/main.dart` calls `SharedPreferencesWithCache.create()` and wraps app in `ProviderScope`
- [ ] `lib/app.dart` is a `ConsumerWidget` watching `settingsProvider.themeMode` — no `themeController` import
- [ ] `dart analyze lib/main.dart lib/app.dart lib/features/settings/presentation/providers/` passes with zero issues
- [ ] Note: `flutter test` may have regressions in `widget_test.dart` (still imports `themeController`) — addressed in Task 006

**Spec criteria addressed**: AC-4 (immediate theme switch via provider), AC-5 (persisted theme loaded on startup), AC-7 (Riverpod provider wiring)

## Contracts

### Expects
- `lib/features/settings/data/repositories/settings_repository_impl.dart` exports `SettingsRepositoryImpl`
- `lib/features/settings/data/datasources/settings_local_data_source.dart` exports `SettingsLocalDataSource`
- `lib/core/providers/shared_preferences_provider.dart` exports `sharedPreferencesProvider`
- `lib/app.dart` currently imports `core/theme/theme_controller.dart` and uses `ListenableBuilder`

### Produces
- `lib/features/settings/presentation/providers/settings_provider.dart` exports `settingsRepositoryProvider`, `settingsProvider` (NotifierProvider), and `SettingsNotifier`
- `lib/main.dart` contains `ProviderScope` wrapping `DoslyApp`, with `sharedPreferencesProvider.overrideWithValue`
- `lib/app.dart` is a `ConsumerWidget` — does NOT import `theme_controller.dart`, uses `ref.watch(settingsProvider).themeMode`
