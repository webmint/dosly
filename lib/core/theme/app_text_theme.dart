/// Material 3 type scale for dosly using bundled Roboto.
///
/// Declares all 15 M3 type scale styles. Composed into `ThemeData.textTheme`
/// by `AppTheme` (see `app_theme.dart`). Roboto is bundled as an asset
/// (Task 001) at weights 300, 400, 500, 700.
///
/// The `height` field is a multiplier of `fontSize` (Flutter convention),
/// so canonical M3 line-heights are expressed as `lineHeight / fontSize`.
library;

import 'package:flutter/material.dart';

/// Static utility class providing the dosly Material 3 [textTheme].
///
/// Not instantiable. Use the static `textTheme` getter directly.
class AppTextTheme {
  const AppTextTheme._();

  /// Bundled font family name (declared in `pubspec.yaml` under `flutter.fonts`).
  static const String fontFamily = 'Roboto';

  /// Material 3 type scale built on bundled Roboto.
  ///
  /// All 15 standard styles are defined. Sizes, weights, line-heights, and
  /// letter-spacings follow the canonical Material 3 type scale.
  static const TextTheme textTheme = TextTheme(
    // Display
    displayLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 57,
      fontWeight: FontWeight.w400,
      height: 64 / 57,
      letterSpacing: -0.25,
    ),
    displayMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 45,
      fontWeight: FontWeight.w400,
      height: 52 / 45,
      letterSpacing: 0,
    ),
    displaySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 36,
      fontWeight: FontWeight.w400,
      height: 44 / 36,
      letterSpacing: 0,
    ),

    // Headline
    headlineLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 32,
      fontWeight: FontWeight.w400,
      height: 40 / 32,
      letterSpacing: 0,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.w400,
      height: 36 / 28,
      letterSpacing: 0,
    ),
    headlineSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 24,
      fontWeight: FontWeight.w400,
      height: 32 / 24,
      letterSpacing: 0,
    ),

    // Title
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w500,
      height: 28 / 22,
      letterSpacing: 0,
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 24 / 16,
      letterSpacing: 0.15,
    ),
    titleSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 20 / 14,
      letterSpacing: 0.1,
    ),

    // Body
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 24 / 16,
      letterSpacing: 0.5,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 20 / 14,
      letterSpacing: 0.25,
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 16 / 12,
      letterSpacing: 0.4,
    ),

    // Label
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 20 / 14,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 16 / 12,
      letterSpacing: 0.5,
    ),
    labelSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 16 / 11,
      letterSpacing: 0.5,
    ),
  );
}
