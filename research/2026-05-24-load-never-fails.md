# Research: Bug 014 — `SettingsRepository.load()` claims "Never fails" but cannot honor the contract

**Date**: 2026-05-24
**Topic**: `SettingsRepository.load()` returns `AppSettings` with a dartdoc promise of "Never fails", but the implementation chains four data-source reads with no error containment — and three of those reads have no defensive guard, so a `TypeError`/`Error` from `SharedPreferencesWithCache` escapes the data layer and crashes the app *past* the new splash gate.
**Verdict**: **Feasible** — `/fix`-grade, root cause already documented in `bugs/014-load-never-fails-doc-lie.md`.

## Summary

The claim is real and has teeth. `load()` (settings_repository_impl.dart:21-27) calls four getters with no `try/catch`. Of those four, **only `getThemeMode()` is defensively guarded** (settings_local_data_source.dart:40-51). The other three — `getUseSystemTheme()` (`getBool`), `getUseSystemLanguage()` (`getBool`), `getManualLanguage()` (`getString`) — are unguarded. If any cached value is the wrong type (legacy data, cache corruption, a platform-channel edge case), the cast inside `SharedPreferencesWithCache` throws a `TypeError`. `TypeError` extends `Error`, not `Exception`, so nothing catches it and it propagates out of `load()`.

