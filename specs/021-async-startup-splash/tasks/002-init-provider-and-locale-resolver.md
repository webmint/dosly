# Task 002: Add async prefs init provider + extract shared locale resolver

**Agent**: architect
**Files**: `lib/core/providers/shared_preferences_provider.dart` (+ regenerated `.g.dart`), `lib/core/l10n/locale_resolver.dart` (new), `lib/app.dart`
**Depends on**: None
**Blocks**: 004
**Context docs**: `docs/architecture.md` (Bootstrap + provider-wiring sections)
**Review checkpoint**: No
**Status**: Complete

## Description

Establish the two foundations the bootstrap widget depends on, with **no UI**:

1. **Async initializer** — add `sharedPreferencesInitProvider`, a function-form `@riverpod` provider returning `Future<SharedPreferencesWithCache>` that performs `SharedPreferencesWithCache.create(...)` with the existing allowList. This is the async + testable seam. Function-form `@riverpod` emits `sharedPreferencesInitProvider` directly — **no `name:` parameter** (MEMORY L144; only class-form notifiers need `name:`). Leave the existing synchronous, throwing `sharedPreferences` provider unchanged — it remains the override-injected sync accessor the settings tree reads.

2. **Shared locale resolver** — move the English-fallback resolution policy out of `lib/app.dart`'s private `_resolveLocale` into a new public top-level function `resolveAppLocale` in `lib/core/l10n/locale_resolver.dart` (verbatim body + dartdoc). Update `app.dart` to import and use it. This is the single production source of truth so the bootstrap shell (Task 004) can reuse the same policy without a second copy. (The 7 private `_resolveLocale` copies in test harnesses are pre-existing and out of scope — do not touch them.)

Run `dart run build_runner build --delete-conflicting-outputs` to regenerate the provider `.g.dart`.

## Change details

- In `lib/core/providers/shared_preferences_provider.dart`:
  - Add a function-form provider below the existing `sharedPreferences` function:
    ```dart
    /// Asynchronously creates the application-wide [SharedPreferencesWithCache].
    /// ...dartdoc explaining this is the async seam gated by AppBootstrap...
    @riverpod
    Future<SharedPreferencesWithCache> sharedPreferencesInit(Ref ref) =>
        SharedPreferencesWithCache.create(
          cacheOptions: const SharedPreferencesWithCacheOptions(
            allowList: <String>{
              'themeMode', 'useSystemTheme', 'useSystemLanguage', 'manualLanguage',
            },
          ),
        );
    ```
  - Keep the existing throwing `sharedPreferences` provider intact. Update the library dartdoc to mention both providers (the async initializer creates prefs; the sync provider is override-injected from the resolved value).
- Create `lib/core/l10n/locale_resolver.dart`:
  - Top-level `Locale resolveAppLocale(Locale? deviceLocale, Iterable<Locale> supportedLocales)` — body and dartdoc moved verbatim from `app.dart._resolveLocale` (English fallback, languageCode match).
- In `lib/app.dart`:
  - Remove the private `_resolveLocale` function.
  - Add `import 'core/l10n/locale_resolver.dart';`.
  - Change `localeResolutionCallback: _resolveLocale` → `localeResolutionCallback: resolveAppLocale`.
  - Update the library dartdoc reference from `[_resolveLocale]` to `[resolveAppLocale]`.
- Run `dart run build_runner build --delete-conflicting-outputs`.

## Contracts

### Expects
- `lib/core/providers/shared_preferences_provider.dart` declares the function `sharedPreferences` annotated `@Riverpod(keepAlive: true)` and `part 'shared_preferences_provider.g.dart';`.
- `lib/app.dart` declares `_resolveLocale` and passes `localeResolutionCallback: _resolveLocale` to `MaterialApp.router`.

### Produces
- `lib/core/providers/shared_preferences_provider.dart` declares `Future<SharedPreferencesWithCache> sharedPreferencesInit(Ref ref)` annotated `@riverpod`.
- `lib/core/providers/shared_preferences_provider.g.dart` declares `sharedPreferencesInitProvider`.
- `lib/core/l10n/locale_resolver.dart` declares top-level `Locale resolveAppLocale(Locale? deviceLocale, Iterable<Locale> supportedLocales)`.
- `lib/app.dart` imports `resolveAppLocale` from `core/l10n/locale_resolver.dart`, passes `localeResolutionCallback: resolveAppLocale`, and no longer declares `_resolveLocale`.

## Done when
- [x] `sharedPreferencesInitProvider` is generated and resolvable (no `name:` parameter on the annotation).
- [x] The existing synchronous throwing `sharedPreferences` provider is unchanged.
- [x] `resolveAppLocale` exists in `lib/core/l10n/locale_resolver.dart` with the verbatim English-fallback behavior.
- [x] `lib/app.dart` compiles using `resolveAppLocale`; no `_resolveLocale` remains in `app.dart`.
- [x] `dart run build_runner build` succeeds.
- [x] `dart analyze` passes on changed files; `flutter test` passes (the app.dart change is behavior-preserving).

**Spec criteria addressed**: AC-6, AC-8

## Completion Notes
**Completed**: 2026-05-23
**Files changed**: lib/core/providers/shared_preferences_provider.dart (+.g.dart), lib/core/l10n/locale_resolver.dart (new), lib/app.dart
**Contract**: Expects [2/2 verified] | Produces [4/4 verified]
**Notes**: Function-form `@riverpod` correctly omits `name:` (MEMORY L144). Sync throwing provider byte-for-byte unchanged. resolveAppLocale is a verbatim move. 226 tests pass. build_runner also regenerated app_router.g.dart's provider hash (benign). Code review: APPROVE (no issues).
