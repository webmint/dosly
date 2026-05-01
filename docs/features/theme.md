# Theme

## Overview

The theme module is dosly's visual foundation. It hand-codes Material 3 `ColorScheme` tokens for light and dark mode, bundles Roboto at four weights, and composes them into `ThemeData` with 11 pre-wired component themes. Everything lives under `lib/core/theme/` so every future feature consumes the same tokens — widgets never hardcode colors or text styles.

Runtime theme-mode selection (light / dark / system) is owned by `settingsProvider`, not by this module. See [`settings.md`](settings.md) and [`architecture.md`](../architecture.md) for how `DoslyApp` maps `AppThemeMode` to Flutter's `ThemeMode`.

## How it works

Composition flows bottom-up:

```
app_color_schemes.dart   (const ColorScheme literals — one per brightness)
        │
        ▼
app_text_theme.dart      (AppTextTheme.textTheme — M3 type scale on Roboto)
        │
        ▼
app_theme.dart           (AppTheme.lightTheme / darkTheme — ThemeData)
        │
        ▼
app.dart                 (DoslyApp passes lightTheme/darkTheme to MaterialApp.router;
                          themeMode is driven by settingsProvider)
```

**`app_color_schemes.dart`** exports two `const ColorScheme` values — `lightColorScheme` and `darkColorScheme`. Every role (primary, secondary, tertiary, error, surface + containers, outline, inverse) is a hand-coded `Color(0xFF…)` literal taken from `dosly_m3_template.html` (Material Theme Builder, seed `#4CAF50`). `ColorScheme.fromSeed` is **not** used — the spec requires a deterministic, in-source palette that unit tests can pin.

**`app_text_theme.dart`** exposes `AppTextTheme.textTheme` — all 15 M3 type-scale styles (`displayLarge` … `labelSmall`) built on `fontFamily: 'Roboto'`. Sizes, weights, line-heights, and letter-spacings follow the canonical M3 type scale.

**`app_theme.dart`** has a private `_build(ColorScheme scheme)` method that produces a fully-configured `ThemeData`. It is called twice:

```dart
class AppTheme {
  const AppTheme._();
  static ThemeData get lightTheme => _build(lightColorScheme);
  static ThemeData get darkTheme => _build(darkColorScheme);
  // _build wires useMaterial3, colorScheme, textTheme, iconTheme,
  // scaffoldBackgroundColor, and 11 component themes: appBar, card,
  // filledButton, outlinedButton, textButton, chip, fab, inputDecoration,
  // divider, bottomNavigationBar.
}
```

`textTheme` is tinted on build via `.apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface)` so text contrast tracks the active brightness automatically.

