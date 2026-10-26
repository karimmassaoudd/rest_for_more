import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  static const _endTimeKey = 'sessionEndTimeMillis';
  static const _profileNameKey = 'sessionProfileName';
  static const _breakEndKey = 'sessionBreakEndMillis';
  static const _pausesUsedKey = 'sessionPausesUsed';
  static const _pausesAllowedKey = 'sessionPausesAllowed';
  static const _profileIdKey = 'sessionProfileId';
  static const _totalMillisKey = 'totalTimeInMillis';
  static const _customPresetsKey = 'customPresets';

  Future<String?> profileName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getString(_profileNameKey);
  }

  Future<String?> profileId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getString(_profileIdKey);
  }

  Future<void> setProfileId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileIdKey, id);
  }

  Future<void> setProfileName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileNameKey, name);
  }

  Future<void> setEndIn(int remainingMillis) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _endTimeKey,
      DateTime.now().millisecondsSinceEpoch + remainingMillis,
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_endTimeKey);
    await prefs.remove(_profileNameKey);
    await prefs.remove(_breakEndKey);
    await prefs.remove(_pausesUsedKey);
    await prefs.remove(_pausesAllowedKey);
    await prefs.remove(_profileIdKey);
  }

  Future<int?> remainingMillis() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final end = prefs.getInt(_endTimeKey);
    if (end == null) return null;
    final now = DateTime.now().millisecondsSinceEpoch;
    final breakEnd = prefs.getInt(_breakEndKey) ?? 0;
    return end - (breakEnd > now ? breakEnd : now);
  }

  Future<bool> hasExpired() async {
    final left = await remainingMillis();
    return left != null && left <= 0;
  }

  /// True while a session is running.
  Future<bool> isActive() async {
    final left = await remainingMillis();
    return left != null && left > 0;
  }

  Future<int?> endAt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getInt(_endTimeKey);
  }

  Future<int> breakEnd() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getInt(_breakEndKey) ?? 0;
  }

  Future<int> pausesUsed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getInt(_pausesUsedKey) ?? 0;
  }

  Future<int> pausesAllowed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getInt(_pausesAllowedKey) ?? 0;
  }

  /// Called when a session starts: set the allowance, reset the rest.
  Future<void> setPausesAllowed(int allowed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pausesAllowedKey, allowed);
    await prefs.setInt(_pausesUsedKey, 0);
    await prefs.remove(_breakEndKey);
  }

  /// Starts a break: the end time moves back by the break length.
  Future<void> startBreak(Duration length) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final end = prefs.getInt(_endTimeKey);
    if (end == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_breakEndKey, now + length.inMilliseconds);
    await prefs.setInt(_endTimeKey, end + length.inMilliseconds);
    await prefs.setInt(_pausesUsedKey, (prefs.getInt(_pausesUsedKey) ?? 0) + 1);
  }

  // ---------- timer settings (not part of a running session) ----------

  Future<int?> totalMillis() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalMillisKey);
  }

  Future<List<int>> customPresets() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_customPresetsKey) ?? [])
        .map((e) => int.tryParse(e))
        .whereType<int>()
        .toList();
  }

  Future<void> saveTimerSettings({
    required int totalMillis,
    required List<int> customPresets,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalMillisKey, totalMillis);
    await prefs.setStringList(
      _customPresetsKey,
      customPresets.map((e) => e.toString()).toList(),
    );
  }
}
