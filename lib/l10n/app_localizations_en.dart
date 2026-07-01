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
  String get medsAddSaveSuccess => 'Medication saved';

  @override
  String get medsEditTitle => 'Edit medication';

  @override
  String get medsEditSaveSuccess => 'Medication updated';

  @override
  String get medsDeleteButtonTooltip => 'Delete medication';

  @override
  String get medsDeleteDialogTitle => 'Delete medication?';

  @override
  String medsDeleteDialogBody(String name) {
    return 'Delete \"$name\"? This can\'t be undone.';
  }

  @override
  String get medsDeleteDialogConfirm => 'Delete';

  @override
  String get medsDeleteDialogCancel => 'Cancel';

  @override
  String get medsDeleteSuccess => 'Medication deleted';

  @override
  String get medsDeleteError =>
      'Couldn\'t delete medication. Please try again.';

  @override
  String get medsAddSaveErrorName => 'Enter a medication name';

  @override
  String get medsAddSaveErrorTimes => 'Add at least one intake time';

  @override
  String get medsAddSaveErrorDuration =>
      'Course duration must be at least 1 day';

  @override
  String get medsAddSaveErrorDose => 'Enter a dose greater than zero';

  @override
  String get medsAddSaveErrorGeneric =>
      'Couldn\'t save medication. Please try again.';

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

  @override
  String get medsListTitle => 'My medications';

  @override
  String get medsListSearchHint => 'Search medications…';

  @override
  String get medsListSearchTooltip => 'Search';

  @override
  String get medsListFilterAll => 'All';

  @override
  String get medsListFilterActive => 'Active';

  @override
  String get medsListSectionContinuous => 'Continuous';

  @override
  String get medsListSectionCourse => 'Courses';

  @override
  String get medsListSectionEmpty => 'Nothing found';

  @override
  String get medsListEmptyTitle => 'No medications yet';

  @override
  String get medsListEmptyBody => 'Tap + to add your first medication';

  @override
  String get medsListStatusActive => 'Active';

  @override
  String get medsListStatusCompleted => 'Completed';

  @override
  String get medsListTypeContinuous => 'continuous';

  @override
  String get medsListTypeCoursePaused => 'Paused';

  @override
  String medsListTypeCourseDay(int current, int total) {
    return 'Day $current/$total';
  }

  @override
  String medsListStock(int remaining, int total) {
    return '$remaining of $total pcs';
  }

  @override
  String get doseUnitTablet => 'tab';

  @override
  String get doseUnitCapsule => 'cap';

  @override
  String get doseUnitMl => 'ml';

  @override
  String get doseUnitMg => 'mg';

  @override
  String get doseUnitDrops => 'drops';

  @override
  String get doseUnitUnits => 'IU';

  @override
  String get doseUnitPuff => 'puff';

  @override
  String get doseUnitApplication => 'dose';

  @override
  String get doseUnitSachet => 'sachet';
}
