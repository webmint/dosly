### Task 003: Create settings data layer

**Agent**: architect
**Files**:
- `lib/features/settings/data/datasources/settings_local_data_source.dart` (create)
- `lib/features/settings/data/repositories/settings_repository_impl.dart` (create)

**Depends on**: 002
**Blocks**: 004
**Review checkpoint**: No
**Context docs**: None

**Description**:
Create the data layer that implements the `SettingsRepository` contract using `SharedPreferencesWithCache`.

1. `SettingsLocalDataSource` — wraps `SharedPreferencesWithCache` for raw read/write of settings keys.
   - `ThemeMode getThemeMode()` — synchronous read from cache. Key: `'themeMode'`, stored as `int` (ThemeMode.index: 0=system, 1=light, 2=dark). Returns `ThemeMode.system` if key is absent.
   - `Future<void> setThemeMode(ThemeMode mode)` — writes `mode.index` as int.

2. `SettingsRepositoryImpl` — implements `SettingsRepository`.
   - `load()` reads from the data source, assembles an `AppSettings`. Synchronous, never fails.
   - `saveThemeMode()` delegates to the data source, wraps in try/catch → returns `Right(null)` on success, `Left(CacheFailure(...))` on exception.

The data source receives `SharedPreferencesWithCache` via constructor injection (provided by the Riverpod provider graph in Task 004).

**Change details**:
- `lib/features/settings/data/datasources/settings_local_data_source.dart`:
  - Constructor takes `SharedPreferencesWithCache`
  - `ThemeMode getThemeMode()` — reads `prefs.getInt('themeMode')`, maps index to `ThemeMode.values[index]` with bounds check, defaults to `ThemeMode.system`
  - `Future<void> setThemeMode(ThemeMode mode)` — calls `prefs.setInt('themeMode', mode.index)`
- `lib/features/settings/data/repositories/settings_repository_impl.dart`:
  - Constructor takes `SettingsLocalDataSource`
  - `AppSettings load()` — creates `AppSettings(themeMode: dataSource.getThemeMode())`
  - `Future<Either<Failure, void>> saveThemeMode(ThemeMode mode)` — try/catch around `dataSource.setThemeMode(mode)`, returns `Right(null)` or `Left(CacheFailure(e.toString()))`

**Done when**:
- [ ] `lib/features/settings/data/datasources/settings_local_data_source.dart` exists with `SettingsLocalDataSource` class
- [ ] `lib/features/settings/data/repositories/settings_repository_impl.dart` exists with `SettingsRepositoryImpl` implementing `SettingsRepository`
- [ ] `dart analyze lib/features/settings/data/` passes with zero issues

**Spec criteria addressed**: AC-5 (persistence layer), AC-7 (repository impl in data layer wrapping SharedPreferences)

## Contracts

### Expects
- `lib/features/settings/domain/entities/app_settings.dart` exports `class AppSettings` with `copyWith`
- `lib/features/settings/domain/repositories/settings_repository.dart` exports `abstract interface class SettingsRepository`
- `lib/core/error/failures.dart` exports `CacheFailure`
- `lib/core/providers/shared_preferences_provider.dart` exports `sharedPreferencesProvider`
- `pubspec.yaml` contains `shared_preferences` and `fpdart`

### Produces
- `lib/features/settings/data/datasources/settings_local_data_source.dart` exports `class SettingsLocalDataSource` with constructor taking `SharedPreferencesWithCache`, methods `getThemeMode()` and `setThemeMode(ThemeMode)`
- `lib/features/settings/data/repositories/settings_repository_impl.dart` exports `class SettingsRepositoryImpl implements SettingsRepository` with constructor taking `SettingsLocalDataSource`
