# Plan: Bottom App Navigation

**Date**: 2026-04-14
**Spec**: [spec.md](spec.md)
**Status**: Approved

## Summary

Implement a new stateless `HomeBottomNav` widget that wraps Flutter's built-in Material 3 `NavigationBar` with three fixed `NavigationDestination`s (Today / Meds / History, using Lucide icons). Wire it into `HomeScreen.Scaffold.bottomNavigationBar`. Pure presentation-layer work — no `domain/` or `data/` files touched, no dependencies added, no theme changes.

## Technical Context

**Architecture**: Presentation layer only (`lib/features/home/presentation/widgets/` + `lib/features/home/presentation/screens/`). Clean Architecture §2.1 satisfied trivially because no domain logic exists.
**Error Handling**: N/A — widget has no fallible operations. `NavigationBar` itself never throws under documented use.
**State Management**: None. `HomeBottomNav` is `StatelessWidget`. `selectedIndex` is hard-coded to `0`; `onDestinationSelected` is a const empty lambda. No Riverpod provider, no `StatefulWidget`, no `ValueNotifier`.

## Constitution Compliance

| Rule | Status |
|------|--------|
| §2.1 Layer boundaries — no Flutter/drift/3rd-party in `domain/` | ✅ Compliant — no `domain/` files touched |
| §2.2 Filenames `snake_case.dart`, one public type per file | ✅ `home_bottom_nav.dart` contains only `HomeBottomNav` |
| §2.3 Dependency rules — no new packages | ✅ Uses only `flutter/material.dart` + already-installed `lucide_icons_flutter` |
| §3 Code quality — null safety, no `!`, dartdoc on public API | ✅ No nullables introduced; `HomeBottomNav` + constructor get `///` dartdoc |
| §3 Error handling — `Either<Failure, T>` at boundaries | ✅ N/A — no fallible ops |
| §6 Testing — widget tests mirror `lib/` structure | ✅ `test/features/home/presentation/widgets/home_bottom_nav_test.dart` |
| Strict-mode lints (`strict-casts`, `strict-inference`, no `dynamic`) | ✅ Types are all concrete; compile-time-known indices |
| MEMORY.md — `package:flutter/foundation.dart` trap | ✅ Only `material.dart` imported |
| MEMORY.md — verified Lucide icon names (`house`, `pill`, `activity`) | ✅ All three are on the verified list |
| MEMORY.md — `const` constructors for fixed icons | ✅ Every `Icon(LucideIcons.xxx)` instance is `const` |

## Implementation Approach

### Layer Map

