# Plan: Typed Logger with PHI Sanitize Layer

**Date**: 2026-06-01
**Spec**: [spec.md](spec.md)
**Status**: Approved

## Summary

Build a `package:logging` pipeline under `lib/core/logging/`: a keep-alive `@riverpod loggerProvider` returns a named `Logger`, and on first read configures `Logger.root` with a build-mode-keyed level and a **single sanitizing listener**. Every record flows through a pure `Failure`-aware sanitizer before being forwarded to a `dart:developer log()` sink. One pilot integration in the router error path proves the wiring. The design is built around three testability seams (pure sanitizer, pure level selector, injectable sink) so every AC is verifiable without toggling compile-time constants or intercepting `dart:developer`.

## Technical Context

**Architecture**: `lib/core/logging/` — a cross-feature core module (not a feature, not domain). May import Flutter (`flutter/foundation.dart` for `kReleaseMode`/`kDebugMode`) and `dart:developer`; only `domain/` must stay pure (§4.2.1).
**Error Handling**: Consumes the existing `Failure` sealed union (`lib/core/error/failures.dart`); the sanitizer matches its six variants exhaustively. No new `Either`/`Failure` flows introduced.
**State Management**: Riverpod codegen (`@riverpod`, keep-alive). The logger is a singleton-per-container provider; `ref.onDispose` cancels the root-listener subscription.

## Constitution Compliance

- **§7.1 step #3** (typed logger at `core/logging/`): satisfied — this is that file.
- **§4.2.1** (no `print`/`debugPrint`; typed logger required; PHI sanitize layer mandatory): satisfied — `package:logging` → `dart:developer log()`, never `print`; sanitizer is mandatory and runs on every record.
- **§4.2.1** (never log medication names/dosages/intake): satisfied — redact-by-default sanitizer; the three leak tests (AC-7) are the guardrail.
- **§4.1** (exhaustive switch, no `default:`): satisfied — sanitizer uses a sealed `switch` over `Failure` with no `default:`; a new variant breaks compilation.
- **§4.3.1** (`@riverpod` codegen; `Notifier` patterns): satisfied — `loggerProvider` is codegen, keep-alive, override-in-tests.
- **§4.2 domain purity**: not at risk — logging lives in `core/`, no `domain/` file imports it or Flutter.
- **Key Rule #7** (dartdoc on new public APIs): all new public declarations documented.
- **§3.2** (fallible ops return `Either`): N/A — logging is fire-and-forget side-effect, not a fallible domain operation; no `Either` needed.

## Implementation Approach

### Layer Map

