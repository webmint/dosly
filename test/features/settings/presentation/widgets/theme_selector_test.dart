library;

import 'package:dosly/features/settings/domain/entities/app_settings.dart';
import 'package:dosly/features/settings/domain/repositories/settings_repository.dart';
import 'package:dosly/features/settings/presentation/providers/settings_provider.dart';
import 'package:dosly/features/settings/presentation/widgets/theme_selector.dart';
import 'package:dosly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

/// Fake [SettingsRepository] that stores settings in memory.
class _FakeSettingsRepository implements SettingsRepository {
  AppSettings _settings;

  _FakeSettingsRepository({AppSettings? initial})
      : _settings = initial ?? const AppSettings();

  bool get savedUseSystemTheme => _settings.useSystemTheme;
  ThemeMode get savedManualThemeMode => _settings.manualThemeMode;

  @override
  AppSettings load() => _settings;

  @override
  Future<Either<Never, void>> saveThemeMode(ThemeMode mode) async {
    _settings = _settings.copyWith(manualThemeMode: mode);
    return const Right(null);
  }

  @override
  Future<Either<Never, void>> saveUseSystemTheme(bool value) async {
    _settings = _settings.copyWith(useSystemTheme: value);
    return const Right(null);
  }
}

/// Mirrors the production locale resolution policy.
Locale _resolveLocale(
  Locale? deviceLocale,
  Iterable<Locale> supportedLocales,
) {
  if (deviceLocale != null) {
    for (final supported in supportedLocales) {
      if (supported.languageCode == deviceLocale.languageCode) {
        return supported;
      }
    }
  }
  return const Locale('en');
}

/// Builds a widget tree wrapping [ThemeSelector] under the given [locale].
///
/// [repo] can be supplied to pre-configure repository state or to inspect
/// writes that happen during the test.
Widget _harness({
  required Locale locale,
  _FakeSettingsRepository? repo,
  Brightness platformBrightness = Brightness.light,
}) {
  return ProviderScope(
    overrides: [
      settingsRepositoryProvider
          .overrideWithValue(repo ?? _FakeSettingsRepository()),
    ],
    child: MediaQuery(
      data: MediaQueryData(platformBrightness: platformBrightness),
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        localeResolutionCallback: _resolveLocale,
        home: const Scaffold(body: ThemeSelector()),
      ),
    ),
  );
}

void main() {
  group('ThemeSelector', () {
    group('English labels', () {
      testWidgets('renders SwitchListTile and two segments with English labels',
          (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        expect(find.text('Use system theme'), findsOneWidget);
        expect(find.text('Follow your device settings'), findsOneWidget);
        expect(find.text('Light'), findsOneWidget);
        expect(find.text('Dark'), findsOneWidget);
      });

      testWidgets('no "System" segment is rendered (removed from design)',
          (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        expect(find.text('System'), findsNothing);
      });

      testWidgets('switch is ON by default (useSystemTheme=true)', (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        final switchTile = tester.widget<SwitchListTile>(
          find.byType(SwitchListTile),
        );
        expect(switchTile.value, isTrue);
      });

      testWidgets(
          'when useSystemTheme=true, SegmentedButton has null onSelectionChanged (disabled)',
          (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        final button = tester.widget<SegmentedButton<ThemeMode>>(
          find.byType(SegmentedButton<ThemeMode>),
        );
        expect(button.onSelectionChanged, isNull);
      });

      testWidgets(
          'when system theme is ON and device is light, Light segment is highlighted',
          (tester) async {
        await tester.pumpWidget(
          _harness(
            locale: const Locale('en'),
            platformBrightness: Brightness.light,
          ),
        );
        await tester.pumpAndSettle();

        final button = tester.widget<SegmentedButton<ThemeMode>>(
          find.byType(SegmentedButton<ThemeMode>),
        );
        expect(button.selected, {ThemeMode.light});
      });

      testWidgets(
          'when system theme is ON and device is dark, Dark segment is highlighted',
          (tester) async {
        await tester.pumpWidget(
          _harness(
            locale: const Locale('en'),
            platformBrightness: Brightness.dark,
          ),
        );
        await tester.pumpAndSettle();

        final button = tester.widget<SegmentedButton<ThemeMode>>(
          find.byType(SegmentedButton<ThemeMode>),
        );
        expect(button.selected, {ThemeMode.dark});
      });

      testWidgets(
          'when useSystemTheme=false, SegmentedButton is enabled (non-null onSelectionChanged)',
          (tester) async {
        final repo = _FakeSettingsRepository(
          initial: const AppSettings(useSystemTheme: false),
        );
        await tester.pumpWidget(
          _harness(locale: const Locale('en'), repo: repo),
        );
        await tester.pumpAndSettle();

        final button = tester.widget<SegmentedButton<ThemeMode>>(
          find.byType(SegmentedButton<ThemeMode>),
        );
        expect(button.onSelectionChanged, isNotNull);
      });

      testWidgets(
          'when useSystemTheme=false and manualThemeMode=dark, Dark is selected',
          (tester) async {
        final repo = _FakeSettingsRepository(
          initial: const AppSettings(
            useSystemTheme: false,
            manualThemeMode: ThemeMode.dark,
          ),
        );
        await tester.pumpWidget(
          _harness(locale: const Locale('en'), repo: repo),
        );
        await tester.pumpAndSettle();

        final button = tester.widget<SegmentedButton<ThemeMode>>(
          find.byType(SegmentedButton<ThemeMode>),
        );
        expect(button.selected, {ThemeMode.dark});
      });

      testWidgets(
          'tapping Dark segment when system OFF saves manualThemeMode=dark',
          (tester) async {
        final repo = _FakeSettingsRepository(
          initial: const AppSettings(useSystemTheme: false),
        );
        await tester.pumpWidget(
          _harness(locale: const Locale('en'), repo: repo),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Dark'));
        await tester.pumpAndSettle();

        expect(repo.savedManualThemeMode, ThemeMode.dark);
      });

      testWidgets(
          'toggling switch OFF saves useSystemTheme=false and pre-sets manualThemeMode from brightness',
          (tester) async {
        final repo = _FakeSettingsRepository();
        await tester.pumpWidget(
          _harness(
            locale: const Locale('en'),
            repo: repo,
            platformBrightness: Brightness.dark,
          ),
        );
        await tester.pumpAndSettle();

        // Switch starts ON — tap to turn it OFF.
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        expect(repo.savedUseSystemTheme, isFalse);
        // Dark device → dark manual mode pre-set
        expect(repo.savedManualThemeMode, ThemeMode.dark);
      });
    });

    group('Ukrainian labels', () {
      testWidgets('renders correct Ukrainian labels under Locale("uk")',
          (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('uk')));
        await tester.pumpAndSettle();

        expect(find.text('Системна тема'), findsOneWidget);
        expect(find.text('Використовувати налаштування пристрою'),
            findsOneWidget);
        expect(find.text('Світла'), findsOneWidget);
        expect(find.text('Темна'), findsOneWidget);
      });
    });

    group('German labels', () {
      testWidgets('renders correct German labels under Locale("de")',
          (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('de')));
        await tester.pumpAndSettle();

        expect(find.text('Systemdesign verwenden'), findsOneWidget);
        expect(find.text('Geräteeinstellungen folgen'), findsOneWidget);
        expect(find.text('Hell'), findsOneWidget);
        expect(find.text('Dunkel'), findsOneWidget);
      });
    });
  });
}
