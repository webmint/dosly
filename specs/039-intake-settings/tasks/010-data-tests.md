# Task 010: Unit tests — data source + repository

**Agent**: qa-engineer
**Files**: `test/features/settings/data/datasources/settings_local_data_source_test.dart` (extend or new), `test/features/settings/data/repositories/settings_repository_impl_test.dart` (extend or new)
**Depends on**: 002, 004
**Blocks**: None
**Context docs**: None
**Review checkpoint**: No

**Description**:
Cover the new data-source read/write pairs (round-trip, clamp-on-read, missing-key default) and the repository's `load()` + three `saveX` (success + failure). Use a fake/in-memory `SharedPreferencesWithCache` (mirror the existing settings data-source test setup) and, for the repo failure paths, a data source stubbed to throw.

**Change details**:
- Data-source tests: `set → get` round-trip for window/grace/bool; raw out-of-range int reads back clamped (500→240, 3→15, 99→30, −5→0); absent key → default (120 / 5 / false).
- Repo tests: `load()` returns `Right(AppSettings)` with the three new fields from the data source; a throwing getter → `Left(Failure.unknown)`; each `saveX` returns `Right(null)` on success and `Left(Failure.unknown)` when the setter throws.

**Contracts**:

### Expects
- `SettingsLocalDataSource` exposes the six new get/set methods with clamp-on-read (Task 002).
- `SettingsRepositoryImpl.load()` populates the new fields and the three `saveX` exist (Task 004).

### Produces
- Data-source and repository test files asserting round-trip, clamp, default, and success/failure `Either` paths for the new settings.

**Done when**:
- [x] `flutter test test/features/settings/data/` passes.
- [x] Clamp-on-read and missing-key-default cases are asserted for both numerics.
- [x] `saveX` success (`Right`) and throw (`Left`) paths asserted.
- [x] `dart analyze` passes on the changed test files.

**Spec criteria addressed**: AC-6, AC-7, AC-8, AC-9, AC-10

## Completion Notes
**Status**: Complete
**Completed**: 2026-07-03
**Files changed**: `settings_local_data_source_test.dart`, `settings_repository_impl_test.dart` (both extended)
**Contract**: Produces [verified — round-trip, clamp-on-read via RAW seeded ints, missing-key defaults, load() + saveX Right/Left]
**Code review**: APPROVE (coherence check passed — pure-insertion diff; clamp tests exercise raw ints not the VO factory; 2 Info: allowList-literal drift [already in MEMORY], minor style)
**Notes**: First agent's connection DROPPED after only setup prep (VO imports + 3 keys added to the datasource test allowList); resumed by a second qa-engineer that added 28 tests on top. 66 data tests pass. Reviewer diff-confirmed no duplicate/orphaned blocks from the split.
