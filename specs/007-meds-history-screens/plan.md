# Plan: Meds & History Screens + Tabbed Routing

**Date**: 2026-04-15
**Spec**: [spec.md](spec.md)
**Status**: Approved

## Summary

Replace the flat two-route `GoRouter` with a `StatefulShellRoute.indexedStack` holding three branches (`/`, `/meds`, `/history`), plus a preserved top-level `/theme-preview` sibling route. Introduce a shell scaffold at `lib/core/routing/app_shell.dart` that hosts a single shared bottom navigation bar and passes `selectedIndex` / `onDestinationSelected` to a refactored, router-agnostic `HomeBottomNav`. Add two presentation-only screens (`MedsScreen`, `HistoryScreen`) with localized `AppBar` titles reusing existing ARB keys, empty bodies, and no action icons. No domain or data layers are introduced.

## Technical Context

**Architecture**: Clean Architecture (constitution §2.1). This feature is entirely presentation + routing — three new `features/[x]/presentation/screens/` files, one new `core/routing/` shell widget, router refactor. No `domain/`, `data/`, repositories, or use cases are added. The Meds and History feature folders are created with only a `presentation/` subtree.

**Error Handling**: N/A for this feature. No fallible operations, no `Either<Failure, T>` surfaces. All new widgets are pure build functions over `BuildContext` + localization.

**State Management**: Persistent tab state is owned by go_router's `StatefulShellRoute.indexedStack` (no Riverpod introduced in this spec — Riverpod migration remains a separate future concern). Theme state continues to use the existing `ValueNotifier<ThemeMode> themeController` + `ListenableBuilder` pattern unchanged.

## Constitution Compliance

| Rule | Compliance |
|------|------------|
| §2.1 Layer boundaries | Compliant — new features are `presentation/`-only. No `domain/` or `data/` content is added, so the "no Flutter in `domain/`" and "no `data/` in `presentation/`" rules are trivially satisfied. |
| §2.1 Cross-feature imports | Compliant — the shell in `lib/core/routing/app_shell.dart` is the documented exception permitted to import from multiple feature folders. No feature imports another feature directly. |
| §2.2 File organization | Compliant — `lib/features/meds/presentation/screens/meds_screen.dart` and `lib/features/history/presentation/screens/history_screen.dart` follow the mandated layout. `snake_case.dart` filenames. |
| §2.3 Package policy | Compliant — zero new dependencies; `go_router ^17.2.0` already installed. |
| §3.1 Type safety — no `!` | Compliant — no new `!` sites. Localization access is centralized via the existing `context.l10n` extension. Any shell-state lookup uses typed args, not `StatefulNavigationShell.of(context)!`. |
| §3.1 Type safety — no `dynamic` | Compliant — all new widget signatures use concrete types (`int`, `ValueChanged<int>`, `StatefulNavigationShell`). |
| §3.3 Naming | Compliant — `MedsScreen`, `HistoryScreen`, `AppShell` in `UpperCamelCase`; file names in `snake_case`. |
| §3.5 Dartdoc for public API | Planned — every new public class (`MedsScreen`, `HistoryScreen`, `AppShell`) and every changed public signature (`HomeBottomNav` constructor) gets `///` comments. |
| §3.6 Keep it simple | Compliant — no abstractions beyond what go_router demands. No new state management. No new packages. |
| "No color literals outside `lib/core/theme/`" (spec 001 AC-14) | Compliant — new `Divider`s on Meds/History `AppBar`s are `const Divider()` with no `color:`, resolving via `DividerTheme` to `ColorScheme.outlineVariant`. `Color(0xFF` grep invariant holds. |
| "No feature A imports feature B" | Compliant — `MedsScreen` and `HistoryScreen` do not import each other or the home feature. The shell is the only cross-feature importer (allowed). |
| "All new public classes have dartdoc" | Planned — see §3.5 row. |
| "No `!` null-assertions" | Compliant — see §3.1 row. Open Question §8.1 deferred until implementation; current plan does NOT introduce a new `!` site. |

## Implementation Approach

### Layer Map

