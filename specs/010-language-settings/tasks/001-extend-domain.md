# Task 001: Extend domain layer with AppLanguage enum, AppSettings fields, and repository contract

**Status**: Complete
**Agent**: architect
**Files**:
- `lib/features/settings/domain/entities/app_language.dart` (NEW)
- `lib/features/settings/domain/entities/app_settings.dart` (MOD)
- `lib/features/settings/domain/repositories/settings_repository.dart` (MOD)

**Depends on**: None
**Blocks**: 002, 003, 004, 005
**Context docs**: None — task description is self-contained
**Review checkpoint**: No

## Description

Establish the domain layer for language settings: define the `AppLanguage` enum (the typed value object for the three currently-supported languages), extend `AppSettings` with two new fields (`useSystemLanguage`, `manualLanguage`) and an `effectiveLocale` getter, and extend the `SettingsRepository` abstract contract with two new save methods. This is purely additive — no existing fields, getters, or methods are renamed, removed, or behaviour-changed.

The enum stores native language names (`English`, `Deutsch`, `Українська`) on the enum itself so consumers (the `LanguageSelector` widget in Task 004 and downstream tests) can read them off `AppLanguage.values` without scattering literals across files. `effectiveLocale` returns `null` when the user has opted into device-locale mode, so `MaterialApp.locale` (wired in Task 003) stays null and Flutter falls through to the existing `localeResolutionCallback` in `app.dart` — preserving spec-009 device-locale resolution exactly.

## Change details

### `lib/features/settings/domain/entities/app_language.dart` — CREATE

Pure-Dart enum, no Flutter imports. Exact shape:

```dart
/// Languages currently supported by the app.
///
/// Each value carries its IETF language code ([code]) and a human-readable
/// label in its own native script ([nativeName]). Native names are NOT
/// translated — they are the universal convention for language pickers,
/// letting users find their language regardless of the currently-displayed
/// UI language.
library;

enum AppLanguage {
  /// English — fallback for unsupported device locales.
  en('en', 'English'),

  /// German.
  de('de', 'Deutsch'),

  /// Ukrainian.
  uk('uk', 'Українська');

  const AppLanguage(this.code, this.nativeName);

  /// IETF language code (lowercase, two letters) used to construct a [Locale].
  final String code;

  /// Human-readable label in the language's own script.
  ///
  /// Plain literal — never localised.
  final String nativeName;
}
```

### `lib/features/settings/domain/entities/app_settings.dart` — MOD

Add two `final` fields, default initialisers, and an `effectiveLocale` getter. Extend `copyWith` with the two new nullable params. Keep all existing fields, defaults, and the `effectiveThemeMode` getter exactly as they are.

Required additions:
- Import the new `app_language.dart` (relative path: `'app_language.dart'`).
- New constructor params:
  - `this.useSystemLanguage = true`
  - `this.manualLanguage = AppLanguage.en`
- New fields:
  - `final bool useSystemLanguage;`
  - `final AppLanguage manualLanguage;`
- New getter:
  ```dart
  /// The [Locale] to pass to [MaterialApp.locale].
  ///
  /// Returns `null` when [useSystemLanguage] is `true` so [MaterialApp]'s
  /// `localeResolutionCallback` runs and resolves the device locale (with
  /// the project's English fallback). Returns a non-null `Locale` derived
  /// from [manualLanguage] otherwise.
  Locale? get effectiveLocale =>
      useSystemLanguage ? null : Locale(manualLanguage.code);
  ```
- Extended `copyWith`:
  ```dart
  AppSettings copyWith({
    bool? useSystemTheme,
    ThemeMode? manualThemeMode,
    bool? useSystemLanguage,
    AppLanguage? manualLanguage,
  }) =>
      AppSettings(
        useSystemTheme: useSystemTheme ?? this.useSystemTheme,
        manualThemeMode: manualThemeMode ?? this.manualThemeMode,
        useSystemLanguage: useSystemLanguage ?? this.useSystemLanguage,
        manualLanguage: manualLanguage ?? this.manualLanguage,
      );
  ```

The library doc comment at the top of the file should be lightly extended to mention the language fields (one short sentence).

### `lib/features/settings/domain/repositories/settings_repository.dart` — MOD

Add two abstract method declarations. Keep the existing three methods unchanged. Required imports: add `import '../entities/app_language.dart';` next to the existing `app_settings.dart` import (relative path: `../entities/app_language.dart`).

New method declarations (in order, after `saveUseSystemTheme`):

