# Task 005: Write feature tests (terminal integration gate)

**Status**: Complete
**Agent**: qa-engineer
**Files**:
- `test/features/settings/data/repositories/settings_repository_impl_test.dart` (MOD)
- `test/features/settings/presentation/providers/settings_provider_test.dart` (MOD)
- `test/features/settings/presentation/screens/settings_screen_test.dart` (MOD)
- `test/features/settings/presentation/widgets/language_selector_test.dart` (NEW)
- `test/widget_test.dart` (MOD)

**Depends on**: 004 (and transitively 001, 002, 003)
**Blocks**: None
**Context docs**: None — patterns are fully established by the existing spec-009 test files
**Review checkpoint**: Yes — terminal integration gate (full `flutter test` + `flutter build apk --debug` runs here)

## Description

Cover every new behaviour with tests, mirroring the patterns established by the existing spec-009 test files. Five test files change in this task — three extensions, one creation, and one extension to the existing app-level test (`widget_test.dart`). All five share the same `_FakeSettingsRepository` shape with two new failure flags (`failOnSaveUseSystemLanguage`, `failOnSaveManualLanguage`) and the two new save methods.

Per project precedent (spec 009 + spec 002 + spec 005 + spec 007), this is the **terminal integration-gate task**: it's the only task whose `Done when` invokes the full `flutter test` + `flutter build apk --debug`. Earlier tasks gated only on `dart analyze` and any feature-scoped tests they added. Putting both gates here means a single pass at the end catches every regression in one place — and avoids spurious "task X broke tests" panics during a feature-wide signature shift.

## Change details

### `test/features/settings/data/repositories/settings_repository_impl_test.dart` — MOD

1. Update every `allowList:` literal (currently `{'themeMode', 'useSystemTheme'}`) to also include `'useSystemLanguage'` and `'manualLanguage'`. There are two such literals — one in `_buildRepository` and one in the persistence-round-trip test.
2. Add a new import: `import 'package:dosly/features/settings/domain/entities/app_language.dart';`.
3. Extend `group('load()')` with cases for the new fields:
   - `'returns useSystemLanguage=true and manualLanguage=en by default'` (with no initial data, asserts both fields).
   - `'returns useSystemLanguage=false after saveUseSystemLanguage(false)'`.
   - `'returns manualLanguage=uk after saveManualLanguage(AppLanguage.uk)'`.
   - `'returns manualLanguage=en when an unknown code (xx) is stored'` (initialise with `{'manualLanguage': 'xx'}` directly via `_buildRepository(initialData: ...)` to exercise the `firstWhere(orElse:)` fallback).
   - `'effectiveLocale is null when useSystemLanguage=true'`.
   - `'effectiveLocale equals Locale("de") when useSystemLanguage=false and manualLanguage=de'`.
4. Add `group('saveUseSystemLanguage()')` with one test asserting `Right(null)` on success.
5. Add `group('saveManualLanguage()')` with one test asserting `Right(null)` on success.
6. Extend the persistence-round-trip group with one test that round-trips `useSystemLanguage` and `manualLanguage` (in addition to the existing theme round-trip).

### `test/features/settings/presentation/providers/settings_provider_test.dart` — MOD

1. Add a new import: `import 'package:dosly/features/settings/domain/entities/app_language.dart';`.
2. Extend `_FakeSettingsRepository` with:
   - Two new flags: `bool failOnSaveUseSystemLanguage = false;` and `bool failOnSaveManualLanguage = false;`.
   - Two new `@override` methods (`saveUseSystemLanguage`, `saveManualLanguage`) following the exact same pattern as `saveThemeMode` (return `Left(CacheFailure(...))` when the flag is set, otherwise mutate the in-memory `_settings` via `copyWith` and return `Right(null)`).
