import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

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

  Future<void> removeProfile(String profileId) async {
    final map = await _loadMap();
    map.remove(profileId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(map));
  }
}
