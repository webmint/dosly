# Spec: Async Startup Splash & Prefs-Failure Recovery

**Date**: 2026-05-23
**Status**: Complete
**Author**: Claude + Webmint

## 1. Overview

`main()` currently blocks on `await SharedPreferencesWithCache.create(...)` before calling `runApp`, violating constitution §4.2.1 ("Never block `main()` on async work. Show a splash, run async setup, then `runApp`"). If prefs hydration stalls or the prefs store is corrupted, the app shows a frozen black launch screen with no UI and no recovery path. This feature moves prefs hydration behind a Flutter-rendered splash via an async-initializing provider and a bootstrap widget, adding a recoverable retry UI for the hydration-failure case. Closes Bug 013.

## 2. Current State

**Entry point** — `lib/main.dart:8-28`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: <String>{
        'themeMode', 'useSystemTheme', 'useSystemLanguage', 'manualLanguage',
      },
    ),
  );
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const DoslyApp(),
    ),
  );
}
```

**Why it blocks on purpose** — the synchronous read contract:
- `lib/core/providers/shared_preferences_provider.dart` declares `sharedPreferencesProvider` as a `@Riverpod(keepAlive: true)` function with a *throwing* placeholder body — it must be overridden in the root `ProviderScope`. Its return type is the concrete synchronous `SharedPreferencesWithCache`.
- `settingsRepositoryProvider` (`lib/features/settings/presentation/providers/settings_provider.dart:33-38`) reads `ref.watch(sharedPreferencesProvider)` **synchronously**.
- `SettingsNotifier.build()` (same file, lines 85-91) calls `repo.load()` **synchronously** to produce the initial `AppSettings`.
- `SettingsRepositoryImpl.load()` (`lib/features/settings/data/repositories/settings_repository_impl.dart:22`) reads straight from the hot `SharedPreferencesWithCache` cache.

So the cache *must* be hydrated before the first widget build — that is the reason `main()` awaits. Any fix must preserve a hydrated, synchronous prefs instance by the time `DoslyApp` first builds.

**App root** — `lib/app.dart` (`DoslyApp`, a `ConsumerWidget`) builds `MaterialApp.router`, watching four `settingsNotifierProvider.select(...)` fields to derive `themeMode`/`locale`, and provides `localizationsDelegates`, `supportedLocales`, theme, and the router. It is the only widget currently wrapping the app in a `MaterialApp` (i.e. the only source of `Localizations`, `Directionality`, and theme in the tree).

**Localization** — gen_l10n from `lib/l10n/app_{en,de,uk}.arb`. `app_en.arb` carries `@key` metadata blocks (description); `app_de.arb` / `app_uk.arb` are value-only. Strings are read via `context.l10n.<key>` (`lib/l10n/l10n_extensions.dart`). Supported locales: en, de, uk (English is the designated fallback per `_resolveLocale` in `app.dart:35`).

**Docs** — `docs/architecture.md` §"Bootstrap: `SharedPreferencesWithCache`" (lines 93-120) documents the current blocking `main()` verbatim and must be updated by this feature.

**Deferred dependency** — there is no typed logger yet (`lib/core/logging/` does not exist; tracked by Bug 017). Constitution §4.2.1 forbids `print`/`debugPrint`, so the error path surfaces UI only and does not log in this feature.

## 3. Desired Behavior

### 3.1 Non-blocking entry point
`main()` performs only synchronous setup (`WidgetsFlutterBinding.ensureInitialized()`) and then calls `runApp` immediately with the bootstrap widget. No `await` precedes `runApp`.

### 3.2 Async prefs initializer
A new provider, `sharedPreferencesInitProvider` (Riverpod `@riverpod` codegen, returning a `Future<SharedPreferencesWithCache>`), performs `SharedPreferencesWithCache.create(...)` with the **existing allowList** (`themeMode`, `useSystemTheme`, `useSystemLanguage`, `manualLanguage`). This is the async seam; it is also the testable seam (tests override it with a failing or delayed future).

The existing synchronous `sharedPreferencesProvider` (throwing placeholder) is **unchanged** — it continues to be satisfied by a `ProviderScope` override; only the *location* of that override moves (see 3.4).

### 3.3 Bootstrap widget with splash + retry
A new `AppBootstrap` widget (a `ConsumerWidget`, presentation/core layer) is the root passed to `runApp`. It wraps its content in a minimal `MaterialApp` that supplies `localizationsDelegates`, `supportedLocales`, and `localeResolutionCallback` so the splash and error UIs are localized **before** settings are available. This phase uses the **default theme** and **device locale** (settings-driven theme/locale are not yet known). It watches `sharedPreferencesInitProvider` and renders:

- **loading** → a Material splash screen filling the viewport with `Theme.of(context).colorScheme.surface` as the background (matching the native OS LaunchScreen so the hand-off from the native splash is visually seamless), with a centered progress indicator and a localized splash label.
- **error** → a centered error screen showing a localized "could not load preferences" message and a localized **Retry** button. Retry re-runs the initializer by invalidating `sharedPreferencesInitProvider` (`ref.invalidate`). The error is surfaced to the user (not swallowed, per §4.2); no logging in this feature.
- **data** → a nested `ProviderScope` with `overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]` wrapping `const DoslyApp()`. This hands the hydrated, synchronous prefs instance to the existing provider tree unchanged.

### 3.4 Override relocation
The `sharedPreferencesProvider.overrideWithValue(prefs)` override moves out of `main()` and into `AppBootstrap`'s **data** branch (the nested `ProviderScope`). The outer `ProviderScope` in `main()` carries no overrides. All synchronous downstream providers (`settingsRepositoryProvider`, `settingsNotifierProvider`, and the use-case providers) build only inside the nested scope, after prefs is resolved — so their behavior is identical to today.

### 3.5 Localization strings
Add three new keys to all three ARBs (en with `@` metadata; de/uk value-only):
- `splashLoading` — splash label shown while prefs hydrate (e.g. EN "Loading…").
- `prefsLoadErrorMessage` — the "could not load preferences" message (user-facing, no technical detail).
- `prefsLoadRetry` — the Retry button label (e.g. EN "Retry").

### 3.6 Documentation
Update `docs/architecture.md` §"Bootstrap" (lines 93-120) to describe the non-blocking `main()` → `AppBootstrap` → `sharedPreferencesInitProvider` flow and the nested-scope override, and add `sharedPreferencesInitProvider` to the provider-wiring table. Mark Bug 013 Fixed.

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Entry point | `lib/main.dart` | Rewrite: synchronous body, `runApp(const AppBootstrap())`, no await, no override |
| Async initializer | `lib/core/providers/shared_preferences_provider.dart` | Add `sharedPreferencesInitProvider` (`@riverpod` Future) alongside the existing throwing sync provider; regenerate `.g.dart` |
| Bootstrap widget | `lib/app_bootstrap.dart` (new) | Create `AppBootstrap` `ConsumerWidget`: minimal localized `MaterialApp`, `.when(loading/error/data)`, nested `ProviderScope` override on data |
| Splash UI | `lib/core/widgets/` (new widget, e.g. `splash_screen.dart`) | Create splash screen (surface-colored, progress indicator, localized label) |
| Error/Retry UI | `lib/core/widgets/` (new widget, e.g. `prefs_load_error_screen.dart`) | Create error screen with localized message + Retry that invalidates the init provider |
| Localization | `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb` | Add `splashLoading`, `prefsLoadErrorMessage`, `prefsLoadRetry`; regenerate `app_localizations*.dart` |
| Docs | `docs/architecture.md` | Update Bootstrap section + provider table |
| Bug tracking | `bugs/013-main-blocks-on-async.md` | Set Status: Fixed, add Resolution + Fixed date |

## 5. Acceptance Criteria

- [x] **AC-1**: `lib/main.dart` contains no `await` (and no other async gate) before `runApp`; `main()` calls `runApp` with the bootstrap widget synchronously after `WidgetsFlutterBinding.ensureInitialized()`.
- [x] **AC-2**: On a normal launch, the app renders the splash, then transitions to the fully functional `DoslyApp` with persisted settings (theme + language) applied exactly as before this change.
- [x] **AC-3**: When `sharedPreferencesInitProvider` fails (simulated in a widget test by overriding it with a failing future), the app shows the error screen with the localized "could not load preferences" message and a Retry button — **never** a frozen black/blank screen.
- [x] **AC-4**: Tapping Retry re-invokes the initializer; when the underlying failure is cleared (override replaced with a succeeding future), the app proceeds to `DoslyApp`.
- [x] **AC-5**: While prefs hydrate, the splash background is `colorScheme.surface` and a progress indicator is visible.
- [x] **AC-6**: Theme and locale resolution behave identically to today once prefs resolve (verified by existing settings/theme/i18n tests passing unchanged).
- [x] **AC-7**: `splashLoading`, `prefsLoadErrorMessage`, and `prefsLoadRetry` exist in `app_en.arb`, `app_de.arb`, and `app_uk.arb`, and the splash/error UI reads them via `context.l10n` (no hardcoded user-facing strings).
- [x] **AC-8**: `lib/features/settings/**` is unchanged (the synchronous read contract is preserved by the nested-scope override).
- [x] **AC-9**: No `print`/`debugPrint` is introduced; the error path surfaces UI only. `dart analyze` passes clean on all changed files; `flutter test` passes.
- [x] **AC-10**: `docs/architecture.md` Bootstrap section reflects the new flow and `bugs/013-main-blocks-on-async.md` is marked Fixed.

## 6. Out of Scope

- NOT included: a typed logger or any logging of the hydration failure (deferred to Bug 017). The error branch is UI-only.
- NOT included: changes to `lib/features/settings/**` (data, domain, or presentation).
- NOT included: changing the `sharedPreferencesProvider` synchronous contract to async / `requireValue` (Option B from research — explicitly rejected to keep downstream untouched).
- NOT included: converting settings to an `AsyncNotifier` (Option C from research).
- NOT included: native splash screen / launch image configuration (Android `launch_background`, iOS `LaunchScreen.storyboard`) — only the Flutter-rendered splash after first frame.
- NOT included: a configurable timeout or auto-retry/backoff for prefs hydration (retry is manual via the button).
- NOT included: persisting or migrating any new prefs keys; the allowList is unchanged.

## 7. Technical Constraints

- Must follow constitution §4.2.1: no async work blocking `main()` before `runApp`.
- Must follow §4.2.1: no `package:flutter/*` imports in `domain/` (splash/bootstrap live in `lib/` root / `lib/core/`, not in any `domain/`).
- Must follow §4.2: the hydration error must be surfaced, not silently swallowed.
- Must follow §4.3.1: prefer `@riverpod` codegen for the new initializer (not a hand-written `FutureProvider`).
- Must reuse the existing l10n pattern (`context.l10n`, gen_l10n ARBs) — no new localization mechanism.
- Must keep the existing `sharedPreferencesProvider` throwing-placeholder contract intact.
- The splash/error `MaterialApp` must carry `AppLocalizations.localizationsDelegates` + `supportedLocales` so `context.l10n` resolves before settings load.
- `dart analyze` must pass clean (PostToolUse hook enforces this).

## 8. Open Questions

- **Locale during pre-settings phase**: the splash/error UI runs before settings are loaded, so it uses the **device** locale (resolved against supported locales, English fallback) rather than any saved `manualLanguage`. This is acceptable because (a) on a hydration failure there is no reliable saved language anyway, and (b) the splash is momentary on the happy path. Confirm during `/plan`.
- **Splash minimum-duration / flicker**: on fast devices prefs hydration may resolve within a frame or two, so the Flutter splash may be imperceptible (the native launch screen covers most of it). No artificial minimum duration is planned. Confirm no flash-of-splash mitigation is desired.
- **Widget placement**: splash and error screens are proposed under `lib/core/widgets/`; `AppBootstrap` at `lib/app_bootstrap.dart` (sibling to `app.dart`). Final paths confirmed in `/breakdown`.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Splash `MaterialApp` + nested `DoslyApp` `MaterialApp` causes a double-MaterialApp/Navigator nesting issue | Med | Med | Splash phase uses a plain `MaterialApp` (not `.router`); on data, the nested `ProviderScope`+`DoslyApp` fully replaces the subtree. Only one `MaterialApp` is mounted at a time (loading/error vs. data are mutually exclusive branches). Verify no Navigator/observer leaks in a widget test. |
| `SharedPreferencesWithCache.create` is a static method — hard to mock for the failure test | Med | Med | Test at the provider seam: override `sharedPreferencesInitProvider` with `Future.error(...)` / a delayed future in a `ProviderScope` (no need to mock the static). |
| Theme flash: splash uses default `ThemeData` while `DoslyApp` may apply dark theme, causing a light→dark flash | Med | Low | Splash background `colorScheme.surface`; acceptable momentary transition. Could honor `MediaQuery.platformBrightness` for the splash if flash is objectionable — defer unless observed. |
| Regression in settings/theme/locale behavior | Low | High | AC-6 + AC-8: existing settings/theme/i18n tests must pass unchanged; settings feature code is untouched. |
| First-frame timing: provider read before binding ready | Low | Med | `WidgetsFlutterBinding.ensureInitialized()` stays first in `main()`; the async create runs inside the provider, after binding init. |
```
