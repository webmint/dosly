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
