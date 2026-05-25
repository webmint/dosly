# Spec: Settings Data-Layer Error Containment

**Date**: 2026-05-24
**Status**: Complete
**Author**: Claude + Webmint

## 1. Overview

Enforce constitution §3.2 ("exceptions NEVER escape the data layer") across the
settings repository. Today `SettingsRepository.load()` returns `AppSettings`
directly with a dartdoc promising "Never fails", yet its implementation can
throw, and the four `save*` methods catch only `Exception` — letting `Error`
subtypes (e.g. `TypeError` from a wrong-type cached value) escape. This spec
makes every `SettingsRepository` method contain all throwables, returns the
load failure as a value (`Either<Failure, AppSettings>`), and surfaces it
through the existing error stream instead of crashing the app.

Root cause and approach analysis: `research/2026-05-24-load-never-fails.md`
(closes bug 014; bundles sibling bug 010).

## 2. Current State

### `load()` — the unguarded synchronous read (bug 014)

`SettingsRepository.load()` is declared in the domain interface as a synchronous
`AppSettings load()` with the dartdoc "Never fails — returns defaults if nothing
is stored" (`lib/features/settings/domain/repositories/settings_repository.dart:17-20`).

The implementation chains four data-source getters with **no `try/catch`**
(`lib/features/settings/data/repositories/settings_repository_impl.dart:21-27`):

```dart
AppSettings load() => AppSettings(
      useSystemTheme: _dataSource.getUseSystemTheme(),
      manualThemeMode: _dataSource.getThemeMode(),
      useSystemLanguage: _dataSource.getUseSystemLanguage(),
      manualLanguage: _dataSource.getManualLanguage(),
    );
```

Of the four getters in `settings_local_data_source.dart`, **only `getThemeMode()`
is defensively guarded** (lines 40-51 — a `try/catch` that absorbs the `TypeError`
`SharedPreferencesWithCache.getString` throws on legacy `int` data). The other
three are unguarded:
- `getUseSystemTheme()` → `_prefs.getBool(...)` (line 61)
- `getUseSystemLanguage()` → `_prefs.getBool(...)` (line 70)
- `getManualLanguage()` → `_prefs.getString(...)` (lines 76-82)

If any of those three keys holds a wrong-type cached value (legacy data, cache
corruption, a platform-channel edge case), the cast inside
`SharedPreferencesWithCache` throws a `TypeError`. `TypeError` extends `Error`,
not `Exception`, so nothing catches it and it propagates out of `load()`.

The **only production consumer** of `load()` is `SettingsNotifier.build()`
(`lib/features/settings/presentation/providers/settings_provider.dart:85-91`),
which returns `repo.load()` synchronously. This runs inside `DoslyApp` —
**after** the `AppBootstrap` splash/retry gate (feature 021), which only guards
`SharedPreferencesWithCache.create()`, not the synchronous read. A throw from
`load()` therefore lands in the provider tree behind the gate as an uncaught
build error → frozen/crashed app. The "Never fails" doc is both inaccurate and
an unguarded crash path.

### `save*` methods — catch only `Exception` (bug 010)

All four mutators in `settings_repository_impl.dart` (lines 30-69) use
`} on Exception catch (e) { return Left(CacheFailure(e.toString())); }`.
`Error` subtypes (`StateError`, `ArgumentError`, `RangeError`, `TypeError` — all
plausibly thrown by the prefs platform bridge) escape unconverted. Additionally,
`e.toString()` on platform-channel errors can embed the absolute filesystem path
of the on-disk store, leaking it into `CacheFailure.message` (CWE-209-adjacent).

### Existing infrastructure this spec relies on

- `Failure.unknown(Object error, StackTrace stack)` already exists
  (`lib/core/error/failures.dart:43-48`) for uncategorized throwables.
- `SettingsNotifier` already owns a broadcast `StreamController<Failure> _errors`
  exposed via `settingsErrorsProvider` (`settings_provider.dart:73-83, 205-216`),
  used today to surface `save*` failures to the UI.
- `const AppSettings()` provides safe defaults via `@Default` annotations
  (`lib/features/settings/domain/entities/app_settings.dart:38-43`).
- `fpdart`'s `Either<L, R>` is synchronous — a sync `Either` return needs no
  `Future`/`async`.

