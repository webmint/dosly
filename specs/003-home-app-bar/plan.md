# Plan: Home Screen App Bar

**Date**: 2026-04-12
**Spec**: specs/003-home-app-bar/spec.md
**Status**: Approved

## Summary

Add a Material 3 `AppBar` to the home screen's `Scaffold` matching the HTML template's `.app-bar` design — "Dosly" title, disabled settings icon, `surfaceContainer` background, `outlineVariant` bottom border. Update the global `AppBarTheme` so `backgroundColor` and `surfaceTintColor` align with the HTML design system for all current and future screens.

## Technical Context

**Architecture**: Presentation layer only (`lib/features/home/presentation/`) + shared theme (`lib/core/theme/`)
**Error Handling**: N/A — no fallible operations
**State Management**: N/A — the AppBar is stateless; scroll-shadow is handled by Flutter's built-in `Scrollable` notification

## Constitution Compliance

- §2.1 Layer Boundaries: compliant — edits are in `presentation/` and `core/theme/` only
- §3.1 Type Safety: compliant — no `dynamic`, no `!`, no `as` casts
- §3.3 Naming: compliant — no new types or files
- §3.5 No dead code: compliant — settings icon is rendered in the UI (not dead)
- §3 "Document new code": compliant — updated `HomeScreen` dartdoc will describe the AppBar and its settings icon placeholder

## Implementation Approach

### Layer Map

| Layer | What | Files |
|-------|------|-------|
| Core/Theme | Update global `AppBarTheme` defaults | `lib/core/theme/app_theme.dart` (modify) |
| Presentation | Add `AppBar` to `HomeScreen` scaffold | `lib/features/home/presentation/screens/home_screen.dart` (modify) |
| Test | Verify existing tests still pass, add AppBar title assertion | `test/widget_test.dart` (modify) |

### Key Design Decisions

| Decision | Chosen Approach | Why | Alternatives Rejected |
|----------|----------------|-----|----------------------|
| Bottom border technique | `AppBar.bottom` with `PreferredSize(preferredSize: Size.fromHeight(1))` containing a `Divider()` | Idiomatic Flutter; `DividerThemeData` in `app_theme.dart` already configures `color: outlineVariant`, `space: 1`, `thickness: 1` — so a bare `Divider()` renders the correct style. Explicit, readable, easy to find in code. | `AppBar.shape: Border(bottom: BorderSide(...))` — technically works since `Border` extends `ShapeBorder`, but unconventional for `AppBar.shape` which is typically used for overall outline/clipping. Harder to discover during maintenance. |
| Scroll-shadow without tint | Set `surfaceTintColor: Colors.transparent` in global `AppBarTheme` | HTML template keeps `surfaceContainer` background constant on scroll, adding only `box-shadow`. Flutter's `scrolledUnderElevation` applies both shadow AND tonal overlay by default — `surfaceTintColor: transparent` disables only the tint, preserving the shadow. Global because all HTML template app bars share this behavior. | Per-screen override — would require every future screen to repeat `surfaceTintColor: transparent`. |
| Settings icon state | `IconButton(onPressed: null, tooltip: 'Settings', icon: Icon(Icons.settings))` | `onPressed: null` is the standard Flutter pattern for a disabled button. Flutter renders it with reduced opacity, which is an acceptable visual signal that the button is non-functional. The `tooltip` remains for accessibility. When a settings screen lands, only `onPressed` needs updating. | `onPressed: () {}` (empty callback) — keeps full opacity but misleads the user (tappable but does nothing). Worse UX. |
| AppBar title | `AppBar(title: Text('Dosly'))` relying on `AppBarTheme.titleTextStyle` | The global `AppBarTheme` already sets `titleTextStyle: titleLarge` (Roboto 500 22/28, `onSurface`), and `centerTitle: false`. This exactly matches the HTML `.ab-title`. No per-screen style overrides needed. | Explicit `style:` on the `Text` widget — redundant; would fight the theme system. |
| toolbarHeight | Keep Flutter default (56dp), do NOT set to 64 | The spec focuses on visual elements (title, icon, border, color), not pixel-exact height. Flutter's M3 default of 56dp is the framework's interpretation of M3 guidelines. Forcing 64dp would be a global change not requested in the spec and could affect the theme preview screen's AppBar. | `toolbarHeight: 64` globally — matches the HTML's `--appbar-h: 64px` but changes behavior for all screens; should be a separate spec decision if desired. |
| Test updates | Add `find.text('Dosly')` assertion to the first test; no other test changes | Existing assertions (`find.text('Hello World')`, `find.widgetWithText(OutlinedButton, 'Theme preview')`) remain valid with an AppBar present — `Text('Hello World')` is in the body, not the AppBar. Adding the title assertion verifies AC-1. Navigation test (test 2) is unaffected. | Adding a dedicated AppBar test file — overkill for 2 lines of assertions on an existing test. |