| Layer | What | Files (existing or new) |
|-------|------|------------------------|
| Core / logging | Logger provider, `Logger.root` configuration, build-mode level selector, dev-log sink | `lib/core/logging/logger.dart` (new) |
| Core / logging | Pure `Failure`-aware + PHI redactor producing a sanitized record | `lib/core/logging/log_sanitizer.dart` (new) |
| Core / routing | Pilot: log the routing error via `loggerProvider` (sanitized), once per error | `lib/core/routing/app_router.dart` (modify) |
| App bootstrap | Read `loggerProvider` once at startup so the listener registers before any route runs | `lib/app_bootstrap.dart` (modify) |
| Dependencies | Add `logging` | `pubspec.yaml` (modify) |
| Tests | Pure sanitizer suite (per-variant + 3 leak tests) | `test/core/logging/log_sanitizer_test.dart` (new) |
| Tests | Provider wiring, `levelFor` both branches, idempotent registration via capturing sink | `test/core/logging/logger_test.dart` (new) |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| Backend | `package:logging` → `dart:developer log()` | Single `onRecord` choke point = structural sanitize guarantee | `dart:developer` wrapper (bypassable); `talker` (overkill) — see research.md |
| Sanitizer shape | **Pure** `SanitizedLog sanitizeRecord(LogRecord r, {required bool includeErrorDetail})` in its own file | Testable without `dart:developer`; security surface isolated; `includeErrorDetail` param replaces a direct `kDebugMode` read so both paths are tested (AC-6) | Inlining sanitize in the listener (untestable) |
| `Failure` matching | Sealed `switch (failure) { case NotFoundFailure(): ... }` exhaustive, no `default:` | §4.1; new variant → compile error forces a redaction decision (AC-5) | `when`/`map` (works too, but `switch` is the §4.1-preferred form) |
| Level selection | Pure `Level levelFor({required bool isRelease})`; wired as `levelFor(isRelease: kReleaseMode)` | `kReleaseMode` is const & untoggleable in tests; pure helper makes AC-4 testable | Inline ternary on `kReleaseMode` (untestable release branch) |
| Listener registration | Inside `loggerProvider` (keep-alive) on first build; store `StreamSubscription`, cancel via `ref.onDispose` | Provider memoization → idempotent single registration (AC-3); `onDispose` isolates test containers on global `Logger.root` | Registering in `main()` (not overridable, leaks across tests) |
| Sink seam | Listener forwards `SanitizedLog` to an injectable `void Function(SanitizedLog, Level)` sink, default = `dart:developer log()` wrapper | Tests pass a capturing sink + explicit `Level` to assert single-emit (AC-3) and release suppression (AC-4) without intercepting `dart:developer` | Hard-coding `dev.log` in the listener (unobservable in tests) |
| Logger value type | Provider returns a plain `Logger('dosly')` (no custom wrapper class) | `Logger` already exposes `info`/`warning`/`severe`; §4.3 "boring over clever"; fewer types | A bespoke `AppLogger` facade (redundant with `Logger`) |
| Router "log once" | Use `go_router`'s `onException` callback (fires once per failed match) rather than logging inside `errorBuilder` (runs every rebuild) | Satisfies AC-9 "once per error, not per rebuild"; `errorBuilder` stays UI-only/unchanged | Logging inside `errorBuilder` (rebuild noise) |
| Redaction marker | Sanitizer substitutes a constant placeholder (e.g. `‹redacted›`) for withheld fields | Cosmetic; tests assert *absence of the secret*, not marker text (spec §8) | — |

### `SanitizedLog` shape (small value object, not a domain entity)

A plain immutable class (or record) in `log_sanitizer.dart`:
- `String message` — sanitized message.
- `String error` — sanitized error rendering (e.g. `"UnknownFailure(PlatformException)"` with internals redacted), empty when no error.
- Optional `String? stack` — truncated (~10 frames) when present and safe (AC-8).

`sanitizeRecord` builds it by: passing `record.message` through the PHI backstop, then dispatching on `record.error` — `Failure` → per-variant redactor (§3.3 table), non-`Failure` → `runtimeType` only (full `toString()` only when `includeErrorDetail`), `null` → empty.

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `pubspec.yaml` | Modify | Add `logging: ^1.3.0` under `dependencies` (exact version confirmed by `flutter pub get`) |
| `lib/core/logging/logger.dart` | Create | `loggerProvider` (`@Riverpod(keepAlive: true)`) returning `Logger('dosly')`; `levelFor({required bool isRelease})`; root-listener registration with injectable sink + default `dart:developer log()` sink; `ref.onDispose` cancel. Part file `logger.g.dart` generated. |
| `lib/core/logging/log_sanitizer.dart` | Create | Pure `sanitizeRecord(...)` + `SanitizedLog` + exhaustive `Failure` switch implementing the §3.3 disposition table |
| `lib/core/routing/app_router.dart` | Modify | Add `onException` to the `GoRouter` that reads `ref.read(loggerProvider)` and logs `state.error` (sanitized, once). `errorBuilder`/`_RouterErrorScreen` UI unchanged. |
| `lib/app_bootstrap.dart` | Modify | Read `loggerProvider` once during startup (e.g. `ref.watch`/`ref.read`) so the listener is configured before routing runs |
| `test/core/logging/log_sanitizer_test.dart` | Create | `group('Failure sanitization')` ≥1 test/variant + 3 leak tests (AC-7) + truncation (AC-8) + `includeErrorDetail` both values (AC-6) |
| `test/core/logging/logger_test.dart` | Create | `levelFor` both branches (AC-4), idempotent single-emit via capturing sink (AC-3), `Level.OFF` suppression (AC-4), provider exposes info/warning/severe (AC-2) |

