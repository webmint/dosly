# Plan: Test-coverage hardening (Bug 016)

**Date**: 2026-05-27
**Spec**: specs/024-test-coverage-bug016/spec.md
**Status**: Approved

## Summary

Add three new test files (datasource, home-screen navigation, locale resolver),
deduplicate the 7 copied `_resolveLocale` harness functions into the existing
production `resolveAppLocale`, document the `language_selector` defensive guard,
and update the Bug 016 record. All work lives in `test/` plus one one-line
comment in a presentation widget and one Markdown bug file — no production logic
changes, no new dependencies.

## Technical Context

**Architecture**: Touches the test mirror of the data layer
(`SettingsLocalDataSource`), presentation layer (`HomeScreen`,
`LanguageSelector`), and a core utility (`resolveAppLocale`). The only `lib/`
edit is a comment.
**Error Handling**: N/A — no fallible production code added. The datasource's
existing `catch (_)` legacy-int fallback is exercised, not changed.
**State Management**: Riverpod. Widget tests override `settingsRepositoryProvider`
with an in-test fake (existing pattern), never real prefs in widget tests.

## Constitution Compliance

- **§3.4 Testing (1:1 mirror, mandatory data-layer coverage)**: compliant — adds
  the missing `settings_local_data_source_test.dart` and `locale_resolver_test.dart`
  mirrors; uses `flutter_test` + `InMemorySharedPreferencesAsync`, no codegen.
- **§3.4 Forbidden-in-tests**: compliant — no real `DateTime.now()`, no
  `Future.delayed` sleeps, every test asserts, tests isolated (fresh prefs per test).
- **§3.6 DRY (3+ rule)**: compliant — removes 7 duplicate `_resolveLocale`
  copies rather than adding an 8th; consumers call the single production function.
- **Never #7 (no `!` without certainty)**: compliant — the `language_selector`
  guard is documented and kept; no null-assertion introduced.
- **Never #8 (no Flutter imports in `domain/`)**: N/A — no `domain/` edits.
- **§3.5 No dead code**: after deleting each harness `_resolveLocale`, orphaned
  imports are removed (MEMORY L103 — `dart analyze` won't flag unused private
  members, so this is a manual grep step).

## Implementation Approach

### Layer Map

