import 'package:dosly/features/settings/domain/entities/app_settings.dart';
import 'package:dosly/features/settings/domain/repositories/settings_repository.dart';
import 'package:dosly/features/settings/presentation/providers/settings_provider.dart';
import 'package:dosly/features/settings/presentation/screens/settings_screen.dart';
import 'package:dosly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

/// Minimal fake that satisfies [SettingsRepository] for widget tests.
class _FakeSettingsRepository implements SettingsRepository {
  @override
  AppSettings load() => const AppSettings();

  @override
  Future<Either<Never, void>> saveThemeMode(ThemeMode mode) async =>
      const Right(null);

  @override
  Future<Either<Never, void>> saveUseSystemTheme(bool value) async =>
      const Right(null);
}

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

/// Builds a widget tree wrapping [SettingsScreen] under the requested [locale].
///
/// Registers the full `AppLocalizations` delegate chain plus the project's
/// English-fallback `localeResolutionCallback`, so unsupported locales
/// resolve to English (matching production behaviour).
Widget _harness({required Locale locale}) {
  return ProviderScope(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(_FakeSettingsRepository()),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: _resolveLocale,
      home: const SettingsScreen(),
    ),
  );
}

void main() {
  group('SettingsScreen locale switching', () {
    testWidgets('renders "Settings" under Locale("en")', (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('renders "Einstellungen" under Locale("de")', (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('de')));
      await tester.pumpAndSettle();

      expect(find.text('Einstellungen'), findsOneWidget);
    });

    testWidgets('renders "Налаштування" under Locale("uk")', (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('uk')));
      await tester.pumpAndSettle();

      expect(find.text('Налаштування'), findsOneWidget);
    });

    testWidgets('falls back to "Settings" for unsupported Locale("fr")',
        (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('fr')));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });
  });

  group('SettingsScreen appearance header', () {
    testWidgets('renders uppercased "APPEARANCE" header under Locale("en")',
        (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('APPEARANCE'), findsOneWidget);
    });

    testWidgets(
        'renders uppercased "ЗОВНІШНІЙ ВИГЛЯД" header under Locale("uk")',
        (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('uk')));
      await tester.pumpAndSettle();

      expect(find.text('ЗОВНІШНІЙ ВИГЛЯД'), findsOneWidget);
    });

    testWidgets('renders uppercased "DARSTELLUNG" header under Locale("de")',
        (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('de')));
      await tester.pumpAndSettle();

      expect(find.text('DARSTELLUNG'), findsOneWidget);
    });
  });

  group('SettingsScreen AppBar shape', () {
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
