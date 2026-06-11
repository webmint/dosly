import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dosly/core/l10n/locale_resolver.dart';

void main() {
  // The supported list intentionally starts with 'de' (matching the
  // alphabetical order gen_l10n emits) so every test below proves that
  // the function's English-pin is independent of list ordering.
  const supported = [Locale('de'), Locale('en'), Locale('uk')];

  group('resolveAppLocale', () {
    test('should return English when device locale is null', () {
      final result = resolveAppLocale(null, supported);
      expect(result, const Locale('en'));
    });

    test(
      'should return the matching supported locale when device locale is supported',
      () {
        final result = resolveAppLocale(const Locale('uk'), supported);
        expect(result, const Locale('uk'));
      },
    );

    test(
      'should return English when device locale is unsupported — NOT the first entry (de)',
      () {
        // Key regression guard: Flutter's default resolver would return Locale('de')
        // because it is first in the list; resolveAppLocale must pin English instead.
        final result = resolveAppLocale(const Locale('fr'), supported);
        expect(result, const Locale('en'));
      },
    );

    test('should match by languageCode only — country code is ignored', () {
      final result = resolveAppLocale(const Locale('en', 'US'), supported);
      expect(result, const Locale('en'));
    });
  });
}
