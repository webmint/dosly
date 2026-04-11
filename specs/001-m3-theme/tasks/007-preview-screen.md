# Task 007: Create ThemePreviewScreen

**Agent**: mobile-engineer
**Files**:
- `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` *(create)*

**Depends on**: 004 (themeController for cycle action), 006 (ColorSwatchCard, TypographySample widgets)
**Blocks**: 008 (DoslyApp uses this as `home:`)
**Review checkpoint**: Yes — first integration of multiple modules; verify rendering before main.dart wiring
**Context docs**: None

## Description

Build the screen that visually verifies the entire theme. Three sections: a color palette grid (one `ColorSwatchCard` per role), a typography section (one `TypographySample` per text style), and a component showcase (FilledButton, FilledButton.tonal, OutlinedButton, TextButton, Card, Chip, FloatingActionButton, Switch, TextField). The app bar has a cycle action that calls `themeController.cycle()` so the entire screen rebuilds in the new theme without leaving.

This is the first widget that pulls many pieces together — it's the visual ground truth for AC-13 (the manual `flutter run` step).

## Change details

- Create `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart`:
  - `import 'package:flutter/material.dart';`
  - `import '../../../../core/theme/theme_controller.dart';` (themeController singleton)
  - `import '../widgets/color_swatch_card.dart';`
  - `import '../widgets/typography_sample.dart';`
  - File header dartdoc explaining the purpose: "Theme preview / smoke screen. Renders every M3 color role, every type-scale style, and one of each common widget. Used as the app's `home` until real screens land. Delete when no longer needed."
  - Class `ThemePreviewScreen extends StatelessWidget`:
    - `const ThemePreviewScreen({super.key});`
    - `build` returns a `Scaffold`:
      - `appBar: AppBar(title: const Text('dosly · M3 preview'), actions: [IconButton(tooltip: 'Cycle theme mode', icon: Icon(_iconForMode(themeController.value)), onPressed: themeController.cycle)])`
      - **Note**: the IconButton needs to rebuild when the theme cycles. Since `MaterialApp` is wrapped in `ListenableBuilder` at the root (Task 008), the entire tree rebuilds on cycle, so this works without local state.
      - `body: const SingleChildScrollView(padding: EdgeInsets.all(16), child: _PreviewBody())`
      - `floatingActionButton: const FloatingActionButton(onPressed: null, tooltip: 'Demo FAB', child: Icon(Icons.add_rounded))`
    - Private static method `IconData _iconForMode(ThemeMode mode)`:
      - `system → Icons.brightness_auto_rounded`
      - `light → Icons.light_mode_rounded`
      - `dark → Icons.dark_mode_rounded`
  - Private class `_PreviewBody extends StatelessWidget`:
    - `const _PreviewBody();`
    - `build` returns a `Column(crossAxisAlignment: CrossAxisAlignment.start, children: [...])` containing three sections, each preceded by a `_SectionHeader`:
      1. **Color palette section**:
         - Header: `_SectionHeader(label: 'Color roles')`
         - Grid: `Wrap(spacing: 8, runSpacing: 8, children: [ ... ColorSwatchCard for every role ... ])`
         - Use `Theme.of(context).colorScheme.primary`, `.onPrimary`, `.primaryContainer`, `.onPrimaryContainer`, `.secondary`, `.onSecondary`, `.secondaryContainer`, `.onSecondaryContainer`, `.tertiary`, `.onTertiary`, `.tertiaryContainer`, `.onTertiaryContainer`, `.error`, `.onError`, `.errorContainer`, `.onErrorContainer`, `.surface`, `.onSurface`, `.onSurfaceVariant` (paired with `.surfaceContainerHigh`), `.outline` (text on surface), `.outlineVariant` (text on surface), `.surfaceContainerLowest`, `.surfaceContainerLow`, `.surfaceContainer`, `.surfaceContainerHigh`, `.surfaceContainerHighest`, `.inverseSurface` paired with `.onInverseSurface`, `.inversePrimary`
         - Each `ColorSwatchCard` is sized with `SizedBox(width: 160, child: ColorSwatchCard(...))` so the wrap layout looks tidy
         - `hex` label is computed via a small helper: `String _hex(Color c) => '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';` (drops the alpha byte)
      2. **Typography section**:
         - Header: `_SectionHeader(label: 'Typography')`
         - `Column` of `TypographySample` widgets, one per text style: `displayLarge`, `displayMedium`, `displaySmall`, `headlineLarge`, `headlineMedium`, `headlineSmall`, `titleLarge`, `titleMedium`, `titleSmall`, `bodyLarge`, `bodyMedium`, `bodySmall`, `labelLarge`, `labelMedium`, `labelSmall`
      3. **Components section**:
         - Header: `_SectionHeader(label: 'Components')`
         - `Wrap(spacing: 12, runSpacing: 12, children: [...])` containing:
           - `FilledButton(onPressed: () {}, child: const Text('Filled'))`
           - `FilledButton.tonal(onPressed: () {}, child: const Text('Tonal'))`
           - `OutlinedButton(onPressed: () {}, child: const Text('Outlined'))`
           - `TextButton(onPressed: () {}, child: const Text('Text'))`
           - `const Chip(label: Text('Chip'), avatar: Icon(Icons.medication_rounded))`
           - `const Icon(Icons.schedule_rounded, size: 32)`
           - `Switch(value: true, onChanged: (_) {})`
         - Followed by:
           - `const SizedBox(height: 16)`
           - `Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Card title', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 4), Text('Cards use surfaceContainer as their background per the M3 elevation overlay model.', style: Theme.of(context).textTheme.bodyMedium)])))`
           - `const SizedBox(height: 16)`
           - `const TextField(decoration: InputDecoration(labelText: 'Text field', helperText: 'Demonstrates the input decoration theme', prefixIcon: Icon(Icons.medication_rounded)))`
  - Private class `_SectionHeader extends StatelessWidget`:
    - `const _SectionHeader({required this.label});`
    - `final String label;`
    - `build` returns `Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(label, style: Theme.of(context).textTheme.titleLarge))`
  - All `Icon`s use `_rounded` variants (`Icons.add_rounded`, `Icons.schedule_rounded`, `Icons.medication_rounded`, `Icons.brightness_auto_rounded`, `Icons.light_mode_rounded`, `Icons.dark_mode_rounded`).
  - No `print()`, no `debugPrint()`, no async work.

