import 'package:dosly/features/home/presentation/widgets/home_bottom_nav.dart';
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

/// Builds a widget tree wrapping [HomeBottomNav] under the requested [locale].
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
    home: const Scaffold(
      body: SizedBox.shrink(),
      bottomNavigationBar: HomeBottomNav(),
    ),
  );
}

void main() {
  group('HomeBottomNav locale switching', () {
    testWidgets('renders German labels under Locale("de")', (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('de')));
      await tester.pumpAndSettle();

      expect(find.text('Heute'), findsOneWidget);
      expect(find.text('Medikamente'), findsOneWidget);
      expect(find.text('Verlauf'), findsOneWidget);
    });

    testWidgets('renders Ukrainian labels under Locale("uk")', (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('uk')));
      await tester.pumpAndSettle();

      expect(find.text('Сьогодні'), findsOneWidget);
      expect(find.text('Ліки'), findsOneWidget);
      expect(find.text('Історія'), findsOneWidget);
    });

    testWidgets('falls back to English for unsupported Locale("fr")',
        (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('fr')));
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Meds'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
    });
  });
}
