import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_nl.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('en'),
    Locale('nl'),
  ];

  /// Title on the Welcome screen; \n breaks it over two lines.
  ///
  /// In en, this message translates to:
  /// **'Welcome to\nRest For More'**
  String get welcomeTitle;

  /// Line under the Welcome title.
  ///
  /// In en, this message translates to:
  /// **'Put your phone away, build calm routines.\nA RestNest is optional.'**
  String get welcomeSubtitle;

  /// Main button on the Welcome screen; starts onboarding.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get welcomeGetStarted;

  /// Text before the log-in link on the Welcome screen.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get welcomeHaveAccount;

  /// Link on the Welcome screen that opens log-in.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get welcomeLogIn;

  /// Title of the language screen in onboarding.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get languageTitle;

  /// Text under the language screen title.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in your profile settings.'**
  String get languageSubtitle;

  /// Button at the bottom of the language screen.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get languageContinue;

  /// Tutorial page 1 title.
  ///
  /// In en, this message translates to:
  /// **'Focus on a profile'**
  String get tutorialFocusTitle;

  /// Tutorial page 1 text.
  ///
  /// In en, this message translates to:
  /// **'Choose a profile to focus on for the day and block distracting notifications from your phone.'**
  String get tutorialFocusText;

  /// Tutorial page 1 text under the profile list.
  ///
  /// In en, this message translates to:
  /// **'Or create and add your own profile to the list in settings.'**
  String get tutorialFocusText2;

  /// Tutorial page 1 example profile.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get tutorialFocusProfile1;

  /// Tutorial page 1 example profile.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get tutorialFocusProfile2;

  /// Tutorial page 1 example profile.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get tutorialFocusProfile3;

  /// Tutorial page 2 title.
  ///
  /// In en, this message translates to:
  /// **'Block distractions'**
  String get tutorialBlockTitle;

  /// Tutorial page 2 text.
  ///
  /// In en, this message translates to:
  /// **'Choose the apps you want to block and start a session.'**
  String get tutorialBlockText;

  /// Tutorial page 2 text under the app icons.
  ///
  /// In en, this message translates to:
  /// **'During your session, these apps will remain inaccessible, helping you avoid distractions and stay focused until your session is complete.'**
  String get tutorialBlockText2;

  /// Tutorial page 3 title.
  ///
  /// In en, this message translates to:
  /// **'Always reachable'**
  String get tutorialReachableTitle;

  /// Tutorial page 3 text.
  ///
  /// In en, this message translates to:
  /// **'Calls and messages are always available during any session.'**
  String get tutorialReachableText;

  /// Tutorial page 3 text under the first one.
  ///
  /// In en, this message translates to:
  /// **'Other application that you choose to stay can also be made available in settings.'**
  String get tutorialReachableText2;

  /// Tutorial page 4 title.
  ///
  /// In en, this message translates to:
  /// **'Take control of your time'**
  String get tutorialTimeTitle;

  /// Tutorial page 4 text next to the timer phone.
  ///
  /// In en, this message translates to:
  /// **'Set up timers that fit your daily life.'**
  String get tutorialTimeText;

  /// Tutorial page 4 text under the timer phone.
  ///
  /// In en, this message translates to:
  /// **'Whether you\'re studying, reading, or taking a break from your phone, you decide how long you want to stay focused.'**
  String get tutorialTimeText2;

  /// Tutorial page 4 last text.
  ///
  /// In en, this message translates to:
  /// **'Your session continues even when you switch apps or lock your phone.'**
  String get tutorialTimeText3;

  /// Tutorial page 5 title.
  ///
  /// In en, this message translates to:
  /// **'Follow a routine'**
  String get tutorialRoutinesTitle;

  /// Tutorial page 5 text next to the routine cards.
  ///
  /// In en, this message translates to:
  /// **'Create your own morning and evening routines.'**
  String get tutorialRoutinesText;

  /// Text on the morning routine card (tutorial page 5).
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get tutorialRoutinesMorning;

  /// Text on the evening routine card (tutorial page 5).
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get tutorialRoutinesEvening;

  /// Tutorial page 5 text under the routine cards.
  ///
  /// In en, this message translates to:
  /// **'Choose activities that help you start your day with intention and wind down before bedtime.'**
  String get tutorialRoutinesText2;

  /// Tutorial page 6 title.
  ///
  /// In en, this message translates to:
  /// **'Stay in control'**
  String get tutorialControlTitle;

  /// Tutorial page 6 text.
  ///
  /// In en, this message translates to:
  /// **'Need your phone anyways?'**
  String get tutorialControlText;

  /// Tutorial page 6 text under the first one.
  ///
  /// In en, this message translates to:
  /// **'Emergency unlock allows you to end an active session whenever you need it.'**
  String get tutorialControlText2;

  /// Tutorial button on the last page.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get tutorialStart;

  /// Tutorial button on every page except the last.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tutorialNext;

  /// Screen-reader label of the tutorial's back arrow.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get tutorialBack;

  /// Tutorial button on the last page when opened from Profile.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tutorialDone;

  /// Profile section: manual.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get profileHelp;

  /// Profile row that reopens the tutorial as a manual.
  ///
  /// In en, this message translates to:
  /// **'How Rest For More works'**
  String get profileManual;

  /// Closes the language picker on the Profile screen.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get profileLanguageDone;

  /// Title of the Profile tab.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// Profile section: light / dark / system.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get profileAppearance;

  /// Profile section: app language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// Title of the language picker on the Profile screen.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get profileChooseLanguage;

  /// Profile section: backup.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get profileYourData;

  /// Profile section: log in / out, delete account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileAccount;

  /// Profile card title when not logged in.
  ///
  /// In en, this message translates to:
  /// **'You\'re using Rest For More as a guest'**
  String get profileGuestTitle;

  /// Profile card text when not logged in.
  ///
  /// In en, this message translates to:
  /// **'Your data is only saved on this phone.'**
  String get profileGuestDescription;

  /// Profile button for guests; opens sign-up.
  ///
  /// In en, this message translates to:
  /// **'Create account to keep your data'**
  String get profileCreateAccount;

  /// Profile button for guests; opens log-in.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get profileLogin;

  /// Profile button when logged in.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get profileLogout;

  /// Title of the log-out confirm dialog.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get profileLogoutTitle;

  /// Text of the log-out confirm dialog.
  ///
  /// In en, this message translates to:
  /// **'Your focus profiles and routines stay on this phone.'**
  String get profileLogoutMessage;

  /// Profile button and confirm label for deleting the account.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get profileDelete;

  /// Title of the delete-account confirm dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get profileDeleteTitle;

  /// Text of the delete-account confirm dialog.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes your account and backed-up data. This can\'t be undone.'**
  String get profileDeleteMessage;

  /// Profile backup button (not built yet).
  ///
  /// In en, this message translates to:
  /// **'Back up my data'**
  String get profileBackup;

  /// Shown under the backup button.
  ///
  /// In en, this message translates to:
  /// **'Last backup: never'**
  String get profileLastBackup;

  /// Badge or snackbar for features that aren't built yet.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get profileComingSoon;

  /// Appearance option.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get profileAppearanceLight;

  /// Appearance option.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get profileAppearanceDark;

  /// Appearance option: follow the phone's setting.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get profileAppearanceSystem;

  /// Screen-reader label of the appearance switch; {selected} is Light, Dark or System.
  ///
  /// In en, this message translates to:
  /// **'Appearance: {selected}. Coming soon'**
  String profileAppearanceSemantics(Object selected);
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
      <String>['en', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'nl':
      return AppLocalizationsNl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
