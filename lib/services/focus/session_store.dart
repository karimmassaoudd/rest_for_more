import 'package:shared_preferences/shared_preferences.dart';

/// Saves the running focus session on the phone, so it survives the app
/// being closed: end time, profile, break and pauses.
/// Also keeps the timer settings (last duration, custom presets).
///
/// All times are milliseconds since epoch. Don't rename the keys:
/// that would lose a session that is running during an update.
class SessionStore {
  static const _endTimeKey = 'sessionEndTimeMillis';
  static const _profileNameKey = 'sessionProfileName';
  static const _breakEndKey = 'sessionBreakEndMillis';
  static const _pausesUsedKey = 'sessionPausesUsed';
  static const _pausesAllowedKey = 'sessionPausesAllowed';
  static const _profileIdKey = 'sessionProfileId';
  static const _totalMillisKey = 'totalTimeInMillis';
  static const _customPresetsKey = 'customPresets';

  /// Prefs re-read from disk, in case another part of the app
  /// (or a notification) changed them in the meantime.
  Future<SharedPreferences> _fresh() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs;
  }

  // ---------- running session ----------

  Future<String?> profileName() async =>
      (await _fresh()).getString(_profileNameKey);

  Future<String?> profileId() async =>
      (await _fresh()).getString(_profileIdKey);

  Future<void> setProfileId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileIdKey, id);
  }

  Future<void> setProfileName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileNameKey, name);
  }

  /// Starts the session clock: it ends [remainingMillis] from now.
  Future<void> setEndIn(int remainingMillis) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _endTimeKey,
      DateTime.now().millisecondsSinceEpoch + remainingMillis,
    );
  }

  /// Forgets the session (the timer settings stay).
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_endTimeKey);
    await prefs.remove(_profileNameKey);
    await prefs.remove(_breakEndKey);
    await prefs.remove(_pausesUsedKey);
    await prefs.remove(_pausesAllowedKey);
    await prefs.remove(_profileIdKey);
  }

  /// Focus time left, or null when no session was started.
  /// During a break it stays frozen at the break's end.
  Future<int?> remainingMillis() async {
    final prefs = await _fresh();
    final end = prefs.getInt(_endTimeKey);
    if (end == null) return null;
    final now = DateTime.now().millisecondsSinceEpoch;
    final breakEnd = prefs.getInt(_breakEndKey) ?? 0;
    return end - (breakEnd > now ? breakEnd : now);
  }

  /// True when a session was started and its time is up.
  Future<bool> hasExpired() async {
    final left = await remainingMillis();
    return left != null && left <= 0;
  }

  /// True while a session is running.
  Future<bool> isActive() async {
    final left = await remainingMillis();
    return left != null && left > 0;
  }

  Future<int?> endAt() async => (await _fresh()).getInt(_endTimeKey);

  /// 0 when there is no break.
  Future<int> breakEnd() async => (await _fresh()).getInt(_breakEndKey) ?? 0;

  Future<int> pausesUsed() async =>
      (await _fresh()).getInt(_pausesUsedKey) ?? 0;

  Future<int> pausesAllowed() async =>
      (await _fresh()).getInt(_pausesAllowedKey) ?? 0;

  /// Called when a session starts: sets the allowance and resets the rest.
  Future<void> setPausesAllowed(int allowed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pausesAllowedKey, allowed);
    await prefs.setInt(_pausesUsedKey, 0);
    await prefs.remove(_breakEndKey);
  }

  /// Starts a break: the session end moves back by the break length.
  Future<void> startBreak(Duration length) async {
    final prefs = await _fresh();
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

  /// Custom presets in minutes (stored as strings).
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
