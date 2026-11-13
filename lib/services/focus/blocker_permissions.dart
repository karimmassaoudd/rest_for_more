import 'package:flutter/services.dart';

/// Android only: asks our app_blocker plugin which of its two permissions
/// are on, and opens the settings page for each one separately.
///
/// The plugin's own permission check only says "granted or not";
/// this lets BlockingService explain each step to the user.
class BlockerPermissions {
  BlockerPermissions._();

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
