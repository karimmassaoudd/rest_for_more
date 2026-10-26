import 'dart:math';

import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:live_activity_kit/live_activity_kit.dart';

import '../theme/app_colors.dart';

/// Alarm at the end of a session and the ongoing countdown in the
/// notification shade. Every method catches its own errors, so a failing
/// notification can never break a session.
class TimerNotificationService {
  TimerNotificationService._();
  static final TimerNotificationService instance = TimerNotificationService._();

  static const _activityId = 'focus-timer';
  static const _alarmId = 1;
  static const _breakAlarmId = 2;
  static const _alarmAsset = 'assets/sounds/alarm.mp3';

  final _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      await Alarm.init();
      await _notifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
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
    await _endLiveActivity();
  }

  Future<bool> isRinging() async {
    try {
      return await Alarm.isRinging(_alarmId);
    } catch (_) {
      return false;
    }
  }

  // ---------- alarm ----------

  Future<void> _scheduleAlarm(DateTime endAt, String profileName) async {
    if (!endAt.isAfter(DateTime.now())) return;
    try {
      await Alarm.stop(_alarmId);
      final scheduled = await Alarm.set(
        alarmSettings: AlarmSettings(
          id: _alarmId,
          dateTime: endAt,
          assetAudioPath: _alarmAsset,
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
          assetAudioPath: _alarmAsset,
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

  // ---------- live countdown ----------

  Future<void> _showCountdown({
    required DateTime until,
    required String title,
    required String subtitle,
  }) async {
    final remaining = until.difference(DateTime.now()).inMilliseconds;
    try {
      await _endLiveActivity(); // makes sure the old text is replaced
      await LiveActivity.show(
        id: _activityId,
        compact: LA.row([
          LA.symbol('timer', size: 18, color: AppColors.mediumbrown),
          LA.countdown(
            until,
            size: 18,
            weight: FontWeight.w600,
            color: AppColors.mediumbrown,
            monospacedDigit: true,
          ),
        ], spacing: 8),
        compactLeading: LA.symbol(
          'timer',
          size: 17,
          color: AppColors.mediumbrown,
        ),
        compactTrailing: LA.countdown(
          until,
          size: 15,
          weight: FontWeight.w600,
          color: AppColors.mediumbrown,
          monospacedDigit: true,
        ),
        minimal: LA.symbol('timer', size: 17, color: AppColors.mediumbrown),
        expanded: LA.column([
          LA.row([
            LA.symbol('timer', size: 20, color: AppColors.yellowhighlight),
            LA.text(
              title,
              size: 16,
              weight: FontWeight.bold,
              color: AppColors.mediumbrown,
            ),
            LA.spacer(),
            LA.countdown(
              until,
              size: 22,
              weight: FontWeight.w600,
              color: AppColors.mediumbrown,
              monospacedDigit: true,
            ),
          ], spacing: 8),
          LA.text(subtitle, size: 13, color: AppColors.lightbrown),
        ], spacing: 5),
        lockScreen: LA.column([
          LA.row([
            LA.text(
              title,
              size: 17,
              weight: FontWeight.bold,
              color: AppColors.mediumbrown,
            ),
            LA.spacer(),
            LA.countdown(
              until,
              size: 22,
              weight: FontWeight.w600,
              color: AppColors.mediumbrown,
              monospacedDigit: true,
            ),
          ], spacing: 8),
          LA.text(subtitle, size: 13, color: AppColors.lightbrown),
        ], spacing: 5),
        staleAfter: Duration(milliseconds: max(1000, remaining + 1000)),
      );
    } catch (error) {
      debugPrint('Unable to start system focus activity: $error');
    }
  }

  Future<void> _endLiveActivity() async {
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