```dart
/// Persists whether the app should follow the device language.
///
/// When `true`, [AppSettings.effectiveLocale] returns `null` and
/// [MaterialApp]'s `localeResolutionCallback` resolves the device locale.
Future<Either<Failure, void>> saveUseSystemLanguage(bool value);

/// Persists the user's manual [AppLanguage] choice.
///
/// Consulted only when [AppSettings.useSystemLanguage] is `false`.
Future<Either<Failure, void>> saveManualLanguage(AppLanguage language);
```

The class-level dartdoc should mention the language methods (one short addition).

## Done when

- [x] `lib/features/settings/domain/entities/app_language.dart` exists with `enum AppLanguage` declaring exactly three values (`en`, `de`, `uk`) and final fields `code` + `nativeName`.
- [x] `lib/features/settings/domain/entities/app_settings.dart` declares fields `useSystemLanguage` (default `true`) and `manualLanguage` (default `AppLanguage.en`), plus a `Locale? get effectiveLocale` getter that returns `null` when `useSystemLanguage` is `true` and `Locale(manualLanguage.code)` otherwise.
- [x] `AppSettings.copyWith` accepts `bool? useSystemLanguage` and `AppLanguage? manualLanguage` parameters and uses the `?? this.x` fall-through pattern for both.
- [x] `lib/features/settings/domain/repositories/settings_repository.dart` declares abstract methods `saveUseSystemLanguage(bool)` and `saveManualLanguage(AppLanguage)`, both returning `Future<Either<Failure, void>>`.
- [x] No `package:flutter/*` import is added to `app_language.dart` (constitution §2.1 — domain purity).
- [x] `dart analyze lib/features/settings/domain/` exits with zero issues.

## Spec criteria addressed

AC-1, AC-2, AC-3 (partial — repository contract only; impl in Task 002).

## Completion Notes

**Completed**: 2026-04-27
**Files changed**:
- `lib/features/settings/domain/entities/app_language.dart` (NEW)
- `lib/features/settings/domain/entities/app_settings.dart` (MOD)
- `lib/features/settings/domain/repositories/settings_repository.dart` (MOD)

**Contract**: Expects 3/3 verified | Produces 4/4 verified

**Notes**:
- Pure additive change — no existing fields, getters, or methods touched.
- `dart analyze lib/features/settings/domain/` passes cleanly. Whole-repo `dart analyze` surfaces ~6 expected errors in data layer (`SettingsRepositoryImpl`) and a couple of test fakes that don't yet implement the two new abstract methods — Tasks 002 and 005 will resolve.
- Code review: APPROVE WITH WARNINGS. Reviewer flagged a duplicate library-level vs. enum-level doc comment in `app_language.dart`; trimmed the redundant enum-level `///` to leave the substantive description on the `library` directive only.
- Pre-existing `package:flutter/material.dart` import in `app_settings.dart` (for `ThemeMode`, transitively `Locale`) — accepted compromise from spec 009, not deepened by this task.

## Contracts

### Expects
- `lib/features/settings/domain/entities/app_settings.dart` exists with class `AppSettings` declaring fields `useSystemTheme: bool` (default `true`) and `manualThemeMode: ThemeMode` (default `ThemeMode.light`), and getter `effectiveThemeMode`.
- `lib/features/settings/domain/repositories/settings_repository.dart` exists with abstract class `SettingsRepository` declaring `AppSettings load()`, `Future<Either<Failure, void>> saveThemeMode(ThemeMode mode)`, and `Future<Either<Failure, void>> saveUseSystemTheme(bool value)`.
- `lib/core/error/failures.dart` exports `Failure` and `CacheFailure`.

### Produces
- `lib/features/settings/domain/entities/app_language.dart` exports `enum AppLanguage` with values `en`, `de`, `uk`. Each value declares a `final String code` and `final String nativeName` (constants: `'English'`, `'Deutsch'`, `'Українська'`).
- `AppSettings` declares `final bool useSystemLanguage` and `final AppLanguage manualLanguage`, and a `Locale? get effectiveLocale` whose body returns `useSystemLanguage ? null : Locale(manualLanguage.code)`.
- `AppSettings.copyWith` accepts `bool? useSystemLanguage` and `AppLanguage? manualLanguage`.
- `SettingsRepository` declares abstract methods named `saveUseSystemLanguage(bool value)` and `saveManualLanguage(AppLanguage language)`, each returning `Future<Either<Failure, void>>`.
