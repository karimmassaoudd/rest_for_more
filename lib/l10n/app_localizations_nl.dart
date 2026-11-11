// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get welcomeTitle => 'Welkom bij Rest For More';

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
}
