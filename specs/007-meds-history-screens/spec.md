# Spec: Meds & History Screens + Tabbed Routing

**Date**: 2026-04-15
**Status**: Complete
**Author**: Claude + Mykola

## 1. Overview

Add two new top-level screens — `MedsScreen` at `/meds` and `HistoryScreen` at `/history` — and wire the existing home bottom navigation bar so tapping a destination switches between them and the existing `HomeScreen` at `/`. The three screens share a single persistent bottom navigation bar via a `StatefulShellRoute`, so per-branch navigation state is preserved across tab switches. Both new screens are intentionally empty of body content at this stage; they exist as reachable placeholders ready for future features (medication list, adherence history) to hang content off.

## 2. Current State

### Routing

`lib/core/routing/app_router.dart` declares a flat `GoRouter` with exactly two routes — `/` → `HomeScreen` and `/theme-preview` → `ThemePreviewScreen` (temporary dev-only). There is no shell route, no nested navigation, no redirect logic. Consumed by `DoslyApp` via `MaterialApp.router(routerConfig: appRouter)`.

### Home screen

`lib/features/home/presentation/screens/home_screen.dart` renders a `Scaffold` with:

- `AppBar` — title `Text('Dosly')` (hard-coded, not localized), a disabled settings `IconButton` in `actions` (tooltip is localized via `context.l10n.settingsTooltip`), and a 1-px bottom `Divider` wrapped in `PreferredSize(Size.fromHeight(1))`. The `Divider` has no explicit color, so Material 3's `DividerTheme` default resolves to `ColorScheme.outlineVariant`.
- Body — centered `Hello World` text plus an `OutlinedButton('Theme preview')` that calls `context.push('/theme-preview')` (dev scaffolding, marked for post-MVP removal).
- `bottomNavigationBar` — `const HomeBottomNav()`.

### Bottom navigation widget

`lib/features/home/presentation/widgets/home_bottom_nav.dart` is a `StatelessWidget` wrapping Material 3's `NavigationBar`. It is **intentionally inert** today:

- `selectedIndex: 0` hard-coded.
- `onDestinationSelected: _noop` — a top-level `void _noop(int _) {}` (top-level is required so the widget stays `const`-constructable — inline lambdas are not `const`-compatible).
- Three destinations in fixed order: `(0) Today / LucideIcons.house`, `(1) Meds / LucideIcons.pill`, `(2) History / LucideIcons.activity`. Labels sourced from `context.l10n.bottomNavToday / bottomNavMeds / bottomNavHistory`.
- A 1-px `Divider` pinned above the `NavigationBar` matches the HTML design template's top-border rule.
- `labelBehavior: NavigationDestinationLabelBehavior.alwaysShow`.

The widget's library dartdoc and `docs/features/home.md` both explicitly call out that a **follow-up spec will convert it to track router state and actually navigate** — this is that spec.

### Localization

`lib/l10n/` holds three ARB files (`app_en.arb`, `app_de.arb`, `app_uk.arb`) with four keys: `settingsTooltip`, `bottomNavToday`, `bottomNavMeds`, `bottomNavHistory`. Fallback locale is pinned to English via a custom `_resolveLocale` in `lib/app.dart`. Widgets read strings via `context.l10n.xxx` (see `lib/l10n/l10n_extensions.dart` — the single sanctioned `!` site in the codebase).

### Architecture

Clean Architecture applies. `domain/` and `data/` layers do not exist yet — `home/` is presentation-only, and so are the new `meds/` and `history/` features introduced here (no domain logic, no persistence). `lib/core/routing/` is the documented composition root allowed to import from multiple feature folders (architecture doc §Routing).

### Memory notes that shape this spec

- `NavigationBar` itself has **no** `const` constructor (constitution memory); `const` must be applied to inner `Icon` leaves, not the outer `Column` + `NavigationBar`.
- `M3 Divider(height: 1, thickness: 1)` with no `color:` resolves to `ColorScheme.outlineVariant` — reuse this exact pattern, do not hard-code a color.
- Top-level `_noop(int _)` preserves `const`; when the widget becomes reactive, the const-ness will change and that is expected.
- `context.l10n.x` is the only allowed access path for localized strings; `AppLocalizations.of(context)` must not be called directly in widget code.
- Feature 006 established that locale-fallback tests must include an unsupported locale (e.g. `Locale('fr')`) to verify English fallback works through the custom `_resolveLocale`.

