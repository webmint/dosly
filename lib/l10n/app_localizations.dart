import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_uk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('uk'),
  ];

  /// Tooltip for the Settings icon button in the HomeScreen AppBar.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// Localized title for the Settings screen AppBar.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Label for the Today destination in the home bottom navigation bar.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get bottomNavToday;

  /// Label for the Meds destination in the home bottom navigation bar.
  ///
  /// In en, this message translates to:
  /// **'Meds'**
  String get bottomNavMeds;

  /// Label for the History destination in the home bottom navigation bar.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get bottomNavHistory;

  /// Section header for the appearance/theme settings group.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceHeader;

  /// Label for the switch that toggles following the device system theme.
  ///
  /// In en, this message translates to:
  /// **'Use system theme'**
  String get settingsUseSystemTheme;

  /// Subtitle for the system theme switch describing what the toggle does.
  ///
  /// In en, this message translates to:
  /// **'Follow your device settings'**
  String get settingsUseSystemThemeSub;

  /// Label for the Light theme option in the theme selector.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// Label for the Dark theme option in the theme selector.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// Section header for the language settings group on the Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageHeader;

  /// Label for the switch that toggles following the device-resolved language.
  ///
  /// In en, this message translates to:
  /// **'Use device language'**
  String get settingsUseDeviceLanguage;

  /// Subtitle for the device-language switch describing what the toggle does.
  ///
  /// In en, this message translates to:
  /// **'Follow your device settings'**
  String get settingsUseDeviceLanguageSub;

  /// SnackBar message shown on the Settings screen when a preference change fails to persist (e.g. SharedPreferences write error).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your preference. Please try again.'**
  String get settingsPersistenceError;

  /// Header for the intake-behavior settings section.
  ///
  /// In en, this message translates to:
  /// **'Intake'**
  String get settingsIntakeHeader;

  /// Label for the intake window stepper.
  ///
  /// In en, this message translates to:
  /// **'Intake window'**
  String get settingsIntakeWindowLabel;

  /// Subtitle explaining the intake window setting.
  ///
  /// In en, this message translates to:
  /// **'How long after the scheduled time a dose can still be marked'**
  String get settingsIntakeWindowDescription;

  /// Label for the grace period stepper.
  ///
  /// In en, this message translates to:
  /// **'Grace period'**
  String get settingsGracePeriodLabel;

  /// Subtitle explaining the grace period setting.
  ///
  /// In en, this message translates to:
  /// **'How long you can undo a dose after marking it'**
  String get settingsGracePeriodDescription;

  /// Label for the allow-mark-ahead switch.
  ///
  /// In en, this message translates to:
  /// **'Allow marking ahead'**
  String get settingsAllowMarkAheadLabel;

  /// Subtitle explaining the allow-mark-ahead setting.
  ///
  /// In en, this message translates to:
  /// **'Let doses be marked before their window opens'**
  String get settingsAllowMarkAheadDescription;

  /// Displays a minute count for a setting value.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String settingsMinutesValue(int minutes);

  /// Tooltip for a stepper increment button.
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get settingsStepperIncreaseTooltip;

  /// Tooltip for a stepper decrement button.
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get settingsStepperDecreaseTooltip;

  /// Tooltip for the FAB on the Meds screen that opens the placeholder Add-medication modal.
  ///
  /// In en, this message translates to:
  /// **'Add medication'**
  String get medsAddFabTooltip;

  /// Title shown at the top of the placeholder Add-medication full-screen modal on the Meds screen.
  ///
  /// In en, this message translates to:
  /// **'Add medication'**
  String get medsAddTitle;

  /// Floating label for the medication-name text field in the Add-medication modal.
  ///
  /// In en, this message translates to:
  /// **'Medication name'**
  String get medsAddNameLabel;

  /// Label on the Save button in the Add-medication modal (visual-only placeholder, no-op in iteration 1).
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get medsAddSaveButton;

  /// Floating label on the medication-form picker display row in the Add-medication modal.
  ///
  /// In en, this message translates to:
  /// **'Medication form'**
  String get medsAddFormLabel;

  /// Display-row text shown before a medication form is selected.
  ///
  /// In en, this message translates to:
  /// **'Choose a form'**
  String get medsAddFormPlaceholder;

  /// Title above the medication-form options grid.
  ///
  /// In en, this message translates to:
  /// **'Common forms'**
  String get medsAddFormGridTitle;

  /// Medication-form option name (tablet) in the Add-medication picker.
  ///
  /// In en, this message translates to:
  /// **'Tablet'**
  String get medsAddFormTablet;

  /// Sub-description for the tablet medication form.
  ///
  /// In en, this message translates to:
  /// **'Compressed form'**
  String get medsAddFormTabletSub;

  /// Medication-form option name (capsule).
  ///
  /// In en, this message translates to:
  /// **'Capsule'**
  String get medsAddFormCapsule;

  /// Sub-description for the capsule medication form.
  ///
  /// In en, this message translates to:
  /// **'Hard gelatin shell'**
  String get medsAddFormCapsuleSub;

  /// Medication-form option name (syrup).
  ///
  /// In en, this message translates to:
  /// **'Syrup'**
  String get medsAddFormSyrup;

  /// Sub-description for the syrup medication form.
  ///
  /// In en, this message translates to:
  /// **'Liquid dosage form'**
  String get medsAddFormSyrupSub;

  /// Medication-form option name (drops).
  ///
  /// In en, this message translates to:
  /// **'Drops'**
  String get medsAddFormDrops;

  /// Sub-description for the drops medication form.
  ///
  /// In en, this message translates to:
  /// **'Liquid drop form'**
  String get medsAddFormDropsSub;

  /// Medication-form option name (injection).
  ///
  /// In en, this message translates to:
  /// **'Injection'**
  String get medsAddFormInjection;

  /// Sub-description for the injection medication form.
  ///
  /// In en, this message translates to:
  /// **'Intramuscular / IV'**
  String get medsAddFormInjectionSub;

  /// Medication-form option name (inhaler).
  ///
  /// In en, this message translates to:
  /// **'Inhaler'**
  String get medsAddFormInhaler;

  /// Sub-description for the inhaler medication form.
  ///
  /// In en, this message translates to:
  /// **'Aerosol form'**
  String get medsAddFormInhalerSub;

  /// Medication-form option name (cream/ointment).
  ///
  /// In en, this message translates to:
  /// **'Cream / Ointment'**
  String get medsAddFormCream;

  /// Sub-description for the cream/ointment medication form.
  ///
  /// In en, this message translates to:
  /// **'Topical form'**
  String get medsAddFormCreamSub;

  /// Medication-form option name (sachet).
  ///
  /// In en, this message translates to:
  /// **'Sachet'**
  String get medsAddFormSachet;

  /// Sub-description for the sachet medication form.
  ///
  /// In en, this message translates to:
  /// **'Soluble powder'**
  String get medsAddFormSachetSub;

  /// Label for the dose amount text field (liquid forms)
  ///
  /// In en, this message translates to:
  /// **'Dose'**
  String get medsAddDoseLabel;

  /// Label for the dose unit dropdown
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get medsAddDoseUnitLabel;

  /// Floating label for the quantity-per-intake stepper (tablet/capsule)
  ///
  /// In en, this message translates to:
  /// **'Quantity per intake'**
  String get medsAddQuantityLabel;

  /// Header of the pack-stock card
  ///
  /// In en, this message translates to:
  /// **'Pack stock'**
  String get medsAddStockTitle;

  /// Explanatory note under the pack-stock card header
  ///
  /// In en, this message translates to:
  /// **'For capsules, tablets and similar forms. Decreases automatically after each intake.'**
  String get medsAddStockNote;

  /// Label for the remaining-in-pack stock input
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get medsAddStockRemainingLabel;

  /// Label for the total-in-pack stock input
  ///
  /// In en, this message translates to:
  /// **'Total in pack'**
  String get medsAddStockTotalLabel;

  /// Label for the low-stock warning threshold input
  ///
  /// In en, this message translates to:
  /// **'Warn when remaining reaches'**
  String get medsAddStockWarnLabel;

  /// Dose unit abbreviation: millilitres
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get medsAddUnitMl;

  /// Dose unit abbreviation: milligrams
  ///
  /// In en, this message translates to:
  /// **'mg'**
  String get medsAddUnitMg;

  /// Dose unit: international units (IU) — e.g. insulin, vitamins
  ///
  /// In en, this message translates to:
  /// **'IU'**
  String get medsAddUnitUnits;

  /// Dose unit abbreviation: drops
  ///
  /// In en, this message translates to:
  /// **'drops'**
  String get medsAddUnitDrops;

  /// Quantity unit abbreviation: tablets
  ///
  /// In en, this message translates to:
  /// **'tab'**
  String get medsAddUnitTablet;

  /// Quantity unit abbreviation: capsules
  ///
  /// In en, this message translates to:
  /// **'cap'**
  String get medsAddUnitCapsule;

  /// Section title for the intake-time chips in the Add-medication modal.
  ///
  /// In en, this message translates to:
  /// **'Intake time'**
  String get medsAddTimeTitle;

  /// Label of the dashed add chip that opens the time picker to append an intake time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get medsAddTimeAddChip;

  /// Tooltip/semantics label for the delete (×) affordance on an intake-time chip.
  ///
  /// In en, this message translates to:
  /// **'Remove time'**
  String get medsAddTimeRemoveTooltip;

  /// SnackBar message shown when the user picks an intake time that is already in the list.
  ///
  /// In en, this message translates to:
  /// **'This time is already added'**
  String get medsAddTimeDuplicate;

  /// Section title for the intake-type selector in the Add-medication modal.
  ///
  /// In en, this message translates to:
  /// **'Intake type'**
  String get medsAddIntakeTypeTitle;

  /// Intake-type option label for ongoing/continuous medication use.
  ///
  /// In en, this message translates to:
  /// **'Continuous'**
  String get medsAddIntakeTypeContinuous;

  /// Intake-type option label for a fixed-duration medication course.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get medsAddIntakeTypeCourse;

  /// Section title for the course-parameter fields (duration, pause, start date).
  ///
  /// In en, this message translates to:
  /// **'Course parameters'**
  String get medsAddCourseParamsTitle;

  /// Label for the course duration input field (value in days).
  ///
  /// In en, this message translates to:
  /// **'Duration (days)'**
  String get medsAddCourseDurationLabel;

  /// Label for the pause-between-courses input field (value in days).
  ///
  /// In en, this message translates to:
  /// **'Pause (days)'**
  String get medsAddCoursePauseLabel;

  /// Label for the course start-date picker field.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get medsAddCourseStartLabel;

  /// Course info chip: localized date range plus a pluralized day count.
  ///
  /// In en, this message translates to:
  /// **'Course: {range} ({count, plural, =1{1 day} other{{count} days}})'**
  String medsAddCourseRangeLabel(String range, int count);

  /// Course info-chip fallback shown when the duration is empty or not a positive integer.
  ///
  /// In en, this message translates to:
  /// **'Course starts {date}'**
  String medsAddCourseStartOnly(String date);

  /// SnackBar message shown when a medication is successfully saved from the Add-medication modal.
  ///
  /// In en, this message translates to:
  /// **'Medication saved'**
  String get medsAddSaveSuccess;

  /// App-bar title shown when editing an existing medication.
  ///
  /// In en, this message translates to:
  /// **'Edit medication'**
  String get medsEditTitle;

  /// SnackBar message shown after an existing medication is successfully updated.
  ///
  /// In en, this message translates to:
  /// **'Medication updated'**
  String get medsEditSaveSuccess;

  /// Tooltip for the AppBar trash-icon button that deletes the current medication.
  ///
  /// In en, this message translates to:
  /// **'Delete medication'**
  String get medsDeleteButtonTooltip;

  /// Title of the confirmation dialog shown before deleting a medication.
  ///
  /// In en, this message translates to:
  /// **'Delete medication?'**
  String get medsDeleteDialogTitle;

  /// Body text of the delete-confirmation dialog, naming the medication to be deleted.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This can\'t be undone.'**
  String medsDeleteDialogBody(String name);

  /// Label for the destructive confirm button in the delete-medication dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get medsDeleteDialogConfirm;

  /// Label for the cancel button in the delete-medication dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get medsDeleteDialogCancel;

  /// SnackBar message shown after a medication is successfully deleted.
  ///
  /// In en, this message translates to:
  /// **'Medication deleted'**
  String get medsDeleteSuccess;

  /// SnackBar message shown when deleting a medication fails for an unexpected reason.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete medication. Please try again.'**
  String get medsDeleteError;

  /// Validation error shown when the user attempts to save without entering a medication name.
  ///
  /// In en, this message translates to:
  /// **'Enter a medication name'**
  String get medsAddSaveErrorName;

  /// Validation error shown when the user attempts to save without adding any intake times.
  ///
  /// In en, this message translates to:
  /// **'Add at least one intake time'**
  String get medsAddSaveErrorTimes;

  /// Validation error shown when the course duration is set to zero or is missing.
  ///
  /// In en, this message translates to:
  /// **'Course duration must be at least 1 day'**
  String get medsAddSaveErrorDuration;

  /// Validation error shown when a dose-based form has a non-positive dose value.
  ///
  /// In en, this message translates to:
  /// **'Enter a dose greater than zero'**
  String get medsAddSaveErrorDose;

  /// Generic SnackBar error message shown when saving a medication fails for an unexpected reason.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save medication. Please try again.'**
  String get medsAddSaveErrorGeneric;

  /// Title in the AppBar of the router error screen shown when navigation lands on a path with no registered route (e.g., a malformed deep link).
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get errorScreenTitle;

  /// Body text on the router error screen explaining that the requested destination was not found.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find that destination.'**
  String get errorScreenBody;

  /// Label for the FilledButton on the router error screen that returns the user to the home route ('/').
  ///
  /// In en, this message translates to:
  /// **'Go to home'**
  String get errorScreenGoHome;

  /// Label shown on the startup splash screen while app preferences are being loaded.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get splashLoading;

  /// Message on the startup error screen shown when SharedPreferences hydration fails at app launch.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your preferences.'**
  String get prefsLoadErrorMessage;

  /// Label for the button on the startup error screen that retries loading preferences.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get prefsLoadRetry;

  /// AppBar title for the medications list screen.
  ///
  /// In en, this message translates to:
  /// **'My medications'**
  String get medsListTitle;

  /// Hint text inside the search field on the medications list screen.
  ///
  /// In en, this message translates to:
  /// **'Search medications…'**
  String get medsListSearchHint;

  /// Tooltip for the search icon button on the medications list screen.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get medsListSearchTooltip;

  /// Filter chip label showing all medications (active + completed).
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get medsListFilterAll;

  /// Filter chip label showing only active medications.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get medsListFilterActive;

  /// Section header for the continuous-intake medications group in the list.
  ///
  /// In en, this message translates to:
  /// **'Continuous'**
  String get medsListSectionContinuous;

  /// Section header for the course-intake medications group in the list.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get medsListSectionCourse;

  /// Placeholder text shown inside a section when no items match the current filter/search.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get medsListSectionEmpty;

  /// Title of the empty-state illustration shown when the medications list has no entries at all.
  ///
  /// In en, this message translates to:
  /// **'No medications yet'**
  String get medsListEmptyTitle;

  /// Body text of the empty-state illustration on the medications list screen.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first medication'**
  String get medsListEmptyBody;

  /// Status badge label shown on a medication card when the medication is currently active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get medsListStatusActive;

  /// Status badge label shown on a medication card when the course has been completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get medsListStatusCompleted;

  /// Lowercase type label shown in the subtitle of a continuous-intake medication card.
  ///
  /// In en, this message translates to:
  /// **'continuous'**
  String get medsListTypeContinuous;

  /// Type label shown in the subtitle of a course medication card when the course is in its pause period.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get medsListTypeCoursePaused;

  /// Type label shown in the subtitle of a course medication card indicating current day progress.
  ///
  /// In en, this message translates to:
  /// **'Day {current}/{total}'**
  String medsListTypeCourseDay(int current, int total);

  /// Stock indicator shown on a medication card: remaining units out of total pack size.
  ///
  /// In en, this message translates to:
  /// **'{remaining} of {total} pcs'**
  String medsListStock(int remaining, int total);

  /// Short dose-unit abbreviation for tablets, shown in medication card subtitle.
  ///
  /// In en, this message translates to:
  /// **'tab'**
  String get doseUnitTablet;

  /// Short dose-unit abbreviation for capsules, shown in medication card subtitle.
  ///
  /// In en, this message translates to:
  /// **'cap'**
  String get doseUnitCapsule;

  /// Short dose-unit abbreviation for millilitres, shown in medication card subtitle.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get doseUnitMl;

  /// Short dose-unit abbreviation for milligrams, shown in medication card subtitle.
  ///
  /// In en, this message translates to:
  /// **'mg'**
  String get doseUnitMg;

  /// Short dose-unit abbreviation for drops, shown in medication card subtitle.
  ///
  /// In en, this message translates to:
  /// **'drops'**
  String get doseUnitDrops;

  /// Short dose-unit abbreviation for international units (IU), shown in medication card subtitle.
  ///
  /// In en, this message translates to:
  /// **'IU'**
  String get doseUnitUnits;

  /// Short dose-unit abbreviation for inhaler puffs, shown in medication card subtitle.
  ///
  /// In en, this message translates to:
  /// **'puff'**
  String get doseUnitPuff;

  /// Short dose-unit abbreviation for a generic application/dose (cream, ointment), shown in medication card subtitle.
  ///
  /// In en, this message translates to:
  /// **'dose'**
  String get doseUnitApplication;

  /// Short dose-unit abbreviation for sachets, shown in medication card subtitle.
  ///
  /// In en, this message translates to:
  /// **'sachet'**
  String get doseUnitSachet;

  /// AppBar title for the Today screen.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayTitle;

  /// Label for the action button on a Today dose row that marks the dose as taken.
  ///
  /// In en, this message translates to:
  /// **'Take'**
  String get todayMarkTaken;

  /// Label for the action button on a Today dose row that marks the dose as skipped.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get todaySkip;

  /// Label for the action that reverts a dose on the Today screen back to its pending state after being marked taken or skipped.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get todayUndo;

  /// Status label shown on a Today dose row once the dose has been marked as taken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get todayStatusTaken;

  /// Status label shown on a Today dose row once the dose has been marked as skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get todayStatusSkipped;

  /// Title of the empty-state illustration shown on the Today screen when no doses are scheduled.
  ///
  /// In en, this message translates to:
  /// **'Nothing due today'**
  String get todayEmptyTitle;

  /// Body text of the empty-state illustration on the Today screen.
  ///
  /// In en, this message translates to:
  /// **'You have no doses scheduled for today.'**
  String get todayEmptyBody;

  /// Error message shown on the Today screen when loading today's doses fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load today\'s doses.'**
  String get todayLoadError;

  /// SnackBar shown when marking a dose taken/skipped or undoing it fails.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get todayActionError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