## Done when

- [x] `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` exists
- [x] `class ThemePreviewScreen extends StatelessWidget` is exported
- [x] App bar has a cycle action calling `themeController.cycle`
- [x] Body renders all three sections (palette, typography, components)
- [x] All `Icon` widgets use `*_rounded` variants
- [x] No hardcoded `Color(0xFF...)` literals — every color comes from `Theme.of(context).colorScheme`
- [x] `dart analyze` is clean
- [x] `flutter test` continues to pass (78/78)

## Spec criteria addressed

AC-9 (full preview screen content), AC-10 (rounded icons only), AC-14 (no hardcoded colors outside `lib/core/theme/`)

## Completion Notes

**Status**: Complete
**Completed**: 2026-04-11
**Files changed**: `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` (created — 206 lines)
**Contract**: Expects 3/3 verified | Produces 7/7 verified
**Notes**:
- 28 color swatches, 15 typography samples, full component showcase (FilledButton/Tonal/Outlined/Text + Card + Chip + Switch + TextField + FAB).
- All 6 distinct icons use `_rounded` variants (`add`, `brightness_auto`, `dark_mode`, `light_mode`, `medication`, `schedule`).
- `Color.toARGB32()` (modern Flutter API) worked first try — no fallback needed.
- `themeController.cycle` passed as tearoff (no parens).
- 78/78 tests pass.
- **Code review verdict**: APPROVE (review checkpoint cleared). One info note: spec.md AC-9 lists `inverse-on-surface` as a standalone role; the task spec's role list shows it as the foreground of the `inverseSurface` swatch instead. Implementation matches task spec; future enhancement could add a dedicated `onInverseSurface` swatch.

## Contracts

### Expects
- `lib/core/theme/theme_controller.dart` exports `themeController` (produced by Task 004)
- `lib/features/theme_preview/presentation/widgets/color_swatch_card.dart` exports `ColorSwatchCard` (produced by Task 006)
- `lib/features/theme_preview/presentation/widgets/typography_sample.dart` exports `TypographySample` (produced by Task 006)

### Produces
- File `lib/features/theme_preview/presentation/screens/theme_preview_screen.dart` exists
- It declares `class ThemePreviewScreen extends StatelessWidget`
- It contains an `IconButton` whose `onPressed` references `themeController.cycle`
- It uses `ColorSwatchCard` (verifiable by grep)
- It uses `TypographySample` (verifiable by grep)
- It contains at least one `FilledButton`, `OutlinedButton`, `Chip`, `Card`, `Switch`, `TextField`, and `FloatingActionButton`
- All icon references use `_rounded` suffix (verifiable by grep — no `Icons.xxx_rounded` should be missing the suffix)
