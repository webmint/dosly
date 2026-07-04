# Task 004: Grow SettingsRepository by 3 methods (contract + impl + all fakes)

**Agent**: architect
**Files**: `lib/features/settings/domain/repositories/settings_repository.dart`, `lib/features/settings/data/repositories/settings_repository_impl.dart`, and the 8 hand-written fakes: `test/app_bootstrap_test.dart`, `test/widget_test.dart`, `test/core/routing/app_router_test.dart`, `test/features/settings/presentation/screens/settings_screen_test.dart`, `test/features/settings/presentation/providers/settings_provider_test.dart` (two fake classes in this file), `test/features/settings/presentation/widgets/theme_selector_test.dart`, `test/features/settings/presentation/widgets/language_selector_test.dart`
**Depends on**: 001, 002, 003
**Blocks**: 005, 011
**Context docs**: `docs/features/settings.md`
**Review checkpoint**: Yes

**Description**:
Add the three `saveX` methods to the `SettingsRepository` contract, implement them (and populate `load()` with the 3 new fields) in `SettingsRepositoryImpl`, and patch **every** hand-written `implements SettingsRepository` fake with a no-op override. This is intentionally one task touching many files (an exception to the 1–3 file rule): per MEMORY (Feature 037), adding a method to this interface breaks all hand-written fakes, and project-wide `dart analyze` stays red until every implementer is updated — so contract, impl, and fakes must land together to keep the tree compiling. The four `_MockSettingsRepository extends Mock` classes auto-satisfy the new methods and need no change.

**Change details**:
- In `settings_repository.dart`:
  - Import the two VO files.
  - Add `Future<Either<Failure, void>> saveIntakeWindow(IntakeWindow window);`, `saveGracePeriod(GracePeriod grace);`, `saveAllowMarkAhead(bool value);` with dartdoc.
- In `settings_repository_impl.dart`:
  - In `load()`, populate `intakeWindow: _dataSource.getIntakeWindow()`, `gracePeriod: _dataSource.getGracePeriod()`, `allowMarkAhead: _dataSource.getAllowMarkAhead()`.
  - Add the three `saveX` overrides mirroring the existing `try/catch → Either` idiom (delegate to the matching data-source setter).
- In each of the 8 fake classes: add no-op overrides, e.g. `@override Future<Either<Failure, void>> saveIntakeWindow(IntakeWindow window) async => const Right(null);` (and grace/bool), importing the VOs where needed.

**Contracts**:

### Expects
- `IntakeWindow`/`GracePeriod` exist (Task 001).
- `SettingsLocalDataSource` exposes `getIntakeWindow`/`setIntakeWindow`, `getGracePeriod`/`setGracePeriod`, `getAllowMarkAhead`/`setAllowMarkAhead` (Task 002).
- `AppSettings` has `intakeWindow`/`gracePeriod`/`allowMarkAhead` fields (Task 003).
- Exactly 8 hand-written classes `implements SettingsRepository` across `test/`.

### Produces
- `settings_repository.dart` declares `saveIntakeWindow(`, `saveGracePeriod(`, `saveAllowMarkAhead(`.
- `settings_repository_impl.dart` `load()` references `getIntakeWindow(`, `getGracePeriod(`, `getAllowMarkAhead(`, and declares the three `saveX` overrides.
- Each of the 8 fake files declares `saveIntakeWindow`, `saveGracePeriod`, `saveAllowMarkAhead` overrides.

**Done when**:
- [x] `SettingsRepositoryImpl.load()` returns `Right(AppSettings)` with the 3 new fields populated; a data-source throw yields `Left(Failure.unknown)`.
- [x] Each new `saveX` returns `Right(null)` on success and `Left(Failure.unknown)` on a write throw.
- [x] Project-wide `dart analyze` is clean (no "missing concrete implementation" errors).
- [x] The full existing test suite still compiles (`flutter test` collects with no compile errors).

**Spec criteria addressed**: AC-9, AC-10, AC-17

## Completion Notes
**Status**: Complete
**Completed**: 2026-07-03
**Files changed**: `settings_repository.dart`, `settings_repository_impl.dart`, 8 hand-written fakes across 7 test files, **+1 unplanned**: `test/features/settings/data/repositories/settings_repository_impl_test.dart` (allowList fix)
**Contract**: Expects [verified] | Produces [all verified — 3 methods in contract, 3 getters in impl load(), 3 overrides per fake]
**Code review**: APPROVE (no critical/warning; 2 Info — both deferred/pre-existing)
**Verification**: project-wide `dart analyze` clean; full suite 681/681 green (independently re-run by orchestrator).
**Notes**: Unplanned but necessary: `settings_repository_impl_test.dart` hardcoded 4 `SharedPreferencesWithCache` allowLists listing only the OLD 4 keys → once `load()` read the 3 new keys, the cache threw (out-of-allowlist) and `load()` returned `Left`, reddening 14 tests. Fixed by adding the 3 new keys to each literal allowList. Production was unaffected (it uses the shared `settingsPrefsKeys` superset). The 4 mocktail `_MockSettingsRepository extends Mock` classes were correctly left untouched.