| Layer | What | Files (existing or new) |
|-------|------|------------------------|
| Data (test) | New unit tests for `SettingsLocalDataSource` | `test/features/settings/data/datasources/settings_local_data_source_test.dart` (new) |
| Presentation (test) | New widget test for gear→Settings nav | `test/features/home/presentation/screens/home_screen_test.dart` (new) |
| Core (test) | New unit test for `resolveAppLocale` | `test/core/l10n/locale_resolver_test.dart` (new) |
| Test harnesses | Replace local `_resolveLocale` with `resolveAppLocale` | 7 existing test files (see File Impact) |
| Presentation (lib) | One-line comment on defensive guard | `lib/features/settings/presentation/widgets/language_selector.dart` |
| Docs/bookkeeping | Update Bug 016 sub-item statuses | `bugs/016-test-coverage-gaps-consolidated.md` |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| Datasource prefs setup | `SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.withData({...})` then `SharedPreferencesWithCache.create(...)` per test | Matches the proven pattern in `settings_repository_impl_test.dart:14-38` (MEMORY L112); gives a real cache, fresh per test | Legacy `setMockInitialValues` (wrong API for the async cache); mocking `create` (static, hard to inject) |
| Legacy-int catch trigger | Seed `withData({'themeMode': 1})` (an `int`), then call `getThemeMode()` — `getString` cast throws `TypeError`, the `catch (_)` returns `AppThemeMode.light` | Directly exercises the real degrade-gracefully branch (`settings_local_data_source.dart:44-50`) without faking | Subclassing to force a throw (less faithful to the real legacy-data scenario) |
| Home-nav test harness (OQ-1) | Minimal 2-route `GoRouter` (`/`→`HomeScreen`, `/settings`→real `SettingsScreen`) inside a `ProviderScope` overriding `settingsRepositoryProvider` with an always-success fake; tap gear, `pumpAndSettle`, assert `find.byType(SettingsScreen)` | Mounts the **real** `SettingsScreen` (satisfies AC-5 literally) while the fake repo avoids real prefs; keeps the harness small | Full `appRouterProvider` (pulls in the whole app shell, heavier); route-observer-only assertion (doesn't prove `SettingsScreen` mounts) |
| Harness dedup mechanism | Delete each top-level `_resolveLocale` + its doc comment, add `import 'package:dosly/core/l10n/locale_resolver.dart';`, point `localeResolutionCallback: resolveAppLocale` | Single source of truth; behavior identical (production function is byte-equivalent to the copies) | Leaving copies (DRY violation the bug names); extracting a new shared test helper (the production function already is the helper) |
| `language_selector` guard | Keep `if (selected != null)`, add one `//` line explaining `DropdownButton.onChanged` is typed nullable but only fires non-null on selection | Honors Never #7; documents intent for future readers | Remove guard + `selected!` (introduces `!`); leave undocumented (the flagged state) |

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `test/features/settings/data/datasources/settings_local_data_source_test.dart` | Create | Tests all 6 public methods incl. legacy-int catch, null/empty/unknown language code, `?? true` defaults, setter round-trips (AC-1..4) |
| `test/features/home/presentation/screens/home_screen_test.dart` | Create | Gear-tap → `SettingsScreen` via minimal GoRouter + fake repo (AC-5) |
| `test/core/l10n/locale_resolver_test.dart` | Create | `resolveAppLocale` null/match/unsupported → English (AC-6) |
| `test/core/routing/app_bottom_nav_l10n_test.dart` | Modify | Drop local `_resolveLocale`, use `resolveAppLocale` (AC-7) |
| `test/features/settings/presentation/screens/settings_screen_test.dart` | Modify | Same dedup |
| `test/features/settings/presentation/widgets/theme_selector_test.dart` | Modify | Same dedup |
| `test/features/settings/presentation/widgets/language_selector_test.dart` | Modify | Same dedup |
| `test/features/history/presentation/screens/history_screen_test.dart` | Modify | Same dedup |
| `test/features/meds/presentation/screens/meds_screen_test.dart` | Modify | Same dedup |
| `test/features/meds/presentation/widgets/add_medication_modal_test.dart` | Modify | Same dedup |
| `lib/features/settings/presentation/widgets/language_selector.dart` | Modify | One `//` comment at line ~81 (AC-8) |
| `bugs/016-test-coverage-gaps-consolidated.md` | Modify | Sub-item statuses + Status: Fixed (AC-9) |

### Documentation Impact

No documentation changes expected — test-only work with no feature-behavior
change. The `bugs/016-...md` update is issue bookkeeping (tracked above), not
`docs/`. `docs/features/` and `docs/architecture.md` are unaffected.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Harness dedup (7 files) leaves an unused import or breaks a test | Med | Low | Mechanical substitution; `flutter test` (AC-10) is the backstop; manually drop now-unused imports per file (MEMORY L103) |
| `InMemorySharedPreferencesAsync.withData({'themeMode': 1})` doesn't actually throw on `getString` | Low | Med | Verify the legacy-int test red→green; if the cast doesn't throw, assert the equivalent degrade path another faithful way (e.g. a non-matching string code) and note in task |
| Real `SettingsScreen` needs more provider overrides than just the repo | Low | Low | Add the minimal extra override the build requires; fall back to OQ-1's route-path assertion only if mounting proves disproportionately heavy |
| `allowList` mismatch hides a stored key in datasource tests | Low | Low | Reuse the exact 4-key allowList from `settings_repository_impl_test.dart` |

## Dependencies

None. `flutter_test`, `mocktail`, `shared_preferences`, and
`shared_preferences_platform_interface` are already in `dev_dependencies` /
dependencies. `go_router` and `lucide_icons_flutter` are already used by
`HomeScreen`.

## Supporting Documents

- Research: `research/2026-05-27-bug-016-test-coverage.md` (pre-spec feasibility; no `research.md` needed — no new-tech signals)
- Data Model: N/A — no entities created or changed
- Contracts: N/A — no API surface
