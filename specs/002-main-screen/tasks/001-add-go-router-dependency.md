# Task 001: Add go_router dependency

**Status**: Complete
**Agent**: mobile-engineer
**Files**: `pubspec.yaml`, `pubspec.lock`
**Depends on**: None
**Blocks**: 002, 003
**Context docs**: None
**Review checkpoint**: No

## Completion Notes

**Completed**: 2026-04-11
**Files changed**: `pubspec.yaml` (one line added at line 37), `pubspec.lock` (regenerated)
**Resolved version**: `go_router: ^17.2.0`
**Transitive deps added**: `logging` 1.3.0, `flutter_web_plugins` (from SDK)
**Contract**: Expects 3/3 verified | Produces 5/5 verified
**Verification**: `dart analyze` clean, `flutter test` all 79 tests passing (pre-existing tests still green because no code changes yet)
**Code review**: APPROVE, no findings
**Notes**: `flutter pub add go_router` inserted the line cleanly; no SDK mismatch encountered. pub's note about 3 packages with newer versions refers to Flutter-SDK-constrained transitives (meta, test_api, vector_math) — not actionable from this task.

## Description

Introduce `go_router` as the project's runtime routing dependency so downstream tasks can import `package:go_router/go_router.dart`. This is the first dependency added to dosly since the m3-theme spec. Use `flutter pub add go_router` so pub.dev resolves the current latest stable caret constraint — do not hardcode a version number. `pubspec.lock` regenerates automatically.

No other dependencies are added. Specifically forbidden by the spec's Out of Scope:
- `go_router_builder`
- `build_runner`
- `riverpod` / `flutter_riverpod` / `riverpod_annotation`
- `fpdart`, `freezed`, `drift`, `clock`, `logging`

## Change details

- In `pubspec.yaml`:
  - Run `flutter pub add go_router` from the repo root. This will insert a `go_router: ^<version>` line under the `dependencies:` section (between `flutter:` and `cupertino_icons:` or after `cupertino_icons:` — pub add picks). Accept whatever caret constraint pub.dev resolves.
  - Do not reorder, reformat, or rewrite any other lines in `pubspec.yaml`. No changes to `environment:`, `flutter:`, `fonts:`, or any comment block.
- In `pubspec.lock`:
  - Let `flutter pub add` regenerate this file mechanically. Do not hand-edit. The diff will include the new `go_router` entry and its transitive dependencies (typically `logging`, `meta` — these are pulled in automatically and do not count as "new dependencies added" for spec purposes since they are transitive).

## Done when

- [x] `pubspec.yaml` has a line `go_router: ^17.2.0` under `dependencies:`
- [x] `pubspec.yaml` is otherwise byte-for-byte identical to its pre-task state
- [x] `pubspec.lock` exists and contains a `go_router:` package entry at line 83
- [x] `flutter pub get` exits 0 with no errors or warnings
- [x] `dart analyze` exits 0 (No issues found!)
- [x] `flutter test` still passes (all 79 tests green)

## Contracts

### Expects

- `pubspec.yaml` exists at the repo root and contains a `dependencies:` section (currently listing `flutter:` and `cupertino_icons: ^1.0.8`).
- The project's `environment.sdk: ^3.11.1` constraint is compatible with the current `go_router` stable release (verify at runtime — if `flutter pub add` fails on SDK mismatch, stop and escalate).
- No existing `go_router:` line in `pubspec.yaml`.

### Produces

- `pubspec.yaml` contains a literal line matching `go_router: ^` under the `dependencies:` block.
- `pubspec.lock` contains a top-level entry `go_router:` with a `source: hosted` field and a resolved version string.
- `flutter pub get` exits 0.
- `package:go_router/go_router.dart` is resolvable by the Dart analyzer (i.e., later tasks can import it without "Target of URI doesn't exist" errors).

## Spec criteria addressed

- AC-1 (pubspec declares `go_router`; lock resolves cleanly; no other deps changed; no `go_router_builder`, no `build_runner`)

## Notes

- **SDK mismatch fallback**: If `flutter pub add go_router` fails because the installed Flutter SDK is older than the current `go_router` minimum (check the error message for "requires SDK version >= X"), stop the task and report. Two options: (a) user upgrades Flutter SDK, then retry; (b) pin to an older `go_router` release that matches the installed SDK (e.g., `flutter pub add go_router:^14.0.0`). The task cannot fix an SDK mismatch on its own.
- **Version drift note**: The resolved version will be recorded in `pubspec.lock`. Future specs should `cat pubspec.lock | grep go_router` to see what was actually installed, not guess from this task description.
- **Transitive dependencies**: `go_router` pulls in `logging`, `meta`, and possibly other Dart/Flutter-team packages. These are transitive and do not count as new dependencies for spec compliance.