## 3. Desired Behavior

### Navigation topology

The router is refactored to a **`StatefulShellRoute.indexedStack`** with three branches:

| Branch | Path       | Screen          |
|-------:|------------|-----------------|
| 0      | `/`        | `HomeScreen`    |
| 1      | `/meds`    | `MedsScreen`    |
| 2      | `/history` | `HistoryScreen` |

A single shared shell scaffold renders the bottom navigation bar **once** and houses the active branch's screen above it. Each branch maintains its own navigation stack — if a future feature pushes a sub-route inside `/meds` and the user switches to `/history` and back, the pushed page is still on the Meds stack.

The existing `/theme-preview` route remains as a top-level (non-shell) route, reachable from the `HomeScreen` body button as today. It is deliberately outside the shell so it does not render the bottom nav (developer-preview screen).

### Bottom nav behavior

- `HomeBottomNav` is converted from inert to **router-aware**:
  - `selectedIndex` is derived from the current shell branch index (0/1/2).
  - `onDestinationSelected` calls the shell's branch-switch API (`StatefulNavigationShell.goBranch(index)`) to switch tabs.
  - Tapping the already-selected destination is a no-op (or pops to the branch root — pick one explicitly in `/plan`).
- Visual contract is unchanged: three destinations, same icons, same labels, same 1-px top divider, `labelBehavior.alwaysShow`.
- The widget is now consumed in exactly **one** place — the shell scaffold — not directly on `HomeScreen`. `HomeScreen` loses its `bottomNavigationBar` slot entirely; the shell provides it.

### Screens

#### `HomeScreen` (existing — minor change)

- Unchanged: title `Text('Dosly')`, settings `IconButton` in `actions`, 1-px bottom `Divider`, `Hello World` body, `OutlinedButton('Theme preview')`.
- **Removed**: the `bottomNavigationBar: const HomeBottomNav()` line. The shell now provides the bar.

#### `MedsScreen` (new)

- `Scaffold` with:
  - `AppBar` — title `Text(context.l10n.bottomNavMeds)`, **no** `actions`, 1-px bottom `Divider` via `PreferredSize(Size.fromHeight(1))`.
  - `body: const SizedBox.shrink()` (or equivalent empty placeholder — no visible content).
  - **No** `bottomNavigationBar` (shell provides it).
- File: `lib/features/meds/presentation/screens/meds_screen.dart`.

#### `HistoryScreen` (new)

- `Scaffold` with:
  - `AppBar` — title `Text(context.l10n.bottomNavHistory)`, **no** `actions`, 1-px bottom `Divider` via `PreferredSize(Size.fromHeight(1))`.
  - `body: const SizedBox.shrink()`.
  - **No** `bottomNavigationBar`.
- File: `lib/features/history/presentation/screens/history_screen.dart`.

### Translation strategy