| Layer | What | Files (existing or new) |
|-------|------|------------------------|
| Presentation (Home) | Remove `bottomNavigationBar` line; keep AppBar + body unchanged | `lib/features/home/presentation/screens/home_screen.dart` (modify) |
| Presentation (Home) | Refactor inert widget → router-agnostic with `selectedIndex` + `onDestinationSelected` params. Drop hard-coded `0` and top-level `_noop`. Preserve `const` constructor. | `lib/features/home/presentation/widgets/home_bottom_nav.dart` (modify) |
| Presentation (Meds) | New screen — `Scaffold(appBar: AppBar(title: Text(context.l10n.bottomNavMeds), bottom: PreferredSize(Divider())), body: SizedBox.shrink())` | `lib/features/meds/presentation/screens/meds_screen.dart` (new) |
| Presentation (History) | New screen — same shape as Meds with `context.l10n.bottomNavHistory` | `lib/features/history/presentation/screens/history_screen.dart` (new) |
| Routing | New shell widget — `Scaffold(body: navigationShell, bottomNavigationBar: HomeBottomNav(selectedIndex: navigationShell.currentIndex, onDestinationSelected: navigationShell.goBranch))` | `lib/core/routing/app_shell.dart` (new) |
| Routing | Refactor `appRouter` — replace flat `[GoRoute('/'), GoRoute('/theme-preview')]` with `[StatefulShellRoute.indexedStack(builder: ..., branches: [Today, Meds, History]), GoRoute('/theme-preview')]` | `lib/core/routing/app_router.dart` (modify) |
| Tests | Update — `HomeBottomNav` now takes `selectedIndex` / `onDestinationSelected`. Replace "tap is no-op" assertion with "tap invokes callback with expected index" | `test/features/home/presentation/widgets/home_bottom_nav_test.dart` (modify) |
| Tests | Likely minor tweak — pass `selectedIndex: 0, onDestinationSelected: (_) {}` when pumping the widget under each locale | `test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart` (modify) |
| Tests | New — MedsScreen widget test: title localized in en/de/uk, Locale('fr') → English fallback, no actions, 1-px divider | `test/features/meds/presentation/screens/meds_screen_test.dart` (new) |
| Tests | New — mirror of Meds test for HistoryScreen | `test/features/history/presentation/screens/history_screen_test.dart` (new) |
| Tests | New — integration-style: pump full `MaterialApp.router(routerConfig: appRouter)`, tap each destination, assert the expected screen is visible; push a sub-route inside Meds (using a test-only helper or by reading the branch `Navigator`), switch tabs, return, assert sub-route still on stack (AC-11) | `test/core/routing/app_router_test.dart` (new) |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| Tabbed routing mechanism | `StatefulShellRoute.indexedStack` with three branches | Preserves per-branch navigation state; single-place bottom nav; standard go_router idiom; already planned in `docs/features/home.md` §Evolution | Flat routes with per-screen nav bar (duplication + state loss); `ShellRoute` without state (same state-loss downside); in-`HomeScreen` `IndexedStack` (breaks URL/deep-link per tab) |
| `/theme-preview` placement | Sibling top-level `GoRoute`, outside the shell | Dev preview should NOT render the bottom nav; go_router supports mixing top-level `GoRoute` + `StatefulShellRoute` | Nesting under a shell branch (would render the bar on dev preview) |
| Shell widget location | `lib/core/routing/app_shell.dart` | Constitution §2.1 and `docs/architecture.md` §Routing explicitly designate `core/routing/` as the cross-feature composition root | Inside `features/home/` (would have to import from `features/meds/` and `features/history/` — violates cross-feature rule) |
| `HomeBottomNav` signature | Accept `selectedIndex: int` and `onDestinationSelected: ValueChanged<int>`; remove `_noop` top-level | Keeps the widget router-agnostic — tests do not import go_router; shell is the adapter | Pass the whole `StatefulNavigationShell` (couples widget to go_router; harder to test) |
| `const` constructor on `HomeBottomNav` | Keep the `const` constructor; it simply cannot be exercised at the shell call site anymore (runtime `navigationShell.currentIndex`) | Zero cost to keep; future non-shell callers (e.g. a static preview) can still use it | Drop the `const` constructor entirely (pointless loss of capability) |
| Tap on already-selected destination | Default `goBranch(index)` — restores branch's last location (effective no-op on root) | Matches spec OQ §8.2 recommendation; simplest; no extra state management | `goBranch(index, initialLocation: true)` to reset branch stack on re-tap (defer as later polish) |
| Reuse ARB keys for AppBar titles | Use `bottomNavMeds` / `bottomNavHistory` unchanged for the new titles | Exact string match across all three locales; adding parallel keys is 6 lines × 3 ARBs with zero behavioral gain | New `medsScreenTitle` / `historyScreenTitle` keys (premature split) |
| `HomeScreen.title` localization | Leave `Text('Dosly')` hard-coded | Brand name — not translated in any locale | Introduce `appBrandTitle` key (adds noise for no benefit) |
| Navigator keys per branch | Omitted — let go_router auto-generate | Nothing outside the shell needs to address a specific branch navigator; auto-generated keys work fine | Supply explicit `GlobalKey<NavigatorState>` per branch (unnecessary machinery today) |
| Test harness pattern | Copy `home_bottom_nav_l10n_test.dart`'s pattern verbatim for the two new screen tests (registers `AppLocalizations.localizationsDelegates`, iterates en/de/uk/fr) | Known-good pattern that already covers the fallback-locale bug from Feature 006 | Hand-roll a new harness (risks silently falling back to English on missing delegates) |

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `lib/core/routing/app_router.dart` | Modify | Replace flat two-`GoRoute` list with `[StatefulShellRoute.indexedStack(builder: (c, s, shell) => AppShell(navigationShell: shell), branches: [<three branches>]), GoRoute('/theme-preview')]`. Update library dartdoc to describe the new topology. Remove the `TODO(post-mvp)` comment only if it remains accurate for `/theme-preview`. |
| `lib/core/routing/app_shell.dart` | Create | `class AppShell extends StatelessWidget` taking `final StatefulNavigationShell navigationShell`. `build` returns `Scaffold(body: navigationShell, bottomNavigationBar: HomeBottomNav(selectedIndex: navigationShell.currentIndex, onDestinationSelected: navigationShell.goBranch))`. Full library + class dartdoc. |
| `lib/features/home/presentation/screens/home_screen.dart` | Modify | Remove the `bottomNavigationBar: const HomeBottomNav()` line. Update dartdoc to note the bar is now provided by the shell. All other content (AppBar, settings icon, body, theme-preview button) unchanged. |
| `lib/features/home/presentation/widgets/home_bottom_nav.dart` | Modify | Add `final int selectedIndex; final ValueChanged<int> onDestinationSelected;` fields. Update constructor to `const HomeBottomNav({required this.selectedIndex, required this.onDestinationSelected, super.key})`. Pass these to the inner `NavigationBar`. Remove top-level `_noop`. Update library + class dartdoc to describe the new contract. |
| `lib/features/meds/presentation/screens/meds_screen.dart` | Create | `class MedsScreen extends StatelessWidget` with `const MedsScreen({super.key})`. `build` returns `Scaffold(appBar: AppBar(title: Text(context.l10n.bottomNavMeds), bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider())), body: const SizedBox.shrink())`. Full library + class dartdoc. |
| `lib/features/history/presentation/screens/history_screen.dart` | Create | Mirror of `meds_screen.dart` with `context.l10n.bottomNavHistory` and adjusted dartdoc. |
| `test/features/home/presentation/widgets/home_bottom_nav_test.dart` | Modify | Inject `selectedIndex: 0` / `onDestinationSelected: recorder` when pumping. Replace "tap → selectedIndex still 0" assertion with "tap on Meds destination → recorder receives `1`; tap on History → receives `2`". Keep the icon / destination-count / label / 1-px divider / alwaysShow assertions unchanged. |
| `test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart` | Modify | Adjust `HomeBottomNav()` call sites to `HomeBottomNav(selectedIndex: 0, onDestinationSelected: (_) {})`. Locale loop and assertions unchanged. |
| `test/features/meds/presentation/screens/meds_screen_test.dart` | Create | Harness copied from `home_bottom_nav_l10n_test.dart`. Cases: English title, German title, Ukrainian title, French fallback to English. AppBar actions null/empty. 1-px divider present (find by `Divider` finder within AppBar). |
| `test/features/history/presentation/screens/history_screen_test.dart` | Create | Mirror of Meds test with `bottomNavHistory`. |
| `test/core/routing/app_router_test.dart` | Create | Pump `MaterialApp.router(routerConfig: appRouter)`. Verify `/` shows `HomeScreen`. Tap Meds destination → `MedsScreen` visible. Tap History → `HistoryScreen` visible. Tap Today → `HomeScreen` visible. Navigate to `/theme-preview` and verify bottom nav is **absent** from that screen (AC-13). For AC-11: push a sentinel page inside the Meds branch (via a test-only helper that calls `context.push('/meds/sentinel')` — requires a one-off test-only route added in the test file's `GoRouter`, OR simpler: use a `GlobalKey<NavigatorState>` on a branch and push directly. Investigate during task execution which flavor is cleanest.) |

### Documentation Impact

| Doc File | Action | What Changes |
|----------|--------|-------------|
| `docs/architecture.md` | Update | §Routing table now lists `/`, `/meds`, `/history`, `/theme-preview`. Add a short subsection describing the `StatefulShellRoute` topology and that `lib/core/routing/app_shell.dart` is the shared scaffold. Retire the "flat route table, no shell route" paragraph. |
| `docs/features/home.md` | Update | §Evolution step 1 ("Wire real navigation") moves from the "planned" list to "done in 007-meds-history-screens". Update `HomeBottomNav` code snippet to show the new `selectedIndex` / `onDestinationSelected` constructor. Note that `_noop` was removed. |
| `docs/features/meds.md` | Create | New file describing the Meds feature folder (currently: one empty-body screen at `/meds`, title localized via `bottomNavMeds`). Include the pattern for future content hanging off this screen. |
| `docs/features/history.md` | Create | Mirror of `docs/features/meds.md` for History. |

`/finalize` runs `tech-writer`, which will author these updates based on the final committed code — the plan just notes intent.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `StatefulShellRoute.indexedStack` builder signature mismatch with go_router 17.x (Context7 docs drift) | Low | Medium | Research pulled signature directly from `/websites/pub_dev_go_router` (current pub.dev docs for latest). Verify at implementation time with `flutter analyze` — any signature drift fails the build, no silent bug. |
| Existing `home_bottom_nav_test.dart` pumps `const HomeBottomNav()` — breaking the constructor breaks the test compilation, but the test file is small; risk is just "remember to update it" | High | Low | `/execute-task` phase 3 post-execution will re-run `flutter test` and surface the failure immediately if missed. Task breakdown should pair the widget change with the test update in the same task. |
| `StatefulShellRoute` bumps the widget-tree depth, which some existing widget tests pumping `HomeScreen` in isolation (without the shell) may not care about, but testing the tree shape around `MaterialApp.router` may now see an extra layer | Low | Low | Tests pumping `HomeScreen` directly continue to work — `HomeScreen` is still a normal widget. Tests pumping the full router get the shell. No test mixes the two. |
| Test for AC-11 (branch stack preservation across tab switches) requires pushing a sub-route inside a branch, but no sub-routes exist in production yet | Medium | Medium | Test file declares a test-only child `GoRoute` under the Meds branch with a sentinel widget. This is a standard go_router testing pattern and does not pollute production routes. Document the approach in the task file so the implementer doesn't have to re-invent it. |
| Removing the `_noop` top-level function is a public-API removal (it's prefixed `_` so actually private); confirm no other file imports it | Low | Low | Grep for `_noop` — it is file-private (underscore prefix), so nothing outside can reference it. Safe to remove. |
| `AppShell` receives a non-null `StatefulNavigationShell` from go_router, but a careless refactor could introduce a `navigationShell?.currentIndex ?? 0` null-pathway masking bugs | Low | Low | Spec §7 bans new `!` sites; if the shell API ever returned nullable, we'd centralize the assertion like `context.l10n`. Current API is non-null — straight pass-through is correct. |
| `flutter build apk --debug` fails due to some subtle interaction between `StatefulShellRoute` and the existing `MaterialApp.router` + `ListenableBuilder` wrapping | Low | High | MEMORY.md Feature 002 confirms this combination works (`ListenableBuilder` preserves the router instance across theme changes). No change to `lib/app.dart` is planned. Mitigation: the task that modifies `app_router.dart` has `flutter build apk --debug` in its Done-when conditions. |

## Dependencies

None. `go_router ^17.2.0` is already in `pubspec.yaml` and supports `StatefulShellRoute.indexedStack`. No new packages, no configuration changes, no environment variables.

## Supporting Documents

- [Research](research.md) — go_router API verification, alternatives comparison, shell-placement rationale
- Data Model — N/A (no entities introduced)
- Contracts — N/A (no API surface)
