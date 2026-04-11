import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dosly/core/theme/app_color_schemes.dart';

void main() {
  group('lightColorScheme', () {
    test('brightness is light', () {
      expect(lightColorScheme.brightness, Brightness.light);
    });

    // Primary
    test('primary matches HTML', () => expect(lightColorScheme.primary, const Color(0xFF2E7D32)));
    test('onPrimary matches HTML', () => expect(lightColorScheme.onPrimary, const Color(0xFFFFFFFF)));
    test('primaryContainer matches HTML', () => expect(lightColorScheme.primaryContainer, const Color(0xFFB7F0B1)));
    test('onPrimaryContainer matches HTML', () => expect(lightColorScheme.onPrimaryContainer, const Color(0xFF002204)));

    // Secondary
    test('secondary matches HTML', () => expect(lightColorScheme.secondary, const Color(0xFF52634F)));
    test('onSecondary matches HTML', () => expect(lightColorScheme.onSecondary, const Color(0xFFFFFFFF)));
    test('secondaryContainer matches HTML', () => expect(lightColorScheme.secondaryContainer, const Color(0xFFD5E8CF)));
    test('onSecondaryContainer matches HTML', () => expect(lightColorScheme.onSecondaryContainer, const Color(0xFF101F0F)));

    // Tertiary
    test('tertiary matches HTML', () => expect(lightColorScheme.tertiary, const Color(0xFF38656A)));
    test('onTertiary matches HTML', () => expect(lightColorScheme.onTertiary, const Color(0xFFFFFFFF)));
    test('tertiaryContainer matches HTML', () => expect(lightColorScheme.tertiaryContainer, const Color(0xFFBCEBF0)));
    test('onTertiaryContainer matches HTML', () => expect(lightColorScheme.onTertiaryContainer, const Color(0xFF002023)));

    // Error
    test('error matches HTML', () => expect(lightColorScheme.error, const Color(0xFFBA1A1A)));
    test('onError matches HTML', () => expect(lightColorScheme.onError, const Color(0xFFFFFFFF)));
    test('errorContainer matches HTML', () => expect(lightColorScheme.errorContainer, const Color(0xFFFFDAD6)));
    test('onErrorContainer matches HTML', () => expect(lightColorScheme.onErrorContainer, const Color(0xFF410002)));

    // Surface
    test('surface matches HTML', () => expect(lightColorScheme.surface, const Color(0xFFF6FBF3)));
    test('onSurface matches HTML', () => expect(lightColorScheme.onSurface, const Color(0xFF191C18)));
    test('onSurfaceVariant matches HTML', () => expect(lightColorScheme.onSurfaceVariant, const Color(0xFF404942)));

    // Surface containers
    test('surfaceContainerLowest matches HTML', () => expect(lightColorScheme.surfaceContainerLowest, const Color(0xFFFFFFFF)));
    test('surfaceContainerLow matches HTML', () => expect(lightColorScheme.surfaceContainerLow, const Color(0xFFF0F5ED)));
    test('surfaceContainer matches HTML', () => expect(lightColorScheme.surfaceContainer, const Color(0xFFEAF0E7)));
    test('surfaceContainerHigh matches HTML', () => expect(lightColorScheme.surfaceContainerHigh, const Color(0xFFE4EAE1)));
    test('surfaceContainerHighest matches HTML', () => expect(lightColorScheme.surfaceContainerHighest, const Color(0xFFDFE4DC)));
    test('surfaceBright is derived', () => expect(lightColorScheme.surfaceBright, const Color(0xFFF0F5ED)));
    test('surfaceDim is derived', () => expect(lightColorScheme.surfaceDim, const Color(0xFFDFE4DC)));

    // Outline
    test('outline matches HTML', () => expect(lightColorScheme.outline, const Color(0xFF70796E)));
    test('outlineVariant matches HTML', () => expect(lightColorScheme.outlineVariant, const Color(0xFFC0C9BB)));

    // Inverse
    test('inverseSurface matches HTML', () => expect(lightColorScheme.inverseSurface, const Color(0xFF2E312D)));
    test('onInverseSurface matches HTML', () => expect(lightColorScheme.onInverseSurface, const Color(0xFFEFF2EC)));
    test('inversePrimary matches HTML', () => expect(lightColorScheme.inversePrimary, const Color(0xFF8BD988)));

    // Misc
    test('surfaceTint equals primary', () => expect(lightColorScheme.surfaceTint, const Color(0xFF2E7D32)));
    test('shadow is black', () => expect(lightColorScheme.shadow, const Color(0xFF000000)));
    test('scrim is black', () => expect(lightColorScheme.scrim, const Color(0xFF000000)));
  });

  group('darkColorScheme', () {
    test('brightness is dark', () {
      expect(darkColorScheme.brightness, Brightness.dark);
    });

    // Primary
    test('primary matches HTML', () => expect(darkColorScheme.primary, const Color(0xFF8BD988)));
    test('onPrimary matches HTML', () => expect(darkColorScheme.onPrimary, const Color(0xFF003A02)));
    test('primaryContainer matches HTML', () => expect(darkColorScheme.primaryContainer, const Color(0xFF0A5210)));
    test('onPrimaryContainer matches HTML', () => expect(darkColorScheme.onPrimaryContainer, const Color(0xFFA6F5A2)));

    // Secondary
    test('secondary matches HTML', () => expect(darkColorScheme.secondary, const Color(0xFFB9CCAF)));
    test('onSecondary matches HTML', () => expect(darkColorScheme.onSecondary, const Color(0xFF253422)));
    test('secondaryContainer matches HTML', () => expect(darkColorScheme.secondaryContainer, const Color(0xFF3B4B37)));
    test('onSecondaryContainer matches HTML', () => expect(darkColorScheme.onSecondaryContainer, const Color(0xFFD5E8CF)));

    // Tertiary
    test('tertiary matches HTML', () => expect(darkColorScheme.tertiary, const Color(0xFFA0CFD5)));
    test('onTertiary matches HTML', () => expect(darkColorScheme.onTertiary, const Color(0xFF00363B)));
    test('tertiaryContainer matches HTML', () => expect(darkColorScheme.tertiaryContainer, const Color(0xFF1F4D52)));
    test('onTertiaryContainer matches HTML', () => expect(darkColorScheme.onTertiaryContainer, const Color(0xFFBCEBF0)));

    // Error
    test('error matches HTML', () => expect(darkColorScheme.error, const Color(0xFFFFB4AB)));
    test('onError matches HTML', () => expect(darkColorScheme.onError, const Color(0xFF690005)));
    test('errorContainer matches HTML', () => expect(darkColorScheme.errorContainer, const Color(0xFF93000A)));
    test('onErrorContainer matches HTML', () => expect(darkColorScheme.onErrorContainer, const Color(0xFFFFDAD6)));

    // Surface
    test('surface matches HTML', () => expect(darkColorScheme.surface, const Color(0xFF101410)));
    test('onSurface matches HTML', () => expect(darkColorScheme.onSurface, const Color(0xFFDFE4DC)));
    test('onSurfaceVariant matches HTML', () => expect(darkColorScheme.onSurfaceVariant, const Color(0xFFBFC9BB)));

    // Surface containers
    test('surfaceContainerLowest matches HTML', () => expect(darkColorScheme.surfaceContainerLowest, const Color(0xFF0B0F0B)));
    test('surfaceContainerLow matches HTML', () => expect(darkColorScheme.surfaceContainerLow, const Color(0xFF191C18)));
    test('surfaceContainer matches HTML', () => expect(darkColorScheme.surfaceContainer, const Color(0xFF1D211C)));
    test('surfaceContainerHigh matches HTML', () => expect(darkColorScheme.surfaceContainerHigh, const Color(0xFF272B26)));
    test('surfaceContainerHighest matches HTML', () => expect(darkColorScheme.surfaceContainerHighest, const Color(0xFF323631)));
    test('surfaceBright is derived', () => expect(darkColorScheme.surfaceBright, const Color(0xFF272B26)));
    test('surfaceDim is derived', () => expect(darkColorScheme.surfaceDim, const Color(0xFF0B0F0B)));

    // Outline
    test('outline matches HTML', () => expect(darkColorScheme.outline, const Color(0xFF8A9388)));
    test('outlineVariant matches HTML', () => expect(darkColorScheme.outlineVariant, const Color(0xFF404942)));

    // Inverse
    test('inverseSurface matches HTML', () => expect(darkColorScheme.inverseSurface, const Color(0xFFDFE4DC)));
    test('onInverseSurface matches HTML', () => expect(darkColorScheme.onInverseSurface, const Color(0xFF2E312D)));
    test('inversePrimary matches HTML', () => expect(darkColorScheme.inversePrimary, const Color(0xFF1B6B1D)));

    // Misc
    test('surfaceTint equals primary', () => expect(darkColorScheme.surfaceTint, const Color(0xFF8BD988)));
    test('shadow is black', () => expect(darkColorScheme.shadow, const Color(0xFF000000)));
    test('scrim is black', () => expect(darkColorScheme.scrim, const Color(0xFF000000)));
  });
}
