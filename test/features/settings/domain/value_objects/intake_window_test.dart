library;

import 'package:dosly/features/settings/domain/value_objects/intake_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IntakeWindow', () {
    test('should pass an in-range value through unchanged', () {
      expect(IntakeWindow(90).minutes, 90);
    });

    group('clamping below minMinutes', () {
      test('should clamp a value below minMinutes up to minMinutes', () {
        expect(IntakeWindow(10).minutes, 15);
      });

      test('should clamp zero up to minMinutes', () {
        expect(IntakeWindow(0).minutes, 15);
      });

      test('should clamp a negative value up to minMinutes', () {
        expect(IntakeWindow(-50).minutes, 15);
      });
    });

    group('clamping above maxMinutes', () {
      test('should clamp a value above maxMinutes down to maxMinutes', () {
        expect(IntakeWindow(500).minutes, 240);
      });
    });

    group('boundary values', () {
      test('should pass minMinutes through unchanged', () {
        expect(IntakeWindow(15).minutes, 15);
      });

      test('should pass maxMinutes through unchanged', () {
        expect(IntakeWindow(240).minutes, 240);
      });
    });

    test('defaultValue should be 120 minutes', () {
      expect(IntakeWindow.defaultValue.minutes, 120);
    });

    test('minMinutes and maxMinutes constants should have expected values', () {
      expect(IntakeWindow.minMinutes, 15);
      expect(IntakeWindow.maxMinutes, 240);
    });

    group('value equality', () {
      test('should be equal and share hashCode when minutes are equal', () {
        final a = IntakeWindow(90);
        final b = IntakeWindow(90);

        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('should not be equal when minutes differ', () {
        final a = IntakeWindow(90);
        final b = IntakeWindow(100);

        expect(a == b, isFalse);
      });

      test('defaultValue should equal IntakeWindow(120)', () {
        expect(IntakeWindow.defaultValue, IntakeWindow(120));
      });
    });
  });
}
