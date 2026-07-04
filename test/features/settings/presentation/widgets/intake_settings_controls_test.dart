library;

import 'package:dosly/core/error/failures.dart';
import 'package:dosly/core/l10n/locale_resolver.dart';
import 'package:dosly/features/settings/domain/entities/app_language.dart';
import 'package:dosly/features/settings/domain/entities/app_settings.dart';
import 'package:dosly/features/settings/domain/entities/app_theme_mode.dart';
import 'package:dosly/features/settings/domain/repositories/settings_repository.dart';
import 'package:dosly/features/settings/domain/value_objects/grace_period.dart';
import 'package:dosly/features/settings/domain/value_objects/intake_window.dart';
import 'package:dosly/features/settings/presentation/providers/settings_provider.dart';
import 'package:dosly/features/settings/presentation/widgets/intake_settings_controls.dart';
import 'package:dosly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

const String _windowLabel = 'Intake window';
const String _graceLabel = 'Grace period';
const String _increaseTooltip = 'Increase';
const String _decreaseTooltip = 'Decrease';

/// Fake [SettingsRepository] that stores settings in memory and can simulate
/// per-method persistence failures.
///
/// Implements all seven save methods so it satisfies the full
/// [SettingsRepository] contract. Theme/language save methods are no-ops
/// (aside from mutating [_settings]) for these intake-controls tests; the
/// three intake methods can be made to fail via the `failOnSaveX` flags so
/// tests can assert the "failure leaves the displayed value unchanged"
/// behaviour.
class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository({AppSettings? initial})
    : _settings = initial ?? const AppSettings();

  AppSettings _settings;

  /// When true, [saveIntakeWindow] returns a [Left] with an [UnknownFailure].
  bool failOnSaveIntakeWindow = false;

  /// When true, [saveGracePeriod] returns a [Left] with an [UnknownFailure].
  bool failOnSaveGracePeriod = false;

  /// When true, [saveAllowMarkAhead] returns a [Left] with an [UnknownFailure].
  bool failOnSaveAllowMarkAhead = false;

  /// Convenience accessor for the persisted intake window.
  IntakeWindow get savedIntakeWindow => _settings.intakeWindow;

  /// Convenience accessor for the persisted grace period.
  GracePeriod get savedGracePeriod => _settings.gracePeriod;

  /// Convenience accessor for the persisted allow-mark-ahead flag.
  bool get savedAllowMarkAhead => _settings.allowMarkAhead;

  @override
  Either<Failure, AppSettings> load() => Right(_settings);

  @override
  Future<Either<Failure, void>> saveThemeMode(AppThemeMode mode) async {
    _settings = _settings.copyWith(manualThemeMode: mode);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> saveUseSystemTheme(bool value) async {
    _settings = _settings.copyWith(useSystemTheme: value);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> saveUseSystemLanguage(bool value) async {
    _settings = _settings.copyWith(useSystemLanguage: value);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> saveManualLanguage(AppLanguage language) async {
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

/// Builds a widget tree wrapping [IntakeSettingsControls] under [locale]
/// (English by default), with the settings repository overridden by [repo].
Widget _harness({
  _FakeSettingsRepository? repo,
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(
        repo ?? _FakeSettingsRepository(),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveAppLocale,
      home: const Scaffold(body: IntakeSettingsControls()),
    ),
  );
}

/// Finds the [ListTile] stepper row whose title is [rowLabel].
///
/// Both stepper rows contain a "−" and a "+" `IconButton` with the same
/// tooltips, so lookups must be scoped to the specific row rather than using
/// a bare `find.byTooltip(...)` (ambiguous across rows) or a positional
/// `find.byType(IconButton).at(n)` (fragile to layout changes).
Finder _stepperRow(String rowLabel) =>
    find.ancestor(of: find.text(rowLabel), matching: find.byType(ListTile));

/// Finds the tappable stepper `IconButton` with [tooltip] scoped to the row
/// titled [rowLabel].
///
/// `find.byTooltip` matches the `Tooltip` widget that `IconButton` wraps
/// internally around its icon (a descendant of the button, not the button
/// itself), so this walks back up to the enclosing `IconButton` — the widget
/// whose `onPressed` reflects the enabled/disabled state.
Finder _stepperButton({required String rowLabel, required String tooltip}) {
  final tooltipFinder = find.descendant(
    of: _stepperRow(rowLabel),
    matching: find.byTooltip(tooltip),
  );
  return find.ancestor(of: tooltipFinder, matching: find.byType(IconButton));
}

void main() {
  group('IntakeSettingsControls', () {
    testWidgets(
      'renders both stepper rows and the mark-ahead switch with default values',
      (tester) async {
        await tester.pumpWidget(_harness());
        await tester.pumpAndSettle();

        expect(find.text(_windowLabel), findsOneWidget);
        expect(find.text(_graceLabel), findsOneWidget);
        expect(find.text('120 min'), findsOneWidget);
        expect(find.text('5 min'), findsOneWidget);
        expect(find.text('Allow marking ahead'), findsOneWidget);

        final switchTile = tester.widget<SwitchListTile>(
          find.byType(SwitchListTile),
        );
        expect(switchTile.value, isFalse);
      },
    );

    testWidgets('renders seeded values when settings differ from defaults', (
      tester,
    ) async {
      final repo = _FakeSettingsRepository(
        initial: const AppSettings(
          intakeWindow: IntakeWindow.defaultValue,
          gracePeriod: GracePeriod.defaultValue,
          allowMarkAhead: true,
        ),
      );
      await tester.pumpWidget(_harness(repo: repo));
      await tester.pumpAndSettle();

      final switchTile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switchTile.value, isTrue);
    });

    group('intake window stepper', () {
      testWidgets('tapping + increases the window by 15 minutes and persists', (
        tester,
      ) async {
        final repo = _FakeSettingsRepository();
        await tester.pumpWidget(_harness(repo: repo));
        await tester.pumpAndSettle();

        await tester.tap(
          _stepperButton(rowLabel: _windowLabel, tooltip: _increaseTooltip),
        );
        await tester.pumpAndSettle();

        expect(find.text('135 min'), findsOneWidget);
        expect(repo.savedIntakeWindow, IntakeWindow(135));
      });

      testWidgets('tapping − decreases the window by 15 minutes and persists', (
        tester,
      ) async {
        final repo = _FakeSettingsRepository();
        await tester.pumpWidget(_harness(repo: repo));
        await tester.pumpAndSettle();

        await tester.tap(
          _stepperButton(rowLabel: _windowLabel, tooltip: _decreaseTooltip),
        );
        await tester.pumpAndSettle();

        expect(find.text('105 min'), findsOneWidget);
        expect(repo.savedIntakeWindow, IntakeWindow(105));
      });

      testWidgets('+ is disabled when the window is at its maximum (240)', (
        tester,
      ) async {
        final repo = _FakeSettingsRepository(
          initial: AppSettings(intakeWindow: IntakeWindow(240)),
        );
        await tester.pumpWidget(_harness(repo: repo));
        await tester.pumpAndSettle();

        final button = tester.widget<IconButton>(
          _stepperButton(rowLabel: _windowLabel, tooltip: _increaseTooltip),
        );
        expect(button.onPressed, isNull);
      });

      testWidgets('− is disabled when the window is at its minimum (15)', (
        tester,
      ) async {
        final repo = _FakeSettingsRepository(
          initial: AppSettings(intakeWindow: IntakeWindow(15)),
        );
        await tester.pumpWidget(_harness(repo: repo));
        await tester.pumpAndSettle();

        final button = tester.widget<IconButton>(
          _stepperButton(rowLabel: _windowLabel, tooltip: _decreaseTooltip),
        );
        expect(button.onPressed, isNull);
      });

      testWidgets('displayed value remains unchanged after a failed save', (
        tester,
      ) async {
        final repo = _FakeSettingsRepository()..failOnSaveIntakeWindow = true;
        await tester.pumpWidget(_harness(repo: repo));
        await tester.pumpAndSettle();

        await tester.tap(
          _stepperButton(rowLabel: _windowLabel, tooltip: _increaseTooltip),
        );
        await tester.pumpAndSettle();

        // This widget-level test asserts only that the displayed value
        // stays unchanged on failure — IntakeSettingsControls shows no
        // error UI of its own. The SnackBar surface is covered by
        // settings_screen_test.dart's "SettingsScreen error SnackBar"
        // group, which exercises this same failure path with the
        // SettingsScreen's ScaffoldMessenger listener mounted.
        expect(find.text('120 min'), findsOneWidget);
        expect(repo.savedIntakeWindow, IntakeWindow.defaultValue);
      });
    });

    group('grace period stepper', () {
      testWidgets(
        'tapping + increases the grace period by 5 minutes and persists',
        (tester) async {
          final repo = _FakeSettingsRepository();
          await tester.pumpWidget(_harness(repo: repo));
          await tester.pumpAndSettle();

          await tester.tap(
            _stepperButton(rowLabel: _graceLabel, tooltip: _increaseTooltip),
          );
          await tester.pumpAndSettle();

          expect(find.text('10 min'), findsOneWidget);
          expect(repo.savedGracePeriod, GracePeriod(10));
        },
      );

      testWidgets(
        'tapping − decreases the grace period by 5 minutes and persists',
        (tester) async {
          final repo = _FakeSettingsRepository();
          await tester.pumpWidget(_harness(repo: repo));
          await tester.pumpAndSettle();

          await tester.tap(
            _stepperButton(rowLabel: _graceLabel, tooltip: _decreaseTooltip),
          );
          await tester.pumpAndSettle();

          expect(find.text('0 min'), findsOneWidget);
          expect(repo.savedGracePeriod, GracePeriod(0));
        },
      );

      testWidgets(
        '+ is disabled when the grace period is at its maximum (30)',
        (tester) async {
          final repo = _FakeSettingsRepository(
            initial: AppSettings(gracePeriod: GracePeriod(30)),
          );
          await tester.pumpWidget(_harness(repo: repo));
          await tester.pumpAndSettle();

          final button = tester.widget<IconButton>(
            _stepperButton(rowLabel: _graceLabel, tooltip: _increaseTooltip),
          );
          expect(button.onPressed, isNull);
        },
      );

      testWidgets('− is disabled when the grace period is at its minimum (0)', (
        tester,
      ) async {
        final repo = _FakeSettingsRepository(
          initial: AppSettings(gracePeriod: GracePeriod(0)),
        );
        await tester.pumpWidget(_harness(repo: repo));
        await tester.pumpAndSettle();

        final button = tester.widget<IconButton>(
          _stepperButton(rowLabel: _graceLabel, tooltip: _decreaseTooltip),
        );
        expect(button.onPressed, isNull);
      });

      testWidgets('displayed value remains unchanged after a failed save', (
        tester,
      ) async {
        final repo = _FakeSettingsRepository()..failOnSaveGracePeriod = true;
        await tester.pumpWidget(_harness(repo: repo));
        await tester.pumpAndSettle();

        await tester.tap(
          _stepperButton(rowLabel: _graceLabel, tooltip: _increaseTooltip),
        );
        await tester.pumpAndSettle();

        expect(find.text('5 min'), findsOneWidget);
        expect(repo.savedGracePeriod, GracePeriod.defaultValue);
      });
    });

    group('allow mark-ahead switch', () {
      testWidgets('tapping the switch turns allowMarkAhead on and persists', (
        tester,
      ) async {
        final repo = _FakeSettingsRepository();
        await tester.pumpWidget(_harness(repo: repo));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        final switchTile = tester.widget<SwitchListTile>(
          find.byType(SwitchListTile),
        );
        expect(switchTile.value, isTrue);
        expect(repo.savedAllowMarkAhead, isTrue);
      });

      testWidgets('switch value remains unchanged after a failed save', (
        tester,
      ) async {
        final repo = _FakeSettingsRepository()..failOnSaveAllowMarkAhead = true;
        await tester.pumpWidget(_harness(repo: repo));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        final switchTile = tester.widget<SwitchListTile>(
          find.byType(SwitchListTile),
        );
        expect(switchTile.value, isFalse);
        expect(repo.savedAllowMarkAhead, isFalse);
      });

      testWidgets(
        'tapping the switch turns allowMarkAhead off when seeded true',
        (tester) async {
          final repo = _FakeSettingsRepository(
            initial: const AppSettings(allowMarkAhead: true),
          );
          await tester.pumpWidget(_harness(repo: repo));
          await tester.pumpAndSettle();

          await tester.tap(find.byType(Switch));
          await tester.pumpAndSettle();

          final switchTile = tester.widget<SwitchListTile>(
            find.byType(SwitchListTile),
          );
          expect(switchTile.value, isFalse);
          expect(repo.savedAllowMarkAhead, isFalse);
        },
      );
    });
  });

  group('IntakeSettingsControls locale rendering', () {
    testWidgets(
      'renders German intake labels and "120 Min." under Locale("de")',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('de')));
        await tester.pumpAndSettle();

        expect(find.text('Einnahmefenster'), findsOneWidget);
        expect(find.text('Kulanzzeit'), findsOneWidget);
        expect(find.text('120 Min.'), findsOneWidget);
        expect(find.text('5 Min.'), findsOneWidget);
      },
    );

    testWidgets(
      'renders Ukrainian intake labels and "120 хв" under Locale("uk")',
      (tester) async {
        await tester.pumpWidget(_harness(locale: const Locale('uk')));
        await tester.pumpAndSettle();

        expect(find.text('Вікно прийому'), findsOneWidget);
        expect(find.text('Час на скасування'), findsOneWidget);
        expect(find.text('120 хв'), findsOneWidget);
        expect(find.text('5 хв'), findsOneWidget);
      },
    );
  });
}
