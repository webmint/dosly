# Review Report: 002-main-screen

**Date**: 2026-04-11
**Spec**: [spec.md](spec.md)
**Plan**: [plan.md](plan.md)
**Changed files**: 6 (1 new dep in `pubspec.yaml`/`pubspec.lock`, 2 new Dart files, 1 edited Dart file, 1 rewritten test file)

Feature scope: add a `HomeScreen` placeholder (centered "Hello World" + temporary dev button) and introduce `go_router` 17.2.0 as dosly's permanent routing foundation. No user input, no storage, no network, no auth, no deep-link platform config, no new business logic.

All 5 tasks completed and committed on `spec/002-main-screen`. Integration gates green:
- `dart analyze` — No issues found
- `flutter test` — 79/79 passing
- `flutter build apk --debug` — built successfully

## Security Review

**Summary**: Critical: 0 | High: 0 | Medium: 0 | Info: 7
**Overall**: **PASS**

### Findings

#### Critical (exploit risk)
None.

#### High (security weakness)
None.

#### Medium (defense-in-depth gap)
None.

#### Info (hardening suggestion)
- `pubspec.yaml:37` — `go_router: ^17.2.0` is the official Flutter-team-maintained routing package hosted on pub.dev (sha256 verified in `pubspec.lock:87`). No known CVEs at version 17.2.0. Package is marked "feature-complete, stability focus" by the maintainers. No action required.
- `pubspec.lock:123` — Transitive `logging 1.3.0` is the official `dart.dev/packages/logging` package maintained by the Dart team. Pulled in by `flutter_web_plugins` (SDK-side). No known CVEs. No action required.
- `lib/core/routing/app_router.dart:29-32` — `/theme-preview` route is reachable only via in-app `context.push`. No `Info.plist` `CFBundleURLTypes`, no `AndroidManifest.xml` `<intent-filter>` with `android:scheme`/`android:host`, no `GoRouter` deep-link callbacks configured. The route is therefore **not** externally addressable, so exposing a dev-only preview screen carries no deep-link attack surface. Existing `TODO(post-mvp)` markers at `app_router.dart:27` and `home_screen.dart:34` already track removal.
- `lib/app.dart:26-33` — `MaterialApp.router` wiring contains no secrets, API keys, tokens, or hardcoded credentials. `debugShowCheckedModeBanner: false` is a UI preference, not a security concern.
- `lib/features/home/presentation/screens/home_screen.dart` — `StatelessWidget` with two static `Text` children and one `OutlinedButton`. Zero input surface (no `TextField`, no `FormField`, no file/URL handling, no `jsonDecode`, no `Process.run`, no `WebView`). Nothing to validate.
- `test/widget_test.dart` — Widget test file, not shipped in the release binary. No secrets or sensitive fixtures.
- MASVS checklist items intentionally skipped as non-applicable to this feature: STORAGE (no disk writes), CRYPTO (no crypto), AUTH (no auth), NETWORK (no network calls), PLATFORM (no native config changes), CODE (no unsafe patterns — no `dart:mirrors`, no `Process`, no reflection, no dynamic eval), RESILIENCE (out of scope for UI scaffolding).

**Remediation needed**: None. Feature is clear to proceed.

## Performance Review

**Summary**: High: 0 | Medium: 0 | Low: 0 (6 Info-level observations confirming optimal shape)
**Overall**: **APPROVED**

No profile-mode measurements were performed — per MEMORY.md's "profile in profile mode, never debug" rule and the agent's "don't over-optimize" rule, empirical measurement is the wrong tool when there's no suspected bottleneck. A single text label + one button + two `GoRoute` entries cannot produce a regression large enough to warrant profiling. If the user wants empirical confirmation: `flutter run --profile` with DevTools, and `flutter build apk --analyze-size --target-platform android-arm64` for size.

### Findings (Info-level observations — no action required)

