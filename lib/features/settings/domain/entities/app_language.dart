/// Languages currently supported by the app.
///
/// Each value carries its IETF language code ([AppLanguage.code]) and a
/// human-readable label in its own native script ([AppLanguage.nativeName]).
/// Native names are NOT translated — they are the universal convention for
/// language pickers, letting users find their language regardless of the
/// currently-displayed UI language.
library;

enum AppLanguage {
  /// English — fallback for unsupported device locales.
  en('en', 'English'),

  /// German.
  de('de', 'Deutsch'),

  /// Ukrainian.
  uk('uk', 'Українська');

  const AppLanguage(this.code, this.nativeName);

  /// IETF language code (lowercase, two letters) used to construct a [Locale].
  final String code;

  /// Human-readable label in the language's own script. Plain literal — never
  /// localised.
  final String nativeName;
}
