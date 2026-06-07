# Task 2: Implement the pure PHI / `Failure`-aware sanitizer

**Agent**: architect
**Files**: `lib/core/logging/log_sanitizer.dart`
**Depends on**: 1
**Blocks**: 3, 4
**Review checkpoint**: Yes
**Context docs**: `specs/025-typed-logger/research.md` (per-variant disposition rationale)
**Status**: Complete

## Completion Notes
**Completed**: 2026-06-01
**Files changed**: `lib/core/logging/log_sanitizer.dart` (new)
**Contract**: Expects 2/2 verified | Produces 3/3 verified
**Code review**: APPROVE WITH WARNINGS → both addressed. W1 (shadowed `error` → `innerError` in UnknownFailure case), W2 (lying class dartdoc claiming all 3 fields PHI-free → corrected to exclude verbatim `message`).
**Notes**: Pure file — imports only `package:logging` + `../error/failures.dart`. Exhaustive sealed `switch`, no `default:`. `_renderOpaque` emits `runtimeType` only when `includeErrorDetail: false`, so PlatformException paths don't leak. Stack bounded to 10 frames. Private consts `_redacted = '‹redacted›'` and `_maxStackFrames = 10` — tests must hardcode these (not `@visibleForTesting`).

**Description**:
Implement the security-critical core: a **pure** function that turns a `LogRecord` into a sanitized value object, applying the redact-by-default policy from spec §3.3. This file must have **no dependency on `dart:developer` or Riverpod** so it is unit-testable in isolation. It is the single point where PHI / CWE-209/532 leakage is prevented.

**Change details**:
- Create `lib/core/logging/log_sanitizer.dart`:
  - Define `SanitizedLog` — an immutable value object with `String message`, `String error` (empty when no error), and `String? stack`.
  - Define `SanitizedLog sanitizeRecord(LogRecord record, {required bool includeErrorDetail})`:
    - `message`: pass `record.message` through (PHI backstop — see dartdoc note that call sites must not interpolate PHI; the sanitizer guarantees the *error* payload is safe).
    - `record.error == null` → `error = ''`.
    - `record.error is Failure` → dispatch via an exhaustive `switch` (no `default:`) over the sealed union, applying the disposition table:
      - `NotFoundFailure` → redact `id`.
      - `CacheFailure` → redact `message`.
      - `PermissionDeniedFailure` → keep `permission` (safe OS identifier).
      - `NotificationScheduleFailure` → redact `reason`.
      - `ValidationFailure` → keep `field`, redact `message`.
      - `UnknownFailure` → emit `error.runtimeType` only; include `error.toString()` **only** when `includeErrorDetail` is true.
    - `record.error` is any other `Object` → emit `runtimeType` only; full `toString()` only when `includeErrorDetail`.
    - `stack`: when present and safe, truncate to the first ~10 frames (`StackTrace.toString().split('\n').take(10)`); otherwise `null`.
  - Use a single redaction placeholder constant (e.g. `const _redacted = '‹redacted›'`).
  - Dartdoc on `SanitizedLog`, `sanitizeRecord`, and an inline comment documenting the redact-by-default policy.

**Done when**:
- [ ] `lib/core/logging/log_sanitizer.dart` exists and compiles
- [ ] `sanitizeRecord` matches `Failure` with an exhaustive `switch` and no `default:` clause
- [ ] No import of `dart:developer`, `package:flutter`, or Riverpod in this file
- [ ] All public declarations have dartdoc
- [ ] `dart analyze` passes on changed files

**Spec criteria addressed**: AC-5, AC-6, AC-8 (partial: AC-7 verified by Task 3 tests)

## Contracts

### Expects
- `package:logging` resolves (Task 1) — `LogRecord` importable.
- `lib/core/error/failures.dart` exports a sealed `Failure` with subclasses `NotFoundFailure`, `CacheFailure`, `PermissionDeniedFailure`, `NotificationScheduleFailure`, `ValidationFailure`, `UnknownFailure`.

### Produces
- `lib/core/logging/log_sanitizer.dart` exports a class `SanitizedLog` with fields `message`, `error`, `stack`.
- exports `SanitizedLog sanitizeRecord(LogRecord record, {required bool includeErrorDetail})`.
- the function body contains a `switch` over the `Failure` variants with no `default:` case.