- **Reuse the existing ARB keys** `bottomNavMeds` and `bottomNavHistory` for the new `AppBar` titles — the strings match exactly (English "Meds"/"History", German "Medikamente"/"Verlauf", Ukrainian "Ліки"/"Історія") and adding parallel `medsScreenTitle` / `historyScreenTitle` keys would duplicate six translations today for no current-scope benefit.
- No new ARB keys are added in this spec.
- If a future design requires divergence (e.g. longer `AppBar` title vs short nav label), a follow-up spec introduces new keys and the screens switch over — a cheap migration (one `context.l10n.x` rename each).

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Routing | `lib/core/routing/app_router.dart` | Refactor flat router into `StatefulShellRoute.indexedStack` with three branches + preserved `/theme-preview` top-level route |
| Routing | `lib/core/routing/app_shell.dart` (or similar) | **Create new** — shell scaffold that hosts the shared `HomeBottomNav` and the active branch's `StatefulNavigationShell` child |
| Home feature | `lib/features/home/presentation/screens/home_screen.dart` | Remove `bottomNavigationBar: const HomeBottomNav()` line; all other content unchanged |
| Home feature | `lib/features/home/presentation/widgets/home_bottom_nav.dart` | Convert from inert to router-aware — accept `selectedIndex` and `onDestinationSelected` from the shell, drop the hard-coded `0` and `_noop`. `const` constructability expectations change (see Open Questions §8.1) |
| Meds feature | `lib/features/meds/presentation/screens/meds_screen.dart` | **Create new** — `Scaffold` + `AppBar` (title + divider, no actions) + empty body |
| History feature | `lib/features/history/presentation/screens/history_screen.dart` | **Create new** — `Scaffold` + `AppBar` (title + divider, no actions) + empty body |
| Tests | `test/features/home/presentation/widgets/home_bottom_nav_test.dart` | Update — `selectedIndex` and `onDestinationSelected` are now inputs; the "tap is a no-op" contract is replaced by "tap invokes callback with correct index" |
| Tests | `test/features/home/presentation/widgets/home_bottom_nav_l10n_test.dart` | Likely unchanged in intent (labels in de/uk/fr-fallback) but may need minor setup tweak if the widget's constructor signature changes |
| Tests | `test/features/meds/presentation/screens/meds_screen_test.dart` | **Create new** — title renders localized, AppBar has no actions, 1-px divider present, en/de/uk/fr-fallback |
| Tests | `test/features/history/presentation/screens/history_screen_test.dart` | **Create new** — same shape as Meds test |
| Tests | `test/core/routing/app_router_test.dart` (or integration-style widget test) | **Create new** — tapping each bottom-nav destination on a running `MaterialApp.router` changes the visible screen to the correct route; pushed sub-routes are preserved across tab switches (StatefulShellRoute contract) |

## 5. Acceptance Criteria

- [x] **AC-1**: Navigating to `/meds` renders `MedsScreen`.
- [x] **AC-2**: Navigating to `/history` renders `HistoryScreen`.
- [x] **AC-3**: `MedsScreen` renders an `AppBar` whose title text is exactly `context.l10n.bottomNavMeds` (verified by pumping under English, German, and Ukrainian locales and asserting the rendered string matches each ARB value).
- [x] **AC-4**: `HistoryScreen` renders an `AppBar` whose title text is exactly `context.l10n.bottomNavHistory` (same locale coverage as AC-3).
- [x] **AC-5**: `MedsScreen` and `HistoryScreen` each render a 1-px bottom `Divider` in their `AppBar`, with no explicit `color:` — matching `HomeScreen`'s pattern so `DividerTheme` resolves to `ColorScheme.outlineVariant` in both light and dark mode.
- [x] **AC-6**: `MedsScreen` and `HistoryScreen` `AppBar`s contain no `actions` (no settings icon, no other icons) — verified by asserting `AppBar.actions` is null or empty in a widget test.
- [x] **AC-7**: `MedsScreen.body` and `HistoryScreen.body` contain no visible textual or interactive content (a `SizedBox.shrink()` or equivalent empty placeholder is acceptable).
- [x] **AC-8**: The three screens (`/`, `/meds`, `/history`) share a single bottom navigation bar rendered by the shell — there is exactly one `HomeBottomNav` in the widget tree at any time, whichever tab is active.
- [x] **AC-9**: Tapping the "Today" / "Meds" / "History" destination in the bottom nav switches the visible screen to `HomeScreen` / `MedsScreen` / `HistoryScreen` respectively (verified by a widget test that pumps the full app, taps each destination, and asserts the expected screen finder).
- [x] **AC-10**: The bottom nav's `selectedIndex` always reflects the current route — `0` on `/`, `1` on `/meds`, `2` on `/history` — even when the route is reached by direct URL / `context.go` rather than a tap.
- [x] **AC-11**: When the user pushes a sub-route inside one branch (simulated via a test helper that calls `context.push` inside the Meds branch), switches to another branch, and returns, the pushed page is still on the Meds stack. This verifies `StatefulShellRoute` state preservation.
- [x] **AC-12**: `HomeScreen` still renders its settings `IconButton` in `AppBar.actions` and still has the `OutlinedButton('Theme preview')` in its body navigating to `/theme-preview`.
- [x] **AC-13**: `/theme-preview` remains reachable via `context.push('/theme-preview')` from `HomeScreen` and renders **without** the bottom navigation bar (it is outside the shell).
- [x] **AC-14**: All three `AppBar` titles (`HomeScreen` → `'Dosly'`, `MedsScreen` → bottomNavMeds, `HistoryScreen` → bottomNavHistory) render correctly under unsupported locale `Locale('fr')` — falling back to English per the existing `_resolveLocale` contract.
- [x] **AC-15**: `flutter test` passes — existing `home_bottom_nav_test.dart` and `home_bottom_nav_l10n_test.dart` are updated to reflect the new `selectedIndex` / `onDestinationSelected` contract, and the new `meds_screen_test.dart`, `history_screen_test.dart`, and routing integration test all pass.
- [x] **AC-16**: `dart analyze` passes with zero issues on the full codebase.
- [x] **AC-17**: `flutter build apk --debug` succeeds.

