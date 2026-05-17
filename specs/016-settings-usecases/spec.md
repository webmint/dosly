# Spec: Settings feature — introduce `domain/usecases/`

**Date**: 2026-05-09
**Status**: Complete
**Author**: Claude + Webmint

## 1. Overview

Introduce a `lib/features/settings/domain/usecases/` layer that mediates every mutation between `SettingsNotifier` and `SettingsRepository`. Move the cross-cutting "switch-to-manual must pre-fill from device" rule out of the two selector widgets and into the relevant use cases as an atomic operation. As part of the same pass, absorb the triplicated `AppLanguage.values.firstWhere(orElse: en)` literal into a single `AppLanguage.fromLanguageCodeOrDefault` static helper, and extract the `theme_preview_screen.dart` cycle logic into a use case so no presentation-layer file owns Settings business rules. Closes **bug 005** and **bug 011**.

Background research: [`research/2026-05-09-bug-005-settings-usecases.md`](../../research/2026-05-09-bug-005-settings-usecases.md).

## 2. Current State

### 2.1 Settings notifier calls the repository directly (bug 005)

`lib/features/settings/presentation/providers/settings_provider.dart:65–121` exposes four mutators (`setThemeMode`, `setUseSystemTheme`, `setUseSystemLanguage`, `setManualLanguage`). Each one reaches into `ref.read(settingsRepositoryProvider)` and folds the resulting `Either` directly:

```dart
Future<void> setThemeMode(AppThemeMode mode) async {
  final repo = ref.read(settingsRepositoryProvider);
  final result = await repo.saveThemeMode(mode);
  result.fold(
    (failure) => _errors.add(failure),
    (_) => state = state.copyWith(manualThemeMode: mode),
  );
}
```

This violates **constitution §2.1** ("`usecases/` — single-purpose callable classes; one operation per class") and **§4.1.1** ("Screens never call repositories directly"). No `lib/features/settings/domain/usecases/` directory exists.

### 2.2 Pre-fill rule duplicated across widgets (bug 005 + bug 011)

The cross-cutting rule "when the user toggles 'use system X' from ON to OFF, the manual override must be pre-filled with the value the system was just resolving so the visible UI doesn't lurch" is currently expressed in two places:

- `lib/features/settings/presentation/widgets/theme_selector.dart:55–66` — pre-fills `manualThemeMode` from `MediaQuery.platformBrightnessOf(context)` before persisting `useSystemTheme=false`.
- `lib/features/settings/presentation/widgets/language_selector.dart:60–72` — pre-fills `manualLanguage` from `Localizations.localeOf(context).languageCode` before persisting `useSystemLanguage=false`.

Both call sites issue **two separate notifier writes** (one for the manual override, one for the toggle). The rule lives in the widget — exactly the layer the constitution forbids business logic from inhabiting.

### 2.3 `AppLanguage.values.firstWhere(orElse: en)` triplicated (bug 011)

The same `firstWhere` literal appears in three files:

- `lib/features/settings/presentation/widgets/language_selector.dart:42–45` (in `build`, deriving the displayed language while system mode is on)
- `lib/features/settings/presentation/widgets/language_selector.dart:65–68` (in the toggle callback, pre-filling)
- `lib/features/settings/data/datasources/settings_local_data_source.dart:81–84` (in `getManualLanguage()`, parsing the persisted code)

Three occurrences crosses the **constitution §3.6 DRY threshold**. The same shape is already captured for `AppThemeMode` via `AppThemeMode.fromCodeOrDefault` (post-bug-001) — the asymmetry is purely missing.

### 2.4 Theme cycle rule in `theme_preview_screen.dart` (bug 011)

`lib/features/theme_preview/presentation/screens/theme_preview_screen.dart:52–66` orchestrates a `system → light → dark → system` cycle by calling two notifier methods inline depending on current state. This is dev-only code (the screen is scheduled for removal per `specs/002-main-screen` §6) but the rule is still business logic in a presentation file.

### 2.5 Already in place (no work needed)

