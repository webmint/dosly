# Task 005: Wire use case providers + rewrite `SettingsNotifier` mutators + adapt notifier test

**Agent**: architect
**Files**:
- `lib/features/settings/presentation/providers/settings_provider.dart` (modify)
- `lib/features/settings/presentation/providers/settings_provider.g.dart` (regenerate via `dart run build_runner build --delete-conflicting-outputs`)
- `test/features/settings/presentation/providers/settings_provider_test.dart` (modify)

**Depends on**: 001, 002, 003, 004
**Blocks**: 006
**Context docs**: `docs/features/settings.md` (Presentation section), `docs/architecture.md` (use case pattern)
**Review checkpoint**: Yes — convergence on Tasks 001–004 + first cross-layer integration

## Description

Add five `@riverpod` function providers that wire each use case to its `SettingsRepository`. Rewrite the four existing `SettingsNotifier` mutators to delegate exclusively through these providers — `ref.read(settingsRepositoryProvider)` is removed from all four mutator bodies. Two mutators (`setUseSystemTheme`, `setUseSystemLanguage`) gain a `required` named parameter (`currentDeviceMode` / `currentDeviceLanguage`) carrying the resolved device value the widgets supply. Add a new `cycleThemeMode()` notifier method that delegates to `cycleThemeModeProvider`, folds its `Either`, and on `Right` applies `state.copyWith(useSystemTheme: ..., manualThemeMode: ...)` from the returned record.

Adapt `settings_provider_test.dart` to (a) supply the new device-value parameters wherever `setUseSystemTheme(false)` / `setUseSystemLanguage(false)` previously appeared and (b) add a new `cycleThemeMode()` test group covering at least one transition + one failure-forwarding case. The existing `_FakeSettingsRepository` stays as-is — use cases write through it the same way the old mutators did.

## Change details

- In `lib/features/settings/presentation/providers/settings_provider.dart`:
  - Add imports for the five use case classes from `../../domain/usecases/`.
  - Add five `@riverpod` function providers at the file's top level (after `settingsRepositoryProvider`, before `SettingsNotifier`):

    ```dart
    @riverpod
    SetThemeMode setThemeMode(Ref ref) =>
        SetThemeMode(ref.watch(settingsRepositoryProvider));

    @riverpod
    SetUseSystemTheme setUseSystemTheme(Ref ref) =>
        SetUseSystemTheme(ref.watch(settingsRepositoryProvider));

    @riverpod
    SetUseSystemLanguage setUseSystemLanguage(Ref ref) =>
        SetUseSystemLanguage(ref.watch(settingsRepositoryProvider));

    @riverpod
    SetManualLanguage setManualLanguage(Ref ref) =>
        SetManualLanguage(ref.watch(settingsRepositoryProvider));

    @riverpod
    CycleThemeMode cycleThemeMode(Ref ref) =>
        CycleThemeMode(ref.watch(settingsRepositoryProvider));
    ```

    These are function-form providers — codegen emits `setThemeModeProvider`, etc. No `name:` annotation needed (the suffix-stripping rule from spec 015 applies only to class-form notifiers).

  - **Important — provider name collision**: the new function providers (`setThemeMode`, `setUseSystemTheme`, `setUseSystemLanguage`, `setManualLanguage`) collide in name with the notifier methods of the same names. Codegen will produce `setThemeModeProvider` etc., which is fine. But the function NAMES themselves collide with each other only at their declaration sites. Since `SettingsNotifier`'s methods are *instance methods* (accessed as `notifier.setThemeMode(...)`) and the providers are *top-level functions*, they live in different namespaces and do not actually conflict at use sites. Nothing to disambiguate, but reviewers may flinch at the visual repetition — keep going; it's correct.

  - Rewrite each notifier mutator. Example for `setThemeMode`:

    ```dart
    Future<void> setThemeMode(AppThemeMode mode) async {
      final result = await ref.read(setThemeModeProvider).call(mode);
      result.fold(
        (failure) => _errors.add(failure),
        (_) {
          state = state.copyWith(manualThemeMode: mode);
        },
      );
    }
    ```

  - For `setUseSystemTheme` and `setUseSystemLanguage`, change the signature to:

    ```dart
    Future<void> setUseSystemTheme(bool value, {required AppThemeMode currentDeviceMode}) async {
      final result = await ref.read(setUseSystemThemeProvider).call(
        value: value,
        currentDeviceMode: currentDeviceMode,
      );
      result.fold(
        (failure) => _errors.add(failure),
        (_) {
          if (!value) {
            state = state.copyWith(
              manualThemeMode: currentDeviceMode,
              useSystemTheme: false,
            );
          } else {
            state = state.copyWith(useSystemTheme: true);
          }
        },
      );
    }
    ```

    Symmetric for `setUseSystemLanguage` with `currentDeviceLanguage`/`AppLanguage`/`manualLanguage`/`useSystemLanguage`.

  - Add the new `cycleThemeMode()` method:

    ```dart
    Future<void> cycleThemeMode() async {
      final result = await ref.read(cycleThemeModeProvider).call(
        currentUseSystemTheme: state.useSystemTheme,
        currentManualMode: state.manualThemeMode,
      );
      result.fold(
        (failure) => _errors.add(failure),
        (next) {
          state = state.copyWith(
            useSystemTheme: next.useSystemTheme,
            manualThemeMode: next.manualThemeMode,
          );
        },
      );
    }
    ```

  - The `setManualLanguage` mutator's body retains the same `state.copyWith(manualLanguage: language)` on success.

