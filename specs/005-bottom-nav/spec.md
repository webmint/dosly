# Spec: Bottom App Navigation

**Date**: 2026-04-14
**Status**: Complete
**Author**: Claude + User

## 1. Overview

Add a Material 3 bottom navigation bar to the root `HomeScreen` that visually matches the `.bot-nav` component in `dosly_m3_template.html`. Three destinations (Today, Meds, History) with Lucide icons, pill-shaped active indicator, and automatic light/dark theming via `ColorScheme`. Destinations are intentionally non-functional at this stage — a follow-up feature will wire navigation and add multi-language support.

## 2. Current State

**Existing codebase** — the app is a thin scaffold with Material 3 theming, a single route, and Lucide icons already wired:

- `lib/app.dart:18-36` — `DoslyApp` uses `MaterialApp.router` with `AppTheme.lightTheme` / `darkTheme` and `themeController.value` driving `themeMode`. The entire tree rebuilds on theme changes via `ListenableBuilder`.
- `lib/core/routing/app_router.dart:21-34` — `appRouter` is a flat `GoRouter` with two routes: `/` → `HomeScreen`, `/theme-preview` → dev-only `ThemePreviewScreen`.
- `lib/features/home/presentation/screens/home_screen.dart:26-65` — currently a `Scaffold` with an `AppBar` ("Dosly" + disabled settings icon), a body showing "Hello World" + a temporary "Theme preview" `OutlinedButton`, and **no `bottomNavigationBar`**.
- `lib/core/theme/app_theme.dart` — Material 3 light + dark themes seeded from the hand-coded `ColorScheme` generated in Feature 001. All `surfaceContainer`, `secondaryContainer`, `onSecondaryContainer`, `onSurface`, `onSurfaceVariant`, and `outlineVariant` tokens are populated per HTML CSS variables.
- `pubspec.yaml` — `lucide_icons_flutter: ^3.1.12` is already a dependency (Feature 004). `LucideIcons.house`, `LucideIcons.pill`, and `LucideIcons.activity` are verified-working names in this project (see MEMORY.md → What Worked).
- `dosly_m3_template.html:297-332` — the `.bot-nav` CSS spec: `surface-container` background, 1-px `outline-variant` top border, 12-px top padding. Each `.nav-item` is a column of a 64×32 `.nav-pill` (rounded 16, `secondary-container` bg when active) containing a 24×24 SVG (stroke `on-surface-variant` inactive, `on-secondary-container` active), and a 10-px / 500-weight label below (`on-surface-variant` inactive; `on-surface` + 700 weight active).
- `dosly_m3_template.html:1816-1830` — the home-screen instance of `.bot-nav` uses three destinations with icons matching Lucide `house`, `pill`, `activity` and the Ukrainian labels «Сьогодні / Ліки / Історія».

**Architecture context** (from `constitution.md` §2.1 and `docs/architecture.md`): This is a pure presentation change — scoped to `lib/features/home/presentation/`. No `domain/` or `data/` work. No Riverpod providers needed yet (no state to expose). Widget tests live under `test/features/home/`.

## 3. Desired Behavior

The `HomeScreen` `Scaffold` gains a `bottomNavigationBar` that renders Flutter's built-in Material 3 `NavigationBar` with exactly three `NavigationDestination`s, in this order:

1. **Today** — `LucideIcons.house` icon
2. **Meds** — `LucideIcons.pill` icon
3. **History** — `LucideIcons.activity` icon

Visual & behavioural rules:

