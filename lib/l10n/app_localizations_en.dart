// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeTitle => 'Welcome to Rest For More';

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
}