- `@riverpod` codegen pipeline (closed by bug 004 / spec 015).
- `AppThemeMode` pure-Dart enum with `fromCodeOrDefault` (closed by bug 001 / spec 012).
- `AppSettings` `freezed` entity + `==`/`hashCode` (closed by bug 001 / spec 012).
- `SettingsRepository` returning `Future<Either<Failure, void>>` for all save operations.
- `SettingsNotifier._errors` broadcast `StreamController<Failure>` + `settingsErrorsProvider` (closed by bug 003 / spec 014).
- `SettingsScreen` `ref.listen` SnackBar surface for failures (spec 014).

## 3. Desired Behavior

### 3.1 Use case layer

Create `lib/features/settings/domain/usecases/` with **five callable classes**, each in its own file (constitution §2.2 "one public type per file"):

1. **`SetThemeMode`** (`set_theme_mode.dart`)
   - `Future<Either<Failure, void>> call(AppThemeMode mode)`
   - Persists the manual theme mode via `SettingsRepository.saveThemeMode`. No additional logic.

2. **`SetUseSystemTheme`** (`set_use_system_theme.dart`)
   - `Future<Either<Failure, void>> call({required bool value, required AppThemeMode currentDeviceMode})`
   - **Atomic**: when `value` is `false`, persists `currentDeviceMode` as the manual override **first**, then persists `useSystemTheme=false`. When `value` is `true`, persists `useSystemTheme=true` only. On any inner Left, returns the first Left and skips the remaining write.
   - Caller always passes `currentDeviceMode` (the resolved `AppThemeMode` derived from `MediaQuery.platformBrightnessOf` at the call site). Required, not optional — the use case does not "know" whether the caller is toggling on or off until invocation time, so the parameter is always supplied.

3. **`SetUseSystemLanguage`** (`set_use_system_language.dart`)
   - `Future<Either<Failure, void>> call({required bool value, required AppLanguage currentDeviceLanguage})`
   - **Atomic**: when `value` is `false`, persists `currentDeviceLanguage` as the manual override **first**, then persists `useSystemLanguage=false`. When `value` is `true`, persists `useSystemLanguage=true` only. Failure semantics identical to `SetUseSystemTheme`.

4. **`SetManualLanguage`** (`set_manual_language.dart`)
   - `Future<Either<Failure, void>> call(AppLanguage language)`
   - Persists the manual language via `SettingsRepository.saveManualLanguage`. No additional logic.

5. **`CycleThemeMode`** (`cycle_theme_mode.dart`)
   - `Future<Either<Failure, void>> call({required bool currentUseSystemTheme, required AppThemeMode currentManualMode})`
   - Encodes the `system → light → dark → system` cycle. Returns the first Left if any inner write fails.

Each use case is a callable `class` with a `const` constructor taking `SettingsRepository` (constitution §2.1 use case shape; mirrors the `AddMedication` example in constitution §7).

### 3.2 Use case providers

For each use case, expose a `@riverpod` function provider in `lib/features/settings/presentation/providers/settings_provider.dart`:

```dart
@riverpod
SetThemeMode setThemeMode(Ref ref) =>
    SetThemeMode(ref.watch(settingsRepositoryProvider));
```

Five new providers: `setThemeModeProvider`, `setUseSystemThemeProvider`, `setUseSystemLanguageProvider`, `setManualLanguageProvider`, `cycleThemeModeProvider`. Same file as the existing `settingsRepositoryProvider`, `settingsNotifierProvider`, `settingsErrorsProvider`.

### 3.3 Notifier rewrite

`SettingsNotifier`'s four mutators delegate exclusively to use case providers. The repository is no longer read from the notifier:

```dart
Future<void> setThemeMode(AppThemeMode mode) async {
  final result = await ref.read(setThemeModeProvider).call(mode);
  result.fold(
    (failure) => _errors.add(failure),
    (_) => state = state.copyWith(manualThemeMode: mode),
  );
}
```

