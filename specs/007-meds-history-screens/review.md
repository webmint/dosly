# Review Report: 007-meds-history-screens

**Date**: 2026-04-15
**Spec**: [spec.md](spec.md)
**Changed files**: 11 (6 lib/ + 5 test/)

## Security Review

- **Critical: 0 | High: 0 | Medium: 0 | Info: 6**

### Info (hardening suggestions)

- **Info** — `lib/core/routing/app_router.dart:26`: `appRouter` has no `errorBuilder`. Malformed deep-links would fall through go_router's default error screen. Not a vulnerability today (no `android:intent-filter` / `CFBundleURLTypes` declared, all routes take zero params), but when deep-linking is enabled in a future feature, add an explicit `errorBuilder` + allow-listed redirect to prevent arbitrary-path UX abuse / info-disclosure via stack traces.
  Recommendation: Defer to the feature that first adds deep-link intent filters; file a follow-up note.

- **Info** — `lib/features/home/presentation/screens/home_screen.dart:62`: `context.push('/theme-preview')` uses a hard-coded literal (safe). When the `theme-preview` dev route is deleted post-MVP (per the `TODO(post-mvp)` at `app_router.dart:58` and `home_screen.dart`), ensure BOTH the route definition and the button are removed together — no dangling dev entry point.
  Recommendation: When spec 002 post-MVP cleanup runs, grep for both `theme-preview` references and remove together.

- **Info** — Test harness files (`test/features/meds/...`, `test/features/history/...`, `test/core/routing/app_router_test.dart`): contain only locale strings and sentinel tokens. No credentials, tokens, or PII. Clean.

- **Info** — No new Dart/Flutter dependencies added for this feature. `go_router` / `flutter_localizations` / `lucide_icons_flutter` / `flutter` were all pre-existing. No `INTERNET` or network permission change.

- **Info** — Constitution §3.1 `!` ban: verified zero new null-assertions across the 6 `lib/` files. Compliant.

- **Info** — Constitution color-hardcoding rule: `Color(0xFF…)` present only under `lib/core/theme/app_color_schemes.dart`. Compliant.

### PHI / Privacy (§4.x)
No medication names, no logs, no notifications introduced. N/A for this routing-only diff.

### Security verdict: PASS

## Performance Review

- **High: 0 | Medium: 0 | Low: 3**

### Low findings

- **Low** — `lib/core/routing/app_shell.dart:63`: `onDestinationSelected: navigationShell.goBranch` is a method tearoff — allocates a new `Function` object on each `AppShell.build`. `HomeBottomNav` is a `StatelessWidget` with no equality short-circuit, so Flutter's element reconciliation always sees a new value and rebuilds the subtree. In practice `AppShell.build` only fires when `GoRouter` notifies its `RouterDelegate` (i.e., on route changes) — one extra allocation per navigation event, not per frame. The `HomeBottomNav` subtree is small (a `Column` + `NavigationBar`); cost is immeasurable on any device.
  Recommendation: No action at the current scale. If `HomeBottomNav` grows to hold heavy children, cache the wrapper as a stable field in a `StatefulWidget`.

- **Low** — `lib/features/meds/presentation/screens/meds_screen.dart:31` and `lib/features/history/presentation/screens/history_screen.dart:31`: `Text(context.l10n.bottomNavX)` cannot be `const` — runtime lookup. Expected and correct; all other leaves (`SizedBox.shrink`, `PreferredSize`, `Divider`) are `const`.
  Recommendation: None — this is the correct pattern for a localized title.

- **Low** — `lib/core/routing/app_router.dart:26`: `appRouter` is a top-level `final` singleton holding a `ChangeNotifier`. Never disposed. Harmless for a single-app lifecycle, but in tests that pump multiple `MaterialApp.router` instances sharing the same router, listeners accumulate. Tests 1–3 reuse `appRouter` across cases; Test 4 correctly creates and disposes its own router.
  Recommendation: Medium-term — when Riverpod lands, scope the router via a provider to the widget-tree lifetime. No immediate action.

### No issues for
- `StatefulShellRoute.indexedStack` memory cost — all 3 branches are empty Scaffolds, IndexedStack overhead is negligible. Revisit when branches hold real content (feature 008+).
- `pumpAndSettle` in tests — single-animation settles, no loops, no `Future.delayed`. Trivial trees.
- Startup impact — `StatefulShellRoute` branches are built lazily on first activation; top-level `final` is initialized before `runApp`. First-frame time unaffected.

### Performance verdict: CLEAN

## Test Assessment

### AC Coverage: 14 fully covered / 17 total

| AC | Description | Covered by | Status |
|----|-------------|------------|--------|
| AC-1 | `/meds` renders `MedsScreen` | router_test Test 1 + Test 3 | Covered |
| AC-2 | `/history` renders `HistoryScreen` | router_test Test 1 + Test 3 | Covered |
| AC-3 | MedsScreen title localized (en/de/uk) | meds_screen_test locale group | Covered |
| AC-4 | HistoryScreen title localized (en/de/uk) | history_screen_test locale group | Covered |
| AC-5 | 1-px bottom Divider on new AppBars | meds/history divider predicates | Covered |
| AC-6 | AppBars have no actions | meds/history "no actions" tests | Covered |
| AC-7 | Empty body on new screens | Implementation via `SizedBox.shrink()`; no dedicated test | Gap (low priority) |
| AC-8 | Exactly one `HomeBottomNav` at a time | router_test Test 2 | Covered |
| AC-9 | Tab taps navigate | router_test Test 1 | Covered |
| AC-10 | `selectedIndex` reflects route | router_test Test 3 | Covered |
| AC-11 | Branch stack preservation | router_test Test 4 (test-only sentinel router) | Covered |
| AC-12 | HomeScreen retains settings + theme preview | widget_test.dart (pre-existing, still passing) | Covered |
| AC-13 | `/theme-preview` renders without shell | router_test Test 5 | Covered |
| AC-14 | French fallback on new screens | meds/history fr-fallback cases | Covered (HomeScreen's 'Dosly' is hard-coded brand, spec §8.4 — not routed through l10n) |
| AC-15 | `flutter test` passes | Build gate: 105/105 | Covered |
| AC-16 | `dart analyze` clean | Build gate | Not test-verifiable (CI covers) |
| AC-17 | `flutter build apk --debug` | Build gate | Not test-verifiable (build pipeline covers) |

### Gaps

- **AC-7** (body is empty): no dedicated widget-test assertion. Low priority — the `SizedBox.shrink()` implementation is self-evident and a test would merely assert widget type, not behavior. Skip unless a follow-up feature regresses this.
- **AC-16 / AC-17**: by definition not test-verifiable (build-pipeline gates).

### Specific strengths

- AC-5 divider predicate (`height == 1 && thickness == 1` scoped to `find.descendant(of: appBarFinder, ...)`) correctly excludes the `HomeBottomNav`'s own top divider — no false matches.
- AC-11 (branch stack preservation) uses a test-only `GoRouter` with a sentinel sub-route; production `appRouter` stays clean. This is a reusable pattern for future shell-route coverage.
- Brand title 'Dosly' intentionally hard-coded and NOT tested under `fr` — matches the spec's own reasoning (§8.4). Defensible exclusion.

### Test verdict: ADEQUATE

No meaningful behavioral gap exists. All 14 behavioral acceptance criteria have direct test coverage; the remaining 3 are build gates (AC-16, AC-17) and a low-priority empty-body assertion (AC-7) that would duplicate source-code inspection.

---

## Overall Review Verdict: CLEAN

No Critical, High, or Medium findings across security, performance, or test coverage. Feature is ready for `/verify`.
