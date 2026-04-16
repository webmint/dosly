# Task 005: Refactor router to StatefulShellRoute + add integration test

**Agent**: mobile-engineer
**Files**:
- `lib/core/routing/app_router.dart`
- `test/core/routing/app_router_test.dart` (new)

**Depends on**: 001, 002, 003, 004
**Blocks**: None
**Review checkpoint**: Yes
**Context docs**: `docs/architecture.md` (§Routing), `specs/007-meds-history-screens/plan.md` (File Impact, Risk Assessment)

## Description

Replace the current flat two-route `GoRouter` with a `StatefulShellRoute.indexedStack` that declares three branches (`/`, `/meds`, `/history`) under a single `AppShell`, plus a sibling top-level `GoRoute('/theme-preview')` that renders **outside** the shell (so the theme preview screen has no bottom nav, satisfying AC-13). Add an integration test that pumps the full `MaterialApp.router(routerConfig: appRouter)`, verifies tab-tap navigation between the three branches, verifies `selectedIndex` tracks the current route, verifies branch stack preservation across tab switches (AC-11), and verifies `/theme-preview` renders without the shell.

This is the convergence task — it depends on the widget refactor (001), both new screens (002, 003), and the shell (004). It is a review checkpoint because routing errors here would silently break navigation for the entire app. This task also runs the full integration gate (`flutter test` + `flutter build apk --debug`) per the "integration-gate task ordering" pattern (Feature 002, MEMORY.md).

## Change details

- In `lib/core/routing/app_router.dart`:
  - Update library dartdoc to describe the new topology: "A `StatefulShellRoute.indexedStack` with three branches — `/` Home, `/meds`, `/history` — sharing a single [AppShell] scaffold + [HomeBottomNav]. The `/theme-preview` route is declared as a sibling top-level route so it renders without the shell's bottom nav (dev-preview screen)."
  - Imports: add `../../features/meds/presentation/screens/meds_screen.dart`, `../../features/history/presentation/screens/history_screen.dart`, `app_shell.dart`. Retain imports for `home_screen.dart` and `theme_preview_screen.dart`. Retain `package:go_router/go_router.dart`.
  - Replace the current `routes:` list with:
    ```dart
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/meds',
                builder: (context, state) => const MedsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/theme-preview',
        builder: (context, state) => const ThemePreviewScreen(),
      ),
    ],
    ```
  - Review the existing `TODO(post-mvp)` comment on the theme-preview route — preserve it verbatim if still accurate (it is: theme-preview remains scheduled for post-MVP removal).