3. Add new tests under `group('SettingsNotifier')`:
   - `'setUseSystemLanguage(false) updates useSystemLanguage to false'`.
   - `'setUseSystemLanguage does not update state when save fails'` (sets `failOnSaveUseSystemLanguage = true` and asserts `useSystemLanguage` is still the default `true`).
   - `'setManualLanguage(AppLanguage.uk) updates manualLanguage to uk'`.
   - `'setManualLanguage does not update state when save fails'`.
   - `'effectiveLocale is null when useSystemLanguage=true'`.
   - `'effectiveLocale equals Locale("de") after setUseSystemLanguage(false) + setManualLanguage(de)'`.

### `test/features/settings/presentation/screens/settings_screen_test.dart` — MOD

1. Add new tests under a new group `group('SettingsScreen language header')`:
   - `'renders uppercased "LANGUAGE" header under Locale("en")'`.
   - `'renders uppercased "МОВА" header under Locale("uk")'`.
   - `'renders uppercased "SPRACHE" header under Locale("de")'`.

   These mirror the existing Appearance-header tests' shape exactly.
2. The existing Appearance-section tests must continue to pass. No changes to the existing `_FakeSettingsRepository`, `_resolveLocale`, or `_harness` helpers (they don't need to know about language settings — the load() defaults cover the visible state for these tests).

### `test/features/settings/presentation/widgets/language_selector_test.dart` — CREATE

Mirror the structure of `theme_selector_test.dart` exactly. Imports must include `package:dosly/features/settings/domain/entities/app_language.dart` and `package:dosly/features/settings/presentation/widgets/language_selector.dart`.

`_FakeSettingsRepository` for this file (similar to the theme selector's fake):

```dart
class _FakeSettingsRepository implements SettingsRepository {
  AppSettings _settings;

  _FakeSettingsRepository({AppSettings? initial})
      : _settings = initial ?? const AppSettings();

  bool get savedUseSystemLanguage => _settings.useSystemLanguage;
  AppLanguage get savedManualLanguage => _settings.manualLanguage;
  // (Plus theme getters/setters mirroring the theme selector's fake — required
  // because SettingsRepository's contract still includes the theme methods.)

  @override
  AppSettings load() => _settings;

  @override
  Future<Either<Never, void>> saveThemeMode(ThemeMode mode) async {
    _settings = _settings.copyWith(manualThemeMode: mode);
    return const Right(null);
  }

  @override
  Future<Either<Never, void>> saveUseSystemTheme(bool value) async {
    _settings = _settings.copyWith(useSystemTheme: value);
    return const Right(null);
  }

  @override
  Future<Either<Never, void>> saveUseSystemLanguage(bool value) async {
    _settings = _settings.copyWith(useSystemLanguage: value);
    return const Right(null);
  }

  @override
  Future<Either<Never, void>> saveManualLanguage(AppLanguage language) async {
    _settings = _settings.copyWith(manualLanguage: language);
    return const Right(null);
  }
}
```

Tests (each group named per the existing theme-selector pattern):

- `group('English labels')`:
  - `'renders SwitchListTile and three radio rows with native names'` — asserts `find.text('Use device language')`, `find.text('Follow your device settings')`, `find.text('English')`, `find.text('Deutsch')`, `find.text('Українська')` each find one widget.
  - `'switch is ON by default (useSystemLanguage=true)'`.
  - `'when useSystemLanguage=true, every RadioListTile has null onChanged (disabled)'` — iterate `find.byType(RadioListTile<AppLanguage>)`, assert each widget's `onChanged == null`.
  - `'when useSystemLanguage=true, groupValue still reflects manualLanguage'`.
  - `'when useSystemLanguage=false, RadioListTiles are enabled (non-null onChanged)'` — pump with `initial: const AppSettings(useSystemLanguage: false)`.
  - `'tapping Deutsch radio when system OFF saves manualLanguage=AppLanguage.de'` — tap `find.text('Deutsch')`, assert `repo.savedManualLanguage == AppLanguage.de`.
  - `'toggling switch OFF saves useSystemLanguage=false and pre-sets manualLanguage from device locale'` — pump with `Locale('uk')`, tap the switch, assert `repo.savedUseSystemLanguage == false` AND `repo.savedManualLanguage == AppLanguage.uk`.
  - `'toggling switch OFF with unsupported device locale defaults manualLanguage to en'` — pump with `Locale('fr')`, tap switch, assert `repo.savedManualLanguage == AppLanguage.en`.
- `group('Native names are not translated')`:
  - `'native names render identically under Locale("uk") and Locale("de")'` — pump with each locale, assert all three native-name strings are still present (proving they are NOT going through `AppLocalizations`).
- `group('Localized switch labels under non-English locales')`:
  - `'renders correct Ukrainian labels under Locale("uk")'` (assert `find.text('Мова пристрою')` and `find.text('Використовувати налаштування пристрою')`).
  - `'renders correct German labels under Locale("de")'` (assert `find.text('Sprache des Geräts verwenden')` and `find.text('Geräteeinstellungen folgen')`).

### `test/widget_test.dart` — MOD

1. Extend `_FakeSettingsRepository` with two flags + two new save methods (same shape as the provider-test fake — see above). Add `bool get savedUseSystemLanguage => _settings.useSystemLanguage;` and `AppLanguage get savedManualLanguage => _settings.manualLanguage;` for assertions.
2. Add a new import: `import 'package:dosly/features/settings/domain/entities/app_language.dart';`.
3. Add a new test group `group('MaterialApp.locale reactivity')`:
   - `'is null by default (useSystemLanguage=true → resolution callback drives locale)'` — pump `DoslyApp` with the default fake; read the inner `MaterialApp` via `find.byType(MaterialApp)` (or `MaterialApp.router` — confirm the actual `Type` after running once); assert `.locale` is null.
   - `'becomes Locale("de") after switching to manual de'` — pump `DoslyApp`; read the `ProviderContainer` via `tester.element(find.byType(DoslyApp))` and call `container.read(settingsProvider.notifier).setUseSystemLanguage(false)` then `setManualLanguage(AppLanguage.de)`; pump and settle; assert `MaterialApp.locale == Locale('de')`.

   **Note**: reading the container in a widget test requires `ProviderScope.containerOf(...)` or fetching from the element tree. The simplest pattern (used by Riverpod's docs): expose the `ProviderScope`'s container via `tester.element(...)` plus `ProviderScope.containerOf`. If the implementation gets fiddly, the alternative is to pre-seed the fake repo with `useSystemLanguage:false, manualLanguage:de` and assert `MaterialApp.locale == Locale('de')` immediately after pump — that proves the wiring without exercising the notifier path. Either approach satisfies AC-12; the implementer chooses based on what reads cleanly.
4. The existing Theme-preview / Hello World / Cycle-theme-mode tests must continue to pass unchanged.

## Done when

- [x] All five test files compile cleanly under `dart analyze test/`.
- [x] `flutter test` passes — every existing test still green AND every new test green.
- [x] `flutter build apk --debug` succeeds.
- [x] The new `language_selector_test.dart` includes assertions for: switch default ON, all radios disabled when system ON, all radios enabled when system OFF, native names render under all three locales, tapping a radio saves the right `AppLanguage`, toggling switch OFF pre-fills `manualLanguage` from device locale (with `en` fallback for unsupported).
- [x] `widget_test.dart`'s new group asserts `MaterialApp.locale` reactivity (default-null and post-toggle non-null cases).
- [x] Total test count grows by at least 18 (rough estimate: 6 repo + 6 provider + 3 screen + ~9 widget + 2 app — actual count may differ, but should be ≥ 18 net new tests).
- [x] Total test count starts from 117 (spec 009 baseline) and ends ≥ 135.

## Spec criteria addressed

AC-11, AC-12, AC-13, AC-14, AC-15, AC-16, AC-17.

## Completion Notes

**Completed**: 2026-04-27
**Files changed**:
- `test/features/settings/data/repositories/settings_repository_impl_test.dart` (MOD — +9 tests)
- `test/features/settings/presentation/providers/settings_provider_test.dart` (MOD — +6 tests)
- `test/features/settings/presentation/screens/settings_screen_test.dart` (MOD — +3 tests)
- `test/features/settings/presentation/widgets/language_selector_test.dart` (NEW — 14 tests)
- `test/widget_test.dart` (MOD — +2 tests)
- `test/core/routing/app_router_test.dart` (MOD — additive: 2 new `@override` no-op stubs to satisfy extended contract)
- `test/features/settings/presentation/widgets/theme_selector_test.dart` (MOD — additive: 2 new `@override` no-op stubs)

**Contract**: Expects 7/7 verified | Produces 7/7 verified

**Verification**:
- `dart analyze` (whole repo): zero issues
- `flutter test`: 168/168 passed (was 117 baseline, +51 net new tests, well above the ≥18 target)
- `flutter build apk --debug`: succeeded (`build/app/outputs/flutter-apk/app-debug.apk`)

**Code review**: APPROVE. Reviewer flagged a `library;` directive as missing but it was actually present — false alarm.

**Notes**:
- Two pre-existing test files (`app_router_test.dart`, `theme_selector_test.dart`) needed additive fixes to their `_FakeSettingsRepository` classes — they were failing to compile after Task 001 extended the abstract `SettingsRepository` contract. Fix is two `@override` no-op stubs each (returning `Right(null)`), matching the existing minimal-fake style. Strictly additive; existing test logic untouched.
- LanguageSelector widget tests use `expect(tile.enabled, isFalse)` for the system-on disabled state, NOT the deprecated `onChanged: null` pattern. Updated per Task 004's `RadioGroup` migration. AC-11's spirit ("when system ON, all radios are non-interactive") is satisfied by the new mechanism.
- `MaterialApp.locale` reactivity test (AC-12) used the simpler pre-seeded-fake approach: `_FakeSettingsRepository(initial: const AppSettings(useSystemLanguage: false, manualLanguage: AppLanguage.de))` then asserts `MaterialApp.locale == const Locale('de')`. Proves the wiring without driving the notifier through a `ProviderContainer`. Spec explicitly allowed this approach.

## Contracts

### Expects
- All Produces from Tasks 001-004.
- Existing test files (`settings_repository_impl_test.dart`, `settings_provider_test.dart`, `settings_screen_test.dart`, `theme_selector_test.dart`, `widget_test.dart`) compile and pass under the spec-009 baseline (current codebase state — 117 tests passing).
- `pub.dev` packages already present in `pubspec.yaml` for tests: `flutter_test`, `mocktail`, `fpdart`, `shared_preferences_platform_interface` (used by `InMemorySharedPreferencesAsync` in repo tests).

### Produces
- `test/features/settings/data/repositories/settings_repository_impl_test.dart` contains: every `allowList:` literal extended to four entries (`'themeMode', 'useSystemTheme', 'useSystemLanguage', 'manualLanguage'`); new tests under `group('load()')` covering the four default/non-default/fallback cases; `group('saveUseSystemLanguage()')` with at least one Right-on-success assertion; `group('saveManualLanguage()')` with at least one Right-on-success assertion; the persistence round-trip extended for the new fields.
- `test/features/settings/presentation/providers/settings_provider_test.dart`'s `_FakeSettingsRepository` declares `failOnSaveUseSystemLanguage`, `failOnSaveManualLanguage`, and `@override` implementations of the two new save methods; new tests cover state-update-on-success and state-unchanged-on-failure for both methods, and the `effectiveLocale` getter.
- `test/features/settings/presentation/screens/settings_screen_test.dart` declares a new `group('SettingsScreen language header')` with three locale-specific tests asserting the uppercased localized header strings.
- `test/features/settings/presentation/widgets/language_selector_test.dart` exists and contains test groups exercising switch default, radio disabled state, tap-to-save, native-name rendering, and pre-fill-on-toggle-OFF.
- `test/widget_test.dart`'s `_FakeSettingsRepository` implements `saveUseSystemLanguage` and `saveManualLanguage`; a new group asserts `MaterialApp.locale` reactivity.
- `flutter test` produces a passing run.
- `flutter build apk --debug` produces a debug APK.
