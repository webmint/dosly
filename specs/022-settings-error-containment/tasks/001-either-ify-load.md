# Task 1: Either-ify `load()` and align all consumers

**Agent**: architect
**Review checkpoint**: Yes
**Files**:
- `lib/features/settings/domain/repositories/settings_repository.dart`
- `lib/features/settings/data/repositories/settings_repository_impl.dart`
- `lib/features/settings/presentation/providers/settings_provider.dart`
- `test/features/settings/data/repositories/settings_repository_impl_test.dart`
- `test/features/settings/presentation/providers/settings_provider_test.dart`
- `test/app_bootstrap_test.dart`
- `test/widget_test.dart`
- `test/core/routing/app_router_test.dart`
- `test/features/settings/presentation/screens/settings_screen_test.dart`
- `test/features/settings/presentation/widgets/theme_selector_test.dart`
- `test/features/settings/presentation/widgets/language_selector_test.dart`

**Depends on**: None
**Blocks**: 2, 3
**Context docs**: `docs/architecture.md` (error-handling / Either boundary section)

**Description**:
Change `SettingsRepository.load()` from `AppSettings load()` to a synchronous
`Either<Failure, AppSettings> load()`, wrap the impl's four-getter chain in a
`try/catch (e, st)` so no throwable escapes, and fold the result in
`SettingsNotifier.build()` (Left → `const AppSettings()` default state **and**
emit the failure to the existing `_errors` stream; Right → the loaded settings).
This is a single indivisible signature change: the interface, the impl, the one
production consumer, all seven hand-written test fakes, and the repo-impl test's
existing `load()` call sites must change together or `dart analyze` (which
analyzes `test/`) fails project-wide with `invalid_override`. This task does NOT
touch the `save*` methods (Task 2) and does NOT add new failure-path tests
(Task 3) — only the mechanical alignment needed to keep the suite green.

**Change details**:
- In `lib/features/settings/domain/repositories/settings_repository.dart`:
  - Change `AppSettings load();` to `Either<Failure, AppSettings> load();`.
  - Rewrite the dartdoc: drop "Never fails — returns defaults if nothing is
    stored"; describe the `Either` contract (e.g. "Reads current settings
    synchronously from cache. Returns `Right(settings)` on success, or
    `Left(Failure.unknown(...))` if the underlying cache read throws.").
  - `Either`/`Failure` are already imported.
- In `lib/features/settings/data/repositories/settings_repository_impl.dart`:
  - Change `load()` to:
    ```dart
    @override
    Either<Failure, AppSettings> load() {
      try {
        return Right(AppSettings(
          useSystemTheme: _dataSource.getUseSystemTheme(),
          manualThemeMode: _dataSource.getThemeMode(),
          useSystemLanguage: _dataSource.getUseSystemLanguage(),
          manualLanguage: _dataSource.getManualLanguage(),
        ));
      } catch (e, st) {
        return Left(Failure.unknown(e, st));
      }
    }
    ```
  - Leave the four `save*` methods unchanged in this task.
- In `lib/features/settings/presentation/providers/settings_provider.dart`:
  - In `build()`, replace `return repo.load();` with a fold:
    ```dart
    return repo.load().fold(
      (failure) {
        _errors.add(failure);
        return const AppSettings();
      },
      (settings) => settings,
    );
    ```
  - `build()` still returns `AppSettings` (no signature change to the notifier).
- In `test/features/settings/data/repositories/settings_repository_impl_test.dart`:
  - At each existing `final settings = repository.load();` site (and the two
    `secondRepository.load()` sites), unwrap the `Either` without a forbidden
    partial extractor — e.g. `final settings = repository.load().getOrElse((_) => fail('expected Right'));`
    or pattern-match `switch`. Do NOT use `.getRight()`, `.toIterable().first`,
    etc. (constitution §3.2). Existing assertions stay the same.
