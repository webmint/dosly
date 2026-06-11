import 'package:dosly/core/l10n/locale_resolver.dart';
import 'package:dosly/core/routing/app_bottom_nav.dart';
import 'package:dosly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a widget tree wrapping [AppBottomNav] under the requested [locale].
///
/// Registers the full `AppLocalizations` delegate chain plus the project's
/// English-fallback `localeResolutionCallback`, so unsupported locales
/// resolve to English (matching production behaviour).
Widget _harness({required Locale locale}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    localeResolutionCallback: resolveAppLocale,
    home: Scaffold(
      body: const SizedBox.shrink(),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: 0,
        onDestinationSelected: (_) {},
      ),
    ),
  );
}

void main() {
  group('AppBottomNav locale switching', () {
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

    testWidgets('falls back to English for unsupported Locale("fr")', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(locale: const Locale('fr')));
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Meds'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
    });
  });
}
