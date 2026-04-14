# Review Report: 005-bottom-nav

**Date**: 2026-04-14
**Spec**: [spec.md](spec.md)
**Changed files**: 3
- `lib/features/home/presentation/widgets/home_bottom_nav.dart` (new, 58 lines)
- `lib/features/home/presentation/screens/home_screen.dart` (modified, +3 lines)
- `test/features/home/presentation/widgets/home_bottom_nav_test.dart` (new, 82 lines)

## Security Review

- Critical: 0 | High: 0 | Medium: 0 | Info: 5
- **Overall: PASS**

### Findings

No Critical, High, or Medium findings.

### Info (hardening observations)
- No I/O, no state, no external input, no PHI, no crypto, no storage, no network — most MASVS categories are vacuous for this feature.
- Constitution §3 checks clean: no `!` null assertions, no `dynamic`, no `print`/`debugPrint`, no `SharedPreferences` usage introduced.
- Constitution §6 (privacy): static UI labels (`Today`/`Meds`/`History`) are not PHI; nothing logged.
- Imports limited to already-vetted project dependencies (`flutter/material.dart`, `lucide_icons_flutter`, `go_router` — the last pre-existing in `home_screen.dart` and not introduced here).
- `onDestinationSelected: _noop` is an inert top-level function — no side effects, no context capture, no `mounted`/`await` concerns.

## Performance Review

- High: 0 | Medium: 0 | Low: 0
- **Overall: PASS**

### Findings

No findings.

### Notes
- `HomeBottomNav` is a `StatelessWidget` with a `const` constructor.
- `destinations` is a `const <NavigationDestination>[…]` with `const Icon(LucideIcons.xxx)` children — the MEMORY pitfall "generic helper params blocking const on Icon" is respected (no helper wraps the icons).
- `onDestinationSelected: _noop` preserves const-compatibility at call sites.
- `home_screen.dart:69` instantiates as `const HomeBottomNav()`, so the subtree is canonicalized and skipped on `HomeScreen` rebuilds.
- Widget tree depth is flat (one `NavigationBar` with 3 leaves). Nothing to optimize.

## Test Assessment

- AC items with direct test coverage: **7 of 12** (AC-1, 2, 3, 4, 5, 7, 8)
- Gate-verified (CI, not unit test): **3** (AC-9, 10, 11)
- Structural / static-inspection: **2** (AC-6, 12)
- **Verdict: ADEQUATE**

### AC-to-Test Traceability

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | ✅ | `_harness()` places `HomeBottomNav` in `Scaffold.bottomNavigationBar`; `find.byType(NavigationBar)` succeeds across cases. |
| AC-2 | ✅ | "renders exactly 3 NavigationDestinations…" asserts `findsNWidgets(3)` + each English label. |
| AC-3 | ✅ | "renders the correct Lucide icons…" — `find.byIcon(LucideIcons.house/pill/activity)`. |
| AC-4 | ✅ | "selectedIndex is 0 on first render" + "tapping an inactive destination does not change selectedIndex" (Meds then History taps, asserts 0 both times). |
| AC-5 | ✅ (with static inspection) | Tap test confirms no state change; no-route-push is self-evident — harness has no router and `_noop` is a 3-line top-level function. |
| AC-6 | ⚠️ structural | No hard-coded colors in source (zero `Color(` / `Colors.` refs); `NavigationBar` inherits `ColorScheme` automatically. Golden theme-swap test would cost more than it catches for an inert widget. |
| AC-7 | ✅ | Direct assertion on `bar.labelBehavior == NavigationDestinationLabelBehavior.alwaysShow`. |
| AC-8 | ✅ | Test file itself (82 lines, 5 `testWidgets` cases). |
| AC-9 | gate-verified | `dart analyze` — clean. |
| AC-10 | gate-verified | `flutter test` — 84/84 passing. |
| AC-11 | gate-verified | `flutter build apk --debug` — success. |
| AC-12 | structural | `ls lib/features/home/` → only `presentation/` exists; no `domain/` or `data/`. |

### Coverage Gaps

- **AC-1 screen-level integration**: Tests exercise `HomeBottomNav` in a synthetic `Scaffold`, not inside `HomeScreen` itself. Spec §4 explicitly scopes this out ("If [home_screen_test.dart] does not exist, do not create it"). Accepted scope limit, not a gap.
- **AC-2 order**: Tests assert labels exist, not their left-to-right position. Order is determined by a `const` list and `NavigationBar` preserves it deterministically — position-based assertions would be over-testing.
- **AC-5 no-route-push**: No `NavigatorObserver` spy. Low value — harness has no routes and the no-op callback is inspectable in 3 lines.

### Edge Cases Worth Adding

None. The widget is 58 lines, stateless, zero-branching, zero-parameter. Additional tests (theme swap, golden snapshots, semantics tree, RTL) would cost more to maintain than they'd catch for an inert presentational widget that the spec explicitly marks for rewrite when routing lands (spec §6).