- `selectedIndex` is **fixed at 0** ("Today") and never changes. The `onDestinationSelected` callback is a no-op (empty lambda) — destinations are tappable (ripple effect fires) but no state changes and no route transitions occur.
- Colors come entirely from the active `ColorScheme`: background = `surfaceContainer`, pill indicator = `secondaryContainer`, selected icon = `onSecondaryContainer`, unselected icon = `onSurfaceVariant`, selected label = `onSurface`, unselected label = `onSurfaceVariant`. Light and dark themes both work correctly without any per-theme code because `NavigationBar` reads these tokens directly from the ambient `ThemeData`.
- `labelBehavior: NavigationDestinationLabelBehavior.alwaysShow` — labels are always visible under icons (matches HTML: `.nav-lbl` is never hidden).
- The bar participates in `MediaQuery.viewPadding` so content above it does not collide with the home indicator on iOS or gesture bar on Android.
- The existing `AppBar` + "Hello World" + "Theme preview" `OutlinedButton` in the body are unchanged. This spec adds a slot; it does not modify any other widget.

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Home screen | `lib/features/home/presentation/screens/home_screen.dart` | Add `bottomNavigationBar:` slot to existing `Scaffold`; add import for `LucideIcons`-backed destinations. No body changes. |
| Home bottom nav widget | `lib/features/home/presentation/widgets/home_bottom_nav.dart` | **Create new.** Stateless widget wrapping `NavigationBar` with the three fixed `NavigationDestination`s and a no-op `onDestinationSelected`. Exported as `HomeBottomNav`. |
| Widget tests | `test/features/home/presentation/widgets/home_bottom_nav_test.dart` | **Create new.** Unit-level widget tests: renders three destinations, correct labels, `selectedIndex == 0`, tap on inactive destinations does NOT change `selectedIndex`. |
| Home screen tests | `test/features/home/presentation/screens/home_screen_test.dart` | If this file exists, add an assertion that the screen now renders a `HomeBottomNav`. If it does not exist, do not create it (out of scope — tracked separately). |

## 5. Acceptance Criteria

- [x] **AC-1**: `HomeScreen` renders a `NavigationBar` (via the new `HomeBottomNav` widget) in the `Scaffold.bottomNavigationBar` slot.
- [x] **AC-2**: The bar exposes exactly three `NavigationDestination`s in order: Today, Meds, History — all with English labels.
- [x] **AC-3**: The three icons are `LucideIcons.house`, `LucideIcons.pill`, `LucideIcons.activity` respectively.
- [x] **AC-4**: `selectedIndex` is 0 (Today) on first render and remains 0 after tapping any destination.
- [x] **AC-5**: Tapping any destination does NOT navigate, does NOT push routes, and does NOT mutate any app state. It MAY produce the standard Material ripple (this is acceptable user feedback).
- [x] **AC-6**: With `ThemeMode.light`, the bar's background resolves to `ColorScheme.surfaceContainer`, the pill indicator to `secondaryContainer`, and the selected icon to `onSecondaryContainer`. With `ThemeMode.dark`, the same tokens resolve correctly for the dark scheme (no hard-coded colors anywhere).
- [x] **AC-7**: Labels are always visible (i.e. `labelBehavior: NavigationDestinationLabelBehavior.alwaysShow`) — unselected labels are not hidden on any platform.
- [x] **AC-8**: A widget test asserts AC-1 through AC-5 (rendering, labels, selected index, no-op tap).
- [x] **AC-9**: `dart analyze` passes cleanly on all modified files with no new warnings.
- [x] **AC-10**: `flutter test` passes all tests (existing + new) with 0 failures.
- [x] **AC-11**: `flutter build apk --debug` succeeds.
- [x] **AC-12**: No Flutter import, no drift import, no new code appears under `lib/features/home/domain/` or `lib/features/home/data/` as a result of this work (pure presentation change).

## 6. Out of Scope

