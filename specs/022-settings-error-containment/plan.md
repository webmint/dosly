# Plan: Settings Data-Layer Error Containment

**Date**: 2026-05-24
**Spec**: [spec.md](spec.md)
**Status**: Approved

## Summary

Bring `SettingsRepository` into full conformance with constitution §3.2 by
containing every throwable in the data layer. `load()` becomes a synchronous
`Either<Failure, AppSettings>` whose impl wraps the four-getter chain in a
`try/catch (e, st)`; `SettingsNotifier.build()` folds the result (Left → default
state + emit to the existing `_errors` stream; Right → loaded settings). The four
`save*` methods widen their catch from `on Exception` to `catch (e, st)` and route
uncategorized throws to `Failure.unknown(e, st)` instead of `CacheFailure(e.toString())`.

## Technical Context

**Architecture**: Clean Architecture — touches `domain/repositories` (contract),
`data/repositories` (impl), and `presentation/providers` (consumer fold). No new
layers, no data-source changes.
**Error Handling**: `fpdart` synchronous `Either<Failure, T>`. Reuses the existing
`Failure.unknown(Object error, StackTrace stack)` variant (`lib/core/error/failures.dart:43-48`).
**State Management**: Riverpod `@Riverpod(keepAlive:)` notifier; `build()` stays
synchronous (returns `AppSettings`), only its internal extraction changes from a
direct return to a `.fold`.

## Constitution Compliance

- **§3.2 (Either at every repository return; exceptions never escape; fold both branches)** — compliant: this is the rule being enforced. `load()` gains `Either`; both `save*` and `load()` catch all throwables; `build()`'s `.fold` handles both branches.
- **§4.2 (never swallow errors)** — compliant: the load failure is emitted to `settingsErrorsProvider`, not silently dropped. (Startup-with-no-listener drop is the documented, accepted behavior of that broadcast stream — spec OQ-2.)
- **§3.1 (no `!`, no unchecked `as`, exhaustive switch)** — compliant: `.fold` avoids null assertions; no casts introduced.
- **§2.1 (domain stays pure Dart)** — compliant: `Either`/`Failure` are pure-Dart and already imported in `domain/`.
- **§4.2.1 (no `print`/`debugPrint`)** — compliant: no logging added (deferred to bug 017, per spec §6).
- **§6.1 (minimal changes)** — compliant: production change is 3 files; the broader test fan-out is mechanical signature alignment, not behavior change.

## Implementation Approach

### Layer Map

| Layer | What | Files (existing or new) |
|-------|------|------------------------|
| Domain | Change `load()` contract to `Either<Failure, AppSettings>`; rewrite dartdoc | `lib/features/settings/domain/repositories/settings_repository.dart` (modify) |
| Data | Wrap `load()` chain in `try/catch`; widen 4 `save*` catches; route to `Failure.unknown` | `lib/features/settings/data/repositories/settings_repository_impl.dart` (modify) |
| Presentation | `build()` folds the `Either` (Left → default + emit; Right → settings) | `lib/features/settings/presentation/providers/settings_provider.dart` (modify) |
| Tests | Update repo-impl tests; add failure-path tests; align 7 hand-written fakes to the new `load()` signature | see File Impact |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| `load()` return shape | Synchronous `Either<Failure, AppSettings>` | Honors §3.2 letter; failure becomes a value; aligns with `save*` siblings | Option B (try/catch→default + honest doc): swallows, needs bug-017 logger. Option C (per-getter guards): doesn't satisfy "return Either" |
| Single containment point | Wrap the chain in `load()` impl, not each getter | One boundary to reason about; KISS; keeps `getThemeMode`'s existing guard as defense-in-depth | Per-getter `try/catch` (Option C) — more duplication, doesn't change the contract |
| Where load-Left surfaces | Emit to existing `_errors` stream; set state to `const AppSettings()` | Reuses spec-014 infra; satisfies §4.2 without a logger | Throw (status quo — crashes); silently default (violates §4.2) |
| `save*` failure variant | `Failure.unknown(e, st)` for all caught throwables | Avoids leaking platform filesystem paths via `e.toString()` (CWE-209); captures stack | Keep `CacheFailure(e.toString())` — leaks paths, loses stack |
| `build()` return type | Keep synchronous `AppSettings` | Preserves the sync-read contract feature-021 depends on; smallest blast radius | `AsyncValue`/`Future` (research Option C) — large rewrite of `app.dart` |

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `lib/features/settings/domain/repositories/settings_repository.dart` | Modify | `load()` → `Either<Failure, AppSettings> load();`; rewrite dartdoc (drop "Never fails", describe Either contract) |
| `lib/features/settings/data/repositories/settings_repository_impl.dart` | Modify | `load()`: wrap getter chain in `try { return Right(AppSettings(...)); } catch (e, st) { return Left(Failure.unknown(e, st)); }`. `saveThemeMode`/`saveUseSystemTheme`/`saveUseSystemLanguage`/`saveManualLanguage`: `on Exception catch (e)` → `catch (e, st)`; `CacheFailure(e.toString())` → `Failure.unknown(e, st)` |
| `lib/features/settings/presentation/providers/settings_provider.dart` | Modify | `build()` body: `return repo.load().fold((f) { _errors.add(f); return const AppSettings(); }, (s) => s);` |
| `test/features/settings/data/repositories/settings_repository_impl_test.dart` | Modify | Unwrap `Either` at 13 `load()` call sites (e.g. `(repository.load() as Right).value` via fold/`getRight`-free pattern match); **add**: failing-data-source test → `load()` returns `Left`; wrong-type cached value tests for `useSystemTheme`/`useSystemLanguage`/`manualLanguage` → `load()` returns a value (no throw); failing-data-source tests → each `save*` returns `Left(UnknownFailure)` incl. an `Error` thrower |
| `test/features/settings/presentation/providers/settings_provider_test.dart` | Modify | Update `_FakeSettingsRepository.load()` (line 50) to return `Either`; add a `failOnLoad` flag; add test: Left-on-load → state is `const AppSettings()` AND failure emitted to `settingsErrorsProvider` |
| `test/app_bootstrap_test.dart` | Modify | Fake `load()` (line 37) → `Either<Failure, AppSettings> load() => const Right(AppSettings());` |
| `test/widget_test.dart` | Modify | Fake `load()` (line 24) → return `Right(_settings)` |
| `test/core/routing/app_router_test.dart` | Modify | Fake `load()` (line 33) → `const Right(AppSettings())` |
| `test/features/settings/presentation/screens/settings_screen_test.dart` | Modify | Fake `load()` (line 27) → `Right(_settings)` |
| `test/features/settings/presentation/widgets/theme_selector_test.dart` | Modify | Fake `load()` (line 26) → `Right(_settings)` |
| `test/features/settings/presentation/widgets/language_selector_test.dart` | Modify | Fake `load()` (line 31) → `Right(_settings)` |

