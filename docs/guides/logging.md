# Logging

## Overview

dosly uses a typed, PHI-safe logging pipeline built on `package:logging`. Every
log record passes through a single sanitize choke point before reaching any
sink, so Protected Health Information (medication names, dosages, intake data)
cannot leak into logs regardless of which call site produced the record.

## How It Works

```
call site (ref.read(loggerProvider).warning(...))
  → Logger('dosly')
  → single Logger.root.onRecord listener (registered by loggerProvider on first read)
  → sanitizeRecord(record, includeErrorDetail: kDebugMode)  ← the choke point
  → dart:developer log() sink
```

`loggerProvider` (`@Riverpod(keepAlive: true)`, `lib/core/logging/logger.dart`)
registers exactly one `Logger.root.onRecord` listener via `configureLogging`.
Any prior listener is cancelled first — the pipeline is idempotent across hot
reloads and test containers. The subscription is cancelled on `ref.onDispose`.

**Release no-op**: `levelFor(isRelease: kReleaseMode)` sets `Level.OFF` in
release builds. No record is ever delivered to the listener, so there is zero
sink cost in production. dosly has no backend telemetry endpoint; if that
changes, `levelFor` and the sink injection point in `configureLogging` are the
migration targets.

## Usage

Obtain the logger through the provider and pass the error or `Failure` as the
second argument to the logging method — never interpolate it into the message
string:

```dart
// Good — error payload goes through sanitizeRecord automatically.
final log = ref.read(loggerProvider);
log.warning('Route resolution failed', error);

// Good — structured Failure passed as the error arg.
result.fold(
  (failure) => log.warning('Settings save failed', failure),
  (_) { /* success */ },
);
```

### PHI safety rule

**Never interpolate PHI into the message string.** `sanitizeRecord` guarantees
the structured error/`Failure` argument is leak-free, but it passes the message
string through verbatim. Medication names, dosages, and intake values must not
appear in the message:

```dart
// BAD — medication name in message string, not sanitized.
log.warning('Failed to save ${med.name}');

// GOOD — keep the message a static string; pass the error object.
log.warning('Medication save failed', failure);
```

### What each `Failure` field discloses vs. redacts

| Failure | Disclosed | Redacted |
|---|---|---|
| `NotFoundFailure` | type name only | `.id` |
| `CacheFailure` | type name only | `.message` (may contain filesystem paths) |
| `PermissionDeniedFailure` | `.permission` (e.g. `POST_NOTIFICATIONS`) | — |
| `NotificationScheduleFailure` | type name only | `.reason` |
| `ValidationFailure` | `.field` (enum-like identifier) | `.message` (may contain user-entered text) |
| `UnknownFailure` | wrapped error `runtimeType` (+ full `toString()` when `kDebugMode`) | wrapped error detail in release/profile |

Any non-`Failure` error object: `runtimeType` only by default; full
`toString()` only when `includeErrorDetail` is `true` (= `kDebugMode`).

### Startup wiring

`AppBootstrap` calls `ref.read(loggerProvider)` as a side effect in its `build`
method so the `Logger.root` listener is registered before any route can fail:

```dart
// lib/app_bootstrap.dart
ref.read(loggerProvider); // side-effect: registers Logger.root listener
```

All subsequent reads of `loggerProvider` return the same interned
`Logger('dosly')` instance — `package:logging` caches by name.

## Related

- [architecture.md §Logging](../architecture.md#logging) — pipeline diagram,
  provider table entry, and release no-op rationale
- `lib/core/logging/logger.dart` — provider, `configureLogging`, `levelFor`, `LogSink`
- `lib/core/logging/log_sanitizer.dart` — `sanitizeRecord`, `SanitizedLog`,
  redact-by-default policy
