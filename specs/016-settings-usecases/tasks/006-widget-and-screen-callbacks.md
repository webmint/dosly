# Task 006: Simplify selector callbacks + theme_preview cycle to one-call delegation + adapt widget tests

**Agent**: mobile-engineer
**Files**:
- `lib/features/settings/presentation/widgets/theme_selector.dart` (modify)
- `lib/features/settings/presentation/widgets/language_selector.dart` (modify)
- `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` (modify)
- `test/features/settings/presentation/widgets/theme_selector_test.dart` (modify if needed)
- `test/features/settings/presentation/widgets/language_selector_test.dart` (modify if needed)

**Depends on**: 005
**Blocks**: 007
**Context docs**: `docs/features/settings.md` (ThemeSelector and LanguageSelector subsections)
**Review checkpoint**: Yes — layer boundary (first presentation-layer task) + integration gate

## Description

Three presentation-layer files now consume the new notifier API. The work in each file is a single-callback rewrite:

1. **`theme_selector.dart`**: the `SwitchListTile.onChanged` callback resolves the device brightness once (already done in `build`), and on toggle change makes ONE notifier call `setUseSystemTheme(value, currentDeviceMode: deviceMode)`. The `if (!value) { ... setThemeMode(...) }` block is removed.
2. **`language_selector.dart`**: same shape — the `onChanged` callback resolves the device language once via `AppLanguage.fromLanguageCodeOrDefault(Localizations.localeOf(context).languageCode)`, and makes ONE notifier call `setUseSystemLanguage(value, currentDeviceLanguage: deviceLanguage)`. Both existing `firstWhere(orElse: en)` literals (lines 42 and 65) replaced by the helper. The `if (!value) { ... setManualLanguage(...) }` block is removed.
3. **`theme_preview_screen.dart`**: the cycle `IconButton.onPressed` callback collapses to one line — `ref.read(settingsNotifierProvider.notifier).cycleThemeMode()`. The 14-line `if/else if/else` body is removed.

Widget tests use the existing `_FakeSettingsRepository` and assert on its `savedX` flags. Because the new use cases write through the same repository, `savedManualThemeMode` and `savedUseSystemTheme` end-states are unchanged — most assertions hold without modification. Where a test asserted on a SEQUENCE of fake-repo writes (rare; check during execution), update to assert on the final state only.

This task is the **integration gate** for the spec — full `flutter test` and `flutter build apk --debug` run here.

## Change details

- In `lib/features/settings/presentation/widgets/theme_selector.dart`:
  - Inside `build`, keep the existing `final systemBrightness = MediaQuery.platformBrightnessOf(context);` line.
  - Compute once: `final deviceMode = systemBrightness == Brightness.dark ? AppThemeMode.dark : AppThemeMode.light;` (reuse where `displayedMode` is computed; or extract to a single `final` above the `Column`).
  - Rewrite `SwitchListTile.onChanged` to:
    ```dart
    onChanged: (bool value) {
      ref.read(settingsNotifierProvider.notifier)
          .setUseSystemTheme(value, currentDeviceMode: deviceMode);
    },
    ```
  - Remove the entire `if (!value) { ... setThemeMode(manualMode); }` block.

- In `lib/features/settings/presentation/widgets/language_selector.dart`:
  - Replace BOTH existing `AppLanguage.values.firstWhere(...)` blocks with `AppLanguage.fromLanguageCodeOrDefault(Localizations.localeOf(context).languageCode)`. After this replacement, the file contains zero `firstWhere(orElse: ...)` literals.
  - Reuse the `deviceLanguage` derivation at the top of `build` for both the `displayedLanguage` computation and the new callback (single source of truth).
  - Rewrite `SwitchListTile.onChanged` to:
    ```dart
    onChanged: (bool value) {
      ref.read(settingsNotifierProvider.notifier)
          .setUseSystemLanguage(value, currentDeviceLanguage: deviceLanguage);
    },
    ```
  - Remove the entire `if (!value) { ... setManualLanguage(pre); }` block.

- In `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart`:
  - Rewrite the cycle `IconButton.onPressed` to:
    ```dart
    onPressed: () {
      ref.read(settingsNotifierProvider.notifier).cycleThemeMode();
    },
    ```
  - Remove the 14-line `if (settings.useSystemTheme) { ... } else if (settings.manualThemeMode == AppThemeMode.light) { ... } else { ... }` block.
  - Keep the icon helper `_iconForEffectiveMode` and the `effectiveMode` computation untouched — they still drive the icon.

