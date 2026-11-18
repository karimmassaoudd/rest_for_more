import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pretends to be the Android side of our app_blocker plugin, so tests can
/// say which apps a profile blocks and check what the app asked it to do.
///
/// Speaks on the same channel and with the same method names and data as
/// AppBlockerPlugin.kt.
class FakeAppBlocker {
  static const _channel = MethodChannel('com.khanhtq.app_blocker/methods');

  /// Profile id → the apps it blocks. A missing id: no such profile.
  final Map<String, List<String>> profiles = {};

  /// Answer to "is app blocking allowed?".
  bool permissionGranted = true;

  /// Every call the app made, in order.
  final List<MethodCall> calls = [];

  List<String> get methods => [for (final call in calls) call.method];

  /// The arguments of the last call to [method] (a map), or null.
  Map<Object?, Object?>? lastArguments(String method) {
    for (final call in calls.reversed) {
      if (call.method == method) return call.arguments as Map<Object?, Object?>?;
    }
    return null;
  }

  void install() {
    calls.clear();
    profiles.clear();
    permissionGranted = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, _handle);
  }

  void uninstall() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  }

  Future<Object?> _handle(MethodCall call) async {
    calls.add(call);
    switch (call.method) {
      case 'getProfiles':
        return [
          for (final entry in profiles.entries)
            {
              'id': entry.key,
              'name': entry.key,
              'appIdentifiers': entry.value,
              'schedules': <Object?>[],
              'isActive': false,
            },
        ];
      case 'checkPermission':
        return permissionGranted ? 'granted' : 'denied';
      case 'checkPermissionDetails':
        return {
          'accessibility': permissionGranted,
          'exactAlarm': permissionGranted,
        };
      default:
        return null; // blockApps, unblockAll, setBlockScreenConfig, …
    }
  }
}
