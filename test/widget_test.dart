import 'package:dosly/features/settings/domain/entities/app_settings.dart';
import 'package:dosly/features/settings/domain/repositories/settings_repository.dart';
import 'package:dosly/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:dosly/app.dart';

/// Minimal fake that satisfies [SettingsRepository] for widget tests.
///
/// Returns defaults from [load] and records saves in [lastSavedMode] and
/// [lastSavedUseSystemTheme].
class _FakeSettingsRepository implements SettingsRepository {
  AppSettings _settings = const AppSettings();

  ThemeMode? get lastSavedMode => _settings.manualThemeMode;
  bool get lastSavedUseSystemTheme => _settings.useSystemTheme;

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

void main() {
  late _FakeSettingsRepository fakeRepo;

  setUp(() {
    fakeRepo = _FakeSettingsRepository();
  });

  testWidgets(
    'DoslyApp renders the home screen with app bar, Hello World, and Theme preview button',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const DoslyApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello World'), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, 'Theme preview'),
        findsOneWidget,
      );
      expect(find.text('Dosly'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping Theme preview navigates to the preview and cycling theme mode works',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const DoslyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate from HomeScreen → ThemePreviewScreen via the dev button.
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Theme preview'),
      );
      await tester.pumpAndSettle();

      // Confirm we arrived at the preview screen.
      expect(find.text('dosly · M3 preview'), findsOneWidget);
      expect(find.byTooltip('Cycle theme mode'), findsOneWidget);

      // Cycle once: system → light (manual, useSystemTheme=false)
      await tester.tap(find.byTooltip('Cycle theme mode'));
      await tester.pumpAndSettle();
      expect(fakeRepo.lastSavedUseSystemTheme, isFalse);
      expect(fakeRepo.lastSavedMode, ThemeMode.light);

      // Cycle again: light → dark (still manual)
      await tester.tap(find.byTooltip('Cycle theme mode'));
      await tester.pumpAndSettle();
      expect(fakeRepo.lastSavedMode, ThemeMode.dark);

      // Cycle again: dark → system (useSystemTheme=true)
      await tester.tap(find.byTooltip('Cycle theme mode'));
      await tester.pumpAndSettle();
      expect(fakeRepo.lastSavedUseSystemTheme, isTrue);
    },
  );
}
