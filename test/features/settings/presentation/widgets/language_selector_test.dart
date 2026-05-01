library;

import 'package:dosly/features/settings/domain/entities/app_language.dart';
import 'package:dosly/features/settings/domain/entities/app_settings.dart';
import 'package:dosly/features/settings/domain/entities/app_theme_mode.dart';
import 'package:dosly/features/settings/domain/repositories/settings_repository.dart';
import 'package:dosly/features/settings/presentation/providers/settings_provider.dart';
import 'package:dosly/features/settings/presentation/widgets/language_selector.dart';
import 'package:dosly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

/// Fake [SettingsRepository] that stores settings in memory and records writes.
///
/// Implements all four save methods so it satisfies the full [SettingsRepository]
/// contract. Theme save methods are no-ops for language-selector tests; language
/// save methods mutate [_settings] so tests can inspect the result via the
/// [savedUseSystemLanguage] and [savedManualLanguage] getters.
class _FakeSettingsRepository implements SettingsRepository {
  AppSettings _settings;

  _FakeSettingsRepository({AppSettings? initial})
      : _settings = initial ?? const AppSettings();

  bool get savedUseSystemLanguage => _settings.useSystemLanguage;
  AppLanguage get savedManualLanguage => _settings.manualLanguage;

  @override
  AppSettings load() => _settings;

  @override
  Future<Either<Never, void>> saveThemeMode(AppThemeMode mode) async {
    _settings = _settings.copyWith(manualThemeMode: mode);
    return const Right(null);
  }

  @override
  Future<Either<Never, void>> saveUseSystemTheme(bool value) async {
    _settings = _settings.copyWith(useSystemTheme: value);
    return const Right(null);
  }

  @override
  Future<Either<Never, void>> saveUseSystemLanguage(bool value) async {
    _settings = _settings.copyWith(useSystemLanguage: value);
    return const Right(null);
  }

