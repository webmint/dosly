# Research: Bug 013 — `main()` blocks on async work before `runApp`

**Date**: 2026-05-23
**Topic**: `main()` awaits `SharedPreferencesWithCache.create()` before `runApp` → frozen black launch screen if prefs hydration stalls (violates constitution §4.2.1 [enforced])
**Verdict**: Feasible — clean fix, fully supported by existing patterns

## Summary

The fix is feasible and fits the architecture cleanly. The constitution rule (§4.2.1: *"Never block `main()` on async work. Show a splash, run async setup, then `runApp`"*) is violated at `lib/main.dart:10-19`. The non-obvious wrinkle: `main()` pre-hydrates the prefs cache **on purpose** — `SettingsNotifier.build()` reads settings *synchronously* (`repo.load()`, settings_provider.dart:86-91) and `settingsRepositoryProvider` watches `sharedPreferencesProvider` synchronously. So you can't just delete the `await`; you must move hydration into an async initializer that *gates* the synchronous consumers behind a resolved `AsyncValue`. The recommended approach uses a `FutureProvider` + a bootstrap widget that renders a splash while loading and a nested `ProviderScope` override on success — this keeps **all** downstream synchronous providers unchanged.

## Codebase Findings

### Existing Related Code
| Area | Files | Relevance |
|------|-------|-----------|
| Async entry point | `lib/main.dart:8-28` | The offending `await SharedPreferencesWithCache.create(...)` before `runApp` |
| Prefs provider contract | `lib/core/providers/shared_preferences_provider.dart` | Throwing placeholder, *must* be overridden in `main()`. This override is what moves into the bootstrap |
| Synchronous consumer | `lib/features/settings/.../settings_provider.dart:33-38, 85-91` | `settingsRepositoryProvider` + `SettingsNotifier.build()` read prefs **synchronously** — the reason the cache must be hot before first build |
| App root | `lib/app.dart` (`DoslyApp`) | The widget that must be gated behind the resolved future |
| l10n | `lib/l10n/app_{en,de,uk}.arb` + gen_l10n | Splash/error strings must be added to all three ARBs (project supports en/de/uk) |

### Patterns Available
- **Riverpod codegen** (`@riverpod` / `@Riverpod(keepAlive:)`) is the house style — bug 007's fix already migrated the router to a provider; the same shape applies here.
- **Override-at-scope** pattern is already in use (`sharedPreferencesProvider.overrideWithValue` in `main()`) — the fix relocates this, doesn't invent it.
- **`AsyncValue` gating** is idiomatic Riverpod (`.when(loading/error/data)`).

### Gaps
- **No splash widget exists** (`grep` for splash → only `ensureInitialized`). Must be created.
- **No typed logger yet** (bug 017 — `lib/core/logging/` absent). The error branch can surface a UI message + retry **without** logging for now; wire logging when bug 017 lands (constitution forbids `print`/`debugPrint`).

## Constitution Constraints

| Rule | Impact |
|------|--------|
| §4.2.1 [enforced] "Never block `main()` on async work" | The rule being fixed — drives the whole change |
| §4.2 "Never swallow errors" | Error branch must *surface* the hydration failure (retry UI), not silently fall through |
| §4.2.1 "Never use `print`/`debugPrint`" | Error branch shows UI only; defer logging to bug 017 |
| §4.3.1 "Prefer `@riverpod` codegen" / "Prefer `AsyncNotifier`" | Async initializer should be a codegen `FutureProvider`, not hand-rolled |
| §4.1 "Always check `mounted` after `await`" | Splash/retry interactions must respect this if any imperative async is added |
| §4.2.1 "Domain stays pure Dart" | Splash + bootstrap are presentation/core — no domain impact |

## Approaches

