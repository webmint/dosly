# Review Report: 022-settings-error-containment

**Date**: 2026-05-25
**Spec**: specs/022-settings-error-containment/spec.md
**Changed files**: 11 (3 production + 8 test) — excluding spec/research/memory artifacts

## Security Review

- Critical: 0 | High: 0 | Medium: 0 | Info: 5

**Overall: PASS.** The feature is a net security improvement — it removes the CWE-209 path-leak that motivated it and introduces no new error sink that logs or displays raw exception data.

- **Info** — `settings_repository_impl.dart:32-33, 42-44, 52-53, 63-64, 74-75`: CWE-209 path-leak correctly closed. `load()` and all four `save*` now use `catch (e, st) { return Left(Failure.unknown(e, st)); }`, replacing the prior `CacheFailure(e.toString())` that string-ified the SharedPreferences error (which can embed the on-disk store path). Catching `(e, st)` (not `on Exception`) also captures `Error` subtypes (e.g. the `TypeError` from wrong-type cache reads). Constitution §3.2 satisfied.
- **Info** — No new sink for the tracked logger risk (bug 017). `settings_provider.dart` forwards the `Failure` object to the `_errors` broadcast stream but never stringifies it; the UI consumer `settings_screen.dart:38-46` discards the payload (`whenData((_) {...})`) and shows a static localized string. So `Failure.unknown(error,...)`'s forward-looking CWE-209/CWE-532 risk remains exactly as already tracked in `bugs/017-typed-logger-missing.md` — not newly triggered, not double-reported.
- **Info** — Constitution §4.2.1 (no `print`/`debugPrint`) satisfied across all reviewed files.
- **Info** — Constitution "never swallow errors" satisfied: no empty catch blocks; every catch yields a typed `Failure.unknown(e, st)` surfaced via the error stream.
- **Info** — Test fixtures clean: no secrets/tokens/PII/filesystem paths. Error literals are benign (`StateError('boom')`, `Exception('mock failure')`, `Exception('load boom')`).
  - *Consistency note (not a security issue):* `settings_screen_test.dart:32-62` still injects `CacheFailure('mock failure')` from its fake, while production no longer emits `CacheFailure` for save failures. The screen ignores the payload so the test passes, but the fake diverges from production behavior. (Same class as the notifier-test fix already made in Task 2; the screen test was out of that task's scope.)

## Performance Review

- High: 0 | Medium: 0 | Low: 1

**Verdict: performance-neutral on the startup path.** The `.fold` closure + `try/catch` wrapper add under ~5 µs of synchronous work (four in-memory cache lookups; no disk I/O, no async boundary) — rounding error against the 16 ms frame budget. Nothing to optimize without sacrificing the correctness guarantees the feature adds.

- **Low** — `settings_provider.dart:89`: `_errors = StreamController<Failure>.broadcast()` is constructed inside `build()`, so it is re-created on every provider invalidation. **Pre-existing (not introduced by this feature).** Dormant in production because the notifier is `keepAlive: true` and built once. Hazard only if `settingsNotifierProvider` were ever made non-keepAlive or deliberately invalidated: a listener holding `errors` from before a rebuild would be subscribed to the closed (dead) stream. If it ever matters, move `_errors` to a field initializer. Out of scope here.
- **Info** — `settings_repository_impl.dart` `load()` outer `catch` is effectively defensive: `getThemeMode()` guards its own `TypeError` internally and the two `getBool` calls return nullable defaults, so on a well-formed prefs instance the catch fires only if `SharedPreferencesWithCache` itself throws. Valid defensive layer; negligible cost (one inactive exception-table entry).
- **Info** — `settings_provider.dart:94`: `_errors.add(failure)` at cold start fires into a listener-less broadcast stream and is dropped silently (correct, documented OQ-2 behavior). No buffering overhead.

## Test Assessment

- AC items with test coverage: **7 of 10 fully covered** (AC-2, AC-3, AC-4, AC-6, AC-7, AC-8, AC-9); **2 partial-with-accepted-rationale** (AC-1, AC-5); **1 process gate** (AC-10).
- Verdict: **ADEQUATE**

Per-AC traceability:
- **AC-1** (Partial): signature confirmed structurally by every `load()` test; dartdoc accuracy is a doc assertion, not behaviorally testable. Production `load()` has no stale "Never fails" text — satisfied by omission.
- **AC-2** (Covered): `returns Left when useSystemTheme is stored as a String (not bool)`, `...useSystemLanguage...`, `...manualLanguage is stored as an int (not String)`.
- **AC-3** (Covered): `returns Left(UnknownFailure) when the data source getter throws`.
- **AC-4** (Covered): default/happy-path + persistence round-trip tests.
- **AC-5** (Partial, accepted — OQ-2): `should fall back to default AppSettings when load() returns Left (AC-5)` (state fallback) + `errors stream is wired ... subsequent save failure ... emits UnknownFailure` (infra). The build-time emission itself is structurally unobservable (broadcast stream, no listener yet).
- **AC-6** (Covered): `should have state equal to seeded AppSettings when load() returns Right (AC-6)`.
- **AC-7** (Covered): one `StateError`-thrower test per save method (proves `Error`, not just `Exception`, is caught).
- **AC-8** (Covered): each AC-7 test also asserts `isNot(isA<CacheFailure>())`.
- **AC-9** (Covered): legacy-int `themeMode` fallback + happy-path + round-trip tests unchanged and passing.
- **AC-10** (N/A): process gate — `dart analyze` clean, `flutter test` 241/241.

Coverage gaps:
- **AC-2 (low priority)**: the `themeMode` wrong-type case is NOT tested for the Left path because `getThemeMode()` is internally guarded (it returns `Right(default)`, not `Left`, on type mismatch — unlike the other three unguarded keys). The asymmetry is real and works, but no test explicitly names it. The existing legacy-int `themeMode` test covers the guarded-fallback behavior.
- **AC-1 / AC-5**: bounded by accepted constraints (untestable doc assertion / OQ-2 dropped emission) — not defects.
