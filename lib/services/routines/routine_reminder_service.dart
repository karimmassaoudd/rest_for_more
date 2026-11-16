import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class RoutineReminderSettings {
  const RoutineReminderSettings({
    required this.enabled,
    required this.morningHour,
    required this.morningMinute,
    required this.eveningHour,
    required this.eveningMinute,
  });

  final bool enabled;
  final int morningHour;
  final int morningMinute;
  final int eveningHour;
  final int eveningMinute;
}

/// Persists and schedules the two daily routine start notifications.
class RoutineReminderService {
  RoutineReminderService({FlutterLocalNotificationsPlugin? notifications})
    : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _notifications;
  bool _initialized = false;

  static const _enabledKey = 'routine_reminders_enabled';
  static const _morningHourKey = 'routine_reminder_morning_hour';
  static const _morningMinuteKey = 'routine_reminder_morning_minute';
  static const _eveningHourKey = 'routine_reminder_evening_hour';
  static const _eveningMinuteKey = 'routine_reminder_evening_minute';
  static const _morningId = 410;
  static const _eveningId = 411;

  Future<RoutineReminderSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return RoutineReminderSettings(
      enabled: prefs.getBool(_enabledKey) ?? false,
      morningHour: prefs.getInt(_morningHourKey) ?? 7,
      morningMinute: prefs.getInt(_morningMinuteKey) ?? 0,
      eveningHour: prefs.getInt(_eveningHourKey) ?? 21,
      eveningMinute: prefs.getInt(_eveningMinuteKey) ?? 40,
    );
  }

  Future<bool> requestPermission() async {
    await _initialize();
    try {
      final android = await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      final ios = await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return android ?? ios ?? true;
    } catch (error) {
      debugPrint('Routine reminder permission failed: $error');
      return false;
    }
  }

  Future<void> saveAndSchedule(RoutineReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, settings.enabled);
    await prefs.setInt(_morningHourKey, settings.morningHour);
    await prefs.setInt(_morningMinuteKey, settings.morningMinute);
    await prefs.setInt(_eveningHourKey, settings.eveningHour);
    await prefs.setInt(_eveningMinuteKey, settings.eveningMinute);
    await _initialize();
    await _notifications.cancel(_morningId);
    await _notifications.cancel(_eveningId);
    if (!settings.enabled) return;
    await _scheduleDaily(
      _morningId,
      settings.morningHour,
      settings.morningMinute,
      'Your morning routine is ready',
      'Start gently with your first activity.',
    );
    await _scheduleDaily(
      _eveningId,
      settings.eveningHour,
      settings.eveningMinute,
      'Your evening routine is ready',
      'It is time to slow down and begin your routine.',
    );
  }

  Future<void> refreshIfEnabled() async {
    try {
      final settings = await loadSettings();
      if (settings.enabled) await saveAndSchedule(settings);
    } catch (error) {
      debugPrint('Routine reminder refresh failed: $error');
    }
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    await _notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    tz.initializeTimeZones();
    try {
      final zoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zoneName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    _initialized = true;
  }

  Future<void> _scheduleDaily(
    int id,
    int hour,
    int minute,
    String title,
    String body,
  ) async {
    final now = tz.TZDateTime.now(tz.local);
    var date = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour % 24,
      minute,
    );
    if (!date.isAfter(now)) {
      date = date.add(const Duration(days: 1));
    }
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      date,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'routine_reminders',
          'Routine reminders',
          channelDescription: 'Daily morning and evening routine reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