## 6. Out of Scope

- **Content inside Meds / History screens** — no medication list, no adherence chart, no FAB, no empty-state message text. Bodies are empty placeholders.
- **Search input in the Meds `AppBar`** — the user has confirmed this is a future spec; the Meds `AppBar` today is title + divider only.
- **New ARB keys** — the existing `bottomNavMeds` / `bottomNavHistory` keys are reused for the titles. No `medsScreenTitle` / `historyScreenTitle` are added.
- **Settings icon behavior** — the home settings `IconButton` remains disabled (`onPressed: null`). No settings screen, no settings route.
- **Theme preview cleanup** — `ThemePreviewScreen`, its route, and the `OutlinedButton` on `HomeScreen` remain as-is. The post-MVP removal is tracked under spec 002 and is not part of this spec.
- **FAB above the bottom nav** — the HTML design shows a FAB; not added here.
- **Redirects / deep-link handling** — none. Direct URL navigation is supported by `go_router` defaults; no custom `redirect` logic is introduced.
- **`domain/` or `data/` layers for Meds / History** — these features are presentation-only at this stage. No entities, repositories, or use cases yet.
- **Icon changes** — the three bottom-nav icons (`LucideIcons.house`, `pill`, `activity`) remain unchanged; no icon review of the new screens.

## 7. Technical Constraints

- Must follow **Clean Architecture** (constitution §2.1 / §2.2). New feature folders `lib/features/meds/` and `lib/features/history/` must nest screens under `presentation/screens/`. No `domain/` or `data/` content is added in this spec.
- Must use **`go_router`'s `StatefulShellRoute.indexedStack`** for the tabbed topology. This is the standard Flutter/go_router pattern for bottom-nav tabs and matches the evolution path documented in `docs/features/home.md` §Evolution.
- Must not introduce color literals outside `lib/core/theme/` — bottom `Divider`s on both new screens rely on `DividerTheme` defaults exactly like `HomeScreen` does. The `Color(0xFF` grep invariant from spec 001 AC-14 must continue to pass.
- Must route strings through `context.l10n.x` — no direct `AppLocalizations.of(context)` calls in new screens. No new `!` sites introduced (the one in `l10n_extensions.dart` remains the sole sanctioned site).
- **No** Flutter imports in `domain/` — trivially satisfied; no `domain/` code is added.
- Must not add new dependencies. `go_router` already supports `StatefulShellRoute` — no new package needed.
- Must preserve the `appRouter` top-level `final GoRouter` pattern (mirrors `themeController`; consumed by `DoslyApp` via `MaterialApp.router(routerConfig: appRouter)`). Do **not** convert the router to a Riverpod provider in this spec — Riverpod has not been introduced yet (still tracked as a separate future migration).
- Must preserve `const` constructability of widget leaves where possible. The `NavigationBar` itself has no `const` constructor (memory note) — this is already the status quo.
- File naming is `snake_case.dart` per constitution §2.2; screen classes are `UpperCamelCase`.
- All new public classes, the shell widget, and the two new screens require dartdoc `///` comments per constitution §3 and "Always rule #7" in `CLAUDE.md`.

