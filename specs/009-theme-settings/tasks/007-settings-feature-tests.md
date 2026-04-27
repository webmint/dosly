### Task 007: Write settings feature tests

**Agent**: qa-engineer
**Files**:
- `test/features/settings/data/repositories/settings_repository_impl_test.dart` (create)
- `test/features/settings/presentation/providers/settings_provider_test.dart` (create)
- `test/features/settings/presentation/widgets/theme_selector_test.dart` (create)

**Depends on**: 005, 006
**Blocks**: None
**Review checkpoint**: No
**Context docs**: None

**Description**:
Write tests for the new settings infrastructure: repository impl, provider/notifier, and the theme selector widget.

**Part 1: Repository impl tests** (`settings_repository_impl_test.dart`)

Test `SettingsRepositoryImpl` with a real `SharedPreferencesWithCache` (use `SharedPreferencesWithCache.create()` in test `setUp` — SharedPreferences has an in-memory test mode, or use `SharedPreferences.setMockInitialValues({})` for the legacy API).

Test cases:
- `load()` returns `AppSettings(themeMode: ThemeMode.system)` when no value is stored
- `load()` returns the correct `ThemeMode` after `saveThemeMode(ThemeMode.dark)` is called
- `saveThemeMode()` returns `Right(null)` on success
- `load()` survives invalid stored values (out-of-range int) — falls back to system

**Part 2: Provider/notifier tests** (`settings_provider_test.dart`)

Test `SettingsNotifier` using `ProviderContainer` with overridden `settingsRepositoryProvider` (provide a fake/mock `SettingsRepository` via `mocktail` or a simple fake class).

Test cases:
- Initial state is `AppSettings(themeMode: ThemeMode.system)` from repository's `load()`
- `setThemeMode(ThemeMode.dark)` updates state to dark AND calls `repo.saveThemeMode`
- `setThemeMode` with a repo that returns `Left(CacheFailure(...))` does NOT update state

**Part 3: Theme selector widget tests** (`theme_selector_test.dart`)

Test the `ThemeSelector` widget in a `ProviderScope` + `MaterialApp` harness.

Test cases:
- Renders three segments with correct English labels ("System", "Light", "Dark")
- Default selection is "System" (matching initial provider state)
- Tapping "Dark" segment calls `setThemeMode(ThemeMode.dark)` on the notifier
- Renders correct Ukrainian labels when locale is `uk`
- Renders correct German labels when locale is `de`

**Change details**:
- `test/features/settings/data/repositories/settings_repository_impl_test.dart`: ~4 test cases for repo
- `test/features/settings/presentation/providers/settings_provider_test.dart`: ~3 test cases for notifier
- `test/features/settings/presentation/widgets/theme_selector_test.dart`: ~5 test cases for widget

**Done when**:
- [ ] All three test files exist and pass via `flutter test test/features/settings/`
- [ ] Repository tests verify load/save round-trip and default fallback
- [ ] Provider tests verify state updates and failure handling
- [ ] Widget tests verify rendering, selection, and localization
- [ ] `flutter test` (full suite) passes with zero failures
- [ ] `dart analyze test/features/settings/` passes with zero issues

**Spec criteria addressed**: AC-10 (new tests covering repository, provider, and widget)

## Contracts

### Expects
- `lib/features/settings/data/repositories/settings_repository_impl.dart` exports `SettingsRepositoryImpl`
- `lib/features/settings/data/datasources/settings_local_data_source.dart` exports `SettingsLocalDataSource`
- `lib/features/settings/presentation/providers/settings_provider.dart` exports `settingsProvider`, `settingsRepositoryProvider`, `SettingsNotifier`
- `lib/features/settings/presentation/widgets/theme_selector.dart` exports `ThemeSelector`
- `flutter test` passes (from Task 006 — no pre-existing regressions)

### Produces
- `test/features/settings/data/repositories/settings_repository_impl_test.dart` exists and passes
- `test/features/settings/presentation/providers/settings_provider_test.dart` exists and passes
- `test/features/settings/presentation/widgets/theme_selector_test.dart` exists and passes
- `flutter test` exits with code 0 (full suite green)