The four notifier methods retain their existing public signatures (`Future<void>`, same parameter list — except `setUseSystemTheme` and `setUseSystemLanguage` gain a `currentDeviceMode` / `currentDeviceLanguage` required parameter so the widget's resolved device value can flow through). Optimistic-state and error-stream semantics are preserved bit-for-bit.

### 3.4 Widget callbacks simplify

`theme_selector.dart` and `language_selector.dart` callbacks shrink to a **single notifier call**:

```dart
// theme_selector.dart
onChanged: (bool value) {
  final deviceMode = systemBrightness == Brightness.dark
      ? AppThemeMode.dark
      : AppThemeMode.light;
  ref.read(settingsNotifierProvider.notifier)
      .setUseSystemTheme(value, currentDeviceMode: deviceMode);
}
```

```dart
// language_selector.dart
onChanged: (bool value) {
  final deviceLanguage = AppLanguage.fromLanguageCodeOrDefault(
    Localizations.localeOf(context).languageCode,
  );
  ref.read(settingsNotifierProvider.notifier)
      .setUseSystemLanguage(value, currentDeviceLanguage: deviceLanguage);
}
```

The pre-fill rule no longer appears in any presentation file. The widget's only responsibility is to **resolve** the Flutter-typed device value (`Brightness` / `Locale`) into a domain-typed value (`AppThemeMode` / `AppLanguage`) and forward it.

### 3.5 `AppLanguage.fromLanguageCodeOrDefault` helper

Add a static factory to `lib/features/settings/domain/entities/app_language.dart`:

```dart
/// Resolves [code] (a 2-letter IETF code) to the matching [AppLanguage],
/// falling back to [AppLanguage.en] when no entry matches. Mirrors the
/// existing [AppThemeMode.fromCodeOrDefault] shape.
static AppLanguage fromLanguageCodeOrDefault(String code) =>
    AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.en,
    );
```

All three current `firstWhere(orElse: en)` call sites migrate to it:

- `language_selector.dart:42` (displayed-language derivation when system is on)
- `language_selector.dart:65` (now removed entirely — folded into the use case + the helper for the device-language resolution at the call site)
- `settings_local_data_source.dart:81` (parsing the persisted code in `getManualLanguage`)

After the migration, the `firstWhere` literal appears exactly **once** in the codebase — inside `fromLanguageCodeOrDefault` itself.

### 3.6 `theme_preview_screen.dart` cycle delegation

The cycle `IconButton.onPressed` callback collapses to a single use case call:

```dart
onPressed: () {
  ref.read(cycleThemeModeProvider).call(
    currentUseSystemTheme: settings.useSystemTheme,
    currentManualMode: settings.manualThemeMode,
  );
}
```

The notifier does not gain a `cycleThemeMode` method — the screen consumes the use case provider directly because the cycle output cannot be reduced to a single `state.copyWith(...)` call (it may toggle both fields). The use case writes through the repository; the notifier's existing watchers re-emit on each underlying repository-backed state change. **Implementation note**: since the notifier's state shape currently advances only via its own `state = state.copyWith(...)` calls in mutators, the cycle use case must dispatch through the **notifier's mutators** (not raw repository writes) so the in-memory state stays in sync. Concretely, `CycleThemeMode` is constructed with both the `SettingsRepository` and a callback that reads the `SettingsNotifier` (or, more cleanly: `theme_preview_screen.dart` continues to call notifier mutators sequentially inside the use case orchestration). The exact wiring is settled in `/plan`; what this spec contracts is that **no presentation file orchestrates the cycle's branch logic**.

### 3.7 Tests

- **New unit tests** for each of the five use cases under `test/features/settings/domain/usecases/`. Each use case test covers happy path + at least one repository failure (constitution §6.2: "Every use case has unit tests covering happy path, validation failure, and at least one repository failure").
- **New unit tests** for `AppLanguage.fromLanguageCodeOrDefault` under the existing `test/features/settings/domain/entities/app_language_test.dart` (or create the file if missing).
- **Existing widget tests** for `ThemeSelector`, `LanguageSelector`, `SettingsScreen`, `SettingsNotifier` continue to pass with at most minimal adaptation to the notifier signature (`setUseSystemTheme(bool, {AppThemeMode currentDeviceMode})` and `setUseSystemLanguage(bool, {AppLanguage currentDeviceLanguage})`).
- **Existing repository test** continues to pass unchanged.
- **Existing data-source test** continues to pass; if it asserted on the `firstWhere` shape directly, update to assert on the helper's behaviour.

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Domain — use cases (new) | `lib/features/settings/domain/usecases/set_theme_mode.dart` | Create new |
| Domain — use cases (new) | `lib/features/settings/domain/usecases/set_use_system_theme.dart` | Create new |
| Domain — use cases (new) | `lib/features/settings/domain/usecases/set_use_system_language.dart` | Create new |
| Domain — use cases (new) | `lib/features/settings/domain/usecases/set_manual_language.dart` | Create new |
| Domain — use cases (new) | `lib/features/settings/domain/usecases/cycle_theme_mode.dart` | Create new |
| Domain — entity helper | `lib/features/settings/domain/entities/app_language.dart` | Add `fromLanguageCodeOrDefault` static factory |
| Data — data source | `lib/features/settings/data/datasources/settings_local_data_source.dart` | Replace `firstWhere` literal in `getManualLanguage` with `AppLanguage.fromLanguageCodeOrDefault` |
| Presentation — providers | `lib/features/settings/presentation/providers/settings_provider.dart` | Add 5 use case `@riverpod` providers; rewrite the 4 notifier mutators to delegate to use cases instead of repository |
| Presentation — widgets | `lib/features/settings/presentation/widgets/theme_selector.dart` | Toggle callback shrinks to one notifier call; widget continues to compute `Brightness → AppThemeMode` for the parameter |
| Presentation — widgets | `lib/features/settings/presentation/widgets/language_selector.dart` | Toggle callback shrinks to one notifier call; both `firstWhere` sites replaced by `AppLanguage.fromLanguageCodeOrDefault` |
| Presentation — screens (dev-only) | `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` | Cycle callback delegates to `CycleThemeMode` use case |
| Tests — domain (new) | `test/features/settings/domain/usecases/*_test.dart` | Create 5 use case test files (happy path + repository failure each) |
| Tests — domain (existing) | `test/features/settings/domain/entities/app_language_test.dart` | Add `fromLanguageCodeOrDefault` cases (or create file) |
| Tests — presentation (existing) | `test/features/settings/presentation/providers/settings_provider_test.dart` | Update fakes to wire the new use case providers; assert delegation |
| Tests — presentation (existing) | `test/features/settings/presentation/widgets/theme_selector_test.dart`, `language_selector_test.dart` | Adapt to the new single-call notifier signature; assert pre-fill rule moved (no longer asserted at widget level — moves to use case test) |
| Docs | `docs/features/settings.md` | Update `Presentation`, `ThemeSelector`, `LanguageSelector` sections to describe the use case layer; note the helper |
| Bugs | `bugs/005-settings-feature-missing-usecases.md`, `bugs/011-business-rule-duplicated-selectors.md` | Status: Open → Closed; Fixed: 2026-05-10 |

## 5. Acceptance Criteria

- [x] **AC-1**: `lib/features/settings/domain/usecases/` directory exists and contains exactly five files: `set_theme_mode.dart`, `set_use_system_theme.dart`, `set_use_system_language.dart`, `set_manual_language.dart`, `cycle_theme_mode.dart`.
- [x] **AC-2**: Every file under `lib/features/settings/domain/usecases/` imports only from `package:fpdart/fpdart.dart`, `dart:async`, `dart:core`, `package:meta/*`, `../entities/*`, `../repositories/*`, and `../../../../core/error/*`. **No** `package:flutter/*`, `package:flutter_riverpod/*`, or `package:drift/*` imports — verified by `grep -rE "package:(flutter|flutter_riverpod|drift)" lib/features/settings/domain/usecases/` returning empty.
- [x] **AC-3**: Every use case class is callable (`Future<Either<Failure, void>> call(...)`) and is constructed with a `const` constructor taking exactly one positional `SettingsRepository` parameter.
- [x] **AC-4**: `SetUseSystemTheme.call(value: false, currentDeviceMode: X)` issues exactly two repository calls in order — first `saveThemeMode(X)`, then `saveUseSystemTheme(false)` — and short-circuits with the first Left if any call fails. Verified by a unit test using a mock repository.
- [x] **AC-5**: `SetUseSystemTheme.call(value: true, currentDeviceMode: X)` issues exactly one repository call — `saveUseSystemTheme(true)` — and never touches `saveThemeMode`. Verified by a unit test.
- [x] **AC-6**: `SetUseSystemLanguage` exhibits the symmetric behaviour described in AC-4 / AC-5 with `saveManualLanguage` and `saveUseSystemLanguage`. Verified by unit tests.
- [x] **AC-7**: `CycleThemeMode` produces the cycle `system → light → dark → system` for the three input states `(true, *)`, `(false, light)`, `(false, dark)` respectively. Each transition is verified by a unit test.
- [x] **AC-8**: `SettingsNotifier`'s four mutator methods reach the repository **only** via use case providers — `grep -nE "settingsRepositoryProvider" lib/features/settings/presentation/providers/settings_provider.dart` returns exactly **one** match (the existing `settingsRepository` provider declaration), and `grep -nE "ref\\.read\\(settingsRepositoryProvider\\)" lib/features/settings/presentation/providers/settings_provider.dart` returns **zero** matches.
- [x] **AC-9**: `theme_selector.dart`'s toggle `onChanged` callback contains exactly one notifier method call (the use case orchestration is invisible to the widget). The pre-fill `firstWhere`/`Brightness == dark ? dark : light` literal that previously lived in the callback (lines 55–66) is gone. Verified by reading the file.
- [x] **AC-10**: `language_selector.dart`'s toggle `onChanged` callback contains exactly one notifier method call. The pre-fill `firstWhere(orElse: en)` literal that previously lived in the callback (lines 60–72) is gone. Verified by reading the file.
- [x] **AC-11**: `theme_preview_screen.dart`'s cycle `IconButton.onPressed` callback contains exactly one use case call — no `if/else` branching on `useSystemTheme` or `manualThemeMode` remains in the widget body.
- [x] **AC-12**: `AppLanguage.fromLanguageCodeOrDefault(String)` exists, returns `AppLanguage.en` for unknown codes, and matches the `code` field for known codes (`'en'` → `en`, `'de'` → `de`, `'uk'` → `uk`). Verified by a unit test covering all three known codes plus at least one unknown (`'xx'`) and the empty string.
- [x] **AC-13**: `grep -rnE "AppLanguage\\.values\\.firstWhere" lib/` returns exactly **one** match — inside `AppLanguage.fromLanguageCodeOrDefault` itself.
- [x] **AC-14**: `dart analyze` exits 0 with no warnings or errors after all changes.
- [x] **AC-15**: `flutter test` passes — including the five new use case test files, the existing `app_language_test.dart` with new cases, and all existing widget/screen/provider/repository tests after their adaptations.
- [x] **AC-16**: `flutter build apk --debug` exits 0.
- [x] **AC-17**: User-visible behaviour is identical: toggling "Use system theme" OFF still pre-fills the manual segment with the current system brightness; toggling "Use device language" OFF still pre-fills the manual dropdown with the device-resolved language; both system-on states still display the device-resolved value as a disabled selection. Verified by the existing widget tests (which continue to assert these invariants) plus a manual smoke run on iOS or Android simulator.
- [x] **AC-18**: Persistence-failure surface is unchanged — when any inner repository write returns `Left(CacheFailure)`, the failure is forwarded to `settingsErrorsProvider` and surfaces as the existing localized SnackBar. Verified by adapting the existing `settings_provider_test.dart` failure-emission tests.
- [x] **AC-19**: `bugs/005-settings-feature-missing-usecases.md` and `bugs/011-business-rule-duplicated-selectors.md` both have `**Status**: Closed` and `**Fixed**: 2026-05-10`.
- [x] **AC-20**: `docs/features/settings.md` describes the use case layer in the Presentation section, references the five use case files, and the `ThemeSelector` / `LanguageSelector` subsections no longer show the pre-fill code blocks (those move out of widget code per the spec).

## 6. Out of Scope

- **NOT included**: bug 002 (`debugPrint` in settings provider — already closed by spec 013), bug 003 (silent error swallowing — closed by spec 014), bug 004 (manual providers — closed by spec 015), bug 001 (domain Flutter contamination — closed by spec 012), bug 006 (Failure hierarchy completion).
- **NOT included**: bug 007–010, 012–017 — none of these touch the Settings use case layer or the duplicated rule.
- **NOT included**: deleting the `theme_preview` feature. The cycle use case is added in this spec, but the screen continues to exist; its removal is tracked by `specs/002-main-screen` §6 / §8.
- **NOT included**: changes to persisted format. The four `SharedPreferences` keys (`themeMode`, `useSystemTheme`, `useSystemLanguage`, `manualLanguage`) and their value types are untouched.
- **NOT included**: changes to the `AppSettings` entity, `AppThemeMode` enum, or `AppLanguage` enum's existing fields. Only an additive static factory on `AppLanguage`.
- **NOT included**: changes to `MaterialApp.themeMode` / `MaterialApp.locale` derivation in `lib/app.dart`. The existing four `select` watches keep working unchanged.
- **NOT included**: changes to `SettingsRepository` interface or `SettingsRepositoryImpl`. The contract is exactly satisfied as-is.
- **NOT included**: changes to localized strings (`l10n/*.arb`). The new use case layer has no user-facing strings.
- **NOT included**: changes to the SnackBar wiring or `settingsErrorsProvider`. They remain the failure-surface as established by spec 014.
- **NOT included**: introduction of `value_objects/`, `mappers/`, or any other new architectural layer beyond `usecases/`.

## 7. Technical Constraints

- **Must follow**: Clean Architecture per constitution §2.1 — use cases are domain-layer-only and pure Dart.
- **Must follow**: Constitution §3.6 DRY threshold — `AppLanguage.values.firstWhere` literal must end up in exactly one place after this spec.
- **Must follow**: Constitution §6.2 use case test coverage — happy path + at least one repository failure per use case.
- **Must use**: `@riverpod` codegen for new providers (per project's bug 004 / spec 015 standard).
- **Must use**: `Either<Failure, void>` return type for all use cases (constitution §4.1).
- **Must use**: `mocktail` for repository mocking in use case tests (project standard).
- **Must not**: introduce any `package:flutter/*` import inside `lib/features/settings/domain/`.
- **Must not**: change the public signature of `SettingsRepository` or any of its methods.
- **Must not**: change the persisted shape of any `SharedPreferences` key.
- **Must not**: introduce a new `Failure` subclass — `CacheFailure` remains the only persistence-layer Failure (bug 006 stays out of scope).
- **Must not**: use `// ignore_for_file: ...` lint suppression as a workaround (MEMORY.md Feature 010 lesson — migrate the API instead).

## 8. Open Questions

- **Q1**: `CycleThemeMode` wiring detail — does it (a) take `SettingsRepository` directly and write through it (the in-memory notifier state then re-loads on next `state.copyWith`-trigger, which is fragile), or (b) take a `SettingsNotifier`-facing callback / closure so it dispatches through the notifier's mutators (preserves optimistic state pattern)? Spec §3.6 prescribes "no presentation file orchestrates the cycle's branch logic" — the wiring choice that achieves this most cleanly is settled in `/plan`.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Notifier signature change (`setUseSystemTheme(bool)` → `setUseSystemTheme(bool, {AppThemeMode currentDeviceMode})`) breaks consumers | Medium | Low | Only two consumers — `theme_selector.dart` and `theme_preview_screen.dart`. Both are rewritten in this spec. `dart analyze` will flag any missed call site. |
| `CycleThemeMode` wiring inadvertently bypasses the notifier's optimistic-state path, leaving in-memory state stale until a rebuild | Medium | Medium | Resolved in `/plan`. AC-7 explicitly verifies the cycle's behaviour end-to-end via a unit test on the use case + a smoke test of the theme_preview screen flow. |
| Existing widget tests assert on the old two-call notifier sequence and break | Low | Low | Tests are adapted as part of this spec. Adaptation is mechanical (single `verify(...)` call for the orchestrated mutator instead of two). |
| Use case test fakes drift from the repository's real shape | Low | Low | Repository contract is unchanged; existing `MockSettingsRepository` (or equivalent) used in `settings_provider_test.dart` is reusable verbatim. |
| `theme_preview` cycle use case adds churn to a soon-to-be-deleted screen | Medium | Low | The use case is small (~20 lines). When `theme_preview` is eventually deleted, the use case can be deleted alongside it. Net: closes bug 011 today, costs one file at deletion time. |
| Symmetric atomicity (`SetUseSystem*`'s two-write order) is reversed by accident, leaving `manualX` updated but `useSystemX` stuck on `true` | Low | Medium | Order is part of the use case contract; AC-4 and AC-6 explicitly verify "first manual override, then toggle" with a `verifyInOrder` assertion in the unit test. |
