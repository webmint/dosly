# Plan: Async Startup Splash & Prefs-Failure Recovery

**Date**: 2026-05-23
**Spec**: [spec.md](spec.md)
**Status**: Approved

## Summary

Make `main()` synchronous and hand startup to a new `AppBootstrap` root widget that watches an async `sharedPreferencesInitProvider` (`@riverpod` Future). While prefs hydrate it shows a localized, themed splash; on hydration failure it shows a localized error + Retry (manual `ref.invalidate`); on success it mounts a nested `ProviderScope` that injects the hydrated prefs into the unchanged downstream provider tree (`DoslyApp`). The existing synchronous `sharedPreferencesProvider` throwing-placeholder contract is preserved verbatim — only the override location moves out of `main()`.

## Technical Context

**Architecture**: `core` (providers, l10n helper, widgets) + app root (`main.dart`, new `app_bootstrap.dart`) + minor touch to presentation root (`app.dart`). No domain or data-layer changes; `lib/features/**` untouched.
**Error Handling**: `AsyncValue.when(loading/error/data)` from the Future provider. Hydration failure is surfaced as UI (error screen + Retry), never swallowed (§4.2). No logging this feature (Bug 017 deferred).
**State Management**: Riverpod codegen. New initializer is **function-form** `@riverpod` → emits `sharedPreferencesInitProvider`, no `name:` parameter needed (MEMORY L144 — only class-form notifiers need `name:`).

## Constitution Compliance

- **§4.2.1 "Never block `main()` on async work"** — compliant; this is the rule being satisfied. `main()` does only `WidgetsFlutterBinding.ensureInitialized()` then `runApp`, both synchronous.
- **§4.2.1 "No `package:flutter/*` in `domain/`"** — compliant; all new code lives in `core/` and app root, none in any `domain/`.
- **§4.2 "Never swallow errors"** — compliant; the `error` branch renders a user-facing message + Retry.
- **§4.2.1 "No `print`/`debugPrint`"** — compliant; error path is UI-only.
- **§4.3.1 "Prefer `@riverpod` codegen"** — compliant; function-form annotated provider, not a hand-rolled `FutureProvider`.
- **§4.1 "Check `mounted` after `await`"** — N/A; Retry callback calls `ref.invalidate(...)` synchronously, no `await`, no `BuildContext` across an async gap.
- **§4.3 DRY** — extracting the locale resolver to `core/l10n/` consolidates the (currently sole) production copy into a shared single source of truth used by both `app.dart` and `AppBootstrap`.
- **l10n** — new strings read via `context.l10n`; ARB edits followed by `flutter gen-l10n` (MEMORY L206: ARB `@`-descriptions are living docs).

## Implementation Approach

### Layer Map

