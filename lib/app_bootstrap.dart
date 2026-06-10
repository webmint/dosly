/// Non-blocking startup root for the dosly app.
///
/// [AppBootstrap] is mounted directly by `main()` inside the root
/// [ProviderScope]. It watches [sharedPreferencesInitProvider] — the async
/// creation seam — and drives the startup lifecycle:
///
/// * **loading** — shows a [SplashScreen] inside a lightweight [MaterialApp]
///   shell so the device splash hand-off is seamless.
/// * **error** — shows [PrefsLoadErrorScreen] inside the same shell; the Retry
///   button calls [ProviderRef.invalidate] on
///   [sharedPreferencesInitProvider] to re-trigger the async init.
/// * **data** — wraps [DoslyApp] in a nested [ProviderScope] that overrides
///   the synchronous [sharedPreferencesProvider] with the resolved instance.
///   This preserves the synchronous-read contract used by
///   `lib/features/settings/**` without any change to that code.
///
/// Only one [MaterialApp] is ever mounted at a time: the loading and error
/// branches use [_bootstrapShell]; the data branch returns [DoslyApp] which
/// brings its own [MaterialApp.router].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/l10n/locale_resolver.dart';
import 'core/logging/logger.dart';
import 'core/providers/shared_preferences_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/prefs_load_error_screen.dart';
import 'core/widgets/splash_screen.dart';
import 'l10n/app_localizations.dart';

/// Root widget that orchestrates the non-blocking startup sequence.
///
/// Watches [sharedPreferencesInitProvider] and maps each [AsyncValue] state
/// to the correct child:
///
/// * [AsyncLoading] → [SplashScreen] (with a [MaterialApp] bootstrap shell)
/// * [AsyncError] → [PrefsLoadErrorScreen] (with a [MaterialApp] bootstrap
///   shell; the Retry button invalidates the init provider)
/// * [AsyncData] → [DoslyApp] wrapped in a [ProviderScope] override that
///   injects the resolved [SharedPreferencesWithCache] instance
///
/// `const`-constructible — Flutter's element reuse applies.
class AppBootstrap extends ConsumerWidget {
  /// Creates an [AppBootstrap].
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Instantiate the logging pipeline in the root ProviderScope so that
    // Logger.root listener is registered before any route can fail.
    ref.read(loggerProvider); // side-effect only; value discarded
    return ref
        .watch(sharedPreferencesInitProvider)
        .when(
          loading: () => _bootstrapShell(const SplashScreen()),
          error: (error, stackTrace) => _bootstrapShell(
            PrefsLoadErrorScreen(
              onRetry: () => ref.invalidate(sharedPreferencesInitProvider),
            ),
          ),
          data: (prefs) => ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: const DoslyApp(),
          ),
        );
  }

  /// Wraps [home] in a minimal [MaterialApp] shell for the startup phases.
  ///
  /// Used by both the loading and error branches so theme, localization
  /// delegates, and locale resolution are identical in both states.
  /// [ThemeMode.system] lets the splash respect device brightness immediately,
  /// minimizing a light-to-dark flash before [DoslyApp] mounts.
  ///
  /// This is a plain [MaterialApp] (not [MaterialApp.router]) because neither
  /// the splash screen nor the error screen requires routing.
  Widget _bootstrapShell(Widget home) => MaterialApp(
    debugShowCheckedModeBanner: false,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    localeResolutionCallback: resolveAppLocale,
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: ThemeMode.system,
    home: home,
  );
}
