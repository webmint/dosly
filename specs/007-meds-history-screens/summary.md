## Feature Summary: 007 — Meds & History Screens + Tabbed Routing

### What was built
The home bottom navigation bar is now fully functional — tapping Today, Meds, or History switches between three tab-hosted screens. The two new screens (`/meds`, `/history`) are empty-body placeholders with localized AppBar titles (EN/DE/UK) ready for future medication-list and adherence-history content. Navigation uses `StatefulShellRoute.indexedStack`, so each tab preserves its own navigation stack when the user switches away and back.

### Changes
- Task 001: Refactor HomeBottomNav signature — converted from inert (hard-coded index, no-op callback) to router-agnostic (`selectedIndex` + `onDestinationSelected` params); removed from HomeScreen (shell now provides it)
- Task 002: Create MedsScreen — new `Scaffold` + localized AppBar title (`bottomNavMeds`) + 1-px divider, empty body; widget test covers 4 locales + AppBar shape
- Task 003: Create HistoryScreen — mirror of MedsScreen using `bottomNavHistory`; same test shape
- Task 004: Create AppShell — go_router ↔ HomeBottomNav adapter that passes `navigationShell.currentIndex` / `.goBranch` as plain values
- Task 005: Router integration — replaced flat two-route `GoRouter` with `StatefulShellRoute.indexedStack` (3 branches) + sibling `/theme-preview`; added 5 integration tests

### Files changed
- `lib/core/routing/` — 1 modified (`app_router.dart`), 1 added (`app_shell.dart`)
- `lib/features/home/presentation/` — 2 modified (`home_screen.dart`, `home_bottom_nav.dart`)
- `lib/features/meds/presentation/screens/` — 1 added (`meds_screen.dart`)
- `lib/features/history/presentation/screens/` — 1 added (`history_screen.dart`)
- `test/core/routing/` — 1 added (`app_router_test.dart`)
- `test/features/` — 2 added (meds + history screen tests), 2 modified (home bottom nav tests)

Total: 11 source/test files changed (+1793 lines, −73 lines)

### Key decisions
- **`StatefulShellRoute.indexedStack`** over flat routes: preserves per-branch navigation state; already planned in `docs/features/home.md` §Evolution
- **Router-agnostic `HomeBottomNav`**: takes `int` + `ValueChanged<int>` instead of the whole `StatefulNavigationShell` — keeps the widget testable without go_router
- **Shell in `lib/core/routing/`**: the constitution's sanctioned cross-feature composition root, the only place allowed to import from multiple features
- **Reused existing ARB keys** (`bottomNavMeds` / `bottomNavHistory`) for the new AppBar titles — exact string match across all 3 locales; avoids 6 redundant translations

### Acceptance criteria
- [x] AC-1: `/meds` renders MedsScreen
- [x] AC-2: `/history` renders HistoryScreen
- [x] AC-3: MedsScreen title localized (en/de/uk)
- [x] AC-4: HistoryScreen title localized (en/de/uk)
- [x] AC-5: 1-px bottom Divider on new AppBars
- [x] AC-6: New AppBars have no actions
- [x] AC-7: New screen bodies empty
- [x] AC-8: Single shared bottom nav across tabs
- [x] AC-9: Tap destination navigates to correct route
- [x] AC-10: selectedIndex reflects current route
- [x] AC-11: Branch stack preserved across tab switches
- [x] AC-12: HomeScreen retains settings icon + theme preview
- [x] AC-13: /theme-preview renders without bottom nav
- [x] AC-14: French fallback → English on new screens
- [x] AC-15: flutter test passes (105/105)
- [x] AC-16: dart analyze clean
- [x] AC-17: flutter build apk --debug succeeds
