# Task 006: Create preview helper widgets (ColorSwatchCard + TypographySample)

**Agent**: mobile-engineer
**Files**:
- `lib/features/theme_preview/presentation/widgets/color_swatch_card.dart` *(create)*
- `lib/features/theme_preview/presentation/widgets/typography_sample.dart` *(create)*

**Depends on**: None
**Blocks**: 007 (preview screen composes these widgets)
**Review checkpoint**: No
**Context docs**: None

## Description

Two small reusable widgets used by the preview screen. Bundled into a single task because they're tiny, share an agent, and are only consumed by Task 007 — keeping them as separate tasks would add an execution wave for ~70 lines of code.

`ColorSwatchCard` paints a single color role's background with the corresponding `on*` color text overlay (role name + hex). Used to render the palette grid.

`TypographySample` shows one row labelled with a text-style name and a sample line rendered in that style. Used to render the typography section.

Both are pure `StatelessWidget`s that read nothing from `Theme.of(context)` themselves — values are passed in via constructor. This makes them trivially testable and keeps them dependency-free.

## Change details

- Create `lib/features/theme_preview/presentation/widgets/color_swatch_card.dart`:
  - `import 'package:flutter/material.dart';`
  - File header dartdoc.
  - Class `ColorSwatchCard extends StatelessWidget`:
    - `const ColorSwatchCard({super.key, required this.label, required this.color, required this.onColor, required this.hex});`
    - Final fields: `final String label`, `final Color color`, `final Color onColor`, `final String hex`
    - `build` returns a `Container`:
      - `decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12))`
      - `padding: const EdgeInsets.all(12)`
      - `constraints: const BoxConstraints(minHeight: 72)`
      - Child: `Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: onColor, fontWeight: FontWeight.w500, fontSize: 13)), Text(hex, style: TextStyle(color: onColor, fontFamily: 'monospace', fontSize: 11))])`
    - Dartdoc on the class explaining its purpose.

- Create `lib/features/theme_preview/presentation/widgets/typography_sample.dart`:
  - `import 'package:flutter/material.dart';`
  - File header dartdoc.
  - Class `TypographySample extends StatelessWidget`:
    - `const TypographySample({super.key, required this.styleName, required this.style});`
    - Final fields: `final String styleName`, `final TextStyle? style`
    - `build` returns a `Padding`:
      - `padding: const EdgeInsets.symmetric(vertical: 8)`
      - Child: `Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(styleName, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11)), const SizedBox(height: 2), Text('The quick brown fox', style: style)])`
    - Note: `style` is nullable so callers can pass `Theme.of(context).textTheme.titleLarge` directly without `!`.
    - Dartdoc on the class.

- Both widgets use only `const` constructors. No state, no controllers, no async.
- All Material icon usage in the preview-screen task uses `Icons.xxx_rounded`; these widgets don't use icons themselves.

## Done when

- [x] Both widget files exist at the paths above
- [x] `ColorSwatchCard` constructor takes `label`, `color`, `onColor`, `hex` as required named parameters
- [x] `TypographySample` constructor takes `styleName` and `style` (nullable) as required named parameters
- [x] Both classes are `const`-constructible
- [x] `dart analyze` is clean
- [x] No hardcoded `Color(0xFF...)` literals — colors come from constructor parameters or `Theme.of(context).colorScheme`

## Spec criteria addressed

AC-9 (preview-screen content), AC-14 (no hardcoded colors outside `lib/core/theme/`)

## Completion Notes

**Status**: Complete
**Completed**: 2026-04-11
**Files changed**:
- `lib/features/theme_preview/presentation/widgets/color_swatch_card.dart` (created)
- `lib/features/theme_preview/presentation/widgets/typography_sample.dart` (created)

**Contract**: Expects 2/2 verified | Produces 4/4 verified

**Notes**:
- 78/78 tests still passing.
- Zero `Color(0xFF...)` literals in either file (grep verified) — both widgets pull colors from constructor params or `Theme.of(context).colorScheme`.
- `lib/features/` directory created as part of this task (didn't exist before).
- Code review skipped (small mechanical widgets matching spec literally).

## Contracts

### Expects
- `lib/features/` directory may not exist — task creates it
- `package:flutter/material.dart` is available

### Produces
- File `lib/features/theme_preview/presentation/widgets/color_swatch_card.dart` exists
- It declares `class ColorSwatchCard extends StatelessWidget`
- It declares the constructor `const ColorSwatchCard({super.key, required this.label, required this.color, required this.onColor, required this.hex})`
- File `lib/features/theme_preview/presentation/widgets/typography_sample.dart` exists
- It declares `class TypographySample extends StatelessWidget`
- It declares the constructor `const TypographySample({super.key, required this.styleName, required this.style})`
