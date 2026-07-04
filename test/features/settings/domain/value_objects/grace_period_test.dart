library;

import 'package:dosly/features/settings/domain/value_objects/grace_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GracePeriod', () {
    test('should pass an in-range value through unchanged', () {
      expect(GracePeriod(10).minutes, 10);
    });

    group('clamping below minMinutes', () {
      test('should clamp a negative value up to minMinutes', () {
        expect(GracePeriod(-1).minutes, 0);
      });
    });

    group('clamping above maxMinutes', () {
      test('should clamp a value above maxMinutes down to maxMinutes', () {
        expect(GracePeriod(99).minutes, 30);
      });
    });

    group('boundary values', () {
      test('should pass minMinutes (0) through unchanged', () {
        expect(GracePeriod(0).minutes, 0);
      });

      test('should pass maxMinutes (30) through unchanged', () {
        expect(GracePeriod(30).minutes, 30);
      });
    });

    test('defaultValue should be 5 minutes', () {
      expect(GracePeriod.defaultValue.minutes, 5);
    });

    test('minMinutes and maxMinutes constants should have expected values', () {
      expect(GracePeriod.minMinutes, 0);
      expect(GracePeriod.maxMinutes, 30);
    });

    group('value equality', () {
      test('should be equal and share hashCode when minutes are equal', () {
        final a = GracePeriod(10);
        final b = GracePeriod(10);

        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('should not be equal when minutes differ', () {
        final a = GracePeriod(10);
        final b = GracePeriod(15);

        expect(a == b, isFalse);
      });

      test('defaultValue should equal GracePeriod(5)', () {
        expect(GracePeriod.defaultValue, GracePeriod(5));
      });
    });
  });
}
