import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saves, per focus profile, which apps the user keeps available during a session.
///
/// Stored on the phone as one JSON map: profile id → list of package names.
/// The phone and messages apps are added on top of this list elsewhere
/// (see hard_always_available_apps.dart); they are not stored here.
class AlwaysAvailableAppsStore {
  static const _prefsKey = 'alwaysAvailableApps';

  Future<List<String>> getAlwaysAvailableApps(String profileId) async {
    final map = await _loadMap();
    return map[profileId] ?? [];
  }

  Future<void> setAlwaysAvailableApps(
    String profileId,
    List<String> packageNames,
  ) async {
    final map = await _loadMap();
    map[profileId] = packageNames;
    await _saveMap(map);
  }

  /// Forgets the list of a deleted profile.
  Future<void> removeProfile(String profileId) async {
    final map = await _loadMap();
    map.remove(profileId);
    await _saveMap(map);
  }

  /// An unreadable value (e.g. from an older app version) counts as empty.
  Future<Map<String, List<String>>> _loadMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return {};

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(key, List<String>.from(value as List)),
      );
    } catch (error) {
      debugPrint('Could not read always-available apps: $error');
      return {};
    }
  }

  Future<void> _saveMap(Map<String, List<String>> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(map));
  }
}
