# Spec: Adopt `@riverpod` Codegen Across All Manual Providers

**Date**: 2026-05-08
**Status**: Complete
**Author**: Claude + Webmint
**Verified**: 2026-05-09 — all 14 ACs PASS, all gates green, APPROVED
**Closes**: bug 004 (`bugs/004-manual-providers-missing-riverpod-codegen.md`)
**Research**: `research/2026-05-08-bug-004-riverpod-codegen.md`

## 1. Overview

The project's stack (constitution §1) and conventions (§4.1.1) mandate `@riverpod` codegen, but `pubspec.yaml` is missing `riverpod_annotation` and `riverpod_generator`, and four providers are still hand-rolled. This spec wires up the missing dependencies and migrates every existing provider to the codegen form, producing the first canonical `@riverpod` exemplar in the codebase. Pure compile-time refactor — no runtime behavior change.

## 2. Current State

### Constitution position
- §1 names the stack as "Riverpod 2.x with `riverpod_generator` (code generation)". Wording is stale (`flutter_riverpod ^3.3.1` is pinned), but intent is unambiguous: codegen is the standard.
- §2.2 mandates that generated files (`*.g.dart`, `*.freezed.dart`) sit next to source AND are committed.
- §4.1.1 [convention]: "Always use `@riverpod` codegen for new providers. No manual `Provider`/`StateNotifierProvider` declarations."
- §6.6: `dart run build_runner build --delete-conflicting-outputs` is the documented codegen invocation.

### Codebase reality (drift from constitution)
- **`pubspec.yaml`** (`pubspec.yaml:30-62`):
  - Has `flutter_riverpod ^3.3.1`, `freezed_annotation ^3.1.0`, `freezed ^3.2.5`, `build_runner ^2.15.0`.
  - **Missing**: `riverpod_annotation` (runtime dep), `riverpod_generator` (dev dep).
  - The `build_runner` pipeline already runs for `freezed` (added in feature 012); adding Riverpod codegen extends it without new tooling.
- **Hand-rolled providers (4 sites)**:
  1. `lib/core/providers/shared_preferences_provider.dart:23` — `Provider<SharedPreferencesWithCache>` with throwing-placeholder pattern (overridden in `main.dart`).
  2. `lib/features/settings/presentation/providers/settings_provider.dart:23` — `Provider<SettingsRepository>`.
  3. `lib/features/settings/presentation/providers/settings_provider.dart:30` — `NotifierProvider<SettingsNotifier, AppSettings>`.
  4. `lib/features/settings/presentation/providers/settings_provider.dart:130` — `StreamProvider<Failure>` (`settingsErrorsProvider`, added in feature 014).
- **`analysis_options.yaml:19-21`** already excludes `**/*.g.dart` — no analyzer changes needed.
- **Existing `freezed` codegen output** (e.g. `lib/features/settings/domain/entities/app_settings.freezed.dart`) confirms the `dart run build_runner build --delete-conflicting-outputs` workflow is wired up and reusable.

### Consumer call-sites of the providers being migrated
Production code:
- `lib/main.dart:23` — `sharedPreferencesProvider.overrideWithValue(prefs)`
- `lib/app.dart:67-76` — four `settingsProvider.select(...)` calls
- `lib/features/settings/presentation/screens/settings_screen.dart:38` — `settingsErrorsProvider`
- `lib/features/settings/presentation/widgets/language_selector.dart:35,69,71,85` — `settingsProvider` (read state) and `settingsProvider.notifier` (mutate)
- `lib/features/settings/presentation/widgets/theme_selector.dart:33,63,65,91` — same pattern
- `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart:34,53` — `settingsProvider` and `settingsProvider.notifier`
- `lib/features/settings/domain/entities/app_settings.dart:24` — dartdoc reference to `settingsProvider`

Test code:
- `test/features/settings/presentation/providers/settings_provider_test.dart` — heavy usage: `settingsProvider`, `settingsProvider.notifier`, `settingsRepositoryProvider.overrideWithValue(...)`
- `test/core/routing/app_router_test.dart:128` — `settingsRepositoryProvider.overrideWithValue(...)`
- `test/features/settings/presentation/screens/settings_screen_test.dart:99` — `settingsRepositoryProvider.overrideWithValue(...)`

The widget tests for `language_selector` and `theme_selector` do not reference the providers directly (they pump the screen with the widget under test); no changes expected there.

### Architecture pattern (carried from `docs/architecture.md`)
- Repositories are wired through providers in `presentation/providers/`. UI consumes via `ref.watch` / `ref.read`. The codegen migration preserves this layering exactly — only the provider declaration syntax changes.

## 3. Desired Behavior