## 8. Open Questions

### 8.1 `HomeBottomNav` const constructability

Today `HomeBottomNav` has a `const` constructor (the whole point of the top-level `_noop` trick). Once it takes `selectedIndex: int` and `onDestinationSelected: ValueChanged<int>` parameters driven by the shell state, the **call site** can no longer be `const` (the params are runtime values). The constructor itself can remain `const`, but every caller in the shell will construct it non-const.

Decision needed in `/plan`: is this acceptable (the widget class stays `const`-capable, just unused), or should the widget be simplified (drop the `const` constructor, drop the top-level `_noop`) since the only caller can no longer exploit it? Recommendation: keep the `const` constructor, drop `_noop` (it becomes dead code).

### 8.2 Tap on already-selected destination

When the user is on `/meds` and taps the "Meds" destination, should the tap (a) be a no-op, or (b) pop the branch stack to the branch root (common iOS / Material pattern for "re-tap to reset")? `StatefulNavigationShell.goBranch(initialLocation: true)` supports the latter. The user has not specified. Recommendation: no-op in this spec (simpler); tracked for a later polish spec if desired.

### 8.3 Location of the shell scaffold widget

Two plausible homes: `lib/core/routing/app_shell.dart` (composition root, allowed to import multiple features) or `lib/features/home/presentation/widgets/app_shell.dart` (home-feature-scoped, since the home nav is a home-feature widget). The constitution is silent; architecture doc hints at `core/routing/` for cross-feature composition. Recommendation: `lib/core/routing/app_shell.dart` — it imports `HomeBottomNav` and the three branch screens, which is exactly the cross-feature coordination `core/routing/` exists for.

### 8.4 Should `HomeScreen` title `'Dosly'` also be localized?

Currently hard-coded. Not part of the user's request, but brand names typically aren't translated, so leaving as-is is defensible. Flagged only because all three screens will now have `AppBar` titles and two of them are localized. Recommendation: leave `'Dosly'` hard-coded, add a comment noting it is a brand name.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `StatefulShellRoute.indexedStack` changes the visible widget tree shape enough that existing `HomeScreen` widget tests (smoke tests verifying theme preview button, settings icon) break | Medium | Low | Update tests to pump the full router (or an isolated `HomeScreen` under a bare `MaterialApp`) consistently; existing tests in feature 002 already pump under `MaterialApp.router` so the pattern is known |
| Removing `bottomNavigationBar: const HomeBottomNav()` from `HomeScreen` breaks a test that asserts its presence | High | Low | Inventory `test/features/home/` up front in `/plan`; update assertions to target the shell instead of `HomeScreen` |
| Accidentally introducing a new `!` null-assertion somewhere in the shell wiring (e.g. reading `StatefulNavigationShell.of(context)!`) | Medium | Medium | Use pattern-match / explicit null-check; if the shell API genuinely returns nullable and the null case is unreachable, centralize the `!` in an extension exactly like `context.l10n` |
| Two-level routing (shell + `/theme-preview` top-level) confuses the router when the user deep-links to `/theme-preview` | Low | Low | Keep `/theme-preview` declared as a **sibling** top-level `GoRoute` to the `StatefulShellRoute`, not nested inside any branch; covered by AC-13 |
| Widget tests for Meds/History locales rely on existing `AppLocalizations.localizationsDelegates` wiring, but a forgotten `supportedLocales` in the test harness silently falls back to English and hides a bug | Medium | Medium | Copy the existing `home_bottom_nav_l10n_test.dart` harness verbatim for the new screen tests — it is a known-good pattern that already covers en/de/uk/fr-fallback |
| Converting `HomeBottomNav` from inert to reactive changes `const` constructability at call sites; reviewer flags as a regression | Low | Low | Call it out in the `/plan` and the task file; the trade-off is deliberate and documented in Open Question §8.1 |
