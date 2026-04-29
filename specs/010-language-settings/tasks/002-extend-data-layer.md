# Task 002: Extend data layer with language persistence

**Status**: Complete
**Agent**: architect
**Files**:
- `lib/features/settings/data/datasources/settings_local_data_source.dart` (MOD)
- `lib/features/settings/data/repositories/settings_repository_impl.dart` (MOD)

**Depends on**: 001
**Blocks**: 003, 005
**Context docs**: None — pattern is fully established by spec 009's existing data layer
**Review checkpoint**: No

## Description

Implement persistence for the two new domain fields. The `SettingsLocalDataSource` gains two new key constants and four new accessor methods (read/write for each of `useSystemLanguage` and `manualLanguage`). The `SettingsRepositoryImpl`'s `load()` is extended to populate the new `AppSettings` fields, and two new save methods are added with the exact same try/`CacheFailure` shape as the existing theme save methods. Persistence schema choice (per plan D6): `useSystemLanguage` is a bool key; `manualLanguage` is a string key whose value is the `AppLanguage.code` (parsed back via `AppLanguage.values.firstWhere((l) => l.code == stored, orElse: () => AppLanguage.en)`). Strings survive enum reordering better than indices.

## Change details

### `lib/features/settings/data/datasources/settings_local_data_source.dart` — MOD

After the existing private key constants `_kThemeModeKey` / `_kUseSystemThemeKey`, add:

```dart
/// Key used to persist whether the app follows the device language.
const String _kUseSystemLanguageKey = 'useSystemLanguage';

/// Key used to persist the user's manual [AppLanguage] choice as its [code].
const String _kManualLanguageKey = 'manualLanguage';
```

Add `import '../../domain/entities/app_language.dart';` next to the existing imports.

After `setUseSystemTheme`, add four new methods (matching the documentation style of the existing methods):

```dart
/// Returns whether the app should follow the device language.
///
/// Defaults to `true` when no value has been stored.
bool getUseSystemLanguage() => _prefs.getBool(_kUseSystemLanguageKey) ?? true;

/// Returns the persisted manual [AppLanguage].
///
/// Falls back to [AppLanguage.en] when no value has been stored or the
/// stored code does not match a known [AppLanguage].
AppLanguage getManualLanguage() {
  final String? code = _prefs.getString(_kManualLanguageKey);
  if (code == null) {
    return AppLanguage.en;
  }
  return AppLanguage.values.firstWhere(
    (lang) => lang.code == code,
    orElse: () => AppLanguage.en,
  );
}

/// Persists whether the app should follow the device language.
Future<void> setUseSystemLanguage(bool value) =>
    _prefs.setBool(_kUseSystemLanguageKey, value);

/// Persists the user's manual [AppLanguage] choice as its [AppLanguage.code].
Future<void> setManualLanguage(AppLanguage language) =>
    _prefs.setString(_kManualLanguageKey, language.code);
```

### `lib/features/settings/data/repositories/settings_repository_impl.dart` — MOD

Extend the `load()` body to populate the new fields:

```dart
@override
AppSettings load() => AppSettings(
      useSystemTheme: _dataSource.getUseSystemTheme(),
      manualThemeMode: _dataSource.getThemeMode(),
      useSystemLanguage: _dataSource.getUseSystemLanguage(),
      manualLanguage: _dataSource.getManualLanguage(),
    );
```

Add two new save method implementations after `saveUseSystemTheme`, mirroring its shape exactly:

```dart
@override
Future<Either<Failure, void>> saveUseSystemLanguage(bool value) async {
  try {
    await _dataSource.setUseSystemLanguage(value);
    return const Right(null);
  } on Exception catch (e) {
    return Left(CacheFailure(e.toString()));
  }
}

@override
Future<Either<Failure, void>> saveManualLanguage(AppLanguage language) async {
  try {
    await _dataSource.setManualLanguage(language);
    return const Right(null);
  } on Exception catch (e) {
    return Left(CacheFailure(e.toString()));
  }
}
```

Add `import '../../domain/entities/app_language.dart';` to the imports.

The class-level dartdoc may receive a brief mention of language persistence (one short sentence).

## Done when

