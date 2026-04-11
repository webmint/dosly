import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dosly/app.dart';
import 'package:dosly/core/theme/theme_controller.dart';

void main() {
  setUp(() {
    // Reset the singleton between tests so we don't carry state across.
    themeController.setMode(ThemeMode.system);
  });

  testWidgets(
    'DoslyApp renders the home screen with Hello World and a Theme preview button',
    (tester) async {
      await tester.pumpWidget(const DoslyApp());
      await tester.pumpAndSettle();

      expect(find.text('Hello World'), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, 'Theme preview'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'tapping Theme preview navigates to the preview and cycling theme mode works',
    (tester) async {
      await tester.pumpWidget(const DoslyApp());
      await tester.pumpAndSettle();

      // Navigate from HomeScreen → ThemePreviewScreen via the dev button.
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Theme preview'),
      );
      await tester.pumpAndSettle();

      // Confirm we arrived at the preview screen.
      expect(find.text('dosly · M3 preview'), findsOneWidget);
      expect(find.byTooltip('Cycle theme mode'), findsOneWidget);

      // Cycle once → light
      await tester.tap(find.byTooltip('Cycle theme mode'));
      await tester.pumpAndSettle();
      expect(themeController.value, ThemeMode.light);

      // Cycle again → dark
      await tester.tap(find.byTooltip('Cycle theme mode'));
      await tester.pumpAndSettle();
      expect(themeController.value, ThemeMode.dark);

      // Cycle again → system
      await tester.tap(find.byTooltip('Cycle theme mode'));
      await tester.pumpAndSettle();
      expect(themeController.value, ThemeMode.system);
    },
  );
}
