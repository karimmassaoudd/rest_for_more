import 'dart:async';

import 'package:flutter/foundation.dart';

import 'session_store.dart';

/// App-wide clock for the running focus session, independent of the
/// timer screen, so other parts of the app can show the time left.
///
/// Restored by AppNavShell on start and on resume, and refreshed by
/// SessionController whenever the session changes.
///
/// Note: no widget listens to it yet.
class KeepRunningTimerClock extends ChangeNotifier {
  KeepRunningTimerClock._();
  static final KeepRunningTimerClock instance = KeepRunningTimerClock._();

  final _store = SessionStore();

  Timer? _ticker;
  int _endAt = 0;
  int _breakEnd = 0;
  int _remainingMillis = 0;
  bool _active = false;

  /// True while a session is running.
  bool get isActive => _active;

  /// Focus time left (a break doesn't count down the session).
  int get remainingMillis => _remainingMillis;

  int get breakRemainingMillis {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _breakEnd <= now ? 0 : _breakEnd - now;
  }

  bool get isOnBreak => breakRemainingMillis > 0;

  /// Break time while on a break, otherwise focus time: "m:ss" or "h:mm:ss".
  String get formattedTime {
    final millis = isOnBreak ? breakRemainingMillis : remainingMillis;
    final seconds = (millis / 1000).ceil();
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return hours > 0
        ? '$hours:${minutes.toString().padLeft(2, '0')}:$ss'
        : '$minutes:$ss';
  }

  /// Reads the saved session and starts ticking if one is running.
  Future<void> restore() async {
    _endAt = await _store.endAt() ?? 0;
    _breakEnd = await _store.breakEnd();
    _update();
    _startTicker();
  }

  Future<void> refresh() => restore();

  void stopTicker() => _ticker?.cancel();

  void _startTicker() {
    _ticker?.cancel();
    if (!_active) return;
    _ticker = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _update(),
    );
  }

  void _update() {
    final now = DateTime.now().millisecondsSinceEpoch;
    // During a break the session end is pushed back, so count from the break's end.
    final effectiveNow = _breakEnd > now ? _breakEnd : now;

    _remainingMillis = (_endAt - effectiveNow).clamp(0, 1 << 53).toInt();
    _active = _endAt > now;

    if (!_active) {
      _ticker?.cancel();
      _remainingMillis = 0;
    }
    notifyListeners();
  }
}
