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
  String get tutorialFocusTitle => 'Focus op een profiel';

  @override
  String get tutorialFocusText =>
      'Kies een profiel om op te focussen voor de dag en blokkeer afleidende meldingen van je telefoon.';

  @override
  String get tutorialFocusText2 =>
      'Of maak je eigen profiel en voeg het toe aan de lijst in de instellingen.';

  @override
  String get tutorialFocusProfile1 => 'Focus';

  @override
  String get tutorialFocusProfile2 => 'Lezen';

  @override
  String get tutorialFocusProfile3 => 'Studeren';

  @override
  String get tutorialBlockTitle => 'Blokkeer afleiding';

  @override
  String get tutorialBlockText =>
      'Kies de apps die je wilt blokkeren en start een sessie.';

  @override
  String get tutorialBlockText2 =>
      'Tijdens je sessie blijven deze apps ontoegankelijk, zodat je niet wordt afgeleid en gefocust blijft tot je sessie klaar is.';

  @override
  String get tutorialReachableTitle => 'Altijd bereikbaar';

  @override
  String get tutorialReachableText =>
      'Oproepen en berichten zijn tijdens elke sessie altijd beschikbaar.';

  @override
  String get tutorialReachableText2 =>
      'Andere apps die je beschikbaar wilt houden, kun je in de instellingen toevoegen.';

  @override
  String get tutorialTimeTitle => 'Neem de regie over je tijd';

  @override
  String get tutorialTimeText => 'Stel timers in die passen bij je dag.';

  @override
  String get tutorialTimeText2 =>
      'Of je nu studeert, leest of een pauze neemt van je telefoon: jij bepaalt hoe lang je gefocust blijft.';

  @override
  String get tutorialTimeText3 =>
      'Je sessie loopt door, ook als je van app wisselt of je telefoon vergrendelt.';

  @override
  String get tutorialRoutinesTitle => 'Volg een routine';

  @override
  String get tutorialRoutinesText => 'Maak je eigen ochtend- en avondroutines.';

  @override
  String get tutorialRoutinesMorning => 'Goedemorgen';

  @override
  String get tutorialRoutinesEvening => 'Goedenavond';

  @override
  String get tutorialRoutinesText2 =>
      'Kies activiteiten die je helpen om je dag bewust te beginnen en voor het slapengaan tot rust te komen.';

  @override
  String get tutorialControlTitle => 'Houd de controle';

  @override
  String get tutorialControlText => 'Heb je je telefoon toch nodig?';

  @override
  String get tutorialControlText2 =>
      'Met de noodontgrendeling beëindig je een actieve sessie wanneer je maar wilt.';

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