### Option A — `FutureProvider` + bootstrap widget with nested `ProviderScope` override (recommended)
- **Description**: `main()` calls `runApp` immediately with an `AppBootstrap` widget. A new `sharedPreferencesInitProvider` (`FutureProvider`) performs `SharedPreferencesWithCache.create(...)`. `AppBootstrap` does `.when(loading: splash, error: retry, data: (prefs) => ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)], child: DoslyApp()))`.
- **Pros**: **Zero changes to `settings_provider.dart`** — the existing throwing/synchronous `sharedPreferencesProvider` contract is preserved verbatim; only the override *location* moves. Smallest blast radius. Matches the bug's own Fix Notes.
- **Cons**: Nested `ProviderScope` is slightly less common; needs a one-line dartdoc explaining why.
- **Complexity**: Low

### Option B — Convert `sharedPreferencesProvider` itself to a `FutureProvider`
- **Description**: Make the provider async; downstream synchronous providers read `.requireValue` (safe because the bootstrap gate guarantees resolution).
- **Pros**: No nested scope; single provider.
- **Cons**: Touches `settings_provider.dart` (`requireValue`), erases the existing "must be overridden" contract & its dartdoc, more downstream churn.
- **Complexity**: Low–Medium

### Option C — Convert settings to a top-level `AsyncNotifier`
- **Description**: Settings becomes `AsyncValue<AppSettings>`; `DoslyApp` handles loading/error.
- **Pros**: Conceptually "most correct" async modeling.
- **Cons**: Heavily rewrites `app.dart` (all four `.select` reads + theme/locale derivation must handle `AsyncValue`); largest blast radius. Overkill for a fast local read.
- **Complexity**: High

**Recommended approach**: Option A — surgical, preserves the synchronous-consumer contract, directly satisfies §4.2.1, and matches the bug's documented Fix Notes.

## Complexity Assessment

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Codebase changes | Low | `main.dart` rewrite; add `sharedPreferencesInitProvider`; new `AppBootstrap` + splash widget; 3 ARB strings (splash label, error message, retry label). ~3-5 files |
| New dependencies | None | Splash = plain Flutter widget; `FutureProvider` already available |
| Risk | Low | Behavior-preserving for the happy path; new value is graceful degradation on a failure that currently produces a black screen |

## Recommendation

**Proceed via `/fix`** — this is a localized change (≈3-5 files, well under the 5-file `/fix` ceiling) with a clear root cause already documented in `bugs/013-main-blocks-on-async.md`. The full spec pipeline is unnecessary.

Two decisions to confirm during the fix: **(1)** Option A's nested-scope vs Option B's `requireValue` (A keeps `settings_provider.dart` untouched); **(2)** error-branch UX — silent retry vs. a visible "couldn't load preferences" message with a retry button (recommend the latter, per §4.2 "never swallow errors").

## Next-step prompt

If escalating to a spec instead of `/fix`:

```
/specify "Make app startup non-blocking per constitution §4.2.1. main() must call runApp immediately with an AppBootstrap widget instead of awaiting SharedPreferencesWithCache.create(). Add a sharedPreferencesInitProvider FutureProvider that hydrates prefs; AppBootstrap renders a Material splash (themed to colorScheme.surface, matching the OS LaunchScreen) while loading, a 'could not load preferences' message with a Retry action on error, and on success a nested ProviderScope overriding sharedPreferencesProvider so all synchronous downstream providers (settingsRepositoryProvider, SettingsNotifier) stay unchanged. Add splash/error/retry strings to app_en.arb, app_de.arb, app_uk.arb. Defer structured logging of the failure to bug 017 (typed logger). Acceptance: no await before runApp; corrupted/stalled prefs shows splash then retry UI, never a frozen black screen."
```

Faster path (recommended):

```
/fix "Bug 013: main() blocks on async prefs hydration. Apply Option A — runApp immediately with an AppBootstrap widget; add a sharedPreferencesInitProvider FutureProvider that creates SharedPreferencesWithCache; show a Material splash (colorScheme.surface) while loading and a retry UI on error; on data, render a nested ProviderScope overriding sharedPreferencesProvider so all synchronous downstream providers stay unchanged. Add splash/error/retry strings to app_en/de/uk.arb. Defer logging to bug 017."
```