| Layer | What | Files (existing or new) |
|-------|------|------------------------|
| Domain | Nothing | — |
| Data | Nothing | — |
| Presentation | 1 new widget + modify 1 existing screen + 1 new widget test | `lib/features/home/presentation/widgets/home_bottom_nav.dart` (**new**), `lib/features/home/presentation/screens/home_screen.dart` (**modify**), `test/features/home/presentation/widgets/home_bottom_nav_test.dart` (**new**) |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| Widget primitive | Flutter `NavigationBar` + 3 `NavigationDestination` | M3 pill-indicator is already encoded in the widget; pulls `surfaceContainer`/`secondaryContainer`/`onSurface` from `ColorScheme` automatically → light/dark for free | Custom `Row`-based widget (too much drift surface, no ColorScheme wiring for free); `BottomNavigationBar` (M2, wrong visual) |
| Statefulness | `StatelessWidget` with `selectedIndex: 0`, no-op lambda | "Buttons that do nothing" per spec §3 + AC-5. Pure function of theme → zero state bugs possible. Easy to refactor to stateful in a future spec. | `StatefulWidget` with `_selectedIndex` local state (violates AC-4 which fixes index at 0); Riverpod provider (over-engineered; no state to expose) |
| `onDestinationSelected` value | Const empty lambda `(_) {}` | Keeps destinations tappable → ripple fires → matches HTML `cursor: pointer` UX. AC-5 explicitly permits ripple. | `null` (disables ripple, destinations feel dead); navigate-to-placeholder (violates §6 Out of Scope: "no navigation wiring") |
| Label behavior | `NavigationDestinationLabelBehavior.alwaysShow` | Spec AC-7 + HTML shows all labels permanently. Defaults differ by platform — must be explicit. | `onlyShowSelected` (hides Meds/History labels, contradicts HTML); platform default (non-deterministic) |
| Icon selection | `LucideIcons.house` / `pill` / `activity`, all wrapped in `const Icon(...)` | Names verified in MEMORY.md (Feature 004). SVG paths in HTML lines 1818/1822/1826 match these Lucide glyphs. `const` Icon is a free perf win per MEMORY.md Performance Notes. | Material `Icons.*` (violates Feature 004 decision); custom SVG via `flutter_svg` (no such dep, over-engineered) |
| Theme wiring | Rely on ambient `Theme.of(context).colorScheme` via `NavigationBar`'s internal `IndicatorColor` / `NavigationBarTheme` defaults | Zero hard-coded colors; zero `NavigationBarThemeData` additions needed because M3 `ColorScheme` defaults already map to the HTML's intent (`surfaceContainer` bg, `secondaryContainer` pill, `onSecondaryContainer` selected icon, `onSurfaceVariant` unselected) | Extending `AppTheme.lightTheme`/`darkTheme` with a custom `NavigationBarThemeData` (unnecessary — defaults already match) |
| Widget placement | Slot directly into `HomeScreen.Scaffold.bottomNavigationBar` | Spec §6 explicitly defers `ShellRoute` lift; single insertion point, minimum diff | `StatefulShellRoute` in `app_router.dart` (spec-out-of-scope); wrap at `DoslyApp` level (breaks separation — home-specific widget in app shell) |
| Test strategy | One new widget test file exercising the widget in isolation; leave `test/widget_test.dart` untouched | Existing `widget_test.dart` tests the full `DoslyApp` pump — it will implicitly get the `NavigationBar` in its tree without any assertion changes (the test targets body content + app bar, not `bottomNavigationBar`). A dedicated `home_bottom_nav_test.dart` covers AC-2 through AC-7 without coupling to `DoslyApp` bootstrap. | Extend `widget_test.dart` (bloats the bootstrap smoke test); end-to-end test via `DoslyApp` only (too much setup for a stateless-widget unit) |

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `lib/features/home/presentation/widgets/home_bottom_nav.dart` | **Create** | New `StatelessWidget` `HomeBottomNav` wrapping `NavigationBar` with 3 `const NavigationDestination`s. Const-constructable. `///` dartdoc on class + constructor explaining the fixed-index / no-op-callback contract and the "future spec will convert to stateful when routes exist" note. |
| `lib/features/home/presentation/screens/home_screen.dart` | **Modify** | Add `bottomNavigationBar: const HomeBottomNav()` to the existing `Scaffold`. Add import `'../widgets/home_bottom_nav.dart'`. No body changes, no AppBar changes, no new state. |
| `test/features/home/presentation/widgets/home_bottom_nav_test.dart` | **Create** | `testWidgets` cases pumping `HomeBottomNav` inside a minimal `MaterialApp(home: Scaffold(bottomNavigationBar: ...))` harness. Tests: (a) renders exactly 3 destinations; (b) labels are "Today", "Meds", "History" in order; (c) icons resolve to Lucide `house`/`pill`/`activity`; (d) `selectedIndex == 0`; (e) tapping "Meds" and "History" leaves `selectedIndex == 0` after `pumpAndSettle`; (f) `labelBehavior == NavigationDestinationLabelBehavior.alwaysShow`. |

### Documentation Impact

| Doc File | Action | What Changes |
|----------|--------|-------------|
| `docs/features/home.md` (if exists) | Update | Note: HomeScreen now renders a 3-destination `NavigationBar` with no-op callbacks; mention the "multi-lang + navigation wiring" follow-up. Scope: 2–3 sentences. |
| `docs/architecture.md` | **No change** | No new architectural pattern. Clean Architecture boundaries are unaffected. |

