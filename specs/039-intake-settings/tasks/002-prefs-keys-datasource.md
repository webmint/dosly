# Task 002: Add prefs keys and data-source read/write for the 3 settings

**Agent**: architect
**Files**: `lib/core/providers/settings_prefs_keys.dart`, `lib/features/settings/data/datasources/settings_local_data_source.dart`
**Depends on**: 001
**Blocks**: 004, 010
**Context docs**: `specs/039-intake-settings/data-model.md`
**Review checkpoint**: No

**Description**:
Register three new SharedPreferences keys (auto-extending the cache allowlist via the `settingsPrefsKeys` set) and add the getter/setter pairs to `SettingsLocalDataSource`. Getters route the stored `int` through the VO factory so out-of-range persisted values are clamped on read; a missing key falls back to the VO default. Follow the existing `getUseSystemTheme`/`setUseSystemTheme` and `getManualLanguage` idioms; getters are **unguarded** (a wrong-type throw propagates to `SettingsRepositoryImpl.load`'s single catch — these are brand-new keys with no legacy data).

**Change details**:
- In `lib/core/providers/settings_prefs_keys.dart`:
  - Add `const String intakeWindowMinutesPrefsKey = 'intakeWindowMinutes';`, `const String gracePeriodMinutesPrefsKey = 'gracePeriodMinutes';`, `const String allowMarkAheadPrefsKey = 'allowMarkAhead';`.
  - Add all three to the `settingsPrefsKeys` set.
- In `lib/features/settings/data/datasources/settings_local_data_source.dart`:
  - Import the two VO files.
  - `IntakeWindow getIntakeWindow() => IntakeWindow(_prefs.getInt(intakeWindowMinutesPrefsKey) ?? IntakeWindow.defaultValue.minutes);`
  - `Future<void> setIntakeWindow(IntakeWindow value) => _prefs.setInt(intakeWindowMinutesPrefsKey, value.minutes);`
  - `GracePeriod getGracePeriod()` / `setGracePeriod(GracePeriod value)` — same shape.
  - `bool getAllowMarkAhead() => _prefs.getBool(allowMarkAheadPrefsKey) ?? false;`
  - `Future<void> setAllowMarkAhead(bool value) => _prefs.setBool(allowMarkAheadPrefsKey, value);`
  - Dartdoc each, matching the existing getters/setters.

**Contracts**:

### Expects
- `IntakeWindow` and `GracePeriod` exist with `static const defaultValue` and `int minutes` (Task 001).
- `settings_prefs_keys.dart` declares `settingsPrefsKeys` (a `Set<String>`) and the existing key consts.
- `SettingsLocalDataSource` holds a `SharedPreferencesWithCache _prefs` and already exposes `getBool`/`setBool`-style pairs.

### Produces
- `settings_prefs_keys.dart` declares `intakeWindowMinutesPrefsKey`, `gracePeriodMinutesPrefsKey`, `allowMarkAheadPrefsKey`, and the `settingsPrefsKeys` set contains all three.
- `settings_local_data_source.dart` declares `getIntakeWindow(`, `setIntakeWindow(`, `getGracePeriod(`, `setGracePeriod(`, `getAllowMarkAhead(`, `setAllowMarkAhead(`.
- `getIntakeWindow`/`getGracePeriod` construct their VO via the clamping factory (pass the raw stored int in).

**Done when**:
- [x] After `setIntakeWindow(IntakeWindow(90))`, `getIntakeWindow() == IntakeWindow(90)`; grace and bool round-trip likewise.
- [x] A raw stored `intakeWindowMinutes` of `500` → `IntakeWindow(240)`; `3` → `IntakeWindow(15)`; grace `99` → `GracePeriod(30)`; `-5` → `GracePeriod(0)`.
- [x] Missing keys → `IntakeWindow(120)` / `GracePeriod(5)` / `false`.
- [x] All three keys present in `settingsPrefsKeys`.
- [x] `dart analyze` passes on both files.

**Spec criteria addressed**: AC-5, AC-6, AC-7, AC-8

## Completion Notes
**Status**: Complete
**Completed**: 2026-07-03
**Files changed**: `lib/core/providers/settings_prefs_keys.dart`, `lib/features/settings/data/datasources/settings_local_data_source.dart`
**Contract**: Expects [verified] | Produces [all verified — 3 keys in set, 6 methods declared, clamp via VO factory]
**Code review**: APPROVE (no issues)
**Notes**: Getters reference canonical key constants directly (no `_k` aliases) — accepted style. Getters unguarded (mirror `getManualLanguage`); clamp centralized in the VO factory (no second clamp). Wiring into the repo is Task 004.