- In the six hand-written fakes, change the `load()` override to return `Right`:
  - `test/features/settings/presentation/providers/settings_provider_test.dart`
    (`_FakeSettingsRepository`): `Either<Failure, AppSettings> load() => Right(_settings);`
  - `test/app_bootstrap_test.dart`: `Either<Failure, AppSettings> load() => const Right(AppSettings());`
  - `test/widget_test.dart`: `Either<Failure, AppSettings> load() => Right(_settings);`
  - `test/core/routing/app_router_test.dart`: `Either<Failure, AppSettings> load() => const Right(AppSettings());`
  - `test/features/settings/presentation/screens/settings_screen_test.dart`: `Either<Failure, AppSettings> load() => Right(_settings);`
  - `test/features/settings/presentation/widgets/theme_selector_test.dart`: `Either<Failure, AppSettings> load() => Right(_settings);`
  - `test/features/settings/presentation/widgets/language_selector_test.dart`: `Either<Failure, AppSettings> load() => Right(_settings);`
  - Add the `fpdart` import to any of these files that does not already import it.

**Done when**:
- [x] `SettingsRepository.load()` is declared `Either<Failure, AppSettings> load();` with an accurate dartdoc (no "Never fails").
- [x] `SettingsRepositoryImpl.load()` wraps its getter chain in `try/catch (e, st)` returning `Right(...)` / `Left(Failure.unknown(e, st))`.
- [x] `SettingsNotifier.build()` folds the `Either` (Left → `const AppSettings()` + `_errors.add(failure)`; Right → settings) and still returns `AppSettings`.
- [x] All seven hand-written fakes return `Either<Failure, AppSettings>` from `load()`.
- [x] The repo-impl test unwraps `load()`'s `Either` at all existing call sites without a partial extractor.
- [x] `dart analyze` passes with no new warnings/errors.
- [x] `flutter test` passes (existing tests, adapted).

**Spec criteria addressed**: AC-1, AC-4, AC-9 (load side); production groundwork for AC-2, AC-3, AC-5, AC-6, AC-10

## Completion Notes

**Completed**: 2026-05-25
**Files changed**: 11 (3 prod: settings_repository.dart, settings_repository_impl.dart, settings_provider.dart; 8 test: repo-impl test + 7 hand-written fakes) + a docstring follow-up in settings_provider.dart
**Contract**: Expects [4/4 verified] | Produces [5/5 verified]
**Notes**:
- `load()` kept synchronous; impl uses broad `catch (e, st)` (not `on Exception`) because `SharedPreferencesWithCache` can throw `TypeError` (an `Error`) on type-mismatched cache reads. The four `save*` methods left untouched (still `on Exception` — Task 2 widens them).
- Repo-impl test call sites unwrap via `getOrElse((f) => fail(...))` per §3.2 (no partial extractor).
- Code review APPROVE-with-warnings: (1) stale `_errors`/`settingsErrorsProvider` docstrings — FIXED in this task (now name both the load fold and the save mutators). (2) load-Left branch lacks a test — deferred to Task 3 (AC-5/AC-6), by design.
- Verification: `dart analyze` clean; `flutter test` 230/230 pass.

## Contracts

### Expects
- `lib/features/settings/domain/repositories/settings_repository.dart` declares `abstract interface class SettingsRepository` with a method `load()`.
- `lib/core/error/failures.dart` exports `Failure` with factory `Failure.unknown(Object error, StackTrace stack)` (subclass `UnknownFailure`).
- `settings_provider.dart` `SettingsNotifier` has a field `_errors` of type `StreamController<Failure>` initialized in `build()`.
- `fpdart` provides `Either`, `Right`, `Left`, and `fold`.

### Produces
- `settings_repository.dart` declares `Either<Failure, AppSettings> load();`.
- `settings_repository_impl.dart` `load()` contains `Right(AppSettings(` and `Left(Failure.unknown(e, st))` inside a `try { ... } catch (e, st) {`.
- `settings_provider.dart` `build()` contains `repo.load().fold(` and `_errors.add(` and returns `const AppSettings()` in the Left branch.
- All seven hand-written test fakes declare `Either<Failure, AppSettings> load()`.
- `dart analyze` reports no `invalid_override` for `load()`.