### Dependencies
- `pubspec.yaml` lists `riverpod_annotation` under `dependencies` and `riverpod_generator` under `dev_dependencies`, both at versions compatible with `flutter_riverpod ^3.3.1` (Riverpod 3.x line — verified via Context7 in research).
- `flutter pub get` resolves cleanly; `pubspec.lock` reflects the new packages.

### Provider migration
All four manual providers are replaced with `@riverpod`-annotated equivalents:

1. **`sharedPreferencesProvider`** → `@Riverpod(keepAlive: true)` function with the throwing-placeholder body. The override in `main.dart` continues to compile and work without further changes.
2. **`settingsRepositoryProvider`** → `@riverpod` function returning `SettingsRepository`.
3. **`settingsProvider`** → `@riverpod class SettingsNotifier extends _$SettingsNotifier` with the existing `build()` method and four `setX` mutators preserved verbatim. Codegen emits a generated provider named **`settingsNotifierProvider`** — the canonical Riverpod 3.x idiom for class-form notifiers. Consumer call-sites are renamed from `settingsProvider` to `settingsNotifierProvider`.
4. **`settingsErrorsProvider`** → `@riverpod` function returning `Stream<Failure>` (replaces the `StreamProvider<Failure>` factory). Same lifetime semantics — non-`autoDispose` is no longer needed because `keepAlive: true` is the explicit codegen option; default `autoDispose` is acceptable here since `settingsNotifierProvider` is read elsewhere and stays alive.

### Consumer call-site updates
- All `settingsProvider` references in production and test code are renamed to `settingsNotifierProvider`.
- `settingsRepositoryProvider`, `sharedPreferencesProvider`, and `settingsErrorsProvider` keep their names — the codegen-emitted symbol is identical to the original lowerCamelCase name (function-form providers).
- The dartdoc reference in `lib/features/settings/domain/entities/app_settings.dart:24` is updated to `settingsNotifierProvider`.

### Generated files
- New `*.g.dart` files sit next to their source files and are committed:
  - `lib/core/providers/shared_preferences_provider.g.dart`
  - `lib/features/settings/presentation/providers/settings_provider.g.dart`
- The generated symbols expose `sharedPreferencesProvider`, `settingsRepositoryProvider`, `settingsNotifierProvider`, and `settingsErrorsProvider`.

### Behavior preserved
- `SettingsNotifier` API surface (`build`, `setThemeMode`, `setUseSystemTheme`, `setUseSystemLanguage`, `setManualLanguage`, `errors` getter) remains identical.
- Persistence semantics, error-stream broadcasting, and dispose ordering are unchanged.
- `main.dart` startup path is unchanged.
- All existing tests pass after the rename, with no behavioral assertion changes required.

### Quality gates
- `dart analyze` returns clean (no new warnings/errors).
- `flutter test` passes (full suite — currently 203 tests per session-state from feature 014).
- `flutter build apk` succeeds.
- `dart run build_runner build --delete-conflicting-outputs` runs to completion with no errors.

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Dependency manifest | `pubspec.yaml`, `pubspec.lock` | Add `riverpod_annotation` (dependencies), `riverpod_generator` (dev_dependencies); resolve. |
| Core provider | `lib/core/providers/shared_preferences_provider.dart` | Migrate to `@Riverpod(keepAlive: true)` function. |
| Settings providers | `lib/features/settings/presentation/providers/settings_provider.dart` | Migrate `settingsRepositoryProvider`, `SettingsNotifier`, `settingsErrorsProvider` to `@riverpod`. Add `part 'settings_provider.g.dart';`. |
| Generated files (new) | `lib/core/providers/shared_preferences_provider.g.dart`, `lib/features/settings/presentation/providers/settings_provider.g.dart` | Create via `build_runner`; commit per §2.2. |
| App entry | `lib/main.dart` | No semantic change — `sharedPreferencesProvider.overrideWithValue(prefs)` still compiles. Verify only. |
| App root selectors | `lib/app.dart` | Rename `settingsProvider.select(...)` → `settingsNotifierProvider.select(...)` in 4 places. |
| Settings UI | `lib/features/settings/presentation/screens/settings_screen.dart`, `lib/features/settings/presentation/widgets/language_selector.dart`, `lib/features/settings/presentation/widgets/theme_selector.dart` | Rename `settingsProvider` → `settingsNotifierProvider` at all call-sites. `settingsErrorsProvider` reference unchanged. |
| Theme preview | `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` | Rename `settingsProvider` → `settingsNotifierProvider` at 2 call-sites. |
| Domain dartdoc | `lib/features/settings/domain/entities/app_settings.dart` | Update dartdoc reference (line 24) from `settingsProvider` to `settingsNotifierProvider`. No code change. |
| Settings provider tests | `test/features/settings/presentation/providers/settings_provider_test.dart` | Rename `settingsProvider` → `settingsNotifierProvider` (~20 call-sites). `settingsRepositoryProvider.overrideWithValue` unchanged. |
| Router tests | `test/core/routing/app_router_test.dart` | No name change for `settingsRepositoryProvider`. Verify import path still works. |
| Settings screen tests | `test/features/settings/presentation/screens/settings_screen_test.dart` | No name change for `settingsRepositoryProvider`. Verify. |
| Documentation | `docs/architecture.md` | Add a brief note recording the codegen pattern (function-form vs class-form) and the `build_runner` invocation, since constitution §6.6 covers it but `docs/` does not yet. |
| Bug tracker | `bugs/004-manual-providers-missing-riverpod-codegen.md` | Flip Status → Fixed; set Fixed date. |

