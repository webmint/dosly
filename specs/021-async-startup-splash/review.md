# Review Report: 021-async-startup-splash

**Date**: 2026-05-23
**Spec**: specs/021-async-startup-splash/spec.md
**Changed files**: 9 source/test (+ generated l10n/.g.dart, docs, bug file)

## Security Review

- Critical: 0 | High: 0 | Medium: 0 | Info: 7
- **Overall: PASS**

No exploitable vulnerabilities. This is a non-blocking-startup refactor on a fully-local app (no network/auth/server surface). All four enforced constitution rules (§4.2, §4.2.1) upheld. Notable confirmations:

- **Info** — `lib/app_bootstrap.dart:53-57`: the `.when` error callback destructures `(error, stackTrace)` but **discards both** — `PrefsLoadErrorScreen` renders only the static localized `prefsLoadErrorMessage`. No raw exception/stack-trace reaches the UI (no CWE-209 info disclosure).
- **Info** — `lib/core/providers/shared_preferences_provider.dart:36-41`: the init allowList contains ONLY the four UI-flag keys (`themeMode`, `useSystemTheme`, `useSystemLanguage`, `manualLanguage`) — no PHI. Constitution §4.2.1 satisfied; the test fixture mirrors the same set.
- **Info** — No `print`/`debugPrint` in any changed file (error path is intentionally UI-only pending Bug 017's typed logger). §4.2.1 satisfied.
- **Info** — No secrets, hardcoded credentials, `jsonDecode`/`Process.run`/`dart:mirrors`/path concatenation/webview introduced.
- **Info** — Error surfaced (not swallowed) via the error branch. §4.2 satisfied.
- **Info** — Retry (`ref.invalidate`) is user-gated (manual tap) → no self-DoS / infinite loop.
- **Info** — `resolveAppLocale` validates device locale (external input) against the supported allowlist with a safe `Locale('en')` fallback.

## Performance Review

- High: 0 | Medium: 2 | Low: 3
- **Overall: net positive for startup latency** — removing the blocking `await SharedPreferencesWithCache.create(...)` from `main()` lets the first Flutter frame (the splash) render before the platform-channel I/O completes (saves ~30–120 ms of blank native launch screen on mid-range Android). No new synchronous startup-path work added.

- **Medium** — `lib/core/theme/app_theme.dart:19-20`: `AppTheme.lightTheme`/`darkTheme` are computed getters (`=> _build(...)`), so a fresh full `ThemeData` graph is allocated on every access. `_bootstrapShell` accesses both per call (loading + error branches), and `DoslyApp.build` accesses both again on the data branch. Recommendation: change to `static final ThemeData lightTheme = _build(...)` so all consumers reuse one process-lifetime instance. **Note: this is a PRE-EXISTING pattern, not introduced by this feature — out of feature 021's scope; feature 021 only consumes the getters. Track as a separate cleanup.**
- **Medium (theoretical)** — `lib/app_bootstrap.dart:59`: the `overrides: [...]` list is re-allocated on every `AppBootstrap.build`. With `sharedPreferencesInitProvider` autoDispose and no rebuild source above `AppBootstrap`, this fires once on the happy path — no observable cost. Acceptable as-is.
- **Low** — `lib/app_bootstrap.dart` / `lib/app.dart`: `MaterialApp`→`MaterialApp.router` full subtree teardown+mount at the splash→data transition. Intentional (single-MaterialApp invariant), one-time cost off the critical frame path. No action.
- **Low** — `lib/core/widgets/splash_screen.dart`: lean; `const` children, O(1) `Theme.of`, `CircularProgressIndicator` animates on the engine ticker (no Dart per-frame work). No action.
- **Low** — `lib/core/l10n/locale_resolver.dart`: linear scan over 3 locales — negligible. No action.

## Test Assessment

- AC items with test coverage: **6 of 10 fully covered by runtime tests; 4 are static/structural** (AC-1, AC-8, AC-9, AC-10 — correctly verified by analyze/grep/inspection, not test-shaped).
- **Verdict: GAPS FOUND** (coverage-breadth gaps, not AC failures — every AC's contract is satisfied).

AC-to-test traceability:
- AC-1: covered by inspection (main() has no async/await). AC-2: partially (DoslyApp mount confirmed; "persisted settings applied" not round-tripped). AC-3: covered (English). AC-4: covered. AC-5: **partially** — `CircularProgressIndicator` asserted, but surface-color background and the `splashLoading` label are NOT asserted. AC-6: covered (230 tests pass). AC-7: partially (structural presence confirmed; de/uk runtime rendering not exercised). AC-8: covered by inspection + integration. AC-9: covered by guards. AC-10: process (docs/bug).

Coverage gaps (prioritized missing tests):
- **High** — `SplashScreen` isolated widget test asserting `backgroundColor == colorScheme.surface` and `Text(l10n.splashLoading)` rendered (AC-5's two un-asserted properties). `test/core/widgets/splash_screen_test.dart`.
- **Medium** — `resolveAppLocale` pure-Dart unit tests (supported match; `fr`→en fallback; `null`→en). Currently NO test calls the production function directly — the 3 test harnesses each duplicate a local `_resolveLocale`. `test/core/l10n/locale_resolver_test.dart`.
- **Medium** — `PrefsLoadErrorScreen` isolated test: assert localized message text, retry button label, and `onRetry` invoked on tap (currently only `FilledButton` by type + indirect recovery). `test/core/widgets/prefs_load_error_screen_test.dart`.
- **Low** — de/uk rendering of the 3 new keys (typo in a key would be a compile error via gen_l10n, so genuinely low).
- **Low** — edge case: error branch after a successful init (re-invalidate + second-attempt failure); rapid multiple Retry taps.
