# Task 001: Add drift + uuid dependencies

**Agent**: architect
**Files**: `pubspec.yaml`, `pubspec.lock`
**Depends on**: None
**Blocks**: 005, 006
**Context docs**: `specs/032-med-persistence/plan.md` (Dependencies section)
**Review checkpoint**: No

**Description**:
Add the local-database stack and the UUID generator as project dependencies. These are the first persistence libraries in the codebase. Per constitution §2.3, use `flutter pub add` (never hand-edit `pubspec.yaml`) so the declared constraint matches the resolved version.

**Change details**:
- Run: `flutter pub add drift drift_flutter sqlite3_flutter_libs uuid`
- Run: `flutter pub add --dev drift_dev`
- Run `flutter pub get` (implicit) and confirm resolution succeeds.
- Do NOT add `path`/`path_provider` explicitly — `drift_flutter` pulls and manages them.

**Done when**:
- [ ] `pubspec.yaml` lists `drift`, `drift_flutter`, `sqlite3_flutter_libs`, `uuid` under `dependencies` and `drift_dev` under `dev_dependencies`, each with a caret constraint matching the resolved version
- [ ] `flutter pub get` completes without error
- [ ] `dart analyze` passes (no new issues)

## Contracts
### Expects
- `pubspec.yaml` exists with `dependencies` and `dev_dependencies` sections (current state)
### Produces
- `pubspec.yaml` `dependencies` contains `drift:`, `drift_flutter:`, `sqlite3_flutter_libs:`, `uuid:`
- `pubspec.yaml` `dev_dependencies` contains `drift_dev:`

**Spec criteria addressed**: AC-1

## Completion Notes
**Completed**: 2026-06-17
**Status**: Complete
**Files changed**: pubspec.yaml, pubspec.lock
**Contract**: Expects 1/1 | Produces 2/2
**Notes**: Drift stack resolved to **2.31.x** (not latest 2.34.x): the Flutter SDK pins `meta 1.17.0` → `analyzer 9.0.0` ceiling (shared with freezed + riverpod_generator), and drift_dev for 2.34 needs analyzer ≥10. Must add the whole stack in ONE `flutter pub add ... dev:drift_dev` solve (adding runtime deps first locks drift to 2.34 and leaves no compatible drift_dev). Versions: drift/drift_dev ^2.31.0, drift_flutter ^0.2.8, sqlite3_flutter_libs ^0.5.42, uuid ^4.5.3.
