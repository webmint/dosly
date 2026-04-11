# Research: Material Design 3 Theme

**Date**: 2026-04-11
**Signals detected**:
1. Flutter `ColorScheme` field naming for M3 surface containers (HTML uses `--md-surface-{lowest,low,container,high,highest}`, Flutter renamed these as the M3 expressive update landed — needed to verify)
2. Deprecated `ColorScheme` fields (background, onBackground, surfaceVariant) — needed to confirm migration path
3. `pubspec.yaml` font declaration syntax for multiple weights

## Questions Investigated

1. **What are the exact Flutter `ColorScheme` field names for the M3 surface container scale?**
   → **Finding**: Flutter exposes `surfaceContainerLowest`, `surfaceContainerLow`, `surfaceContainer`, `surfaceContainerHigh`, `surfaceContainerHighest`. These map 1:1 to the HTML's `--md-surface-lowest/low/container/high/highest`. Source: Flutter breaking changes doc "Introduce new ColorScheme roles for Material 3" (`flutter/website` repo, `breaking-changes/new-color-scheme-roles.md`).

2. **Which `ColorScheme` fields are deprecated and how should the HTML's deprecated tokens be migrated?**
   → **Finding**: `background`, `onBackground`, and `surfaceVariant` were removed. Migration:
   - `background` → `surface` (HTML values are already identical: light `#F6FBF3`, dark `#101410`)
   - `onBackground` → `onSurface` (HTML values are already identical: light `#191C18`, dark `#DFE4DC`)
   - `surfaceVariant` → `surfaceContainerHighest` (per migration guide)
   - **HOWEVER**, the HTML provides its OWN `--md-surface-highest` (light `#DFE4DC`, dark `#323631`) which takes precedence as `surfaceContainerHighest`. The deprecated `--md-surface-variant` value (light `#DCE5D8`, dark `#404942`) is therefore **dropped** — using it would shadow the explicit modern value.
   - `--md-on-surface-variant` is STILL CURRENT (it's the on-color for tinted text on surface containers and is unrelated to the deprecated `surfaceVariant`). Map to Flutter `onSurfaceVariant`.

3. **Which M3 expressive fields does the HTML NOT specify, and what should we set them to?**
   → **Finding**: The HTML lacks `surfaceBright`, `surfaceDim`, and the "fixed" variants (`primaryFixed`, `primaryFixedDim`, `onPrimaryFixed`, `onPrimaryFixedVariant`, plus secondary/tertiary equivalents).
   - **`surfaceBright` / `surfaceDim`**: derive from existing surface containers in a way that preserves M3 semantics (bright = higher tone in light, lower tone in dark; dim = the opposite):
     - Light: `surfaceBright = surfaceContainerLow` (`#F0F5ED`), `surfaceDim = surfaceContainerHighest` (`#DFE4DC`)
     - Dark: `surfaceBright = surfaceContainerHigh` (`#272B26`), `surfaceDim = surfaceContainerLowest` (`#0B0F0B`)
   - **Fixed variants**: skip in v1. Flutter's `ColorScheme(...)` constructor accepts them as nullable — we omit them. If a future widget needs them, we add them in a later spec.
   - **`surfaceTint`**: defaults to `primary`. Set explicitly to `primary` for both schemes.
   - **`shadow`**: M3 default is `Color(0xFF000000)`. Set explicitly.

4. **What's the canonical `pubspec.yaml` syntax for declaring multiple weights of one font family?**
   → **Finding**: Confirmed format from Flutter cookbook (`flutter/website/cookbook/design/fonts.md`):
   ```yaml
   flutter:
     fonts:
       - family: Roboto
         fonts:
           - asset: assets/fonts/Roboto-Light.ttf
             weight: 300
           - asset: assets/fonts/Roboto-Regular.ttf
             weight: 400
           - asset: assets/fonts/Roboto-Medium.ttf
             weight: 500
           - asset: assets/fonts/Roboto-Bold.ttf
             weight: 700
   ```
   The `weight:` is optional but required when multiple weights of the same family are declared so Flutter can pick the right TTF for `FontWeight.w300/w400/w500/w700`.

5. **Are `Icons.xxx_rounded` variants available for the icons we'll need in the preview screen?**
   → **Finding**: Flutter ships rounded variants for all standard Material icons. Examples used in the preview screen: `Icons.dark_mode_rounded`, `Icons.light_mode_rounded`, `Icons.brightness_auto_rounded`, `Icons.add_rounded`, `Icons.medication_rounded`, `Icons.schedule_rounded`, `Icons.check_rounded`. All exist in the built-in `Icons` class.

## Alternatives Compared

### How to construct the ColorScheme

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| `ColorScheme(...)` constructor with every field hand-coded | Exact, deterministic, no surprises, every value is in source. Matches spec AC-1 literally ("NO `ColorScheme.fromSeed`"). | Verbose (~30 named parameters per scheme). Must derive `surfaceBright`/`surfaceDim` manually. | **Chosen** |
| `ColorScheme.fromSeed(seedColor: Color(0xFF4CAF50)).copyWith(...)` | Less code. `surfaceBright`/`surfaceDim`/fixed variants auto-derived from the same seed Theme Builder used. Still 100% faithful to HTML for explicit overrides. | Spec AC-1 forbids it ("NO `ColorScheme.fromSeed` is used"). Two sources of truth (seed + overrides) instead of one. | Rejected (spec violation) |
| `ColorScheme.fromImageProvider(...)` (Material You-style image extraction) | None for this use case | Wrong tool — we have explicit hex tokens, not an image | Rejected |

**Decision**: Hand-coded `ColorScheme(...)` constructor literal with `const` where possible. Single source of truth. Compatible with spec AC-1.

### Where to place `surfaceBright` / `surfaceDim` derivations

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| Reuse existing container values (`surfaceBright = surfaceContainerLow`, etc.) | Zero code, deterministic, documented in research.md | Slightly less semantically accurate than algorithmic derivation | **Chosen** |
| Compute via HSL adjustment | More semantically accurate | Adds dependency on a color-math helper, more code, easy to get wrong | Rejected |
| Set both equal to `surface` | Simplest | Loses the bright/dim distinction entirely; widgets that distinguish them will look wrong | Rejected |

**Decision**: Reuse adjacent container tones. Documented in `app_color_schemes.dart` with a `///` comment so the choice is discoverable.

### Font loading strategy

(Already decided in spec — bundle TTF assets. Including here for completeness.)

| Option | Pros | Cons | Verdict |
|---|---|---|---|
| Bundle Roboto TTF as asset | Works offline, identical cross-platform, reproducible, no runtime network call (constitution-compliant) | App size +~600 KB (4 weights × ~150 KB) | **Chosen** (per spec) |
| `google_fonts` package | No bundled assets | Loads from Google Fonts at runtime, network call on first launch (violates "fully local" constitution rule) | Rejected (constitution violation) |
| Platform default | Smallest app | Roboto on Android, San Francisco on iOS — design is not consistent | Rejected (per spec) |

**Decision**: Bundle. Per the spec.

## References

- [Flutter breaking changes — new ColorScheme roles](https://docs.flutter.dev/release/breaking-changes/new-color-scheme-roles)
- [Flutter breaking changes — Material Design 3 token update](https://docs.flutter.dev/release/breaking-changes/material-design-3-token-update)
- [Flutter cookbook — Use a custom font](https://docs.flutter.dev/cookbook/design/fonts)
- [pubspec.yaml reference — fonts field](https://docs.flutter.dev/tools/pubspec)
- [Material Theme Builder](https://material-foundation.github.io/material-theme-builder/) — the tool that generated `dosly_m3_template.html`
- Local: `dosly_m3_template.html` lines 12 (seed), 16-55 (light scheme), 77-108 (dark scheme), 117 (Roboto family), 1447 (`material-icons-round` reference)
