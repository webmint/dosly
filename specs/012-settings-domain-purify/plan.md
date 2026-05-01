# Plan: Settings Domain Purify

**Date**: 2026-04-30
**Spec**: [spec.md](spec.md) (Approved 2026-04-30)
**Status**: Approved
**Approved**: 2026-04-30 (implicit — user invoked /breakdown immediately after plan presentation)

## Summary

Introduce a domain-owned `AppThemeMode` enum, convert `AppSettings` to `@freezed`, switch theme persistence from `int` to `String`, and confine all `Flutter SDK ↔ domain` type mapping to a single seam in `lib/app.dart`. The work spans 9 source files (8 modified + 1 created), 1 generated file (committed), 7 test files, 1 doc file, and pubspec — all enumerated by the spec. This is the first `*.freezed.dart` in the codebase, so a one-shot codegen-pipeline-bring-up is part of the work.

## Technical Context

**Architecture**: Three-layer Clean Architecture (`domain` / `data` / `presentation`) per constitution §2.1. This plan touches all three layers but the domain layer is the originating concern — every other change is a downstream consequence of removing Flutter from `lib/features/settings/domain/`.

**Error Handling**: `Either<Failure, T>` (fpdart) at every repository boundary — unchanged by this plan. The existing `try/catch (e) → Left(CacheFailure(e.toString()))` pattern stays as-is in `settings_repository_impl.dart`. (Bug 010 — replacing this with `catch (e, st)` and `Failure.unknown(e, st)` — is out of scope.)

**State Management**: Riverpod 2.x via `flutter_riverpod`. The presentation seam in `lib/app.dart` switches from one wide `.select((s) => s.effectiveThemeMode)` call to four narrow `.select(...)` calls (one per raw entity field). This is finer-grained, not coarser; it does not regress §4.1.1 reactivity.

**Codegen**: First adoption of `build_runner` in this codebase. Generated files (`*.freezed.dart`) are committed per constitution §2.2.

## Constitution Compliance

| Rule | Status | Notes |
|------|--------|-------|
| §2.1 — `domain/` no `package:flutter/*` | **This plan establishes compliance** (resolves the existing violation) | Verified by AC-1 |
| §2.1 — `data/` may import Flutter only when needed | **Improved** — `data/` no longer needs Flutter | Verified by AC-2 |
| §2.1 — feature A doesn't import feature B | Compliant; not touched by this plan | bug 009 (theme_preview cross-feature import) is out of scope |
| §2.2 — `*.freezed.dart` committed | Compliant | New `app_settings.freezed.dart` is committed |
| §3.1 — entities use `freezed` | **This plan establishes compliance** for `AppSettings` | Verified by AC-4 |
| §3.1 — no `dynamic`, no `!`, no unchecked `as` | Compliant; no new instances introduced | The seam in `lib/app.dart` uses pattern-matching `switch` for `AppThemeMode` (exhaustive over 2 values) |
| §3.2 — `Either<Failure, T>` at repo boundary | Unchanged | All 4 `saveX` methods retain their `Future<Either<Failure, void>>` return |
| §3.3 — naming: `App<Concept>` prefix, `snake_case.dart` filenames | Compliant | `AppThemeMode` in `app_theme_mode.dart` follows the `AppLanguage`/`AppSettings`/`app_language.dart` precedent |
| §3.4 — every fallible op tested | Compliant; existing tests are preserved and updated | A new pure-Dart `app_settings_test.dart` is added (AC-16) |
| §3.6 — DRY (3+ uses) | Acceptable | The `AppLanguage.fromLanguageCodeOrDefault`-style helper proposed by bug 011 is NOT added in this spec (out of scope §6) — `AppThemeMode.fromCodeOrDefault` is added because the data source needs it |
| §4.1.1 — `@riverpod` codegen | Out of scope (bug 004) | Hand-rolled `Provider`/`NotifierProvider` declarations stay; only their parameter types change |
| §4.2 — never swallow errors | Out of scope (bug 003) | The four `kDebugMode`-guarded `debugPrint` sites stay; restructuring to `AsyncNotifier` is its own spec |
| §4.2.1 — `Clock` injection, no `print`/`debugPrint` | Out of scope (bug 002) | The four `debugPrint` sites stay (carried forward as known recurring violation) |
| §6.1 — minimal changes | Compliant **per file** (each file change is the smallest needed); spec-wide diff is necessarily large because the violation has 19-file blast radius | Documented in spec §4 |
| §7.3 — initial dependencies | This plan adds the missing `freezed`/`build_runner` per the constitution's `flutter pub add` command | Verified by AC-11 |
| §7.4 — analyzer excludes `*.freezed.dart` | Already compliant | `analysis_options.yaml` already excludes the pattern; no change needed |

