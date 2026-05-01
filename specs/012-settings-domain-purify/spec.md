# Spec: Settings Domain Purify (remove Flutter from settings/domain + persist theme as string)

**Date**: 2026-04-30
**Status**: Complete
**Author**: Claude + Webmint
**Approved**: 2026-04-30 (implicit — user invoked /plan immediately after spec presentation)
**Verified**: 2026-04-30 (16/16 automated ACs PASS; AC-17 deferred manual real-device check; review APPROVED clean)
**Source**: bugs/001-domain-layer-flutter-contamination.md (audited 2026-04-30)

## 1. Overview

Remove `package:flutter/material.dart` from `lib/features/settings/domain/`, eliminating the constitution §2.1 / §4.2.1 violation that currently makes domain tests require the Flutter binding. Introduce a domain-owned `AppThemeMode` enum, persist the theme choice as a stable string code (already documented as `String` in `docs/features/settings.md:158` — the implementation drifted to `int`), convert `AppSettings` to `@freezed` for proper value equality, and confine all `Flutter ↔ domain` type mapping to a single presentation-layer seam in `lib/app.dart`.

## 2. Current State

### 2.1 The violation

`lib/features/settings/domain/entities/app_settings.dart:11` and `lib/features/settings/domain/repositories/settings_repository.dart:4` both `import 'package:flutter/material.dart'` so the domain layer can use `ThemeMode` (Flutter SDK enum) and `Locale` (Flutter SDK type). Constitution §2.1 [enforced]: "FORBIDDEN imports in `domain/`: anything from `package:flutter/*`." Constitution §4.2.1 [enforced]: "Never put `package:flutter/* ` (or any UI/SDK package) imports in `lib/features/*/domain/`. Domain must run in pure Dart tests with no Flutter binding."

`AppSettings` is also a hand-rolled class (no `@freezed`), violating §3.1 [convention]: "All entities, DTOs, and state classes use `freezed` — never hand-roll `==`, `hashCode`, or `copyWith`." Missing `==`/`hashCode` means `ref.watch(settingsProvider.select(...))` cannot dedup rebuilds by value-equality — every `state = state.copyWith(...)` triggers all watchers regardless of whether the selected field changed.

### 2.2 The persistence drift

`docs/features/settings.md:156–161` documents the persistence contract:

| Key | Type | Default |
|---|---|---|
| `themeMode` | `String` (`'light'` / `'dark'`) | `'light'` |

But the actual code at `lib/features/settings/data/datasources/settings_local_data_source.dart:37–47` persists `ThemeMode.index` as an `int`. The implementation drifted from the documented contract. Furthermore, `ThemeMode.values == [system, light, dark]` (3 values), so the `setInt(_kThemeModeKey, mode.index)` write at line 47 will silently store `0` if a future caller passes `ThemeMode.system` — and the matching read at lines 38–43 will load it back as `manualThemeMode = ThemeMode.system`, contradicting the existing `app_settings.dart:42–43` dartdoc claim that "Only `ThemeMode.light` and `ThemeMode.dark` are semantically valid here."

### 2.3 The mapping seam

`AppSettings` exposes two derived getters for `MaterialApp`:

```dart
ThemeMode get effectiveThemeMode =>
    useSystemTheme ? ThemeMode.system : manualThemeMode;

Locale? get effectiveLocale =>
    useSystemLanguage ? null : Locale(manualLanguage.code);
```

Both return Flutter SDK types (`ThemeMode`, `Locale`). They are consumed in `lib/app.dart:58–61` via `ref.watch(settingsProvider.select((s) => s.effectiveThemeMode))` etc. — the only place in the codebase that needs Flutter SDK types for these.

### 2.4 Architecture context

Per `docs/architecture.md:7–23`, the project's first full Clean-Architecture stack landed in `009-theme-settings`. The architecture doc explicitly calls out the §2.1 rule: "**`domain/` never imports `package:flutter/*`.** Domain must run in pure-Dart tests." The current settings/domain code violates the doc's own example — and the doc's settings-feature walkthrough (`docs/features/settings.md`) describes the `String` persistence shape that the actual code does not implement.