| Layer | What | Files (existing or new) |
|-------|------|------------------------|
| Core / providers | `sharedPreferencesInitProvider` — `@riverpod` `Future<SharedPreferencesWithCache>` performing `create(...)` with the existing allowList | `lib/core/providers/shared_preferences_provider.dart` (modify) + `.g.dart` (regen) |
| Core / l10n | `resolveAppLocale(Locale?, Iterable<Locale>)` — extracted from `app.dart`'s private `_resolveLocale` (verbatim body + dartdoc); English-fallback policy | `lib/core/l10n/locale_resolver.dart` (new) |
| Core / widgets | `SplashScreen` (surface-colored Scaffold + progress indicator + `splashLoading` label); `PrefsLoadErrorScreen` (message + Retry button, `onRetry` callback) | `lib/core/widgets/splash_screen.dart`, `lib/core/widgets/prefs_load_error_screen.dart` (new) |
| App root | `AppBootstrap` `ConsumerWidget` — bootstrap `MaterialApp` shell (theme/darkTheme/`ThemeMode.system`, delegates, supportedLocales, `localeResolutionCallback: resolveAppLocale`) wrapping splash/error; nested `ProviderScope` override on data | `lib/app_bootstrap.dart` (new) |
| App root | `main()` synchronous: `ensureInitialized()` → `runApp(const ProviderScope(child: AppBootstrap()))` | `lib/main.dart` (modify) |
| Presentation root | Swap private `_resolveLocale` for the shared `resolveAppLocale` import | `lib/app.dart` (modify — discovered during planning) |
| Localization | Add `splashLoading`, `prefsLoadErrorMessage`, `prefsLoadRetry` (en with `@`-metadata; de/uk value-only) + regen | `lib/l10n/app_en.arb`, `app_de.arb`, `app_uk.arb`, `app_localizations*.dart` (regen) |
| Tests | Widget tests: failure→error screen, Retry→recovery, normal→DoslyApp, splash visuals | `test/app_bootstrap_test.dart` (new — discovered during planning) |
| Docs | Update Bootstrap section + provider-wiring table | `docs/architecture.md` (modify) |
| Bug | Close Bug 013 | `bugs/013-main-blocks-on-async.md` (modify) |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| Async seam | New function-form `@riverpod` `sharedPreferencesInitProvider` returning a `Future`, alongside the unchanged throwing sync `sharedPreferencesProvider` | Keeps the sync read contract intact for `lib/features/settings/**`; provides a clean test seam (`overrideWith((ref) => Future.error(...))`) without mocking the static `create` | Convert `sharedPreferencesProvider` itself to async + `requireValue` downstream (spec Option B — touches settings, erases the throwing contract) |
| Override relocation | Move `sharedPreferencesProvider.overrideWithValue(prefs)` from `main()` into `AppBootstrap`'s `data` branch (nested `ProviderScope`) | All synchronous downstream providers build only after prefs resolves, inside the nested scope — behavior identical to today, zero changes to settings providers | Top-level `requireValue` (Option B); `AsyncNotifier` settings (Option C) |
| Single vs double `MaterialApp` | `loading`/`error` return a plain `MaterialApp` shell; `data` returns `ProviderScope`→`DoslyApp` (which owns `MaterialApp.router`). Branches are mutually exclusive | Only one `MaterialApp`/Navigator is ever mounted at a time → no nested-Navigator/MediaQuery hazard (spec Risk #1) | Single `MaterialApp` with switching `home:` — impossible since `DoslyApp` is itself a `MaterialApp.router` |
| Splash theming | Bootstrap shell `MaterialApp` uses `AppTheme.lightTheme`/`darkTheme` with `themeMode: ThemeMode.system`; splash background `colorScheme.surface` | Splash respects device brightness → minimizes the light→dark flash when `DoslyApp` later applies a dark theme (spec Risk #3); reuses existing `AppTheme` | Hardcoded color / default `ThemeData` (flash on dark-mode devices) |
| Pre-settings locale | Bootstrap shell uses `resolveAppLocale` against the **device** locale (English fallback). Settings-driven `manualLanguage` is not yet available (spec Open Q #1) | On a hydration failure there is no reliable saved language; the splash is momentary on the happy path. English-fallback prevents the alphabetical-first (German) default-resolution bug | Flutter default resolution (surfaces German to unsupported locales); pinning `Locale('en')` (ignores device locale) |
| Resolver location | Extract `_resolveLocale` → public `resolveAppLocale` in `lib/core/l10n/locale_resolver.dart`; `app.dart` and `AppBootstrap` both import it | Production code currently has one copy in `app.dart`; the splash needs the same policy. A shared core helper is the single source of truth (avoids a 2nd production copy that must stay in sync) | Duplicate the ~8-line resolver inside `AppBootstrap` (2 production copies). NOTE: the 7 private `_resolveLocale` copies in test harnesses are pre-existing and out of scope — not touched |
| Retry mechanism | `PrefsLoadErrorScreen.onRetry` calls `ref.invalidate(sharedPreferencesInitProvider)` | Re-runs `create()`; `AppBootstrap` rebuilds through loading→data/error. Synchronous callback, no `mounted` concern | Stateful retry counter / auto-backoff (out of scope per spec §6) |
| Init provider lifetime | Plain `@riverpod` (autoDispose) | `AppBootstrap` is the app root and always `ref.watch`es it, so an active listener keeps it alive for the app's life; autoDispose is the codegen default/preferred | `keepAlive: true` — unnecessary given the permanent root listener |

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `lib/main.dart` | Modify | Remove `async`/`await`; `runApp(const ProviderScope(child: AppBootstrap()))`; drop the prefs override (moves to AppBootstrap) |
| `lib/core/providers/shared_preferences_provider.dart` | Modify | Add `sharedPreferencesInitProvider` (`@riverpod` Future running `create` with the allowList); keep the sync throwing provider unchanged; update library dartdoc |
| `lib/core/providers/shared_preferences_provider.g.dart` | Regen | `dart run build_runner build` |
| `lib/core/l10n/locale_resolver.dart` | Create | `resolveAppLocale` (moved verbatim from `app.dart._resolveLocale` + dartdoc) |
| `lib/core/widgets/splash_screen.dart` | Create | Surface-colored Scaffold, centered progress indicator + `context.l10n.splashLoading` |
| `lib/core/widgets/prefs_load_error_screen.dart` | Create | Centered message `context.l10n.prefsLoadErrorMessage` + `FilledButton` `context.l10n.prefsLoadRetry`; `required VoidCallback onRetry` |
| `lib/app_bootstrap.dart` | Create | `AppBootstrap` ConsumerWidget: bootstrap `MaterialApp` shell + `.when(loading/error/data)` + nested `ProviderScope` override |
| `lib/app.dart` | Modify *(planning-discovered)* | Replace private `_resolveLocale` with import of `resolveAppLocale`; update the library dartdoc reference |
| `lib/l10n/app_en.arb` | Modify | Add 3 keys + `@`-metadata descriptions |
| `lib/l10n/app_de.arb` | Modify | Add 3 keys (German values) |
| `lib/l10n/app_uk.arb` | Modify | Add 3 keys (Ukrainian values) |
| `lib/l10n/app_localizations*.dart` | Regen | `flutter gen-l10n` |
| `test/app_bootstrap_test.dart` | Create *(planning-discovered)* | Widget tests: error-branch (override init with `Future.error`), Retry recovery (swap override), normal launch reaches `DoslyApp`, splash shows progress indicator + surface bg |
| `docs/architecture.md` | Modify | Rewrite "Bootstrap: `SharedPreferencesWithCache`" (lines 93-120) for the new flow; add `sharedPreferencesInitProvider` to the provider-wiring table |
| `bugs/013-main-blocks-on-async.md` | Modify | Status: Fixed, Fixed date, Resolution section |

### Documentation Impact

| Doc File | Action | What Changes |
|----------|--------|-------------|
| `docs/architecture.md` | Update | Bootstrap section now describes synchronous `main()` → `AppBootstrap` → `sharedPreferencesInitProvider` → nested-scope override; add the new provider to the wiring table |
| `docs/features/*.md` | None | No feature-level behavior change |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Double-`MaterialApp` nesting (Navigator/MediaQuery hazard) | Med | Med | Mutually exclusive branches — only the shell `MaterialApp` (loading/error) **or** `DoslyApp`'s `MaterialApp.router` (data) is mounted, never both. Widget test asserts a single Navigator. |
| Static `SharedPreferencesWithCache.create` hard to fail-inject | Med | Med | Test at the provider seam: `sharedPreferencesInitProvider.overrideWith((ref) => Future.error(...))` / delayed success — no static mocking. |
| Extracting `_resolveLocale` subtly changes locale behavior | Low | High | Move body + dartdoc verbatim; existing locale/i18n widget tests must pass unchanged (they use their own harness copies, independent of production). |
| Theme flash light→dark on the splash | Med | Low | Bootstrap shell `themeMode: ThemeMode.system` + `AppTheme` themes; surface-colored splash. Acceptable momentary transition. |
| Regression in settings/theme/locale behavior | Low | High | `lib/features/settings/**` untouched; AC-6/AC-8 gated on existing settings/theme/i18n tests passing unchanged. |
| All ACs covered (cross-ref) | Low | — | See cross-reference below — AC-1…AC-10 each map to a concrete file/decision. |

## Dependencies

None. No new packages, services, or environment variables. Uses existing `flutter_riverpod`/`riverpod_annotation`, `shared_preferences`, `flutter_localizations`/gen_l10n, `flutter_test`. Requires the existing codegen steps: `dart run build_runner build` (for the new provider) and `flutter gen-l10n` (for the ARB keys).

## Plan–Spec Cross-Reference

| AC | Covered by |
|----|-----------|
| AC-1 (no await before runApp) | `main.dart` rewrite |
| AC-2 (normal launch, settings applied) | `data` branch → unchanged `DoslyApp`; `app_bootstrap_test` normal-launch case |
| AC-3 (failure → error screen, never black) | `AppBootstrap` error branch + `PrefsLoadErrorScreen`; test overrides init with `Future.error` |
| AC-4 (Retry recovers) | `onRetry`→`ref.invalidate`; test swaps override to success |
| AC-5 (splash surface + progress indicator) | `SplashScreen` (surface bg, `CircularProgressIndicator`) |
| AC-6 (theme/locale identical) | `DoslyApp` untouched; existing settings/theme/i18n tests |
| AC-7 (3 strings × 3 locales via `context.l10n`) | ARB edits + gen-l10n; splash/error widgets read `context.l10n` |
| AC-8 (`features/settings` unchanged) | Nested-scope override design; no edits under `lib/features/` |
| AC-9 (no print, analyze/test pass) | UI-only error path; PostToolUse `dart analyze` hook; `flutter test` |
| AC-10 (docs + bug) | `docs/architecture.md` + `bugs/013` updates |

## Supporting Documents

None — no `research.md` (no signals), `data-model.md` (no entities), or `contracts.md` (no API) required.

## Suggested Task Grain (for `/breakdown`)

Per MEMORY L226 (l10n → source+test → docs+bug is optimal for small localized Flutter specs), a likely 3-task split:
1. **l10n** — add 3 ARB keys (en/de/uk) + `flutter gen-l10n`. Natural rollback boundary; gates on `dart analyze`.
2. **source + tests** — `sharedPreferencesInitProvider`, `locale_resolver` extraction (+ `app.dart` swap), `SplashScreen`, `PrefsLoadErrorScreen`, `AppBootstrap`, `main.dart` rewrite, `build_runner`, widget tests. Gates on `dart analyze` + `flutter test` + `flutter build apk --debug` (integration verification point, per L114).
3. **docs + bug** — `docs/architecture.md` Bootstrap section + provider table; close Bug 013 (tech-writer, last so Resolution reflects what shipped).

Final grain is `/breakdown`'s call.
```
