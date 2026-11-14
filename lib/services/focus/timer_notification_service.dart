import 'dart:math';

import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:live_activity_kit/live_activity_kit.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_palette.dart';
import 'focus_notification_navigation.dart';

/// Alarm at the end of a session and the ongoing countdown in the
/// notification shade (Android) or Live Activity (iOS).
///
/// Every method catches its own errors, so a failing notification
/// can never break a session.
class TimerNotificationService {
  TimerNotificationService._();
  static final TimerNotificationService instance = TimerNotificationService._();

  static const _activityId = 'focus-timer';
  static const _alarmId = 1;
  static const _breakAlarmId = 2;
  static const _countdownNotificationId = 100;

  final _notifications = FlutterLocalNotificationsPlugin();

  /// Call once in main().
  Future<void> init() async {
    try {
      await Alarm.init();
      await _notifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: (response) {
          final link = response.payload;
          if (link != null) FocusNotificationNavigation.reportTap(link);
        },
      );
    } catch (error) {
      debugPrint('Notification setup failed: $error');
    }
  }

  /// Asks for the notification permission. Returns whether it was granted.
  Future<bool> requestPermission() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final granted = await _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
        return granted ?? true;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final granted = await _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true);
        return granted ?? false;
      }
      return true;
    } catch (error) {
      debugPrint('Notification permission failed: $error');
      return false;
    }
  }

  /// Whether notifications are allowed. Android only; elsewhere (or on
  /// error) assumes yes.
  Future<bool> hasPermission() async {
    try {
      final android = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.areNotificationsEnabled() ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Schedules the end-of-session alarm and shows the live countdown.
  Future<void> scheduleEnd({
    required DateTime endAt,
    required String profileName,
  }) async {
    await _scheduleAlarm(endAt, profileName);
    await showFocus(endAt: endAt, profileName: profileName);
  }

  /// Shows the focus countdown (also used when a break is over).
  Future<void> showFocus({
    required DateTime endAt,
    required String profileName,
  }) => _showCountdown(
    until: endAt,
    title: 'Focus',
    subtitle: '$profileName session',
  );

  /// A break started: move the end alarm, count down the break,
  /// and schedule a "Break over" notification.
  Future<void> startBreak({
    required DateTime breakEnd,
    required DateTime endAt,
    required String profileName,
  }) async {
    await _scheduleAlarm(endAt, profileName);
    await _scheduleBreakAlarm(breakEnd, profileName);
    await _showCountdown(
      until: breakEnd,
      title: 'Break',
      subtitle: '$profileName session paused',
    );
  }

  /// Stops every alarm and removes the countdown.
  Future<void> cancelAll() async {
    await _stopAlarm();
    await _stopBreakAlarm();
    await _removeCountdown();
  }

  /// True while the end-of-session alarm is ringing.
  Future<bool> isRinging() async {
    try {
      return await Alarm.isRinging(_alarmId);
    } catch (_) {
      return false;
    }
  }

  /// Loud, looping alarm with a full-screen notification when the session ends.
  Future<void> _scheduleAlarm(DateTime endAt, String profileName) async {
    if (!endAt.isAfter(DateTime.now())) return;
    try {
      await Alarm.stop(_alarmId);
      final scheduled = await Alarm.set(
        alarmSettings: AlarmSettings(
          id: _alarmId,
          dateTime: endAt,
          loopAudio: true,
          vibrate: true,
          androidAlarmClock: true,
          androidFullScreenIntent: true,
          androidStopAlarmOnTermination: false,
          warningNotificationOnKill: true,
          notificationSettings: NotificationSettings(
            title: 'Focus session ended',
            body: 'Your $profileName session has ended.',
            stopButton: 'Stop',
            keepNotificationAfterAlarmEnds: false,
          ),
          volumeSettings: VolumeSettings.fade(
            volume: 1.0,
            fadeDuration: Duration.zero,
            volumeEnforced: false,
          ),
        ),
      );
      if (!scheduled) debugPrint('Unable to schedule focus alarm');
    } catch (error) {
      debugPrint('Unable to schedule focus alarm: $error');
    }
  }

  Future<void> _stopAlarm() async {
    try {
      await Alarm.stop(_alarmId);
    } catch (error) {
      debugPrint('Unable to stop focus alarm: $error');
    }
  }

  /// Quieter, single "Break over" sound.
  Future<void> _scheduleBreakAlarm(
    DateTime breakEnd,
    String profileName,
  ) async {
    if (!breakEnd.isAfter(DateTime.now())) return;
    try {
      await Alarm.stop(_breakAlarmId);
      await Alarm.set(
        alarmSettings: AlarmSettings(
          id: _breakAlarmId,
          dateTime: breakEnd,
          loopAudio: false,
          vibrate: true,
          androidAlarmClock: true,
          androidFullScreenIntent: false,
          androidStopAlarmOnTermination: false,
          warningNotificationOnKill: false,
          notificationSettings: NotificationSettings(
            title: 'Break over',
            body: 'Back to your $profileName session.',
            stopButton: 'OK',
            keepNotificationAfterAlarmEnds: false,
          ),
          volumeSettings: VolumeSettings.fade(
            volume: 0.6,
            fadeDuration: Duration.zero,
            volumeEnforced: false,
          ),
        ),
      );
    } catch (error) {
      debugPrint('Unable to schedule break alarm: $error');
    }
  }

  Future<void> _stopBreakAlarm() async {
    try {
      await Alarm.stop(_breakAlarmId);
    } catch (error) {
      debugPrint('Unable to stop break alarm: $error');
    }
  }

  /// Replaces the countdown with a new one running until [until].
  ///
  /// Android: a normal ongoing notification (see [_showAndroidCountdown]).
  /// iOS: a Live Activity. The Dynamic Island is always black and the lock
  /// screen gets our own tint, so both use the dark app palette.
  Future<void> _showCountdown({
    required DateTime until,
    required String title,
    required String subtitle,
  }) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _showAndroidCountdown(
        until: until,
        title: title,
        subtitle: subtitle,
      );
      return;
    }

    final remaining = until.difference(DateTime.now()).inMilliseconds;
    const dark = AppPalette.dark;
    try {
      await _removeCountdown(); // replaces the old text
      await LiveActivity.show(
        id: _activityId,
        deepLink: FocusNotificationNavigation.timerLink,
        theme: LATheme(
          background: dark.background,
          foreground: dark.text,
          tint: dark.highlight,
        ),
        compactLeading: LA.symbol('timer', size: 17, color: dark.highlight),
        compactTrailing: LA.countdown(
          until,
          size: 15,
          weight: FontWeight.w600,
          color: dark.highlight,
          monospacedDigit: true,
        ),
        minimal: LA.symbol('timer', size: 17, color: dark.highlight),
        expanded: LA.column([
          LA.row([
            LA.symbol('timer', size: 20, color: dark.highlight),
            LA.text(title, size: 16, weight: FontWeight.bold, color: dark.text),
            LA.spacer(),
            LA.countdown(
              until,
              size: 22,
              weight: FontWeight.w600,
              color: dark.highlight,
              monospacedDigit: true,
            ),
          ], spacing: 8),
          LA.text(subtitle, size: 13, color: dark.muted, maxLines: 1),
        ], spacing: 5),
        lockScreen: LA.column([
          LA.row([
            LA.text(
              title,
              size: 17,
              weight: FontWeight.bold,
              color: dark.text,
              maxLines: 1,
            ),
            LA.spacer(),
            LA.countdown(
              until,
              size: 22,
              weight: FontWeight.w600,
              color: dark.highlight,
              monospacedDigit: true,
            ),
          ], spacing: 8),
          LA.text(subtitle, size: 13, color: dark.muted, maxLines: 1),
        ], spacing: 5),
        // Marks the countdown as outdated 1 s after it reaches zero.
        staleAfter: Duration(milliseconds: max(1000, remaining + 1000)),
      );
    } catch (error) {
      debugPrint('Unable to start system focus activity: $error');
    }
  }

  /// Android: a standard ongoing notification with the system countdown
  /// (chronometer) in its top line. The system draws it, so it follows the
  /// phone's light/dark mode and fits both the collapsed and the expanded
  /// notification. It removes itself 1 s after the end; the alarm takes over.
  Future<void> _showAndroidCountdown({
    required DateTime until,
    required String title,
    required String subtitle,
  }) async {
    final remaining = until.difference(DateTime.now()).inMilliseconds;
    try {
      await _notifications.show(
        _countdownNotificationId,
        title,
        subtitle,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'focus_countdown',
            'Focus countdown',
            channelDescription:
                'Shows the time left in a focus session or break.',
            importance: Importance.low,
            priority: Priority.low,
            ongoing: true,
            autoCancel: false,
            onlyAlertOnce: true,
            silent: true,
            showWhen: true,
            when: until.millisecondsSinceEpoch,
            usesChronometer: true,
            chronometerCountDown: true,
            timeoutAfter: max(1000, remaining + 1000),
            color: AppColors.lightBrown,
            visibility: NotificationVisibility.public,
          ),
        ),
        payload: FocusNotificationNavigation.timerLink,
      );
    } catch (error) {
      debugPrint('Unable to show focus notification: $error');
    }
  }

  /// Removes the countdown (Android notification or iOS Live Activity).
  Future<void> _removeCountdown() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await _notifications.cancel(_countdownNotificationId);
      } catch (error) {
        debugPrint('Unable to remove focus notification: $error');
      }
      return;
    }
    try {
      if (!await LiveActivity.isRunning(_activityId)) return;
      await LiveActivity.end(
        id: _activityId,
        policy: const LiveActivityEndPolicy.immediate(),
      );
    } catch (error) {
      debugPrint('Unable to end system focus activity: $error');
    }
  }
}
