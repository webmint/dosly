# Task 003: Extend SettingsNotifier and wire MaterialApp.locale

**Status**: Complete
**Agent**: architect
**Files**:
- `lib/features/settings/presentation/providers/settings_provider.dart` (MOD)
- `lib/main.dart` (MOD)
- `lib/app.dart` (MOD)

**Depends on**: 002 (and transitively 001)
**Blocks**: 004, 005
**Context docs**: None
**Review checkpoint**: Yes — convergence (depends on 001 + 002) and layer crossing (data → presentation/wiring)

## Description

Wire the new domain + data layer into the running app. Three files change in lock-step:

1. `SettingsNotifier` (`settings_provider.dart`) gains two new public methods (`setUseSystemLanguage`, `setManualLanguage`) that persist via the repository and update reactive state on success — exactly the same shape as `setThemeMode` / `setUseSystemTheme`, including the `kDebugMode`-guarded `debugPrint` on failure.
2. `main.dart` extends the `SharedPreferencesWithCache` allowList from `{'themeMode', 'useSystemTheme'}` to also include `'useSystemLanguage'` and `'manualLanguage'`. Without this extension, the new keys silently fail to cache and the data source would throw at runtime.
3. `app.dart` adds a `locale:` parameter to `MaterialApp.router(...)` that watches `settingsProvider.select((s) => s.effectiveLocale)`. The existing `localeResolutionCallback` is left untouched — it remains the resolver when `effectiveLocale` is `null` (default = follow device locale).

This is a hard convergence point — the spec's behaviour is observable end-to-end only after all three files are updated together.

## Change details

### `lib/features/settings/presentation/providers/settings_provider.dart` — MOD

Add `import '../../domain/entities/app_language.dart';` to the imports (sorted alphabetically with the existing relative imports).

After `setUseSystemTheme`, append two new methods that mirror its exact shape (try/fold/`kDebugMode`-`debugPrint`/state-update-only-on-Right):

```dart
/// Updates whether the app should follow the device language, persists the
/// choice, and notifies listeners.
///
/// On persistence failure the in-memory state is not updated.
Future<void> setUseSystemLanguage(bool value) async {
  final repo = ref.read(settingsRepositoryProvider);
  final result = await repo.saveUseSystemLanguage(value);
  result.fold(
    (failure) {
      if (kDebugMode) {
        debugPrint('Settings: persistence failed — $failure');
      }
    },
    (_) {
      state = state.copyWith(useSystemLanguage: value);
    },
  );
}

/// Updates the manual language, persists it, and notifies listeners.
///
/// On persistence failure the in-memory state is not updated.
Future<void> setManualLanguage(AppLanguage language) async {
  final repo = ref.read(settingsRepositoryProvider);
  final result = await repo.saveManualLanguage(language);
  result.fold(
    (failure) {
      if (kDebugMode) {
        debugPrint('Settings: persistence failed — $failure');
      }
    },
    (_) {
      state = state.copyWith(manualLanguage: language);
    },
  );
}
```

The class-level dartdoc may receive a one-line mention of language methods.

### `lib/main.dart` — MOD

Change the literal:

```dart
allowList: <String>{'themeMode', 'useSystemTheme'},
```

to:

```dart
allowList: <String>{
  'themeMode',
  'useSystemTheme',
  'useSystemLanguage',
  'manualLanguage',
},
```

No other changes. The async init flow stays exactly as it is.

### `lib/app.dart` — MOD

Inside `DoslyApp.build`, the `MaterialApp.router(...)` call gets one new named argument adjacent to `themeMode:`:

```dart
return MaterialApp.router(
  title: 'dosly',
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: ref.watch(settingsProvider.select((s) => s.effectiveLocale)),
  localeResolutionCallback: _resolveLocale,
  debugShowCheckedModeBanner: false,
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ref.watch(
    settingsProvider.select((s) => s.effectiveThemeMode),
  ),
  routerConfig: appRouter,
);
```

The library-level dartdoc at the top of `app.dart` should add one short sentence noting that `MaterialApp.locale` is now driven by the user's settings (with the existing `localeResolutionCallback` as the fallback when the user has opted into device-locale mode). `_resolveLocale` is unchanged.

## Done when

