# Bug 017: Typed logger from `core/logging/` does not exist

**Status**: Open
**Severity**: Medium
**Source**: spec 013 spin-off (originally flagged inside bug 002 description)
**Reported**: 2026-05-01
**Fixed**:

## Description

Constitution §7.1 step #3 prescribes the creation of a typed logger at
`lib/core/logging/logger.dart` (consider `package:logging` + a sanitize
layer). The file does not yet exist.

Constitution §4.2.1 [enforced]: "Never use `print()` or `debugPrint()` in
committed code. Use the typed logger from `core/logging/`. The `avoid_print`
lint must remain enabled."

Constitution §4.2.1 [enforced]: "Never log medication names, dosages, or
intake history. These are sensitive PHI even for personal use. The logger
must have a sanitize layer."

The combination is load-bearing: §4.2.1 forbids `debugPrint` and requires
the logger to exist as the compliant alternative, but the logger itself
hasn't been built. Until it lands, every code path that "wants to log
something" is forced to either (a) propagate the failure to the UI, or
(b) silently drop the diagnostic — neither of which is a true logging
posture.

This was originally noted inside bug 002's description as "a separate gap"
and is being formally tracked here so spec 013 (the bug 002 fix) can
explicitly cite it as out-of-scope rather than allowing it to drop off the
radar.

## File(s)

| File | Detail |
|------|--------|
| lib/core/logging/logger.dart | Does not exist. Should be created per constitution §7.1 step #3. |

## Evidence

`constitution.md:88` (file inventory in §2.2):
```
│   ├── logging/logger.dart                  # typed logger (no print/debugPrint anywhere else)
```

`constitution.md:560–562` (§7.1 first-files-to-create order):
```
3. `lib/core/logging/logger.dart` — typed logger (consider `package:logging` + a sanitize layer)
```

`constitution.md:359` (§4.2.1):
```
- [enforced] **Never log medication names, dosages, or intake history.**
  These are sensitive PHI even for personal use. The logger must have a
  sanitize layer.
```

