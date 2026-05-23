/// Application root.
///
/// A [ConsumerWidget] that watches the four raw [AppSettings] fields
/// through narrow `ref.watch(settingsNotifierProvider.select(...))` calls
/// (`useSystemTheme`, `manualThemeMode`, `useSystemLanguage`,
/// `manualLanguage`) and computes the Flutter-typed `themeMode` /
/// `locale` for [MaterialApp.router] inline. This file is the single
/// `Flutter SDK ↔ domain` mapping seam — `package:flutter`'s
/// [ThemeMode] does not appear in `lib/features/settings/`. Routing is
/// delegated to [appRouterProvider] which exposes `/` ([HomeScreen]),
/// `/meds`, `/history`, and `/settings`. When `useSystemLanguage` is `true`
/// `MaterialApp.locale` is left `null` so [resolveAppLocale] resolves the
/// device locale against [AppLocalizations.supportedLocales] with
/// English as the fallback.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/locale_resolver.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/domain/entities/app_theme_mode.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'l10n/app_localizations.dart';

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
      settingsNotifierProvider.select((s) => s.useSystemTheme),
    );
    final manualThemeMode = ref.watch(
      settingsNotifierProvider.select((s) => s.manualThemeMode),
    );
    final useSystemLanguage = ref.watch(
      settingsNotifierProvider.select((s) => s.useSystemLanguage),
    );
    final manualLanguage = ref.watch(
      settingsNotifierProvider.select((s) => s.manualLanguage),
    );

    return MaterialApp.router(
      title: 'dosly',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveAppLocale,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: useSystemLanguage ? null : Locale(manualLanguage.code),
      themeMode: useSystemTheme
          ? ThemeMode.system
          : _toFlutterThemeMode(manualThemeMode),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
