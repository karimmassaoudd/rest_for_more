import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ReminderSettings {
  const ReminderSettings({
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

class RoutineReminderService {
  RoutineReminderService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _enabledKey = 'routine_reminders_enabled';
  static const _morningHourKey = 'routine_reminder_morning_hour';
  static const _morningMinuteKey = 'routine_reminder_morning_minute';
  static const _eveningHourKey = 'routine_reminder_evening_hour';
  static const _eveningMinuteKey = 'routine_reminder_evening_minute';

  Future<ReminderSettings> loadSettings() async {
    final preferences = await SharedPreferences.getInstance();
    return ReminderSettings(
      enabled: preferences.getBool(_enabledKey) ?? false,
      morningHour: preferences.getInt(_morningHourKey) ?? 7,
      morningMinute: preferences.getInt(_morningMinuteKey) ?? 0,
      eveningHour: preferences.getInt(_eveningHourKey) ?? 21,
      eveningMinute: preferences.getInt(_eveningMinuteKey) ?? 40,
    );
  }

  Future<bool> requestPermission() async {
    await _initialize();
    final android = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return android ?? ios ?? true;
  }

  Future<void> saveAndSchedule({
    required ReminderSettings settings,
    required int morningRemaining,
    required int eveningRemaining,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, settings.enabled);
    await preferences.setInt(_morningHourKey, settings.morningHour);
    await preferences.setInt(_morningMinuteKey, settings.morningMinute);
    await preferences.setInt(_eveningHourKey, settings.eveningHour);
    await preferences.setInt(_eveningMinuteKey, settings.eveningMinute);
    await _initialize();
    for (final id in [100, 101, 200, 201]) {
      await _plugin.cancel(id: id);
    }
    if (!settings.enabled) return;
    await _scheduleDaily(
      id: 100,
      hour: settings.morningHour,
      minute: settings.morningMinute,
      title: 'Your Morning Routine is ready',
      body: 'Start the day with your first routine task.',
    );
    await _scheduleDaily(
      id: 101,
      hour: settings.morningHour + 1,
      minute: settings.morningMinute,
      title: 'Morning routine check-in',
      body: morningRemaining == 0
          ? 'Your Morning Routine is complete.'
          : 'You still have $morningRemaining tasks left.',
    );
    await _scheduleDaily(
      id: 200,
      hour: settings.eveningHour,
      minute: settings.eveningMinute,
      title: 'Your Evening Routine is ready',
      body: 'Slow down and begin your evening routine.',
    );
    await _scheduleDaily(
      id: 201,
      hour: settings.eveningHour + 1,
      minute: settings.eveningMinute,
      title: 'Evening routine check-in',
      body: eveningRemaining == 0
          ? 'Your Evening Routine is complete.'
          : 'You still have $eveningRemaining tasks left.',
    );
  }

  Future<void> refreshIfEnabled({
    required int morningRemaining,
    required int eveningRemaining,
  }) async {
    final settings = await loadSettings();
    if (!settings.enabled) return;
    await saveAndSchedule(
      settings: settings,
      morningRemaining: morningRemaining,
      eveningRemaining: eveningRemaining,
    );
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings);
    tz.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    _initialized = true;
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final normalizedHour = hour % 24;
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      normalizedHour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'routine_reminders',
          'Routine reminders',
          channelDescription: 'Morning and Evening routine reminders',
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
