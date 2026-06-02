# Task 5: Logger pipeline tests (level, idempotency, provider)

**Agent**: qa-engineer
**Files**: `test/core/logging/logger_test.dart`
**Depends on**: 4
**Blocks**: None
**Review checkpoint**: No
**Context docs**: None
**Status**: Complete

## Completion Notes
**Completed**: 2026-06-01
**Files changed**: `test/core/logging/logger_test.dart` (new)
**Contract**: Expects 1/1 verified | Produces 2/2 verified
**Notes**: 6 tests / 4 groups (levelFor both branches, release suppression zero-emit under Level.OFF, idempotent single-emit after double configure + sanitization proof, loggerProvider returns Logger + info/warning/severe no-throw). Global `tearDown(Logger.root.clearListeners)` + per-test `addTearDown(sub.cancel/container.dispose)` prevents leakage into the shared process-global `Logger.root`. Full suite of 285 tests green — confirms no cross-file listener leak.

**Description**:
Tests for the logger wiring that exercise the testability seams from Task 4 — the pure `levelFor`, the injectable sink, and the provider value — without toggling `kReleaseMode`/`kDebugMode` or intercepting `dart:developer`.

**Change details**:
- Create `test/core/logging/logger_test.dart`:
  - `levelFor`: assert `levelFor(isRelease: true) == Level.OFF` and `levelFor(isRelease: false) == Level.ALL` (AC-4).
  - Release suppression: configure the pipeline with `Level.OFF` and a capturing sink, log a record, assert the sink received **zero** invocations (AC-4).
  - Idempotent single-emit: configure with `Level.ALL` + a capturing sink, log once, assert the sink received **exactly one** invocation and that the captured `SanitizedLog` reflects sanitization (AC-3). Tear down the subscription after the test.
  - Provider value: read `loggerProvider` from a `ProviderContainer`, assert it returns a `Logger` exposing `info`/`warning`/`severe` (call each; no throw) (AC-2). Dispose the container.

**Done when**:
- [ ] `test/core/logging/logger_test.dart` exists
- [ ] `levelFor` both branches asserted
- [ ] Zero-emit-under-`Level.OFF` and single-emit-under-`Level.ALL` asserted via capturing sink
- [ ] `loggerProvider` returns a `Logger` with `info`/`warning`/`severe`
- [ ] Each test cancels its subscription / disposes its container (no cross-test listener leak)
- [ ] `flutter test test/core/logging/logger_test.dart` passes
- [ ] `dart analyze` passes on changed files

**Spec criteria addressed**: AC-2, AC-3, AC-4

## Contracts

### Expects
- `lib/core/logging/logger.dart` exports `loggerProvider`, `levelFor({required bool isRelease})`, and an injectable-sink configuration seam (Task 4).

### Produces
- `test/core/logging/logger_test.dart` asserts `levelFor(isRelease: true) == Level.OFF`, single-emit via a capturing sink, and that `loggerProvider` yields a `Logger`.
- `flutter test` passes for this file.
