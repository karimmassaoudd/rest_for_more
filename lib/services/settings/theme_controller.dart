import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's Light / Dark / System choice for the whole app.
///
/// One shared instance. `main.dart` calls [initialize] before `runApp`
/// and rebuilds MaterialApp when it changes; the profile screen calls
/// [setThemeMode]. Defaults to following the system setting.
class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const String _storageKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  /// Loads the saved choice. No notify needed: runs before the app starts.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_storageKey);

    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == savedMode,
      orElse: () => ThemeMode.system,
    );
  }

  /// Switches the theme and remembers it for the next launch.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, mode.name);

    notifyListeners();
  }
}
