import 'package:dosly/core/error/failures.dart';
import 'package:dosly/core/l10n/locale_resolver.dart';
import 'package:dosly/features/home/presentation/screens/home_screen.dart';
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
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Always-success fake [SettingsRepository] — mirrors the shape used in the
/// reference settings_screen_test.dart.
class _FakeSettingsRepository implements SettingsRepository {
  @override
  Either<Failure, AppSettings> load() => const Right(AppSettings());

  @override
  Future<Either<Failure, void>> saveThemeMode(AppThemeMode mode) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> saveUseSystemTheme(bool value) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> saveUseSystemLanguage(bool value) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> saveManualLanguage(
    AppLanguage language,
  ) async => const Right(null);
}

/// Builds a two-route [GoRouter] + [ProviderScope] + [MaterialApp.router]
/// harness for testing gear-icon navigation from [HomeScreen] to
/// [SettingsScreen].
Widget _harness() {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, _) => const HomeScreen()),
      GoRoute(
        path: '/settings',
        builder: (context, _) => const SettingsScreen(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(_FakeSettingsRepository()),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveAppLocale,
    ),
  );
}

void main() {
  group('HomeScreen gear icon navigation', () {
    testWidgets('should navigate to SettingsScreen when gear is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      // Verify we start on HomeScreen.
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(SettingsScreen), findsNothing);

      // Tap the gear icon in the AppBar.
      final gearFinder = find.byIcon(LucideIcons.settings);
      expect(gearFinder, findsOneWidget);
      await tester.tap(gearFinder);
      await tester.pumpAndSettle();

      // SettingsScreen must be visible after navigation.
      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });
}
