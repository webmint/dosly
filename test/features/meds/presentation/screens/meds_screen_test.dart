import 'package:dosly/features/meds/presentation/screens/meds_screen.dart';
import 'package:dosly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
