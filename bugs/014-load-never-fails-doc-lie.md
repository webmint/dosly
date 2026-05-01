# Bug 014: `SettingsRepository.load()` claims "Never fails" but cannot honor the contract

**Status**: Open
**Severity**: Warning
**Source**: audit (audits/2026-04-30-audit.md)
**Reported**: 2026-04-30
**Fixed**:

## Description

Constitution §3.2: "Every repository implementation catches its data-source
exceptions and returns `Left(Failure.x(...))`. Exceptions NEVER escape the
data layer."

`SettingsRepository.load()` returns `AppSettings` directly (not
`Either<Failure, AppSettings>`). The dartdoc claims "Never fails — returns
defaults if nothing is stored." But the implementation
(`SettingsRepositoryImpl.load()`) calls `_dataSource.getInt`/`getString`/`getBool`
in a chain — every one of which can throw if `SharedPreferencesWithCache` is
in a bad state (cache corruption, platform-channel error during hot-restart
edge cases, decoded-int range error on the `ThemeMode.values[index]` path
despite the bounds check).

There is no `try/catch` around the `load()` chain in
`SettingsRepositoryImpl`, so the "Never fails" comment is a claim the
implementation cannot rigorously honor. It's a lie waiting to be exposed at
runtime.

## File(s)

| File | Detail |
|------|--------|
| lib/features/settings/domain/repositories/settings_repository.dart | Lines 17–20 (`load()` declaration + dartdoc) |
| lib/features/settings/data/repositories/settings_repository_impl.dart | Lines 21–27 (`load()` impl — no try/catch) |
| lib/features/settings/data/datasources/settings_local_data_source.dart | Lines 37–43, 52, 61, 67–76 (chain that can throw) |

## Evidence

`lib/features/settings/domain/repositories/settings_repository.dart:16–20`:
```
abstract interface class SettingsRepository {
  /// Loads current settings synchronously from cache.
  ///
  /// Never fails — returns defaults if nothing is stored.
  AppSettings load();
```

`lib/features/settings/data/repositories/settings_repository_impl.dart:21–27`:
```
  @override
  AppSettings load() => AppSettings(
        useSystemTheme: _dataSource.getUseSystemTheme(),
        manualThemeMode: _dataSource.getThemeMode(),
        useSystemLanguage: _dataSource.getUseSystemLanguage(),
        manualLanguage: _dataSource.getManualLanguage(),
      );
```

(No try/catch.)

Reported by audit (architect F12).

## Fix Notes

Two options (to be confirmed in `/fix`):

**Option A (preferred — honor the constitution invariant):** change `load()` to
`Either<Failure, AppSettings> load()`. `fpdart` supports synchronous Either,
so the signature stays sync. Notifier uses `.fold(...)` to extract.

**Option B (minimal change — make the doc honest):** wrap the impl in a
`try/catch (_)` that returns the default `AppSettings()` constant on any
throw. Update the dartdoc to: "Never throws — returns the default
[AppSettings] on any underlying error." Pair with the typed logger (bug 002)
to log the swallowed exception so failures don't disappear silently.

Option A is the canonical fix; Option B is acceptable as a stop-gap if Option
A is too invasive in the current refactor wave.
