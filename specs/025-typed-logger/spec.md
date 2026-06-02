# Spec: Typed Logger with PHI Sanitize Layer

**Date**: 2026-06-01
**Status**: Complete
**Author**: Claude + Webmint

## 1. Overview

dosly's constitution (§7.1 step #3, §4.2.1) mandates a typed logger at `lib/core/logging/` as the *only* sanctioned alternative to `print`/`debugPrint`, with a mandatory PHI sanitize layer. The file has never been created (Bug 017), so a long chain of features (specs 010/012/013/018/019/022) has been forced to defer all diagnostic logging. This spec builds the logger infrastructure — a `package:logging`-based pipeline whose single root listener sanitizes every record before emitting — plus a `Failure`-aware redactor and one pilot integration in the router error path to prove the end-to-end wiring. Retrofitting the remaining deferred call sites is explicitly out of scope.

## 2. Current State

**No logging infrastructure exists.** `lib/core/logging/` does not exist. `pubspec.yaml` has no logging dependency. There are zero `print`/`debugPrint`/`developer.log` calls anywhere in `lib/` (verified via grep) — every code path that "wants to log" currently either propagates to the UI or silently drops the diagnostic.

**Deferred consumers waiting on this work** (NOT touched by this spec — see §6):
- `lib/features/settings/presentation/providers/settings_provider.dart` — four mutator Left-branches hold `(_) { /* deferred to bug 003 (UI) + bug 017 (logger) */ }` comments (specs 013).
- `lib/features/settings/data/datasources/settings_local_data_source.dart:44` — `getThemeMode()`'s broad `catch (_)` that bug 002/012 wanted narrowed to `on TypeError catch (e) { logger.warning(...); }`.
- `lib/core/routing/app_router.dart:73` — `errorBuilder: (context, state) => const _RouterErrorScreen()`. Spec 019 explicitly deferred logging here to bug 017. **This is the pilot call site** (see §3).

**The `Failure` union the sanitizer must handle** — `lib/core/error/failures.dart` (landed by spec 017), a `@freezed sealed` union with six variants:
- `NotFoundFailure { String? id }`
- `CacheFailure(String message)`
- `PermissionDeniedFailure(String permission)`
- `NotificationScheduleFailure(String reason)`
- `ValidationFailure { String field, String message }`
- `UnknownFailure(Object error, StackTrace stack)` — already carries a dartdoc PII warning (`failures.dart:43–47`). Its generated `toString()` (`failures.freezed.dart:558–560`) emits `error.toString()` verbatim → CWE-209/CWE-532 leakage of filesystem paths, SQL fragments, package IDs (flagged in `specs/017-failure-freezed/review.md`).

**Confirmed `package:logging` API** (verified against live pub.dev docs):
- `Logger.root.onRecord.listen((LogRecord r) {...})` — single choke point; every named logger's records flow through it.
- `LogRecord` fields: `level` (`Level`), `message` (`String`), `loggerName` (`String`), `error` (`Object?`), `stackTrace` (`StackTrace?`), `time`, `sequenceNumber`.
- Level methods: `info` / `warning` / `severe` etc.; `Logger.root.level` is the filter threshold.
- Call shape: `_log.warning('message', errorObject, stackTrace)` — a `Failure` is passed as the `error` argument.

**Riverpod**: codegen via `riverpod_annotation: ^4.0.2` is in deps (spec 015). The logger is exposed via an `@riverpod` provider per constitution §4.3.1 and Bug 017 Fix Note #4.

## 3. Desired Behavior

### 3.1 Logger infrastructure
- Add `package:logging` as a runtime dependency.
- Create a logging pipeline under `lib/core/logging/` exposing a typed logger that call sites consume via Riverpod (`ref.read(loggerProvider).warning(...)` style), with at least `info`, `warning`, and `severe` level entry points.
- A **single** `Logger.root.onRecord` listener is the only sink. It sanitizes every `LogRecord` (see §3.3) and then forwards the sanitized result to `dart:developer`'s `log()` (so output lands in the DevTools logging view). No other code emits logs directly.
- Listener registration is idempotent — registering the pipeline more than once (e.g. across tests) must not produce duplicate emissions.

### 3.2 Build-mode behavior
- The root level is keyed on build mode: `Logger.root.level = kReleaseMode ? Level.OFF : Level.ALL`.
- In release builds the logger is effectively a no-op (no records pass the `Level.OFF` threshold), honoring dosly's no-telemetry / no-sink privacy posture (§1, §5.3). The threshold is the single line to change if a future debugger-attach workflow needs `Level.SEVERE`.

