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

  @override
  String get settingsLanguageHeader => 'Language';

  @override
  String get settingsUseDeviceLanguage => 'Use device language';

  @override
  String get settingsUseDeviceLanguageSub => 'Follow your device settings';

  @override
  String get settingsPersistenceError =>
      'Couldn\'t save your preference. Please try again.';

  @override
  String get medsAddFabTooltip => 'Add medication';

  @override
  String get medsAddTitle => 'Add medication';

  @override
  String get medsAddNameLabel => 'Medication name';

  @override
  String get medsAddSaveButton => 'Save';

  @override
  String get medsAddFormLabel => 'Medication form';

  @override
  String get medsAddFormPlaceholder => 'Choose a form';

  @override
  String get medsAddFormGridTitle => 'Common forms';

  @override
  String get medsAddFormTablet => 'Tablet';

  @override
  String get medsAddFormTabletSub => 'Compressed form';

  @override
  String get medsAddFormCapsule => 'Capsule';

  @override
  String get medsAddFormCapsuleSub => 'Hard gelatin shell';

  @override
  String get medsAddFormSyrup => 'Syrup';

  @override
  String get medsAddFormSyrupSub => 'Liquid dosage form';

  @override
  String get medsAddFormDrops => 'Drops';

  @override
  String get medsAddFormDropsSub => 'Liquid drop form';

  @override
  String get medsAddFormInjection => 'Injection';

  @override
  String get medsAddFormInjectionSub => 'Intramuscular / IV';

  @override
  String get medsAddFormInhaler => 'Inhaler';

  @override
  String get medsAddFormInhalerSub => 'Aerosol form';

  @override
  String get medsAddFormCream => 'Cream / Ointment';

  @override
  String get medsAddFormCreamSub => 'Topical form';

  @override
  String get medsAddFormSachet => 'Sachet';

  @override
  String get medsAddFormSachetSub => 'Soluble powder';

  @override
  String get medsAddDoseLabel => 'Dose';

  @override
  String get medsAddDoseUnitLabel => 'Unit';

  @override
  String get medsAddQuantityLabel => 'Quantity per intake';

  @override
  String get medsAddStockTitle => 'Pack stock';

  @override
  String get medsAddStockNote =>
      'For capsules, tablets and similar forms. Decreases automatically after each intake.';

  @override
  String get medsAddStockRemainingLabel => 'Remaining';

  @override
  String get medsAddStockTotalLabel => 'Total in pack';

  @override
  String get medsAddStockWarnLabel => 'Warn when remaining reaches';

  @override
  String get medsAddUnitMl => 'ml';

  @override
  String get medsAddUnitMg => 'mg';

  @override
  String get medsAddUnitUnits => 'IU';

  @override
  String get medsAddUnitDrops => 'drops';

  @override
  String get medsAddUnitTablet => 'tab';

  @override
  String get medsAddUnitCapsule => 'cap';

  @override
  String get medsAddTimeTitle => 'Intake time';

  @override
  String get medsAddTimeAddChip => 'Time';

  @override
  String get medsAddTimeRemoveTooltip => 'Remove time';

  @override
  String get medsAddTimeDuplicate => 'This time is already added';

  @override
  String get medsAddIntakeTypeTitle => 'Intake type';

  @override
  String get medsAddIntakeTypeContinuous => 'Continuous';

  @override
  String get medsAddIntakeTypeCourse => 'Course';

  @override
  String get medsAddCourseParamsTitle => 'Course parameters';

  @override
  String get medsAddCourseDurationLabel => 'Duration (days)';

  @override
  String get medsAddCoursePauseLabel => 'Pause (days)';

  @override
  String get medsAddCourseStartLabel => 'Start date';

  @override
  String medsAddCourseRangeLabel(String range, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return 'Course: $range ($_temp0)';
  }

  @override
  String medsAddCourseStartOnly(String date) {
    return 'Course starts $date';
  }

  @override
  String get errorScreenTitle => 'Page not found';

  @override
  String get errorScreenBody => 'We couldn\'t find that destination.';

  @override
  String get errorScreenGoHome => 'Go to home';

  @override
  String get splashLoading => 'Loading…';

  @override
  String get prefsLoadErrorMessage => 'We couldn\'t load your preferences.';

  @override
  String get prefsLoadRetry => 'Retry';
}
