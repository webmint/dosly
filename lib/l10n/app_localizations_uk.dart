// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get settingsTooltip => 'Налаштування';

  @override
  String get settingsTitle => 'Налаштування';

  @override
  String get bottomNavToday => 'Сьогодні';

  @override
  String get bottomNavMeds => 'Ліки';

  @override
  String get bottomNavHistory => 'Історія';

  @override
  String get settingsAppearanceHeader => 'Зовнішній вигляд';

  @override
  String get settingsUseSystemTheme => 'Системна тема';

  @override
  String get settingsUseSystemThemeSub =>
      'Використовувати налаштування пристрою';

  @override
  String get settingsThemeLight => 'Світла';

  @override
  String get settingsThemeDark => 'Темна';
}
