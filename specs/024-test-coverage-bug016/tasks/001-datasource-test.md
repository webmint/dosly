# Task 001: Add SettingsLocalDataSource unit tests

**Agent**: qa-engineer
**Status**: Complete
**Files**: `test/features/settings/data/datasources/settings_local_data_source_test.dart`
**Depends on**: None
**Blocks**: 005
**Context docs**: None
**Review checkpoint**: No

## Completion Notes

**Completed**: 2026-05-27
**Files changed**: test/features/settings/data/datasources/settings_local_data_source_test.dart (new, 15 tests / 8 groups)
**Contract**: Expects [3/3 verified] | Produces [3/3 verified]
**Notes**: The legacy-`int` `catch (_)` branch in `getThemeMode()` is NOT reachable
via `InMemorySharedPreferencesAsync` — the in-memory platform does not throw a
`TypeError` on an int stored under a String key. Substituted an unrecognized
string code (`'legacy'`) that drives the SAME `AppThemeMode.light` outcome through
`fromCodeOrDefault`'s `orElse` default, with a `//` comment + accurate test name
documenting the substitution. Net: the `catch` branch remains uncovered by design
(harness limitation); the graceful-degrade outcome it guards IS covered. Code
review APPROVE-with-warnings; both warnings (misleading name, allowList sync
comment) fixed.

**Description**:
Create the missing 1:1 test mirror for `SettingsLocalDataSource`
(constitution §3.4 mandates data-layer coverage). Cover all six public
methods, including the branches Bug 016 sub-items 1, 2, and 10 flag as
untested: the legacy-`int` `catch (_)` fallback in `getThemeMode()`, the
`null` / empty / unknown-code paths of `getManualLanguage()`, and the
`?? true` defaults of the two `getUseSystem*` getters. Follow the proven
in-memory prefs harness from
`test/features/settings/data/repositories/settings_repository_impl_test.dart:14-38`
(MEMORY L112) — do NOT use the legacy `setMockInitialValues` API.

**Change details**:
- Create `test/features/settings/data/datasources/settings_local_data_source_test.dart`:
  - Build a fresh `SharedPreferencesWithCache` per test via
    `SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.withData({...})`
    (or `.empty()`) then `SharedPreferencesWithCache.create(cacheOptions: ...)`
    using the same 4-key allowList `{'themeMode', 'useSystemTheme', 'useSystemLanguage', 'manualLanguage'}`.
  - `getThemeMode()`: (a) stored valid code `'dark'` → `AppThemeMode.dark`;
    (b) absent key → `AppThemeMode.light`; (c) legacy-`int` data
    `withData({'themeMode': 1})` → the `catch (_)` returns `AppThemeMode.light`.
  - `getManualLanguage()`: `null` (absent) → `AppLanguage.en`; unknown/empty
    stored code (`''` or `'zz'`) → default `AppLanguage.en`; valid stored code
    (`'uk'`) → `AppLanguage.uk`.
  - `getUseSystemTheme()` / `getUseSystemLanguage()`: absent key → `true`;
    stored `false` → `false`.
  - Round-trip each setter: `setThemeMode`, `setUseSystemTheme`,
    `setUseSystemLanguage`, `setManualLanguage` → write then read back the
    matching getter and assert the persisted value.
  - Group names per §3.4: describe the method + scenario.

**Done when**:
- [ ] The test file exists and all listed scenarios are present as `test(...)` cases.
- [ ] The legacy-`int` case asserts `AppThemeMode.light` (if seeding an int does not throw in `getString`, fall back to a faithful degrade case — e.g. a non-matching string — and note it in the completion notes).
- [ ] No `setMockInitialValues`, no `await Future.delayed`, no real `DateTime.now()`; each test is isolated.
- [ ] `flutter test test/features/settings/data/datasources/settings_local_data_source_test.dart` passes.
- [ ] `dart analyze` passes on the changed file.

**Spec criteria addressed**: AC-1, AC-2, AC-3, AC-4

## Contracts

### Expects
- `lib/features/settings/data/datasources/settings_local_data_source.dart` exports class `SettingsLocalDataSource` with methods `getThemeMode`, `setThemeMode`, `getUseSystemTheme`, `setUseSystemTheme`, `getUseSystemLanguage`, `setUseSystemLanguage`, `getManualLanguage`, `setManualLanguage`.
- `AppThemeMode` exposes `light` and `dark`; `AppLanguage` exposes `en` and `uk`.
- `package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart` provides `InMemorySharedPreferencesAsync`.

### Produces
- `test/features/settings/data/datasources/settings_local_data_source_test.dart` exists and imports `package:dosly/features/settings/data/datasources/settings_local_data_source.dart`.
- The file references `InMemorySharedPreferencesAsync` and `SharedPreferencesWithCache.create`.
- The file contains a test seeding legacy-`int` `themeMode` data and asserting the `AppThemeMode.light` fallback.
