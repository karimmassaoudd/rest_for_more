import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:live_activity_kit/live_activity_kit.dart';

class FocusNotificationNavigation {
  FocusNotificationNavigation._();

  static final FocusNotificationNavigation instance =
      FocusNotificationNavigation._();

  static const String timerLink = 'restformore://open-active-timer';

  StreamSubscription<String>? _subscription;

  void start({required Future<void> Function() openTimer}) {
    _subscription?.cancel();

    _subscription = LiveActivity.deepLinks.listen((link) {
      if (link != timerLink) return;

      unawaited(_handleTap(openTimer));
    });
  }

  Future<void> _handleTap(Future<void> Function() openTimer) async {
    try {
      await openTimer();
    } catch (error) {
      debugPrint('Unable to open focus timer: $error');
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
