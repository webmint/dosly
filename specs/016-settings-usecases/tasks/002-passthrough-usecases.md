# Task 002: Create `SetThemeMode` and `SetManualLanguage` pass-through use cases

**Agent**: architect
**Files**:
- `lib/features/settings/domain/usecases/set_theme_mode.dart` (create)
- `lib/features/settings/domain/usecases/set_manual_language.dart` (create)
- `test/features/settings/domain/usecases/set_theme_mode_test.dart` (create)
- `test/features/settings/domain/usecases/set_manual_language_test.dart` (create)

**Depends on**: None
**Blocks**: 005
**Context docs**: None
**Review checkpoint**: No

## Description

Create the two **pass-through** use cases. They each wrap exactly one repository method with no additional logic — but the constitution still requires them as the indirection layer the notifier delegates through (§2.1, §4.1.1).

Use the constitution §7.2 `AddMedication` template: `class FooUseCase { const FooUseCase(this._repo); final SettingsRepository _repo; Future<Either<Failure, void>> call(...) async => _repo.saveX(...); }`.

Each use case has a unit test using `mocktail`'s `MockSettingsRepository` covering the happy path (verify `_repo.saveX` was called with the input) and one repository failure (when `_repo.saveX` returns `Left(CacheFailure)`, the use case returns the same `Left`).

## Change details

- In `lib/features/settings/domain/usecases/set_theme_mode.dart` (create):
  - Library dartdoc + a `class SetThemeMode` with `const SetThemeMode(this._repo)`, a `final SettingsRepository _repo`, and `Future<Either<Failure, void>> call(AppThemeMode mode) => _repo.saveThemeMode(mode);`.
  - Imports: `package:fpdart/fpdart.dart`, the `Failure` from `core/error`, the `AppThemeMode` entity, and the `SettingsRepository` interface.

- In `lib/features/settings/domain/usecases/set_manual_language.dart` (create):
  - Same shape, callable with `AppLanguage language`, dispatching to `_repo.saveManualLanguage(language)`.

- In `test/features/settings/domain/usecases/set_theme_mode_test.dart` (create):
  - Use `mocktail`'s `Mock` to declare `class _MockSettingsRepository extends Mock implements SettingsRepository {}`.
  - In `setUpAll`, register fallback values for any non-primitive arguments used in `verify`/`when` (`registerFallbackValue(AppThemeMode.light)` for `AppThemeMode`).
  - Test 1: `'forwards the input to repo.saveThemeMode and returns Right(null) on success'` — `when(() => repo.saveThemeMode(any())).thenAnswer((_) async => const Right(null));` then `await useCase(AppThemeMode.dark)` and `verify(() => repo.saveThemeMode(AppThemeMode.dark)).called(1);` plus `expect(result, const Right<Failure, void>(null));`.
  - Test 2: `'returns the repository Left when saveThemeMode fails'` — `when` returns `const Left(CacheFailure('mock'))` and the result equals that Left.

- In `test/features/settings/domain/usecases/set_manual_language_test.dart` (create):
  - Same shape; `registerFallbackValue(AppLanguage.en)`; happy + failure paths for `saveManualLanguage(AppLanguage.uk)`.

## Done when

- [x] Both `SetThemeMode` and `SetManualLanguage` exist as `class`es with `const` constructors taking exactly one positional `SettingsRepository`.
- [x] Both have a single `call(...)` method returning `Future<Either<Failure, void>>`.
- [x] Neither file imports `package:flutter/*`, `package:flutter_riverpod/*`, or `package:drift/*` — verified by `grep -rE "package:(flutter|flutter_riverpod|drift)" lib/features/settings/domain/usecases/`.
- [x] Both unit test files exist with at least 2 tests each (happy path + repo failure).
- [x] `dart analyze lib/features/settings/domain/usecases/ test/features/settings/domain/usecases/` exits 0.
- [x] `flutter test test/features/settings/domain/usecases/set_theme_mode_test.dart test/features/settings/domain/usecases/set_manual_language_test.dart` passes.

## Spec criteria addressed

AC-1 (partial — 2 of 5 files), AC-2 (partial), AC-3 (partial).

## Completion Notes

**Status**: Complete
**Completed**: 2026-05-10
**Files changed**:
- `lib/features/settings/domain/usecases/set_theme_mode.dart` (new, ~30 lines)
- `lib/features/settings/domain/usecases/set_manual_language.dart` (new, ~30 lines)
- `test/features/settings/domain/usecases/set_theme_mode_test.dart` (new, 2 tests)
- `test/features/settings/domain/usecases/set_manual_language_test.dart` (new, 2 tests)
- `pubspec.yaml` (+1 line: `mocktail: ^1.0.4` under dev_dependencies)
- `pubspec.lock` (regenerated)

**Contract**: Expects 4/4 verified | Produces 3/3 verified

**Notes**:
- Code review verdict: APPROVE (1 procedural Warning).
- The agent discovered `mocktail` was missing from `pubspec.yaml` despite being listed as the project-standard test mock in MEMORY.md. Added `mocktail: ^1.0.4` (resolved to 1.0.5) under `dev_dependencies`. This is a justified scope expansion — Tasks 003, 004, 005 also rely on `mocktail`.
- Procedural warning: dependency was added by editing `pubspec.yaml` directly rather than running `flutter pub add --dev mocktail`. The end state is identical; flagged for habit reinforcement only.
- Use case `call` methods use arrow form (`=>`) — pure delegation needs no `async`/`await` frame, just forwards the underlying `Future<Either<...>>`. Reviewer ratified.

## Contracts

### Expects
- `SettingsRepository` interface exists at `lib/features/settings/domain/repositories/settings_repository.dart` with methods `saveThemeMode(AppThemeMode)` and `saveManualLanguage(AppLanguage)` returning `Future<Either<Failure, void>>`.
- `AppThemeMode` and `AppLanguage` entities exist as pure-Dart enums.
- `mocktail` is a project dev dependency.
- `Failure` and `CacheFailure` exist in `lib/core/error/failures.dart`.

### Produces
- `lib/features/settings/domain/usecases/set_theme_mode.dart` exports a `class SetThemeMode` with `const SetThemeMode(this._repo)` and `Future<Either<Failure, void>> call(AppThemeMode mode)`.
- `lib/features/settings/domain/usecases/set_manual_language.dart` exports a `class SetManualLanguage` with `const SetManualLanguage(this._repo)` and `Future<Either<Failure, void>> call(AppLanguage language)`.
- Test files prove both use cases forward the call and propagate `Left` from the repo.