`bugs/002-debugprint-in-settings-provider.md:21–23`:
> The typed logger (`lib/core/logging/logger.dart`, prescribed by constitution
> §7.1 step #3) does not exist yet, which is itself a separate gap. Once it
> lands, all four sites should route through it (with a sanitize layer per §4.2.1
> PHI rule).

`ls lib/core/` returns: `error/`, `providers/`, `routing/`, `theme/`, `widgets/`
— no `logging/` directory.

## Fix Notes

Suggested approach (to be confirmed in `/specify`):

1. Add `package:logging` (or pick an alternative — `logger`, `talker`) as a
   runtime dependency.
2. Create `lib/core/logging/logger.dart` exposing a single typed logger
   instance plus level helpers (`info`, `warning`, `severe`).
3. Implement a **sanitize layer** that strips PHI tokens before any
   message is emitted. At minimum: medication names, dosages, intake
   timestamps, schedule strings. The sanitizer is the most important
   piece — without it, the typed logger is no better than `debugPrint`
   for §4.2.1 compliance.
4. Wire a single `loggerProvider` (Riverpod) so call sites can consume it
   via `ref.read(loggerProvider).warning(...)` instead of importing a
   bare top-level instance (testability + override-in-tests).
5. Land separately from spec 013 so the logger arrives with proper test
   coverage of the sanitize layer (the sanitize layer is the security
   surface — it must have its own tests).

This bug is a prerequisite for any future code path that needs to record
a non-fatal diagnostic without surfacing it to the UI. Spec 013 deliberately
defers any logging at the four `debugPrint` sites until this lands.

## Additional Finding: `Failure`-aware sanitizer (added 2026-05-17 by spec 017 /review)

Spec 017 (bug 006 fix) landed the constitution-§3.2 `@freezed sealed class Failure`
union with six variants, including `Failure.unknown(Object error, StackTrace stack)`.
The security review flagged `UnknownFailure.toString()` (generated at
`lib/core/error/failures.freezed.dart:558–560`) as **CWE-209 / CWE-532** because it
emits `error.toString()` verbatim — common Flutter throwables like
`PlatformException`, `FileSystemException`, and drift exceptions serialize
filesystem paths, package IDs, SQL fragments, and table/row IDs through their
default `toString()`. When this typed logger lands and consumes `Failure` payloads
via the standard `failure.toString()` interpolation, those internals will leak
into logs without any sanitization — directly violating §4.2.1's PHI rule.

Spec 017 mitigated this for the empty-variant phase by adding a 4-line dartdoc
warning on the `Failure.unknown` factory at `lib/core/error/failures.dart:43–47`.
That dartdoc is developer-facing guidance only; a real defense requires this
bug's sanitize layer to be **`Failure`-aware**.

### Scope addition for this bug's `/specify`

The sanitize layer (step #3 in Fix Notes above) must, in addition to stripping
medication names / dosages / intake timestamps, intercept any `Failure` payload
and route it through a variant-aware redactor. Use the generated `when` / `map`
matchers from `lib/core/error/failures.freezed.dart`:

| Variant | Field | Default disposition |
|---------|-------|---------------------|
| `NotFoundFailure` | `id` (`String?`) | **Redact-by-default** — bare `MedicationId.value` is a correlation vector when combined with surrounding log context. Allowlist per call site if needed. |
| `CacheFailure` | `message` (`String`) | **Redact-by-default until bug 010 lands.** Today this is `e.toString()` from a platform exception (path leakage). Only allowlist once bug 010 fixes the data layer to pass static reason strings (e.g. `'shared_preferences_write_failed'`). |
| `PermissionDeniedFailure` | `permission` (`String`) | **Safe to log** — OS-level identifiers (`POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`). |
| `NotificationScheduleFailure` | `reason` (`String`) | **Redact-by-default** — free-form string from a platform exception. Treat like `CacheFailure.message`. |
| `ValidationFailure` | `field` (`String`) | **Safe to log if call sites use closed enum-like strings** (`'name'`, `'dosage'`, `'frequency'`). Reject at lint time if call sites use free-form user input. |
| `ValidationFailure` | `message` (`String`) | **Redact-by-default** — may contain user input including PHI (e.g. medication names entered in the validation message). |
| `UnknownFailure` | `error` (`Object`) | **Redact-by-default — most important case.** Log only `error.runtimeType.toString()` by default. Route the full `error.toString()` to a developer-only sink gated by `kDebugMode`. Never to production logs / telemetry / analytics. |
| `UnknownFailure` | `stack` (`StackTrace`) | **Safe by default** — stack frames reference source files, not user data. But truncate to first ~10 frames to bound log size. |

### Test surface this adds

The sanitize layer's tests (step #5 in Fix Notes) must include a `group('Failure
sanitization', ...)` with at least one test per variant covering the redact /
allowlist decision above. The most load-bearing tests:

1. `UnknownFailure(PlatformException(code: 'IO', message: '/Users/.../db.sqlite write failed'), stack)` — the sanitized log line must NOT contain `/Users/.../db.sqlite`.
2. `ValidationFailure(field: 'name', message: 'Aspirin is not a valid name')` — the sanitized log line must NOT contain `Aspirin`.
3. `CacheFailure('FileSystemException: /data/data/app.dosly/shared_prefs/...')` — same redaction principle.

### Cross-reference

- `bugs/006-failure-hierarchy-incomplete.md` (Closed by spec 017) — defines the union shape.
- `bugs/010-repository-catches-only-exception.md` — when fixed, the upstream catches should produce sanitized `Failure.cache(staticReason)` or `Failure.unknown(e, st)` rather than `Failure.cache(e.toString())`. The logger's redact-by-default policy on `CacheFailure.message` becomes safer once bug 010 lands.
- `specs/017-failure-freezed/review.md` — security review's Medium finding documenting CWE-209 / CWE-532 exposure.
- `lib/core/error/failures.dart:43–47` — dartdoc warning on `Failure.unknown.error` flagging PII risk.