### docs/architecture.md

The error-handling section documents the `Either<Failure, T>` boundary contract
and the "exceptions never escape the data layer" rule. This spec brings `load()`
into conformance; docs must be updated to reflect that `load()` now returns
`Either` (handled by `/finalize` via tech-writer).

## 3. Desired Behavior

1. **`load()` returns `Either<Failure, AppSettings>` (synchronous).**
   - Domain interface signature changes from `AppSettings load();` to
     `Either<Failure, AppSettings> load();` (no `Future` — stays synchronous).
   - The implementation wraps its four-getter chain in `try { ... } catch (e, st)`,
     returning `Right(settings)` on success and `Left(Failure.unknown(e, st))` on
     any throw (Exception **or** Error).
   - The dartdoc is rewritten to describe the `Either` contract honestly
     (replacing the "Never fails" claim).

2. **`SettingsNotifier.build()` folds the `Either`.**
   - `Left(failure)` → set state to `const AppSettings()` (graceful default)
     **and** emit `failure` to the existing `_errors` stream so it surfaces via
     `settingsErrorsProvider` (not silently swallowed — §4.2).
   - `Right(settings)` → set state to `settings`.
   - `build()` continues to return `AppSettings` synchronously (no signature
     change to the notifier).
   - Note: `build()` runs during notifier construction; emitting to `_errors`
     here must not throw if there are no subscribers yet (the broadcast
     controller tolerates this — events with no listener are simply dropped).

3. **The four `save*` methods catch all throwables.**
   - Change `} on Exception catch (e) {` to `} catch (e, st) {` in all four
     methods (`saveThemeMode`, `saveUseSystemTheme`, `saveUseSystemLanguage`,
     `saveManualLanguage`).
   - Route the caught throwable to `Left(Failure.unknown(e, st))` instead of
     `Left(CacheFailure(e.toString()))`, avoiding the platform-path leak.

4. **No throwable escapes any `SettingsRepository` method** — `load()` and all
   four `save*` methods return a `Left`/default rather than propagating any
   `Exception` or `Error`.

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Domain contract | `lib/features/settings/domain/repositories/settings_repository.dart` | Change `load()` return type to `Either<Failure, AppSettings>`; rewrite dartdoc |
| Repository impl — load | `lib/features/settings/data/repositories/settings_repository_impl.dart:21-27` | Wrap getter chain in `try/catch (e, st)`; return `Right`/`Left(Failure.unknown)` |
| Repository impl — saves | `lib/features/settings/data/repositories/settings_repository_impl.dart:30-69` | Change all four `on Exception catch (e)` → `catch (e, st)`; return `Failure.unknown(e, st)` |
| Notifier consumer | `lib/features/settings/presentation/providers/settings_provider.dart:85-91` | `build()` folds the `Either`: Left → default state + emit to `_errors`; Right → settings |
| Repo impl tests | `test/features/settings/data/repositories/settings_repository_impl_test.dart` | Update 13 `load()` call sites to unwrap `Either`; add failing-data-source tests for `load()` and each `save*`; add wrong-type-cached-value tests for the 3 previously-unguarded keys |
| Notifier tests | `test/features/settings/presentation/providers/settings_provider_test.dart` | Add/adjust tests for the Left-on-load path (default state + error emission) |

## 5. Acceptance Criteria

- [x] **AC-1**: `SettingsRepository.load()` is declared as `Either<Failure, AppSettings> load()` (synchronous) in the domain interface, and its dartdoc accurately describes the `Either` contract (no "Never fails" claim).
- [x] **AC-2**: A wrong-type cached value for **any** of `themeMode`, `useSystemTheme`, `useSystemLanguage`, or `manualLanguage` causes `load()` to return a value (never throws an `Exception` or `Error` out of `load()`).
- [x] **AC-3**: When the underlying data source throws during `load()`, `load()` returns `Left(Failure.unknown(error, stack))`.
- [x] **AC-4**: When the data source succeeds, `load()` returns `Right(settings)` with the correctly read values.
- [x] **AC-5**: `SettingsNotifier.build()` returns `const AppSettings()` as state when `load()` returns `Left`, and emits that `Failure` to the `settingsErrorsProvider` stream.
- [x] **AC-6**: `SettingsNotifier.build()` returns the loaded `AppSettings` as state when `load()` returns `Right`.
- [x] **AC-7**: Each of the four `save*` methods returns `Left(Failure.unknown(error, stack))` (not `CacheFailure`) when the data source throws **any** throwable, including `Error` subtypes — verified with a data source that throws an `Error`.
- [x] **AC-8**: No `save*` method puts the raw `e.toString()` of a platform exception into a `CacheFailure.message` (the `Failure.unknown` route is used for uncategorized throws).
- [x] **AC-9**: Existing happy-path repository tests and the legacy-`int`-`themeMode` fallback test continue to pass (adapted only to unwrap the new `Either` return where they call `load()`).
- [x] **AC-10**: `dart analyze` passes with no new warnings/errors; the full test suite (`flutter test`) passes.

