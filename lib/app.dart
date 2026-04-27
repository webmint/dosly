/// Application root.
///
/// A [ConsumerWidget] that watches [settingsProvider] for the current
/// [ThemeMode]. Sets the M3 light and dark themes from [AppTheme].
/// Routing is delegated to [appRouter] which currently exposes `/`
/// ([HomeScreen]) and a temporary dev-only `/theme-preview` route — the
/// preview route will be removed in the final development stages (see
/// specs/002-main-screen/spec.md). Locale is auto-resolved from the device
/// via [AppLocalizations.localizationsDelegates] and
/// [AppLocalizations.supportedLocales] — when the device locale is German or
/// Ukrainian those translations render; otherwise English (the
/// template/fallback) is used.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'l10n/app_localizations.dart';

/// Resolves the active [Locale] for [MaterialApp.router].
///
/// Matches [deviceLocale] against [supportedLocales] by `languageCode`; if
/// no match is found, falls back to English (the project's designated
/// fallback per spec §3.2). Flutter's default resolution instead returns
/// the first entry of `supportedLocales`, which — because gen_l10n emits
/// the list alphabetically (`de`, `en`, `uk`) — would incorrectly surface
/// German to users on unsupported device locales. This callback pins the
/// fallback to English regardless of list order.
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

/// The dosly application root widget.
class DoslyApp extends ConsumerWidget {
  /// Creates the application root.
  const DoslyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'dosly',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: _resolveLocale,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.watch(
        settingsProvider.select((s) => s.effectiveThemeMode),
      ),
      routerConfig: appRouter,
    );
  }
}
