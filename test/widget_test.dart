import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dosly/app.dart';
import 'package:dosly/core/theme/theme_controller.dart';

void main() {
  setUp(() {
    // Reset the singleton between tests so we don't carry state across.
    themeController.setMode(ThemeMode.system);
  });

  testWidgets('DoslyApp renders the theme preview screen', (tester) async {
    await tester.pumpWidget(const DoslyApp());
    await tester.pumpAndSettle();

    expect(find.text('dosly · M3 preview'), findsOneWidget);
  });

  testWidgets('cycling theme mode does not throw and updates state',
      (tester) async {
    await tester.pumpWidget(const DoslyApp());
    await tester.pumpAndSettle();

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
  });
}
