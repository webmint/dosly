import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dosly/core/theme/theme_controller.dart';

void main() {
  group('ThemeController', () {
    test('default value is ThemeMode.system', () {
      final controller = ThemeController();
      expect(controller.value, ThemeMode.system);
    });

    test('setMode updates value', () {
      final controller = ThemeController();
      controller.setMode(ThemeMode.dark);
      expect(controller.value, ThemeMode.dark);
    });

    test('setMode notifies listeners', () {
      final controller = ThemeController();
      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.setMode(ThemeMode.dark);

      expect(notifyCount, 1);
    });

    test('cycle advances system → light', () {
      final controller = ThemeController();
      controller.cycle();
      expect(controller.value, ThemeMode.light);
    });

    test('cycle advances light → dark', () {
      final controller = ThemeController();
      controller.setMode(ThemeMode.light);
      controller.cycle();
      expect(controller.value, ThemeMode.dark);
    });

    test('cycle advances dark → system', () {
      final controller = ThemeController();
      controller.setMode(ThemeMode.dark);
      controller.cycle();
      expect(controller.value, ThemeMode.system);
    });

    test('three cycles return to start', () {
      final controller = ThemeController();
      controller.cycle();
      controller.cycle();
      controller.cycle();
      expect(controller.value, ThemeMode.system);
    });
  });
}