## Implementation Approach

### Layer Map

| Layer | What | Files |
|-------|------|-------|
| Domain (entities) | New 2-value enum + freezed entity rewrite | `lib/features/settings/domain/entities/app_theme_mode.dart` (new), `app_settings.dart` (rewrite), `app_settings.freezed.dart` (generated, committed) |
| Domain (contracts) | Pure-Dart repository contract | `lib/features/settings/domain/repositories/settings_repository.dart` (drop Flutter import; `saveThemeMode(AppThemeMode)`) |
| Data (data source) | String-keyed theme persistence; remove Flutter import | `lib/features/settings/data/datasources/settings_local_data_source.dart` (`getString`/`setString` for `themeMode`; signature uses `AppThemeMode`) |
| Data (repo impl) | Signature update only | `lib/features/settings/data/repositories/settings_repository_impl.dart` (`saveThemeMode(AppThemeMode)`; `load()` constructs `AppSettings` with the new enum field) |
| Presentation (provider) | Signature update only | `lib/features/settings/presentation/providers/settings_provider.dart` (`setThemeMode(AppThemeMode)`; `state.copyWith(manualThemeMode: AppThemeMode...)`) |
| Presentation (widgets) | Signature update only | `lib/features/settings/presentation/widgets/theme_selector.dart` (`SegmentedButton<AppThemeMode>`; pre-fill helper) |
| Presentation (theme preview) | Signature update + cycle logic re-anchored on `AppThemeMode` | `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` |
| Presentation (seam) | The single `Flutter SDK ↔ domain` mapping point | `lib/app.dart` (four `.select()` calls; inline `themeMode` and `locale` computation) |
| Tooling | Codegen pipeline bring-up | `pubspec.yaml` (add `freezed_annotation`, `freezed`, `build_runner`) |
| Tests | Fixture seed + expectation updates across 7 files | `test/features/settings/data/repositories/settings_repository_impl_test.dart`, `test/features/settings/presentation/providers/settings_provider_test.dart`, `test/features/settings/presentation/screens/settings_screen_test.dart`, `test/features/settings/presentation/widgets/theme_selector_test.dart`, `test/features/settings/presentation/widgets/language_selector_test.dart`, `test/widget_test.dart`, `test/core/routing/app_router_test.dart` |
| Tests (new) | Pure-Dart domain test for `AppSettings` + `AppThemeMode` | `test/features/settings/domain/entities/app_settings_test.dart` (new) |
| Docs | Domain section update | `docs/features/settings.md` |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|-----------------|-----|-----------------------|
| `AppThemeMode` cardinality | 2-value `{ light, dark }` | Matches existing `manualThemeMode` field semantics; impossible to persist invalid `system` value | 3-value (re-introduces contract gap); single field collapsing `useSystemTheme` (breaks schema + UI shape) |
| Persistence format | Stable `String` codes | Matches `docs/features/settings.md:158` documented contract; order-independent | Status quo `int.index` (the bug) |
| Legacy `int` migration | Auto-fallback to `AppThemeMode.light` via `getString → null → fromCodeOrDefault` | Zero migration code; relies on platform-level type strictness; documented in spec §3.6 + AC-8 | Read-both-formats (over-engineered for 1-user app); schema version key (overkill) |
| `effectiveThemeMode`/`effectiveLocale` getters | Removed entirely | "Effective" is a presentation concern; the seam in `lib/app.dart` has direct field access via `.select()` | Retype to domain types (still leaks presentation semantics into domain); status quo (Flutter in domain) |
| Codegen tool | `freezed` + `build_runner` | Constitution §3.1; already-prescribed tool in §7.3 | `equatable` (smaller dep but divergent from constitution); hand-rolled (the bug we're fixing) |
| `freezed` JSON support | NOT added | `AppSettings` is persisted field-by-field via separate SharedPreferences keys — no JSON blob | Adding `json_annotation`+`json_serializable` (no consumer for it) |
| `freezed` class shape | `@freezed class AppSettings with _$AppSettings { const factory AppSettings({...}) = _AppSettings; }` | Single factory → plain class (not `sealed`); per Context7 canonical example | `sealed class with _$AppSettings` (only needed for unions like the future `Failure` rewrite) |
| Provider rebuild granularity | 4 narrow `.select()` calls in `lib/app.dart` (one per field) | Finer-grained than the previous single `effectiveThemeMode` selector — `useSystemTheme` toggle without changing `manualThemeMode` no longer triggers `themeMode` rebuild propagation through the same selector | One wide `.select((s) => s)` (would regress §4.1.1) |
| Switch statement style | `switch` expression with exhaustive arms over `AppThemeMode` | Constitution §3.1 mandates exhaustive switches over enums and sealed types; Dart 3 `switch` expressions are the canonical form | `if/else` chain (non-exhaustive at compile time) |

### File Impact

Action: **C** = Create, **M** = Modify, **G** = Generated (committed)

| File | Action | What Changes |
|------|--------|-------------|
| `pubspec.yaml` | M | Add `freezed_annotation` (runtime), `freezed` + `build_runner` (dev) via `flutter pub add freezed_annotation dev:freezed dev:build_runner` |
| `lib/features/settings/domain/entities/app_theme_mode.dart` | C | New 2-value enum with `code` field and `fromCodeOrDefault` static helper; pure Dart |
| `lib/features/settings/domain/entities/app_settings.dart` | M | Rewrite as `@freezed` class; remove Flutter import; `manualThemeMode: AppThemeMode`; remove `effectiveThemeMode` and `effectiveLocale` getters |
| `lib/features/settings/domain/entities/app_settings.freezed.dart` | G | Generated by `dart run build_runner build`; committed to repo per §2.2 |
| `lib/features/settings/domain/repositories/settings_repository.dart` | M | Remove Flutter import; `saveThemeMode(AppThemeMode mode)`; rewrite `saveUseSystemLanguage` dartdoc to drop `MaterialApp.localeResolutionCallback` reference (describe in domain terms) |
| `lib/features/settings/data/datasources/settings_local_data_source.dart` | M | Drop `import 'package:flutter/material.dart';`; `getThemeMode()` returns `AppThemeMode` via `_prefs.getString` + `AppThemeMode.fromCodeOrDefault`; `setThemeMode(AppThemeMode mode)` writes `_prefs.setString(_kThemeModeKey, mode.code)` |
| `lib/features/settings/data/repositories/settings_repository_impl.dart` | M | Drop `import 'package:flutter/material.dart';` (no longer needed once `ThemeMode` is gone); `saveThemeMode(AppThemeMode)` signature; `load()` constructs `AppSettings` with `AppThemeMode` field |
| `lib/features/settings/presentation/providers/settings_provider.dart` | M | `setThemeMode(AppThemeMode mode)` signature; `state.copyWith(manualThemeMode: AppThemeMode...)` mutation. `debugPrint` sites unchanged (out of scope — bug 002) |
| `lib/features/settings/presentation/widgets/theme_selector.dart` | M | `SegmentedButton<AppThemeMode>`; pre-fill helper computes `AppThemeMode` from `Brightness`; mapping back to Flutter `ThemeMode` for the disabled-display case is computed in this widget OR delegated to a small local helper |
| `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` | M | `_iconForEffectiveMode` switches on `(useSystemTheme, manualThemeMode)` returning `IconData`; cycle logic in `onPressed` re-anchored on `AppThemeMode` (no `setThemeMode(ThemeMode.light)` — uses `setThemeMode(AppThemeMode.light)`) |
| `lib/app.dart` | M | Four narrow `.select(...)` calls; remove `effectiveThemeMode`/`effectiveLocale` consumption; inline computation of `MaterialApp.themeMode` and `locale`; `_resolveLocale` callback unchanged |
| `test/features/settings/data/repositories/settings_repository_impl_test.dart` | M | `InMemorySharedPreferencesAsync` fixture seeds switch from `{'themeMode': <int>}` to `{'themeMode': '<code>'}`; assertions use `AppThemeMode`. Adds AC-8 test (legacy `int` value reads as `light`) |
| `test/features/settings/presentation/providers/settings_provider_test.dart` | M | Mock `SettingsRepository.saveThemeMode` calls update from `ThemeMode.x` to `AppThemeMode.x`; expectations on `AppSettings.manualThemeMode` use `AppThemeMode` |
| `test/features/settings/presentation/screens/settings_screen_test.dart` | M | `AppSettings(...)` fixture constructions use `AppThemeMode.dark` etc.; the locally-duplicated `_resolveLocale` (qa-engineer F10) stays as-is in this spec (bug 016 territory) |
| `test/features/settings/presentation/widgets/theme_selector_test.dart` | M | Segments are `AppThemeMode.light`/`AppThemeMode.dark`; pre-fill assertions expect `setManualLanguage`-style notifier calls with `AppThemeMode` |
| `test/features/settings/presentation/widgets/language_selector_test.dart` | M | `AppSettings(...)` fixture constructions updated where `manualThemeMode` is set; widget body untouched |
| `test/widget_test.dart` | M | Cycle test assertions use `AppThemeMode`; the `fakeRepo.lastSavedMode` field changes type from `ThemeMode?` to `AppThemeMode?` |
| `test/core/routing/app_router_test.dart` | M | Compile-only update — no direct `ThemeMode`/`AppSettings` references expected, but if any `AppSettings(...)` construction exists for harness setup, parameter types are updated |
| `test/features/settings/domain/entities/app_settings_test.dart` | C | New pure-Dart test covering `AppThemeMode.fromCodeOrDefault` (5 cases: `'light'`, `'dark'`, `null`, `''`, `'unknown'`) and `AppSettings.copyWith` (all-null preserves originals; each field individually replaced) |
| `docs/features/settings.md` | M | Update Domain section: replace `ThemeMode manualThemeMode` table row with `AppThemeMode manualThemeMode`; update the `effectiveThemeMode`/`effectiveLocale` code samples (lines 25–34) to show the new seam shape in `lib/app.dart` instead. Persistence table at line 158 stays unchanged (`String 'light'`/`'dark'` — already correct; the spec restores the contract the doc already documents) |

**Total**: 19 files affected (8 source modified + 1 source created + 1 generated + 1 pubspec + 6 tests modified + 1 test created + 1 doc).

### Documentation Impact

| Doc File | Action | What Changes |
|----------|--------|-------------|
| `docs/features/settings.md` | M | "Domain" section: `manualThemeMode` row swaps `ThemeMode` → `AppThemeMode`. The `effectiveThemeMode`/`effectiveLocale` code samples (lines 22–36) become out-of-date when this spec lands and must be replaced with a sample of the new seam shape in `lib/app.dart`. Persistence table at lines 156–161 already documents `String` — no change. Add a brief note that `AppThemeMode` lives in domain alongside `AppLanguage` |
| `docs/architecture.md` | M (small) | The pull-quote at line 23 says spec 009 was the first full Clean-Architecture stack; add a brief note that spec 012 made the settings domain truly Flutter-free (the §2.1 invariant the doc itself states is now actually enforced in this feature) |
| `docs/features/theme.md` | (verify only) | Likely unchanged; the theme module under `lib/core/theme/` is not touched. Verified by tech-writer pass |
| `docs/api/*.md` | n/a | This is a local app — no API docs |

The `tech-writer` agent runs in `/finalize` and will catch any further drift.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `freezed` codegen pipeline fails on first run (no prior `*.freezed.dart` exists in repo) | Med | High | The very first task in the breakdown is "establish codegen": pubspec adds, then run `dart run build_runner build --delete-conflicting-outputs` against an unchanged codebase to confirm the pipeline is clean BEFORE any source changes. Fail fast. (Falls under the codegen-task in `/breakdown`.) |
| `with _$AppSettings` mixin fails to resolve because the `.freezed.dart` file isn't generated yet during the `dart analyze` self-repair loop in `/execute-task` | High | Low | `/execute-task`'s post-execution hook needs to run `dart run build_runner build` after any change to a `@freezed`/`@riverpod`-annotated source file. Constitution §6.6 already documents this. The breakdown will sequence "modify `app_settings.dart` → run codegen → run analyze" in the correct order |
| Tests that construct `AppSettings(...)` with positional `ThemeMode` args break invisibly because `freezed`'s factory accepts only named args | Low | Low | The current `AppSettings` constructor already uses named args (lines 21–32), so no test should be relying on positional. Verified during Phase 3 codebase analysis |
| `theme_preview_screen.dart`'s `_iconForEffectiveMode` switch over Flutter's 3-value `ThemeMode` becomes incoherent if it tries to switch over the new 2-value `AppThemeMode` | Med | Low | The fix: `_iconForEffectiveMode` keeps switching over Flutter `ThemeMode` (it's reading Flutter's effective mode for display purposes only — `Theme.of(context).brightness` or the computed `useSystemTheme ? ThemeMode.system : map(manualThemeMode)`). Domain types do not flow into the icon decision. /breakdown will spell this out |
| The `flutter_riverpod ^3.3.1` in pubspec is a recent major version; `freezed`'s codegen interaction with riverpod is currently untested in this codebase | Low | Low | `freezed` and `riverpod` are independent codegens. They share `build_runner` as the runner only. Context7 confirms the install commands don't conflict. If it does fail, the failure surfaces immediately on the first `dart run build_runner build` in the codegen-establishment task |
| The bug 011 partial-DRY-touch concern (a `theme_selector.dart` modification here might invite "while I'm here" extracting the device-mode helper) | Med | Low | Spec §6 explicitly excludes bug 011. /breakdown's task for `theme_selector.dart` will list "do NOT extract helpers" as an explicit constraint |
| `effectiveLocale` is referenced from `docs/features/settings.md:30–35` (code sample) — leaving it stale would create new doc-vs-code drift | Med | Low | AC-15 covers the doc update. The tech-writer pass in `/finalize` enforces broader currency |
| AC-1/AC-2 grep checks fail because of an indirect re-export through a barrel file | Low | Low | This codebase has no barrel files. `dart analyze` would catch any `package:flutter` import directly. AC-1/AC-2 use `grep -r "package:flutter" path/` which is robust against the codebase's flat-import style |
| Bug 010 (catches only Exception) interaction: while editing `settings_repository_impl.dart` to update the `saveThemeMode` signature, the `try { } on Exception catch` blocks are visible. A motivated implementer might "fix it while here" | Med | Low | /breakdown's task for `settings_repository_impl.dart` lists "scope: signature update only — do NOT change try/catch shape (bug 010)". Spec §6 explicitly excludes bug 010 |

## Dependencies

**External packages** (added to `pubspec.yaml`):
- `freezed_annotation: ^3.0.0` (or whichever current minor freezed_annotation supports — pin via `flutter pub add` which picks current)
- `freezed: ^3.0.0` (dev) — same major; freezed and freezed_annotation must be the same major version
- `build_runner: ^2.4.0` (dev) — required as the codegen runner

The `flutter pub add` command resolves these to compatible current versions automatically; the implementation task does not hard-code them.

**Tooling commands**:
- `flutter pub add freezed_annotation dev:freezed dev:build_runner` (per Context7's canonical install line)
- `dart run build_runner build --delete-conflicting-outputs` (run after any change to `@freezed`-annotated source)
- Constitution §6.6 already documents this as the project's codegen ritual

**No environment variables, services, or platform configuration** are added by this plan.

## Supporting Documents

- [research.md](research.md) — freezed/build_runner version selection, codegen invocation, persistence migration analysis, alternatives compared for AppThemeMode cardinality and getter removal
- [data-model.md](data-model.md) — `AppThemeMode` (new), `AppSettings` (changed), persistence layout
- contracts.md — **not generated** (no API contracts; this is a local app)
- [bug 001](../../bugs/001-domain-layer-flutter-contamination.md) — originating bug report
- [audit](../../audits/2026-04-30-audit.md) — sourcing context (Critical Findings 4–8)

---

## Phase 2.5: AC-by-AC Coverage Cross-Reference

Each spec AC verified against this plan's File Impact + Layer Map + Key Design Decisions:

| AC | Spec Statement | Implementation path in this plan |
|----|----------------|----------------------------------|
| AC-1 | `grep -r "package:flutter" lib/features/settings/domain/` returns zero | File Impact: `app_settings.dart` (drop import), `settings_repository.dart` (drop import), `app_theme_mode.dart` (created pure Dart). No domain file retains a Flutter import |
| AC-2 | `grep -r "package:flutter" lib/features/settings/data/` returns zero | File Impact: `settings_local_data_source.dart` (drop import — only needed for `ThemeMode`), `settings_repository_impl.dart` (drop import — only needed for `ThemeMode`) |
| AC-3 | `app_theme_mode.dart` exists with 2-value enum + `fromCodeOrDefault` | File Impact: action **C** for `app_theme_mode.dart`; Data Model defines exact shape |
| AC-4 | `AppSettings` is `@freezed`; `.freezed.dart` committed; analyze clean | File Impact: action **M** for `app_settings.dart` + action **G** for `app_settings.freezed.dart`; Constitution Compliance row §2.2 + §3.1 |
| AC-5 | `effectiveThemeMode` / `effectiveLocale` getters removed | Key Design Decisions row "Removed entirely"; Data Model "**Removed** in this spec" section |
| AC-6 | `saveThemeMode` parameter type is `AppThemeMode` | File Impact rows for `settings_repository.dart`, `settings_repository_impl.dart`, `settings_provider.dart` |
| AC-7 | Theme persists as `String`; round-trip works | File Impact: `settings_local_data_source.dart` (`getString`/`setString`); Data Model "Persistence Layout" |
| AC-8 | Legacy `int` reads return `AppThemeMode.light` | Research §6 documents the platform behavior; File Impact: test added to `settings_repository_impl_test.dart` |
| AC-9 | Only `lib/app.dart` (and theme_preview for display) maps `AppThemeMode → ThemeMode` | Layer Map "Presentation (seam)" row; Key Design Decisions row 4; theme_preview kept for display per Risk Assessment row 4 |
| AC-10 | `lib/app.dart` no longer references the removed getters | File Impact row for `lib/app.dart` ("four `.select()` calls; remove `effectiveThemeMode`/`effectiveLocale` consumption") |
| AC-11 | pubspec.yaml lists the three new packages | File Impact row for `pubspec.yaml`; Dependencies section names the exact packages |
| AC-12 | `dart analyze` clean | Constitution Compliance row + Risk Assessment "self-repair loop" mitigation |
| AC-13 | `flutter test` passes | File Impact: 7 test files updated + 1 added (AC-16). All assertions preserved (behavior unchanged) |
| AC-14 | `flutter build apk --debug` succeeds | Implicit — covered by /execute-task's terminal-task build gate (constitution §6.6 + MEMORY.md "Integration-gate task pattern") |
| AC-15 | `docs/features/settings.md` Domain tables updated | Documentation Impact row "Domain section update" |
| AC-16 | Pure-Dart test for `copyWith` + `fromCodeOrDefault` | File Impact action **C** for `test/features/settings/domain/entities/app_settings_test.dart` |
| AC-17 | Real-device run shows graceful theme reset, then re-toggle persists | Manual AC; Risk Assessment row 3 + spec §3.6. Verified by user at `/verify` time, not automatable |

**Reverse check**: this plan adds files/components NOT in the spec's Affected Areas? Yes — one item:
- `test/features/settings/domain/entities/app_settings_test.dart` — created. Spec §4 lists it implicitly via AC-16 ("a pure-Dart unit test... is added under `test/features/settings/domain/`") but the file path is not in the Affected Areas table. Adding to plan as a discovered addition; will appear explicitly in /breakdown's task list.

All 17 ACs have a clear implementation path. No "AC has no clear implementation path" risks need to be added.