- Create `test/core/routing/app_router_test.dart`:
  - Group: `'appRouter'`.
  - Pump helper: builds a `MaterialApp.router(routerConfig: appRouter)` with `AppLocalizations.localizationsDelegates` + `supportedLocales` registered.
  - **Test 1 (AC-1, AC-2, AC-9)**: Start at `/` (HomeScreen visible — `find.text('Dosly')`). Tap the bottom-nav "Meds" destination (`find.text('Meds')`). Pump-and-settle. Verify `MedsScreen` visible via `expect(find.byType(MedsScreen), findsOneWidget)`. Tap "History". Verify `HistoryScreen` visible. Tap "Today". Verify `HomeScreen` visible (`find.text('Hello World')`).
  - **Test 2 (AC-8)**: Across all three routes, exactly one `HomeBottomNav` is in the widget tree at any time: `expect(find.byType(HomeBottomNav), findsOneWidget)` after each navigation.
  - **Test 3 (AC-10)**: After `context.go('/meds')` (via direct URL push, not a tap), the `NavigationBar.selectedIndex == 1`. After `context.go('/history')`, `== 2`. After `context.go('/')`, `== 0`.
  - **Test 4 (AC-11)**: Branch stack preservation. The cleanest approach is to add a sub-route under the Meds branch in a **test-only router instance** (duplicate the `appRouter` structure in the test file with one extra child `GoRoute('sentinel', ...)` under Meds's `StatefulShellBranch`; pump this test-only router instead of the production `appRouter`). Start on `/meds`, push `/meds/sentinel`, verify sentinel visible, tap "History", verify sentinel gone (history visible), tap "Meds", verify sentinel still visible (branch stack preserved). Document in a test-file comment that this verifies the production `StatefulShellRoute` contract using a test-only child route.
  - **Test 5 (AC-13)**: Pump production `appRouter`, start at `/`, tap the "Theme preview" `OutlinedButton`, pump-and-settle. Verify `ThemePreviewScreen` visible. Verify `HomeBottomNav` is **not** in the widget tree: `expect(find.byType(HomeBottomNav), findsNothing)`.

## Contracts

### Expects
- Task 001 produced a `HomeBottomNav` with `selectedIndex` + `onDestinationSelected` constructor and no `bottomNavigationBar` in `home_screen.dart`.
- Task 002 produced `class MedsScreen` importable from `lib/features/meds/presentation/screens/meds_screen.dart`.
- Task 003 produced `class HistoryScreen` importable from `lib/features/history/presentation/screens/history_screen.dart`.
- Task 004 produced `class AppShell` importable from `lib/core/routing/app_shell.dart` with `const AppShell({required StatefulNavigationShell navigationShell, super.key})`.
- `go_router ^17.2.0` exports `StatefulShellRoute`, `StatefulShellBranch`, `GoRoute` (already true).

### Produces
- `lib/core/routing/app_router.dart` declares `final GoRouter appRouter = GoRouter(routes: [...])` whose top-level `routes` list has exactly two entries: a `StatefulShellRoute.indexedStack` with three `StatefulShellBranch` entries (paths `/`, `/meds`, `/history`), and a sibling `GoRoute(path: '/theme-preview', ...)`.
- The `StatefulShellRoute.indexedStack` builder returns `AppShell(navigationShell: navigationShell)`.
- `test/core/routing/app_router_test.dart` exists with at least 5 test cases covering AC-1, AC-2, AC-8, AC-9, AC-10, AC-11, AC-13.
- `flutter test` reports all tests pass (existing 88 + new ones from tasks 001/002/003/005).
- `flutter build apk --debug` succeeds.

## Done when

- [x] `appRouter` has exactly one `StatefulShellRoute` and one sibling `GoRoute('/theme-preview')`.
- [x] The shell's builder returns `AppShell(navigationShell: navigationShell)`.
- [x] `test/core/routing/app_router_test.dart` passes with coverage for AC-1, AC-2, AC-8, AC-9, AC-10, AC-11, AC-13.
- [x] Existing `test/widget_test.dart` still passes (boot + `Dosly` title + Theme preview navigation).
- [x] `dart analyze 2>&1 | head -40` reports no issues on the full codebase.
- [x] `flutter test` reports 100% pass.
- [x] `flutter build apk --debug` succeeds.
- [x] No `!` null-assertions introduced.
- [x] No color literals introduced outside `lib/core/theme/`.

**Spec criteria addressed**: AC-1, AC-2, AC-8, AC-9, AC-10, AC-11, AC-12 (verified unchanged via `widget_test.dart`), AC-13, AC-15, AC-16, AC-17.

## Completion Notes

**Completed**: 2026-04-15
**Files changed**: lib/core/routing/app_router.dart (modified), test/core/routing/app_router_test.dart (new, 10.7 KB)
**Contract**: Expects 5/5 verified | Produces 6/6 verified
**Notes**:
- Router refactored to `StatefulShellRoute.indexedStack` with 3 branches + sibling `/theme-preview`. `AppShell(navigationShell:)` wired in the builder.
- Test 4 (branch-stack preservation) uses a test-local `GoRouter` built via `_buildTestRouterWithSentinel()` — production `appRouter` untouched. Test-local router is `dispose()`'d at end of test.
- Test 5 verifies `find.byType(HomeBottomNav), findsNothing` on theme preview — shell isolation confirmed.
- Sentinel marker string: `'SENTINEL_MEDS_SUB'` (unique, not a common word).
- `GoRouter.of(tester.element(find.byType(HomeBottomNav)))` pattern used for programmatic navigation without `!`.
- Full integration gate: `dart analyze` clean, 105/105 tests pass (100 pre-existing + 5 new), `flutter build apk --debug` success.
- Code review: APPROVE (no issues, no warnings).

**Status**: Complete
