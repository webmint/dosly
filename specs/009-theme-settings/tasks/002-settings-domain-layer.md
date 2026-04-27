### Task 002: Create settings domain layer

**Agent**: architect
**Files**:
- `lib/features/settings/domain/entities/app_settings.dart` (create)
- `lib/features/settings/domain/repositories/settings_repository.dart` (create)

**Depends on**: 001
**Blocks**: 003
**Review checkpoint**: No
**Context docs**: None

**Description**:
Create the domain layer for the settings feature: the `AppSettings` entity and the abstract `SettingsRepository` interface.

1. `AppSettings` is a hand-written immutable class with a single `themeMode` field (defaults to `ThemeMode.system`) and a manual `copyWith`. This is the single source of truth for all app preferences — future settings (notification toggle, grace period, etc.) are added as fields here.

2. `SettingsRepository` is an `abstract interface class` with:
   - `AppSettings load()` — synchronous read from cache, returns defaults if nothing stored
   - `Future<Either<Failure, void>> saveThemeMode(ThemeMode mode)` — persists theme mode

Note on `ThemeMode` in domain: `ThemeMode` is from `package:flutter/material.dart`, which technically violates domain purity. However, it's a simple 3-value enum with no framework coupling at runtime. The pragmatic choice is to use it directly rather than introducing a domain-local enum + mapper for zero benefit. If domain purity becomes a real constraint (e.g., shared Dart package), extract then.

**Change details**:
- `lib/features/settings/domain/entities/app_settings.dart`:
  - Create `class AppSettings` with `const AppSettings({this.themeMode = ThemeMode.system})`
  - `final ThemeMode themeMode` field
  - `AppSettings copyWith({ThemeMode? themeMode})` method
- `lib/features/settings/domain/repositories/settings_repository.dart`:
  - Import `fpdart` for `Either`, `failures.dart` for `Failure`, `app_settings.dart`
  - Create `abstract interface class SettingsRepository`
  - Method `AppSettings load()`
  - Method `Future<Either<Failure, void>> saveThemeMode(ThemeMode mode)`

**Done when**:
- [ ] `lib/features/settings/domain/entities/app_settings.dart` exists with `AppSettings` class, `themeMode` field, and `copyWith` method
- [ ] `lib/features/settings/domain/repositories/settings_repository.dart` exists with `abstract interface class SettingsRepository` declaring `load()` and `saveThemeMode()`
- [ ] `dart analyze lib/features/settings/domain/` passes with zero issues

**Spec criteria addressed**: AC-6 (single source of truth settings model), AC-7 (abstract repository in domain)

## Contracts

### Expects
- `lib/core/error/failures.dart` exports `sealed class Failure`
- `pubspec.yaml` contains `fpdart` in dependencies

### Produces
- `lib/features/settings/domain/entities/app_settings.dart` exports `class AppSettings` with field `final ThemeMode themeMode` and method `copyWith`
- `lib/features/settings/domain/repositories/settings_repository.dart` exports `abstract interface class SettingsRepository` with methods `load()` returning `AppSettings` and `saveThemeMode(ThemeMode mode)` returning `Future<Either<Failure, void>>`