- **Navigation wiring** — `onDestinationSelected` is deliberately a no-op. Routing to real Meds / History screens is a future feature.
- **Stateful selection** — tapping does not change the active destination. A future feature will convert the widget to stateful (or Riverpod-backed) when routes exist.
- **Internationalization / i18n / l10n** — labels are hard-coded English strings ("Today", "Meds", "History"). No ARB files, no `MaterialLocalizations` additions, no `flutter_localizations` dependency. The user explicitly flagged multi-language as the NEXT step.
- **Lifting the nav into a `ShellRoute`** — the bar is added to `HomeScreen` only. No `go_router` refactor. No `StatefulShellRoute`.
- **Meds screen, History screen, or any other screen** — only `HomeScreen` is touched.
- **Custom pixel-perfect replication** of the HTML's exact 84-px height, 12-px top padding, or custom pill dimensions. Flutter's M3 `NavigationBar` defaults (80-px height, standard 64×32 indicator) are accepted as "matching" the HTML's M3 intent. If the user later wants pixel-exact parity, it will be a separate spec.
- **Settings icon / app bar changes** — untouched.
- **Theme-preview route removal** — still tracked separately in `specs/002-main-screen/spec.md`.
- **FAB (`.fab-wrap` / `.fab` in HTML lines 350-366)** — not part of this spec.

## 7. Technical Constraints

- Must follow Clean Architecture (constitution §2.1): this change is **pure presentation**. No files under `domain/` or `data/` may be created or modified.
- Must use Material 3's built-in `NavigationBar` + `NavigationDestination` APIs. A fully-custom `Row`-based widget was considered and rejected (see §6) because `NavigationBar` already encodes the M3 pill-indicator pattern the HTML is imitating.
- Must use `LucideIcons.*` names only — no `Icons.*` Material glyphs — per Feature 004's icon-library decision. Names MUST be one of the 22 verified in MEMORY.md → "Lucide package is the right fit". `house`, `pill`, `activity` are all on that list.
- Must not hard-code colors. All colors come from `Theme.of(context).colorScheme.*` or are applied automatically by `NavigationBar` via `ThemeData.navigationBarTheme` / `ColorScheme`.
- Must not use `!` null-assertion (constitution §3 + MEMORY.md "Never").
- New public widget (`HomeBottomNav`) requires a dartdoc `///` comment per CLAUDE.md "Always §7" and constitution §3.
- Filename is `snake_case.dart` — `home_bottom_nav.dart`.
- One public type per file (constitution §2.2).
- `dart analyze` must pass in strict mode after the change (zero new warnings).
- `flutter test` must pass including the new widget test (constitution §6).

## 8. Open Questions

- **`NavigationBar` default height vs HTML `--nav-h`**: the HTML uses a CSS variable we haven't sampled; Flutter's `NavigationBar` is 80 dp. If the variable resolves to anything materially different (e.g., 72 or 96), the visual match may feel off. Acceptance is "matches M3 intent", not "pixel-exact" — see §6. Resolution: accept 80 dp default; revisit only if user flags visual mismatch after seeing it on-device.
- **Ripple on tap with a no-op callback**: supplying an empty `onDestinationSelected` keeps destinations tappable with a ripple. Supplying `null` disables them entirely. We're choosing the no-op callback so destinations feel interactive (per the HTML's `cursor: pointer` intent). AC-5 explicitly permits the ripple.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Flutter `NavigationBar` renders slightly differently from HTML's `.bot-nav` (height, padding, label size) | Medium | Low | §6 explicitly accepts "M3 intent match" over pixel-exact. Revisit as a separate spec if the user rejects the visual. |
| Adding the bar shifts the existing "Hello World" + "Theme preview" layout off-center | Low | Low | `Scaffold` adjusts body constraints automatically; existing widget tests (if any target the body center) should still pass. Run `flutter test` to verify. |
| A future "wire up navigation" spec has to refactor this widget from stateless to stateful | High | Low | Expected and intentional — called out in §6. Keeping the current widget small and isolated minimizes the churn of that refactor. |
| Lucide icon name surprise on `activity` (e.g., renamed in a patch release) | Low | Low | `LucideIcons.activity` is verified in MEMORY.md External API Quirks under Feature 004. `pubspec.yaml` pins `^3.1.12`, so a breaking rename would require an explicit upgrade. |
| Widget test flakiness around tap-is-a-no-op assertion | Low | Low | Use `tester.tap` + `pumpAndSettle`, then assert `selectedIndex` on the `NavigationBar` via `find.byType` → `widget.selectedIndex == 0`. Deterministic. |
