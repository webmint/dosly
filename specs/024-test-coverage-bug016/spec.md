# Spec: Test-coverage hardening (Bug 016)

**Date**: 2026-05-27
**Status**: Complete
**Author**: Claude + Webmint

## 1. Overview

Close the still-open test-coverage gaps from Bug 016 (filed 2026-04-30 by the
audit's qa-engineer pass). Re-verification against the current tree shows the
bug is largely stale: of its 10 sub-items, 2 are already covered by tests that
landed since (4, 7), and 2 are moot because the `theme_preview` feature was
deleted in spec 020 (5, 6). The remaining 6 collapse into a small,
**test-only-plus-one-doc-line** task: three new test files, a documenting
comment on one defensive guard, and a DRY cleanup of duplicated locale-fallback
logic across the test harnesses. No production behavior changes.

## 2. Current State

Source-of-truth for the gaps is `research/2026-05-27-bug-016-test-coverage.md`
and `bugs/016-test-coverage-gaps-consolidated.md`. Verified current facts:

- **Datasource — no test file**: `lib/features/settings/data/datasources/settings_local_data_source.dart`
  has six public methods and **no** mirroring test. `test/features/settings/data/`
  contains only `repositories/`. Constitution §3.4 mandates a 1:1 `test/`
  mirror for data-layer code and marks data-layer coverage **mandatory**.
  Relevant untested branches:
  - `getThemeMode()` (lines 40–51): the legacy-`int` `catch (_)` fallback to
    `AppThemeMode.light` (the code was rewritten string-based in spec 012; the
    bug's original "negative-index" framing no longer applies).
  - `getManualLanguage()` (lines 76–82): `null` code → `AppLanguage.en` vs.
    non-null → `fromLanguageCodeOrDefault(code)` (incl. empty/unknown string).
  - `getUseSystemTheme()` / `getUseSystemLanguage()` `?? true` defaults
    (lines 61, 70); the four setters round-trip via `SharedPreferencesWithCache`.
- **Home gear-tap navigation**: `lib/features/home/presentation/screens/home_screen.dart:34`
  has an `IconButton` with `onPressed: () => context.push('/settings')` and
  `tooltip: context.l10n.settingsTooltip`. No `home_screen_test.dart` exists;
  `app_router_test.dart` Test 6 pushes `/settings` programmatically, never via
  the gear. The route's destination is `SettingsScreen`.
- **`resolveAppLocale`**: already extracted to
  `lib/core/l10n/locale_resolver.dart` (function `resolveAppLocale(Locale?,
  Iterable<Locale>)`; `null`/match/unsupported → English fallback). It has
  **no** direct unit test (`test/core/l10n/` does not exist). `/verify` for
  spec 021 already filed this as a known test-coverage Warning (MEMORY L110).
  Separately, **7** test harnesses each define their own private copy of the
  identical fallback logic instead of calling the production function:
  - `test/core/routing/app_bottom_nav_l10n_test.dart:13`
  - `test/features/settings/presentation/screens/settings_screen_test.dart:73`
  - `test/features/settings/presentation/widgets/theme_selector_test.dart` (~56)
  - `test/features/settings/presentation/widgets/language_selector_test.dart` (~61)
  - `test/features/history/presentation/screens/history_screen_test.dart:13`
  - `test/features/meds/presentation/screens/meds_screen_test.dart:15`
  - `test/features/meds/presentation/widgets/add_medication_modal_test.dart:9`
  This is a clear DRY violation (1 production + 7 test copies of the same
  function) by the constitution's 3+ rule (§3.6).
- **`language_selector` guard**: `lib/features/settings/presentation/widgets/language_selector.dart:81`
  has `if (selected != null)` inside `DropdownButton<AppLanguage>.onChanged`.
  `DropdownButton.onChanged` is typed `ValueChanged<T?>?` but only ever fires
  with a non-null value when an item is tapped, so the `false` branch is
  unreachable through the UI — it is defensive only. `language_selector_test.dart`
  exercises the enabled/disabled states and selection, but the guard's purpose
  is undocumented.

Already-resolved sub-items (no action; recorded for the bug file update):
- **copyWith (4)**: covered by `test/features/settings/domain/entities/app_settings_test.dart`.
- **Repository exception-catch (7)**: covered by `settings_repository_impl_test.dart`'s
  throwing data-source doubles asserting `Left(UnknownFailure)` for all 4 setters.

Moot sub-items (feature removed in spec 020):
- **theme_preview icon selection (5)** and **cycle branch (6)** — `lib/features/theme_preview/`
  no longer exists.

Testing conventions to follow (constitution §3.4, MEMORY): `flutter_test` +
`mocktail`, no codegen; tests isolated; no real `DateTime.now()` / sleeps;
every test asserts. For `SharedPreferencesWithCache`, use
`SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty()`
then `SharedPreferencesWithCache.create(...)` (MEMORY L112), **not** the legacy
`setMockInitialValues`.

## 3. Desired Behavior

1. A new `settings_local_data_source_test.dart` exercises all six public
   methods of `SettingsLocalDataSource`, including: the legacy-`int`
   `catch (_)` fallback in `getThemeMode()`, the `null` / empty / unknown-code
   paths of `getManualLanguage()`, the `?? true` defaults of both `getUseSystem*`
   getters, and a write→read round-trip for each of the four setters.
2. A new `home_screen_test.dart` mounts `HomeScreen` in a `MaterialApp.router`
   harness, taps the settings gear (located by tooltip or
   `LucideIcons.settings` icon), and asserts navigation lands on `SettingsScreen`.
3. A new `locale_resolver_test.dart` directly unit-tests `resolveAppLocale`:
   `null` device locale → `Locale('en')`; a supported device locale → that
   supported locale; an unsupported device locale → `Locale('en')` (proving the
   English-fallback policy independent of `supportedLocales` ordering).
4. All 7 test harnesses that define a private `_resolveLocale` copy are
   refactored to import and use the production `resolveAppLocale` from
   `core/l10n/locale_resolver.dart`; the local copies (and their doc comments)
   are deleted. Harness behavior is unchanged.
5. `language_selector.dart:81`'s `if (selected != null)` guard gains a single
   one-line `//` comment explaining it is defensive against `DropdownButton`'s
   nullable `onChanged` signature. The guard is **kept** (no `!` introduced).
6. `bugs/016-test-coverage-gaps-consolidated.md` is updated: sub-items 1, 2, 3,
   8, 9, 10 marked fixed (referencing this spec); 4 & 7 marked already-closed;
   5 & 6 marked moot (theme_preview removed in spec 020); Status set to Fixed
   with the fix date.

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Datasource test | `test/features/settings/data/datasources/settings_local_data_source_test.dart` | Create new |
| Home screen test | `test/features/home/presentation/screens/home_screen_test.dart` | Create new |
| Locale resolver test | `test/core/l10n/locale_resolver_test.dart` | Create new |
| Harness dedup (×7) | `test/core/routing/app_bottom_nav_l10n_test.dart`, `test/features/settings/presentation/screens/settings_screen_test.dart`, `test/features/settings/presentation/widgets/theme_selector_test.dart`, `test/features/settings/presentation/widgets/language_selector_test.dart`, `test/features/history/presentation/screens/history_screen_test.dart`, `test/features/meds/presentation/screens/meds_screen_test.dart`, `test/features/meds/presentation/widgets/add_medication_modal_test.dart` | Replace local `_resolveLocale` with imported `resolveAppLocale` |
| Guard doc | `lib/features/settings/presentation/widgets/language_selector.dart` | Add one-line comment at line 81 |
| Bug bookkeeping | `bugs/016-test-coverage-gaps-consolidated.md` | Update sub-item statuses + Status/Fixed |

## 5. Acceptance Criteria

- [x] **AC-1**: `test/features/settings/data/datasources/settings_local_data_source_test.dart` exists and tests `getThemeMode()` for (a) a stored valid code, (b) absent key → `AppThemeMode.light`, and (c) the legacy-`int` `catch (_)` fallback → `AppThemeMode.light`.
- [x] **AC-2**: The same file tests `getManualLanguage()` for `null` (→ `AppLanguage.en`), an unknown/empty stored code (→ default), and a valid stored code (→ matching language).
- [x] **AC-3**: The same file tests both `getUseSystemTheme()` and `getUseSystemLanguage()` returning `true` when the key is absent, and reflecting a stored `false`; and a write→read round-trip for each of `setThemeMode`, `setUseSystemTheme`, `setUseSystemLanguage`, `setManualLanguage`.
- [x] **AC-4**: The datasource test uses `InMemorySharedPreferencesAsync` + `SharedPreferencesWithCache.create` (no legacy `setMockInitialValues`), runs in isolation, and contains no `await Future.delayed` / real `DateTime.now()`.
- [x] **AC-5**: `test/features/home/presentation/screens/home_screen_test.dart` exists, taps the settings gear via tooltip or `LucideIcons.settings`, and asserts `find.byType(SettingsScreen)` is found after the tap.
- [x] **AC-6**: `test/core/l10n/locale_resolver_test.dart` exists and asserts `resolveAppLocale` returns `Locale('en')` for `null` deviceLocale, the matching supported locale for a supported deviceLocale, and `Locale('en')` for an unsupported deviceLocale.
- [x] **AC-7**: None of the 7 listed harness files define a private `_resolveLocale` function any more; each imports `resolveAppLocale` from `core/l10n/locale_resolver.dart` and passes it to `localeResolutionCallback`.
- [x] **AC-8**: `language_selector.dart` line ~81 retains the `if (selected != null)` guard with a new one-line `//` comment explaining the defensive rationale; no `!` null-assertion is introduced.
- [x] **AC-9**: `bugs/016-test-coverage-gaps-consolidated.md` Status is `Fixed` with a Fixed date, and each of the 10 sub-items is annotated (fixed / already-closed / moot) per §3 item 6.
- [x] **AC-10**: `dart analyze` reports no new issues, and `flutter test` passes (all pre-existing tests plus the new ones).

## 6. Out of Scope

- NOT included: any change to production logic in `settings_local_data_source.dart`, `home_screen.dart`, `locale_resolver.dart`, or `app.dart` (the only `lib/` edit is the one-line comment in `language_selector.dart`).
- NOT included: removing the `language_selector` guard or replacing it with `selected!`.
- NOT included: re-testing sub-items 4 and 7 (already covered) or restoring/testing the deleted `theme_preview` feature (sub-items 5, 6).
- NOT included: adding coverage tooling, CI thresholds, or coverage gates.
- NOT included: golden/integration tests — these are unit/widget tests only.
- NOT included: refactoring the harnesses beyond replacing the duplicated `_resolveLocale` (e.g., no extraction of a shared `pumpApp` helper).

## 7. Technical Constraints

- Must follow constitution §3.4 testing rules: `flutter_test` + `mocktail`, 1:1 `test/` mirror, isolated tests, every test asserts, no sleeps, no real `DateTime.now()`.
- Must follow §3.6 DRY: the harness dedup removes duplicated logic rather than adding a 4th+ copy.
- Must not introduce `!` null-assertions (Key Rule Never #7).
- Must not put Flutter imports in `domain/` (N/A here — all edits are in `test/`, `core/l10n` consumers, and one presentation widget comment).
- Widget/datasource tests must compile-and-run in the sandbox; manual on-device runs are not required for these unit/widget tests.

## 8. Open Questions

- OQ-1: The home-screen test asserts navigation reaches `SettingsScreen`. If `SettingsScreen`'s own dependencies (providers) make it expensive to fully build in the test harness, the assertion may instead verify the pushed route path (`/settings`) via a router observer. Decide during `/breakdown` based on how heavy `SettingsScreen` is to mount.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Harness dedup (7 files) introduces an import error or breaks an existing test | Med | Low | Mechanical substitution; `flutter test` (AC-10) catches any breakage immediately; change is import + callback reference only |
| `SharedPreferencesWithCache` test setup is fiddly | Med | Low | Follow the exact recipe in MEMORY L112 (`InMemorySharedPreferencesAsync` + `create`) |
| Home-screen test can't cheaply mount `SettingsScreen` | Low | Low | Fallback to route-observer assertion (OQ-1) |
| `dart analyze` blind spot leaves orphaned harness members after dedup | Low | Low | After deleting each `_resolveLocale`, grep the file for now-unused imports/helpers (MEMORY L103); code-review step backstops |