### 2.5 Files referencing the affected types

`grep` verified 15 files reference `ThemeMode`, `effectiveLocale`, `effectiveThemeMode`, or `AppSettings(`:

- 8 source: `lib/app.dart`, `lib/features/settings/data/datasources/settings_local_data_source.dart`, `lib/features/settings/data/repositories/settings_repository_impl.dart`, `lib/features/settings/domain/entities/app_settings.dart`, `lib/features/settings/domain/repositories/settings_repository.dart`, `lib/features/settings/presentation/providers/settings_provider.dart`, `lib/features/settings/presentation/widgets/theme_selector.dart`, `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart`
- 7 tests: `test/core/routing/app_router_test.dart`, `test/features/settings/data/repositories/settings_repository_impl_test.dart`, `test/features/settings/presentation/providers/settings_provider_test.dart`, `test/features/settings/presentation/screens/settings_screen_test.dart`, `test/features/settings/presentation/widgets/language_selector_test.dart`, `test/features/settings/presentation/widgets/theme_selector_test.dart`, `test/widget_test.dart`

## 3. Desired Behavior

### 3.1 New domain types

Add `lib/features/settings/domain/entities/app_theme_mode.dart` — pure Dart, two values:

```dart
enum AppThemeMode {
  light(code: 'light'),
  dark(code: 'dark');

  const AppThemeMode({required this.code});

  /// Stable string code used for SharedPreferences persistence.
  /// Order-independent — safe across Flutter SDK changes.
  final String code;

  /// Resolves a stored code back to its enum value, falling back to [light]
  /// when the code is unknown, empty, or null.
  static AppThemeMode fromCodeOrDefault(String? code) =>
      AppThemeMode.values.firstWhere(
        (m) => m.code == code,
        orElse: () => AppThemeMode.light,
      );
}
```

Rationale for the **two-value enum** (not three): the existing `manualThemeMode` field's dartdoc already states "Only `ThemeMode.light` and `ThemeMode.dark` are semantically valid here." The `system` concept is owned by the orthogonal `useSystemTheme: bool` field. Mirroring Flutter's three-value `ThemeMode` in the domain enum would re-introduce the same contract violation we're fixing.

### 3.2 `AppSettings` becomes a `@freezed` class

`lib/features/settings/domain/entities/app_settings.dart` is rewritten as:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'app_language.dart';
import 'app_theme_mode.dart';

part 'app_settings.freezed.dart';

@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(true) bool useSystemTheme,
    @Default(AppThemeMode.light) AppThemeMode manualThemeMode,
    @Default(true) bool useSystemLanguage,
    @Default(AppLanguage.en) AppLanguage manualLanguage,
  }) = _AppSettings;
}
```

The `effectiveThemeMode` and `effectiveLocale` getters are **removed** from the entity. The presentation seam in `lib/app.dart` computes the Flutter-typed values directly using the entity's plain fields (see §3.4).

### 3.3 Repository contract becomes pure Dart

`lib/features/settings/domain/repositories/settings_repository.dart` removes the Flutter import. `saveThemeMode` accepts `AppThemeMode` (not `Flutter.ThemeMode`). The dartdoc on `saveUseSystemLanguage` removes the `MaterialApp.localeResolutionCallback` reference and describes behavior in domain terms only.

### 3.4 The presentation seam

`lib/app.dart` becomes the single mapping point:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final useSystemTheme = ref.watch(
    settingsProvider.select((s) => s.useSystemTheme),
  );
  final manualThemeMode = ref.watch(
    settingsProvider.select((s) => s.manualThemeMode),
  );
  final useSystemLanguage = ref.watch(
    settingsProvider.select((s) => s.useSystemLanguage),
  );
  final manualLanguage = ref.watch(
    settingsProvider.select((s) => s.manualLanguage),
  );

  return MaterialApp.router(
    // ...
    themeMode: useSystemTheme ? ThemeMode.system : _toFlutterThemeMode(manualThemeMode),
    locale: useSystemLanguage ? null : Locale(manualLanguage.code),
    routerConfig: appRouter,
  );
}

ThemeMode _toFlutterThemeMode(AppThemeMode m) => switch (m) {
  AppThemeMode.light => ThemeMode.light,
  AppThemeMode.dark => ThemeMode.dark,
};
```

