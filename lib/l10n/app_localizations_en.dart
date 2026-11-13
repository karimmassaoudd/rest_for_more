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
  String get tutorialFocusTitle => 'Focus sessions';

  @override
  String get tutorialFocusText =>
      'Pick a profile like Study or Read, choose a time, and distracting apps are blocked until it ends.';

  @override
  String get tutorialReachableTitle => 'Always reachable';

  @override
  String get tutorialReachableText =>
      'Calls, messages and the apps you choose stay available during every session.';

  @override
  String get tutorialRoutinesTitle => 'Morning and evening routines';

  @override
  String get tutorialRoutinesText =>
      'Small calm steps to start and end your day without your phone.';

  @override
  String get tutorialControlTitle => 'You stay in control';

  @override
  String get tutorialControlText =>
      'Need your phone after all? Emergency unlock ends a session whenever you need it.';

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
