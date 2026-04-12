# Spec: Home Screen App Bar

**Date**: 2026-04-12
**Status**: Complete
**Author**: Claude + mykolakudlyk

## 1. Overview

Add a top app bar to the home screen that visually matches the `app-bar` design in `dosly_m3_template.html`. The bar displays the app title "Dosly" left-aligned with a settings gear icon on the right (non-functional placeholder). The bar uses `surfaceContainer` background, a 1px `outlineVariant` bottom border, and gains a shadow on scroll. The global `AppBarTheme` is updated to align with the HTML template's design system so all future screens inherit the correct defaults.

## 2. Current State

**Home screen** (`lib/features/home/presentation/screens/home_screen.dart`, 46 lines): a placeholder `StatelessWidget` returning a bare `Scaffold` with no `AppBar`. Body is a centered `Column` with "Hello World" text and a temporary "Theme preview" `OutlinedButton` that pushes `/theme-preview` via `context.push`. Spec 002 explicitly noted "No `AppBar`, no `FloatingActionButton`" in AC-6.

**Global AppBarTheme** (`lib/core/theme/app_theme.dart:34-43`): currently configured as:
- `backgroundColor: scheme.surface` — the HTML template uses `surfaceContainer` for all app bars
- `foregroundColor: scheme.onSurface` — matches HTML's `--md-on-surface` for title color
- `elevation: 0` — correct for at-rest state
- `scrolledUnderElevation: 3` — provides shadow on scroll (matches HTML's `box-shadow` on `.scrolled`)
- `centerTitle: false` — correct, HTML title is left-aligned
- `titleTextStyle: titleLarge` (Roboto 500 22px/28px) — matches HTML's `.ab-title` (`font: 500 22px/28px 'Roboto'`)

**Color tokens** (`lib/core/theme/app_color_schemes.dart`):
- `surfaceContainer`: light `Color(0xFFEAF0E7)` / dark `Color(0xFF1D211C)` — matches HTML `--md-surface-container: #EAF0E7` / `#1D211C`
- `outlineVariant`: light `Color(0xFFC0C9BB)` / dark `Color(0xFF404942)` — needed for the bottom border

**HTML template reference** (`dosly_m3_template.html` lines 254-283):
- `.app-bar`: height 64px, flex row, `align-items: center`, `padding: 0 4px`, `background: var(--md-surface-container)`, `border-bottom: 1px solid var(--md-outline-variant)`
- `.app-bar.scrolled`: same background, adds `box-shadow: var(--md-shadow-1)`
- `.ab-title`: `font: 500 22px/28px 'Roboto'`, `color: var(--md-on-surface)`, `padding: 0 8px`, `flex: 1`, `letter-spacing: -.1px`
- `.icon-btn`: 48x48, circular, flex-centered, `color: var(--md-on-surface-variant)`
- Home screen instance (line 1631-1634): title "Dosly", single settings gear icon button on the right

**Routing** (`lib/core/routing/app_router.dart`): flat table with `/` (HomeScreen) and `/theme-preview` (ThemePreviewScreen). No settings route exists.

**Existing tests** (`test/widget_test.dart`): two tests — one asserts "Hello World" text and "Theme preview" button; another tests navigation to theme preview and theme cycling. Neither references an AppBar.

## 3. Desired Behavior

After this spec is implemented, the home screen displays a top app bar with:

1. **Title "Dosly"** left-aligned, using the theme's `titleLarge` text style (Roboto Medium 22px/28px, `onSurface` color). This matches the HTML `.ab-title` styling.

2. **Settings gear icon** on the right as a 48x48 `IconButton` with `onSurfaceVariant` color. The icon is a standard Material settings/gear icon matching the HTML's SVG. The button is a **non-functional placeholder** (`onPressed: null` or equivalent) — it does not navigate anywhere. When a settings screen is built in a future spec, this button will be wired up.

3. **Background**: `surfaceContainer` from the color scheme (not `surface`). This matches the HTML template's `--md-surface-container` used across all app bars.

4. **Bottom border**: A 1px line in `outlineVariant` color along the bottom edge of the app bar. This is a custom visual detail from the HTML template not covered by default Material AppBar.

5. **Scroll behavior**: When content below scrolls, the app bar gains elevation (shadow). Flutter's built-in `scrolledUnderElevation` on `AppBar` handles this. To prevent the tonal elevation overlay from changing the background color on scroll, `surfaceTintColor` is set to `Colors.transparent` — this way only a shadow appears (matching the HTML where background stays `surfaceContainer` and only `box-shadow` is added).

6. **Existing body content preserved**: The "Hello World" text and "Theme preview" button remain centered in the body. Their layout does not change.

7. The **global `AppBarTheme`** in `app_theme.dart` is updated so `backgroundColor` uses `surfaceContainer` instead of `surface`. This aligns the design system with the HTML template where every screen's app-bar uses `surfaceContainer`. The `surfaceTintColor: Colors.transparent` is also set globally to prevent scroll-elevation from tinting the background.

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Global theme | `lib/core/theme/app_theme.dart:34-43` | Edit `AppBarTheme` — change `backgroundColor` from `scheme.surface` to `scheme.surfaceContainer`, add `surfaceTintColor: Colors.transparent` |
| Home screen | `lib/features/home/presentation/screens/home_screen.dart` | Edit — add `AppBar` to `Scaffold` with title "Dosly", settings icon action, and bottom border decoration |
| Widget tests | `test/widget_test.dart` | Edit — update assertions to account for AppBar presence (title text, icon button) |
| Color schemes | `lib/core/theme/app_color_schemes.dart` | Unchanged (tokens already defined) |
| Text theme | `lib/core/theme/app_text_theme.dart` | Unchanged (`titleLarge` already defined correctly) |
| Routing | `lib/core/routing/app_router.dart` | Unchanged (no new routes) |
| App root | `lib/app.dart`, `lib/main.dart` | Unchanged |

## 5. Acceptance Criteria

Each criterion must be testable and unambiguous:

- [x] **AC-1**: `HomeScreen`'s `Scaffold` has an `appBar` property set to a Flutter `AppBar` widget. The `AppBar` has `title` set to a `Text` widget displaying the string `'Dosly'` (exact casing, no punctuation).
- [x] **AC-2**: The `AppBar` has a single `actions` entry: an `IconButton` with the Material settings/gear icon (`Icons.settings`), sized and colored via theme defaults (`onSurfaceVariant`). The `IconButton`'s `onPressed` is `null` (disabled/non-functional placeholder).
- [x] **AC-3**: The `AppBar` has a visible bottom border — a 1px line in the theme's `outlineVariant` color. Implementation uses `AppBar.shape` with a bottom `BorderSide`, or `AppBar.bottom` with a `PreferredSize` containing a `Divider`, or an equivalent technique that renders a 1px line at the bottom edge.
- [x] **AC-4**: The global `AppBarTheme` in `app_theme.dart` sets `backgroundColor` to `scheme.surfaceContainer` (was `scheme.surface`). This matches the HTML template's `--md-surface-container` for all app bars.
- [x] **AC-5**: The global `AppBarTheme` in `app_theme.dart` sets `surfaceTintColor` to `Colors.transparent`. This prevents the scroll-elevation tonal overlay from changing the background color, matching the HTML behavior where only a shadow is added on scroll.
- [x] **AC-6**: The existing body content — centered `Column` with "Hello World" `Text`, `SizedBox(height: 24)`, and "Theme preview" `OutlinedButton` — is unchanged.
- [x] **AC-7**: The "Theme preview" `OutlinedButton` still navigates to `/theme-preview` via `context.push`. Navigation and back-button behavior are unaffected.
- [x] **AC-8**: `dart analyze` reports zero errors, warnings, and info-level diagnostics across the entire project.
- [x] **AC-9**: `flutter test` passes — all existing tests plus any updates needed to accommodate the new AppBar.
- [x] **AC-10**: `flutter build apk --debug` completes successfully.
- [x] **AC-11**: No `print()`, `debugPrint()`, `!` null assertion, or `dynamic` usage in any file created or edited by this spec. No `package:flutter/*` imports leak into any `domain/` folder.
- [x] **AC-12**: All new and edited code has dartdoc (`///`) comments on public members where required by the constitution.
- [x] **AC-13**: No new dependencies added to `pubspec.yaml`. The implementation uses only existing Flutter widgets and theme tokens.

## 6. Out of Scope

- NOT included: Settings screen, settings route, or any navigation from the settings icon. The icon is a visual placeholder only.
- NOT included: Search functionality or any other app-bar actions beyond the single settings icon.
- NOT included: Scroll-based app-bar collapsing, `SliverAppBar`, or `FlexibleSpaceBar`. The app bar has a fixed height.
- NOT included: Custom transitions or animations beyond Flutter's built-in scroll-elevation behavior.
- NOT included: Changes to other screens' app bars (theme preview, future screens). They inherit the updated `AppBarTheme` automatically.
- NOT included: Localization of the "Dosly" title string. Hardcoded for now.
- NOT included: Adding new color tokens or modifying `app_color_schemes.dart`. All needed tokens already exist.
- NOT included: Changes to `lib/core/routing/app_router.dart` or any route additions.
- NOT included: Changes to `lib/main.dart`, `lib/app.dart`, or the theme preview feature.
- NOT included: New test files. Only the existing `test/widget_test.dart` is updated if needed to accommodate the AppBar.

## 7. Technical Constraints

- Must follow: Clean Architecture — edits stay within `presentation/` (home screen) and `core/theme/` (global theme). No domain or data layer involvement.
- Must follow: Existing state management pattern (`ValueNotifier` + `ListenableBuilder`). No Riverpod introduction.
- Must follow: Constitution strict-mode rules — no `!`, no `dynamic`, `const` where possible.
- Must follow: Constitution dartdoc rule — new public widgets/parameters get `///` comments.
- Must not break: Theme cycling behavior. The `themeController` and `ListenableBuilder` in `app.dart` are untouched.
- Must not break: Navigation to `/theme-preview` via the existing `OutlinedButton`.
- Must not break: Existing tests in `test/core/theme/` (color scheme and theme controller tests).
- Must use: Theme tokens from `app_color_schemes.dart` (`surfaceContainer`, `outlineVariant`, `onSurface`, `onSurfaceVariant`) — no hardcoded color values.
- Must use: `titleLarge` from `AppTextTheme` for the app bar title (already wired via `AppBarTheme.titleTextStyle`).

## 8. Open Questions

1. **Bottom border technique**: Flutter's `AppBar` doesn't have a built-in "bottom border" property. Options include (a) `AppBar.bottom` with a zero-height `PreferredSize` + `Divider`, (b) wrapping in a `DecoratedBox` or `Container` with a `BoxDecoration` bottom border, (c) using `AppBar.shape` with `Border(bottom: BorderSide(...))`. `/plan` should evaluate which approach is cleanest and most maintainable. The spec only requires the visual result: a 1px `outlineVariant` line at the bottom edge.

2. **Settings icon tooltip**: Should the disabled settings icon have a tooltip (e.g., `'Settings'` or `'Налаштування'`)? Default: include a tooltip `'Settings'` for accessibility even though the button is non-functional. `/plan` can decide.

3. **`surfaceTintColor: Colors.transparent` side effect**: Setting this globally means no M3 tonal elevation overlay on any app bar across the app. This matches the HTML template (which uses flat `surfaceContainer` everywhere), but deviates from stock M3. Flagged here for awareness — the template's design is intentional.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Bottom border implementation doesn't render pixel-perfectly across iOS/Android | Low | Low | Multiple viable techniques exist; `/plan` picks the most portable one. AC-3 only requires a visible 1px line. |
| `surfaceTintColor: Colors.transparent` affects theme preview screen's AppBar | Low | Low | Theme preview uses its own AppBar title and actions; the visual change (no tint on scroll) is an improvement matching the design system. |
| Disabled `IconButton` (`onPressed: null`) renders with reduced opacity on some platforms | Low | Low | If opacity is visually undesirable, `/plan` can use an enabled button with empty callback instead. Spec requires the icon to be present and non-functional — implementation details are flexible. |
| Existing widget tests fail due to new AppBar changing the widget tree | Med | Low | AC-9 requires tests to pass. Test updates are scoped in the Affected Areas table. The current tests find "Hello World" text and the OutlinedButton — these should still be findable with an AppBar present. |
| Global `AppBarTheme` change to `surfaceContainer` affects theme preview screen background color | Low | Low | Theme preview's AppBar will shift from `surface` to `surfaceContainer` — a subtle and correct change matching the design system. |
