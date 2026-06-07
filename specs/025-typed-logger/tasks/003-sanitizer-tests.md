# Task 3: Sanitizer test suite (leak tests + per-variant)

**Agent**: qa-engineer
**Files**: `test/core/logging/log_sanitizer_test.dart`
**Depends on**: 2
**Blocks**: None
**Review checkpoint**: No
**Context docs**: None
**Status**: Complete

## Completion Notes
**Completed**: 2026-06-01
**Files changed**: `test/core/logging/log_sanitizer_test.dart` (new)
**Contract**: Expects 1/1 verified | Produces 2/2 verified
**Notes**: 18 tests across 6 groups (Failure sanitization ×9, Leak prevention ×3, includeErrorDetail, Stack truncation ×2, Null error, Message passthrough). 100% branch coverage of the sanitizer. All pass; analyze clean. Leak tests are in `group('Leak prevention')` (the per-variant tests are in `group('Failure sanitization')`).

**Description**:
Exhaustive unit tests for the sanitizer — this is the security surface, so coverage must include the three mandatory leak tests and at least one test per `Failure` variant. Tests call the pure `sanitizeRecord` directly and assert on the returned `SanitizedLog` strings (no `dart:developer` interception needed).

**Change details**:
- Create `test/core/logging/log_sanitizer_test.dart`:
  - `group('Failure sanitization', ...)` with ≥1 test per variant covering the redact/keep decision (NotFound.id redacted, Cache.message redacted, PermissionDenied.permission kept, NotificationSchedule.reason redacted, Validation.field kept + message redacted, Unknown → runtimeType only).
  - The three load-bearing leak tests (build a `LogRecord` with the given `error`, call `sanitizeRecord(record, includeErrorDetail: false)`, assert the concatenated `SanitizedLog` strings do NOT contain the secret):
    1. `UnknownFailure(PlatformException(... '/Users/.../db.sqlite write failed'), stack)` → output excludes `/Users/.../db.sqlite`.
    2. `ValidationFailure(field: 'name', message: 'Aspirin is not a valid name')` → output excludes `Aspirin`.
    3. `CacheFailure('FileSystemException: /data/data/app.dosly/shared_prefs/...')` → output excludes the path.
  - `includeErrorDetail` test: with `true`, `UnknownFailure` error string includes the detail; with `false`, it does not.
  - Stack truncation test: a long stack trace yields ≤ ~10 lines in `SanitizedLog.stack`.

**Done when**:
- [ ] `test/core/logging/log_sanitizer_test.dart` exists
- [ ] The three leak tests assert *absence* of the secret substrings
- [ ] At least one test per `Failure` variant
- [ ] `includeErrorDetail` true/false both asserted
- [ ] `flutter test test/core/logging/log_sanitizer_test.dart` passes
- [ ] `dart analyze` passes on changed files

**Spec criteria addressed**: AC-7, AC-8, AC-6

## Contracts

### Expects
- `lib/core/logging/log_sanitizer.dart` exports `SanitizedLog` and `sanitizeRecord(LogRecord, {required bool includeErrorDetail})` (Task 2).

### Produces
- `test/core/logging/log_sanitizer_test.dart` contains a `group('Failure sanitization'` and three tests asserting the absence of `db.sqlite`/`Aspirin`/`shared_prefs` path substrings.
- `flutter test` passes for this file.
