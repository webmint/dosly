# Task 003: Create app_text_theme.dart with Roboto-based M3 type scale

**Agent**: mobile-engineer
**Files**:
- `lib/core/theme/app_text_theme.dart` *(create)*

**Depends on**: 001 (Roboto family must be declared in `pubspec.yaml`)
**Blocks**: 005 (AppTheme builds ThemeData with this textTheme)
**Review checkpoint**: No
**Context docs**: None

## Description

Define `AppTextTheme.textTheme` — a `const TextTheme` configured with Roboto across all 15 M3 type scale roles (`displayLarge`, `displayMedium`, `displaySmall`, `headlineLarge`, `headlineMedium`, `headlineSmall`, `titleLarge`, `titleMedium`, `titleSmall`, `bodyLarge`, `bodyMedium`, `bodySmall`, `labelLarge`, `labelMedium`, `labelSmall`). Each `TextStyle` sets `fontFamily: 'Roboto'` and the canonical M3 size/weight/line-height/letter-spacing values.

This file is small but important — every text-rendering widget downstream picks up these styles via `Theme.of(context).textTheme.xxx`.

## Change details

- Create `lib/core/theme/app_text_theme.dart`:
  - Header dartdoc explaining: provides Material 3 type scale using bundled Roboto font.
  - `import 'package:flutter/material.dart';`
  - Class `AppTextTheme` with private constructor (`const AppTextTheme._()`) — utility class, not instantiable.
  - Static `const String fontFamily = 'Roboto';`
  - Static `const TextTheme textTheme = TextTheme(...)` with all 15 fields. Use the official M3 type scale values:

    | Role | Size | Weight | LineHeight | LetterSpacing |
    |---|---|---|---|---|
    | `displayLarge` | 57 | w400 | 64 | -0.25 |
    | `displayMedium` | 45 | w400 | 52 | 0.0 |
    | `displaySmall` | 36 | w400 | 44 | 0.0 |
    | `headlineLarge` | 32 | w400 | 40 | 0.0 |
    | `headlineMedium` | 28 | w400 | 36 | 0.0 |
    | `headlineSmall` | 24 | w400 | 32 | 0.0 |
    | `titleLarge` | 22 | w500 | 28 | 0.0 |
    | `titleMedium` | 16 | w500 | 24 | 0.15 |
    | `titleSmall` | 14 | w500 | 20 | 0.1 |
    | `bodyLarge` | 16 | w400 | 24 | 0.5 |
    | `bodyMedium` | 14 | w400 | 20 | 0.25 |
    | `bodySmall` | 12 | w400 | 16 | 0.4 |
    | `labelLarge` | 14 | w500 | 20 | 0.1 |
    | `labelMedium` | 12 | w500 | 16 | 0.5 |
    | `labelSmall` | 11 | w500 | 16 | 0.5 |

  - Each TextStyle: `TextStyle(fontFamily: fontFamily, fontSize: X, fontWeight: FontWeight.wY, height: Z / X, letterSpacing: W)` (height in TextStyle is a multiplier, so divide line-height by font-size).
  - Use `const` constructors throughout. The whole class should compile to compile-time constants.
  - Add `///` dartdoc on `textTheme`: "Material 3 type scale using bundled Roboto font (weights 300/400/500/700)."

## Done when

- [x] `lib/core/theme/app_text_theme.dart` exists
- [x] `AppTextTheme.textTheme` is `const` and contains all 15 M3 type scale fields
- [x] Every `TextStyle` has `fontFamily: 'Roboto'`
- [x] `dart analyze` is clean (no missing-const warnings, no unused-import warnings)

## Spec criteria addressed

AC-4 (partial — text theme is a component of AppTheme.lightTheme/darkTheme), AC-9 (typography samples in preview screen need this)

## Completion Notes

**Status**: Complete
**Completed**: 2026-04-11
**Files changed**: `lib/core/theme/app_text_theme.dart` (created)
**Contract**: Expects 2/2 verified | Produces 5/5 verified
**Notes**: Mechanical M3 type scale transcription. All 15 styles wired with canonical sizes/weights/line-heights/letter-spacings. Heights expressed as `lineHeight / fontSize` per Flutter convention. Zero deviations. Code review skipped (pure data, matches spec literally, no design decisions to review).

## Contracts

### Expects
- `pubspec.yaml` declares `family: Roboto` under `flutter.fonts` (produced by Task 001)
- `lib/core/theme/` directory exists (produced by Task 002, OR created here if Task 002 hasn't run yet — both safe)

### Produces
- File `lib/core/theme/app_text_theme.dart` exists
- It contains the literal string `class AppTextTheme`
- It contains the literal string `static const TextTheme textTheme`
- It contains the literal string `fontFamily: 'Roboto'` (or `fontFamily: fontFamily` referencing the static const)
- It declares all 15 M3 type scale fields: `displayLarge`, `displayMedium`, `displaySmall`, `headlineLarge`, `headlineMedium`, `headlineSmall`, `titleLarge`, `titleMedium`, `titleSmall`, `bodyLarge`, `bodyMedium`, `bodySmall`, `labelLarge`, `labelMedium`, `labelSmall`
