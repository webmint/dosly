# Review Report: 020-remove-theme-preview

**Date**: 2026-05-22
**Spec**: specs/020-remove-theme-preview/spec.md
**Changed files**: 8 source/test/bug files (3 deleted, 5 edited) + Claude artifacts

> Feature 020 is a pure **deletion**: it removes the dev-only `theme_preview`
> screen + 2 helper widgets, the `/theme-preview` route, the HomeScreen dev
> button, and the tests that exercised them; it closes Bug 009 (cross-feature
> import). No new code, dependencies, or behavior were introduced.

## Security Review

- Critical: 0 | High: 0 | Medium: 0 | Info: 4
- **Overall: PASS** — the deletion is security-neutral.

Findings (all Info / hardening observations):
- **Info** — `lib/core/routing/app_router.dart`: the removed `/theme-preview`
  route was a dev-only M3 theme gallery with no auth gate, no protected data, no
  input handling, no network/storage. Removing it neither removes nor weakens any
  security control.
- **Info** — `lib/core/routing/app_router.dart`: unknown-route / deep-link
  handling is intact — the `errorBuilder` still routes unmatched paths to
  `_RouterErrorScreen` (`context.go('/')`). The four remaining routes (`/`,
  `/meds`, `/history`, `/settings`) are static `const` builders that take no
  `state` params, so there is no deep-link parameter parsing to validate.
- **Info** — the removed cross-feature import (`theme_preview` → `settings/`,
  Bug 009) is gone with no replacement; the `settings_provider` it read remains
  used legitimately elsewhere (only the dev consumer was deleted).
- **Info** — no secrets, keys, PII, logging (`print`/`debugPrint`/`developer.log`),
  storage, or network code appears in any deleted or modified hunk. Test changes
  only drop assertions for removed UI; no test weakened a security check.

## Performance Review

- High: 0 | Medium: 0 | Low (positive): 3
- **Net-positive change.** No regressions; no action required.

Findings (all Low / positive):
- **Low (positive)** — app binary size: tree-shaking eliminates
  `ThemePreviewScreen`, `ColorSwatchCard`, `TypographySample` (~388 lines of
  widget code) and makes the `LucideIcons.sunMoon`/`sun`/`moon`/`plus` glyphs
  referenced only there candidates for elimination at AOT build time.
- **Low (positive)** — `HomeScreen` build cost: body went from a 5-node `Column`
  (Text + SizedBox + OutlinedButton + a `context.push` closure) to a fully `const`
  2-node `Center(child: Text(...))`, allocated once.
- **Low (positive)** — startup: the preview's two `ref.watch(settingsNotifierProvider.select(...))`
  subscriptions are no longer reachable from the navigation graph. Negligible (the
  route was never the initial route), but strictly positive.

## Test Assessment

- AC items with a verification path: **12 of 12** (mix of test / grep-absence /
  `dart analyze` / build / inspection)
- **Verdict: ADEQUATE** — suite green (226/226).

Coverage notes:
- **No lost coverage** from deleting widget_test.dart's theme-cycle test: the
  `system → light → dark → system` cycle is independently covered at four layers —
  `cycle_theme_mode_test.dart` (use case, all 3 branches + failure),
  `settings_provider_test.dart` (`cycleThemeMode` group), `theme_selector_test.dart`
  (production UI entry point), and `settings_screen_test.dart`. The deleted test
  exercised the cycle through the *violating* screen — duplicate coverage, not
  unique.
- **No routing gap** after Test 5's removal: Tests 1–4 (shell topology, tab nav,
  selectedIndex, branch-stack), Test 6 (`/settings` outside shell + back), and
  Test 7 (unknown-route `errorBuilder` + recovery) remain. Test 5 uniquely covered
  `/theme-preview` outside the shell — a route that no longer exists.

Coverage gaps (all **low** priority):
- **AC-4**: `widget_test.dart` test 1 asserts the home screen renders
  (`'Hello World'`, `'Dosly'`) but does NOT add a `findsNothing` absence assertion
  for `OutlinedButton('Theme preview')`. If the button were ever re-added the test
  would still pass. Optional hardening — the spec deliberately adds no new tests,
  and the button's source is gone.
- **AC-11** (`flutter build apk --debug`): verified during Task 003 execution
  (build succeeded), not re-run in this assessment; spec §5 delegates the build
  gate.
- **AC-12** (`!` / `dynamic` absence): relies on code review, not a tooled lint
  gate. Low risk for a pure deletion (no new code).

## Overall

No Critical/High findings in any dimension. Security PASS, performance net-positive,
tests ADEQUATE. The one actionable item is a low-priority optional `findsNothing`
hardening assertion for AC-4 — `/verify` to decide whether to require it. Docs
referencing the deleted feature remain to be cleaned at `/finalize` (tech-writer),
per spec §6.
