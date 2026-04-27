// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get bottomNavToday => 'Today';

  @override
  String get bottomNavMeds => 'Meds';

  @override
  String get bottomNavHistory => 'History';

  @override
  String get settingsAppearanceHeader => 'Appearance';

  @override
  String get settingsUseSystemTheme => 'Use system theme';

  @override
  String get settingsUseSystemThemeSub => 'Follow your device settings';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';
}