**`app.dart`** passes `AppTheme.lightTheme` and `AppTheme.darkTheme` to `MaterialApp.router`. `DoslyApp` is a `ConsumerWidget` that reads `settingsProvider` with four narrow selectors and computes `themeMode` and `locale` inline. See [`architecture.md`](../architecture.md#app-wide-state-riverpod--sharedpreferences) for the full bootstrap and the code sample.

## Usage

Downstream widgets consume the theme via `Theme.of(context)`. They never hardcode colors or text sizes.

**Colors**:

```dart
final scheme = Theme.of(context).colorScheme;

Container(
  color: scheme.primaryContainer,
  child: Text('Hi', style: TextStyle(color: scheme.onPrimaryContainer)),
);
```

**Text styles**:

```dart
Text('Card title', style: Theme.of(context).textTheme.titleMedium);
```

**Component themes** require no extra work — `FilledButton`, `Card`, `TextField`, `Chip`, `FloatingActionButton`, etc. pick up the dosly-specific shape, radius, and color overrides automatically because they are pre-wired inside `AppTheme._build`.

**Rule**: no `Color(0xFF…)` literals outside `lib/core/theme/`. Spec `001-m3-theme` AC-14 enforces this with a grep check during verification.

## How to change a color

1. Open `lib/core/theme/app_color_schemes.dart`.
2. Edit the role's `Color(0xFF…)` literal in `lightColorScheme` and/or `darkColorScheme`. Keep the two schemes in sync when the change is semantic.
3. Update the per-hex assertion in `test/core/theme/app_color_schemes_test.dart` — the tests pin every role, so a silent edit will fail CI.
4. Re-run the preview to eyeball the result:
   ```bash
   flutter run
   ```
5. If you added a brand-new role (rare — M3 only has a fixed set), also add a `ColorSwatchCard` for it in `theme_preview_screen.dart` so it shows up in the preview.

## How to change or add a text style

1. Open `lib/core/theme/app_text_theme.dart`.
2. Edit the style inside the `TextTheme(...)` literal — all 15 M3 slots are already declared, so usually you're tweaking one.
3. If you want the change to appear in the preview, add a matching row to the typography section of `theme_preview_screen.dart`:
   ```dart
   TypographySample(styleName: 'titleLarge', style: textTheme.titleLarge),
   ```
4. Rebuild. Text consumers that read `Theme.of(context).textTheme.titleLarge` pick it up automatically.

Do not add a new `fontFamily`. The app bundles only Roboto (300 / 400 / 500 / 700); adding another family means adding more TTF assets to `assets/fonts/` and declaring them in `pubspec.yaml` under `flutter.fonts`.

## How to change the runtime theme mode

Theme-mode state lives in `settingsProvider` (a `Notifier<AppSettings>`). To change it from a widget, obtain the notifier via `ref.read` and call its mutation methods:

```dart
// Force dark mode manually (turns off "follow system")
ref.read(settingsProvider.notifier).setThemeMode(AppThemeMode.dark);
ref.read(settingsProvider.notifier).setUseSystemTheme(false);

// Return to following the system theme
ref.read(settingsProvider.notifier).setUseSystemTheme(true);
```

`DoslyApp` in `lib/app.dart` watches `settingsProvider` with narrow selectors and passes the computed `ThemeMode` to `MaterialApp.router`. Changes are persisted to `SharedPreferencesWithCache` and survive restarts.

See [`settings.md`](settings.md) for the full provider and persistence contract.

## The preview screen

`lib/features/theme_preview/` is a one-off "feature folder" containing `ThemePreviewScreen` plus two helper widgets (`ColorSwatchCard`, `TypographySample`). It is currently wired as `DoslyApp`'s `home`, so the app boots directly into it.

What it shows:

- **Color roles** — one swatch per role (primary / onPrimary / primaryContainer / …, all surface containers, outline, inverse, etc.), each rendered with its actual color as the background and hex label overlaid
- **Typography** — one row per M3 style (`displayLarge` … `labelSmall`)
- **Icons** — the 20 canonical Lucide glyphs used across the app design (`pill`, `house`, `settings`, `history`, `circlePlus`, `thermometer`, `syringe`, `glasses`, `droplets`, `activity`, `clock`, `check`, `chevronDown`, `chevronRight`, `arrowLeft`, `search`, `plus`, `eye`, `x`, `phone`), each shown with its `LucideIcons.*` field name as a label. See [`icons.md`](icons.md) for the icon-set rationale.
- **Components** — one instance each of `FilledButton`, `FilledButton.tonal`, `OutlinedButton`, `TextButton`, `Chip`, `Icon`, `Switch`, `Card`, `TextField`, `FloatingActionButton`
- **App-bar cycle action** — an `IconButton` whose icon reflects the current mode (`LucideIcons.sunMoon` / `sun` / `moon`). Pressing it cycles system → light → dark → system by writing to `settingsProvider.notifier` (`setUseSystemTheme` + `setThemeMode(AppThemeMode.*)`).

All icons are sourced from `lucide_icons_flutter` — see [`icons.md`](icons.md).

**When to delete**: once real screens ship and `DoslyApp.home` points at something non-preview, delete `lib/features/theme_preview/` entirely. The folder was built to be disposable — no other feature folder imports from it (its own imports into `lib/features/settings/` are the only cross-feature dependency, and those disappear with the folder).

## Related specs and references

- [`specs/001-m3-theme/spec.md`](../../specs/001-m3-theme/spec.md) — the original spec
- [`specs/001-m3-theme/plan.md`](../../specs/001-m3-theme/plan.md) — technical plan and design decisions
- [`specs/001-m3-theme/summary.md`](../../specs/001-m3-theme/summary.md) — concise feature summary
- [`architecture.md`](../architecture.md) — where the theme module fits in the overall layering
- `dosly_m3_template.html` — the original Material Theme Builder export (seed `#4CAF50`) that every hex in `app_color_schemes.dart` traces back to
- `assets/fonts/SOURCE.md` — Roboto provenance (download URL, version, SHA-256 hashes)
- `assets/fonts/LICENSE.txt` — Roboto SIL OFL 1.1 license