The `_resolveLocale` callback in `app.dart:32` stays unchanged.

### 3.5 Persistence becomes string-based

`SettingsLocalDataSource.getThemeMode()` reads `getString(_kThemeModeKey)` and returns `AppThemeMode.fromCodeOrDefault(code)`. `setThemeMode(AppThemeMode mode)` writes `setString(_kThemeModeKey, mode.code)`. This matches the contract documented in `docs/features/settings.md:158` and is order-independent.

### 3.6 Legacy migration

Devices that ran a previous build have an `int` value persisted under `themeMode`. After this change, `getString('themeMode')` on an int-stored key returns `null` (SharedPreferences is type-strict at the platform level). The `fromCodeOrDefault` fallback then returns `AppThemeMode.light`. **Result: the user sees their prior manual theme reset to `light` on first launch after this change.** No data loss for any other field.

For a one-user personal app where the developer is the user, this is acceptable. No multi-step migration is added.

### 3.7 Tooling additions

`pubspec.yaml` gains:
- `freezed_annotation: ^3.0.0` (or current pinned minor) — runtime
- `freezed: ^3.0.0` — dev
- `build_runner: ^2.4.0` — dev (already required by riverpod_generator if/when bug 004 lands)

The existing analysis_options.yaml already has `exclude: ["**/*.freezed.dart"]` (constitution §7.4) so generated files do not trigger lints.

### 3.8 Generated file commit policy

