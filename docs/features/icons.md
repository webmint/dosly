# Icons

## Overview

dosly uses **Lucide** as its icon set across every screen. Icons come from the [`lucide_icons_flutter`](https://pub.dev/packages/lucide_icons_flutter) package (v3.1.12), which exposes Lucide glyphs as standard Flutter `IconData` constants — drop-in replacements for `Icons.*`. This matches the icon set drawn in the HTML design template (`dosly_m3_template.html`), so what ships on-device visually tracks the design reference.

No Material Design icons (`Icons.*`) are used in app-level widgets. `cupertino_icons` and `uses-material-design: true` remain in `pubspec.yaml` because Flutter's own scaffolding (e.g., default `BackButton`) falls back to Material glyphs, but feature code should not reach for them.

## How it works

The package ships `LucideIcons` — a class full of `static const IconData` fields — which you pass to any widget that accepts an `IconData`:

```dart
import 'package:lucide_icons_flutter/lucide_icons.dart';

IconButton(
  tooltip: 'Settings',
  icon: const Icon(LucideIcons.settings),
  onPressed: null,
);
```

Because Lucide glyphs are delivered as an icon font (not SVG), they render at any size, honour `Theme.of(context).iconTheme`, and get tree-shaken in release builds just like Material icons. Nothing extra is required in `MaterialApp` or `ThemeData` — the font is registered by the package.

## Naming convention

Lucide uses kebab-case names on [lucide.dev](https://lucide.dev) (e.g., `circle-plus`, `chevron-down`). The Dart package converts these to lowerCamelCase fields on `LucideIcons`:

| lucide.dev | `LucideIcons.*` |
|---|---|
| `pill` | `LucideIcons.pill` |
| `circle-plus` | `LucideIcons.circlePlus` |
| `chevron-down` | `LucideIcons.chevronDown` |
| `arrow-left` | `LucideIcons.arrowLeft` |
| `sun-moon` | `LucideIcons.sunMoon` |
| `x` | `LucideIcons.x` |

When you find a glyph on lucide.dev, translate the name to camelCase and let the Dart analyzer confirm the field exists. The analyser catches typos immediately — there is no silent fallback icon.

## Picking an icon

1. Open the design source (`dosly_m3_template.html` or a Figma export) and find the SVG you're replacing.
2. Search [lucide.dev](https://lucide.dev) for the glyph by name or visual match.
3. Convert the kebab-case name to lowerCamelCase and reference it as `LucideIcons.<name>`.
4. If you're unsure whether an icon exists, open the theme preview screen — the Icons section lists the canonical glyphs used in the design and is the fastest way to confirm a given field resolves.

Stroke weight: the default `LucideIcons.foo` matches the template's `stroke-width="2"` standard. The package also exposes weight variants (`LucideIcons.activity200`, etc.) but the default is what the design uses — do not mix weights without updating the design reference first.

## The canonical icon set

The 20 icons below are the full set catalogued from the HTML template and are the first-class glyphs for the app. All 20 render in the theme preview's Icons section so you can eyeball them live:

`pill` · `house` · `settings` · `history` · `circlePlus` · `thermometer` · `syringe` · `glasses` · `droplets` · `activity` · `clock` · `check` · `chevronDown` · `chevronRight` · `arrowLeft` · `search` · `plus` · `eye` · `x` · `phone`

Plus the three theme-mode glyphs consumed by the theme preview's cycle button: `sunMoon` · `sun` · `moon`.

New features should prefer icons already in this set before introducing additional Lucide glyphs — when a new one is needed, add it to the showcase in `theme_preview_screen.dart` at the same time.

## Usage

### In an IconButton

```dart
AppBar(
  actions: [
    IconButton(
      tooltip: 'Settings',
      icon: const Icon(LucideIcons.settings),
      onPressed: null,
    ),
  ],
);
```

### As a widget prefix or avatar

```dart
Chip(
  label: const Text('Vitamin D'),
  avatar: const Icon(LucideIcons.pill, size: 18),
);

TextField(
  decoration: const InputDecoration(
    labelText: 'Medication',
    prefixIcon: Icon(LucideIcons.pill),
  ),
);
```

### As a FAB

```dart
FloatingActionButton(
  tooltip: 'Add',
  child: const Icon(LucideIcons.plus),
  onPressed: () {},
);
```

### Dynamic selection

Icons are plain `IconData` values, so you can switch on state:

```dart
static IconData _iconForMode(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => LucideIcons.sunMoon,
    ThemeMode.light  => LucideIcons.sun,
    ThemeMode.dark   => LucideIcons.moon,
  };
}
```

## Rules

- **Never import `package:flutter/material.dart`'s `Icons.*` in feature code.** If you need a glyph, reach for `LucideIcons.*`. The two exceptions are (a) widgets Flutter renders itself (e.g., default `BackButton`) and (b) the odd Cupertino-only situation, which should be explicitly called out.
- **Never import icons in `domain/`.** Icons are a presentation concern. Use cases, entities, and repositories are pure Dart (constitution §2.1).
- **Keep the showcase in sync.** When a feature introduces a new Lucide icon, add an `_iconTile` entry to the Icons section of `theme_preview_screen.dart` so the canonical set stays discoverable.

## Related

- [`../../specs/004-lucide-icons/spec.md`](../../specs/004-lucide-icons/spec.md) — the spec that introduced Lucide
- [`../../specs/004-lucide-icons/summary.md`](../../specs/004-lucide-icons/summary.md) — concise feature summary
- [`theme.md`](theme.md) — the theme preview screen that hosts the icon showcase
- [lucide.dev](https://lucide.dev) — browse the full Lucide icon catalogue
- [`lucide_icons_flutter` on pub.dev](https://pub.dev/packages/lucide_icons_flutter) — the Flutter package
