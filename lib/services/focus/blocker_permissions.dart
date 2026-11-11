import 'package:flutter/services.dart';

/// Asks the app_blocker plugin (Android) which of its two permissions are on,
/// and opens the settings page for each one separately.
class BlockerPermissions {
  static const _channel = MethodChannel('com.khanhtq.app_blocker/methods');

  /// The Settings → Accessibility switch for Rest For More.
  static Future<bool> accessibilityOn() async =>
      (await _details())['accessibility'] ?? false;

  /// "Alarms & reminders": needed so breaks and sessions end on time.
  static Future<bool> exactAlarmOn() async =>
      (await _details())['exactAlarm'] ?? false;

  static Future<void> openAccessibility() =>
      _channel.invokeMethod<void>('requestAccessibilityPermission');

  static Future<void> openExactAlarm() =>
      _channel.invokeMethod<void>('requestExactAlarmPermission');

  static Future<Map<String, bool>> _details() async =>
      await _channel.invokeMapMethod<String, bool>('checkPermissionDetails') ??
      const {};
}
