import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:live_activity_kit/live_activity_kit.dart';

/// Opens the running timer when the user taps the countdown: the iOS
/// Live Activity, or the Android notification. Started and stopped in
/// main.dart.
class FocusNotificationNavigation {
  FocusNotificationNavigation._();
  static final FocusNotificationNavigation instance =
      FocusNotificationNavigation._();

  /// The link the countdown opens; also used by TimerNotificationService
  /// when it shows the countdown.
  static const String timerLink = 'restformore://open-active-timer';

  /// Taps on the Android notification, reported by TimerNotificationService.
  static final _androidTaps = StreamController<String>.broadcast();

  /// Called by TimerNotificationService when its notification is tapped.
  static void reportTap(String link) => _androidTaps.add(link);

  StreamSubscription<String>? _iosSubscription;
  StreamSubscription<String>? _androidSubscription;

  /// Starts listening; [openTimer] is called on every tap of the countdown.
  void start({required Future<void> Function() openTimer}) {
    void onLink(String link) {
      if (link != timerLink) return;
      unawaited(_handleTap(openTimer));
    }

    _iosSubscription?.cancel();
    _androidSubscription?.cancel();
    _iosSubscription = LiveActivity.deepLinks.listen(onLink);
    _androidSubscription = _androidTaps.stream.listen(onLink);
  }

  /// Stops listening (when the app closes).
  Future<void> stop() async {
    await _iosSubscription?.cancel();
    await _androidSubscription?.cancel();
    _iosSubscription = null;
    _androidSubscription = null;
  }

  Future<void> _handleTap(Future<void> Function() openTimer) async {
    try {
      await openTimer();
    } catch (error) {
      debugPrint('Unable to open focus timer: $error');
    }
  }
}
