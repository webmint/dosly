# Research: Typed Logger with PHI Sanitize Layer

**Date**: 2026-06-01
**Signals detected**: External package not in dependencies (`package:logging`); architectural decision with multiple valid approaches (logger backend choice); greenfield pattern (first logging infrastructure in the codebase).

## Questions Investigated

1. **Which logging backend?** → `package:logging` (Dart-team maintained). Chosen over a bare `dart:developer` wrapper and over `talker`/`logger`. Decisive factor: `Logger.root.onRecord` is a **single structural choke point** through which every record flows — placing the PHI sanitizer there makes bypass structurally impossible, satisfying §4.2.1 by construction rather than by a lint that hopes no call site calls `dev.log` directly. (Decided with user during `/specify`.)

2. **What does the call/listener API look like?** → Verified against live pub.dev docs (`/websites/pub_dev_logging`, High reputation):
   - `Logger.root.onRecord.listen((LogRecord r) {...})` — the sink.
   - `LogRecord` fields: `level` (`Level`), `message` (`String`), `loggerName` (`String`), `error` (`Object?`), `stackTrace` (`StackTrace?`), `time`, `sequenceNumber`.
   - Level methods on a `Logger`: `info` / `warning` / `severe` etc.
   - `Logger.root.level` is the global filter threshold; records below it never reach the listener.
   - A `Failure` is passed as the `error` argument: `log.warning('msg', failure)` → arrives as `record.error`.

3. **How to make release builds a no-op without losing testability?** → `Logger.root.level = kReleaseMode ? Level.OFF : Level.ALL`. Because `kReleaseMode` is a compile-time const (cannot be toggled in tests), the level decision is extracted into a **pure** `levelFor({required bool isRelease})` so both branches are unit-tested directly. (Decided with user during `/specify`.)

4. **Where is the listener registered, given `main()` is synchronous and wraps `ProviderScope`?** → Through Riverpod, not a bare `main()` side-effect. A keep-alive `loggerProvider` configures `Logger.root` (level + sanitizing listener) on first read and cancels the subscription via `ref.onDispose`. Provider memoization gives idempotent single-registration per container (spec AC-3); `ref.onDispose` isolates test containers. `AppBootstrap` reads the provider once at startup to trigger configuration.

5. **How to test "no PHI leak" and "no double-emit" without intercepting `dart:developer log()`?** → Two seams:
   - The sanitizer is a **pure function** `sanitizeRecord(LogRecord, {required bool includeErrorDetail})` independent of `dart:developer` — tested directly on its returned strings (AC-5/6/7/8).
   - The listener forwards the sanitized result to an **injectable sink** (defaults to a `dart:developer log()` wrapper). Tests pass a capturing sink + an explicit `Level` to verify single-emit (AC-3) and release suppression (AC-4) without touching `kReleaseMode`/`kDebugMode`.

6. **Latest stable version?** → `logging: ^1.3.0` (pure-Dart, no transitive Flutter deps; compatible with SDK ^3.11.1). Exact resolved version confirmed by `flutter pub get` during execution.

## Alternatives Compared

### Logger backend
| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| `package:logging` | Single `onRecord` choke point → structural sanitizer; Dart-team maintained; literal §7.1 adherence; ~1 small pure-Dart dep | One new dependency | **Chosen** |
| `dart:developer` wrapper | Zero deps; minimal (§4.3) | Sanitizer enforcement is lint-based, not structural — a call site can bypass the wrapper via `dev.log` | Rejected |
| `talker` / `logger` | Rich DX, in-app log viewer | Overkill for a local-only no-telemetry app; larger surface to sanitize-wrap; against §4.3 | Rejected |

### Release-build behavior
| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| `Logger.root.level = Level.OFF` in release (via pure `levelFor`) | Idiomatic `package:logging` control surface; honors no-sink privacy posture; one line to flip to `Level.SEVERE` later; testable via pure helper | None for current requirements | **Chosen** |
| `kDebugMode` early-return in listener | Simple | Hand-rolled; not the library idiom; harder to relax later | Rejected |

### Retrofit scope
| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| Infra + 1 pilot (router error path) | Proves provider→sanitizer→sink wiring end-to-end with a real consumer; avoids unused infra (YAGNI); ≤5 source files | — | **Chosen** |
| Infra only | Smallest PR | Ships infrastructure with zero consumers (unproven integration) | Rejected |
| Infra + retrofit all deferred sites | Closes the deferral chain | >5 files; reopens bug 003 (UI) + bug 010 (CacheFailure strings) scope | Rejected (separate follow-ups) |

## References
- pub.dev `package:logging` API docs — `/websites/pub_dev_logging` (Context7, High reputation).
- `bugs/017-typed-logger-missing.md` — per-variant `Failure` sanitizer disposition table.
- `specs/017-failure-freezed/review.md` — CWE-209/CWE-532 finding the sanitizer addresses.
- `lib/core/error/failures.dart:43–48` — `Failure.unknown` PII dartdoc warning.
- `lib/core/routing/app_router.dart:73` — router error path (pilot site).
- `lib/main.dart` — synchronous `ProviderScope` bootstrap (drives the provider-based registration decision).
