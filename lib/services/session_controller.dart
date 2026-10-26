import 'dart:async';

import 'package:app_blocker/app_blocker.dart';
import 'package:flutter/foundation.dart';

import 'blocking_service.dart';
import 'session_store.dart';
import 'timer_notification_service.dart';
import '../models/pause_rules.dart';

class SessionController extends ChangeNotifier {
  SessionController({required this.profile});

  static const int defaultMillis = 15 * 60 * 1000;

  final BlockProfile profile;
  final _blocking = BlockingService();
  final _session = SessionStore();
  final _alerts = TimerNotificationService.instance;
  int pausesAllowed = 0;
  int pausesUsed = 0;
  int _breakEnd = 0;
  bool _wasOnBreak = false;

  /// Called when the timer reaches zero while this page is open.
  VoidCallback? onFinished;

  // State the screen reads
  int totalMillis = defaultMillis;
  int remainingMillis = defaultMillis;
  bool isRunning = false;
  bool hasStarted = false;
  List<int> customPresets = [];
  int get pausesLeft => pausesAllowed - pausesUsed;
  bool get isOnBreak => _breakEnd > DateTime.now().millisecondsSinceEpoch;
  int get breakLeftMillis {
    final left = _breakEnd - DateTime.now().millisecondsSinceEpoch;
    return left < 0 ? 0 : left;
  }

  bool get canPause => isRunning && !isOnBreak && pausesLeft > 0;

  Timer? _timer;
  int _endAt = 0;
  int _shownSecond = -1;
  bool _disposed = false;
  bool _starting = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }

  // ---------- loading and saving ----------

  Future<void> load() async {
    try {
      if (await _alerts.isRinging()) await _alerts.cancelAll();
      if (await _session.hasExpired()) {
        await _blocking.stopBlocking();
      }

      totalMillis = await _session.totalMillis() ?? defaultMillis;
      customPresets = await _session.customPresets();

      final sessionLeft = await _session.remainingMillis();
      if (sessionLeft != null && sessionLeft > 0) {
        // A session is running: the saved end time is the truth.
        remainingMillis = sessionLeft;
        isRunning = true;
        hasStarted = true;
        await _readSessionState();
        _wasOnBreak = isOnBreak;
        if (_breakEnd > 0 && !isOnBreak) {
          // A break happened and is over: make sure the shade shows focus time.
          _alerts.showFocus(
            endAt: DateTime.fromMillisecondsSinceEpoch(_endAt),
            profileName: profile.name,
          );
        }
        _runTimer();
      } else {
        // No session: show the chosen duration and clean up anything left over.
        _timer?.cancel();
        isRunning = false;
        hasStarted = false;
        remainingMillis = totalMillis;
        _resetBreakState();
        await _alerts.cancelAll();
        _notify();
      }
    } catch (error) {
      debugPrint('Loading state failed: $error');
    }
  }

  Future<void> save() async {
    try {
      await _session.saveTimerSettings(
        totalMillis: totalMillis,
        customPresets: customPresets,
      );
    } catch (error) {
      debugPrint('Saving state failed: $error');
    }
  }

  /// Called when the app comes back to the foreground.
  Future<void> onResumed() async {
    if (isRunning) {
      // Show the right time immediately, before the slower load finishes.
      final left = _remainingNow();
      remainingMillis = left.clamp(0, totalMillis).toInt();
      _notify();
    }
    await load();
  }

  Future<void> _readSessionState() async {
    _endAt = await _session.endAt() ?? 0;
    _breakEnd = await _session.breakEnd();
    pausesUsed = await _session.pausesUsed();
    pausesAllowed = await _session.pausesAllowed();
  }

  int _remainingNow() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _endAt - (_breakEnd > now ? _breakEnd : now);
  }

  void _resetBreakState() {
    pausesAllowed = 0;
    pausesUsed = 0;
    _breakEnd = 0;
  }

  // ---------- actions ----------

  /// Starts the session. Permission must already be granted.
  /// Returns false if it could not start.
  Future<bool> start() async {
    if (remainingMillis <= 0) return false;
    if (_starting) return false;
    _starting = true;
    try {
      await _session.setEndIn(remainingMillis);
      await _session.setPausesAllowed(pausesAllowedFor(totalMillis ~/ 60000));
      await _session.setProfileName(profile.name);
      await _session.setProfileId(profile.id);
      await _blocking.startBlocking(profile);
      await _readSessionState();
      _runTimer();
      await _alerts.scheduleEnd(
        endAt: DateTime.fromMillisecondsSinceEpoch(_endAt),
        profileName: profile.name,
      );
      return true;
    } catch (error) {
      debugPrint('Start session failed: $error');
      await _stopSessionSafely();
      return false;
    } finally {
      _starting = false;
    }
  }

  Future<void> startBreak() async {
    if (!canPause) return;
    try {
      await _session.startBreak(const Duration(minutes: kBreakMinutes));
      await _readSessionState();
      _shownSecond = -1;
      _notify();
      await _alerts.startBreak(
        breakEnd: DateTime.fromMillisecondsSinceEpoch(_breakEnd),
        endAt: DateTime.fromMillisecondsSinceEpoch(_endAt),
        profileName: profile.name,
      );
      _wasOnBreak = true;
    } catch (error) {
      debugPrint('Starting the break failed: $error');
    }
  }

  void stop() {
    _timer?.cancel();
    isRunning = false;
    hasStarted = false;
    remainingMillis = totalMillis;
    _notify();
    _alerts.cancelAll();
    _stopSessionSafely();
    _resetBreakState();
  }

  void selectPreset(int minutes) {
    _timer?.cancel();
    isRunning = false;
    hasStarted = false;
    totalMillis = minutes * 60 * 1000;
    remainingMillis = totalMillis;
    _notify();
  }

  void updateCustomPresets(List<int> presets) {
    customPresets = presets;
    _notify();
    save();
  }

  // ---------- internals ----------

  void _runTimer() {
    if (remainingMillis <= 0) return;

    _timer?.cancel();
    _shownSecond = -1;
    isRunning = true;
    hasStarted = true;
    _notify();

    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final now = DateTime.now().millisecondsSinceEpoch;

      if (_endAt - now > 0) {
        final onBreak = isOnBreak;
        if (_wasOnBreak && !onBreak) {
          // The break just ended: show the focus countdown again.
          _alerts.showFocus(
            endAt: DateTime.fromMillisecondsSinceEpoch(_endAt),
            profileName: profile.name,
          );
        }
        _wasOnBreak = onBreak;
        remainingMillis = _remainingNow();
        final second = isOnBreak
            ? (breakLeftMillis / 1000).ceil()
            : (remainingMillis / 1000).ceil();
        if (second != _shownSecond) {
          _shownSecond = second;
          _notify(); // redraw only when the visible second changes
        }
        return;
      }

      _timer?.cancel();
      isRunning = false;
      hasStarted = false;
      remainingMillis = totalMillis;
      _notify();
      onFinished?.call();
      _stopSessionSafely();
      _resetBreakState();
    });
  }

  Future<void> _stopSessionSafely() async {
    try {
      await _blocking.stopBlocking();
    } catch (error) {
      debugPrint('Stopping the session failed: $error');
    }
  }
}
