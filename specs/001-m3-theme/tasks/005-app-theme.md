# Task 005: Create app_theme.dart with full ThemeData for both schemes

**Agent**: mobile-engineer
**Files**:
- `lib/core/theme/app_theme.dart` *(create)*

**Depends on**: 002 (color schemes), 003 (text theme)
**Blocks**: 008 (DoslyApp uses AppTheme.lightTheme/darkTheme)
**Review checkpoint**: No
**Context docs**: None

## Description

Build the two `ThemeData` instances that `MaterialApp` consumes. Each pulls in the matching `ColorScheme` from Task 002 and the `AppTextTheme.textTheme` from Task 003, then wires explicit component-level themes (`appBarTheme`, `cardTheme`, `filledButtonTheme`, etc.) so individual widgets render the M3 design out of the box without per-widget overrides downstream.

This is the largest single file in the spec (~120 lines) but mostly mechanical — each component theme is a `*ThemeData(...)` constructor call with `colorScheme.xxx` references.

## Change details

- Create `lib/core/theme/app_theme.dart`:
  - File header dartdoc: "Builds light and dark `ThemeData` for dosly. Composes `app_color_schemes.dart` and `app_text_theme.dart`. Component themes pre-wire Material 3 defaults so individual widgets don't need overrides."
  - `import 'package:flutter/material.dart';`
  - `import 'app_color_schemes.dart';`
  - `import 'app_text_theme.dart';`
  - Class `AppTheme` with private constructor (`AppTheme._()`).
  - Static getter `static ThemeData get lightTheme => _build(lightColorScheme);`
  - Static getter `static ThemeData get darkTheme => _build(darkColorScheme);`
  - Private static `ThemeData _build(ColorScheme scheme)` that returns:
    ```dart
    ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: AppTextTheme.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 3,
        centerTitle: false,
        titleTextStyle: AppTextTheme.textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        selectedItemColor: scheme.onSurface,
        unselectedItemColor: scheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
    ```
  - Notes for the implementer:
    - The method is NOT `const` because `ThemeData(...)` and the component themes use runtime constructors.
    - Border radii (8, 12, 20) are M3 sensible defaults — match the HTML's rounded shapes from `dosly_m3_template.html` lines 388, 405, 459 etc.
    - `AppBarTheme.scrolledUnderElevation: 3` enables the M3 surface tint when content scrolls under the app bar.
  - Add `///` dartdoc on `lightTheme` and `darkTheme` getters explaining what they contain.

## Done when

- [x] `lib/core/theme/app_theme.dart` exists with class `AppTheme` and getters `lightTheme` and `darkTheme`
- [x] Both getters return `ThemeData` with `useMaterial3: true` and the matching scheme
- [x] Every component theme listed in the change details is wired (appBar, card, filledButton, outlinedButton, textButton, chip, fab, inputDecoration, divider, bottomNavBar, iconTheme)
- [x] `dart analyze` is clean
- [x] `flutter test` continues to pass (78/78 across all files)

## Spec criteria addressed

AC-4

## Completion Notes

**Status**: Complete
**Completed**: 2026-04-11
**Files changed**: `lib/core/theme/app_theme.dart` (created)
**Contract**: Expects 3/3 verified | Produces 5/5 verified
**Notes**:
- Used `CardThemeData` (modern API) — accepted by Flutter SDK ^3.11.1 with no warning. No fallback to legacy `CardTheme` needed.
- All 11 component themes wired (appBar, card, filledButton, outlinedButton, textButton, chip, fab, inputDecoration, divider, bottomNav, iconTheme).
- Zero deviations from spec template.
- 78/78 tests still passing across the project.
- Code review skipped (mechanical, large but pure-config file matching spec verbatim).

## Contracts

### Expects
- `lib/core/theme/app_color_schemes.dart` exists and exports `lightColorScheme` and `darkColorScheme` (produced by Task 002)
- `lib/core/theme/app_text_theme.dart` exists and exports `AppTextTheme.textTheme` (produced by Task 003)
- `package:flutter/material.dart` is available

### Produces
- File `lib/core/theme/app_theme.dart` exists
- It declares `class AppTheme`
- It declares `static ThemeData get lightTheme`
- It declares `static ThemeData get darkTheme`
- Both getters reference `lightColorScheme` and `darkColorScheme` respectively (verifiable by grep for `lightColorScheme` and `darkColorScheme` in the file)
- The literal string `useMaterial3: true` appears in the file