## 5. Acceptance Criteria

- [x] **AC-1**: `pubspec.yaml` declares `riverpod_annotation` under `dependencies` and `riverpod_generator` under `dev_dependencies`; `flutter pub get` succeeds and `pubspec.lock` is updated.
- [x] **AC-2**: `lib/core/providers/shared_preferences_provider.dart` uses `@Riverpod(keepAlive: true)` with `part 'shared_preferences_provider.g.dart';`. The throwing-placeholder body and dartdoc are preserved.
- [x] **AC-3**: `lib/features/settings/presentation/providers/settings_provider.dart` declares `settingsRepositoryProvider`, `SettingsNotifier`, and `settingsErrorsProvider` via `@riverpod` (function or class form as appropriate) with `part 'settings_provider.g.dart';`. No `Provider<...>`, `NotifierProvider<...>`, or `StreamProvider<...>` declarations remain.
- [x] **AC-4**: `dart run build_runner build --delete-conflicting-outputs` produces `lib/core/providers/shared_preferences_provider.g.dart` and `lib/features/settings/presentation/providers/settings_provider.g.dart`. Both are committed.
- [x] **AC-5**: All production consumers of `settingsProvider` are renamed to `settingsNotifierProvider`. Specifically: `lib/app.dart` (4 sites), `lib/features/settings/presentation/widgets/language_selector.dart`, `lib/features/settings/presentation/widgets/theme_selector.dart`, `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart`. `grep -rn "settingsProvider\b" lib/` returns no matches.
- [x] **AC-6**: All test consumers of `settingsProvider` are renamed to `settingsNotifierProvider` in `test/features/settings/presentation/providers/settings_provider_test.dart`. Other test files using `settingsRepositoryProvider` need no rename.
- [x] **AC-7**: The dartdoc in `lib/features/settings/domain/entities/app_settings.dart:24` references `settingsNotifierProvider`.
- [x] **AC-8**: `lib/main.dart` is unchanged in semantics — `sharedPreferencesProvider.overrideWithValue(prefs)` compiles and behaves identically. The override mechanism is preserved.
- [x] **AC-9**: `SettingsNotifier`'s public surface (`build`, `setThemeMode`, `setUseSystemTheme`, `setUseSystemLanguage`, `setManualLanguage`, `errors` stream getter) is byte-identical to the pre-migration version (only the class declaration changes from `extends Notifier<AppSettings>` to `extends _$SettingsNotifier`).
- [x] **AC-10**: `dart analyze` returns no warnings or errors.
- [x] **AC-11**: `flutter test` passes the full suite without modifying any test assertions (only the `settingsProvider` → `settingsNotifierProvider` symbol rename).
- [x] **AC-12**: `flutter build apk` succeeds (debug build).
- [x] **AC-13**: `bugs/004-manual-providers-missing-riverpod-codegen.md` Status is `Fixed` with a `Fixed: 2026-05-09` entry. Reference back to this spec.
- [x] **AC-14**: `docs/architecture.md` includes a brief codegen-pattern note that mentions the `build_runner` invocation and points to the new providers as the exemplars.

## 6. Out of Scope

