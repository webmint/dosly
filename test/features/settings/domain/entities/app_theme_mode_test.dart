import 'package:flutter_test/flutter_test.dart';

import 'package:dosly/features/settings/domain/entities/app_theme_mode.dart';

void main() {
  group('AppThemeMode.fromCodeOrDefault', () {
    test('resolves "light" to AppThemeMode.light', () {
      expect(AppThemeMode.fromCodeOrDefault('light'), AppThemeMode.light);
    });

    test('resolves "dark" to AppThemeMode.dark', () {
      expect(AppThemeMode.fromCodeOrDefault('dark'), AppThemeMode.dark);
    });

    test('falls back to light when code is null', () {
      expect(AppThemeMode.fromCodeOrDefault(null), AppThemeMode.light);
    });

    test('falls back to light when code is empty string', () {
      expect(AppThemeMode.fromCodeOrDefault(''), AppThemeMode.light);
    });

    test('falls back to light when code is unknown', () {
      expect(
        AppThemeMode.fromCodeOrDefault('unknown'),
        AppThemeMode.light,
      );
    });
  });

  group('AppThemeMode cardinality', () {
    test('has exactly 2 values (light, dark) — system stays in useSystemTheme bool', () {
      expect(AppThemeMode.values.length, 2);
      expect(
        AppThemeMode.values,
        containsAll([AppThemeMode.light, AppThemeMode.dark]),
      );
    });
  });
}
