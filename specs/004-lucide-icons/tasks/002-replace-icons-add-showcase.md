### Task 002: Replace Material icons with Lucide equivalents and add icon showcase

**Agent**: mobile-engineer
**Files**: `lib/features/home/presentation/screens/home_screen.dart`, `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart`
**Depends on**: 001
**Blocks**: None
**Context docs**: None
**Review checkpoint**: Yes

**Description**:
Replace every `Icons.*` reference in the home screen and theme preview screen with `LucideIcons.*` equivalents. Then add an "Icons" showcase section to the theme preview screen that displays all 20 Lucide icons used in the HTML design template, each with a name label.

**Change details**:

- In `lib/features/home/presentation/screens/home_screen.dart`:
  - Add import: `import 'package:lucide_icons_flutter/lucide_icons.dart';`
  - Replace `Icons.settings` (line 38) → `LucideIcons.settings`
  - Remove `import 'package:flutter/material.dart';` only if no longer needed (it IS still needed for `StatelessWidget`, `Scaffold`, etc. — keep it)

- In `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart`:
  - Add import: `import 'package:lucide_icons_flutter/lucide_icons.dart';`
  - Replace `_iconForMode` method (lines 19-25):
    - `Icons.brightness_auto_rounded` → `LucideIcons.sunMoon`
    - `Icons.light_mode_rounded` → `LucideIcons.sun`
    - `Icons.dark_mode_rounded` → `LucideIcons.moon`
  - Replace in `_PreviewBody.build`:
    - `Icons.add_rounded` (line 47) → `LucideIcons.plus`
    - `Icons.medication_rounded` (line 141, chip avatar) → `LucideIcons.pill`
    - `Icons.schedule_rounded` (line 143, standalone icon) → `LucideIcons.clock`
    - `Icons.medication_rounded` (line 169, text field prefix) → `LucideIcons.pill`
  - Add icon showcase section in `_PreviewBody.build` between the Typography section and the Components section (between the last `TypographySample` widget and `const _SectionHeader(label: 'Components')`):
    - Add `const _SectionHeader(label: 'Icons')` header
    - Add a `Wrap` widget (spacing: 8, runSpacing: 8) containing 20 icon showcase items
    - Each item: a `SizedBox(width: 80)` containing a `Column` with the `Icon` (size 32) and a `Text` label (icon name, bodySmall style, centered)
    - The 20 icons to showcase (with their display labels):
      1. `LucideIcons.pill` — "pill"
      2. `LucideIcons.house` — "house"
      3. `LucideIcons.settings` — "settings"
      4. `LucideIcons.history` — "history"
      5. `LucideIcons.circlePlus` — "circlePlus"
      6. `LucideIcons.thermometer` — "thermometer"
      7. `LucideIcons.syringe` — "syringe"
      8. `LucideIcons.glasses` — "glasses"
      9. `LucideIcons.droplets` — "droplets"
      10. `LucideIcons.activity` — "activity"
      11. `LucideIcons.clock` — "clock"
      12. `LucideIcons.check` — "check"
      13. `LucideIcons.chevronDown` — "chevronDown"
      14. `LucideIcons.chevronRight` — "chevronRight"
      15. `LucideIcons.arrowLeft` — "arrowLeft"
      16. `LucideIcons.search` — "search"
      17. `LucideIcons.plus` — "plus"
      18. `LucideIcons.eye` — "eye"
      19. `LucideIcons.x` — "x"
      20. `LucideIcons.phone` — "phone"
    - NOTE: If any `LucideIcons.*` field name doesn't compile, check the package source for the correct name. Common alternatives: `house` might be `home`, `circlePlus` might be `plusCircle`. Use `dart analyze` to catch and fix immediately.

**Done when**:
- [x] No `Icons.*` references remain in `home_screen.dart`
- [x] No `Icons.*` references remain in `theme_preview_screen.dart`
- [x] Both files import `package:lucide_icons_flutter/lucide_icons.dart`
- [x] Theme preview screen has an "Icons" section with 20 labeled Lucide icons in a `Wrap` layout
- [x] `dart analyze` passes on both changed files
- [x] `flutter test` passes (all existing tests green)
- [x] `flutter build apk --debug` succeeds

**Spec criteria addressed**: AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8, AC-9

**Status**: Complete

## Completion Notes
**Completed**: 2026-04-12
**Files changed**: `lib/features/home/presentation/screens/home_screen.dart`, `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart`
**Contract**: Expects 3/3 verified | Produces 4/4 verified
**Notes**: All 20 Lucide icon names compiled without issues — no naming mismatches. All icon names followed the expected lowerCamelCase convention from the package.

## Contracts

### Expects
- `pubspec.yaml` contains `lucide_icons_flutter` in dependencies (produced by Task 001)
- `lib/features/home/presentation/screens/home_screen.dart` exists with `Icons.settings` on line 38
- `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` exists with `Icons.brightness_auto_rounded`, `Icons.light_mode_rounded`, `Icons.dark_mode_rounded`, `Icons.add_rounded`, `Icons.medication_rounded`, `Icons.schedule_rounded`

### Produces
- `home_screen.dart` contains `LucideIcons.settings` and imports `lucide_icons_flutter`
- `theme_preview_screen.dart` contains `LucideIcons.sunMoon`, `LucideIcons.sun`, `LucideIcons.moon`, `LucideIcons.plus`, `LucideIcons.pill`, `LucideIcons.clock` and imports `lucide_icons_flutter`
- `theme_preview_screen.dart` contains `_SectionHeader(label: 'Icons')` followed by a `Wrap` with 20 icon entries
- Zero occurrences of `Icons.` in either file (grep-verifiable)
