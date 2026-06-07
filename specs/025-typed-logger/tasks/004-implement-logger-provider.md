# Task 4: Implement `loggerProvider` + `Logger.root` configuration

**Agent**: architect
**Files**: `lib/core/logging/logger.dart`, `lib/core/logging/logger.g.dart` (generated)
**Depends on**: 1, 2
**Blocks**: 5, 6
**Review checkpoint**: Yes
**Context docs**: `specs/025-typed-logger/research.md` (API + registration decisions)
**Status**: Complete

## Completion Notes
**Completed**: 2026-06-01
**Files changed**: `lib/core/logging/logger.dart` (new), `lib/core/logging/logger.g.dart` (generated)
**Contract**: Expects 2/2 verified | Produces 5/5 verified
**Code review**: APPROVE WITH WARNINGS → W1 fixed (configureLogging now cancels a prior listener via module-level `_activeSubscription` before registering — idempotent by construction, robustly satisfies AC-3 independent of caller disposal), W2 fixed (inline note that `Logger('dosly')` returns the interned instance).
**Notes**: Seams = pure `levelFor({required bool isRelease})`, injectable `LogSink` (default `_developerLogSink`), independently-callable `configureLogging({level, includeErrorDetail, sink})`. Provider wires `levelFor(isRelease: kReleaseMode)` + `includeErrorDetail: kDebugMode`. Single `onRecord.listen` (logger.dart:89), cancelled in `ref.onDispose`. Sink consumes only the sanitized `SanitizedLog`, never the raw record.

**Description**:
Wire the logging pipeline. A keep-alive `@riverpod loggerProvider` returns a named `Logger` and, on first build, configures `Logger.root` (build-mode level + a single sanitizing listener). The listener routes each record through `sanitizeRecord` (Task 2) and forwards the result to an injectable sink defaulting to a `dart:developer log()` wrapper. The subscription is cancelled via `ref.onDispose`. Convergence point — depends on the dependency (Task 1) and the sanitizer (Task 2).

**Change details**:
- Create `lib/core/logging/logger.dart`:
  - `Level levelFor({required bool isRelease}) => isRelease ? Level.OFF : Level.ALL;` (pure, top-level, dartdoc).
  - A sink typedef, e.g. `typedef LogSink = void Function(SanitizedLog log, Level level);` and a default sink that calls `dart:developer`'s `log()` (`name: 'dosly'`, `level: level.value`).
  - A configuration function that: sets `Logger.root.level = levelFor(isRelease: kReleaseMode)`, registers a single `Logger.root.onRecord.listen` that calls `sanitizeRecord(record, includeErrorDetail: kDebugMode)` then the sink, and returns the `StreamSubscription` so it can be cancelled. Accept the sink as a parameter (default = dev-log sink) and `Level`/`includeErrorDetail` seams so tests can drive it without `kReleaseMode`/`kDebugMode`.
  - `@Riverpod(keepAlive: true) Logger logger(Ref ref) { ... }` — on build, call the configuration function, register `ref.onDispose(subscription.cancel)`, and return `Logger('dosly')`.
  - `part 'logger.g.dart';` and dartdoc on all public declarations.
- Run `build_runner` (or rely on the watch) to generate `logger.g.dart`.

**Done when**:
- [ ] `lib/core/logging/logger.dart` exists and compiles; `logger.g.dart` generated
- [ ] `loggerProvider` is generated from a `@Riverpod(keepAlive: true)` annotation and yields a `Logger`
- [ ] `levelFor` is a pure top-level function returning `Level.OFF` for release, `Level.ALL` otherwise
- [ ] Exactly one `Logger.root.onRecord.listen` is registered; subscription cancelled in `ref.onDispose`
- [ ] The sink is injectable (parameter with a default), enabling test capture
- [ ] All public declarations have dartdoc
- [ ] `dart analyze` passes on changed files

**Spec criteria addressed**: AC-2, AC-3, AC-4

## Contracts

### Expects
- `package:logging` resolves (Task 1).
- `lib/core/logging/log_sanitizer.dart` exports `sanitizeRecord` and `SanitizedLog` (Task 2).

### Produces
- `lib/core/logging/logger.dart` contains `@Riverpod(keepAlive: true)` and a function `Logger logger(Ref ref)` (→ generates `loggerProvider`).
- exports `Level levelFor({required bool isRelease})`.
- the file contains exactly one `Logger.root.onRecord.listen` registration and a `ref.onDispose` cancelling its subscription.
- the listener calls `sanitizeRecord` and forwards to an injectable sink (a `typedef`'d function parameter with a default).
