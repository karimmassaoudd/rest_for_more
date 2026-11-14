// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get welcomeTitle => 'Welkom bij\nRest For More';

  @override
  String get welcomeSubtitle =>
      'Leg je telefoon weg en bouw rustige routines.\nEen RestNest is optioneel.';

  @override
  String get welcomeGetStarted => 'Aan de slag';

  @override
  String get welcomeHaveAccount => 'Heb je al een account?';

  @override
  String get welcomeLogIn => 'Inloggen';

  @override
  String get languageTitle => 'Kies je taal';

  @override
  String get languageSubtitle =>
      'Je kunt dit later wijzigen in je profielinstellingen.';

  @override
  String get languageContinue => 'Doorgaan';

  @override
  String get tutorialFocusTitle => 'Focussessies';

  @override
  String get tutorialFocusText =>
      'Kies een profiel zoals Studeren of Lezen, kies een tijd, en afleidende apps worden geblokkeerd tot de sessie voorbij is.';

  @override
  String get tutorialReachableTitle => 'Altijd bereikbaar';

  @override
  String get tutorialReachableText =>
      'Oproepen, berichten en de apps die je kiest blijven tijdens elke sessie beschikbaar.';

  @override
  String get tutorialRoutinesTitle => 'Ochtend- en avondroutines';

  @override
  String get tutorialRoutinesText =>
      'Kleine, rustige stappen om je dag te beginnen en af te sluiten zonder je telefoon.';

  @override
  String get tutorialControlTitle => 'Jij houdt de controle';

  @override
  String get tutorialControlText =>
      'Heb je je telefoon toch nodig? Met de noodontgrendeling beëindig je een sessie wanneer je maar wilt.';

  @override
  String get tutorialStart => 'Starten';

  @override
  String get tutorialNext => 'Volgende';

  @override
  String get tutorialBack => 'Terug';

  @override
  String get tutorialDone => 'Klaar';

  @override
  String get profileHelp => 'Hulp';

  @override
  String get profileManual => 'Zo werkt Rest For More';

  @override
  String get profileLanguageDone => 'Gereed';

  @override
  String get profileTitle => 'Profiel';

  @override
  String get profileAppearance => 'Weergave';

  @override
  String get profileLanguage => 'Taal';

  @override
  String get profileChooseLanguage => 'Kies je taal';

  @override
  String get profileYourData => 'Jouw gegevens';

  @override
  String get profileAccount => 'Account';

  @override
  String get profileGuestTitle => 'Je gebruikt Rest For More als gast';

  @override
  String get profileGuestDescription =>
      'Je gegevens worden alleen op deze telefoon opgeslagen.';

  @override
  String get profileCreateAccount =>
      'Account aanmaken om je gegevens te bewaren';

  @override
  String get profileLogin => 'Inloggen';

  @override
  String get profileLogout => 'Uitloggen';

  @override
  String get profileLogoutTitle => 'Uitloggen?';

  @override
  String get profileLogoutMessage =>
      'Je focusprofielen en routines blijven op deze telefoon staan.';

  @override
  String get profileDelete => 'Account verwijderen';

  @override
  String get profileDeleteTitle => 'Je account verwijderen?';

  @override
  String get profileDeleteMessage =>
      'Je account en back-upgegevens worden permanent verwijderd. Dit kan niet ongedaan worden gemaakt.';

  @override
  String get profileBackup => 'Maak een back-up van mijn gegevens';

  @override
  String get profileLastBackup => 'Laatste back-up: nooit';

  @override
  String get profileComingSoon => 'Binnenkort beschikbaar';

  @override
  String get profileAppearanceLight => 'Licht';

  @override
  String get profileAppearanceDark => 'Donker';

  @override
  String get profileAppearanceSystem => 'Systeem';

  @override
  String profileAppearanceSemantics(Object selected) {
    return 'Weergave: $selected. Binnenkort beschikbaar';
  }
}