> **Discovered during planning (not in spec §4 Affected Areas):** the 5 hand-written
> fakes in `app_bootstrap_test.dart`, `widget_test.dart`, `app_router_test.dart`,
> `settings_screen_test.dart`, `theme_selector_test.dart`, `language_selector_test.dart`
> all override `AppSettings load()` and must adopt the new `Either` signature or the
> suite won't compile. These are one-line mechanical edits. The 5 use-case test mocks
> (`set_*_test.dart`, `cycle_theme_mode_test.dart`) use mocktail (`Mock implements`)
> and do **not** override `load()`, so they need no change.

### Documentation Impact

| Doc File | Action | What Changes |
|----------|--------|-------------|
| `docs/architecture.md` | Update | Error-handling section: note `SettingsRepository.load()` now returns `Either<Failure, AppSettings>` and that the settings notifier surfaces load failures via `settingsErrorsProvider`. (Handled by tech-writer at `/finalize`.) |
| `docs/features/settings*.md` | Update (if present) | Reflect the load-failure surfacing behavior, if the settings feature doc describes the load path. |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Test fan-out larger than spec implied (7 fakes across 7 files) | High (already realized) | Low | All sites grep-identified and listed; mechanical one-line edits; covered in a dedicated test task |
| `_errors.add` during `build()` throws / triggers re-entrant build | Low | Med | Broadcast controller tolerates no-listener emits; emit inside the fold after controller init; assert via notifier test (AC-5) |
| `e.toString()` path-leak fix changes existing `save*` failure-message assertions | Med | Low | Existing `save*` tests assert `isA<Left>` / `isA<Right>`, not message contents (verified in repo-impl test); update only if a message assertion exists |
| Unwrapping `Either` in repo-impl tests tempts a forbidden partial extractor (`.getRight()`, `.toIterable().first`) | Med | Low | Use pattern-matching/`fold` in tests per §3.2; call out in the test task |
| AC-9 regression: legacy-int `themeMode` test | Low | Med | `getThemeMode`'s internal guard is untouched (spec §6); test only needs `Either`-unwrap adaptation |

## Dependencies

None. No packages to install, no services to configure. `fpdart` (`Either`, `Right`, `Left`) and `Failure.unknown` are already in the project.

## Plan–Spec Cross-Reference

| AC | Covered by |
|----|-----------|
| AC-1 (sync `Either` + honest dartdoc) | Domain contract change (settings_repository.dart) |
| AC-2 (wrong-type cache never throws) | `load()` try/catch in impl; repo-impl tests for 3 keys |
| AC-3 (data-source throw → `Left(Failure.unknown)`) | `load()` catch branch; repo-impl failing-source test |
| AC-4 (success → `Right(settings)`) | `load()` try branch; existing happy-path tests (adapted) |
| AC-5 (Left → default state + emit) | `build()` fold; notifier test |
| AC-6 (Right → loaded state) | `build()` fold; notifier test |
| AC-7 (`save*` catch `Error` → `Failure.unknown`) | 4 `save*` catch-widening; repo-impl `Error`-thrower tests |
| AC-8 (no raw `toString` in `CacheFailure`) | `save*` route to `Failure.unknown`; repo-impl test |
| AC-9 (existing + legacy-int tests pass) | Mechanical `Either`-unwrap in repo-impl test; `getThemeMode` guard untouched |
| AC-10 (`dart analyze` + `flutter test` clean) | All test fakes aligned to new signature; verification phase per task |

All 10 ACs have an implementation path. No AC left uncovered.

## Supporting Documents

None generated — no external libraries, architectural decisions, new data entities, or API contracts were involved (the approach was already decided in `research/2026-05-24-load-never-fails.md`).