### 3.3 PHI / `Failure`-aware sanitize layer
The sanitizer is the security-critical deliverable. It runs inside the root listener on every record and produces a sanitized `(message, error)` pair before anything is emitted.

- **`record.message`**: passed through a redactor that strips/withholds PHI tokens. Since dosly call sites control message strings, the message contract is "never interpolate medication names, dosages, intake timestamps, or schedule strings into a log message"; the sanitizer is the defense-in-depth backstop, not a free-text PHI scrubber.
- **`record.error` when it is a `Failure`**: routed through a variant-aware redactor using the generated `switch`/sealed matching on `Failure`. Per-variant disposition (from Bug 017's table):

  | Variant | Field | Disposition |
  |---------|-------|-------------|
  | `NotFoundFailure` | `id` | Redact by default (correlation vector) |
  | `CacheFailure` | `message` | Redact by default (today carries `e.toString()` path leakage; revisit when bug 010 lands static reasons) |
  | `PermissionDeniedFailure` | `permission` | Safe — OS identifier (`POST_NOTIFICATIONS`, …) |
  | `NotificationScheduleFailure` | `reason` | Redact by default (free-form platform string) |
  | `ValidationFailure` | `field` | Safe (closed enum-like strings) |
  | `ValidationFailure` | `message` | Redact by default (may contain user PHI) |
  | `UnknownFailure` | `error` | **Redact by default** — emit only `error.runtimeType`. Full `error.toString()` routed to a `kDebugMode`-only path, never to a non-debug emission |
  | `UnknownFailure` | `stack` | Safe, but truncate to ~first 10 frames to bound size |

- **`record.error` when it is NOT a `Failure`** (a raw `Object`/exception): emit only its `runtimeType` by default; full `toString()` is `kDebugMode`-gated.
- The redaction must be exhaustive over the sealed `Failure` union (no `default:` clause — constitution §4.1) so adding a future variant forces a compile-time decision.

### 3.4 Pilot integration — router error path
- The router error path in `lib/core/routing/app_router.dart` logs the routing failure through the new logger (sanitized), proving the `loggerProvider` → sanitizer → `dart:developer` pipeline end-to-end. The `appRouter(Ref ref)` provider scope already has access to `ref`, so the logger is obtained without new plumbing.
- The visible `_RouterErrorScreen` UI is unchanged. Logging must not fire repeatedly on widget rebuild (log once per routing error, not once per `build`).

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Dependencies | `pubspec.yaml` | Add `logging: ^1.3.0` (latest stable; exact constraint resolved in `/plan`) |
| Logger | `lib/core/logging/logger.dart` | Create new — typed logger + `@riverpod loggerProvider` + the `Logger.root` listener registration |
| Sanitizer | `lib/core/logging/log_sanitizer.dart` | Create new — PHI + `Failure`-aware variant redactor (exact file split decided in `/plan`) |
| Router pilot | `lib/core/routing/app_router.dart` | Modify — log the routing error via the logger in the error path; UI unchanged |
| Logger tests | `test/core/logging/logger_test.dart` | Create new — provider wiring, level-by-build-mode, idempotent registration |
| Sanitizer tests | `test/core/logging/log_sanitizer_test.dart` | Create new — `group('Failure sanitization')` with ≥1 test per variant + the three load-bearing leak tests (§5 AC-7) |

## 5. Acceptance Criteria

- [x] **AC-1**: `package:logging` is declared in `pubspec.yaml` under `dependencies` and `flutter pub get` resolves it on SDK ^3.11.1.
- [x] **AC-2**: `lib/core/logging/logger.dart` exposes an `@riverpod` `loggerProvider` whose value offers `info`, `warning`, and `severe` entry points accepting a message and an optional error/`Failure`.
- [x] **AC-3**: A single `Logger.root.onRecord` listener is the only emission sink; it forwards sanitized output to `dart:developer log()`. Registering the pipeline twice does not double-emit (idempotent).
- [x] **AC-4**: `Logger.root.level` is set from `kReleaseMode` such that it is `Level.OFF` in release and `Level.ALL` in debug; a test verifies the release branch produces zero emissions.
- [x] **AC-5**: The sanitizer routes a `Failure` `error` through an exhaustive sealed-`switch` (no `default:`) applying the §3.3 per-variant disposition.
- [x] **AC-6**: For a non-`Failure` error object, only `runtimeType` is emitted by default; full `toString()` is reachable only under `kDebugMode`.
- [x] **AC-7**: Sanitizer leak tests pass — the emitted log line does NOT contain:
  - `/Users/.../db.sqlite` for `UnknownFailure(PlatformException(message: '/Users/.../db.sqlite write failed'), stack)`
  - `Aspirin` for `ValidationFailure(field: 'name', message: 'Aspirin is not a valid name')`
  - the path for `CacheFailure('FileSystemException: /data/data/app.dosly/shared_prefs/...')`
- [x] **AC-8**: `UnknownFailure.stack` emission is truncated to ~10 frames.
- [x] **AC-9**: The router error path calls the logger once per routing error (not per rebuild); `_RouterErrorScreen`'s rendered UI is byte-identical to before.
- [x] **AC-10**: `dart analyze` passes clean on all changed/created files; no `print`/`debugPrint` introduced (`avoid_print` stays satisfied).
- [x] **AC-11**: All new public APIs carry dartdoc (`///`); the sanitizer's redact-by-default policy is documented inline.

## 6. Out of Scope

- **NOT included**: Retrofitting the four `settings_provider.dart` Left-branch closures. They stay as deferral comments; wiring them pulls in bug 003 (UI surfacing) and is tracked separately.
- **NOT included**: Narrowing `getThemeMode()`'s broad `catch (_)` in `settings_local_data_source.dart` (bug 002/012 follow-up).
- **NOT included**: Changing the data layer to emit static reason strings for `CacheFailure` (bug 010). Until then `CacheFailure.message` is redact-by-default.
- **NOT included**: Any UI surface for failures, telemetry, crash reporting, or remote log shipping — dosly has no backend (§1, §5.3).
- **NOT included**: A third-party log framework (`talker`/`logger`) or an in-app log viewer.
- **NOT included**: Changing `Failure.toString()` or `failures.freezed.dart` (generated). The sanitizer never relies on `Failure.toString()`; it matches variants directly.
- **NOT included**: Allowlisting per-call-site PHI overrides — redact-by-default only; per-site allowlists are a future enhancement.

## 7. Technical Constraints

- Must follow Clean Architecture: logging lives in `lib/core/` (cross-feature), no feature imports.
- Must use `package:logging` (decided) routed to `dart:developer log()`; the single-listener sanitize choke point is the architecture.
- Must expose the logger via an `@riverpod` provider (§4.3.1) so tests can `overrideWith` a capturing fake.
- Must honor §4.2.1: never log medication names, dosages, intake history; the sanitize layer is mandatory.
- Sealed-union matching must be exhaustive, no `default:` clause (§4.1).
- No Flutter imports leak into anything that must stay pure — the logger is in `core/`, not `domain/`, so `dart:developer`/`flutter/foundation` (`kReleaseMode`, `kDebugMode`) are permitted here.
- All new public declarations carry dartdoc (Key Rule #7).
- Tests use `flutter_test` + `mocktail`; the sanitizer suite is the security surface and must be exhaustive per variant.

## 8. Open Questions

- **File split**: one `logger.dart` vs separate `logger.dart` + `log_sanitizer.dart`. Leaning two files (sanitizer is independently testable and is the security surface). Resolved in `/plan`.
- **How the router obtains "log once"**: `go_router`'s `onException` callback vs guarding inside `errorBuilder`. `/plan` picks the mechanism; the spec only requires "once per routing error, not per rebuild."
- **Redaction marker**: what the sanitizer substitutes for a redacted field (e.g. `‹redacted›` vs the field name + `‹redacted›`). Cosmetic; `/plan` decides. Tests assert *absence* of the secret, not the exact marker.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Sanitizer misses a leak path (PHI/CWE-209/532 in logs) | Medium | High | Exhaustive per-variant sealed switch + the three mandatory leak tests (AC-7); sanitizer is its own test file |
| Listener registered multiple times across tests → duplicate/leaked emissions | Medium | Low | Idempotent registration (AC-3); provider override in tests |
| Logger emits in release despite no sink | Low | High | `Level.OFF` in release + explicit release-branch test (AC-4) |
| Future `Failure` variant added without a redaction decision | Low | Medium | Exhaustive switch, no `default:` → compile error forces the decision (AC-5) |
| Router pilot logs on every rebuild (noise / perf) | Medium | Low | "Log once per error" requirement + AC-9 |
| `kReleaseMode`/`kDebugMode` make `core/logging` un-pure | Low | Low | Acceptable — `core/` may import Flutter; only `domain/` must stay pure (§4.2.1) |
