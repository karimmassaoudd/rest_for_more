import 'dart:async';
import 'dart:io';

import 'package:app_blocker/app_blocker.dart';
import 'package:flutter/material.dart';

import '../../models/focus/hard_always_available_apps.dart';
import '../../theme/app_colors.dart';
import '../../widgets/focus/permission_dialog.dart';
import 'always_available_apps_store.dart';
import 'blocker_permissions.dart';
import 'session_store.dart';

/// Talks to the app_blocker plugin: asks for permission, and starts and
/// stops blocking a profile's apps.
class BlockingService {
  final _blocker = AppBlocker.instance;
  final _session = SessionStore();
  final _alwaysAvailableStore = AlwaysAvailableAppsStore();

  /// Makes sure apps can be blocked, explaining each step first.
  /// Returns true when blocking is allowed.
  ///
  /// Android has two separate switches (accessibility, exact alarms), each
  /// on its own settings page; iOS has a single system prompt.
  Future<bool> ensurePermission(BuildContext context) async {
    if (await _blocker.checkPermission() == BlockerPermissionStatus.granted) {
      return true;
    }

    if (!Platform.isAndroid) {
      await _blocker.requestPermission();
      return await _blocker.checkPermission() ==
          BlockerPermissionStatus.granted;
    }

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

    return await _blocker.checkPermission() == BlockerPermissionStatus.granted;
  }

  /// Waits until the user comes back to the app from the settings screen
  /// (gives up after 5 minutes).
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

  /// Blocks the profile's apps, except the always-available ones.
  Future<void> startBlocking(BlockProfile profile) async {
    await _configureBlockScreen(profile.name);

    final stored = await _alwaysAvailableStore.getAlwaysAvailableApps(
      profile.id,
    );
    final protectedApps = getHardAlwaysAvailableApps(stored.toSet());
    final toBlock = profile.appIdentifiers
        .where((id) => !protectedApps.contains(id))
        .toList();

    await _blocker.blockApps(toBlock);
  }

  /// Unblocks everything and forgets the session, even if unblocking fails.
  Future<void> stopBlocking() async {
    try {
      await _blocker.unblockAll();
    } finally {
      await _session.clear();
    }
  }

  /// The screen shown when the user opens a blocked app.
  /// {appName} and {timeLeft} are filled in by the plugin. The background
  /// stays dark brown in both themes: the plugin draws it natively.
  Future<void> _configureBlockScreen(String profileName) async {
    await _blocker.setBlockScreenConfig(
      BlockScreenConfig(
        title: '{appName} app is blocked',
        subtitle: '$profileName session in progress',
        timerLabel: '{timeLeft} remaining',
        backgroundColor: AppColors.darkBrown,
        returnHomeButtonText: 'Return to Home',
        emergencyButtonText: 'Emergency Unlock',
      ),
    );
  }
}
