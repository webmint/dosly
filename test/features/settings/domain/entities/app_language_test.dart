import 'package:flutter_test/flutter_test.dart';

import 'package:dosly/features/settings/domain/entities/app_language.dart';

void main() {
  group('fromLanguageCodeOrDefault', () {
    test("resolves 'en' to AppLanguage.en", () {
      expect(AppLanguage.fromLanguageCodeOrDefault('en'), AppLanguage.en);
    });

    test("resolves 'de' to AppLanguage.de", () {
      expect(AppLanguage.fromLanguageCodeOrDefault('de'), AppLanguage.de);
    });

    test("resolves 'uk' to AppLanguage.uk", () {
      expect(AppLanguage.fromLanguageCodeOrDefault('uk'), AppLanguage.uk);
    });

    test("falls back to AppLanguage.en for unknown code 'xx'", () {
      expect(AppLanguage.fromLanguageCodeOrDefault('xx'), AppLanguage.en);
    });

    test('falls back to AppLanguage.en for empty string', () {
      expect(AppLanguage.fromLanguageCodeOrDefault(''), AppLanguage.en);
    });
  });
}
