/// Application root.
///
/// A [ConsumerWidget] that watches the four raw [AppSettings] fields
/// through narrow `ref.watch(settingsProvider.select(...))` calls
/// (`useSystemTheme`, `manualThemeMode`, `useSystemLanguage`,
/// `manualLanguage`) and computes the Flutter-typed `themeMode` /
/// `locale` for [MaterialApp.router] inline. This file is the single
/// `Flutter SDK ↔ domain` mapping seam — `package:flutter`'s
/// [ThemeMode] does not appear in `lib/features/settings/`. Routing is
/// delegated to [appRouter] which currently exposes `/` ([HomeScreen])
/// and a temporary dev-only `/theme-preview` route — the preview route
/// will be removed in the final development stages (see
/// specs/002-main-screen/spec.md). When `useSystemLanguage` is `true`
/// `MaterialApp.locale` is left `null` so [_resolveLocale] resolves the
/// device locale against [AppLocalizations.supportedLocales] with
/// English as the fallback.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/domain/entities/app_theme_mode.dart';
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

/// Maps the domain-owned [AppThemeMode] to Flutter's [ThemeMode].
///
/// Exhaustive over [AppThemeMode]'s two values (no `default:` clause —
/// the Dart compiler enforces exhaustiveness). The `system` case is
/// handled at the call site by checking `useSystemTheme` before
/// invoking this function.
ThemeMode _toFlutterThemeMode(AppThemeMode m) => switch (m) {
  AppThemeMode.light => ThemeMode.light,
  AppThemeMode.dark => ThemeMode.dark,
};

/// The dosly application root widget.
class DoslyApp extends ConsumerWidget {
  /// Creates the application root.
  const DoslyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useSystemTheme = ref.watch(
      settingsProvider.select((s) => s.useSystemTheme),
    );
    final manualThemeMode = ref.watch(
      settingsProvider.select((s) => s.manualThemeMode),
    );
    final useSystemLanguage = ref.watch(
      settingsProvider.select((s) => s.useSystemLanguage),
    );
    final manualLanguage = ref.watch(
      settingsProvider.select((s) => s.manualLanguage),
    );

    return MaterialApp.router(
      title: 'dosly',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: _resolveLocale,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: useSystemLanguage ? null : Locale(manualLanguage.code),
      themeMode: useSystemTheme
          ? ThemeMode.system
          : _toFlutterThemeMode(manualThemeMode),
      routerConfig: appRouter,
    );
  }
}
