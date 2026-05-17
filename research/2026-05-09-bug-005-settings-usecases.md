# Research: Bug 005 — Settings feature missing `domain/usecases/`

**Date**: 2026-05-09
**Topic**: Bug 005 — Settings feature has no `domain/usecases/`; business rules duplicated in widgets
**Verdict**: Feasible

## Summary

Bug 005 is a Critical architectural violation: `SettingsNotifier` calls `SettingsRepositoryImpl` directly (no use case layer), and the cross-cutting "switch-to-manual must pre-fill from device" rule is duplicated across `language_selector.dart` and `theme_selector.dart`. The fix is well-bounded — introduce four use cases under `lib/features/settings/domain/usecases/`, route the notifier through them, and fold the pre-fill rule into the relevant use case. Predecessor bugs (001, 003, 004) have shipped, so the codegen + `AppThemeMode` + error-stream scaffolding is already in place. No new dependencies. Estimate ~5-6 changed source files plus tests.

## Codebase Findings

### Existing Related Code

| Area | Files | Relevance |
|------|-------|-----------|
| Settings notifier | `lib/features/settings/presentation/providers/settings_provider.dart:65–121` | Four mutators each call `ref.read(settingsRepositoryProvider)` directly — exactly the violation |
| Pre-fill rule (theme) | `lib/features/settings/presentation/widgets/theme_selector.dart:55–66` | Duplicated business logic in widget callback |
| Pre-fill rule (language) | `lib/features/settings/presentation/widgets/language_selector.dart:60–72` | Duplicated business logic in widget callback |
| Cycle rule | `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart:52–66` | Adjacent rule (system→light→dark→system) — bug 011 territory, not strictly 005 |
| Repository contract | `lib/features/settings/domain/repositories/settings_repository.dart` | Already returns `Future<Either<Failure, void>>` — clean target for use cases |
| `firstWhere` pattern | `language_selector.dart:42, 65` + `settings_local_data_source.dart:81` | 3rd duplication — fix-notes' `AppLanguage.fromLanguageCodeOrDefault` helper would absorb |

### Patterns Available

- **Riverpod codegen for use case providers** — bug 004 closed; `@riverpod` codegen is wired (`settings_provider.g.dart` exists). Use cases get `@riverpod SetThemeMode setThemeMode(Ref ref) => SetThemeMode(ref.watch(settingsRepositoryProvider));`.
- **`Either<Failure, void>` return type** — repository methods already match the use-case contract shape verbatim. Use cases can be thin pass-throughs (still required by constitution §2.1).
- **Error stream surface** — `SettingsNotifier._errors` already forwards `Left(failure)` via `settingsErrorsProvider`. Use cases returning `Either<Failure, void>` slot in cleanly; the notifier still does the `fold` and pushes onto the stream.
- **Static factory on enum** — `AppThemeMode` (post-bug-001) already lives as a pure-Dart enum; adding a `static AppLanguage fromLanguageCodeOrDefault(String code)` to `app_language.dart` is a straightforward extension.

### Gaps

- No `lib/features/settings/domain/usecases/` directory exists.
- No `test/features/settings/domain/usecases/` directory exists.
- The pre-fill rule has no current single-source-of-truth — it lives in two widget callbacks, each independently re-deriving device language/theme.

## Constitution Constraints

| Rule | Impact on This Idea |
|------|---------------------|
| §2.1 — `usecases/` mandatory; "single-purpose callable classes; one operation per class" | Each of the 4 mutators gets its own callable class (`SetThemeMode`, `SetUseSystemTheme`, `SetUseSystemLanguage`, `SetManualLanguage`) |
| §2.1 — "FORBIDDEN imports in `domain/`: anything from `package:flutter/*`" | Use cases CANNOT call `Localizations.localeOf` or `MediaQuery.platformBrightnessOf`. Pre-fill rule must accept the resolved value (`String deviceLanguageCode` / `AppThemeMode currentDeviceMode`) as a parameter |
| §4.1.1 — "Screens never call repositories directly" | Notifier must route through the use cases — repository calls leave the presentation file entirely |
| §3.6 — DRY threshold | Pre-fill rule moves into one use case; `firstWhere(orElse: en)` triplicate absorbed by `AppLanguage.fromLanguageCodeOrDefault` |
| §4.1 — "Every use case returns `Future<Either<Failure, T>>`" | Already satisfied by the repository's existing return shape |
| §3.1 — "No `!` null assertion without certainty" | The pre-fill use case takes a non-nullable resolved argument from the widget — caller resolves the `Brightness`/`languageCode` and passes it in. Zero `!` introduced |

