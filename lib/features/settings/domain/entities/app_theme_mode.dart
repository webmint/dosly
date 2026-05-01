/// Domain-owned theme-mode enum.
///
/// dosly's settings layer must be pure Dart per constitution §2.1
/// (FORBIDDEN imports in `domain/`: anything from `package:flutter/*`).
/// `AppThemeMode` is the domain-typed replacement for Flutter's `ThemeMode`
/// in [AppSettings.manualThemeMode]. The `Flutter SDK ↔ domain` mapping
/// is confined to the presentation seam in `lib/app.dart`.
///
/// Cardinality is intentionally **two values**, not three. The `system`
/// concept is owned by the orthogonal [AppSettings.useSystemTheme] `bool`
/// flag — it is impossible by construction to persist `system` as a
/// manual override here.
library;

/// User-facing theme choice for the manual theme override.
///
/// Persisted to `SharedPreferences` as the [code] string (`'light'` /
/// `'dark'`) — order-independent across SDK changes and matches the
/// contract documented in `docs/features/settings.md`.
enum AppThemeMode {
  /// Light Material 3 theme.
  light(code: 'light'),

  /// Dark Material 3 theme.
  dark(code: 'dark');

  const AppThemeMode({required this.code});

  /// Stable string code persisted to local storage.
  ///
  /// Persistence reads use [fromCodeOrDefault] for graceful fallback on
  /// unknown / corrupted / legacy values.
  final String code;

  /// Resolves a stored code back to its [AppThemeMode] value.
  ///
  /// Returns [AppThemeMode.light] for any unknown, null, or empty input
  /// — same defensive pattern used by `getManualLanguage()` for
  /// `AppLanguage` in `settings_local_data_source.dart`.
  static AppThemeMode fromCodeOrDefault(String? code) =>
      AppThemeMode.values.firstWhere(
        (m) => m.code == code,
        orElse: () => AppThemeMode.light,
      );
}
