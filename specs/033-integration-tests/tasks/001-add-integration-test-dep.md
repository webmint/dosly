# Task 001: Add the integration_test dev dependency

**Agent**: qa-engineer
**Files**: `pubspec.yaml`
**Depends on**: None
**Blocks**: 003, 004
**Context docs**: `specs/033-integration-tests/plan.md` (Dependencies section)
**Review checkpoint**: No

**Description**:
Add the `integration_test` Flutter SDK package to `dev_dependencies` so the new `integration_test/` suite can run on a device/emulator. This is a clean rollback boundary — every harness/test task depends on it resolving.

**Change details**:
- In `pubspec.yaml`:
  - Run `flutter pub add --dev integration_test` (constitution §2.3 — never hand-edit). It resolves to the SDK-pinned version:
    ```yaml
    dev_dependencies:
      integration_test:
        sdk: flutter
    ```
  - Do NOT add `path_provider` yet — only if Task 007 finds the smoke-file path can't be resolved transitively via `drift_flutter`.

**Done when**:
- [x] `pubspec.yaml` `dev_dependencies` contains `integration_test` with `sdk: flutter`
- [x] `flutter pub get` resolves cleanly (no version conflicts)
- [x] `pubspec.lock` lists `integration_test`
- [x] `dart analyze` passes (no new issues)

**Spec criteria addressed**: AC-1

## Contracts

### Expects
- `pubspec.yaml` has a `dev_dependencies:` block containing `flutter_test:` with `sdk: flutter`
- `pubspec.yaml` `dependencies:` contains `drift_flutter` and `drift` (already present)

### Produces
- `pubspec.yaml` `dev_dependencies:` contains a key `integration_test:` with nested `sdk: flutter`
- `pubspec.lock` contains an `integration_test` package entry

## Completion Notes

**Status**: Complete
**Completed**: 2026-06-18
**Files changed**: `pubspec.yaml`, `pubspec.lock`
**Contract**: Expects [2/2 verified] | Produces [2/2 verified]
**Notes**: `flutter pub add --dev integration_test` resolves to a discontinued pre-null-safety pub.dev package incompatible with the SDK constraint; SDK-bundled packages must be declared `integration_test: { sdk: flutter }` (same as `flutter_test`/`flutter_localizations`). Justified deviation from §2.3's "use pub add" — end state is the canonical SDK form. Six transitive lock entries added (flutter_driver, fuchsia_remote_debug_protocol, process, sync_http, webdriver). `dart analyze`: No issues found.
