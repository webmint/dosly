import 'package:dosly/features/home/presentation/widgets/home_bottom_nav.dart';
import 'package:dosly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Builds the minimal widget harness used across all test cases.
///
/// Wraps [HomeBottomNav] in a [MaterialApp] + [Scaffold] so the widget has
/// the ambient `Directionality`, `MediaQuery`, and `Theme` it needs to
/// render a Material 3 [NavigationBar].
Widget _harness() {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const Scaffold(
      body: SizedBox.shrink(),
      bottomNavigationBar: HomeBottomNav(),
    ),
  );
}

void main() {
  group('HomeBottomNav', () {
    testWidgets(
      'renders exactly 3 NavigationDestinations with Today/Meds/History '
      'labels in order',
      (tester) async {
        await tester.pumpWidget(_harness());
        await tester.pumpAndSettle();

        expect(find.byType(NavigationDestination), findsNWidgets(3));
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('Meds'), findsOneWidget);
        expect(find.text('History'), findsOneWidget);
      },
    );

    testWidgets('renders the correct Lucide icons for each destination',
        (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.house), findsOneWidget);
      expect(find.byIcon(LucideIcons.pill), findsOneWidget);
      expect(find.byIcon(LucideIcons.activity), findsOneWidget);
    });

    testWidgets('NavigationBar.selectedIndex is 0 on first render',
        (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.selectedIndex, 0);
    });

    testWidgets('tapping an inactive destination does not change selectedIndex',
        (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Meds'));
      await tester.pumpAndSettle();

      var bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.selectedIndex, 0);

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.selectedIndex, 0);
    });

    testWidgets('labelBehavior is alwaysShow', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.labelBehavior, NavigationDestinationLabelBehavior.alwaysShow);
    });

    testWidgets('renders a 1-px top divider above the NavigationBar',
        (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      final dividers = tester.widgetList<Divider>(
        find.descendant(
          of: find.byType(HomeBottomNav),
          matching: find.byType(Divider),
        ),
      );
      expect(
        dividers.any((d) => d.height == 1 && d.thickness == 1),
        isTrue,
      );
    });
  });
}