- **`ListenableBuilder` rebuilding `MaterialApp.router` on theme change** — **verified safe**. `appRouter` is a top-level `final GoRouter` (`lib/core/routing/app_router.dart:21`). `GoRouter` (verified by reading pub-cache `go_router-17.2.0/lib/src/router.dart:173-262`) implements `RouterConfig<RouteMatchList>` and owns its `routerDelegate`, `routeInformationProvider`, `backButtonDispatcher` internally — these are constructed once at top-level `final` initialization, not on each `MaterialApp.router` rebuild. Navigation state survives theme changes. Research.md §5's claim is correct and matches the source.
- **Startup cost of `go_router` initialization** — negligible. Two `GoRoute` factory calls + one `RootBackButtonDispatcher` + one `_ConstantRoutingConfig` wrap. Sub-millisecond. No synchronous I/O, no platform channels, no asset loads. Delta from `MaterialApp` → `MaterialApp.router` is below the cold-start variance floor.
- **`const` discipline in `home_screen.dart`** — **optimal**. Verified: `Text('Hello World')` const ✓, `SizedBox(height: 24)` const ✓, `Text('Theme preview')` const ✓, `OutlinedButton` correctly **not** const (closure captures `context`), outer `Scaffold/Center/Column` not const because they ultimately contain the non-const `OutlinedButton`. Making these const is impossible, not an oversight.
- **Widget-tree nesting** — already minimal. `Scaffold → Center → Column → [Text, SizedBox, OutlinedButton → Text]` is the shortest tree that satisfies the spec's visual requirements. `mainAxisSize: MainAxisSize.min` prevents unnecessary vertical expansion.
- **App size impact** — low and unavoidable. `go_router` package is ~1.8 MB source; tree-shaking in release builds strips unused features (ShellRoute, typed routes, StatefulShellRoute, redirect machinery, restoration, observers). Practical arm64 APK delta: ~150-300 KB. `logging` transitive is ~76 KB source, tree-shakes to a few KB. `flutter_web_plugins` is stripped from mobile builds entirely.
- **Release-mode assertions in `GoRouter`** — debug-only. Flutter strips `assert`s in release builds. Zero production cost.

**Recommendation for future**: If the app later grows expensive widgets high in the tree, consider a `Selector`-style slice so theme changes stop rebuilding the entire `MaterialApp.router`. Not needed at N=1 screen. No action for this spec.

## Test Assessment

**Summary**:
- Automated test coverage: **all testable behaviors this feature introduces**
- Verdict: **ADEQUATE**

### AC-to-test traceability

| AC | Coverage | Source |
|----|----------|--------|
| AC-1 (pubspec declares `go_router`) | Implementation contract (file read) | `pubspec.yaml` |
| AC-2 (`app_router.dart` flat two-route shape) | Implementation contract + **indirect** | `lib/core/routing/app_router.dart` code read; tests exercise both routes end-to-end |
| AC-3 (TODO adjacent to `/theme-preview`) | Implementation contract (grep) | `app_router.dart` |
| AC-4 (`HomeScreen` structure) | **Partial test** + file read | Widget test asserts `Text('Hello World')` and `OutlinedButton('Theme preview')` present; internal layout (`Center`, `Column`, `SizedBox(24)`, `mainAxisSize.min`) is read from source |
| AC-5 (HomeScreen import whitelist) | Implementation contract (grep) | `home_screen.dart` |
| AC-6 (no AppBar/FAB/Drawer/BottomNav on HomeScreen) | Implementation contract (file read) | `home_screen.dart` |
| AC-7 (exact strings `'Hello World'` and `'Theme preview'`) | **Direct test** | `widget_test.dart` test 1 |
| AC-8 (HomeScreen dartdoc with spec reference) | Implementation contract (file read) | `home_screen.dart` |
| AC-9 (`app.dart` uses `MaterialApp.router`) | Implementation contract + **indirect test** | File read + tests would fail if router weren't wired |
| AC-10 (`app.dart` library dartdoc updated) | Implementation contract (file read) | `app.dart` |
| AC-11 (test 1 assertions) | **Self-covered** | `widget_test.dart` test 1 is literally this AC |
| AC-12 (test 2 navigates via button then cycles theme) | **Self-covered** | `widget_test.dart` test 2 is literally this AC |
| AC-13 (`dart analyze` clean) | Gate | Execution-time |
| AC-14 (`flutter test` passes) | Gate | Running the tests |
| AC-15 (`flutter build apk --debug`) | Gate | Build step |
| AC-16 (no `print`/`!`/`dynamic`) | Code review + grep | code-reviewer agent on each task |
| AC-17 (const where possible) | Linter (`prefer_const_constructors`) | `dart analyze` |
| AC-18 (manual simulator verification) | **Deferred to `/verify`** | Human check |

