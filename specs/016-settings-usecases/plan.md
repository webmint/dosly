# Plan: Settings feature — introduce `domain/usecases/`

**Date**: 2026-05-09
**Spec**: [spec.md](spec.md)
**Status**: Draft

## Summary

Introduce five callable use case classes under `lib/features/settings/domain/usecases/` constructed with a single `SettingsRepository` dependency, expose each via a `@riverpod` provider, rewire the `SettingsNotifier` mutators to delegate exclusively through these providers, and pull the "switch-to-manual pre-fill" rule into the `SetUseSystem*` use cases as an atomic two-write sequence. As part of the same pass, add `AppLanguage.fromLanguageCodeOrDefault` and replace all three `firstWhere(orElse: en)` literals with it; route the `theme_preview` cycle through `CycleThemeMode` whose `Right` carries the resulting `({bool useSystemTheme, AppThemeMode manualThemeMode})` Dart record so the notifier can apply the cycled state without re-deriving the rule. Closes bug 005 + bug 011.

## Technical Context

**Architecture**: Clean Architecture — adds the `usecases/` layer to the Settings feature for the first time. Domain remains pure Dart (zero `package:flutter/*` imports). Presentation reaches `data/` exclusively through use case providers wired in `settings_provider.dart`.
**Error Handling**: `Either<Failure, T>` from `fpdart` — preserved end-to-end. Atomic use cases short-circuit on the first inner `Left`. Notifier `fold`s into `_errors.add(...)` on `Left`, applies `state.copyWith(...)` on `Right` — semantics unchanged from the post-spec-014 state.
**State Management**: Riverpod 2 with `riverpod_generator` codegen (the project standard since spec 015). All five new use case providers are class-form `@riverpod` function providers; the existing `settingsNotifierProvider` (kept-alive via `@Riverpod(keepAlive: true, name: 'settingsNotifierProvider')`) keeps its current shape.

## Constitution Compliance

| Rule | Status |
|------|--------|
| §2.1 — `usecases/` directory mandatory; one operation per class | Compliant — five callable classes, one file each |
| §2.1 — `domain/` forbidden imports (`package:flutter/*`, `package:flutter_riverpod/*`, `package:drift/*`) | Compliant — use cases import only `package:fpdart/fpdart.dart`, the entity files, and the repository contract |
| §2.2 — One public type per file | Compliant — five files for five use cases; the `({...})` record returned by `CycleThemeMode` is anonymous (no new public type) |
| §3.6 — DRY threshold (3+ duplicates) | Compliant — `firstWhere(orElse: en)` collapses from 3 sites to 1 (inside the helper) |
| §4.1 — Every use case returns `Future<Either<Failure, T>>` | Compliant — 4 use cases return `Future<Either<Failure, void>>`; `CycleThemeMode` returns `Future<Either<Failure, ({bool useSystemTheme, AppThemeMode manualThemeMode})>>` (T is the resulting state record). Note: this refines spec §3.1 item 5 from `void` to the record — see "Key Design Decisions" |
| §4.1.1 — Screens never call repositories directly | Compliant — `theme_preview_screen.dart` calls the cycle use case provider; selectors call notifier mutators; no widget reads `settingsRepositoryProvider` |
| §6.2 — Each use case has happy path + repository failure tests | Compliant — five new test files, each with at least 2 cases |
| §3.1 — No `!` null assertion | Compliant — required parameters mean no nullable device value to coerce |
| MEMORY.md "Riverpod codegen strips Notifier suffix" | N/A — five new providers are function-form (`SetThemeMode setThemeMode(Ref ref) => ...`), not class-form. Suffix-stripping rule doesn't apply. The existing `settingsNotifierProvider` keeps its `name:` annotation as-is |

## Implementation Approach

### Layer Map

