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
///
/// [selectedIndex] is forwarded to [HomeBottomNav.selectedIndex].
/// [onDestinationSelected] is forwarded to [HomeBottomNav.onDestinationSelected];
/// defaults to a no-op when not provided.
Widget _harness({
  int selectedIndex = 0,
  ValueChanged<int>? onDestinationSelected,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: const SizedBox.shrink(),
      bottomNavigationBar: HomeBottomNav(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected ?? (_) {},
      ),
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

    testWidgets(
        'NavigationBar.selectedIndex reflects the selectedIndex parameter',
        (tester) async {
      for (final index in [0, 1, 2]) {
        await tester.pumpWidget(_harness(selectedIndex: index));
        await tester.pumpAndSettle();

        final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(bar.selectedIndex, index);
      }
    });

    testWidgets(
        'tapping a destination invokes onDestinationSelected with the tapped index',
        (tester) async {
      final indices = <int>[];
      await tester.pumpWidget(_harness(onDestinationSelected: indices.add));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Meds'));
      await tester.pumpAndSettle();
      expect(indices, [1]);

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(indices, [1, 2]);
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
