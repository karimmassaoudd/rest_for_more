import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's language: English or Dutch.
///
/// One instance for the whole app. main.dart loads it before the first
/// screen and rebuilds MaterialApp whenever it changes, so every screen
/// switches language at once. The choice is saved on the phone.
class LocaleController extends ChangeNotifier {
  LocaleController._();
  static final LocaleController instance = LocaleController._();

  static const _languageKey = 'app_language';

  /// Languages the app has translations for (see lib/l10n/*.arb), each
  /// with its name written in that language. To add a language, add it
  /// here and add its .arb file.
  static const languageNames = {'en': 'English', 'nl': 'Nederlands'};

  Locale _locale = const Locale('en');
  bool _initialized = false;

  /// The language the app is shown in.
  Locale get locale => _locale;

  /// Call once in main(), before runApp().
  ///
  /// Uses the saved choice; without one, the phone's language if it's
  /// supported, otherwise English.
  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_languageKey);
    final device =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;

    final code = languageNames.containsKey(saved)
        ? saved!
        : (languageNames.containsKey(device) ? device : 'en');
    _locale = Locale(code);

    _initialized = true;
    notifyListeners();
  }

  /// Switches the whole app to [languageCode] ('en' or 'nl') and saves it.
  /// Unsupported codes are ignored.
  Future<void> setLanguage(String languageCode) async {
    if (!languageNames.containsKey(languageCode)) return;
    if (_locale.languageCode == languageCode) return;

    _locale = Locale(languageCode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);

    notifyListeners();
  }
}
