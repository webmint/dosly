# Task 002: Create app_color_schemes.dart with light and dark ColorScheme literals

**Agent**: mobile-engineer
**Files**:
- `lib/core/theme/app_color_schemes.dart` *(create)*
- `test/core/theme/app_color_schemes_test.dart` *(create)*

**Depends on**: None
**Blocks**: 005 (AppTheme builds ThemeData from these schemes)
**Review checkpoint**: No
**Context docs**: `specs/001-m3-theme/research.md` (sections "Questions Investigated" Q1–Q3 explain the surface-container field naming and the dropped `surfaceVariant`)

## Description

Define both `lightColorScheme` and `darkColorScheme` as top-level `const ColorScheme(...)` literals in `lib/core/theme/app_color_schemes.dart`. Every M3 color role uses the **exact hex value** from `dosly_m3_template.html`. The seed (`#4CAF50`) is documented in a header comment but NOT used to construct the schemes — `ColorScheme.fromSeed` is forbidden by spec AC-1.

Also create the per-field hex assertion test file. The test enforces design fidelity: any future edit that drifts from the design source breaks the build.

## Change details

- Create directory `lib/core/theme/`.
- Create `lib/core/theme/app_color_schemes.dart`:
  - File header dartdoc explaining: source = `dosly_m3_template.html`, seed = `#4CAF50` (Material Theme Builder), this file is the single source of truth for every color literal in the app.
  - `import 'package:flutter/material.dart';`
  - Top-level `const ColorScheme lightColorScheme = ColorScheme(brightness: Brightness.light, ...)` with these field assignments:

    | Field | Value | HTML source |
    |---|---|---|
    | `brightness` | `Brightness.light` | — |
    | `primary` | `Color(0xFF2E7D32)` | line 16 |
    | `onPrimary` | `Color(0xFFFFFFFF)` | line 17 |
    | `primaryContainer` | `Color(0xFFB7F0B1)` | line 18 |
    | `onPrimaryContainer` | `Color(0xFF002204)` | line 19 |
    | `secondary` | `Color(0xFF52634F)` | line 21 |
    | `onSecondary` | `Color(0xFFFFFFFF)` | line 22 |
    | `secondaryContainer` | `Color(0xFFD5E8CF)` | line 23 |
    | `onSecondaryContainer` | `Color(0xFF101F0F)` | line 24 |
    | `tertiary` | `Color(0xFF38656A)` | line 26 |
    | `onTertiary` | `Color(0xFFFFFFFF)` | line 27 |
    | `tertiaryContainer` | `Color(0xFFBCEBF0)` | line 28 |
    | `onTertiaryContainer` | `Color(0xFF002023)` | line 29 |
    | `error` | `Color(0xFFBA1A1A)` | line 31 |
    | `onError` | `Color(0xFFFFFFFF)` | line 32 |
    | `errorContainer` | `Color(0xFFFFDAD6)` | line 33 |
    | `onErrorContainer` | `Color(0xFF410002)` | line 34 |
    | `surface` | `Color(0xFFF6FBF3)` | line 38 |
    | `onSurface` | `Color(0xFF191C18)` | line 39 |
    | `onSurfaceVariant` | `Color(0xFF404942)` | line 41 |
    | `outline` | `Color(0xFF70796E)` | line 42 |
    | `outlineVariant` | `Color(0xFFC0C9BB)` | line 43 |
    | `surfaceContainerLowest` | `Color(0xFFFFFFFF)` | line 45 |
    | `surfaceContainerLow` | `Color(0xFFF0F5ED)` | line 46 |
    | `surfaceContainer` | `Color(0xFFEAF0E7)` | line 47 |
    | `surfaceContainerHigh` | `Color(0xFFE4EAE1)` | line 48 |
    | `surfaceContainerHighest` | `Color(0xFFDFE4DC)` | line 49 |
    | `surfaceBright` | `Color(0xFFF0F5ED)` | derived (= surfaceContainerLow) |
    | `surfaceDim` | `Color(0xFFDFE4DC)` | derived (= surfaceContainerHighest) |
    | `inverseSurface` | `Color(0xFF2E312D)` | line 51 |
    | `onInverseSurface` | `Color(0xFFEFF2EC)` | line 52 (HTML: inverse-on-surface) |
    | `inversePrimary` | `Color(0xFF8BD988)` | line 53 |
    | `surfaceTint` | `Color(0xFF2E7D32)` | = primary |
    | `shadow` | `Color(0xFF000000)` | M3 default |
    | `scrim` | `Color(0xFF000000)` | line 55 |

  - Top-level `const ColorScheme darkColorScheme = ColorScheme(brightness: Brightness.dark, ...)` with these field assignments:

    | Field | Value | HTML source |
    |---|---|---|
    | `brightness` | `Brightness.dark` | — |
    | `primary` | `Color(0xFF8BD988)` | line 77 |
    | `onPrimary` | `Color(0xFF003A02)` | line 78 |
    | `primaryContainer` | `Color(0xFF0A5210)` | line 79 |
    | `onPrimaryContainer` | `Color(0xFFA6F5A2)` | line 80 |
    | `secondary` | `Color(0xFFB9CCAF)` | line 81 |
    | `onSecondary` | `Color(0xFF253422)` | line 82 |
    | `secondaryContainer` | `Color(0xFF3B4B37)` | line 83 |
    | `onSecondaryContainer` | `Color(0xFFD5E8CF)` | line 84 |
    | `tertiary` | `Color(0xFFA0CFD5)` | line 85 |
    | `onTertiary` | `Color(0xFF00363B)` | line 86 |
    | `tertiaryContainer` | `Color(0xFF1F4D52)` | line 87 |
    | `onTertiaryContainer` | `Color(0xFFBCEBF0)` | line 88 |
    | `error` | `Color(0xFFFFB4AB)` | line 89 |
    | `onError` | `Color(0xFF690005)` | line 90 |
    | `errorContainer` | `Color(0xFF93000A)` | line 91 |
    | `onErrorContainer` | `Color(0xFFFFDAD6)` | line 92 |
    | `surface` | `Color(0xFF101410)` | line 95 |
    | `onSurface` | `Color(0xFFDFE4DC)` | line 96 |
    | `onSurfaceVariant` | `Color(0xFFBFC9BB)` | line 98 |
    | `outline` | `Color(0xFF8A9388)` | line 99 |
    | `outlineVariant` | `Color(0xFF404942)` | line 100 |
    | `surfaceContainerLowest` | `Color(0xFF0B0F0B)` | line 101 |
    | `surfaceContainerLow` | `Color(0xFF191C18)` | line 102 |
    | `surfaceContainer` | `Color(0xFF1D211C)` | line 103 |
    | `surfaceContainerHigh` | `Color(0xFF272B26)` | line 104 |
    | `surfaceContainerHighest` | `Color(0xFF323631)` | line 105 |
    | `surfaceBright` | `Color(0xFF272B26)` | derived (= surfaceContainerHigh) |
    | `surfaceDim` | `Color(0xFF0B0F0B)` | derived (= surfaceContainerLowest) |
    | `inverseSurface` | `Color(0xFFDFE4DC)` | line 106 |
    | `onInverseSurface` | `Color(0xFF2E312D)` | line 107 |
    | `inversePrimary` | `Color(0xFF1B6B1D)` | line 109 |
    | `surfaceTint` | `Color(0xFF8BD988)` | = primary |
    | `shadow` | `Color(0xFF000000)` | M3 default |
    | `scrim` | `Color(0xFF000000)` | M3 default |

  - Group fields with section comments: `// Primary`, `// Secondary`, `// Tertiary`, `// Error`, `// Surface`, `// Surface containers`, `// Outline`, `// Inverse`, `// Misc` — for readability.
  - Use blank lines between groups.
  - Add `///` dartdoc on each `const` declaration explaining what it is and where the values come from.
  - Add a `///` comment on `surfaceBright` and `surfaceDim` explicitly noting "Not in HTML source — derived from adjacent container tone per `research.md`."