**Files in plan but not in spec §4**: `lib/app_bootstrap.dart` — discovered during planning. `main()` is synchronous and wraps `ProviderScope`, so the listener must be triggered through Riverpod at startup; `AppBootstrap` is the read point. Minimal change (one provider read). Carried into File Impact above.

### Documentation Impact

| Doc File | Action | What Changes |
|----------|--------|-------------|
| `docs/architecture.md` | Update | Add a "Logging" subsection: `core/logging` pipeline, single-listener sanitize choke point, release no-op. Update the line at `:108` that says structured failure logging is "deferred to Bug 017" → now available (router pilot wired). |
| `docs/features/*` | None | No feature-level behavior change. |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Sanitizer misses a leak path (PHI / CWE-209/532 in logs) | Medium | High | Pure sanitizer + exhaustive sealed switch + 3 mandatory leak tests (AC-7); isolated test file |
| Global `Logger.root` listener leaks across test containers → double emissions | Medium | Low | `ref.onDispose` cancels subscription; capturing-sink test asserts single-emit (AC-3) |
| `go_router` `onException` signature/availability differs in `go_router ^17.2.0` | Low | Medium | Verify `onException` exists on this version during execute; fallback = guarded one-shot log in `errorBuilder` if absent |
| Logger emits in release despite no sink | Low | High | `levelFor` → `Level.OFF` in release + explicit pure-helper test (AC-4) |
| Future `Failure` variant added without redaction decision | Low | Medium | Exhaustive `switch`, no `default:` → compile error (AC-5) |
| Riverpod codegen for a side-effecting keep-alive provider feels unidiomatic | Low | Low | Side-effect (listener registration) is bounded and disposed; documented in dartdoc |

## Dependencies

- **New package**: `logging: ^1.3.0` (pure Dart, no transitive Flutter deps). Run `flutter pub get` after adding.
- **Existing, reused**: `flutter_riverpod` / `riverpod_annotation` (provider + codegen), `go_router ^17.2.0` (`onException`), `flutter/foundation` (`kReleaseMode`/`kDebugMode`), `lib/core/error/failures.dart` (the union), `flutter_test` + `mocktail` (tests).
- **Codegen**: `build_runner` run required after creating `logger.dart` (generates `logger.g.dart`).

## AC → Plan coverage (Phase 2.5 cross-reference)

| AC | Covered by |
|----|-----------|
| AC-1 (dep added) | `pubspec.yaml` modify |
| AC-2 (provider w/ info/warning/severe) | `logger.dart` returns `Logger`; `logger_test.dart` |
| AC-3 (single sink, idempotent) | provider registration decision + capturing-sink test |
| AC-4 (level by build mode, release no-op) | `levelFor` pure helper + tests |
| AC-5 (exhaustive Failure switch) | `log_sanitizer.dart` sealed switch |
| AC-6 (non-Failure → runtimeType; full only in debug) | `includeErrorDetail` param + test |
| AC-7 (3 leak tests) | `log_sanitizer_test.dart` |
| AC-8 (stack truncation) | `SanitizedLog.stack` truncation + test |
| AC-9 (router logs once, UI unchanged) | `onException` decision; `app_router.dart` modify |
| AC-10 (`dart analyze` clean, no print) | enforced by PostToolUse hook + review |
| AC-11 (dartdoc) | all new public APIs |

All 11 ACs have an implementation path.

## Supporting Documents

- [Research](research.md) — backend choice, API verification, alternatives compared.