## Approaches

### Option A: Four use cases + parameter-passed device context (recommended)

- **Description**: Create `SetThemeMode`, `SetUseSystemTheme(bool value, {AppThemeMode? deviceMode})`, `SetUseSystemLanguage(bool value, {String? deviceLanguageCode})`, `SetManualLanguage`. The pre-fill rule lives in the two `SetUseSystem*` use cases — when `value=false` and the resolved device argument is provided, persist the matching manual value first. Widgets resolve the Flutter-specific value (`MediaQuery.platformBrightnessOf` / `Localizations.localeOf`) and pass it in as a plain Dart type.
- **Pros**:
  - Pre-fill rule has a single home; one unit test asserts the invariant.
  - `domain/` stays Flutter-free (constitution §2.1).
  - Notifier shrinks from 70 lines of repeated `ref.read(repo).save…().fold(_errors.add, ...)` to one delegation per mutator.
  - Test pyramid lands cleanly: 4 use case tests + 1 pre-fill rule test in pure Dart, no widget harness needed.
- **Cons**:
  - Two of the use cases (`SetUseSystem*`) take optional device parameters — slight asymmetry vs. the simpler two.
- **Complexity**: Low

### Option B: Five use cases (split pre-fill into its own callable)

- **Description**: Introduce a separate `PrefillManualFromDevice` use case alongside the four repository-mirroring ones. `SetUseSystemTheme(value=false)` first calls `PrefillManualFromDevice`, then persists.
- **Pros**: Strictest adherence to "one operation per class".
- **Cons**: Constitution §2.1 means "one user-facing operation" — the pre-fill is part of the toggle, not a standalone user op. Splitting creates two-step orchestration the notifier or another use case must coordinate, leaking the rule back out. Net worse than A.
- **Complexity**: Low-Medium (extra orchestration)

### Option C: Bundle with bug 011 (DRY in selectors / cycle)

- **Description**: Same as A, plus extract a `CycleThemeMode` use case for `theme_preview_screen.dart` and route data-layer's `getManualLanguage` through `AppLanguage.fromLanguageCodeOrDefault`.
- **Pros**: Closes bug 011 in the same PR; one round of repo-consumer changes.
- **Cons**: Bug 011 is Warning-severity and lives partly in dev-only code (theme_preview is on the removal list per spec 002). Bundling adds ~2 files of scope without changing the architectural payoff.
- **Complexity**: Low-Medium

**Recommended approach**: Option A — minimal, high-leverage, matches the bug's Fix Notes verbatim. Bug 011 stays a separate Warning-severity follow-up.

## Complexity Assessment

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Codebase changes | Low-Medium | 4 new use case files (~20 lines each), 1 enum helper, notifier rewrite (~70 lines net delete), 2 widget callback simplifications. Plus 4-5 test files. ~10 files touched |
| New dependencies | None | All scaffolding (Riverpod codegen, fpdart, freezed, error stream) already in place |
| Risk | Low | No persisted-format changes, no public API changes the UI sees, existing tests pin invariants. Notifier mutator return types unchanged (`Future<void>`) |

## Recommendation

**Proceed.** Suggested next-step prompt:

```
/specify "Introduce domain/usecases/ for the Settings feature: SetThemeMode, SetUseSystemTheme (with device-mode pre-fill), SetUseSystemLanguage (with device-language-code pre-fill), SetManualLanguage. Move the pre-fill rule out of language_selector.dart and theme_selector.dart into the use cases. Add AppLanguage.fromLanguageCodeOrDefault to absorb the triplicated firstWhere-orElse pattern. Notifier routes all mutators through use case providers. Closes bug 005. See research/2026-05-09-bug-005-settings-usecases.md for full context."
```

`/specify` will sharpen Options A vs C (whether to bundle bug 011's cycle logic) and ratify the device-parameter shape — those are the only two judgment calls left.