- **NOT included**: Updating constitution §1 wording from "Riverpod 2.x" to "3.x" (real drift exists, but it's a doc-only change unrelated to bug 004 — track separately).
- **NOT included**: Updating constitution §7.2's example block (uses outdated 2.x `XxxRef` typedefs) — also doc-only follow-up.
- **NOT included**: Adding new providers, refactoring the `SettingsNotifier` internals (e.g., switching to `AsyncNotifier`), or changing error-stream semantics.
- **NOT included**: Splitting the `settings_provider.dart` file into one provider per file. Constitution §2.2 allows multiple providers in one file when feature-cohesive; current grouping is fine.
- **NOT included**: Adding `--watch` mode tooling, IDE-integration scripts, or CI workflow changes for codegen.
- **NOT included**: Migrating any other features (none exist yet that use providers — this is the only set).
- **NOT included**: Renaming the `errors` getter on `SettingsNotifier` or changing how `settingsErrorsProvider` derives from it.
- **NOT included**: Closing any other audit-found bug (003, 005-017 stay separate).

## 7. Technical Constraints

- **Must follow**: Constitution §4.1.1 — `@riverpod` codegen is the only sanctioned form for new/migrated providers.
- **Must follow**: Constitution §2.2 — generated `*.g.dart` files are committed.
- **Must follow**: Constitution §6.6 — `dart run build_runner build --delete-conflicting-outputs` is the codegen invocation.
- **Must use**: `flutter pub add` for adding dependencies (constitution §2.3 forbids manual `pubspec.yaml` edits for deps).
- **Must not break**: The existing `sharedPreferencesProvider.overrideWithValue` mechanism in `main.dart`. The throwing-placeholder + override pattern survives the migration.
- **Must not break**: The `errors` stream lifecycle in `SettingsNotifier` (broadcast `StreamController` created in `build()`, closed via `ref.onDispose`).
- **Must preserve**: Riverpod 3.x signature — `Ref` is used directly (no `XxxRef` typedefs, which were a 2.x form).
- **Compatibility**: `riverpod_annotation` and `riverpod_generator` versions must align with `flutter_riverpod ^3.3.1` (Riverpod 3.x line). Use `flutter pub add` defaults, then verify.

## 8. Open Questions

- **Q1**: Should `settingsErrorsProvider` use `@riverpod` (auto-dispose) or `@Riverpod(keepAlive: true)`? The current manual `StreamProvider` is non-autoDispose to match `settingsNotifierProvider`'s lifetime. **Tentative answer**: `@riverpod` (default autoDispose) is fine because the only consumer is `SettingsScreen` (subscribed via `ref.listen` while mounted) — but if the breakdown reveals hidden listeners that require keepAlive, escalate. Defer the decision to `/plan`.
- **Q2**: Does the dartdoc in `lib/features/settings/domain/entities/app_settings.dart:24` count as a "code change" that requires running tests, or is it a comment-only edit covered by `dart analyze`? **Tentative answer**: it's documentation; no behavior impact. Tests should still pass.
- **Q3**: Are there any IDE/Android-Studio configurations that need to know about the new generator (e.g., `build.yaml`)? **Tentative answer**: No — `build_runner` autodiscovers builders from `dev_dependencies`. Verify in `/plan` if a `build.yaml` is needed for any reason.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Version mismatch between `riverpod_annotation`/`riverpod_generator` and `flutter_riverpod ^3.3.1` causes `flutter pub get` to fail | Low | Medium | Use `flutter pub add` (resolves compatible versions). If conflict, pin to a version of the trio that the same maintainer publishes together. |
| `build_runner` produces unexpected output / collides with existing freezed output | Low | Low | `--delete-conflicting-outputs` flag covers this. Existing freezed pipeline already uses the same flag. |
| Missed call-site rename (e.g. a dartdoc reference) leaves stale symbol that `dart analyze` doesn't catch | Medium | Low | Use `grep -rn "settingsProvider\b"` after rename and confirm zero matches outside the spec/research/docs/bug folder. |
| `settingsErrorsProvider` autoDispose semantics differ subtly from manual `StreamProvider` (non-autoDispose) | Low | Medium | Read `SettingsScreen` to confirm the only listener is `ref.listen` while mounted. If any other consumer exists, switch to `@Riverpod(keepAlive: true)`. |
| Generated `.g.dart` files trip the `**/*.g.dart` analyzer exclusion incorrectly | Low | Low | `analysis_options.yaml:19-21` already excludes them. Verify post-codegen. |
| Test fragility: widget tests rely on `settingsProvider` symbol indirectly | Low | Low | Spec only renames; tests' assertion logic stays unchanged. `flutter test` is the gate. |
| Drift between this spec and bug 004's "fix notes" (which mentioned bug 003, since fixed) | Low | Low | This spec supersedes bug 004's free-form fix notes. Bug 004 file gets a `Fixed: ` entry and points back here. |

---

## Notes for `/plan` and `/breakdown`

The research file (`research/2026-05-08-bug-004-riverpod-codegen.md`) recommends a 4-task shape:
1. **Infra** (architect or mobile-engineer): `flutter pub add` the two new deps; verify `flutter pub get` resolves.
2. **Core migration** (architect): Migrate `shared_preferences_provider.dart` to `@Riverpod(keepAlive: true)`; run `build_runner`; verify `main.dart` override still compiles.
3. **Settings cluster** (mobile-engineer — terminal source-edit task): Migrate `settingsRepositoryProvider`, `SettingsNotifier`, `settingsErrorsProvider`; run `build_runner`; rename all production + test consumers (`settingsProvider` → `settingsNotifierProvider`); commit `.g.dart` files.
4. **Bookkeeping** (tech-writer): Update `docs/architecture.md`; flip bug 004 status; (optional follow-up notes for §1/§7.2 doc drift).

This shape is a recommendation only — `/breakdown` will validate or revise.