- In `test/features/settings/presentation/widgets/theme_selector_test.dart` and `language_selector_test.dart`:
  - Run the existing tests after the source edits. If any test fails because it asserted on the OLD two-call sequence, simplify it to assert on the final fake-repo state (`expect(repo.savedManualThemeMode, ...)`, `expect(repo.savedUseSystemTheme, ...)`) instead.
  - If a test was specifically designed to verify "manual write happens BEFORE toggle write" via call-order timing, that invariant is now covered by the use case unit tests (Task 003 AC-4 / AC-6) — drop the widget-level call-order assertion as redundant.
  - **Do not weaken** the user-visible-behavior assertions (toggle visual state, dropdown/segment selection, disabled-when-system-on chrome). Those remain AC-17.

## Done when

- [x] `theme_selector.dart` `onChanged` callback contains exactly one notifier call. No `firstWhere` or `Brightness == dark ? ...` literal in the callback body.
- [x] `language_selector.dart` `onChanged` callback contains exactly one notifier call. `grep -n "firstWhere" lib/features/settings/presentation/widgets/language_selector.dart` returns zero matches.
- [x] `theme_preview_screen.dart` cycle callback contains exactly one notifier call. No `if/else if/else` branching on `useSystemTheme` or `manualThemeMode` remains in the widget body.
- [x] `grep -rnE "AppLanguage\\.values\\.firstWhere" lib/` returns exactly **one** match — inside `AppLanguage.fromLanguageCodeOrDefault` itself.
- [x] `dart analyze` exits 0 over the entire workspace.
- [x] `flutter test` exits 0 over the entire workspace.
- [x] `flutter build apk --debug` exits 0.
- [ ] Toggling "Use system theme" OFF in a manual smoke test pre-fills the manual segment with the current system brightness; toggling "Use device language" OFF pre-fills the manual dropdown with the device-resolved language. (Manual smoke test deferred to `/verify` if no simulator is attached.)

## Spec criteria addressed

AC-9, AC-10, AC-11, AC-13, AC-14, AC-15, AC-16, AC-17 (the user-visible-behaviour preservation), AC-18 (failure surface verified end-to-end via the integration gate).

## Completion Notes

**Status**: Complete
**Completed**: 2026-05-10
**Files changed**:
- `lib/features/settings/presentation/widgets/theme_selector.dart` — `deviceMode` hoisted to `build`-scope; `onChanged` collapsed to 3 lines; pre-fill if-block removed
- `lib/features/settings/presentation/widgets/language_selector.dart` — both `firstWhere` literals replaced by `AppLanguage.fromLanguageCodeOrDefault`; `deviceLanguage` hoisted; `onChanged` collapsed to 3 lines
- `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` — 11-line cycle `if/else if/else` replaced with 2-line `cycleThemeMode()` call; `_iconForEffectiveMode` and `effectiveMode` ternary preserved (display-only)

**Contract**: Expects 5/5 verified | Produces 5/5 verified

**Notes**:
- Code review verdict: APPROVE (zero findings).
- **Integration gate green**: `dart analyze` 0 issues · `flutter test` 227/227 pass · `flutter build apk --debug` succeeded (12.9s).
- ZERO test files modified — existing widget tests use `_FakeSettingsRepository.savedX` flags and assert end-state, which is identical under the new atomic-use-case path.
- AC-13 verified: exactly ONE `AppLanguage.values.firstWhere` literal remains in the codebase (inside the helper).
- AC-17 (user-visible behavior) deferred to `/verify` for manual smoke since the sandbox cannot drive simulators; widget test coverage exercises every assertion-able invariant.

## Contracts

### Expects
- `SettingsNotifier.setUseSystemTheme(bool, {required AppThemeMode currentDeviceMode})` exists (from Task 005).
- `SettingsNotifier.setUseSystemLanguage(bool, {required AppLanguage currentDeviceLanguage})` exists (from Task 005).
- `SettingsNotifier.cycleThemeMode()` exists as `Future<void>` (from Task 005).
- `AppLanguage.fromLanguageCodeOrDefault(String)` exists (from Task 001).
- All use case providers wired (from Task 005); `settings_provider.g.dart` is up to date.

### Produces
- `theme_selector.dart`'s `SwitchListTile.onChanged` body invokes exactly one notifier method call with two named arguments matching the new signature.
- `language_selector.dart` contains zero occurrences of `firstWhere`. Both device-language derivations route through `AppLanguage.fromLanguageCodeOrDefault`.
- `theme_preview_screen.dart` invokes `cycleThemeMode()` and contains zero `if/else if` chains on `useSystemTheme`/`manualThemeMode` outside the still-present `effectiveMode` ternary (which is display-only, not branching on cycle logic).
- Full integration gate green: `dart analyze`, `flutter test`, `flutter build apk --debug` all exit 0.
