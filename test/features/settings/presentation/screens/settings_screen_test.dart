import 'package:dosly/core/error/failures.dart';
import 'package:dosly/core/l10n/locale_resolver.dart';
import 'package:dosly/features/settings/domain/entities/app_language.dart';
import 'package:dosly/features/settings/domain/entities/app_settings.dart';
import 'package:dosly/features/settings/domain/entities/app_theme_mode.dart';
import 'package:dosly/features/settings/domain/repositories/settings_repository.dart';
import 'package:dosly/features/settings/presentation/providers/settings_provider.dart';
import 'package:dosly/features/settings/presentation/screens/settings_screen.dart';
import 'package:dosly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

/// Fake [SettingsRepository] for screen widget tests.
///
/// Holds in-memory [AppSettings] and exposes per-method [failOnSaveX]
/// flags to simulate persistence failures.
class _FakeSettingsRepository implements SettingsRepository {
  AppSettings _settings = const AppSettings();

  bool failOnSaveThemeMode = false;
  bool failOnSaveUseSystemTheme = false;
  bool failOnSaveUseSystemLanguage = false;
  bool failOnSaveManualLanguage = false;

  @override
  Either<Failure, AppSettings> load() => Right(_settings);

  @override
  Future<Either<Failure, void>> saveThemeMode(AppThemeMode mode) async {
    if (failOnSaveThemeMode) {
      return Left(Failure.unknown(Exception('mock failure'), StackTrace.empty));
    }
    _settings = _settings.copyWith(manualThemeMode: mode);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> saveUseSystemTheme(bool value) async {
    if (failOnSaveUseSystemTheme) {
      return Left(Failure.unknown(Exception('mock failure'), StackTrace.empty));
    }
    _settings = _settings.copyWith(useSystemTheme: value);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> saveUseSystemLanguage(bool value) async {
    if (failOnSaveUseSystemLanguage) {
      return Left(Failure.unknown(Exception('mock failure'), StackTrace.empty));
    }
    _settings = _settings.copyWith(useSystemLanguage: value);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> saveManualLanguage(AppLanguage language) async {
    if (failOnSaveManualLanguage) {
      return Left(Failure.unknown(Exception('mock failure'), StackTrace.empty));
    }
    _settings = _settings.copyWith(manualLanguage: language);
    return const Right(null);
  }
}

/// Builds a widget tree wrapping [SettingsScreen] under the requested [locale].
///
/// Registers the full `AppLocalizations` delegate chain plus the project's
/// English-fallback `localeResolutionCallback`, so unsupported locales
/// resolve to English (matching production behaviour).
///
/// An optional [fakeRepo] can be supplied to override the default always-success
/// fake — used by error-SnackBar tests to inject per-method failure flags.
Widget _harness({
  required Locale locale,
  _FakeSettingsRepository? fakeRepo,
}) {
  final repo = fakeRepo ?? _FakeSettingsRepository();
  return ProviderScope(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveAppLocale,
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

  group('SettingsScreen language header', () {
    testWidgets('renders uppercased "LANGUAGE" header under Locale("en")',
        (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('LANGUAGE'), findsOneWidget);
    });

    testWidgets('renders uppercased "МОВА" header under Locale("uk")',
        (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('uk')));
      await tester.pumpAndSettle();

      expect(find.text('МОВА'), findsOneWidget);
    });

    testWidgets('renders uppercased "SPRACHE" header under Locale("de")',
        (tester) async {
      await tester.pumpWidget(_harness(locale: const Locale('de')));
      await tester.pumpAndSettle();

      expect(find.text('SPRACHE'), findsOneWidget);
    });
  });

  group('SettingsScreen error SnackBar', () {
    testWidgets(
        'shows localized error SnackBar when setUseSystemTheme fails',
        (tester) async {
      final fakeRepo = _FakeSettingsRepository()
        ..failOnSaveUseSystemTheme = true;
      await tester.pumpWidget(
        _harness(locale: const Locale('en'), fakeRepo: fakeRepo),
      );
      await tester.pumpAndSettle();

      // Tap the "Use system theme" SwitchListTile to trigger setUseSystemTheme.
      await tester.tap(find.byType(SwitchListTile).first);
      await tester.pump(); // mutator runs
      await tester.pump(const Duration(milliseconds: 100)); // SnackBar enters

      expect(
        find.text("Couldn't save your preference. Please try again."),
        findsOneWidget,
      );
    });
  });
}