- In `lib/features/settings/presentation/providers/settings_provider.g.dart`:
  - Regenerate with `dart run build_runner build --delete-conflicting-outputs` after the source edits.

- In `test/features/settings/presentation/providers/settings_provider_test.dart`:
  - Update every `setUseSystemTheme(value)` call to `setUseSystemTheme(value, currentDeviceMode: AppThemeMode.light)` (or `.dark`, depending on what the test was simulating).
  - Update every `setUseSystemLanguage(value)` call to `setUseSystemLanguage(value, currentDeviceLanguage: AppLanguage.en)` (or `.de`/`.uk`).
  - Existing tests: when `value=false`, the assertion shape should now ALSO verify the manual override was pre-filled in the fake repo (`expect(repo.savedManualThemeMode, AppThemeMode.dark)` for example). If any existing test asserted on the OLD two-call shape (manual write then toggle), that's now atomic and the assertion folds into one — but the fake repo's saved-state remains the same, so end-state assertions hold.
  - Add a new `group('cycleThemeMode', () { ... })`:
    - Test 1: `'cycles system on → manual light: state has useSystemTheme=false, manualThemeMode=light'` (start with default state, call once, verify).
    - Test 2: `'failure during cycle is forwarded to settingsErrorsProvider'` — flip the fake repo's `failOnSaveThemeMode` and verify the error stream emits.

## Done when

- [x] `grep -nE "settingsRepositoryProvider" lib/features/settings/presentation/providers/settings_provider.dart` returns exactly **one** match (the existing `@riverpod SettingsRepository settingsRepository(Ref ref) {...}` declaration). Specifically, `grep -nE "ref\\.read\\(settingsRepositoryProvider\\)" lib/features/settings/presentation/providers/settings_provider.dart` returns **zero** matches.
- [x] All five new use case providers exist: `setThemeModeProvider`, `setUseSystemThemeProvider`, `setUseSystemLanguageProvider`, `setManualLanguageProvider`, `cycleThemeModeProvider`.
- [x] `SettingsNotifier` exposes a `cycleThemeMode()` method returning `Future<void>`.
- [x] `SettingsNotifier.setUseSystemTheme` and `SettingsNotifier.setUseSystemLanguage` have the new `{required ... current...}` named parameters.
- [x] `settings_provider.g.dart` is regenerated and `dart analyze` exits 0 over both source and generated files.
- [x] All existing `settings_provider_test.dart` tests pass with the adapted call signatures.
- [x] New `cycleThemeMode` test group passes (≥ 1 transition + 1 failure-forwarding case).
- [x] `flutter test test/features/settings/presentation/providers/settings_provider_test.dart` passes.
- [x] Failure-stream semantics unchanged: `_errors.add(failure)` is still the `Left` branch of every mutator's `fold`.