(Tech-writer agent will discover `docs/features/home.md` state during `/execute-task` Phase 6. If the file does not yet exist, the tech-writer will either create it or note the gap in the task's memory update — not in scope for this plan to pre-create.)

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `NavigationBar` default look diverges from HTML `.bot-nav` on some metric (height, label size) | Medium | Low | Spec §6 accepts "M3 intent match" not pixel parity. Separate spec if user rejects visual after on-device check (AC-13 is user-run, not sandbox-run). |
| Existing `test/widget_test.dart` asserts fail because adding a `NavigationBar` shifts body layout | Low | Low | Existing test asserts by `find.text(...)` / `find.widgetWithText(OutlinedButton, ...)` — these finders don't care about viewport geometry. Verified by reading `test/widget_test.dart:14-59`. If a tap location fails, wrap with `tester.ensureVisible` before tap. |
| Tapping an inactive destination changes `selectedIndex` via some internal `NavigationBar` behavior I missed | Low | Medium | `NavigationBar` only changes state when `onDestinationSelected` mutates a parent-held index. With a no-op lambda, nothing reads back. Test (e) explicitly asserts this. |
| Adding `const HomeBottomNav()` breaks because the widget is not actually const-constructable | Low | Low | Keep constructor `const HomeBottomNav({super.key});`. The 3 `NavigationDestination` children are `const` because labels are string literals, icons are `const Icon(LucideIcons.xxx)`, and the empty lambda is a compile-time constant when written as `onDestinationSelected: _onTap` with a top-level `void _onTap(int _) {}` or as a field default. If `const` fails, fall back to a non-const widget — no AC impact. |
| AC-12 (no new Flutter import in domain/) — trivial but easy to forget | Low | Low | Nothing in this plan touches `domain/` at all. `dart analyze` will also not flag anything. |

## Dependencies

**None.**
- `flutter/material.dart` — already the standard import everywhere in `presentation/`.
- `lucide_icons_flutter: ^3.1.12` — already in `pubspec.yaml` (Feature 004).
- `flutter_test` — already a dev dependency.

No `flutter pub add` calls. No new assets. No platform channel / manifest / Info.plist changes.

## Supporting Documents

- No `research.md` — no external libraries, no architectural choices with multiple valid paths, no new patterns. Signal scan (Phase 0.2) returned zero signals.
- No `data-model.md` — no entities.
- No `contracts.md` — no API surface.

## Plan ↔ Spec Cross-Reference

| Spec AC | Where the plan covers it |
|---------|--------------------------|
| AC-1 Scaffold slot | File Impact row "home_screen.dart" — add `bottomNavigationBar: const HomeBottomNav()` |
| AC-2 Three destinations, Today/Meds/History order | File Impact row "home_bottom_nav.dart" + test case (a)+(b) |
| AC-3 Lucide icons | Design decision "Icon selection" + test case (c) |
| AC-4 `selectedIndex == 0` on first render | Design decision "Statefulness" + test case (d) |
| AC-5 Tap is a no-op | Design decision "`onDestinationSelected` value" + test case (e) |
| AC-6 Light/dark via ColorScheme | Design decision "Theme wiring" — M3 defaults already pull from `ColorScheme`; no code needed beyond not hard-coding colors |
| AC-7 `alwaysShow` labels | Design decision "Label behavior" + test case (f) |
| AC-8 Widget test exists | File Impact row "home_bottom_nav_test.dart" |
| AC-9 `dart analyze` clean | Post-execution hook (CLAUDE.md) runs `dart analyze` on every edit |
| AC-10 `flutter test` passes | Integration gate at task completion (per Feature 002 pattern) |
| AC-11 `flutter build apk --debug` succeeds | Integration gate at task completion |
| AC-12 No domain/data files touched | File Impact table lists only 3 files, all under `presentation/` — enforced by plan scope |

All 12 ACs have a clear implementation path.

**Reverse check**: the only file in the plan's File Impact that is not 1:1 in the spec's "Affected Areas" is `test/features/home/presentation/widgets/home_bottom_nav_test.dart`, which IS listed in spec §4 ("Widget tests"). No drift.
