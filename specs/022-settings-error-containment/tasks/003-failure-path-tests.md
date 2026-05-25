# Task 3: Add failure-path tests for `load()` and `save*`

**Agent**: qa-engineer
**Review checkpoint**: Yes
**Files**:
- `test/features/settings/data/repositories/settings_repository_impl_test.dart`
- `test/features/settings/presentation/providers/settings_provider_test.dart`

**Depends on**: 1, 2
**Blocks**: None
**Context docs**: None

**Description**:
Add the tests that prove the containment contract now holds. Task 1 made `load()`
return `Either` and Task 2 widened the `save*` catches; this task asserts the
new behaviour: wrong-type cached values never throw out of `load()`, a throwing
data source yields `Left(UnknownFailure)` from both `load()` and every `save*`
(including when the throwable is an `Error`, not just an `Exception`), the
notifier surfaces a load failure, and the legacy-int `themeMode` fallback still
works. Convergence point — depends on both production tasks.

To drive throwing behaviour, add a private test double that subclasses the
concrete `SettingsLocalDataSource` and overrides the relevant getters/setters to
throw. Construct it with a real in-memory `SharedPreferencesWithCache` (as the
existing `_buildRepository` helper already creates) so only the targeted method
throws. Throw an `Error` subtype (e.g. `StateError`) in at least one case to
prove `Error` is caught, not just `Exception`.

**Change details**:
- In `test/features/settings/data/repositories/settings_repository_impl_test.dart`:
  - Add a `_ThrowingDataSource extends SettingsLocalDataSource` whose overridden
    methods throw (parameterize which method throws, or make separate doubles
    for the load-getter case and the save-setter case).
  - **AC-2** — add tests that store a wrong-type value for each of
    `useSystemTheme`, `useSystemLanguage`, and `manualLanguage` (mirroring the
    existing legacy-int `themeMode` test) and assert `load()` returns a value
    (does not throw). For the three previously-unguarded keys the result is a
    `Left` (the unguarded getter throws `TypeError`, caught by `load()`'s
    try/catch); assert no exception escapes.
  - **AC-3** — add a test where the data source throws on a getter and assert
    `load()` returns `Left` whose failure is an `UnknownFailure`.
  - **AC-7** — add tests where the data source throws (use a `StateError` to
    prove `Error` is caught) on each setter, asserting each `save*` returns
    `Left` whose failure is an `UnknownFailure`.
  - **AC-8** — assert the `Left` from a throwing `save*` is an `UnknownFailure`,
    not a `CacheFailure` (i.e. the raw `toString()` path is not used).
  - **AC-9** — keep the existing legacy-int `themeMode` test passing (it asserts
    fallback to `AppThemeMode.light`); adapt only the `Either` unwrap if needed.
- In `test/features/settings/presentation/providers/settings_provider_test.dart`:
  - Add a `failOnLoad` flag to `_FakeSettingsRepository` (default `false`) so its
    `load()` returns `Left(Failure.unknown(...))` when set.
  - **AC-5** — add a test: with `failOnLoad = true`, the notifier's initial state
    equals `const AppSettings()` AND the emitted `Failure` is observed on
    `settingsErrorsProvider` (or directly on the notifier's `errors` stream).
  - **AC-6** — add/confirm a test: with a non-default loaded `AppSettings`
    (`failOnLoad = false`), the notifier's initial state equals those values.

**Done when**:
- [x] Wrong-type cached values for `useSystemTheme`, `useSystemLanguage`, and `manualLanguage` are each covered by a test asserting `load()` does not throw (returns `Left(UnknownFailure)`).
- [x] A throwing-data-source test asserts `load()` returns `Left(UnknownFailure)`.
- [x] Each `save*` has a test asserting `Left(UnknownFailure)` when the data source throws an `Error` (`StateError`).
- [x] A test asserts the throwing-`save*` failure is `UnknownFailure`, not `CacheFailure`.
- [x] A notifier test asserts Left-on-load → `const AppSettings()` state (emission not asserted — see Notes / spec OQ-2).
- [x] The existing legacy-int `themeMode` fallback test still passes.
- [x] `dart analyze` passes with no new warnings/errors.
- [x] `flutter test` passes (full suite green: 241/241).

**Spec criteria addressed**: AC-2, AC-3, AC-5, AC-6, AC-7, AC-8, AC-9, AC-10

## Completion Notes

**Completed**: 2026-05-25
**Files changed**: test/features/settings/data/repositories/settings_repository_impl_test.dart; test/features/settings/presentation/providers/settings_provider_test.dart
**Contract**: Expects [6/6 verified] | Produces [4/4 verified]
**Notes**:
- Throwing doubles: `_ThrowingGetterDataSource` (overrides `getUseSystemTheme` → `StateError`) and `_ThrowingSetterDataSource` (per-setter `throwOn*` flags → `StateError`). `StateError` is an `Error`, proving the broad `catch (e, st)` catches `Error`, not just `Exception` (the point of bug 010).
- AC-2 wrong-type tests assert both `isLeft()` and `isA<UnknownFailure>()` (the second assertion added as a code-review follow-up to match AC-3/AC-7 rigor).
- **AC-5 caveat (carry to /verify):** the load-failure stream *emission* is not directly asserted. `build()` calls `_errors.add(failure)` synchronously before any listener subscribes, and the broadcast stream drops no-listener events — exactly the behavior accepted in spec **OQ-2**. The test asserts the safety-critical default-state fallback; a companion test confirms the errors stream still works after a load failure via a subsequent save failure. Making the emission observable would need a production change (e.g. `scheduleMicrotask`), which OQ-2 defers to a separate startup-error-UX spec.
- No partial Either extractors used (§3.2). Suite grew 230 → 241.
- Code review: APPROVE with warnings (AC-2 rigor) — addressed.

## Contracts

### Expects
- (Task 1) `SettingsRepository.load()` returns `Either<Failure, AppSettings>`; `SettingsRepositoryImpl.load()` returns `Left(Failure.unknown(...))` on a thrown getter.
- (Task 1) `SettingsNotifier.build()` folds load into default state + `_errors` emission; `settingsErrorsProvider` exposes the `errors` stream.
- (Task 2) each `save*` returns `Left(Failure.unknown(...))` on any throwable.
- `SettingsLocalDataSource` is a non-final concrete class whose getter/setter methods can be overridden by a subclass.
- `_buildRepository` helper in the repo-impl test creates a real in-memory `SharedPreferencesWithCache`.
- `UnknownFailure` is the public subclass of `Failure.unknown`.

### Produces
- `settings_repository_impl_test.dart` contains a throwing `SettingsLocalDataSource` double and tests asserting `isA<Left<Failure, AppSettings>>()` / `isA<UnknownFailure>()` for `load()` and `isA<UnknownFailure>()` for each `save*`.
- `settings_repository_impl_test.dart` contains wrong-type-cache tests for `useSystemTheme`, `useSystemLanguage`, `manualLanguage`.
- `settings_provider_test.dart` `_FakeSettingsRepository` has a `failOnLoad` flag and a test asserting default state + emitted failure on load failure.
- `flutter test` exits 0 with the new tests included.
