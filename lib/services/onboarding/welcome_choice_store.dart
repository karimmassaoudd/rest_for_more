import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether the user already chose how to start on the Welcome
/// screen: create an account, log in, or continue as a guest.
///
/// Loaded once in main(), so the router can read [hasChosen] straight away
/// without waiting for storage.
class WelcomeChoiceStore {
  WelcomeChoiceStore._();
  static final WelcomeChoiceStore instance = WelcomeChoiceStore._();

  static const _key = 'welcome_choice_made';

  bool _chosen = false;

  /// True once the user has chosen; the router then skips Welcome.
  bool get hasChosen => _chosen;

  /// Call once in main(), before runApp().
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _chosen = prefs.getBool(_key) ?? false;
  }

  /// After choosing guest, creating an account or logging in.
  Future<void> markChosen() async {
    _chosen = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  /// Shows Welcome again, after logging out or deleting the account.
  Future<void> clearChoice() async {
    _chosen = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, false);
  }
}
