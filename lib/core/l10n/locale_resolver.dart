/// Locale resolution policy for the app.
///
/// Provides [resolveAppLocale], the single production source of truth for the
/// app's English-fallback locale policy. Both `app.dart` and the startup
/// bootstrap widget resolve the active [Locale] through this function so the
/// fallback behavior is identical everywhere.
library;

import 'package:flutter/widgets.dart';

/// Resolves the active [Locale] for `MaterialApp.router`.
///
/// Matches [deviceLocale] against [supportedLocales] by `languageCode`; if
/// no match is found, falls back to English (the project's designated
/// fallback per spec §3.2). Flutter's default resolution instead returns
/// the first entry of `supportedLocales`, which — because gen_l10n emits
/// the list alphabetically (`de`, `en`, `uk`) — would incorrectly surface
/// German to users on unsupported device locales. This function pins the
/// fallback to English regardless of list order.
Locale resolveAppLocale(
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
