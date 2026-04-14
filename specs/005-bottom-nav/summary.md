## Feature Summary: 005 — Bottom App Navigation

### What was built

A Material 3 bottom navigation bar on the root `HomeScreen` with three destinations — Today, Meds, History — rendered with Lucide icons and automatic light/dark theming. The buttons are intentionally inert for now (tappable with ripple feedback, but no navigation) — a follow-up feature will wire real routes and multi-language support.

### Changes

- **Task 001** — Create HomeBottomNav widget and wire into HomeScreen: new `StatelessWidget` wrapping Flutter's M3 `NavigationBar` with three fixed `NavigationDestination`s, slotted into `HomeScreen.Scaffold.bottomNavigationBar`. Zero hard-coded colors; a top-level `_noop` function preserves `const HomeBottomNav()` at the call site.
- **Task 002** — Write widget test for HomeBottomNav: five `testWidgets` cases in a mirrored test path covering destination rendering, Lucide icons, `selectedIndex == 0` invariant, tap-is-no-op behaviour, and `labelBehavior: alwaysShow`.

### Files changed

- `lib/features/home/presentation/widgets/` — 1 file added (`home_bottom_nav.dart`, 58 lines)
- `lib/features/home/presentation/screens/` — 1 file modified (`home_screen.dart`, +7 lines)
- `test/features/home/presentation/widgets/` — 1 file added (`home_bottom_nav_test.dart`, 82 lines)
- `specs/005-bottom-nav/` — spec, plan, tasks, review, summary artifacts
- `.claude/memory/MEMORY.md` — three new "What Worked" entries (const-preserving `_noop` pattern, built-in `NavigationBar` theming, integration-gate task ordering for feature 005)

Source code total: **3 files**, ~147 lines added. Zero changes under `domain/` or `data/`.

### Key decisions

- **Widget primitive**: built-in Material 3 `NavigationBar` + `NavigationDestination` — already encodes the M3 pill-indicator pattern the HTML template was imitating and pulls theme tokens from `ColorScheme` automatically, so light/dark works with zero per-theme code. A custom `Row`-based replica was considered and rejected.
- **Statefulness**: `StatelessWidget` with `selectedIndex: 0` fixed and a no-op top-level `_noop` callback — matches the "buttons that do nothing" requirement, and the top-level function (vs inline lambda) preserves `const` construction at call sites.
- **Placement**: slot into `HomeScreen.bottomNavigationBar` only; no `StatefulShellRoute` refactor. The shell-route lift is explicitly deferred until real Meds / History screens exist.
- **Labels**: English-only (`Today`, `Meds`, `History`) — i18n is the next feature per user direction.

### Acceptance criteria

- [x] AC-1: HomeScreen renders `HomeBottomNav` in `Scaffold.bottomNavigationBar`
- [x] AC-2: Three destinations in order — Today, Meds, History
- [x] AC-3: Icons are `LucideIcons.house`, `pill`, `activity`
- [x] AC-4: `selectedIndex` is 0 on first render and stays 0 after tap
- [x] AC-5: Tap is a no-op — no navigation, no state change (ripple allowed)
- [x] AC-6: Light and dark themes resolve via `ColorScheme` with zero hard-coded colors
- [x] AC-7: `labelBehavior: NavigationDestinationLabelBehavior.alwaysShow`
- [x] AC-8: Widget test file exists with five `testWidgets` cases
- [x] AC-9: `dart analyze` clean
- [x] AC-10: `flutter test` passes — 84/84
- [x] AC-11: `flutter build apk --debug` succeeds
- [x] AC-12: No files created or modified under `lib/features/home/domain/` or `.../data/`

### Review outcome

Security PASS (0/0/0, 5 info) · Performance PASS (0/0/0) · Test coverage ADEQUATE · `/verify` verdict APPROVED.