### File Impact

| File | Action | What Changes |
|------|--------|-------------|
| `lib/core/theme/app_theme.dart` | Modify | `AppBarTheme`: change `backgroundColor: scheme.surface` → `scheme.surfaceContainer`; add `surfaceTintColor: Colors.transparent` |
| `lib/features/home/presentation/screens/home_screen.dart` | Modify | Add `appBar:` to `Scaffold` with `AppBar(title: Text('Dosly'), actions: [IconButton(...)], bottom: PreferredSize(..., child: Divider()))`; update class dartdoc to describe the AppBar |
| `test/widget_test.dart` | Modify | First test: add `expect(find.text('Dosly'), findsOneWidget)` assertion |

### Documentation Impact

No documentation changes expected — internal presentation-layer implementation only. The feature is too thin to warrant a `docs/features/` entry. When a full home screen feature ships (with real content), that spec will document the screen holistically.

## Plan-Spec Cross-Reference

| AC | Covered by |
|----|-----------|
| AC-1 (AppBar with title "Dosly") | `home_screen.dart` modification — `AppBar(title: Text('Dosly'))` |
| AC-2 (Settings IconButton, onPressed: null) | `home_screen.dart` — `actions: [IconButton(onPressed: null, ...)]` |
| AC-3 (Bottom border, 1px outlineVariant) | `home_screen.dart` — `AppBar.bottom: PreferredSize + Divider()` |
| AC-4 (AppBarTheme backgroundColor → surfaceContainer) | `app_theme.dart` — `backgroundColor: scheme.surfaceContainer` |
| AC-5 (AppBarTheme surfaceTintColor transparent) | `app_theme.dart` — `surfaceTintColor: Colors.transparent` |
| AC-6 (Body content unchanged) | No changes to Column/Text/SizedBox/OutlinedButton in home_screen.dart body |
| AC-7 (Navigation still works) | No routing changes; `context.push('/theme-preview')` untouched |
| AC-8 (dart analyze clean) | Post-execution gate |
| AC-9 (flutter test passes) | Test update + post-execution gate |
| AC-10 (flutter build apk) | Post-execution gate |
| AC-11 (No debug artifacts) | Code review gate |
| AC-12 (Dartdoc on public members) | Updated `HomeScreen` class dartdoc |
| AC-13 (No new dependencies) | No pubspec.yaml changes |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `Divider()` in `AppBar.bottom` doesn't respect `DividerThemeData` | Low | Low | If needed, pass explicit `color:` and `height:` to the `Divider`. The global `DividerThemeData` is already configured correctly. |
| Disabled `IconButton` opacity looks wrong in dark mode | Low | Low | Acceptable for a placeholder. When the settings screen ships, the icon becomes enabled. |
| Theme preview screen's AppBar shifts from `surface` to `surfaceContainer` background | Certain | Low | This is intentional — aligns the preview with the design system. The color difference is subtle (light: `#FFFBFE` → `#EAF0E7`). |

## Dependencies

None. No new packages, no external services, no environment changes.
