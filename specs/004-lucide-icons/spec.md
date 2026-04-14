# Spec: Lucide Icons

**Date**: 2026-04-12
**Status**: Complete
**Author**: Claude + Mykola

## 1. Overview

Replace all Material Design icons in the Flutter app with Lucide icons from the `lucide_icons` package to match the icon set used in the HTML design template (`dosly_m3_template.html`). This ensures visual consistency between the design reference and the running app. The theme preview page should showcase all Lucide icons the app uses, and the home screen app bar gear icon should use the Lucide equivalent.

## 2. Current State

The app currently uses Flutter's built-in `Icons.*` (Material Design icons) in two screens:

**Home screen** (`lib/features/home/presentation/screens/home_screen.dart`):
- Line 38: `Icons.settings` — disabled gear icon in the app bar

**Theme preview screen** (`lib/features/theme_preview/presentation/screens/theme_preview_screen.dart`):
- Lines 21-23: `Icons.brightness_auto_rounded`, `Icons.light_mode_rounded`, `Icons.dark_mode_rounded` — theme mode cycling button in app bar
- Line 47: `Icons.add_rounded` — demo FAB
- Line 141: `Icons.medication_rounded` — chip avatar
- Line 143: `Icons.schedule_rounded` — standalone icon demo
- Line 169: `Icons.medication_rounded` — text field prefix icon

The HTML template (`dosly_m3_template.html`) uses Lucide-style SVG icons throughout. These are identifiable as Lucide icons by their SVG path data. The following unique icons were catalogued from the HTML:

| Lucide icon | HTML context |
|------------|-------------|
| `pill` | Medication items, nav bar "Ліки", app logo |
| `house` | "Сьогодні" nav tab |
| `settings` | "Налаштування" button |
| `history` | "Історія" tab |
| `circle-plus` | "Додати" button |
| `thermometer` | Medication type icon |
| `syringe` | Medication type icon |
| `glasses` | Medication type icon |
| `droplets` | Medication type icon |
| `activity` | Nav bar health tab |
| `clock` | Time chips |
| `check` | Intake confirmation |
| `chevron-down` | Time slot expander |
| `chevron-right` | List item trailing |
| `arrow-left` | Back navigation |
| `search` | Search bar |
| `plus` | FAB add button |
| `eye` | Password/visibility toggle |
| `x` | Close/clear |
| `phone` | Contact info |

No icon packages beyond `cupertino_icons` are currently in `pubspec.yaml`. The project uses `uses-material-design: true` for the Material Icons font.

## 3. Desired Behavior

### 3.1 Add `lucide_icons` dependency

Add the `lucide_icons` package to `pubspec.yaml` under `dependencies`.

### 3.2 Replace home screen app bar icon

Replace `Icons.settings` with `LucideIcons.settings` in the home screen app bar `IconButton`.

### 3.3 Replace theme preview screen icons

Replace all Material Design icons on the theme preview screen with their Lucide equivalents:

| Current Material icon | Lucide replacement | Location |
|----------------------|-------------------|----------|
| `Icons.brightness_auto_rounded` | `LucideIcons.sunMoon` | Theme mode button (system) |
| `Icons.light_mode_rounded` | `LucideIcons.sun` | Theme mode button (light) |
| `Icons.dark_mode_rounded` | `LucideIcons.moon` | Theme mode button (dark) |
| `Icons.add_rounded` | `LucideIcons.plus` | Demo FAB |
| `Icons.medication_rounded` | `LucideIcons.pill` | Chip avatar, text field prefix |
| `Icons.schedule_rounded` | `LucideIcons.clock` | Standalone icon demo |

### 3.4 Add icon showcase section to theme preview

Add a new "Icons" section to the theme preview screen (between the existing "Typography" and "Components" sections) that displays the key Lucide icons used across the app design. Each icon should be shown with its name label below it, laid out in a `Wrap` widget consistent with the existing color swatches section. This serves as a visual reference to verify icon rendering matches the HTML template.

Icons to showcase (the full set from the HTML template):
`pill`, `house`, `settings`, `history`, `circlePlus`, `thermometer`, `syringe`, `glasses`, `droplets`, `activity`, `clock`, `check`, `chevronDown`, `chevronRight`, `arrowLeft`, `search`, `plus`, `eye`, `x`, `phone`

## 4. Affected Areas

| Area | Files | Impact |
|------|-------|--------|
| Dependencies | `pubspec.yaml` | Add `lucide_icons` package |
| Home screen | `lib/features/home/presentation/screens/home_screen.dart` | Replace `Icons.settings` → `LucideIcons.settings` |
| Theme preview | `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` | Replace 6 Material icons with Lucide equivalents; add icon showcase section |
| Widget tests | `test/widget_test.dart` | May need update if tests assert on specific icon types (currently none do) |

## 5. Acceptance Criteria

Each criterion must be testable and unambiguous:

- [x] **AC-1**: `lucide_icons` is listed as a dependency in `pubspec.yaml` and `flutter pub get` resolves successfully
- [x] **AC-2**: `Icons.settings` on the home screen app bar is replaced with `LucideIcons.settings`
- [x] **AC-3**: All 6 Material Design icon references in `theme_preview_screen.dart` are replaced with their Lucide equivalents per the mapping table in §3.3
- [x] **AC-4**: The theme preview screen contains an "Icons" section that displays all 20 Lucide icons listed in §3.4, each with a text label showing the icon name
- [x] **AC-5**: The icon showcase section uses a `Wrap` layout consistent with the existing color swatches section styling
- [x] **AC-6**: No `Icons.*` references remain in `home_screen.dart` or `theme_preview_screen.dart` (all replaced with `LucideIcons.*`)
- [x] **AC-7**: `dart analyze` passes cleanly on all changed files
- [x] **AC-8**: `flutter test` passes (all existing tests remain green)
- [x] **AC-9**: `flutter build apk --debug` succeeds

## 6. Out of Scope

- NOT included: Removing `cupertino_icons` from `pubspec.yaml` (may be needed elsewhere later)
- NOT included: Removing `uses-material-design: true` (Material theme infrastructure still needed)
- NOT included: Creating reusable icon wrapper widgets or an icon registry — this is a straightforward icon swap
- NOT included: Changing icon colors, sizes, or styling beyond what's needed for direct replacement
- NOT included: Adding icons to screens/features that don't exist yet (nav bar, medication list, etc.)
- NOT included: Matching the exact stroke-width/style of the HTML SVG icons — the `lucide_icons` package provides its own standard rendering

## 7. Technical Constraints

- Must follow Clean Architecture layer boundaries (icons are presentation-layer only — no icon imports in `domain/`)
- Must not break existing widget tests
- `lucide_icons` package uses `IconData` just like `Icons.*`, so the swap is mechanical — no widget restructuring needed
- The icon showcase section should be a simple inline widget in the existing `_PreviewBody`, not a separate feature module (theme preview is temporary dev scaffolding)

## 8. Open Questions

- The exact `LucideIcons.*` Dart field names need to be verified against the `lucide_icons` package API during implementation (e.g., `circlePlus` vs `circlePlus` vs `plusCircle`). The Lucide icon names in §3.4 are best-effort based on the lucide.dev naming convention.

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `lucide_icons` field names differ from expected | Medium | Low | Verify against package source during implementation; Dart analyzer will catch mismatches |
| Lucide icons look visually different from Material icons (thinner strokes) | Low | Low | Intentional — matching the HTML template is the goal |
| Package version incompatibility with Flutter SDK ^3.11.1 | Low | Medium | Check pub.dev compatibility before adding; fall back to a pinned version |