### Gaps flagged (none blocking)

None for this spec. Intentional non-coverage decisions:
- No standalone `app_router_test.dart` — covered end-to-end via widget tests (spec §6 excluded it explicitly).
- No back-navigation test — deferred to AC-18 manual check. Plausibly add-able via `BackButton` finder; not required by any AC.
- No portrait/landscape test — deferred to AC-18.
- No absence-assertions for AC-6 (`expect(find.byType(AppBar), findsNothing)`) — duplicates file-read check with no meaningful failure mode.

### Future-feature recommendations (NOT gaps in this spec)

- When `HomeScreen` grows past placeholder, add `test/features/home/presentation/screens/home_screen_test.dart` pumping `HomeScreen` in isolation from the full `DoslyApp`. Priority: low, defer until real content.
- When test count exceeds 2 in `widget_test.dart`, convert `appRouter` to a factory function OR add `appRouter.go('/')` to `setUp` to neutralize router state leakage. Priority: medium, revisit on test 3+.
- When `go_router` features grow (redirects, shell routes, guards), add integration tests covering the redirect logic. Priority: medium.
- Consider a custom lint rule preventing `lib/features/home/` from importing `lib/features/theme_preview/`. Currently enforced by spec review + AC-5, not by automation. Priority: low.

### Test Isolation Risk (Spec Open Q §8 #6)

**Assessment**: Acceptable for this spec as written. **Caveat**: adequate by accident, not construction.

Because `appRouter` is a top-level `final`, its `RouteMatchList` persists across tests within the same Dart VM run. Current file:
- Test 1 doesn't navigate — safe.
- Test 2 navigates to `/theme-preview` and ends there without popping.

`flutter_test` runs tests in declaration order, so test 1 runs first and test 2's residual state has no next test to leak into. Adding a third test would expose the risk.

**Strongly recommended fix for future**: add `appRouter.go('/')` to the existing `setUp` alongside `themeController.setMode(ThemeMode.system)`:

```dart
setUp(() {
  themeController.setMode(ThemeMode.system);
  appRouter.go('/'); // neutralize router state between tests
});
```

This is a one-line change, does not require restructuring `appRouter` into a factory, and would preemptively neutralize the risk. Spec §8 #6 recommends shipping the simple version and revisiting if flakiness is observed. That is defensible for a 2-test file, but a test-isolation note belongs in MEMORY.md so future task authors don't trip on it.

**Not blocking `/verify`**, but noted for the follow-up spec that adds a third widget test.

## Overall

- **Security**: PASS — no actionable findings.
- **Performance**: APPROVED — no regressions.
- **Tests**: ADEQUATE — every behavior this feature introduces is covered at the right level.

No Critical or High findings. No constitution violations. Feature is ready for `/verify` to render the formal verdict.

### Notable non-blocking recommendations to roll into a future spec

1. **Add `appRouter.go('/')` to `widget_test.dart` `setUp`** — one-line fix for router test-isolation risk. Trigger: next time a third widget test is added to this file.
2. **Optionally add `/theme-preview` back-navigation widget test** — tap the auto-generated AppBar back button, assert return to `HomeScreen`. Trigger: when ready to harden AC-18 at the automation layer.
3. **Empirical APK size diff** before/after this feature lands — `flutter build apk --analyze-size --target-platform android-arm64` diff. Not required, but provides a baseline for future feature size budgets. Trigger: user preference.
