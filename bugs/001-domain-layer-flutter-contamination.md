# Bug 001: Domain layer Flutter contamination + ThemeMode persistence drift

**Status**: Open
**Severity**: Critical
**Source**: audit (audits/2026-04-30-audit.md)
**Reported**: 2026-04-30
**Fixed**:

## Description

The Settings feature's domain layer imports `package:flutter/material.dart` and
exposes `ThemeMode` (a Flutter SDK type) as a domain-model field. This violates
constitution §2.1 (`FORBIDDEN imports in domain/: anything from package:flutter/*`)
and §4.2.1 (`Never put package:flutter/* imports in lib/features/*/domain/.
Domain must run in pure Dart tests with no Flutter binding`).

Two domain files are affected:
- `lib/features/settings/domain/entities/app_settings.dart:11`
- `lib/features/settings/domain/repositories/settings_repository.dart:4`

The contamination flows through to the data layer
(`settings_local_data_source.dart:5` also imports Flutter, persisting
`ThemeMode.index` as the storage value — coupling the on-disk format to the
order of values in Flutter's `ThemeMode` enum). And to presentation, where
`AppSettings.effectiveLocale` returns a `Locale?`.

The `AppSettings` class is also hand-rolled (no `@freezed`), violating §3.1
(`All entities, DTOs, and state classes use freezed — never hand-roll ==,
hashCode, or copyWith`). Missing `==`/`hashCode` means `ref.watch(settingsProvider
.select(...))` cannot dedup rebuilds by value-equality — every `state =
state.copyWith(...)` triggers all watchers regardless of whether the selected
field changed.

The `SettingsRepository.saveUseSystemLanguage` dartdoc even names
`MaterialApp.localeResolutionCallback` — UI-framework knowledge embedded in a
domain interface.

## File(s)

| File | Detail |
|------|--------|
| lib/features/settings/domain/entities/app_settings.dart | Line 11 (Flutter import); line 27 (hand-rolled class); lines 44, 60, 68 (ThemeMode/Locale fields) |
| lib/features/settings/domain/repositories/settings_repository.dart | Line 4 (Flutter import); lines 25, 32–33 (ThemeMode parameter + MaterialApp dartdoc reference) |
| lib/features/settings/data/datasources/settings_local_data_source.dart | Line 5 (Flutter import — dependent); lines 37–47 (ThemeMode.index persistence) |
| lib/features/settings/data/repositories/settings_repository_impl.dart | Lines 4, 22–24, 30 (ThemeMode parameter + load() chain — dependent) |

## Evidence

`lib/features/settings/domain/entities/app_settings.dart:11`:
```
import 'package:flutter/material.dart';
```

`lib/features/settings/domain/repositories/settings_repository.dart:4`:
```
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
```

`lib/features/settings/domain/entities/app_settings.dart:20`:
```
class AppSettings {
```
(hand-rolled — no `@freezed` annotation)

`lib/features/settings/data/datasources/settings_local_data_source.dart:46–47`:
```
  Future<void> setThemeMode(ThemeMode mode) =>
      _prefs.setInt(_kThemeModeKey, mode.index);
```
(persists `mode.index` — `ThemeMode.values == [system, light, dark]`; nothing
prevents storing index 0, which loads as `manualThemeMode = ThemeMode.system`,
contradicting `AppSettings.manualThemeMode` dartdoc.)

## Fix Notes

Suggested approach (to be confirmed in `/fix`):

1. Add `freezed` + `freezed_annotation` to `pubspec.yaml` (constitution §7.3).
2. Define `enum AppThemeMode { light, dark, system }` in
   `lib/features/settings/domain/entities/app_theme_mode.dart` (pure Dart).
3. Convert `AppSettings` to `@freezed` and replace `ThemeMode` with `AppThemeMode`.
   Replace `Locale? get effectiveLocale` with a domain-typed return (e.g.
   nullable `AppLanguage` or `String? languageCode`).
4. Update `SettingsRepository` contract: replace `ThemeMode` param with
   `AppThemeMode`. Strip `MaterialApp.localeResolutionCallback` reference from
   dartdoc — describe behavior in domain terms only.
5. Persist `AppThemeMode` as a stable string code (`'light'`, `'dark'`,
   `'system'`) in `settings_local_data_source.dart` — same pattern already used
   for `AppLanguage.code`. The Flutter import in the data source disappears.
6. Map `AppThemeMode <-> ThemeMode` only at the presentation seam
   (`app.dart` build method).
7. Run `dart run build_runner build --delete-conflicting-outputs`.
8. Update tests accordingly.

This bug bundles the related drift-protection findings — fixing it together
keeps the migration coherent. Splitting would cause cascading cross-PR churn.
