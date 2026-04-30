import 'package:dosly/features/meds/presentation/screens/meds_screen.dart';
import 'package:dosly/features/meds/presentation/widgets/add_medication_modal.dart';
import 'package:dosly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Resolves the active [Locale] for the harness [MaterialApp].
///
/// Mirrors the production resolution policy in `lib/app.dart`: match by
/// `languageCode`, else fall back to English. Declared as a top-level
/// function so tests exercise the same fallback behaviour the running app
/// uses, not Flutter's default (which would fall back to the first entry
/// of `supportedLocales` — currently German — and quietly mask regressions).
Locale _resolveLocale(Locale? deviceLocale, Iterable<Locale> supportedLocales) {
  if (deviceLocale != null) {
    for (final supported in supportedLocales) {
      if (supported.languageCode == deviceLocale.languageCode) {
        return supported;
      }
    }
  }
  return const Locale('en');
}

/// Builds a widget tree wrapping [MedsScreen] under the requested [locale].
///
/// Registers the full `AppLocalizations` delegate chain plus the project's
/// English-fallback `localeResolutionCallback`, so unsupported locales
/// resolve to English (matching production behaviour).
Widget _harness({required Locale locale}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    localeResolutionCallback: _resolveLocale,
    home: const MedsScreen(),
  );
}

void main() {
  group('MedsScreen locale switching', () {
    testWidgets('renders "Meds" under Locale("en")', (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Meds'), findsOneWidget);
    });

    testWidgets('renders "Medikamente" under Locale("de")', (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('de')));
      await tester.pumpAndSettle();

      expect(find.text('Medikamente'), findsOneWidget);
    });

    testWidgets('renders "Ліки" under Locale("uk")', (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('uk')));
      await tester.pumpAndSettle();

      expect(find.text('Ліки'), findsOneWidget);
    });

    testWidgets('falls back to "Meds" for unsupported Locale("fr")',
        (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('fr')));
      await tester.pumpAndSettle();

      expect(find.text('Meds'), findsOneWidget);
    });
  });

  group('MedsScreen AppBar shape', () {
    testWidgets('AppBar has no actions', (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(
        tester.widget<AppBar>(find.byType(AppBar)).actions,
        anyOf(isNull, isEmpty),
      );
    });

    testWidgets('1-px Divider is a descendant of the AppBar', (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('en')));
      await tester.pumpAndSettle();

      final appBarFinder = find.byType(AppBar);
      final dividerFinder = find.descendant(
        of: appBarFinder,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Divider &&
              widget.height == 1 &&
              widget.thickness == 1,
        ),
      );

      expect(dividerFinder, findsOneWidget);
    });
  });

  group('MedsScreen FAB', () {
    testWidgets('renders a FloatingActionButton', (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('FAB child is the Lucide plus icon', (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('en')));
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(
        find.descendant(
          of: find.byType(FloatingActionButton),
          matching: find.byType(Icon),
        ),
      );

      expect(icon.icon, LucideIcons.plus);
    });

    testWidgets('FAB tooltip equals localized medsAddFabTooltip in en',
        (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('en')));
      await tester.pumpAndSettle();

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );

      expect(fab.tooltip, 'Add medication');
    });

    testWidgets('FAB tooltip equals localized medsAddFabTooltip in de',
        (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('de')));
      await tester.pumpAndSettle();

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );

      expect(fab.tooltip, 'Medikament hinzufügen');
    });

    testWidgets('FAB tooltip equals localized medsAddFabTooltip in uk',
        (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('uk')));
      await tester.pumpAndSettle();

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );

      expect(fab.tooltip, 'Додати ліки');
    });
  });

  group('MedsScreen Add-medication modal', () {
    testWidgets(
        'tapping the FAB opens AddMedicationModal showing the localized title (en)',
        (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('en')));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(AddMedicationModal), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AddMedicationModal),
          matching: find.text('Add medication'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('back-arrow IconButton dismisses the modal', (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('en')));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(AddMedicationModal), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(AddMedicationModal),
          matching: find.byType(IconButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AddMedicationModal), findsNothing);
    });
  });
}
