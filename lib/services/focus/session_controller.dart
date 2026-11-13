import 'dart:async';

import 'package:app_blocker/app_blocker.dart';
import 'package:flutter/foundation.dart';

import '../../models/focus/pause_rules.dart';
import 'blocking_service.dart';
import 'keep_timer_running.dart';
import 'session_store.dart';
import 'timer_notification_service.dart';

/// All logic behind the timer screen for one [profile]: choosing a duration,
/// starting and stopping the session, breaks, and the countdown itself.
///
/// The saved end time in [SessionStore] is the source of truth, so the timer
/// stays correct when the app is closed or the phone is locked.
/// The screen listens to this controller and redraws when it notifies.
class SessionController extends ChangeNotifier {
  SessionController({required this.profile});

  static const int defaultMillis = 15 * 60 * 1000;

  final BlockProfile profile;
  final _blocking = BlockingService();
  final _session = SessionStore();
  final _alerts = TimerNotificationService.instance;

  /// Called when the timer reaches zero while the timer screen is open.
  VoidCallback? onFinished;

  // ---------- state the screen reads ----------

  int totalMillis = defaultMillis;
  int remainingMillis = defaultMillis;
  bool isRunning = false;
  bool hasStarted = false;
  List<int> customPresets = [];
  int pausesAllowed = 0;
  int pausesUsed = 0;

  int get pausesLeft => pausesAllowed - pausesUsed;
  bool get isOnBreak => _breakEnd > DateTime.now().millisecondsSinceEpoch;
  int get breakLeftMillis {
    final left = _breakEnd - DateTime.now().millisecondsSinceEpoch;
    return left < 0 ? 0 : left;
  }

  bool get canPause => isRunning && !isOnBreak && pausesLeft > 0;

  // ---------- internal state ----------

  Timer? _timer;
  int _endAt = 0;
  int _breakEnd = 0;
  bool _wasOnBreak = false;
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

  /// Reads the saved state: continues a running session, or shows the
  /// last chosen duration and cleans up anything left over.
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

        await KeepRunningTimerClock.instance.refresh();

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
        await KeepRunningTimerClock.instance.refresh();
        _notify();
      }
    } catch (error) {
      debugPrint('Loading state failed: $error');
    }
  }

  /// Saves the chosen duration and the custom presets (not the session).
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

  /// Focus time left; during a break it stays frozen at the break's end.
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
  /// Returns false if it could not start (everything is undone then).
  // Future<bool> start() async {
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
      await KeepRunningTimerClock.instance.refresh();
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

  /// Starts a break of [kBreakMinutes]; the session end moves back by as much.
  Future<void> startBreak() async {
    if (!canPause) return;
    try {
      await _session.startBreak(const Duration(minutes: kBreakMinutes));
      await _readSessionState();
      await KeepRunningTimerClock.instance.refresh();
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

  /// Ends the session early and unblocks the apps.
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

  /// Picks a duration (only before the session starts).
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

  // ---------- countdown ----------

  /// Ticks 4× per second, but only redraws when the visible second changes.
  /// Handles the end of a break and the end of the session.
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
          _notify();
        }
        return;
      }

      // Time is up.
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
