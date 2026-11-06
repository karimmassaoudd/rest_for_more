import 'dart:async';

import 'package:flutter/foundation.dart';

import 'session_store.dart';

class KeepRunningTimerClock extends ChangeNotifier {
  KeepRunningTimerClock._();

  static final KeepRunningTimerClock instance = KeepRunningTimerClock._();

  final SessionStore _store = SessionStore();

  Timer? _ticker;

  int _endAt = 0;
  int _breakEnd = 0;
  int _remainingMillis = 0;
  bool _active = false;

  bool get isActive => _active;

  int get remainingMillis => _remainingMillis;

  int get breakRemainingMillis {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_breakEnd <= now) return 0;
    return _breakEnd - now;
  }

  bool get isOnBreak => breakRemainingMillis > 0;

  double get progress {
    if (!_active) return 0;
    return _remainingMillis / 1000;
  }

  Future<void> restore() async {
    final end = await _store.endAt();
    final breakEnd = await _store.breakEnd();

    _endAt = end ?? 0;
    _breakEnd = breakEnd;

    _update();
    _startTicker();
  }

  Future<void> refresh() => restore();

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

    final effectiveNow = _breakEnd > now ? _breakEnd : now;

    _remainingMillis = (_endAt - effectiveNow).clamp(0, 1 << 53).toInt();

    _active = _endAt > now;

    if (!_active) {
      _ticker?.cancel();
      _remainingMillis = 0;
    }

    notifyListeners();
  }

  String get formattedTime {
    final millis = isOnBreak ? breakRemainingMillis : remainingMillis;

    final seconds = (millis / 1000).ceil();
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainder = seconds % 60;

    if (hours > 0) {
      return '$hours:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${remainder.toString().padLeft(2, '0')}';
    }

    return '$minutes:'
        '${remainder.toString().padLeft(2, '0')}';
  }

  void stopTicker() {
    _ticker?.cancel();
  }
}
