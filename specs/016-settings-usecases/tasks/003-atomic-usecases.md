# Task 003: Create `SetUseSystemTheme` and `SetUseSystemLanguage` atomic use cases

**Agent**: architect
**Files**:
- `lib/features/settings/domain/usecases/set_use_system_theme.dart` (create)
- `lib/features/settings/domain/usecases/set_use_system_language.dart` (create)
- `test/features/settings/domain/usecases/set_use_system_theme_test.dart` (create)
- `test/features/settings/domain/usecases/set_use_system_language_test.dart` (create)

**Depends on**: None
**Blocks**: 005
**Context docs**: None
**Review checkpoint**: No

## Description

Create the two **atomic** use cases that own the cross-cutting "switch-to-manual must pre-fill from device" rule. Each one accepts a `required` non-nullable device value (`AppThemeMode currentDeviceMode` or `AppLanguage currentDeviceLanguage`) alongside the boolean toggle.

### Atomic semantics (apply to both)

- When `value` is `false` (toggling OFF):
  1. `final r = await _repo.save{Manual}(currentDeviceY);` — pre-fill the manual override first.
  2. If `r.isLeft()`, return `r` immediately and do NOT execute step 3.
  3. `return _repo.saveUseSystem{Y}(false);` — flip the toggle.
- When `value` is `true` (toggling ON):
  1. `return _repo.saveUseSystem{Y}(true);` — toggle only; do NOT touch `save{Manual}`.

This ordering is contractual: the unit test verifies it via `verifyInOrder([() => repo.saveX(...), () => repo.saveUseSystemX(...)])`, and AC-4 / AC-6 mandate this exact sequence.

### Test cases per use case (4 tests each)

1. `'value=false, repo healthy: writes manual then toggle in that order, returns Right'` — `verifyInOrder` on the two stubbed methods and assert the result is `Right(null)`.
2. `'value=true: toggles only, never touches save{Manual}'` — `verifyNever(() => repo.save{Manual}(any()))` and `verify(() => repo.saveUseSystem{Y}(true)).called(1)`.
3. `'value=false, save{Manual} fails: short-circuits before saveUseSystem{Y}, returns the Left'` — `when(() => repo.save{Manual}(any())).thenAnswer((_) async => const Left(CacheFailure('boom')));` and `verifyNever(() => repo.saveUseSystem{Y}(any()))`.
4. `'value=false, saveUseSystem{Y} fails after save{Manual} succeeds: returns the saveUseSystem{Y} Left'` — second-write failure, both calls happen but the result is the second Left.

## Change details

- In `lib/features/settings/domain/usecases/set_use_system_theme.dart` (create):
  - `class SetUseSystemTheme { const SetUseSystemTheme(this._repo); final SettingsRepository _repo; Future<Either<Failure, void>> call({required bool value, required AppThemeMode currentDeviceMode}) async { ... } }`
  - Body matches the atomic semantics above with `_repo.saveThemeMode(currentDeviceMode)` as the manual write and `_repo.saveUseSystemTheme(value)` as the toggle write.
  - Use `Either.fold` or `result.isLeft()` + early return for the short-circuit. Either form is acceptable; pick whichever reads cleaner.

- In `lib/features/settings/domain/usecases/set_use_system_language.dart` (create):
  - Symmetric: `currentDeviceLanguage: AppLanguage`, manual write is `_repo.saveManualLanguage(currentDeviceLanguage)`, toggle is `_repo.saveUseSystemLanguage(value)`.

- In `test/features/settings/domain/usecases/set_use_system_theme_test.dart` (create):
  - `MockSettingsRepository` from `mocktail`. `setUpAll` registers fallback values for `AppThemeMode` (and bool — primitives don't need fallbacks but keep consistent).
  - All four test cases above.

- In `test/features/settings/domain/usecases/set_use_system_language_test.dart` (create):
  - Same shape, `AppLanguage` instead of `AppThemeMode`.

## Done when

- [x] Both use cases exist with `const` constructors and the prescribed `call({required bool value, required AppThemeMode|AppLanguage current...})` signature.
- [x] Neither file imports `package:flutter/*`, `package:flutter_riverpod/*`, or `package:drift/*`.
- [x] Test files exist; each has the 4 cases above; each has at least one `verifyInOrder` and one `verifyNever`.
- [x] `dart analyze lib/features/settings/domain/usecases/ test/features/settings/domain/usecases/` exits 0.
- [x] `flutter test test/features/settings/domain/usecases/set_use_system_theme_test.dart test/features/settings/domain/usecases/set_use_system_language_test.dart` passes.

## Spec criteria addressed

AC-1 (partial — 2 of 5), AC-2 (partial), AC-3 (partial), AC-4, AC-5, AC-6.

## Completion Notes

**Status**: Complete
**Completed**: 2026-05-10
**Files changed**:
- `lib/features/settings/domain/usecases/set_use_system_theme.dart` (new, atomic 2-write use case)
- `lib/features/settings/domain/usecases/set_use_system_language.dart` (new, symmetric)
- `test/features/settings/domain/usecases/set_use_system_theme_test.dart` (new, 4 tests)
- `test/features/settings/domain/usecases/set_use_system_language_test.dart` (new, 4 tests)

**Contract**: Expects 3/3 verified | Produces 3/3 verified

**Notes**:
- Code review verdict: APPROVE (zero Critical/Warning findings).
- Implementer chose `if (!value) { ... isLeft() return; }` early-return form over `fold` — keeps the short-circuit physically unreachable when the first write Lefts, which makes accidental second-write-skip bugs structurally impossible.
- AC-4 / AC-6 verified: test 1 in each file uses `verifyInOrder([saveManual, saveToggle])` exactly. Test 3 uses `verifyNever(saveToggle)` to prove the bug-prevention case (first-write failure → second write skipped).
- 8 new tests; total project-wide use-case tests now 12/12 green.

## Contracts

### Expects
- `SettingsRepository` exposes `saveThemeMode(AppThemeMode) → Future<Either<Failure, void>>`, `saveUseSystemTheme(bool) → Future<Either<Failure, void>>`, `saveManualLanguage(AppLanguage) → Future<Either<Failure, void>>`, `saveUseSystemLanguage(bool) → Future<Either<Failure, void>>`.
- `mocktail` is a project dev dependency.
- `CacheFailure` exists as a concrete `Failure` subclass.

### Produces
- `lib/features/settings/domain/usecases/set_use_system_theme.dart` exports `class SetUseSystemTheme` with `const SetUseSystemTheme(this._repo)` and `Future<Either<Failure, void>> call({required bool value, required AppThemeMode currentDeviceMode})`.
- `lib/features/settings/domain/usecases/set_use_system_language.dart` exports `class SetUseSystemLanguage` with `const SetUseSystemLanguage(this._repo)` and `Future<Either<Failure, void>> call({required bool value, required AppLanguage currentDeviceLanguage})`.
- Both unit tests assert manual-write-then-toggle ordering via `verifyInOrder` and short-circuit-on-first-Left semantics.