- Create `test/core/theme/app_color_schemes_test.dart`:
  - `import 'package:flutter/material.dart';` and `package:flutter_test/flutter_test.dart`
  - `import 'package:dosly/core/theme/app_color_schemes.dart';`
  - `void main() { group('lightColorScheme', () { ... }); group('darkColorScheme', () { ... }); }`
  - One `test('<role> matches HTML source', () { expect(lightColorScheme.<role>, const Color(0x<hex>)); });` per role per scheme. About 60 expectations total.
  - Also assert `lightColorScheme.brightness == Brightness.light` and `darkColorScheme.brightness == Brightness.dark`.

## Done when

- [x] `lib/core/theme/app_color_schemes.dart` exists and exports `const ColorScheme lightColorScheme` and `const ColorScheme darkColorScheme`
- [x] Every field listed in the two tables above is assigned the exact hex value
- [x] `test/core/theme/app_color_schemes_test.dart` exists with expectations for every role in both schemes
- [x] `dart analyze` is clean
- [x] `flutter test test/core/theme/app_color_schemes_test.dart` passes (70/70)

## Spec criteria addressed

AC-1, AC-2, AC-3, AC-12 (this test file's portion), AC-14 (the canonical home for color literals)

## Completion Notes

**Status**: Complete
**Completed**: 2026-04-11
**Files changed**:
- `lib/core/theme/app_color_schemes.dart` (created — 141 lines, two `const ColorScheme` literals)
- `test/core/theme/app_color_schemes_test.dart` (created — 70 expectations: 35 per scheme)

**Contract**: Expects 2/2 verified | Produces 6/6 verified

**Notes**:
- `onInverseSurface` is the correct modern Flutter field name (NOT `inverseOnSurface`).
- `surfaceBright` and `surfaceDim` accepted by Flutter SDK ^3.11.1's `ColorScheme` constructor — derivation per research.md (light: bright=containerLow, dim=containerHighest; dark: bright=containerHigh, dim=containerLowest).
- HTML's deprecated `--md-surface-variant` correctly dropped (Flutter removed the field; replaced by `surfaceContainerHighest` which has its own value from the HTML).
- Added `library;` directive at top of source file to attach file-level dartdoc — Dart 3 idiom, no behavioral effect.
- All 70 tests pass on first run. No self-repair required.
- Code review verdict: APPROVE (zero issues, hex values spot-checked against HTML source).

## Contracts

### Expects
- `lib/core/` directory may not exist yet — task creates it
- `package:flutter/material.dart` is available (built into Flutter)

### Produces
- File `lib/core/theme/app_color_schemes.dart` exists
- It contains a top-level declaration `const ColorScheme lightColorScheme = ColorScheme(`
- It contains a top-level declaration `const ColorScheme darkColorScheme = ColorScheme(`
- The literal string `Color(0xFF2E7D32)` (light primary) appears in the file
- The literal string `Color(0xFF8BD988)` (dark primary) appears in the file
- File `test/core/theme/app_color_schemes_test.dart` exists and imports `package:dosly/core/theme/app_color_schemes.dart`