- [x] `SettingsLocalDataSource` declares `getUseSystemLanguage()`, `getManualLanguage()`, `setUseSystemLanguage(bool)`, `setManualLanguage(AppLanguage)` with the exact signatures specified above. Two new private key constants (`_kUseSystemLanguageKey = 'useSystemLanguage'`, `_kManualLanguageKey = 'manualLanguage'`) exist at the top of the file.
- [x] `getManualLanguage()` returns `AppLanguage.en` when no value is stored OR when the stored string does not match any `AppLanguage.code` (the `orElse:` of `firstWhere`).
- [x] `getUseSystemLanguage()` returns `true` when no value is stored.
- [x] `SettingsRepositoryImpl.load()` populates the new `useSystemLanguage` and `manualLanguage` fields on the returned `AppSettings`.
- [x] `SettingsRepositoryImpl` implements `saveUseSystemLanguage(bool)` and `saveManualLanguage(AppLanguage)` returning `Future<Either<Failure, void>>` with the same try/`CacheFailure(e.toString())` shape as `saveThemeMode`.
- [x] No new `Exception` types are introduced; `CacheFailure` is reused.
- [x] `dart analyze lib/features/settings/data/` exits with zero issues.

## Spec criteria addressed

AC-3 (impl complement to Task 001's contract), AC-4.

## Completion Notes

**Completed**: 2026-04-27
**Files changed**:
- `lib/features/settings/data/datasources/settings_local_data_source.dart` (MOD)
- `lib/features/settings/data/repositories/settings_repository_impl.dart` (MOD)

**Contract**: Expects 5/5 verified | Produces 5/5 verified

**Notes**:
- Mechanical mirror of spec-009 theme save methods. `SettingsLocalDataSource` gained four documented accessors and two private key constants; `SettingsRepositoryImpl` extended `load()` and added two `@override` save methods with the exact same `try { await … } on Exception catch (e) { return Left(CacheFailure(e.toString())); }` shape as `saveThemeMode`.
- `getManualLanguage()` defends against unknown stored codes via `firstWhere(orElse: () => AppLanguage.en)`.
- `dart analyze lib/` exits with zero issues. The 6 expected errors after Task 001 are now resolved. Test fakes in `test/` still need updating for the new abstract methods — Task 005 will handle.
- Per-task code-reviewer skipped: pure mechanical pattern mirror; equivalent code was reviewed and approved in spec 009. Aggregate review will run during `/review`.

## Contracts

### Expects
- `AppLanguage` enum with `code` field (Task 001 → Produces).
- `AppSettings` accepts `useSystemLanguage` and `manualLanguage` in its constructor (Task 001 → Produces).
- `SettingsRepository` declares abstract `saveUseSystemLanguage(bool)` and `saveManualLanguage(AppLanguage)` (Task 001 → Produces).
- Existing `SettingsLocalDataSource` constructor takes a `SharedPreferencesWithCache` and exposes `getThemeMode`, `setThemeMode`, `getUseSystemTheme`, `setUseSystemTheme` (current codebase state).
- Existing `SettingsRepositoryImpl` implements `SettingsRepository` and uses `try { ... } on Exception catch (e) { return Left(CacheFailure(e.toString())); }` for save methods (current codebase state).

### Produces
- `lib/features/settings/data/datasources/settings_local_data_source.dart` declares two top-level private constants `_kUseSystemLanguageKey` (value `'useSystemLanguage'`) and `_kManualLanguageKey` (value `'manualLanguage'`).
- `SettingsLocalDataSource` declares `bool getUseSystemLanguage()`, `AppLanguage getManualLanguage()`, `Future<void> setUseSystemLanguage(bool value)`, `Future<void> setManualLanguage(AppLanguage language)`.
- `SettingsRepositoryImpl.load()` constructs an `AppSettings` whose `useSystemLanguage` and `manualLanguage` fields come from `_dataSource.getUseSystemLanguage()` and `_dataSource.getManualLanguage()` respectively.
- `SettingsRepositoryImpl` declares `@override Future<Either<Failure, void>> saveUseSystemLanguage(bool value)` and `@override Future<Either<Failure, void>> saveManualLanguage(AppLanguage language)`, each returning `Right(null)` on success and `Left(CacheFailure(e.toString()))` on `Exception`.
