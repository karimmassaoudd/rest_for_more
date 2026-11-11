import 'dart:async';
import 'dart:io';

import 'package:app_blocker/app_blocker.dart';
import 'package:flutter/material.dart';

import '../../models/focus/hard_always_available_apps.dart';
import '../../widgets/focus/permission_dialog.dart';
import 'always_available_apps_store.dart';
import 'blocker_permissions.dart';
import 'session_store.dart';

class BlockingService {
  final blocker = AppBlocker.instance;
  final _session = SessionStore();
  final _alwaysAvailableStore = AlwaysAvailableAppsStore();

  Future<void> configureBlockScreen(String profileName) async {
    await blocker.setBlockScreenConfig(
      BlockScreenConfig(
        title: '{appName} app is blocked',
        subtitle: '$profileName session in progress',
        timerLabel: '{timeLeft} remaining',
        backgroundColor: const Color.fromARGB(255, 82, 33, 6),
        returnHomeButtonText: 'Return to Home',
        emergencyButtonText: 'Emergency Unlock',
      ),
    );
  }

  Future<bool> ensurePermission(BuildContext context) async {
    if (await blocker.checkPermission() == BlockerPermissionStatus.granted) {
      return true;
    }

    // iOS has a single system prompt, so keep the plugin's own flow there.
    if (!Platform.isAndroid) {
      await blocker.requestPermission();
      return await blocker.checkPermission() == BlockerPermissionStatus.granted;
    }

    // Step 1: the accessibility switch.
    if (!await BlockerPermissions.accessibilityOn()) {
      if (!context.mounted) return false;
      final ok = await showPermissionDialog(
        context,
        icon: Icons.security,
        title: 'Turn on app blocking',
        message:
            'Rest For More blocks distracting apps during your sessions. '
            'To turn this on:\n\n'
            '1. Tap Installed apps\n'
            '2. Tap Rest For More\n'
            '3. Turn the switch on',
        allowLabel: 'Open settings',
        denyLabel: 'Not now',
        messageAlign: TextAlign.start,
      );
      if (!ok) return false;
      await BlockerPermissions.openAccessibility();
      await _waitUntilBack();
      if (!await BlockerPermissions.accessibilityOn()) return false;
    }

    // Step 2: exact alarms (on most phones this is already on).
    if (!await BlockerPermissions.exactAlarmOn()) {
      if (!context.mounted) return false;
      final ok = await showPermissionDialog(
        context,
        icon: Icons.alarm,
        title: 'Keep your timing exact',
        message:
            'So your breaks and sessions end right on time, '
            'Rest For More needs to set alarms.\n\n'
            'On the next screen, turn on the switch for Rest For More.',
        allowLabel: 'Open settings',
        denyLabel: 'Not now',
        messageAlign: TextAlign.start,
      );
      if (!ok) return false;
      await BlockerPermissions.openExactAlarm();
      await _waitUntilBack();
    }

    return await blocker.checkPermission() == BlockerPermissionStatus.granted;
  }

  /// Waits until the user comes back to the app from the settings screen.
  Future<void> _waitUntilBack() {
    final done = Completer<void>();
    late final AppLifecycleListener listener;
    listener = AppLifecycleListener(
      onResume: () {
        listener.dispose();
        if (!done.isCompleted) done.complete();
      },
    );
    return done.future.timeout(
      const Duration(minutes: 5),
      onTimeout: listener.dispose,
    );
  }

  Future<void> startBlocking(BlockProfile profile) async {
    await configureBlockScreen(profile.name);

    final stored = await _alwaysAvailableStore.getAlwaysAvailableApps(
      profile.id,
    );
    final protectedApps = getHardAlwaysAvailableApps(stored.toSet());
    final toBlock = profile.appIdentifiers
        .where((id) => !protectedApps.contains(id))
        .toList();

    await blocker.blockApps(toBlock);
  }

  Future<void> stopBlocking() async {
    try {
      await blocker.unblockAll();
    } finally {
      await _session.clear();
    }
  }
}
