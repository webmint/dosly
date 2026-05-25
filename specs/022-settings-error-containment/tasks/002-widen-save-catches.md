# Task 2: Widen `save*` catches to `Failure.unknown`

**Agent**: architect
**Review checkpoint**: No
**Files**:
- `lib/features/settings/data/repositories/settings_repository_impl.dart`

**Depends on**: 1
**Blocks**: 3
**Context docs**: None

**Description**:
Close sibling bug 010: the four `save*` mutators in `SettingsRepositoryImpl`
catch only `Exception` (`} on Exception catch (e) {`), letting `Error` subtypes
(`StateError`, `ArgumentError`, `RangeError`, `TypeError`) escape the data layer.
They also populate `CacheFailure(e.toString())`, which can embed the on-disk
store's absolute filesystem path (CWE-209-adjacent). Widen each catch to
`catch (e, st)` so all throwables are contained, and route the caught throwable
to `Failure.unknown(e, st)` instead of `CacheFailure(e.toString())`. Depends on
Task 1 only because both edit the same file (serialize to avoid conflicting
edits); the methods themselves are independent of the `load()` change.

**Change details**:
- In `lib/features/settings/data/repositories/settings_repository_impl.dart`, for
  each of `saveThemeMode`, `saveUseSystemTheme`, `saveUseSystemLanguage`,
  `saveManualLanguage`:
  - Change `} on Exception catch (e) {` to `} catch (e, st) {`.
  - Change `return Left(CacheFailure(e.toString()));` to
    `return Left(Failure.unknown(e, st));`.
- Do not change the happy-path bodies or the method signatures.

**Done when**:
- [x] None of the four `save*` methods uses `on Exception catch`; all use `catch (e, st)`.
- [x] None of the four `save*` methods constructs `CacheFailure(e.toString())`; all return `Failure.unknown(e, st)` on the error path.
- [x] `dart analyze` passes with no new warnings/errors.
- [x] `flutter test` passes.

**Spec criteria addressed**: AC-7, AC-8 (production side)

## Completion Notes

**Completed**: 2026-05-25
**Files changed**: lib/features/settings/data/repositories/settings_repository_impl.dart; test/features/settings/presentation/providers/settings_provider_test.dart (review-driven)
**Contract**: Expects [3/3 verified] | Produces [3/3 verified — 0 `on Exception catch`, 0 `CacheFailure(e.toString())`, 5 `Left(Failure.unknown(e, st))`]
**Notes**:
- Scope expanded by one file beyond the plan: code review (REQUEST CHANGES, Critical) caught that the notifier test's `_FakeSettingsRepository` still fabricated `CacheFailure` on its four `failOn*` save branches and 5 assertions checked `isA<CacheFailure>()` — stale now that production emits `UnknownFailure`. Repaired in the same task: fake now returns `Left(Failure.unknown(Exception('mock failure'), StackTrace.empty))`, 5 assertions → `isA<UnknownFailure>()`, 4 doc comments + 4 test names updated.
- The notifier is type-agnostic about which `Failure` it forwards; the fix aligns the test's asserted type with what production actually emits so the suite honestly guards behavior.
- Verification after repair: `dart analyze` clean; `flutter test` 230/230.

## Contracts

### Expects
- `settings_repository_impl.dart` has methods `saveThemeMode`, `saveUseSystemTheme`, `saveUseSystemLanguage`, `saveManualLanguage` each returning `Future<Either<Failure, void>>`.
- `lib/core/error/failures.dart` exports `Failure.unknown(Object error, StackTrace stack)`.
- (From Task 1) the file already references `Failure.unknown`.

### Produces
- `settings_repository_impl.dart` contains no occurrence of `on Exception catch`.
- Each `save*` error path contains `Left(Failure.unknown(e, st))`.
- `settings_repository_impl.dart` contains no occurrence of `CacheFailure(e.toString())`.
