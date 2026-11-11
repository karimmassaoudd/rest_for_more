// REST-107 / REST-116 — the app's language (English / Dutch).
//
// TODO:
// - One instance for the whole app (like WelcomeChoiceStore.instance).
// - Load the saved language on start-up; save it when it changes
//   (shared_preferences is already installed).
// - Default: the phone's language if English or Dutch, otherwise English.
// - Tell MaterialApp.router when the language changes, so every screen
//   switches at once.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  // Singleton: one language controller for the entire app.
  static final LocaleController instance = LocaleController._internal();

  LocaleController._internal();

  static const String _languageKey = 'app_language';

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  bool _initialized = false;

  // Initialize language on application startup.
  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();

    final savedLanguage = prefs.getString(_languageKey);

    if (savedLanguage == 'en' || savedLanguage == 'nl') {
      _locale = Locale(savedLanguage!);
    } else {
      // Use phone language if supported.
      final deviceLanguage =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;

      _locale = Locale(deviceLanguage == 'nl' ? 'nl' : 'en');
    }

    _initialized = true;
    notifyListeners();
  }

  // Change language throughout the application.
  Future<void> setLanguage(String languageCode) async {
    if (languageCode != 'en' && languageCode != 'nl') {
      return;
    }

    if (_locale.languageCode == languageCode) return;

    _locale = Locale(languageCode);

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_languageKey, languageCode);

    notifyListeners();
  }

  bool get isDutch => _locale.languageCode == 'nl';

  bool get isEnglish => _locale.languageCode == 'en';
}
