# Task 1: Add `logging` dependency

**Agent**: architect
**Files**: `pubspec.yaml`
**Depends on**: None
**Blocks**: 2, 4
**Review checkpoint**: No
**Context docs**: None
**Status**: Complete

## Completion Notes
**Completed**: 2026-06-01
**Files changed**: `pubspec.yaml`, `pubspec.lock`
**Contract**: Expects 1/1 verified | Produces 2/2 verified
**Notes**: `logging` resolved to 1.3.0, promoted from transitive to `direct main`. `dart analyze` clean. No source files touched.

**Description**:
Add the Dart-team `package:logging` as a runtime dependency so the sanitizer and logger can import `LogRecord`/`Logger`/`Level`. Pure-Dart package, no transitive Flutter deps. This is the only new dependency in the feature.

**Change details**:
- In `pubspec.yaml`:
  - Under `dependencies:`, add `logging: ^1.3.0` (alphabetical/grouped with the other runtime deps). Exact resolved version is whatever `flutter pub get` picks within the constraint.
- Run `flutter pub get` to resolve and update `pubspec.lock`.

**Done when**:
- [ ] `pubspec.yaml` lists `logging:` under `dependencies`
- [ ] `flutter pub get` completes without resolution errors on SDK ^3.11.1
- [ ] `pubspec.lock` contains a `logging` entry
- [ ] `dart analyze` passes on changed files

**Spec criteria addressed**: AC-1

## Contracts

### Expects
- `pubspec.yaml` has a `dependencies:` section and `environment.sdk` is `^3.11.1`.

### Produces
- `pubspec.yaml` contains the literal `logging:` key under `dependencies`.
- `pubspec.lock` contains a package entry named `logging`.
