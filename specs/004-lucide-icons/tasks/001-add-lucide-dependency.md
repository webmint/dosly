### Task 001: Add lucide_icons_flutter dependency

**Agent**: mobile-engineer
**Files**: `pubspec.yaml`
**Depends on**: None
**Blocks**: 002
**Context docs**: None
**Review checkpoint**: No

**Description**:
Add the `lucide_icons_flutter` package to the project's dependencies. This is the Lucide icon set for Flutter, providing `IconData` constants via the `LucideIcons` class. The package is a drop-in replacement for `Icons.*` — same API, different icon source.

**Change details**:
- In `pubspec.yaml`:
  - Add `lucide_icons_flutter: ^3.1.12` to the `dependencies:` section, after `go_router`
  - Run `flutter pub get` to resolve the dependency

**Done when**:
- [x] `pubspec.yaml` contains `lucide_icons_flutter: ^3.1.12` under `dependencies`
- [x] `flutter pub get` completes without errors
- [x] `dart analyze` passes

**Spec criteria addressed**: AC-1

**Status**: Complete

## Completion Notes
**Completed**: 2026-04-12
**Files changed**: `pubspec.yaml`, `pubspec.lock`
**Contract**: Expects 2/2 verified | Produces 2/2 verified
**Notes**: Clean addition, no issues.

## Contracts

### Expects
- `pubspec.yaml` exists with a `dependencies:` section containing `flutter`, `cupertino_icons`, and `go_router`
- Project builds successfully (`flutter pub get` resolves all current dependencies)

### Produces
- `pubspec.yaml` `dependencies:` section contains `lucide_icons_flutter: ^3.1.12`
- `flutter pub get` resolves successfully (lockfile updated with lucide_icons_flutter)
