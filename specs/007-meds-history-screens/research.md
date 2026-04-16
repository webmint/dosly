# Research: Meds & History Screens + Tabbed Routing

**Date**: 2026-04-15
**Signals detected**: first use of `StatefulShellRoute` in this codebase (go_router is already installed at ^17.2.0, so it is not a new dependency — but shell routes are a new pattern here, and the API shape must be verified against the installed version).

## Questions Investigated

1. **What is the canonical shape of `StatefulShellRoute.indexedStack` in go_router 17.x?** → Confirmed via Context7 (`/websites/pub_dev_go_router`). Signature:

   ```dart
   StatefulShellRoute.indexedStack({
     required List<StatefulShellBranch> branches,
     StatefulShellRouteBuilder? builder,  // (context, state, navigationShell) => Widget
     ...
   })
   ```

   Each branch is a `StatefulShellBranch(navigatorKey: ..., routes: [...])`. The `builder` is handed a `StatefulNavigationShell` instance, which:
   - exposes `currentIndex` (int) for the active branch
   - exposes `goBranch(int index, {bool initialLocation = false})` for switching branches
   - is itself a `Widget` — passed directly as the `body:` of the shell `Scaffold`.

2. **Do per-branch `navigatorKey`s need to be supplied?** → They are optional — go_router generates them automatically when omitted. Supplying them explicitly is only necessary when something outside the shell needs to address a specific branch navigator (e.g. a global `FAB` that pushes into a specific tab). Not needed for this spec.

3. **How is the bottom nav wired to the shell?** → Standard pattern from the go_router docs:

   ```dart
   Scaffold(
     body: navigationShell,
     bottomNavigationBar: BottomNavigationBar(   // or M3 NavigationBar
       currentIndex: navigationShell.currentIndex,
       onTap: (int index) => navigationShell.goBranch(index),
       items: [...],
     ),
   )
   ```

   The docs explicitly note that the `StatefulNavigationShell` is "directly passed as the body of the Scaffold." This is the exact shape we adopt.

4. **How does tap-on-selected-destination behave by default?** → `goBranch(index)` without `initialLocation: true` restores the branch's last location (no-op if the user is already on the branch's root). With `initialLocation: true` it resets the branch stack. We adopt the default (restore), matching Open Question §8.2 "no-op" recommendation.

5. **Can a top-level `GoRoute` (e.g. `/theme-preview`) coexist with a `StatefulShellRoute` at the router top level?** → Yes. The router's top-level `routes:` list accepts a mix of `GoRoute` and `StatefulShellRoute` entries. A `GoRoute` declared as a sibling of the `StatefulShellRoute` renders **outside** the shell (no bottom nav), which is exactly the desired behavior for `/theme-preview`.

6. **Does the existing `ListenableBuilder(listenable: themeController)` wrapping of `MaterialApp.router` interact badly with `StatefulShellRoute`?** → No. Feature 002's memory note confirms: `MaterialApp.router(routerConfig: appRouter)` wrapped in a `ListenableBuilder` preserves the router instance (the top-level `final GoRouter` constant is not reconstructed). `StatefulShellRoute` lives inside that same router and therefore inherits the same stability. No change needed to `lib/app.dart`.

## Alternatives Compared

### Tabbed routing approach

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| `StatefulShellRoute.indexedStack` (go_router) | Official go_router pattern; preserves per-branch navigation state automatically; matches HTML design intent; already planned in `docs/features/home.md` §Evolution | First shell route in codebase — one-time learning cost | **Chosen** |
| Plain `GoRoute` + `context.go` on tap, no shell | Simplest; no new pattern | Loses per-branch stack state on every tab switch; forces the bottom nav to be re-rendered inside each screen (duplication); screens must each own their copy of the nav bar, fighting the "exactly one bottom nav" AC-8 | Rejected |
| `ShellRoute` (non-stateful) | Shared shell, less machinery than `StatefulShellRoute` | No branch-stack preservation — identical downside to option above for our use case | Rejected |
| Custom `IndexedStack` in `HomeScreen` holding three inlined screens, no routing change | Minimal router churn | Breaks the "each screen has its own route" user expectation (no URL, no deep-link for `/meds`); can't push a sub-route inside a tab | Rejected |

**Decision**: `StatefulShellRoute.indexedStack` — it is the single-purpose tool for this exact shape, and future features (deep links to a specific medication, sub-route under `/meds/edit`) already have a clean path.

### Bottom-nav ↔ shell coupling

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| `HomeBottomNav(navigationShell: StatefulNavigationShell)` — widget takes the whole shell | Single param; always consistent | Couples `HomeBottomNav` to go_router; widget tests need to fake a `StatefulNavigationShell` | Rejected |
| `HomeBottomNav(selectedIndex: int, onDestinationSelected: ValueChanged<int>)` — widget is router-agnostic | Decoupled, trivially testable with plain callbacks; shell is the adapter | Two params instead of one | **Chosen** |

**Decision**: Two-param router-agnostic widget. The shell (`AppShell`) owns the go_router coupling and passes `navigationShell.currentIndex` / `navigationShell.goBranch` as plain values. `HomeBottomNav` remains pure presentation and its tests do not import go_router. Matches the constitution's "domain/presentation separation of concerns" spirit even though both live in presentation — we're isolating the router adapter.

### Shell widget location

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| `lib/core/routing/app_shell.dart` | Explicitly allowed cross-feature composition root (architecture doc §Routing); natural home for a widget that composes `HomeBottomNav` with three feature-scoped screens | Imports from `features/home/`, `features/meds/`, `features/history/` — but that is the documented exception for `core/routing/` | **Chosen** |
| `lib/features/home/presentation/widgets/app_shell.dart` | Keeps `HomeBottomNav` consumption co-located | Violates cross-feature rule (constitution §2.1: "A widget in `features/A/presentation/` may NOT import from `features/B/`") — would need to import Meds and History screens | Rejected |

**Decision**: `lib/core/routing/app_shell.dart`.

## References

- [go_router StatefulShellRoute.indexedStack](https://pub.dev/documentation/go_router/latest/go_router/StatefulShellRoute/StatefulShellRoute.indexedStack)
- [go_router StatefulNavigationShell.goBranch](https://pub.dev/documentation/go_router/latest/go_router/StatefulNavigationShellState/goBranch)
- [go_router stacked_shell_route example](https://github.com/flutter/packages/blob/main/packages/go_router/example/lib/stacked_shell_route.dart) — canonical runnable sample
- `docs/features/home.md` §Evolution — pre-existing plan to adopt `StatefulShellRoute`
- `docs/architecture.md` §Routing — confirms `lib/core/routing/` is the allowed cross-feature composition root
- MEMORY.md "What Worked" — `ListenableBuilder` + `MaterialApp.router` + top-level `GoRouter` constant coexistence confirmed in Feature 002
