# Research: Bug 016 — Consolidated test-coverage gaps

**Date**: 2026-05-27
**Topic**: Bug 016 — 10 logic-blind-spot sub-items from the 2026-04-30 audit
**Verdict**: **Feasible (Low complexity)** — but the bug is substantially stale; only ~5 of 10 sub-items remain real, and the remaining work is purely additive tests (no spec needed).

## Summary

Bug 016 was filed 2026-04-30 against a snapshot that has since shifted considerably. Verifying each sub-item against the current tree: **2 are already closed** (covered by tests landed since), **2 are moot** (the `theme_preview` feature was deleted by spec 020), and **6 remain real** but collapse into a small, well-scoped test-hardening task — 3 new test files plus one trivial code-style decision. No production behavior changes are required. This is a `/fix`-sized job, not a `/specify` one. The bug file itself should be updated to retire the dead sub-items before fixing.

## Sub-item status (verified against current code)

| # | Sub-item | Current status | Evidence |
|---|----------|----------------|----------|
| 1 | `getThemeMode()` untested branch | **OPEN (reframed)** | Code rewritten (spec 012): now string-based with a legacy-`int` `catch (_)` fallback at `settings_local_data_source.dart:44`. No datasource test exists. |
| 2 | `getManualLanguage()` empty-string | **OPEN** | `settings_local_data_source.dart:76` — `null`→en vs `fromLanguageCodeOrDefault('')` branch, untested. |
| 3 | Home gear-icon tap → `/settings` | **OPEN** | `home_screen.dart:34` `context.push('/settings')`. No `home_screen_test.dart`. |
| 4 | `AppSettings.copyWith` | **CLOSED** | `app_settings_test.dart` now covers all-null + each-field copyWith. (`effectiveThemeMode/Locale` getters no longer exist post bug-001.) |
| 5 | `theme_preview` icon selection | **MOOT** | `lib/features/theme_preview/` deleted (spec 020). |
| 6 | `theme_preview` cycle branch | **MOOT** | Same — feature removed. |
| 7 | Repository exception-catch path | **CLOSED** | `settings_repository_impl_test.dart` has `_ThrowingDataSource` / `_FailingSetterDataSource` proving `Left(UnknownFailure)` for all 4 setters (bug 010 / spec 022). |
| 8 | `language_selector` `selected == null` guard | **OPEN (trivial)** | `language_selector.dart:81` — defensive guard unreachable via `DropdownButton` UI. Document-or-remove decision, not a testable branch. |
| 9 | `_resolveLocale` extraction + test | **OPEN (test only)** | Extraction *done*: now `resolveAppLocale` in `core/l10n/locale_resolver.dart`. But no `test/core/l10n/locale_resolver_test.dart`, and harness copies still duplicate the logic (e.g. `language_selector_test.dart:64`). MEMORY L110 already filed this as a known Warning. |
| 10 | No dedicated datasource test file | **OPEN** | `test/features/settings/data/` has only `repositories/`. Constitution §3.4 mandates a 1:1 mirror. |

**Net**: closed = 4, 7 · moot = 5, 6 · open = 1, 2, 3, 8, 9, 10.

## The remaining work, regrouped

- **A. `test/features/settings/data/datasources/settings_local_data_source_test.dart`** (new) → closes **1, 2, 10**. Cover all 6 public methods: legacy-`int` catch fallback in `getThemeMode`, `null`/empty/unknown code in `getManualLanguage`, `?? true` defaults, and setter round-trips. Use `InMemorySharedPreferencesAsync` + `SharedPreferencesWithCache.create` per MEMORY L112.
- **B. `test/features/home/presentation/screens/home_screen_test.dart`** (new) → closes **3**. `MaterialApp.router` harness, `tester.tap(find.byTooltip(...))` / `find.byIcon(LucideIcons.settings)`, assert `find.byType(SettingsScreen)`.
- **C. `test/core/l10n/locale_resolver_test.dart`** (new) → closes **9** (test side; extraction already shipped). Assert `null` device locale → `en`, matching → match, unsupported → `en` (MEMORY L89 confirms the value). Optional: dedupe the 4 harness copies to call the production function.
- **D. `language_selector.dart:81` guard** → closes **8**. Decision only: add a one-line WHY comment (DropdownButton contract guarantees non-null on selection) or remove the guard. No test possible.

## Constitution / memory constraints

| Source | Impact |
|--------|--------|
| Constitution §3.4 (1:1 `test/` mirror) | Mandates the datasource + locale_resolver test files — directly justifies A and C. |
| MEMORY L110 | `/verify` already logged the missing `resolveAppLocale` unit test as a Warning — sub-item 9 is independently confirmed. |
| MEMORY L103 | After test deletions, grep fakes for orphaned members — relevant if touching shared harness fakes during C's dedup. |
| MEMORY L112 | Exact recipe for testing `SharedPreferencesWithCache` — de-risks A. |

## Complexity assessment

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Codebase changes | Low | 3 new test files + 1 one-line comment/removal. Zero production logic change. |
| New dependencies | None | `flutter_test` + `mocktail` + `shared_preferences_platform_interface` (already in use). |
| Risk | Low | Additive tests; worst case is a flaky harness, not a regression. |

## Recommendation

**Proceed via `/fix`, not `/specify`.** This is 3-4 files, no production behavior change — squarely in the lightweight bug-fix lane. Before fixing, **update `bugs/016-test-coverage-gaps-consolidated.md`** to mark sub-items 4 & 7 closed and 5 & 6 moot (theme_preview removed), so the fix scope reflects reality.

Suggested entry point:

```
/fix "Bug 016: add missing tests — settings_local_data_source_test.dart (sub-items 1,2,10), home_screen_test.dart (3), locale_resolver_test.dart (9); document/remove language_selector null guard (8). Sub-items 4,7 already closed; 5,6 moot (theme_preview removed)."
```

## Next steps

- To proceed: update the bug file's sub-item statuses, then run the `/fix` command above.
- To research deeper: `/research "settings_local_data_source SharedPreferencesWithCache test harness"` if the async-init recipe needs validation.
- To shelve: no action needed.
