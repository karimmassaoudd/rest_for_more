import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether the user already made a choice on the Welcome screen
/// (create account, log in or continue as guest). REST-96 / REST-97.
///
/// Loaded once in main() so the router can check it without waiting.
class WelcomeChoiceStore {
  WelcomeChoiceStore._();
  static final WelcomeChoiceStore instance = WelcomeChoiceStore._();

  static const _key = 'welcome_choice_made';

  bool _chosen = false;

  /// True after the user chose how to start. Then Welcome is skipped.
  bool get hasChosen => _chosen;

  /// Call once in main(), before runApp().
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _chosen = prefs.getBool(_key) ?? false;
  }

  /// Guest chosen, account created or logged in.
  Future<void> markChosen() async {
    _chosen = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  /// Show Welcome again after log out or delete account (REST-101, story 8).
  Future<void> clearChoice() async {
    _chosen = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, false);
  }
}