## Spec criteria addressed

AC-8, AC-18 (and pre-confirms AC-2 + AC-3 + AC-7 by exercising the use case providers end-to-end at the notifier-test level).

## Completion Notes

**Status**: Complete
**Completed**: 2026-05-10
**Files changed**:
- `lib/features/settings/presentation/providers/settings_provider.dart` — added 5 use case providers, rewrote 4 mutators to delegate, added `cycleThemeMode()` method, two mutators gained required device-value named params, added inline comment explaining the load-bearing `name:` annotation
- `lib/features/settings/presentation/providers/settings_provider.g.dart` — regenerated (+7K bytes)
- `test/features/settings/presentation/providers/settings_provider_test.dart` — adapted call signatures, added 3 cycleThemeMode tests

**Contract**: Expects 3/3 verified | Produces 6/6 verified

**Notes**:
- Code review verdict: APPROVE (1 Warning, addressed inline — added the missing comment about why `name: 'settingsNotifierProvider'` is load-bearing).
- 22/22 notifier tests pass.
- `dart analyze` clean on `presentation/providers/`. Whole-project analyze surfaces 4 expected widget call-site errors (`theme_selector.dart:65`, `language_selector.dart:71`, `theme_preview_screen.dart:58/64`) — these are owned by Task 006 per the plan's deliberate integration-gate placement.
- Function-form `@riverpod` providers correctly omit the `name:` annotation — the suffix-stripping rule from spec 015 only applies to class-form notifiers.
- In-memory state stays bit-for-bit consistent with persisted state on both atomic mutator branches and the cycle method (reviewer verified).
- `_FakeSettingsRepository` gained `savedManualLanguage` and `savedUseSystemLanguage` accessors; existing OFF-toggle tests were strengthened to verify the pre-fill landed in the fake repo.

## Contracts

### Expects
- `SetThemeMode`, `SetUseSystemTheme`, `SetUseSystemLanguage`, `SetManualLanguage`, `CycleThemeMode` all exist as classes with `const` constructors taking exactly one positional `SettingsRepository` (from Tasks 002, 003, 004).
- `settingsRepositoryProvider` already exists via `@riverpod` codegen.
- `_FakeSettingsRepository` in `settings_provider_test.dart` already implements the full `SettingsRepository` interface.

### Produces
- `settings_provider.dart` defines five additional `@riverpod` function providers: `setThemeMode`, `setUseSystemTheme`, `setUseSystemLanguage`, `setManualLanguage`, `cycleThemeMode`.
- `SettingsNotifier`'s four existing mutator methods reference `setThemeModeProvider`, `setUseSystemThemeProvider`, `setUseSystemLanguageProvider`, `setManualLanguageProvider` (one each) and contain ZERO `ref.read(settingsRepositoryProvider)` calls.
- `SettingsNotifier.setUseSystemTheme` accepts `(bool value, {required AppThemeMode currentDeviceMode})`.
- `SettingsNotifier.setUseSystemLanguage` accepts `(bool value, {required AppLanguage currentDeviceLanguage})`.
- `SettingsNotifier.cycleThemeMode()` is a public `Future<void>` method that delegates to `cycleThemeModeProvider`.
- `settings_provider_test.dart` adapts every call site to the new signatures and includes a `cycleThemeMode` test group with ≥ 2 cases.