  @override
  Future<Either<Never, void>> saveManualLanguage(AppLanguage language) async {
    _settings = _settings.copyWith(manualLanguage: language);
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

/// Builds a widget tree wrapping [LanguageSelector] under the given [locale].
///
/// [repo] can be supplied to pre-configure repository state or to inspect
/// writes that happen during the test.
Widget _harness({
  required Locale locale,
  _FakeSettingsRepository? repo,
}) {
  return ProviderScope(
    overrides: [
      settingsRepositoryProvider
          .overrideWithValue(repo ?? _FakeSettingsRepository()),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: _resolveLocale,
      home: const Scaffold(body: LanguageSelector()),
    ),
  );
}

void main() {
  group('LanguageSelector', () {
    group('English labels', () {
      testWidgets(
          'renders SwitchListTile, dropdown with 3 entries, and switch labels',
          (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        expect(find.text('Use device language'), findsOneWidget);
        expect(find.text('Follow your device settings'), findsOneWidget);
        // With the dropdown closed only the currently-selected language
        // (English by default) is visible on the button face. The other two
        // entries only appear when the menu is open.
        expect(find.text('English'), findsAtLeastNWidgets(1));
        expect(find.text('Deutsch'), findsNothing);
        expect(find.text('Українська'), findsNothing);
      });

      testWidgets('switch is ON by default (useSystemLanguage=true)',
          (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        final switchTile = tester.widget<SwitchListTile>(
          find.byType(SwitchListTile),
        );
        expect(switchTile.value, isTrue);
      });

      testWidgets(
          'when useSystemLanguage=true, DropdownButton has null onChanged (disabled)',
          (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        final dropdown = tester.widget<DropdownButton<AppLanguage>>(
          find.byType(DropdownButton<AppLanguage>),
        );
        expect(dropdown.onChanged, isNull);
      });

      testWidgets(
          'when useSystemLanguage=true, DropdownButton.value reflects the device-resolved language',
          (tester) async {
        // Default settings (useSystemLanguage=true, manualLanguage=en) under
        // device locale en → dropdown shows en.
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        final dropdown = tester.widget<DropdownButton<AppLanguage>>(
          find.byType(DropdownButton<AppLanguage>),
        );
        expect(dropdown.value, AppLanguage.en);
      });

      testWidgets(
          'when useSystemLanguage=true and device locale differs from stored manualLanguage, dropdown shows device language',
          (tester) async {
        // Stored manualLanguage is uk, but system mode is on and the device
        // locale is de → dropdown must surface de, not the stale uk value.
        final repo = _FakeSettingsRepository(
          initial: const AppSettings(
            useSystemLanguage: true,
            manualLanguage: AppLanguage.uk,
          ),
        );
        await tester.pumpWidget(
          _harness(locale: const Locale('de'), repo: repo),
        );
        await tester.pumpAndSettle();

        final dropdown = tester.widget<DropdownButton<AppLanguage>>(
          find.byType(DropdownButton<AppLanguage>),
        );
        expect(dropdown.value, AppLanguage.de);
      });

      testWidgets(
          'when useSystemLanguage=true and device locale is unsupported, dropdown falls back to en',
          (tester) async {
        final repo = _FakeSettingsRepository(
          initial: const AppSettings(
            useSystemLanguage: true,
            manualLanguage: AppLanguage.de,
          ),
        );
        // Locale fr is unsupported. The harness's _resolveLocale falls back
        // to en, so Localizations.localeOf(context).languageCode = 'en'.
        await tester.pumpWidget(
          _harness(locale: const Locale('fr'), repo: repo),
        );
        await tester.pumpAndSettle();

        final dropdown = tester.widget<DropdownButton<AppLanguage>>(
          find.byType(DropdownButton<AppLanguage>),
        );
        expect(dropdown.value, AppLanguage.en);
      });

      testWidgets(
          'when useSystemLanguage=false, DropdownButton.onChanged is non-null (enabled)',
          (tester) async {
        final repo = _FakeSettingsRepository(
          initial: const AppSettings(useSystemLanguage: false),
        );
        await tester.pumpWidget(
          _harness(locale: const Locale('en'), repo: repo),
        );
        await tester.pumpAndSettle();

        final dropdown = tester.widget<DropdownButton<AppLanguage>>(
          find.byType(DropdownButton<AppLanguage>),
        );
        expect(dropdown.onChanged, isNotNull);
      });

      testWidgets(
          'tapping Deutsch entry when system OFF saves manualLanguage=AppLanguage.de',
          (tester) async {
        final repo = _FakeSettingsRepository(
          initial: const AppSettings(useSystemLanguage: false),
        );
        await tester.pumpWidget(
          _harness(locale: const Locale('en'), repo: repo),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(DropdownButton<AppLanguage>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Deutsch').last);
        await tester.pumpAndSettle();

        expect(repo.savedManualLanguage, AppLanguage.de);
      });

      testWidgets(
          'toggling switch OFF saves useSystemLanguage=false and pre-sets manualLanguage from device locale',
          (tester) async {
        final repo = _FakeSettingsRepository();
        await tester.pumpWidget(
          _harness(locale: const Locale('uk'), repo: repo),
        );
        await tester.pumpAndSettle();

        // Switch starts ON — tap to turn it OFF.
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        expect(repo.savedUseSystemLanguage, isFalse);
        // Device locale is uk → pre-filled to Ukrainian.
        expect(repo.savedManualLanguage, AppLanguage.uk);
      });

      testWidgets(
          'toggling switch OFF with unsupported device locale defaults manualLanguage to en',
          (tester) async {
        final repo = _FakeSettingsRepository();
        // fr is unsupported — the resolution callback maps it to en.
        await tester.pumpWidget(
          _harness(locale: const Locale('fr'), repo: repo),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        // Under fr the resolved locale is en, so the firstWhere finds en.
        expect(repo.savedManualLanguage, AppLanguage.en);
      });
    });

    group('Native names are not translated', () {
      testWidgets('native names render under Locale("uk")', (tester) async {
        // useSystemLanguage=false so the dropdown is enabled and manualLanguage
        // is pre-set to uk, making 'Українська' the visible button face.
        final repo = _FakeSettingsRepository(
          initial: const AppSettings(
            useSystemLanguage: false,
            manualLanguage: AppLanguage.uk,
          ),
        );
        await tester.pumpWidget(
          _harness(locale: const Locale('uk'), repo: repo),
        );
        await tester.pumpAndSettle();

        // Open the dropdown to reveal all entries.
        await tester.tap(find.byType(DropdownButton<AppLanguage>));
        await tester.pumpAndSettle();

        expect(find.text('English'), findsAtLeastNWidgets(1));
        expect(find.text('Deutsch'), findsAtLeastNWidgets(1));
        expect(find.text('Українська'), findsAtLeastNWidgets(1));
      });

      testWidgets('native names render under Locale("de")', (tester) async {
        // useSystemLanguage=false so the dropdown is enabled and manualLanguage
        // is pre-set to de, making 'Deutsch' the visible button face.
        final repo = _FakeSettingsRepository(
          initial: const AppSettings(
            useSystemLanguage: false,
            manualLanguage: AppLanguage.de,
          ),
        );
        await tester.pumpWidget(
          _harness(locale: const Locale('de'), repo: repo),
        );
        await tester.pumpAndSettle();

        // Open the dropdown to reveal all entries.
        await tester.tap(find.byType(DropdownButton<AppLanguage>));
        await tester.pumpAndSettle();

        expect(find.text('English'), findsAtLeastNWidgets(1));
        expect(find.text('Deutsch'), findsAtLeastNWidgets(1));
        expect(find.text('Українська'), findsAtLeastNWidgets(1));
      });
    });

    group('Localized switch labels under non-English locales', () {
      testWidgets('renders correct Ukrainian labels under Locale("uk")',
          (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('uk')));
        await tester.pumpAndSettle();

        expect(find.text('Мова пристрою'), findsOneWidget);
        expect(
          find.text('Використовувати налаштування пристрою'),
          findsOneWidget,
        );
      });

      testWidgets('renders correct German labels under Locale("de")',
          (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('de')));
        await tester.pumpAndSettle();

        expect(find.text('Sprache des Geräts verwenden'), findsOneWidget);
        expect(find.text('Geräteeinstellungen folgen'), findsOneWidget);
      });
    });
  });
}
