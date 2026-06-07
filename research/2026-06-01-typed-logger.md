# Research: Typed Logger (`core/logging/`)

**Date**: 2026-06-01
**Topic**: Bug 017 — Typed logger from `core/logging/` does not exist
**Verdict**: Feasible (well-scoped, prerequisites in place)

## Summary

The gap is real and confirmed: `lib/core/logging/` does not exist, no logging package is in `pubspec.yaml`, and the constitution mandates a typed logger as the *only* compliant alternative to `print`/`debugPrint` (§4.2.1). This is not exploratory work — Bug 017's report is already near-spec quality, including a complete `Failure`-aware sanitizer design table. The one architectural nuance worth surfacing before `/specify`: **dosly has no backend and no telemetry**, so "logging" here means *developer-facing diagnostics in debug builds*, not shipped logs. That constraint should drive the package choice. The security-critical deliverable is the **sanitize layer**, not the logger plumbing.

## Codebase Findings

### Existing Related Code
| Area | Files | Relevance |
|------|-------|-----------|
| Error union | `lib/core/error/failures.dart` + `failures.freezed.dart` | Exists. The 6-variant `Failure` union the sanitizer must be aware of. `Failure.unknown` already carries a dartdoc PII warning (lines 43–47). |
| Riverpod codegen | `riverpod_annotation: ^4.0.2` in deps | The prescribed `loggerProvider` should be `@riverpod` (matches codebase convention §4.3.1). |
| Deferred call sites | `settings_provider.dart` (4 empty Left-branches), `getThemeMode()` broad catch, router error branch | All currently *cannot* log — they hold deferral comments pointing at bug 017. These are the first consumers once it lands. |
| Doc deferrals | `docs/architecture.md:108`, specs 010/012/013/018/019/022 | A long deferral chain explicitly waits on this. Closing 017 unblocks "real" failure logging across the app. |

### Patterns Available
- **`@riverpod` provider + override-in-tests** — the bug report's step #4 (`ref.read(loggerProvider).warning(...)`) matches the existing DI pattern exactly.
- **`freezed` `when`/`map` exhaustive matching** — the sanitizer's variant-aware redactor uses the generated matchers on `Failure`.
- **`kDebugMode` gating** — established pattern for debug-only behavior; relevant for the "developer-only sink" for full `UnknownFailure.error`.

### Gaps
- No `lib/core/logging/` directory.
- No logging dependency (`logging` / `logger` / `talker`) in `pubspec.yaml`.
- No sanitize utility anywhere — must be built from scratch (this is the bulk of the work + its own test suite).

## Constitution Constraints

| Rule | Impact |
|------|--------|
| §4.2.1 "Use the typed logger from `core/logging/`" | Defines the deliverable — the logger is the sanctioned `debugPrint` replacement. `avoid_print` lint stays on. |
| §4.2.1 "Logger must have a sanitize layer" / "Never log PHI" | **Hard requirement.** Sanitizer is mandatory, not optional. Must strip medication names, dosages, intake timestamps. |
| §1 / §5.3 No backend, no telemetry | No log shipping target exists. Output sink is local dev console only → favors a *minimal* solution over a feature-heavy log framework. |
| §7.1 step #3 | Prescribes the file path and suggests `package:logging` + sanitize layer. |
| §4.3 "Boring over clever", "Existing patterns" | Argues against a heavyweight third-party logger; argues for a thin, testable wrapper. |

## Approaches

### Option A: `package:logging` + sanitize layer + Riverpod provider
- **Description**: The constitution's suggested path. Add Dart-team-maintained `package:logging`, wrap its `Logger` with a `SanitizingLogger`, expose via `@riverpod`.
- **Pros**: Matches §7.1 verbatim; standard `Level` hierarchy; official/stable package; familiar API.
- **Cons**: Adds a dependency whose main value (hierarchical loggers, listeners) is barely used in a no-telemetry app. The sanitizer still must wrap every call regardless.
- **Complexity**: Low–Medium

### Option B: `dart:developer log()` wrapper + sanitize layer + Riverpod provider
- **Description**: Zero new dependencies. A typed `AppLogger` over `dart:developer`'s `log()`, with the same sanitize layer and `@riverpod` provider. `kDebugMode`-gated developer sink for full error detail.
- **Pros**: No new dependency; "boring over clever"; output integrates with Flutter DevTools logging view; smallest surface to test; sanitizer is identical work to Option A.
- **Cons**: Minor deviation from §7.1's "consider `package:logging`" suggestion (it says *consider*, not *must*); no built-in level filtering (trivial to add).
- **Complexity**: Low

### Option C: Third-party `talker` / `logger`
- **Description**: Feature-rich logging with formatting, in-app log viewer, history.
- **Pros**: Rich DX features out of the box.
- **Cons**: Overkill for a personal, local-only app; larger dep footprint; more API surface to wrap for sanitization. Against §4.3.
- **Complexity**: Medium

**Recommended approach**: **Option B** — for a no-backend, no-telemetry app the logger is pure dev diagnostics; a dependency-free `dart:developer` wrapper satisfies §4.2.1 identically while honoring "boring over clever." Option A is an acceptable fallback if you prefer literal §7.1 adherence. **In both, the `Failure`-aware sanitize layer (with its own test suite) is 80% of the real work** and is identical either way.

## External Research

Skipped deep web research — the one signal (new dependency) is narrow and the candidate (`package:logging`) is a well-established Dart-team package. Note: `package:logging` and `dart:developer` are both stable and SDK-aligned; no compatibility risk with SDK ^3.11.1.

## Complexity Assessment

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Codebase changes | Low | New `lib/core/logging/` dir; logger + sanitizer + provider. ~3 source files. Wiring existing deferred call sites is optional follow-up, not part of this. |
| New dependencies | Low (A) / None (B) | Option B adds nothing. |
| Risk | Medium | Risk is concentrated in the **sanitizer correctness** — a leak = PHI/§4.2.1 violation (CWE-209/532). Mitigated by the mandatory per-variant test suite already designed in the bug report. |

## Recommendation

**Proceed to `/specify`.** Bug 017 already contains a near-complete spec (sanitizer table, test surface, cross-references), so `/specify` will mostly need one decision: **package choice (Option A vs B)**.

Suggested next command:

```
/specify "Typed logger at lib/core/logging/logger.dart per constitution §7.1/§4.2.1: a thin AppLogger (dart:developer-based, no new dependency) exposed via @riverpod loggerProvider, with a mandatory Failure-aware sanitize layer that redacts PHI and per-variant Failure fields per bug 017's disposition table. Sanitize layer must ship with its own per-variant test suite (no /Users path, no 'Aspirin', no e.toString() leaks). Out of scope: retrofitting existing deferred call sites in settings_provider/router."
```

## Cross-References

- `bugs/017-typed-logger-missing.md` — source bug, near-spec quality with the full sanitizer disposition table.
- `bugs/006-failure-hierarchy-incomplete.md` (Closed by spec 017) — defines the `Failure` union shape.
- `bugs/010-repository-catches-only-exception.md` — when fixed, makes `CacheFailure.message` safer to log.
- `specs/017-failure-freezed/review.md` — CWE-209 / CWE-532 finding the sanitizer must address.
- `constitution.md` §2.2 (line 88), §4.2.1 (lines 353/359), §7.1 (line 562).
