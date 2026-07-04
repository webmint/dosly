/// Canonical SharedPreferences key names for the settings feature.
///
/// Single source of truth for the persisted settings keys, shared by the prefs
/// cache `allowList` (in `shared_preferences_provider.dart`) and the settings
/// data source's reads/writes. Centralising them here — a constants-only
/// library with no provider/codegen machinery — keeps the cache allowlist and
/// the data source from drifting apart on a rename without coupling the data
/// layer to a Riverpod provider file.
library;

/// SharedPreferences key for the user's manual theme-mode preference.
const String themeModePrefsKey = 'themeMode';

/// SharedPreferences key for the "follow system theme" flag.
const String useSystemThemePrefsKey = 'useSystemTheme';

/// SharedPreferences key for the "follow system language" flag.
const String useSystemLanguagePrefsKey = 'useSystemLanguage';

/// SharedPreferences key for the user's manual language choice (IETF code).
const String manualLanguagePrefsKey = 'manualLanguage';

/// SharedPreferences key for the intake window length, stored in minutes.
const String intakeWindowMinutesPrefsKey = 'intakeWindowMinutes';

/// SharedPreferences key for the grace period length, stored in minutes.
const String gracePeriodMinutesPrefsKey = 'gracePeriodMinutes';

/// SharedPreferences key for the "allow marking intakes ahead of time" flag.
const String allowMarkAheadPrefsKey = 'allowMarkAhead';

/// The complete set of settings keys permitted in the prefs cache.
///
/// The cache `allowList` MUST be a superset of every key the settings data
/// source reads or writes; deriving both from this one set guarantees it.
const Set<String> settingsPrefsKeys = <String>{
  themeModePrefsKey,
  useSystemThemePrefsKey,
  useSystemLanguagePrefsKey,
  manualLanguagePrefsKey,
  intakeWindowMinutesPrefsKey,
  gracePeriodMinutesPrefsKey,
  allowMarkAheadPrefsKey,
};
