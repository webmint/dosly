# Review Report: 025-typed-logger

**Date**: 2026-06-01
**Spec**: specs/025-typed-logger/spec.md
**Changed files**: 11 (4 hand-written source, 3 generated `.g.dart`, 2 test, `pubspec.yaml`, `docs/architecture.md`)

## Security Review

- Critical: 0 | High: 0 | Medium: 2 | Info: 7
- **Overall: PASS** — No constitution §4.2.1 violation. Under release/non-debug conditions no PHI, filesystem path, or raw exception `toString()` can reach a sink.

### Confirmed clean (the security-critical invariants)
- **Every branch under `includeErrorDetail: false` traced** (`log_sanitizer.dart`): `NotFoundFailure.id`, `CacheFailure.message`, `NotificationScheduleFailure.reason`, `ValidationFailure.message` → `‹redacted›`; `PermissionDeniedFailure.permission` emitted (fixed OS constant, non-PHI); `ValidationFailure.field` emitted (closed enum identifier); `UnknownFailure`/non-`Failure` → `runtimeType` only. CWE-209 / CWE-532 mitigated.
- **Exhaustive `Failure` switch, no `default:`** (`log_sanitizer.dart:115-136`) — §4.1 satisfied; new variant breaks compilation.
- **`developer.log()` is the sanctioned sink, NOT a §4.2.1 violation** — `_developerLogSink` (`logger.dart:64-72`) receives only the sanitized `SanitizedLog`; the single `Logger.root.onRecord.listen` unconditionally routes through `sanitizeRecord` first — choke point cannot be bypassed.
- **Router call site** (`app_router.dart:87`) logs the static string `'Route resolution failed'` with `state.error` as the structured arg (not concatenated); sanitized to `runtimeType` only in non-debug.
- **Stack** bounded to 10 frames; frames reference source paths, not user data.
- **Dependency** `logging 1.3.0` — official Dart-team package, sha256 verified against pub.dev, no advisories, no typosquatting.

### Findings
- **Medium** — `lib/core/logging/logger.dart:50-51,124-127`: **Profile-mode emits sanitized records.** In a profile build both `kReleaseMode` and `kDebugMode` are `false`, so `levelFor(isRelease: kReleaseMode)` → `Level.ALL` (pipeline ON) while `includeErrorDetail: kDebugMode` → `false` (redact-by-default still applies — NO PHI leak). The dartdoc frames the no-op as "production," but only `kReleaseMode` builds are silent; profile builds run the (sanitized) pipeline.
  Recommendation (optional): document that "release no-op" means `kReleaseMode` specifically, OR gate OFF on `!kDebugMode` if profile builds should also be silent. Not a leak — output is sanitized.
- **Medium** — `lib/core/logging/log_sanitizer.dart:66-72,107`: **`message` passthrough is an undefended call-site responsibility.** `record.message` is copied verbatim; only developer discipline prevents PHI in messages. Clearly documented (lines 66-71, 94-95) and the residual risk is explicitly accepted; the router passes a static string. Flagged for the record only.
  Recommendation: none required; documentation + static-string discipline are adequate.

## Performance Review

- High: 0 | Medium: 0 | Low: 0 (one Info note)
- **No changes recommended.** Well-calibrated for a diagnostic, error-path-only logging pipeline.

- **Release cost = zero**: `package:logging` `Logger.log` checks `isLoggable` BEFORE building the record/calling the sink; `Level.OFF` (2000) filters every level → no allocation downstream. The only release cost is an eager positional-arg reference read (a register load; the object already exists). Confirmed solid.
- **Info** — `lib/core/logging/logger.dart:70`: `StackTrace.fromString(stack)` in `_developerLogSink` causes a `String → StackTrace → String` double-serialization (`dart:developer log()` re-serializes). Microseconds, debug-only, error-path-only — no measurable impact. If `SanitizedLog` ever evolves to carry a native `StackTrace`, this disappears. No action now.
- Sanitizer allocations (interpolation + `split/take/join`), `AppBootstrap` one-shot `ref.read`, and the router `identical()` once-guard — all negligible / optimal.

## Test Assessment

- AC items with test coverage: 7 of 11 COVERED, 1 PARTIAL (AC-9), 3 UNCOVERED-by-design (AC-1/10/11 are build/static-analysis gates, not runtime-testable)
- **Verdict: GAPS FOUND** — one material gap (AC-9 once-guard); the rest low/informational.

### AC traceability
| AC | Status | Evidence |
|----|--------|----------|
| AC-1 (dep resolves) | Infra-verified | No dedicated test; implicitly proven by logging tests compiling/running |
| AC-2 (provider info/warning/severe) | COVERED | `logger_test.dart` provider tests |
| AC-3 (single listener, idempotent) | COVERED | `logger_test.dart` idempotent single-emit |
| AC-4 (level by build mode, release zero-emit) | COVERED (caveat) | `levelFor` both branches + `Level.OFF` zero-emit; provider→`levelFor(isRelease: kReleaseMode)` wiring not asserted (Gap 2) |
| AC-5 (exhaustive Failure switch) | COVERED | 6 variant tests; exhaustiveness compiler-enforced |
| AC-6 (non-Failure runtimeType; full only debug) | COVERED | `log_sanitizer_test.dart` includeErrorDetail tests |
| AC-7 (3 leak tests) | COVERED | Leak prevention group (db.sqlite, Aspirin, shared_prefs path) |
| AC-8 (stack truncation) | COVERED | 30-frame → ≤10 test |
| AC-9 (router logs once; UI unchanged) | **PARTIAL** | `_RouterErrorScreen` render verified (existing Test 7); the once-guard is NOT exercised |
| AC-10 (analyze clean, no print) | Static gate | Verified via `dart analyze` (clean) |
| AC-11 (dartdoc) | Static gate | Code-review verified |

### Gaps
- **Gap 1 (Medium) — AC-9 once-guard untested**: no test captures logger output during router error rendering and asserts a single emission on repeated `errorBuilder` invocation for the same error object. The `identical(error, lastLoggedError)` guard is 3 lines of stateful logic that could silently regress. Most significant gap.
- **Gap 2 (Low) — AC-4 wiring**: `levelFor` is tested directly, but no test asserts `loggerProvider` passes `kReleaseMode` (a hardcoded `isRelease: false` regression would go uncaught).
- **Gap 3-5 (Low) — edge cases**: `record.object` vs `record.error` (hypothetical — `package:logging` only uses `error`); empty message string; `UnknownFailure` null-inner-stack fallback (actually exercised by the truncation test).
- **Gap 6 (Info) — AC-10/11** are static-analysis/review gates, not unit-testable; verified out-of-band (`dart analyze` clean).

## Disposition notes for /verify
- Security PASS; the 2 Mediums are documentation/defense-in-depth (no exploitable leak), safe to accept-with-note or fix in a follow-up.
- Performance: nothing actionable.
- Test: AC-9's once-guard is the one gap a reviewer might want closed before finalizing (a focused router-logging widget test capturing emissions). All ACs otherwise covered or covered-by-design.
