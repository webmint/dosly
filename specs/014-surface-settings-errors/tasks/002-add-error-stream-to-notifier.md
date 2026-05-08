# Task 002: Add error stream to `SettingsNotifier` + `settingsErrorsProvider` + unit tests

**Agent**: mobile-engineer
**Status**: Complete
**Files**: `lib/features/settings/presentation/providers/settings_provider.dart`, `test/features/settings/presentation/providers/settings_provider_test.dart`
**Depends on**: None
**Blocks**: 003
**Context docs**: `specs/014-surface-settings-errors/research.md`
**Review checkpoint**: No

## Completion Notes

**Completed**: 2026-05-07
**Files changed**: lib/features/settings/presentation/providers/settings_provider.dart, test/features/settings/presentation/providers/settings_provider_test.dart
**Contract**: Expects 4/4 verified | Produces 9/9 verified
**Code review**: APPROVE (zero critical/warning findings; 3 info-level observations: late-final assumption noted as defensive; tests subscribe directly to `errors` getter rather than via the provider one-liner — acceptable for unit-level coverage; `await Future<void>.delayed(Duration.zero)` used to drain microtasks — standard for non-widget unit tests)
**Notes**: 19/19 tests pass (13 existing + 6 new). All 4 Left branches now `(failure) => _errors.add(failure)`. Zero deferral-comment occurrences and zero log calls. Existing 4 "state is NOT updated" tests preserved unmodified.

## Description

Replace the four empty Left-branch closures in `SettingsNotifier` (currently
`(_) { /* deferred */ }`) with `(failure) => _errors.add(failure)`. The
notifier owns a `StreamController<Failure>.broadcast()` initialized in
`build()` and closed via `ref.onDispose`. Add a top-level
`settingsErrorsProvider` (`StreamProvider<Failure>`) that exposes the stream
to consumers. Add provider-level unit tests asserting the stream emits a
`Failure` for each mutator's Left path and stays silent on Right.

This task is presentation-layer only — no domain or data changes. State
shape (`AppSettings`) stays exactly the same. Mutator return types stay
`Future<void>`. Existing tests must continue to pass unmodified.

## Change details

