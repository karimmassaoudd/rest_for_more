// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeTitle => 'Welcome to\nRest For More';

  @override
  String get welcomeSubtitle =>
      'Put your phone away, build calm routines.\nA RestNest is optional.';

  @override
  String get welcomeGetStarted => 'Get started';

  @override
  String get welcomeHaveAccount => 'Already have an account?';

  @override
  String get welcomeLogIn => 'Log in';

  @override
  String get languageTitle => 'Choose your language';

  @override
  String get languageSubtitle =>
      'You can change this later in your profile settings.';

  @override
  String get languageContinue => 'Continue';

  @override
  String get tutorialFocusTitle => 'Focus on a profile';

  @override
  String get tutorialFocusText =>
      'Choose a profile to focus on for the day and block distracting notifications from your phone.';

  @override
  String get tutorialFocusText2 =>
      'Or create and add your own profile to the list in settings.';

  @override
  String get tutorialFocusProfile1 => 'Focus';

  @override
  String get tutorialFocusProfile2 => 'Read';

  @override
  String get tutorialFocusProfile3 => 'Study';

  @override
  String get tutorialBlockTitle => 'Block distractions';

  @override
  String get tutorialBlockText =>
      'Choose the apps you want to block and start a session.';

  @override
  String get tutorialBlockText2 =>
      'During your session, these apps will remain inaccessible, helping you avoid distractions and stay focused until your session is complete.';

  @override
  String get tutorialReachableTitle => 'Always reachable';

  @override
  String get tutorialReachableText =>
      'Calls and messages are always available during any session.';

  @override
  String get tutorialReachableText2 =>
      'Other application that you choose to stay can also be made available in settings.';

  @override
  String get tutorialTimeTitle => 'Take control of your time';

  @override
  String get tutorialTimeText => 'Set up timers that fit your daily life.';

  @override
  String get tutorialTimeText2 =>
      'Whether you\'re studying, reading, or taking a break from your phone, you decide how long you want to stay focused.';

  @override
  String get tutorialTimeText3 =>
      'Your session continues even when you switch apps or lock your phone.';

  @override
  String get tutorialRoutinesTitle => 'Follow a routine';

  @override
  String get tutorialRoutinesText =>
      'Create your own morning and evening routines.';

  @override
  String get tutorialRoutinesMorning => 'Good morning';

  @override
  String get tutorialRoutinesEvening => 'Good evening';

  @override
  String get tutorialRoutinesText2 =>
      'Choose activities that help you start your day with intention and wind down before bedtime.';

  @override
  String get tutorialControlTitle => 'Stay in control';

  @override
  String get tutorialControlText => 'Need your phone anyways?';

  @override
  String get tutorialControlText2 =>
      'Emergency unlock allows you to end an active session whenever you need it.';

  @override
  String get tutorialStart => 'Start';

  @override
  String get tutorialNext => 'Next';

  @override
  String get tutorialBack => 'Back';

  @override
  String get tutorialDone => 'Done';

  @override
  String get profileHelp => 'Help';

  @override
  String get profileManual => 'How Rest For More works';

  @override
  String get profileLanguageDone => 'Done';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileAppearance => 'Appearance';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileChooseLanguage => 'Choose language';

  @override
  String get profileYourData => 'Your data';

  @override
  String get profileAccount => 'Account';

  @override
  String get profileGuestTitle => 'You\'re using Rest For More as a guest';

  @override
  String get profileGuestDescription =>
      'Your data is only saved on this phone.';

  @override
  String get profileCreateAccount => 'Create account to keep your data';

  @override
  String get profileLogin => 'Log in';

  @override
  String get profileLogout => 'Log out';

  @override
  String get profileLogoutTitle => 'Log out?';

  @override
  String get profileLogoutMessage =>
      'Your focus profiles and routines stay on this phone.';

  @override
  String get profileDelete => 'Delete account';

  @override
  String get profileDeleteTitle => 'Delete your account?';

  @override
  String get profileDeleteMessage =>
      'This permanently removes your account and backed-up data. This can\'t be undone.';

  @override
  String get profileBackup => 'Back up my data';

  @override
  String get profileLastBackup => 'Last backup: never';

  @override
  String get profileComingSoon => 'Coming soon';

  @override
  String get profileAppearanceLight => 'Light';

  @override
  String get profileAppearanceDark => 'Dark';

  @override
  String get profileAppearanceSystem => 'System';

  @override
  String profileAppearanceSemantics(Object selected) {
    return 'Appearance: $selected. Coming soon';
  }
}