The critical detail: `load()` is consumed **synchronously** in `SettingsNotifier.build()` (settings_provider.dart:90), which runs inside `DoslyApp` — i.e. *after* the `AppBootstrap` splash/retry gate (bug 013's fix). The splash only protects `SharedPreferencesWithCache.create()`. A throw from `load()` lands in the provider tree behind the gate and surfaces as an uncaught build error → frozen/crashed app. So "Never fails" is not just a doc lie; it's an unguarded crash path the recent splash work does **not** cover.

This is a sibling of **bug 010** (the four `save*` methods catch only `Exception`, also letting `Error` escape). Both stem from the same root: `Error` subtypes escaping the data layer, violating constitution §3.2.

## Codebase Findings

### Existing Related Code
| Area | File / Lines | Relevance |
|------|------|-----------|
| Domain contract (the lie) | `domain/repositories/settings_repository.dart:17-20` | `AppSettings load();` + "Never fails — returns defaults" dartdoc |
| Impl (no try/catch) | `data/repositories/settings_repository_impl.dart:21-27` | Chains 4 getters; nothing contains a throw |
| Guarded getter (the pattern) | `data/datasources/settings_local_data_source.dart:40-51` | `getThemeMode()` already does the defensive `try/catch → default` — the template to mirror |
| **Unguarded getters** | same file: `getUseSystemTheme()` :61, `getUseSystemLanguage()` :70, `getManualLanguage()` :76-82 | `getBool`/`getString` casts that can throw `TypeError` with no guard |
| Synchronous consumer | `presentation/providers/settings_provider.dart:85-91` | `SettingsNotifier.build()` returns `repo.load()` synchronously — a throw here is uncaught |
| Splash gate (does NOT cover this) | `app_bootstrap.dart:51-62` | Guards `sharedPreferencesInit` (create), not the synchronous `load()` read |
| Default entity | `domain/entities/app_settings.dart:38-43` | `const AppSettings()` with `@Default`s — a valid "graceful degradation" value already exists |
| Sibling bug | `bugs/010-repository-catches-only-exception.md` | Same root cause (`Error` escapes); natural to fix together |

### Patterns Available
- **Defensive getter** — `getThemeMode()` is the in-file precedent for "catch the cast, return default". The fix can extend this exact shape to the other three getters (KISS, consistent style).
- **Synchronous `Either`** — `fpdart`'s `Either<L, R>` is itself sync; only the `save*` methods wrap it in `Future` because they're async. `Either<Failure, AppSettings> load()` is well-supported.
- **Error stream** — `SettingsNotifier` already owns a `StreamController<Failure>` (`settingsErrorsProvider`) for surfacing save failures; a load failure could route through the same surface.

### Gaps
- **No typed logger yet** (bug 017 — `lib/core/logging/` absent). Any "swallow to default" approach can't log the suppressed error without violating §4.2 ("never swallow") or §4.2.1 (no `print`/`debugPrint`). This constrains Option B.
- **No test exercises an unguarded-getter throw.** Existing tests cover legacy-int `themeMode` (passes only because `getThemeMode` is guarded). There is no test for a wrong-type `useSystemTheme`/`manualLanguage` value.

## Constitution Constraints

| Rule | Impact on the fix |
|------|-------------------|
| §3.2 [enforced] "Every repository catches its data-source exceptions and returns `Left`; exceptions NEVER escape the data layer" | The rule being violated. Letter of the rule favors returning `Either` (Option A) or at minimum containing every throw (Option C). |
| §3.2 [enforced] "Every `Either.fold` handles BOTH branches" | If `load()` returns `Either`, the notifier's `build()` must `fold` to a default — and that default-on-error is itself a swallow unless surfaced/logged. |
| §4.2 "Never swallow errors silently" | A bare `catch (_) → defaults` (Option B / Option C) needs a log or a surfaced value to be compliant — and the logger doesn't exist yet (bug 017). |
| §3.7 / "existing patterns over new ones" | `getThemeMode()`'s guard is the established pattern — Option C reuses it verbatim. |
| §6.1 "Minimal changes" | Favors the smallest honest fix; argues against rewriting the consumer chain if avoidable. |

## Approaches

### Option A — Change the contract to `Either<Failure, AppSettings> load()` (canonical per §3.2)
- **Description**: Domain interface returns sync `Either`. Impl wraps the chain in `try/catch (e, st)` → `Left(Failure.unknown(e, st))` / `Right(settings)`. `SettingsNotifier.build()` folds: `Left → const AppSettings()` (+ optionally emit to the existing error stream), `Right → settings`.
- **Pros**: Honors §3.2 to the letter; consistent with the four `save*` methods; the failure becomes a *value* the caller chooses to handle rather than a hidden throw; pairs cleanly with bug 010.
- **Cons**: Touches domain interface + impl + notifier `build()` + tests (~4 files). The fold-to-default in `build()` still needs the error stream (or a logger) to avoid being a silent swallow.
- **Complexity**: Low–Medium

### Option B — Wrap impl `load()` in `try/catch → const AppSettings()`, fix the doc to "Never throws"
- **Description**: Single `try/catch` around the chain in the impl; return the default entity on any throw. Reword the dartdoc to "Never throws — returns default `AppSettings` on any underlying error."
- **Pros**: Smallest diff (1 file + doc); keeps the synchronous-read contract identical; consumer unchanged.
- **Cons**: Swallows the error — needs the typed logger (bug 017) to satisfy §4.2, which doesn't exist yet. Until then it's either a §4.2 violation or a coupling to an unshipped bug. Hides genuinely corrupt state behind silent defaults.
- **Complexity**: Low

### Option C — Harden the three unguarded data-source getters (mirror `getThemeMode`)
- **Description**: Add the same `try/catch → default` guard to `getUseSystemTheme`, `getUseSystemLanguage`, and `getManualLanguage` that `getThemeMode` already has. `load()` then genuinely never throws because no getter can, and the "Never fails" doc becomes literally true.
- **Pros**: Reuses the established in-file pattern (§3.7, consistent style); containment happens at the exact boundary that throws; no domain/consumer churn; makes the existing doc honest rather than rewording it.
- **Cons**: Still a per-getter swallow (same §4.2 logging tension as B); three near-identical catch blocks (borderline DRY — but mirrors existing precedent and the constitution allows 2-3 occurrences before abstracting); doesn't satisfy §3.2's "return `Either`" letter (though it satisfies its *intent*: nothing escapes the data layer).
- **Complexity**: Low

**Recommended approach**: **Option A**, fixed together with **bug 010**. It's the only option that satisfies §3.2 to the letter, makes the failure an explicit value, and aligns `load()` with the four `save*` siblings — all of which the audit flagged as the same class of defect. The `build()` fold should route the `Left` to the existing `settingsErrors` stream (defaulting state to `const AppSettings()`), so the error is *surfaced*, not swallowed, without waiting on bug 017. If the team wants the absolute-minimum stop-gap this cycle, **Option C** is the acceptable fallback because it reuses the existing `getThemeMode` guard and makes the doc honest — but it leaves the §3.2 "return Either" letter unmet and inherits the same logging gap.

## Complexity Assessment

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Codebase changes | Low (A: Low–Med) | A: interface + impl + notifier `build()` + tests (~4 files). C: 1 file (data source) + tests. Both under the `/fix` 5-file ceiling. |
| New dependencies | None | `fpdart` sync `Either` already in use; no new packages. |
| Risk | Low | Behavior-preserving on the happy path; the new behavior replaces an uncaught crash (behind the splash gate) with graceful defaults. |

## Recommendation

**Proceed via `/fix`**, and bundle **bug 010** into the same fix — they are the same root cause (`Error` subtypes escaping the data layer) in the same file, and fixing one without the other leaves the contract half-honored.

Two decisions to confirm during the fix:
1. **Contract shape** — Option A (`Either<Failure, AppSettings> load()`, canonical §3.2) vs Option C (harden the three getters, minimal). Recommend A.
2. **Where the load failure surfaces** — route the `Left` through the existing `settingsErrors` stream (recommended, satisfies §4.2 now) vs defer to the bug 017 logger (couples to unshipped work).

Suggested `/fix` invocation:

```
/fix "Bug 014 + Bug 010: throwables escape SettingsRepository's data layer (constitution §3.2). (A) Change SettingsRepository.load() to return sync Either<Failure, AppSettings>; wrap the impl chain in try/catch (e, st) → Left(Failure.unknown(e, st)); SettingsNotifier.build() folds Left → const AppSettings() and emits the Failure to the existing _errors stream. (B) Change the four save* methods' `on Exception catch` to `catch (e, st)` so Error subtypes are caught too, routing to Failure.unknown(e, st) (avoids leaking platform path strings via toString). Add tests with a failing data source asserting load() and each save* return the default/Left instead of throwing. Update the load() dartdoc to match the new Either contract."
```

## Next-step prompt

If escalating to a full spec instead of `/fix` (e.g. if the team wants to formalize the data-layer error-containment contract across all repositories, not just settings):

```
/specify "Enforce constitution §3.2 error-containment in the settings data layer: no throwable (Exception OR Error) may escape SettingsRepository. Per research/2026-05-24-load-never-fails.md (bug 014, sibling bug 010): (1) change SettingsRepository.load() from `AppSettings load()` to a synchronous `Either<Failure, AppSettings> load()`; the impl wraps its four-getter chain in try/catch (e, st) returning Left(Failure.unknown(e, st)) on any throw and Right(settings) otherwise. (2) SettingsNotifier.build() folds the Either: Left → const AppSettings() as graceful-default state AND emits the Failure to the existing _errors stream (settingsErrorsProvider) so the failure is surfaced, not swallowed (§4.2). (3) change the four save* methods from `on Exception catch` to `catch (e, st)` so Error subtypes are also caught, routing uncategorized throws to Failure.unknown(e, st) instead of CacheFailure(e.toString()) (avoids leaking platform filesystem paths — bug 010 / CWE-209). (4) update the load() dartdoc to describe the new Either contract honestly. Acceptance: wrong-type cached values for themeMode/useSystemTheme/useSystemLanguage/manualLanguage never throw out of load(); a failing data source makes load() return Left and each save* return Left; no Error subtype escapes the data layer; existing happy-path and legacy-int themeMode tests still pass."
```