- In `lib/features/settings/presentation/providers/settings_provider.dart`:
  - Add `import 'dart:async';` to the imports block (alphabetical position, before the `package:` imports).
  - Add a `late final StreamController<Failure> _errors;` field on `SettingsNotifier` (above the `build` override).
  - In `SettingsNotifier.build()`:
    - Initialize the controller as the **first** statement: `_errors = StreamController<Failure>.broadcast();`.
    - Register cleanup as the **second** statement: `ref.onDispose(_errors.close);`.
    - Then keep the existing `final repo = ref.watch(settingsRepositoryProvider); return repo.load();` lines unchanged.
  - Add a new public getter on `SettingsNotifier`: `Stream<Failure> get errors => _errors.stream;` with dartdoc:
    ```dart
    /// Broadcast stream of [Failure]s emitted by the four save mutators.
    ///
    /// Each Left from [SettingsRepository.saveX] is forwarded to this stream
    /// so a UI surface (e.g. [SettingsScreen]) can react via
    /// [settingsErrorsProvider]. The state itself stays consistent with what
    /// was actually persisted — failures do not roll the in-memory state
    /// back. The controller is closed automatically when the notifier is
    /// disposed.
    ```
  - In each of the four mutators (`setThemeMode`, `setUseSystemTheme`,
    `setUseSystemLanguage`, `setManualLanguage`), replace the Left branch:
    - From the current `(_) { /* Failure surfacing deferred to bug 003 (UI surface) and bug 017 (typed logger). */ },`
    - To `(failure) => _errors.add(failure),`
    - Remove the deferral comments at all four sites — they are obsolete (bug 003 closes here; bug 017 still tracked separately by its own bug doc).
  - Update each mutator's existing dartdoc block to remove or update the
    line "On persistence failure the in-memory state is not updated so the
    UI stays consistent with what was actually saved." Replace with: "On
    persistence failure the in-memory state is not updated and the failure
    is forwarded to [settingsErrorsProvider] so the UI can surface it."
  - At the bottom of the file, after `class SettingsNotifier {...}`, add:
    ```dart
    /// Broadcast stream of persistence failures from [SettingsNotifier].
    ///
    /// Consumers (e.g. [SettingsScreen]) listen via `ref.listen` to surface
    /// errors to the user — typically as a SnackBar. Non-`autoDispose` to
    /// match the lifetime of [settingsProvider].
    final settingsErrorsProvider = StreamProvider<Failure>((ref) {
      return ref.watch(settingsProvider.notifier).errors;
    });
    ```
  - Add `import '../../../../core/error/failures.dart';` if not already
    imported (it currently is not — `Failure` is the type used as the
    stream's element type and `_errors` field type).

- In `test/features/settings/presentation/providers/settings_provider_test.dart`:
  - The existing `_FakeSettingsRepository` and the existing `setUp` /
    `tearDown` blocks stay unchanged.
  - Add a new `group('SettingsNotifier error stream', () { ... })` AFTER
    the existing `group('SettingsNotifier', ...)` (do not nest inside it).
    Add these tests inside the new group:
    1. `test('settingsErrorsProvider emits CacheFailure when setThemeMode fails')`:
       - `fakeRepo.failOnSaveThemeMode = true;`
       - Capture emissions: `final emissions = <Failure>[]; final sub = container.read(settingsProvider.notifier).errors.listen(emissions.add);`
       - Trigger: `await container.read(settingsProvider.notifier).setThemeMode(AppThemeMode.dark);`
       - `await Future<void>.delayed(Duration.zero);`
       - `expect(emissions, hasLength(1));`
       - `expect(emissions.single, isA<CacheFailure>());`
       - `await sub.cancel();`
    2. `test('settingsErrorsProvider emits when setUseSystemTheme fails')`: same shape, `failOnSaveUseSystemTheme = true`, `setUseSystemTheme(false)`.
    3. `test('settingsErrorsProvider emits when setUseSystemLanguage fails')`: same shape.
    4. `test('settingsErrorsProvider emits when setManualLanguage fails')`: same shape.
    5. `test('settingsErrorsProvider does NOT emit on successful save')`:
       - All `failOnSaveX` flags stay false.
       - Subscribe; call all four mutators sequentially with valid args.
       - Assert `emissions.isEmpty`.
    6. `test('errors stream supports multiple sequential emissions')`:
       - Subscribe; flip `failOnSaveThemeMode = true`; call `setThemeMode(AppThemeMode.dark)`; assert 1 emission. Call again; assert 2. (Verifies the stream is broadcast and not single-shot.)
  - The 4 existing tests asserting "state is NOT updated when save fails" must continue to pass unmodified — verify by running the test file.

## Done when

- [x] `settings_provider.dart` imports `dart:async` and `core/error/failures.dart`.
- [x] `SettingsNotifier` has a `Stream<Failure> get errors` getter.
- [x] `SettingsNotifier.build()` initializes `_errors = StreamController<Failure>.broadcast()` and registers `ref.onDispose(_errors.close)`.
- [x] All four mutators' Left branches call `_errors.add(failure)` (verify with `grep -c '_errors.add(failure)' settings_provider.dart` returning `4`).
- [x] Zero matches for `grep -F 'deferred to bug 003' lib/features/settings/`.
- [x] Zero matches for `grep -E '\b(debugPrint|print|developer\.log)\b' lib/features/settings/presentation/providers/settings_provider.dart` (regression guard for spec 013's gain).
- [x] Top-level `final settingsErrorsProvider = StreamProvider<Failure>(...)` exists in the same file.
- [x] `flutter test test/features/settings/presentation/providers/settings_provider_test.dart` passes (all existing tests + 6 new tests = 19 total).
- [x] `dart analyze` passes on the two changed files with zero issues.

## Spec criteria addressed

AC-1, AC-2, AC-3, AC-4, AC-5 (preservation), AC-6, AC-7, AC-12 (analyze).

## Contracts

### Expects
- `class SettingsNotifier extends Notifier<AppSettings>` is declared in `settings_provider.dart` (already true).
- The four mutators (`setThemeMode`, `setUseSystemTheme`, `setUseSystemLanguage`, `setManualLanguage`) exist with signatures returning `Future<void>` and use `result.fold(...)` to handle the repository's `Either<Failure, void>` result (already true).
- `core/error/failures.dart` exports `sealed class Failure` and a concrete `CacheFailure` subclass with a `String message` field (already true).
- `_FakeSettingsRepository` in the test file already exposes per-method `failOnSaveX` boolean flags returning `Left(CacheFailure('mock failure'))` when set (already true at lines 22–69 of the existing test file).

### Produces
- `settings_provider.dart` imports `dart:async`.
- `settings_provider.dart` imports `../../../../core/error/failures.dart` (or transitively, but the import line must be present for `Failure` to be in scope).
- `class SettingsNotifier` declares a field `late final StreamController<Failure> _errors`.
- `SettingsNotifier.build()` contains the literal expression `StreamController<Failure>.broadcast()` and the call `ref.onDispose(_errors.close)`.
- `SettingsNotifier` declares the public getter `Stream<Failure> get errors`.
- All four mutators' Left fold-branch contains the literal expression `_errors.add(failure)`.
- The string literal `"deferred to bug 003"` appears nowhere in `lib/features/settings/`.
- The file declares the top-level constant `final settingsErrorsProvider = StreamProvider<Failure>(...)`.
- The expression `ref.watch(settingsProvider.notifier).errors` returns `Stream<Failure>` and compiles.
- `settings_provider_test.dart` contains a group named `'SettingsNotifier error stream'` with at least 6 `test(...)` blocks covering each mutator's emission, the no-emission-on-success path, and the multi-emission path.