- [x] `SettingsNotifier` declares public `Future<void> setUseSystemLanguage(bool value)` and `Future<void> setManualLanguage(AppLanguage language)`, each: (a) calling `ref.read(settingsRepositoryProvider).saveX(...)`, (b) using `result.fold(...)` to handle both branches, (c) on `Right` updating `state = state.copyWith(...)`, (d) on `Left` invoking `debugPrint(...)` guarded by `kDebugMode`.
- [x] `lib/main.dart`'s `SharedPreferencesWithCache.create(...)` `allowList` set contains `'useSystemLanguage'` and `'manualLanguage'` (in addition to the existing two keys).
- [x] `MaterialApp.router(...)` in `lib/app.dart` is configured with `locale: ref.watch(settingsProvider.select((s) => s.effectiveLocale))`.
- [x] `_resolveLocale` and `localeResolutionCallback: _resolveLocale` in `lib/app.dart` are unchanged from their current form.
- [x] `dart analyze lib/main.dart lib/app.dart lib/features/settings/presentation/providers/settings_provider.dart` exits with zero issues.
- [x] No `print()` / `debugPrint()` site is added outside the existing `kDebugMode`-guarded log line pattern.

## Spec criteria addressed

AC-5, AC-6, AC-7.

## Completion Notes

**Completed**: 2026-04-27
**Files changed**:
- `lib/features/settings/presentation/providers/settings_provider.dart` (MOD)
- `lib/main.dart` (MOD)
- `lib/app.dart` (MOD)

**Contract**: Expects 8/8 verified | Produces 4/4 verified

**Notes**:
- Convergence checkpoint executed cleanly — all three files wire end-to-end. New notifier methods are byte-equivalent in structure to `setUseSystemTheme` / `setThemeMode`. `_resolveLocale` body and registration byte-for-byte unchanged.
- `dart analyze lib/` exits with zero issues.
- Code review: APPROVE. Reviewer flagged a cosmetic argument-order deviation in `app.dart` (`locale:` placed after `theme`/`darkTheme` rather than between `supportedLocales` and `localeResolutionCallback`) — no runtime impact, accepted as-is.
- `MaterialApp.locale` correctly receives `Locale?` from `effectiveLocale` getter; no implicit cast.

## Contracts

### Expects
- `AppLanguage` enum exists (Task 001 → Produces).
- `AppSettings.copyWith` accepts `bool? useSystemLanguage` and `AppLanguage? manualLanguage` (Task 001 → Produces).
- `AppSettings.effectiveLocale` returns `Locale?` (Task 001 → Produces).
- `SettingsRepository` declares abstract `saveUseSystemLanguage(bool)` and `saveManualLanguage(AppLanguage)` (Task 001 → Produces).
- `SettingsRepositoryImpl` implements both new save methods with `Right(null)` / `Left(CacheFailure)` shape (Task 002 → Produces).
- `SettingsLocalDataSource` reads/writes the new keys (Task 002 → Produces).
- Existing `SettingsNotifier` extends `Notifier<AppSettings>` and exposes `setThemeMode` / `setUseSystemTheme` with the documented `kDebugMode`-`debugPrint` failure shape (current codebase state).
- Existing `lib/main.dart` calls `SharedPreferencesWithCache.create(cacheOptions: SharedPreferencesWithCacheOptions(allowList: <String>{'themeMode', 'useSystemTheme'}))` (current codebase state).
- Existing `lib/app.dart` `MaterialApp.router(...)` declares `localizationsDelegates`, `supportedLocales`, `localeResolutionCallback: _resolveLocale`, `themeMode: ref.watch(settingsProvider.select((s) => s.effectiveThemeMode))`, and `routerConfig: appRouter` (current codebase state).

### Produces
- `lib/features/settings/presentation/providers/settings_provider.dart`'s `SettingsNotifier` class declares public methods named `setUseSystemLanguage` and `setManualLanguage`, each `Future<void>`, each containing `state = state.copyWith(...)` inside the `Right` fold branch and a `kDebugMode`-guarded `debugPrint(...)` in the `Left` branch.
- `lib/main.dart`'s `SharedPreferencesWithCache.create(...)` `allowList` set literal contains the four strings `'themeMode'`, `'useSystemTheme'`, `'useSystemLanguage'`, `'manualLanguage'`.
- `lib/app.dart`'s `MaterialApp.router(...)` invocation includes a `locale:` argument whose value is `ref.watch(settingsProvider.select((s) => s.effectiveLocale))`.
- `lib/app.dart`'s `localeResolutionCallback: _resolveLocale` line and the `_resolveLocale` function body are unchanged.