## 6. Out of Scope

- NOT included: introducing the typed logger (bug 017 / `lib/core/logging/`). Failures are surfaced via the existing `_errors` stream, not logged. Logging integration is deferred to the bug-017 work.
- NOT included: changing the `Failure` hierarchy (e.g. adding a new `Failure` variant). `Failure.unknown` is reused as-is.
- NOT included: changing `SettingsNotifier.build()`'s return type to `AsyncValue`/`Future` (research Option C). `build()` stays synchronous; only its internal fold changes.
- NOT included: hardening per-getter `try/catch` in `SettingsLocalDataSource` (research Option C). The single containment point is `load()` in the repository impl. `getThemeMode()`'s existing guard stays as-is (it is not removed).
- NOT included: any change to the `AppBootstrap`/splash startup flow (feature 021).
- NOT included: changes to the five `save*`-backed use cases (`SetThemeMode`, etc.) or their providers — only the repository impl's catch blocks change.
- NOT included: error-containment audits of any repository other than `SettingsRepository`.

## 7. Technical Constraints

- Must follow constitution §3.2: every repository method returns `Either<Failure, T>`; exceptions never escape the data layer; every `.fold` handles both branches.
- Must follow §4.2: the load failure must be surfaced (via `_errors`), not silently swallowed.
- Must use `fpdart`'s synchronous `Either` for `load()` — no `Future`/`async` added to the load path.
- Must use the existing `Failure.unknown(Object error, StackTrace stack)` variant for uncategorized throwables; must NOT route them to `CacheFailure(e.toString())`.
- Must keep the domain layer pure Dart (§2.1) — `Either`/`Failure` already satisfy this.
- Must not break feature 021's startup flow or the `settingsErrorsProvider` UI surface (spec 014).
- `dart analyze` must pass (PostToolUse hook enforces this); generated files are not involved (no `freezed`/codegen signature changes to `Failure` or providers).

## 8. Open Questions

- **OQ-1**: Should `getThemeMode()`'s existing internal `try/catch` (data-source level) be left untouched? Current decision: **yes, leave it** — it is defense-in-depth and removing it is out of scope. The repository-level `try/catch` is the contractual containment point. (Resolved as stated unless reviewer objects.)
- **OQ-2**: When `build()` emits a `Left` failure to `_errors` but no UI listener is mounted yet at startup, the event is dropped (broadcast stream, event-driven). Is dropping acceptable for the first load, or should startup load-failures be retained? Current decision: **acceptable** — matches the existing documented behavior of `settingsErrorsProvider` (failures emitted with no subscriber are not buffered). Revisit only if a startup-error UX is desired (would be a separate spec).

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Changing `load()`'s signature breaks the 13 test call sites and the one notifier consumer | High | Low | Mechanical change; all call sites are known (grep-verified: 1 prod consumer, 1 test file). Update in the same task. |
| `build()` emitting to `_errors` during notifier construction throws or causes a re-entrant build | Low | Med | Broadcast controller tolerates no-listener emits; emit after state is set; covered by a notifier test (AC-5). |
| Reviewers prefer research Option C (data-source guards) over Option A | Low | Low | Spec explicitly scopes to Option A per the approved research; Option C is documented as the rejected alternative in §6. |
| Hidden corrupt state now silently defaults instead of crashing, masking a real data problem | Med | Low | Failure is surfaced via `_errors` (not swallowed); full logging deferred to bug 017 (noted in §6). |
