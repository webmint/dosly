import 'package:dosly/core/error/failures.dart';
import 'package:dosly/core/l10n/locale_resolver.dart';
import 'package:dosly/features/settings/domain/entities/app_language.dart';
import 'package:dosly/features/settings/domain/entities/app_settings.dart';
import 'package:dosly/features/settings/domain/entities/app_theme_mode.dart';
import 'package:dosly/features/settings/domain/repositories/settings_repository.dart';
import 'package:dosly/features/settings/domain/value_objects/grace_period.dart';
import 'package:dosly/features/settings/domain/value_objects/intake_window.dart';
import 'package:dosly/features/settings/presentation/providers/settings_provider.dart';
import 'package:dosly/features/settings/presentation/screens/settings_screen.dart';
import 'package:dosly/features/settings/presentation/widgets/intake_settings_controls.dart';
import 'package:dosly/features/settings/presentation/widgets/language_selector.dart';
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
  bool failOnSaveIntakeWindow = false;
  bool failOnSaveGracePeriod = false;
  bool failOnSaveAllowMarkAhead = false;

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

  @override
  Future<Either<Failure, void>> saveIntakeWindow(IntakeWindow window) async {
    if (failOnSaveIntakeWindow) {
      return Left(Failure.unknown(Exception('mock failure'), StackTrace.empty));
    }
    _settings = _settings.copyWith(intakeWindow: window);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> saveGracePeriod(GracePeriod grace) async {
    if (failOnSaveGracePeriod) {
      return Left(Failure.unknown(Exception('mock failure'), StackTrace.empty));
    }
    _settings = _settings.copyWith(gracePeriod: grace);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> saveAllowMarkAhead(bool value) async {
    if (failOnSaveAllowMarkAhead) {
      return Left(Failure.unknown(Exception('mock failure'), StackTrace.empty));
    }
    _settings = _settings.copyWith(allowMarkAhead: value);
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
Widget _harness({required Locale locale, _FakeSettingsRepository? fakeRepo}) {
  final repo = fakeRepo ?? _FakeSettingsRepository();
  return ProviderScope(
    overrides: [settingsRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveAppLocale,
      home: const SettingsScreen(),
    ),
  );
}

const String _windowRowLabel = 'Intake window';
const String _graceRowLabel = 'Grace period';
const String _increaseTooltip = 'Increase';

/// Finds the [ListTile] stepper row whose title is [rowLabel].
///
/// The intake window and grace period rows share the same "Increase"/
/// "Decrease" tooltips, so lookups must be scoped to the specific row rather
/// than using a bare `find.byTooltip(...)` (ambiguous across rows) or a
/// positional `find.byType(IconButton).at(n)` (fragile to layout changes).
Finder _stepperRow(String rowLabel) =>
    find.ancestor(of: find.text(rowLabel), matching: find.byType(ListTile));

/// Finds the tappable stepper `IconButton` with [tooltip] scoped to the row
/// titled [rowLabel].
Finder _stepperButton({required String rowLabel, required String tooltip}) {
  final tooltipFinder = find.descendant(
    of: _stepperRow(rowLabel),
    matching: find.byTooltip(tooltip),
  );
  return find.ancestor(of: tooltipFinder, matching: find.byType(IconButton));
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

    testWidgets('falls back to "Settings" for unsupported Locale("fr")', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(locale: const Locale('fr')));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });
  });

  group('SettingsScreen appearance header', () {
    testWidgets('renders uppercased "APPEARANCE" header under Locale("en")', (
      tester,
    ) async {
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
      },
    );

    testWidgets('renders uppercased "DARSTELLUNG" header under Locale("de")', (
      tester,
    ) async {
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
              widget is Divider && widget.height == 1 && widget.thickness == 1,
        ),
      );

      expect(dividerFinder, findsOneWidget);
    });
  });

  group('SettingsScreen language header', () {
    testWidgets('renders uppercased "LANGUAGE" header under Locale("en")', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('LANGUAGE'), findsOneWidget);
    });

    testWidgets('renders uppercased "МОВА" header under Locale("uk")', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(locale: const Locale('uk')));
      await tester.pumpAndSettle();

      expect(find.text('МОВА'), findsOneWidget);
    });

    testWidgets('renders uppercased "SPRACHE" header under Locale("de")', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(locale: const Locale('de')));
      await tester.pumpAndSettle();

      expect(find.text('SPRACHE'), findsOneWidget);
    });
  });

  group('SettingsScreen intake section', () {
    testWidgets(
      'mounts the Intake section (header + IntakeSettingsControls) after '
      'the Language section',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('en')));
        await tester.pumpAndSettle();

        expect(find.text('INTAKE'), findsOneWidget);
        expect(find.byType(IntakeSettingsControls), findsOneWidget);

        final languageHeaderY = tester.getTopLeft(find.text('LANGUAGE')).dy;
        final intakeControlsY = tester
            .getTopLeft(find.byType(IntakeSettingsControls))
            .dy;
        expect(intakeControlsY, greaterThan(languageHeaderY));
      },
    );
  });

  group('SettingsScreen error SnackBar', () {
    testWidgets('shows localized error SnackBar when setUseSystemTheme fails', (
      tester,
    ) async {
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

    testWidgets(
      'shows localized error SnackBar when setUseSystemLanguage fails',
      (tester) async {
        final fakeRepo = _FakeSettingsRepository()
          ..failOnSaveUseSystemLanguage = true;
        await tester.pumpWidget(
          _harness(locale: const Locale('en'), fakeRepo: fakeRepo),
        );
        await tester.pumpAndSettle();

        // Tap the "Use device language" SwitchListTile, scoped to the
        // LanguageSelector so it's immune to switches added elsewhere on the
        // screen (e.g. the Intake section's "allow mark ahead" switch).
        final languageSwitchFinder = find.descendant(
          of: find.byType(LanguageSelector),
          matching: find.byType(SwitchListTile),
        );
        await tester.tap(languageSwitchFinder);
        await tester.pump(); // mutator runs
        await tester.pump(const Duration(milliseconds: 100)); // SnackBar enters

        expect(
          find.text("Couldn't save your preference. Please try again."),
          findsOneWidget,
        );
      },
    );

    testWidgets('shows localized error SnackBar when setThemeMode fails', (
      tester,
    ) async {
      // Only the ThemeMode save fails; the toggle-off save must succeed so the
      // SegmentedButton becomes enabled.
      final fakeRepo = _FakeSettingsRepository()..failOnSaveThemeMode = true;
      await tester.pumpWidget(
        _harness(locale: const Locale('en'), fakeRepo: fakeRepo),
      );
      await tester.pumpAndSettle();

      // Turn "Use system theme" OFF (save succeeds) so the SegmentedButton
      // becomes interactive.
      await tester.tap(find.byType(SwitchListTile).first);
      await tester.pumpAndSettle();

      // The default manual mode is Light; tap Dark to fire setThemeMode.
      await tester.tap(find.text('Dark').last);
      await tester.pump(); // mutator runs
      await tester.pump(const Duration(milliseconds: 100)); // SnackBar enters

      expect(
        find.text("Couldn't save your preference. Please try again."),
        findsOneWidget,
      );
    });

    testWidgets('shows localized error SnackBar when setManualLanguage fails', (
      tester,
    ) async {
      // Only the manual language save fails; the toggle-off save must succeed
      // so the DropdownButton becomes enabled.
      final fakeRepo = _FakeSettingsRepository()
        ..failOnSaveManualLanguage = true;
      await tester.pumpWidget(
        _harness(locale: const Locale('en'), fakeRepo: fakeRepo),
      );
      await tester.pumpAndSettle();

      // Turn "Use device language" OFF (save succeeds) so the DropdownButton
      // becomes interactive. Scoped to the LanguageSelector so it's immune to
      // switches added elsewhere on the screen (e.g. the Intake section's
      // "allow mark ahead" switch).
      final languageSwitchFinder = find.descendant(
        of: find.byType(LanguageSelector),
        matching: find.byType(SwitchListTile),
      );
      await tester.tap(languageSwitchFinder);
      await tester.pumpAndSettle();

      // Open the dropdown to fire setManualLanguage. In this harness the menu
      // items render OFF-STAGE in the overlay route even after pumpAndSettle,
      // so the idiomatic `pumpAndSettle()` + on-stage `find.text('Deutsch')`
      // throws "Bad state: No element" (verified). Use skipOffstage: false to
      // locate the Deutsch DropdownMenuItem.
      await tester.tap(find.byType(DropdownButton<AppLanguage>));
      await tester.pump();

      final deutschMenuItem = find.descendant(
        of: find.byType(DropdownMenuItem<AppLanguage>, skipOffstage: false),
        matching: find.text('Deutsch', skipOffstage: false),
      );
      // warnIfMissed: false — the off-stage overlay route means the tap
      // coordinates hit-test the underlying widget rather than the menu item
      // render box; the gesture still dispatches to the item's onTap, so the
      // SnackBar assertion below self-validates that setManualLanguage fired.
      await tester.tap(deutschMenuItem.last, warnIfMissed: false);
      await tester.pump(); // mutator runs
      await tester.pump(const Duration(milliseconds: 100)); // SnackBar enters

      expect(
        find.text("Couldn't save your preference. Please try again."),
        findsOneWidget,
      );
    });

    testWidgets('shows localized error SnackBar when setIntakeWindow fails', (
      tester,
    ) async {
      final fakeRepo = _FakeSettingsRepository()..failOnSaveIntakeWindow = true;
      await tester.pumpWidget(
        _harness(locale: const Locale('en'), fakeRepo: fakeRepo),
      );
      await tester.pumpAndSettle();

      // Tap the intake window row's "+" stepper, scoped to that row so it's
      // immune to the grace period row's identically-tooltipped "+" button.
      await tester.tap(
        _stepperButton(rowLabel: _windowRowLabel, tooltip: _increaseTooltip),
      );
      await tester.pump(); // mutator runs
      await tester.pump(const Duration(milliseconds: 100)); // SnackBar enters

      expect(
        find.text("Couldn't save your preference. Please try again."),
        findsOneWidget,
      );
    });

    testWidgets('shows localized error SnackBar when setGracePeriod fails', (
      tester,
    ) async {
      final fakeRepo = _FakeSettingsRepository()..failOnSaveGracePeriod = true;
      await tester.pumpWidget(
        _harness(locale: const Locale('en'), fakeRepo: fakeRepo),
      );
      await tester.pumpAndSettle();

      // Tap the grace period row's "+" stepper, scoped to that row so it's
      // immune to the intake window row's identically-tooltipped "+" button.
      await tester.tap(
        _stepperButton(rowLabel: _graceRowLabel, tooltip: _increaseTooltip),
      );
      await tester.pump(); // mutator runs
      await tester.pump(const Duration(milliseconds: 100)); // SnackBar enters

      expect(
        find.text("Couldn't save your preference. Please try again."),
        findsOneWidget,
      );
    });

    testWidgets('shows localized error SnackBar when setAllowMarkAhead fails', (
      tester,
    ) async {
      final fakeRepo = _FakeSettingsRepository()
        ..failOnSaveAllowMarkAhead = true;
      await tester.pumpWidget(
        _harness(locale: const Locale('en'), fakeRepo: fakeRepo),
      );
      await tester.pumpAndSettle();

      // Tap the "Allow marking ahead" SwitchListTile, scoped to the
      // IntakeSettingsControls widget. With the whole SettingsScreen
      // mounted there are 3 switches on screen (theme, language, intake),
      // so a bare `find.byType(SwitchListTile).last` would be fragile to
      // section reordering — scope to the single switch this widget owns.
      final markAheadSwitchFinder = find.descendant(
        of: find.byType(IntakeSettingsControls),
        matching: find.byType(SwitchListTile),
      );
      // The switch sits below the fold in the default test viewport (it's
      // the third row of the Intake section, after the two stepper rows) —
      // scroll it into view before tapping.
      await tester.ensureVisible(markAheadSwitchFinder);
      await tester.pumpAndSettle();
      await tester.tap(markAheadSwitchFinder);
      await tester.pump(); // mutator runs
      await tester.pump(const Duration(milliseconds: 100)); // SnackBar enters

      expect(
        find.text("Couldn't save your preference. Please try again."),
        findsOneWidget,
      );
    });
  });
}