| Layer | What | Files |
|-------|------|-------|
| Domain — entities | Add `fromLanguageCodeOrDefault` static factory | `lib/features/settings/domain/entities/app_language.dart` (modify) |
| Domain — usecases | Five callable classes, each `const`-constructible from a `SettingsRepository` | `lib/features/settings/domain/usecases/{set_theme_mode,set_use_system_theme,set_use_system_language,set_manual_language,cycle_theme_mode}.dart` (create) |
| Data — datasources | Replace `AppLanguage.values.firstWhere` with `AppLanguage.fromLanguageCodeOrDefault` in `getManualLanguage` | `lib/features/settings/data/datasources/settings_local_data_source.dart` (modify) |
| Presentation — providers | Add 5 `@riverpod` use case providers; rewrite 4 notifier mutators to delegate through them; add `cycleThemeMode()` notifier method | `lib/features/settings/presentation/providers/settings_provider.dart` (modify) + regenerate `settings_provider.g.dart` |
| Presentation — widgets | Toggle callbacks shrink to one notifier call each; resolve device value (`Brightness`/`Locale`) via the helper | `lib/features/settings/presentation/widgets/theme_selector.dart`, `lib/features/settings/presentation/widgets/language_selector.dart` (modify) |
| Presentation — screens | Cycle `IconButton.onPressed` becomes one notifier call to `cycleThemeMode()` | `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` (modify) |
| Tests — domain (new) | Five use case test files, each with happy path + repository failure | `test/features/settings/domain/usecases/{set_theme_mode,set_use_system_theme,set_use_system_language,set_manual_language,cycle_theme_mode}_test.dart` (create) |
| Tests — domain (existing) | Add `fromLanguageCodeOrDefault` cases | `test/features/settings/domain/entities/app_language_test.dart` (modify; create if missing) |
| Tests — presentation | Adapt notifier-test fakes to wire new providers; widget tests survive unchanged on the test fake-repo path (writes still hit repo) | `test/features/settings/presentation/providers/settings_provider_test.dart` (modify), `test/features/settings/presentation/widgets/{theme_selector,language_selector}_test.dart` (minimal adaptation) |
| Docs | Update Presentation / ThemeSelector / LanguageSelector sections | `docs/features/settings.md` (modify) |
| Bugs | Status: Open → Closed; Fixed: 2026-05-09 | `bugs/005-settings-feature-missing-usecases.md`, `bugs/011-business-rule-duplicated-selectors.md` (modify) |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| Use case wiring | Each use case is `class FooUseCase { const FooUseCase(this._repo); final SettingsRepository _repo; Future<Either<Failure, T>> call(...) async {...} }` exposed via `@riverpod FooUseCase fooUseCase(Ref ref) => FooUseCase(ref.watch(settingsRepositoryProvider));` | Mirrors constitution §7's `AddMedication` example; matches every existing-codebase use of `@riverpod` since spec 015 | Function-only use cases (`Future<Either<Failure, T>> setThemeMode(SettingsRepository repo, ...)`) — rejected because constitution §2.1 prescribes "callable classes" |
| Atomic pre-fill ordering inside `SetUseSystem*` | When `value=false`: `await repo.saveX(currentDeviceY)`; if `Left`, return immediately; otherwise `await repo.saveUseSystemX(false)` and return its result. When `value=true`: only `repo.saveUseSystemX(true)` — `currentDeviceY` is ignored | Pre-fill must land BEFORE the toggle flips so an interrupted/failed write never leaves `useSystemX=false` with a stale `manualX`. Verified in unit test via `verifyInOrder` (AC-4 / AC-6) | Reverse order (toggle first, then pre-fill) — rejected because a toggle-success-followed-by-pre-fill-failure leaves a half-applied state. Parallel writes — rejected because the repository contract is sequential and there's no parallelism advantage |
| `currentDeviceY` parameter contract | `required` non-nullable in both `SetUseSystem*` use cases and the matching notifier mutators. Caller always resolves and passes the device value, even when `value=true` (where it's ignored) | Symmetric API; no `!` coercion; the use case decides internally whether to consume the value. Caller-side cost is one inline expression already computed for display purposes | Optional with `value=false` precondition — rejected because it pushes "did I forget to pass it?" runtime risk into a domain layer that should be ironclad. Always-pre-fill-even-when-value=true — rejected because it would write to `manualX` when the user toggled ON, which is semantically wrong (manual override unchanged when system mode resumes) |
| `CycleThemeMode` return type | `Future<Either<Failure, ({bool useSystemTheme, AppThemeMode manualThemeMode})>>` (Dart record). Right value is the post-cycle state shape | The notifier needs the next state to apply `state.copyWith(...)` without re-deriving the cycle rule. Returning the record keeps the rule in one place (the use case body) — duplicating it in the notifier would re-introduce bug 011 in a new location. Refines spec §3.1 item 5's `void` and AC-7's wording — see "Plan-Spec Cross-Reference Check" | Returning `void` and re-loading state from repo in notifier — rejected because that requires `ref.read(settingsRepositoryProvider)` in the notifier, which AC-8 forbids. Returning a freezed `AppThemeCycleStep` class — rejected as overkill for a 2-field anonymous tuple |
| `CycleThemeMode` write path | The use case writes through the `SettingsRepository` directly (one or two `saveX` calls depending on the branch), then returns `Right((useSystemTheme: next.0, manualThemeMode: next.1))` | Keeps the cycle's branching rule entirely inside the use case. Notifier just `fold`s and `copyWith`s | Use case dispatches through the other use cases (e.g., calls `SetUseSystemTheme`) — rejected as needless indirection within the same domain |
| Notifier exposes `cycleThemeMode()` (new method) | New public method on `SettingsNotifier` invokes `cycleThemeModeProvider`, folds the Either, and applies `state.copyWith(useSystemTheme: ..., manualThemeMode: ...)` on Right | Matches the existing pattern of "every notifier mutator is `Future<void>`, optimistically updates state on success, emits on failure". `theme_preview_screen.dart` calls one notifier method instead of touching the use case provider directly — keeps presentation symmetric | Screen calling `cycleThemeModeProvider` directly — rejected because the screen would also have to apply state via `notifier.state = ...` (private setter), violating encapsulation |
| Notifier signature for `setUseSystemTheme` / `setUseSystemLanguage` | Add a `required` named parameter: `setUseSystemTheme(bool value, {required AppThemeMode currentDeviceMode})` and `setUseSystemLanguage(bool value, {required AppLanguage currentDeviceLanguage})` | Mirrors the use case shape; only two consumer call sites (the two selector widgets), both rewritten in this spec; `dart analyze` will flag any missed call | Keep positional `(bool)` and have the notifier resolve device value internally — rejected because the notifier lives in `presentation/` but cannot import Flutter without breaking layer boundaries (notifier file imports `flutter_riverpod` already, but resolving device values from `MediaQuery`/`Localizations` requires a `BuildContext`, which the notifier doesn't have) |
| `AppLanguage.fromLanguageCodeOrDefault` placement | Static factory on the existing `AppLanguage` enum, in `app_language.dart` | Mirrors `AppThemeMode.fromCodeOrDefault` exactly; the enum is the only logical home; collocates the rule with the data it operates on | Free function in a `core/utils/` helper file — rejected as cross-feature creep for a domain-specific concern |
| Test strategy for use cases | `mocktail`-based `MockSettingsRepository`, one `verifyInOrder` per atomic use case, `when(...).thenAnswer((_) async => const Left(CacheFailure('mock')))` for failure paths | Project standard since constitution §6; matches the existing `settings_repository_impl_test.dart` style | Hand-rolled fakes — rejected because `verifyInOrder` is exactly what AC-4 / AC-6 require and `mocktail` is already a project dep |
| Existing widget-test adaptation | Widget tests use the project's `_FakeSettingsRepository` (asserts on `repo.savedX`). After the spec, the use case still writes through the SAME repository, so existing assertions hold. Only the notifier-mutator-call expectation changes shape (one call instead of two) | Minimum churn to existing tests; preserves test intent | Rewrite widget tests against use case mocks — rejected as gratuitous churn; widget tests are end-to-end-ish by design |

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `lib/features/settings/domain/usecases/set_theme_mode.dart` | Create | `class SetThemeMode { const SetThemeMode(this._repo); final SettingsRepository _repo; Future<Either<Failure, void>> call(AppThemeMode mode) => _repo.saveThemeMode(mode); }` |
| `lib/features/settings/domain/usecases/set_use_system_theme.dart` | Create | Atomic 2-write use case with `verifyInOrder`-friendly sequence. ~25 lines |
| `lib/features/settings/domain/usecases/set_use_system_language.dart` | Create | Symmetric to `set_use_system_theme.dart`. ~25 lines |
| `lib/features/settings/domain/usecases/set_manual_language.dart` | Create | Thin pass-through: `_repo.saveManualLanguage(lang)`. ~15 lines |
| `lib/features/settings/domain/usecases/cycle_theme_mode.dart` | Create | Branches on `(currentUseSystemTheme, currentManualMode)`, writes through repo, returns the next-state record. ~40 lines |
| `lib/features/settings/domain/entities/app_language.dart` | Modify | Add `static AppLanguage fromLanguageCodeOrDefault(String code)` |
| `lib/features/settings/data/datasources/settings_local_data_source.dart` | Modify | `getManualLanguage()`: replace 4-line `firstWhere(orElse: en)` with `return AppLanguage.fromLanguageCodeOrDefault(code);` |
| `lib/features/settings/presentation/providers/settings_provider.dart` | Modify | Add 5 use case `@riverpod` function providers. Rewrite 4 mutators to delegate to use case providers (no `ref.read(settingsRepositoryProvider)`). Add `Future<void> cycleThemeMode()` method. `setUseSystemTheme` and `setUseSystemLanguage` gain `{required ...}` named params |
| `lib/features/settings/presentation/providers/settings_provider.g.dart` | Regenerate | `dart run build_runner build --delete-conflicting-outputs` |
| `lib/features/settings/presentation/widgets/theme_selector.dart` | Modify | `onChanged` callback: derive `deviceMode` from `MediaQuery.platformBrightnessOf`, then `notifier.setUseSystemTheme(value, currentDeviceMode: deviceMode)`. Remove the `if (!value) { ... setThemeMode ... }` block |
| `lib/features/settings/presentation/widgets/language_selector.dart` | Modify | Both `firstWhere` literals (lines 42, 65) replaced by `AppLanguage.fromLanguageCodeOrDefault(...)`. `onChanged` callback simplifies to `notifier.setUseSystemLanguage(value, currentDeviceLanguage: deviceLanguage)`. Remove the `if (!value) { ... setManualLanguage ... }` block |
| `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` | Modify | Replace the 14-line cycle `if/else if/else` with `ref.read(settingsNotifierProvider.notifier).cycleThemeMode()` |
| `test/features/settings/domain/usecases/set_theme_mode_test.dart` | Create | Happy path + 1 repo failure |
| `test/features/settings/domain/usecases/set_use_system_theme_test.dart` | Create | `value=false` happy path with `verifyInOrder([saveThemeMode, saveUseSystemTheme])` + `value=true` happy path verifying `saveThemeMode` is NOT called + 1 failure (first write fails, second never called) |
| `test/features/settings/domain/usecases/set_use_system_language_test.dart` | Create | Symmetric to `set_use_system_theme_test.dart` |
| `test/features/settings/domain/usecases/set_manual_language_test.dart` | Create | Happy path + 1 repo failure |
| `test/features/settings/domain/usecases/cycle_theme_mode_test.dart` | Create | All 3 transitions verified + 1 repo failure |
| `test/features/settings/domain/entities/app_language_test.dart` | Modify (or create) | Add cases: `'en'` / `'de'` / `'uk'` / `'xx'` / `''` → expected `AppLanguage` |
| `test/features/settings/presentation/providers/settings_provider_test.dart` | Modify | `_FakeSettingsRepository` stays as-is. Update calls: `setUseSystemTheme(false)` → `setUseSystemTheme(false, currentDeviceMode: AppThemeMode.light)`. Add a `cycleThemeMode()` test covering at least one transition + failure forwarding |
| `test/features/settings/presentation/widgets/theme_selector_test.dart` | Modify | Update any expectations that asserted on TWO sequential repo writes (manual then toggle) — they now coalesce. Existing `repo.savedManualThemeMode` / `repo.savedUseSystemTheme` assertions still hold |
| `test/features/settings/presentation/widgets/language_selector_test.dart` | Modify | Same as above for the language flow |
| `docs/features/settings.md` | Modify | Update "Presentation" subsection (notifier delegates to use cases); update "ThemeSelector" / "LanguageSelector" subsections (pre-fill rule moved out, callback shrinks); add a "Use cases" subsection enumerating the five with one-liners |
| `bugs/005-settings-feature-missing-usecases.md` | Modify | `Status: Open` → `Status: Closed`; `Fixed: 2026-05-09` |
| `bugs/011-business-rule-duplicated-selectors.md` | Modify | `Status: Open` → `Status: Closed`; `Fixed: 2026-05-09` |

### Documentation Impact

| Doc File | Action | What Changes |
|----------|--------|-------------|
| `docs/features/settings.md` | Update | Add a "Use cases" subsection; rewrite "Presentation" / "ThemeSelector" / "LanguageSelector" snippets; remove the pre-fill code blocks (now lives in domain); reference the bug closures |
| `docs/architecture.md` | No change | The Clean Architecture section already describes use cases; no new pattern is introduced |

## Plan-Spec Cross-Reference Check

| AC | Implementation Path |
|----|---------------------|
| AC-1 | Five files created under `lib/features/settings/domain/usecases/` per File Impact |
| AC-2 | Use cases import `package:fpdart/fpdart.dart`, the entity files, the repository contract — no Flutter, no Riverpod. Verified by grep in code-reviewer phase |
| AC-3 | All 5 classes are `class FooUseCase { const FooUseCase(this._repo); final SettingsRepository _repo; Future<Either<...>> call(...) }` |
| AC-4 | `SetUseSystemTheme` body: `if (!value) { final r = await _repo.saveThemeMode(currentDeviceMode); if (r.isLeft()) return r; } return _repo.saveUseSystemTheme(value);` — verified by `verifyInOrder` test |
| AC-5 | Same body — when `value=true`, the `if (!value)` guard skips the first call. Verified by `verifyNever(_repo.saveThemeMode)` |
| AC-6 | `SetUseSystemLanguage` body symmetric to AC-4 / AC-5 with `saveManualLanguage` / `saveUseSystemLanguage` |
| AC-7 | `CycleThemeMode` body: `if (currentUseSystemTheme) { await _repo.saveThemeMode(AppThemeMode.light); await _repo.saveUseSystemTheme(false); return Right((useSystemTheme: false, manualThemeMode: AppThemeMode.light)); } else if (currentManualMode == AppThemeMode.light) { await _repo.saveThemeMode(AppThemeMode.dark); return Right((useSystemTheme: false, manualThemeMode: AppThemeMode.dark)); } else { await _repo.saveUseSystemTheme(true); return Right((useSystemTheme: true, manualThemeMode: currentManualMode)); }` — three transitions, three test cases. **Note**: spec §3.1 item 5 and AC-7 wording referenced `Future<Either<Failure, void>>`; this plan refines the return type to the resulting state record. AC-7's three-transition verification is unaffected; the unit test asserts both the repo write sequence AND the returned record. |
| AC-8 | Notifier file: 1 `settingsRepositoryProvider` declaration site (the existing `@riverpod SettingsRepository settingsRepository(Ref ref) {...}`) and 0 `ref.read(settingsRepositoryProvider)` call sites in the rewritten mutators. Verified by grep |
| AC-9 | `theme_selector.dart` `onChanged` becomes 4 lines: derive `deviceMode`, single notifier call. No `firstWhere`/`Brightness == dark ? ...` literal in the callback body |
| AC-10 | `language_selector.dart` `onChanged` becomes 4 lines using `AppLanguage.fromLanguageCodeOrDefault`. No `firstWhere(orElse: en)` literal in the callback |
| AC-11 | `theme_preview_screen.dart` `onPressed` becomes one notifier call. No `if/else if/else` on `useSystemTheme`/`manualThemeMode` |
| AC-12 | Helper added to `app_language.dart`. Tested with `'en'`/`'de'`/`'uk'`/`'xx'`/`''` |
| AC-13 | Verified by `grep -rnE "AppLanguage\\.values\\.firstWhere" lib/` returning exactly one match — inside the helper |
| AC-14 | Post-edit `dart analyze` is the integration gate |
| AC-15 | All adapted + new tests run via `flutter test` |
| AC-16 | `flutter build apk --debug` runs in the integration gate |
| AC-17 | Widget tests verify pre-fill behaviour end-to-end via the fake repo's `savedX` flags. The use case writes through the same repo, so the assertions hold byte-for-byte |
| AC-18 | Notifier `fold(_errors.add, ...)` pattern preserved verbatim. `settingsErrorsProvider` and `SettingsScreen` SnackBar untouched |
| AC-19 | Bug front-matter flips done in the docs/bookkeeping task |
| AC-20 | `docs/features/settings.md` rewrite covers the use case layer + helper + simplified callbacks |

**Reverse check** (plan files NOT in spec's Affected Areas): The plan introduces no files beyond what the spec lists. The regenerated `settings_provider.g.dart` is implicit (codegen by-product, not in §4 because all `*.g.dart` are auto-derived from `*.dart` siblings).

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `CycleThemeMode` return-type refinement (record vs `void`) is a spec deviation | Low | Low | Documented above + here. AC-7's behavioural contract is preserved (the three transitions still happen and are still tested); only the use case's Right value shape is richer. `/breakdown` notes the deviation in the cycle task; `/verify` flags it as an accepted Implementation Deviation per MEMORY.md's spec-010 precedent |
| `verifyInOrder` test on atomic use case is brittle if the use case's internal write order is reversed by mistake | Low | Medium | The test is the safeguard — it will fail loudly if any future maintainer flips the order. Failure message will name both calls |
| Notifier `cycleThemeMode()` method silently de-syncs in-memory state from persisted state if the use case returns `Right` but the notifier's `copyWith` arguments don't match the use case's writes | Medium | Medium | The use case body contains BOTH the writes and the returned record — they're computed from the same branch. A unit test on the use case asserts both the sequence of writes AND the returned tuple per branch (AC-7 expansion) |
| `setUseSystemTheme(false, currentDeviceMode: ...)` could be called with a stale `currentDeviceMode` if the widget recomputes after a `MediaQuery` change between `build` and `onChanged` | Very Low | Low | The widget reads `systemBrightness` inside `build`, captures it via the closure, and the callback fires synchronously on tap — no opportunity for `MediaQuery` change between resolution and call. Same pattern as the existing pre-fill code (which also captures `systemBrightness` in `build`) |
| Existing widget tests fail because the `setUseSystemX` notifier signature gained a required named parameter | High (expected) | Low | Tests are adapted in the same task as the production change; the notifier-test fake repo doesn't care about the parameter, only about the resulting `repo.saveX` calls |
| `theme_preview` cycle use case is added to a screen scheduled for removal | Medium | Low | The use case is reusable for any future "advanced" theme cycle UI (rare but possible); when `theme_preview_screen.dart` is removed, the use case can be removed alongside it. Net cost: one extra file deletion at removal time, accepted per spec's risk table |
| Code-reviewer flags `name:` parameter on `@riverpod` use case providers as redundant | Low | Low | MEMORY.md's spec 015 lesson: the `name:` annotation is load-bearing for class-form providers. **Function-form providers (which all 5 new use case providers are) do NOT need it** — codegen derives `setThemeModeProvider` from `setThemeMode` directly. No `name:` parameter on the new providers; only the existing `settingsNotifierProvider` keeps it |

## Dependencies

None. All scaffolding (Riverpod codegen, `riverpod_generator`, `mocktail`, `fpdart`, `freezed`) is already in place.

## Supporting Documents

- [Spec](spec.md) — feature contract
- Research: [`research/2026-05-09-bug-005-settings-usecases.md`](../../research/2026-05-09-bug-005-settings-usecases.md) — pre-spec feasibility study (no spec-level research.md was needed since signals were absent)