Per constitution §2.2: "Generated files (`*.g.dart`, `*.freezed.dart`) sit next to their source AND are committed to the repo." The new `app_settings.freezed.dart` is committed.

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Domain — new enum | `lib/features/settings/domain/entities/app_theme_mode.dart` | **Create new** |
| Domain — entity | `lib/features/settings/domain/entities/app_settings.dart` | Rewrite: `@freezed`, remove Flutter import, `manualThemeMode: AppThemeMode`, drop `effectiveThemeMode`/`effectiveLocale` getters |
| Domain — generated | `lib/features/settings/domain/entities/app_settings.freezed.dart` | **Create new** (committed per §2.2) |
| Domain — repository contract | `lib/features/settings/domain/repositories/settings_repository.dart` | Remove Flutter import; `saveThemeMode(AppThemeMode)`; strip MaterialApp reference from dartdoc |
| Data — data source | `lib/features/settings/data/datasources/settings_local_data_source.dart` | Remove Flutter import; `getThemeMode/setThemeMode` operate on `AppThemeMode` and use string-keyed `getString`/`setString` |
| Data — repository impl | `lib/features/settings/data/repositories/settings_repository_impl.dart` | Update `saveThemeMode` signature + `load()` mapping; Flutter import stays only if still needed elsewhere (it isn't — remove it) |
| Presentation — provider | `lib/features/settings/presentation/providers/settings_provider.dart` | `setThemeMode(AppThemeMode)` signature; `state.copyWith(manualThemeMode: AppThemeMode...)`. (Other findings about debugPrint/silent fold are out of scope — see §6.) |
| Presentation — theme selector | `lib/features/settings/presentation/widgets/theme_selector.dart` | `SegmentedButton<AppThemeMode>`; pre-fill helper uses `AppThemeMode` |
| Presentation — theme preview | `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` | `_iconForEffectiveMode` switches on `(useSystemTheme, manualThemeMode)`; cycle logic uses `AppThemeMode` |
| Presentation — app root | `lib/app.dart` | The single Flutter↔domain mapping seam (§3.4); compute `themeMode` and `locale` from raw entity fields |
| Tooling | `pubspec.yaml` | Add `freezed_annotation`, `freezed`, `build_runner` (§3.7) |
| Test — repository impl | `test/features/settings/data/repositories/settings_repository_impl_test.dart` | Update fixture seeds (`'themeMode': 'light'` etc.); update assertions to `AppThemeMode` |
| Test — provider | `test/features/settings/presentation/providers/settings_provider_test.dart` | `AppThemeMode` in expectations + mock calls |
| Test — settings screen | `test/features/settings/presentation/screens/settings_screen_test.dart` | `AppSettings(...)` constructions with `AppThemeMode.dark` etc. |
| Test — theme selector | `test/features/settings/presentation/widgets/theme_selector_test.dart` | `AppThemeMode` segments; pre-fill assertions |
| Test — language selector | `test/features/settings/presentation/widgets/language_selector_test.dart` | Verify-only (constructions of `AppSettings` need updating where present) |
| Test — widget test | `test/widget_test.dart` | `AppThemeMode` in cycle assertions |
| Test — router | `test/core/routing/app_router_test.dart` | Verify-only (no direct `ThemeMode`/`AppSettings` references expected, but compile-check after the change) |
| Docs — features | `docs/features/settings.md` | Update §"Domain" tables to reference `AppThemeMode`; the persistence table at line 158 already says `String` — leave unchanged |

**Total**: 9 source files (8 modified + 1 created), 1 generated file, 1 pubspec, 7 test files, 1 doc file = **19 files**. Above the `/fix` threshold of 5; this is exactly the size that justifies the `/specify` escalation.

## 5. Acceptance Criteria

Each criterion is testable and unambiguous.

- [x] **AC-1**: `grep -r "package:flutter" lib/features/settings/domain/` returns zero results.
- [x] **AC-2**: `grep -r "package:flutter" lib/features/settings/data/` returns zero results (the data source no longer needs `ThemeMode`; only `shared_preferences`).
- [x] **AC-3**: `lib/features/settings/domain/entities/app_theme_mode.dart` exists, defines `enum AppThemeMode { light, dark }` with a `code` field and `fromCodeOrDefault` static helper.
- [x] **AC-4**: `AppSettings` is a `@freezed` class. `app_settings.freezed.dart` is committed to the repo and `dart analyze` is clean.
- [x] **AC-5**: `AppSettings` no longer exposes `effectiveThemeMode` or `effectiveLocale` getters.
- [x] **AC-6**: `SettingsRepository.saveThemeMode` parameter type is `AppThemeMode` (not `ThemeMode`).
- [x] **AC-7**: The data source persists `themeMode` as `String` via `getString`/`setString`. After this change, calling `setThemeMode(AppThemeMode.dark)` followed by `getThemeMode()` returns `AppThemeMode.dark`.
- [x] **AC-8**: A device that previously stored `themeMode` as an `int` reads back as `AppThemeMode.light` (the documented default) — verified by a test that seeds `{'themeMode': 1}` (int) and asserts `getThemeMode() == AppThemeMode.light`.
- [x] **AC-9**: `lib/app.dart` is the only file in `lib/` that maps `AppThemeMode → ThemeMode`. Verified by `grep -r "ThemeMode\." lib/` showing matches only in `lib/app.dart` and `lib/features/theme_preview/` (the preview screen reads Flutter `ThemeMode` for display purposes only — no mapping back to domain). All `lib/features/settings/` files are free of `ThemeMode.` references.
- [x] **AC-10**: `lib/app.dart` no longer references `effectiveThemeMode` or `effectiveLocale`. Instead it watches `useSystemTheme`, `manualThemeMode`, `useSystemLanguage`, `manualLanguage` via `.select(...)` and computes the Flutter-typed values inline.
- [x] **AC-11**: `pubspec.yaml` lists `freezed_annotation` (runtime), `freezed` (dev), `build_runner` (dev).
- [x] **AC-12**: `dart analyze` passes with zero issues.
- [x] **AC-13**: `flutter test` passes — all existing tests pass after their fixture/expectation updates.
- [x] **AC-14**: `flutter build apk --debug` succeeds.
- [x] **AC-15**: `docs/features/settings.md` "Domain" tables reference `AppThemeMode` instead of `ThemeMode`; the persistence table already documents `String` and stays unchanged.
- [x] **AC-16**: A pure-Dart unit test for `AppSettings.copyWith` and `AppThemeMode.fromCodeOrDefault` is added under `test/features/settings/domain/` and runs without the Flutter binding (i.e. uses `package:test/test.dart` via `flutter_test`'s pure-Dart group, or runs as a `dart test`-compatible file with no `flutter_test` import beyond `expect`/`group`/`test`).
- [x] **AC-17**: After `flutter run` on a device that has an existing `int` `themeMode` value stored, the app launches without crash, sees the theme reset to `light`, and the user can re-toggle to `dark` and have it persist.

## 6. Out of Scope

This spec deliberately does NOT include the following audit findings (they are tracked in their own bug files for separate `/fix` or `/specify` cycles):

- **NOT included**: bug 002 (`debugPrint` × 4 sites). The `setX` mutators in `settings_provider.dart` keep their existing `kDebugMode`-guarded `debugPrint` calls in this spec. They will be addressed by `/fix bugs/002-...` after this spec lands.
- **NOT included**: bug 003 (silent error swallowing). The fold left branches stay no-op-in-production. Restructuring the notifier to `AsyncNotifier` is its own architectural change.
- **NOT included**: bug 004 (manual `Provider`/`NotifierProvider` → `@riverpod` codegen). This spec does not touch the existing `final settingsProvider = NotifierProvider<...>` / `final settingsRepositoryProvider = Provider<...>` declarations beyond updating their parameter types. Bug 004 will migrate them to codegen in a separate pass. **Note**: this spec does add `build_runner` to pubspec, which makes bug 004's codegen migration trivial.
- **NOT included**: bug 005 (settings feature missing `domain/usecases/`). The notifier still calls the repository directly. Use cases will be introduced after bug 004.
- **NOT included**: bug 006 (Failure hierarchy completion). `CacheFailure` remains the sole concrete subclass; no new `Failure` variants are added.
- **NOT included**: bug 007 (GoRouter never disposed), bug 008 (no errorBuilder), bug 009 (cross-feature import in theme_preview), bug 010 (catches only Exception), bug 011 (DRY in selectors), bug 012 (app_router doc-vs-code drift), bug 013 (main blocks on async), bug 014 (load() "never fails" lie), bug 015 (AppBottomNav in core), bug 016 (test gap consolidation).
- **NOT included**: any UI-facing change. The Settings screen, theme selector, and language selector continue to render and behave exactly the same way to the user. The only user-observable change is AC-17 (one-time theme reset for users with legacy `int` data).
- **NOT included**: any change to localized strings (ARB files) or supported locales.
- **NOT included**: a multi-step migration plan for legacy `themeMode` int data. We accept the one-time auto-fallback to `light`.
- **NOT included**: removal of the `effectiveThemeMode`/`effectiveLocale` getter call sites' tests in a way that would change their assertions about behavior — the tests are updated to assert the same observable behavior using the new field-by-field reading instead.

## 7. Technical Constraints

- **Constitution §2.1 (NON-NEGOTIABLE)**: domain/ must not import `package:flutter/*`. This spec exists to make this true.
- **Constitution §3.1 [convention]**: all entities use `freezed`. This spec converts `AppSettings`.
- **Constitution §3.3 (naming)**: `AppThemeMode` follows the `App<Concept>` prefix used by `AppLanguage` and `AppSettings`. New file is `app_theme_mode.dart` (snake_case per §2.2 and §3.3).
- **Constitution §2.2 (generated files)**: `*.freezed.dart` files sit next to their source AND are committed.
- **Constitution §7.4 (analysis_options.yaml)**: already excludes `**/*.freezed.dart` — no analyzer changes needed.
- **Constitution §7.3**: tooling deps must be added via `flutter pub add`, not manual `pubspec.yaml` edits.
- **Constitution §6.1 (Minimal Changes)**: this spec is large by necessity (the domain-purity violation has a wide blast radius), but each individual file change is minimal — only the `ThemeMode → AppThemeMode` migration plus the freezed conversion.
- **MEMORY.md "Known Pitfalls"**: `package:flutter/*` in `domain/` — this spec is the resolution.
- **MEMORY.md "External API Quirks"**: SharedPreferences `getString` on an int-stored key returns `null` — used as the implicit migration mechanism for AC-8/AC-17.
- **Codegen**: `dart run build_runner build --delete-conflicting-outputs` must be run as part of the implementation; the generated file is committed.

## 8. Open Questions

- **OQ-1**: Should `AppThemeMode` be a 3-value enum (`{ light, dark, system }`) instead of 2-value? Decided: 2-value, keeping `system` as the orthogonal `useSystemTheme: bool`. This matches the existing field semantics ("Only `ThemeMode.light` and `ThemeMode.dark` are semantically valid here") and avoids re-introducing the same contract violation in a different shape. Document in spec; user can override during approval.
- **OQ-2**: Should `effectiveLocale` be replaced with a domain-typed `AppLanguage?` getter, or removed entirely? Decided: **removed entirely**. The seam in `app.dart` has direct access to `useSystemLanguage` and `manualLanguage` via `.select(...)` and computes `Locale?` inline. Removing the getter avoids defining "what does effective mean in domain terms" — the answer is "consult the two fields and apply the rule," which is presentation-layer concern.
- **OQ-3**: Should this spec also adopt `@freezed` for `Failure` (bug 006 territory)? Decided: **no** — kept out of scope (§6) to keep the diff bounded. `freezed` will be in `pubspec.yaml` after this spec, so bug 006 becomes trivial mechanical work.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `freezed` codegen pipeline fails on this codebase (no generated files exist yet, build_runner has never run) | Med | High | Use the pinned versions documented in constitution §7.3 and the standard greenfield setup. If codegen fails, /breakdown's first task is "establish codegen" — fail fast, fix before any source changes |
| Pre-existing tests break in unexpected ways after `AppThemeMode` migration | High | Medium | Tests are explicitly listed in §4. /breakdown sequences test updates with their corresponding source changes. Each task ends with `flutter test` for the affected scope. The terminal task runs the full suite |
| One-time legacy theme-reset surprises a user with existing `int` data (i.e. the developer) | High (1 user affected) | Low | Documented in §3.6. AC-17 verifies graceful behavior. User reselects theme once |
| `theme_preview_screen.dart` `_iconForEffectiveMode` switch becomes non-exhaustive after `AppThemeMode` is 2-value (currently switches on Flutter's 3-value `ThemeMode`) | Med | Low | The presentation layer keeps reading Flutter's `ThemeMode` for the icon decision. The cycle logic re-derives from `(useSystemTheme, manualThemeMode)`. /breakdown will spell this out |
| Bug 011 (DRY selectors) is partially-touched by `theme_selector.dart` updates here, leaving the codebase in an "inconsistently DRY" state until bug 011 is fixed | Med | Low | Scope discipline (§6): touch `theme_selector.dart` only enough to compile under `AppThemeMode`. Do NOT extract helpers in this spec |
| `effectiveLocale`/`effectiveThemeMode` getters are referenced by docs `docs/features/settings.md:25–34` | Low | Low | Doc update is in scope (AC-15); update the Domain section of `settings.md` accordingly |
| Removing `effectiveLocale` getter breaks a consumer outside the listed files | Low | Med | Phase 3 codebase analysis enumerated all consumers via grep on `effectiveLocale|effectiveThemeMode|AppSettings(`. The 15-file list in §2.5 is comprehensive. /breakdown will re-grep before declaring complete |
| Doc-vs-code drift continues if `docs/features/settings.md:25–34` (the `effectiveThemeMode`/`effectiveLocale` code samples) isn't updated to reflect the new `app.dart` seam shape | Med | Low | AC-15 covers the Domain section update; /finalize's tech-writer pass enforces broader doc currency |
