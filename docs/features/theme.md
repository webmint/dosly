# Theme

## Overview

The theme module is dosly's visual foundation. It hand-codes Material 3 `ColorScheme` tokens for light and dark mode, bundles Roboto at four weights, composes them into `ThemeData` with 11 pre-wired component themes, and drives `MaterialApp.themeMode` from a tiny in-memory controller. Everything lives under `lib/core/theme/` so every future feature consumes the same tokens — widgets never hardcode colors or text styles.

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
app.dart                 (DoslyApp wraps MaterialApp in ListenableBuilder)
        │
        ▼
theme_controller.dart    (themeController drives themeMode at runtime)
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

**`theme_controller.dart`** holds the current `ThemeMode` in a `ValueNotifier<ThemeMode>` subclass and exposes a module-level singleton:

```dart
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.system);

  void setMode(ThemeMode mode) {
    value = mode;
  }

  void cycle() {
    value = switch (value) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
  }
}

final ThemeController themeController = ThemeController();
```

**`app.dart`** wraps `MaterialApp` in a `ListenableBuilder` so the entire tree rebuilds whenever the controller value changes:

```dart
class DoslyApp extends StatelessWidget {
  const DoslyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) => MaterialApp(
        title: 'dosly',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.value,
        home: const ThemePreviewScreen(),
      ),
    );
  }
}
```

Persistence is intentionally not handled — the controller resets to `ThemeMode.system` on every restart. Persistence will land with the future Settings feature (drift-backed).

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

## How to toggle theme mode

From anywhere in the app, import the controller and call one of its methods:

```dart
import 'package:dosly/core/theme/theme_controller.dart';

themeController.setMode(ThemeMode.dark);  // force dark
themeController.setMode(ThemeMode.system); // follow OS
themeController.cycle();                    // system -> light -> dark -> system
```

The `ListenableBuilder` in `DoslyApp` rebuilds `MaterialApp` and the whole tree re-themes. There is no need to call `setState` or wrap anything in a provider.

Reminder: this is **in-memory only**. Restarting the app resets to `ThemeMode.system`.

## The preview screen

`lib/features/theme_preview/` is a one-off "feature folder" containing `ThemePreviewScreen` plus two helper widgets (`ColorSwatchCard`, `TypographySample`). It is currently wired as `DoslyApp`'s `home`, so the app boots directly into it.

What it shows:

- **Color roles** — one swatch per role (primary / onPrimary / primaryContainer / …, all surface containers, outline, inverse, etc.), each rendered with its actual color as the background and hex label overlaid
- **Typography** — one row per M3 style (`displayLarge` … `labelSmall`)
- **Components** — one instance each of `FilledButton`, `FilledButton.tonal`, `OutlinedButton`, `TextButton`, `Chip`, `Icon` (rounded), `Switch`, `Card`, `TextField`, `FloatingActionButton`
- **App-bar cycle action** — an `IconButton` whose icon reflects the current mode and calls `themeController.cycle` on press

All icons use the `Icons.xxx_rounded` variants to match the design reference.

**When to delete**: once real screens ship and `DoslyApp.home` points at something non-preview, delete `lib/features/theme_preview/` entirely. The folder was built to be disposable — nothing else in the codebase imports from it.

## Related specs and references

- [`specs/001-m3-theme/spec.md`](../../specs/001-m3-theme/spec.md) — the original spec
- [`specs/001-m3-theme/plan.md`](../../specs/001-m3-theme/plan.md) — technical plan and design decisions
- [`specs/001-m3-theme/summary.md`](../../specs/001-m3-theme/summary.md) — concise feature summary
- [`architecture.md`](../architecture.md) — where the theme module fits in the overall layering
- `dosly_m3_template.html` — the original Material Theme Builder export (seed `#4CAF50`) that every hex in `app_color_schemes.dart` traces back to
- `assets/fonts/SOURCE.md` — Roboto provenance (download URL, version, SHA-256 hashes)
- `assets/fonts/LICENSE.txt` — Roboto SIL OFL 1.1 license
